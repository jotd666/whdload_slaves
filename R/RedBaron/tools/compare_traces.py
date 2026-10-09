#!/usr/bin/env python3
"""Compare all instruction words, DMA records and screenshot bytes, field by field."""
import argparse,json
from pathlib import Path
import barto
p=argparse.ArgumentParser();p.add_argument('left');p.add_argument('right');p.add_argument('--out');a=p.parse_args()
l=barto.load(a.left);r=barto.load(a.right);diff=[]
if len(l.fields)!=len(r.fields):raise SystemExit('Field counts differ')
for i,(x,y) in enumerate(zip(l.fields,r.fields)):
 kinds=[]
 if l.data[x.insn_off:x.insn_end]!=r.data[y.insn_off:y.insn_end]:kinds.append('instructions')
 if x.dma_size!=y.dma_size or x.dma!=y.dma:kinds.append('dma')
 if x.shot_kind!=y.shot_kind or x.shot!=y.shot:kinds.append('screenshot')
 if x.cycles!=y.cycles or x.idle!=y.idle:kinds.append('accounting')
 if kinds:diff.append(dict(field=i,differences=kinds))
result=dict(fields=len(l.fields),identical=not diff,differences=diff)
s=json.dumps(result,indent=2)+'\n'
if a.out:Path(a.out).write_text(s)
print(s,end='')
raise SystemExit(bool(diff))
