"""Compare complete 318-byte aircraft pool slots and explicit linked payloads.

The prior player check covered only a 280-byte prefix. Record stride/count/root
come from the native type-zero pool descriptors, with exact allocation bounds.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from game_heap import allocations,exact
from hunks import read_hunks
from player_links import linked_state,SIM_SHA,check as player_check
from render_mutations import Snapshot,region
from world_comparison import load

STRIDE=318


def state(read,h3,sim,extents):
    stride=int.from_bytes(exact(read,h3+0x135c,2),'big')
    count=int.from_bytes(exact(read,h3+0x5578,2),'big')
    pointer=int.from_bytes(exact(read,h3+0x5584,4),'big')
    if stride!=STRIDE or not 0<count<=500 or not pointer or pointer&1:
        raise ValueError('Unsupported aircraft pool descriptor')
    if sum(base+8==pointer and size==8+count*stride for base,size in extents)!=1:
        raise ValueError('Aircraft pool does not exactly fill one tracked payload')
    rows=[]
    for slot in range(count):
        raw=exact(read,pointer+slot*stride,stride)
        rows.append(dict(prefix=linked_state(raw[:280],read,extents,sim),tail=raw[280:].hex(),raw=raw.hex()))
    return dict(pointer=pointer,count=count,stride=stride,rows=rows)


def equal(left,right):
    if (left['count'],left['stride'])!=(right['count'],right['stride']):raise ValueError('Different aircraft pool layouts')
    for a,b in zip(left['rows'],right['rows']):
        if a['prefix']!=b['prefix'] or a['tail']!=b['tail']:
            raise ValueError('Aircraft slot bytes or complete linked payload differ')


def contracts(h3):
    return {0x10134:bytes.fromhex('41f9')+(h3+0x5584).to_bytes(4,'big'),
            0x1014e:bytes.fromhex('45f9')+(h3+0x135c).to_bytes(4,'big'),
            0x10156:bytes.fromhex('4df9')+(h3+0x5578).to_bytes(4,'big'),
            0x10164:bytes.fromhex('3f163f122f092f084ebafcbe')}


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError('Unexpected native pool descriptor use')
    prerequisite=player_check(original,left,right)
    roots=(left,right);loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,b in zip(roots,loaded,banks):
            ram=Snapshot(root,b);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,data in contracts(h3).items():
                if exact(ram.read,sim+at,len(data))!=data:raise ValueError('Live aircraft pool contract changed')
            states.append(state(ram.read,h3,sim,allocations(ram.read,h3)))
        equal(*states)
        rows.append(dict(boundary='initial' if not index else index-1,count=states[0]['count'],
                         records=[dict(slot=j,raw=region(bytes.fromhex(a['raw']),bytes.fromhex(b['raw'])),tail=a['tail'],links=a['prefix']['links'])
                                  for j,(a,b) in enumerate(zip(states[0]['rows'],states[1]['rows']))]))
    return dict(sha256=prerequisite['sha256'],stride=STRIDE,rows=rows,
                scope='Complete type-zero aircraft pool slots, order and observed three/four-byte linked payloads at retained checkpoints. Not other pools/globals, all AI decisions, combat outcomes or capacity acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for n in ('original','left','right'):p.add_argument(n,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    r=check(a.original,a.left,a.right);a.out.write_text(json.dumps(r,indent=2)+'\n')
    print('Matched',sum(x['count'] for x in r['rows']),'complete aircraft records across',len(r['rows']),'checkpoints')
