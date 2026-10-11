"""Check the native 32-byte lookup context; retain stack-scratch differences."""
import argparse
import hashlib
import json
from pathlib import Path
from game_heap import exact
from hunks import read_hunks
from player_links import SIM_SHA
from prelude_state import check as prelude_check
from render_mutations import Snapshot,region
from world_comparison import load
from world_controls import compare as compare_controls,extract


def lookup(read,h3):
    pointer=exact(read,h3+0x8d86,4)
    if int.from_bytes(pointer,'big')!=h3+0x48fc:raise ValueError('Unsupported lookup owner')
    data=exact(read,h3+0x48fc,32)
    if data!=bytes(range(32)):raise ValueError('Lookup differs from native identity initializer')
    return pointer,data


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big');b=bytes.fromhex
    return {
        0x57e8:b('7a0078007020b8406c1041f9')+a(0x48fc)+b('d0c420041080524460ea'),
        0x5802:b('23fc')+a(0x48fc)+a(0x8d86),
        0x1e3a6:b('4e55fca848e70730266d000841edfcf443eb000823c8')+a(0x7668),
        0x1e4b2:b('2f39')+a(0x7668),
    }


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported sim')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError(f'Original context contract {at:x}')
    roots=(left,right);loaded=[load(p) for p in roots];preludes=[prelude_check(p) for p in roots]
    if len({p['sha256'] for p in preludes})!=1 or any(m[0]['sim_sha256']!=SIM_SHA for m in loaded):raise ValueError('Different executables')
    if [r['tick'] for r in preludes[0]['rows']]!=[r['tick'] for r in preludes[1]['rows']]:raise ValueError('Different tick sequences')
    compare_controls(*(extract(p) for p in roots))
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Different checkpoint counts')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        values=[];scratch=[]
        for root,m,bank in zip(roots,loaded,banks):
            ram=Snapshot(root,bank);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,data in contracts(h3).items():
                if exact(ram.read,sim+at,len(data))!=data:raise ValueError('Changed live context contract')
            values.append(lookup(ram.read,h3));scratch.append(exact(ram.read,h3+0x7668,4))
        rows.append(dict(boundary='initial' if not index else index-1,lookup=values[0][1].hex(),
                         lookup_owner='h3:48fc',raw_lookup_pointer=region(values[0][0],values[1][0]),
                         raw_scratch_pointer=region(*scratch),scratch_pointers=[x.hex() for x in scratch]))
    return dict(sha256=preludes[0]['sha256'],sim_sha256=SIM_SHA,rows=rows,
                scope='Exact native identity lookup and owner at retained equal-tick checkpoints. Native scratch assignment/read contracts checked, but scratch addresses and target bytes are not normalized or declared equal. No general scratch lifetime, complete state or gameplay-speed verdict.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('original','left','right'):p.add_argument(name,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    r=check(a.original,a.left,a.right);a.out.write_text(json.dumps(r,indent=2)+'\n')
    print('Native lookup matches at',len(r['rows']),'checkpoints; scratch differences retained')
