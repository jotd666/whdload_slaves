"""Compare complete native sun/star records and explicit table ownership."""
import argparse
import hashlib
import json
from pathlib import Path
from game_heap import allocations,exact
from hunks import read_hunks
from pairwise_table import owned
from player_links import SIM_SHA
from prelude_state import check as prelude_check
from render_mutations import Snapshot,region
from world_comparison import load
from world_controls import compare as compare_controls,extract

ROOT=0x49a8
SIZE=0x32


def state(read,h3,extents):
    u=lambda off,n:int.from_bytes(exact(read,h3+off,n),'big')
    count=u(ROOT,2)
    if not 2<=count<=500:raise ValueError('Unsupported sun/star count')
    table=u(0x49aa,4);pool=u(0x49ae,4);phases=u(0x49bc,4)
    raw_table=owned(read,extents,table,count*4)
    records=owned(read,extents,pool,(count-1)*6)
    phase_data=owned(read,extents,phases,count*2)
    for i in range(count):
        pointer=int.from_bytes(raw_table[i*4:i*4+4],'big')
        expected=h3+0x49b2 if i==0 else pool+(i-1)*6
        if pointer!=expected:raise ValueError('Sun/star table row has wrong record owner')
    if u(0x49d0,4)!=table or u(0x8e0,2)!=count or u(0x49d4,4)!=h3+0x8d70:
        raise ValueError('Selected sky context differs from native caller contract')
    descriptor=exact(read,h3+ROOT,SIZE);canonical=bytearray(descriptor)
    for off in (0x49aa,0x49ae,0x49bc,0x49d0,0x49d4):canonical[off-ROOT:off-ROOT+4]=bytes(4)
    return dict(count=count,descriptor=canonical.hex(),records=records.hex(),phases=phase_data.hex(),
                selected_count=u(0x8e0,2),raw_descriptor=descriptor,raw_table=raw_table)


def equal(a,b):
    for key in ('count','descriptor','records','phases','selected_count'):
        if a[key]!=b[key]:raise ValueError('Sun/star state differs: '+key)


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big');b=bytes.fromhex
    return {
        0x6448:b('33c0')+a(ROOT),
        0x646e:b('48f90001')+a(0x49bc),
        0x6498:b('23c0')+a(0x49aa),
        0x64b6:b('23c0')+a(0x49ae),
        0x6508:b('2007c1fc00062079')+a(0x49ae)+b('d1c05d88600641f9')+a(0x49b2),
        0x6522:b('200748c0e5802079')+a(0x49aa)+b('218b0800'),
        0x63a4:b('4879')+a(0x8d70)+b('3f39')+a(ROOT)+b('2f39')+a(0x49aa),
        0x65e0:b('23cb')+a(0x49d0)+b('33c7')+a(0x8e0)+b('23ca')+a(0x49d4)+b('33c6')+a(0x49d8),
        0x60de:b('2079')+a(0x49aa)+b('2070080052680004'),
        0x69d4:b('2079')+a(0x49d0)+b('265008130007'),
    }


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported sim')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError(f'Original sky contract {at:x}')
    roots=(left,right);loaded=[load(p) for p in roots];fixtures=[prelude_check(p) for p in roots]
    if len({f['sha256'] for f in fixtures})!=1 or any(m[0]['sim_sha256']!=SIM_SHA for m in loaded):
        raise ValueError('Different frozen/original executables')
    if [r['tick'] for r in fixtures[0]['rows']]!=[r['tick'] for r in fixtures[1]['rows']]:
        raise ValueError('Different tick sequences')
    compare_controls(*(extract(p) for p in roots))
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Unequal checkpoint sequences')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,bank in zip(roots,loaded,banks):
            ram=Snapshot(root,bank);h3=m[1]['h3'];sim=m[0]['entry']['sim']
            for at,data in contracts(h3).items():
                if exact(ram.read,sim+at,len(data))!=data:raise ValueError('Changed live sky contract')
            states.append(state(ram.read,h3,allocations(ram.read,h3)))
        a,b=states;equal(a,b)
        rows.append(dict(boundary='initial' if not index else index-1,count=a['count'],
                         descriptor=a['descriptor'],records=a['records'],phases=a['phases'],
                         raw_differences={key:region(a['raw_'+key],b['raw_'+key]) for key in ('descriptor','table')}))
    return dict(sha256=fixtures[0]['sha256'],sim_sha256=SIM_SHA,rows=rows,
                scope='Full sun/star record bytes, phase array, descriptor scalars and explicit pointer ownership at retained equal ticks. The selected vector pointer binds to its native h3 field; its contents and all other globals are not normalized. Not all sky/resource lifecycle, gameplay or capacity acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('original','left','right'):p.add_argument(name,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.original,a.left,a.right);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Complete sun/star state matches at',len(result['rows']),'checkpoints')
