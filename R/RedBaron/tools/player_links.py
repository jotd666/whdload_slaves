"""Compare the retained 280-byte player prefix with explicit relocation bindings.

No numeric-pointer guessing: +26 is the native sim:e0ec callback; +30/+120
are exact tracked payload starts of the observed three/four-byte allocations.
All other record bytes and complete referenced payloads must match.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from game_heap import allocations,exact
from hunks import read_hunks
from prelude_state import check as prelude_check
from render_mutations import Snapshot,region
from world_comparison import load
from world_controls import compare as compare_controls,extract

SIM_SHA='e9b3889bc6f177e0bcfc74987665cdafbccd984b3a031bdd1f98f6c445dd8839'
CALLBACK=0xe0ec
FIELDS=((30,3),(120,4))


def linked_state(record,read,extents,sim):
    if len(record)!=280:raise ValueError('Incomplete 280-byte player prefix')
    callback=struct.unpack_from('>I',record,26)[0]
    if callback!=sim+CALLBACK:raise ValueError('Unexpected player callback identity')
    body=bytearray(record);body[26:30]=bytes(4);links=[]
    for offset,size in FIELDS:
        pointer=struct.unpack_from('>I',record,offset)[0]
        if sum(base+8==pointer and length==size+8 for base,length in extents)!=1:
            raise ValueError('Player link is not the expected complete tracked payload')
        payload=exact(read,pointer,size)
        links.append((offset,size,payload.hex()))
        body[offset:offset+4]=bytes(4)
    return dict(body=body.hex(),callback=f'sim:{CALLBACK:05x}',links=links)


def compare(left,right):
    if left!=right:raise ValueError('Player bytes, callback or referenced payload differ')


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original player layout')
    code=read_hunks(raw)[0].data
    required={0x10264:'43fade862149001a',0x1037c:'2740001e',0x103c8:'27400078',0x101ee:'21400078',0x2a3c:'2f2b00784eba2b06',0x2a4c:'2f2b001e4eba2af6'}
    for at,value in required.items():
        if code[at:at+len(value)//2]!=bytes.fromhex(value):raise ValueError('Unexpected native pointer field contract')
    roots=(left,right);loaded=[load(p) for p in roots]
    prelude=[prelude_check(p) for p in roots]
    if len({v['sha256'] for v in prelude})!=1:raise ValueError('Different frozen slaves')
    if any(m[0]['sim_sha256']!=SIM_SHA for m in loaded):raise ValueError('Different original executable')
    inputs=compare_controls(*(extract(p) for p in roots))
    def snapshot(p,m,banks):
        entry,poses,initial,base,lines=m;ram=Snapshot(p,banks);h3=poses['h3'];sim=entry['entry']['sim']
        # The relative callback constructor and both explicit field stores are
        # unpatched in these captures; bind them at each relocated sim base.
        for at,value in required.items():
            if exact(ram.read,sim+at,len(value)//2)!=bytes.fromhex(value):raise ValueError('Live pointer contract changed')
        obj=int.from_bytes(exact(ram.read,h3+0x4578,4),'big');record=exact(ram.read,obj,280)
        return record,linked_state(record,ram.read,allocations(ram.read,h3),sim)
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Unequal boundary sequences')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[snapshot(p,m,b) for p,m,b in zip(roots,loaded,banks)]
        compare(states[0][1],states[1][1])
        rows.append(dict(boundary='initial' if index==0 else index-1,raw=region(states[0][0],states[1][0]),
                         callback=states[0][1]['callback'],complete_payloads=states[0][1]['links']))
    return dict(sha256=prelude[0]['sha256'],rows=rows,input_boundaries=len(inputs['rows']),
                scope='280-byte player prefix with three explicit pointer bindings and complete three/four-byte linked payloads at retained checkpoints only. Raw differences retained; not other objects, globals, allocation lifetimes between samples, combat or capacity acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('original',type=Path);p.add_argument('left',type=Path);p.add_argument('right',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.original,a.left,a.right);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Player and complete linked payloads agree at',len(result['rows']),'checkpoints including initial state')
