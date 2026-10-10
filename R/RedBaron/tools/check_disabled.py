#!/usr/bin/env python3
"""Compare disabled PERF_RANGE bytes to the original, with live hunk relocations applied.
Pass one or more --memory BASE:FILE dumps covering all four BPTR headers and sim code.
No target writes. A build with no ranges is reported as pending, never as a passed audit.
"""
import argparse,struct
from pathlib import Path
from hunks import read_hunks,relocate
from hook_ranges import ranges

def check(original,sim,read,spans,domain="sim"):
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
            raise ValueError(f'CUSTOM2 bit {bit} changed {domain}:{lo+(40 if domain == "sound" else 0):05x} ({source}:{line})')
    return bases

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original',type=Path)
    p.add_argument('--sim', '--base', dest='sim', required=True,type=lambda x:int(x,0));p.add_argument('--memory',action='append',required=True)
    p.add_argument('--domain', choices=['sim', 'sound'], default='sim', help='Code entry: sim:00000 or sound:00028')
    p.add_argument('--custom2',type=lambda x:int(x,0),default=0,help='Actual developer/VERIFY mask; check only bits that are off')
    a=p.parse_args();banks=[]
    for spec in a.memory:
        base,path=spec.split(':',1);banks.append((int(base,0),Path(path).read_bytes()))
    def read(addr,size):
        for base,data in banks:
            at=addr-base
            if 0<=at and at+size<=len(data):return data[at:at+size]
        raise ValueError(f'Missing dump region for {size} bytes')
    spans=ranges(domain=a.domain)
    if not spans:raise SystemExit('PENDING: no performance ranges installed')
    spans=[span for span in spans if not (a.custom2 & (1 << span[2]))]
    if not spans:raise SystemExit('PENDING: no disabled performance ranges in the selected mask')
    check(a.original.read_bytes(),a.sim,read,spans,a.domain)
    print(f'{len(spans)} disabled ranges retain their original relocated bytes')
if __name__=='__main__':main()
