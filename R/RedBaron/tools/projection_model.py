#!/usr/bin/env python3
"""Reference model for sim:38c82, including d0/d1/a0/a1 outputs.

Inputs are raw unsigned 32-bit register patterns. The loop path models the
original normalization; the independent bit-length path checks its arithmetic.
Neither is replacement assembly. Flags and preserved-register contracts need
separate live checks. A zero denominator models the original divide trap.

Optional input: JSON list of {"inputs": [d0,d1,d2,d3],
"outputs": [d0,d1,a0,a1]} from complete original calls. No game bytes required.
"""
import argparse
import json
from pathlib import Path

M32=0xffffffff
def norm_loop(v, top):            # top = 15 (n in [2^14,2^15)) or 16 (n in [2^15,2^16))
    if v==0: return 0,0
    hi=(1<<top); lo=1<<(top-1); e=0
    if v>=hi:
        while v>hi-1: v>>=1; e+=1
    else:
        while v<lo: v=(v<<1)&0xffff; e-=1   # lsl.w on the low word (upper word already 0)
    return v,e
def norm_bl(v, top):
    if v==0: return 0,0
    L=v.bit_length(); e=L-top
    return ((v>>e) if e>=0 else (v<<-e)), e
LENGTHS=tuple(v.bit_length() for v in range(256))
def norm_table(v, top):
    """Instruction-shaped byte selection used by the G1 normalizer."""
    if not v: return 0,0
    high=v>>16
    if high: byte=high; length=16
    else: byte=v; length=0
    if byte>=256: byte>>=8; length+=8
    length+=LENGTHS[byte]
    exponent=length-top
    return (v>>exponent if exponent>=0 else (v<<-exponent)&0xffff),exponent

def norm_inline(v, top):
    """Current assembly's short-shift cases plus the byte-table fallbacks."""
    if v<0x10000:
        if not v: return 0,0
        if top==15:
            if v>=0x8000: return v>>1,1
            if v>=0x4000: return v,0
        else:
            if v>=0x8000: return v,0
            if v>=0x4000: return (v<<1)&0xffff,-1
        byte=v; exponent=-top
        if byte>=256: byte>>=8; exponent+=8
        exponent+=LENGTHS[byte]
        return (v<<-exponent)&0xffff,exponent
    byte=v>>16; exponent=16-top
    if byte>=256: byte>>=8; exponent+=8
    exponent+=LENGTHS[byte]
    return v>>exponent,exponent

def shift(q,e):
    e&=0xffff
    if e&0x8000: c=((-e)&0xffff)&63; return (q>>c)&M32 if c<32 else 0
    c=e&63; return (q<<c)&M32 if c<32 else 0
def p38c82(d0,d1,d2,d3, norm=norm_loop):
    if any(not 0 <= v <= M32 for v in (d0,d1,d2,d3)):
        raise ValueError('Inputs must be raw 32-bit register values')
    a0=(d0^d2^d3)&M32; a1=(d1^d2^d3)&M32
    ab=lambda v: (-v)&M32 if v&0x80000000 else v
    x,z,y,k=ab(d0),ab(d1),ab(d2),ab(d3)
    n3,e3=norm(k,15); n0,e0=norm(x,15); n1,e1=norm(z,15); n2,e2=norm(y,16)
    if n2==0: raise ZeroDivisionError
    q0=(n0*n3)//n2; q1=(n1*n3)//n2
    assert q0<65536 and q1<65536
    r0=shift(q0,e0+e3-e2); r1=shift(q1,e1+e3-e2)
    if a0&0x80000000: r0=(-r0)&M32
    if a1&0x80000000: r1=(-r1)&M32
    return r0,r1,a0,a1

def check_calls(calls):
    if not calls:
        raise ValueError('No complete original calls supplied')
    for index, row in enumerate(calls):
        if len(row['inputs']) != 4 or len(row['outputs']) != 4:
            raise ValueError(f'Call {index}: expected four inputs and outputs')
        for norm in (norm_loop, norm_bl, norm_table, norm_inline):
            got = p38c82(*row['inputs'], norm=norm)
            if got != tuple(row['outputs']):
                raise ValueError(f'Call {index}: {norm.__name__} mismatch {got}')
    return dict(calls=len(calls), model_checks=4*len(calls), mismatches=0)


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('calls', type=Path)
    a = p.parse_args()
    print(json.dumps(check_calls(json.loads(a.calls.read_text())), indent=2))
