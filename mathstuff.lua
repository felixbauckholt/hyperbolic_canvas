zero = {r=0, i=0}
one = {r=1, i=0}
minusone = {r=-1, i=0}

--p = 251
--i_l = 109

mod_p = {}

function pack_mod_p(x)
	--local res = {val = (x + p) % p}
	local res = {val = x}
	setmetatable(res, mod_p)
	return res
end

function unpack_mod_p(x)
	return (type(x) == "number") and x or ((x.val + p) % p)
end

function mod_p.__add(lhs, rhs)
	return pack_mod_p((lhs.val + rhs.val) % p)
end

function mod_p.__sub(lhs, rhs)
	return pack_mod_p((lhs.val + p - rhs.val) % p)
end

function mod_p.__unm(x)
	return pack_mod_p((p - x.val) % p)
end

function mod_p.__mul(lhs, rhs)
	return pack_mod_p((lhs.val * rhs.val) % p)
end

i_zero = pack_mod_p(0)
i_one = pack_mod_p(1)
i_c_zero = {r=i_zero, i=i_zero}
i_c_one = {r=i_one, i=i_zero}
i_c_minusone = {r=pack_mod_p(-1), i=i_zero}


function init_invert_table()
	p_invert_table = {0}
	for i=1, p-1 do
		for j=1, p-1 do
			if (i*j) % p == 1 then
				--print(i, j)
				p_invert_table[i+1] = j
			end
		end
		--print(i, p_invert_table[i+1])
	end
end


function add(a, b)
	return {r=a.r+b.r, i=a.i+b.i}
end

function sub(a, b)
	return {r=a.r-b.r, i=a.i-b.i}
end

function mul(a, b)
	return {r=a.r*b.r - a.i*b.i, i=a.r*b.i + a.i*b.r}
end

function conj(a)
	return {r=a.r, i=-a.i}
end

function mul_ma(a, b)
	local result = {{}, {}}
	for i=1,2 do
		for j=1,2 do
			--local entry = zero
			--for k=1,2 do
			--	entry = add(entry, mul(a[i][k], b[k][j]))
			--end
			local entry = add(mul(a[i][1], b[1][j]), mul(a[i][2], b[2][j]))
			result[i][j] = entry
		end
	end
	return result
end

function abs_sq(a)
	return a.r*a.r + a.i*a.i
end

function invert(a)
	local l = abs_sq(a)
	return {r=a.r/l, i=-a.i/l}
end

function i_invert(a)
	local l = abs_sq(a)
	local il = pack_mod_p(p_invert_table[l.val+1])
	return {r=a.r*il, i=-a.i*il}
end

function normalize(ma)
	local first = ma[1][1]
	local l = math.sqrt(first.r*first.r + first.i*first.i)
	if (l < 2 and l > 0.1) then return ma end
	local a = {r=1/l, i=0}
	return mul_ma(ma, {{a, zero}, {zero, a}})
end

function rotate_scalar(l, turns)
	local ang = turns*2*math.pi
	return {r=l*math.cos(ang), i=l*math.sin(ang)}
end

function i_rotate(l, steps)
	local myl = pack_mod_p(l)
	local i_i = {r=i_zero, i=i_one}
	local arr = {i_c_one, i_i, i_c_minusone, mul(i_i, i_c_minusone)}
	return mul({r=myl, i=i_zero}, arr[(steps % 4) + 1])
end

function distance_of(ma)
	local z = mul(ma[1][2], invert(ma[2][2]))
	return z.r*z.r + z.i*z.i;
end

function i_pos_of(ma)
	return mul(ma[1][2], i_invert(ma[1][1]))
end

function shift_ma(a)
	return {{one, a}, {conj(a), one}}
end

function rotate_ma(turns)
	turns = turns/2
	local rone = rotate_scalar(1, turns)
	return {{rone, zero}, {zero, conj(rone)}}
end

function i_shift_ma(a)
	return {{i_c_one, a}, {conj(a), i_c_one}}
end

function pack_ma(m)
	local res = {}
	for i=1,2 do
		for j=1,2 do
			local entry = m[i][j]
			res[(i-1)*2+j] = {unpack_mod_p(entry.r), unpack_mod_p(entry.i)}
		end
	end
	return res
end

--function mobius(z, a)
--	local b = {r=a.r, i=-a.i}
--	return mul(add(z, a), invert(add({r=1, i=0}, mul(b, z))))
--end
