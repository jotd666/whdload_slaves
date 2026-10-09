#!/usr/bin/env python3
"""Compare disabled PERF_RANGE bytes to the original, with live hunk relocations applied.
Pass one or more --memory BASE:FILE dumps covering all four BPTR headers and sim code.
No target writes. A build with no ranges is reported as pending, never as a passed audit.
"""
import argparse,struct
from pathlib import Path
from hunks import read_hunks,relocate
from hook_ranges import ranges

def check(original,sim,read,spans):
    hs=read_hunks(original);bases=[];base=sim
    for i in range(len(hs)):
        bases.append(base)
        link=struct.unpack('>I',read(base-4,4))[0]
        if i<len(hs)-1:
            if not link:raise ValueError('Truncated live BPTR chain')
            base=link*4+4
        elif link:raise ValueError('Unexpected live trailing hunk')
    expected=relocate(hs[0],bases)
    for lo,hi,bit,source,line in spans:
        if hi>len(expected):raise ValueError('Range outside original code')
        if read(sim+lo,hi-lo)!=expected[lo:hi]:
            raise ValueError(f'CUSTOM2 bit {bit} changed sim:{lo:05x} ({source}:{line})')
    return bases

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original',type=Path)
    p.add_argument('--sim',required=True,type=lambda x:int(x,0));p.add_argument('--memory',action='append',required=True)
    a=p.parse_args();banks=[]
    for spec in a.memory:
        base,path=spec.split(':',1);banks.append((int(base,0),Path(path).read_bytes()))
    def read(addr,size):
        for base,data in banks:
            at=addr-base
            if 0<=at and at+size<=len(data):return data[at:at+size]
        raise ValueError(f'Missing dump region for {size} bytes')
    spans=ranges()
    if not spans:raise SystemExit('PENDING: no performance ranges installed')
    check(a.original.read_bytes(),a.sim,read,spans)
    print(f'{len(spans)} disabled ranges retain their original relocated bytes')
if __name__=='__main__':main()
