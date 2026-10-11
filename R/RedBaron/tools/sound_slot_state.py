"""Inventory native sound slots without hiding playback-clock differences.

Explicit self/source pointers are validated; the playback counter is reported
separately, never asserted equal or excluded from the raw report.
"""
import argparse
import hashlib
import json
from pathlib import Path
from auxiliary_pools import payload
from game_heap import allocations,exact
from hunks import read_hunks
from player_links import SIM_SHA,check as player_check
from render_mutations import Snapshot,region
from world_comparison import load


def slot_state(raw,address,sources):
    if len(raw)!=384:raise ValueError('Incomplete sound slot')
    u=lambda at:int.from_bytes(raw[at:at+4],'big')
    if u(12)!=address+366:raise ValueError('Invalid sound self-pointer')
    source=u(362);data=u(366);identity=None
    if source:
        identity=raw[374]
        if identity>=len(sources):raise ValueError('Invalid sound resource index')
        pointer,content=sources[identity]
        if len(content)<2:raise ValueError('Truncated sound resource header')
        offset=content[1]+2
        if source!=pointer or data!=pointer+offset or offset>=len(content):
            raise ValueError('Sound source/data binding differs from native helper')
    elif data:raise ValueError('Sound data without source')
    body=bytearray(raw)
    for at,n in ((12,4),(362,8),(344,2)):body[at:at+n]=bytes(n)
    return dict(body=body.hex(),source_index=identity,counter=int.from_bytes(raw[344:346],'big'))


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big');b=bytes.fromhex
    return {0x35c00:b('7007be406c5c200748c0e58041f9')+a(0xa184),
            0x35c1a:b('487801802f48000c4eba01d0504f206f00042080'),
            0x35c40:b('41f9')+a(0xa184)+b('d1c02b50fffa206dfffa117c00ff015c43e8016e2149000c'),
            0x2b124:b('2079')+a(0x9712)+b('207018002548016a2f084eba7f2e2540016e'),
            0x2b152:b('41ea016e2548000c'),
            0x33064:b('2f0b266f00087000102b0001204bd0c043e800022009265f4e75'),
            0x34e9a:b('526801582468000c2452'),
            0x2b3a4:b('23c0')+a(0x9712)}


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError(f'Unexpected native sound contract {at:x}')
    prior=player_check(original,left,right);roots=(left,right);loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded];rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,b in zip(roots,loaded,banks):
            ram=Snapshot(root,b);h3=m[1]['h3'];sim=m[0]['entry']['sim'];read=ram.read
            for at,data in contracts(h3).items():
                if exact(read,sim+at,len(data))!=data:raise ValueError('Live sound contract changed')
            extents=allocations(read,h3);sizes={base+8:n-8 for base,n in extents}
            u=lambda off:int.from_bytes(exact(read,h3+off,4),'big')
            table=payload(read,extents,u(0x9712),23,4)
            if table[-4:]!=bytes(4):raise ValueError('Unsupported sound resource list terminator')
            sources=[]
            for off in range(0,88,4):
                ptr=int.from_bytes(table[off:off+4],'big')
                if ptr not in sizes:raise ValueError('Sound source not exact tracked payload')
                sources.append((ptr,exact(read,ptr,sizes[ptr])))
            slots=[]
            for j in range(7):
                ptr=u(0xa184+j*4);data=payload(read,extents,ptr,1,384)
                slots.append((data,slot_state(data,ptr,sources)))
            states.append((sources,slots))
        a,b=states
        if [v[1] for v in a[0]]!=[v[1] for v in b[0]]:raise ValueError('Complete sound resources differ')
        out=[]
        for j,(x,y) in enumerate(zip(a[1],b[1])):
            if any(x[1][key]!=y[1][key] for key in ('body','source_index')):
                raise ValueError('Sound slot differs beyond explicit pointers/playback counter')
            out.append(dict(slot=j,source_index=x[1]['source_index'],left_counter=x[1]['counter'],right_counter=y[1]['counter'],raw_difference=region(x[0],y[0])))
        rows.append(dict(boundary='initial' if not index else index-1,slots=out,resource_bytes=sum(len(v[1]) for v in a[0])))
    return dict(sha256=prior['sha256'],rows=rows,scope='Native sound resource bindings and complete payload bytes; raw slot differences and unequal playback counters retained. Not sound delivery/timing equivalence, all sound state, or gameplay/capacity acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for n in ('original','left','right'):p.add_argument(n,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args();r=check(a.original,a.left,a.right)
    a.out.write_text(json.dumps(r,indent=2)+'\n');print('Inventoried sound slots at',len(r['rows']),'checkpoints; playback counters remain separate')
