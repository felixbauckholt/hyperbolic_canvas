#!/usr/bin/sage -python

print "starting"

from sage.all import *

def conj(x, parent):
    if parent.is_finite:
        return x.frobenius(1)
    else:
        return x.conjugate()

def mobius_shift_matrix(a):
    #only call on "real" values!
    return Matrix([[1, a], [a, 1]])

def rotate(x, turns, parent):
    if parent.is_finite():
        root = parent.zeta(turns.denominator())
        if root * conj(root, parent) != 1:
            raise ValueError("Rotation not well-behaved!")
        return x * root ** turns.numerator()
    else:
        return x * exp(2*i*pi*turns)

def mobius_rotate_matrix(turns, parent):
    return Matrix([[rotate(1, turns, parent), 0], [0, 1]])

def mobius_flip_matrix():
    return Matrix([[-1,0],[0,1]])

def iterated_matrix(poly, n, l, parent):
    #turns = Integer(1)/2 - Integer(1)/poly
    turns = Integer(1)/poly
    #m = mobius_shift_matrix(0)
    #for i in range(n):
    #    m = m*mobius_shift_matrix(rotate(l, i*turns,l.parent()))
    #return m
    m = mobius_shift_matrix(l)*mobius_flip_matrix()*mobius_rotate_matrix(turns, parent)
    return m**n

def getl(poly, n, l, parent):
    tosolve = iterated_matrix(poly, n, l, parent)[0,1]
    strict_parent = parent
    if strict_parent.is_finite():
        strict_parent = strict_parent.subfields(1)[0][0]
    roots = [a for (a, b) in tosolve.roots() if a != 0 and a in strict_parent]
    if (len(roots) == 0): raise ValueError("Can't find l!")
    if parent.is_finite():
        roots = sorted(roots, key = lambda r: -r.multiplicative_order())
        print [(r, r.multiplicative_order()) for r in roots]
    return roots[0]


def get_complex(x, parent):
    a = parent.gen()
    return "{r=pack_mod_p(%s), i=pack_mod_p(%s)}" % ((x + conj(x, parent)) / 2, (x - conj(x, parent)) / 2 / a)

def compute_stuff(poly, n, f):
    print "computing stuff for", poly, n
    l = getl(poly, n, RR["l"].gen(), RR).n()
    print l
    p = 256
    while 1:
        p = previous_prime(p)
        try:
            x = GF(p)["x"].gen()
            r = GF(p**2, "a", modulus = x**2 + 1)
            i_l = getl(poly, n, r["l"].gen(), r)
            get_complex(i_l, r)
            i_zeta = rotate(Integer(1), Integer(1)/Integer(poly), r)
            print "p=", p, "l=", i_l, "zeta=", i_zeta
            f.write("    {%f, %d, %d, %d, %s, %d},\n" % (l, poly, p, Integer(i_l), get_complex(i_zeta, r), n))
            break
        except ValueError as e:
            print "fail:", p, e

f = open("tilings.lua", "w")
f.write("tilings = {\n")
f.write("    -- this is genetated by compute_l.py\n")
f.write("    -- {l (real), sides, p, i_l (scalar mod p), i_zeta (complex mod p), atvertex}\n")

compute_stuff(4, 6, f)
compute_stuff(4, 5, f)
compute_stuff(4, 8, f)
compute_stuff(4, 7, f)
#compute_stuff(3, 7, f)
compute_stuff(3, 8, f)
compute_stuff(6, 4, f)
compute_stuff(6, 6, f)
#compute_stuff(5, 4, f)

f.write("}\n")
f.close()

#p = 5000
#while 1:
#    p = previous_prime(p)
#    F = Integers(p)
#    if F(5).is_square() and F(2).is_square():
#        lol = F(5).sqrt() - 2
#        if lol.is_square():
#            print "yay"
#            print "p=", p, "l=", lol.sqrt(), "sqr2=", F(2).sqrt()/2
#            break
#    print "fail:", p
#p = 5000
#while 1:
#    p = previous_prime(p)
#    F = Integers(p)
#    if F(2).is_square() and F(3).is_square():
#        print "yoy"
#        print "p=", p, "l=", F(3).sqrt()/3, "sqr2=", F(2).sqrt()/2
#        break
