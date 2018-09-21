zero = {r=0, i=0}
one = {r=1, i=0}
minusone = {r=-1, i=0}

mod_p = {}

function pack_mod_p(x)
	-- Create number "modulo p" (using the global variable p)
	-- p doesn't need to be defined (or set to a consistent value) when this
	--  function is called, it is only used when performing arithmetic on
	--  the return value.
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
	-- Initialize table of inverses modulo p
	-- This table will get sent to the shader to perform division mod p.
	p_invert_table = {0}
	for i=1, p-1 do
		for j=1, p-1 do
			if (i*j) % p == 1 then
				p_invert_table[i+1] = j
			end
		end
	end
	p_invert_table[p+1] = 0 -- dummy value necessary because of a dumb 0.10.2 Shader:send bug
end


-- Functions for complex numbers
-- The real and imaginary parts are either floats, or integers mod p.
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

function abs_sq(a)
	return a.r*a.r + a.i*a.i
end

function invert(a)
	local l = abs_sq(a)
	return {r=a.r/l, i=-a.i/l}
end

function i_invert(a)
	-- special case for integers mod p
	local l = abs_sq(a)
	local il = pack_mod_p(p_invert_table[l.val+1])
	return {r=a.r*il, i=-a.i*il}
end

function mul_ma(a, b)
	-- multiply 2x2-matrices
	local result = {{}, {}}
	for i=1,2 do
		for j=1,2 do
			local entry = add(mul(a[i][1], b[1][j]), mul(a[i][2], b[2][j]))
			result[i][j] = entry
		end
	end
	return result
end

function normalize(ma)
	-- perform magic on a matrix representing a Mobius transform to get an
	--  equivalent matrix whose numbers aren't too big or too small
	local first = ma[1][1]
	local l = math.sqrt(first.r*first.r + first.i*first.i)
	if (l < 2 and l > 0.1) then return ma end
	local a = {r=1/l, i=0}
	return mul_ma(ma, {{a, zero}, {zero, a}})
end

function rotate_scalar(l, turns)
	-- "rotate" a scalar by a some angle (in turns), resulting in a complex
	--  number
	local ang = turns*2*math.pi
	return {r=l*math.cos(ang), i=l*math.sin(ang)}
end

function i_rotate(l, steps)
	-- "rotate" an integer mod p by a multiple of some angle chosen in the
	--  "tilings" file
	-- To do that, we repeatedly multiply it by some "complex integer mod p"
	--  i_zeta. It is guaranteed that i_invert(i_zeta) = conj(i_zeta), so we
	--  have conj(i_rotate(l, steps)) = i_rotate(l, -steps).
	-- l must be an integer (as opposed to an integer mod p)
	steps = steps % sides
	local result = {r=pack_mod_p(l), i=i_zero}
	for i=1,steps do
		result = mul(result, i_zeta)
	end
	return result
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
	-- a rotation matrix
	-- I choose a matrix of the form [[e^{i x/2}, 0], [0, e^{-i x/2}]]
	--  as opposed to of the form [[e^x, 0], [0, 1]] because it makes the
	--  computed matrices look nicer (the bottom entries will always be
	--  conjugates of the top entries).
	turns = turns/2
	local rone = rotate_scalar(1, turns)
	return {{rone, zero}, {zero, conj(rone)}}
end

function i_shift_ma(a)
	return {{i_c_one, a}, {conj(a), i_c_one}}
end

function i_rotate_ma(rone)
	return {{rone, i_c_zero}, {i_c_zero, conj(rone)}}
end

function blend_ma(m1, m2, factor)
	local res = {{}, {}}
	local x1 = {r=1-factor, i=0}
	local x2 = {r=factor, i=0}
	for i=1,2 do
		for j=1,2 do
			res[i][j] = add(mul(x1, m1[i][j]), mul(x2, m2[i][j]))
		end
	end
	return res
end

function pack_ma(m)
	-- convert a matrix so that it can be sent to a shader
	local res = {}
	for i=1,2 do
		for j=1,2 do
			local entry = m[i][j]
			res[(i-1)*2+j] = {unpack_mod_p(entry.r), unpack_mod_p(entry.i)}
		end
	end
	res[5] = {420, 0} -- necessary because of a dumb 0.10.2 Shader:send bug
	return res
end

--function mobius(z, a)
--	local b = {r=a.r, i=-a.i}
--	return mul(add(z, a), invert(add({r=1, i=0}, mul(b, z))))
--end
