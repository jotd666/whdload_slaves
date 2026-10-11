"""Classify native message-cache allocations without accepting pixel differences."""
import argparse
import hashlib
import json
from pathlib import Path
from game_heap import allocations,exact
from hunks import read_hunks
from player_links import SIM_SHA
from render_mutations import Snapshot
from world_comparison import load,inventory
from world_controls import compare,extract


def bitmap_size(width,height,planes):
    # Exact native word arithmetic within the supported screen-size domain.
    if not 0<width<=320 or not 0<height<=200 or not 1<=planes<=5:
        raise ValueError('Unsupported message bitmap dimensions')
    return (((width+31)>>3)&0xfffe)*height*planes


def slots(read,h3,extents,seen):
    u=lambda off,n:int.from_bytes(exact(read,h3+off,n),'big')
    sizes={a+8:n-8 for a,n in extents};result=[];owners=set()
    for slot in range(33):
        pointer=u(0x44e6+slot*4,4);key=u(0x44a4+slot*2,2)
        if not pointer:continue
        if pointer not in sizes or pointer in owners or not key:raise ValueError('Invalid message bitmap owner/key')
        owners.add(pointer);identity=(slot,pointer,key)
        if identity not in seen:
            dims=(u(0x456e,2),u(0x4570,2),u(0x9d3c,2))
            if sizes[pointer]!=bitmap_size(*dims):raise ValueError('New bitmap does not match observed native allocation dimensions')
            seen[identity]=dims
        if sizes[pointer]!=bitmap_size(*seen[identity]):raise ValueError('Bitmap allocation extent changed')
        raw=exact(read,pointer,sizes[pointer])
        result.append(dict(slot=slot,key=key,address=pointer,size=len(raw),dimensions=seen[identity],sha256=hashlib.sha256(raw).hexdigest()))
    return result


def contracts(h3,sim):
    a=lambda off:(h3+off).to_bytes(4,'big');b=bytes.fromhex
    return {
        0x8c0:b('7020b079')+a(0xba)+b('67085279')+a(0xba),
        0x922:b('13fc00ff')+a(0x482f),
        0x940:b('3039')+a(0xba)+b('48c0e58041f9')+a(0x44e6)+b('d1c02f48001c'),
        0x956:b('3039')+a(0x456e)+b('3239')+a(0x4570)+b('4eba0c2a48c0487800022f004eba5c56'),
        0x976:b('206f00142080'),
        0x158e:b('4ef9')+(sim+0x2ea12).to_bytes(4,'big'),
        0x65c6:b('4ef9')+(sim+0x2d1ee).to_bytes(4,'big'),
        0x2ea12:b('0640001fe6480240fffec0c1c0f9')+a(0x9d3c)+b('4e75'),
    }


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported sim')
    code=read_hunks(raw)[0].data
    for at,value in contracts(0,0).items():
        if code[at:at+len(value)]!=value:raise ValueError(f'Original bitmap contract {at:x}')
    prior=inventory(left,right);compare(extract(left),extract(right))
    roots=(left,right);loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    seen=[{},{}];rows=[]
    for index,banks in enumerate(zip(*sequences)):
        caches=[];sound=[]
        for side,(root,m,bank) in enumerate(zip(roots,loaded,banks)):
            ram=Snapshot(root,bank);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,value in contracts(h3,sim).items():
                if exact(ram.read,sim+at,len(value))!=value:raise ValueError('Changed live bitmap contract')
            caches.append(slots(ram.read,h3,allocations(ram.read,h3),seen[side]))
            sound.append({int.from_bytes(exact(ram.read,h3+0xa184+4*j,4),'big') for j in range(7)})
        comparison=prior['initial'] if not index else prior['rows'][index-1]
        categories=[]
        for item in comparison['allocation_differences']:
            pointer=item['address']+8
            if pointer in {c['address'] for c in caches[0]}:kind='left message bitmap'
            elif pointer in sound[0] and item['size']==392 and not item.get('layout_changed'):kind='sound slot'
            else:raise ValueError('Unclassified heap difference')
            categories.append(dict(address=item['address'],size=item['size'],kind=kind,raw=item))
        if comparison['right_only_allocations']:raise ValueError('Unclassified right-only allocation')
        rows.append(dict(boundary='initial' if not index else index-1,left_cache=caches[0],right_cache=caches[1],heap_differences=categories))
    return dict(sha256=prior['sha256'],sim_sha256=SIM_SHA,rows=rows,
                scope='Observed complete message-bitmap allocation ownership, native size model and classification of all raw tracked-heap differences in this pair. Pixels and sound differences retained; no general lifecycle/failure, consumer isolation, audio or whole-gameplay verdict.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('original','left','right'):p.add_argument(name,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args();r=check(a.original,a.left,a.right)
    a.out.write_text(json.dumps(r,indent=2)+'\n');print('Classified heap differences at',len(r['rows']),'checkpoints; no equality verdict')
