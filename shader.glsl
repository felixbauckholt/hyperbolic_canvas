/*
 * The quality level of antialiasing. Low levels look bad, while high levels
 * use a lot of resources, so we use no antialiasing at all.
 */
//#define antialias 4

/*
 * The number of iterations. Since for any tiling, most visible tiles are only
 * a few steps away from the center, changing this number only affects some
 * pixels at the margin.
 */
#define ITER_L 20

#define complex vec2
#define i_complex ivec2
#define mobius ivec4


extern complex thetransform[4];
extern complex passive_t[4];
extern number PI=0;
extern number l;
extern number halfl;
extern number settings;
extern number atvertex;
extern number dcount=0;

extern number inverses[265];
extern Image valmap;

// Unfortunately, love doesn't permit sending integers, so we take floats and convert them to integers.
extern number sides_dirty;
extern number P_dirty;
extern number i_l_dirty;
extern complex i_zeta_dirty;

int P;
int i_l;
i_complex i_zeta;
int sides;

extern complex midpoint;
extern number screenr;

// The following functions should correspond to the functions in mathstuff.lua
complex conj(complex a) {
	return vec2(a.x, -a.y);
}

complex mul(complex a, complex b)
{
	return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

complex expo(complex a)
{
	number l = exp(a.x);
	return l*vec2(cos(a.y), sin(a.y));
}

number abs_sq(complex xy)
{
	return xy.x*xy.x + xy.y*xy.y;
}

complex invert(complex xy)
{
	number a = abs_sq(xy);
	return (1./a)*conj(xy);
}

int intmod(int x, int m) {
	return x - m*(x/m);
}

int i_sc_mul(int a, int b) {
	a = intmod(a, P); b = intmod(b, P);
	return intmod(a*b, P);
}

i_complex i_fix(i_complex a) {
	return ivec2(intmod(a.x + P, P), intmod(a.y + P, P));
}

i_complex i_mul(i_complex a, i_complex b) {
	return ivec2(i_sc_mul(a.x, b.x) + P - i_sc_mul(a.y, b.y),
	             i_sc_mul(a.x, b.y)     + i_sc_mul(a.y, b.x));
}

i_complex i_conj(i_complex a) {
	return ivec2(a.x, P-a.y);
}

int i_abs_sq(i_complex a) {
	return intmod(i_mul(a, i_conj(a)).x, P);
}

i_complex i_invert(i_complex a) {
	int len = i_abs_sq(a);
	int ilen = int(inverses[len]);
	a = i_conj(a);
	a.x = i_sc_mul(a.x, ilen);
	a.y = i_sc_mul(a.y, ilen);
	return a;
}

i_complex i_rotate(int x, int dir) {
	i_complex c = ivec2(x, 0);
	for (int i=0; i<intmod(dir, 4); i++) {
		c = i_mul(c, i_zeta);
	}
	return c;
}

// Integer Mobius transformations get packed into an ivec4 for efficiency.
mobius m_pack(i_complex a, i_complex b) {
	mobius result;
	result.xy = a;
	result.zw = b;
	return result;
}

mobius m_shift(i_complex a) {
	return m_pack(ivec2(1, 0), a);
}

mobius m_flip() {
	return m_pack(ivec2(0, 1), ivec2(0, 0));
}

mobius m_from(complex arr[4]) {
	return m_pack(ivec2(arr[0]), ivec2(arr[1]));
}

mobius m_mul(mobius ma, mobius mb) {
	i_complex a = ma.xy, b=ma.zw;
	i_complex c = mb.xy, d=mb.zw;
	i_complex r1 = i_mul(a, c) + i_mul(b, i_conj(d));
	i_complex r2 = i_mul(a, d) + i_mul(b, i_conj(c));
	return m_pack(r1, r2);
}

/*
mobius m_normalize(mobius ma) {
	return ma;
	number l = abs_sq(ma.xy);
	if (l >= 0.1 && l <= 2) return ma;
	return ma/l;
}

complex m_exec(mobius ma, complex z) {
	complex a = ma.xy;
	complex b = ma.zw;
	return mul(mul(z,      a ) +      b,
	    invert(mul(z, conj(b)) + conj(a)));
}
*/


complex doshift(complex z, complex a) {
	return mul(z - a, invert(vec2(1, 0) - mul(conj(a), z)));
}

complex transform(complex z) {
	return mul(mul(z, thetransform[0]) + thetransform[1],
	    invert(mul(z, thetransform[2]) + thetransform[3]));
}

// Some hack I tried to use to get antialiasing to work nicer. Not up to date any more.
vec4 getgrid(complex pos) {
	pos = 1.05*pos;
	if (abs_sq(pos) >= 1) return vec4(0.5, 0.5, 0.5, 0.5);
	pos = transform(pos);
	int col = 0, col2 = 0, col3 = 0;
	complex rv = expo(vec2(0, PI*2/sides));
	complex dv = vec2(l, 0);
	int ctr = 0;
	for (int i=0; i<ITER_L; i++) {
		dv = mul(dv, rv);
		complex newpos = doshift(pos, dv);
		if (abs_sq(newpos) >= abs_sq(pos)) {
			ctr++;
			if (ctr >= sides) break;
		} else {
			ctr = 0;
			pos = -newpos;
			col++;
		}
	}
	//return vec4(mod(col, 2));
	if (pos.x >= 0) col2++;
	if (pos.y >= 0) col2++;
	if (abs_sq(pos) >= halfl*halfl) col3++;
	return vec4(mod(col, 2), mod(col2, 2), col3, 1);
}


/*
 * The main algorithm. This takes a point on the complex plane, then computes
 * what tile it belongs to, and then computes the color.
 */
vec4 getpixel(complex pos) {
	// add margins
	pos = 1.05*pos;
	// color things outside the disk grey.
	if (abs_sq(pos) >= 1) return vec4(0.5, 0.5, 0.5, 0.5);
	// draw a red circle in the center because why not
	if (abs_sq(pos) <= 0.0002) return vec4(1, 0, 0, 1);
	// move everything in a direction indicated by thetransform
	pos = transform(pos);

	// dcount indicates if the center point is on an "even" or "odd" tile (if defined)
	number col = dcount;
	// the integer Mobius transformation that will give the "tile ID" of the current tile
	mobius m = m_shift(ivec2(0, 0));
	if (mod(dcount, 2) == 0) m = m_mul(m, m_flip());

	complex rv = expo(vec2(0, PI*2/sides));
	complex dv = vec2(l, 0);
	int ctr = 0;
	for (int i=0; i<ITER_L; i++) {
		dv = mul(dv, rv);
		complex newpos = doshift(pos, dv);
		if (abs_sq(newpos) >= abs_sq(pos)) {
			// newpos isn't closer to the center than the old pos.
			// If this happens more than "sides" times, we are done.
			ctr++;
			if (ctr >= sides) break;
		} else {
			// newpos is closer to the center. Move there, and update m
			ctr = 0;
			pos = -newpos;
			m = m_mul(m_flip(), m_mul(m_shift(i_rotate(i_l, i)), m));
			col++;
		}
	}
	

	// m_hash is the "tile ID" of the current tile
	m = m_mul(m, m_from(passive_t));
	i_complex m_hash = i_fix(i_mul(m.zw, i_invert(m.xy)));

	// look up info about this tile from a big texture
	vec4 thecolor = Texel(valmap, (vec2(m_hash.y, m_hash.x) + 0.5)/P);
	// color the background somehow
	vec4 backgtiles;
	if (intmod(int(atvertex), 2) == 0) {
		backgtiles = vec4(vec3(mod(col, 2)), 1);
	} else {
		backgtiles = vec4(vec3(i_abs_sq(m_hash))/P, 1);
	}

	// depending on "settings", draw some nice patterns
	if (mod(settings, 3) < 1) {
		if (pos.x >= 0) col++;
		if (pos.y >= 0) col++;
		if (mod(col, 2) == 0) thecolor.r = thecolor.g;
		else thecolor.g = thecolor.r;
	} else if (mod(settings, 3) < 2) {
		if (thecolor.r > .5 && thecolor.g > .5) thecolor = vec4(0, 0, 1, 1);
	} else {
		col = 1;
		if (abs_sq(pos) >= halfl*halfl) col++;
		if (mod(col, 2) == 0) thecolor.r = thecolor.g;
		else thecolor.g = thecolor.r;
		thecolor.b = thecolor.g;
	}

	return 0.9*thecolor + 0.1*backgtiles;
}

// The main entry point.
// This should be self-explanatory, except for the antialiasing part, which is deprecated.
vec4 effect(vec4 colour, Image img, vec2 txy, vec2 sxy)
{
	sides = int(sides_dirty);
	P = int(P_dirty);
	i_zeta = ivec2(i_zeta_dirty);
	i_l = int(i_l_dirty);

	complex pos = (sxy - midpoint)/screenr;
#ifdef antialias
	complex dv = vec2(1)/screenr;
	complex dx = vec2(1, 0)/screenr;
	complex dy = vec2(0, 1)/screenr;
	pos -= dv/2;
	vec4 col_a = getgrid(pos);
	vec4 col_b = getgrid(pos + dx);
	vec4 col_c = getgrid(pos + dy);
	vec4 col_d = getgrid(pos + dv);
	if (col_a == col_b && col_b == col_c && col_c == col_d) return getgrid(pos + dv/2);
	vec4 col = vec4(0, 0, 0, 0);
	for (int i=0; i<antialias; i++) for (int j=0; j<antialias; j++) {
		col += getgrid(pos + dv*vec2(i+.5, j+.5)/antialias);
	}
	return col/(antialias*antialias);
#else
	return getpixel(pos);
#endif
}
