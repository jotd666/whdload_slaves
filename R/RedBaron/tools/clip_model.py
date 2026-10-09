#!/usr/bin/env python3
"""G2 trivial paths; mixed edges are deliberately delegated to sim:39ecc."""
import argparse,json,random
from pathlib import Path

def s32(v):
    v&=0xffffffff
    return v-0x100000000 if v&0x80000000 else v

def bounds(lo,hi):
    lo=lo&65535
    low=lo-65536 if lo&32768 else lo
    # Original MOVE.W high retains the EXT.L low bound's high word.
    return low,s32((low&0xffff0000)|(hi&65535))

def code(v,lo,hi):
    lo,hi=bounds(lo,hi);v=s32(v)
    return 1 if v<lo else 2 if v>hi else 0

def original_pass(coords,lo,hi):
    """Original edge walk without changing any interpolation arithmetic.

    None means an edge invokes the unchanged interpolation callback. Empty and
    all-inside paths are fully specified and can be checked independently.
    """
    if len(coords)<=1:return []
    out=[];previous=code(coords[-1],lo,hi)
    for i,v in enumerate(coords):
        current=code(v,lo,hi)
        if (previous|current)==0:out.append(i)
        elif not (previous&current):return None
        previous=current
    return out

def classify(coords,lo,hi):
    if len(coords)<=1:return 'empty'
    codes=[code(v,lo,hi) for v in coords]
    if not any(codes):return 'inside'
    if all(v==codes[0] for v in codes):return 'outside'
    return 'fallback'

def check(coords,lo,hi,expected=None):
    kind=classify(coords,lo,hi);original=original_pass(coords,lo,hi)
    if kind=='inside':assert original==list(range(len(coords)))
    elif kind in ('empty','outside'):assert original==[]
    if expected is not None and kind!='fallback':assert len(original)==expected
    return kind

def cases():
    for n in (0,1,2,8,20):
        for b in ((0,319,21,139),(-200,-100,-90,-20),(-100,100,-50,50)):
            xlo,xhi,ylo,yhi=b
            for x,y in ((xlo,ylo),(xhi,yhi),(xlo-1,ylo),(xhi+1,ylo),
                        (xlo,ylo-1),(xlo,yhi+1),(0x80000000,0x7fffffff)):
                yield n,b,x&0xffffffff,y&0xffffffff

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--calls',type=Path);a=p.parse_args()
    if a.calls:
        calls=json.loads(a.calls.read_text());counts={}
        for row in calls:
            kind=check(row['coords'],row['lo'],row['hi'],row['output']);counts[kind]=counts.get(kind,0)+1
        print('Original pass checks:',counts)
    r=random.Random(0x39ecc)
    for _ in range(100000):
        lo=r.getrandbits(16);hi=r.getrandbits(16);l,h=bounds(lo,hi)
        values=[l-1,l,l+1,h-1,h,h+1,0x80000000,0x7fffffff,r.getrandbits(32)]
        check([r.choice(values) for _ in range(r.randrange(9))],lo,hi)
    print('100000 polygons around arbitrary signed bounds: zero mismatches')
