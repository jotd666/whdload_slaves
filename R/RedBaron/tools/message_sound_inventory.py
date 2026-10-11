"""Retain every message/sound-slot difference; this is not an equality verdict."""
import argparse
import json
from pathlib import Path
from auxiliary_pools import payload
from game_heap import allocations,exact
from player_links import SIM_SHA
from prelude_state import check as prelude_check
from render_mutations import Snapshot,region
from world_comparison import load
from world_controls import compare,extract


def check(left,right):
    roots=(left,right);loaded=[load(p) for p in roots];preludes=[prelude_check(p) for p in roots]
    if len({p['sha256'] for p in preludes})!=1 or any(m[0]['sim_sha256']!=SIM_SHA for m in loaded):
        raise ValueError('Different or unsupported capture executables')
    compare(extract(left),extract(right))
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Different checkpoint counts')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for p,m,b in zip(roots,loaded,banks):
            ram=Snapshot(p,b);h3=m[1]['h3'];extents=allocations(ram.read,h3)
            slots=[]
            for j in range(7):
                address=int.from_bytes(exact(ram.read,h3+0xa184+4*j,4),'big')
                slots.append(payload(ram.read,extents,address,1,384))
            states.append((exact(ram.read,h3+0x481c,22),slots))
        a,b=states
        rows.append(dict(boundary='initial' if not index else index-1,
                         message=region(a[0],b[0]),sound=[dict(slot=j,changes=region(x,y))
                             for j,(x,y) in enumerate(zip(a[1],b[1])) if x!=y]))
    return dict(sha256=preludes[0]['sha256'],sim_sha256=SIM_SHA,rows=rows,
                scope='Unfiltered 22-byte message descriptor and seven complete owned 384-byte sound slots at matched-input world checkpoints. No differences normalized or accepted; not text/resource ownership, sound timing equivalence or gameplay independence.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('left',type=Path);p.add_argument('right',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.left,a.right);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Retained message/sound differences at',len(result['rows']),'checkpoints; no equality verdict')
