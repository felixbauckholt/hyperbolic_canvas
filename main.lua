require "mathstuff"


tilings = {
	-- {l, sides, p, i_l, i_isqrt2}
	{1/3*math.sqrt(3), 4, 241, 99, 11},
	{math.sqrt(math.sqrt(5) - 2), 4, 239, 56, 169},
	--{1/3*math.sqrt(3), 4, 25439, 3997, 4722},
	--{math.sqrt(math.sqrt(5) - 2), 4, 25583, 12397, 4926},
	--{1/3*math.sqrt(3), 4, 4951, 125, 2822},
	--{math.sqrt(math.sqrt(5) - 2), 4, 4993, 422, 801},

	--{1/2*math.sqrt(2), 6},
	--{0.5558929702,     5},
	--{math.sqrt(-2+3/2*math.sqrt(2)), 3},
}

function love.load()
	speed = 1.5
	rotspeed = 0.5
	blendspeed = 2
	steptime = 0.7
	settings = 1
	tiling = 1
	moving = true
	setup()
	flip_pixel(true)

	myShader = love.graphics.newShader("shader.glsl")
end

function setup()
	local tiling = tilings[(tiling % #tilings) + 1]
	l = tiling[1]
	sides = tiling[2]
	p = tiling[3]
	i_l = tiling[4]
	i_isqrt2 = tiling[5]
	init_invert_table()
	halfl = (1 - math.sqrt(1-l*l))/l;

	pos = shift_ma(zero)
	passive = i_shift_ma({r=pack_mod_p(420), i=pack_mod_p(69)})
	dcount = 0
	curtime = steptime

	valData = love.image.newImageData(p, p)
	valData:mapPixel(function() return 0, 0, 0, 255 end)
	valImg = love.graphics.newImage(valData)
end

function love.update(dt)
	-- --[[
	local x=0
	local y=0
	local ang=0
	if love.keyboard.isDown("right") then
		x = x + (speed * dt)
	end
	if love.keyboard.isDown("left") then
		x = x - (speed * dt)
	end
	if love.keyboard.isDown("down") then
		y = y + (speed * dt)
	end
	if love.keyboard.isDown("up") then
		y = y - (speed * dt)
	end
	if love.keyboard.isDown("1") then
		ang = ang + (rotspeed * dt)
	end
	if love.keyboard.isDown("2") then
		ang = ang - (rotspeed * dt)
	end
	pos = normalize(mul_ma(pos, mul_ma(shift_ma({r=x, i=y}), rotate_ma(ang))))
	--[[
	for i=1,sides do
		local flip = {{minusone, zero}, {zero, one}}
		local i_flip = {{i_c_minusone, i_c_zero}, {i_c_zero, i_c_one}}
		local ma = mul_ma(shift_ma(rotate_scalar(l, (i-1)/sides)), flip)
		local newp = mul_ma(ma, pos)
		if distance_of(newp) < distance_of(pos) then
			local ma2 = mul_ma(i_flip, i_shift_ma(i_rotate(i_l, i)))
			pos = newp
			passive = mul_ma(ma2, passive)
			--print()
			--for j, x in ipairs(pack_ma(passive)) do
			--	print(x[1], x[2])
			--end
			--local mypos = i_pos_of(passive)
			--print(mypos.r.val, mypos.i.val)
			dcount = dcount+1
		end
	end
	--]]
	curtime = curtime - dt
	if (curtime <= 0) then
		curtime = steptime
		--local flip = {{minusone, zero}, {zero, one}}
		--local i_flip = {{i_c_minusone, i_c_zero}, {i_c_zero, i_c_one}}
		--local ma = mul_ma(shift_ma(rotate_scalar(l, 0)), flip)
		--local ma2 = mul_ma(i_flip, i_shift_ma(i_rotate(i_l, 0)))
		
		local spooky_one = {r=pack_mod_p(i_isqrt2), i=pack_mod_p(i_isqrt2)}
		local ang = 1/4
		flip_pixel(true)
		local newcol = flip_pixel()
		if (newcol == 255) then
			spooky_one = conj(spooky_one)
			ang = -ang
		end
		local ma = mul_ma(shift_ma(rotate_scalar(l, 0)), rotate_ma(ang))
		local ma2 = mul_ma(i_shift_ma(i_rotate(i_l, 1)), i_rotate_ma(spooky_one))
		pos = mul_ma(ma, pos)
		passive = mul_ma(ma2, passive)
		flip_pixel(true)
		dcount = dcount + 1
	end
	if moving then
		pos = blend_ma(pos, shift_ma(zero), math.min(dt*blendspeed, 0.2))
	end
end

function flip_pixel(bla)
	local po = i_pos_of(passive)
	local i1, i2 = abs_sq(po).val, po.r.val
	local r, g, b, a = valData:getPixel(i1, i2)
	--if r == g
	--then r = 255-r
	--else g = 255-g
	--end
	r, g, b = 255-r, 255-g, 255-b
	if bla then r, g = 255-r, 255-g end
	valData:setPixel(i1, i2, r, g, b, a)
	valImg:refresh()
	return r, g, b
end

function love.mousepressed()
	settings = settings + 1
end

function love.keypressed(key)
	if (key == "space") then
		moving = not moving
	elseif (key == "escape") then
		love.event.quit()
	elseif (key == "3") then
		pos = shift_ma(zero)
	end
end

function love.draw()
	love.graphics.setBackgroundColor(128, 128, 128)
	love.window.setTitle(love.timer.getFPS().." FPS")

	myShader:send("inverses", unpack(p_invert_table))
	myShader:send("valmap", valImg)
	myShader:send("l", l)
	--myShader:send("halfl", halfl)
	myShader:send("P_dirty", p)
	myShader:send("i_l_dirty", i_l)
	myShader:send("dcount", dcount)
	myShader:send("sides_dirty", sides)
	myShader:send("thetransform", unpack(pack_ma(pos)))
	myShader:send("passive_t", unpack(pack_ma(passive)))
	myShader:send("PI", math.pi)
	--myShader:send("settings", settings)

	local sx, sy = love.window.getMode()
	myShader:send("midpoint", {sx/2, sy/2})
	myShader:send("screenr", math.min(sx, sy)/2)
	love.graphics.setShader(myShader)
	love.graphics.rectangle("fill",0,0,sx,sy)
	love.graphics.setShader()

	love.graphics.print("l is "..l..", "..love.timer.getFPS().." FPS", 0, 0)
	love.graphics.print(pos[1][1].r.." + "..pos[1][1].i.."i", 0, 15)
	love.graphics.print(pos[1][2].r.." + "..pos[1][2].i.."i", 0, 30)
	love.graphics.print(pos[2][1].r.." + "..pos[2][1].i.."i", 0, 45)
	love.graphics.print(pos[2][2].r.." + "..pos[2][2].i.."i", 0, 60)
end
