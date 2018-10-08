# hyperbolic_canvas

A lua/love visualization of a tiled hyperbolic plane. You can move around on it
and change the color of the tile you're on.

The tiling is infinite, but whenever you change the color of your tile, you also
change the color of some "random" tiles far, far away.

For a demo see [this](https://youtu.be/uFkKjt5eWlI)
and [this demo of the `langtons-ant` branch](https://youtu.be/KTXiwg8_cLk).

## How to use it

1. Install [love](http://love2d.org)
2. Open love with this directory
3. Pray that the shader code works on your device
4. Use arrow keys to move around, press space to change the color, left click to
   change the pattern, press 1/2/3 to rotate, press 4 to change the tiling
   parameters.

Alternatively, you can watch a stripped-down version of this project
[on Shadertoy](https://www.shadertoy.com/view/ldsfD8)

## How it works

This displays the
[Poincaré disk model](https://en.wikipedia.org/wiki/Poincar%C3%A9_disk_model)
of the hyperbolic plane. There, translations and rotations are
[Möbius transformations](https://en.wikipedia.org/wiki/M%C3%B6bius_transformation),
which can be represented as matrices of complex numbers.

The visualization uses the GPU to compute, for each pixel, the tile that pixes
is in, as follows: It starts with the position of the pixel, represented as a
complex number. First, it applies a given transformation (that is supposed to
represent the position of the viewer) to that position.
Then, it repeatedly tries to shift the position by some constant l in various
directions (the four cardinal directions for a square tiling, six directions for
a hexagonal tiling, and so on). Here, l represents the "distance" from one tile
to the next. If the new position is closer to the origin than the old one, the
shift succeeds, otherwise we undo it. Eventually, no shifts will succeed, as the
position has been shifted into the center tile.

Depending on if the number of shifts that succeeds is even or odd, we can obtain
a simple black-and-white coloring. But to use the plane as a canvas, we need to
go further: I assign a pseudorandom "tile ID" to each tile.

To compute that "tile ID", we mirror each shift we perform (viewed as a Mobius
transformation matrix) by a corresponding matrix in a finite field. We then
multiply all the finite field matrices together with a matrix representing the
tile that the viewer is on; the result (or at least a hash of its top row) will be the
tile ID.

The finite field stuff is tricky since we only have 16 bit integers. We choose
some prime p and then do all computations in GF(p^2) (with a modulus polynomial
x^2 + 1 to make everything look as much like the complex numbers as possible).
We calculate the "finite field version" of the constant l by solving some weird
equation using python/sage.

## Issues

When writing this, I adapted to all the quirks of the love version of GLSL, as
well as to all the quirks of my machine. The result seems to be not particularly
portable.

If you know how to write portable GLSL code (or just how to do integer modulo
quickly and portably), or you know a framework that is as easy to use as love
while resulting in more portable shader code, any hints would be greatly
appreciated!
