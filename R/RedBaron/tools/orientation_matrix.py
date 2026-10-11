"""Exact word arithmetic for the native sim:3648c orientation constructor.

The original table is an input, never regenerated with host floating point.
Returns the 19 bytes written by the routine; padding byte 19 is untouched.
"""
import struct


def word(x):
    x &= 65535
    return x-65536 if x & 32768 else x


def lookup(table,angle):
    index=(angle & 65535)>>4
    if index & 2048:index=4096-index
    return table[index]


def matrix(table,angles,reuse=False):
    if len(table)!=2049 or len(angles)!=3:raise ValueError('Wrong table/angle extent')
    a,b,c=(word(x) for x in angles)
    cache={};reads=0
    def L(x):
        nonlocal reads
        key=x&65535
        if reuse and key in cache:return cache[key]
        value=lookup(table,key);reads+=1;cache[key]=value
        return value
    def H(x):return L(x)>>1
    if not (a or b):
        if not c:values=[16384,0,0,0,16384,0,0,0,16384];flag=0
        else:
            x=L(c);y=L(c-16384)
            values=[x,y,0,-y,x,0,0,0,16384];flag=1
    else:
        d6=L(a-16384)
        d2=word(H(b+c)+H(b-c))
        d3=word(H(c-b-16384)+H(c+b-16384))
        d4=word(H(b-c-16384)+H(b+c-16384))
        d5=word(H(b-c)-H(b+c))
        values=[d2-((d5*d6)>>14),((d4*d6)>>14)+d3,
                -word(H(b-a-16384)+H(b+a-16384)),
                -word(H(c-a-16384)+H(c+a-16384)),
                word(H(a-c)+H(a+c)),d6,
                ((d3*d6)>>14)+d4,d5-((d2*d6)>>14),
                word(H(a-b)+H(a+b))]
        flag=3
    return struct.pack('>9hB',*(word(x) for x in values),flag),reads
