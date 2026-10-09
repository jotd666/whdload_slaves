#!/usr/bin/env python3
"""Count sim:3154a publications and locate their 24 word writes in PAL DMA slots.
Only complete, matching MOVEM writes receive a measured beam position. Chunk joins
have one missing field; incomplete publications remain explicit, never interpolated.
"""
import argparse,json,struct
from collections import defaultdict,deque
from pathlib import Path
import barto

def analyse(paths,sim):
    rows=[];offset=0;chunks=[]
    for path in paths:
        t=barto.load(path)
        chunks.append(dict(path=str(path),start=offset,fields=len(t.fields),gap_before=1 if offset else 0))
        writes=defaultdict(list)
        for f in t.fields:
            for k in range(len(f.dma)//f.dma_size):
                i=k*f.dma_size
                # Barto CPU word write: type 2, register/access code $1102.
                if f.dma[i+29]!=2 or struct.unpack_from('<H',f.dma,i)[0]!=0x1102:continue
                addr=struct.unpack_from('<I',f.dma,i+12)[0]
                data=struct.unpack_from('<H',f.dma,i+2)[0]
                writes[addr].append((f.index,k,data))
        candidates={}
        for f in t.fields:
            cycles=0
            for pc,c,r in t.instructions(f):
                if pc==sim+0x3154a:
                    dest=r[8]
                    expected=[]
                    for v in (*r[2:8],*r[9:15]):expected.extend((v>>16,v&0xffff))
                    key=(dest,tuple(expected))
                    if key not in candidates:
                        matches=[]
                        for fi,k,data in writes[dest]:
                            if data!=expected[0]:continue
                            sequence=[(fi,k,data)];last=(fi,k)
                            for j,w in enumerate(expected[1:],1):
                                choices=[q for q in writes[dest+2*j] if q[2]==w and last<q[:2] and q[0]<=fi+1]
                                if not choices:break
                                q=min(choices);sequence.append(q);last=q[:2]
                            if len(sequence)==24:matches.append(sequence)
                        candidates[key]=deque(matches)
                    matches=candidates[key]
                    while matches and matches[0][0][0]<f.index:matches.popleft()
                    seq=matches.popleft() if matches and matches[0][0][0]<=f.index+1 else None
                    row=dict(field=offset+f.index,cycle=cycles,copper=dest,dma_complete=seq is not None)
                    if seq:
                        for name,(fi,k,_) in zip(('first_write','last_write'),(seq[0],seq[-1])):
                            row[name]=dict(field=offset+fi,line=k//227,hpos=k%227)
                    rows.append(row)
                cycles+=c
        offset+=len(t.fields)
    return dict(recorded_fields=offset,chunks=chunks,swaps=rows,notice='PAL DMA slots: 227 per line. No cycle-sum beam estimate. Chunk joins omit one field.')

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('traces',nargs='+');p.add_argument('--sim',required=True,type=lambda x:int(x,0));p.add_argument('--out');a=p.parse_args()
    s=json.dumps(analyse(a.traces,a.sim),indent=2)+'\n'
    if a.out:Path(a.out).write_text(s)
    print(s,end='')
if __name__=='__main__':main()
