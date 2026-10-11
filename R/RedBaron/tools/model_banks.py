"""Check complete native shape banks across controlled W6 CPU captures.

The table root is bound through its native constructor and exact allocation.
All table/resource bytes, including embedded pointers, must otherwise match raw.
"""
import argparse
import hashlib
import json
from pathlib import Path
from game_heap import allocations, exact
from hunks import read_hunks
from player_links import SIM_SHA
from prelude_state import check as prelude_check
from render_mutations import Snapshot
from world_comparison import load


def contracts(h3):
    address=lambda n:(h3+n).to_bytes(4,'big')
    return {0x396de:bytes.fromhex('33c0')+address(0x426a)+bytes.fromhex('c0fc000c'),
            0x396f6:bytes.fromhex('23c0')+address(0x4262),
            0x3970a:bytes.fromhex('41f9')+address(0x4250)+bytes.fromhex('2279')+address(0x4262)+bytes.fromhex('22d822d822d8'),
            0x39784:bytes.fromhex('24537c00200a670c204a588a4a906704524660f4'),
            0x398b4:bytes.fromhex('bc79')+address(0x426a)+bytes.fromhex('6c322006c1fc000c2079')+address(0x4262)}


def owned(read, extents, pointer, size=None):
    matches=[n-8 for a,n in extents if a+8==pointer]
    if not pointer or pointer&1 or len(matches)!=1 or (size is not None and matches[0]!=size):
        raise ValueError('Model bank does not exactly own its tracked allocation')
    return exact(read,pointer,matches[0])


def resources(read, extents, table, count):
    if not 0<count<=500 or len(table)!=12*count:raise ValueError('Incomplete model-bank table')
    result=[]
    for index in range(count):
        record=table[index*12:index*12+12]
        pointer=int.from_bytes(record[:4],'big');number=int.from_bytes(record[4:6],'big')
        if not pointer:
            if number:raise ValueError('Empty model bank has nonzero shape count')
            continue
        raw=owned(read,extents,pointer)
        end=(number+1)*4
        if not number or end>len(raw):raise ValueError('Shape list exceeds owned resource')
        for off in range(0,number*4,4):
            shape=int.from_bytes(raw[off:off+4],'big')
            if shape&1 or not pointer+end<=shape<pointer+len(raw):
                raise ValueError('Shape pointer outside resource body')
        if raw[number*4:end]!=bytes(4):raise ValueError('Missing shape-list terminator')
        result.append((index,number,raw))
    return result


def check(original,left,right):
    binary=original.read_bytes()
    if hashlib.sha256(binary).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original sim')
    code=read_hunks(binary)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError('Unexpected native model-bank contract')
    roots=(left,right);loaded=[load(p) for p in roots];fixtures=[prelude_check(p) for p in roots]
    if len({r['sha256'] for r in fixtures})!=1 or any(m[0]['sim_sha256']!=SIM_SHA for m in loaded):
        raise ValueError('Different frozen executable builds')
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Unequal boundary sequences')
    rows=[];initial=None
    for index,banks in enumerate(zip(*sequences)):
        states=[];pointers=[]
        for root,m,b in zip(roots,loaded,banks):
            ram=Snapshot(root,b);read=ram.read;h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,data in contracts(h3).items():
                if exact(read,sim+at,len(data))!=data:raise ValueError('Changed live model-bank contract')
            pointer=int.from_bytes(exact(read,h3+0x4262,4),'big')
            count=int.from_bytes(exact(read,h3+0x426a,2),'big')
            if not 0<count<=500:raise ValueError('Unsupported model-bank capacity')
            extents=allocations(read,h3);table=owned(read,extents,pointer,count*12)
            states.append((table,resources(read,extents,table,count)));pointers.append(pointer)
        if states[0]!=states[1]:raise ValueError('Raw model-bank table or complete resource differs')
        if initial is None:initial=states[0]
        table,items=states[0]
        rows.append(dict(boundary='initial' if index==0 else index-1,roots=pointers,
                         table_bytes=len(table),table_sha256=hashlib.sha256(table).hexdigest(),
                         unchanged_from_initial=states[0]==initial,
                         resources=[dict(bank=i,shapes=n,bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()) for i,n,raw in items]))
    return dict(sha256=fixtures[0]['sha256'],rows=rows,
                scope='Complete owned shape-bank table and resources at equal-tick checkpoints. Only table-root relocation is bound; embedded pointers and all other bytes match raw. Not bitmap banks, transient writes, complete gameplay or capacity acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for n in ('original','left','right'):p.add_argument(n,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args();result=check(a.original,a.left,a.right)
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Complete model banks match at',len(result['rows']),'checkpoints')
