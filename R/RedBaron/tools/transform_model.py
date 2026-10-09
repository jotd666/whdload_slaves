#!/usr/bin/env python3
"""Exact sim:3afbe word-vector transform and register-oriented candidate."""
import argparse,json,random
from pathlib import Path
MASK=0xffffffff

def signed(v,bits=32):
    v&=(1<<bits)-1
    return v-(1<<bits) if v>>(bits-1) else v

def asl(v,n):return (v<<(n&63))&MASK

def asr(v,n):return (signed(v)>>(n&63))&MASK

def original(v,m,kind,scale):
    v=[signed(x,16) for x in v];m=[signed(x,16) for x in m]
    if kind==0:return [asl(x,scale) for x in v]
    out=[]
    for row in range(2 if kind==1 else 3):
        total=0
        for col in range(2 if kind==1 else 3):total=(total+m[row+3*col]*v[col])&MASK
        out.append(asr(total,(14-scale)&65535))
    if kind==1:out.append(asl(v[2],scale))
    return out

def candidate(v,m,kind,scale):
    v=[signed(x,16) for x in v];m=[signed(x,16) for x in m]
    if kind==0:return [asl(x,scale) for x in v]
    shift=(14-scale)&63
    out=[]
    for row in range(2 if kind==1 else 3):
        x=m[row]*v[0] if v[0] else 0
        y=m[row+3]*v[1] if v[1] else 0
        z=m[row+6]*v[2] if kind!=1 and v[2] else 0
        out.append((signed((x+y+z)&MASK)>>shift)&MASK)
    if kind==1:out.append(asl(v[2],scale))
    return out

def cases():
    rng=random.Random(0x38dcc)
    i=0
    for kind in (0,1,2,255):
        for scale in (0,1,2,3,7,14,15,31,32,63,64,65535):
            yield (0,127,254)[i%3],[rng.getrandbits(16) for _ in range(3)],[rng.getrandbits(16) for _ in range(9)],kind,scale
            i+=1
        for v in ([0,0,0],[1,2,0],[0,0,1],[0x8000]*3,[0x7fff]*3,[0xffff]*3,[0,0x8000,0],[0x8000,0,0]):
            yield (0,127,254)[i%3],v,[rng.getrandbits(16) for _ in range(9)],kind,7
            i+=1
    for i in range(128):
        yield (0,127,254)[i%3],[rng.getrandbits(16) for _ in range(3)],[rng.getrandbits(16) for _ in range(9)],rng.choice([0,1,2,255]),rng.getrandbits(16)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--calls',type=Path);a=p.parse_args()
    if a.calls:
        rows=json.loads(a.calls.read_text());assert rows
        for r in rows:assert original(r['v'],r['m'],r['kind'],r['scale'])==candidate(r['v'],r['m'],r['kind'],r['scale'])==r['output']
        print(len(rows),'original transforms: both models match')
    rng=random.Random(0x3afbe)
    for _ in range(200000):
        v=[rng.choice([0,rng.getrandbits(16)]) for _ in range(3)];m=[rng.getrandbits(16) for _ in range(9)];kind=rng.choice([0,1,2,255]);scale=rng.getrandbits(16)
        assert original(v,m,kind,scale)==candidate(v,m,kind,scale)
    print('200000 random word vectors, matrices, types and shift counts: zero mismatches')
