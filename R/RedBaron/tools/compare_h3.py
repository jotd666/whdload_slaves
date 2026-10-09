#!/usr/bin/env python3
"""Compare complete sim v1 h3 snapshots, reporting pointer normalization separately.
Metadata is the corresponding step_log.py JSON. Numeric values that happen to look
like pointers are reported as candidates; inspect them before asserting equivalence.
"""
import argparse,json,struct
from pathlib import Path

def compare(a,b,ma,mb):
    if len(a)!=0xbd0c or len(b)!=0xbd0c:raise ValueError('Expected complete sim v1 h3 allocation')
    raw=[i for i,(x,y) in enumerate(zip(a,b)) if x!=y];remaining=set(raw);pointers=[]
    def identify(v,m):
        for name,size in [('sim',0x3e384),('h3',0xbd0c)]:
            if m[name]<=v<m[name]+size:return name,v-m[name]
        return None
    for at in range(0,len(a)-3,2):
        if not remaining.intersection(range(at,at+4)):continue
        x,y=struct.unpack_from('>I',a,at)[0],struct.unpack_from('>I',b,at)[0]
        left,right=identify(x,ma),identify(y,mb)
        if left is not None and left==right:
            pointers.append(dict(offset=at,target=left[0],target_offset=left[1]))
            remaining.difference_update(range(at,at+4))
    spans=[]
    for at in sorted(remaining):
        if spans and spans[-1]['end']==at:spans[-1]['end']=at+1
        else:spans.append(dict(start=at,end=at+1))
    return dict(strict_equal=not raw,equal_after_pointer_candidates=not remaining,
                different_bytes=len(raw),unexplained_bytes=len(remaining),pointer_candidates=pointers,ranges=spans)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    for name in ['left','right','left_metadata','right_metadata']:p.add_argument(name,type=Path)
    p.add_argument('--out',type=Path);a=p.parse_args()
    result=compare(a.left.read_bytes(),a.right.read_bytes(),json.loads(a.left_metadata.read_text()),json.loads(a.right_metadata.read_text()))
    text=json.dumps(result,indent=2)+'\n'
    if a.out:a.out.write_text(text)
    print(text,end='')
    raise SystemExit(bool(result['unexplained_bytes']))
if __name__=='__main__':main()
