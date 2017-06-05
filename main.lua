require "mathstuff"
require "tilings"



function setup()
	local tiling = tilings[(tiling % #tilings) + 1]
	l = tiling[1]
	sides = tiling[2]
	p = tiling[3]
	i_l = tiling[4]
	i_zeta = tiling[5]
	atvertex = tiling[6]
	init_invert_table()
	halfl = (1 - math.sqrt(1-l*l))/l;

	pos = shift_ma(zero)
	passive = i_shift_ma({r=pack_mod_p(0), i=pack_mod_p(0)})
	dcount = 0

	valData = love.image.newImageData(p, p)
	valData:mapPixel(function() return 0, 0, 0, 255 end)
	valImg = love.graphics.newImage(valData)
end

function love.load()
	speed = 1.5
	rotspeed = 0.5
	settings = 1
	tiling = 0
	setup()

	myShader = love.graphics.newShader("shader.glsl")
end

function love.update(dt)
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
	for i=1,sides do
		local flip = {{minusone, zero}, {zero, one}}
		local i_flip = {{i_c_minusone, i_c_zero}, {i_c_zero, i_c_one}}
		local ma = mul_ma(shift_ma(rotate_scalar(l, (i-1)/sides)), flip)
		local newp = mul_ma(ma, pos)
		if distance_of(newp) < distance_of(pos) then
			local ma2 = mul_ma(i_flip, i_shift_ma(i_rotate(i_l, i)))
			pos = newp
			passive = mul_ma(ma2, passive)
			dcount = dcount+1
		end
			--print()
			--for j, x in ipairs(pack_ma(passive)) do
			--	print(x[1], x[2])
			--end
			--local mypos = i_pos_of(passive)
			--print(mypos.r.val, mypos.i.val)
	end
end

function love.mousepressed()
	settings = settings + 1
end

function love.keypressed(key)
	if (key == "space") then
		local po = i_pos_of(passive)
		local i1, i2 = po.i.val, po.r.val
		local r, g, b, a = valData:getPixel(i1, i2)
		if r == g
		then r = 255-r
		else g = 255-g
		end
		--r, g, b = 255-r, 255-g, 255-b
		valData:setPixel(i1, i2, r, g, b, a)
		valImg:refresh()
	elseif (key == "escape") then
		love.event.quit()
	elseif (key == "3") then
		pos = shift_ma(zero)
	elseif (key == "4") then
		tiling = tiling + 1
		setup()
	end
end

function love.draw()
	love.graphics.setBackgroundColor(128, 128, 128)
	love.window.setTitle(love.timer.getFPS().." FPS")

	myShader:send("inverses", unpack(p_invert_table))
	myShader:send("valmap", valImg)
	myShader:send("l", l)
	myShader:send("halfl", halfl)
	myShader:send("P_dirty", p)
	myShader:send("i_l_dirty", i_l)
	myShader:send("i_zeta_dirty", {unpack_mod_p(i_zeta.r), unpack_mod_p(i_zeta.i)})
	myShader:send("atvertex", atvertex)
	myShader:send("dcount", dcount)
	myShader:send("sides_dirty", sides)
	myShader:send("thetransform", unpack(pack_ma(pos)))
	myShader:send("passive_t", unpack(pack_ma(passive)))
	myShader:send("PI", math.pi)
	myShader:send("settings", settings)

	local sx, sy = love.window.getMode()
	myShader:send("midpoint", {sx/2, sy/2})
	myShader:send("screenr", math.min(sx, sy)/2)
	love.graphics.setShader(myShader)
	love.graphics.rectangle("fill",0,0,sx,sy)
	love.graphics.setShader()

	love.graphics.print("l is "..l..", "..love.timer.getFPS().." FPS", 0, 0)
	--love.graphics.print(pos[1][1].r.." + "..pos[1][1].i.."i", 0, 15)
	--love.graphics.print(pos[1][2].r.." + "..pos[1][2].i.."i", 0, 30)
	--love.graphics.print(pos[2][1].r.." + "..pos[2][1].i.."i", 0, 45)
	--love.graphics.print(pos[2][2].r.." + "..pos[2][2].i.."i", 0, 60)
	love.graphics.print("hash: "..i_pos_of(passive).r.val.." + "..i_pos_of(passive).i.val.."i", 0, 15)
	love.graphics.print(passive[1][1].r.val.." + "..passive[1][1].i.val.."i", 0, 30)
	love.graphics.print(passive[1][2].r.val.." + "..passive[1][2].i.val.."i", 0, 45)
	love.graphics.print(passive[2][1].r.val.." + "..passive[2][1].i.val.."i", 0, 60)
	love.graphics.print(passive[2][2].r.val.." + "..passive[2][2].i.val.."i", 0, 75)
end
