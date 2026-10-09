#!/usr/bin/env python3
"""sim:3b1fa: signed word/long dot product, low 32 bits only."""
import argparse,json,random
from pathlib import Path
MASK=0xffffffff

def signed(v,bits):
    v&=(1<<bits)-1
    return v-(1<<bits) if v>>(bits-1) else v

def original(v,n):
    return sum(signed(x,32)*signed(y,16) for x,y in zip(v,n))&MASK

def candidate(v,n):
    total=0
    for x,y in zip(v,n):
        y=signed(y,16);m=abs(y)
        p=(((x&65535)*m)+(((x>>16)*m)<<16))&MASK
        if y<0:p=(-p)&MASK
        total=(total+p)&MASK
    return total

def cases():
    edges=[0,1,0x7fff,0x8000,0xffff,0x7fffffff,0x80000000,0xffffffff]
    for x in edges:
        for y in edges[:5]:yield [x,x^MASK,(x+1)&MASK],[y,y^65535,(y+1)&65535]
    rng=random.Random(0x3b1fa)
    for _ in range(512):yield [rng.getrandbits(32) for _ in range(3)],[rng.getrandbits(16) for _ in range(3)]

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--calls',type=Path);p.add_argument('--random',type=int,default=0);a=p.parse_args()
    if a.calls:
        rows=json.loads(a.calls.read_text());assert rows
        for row in rows:assert original(row['v'],row['n'])==candidate(row['v'],row['n'])==row['output']
        print(f'{len(rows)} original calls: both models match')
    for v,n in cases():assert original(v,n)==candidate(v,n)
    rng=random.Random(0x3b1fa)
    for _ in range(a.random):
        v=[rng.getrandbits(32) for _ in range(3)];n=[rng.getrandbits(16) for _ in range(3)]
        assert original(v,n)==candidate(v,n)
    print(f'552 edge/synthetic cases and {a.random} random dot products: zero mismatches')
