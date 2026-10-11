"""Inventory native per-shape vertex caches without excluding state differences."""
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

TAGS=0xa4e6
ARRAYS=(0xa5e6,0xa9e2,0xadde,0xb1da,0xb5d6)
NAMES=('camera_x','camera_y','camera_z','screen_x','screen_y')
COUNT=255


def describe(read,h3):
    count=int.from_bytes(exact(read,h3+0xa350,2),'big')
    if count>COUNT:raise ValueError('Invalid selected vertex count')
    tags=exact(read,h3+TAGS,256)
    if any(t>3 for t in tags[:count]):raise ValueError('Unknown active vertex tag')
    arrays=[exact(read,h3+off,COUNT*4) for off in ARRAYS]
    return dict(count=count,tags=tags,arrays=arrays)


def compare(a,b):
    rows=[]
    for i in range(COUNT):
        left=[x[i*4:i*4+4] for x in a['arrays']]
        right=[x[i*4:i*4+4] for x in b['arrays']]
        changed=[name for name,x,y in zip(NAMES,left,right) if x!=y]
        if changed or a['tags'][i]!=b['tags'][i]:
            rows.append(dict(index=i,left_tag=a['tags'][i],right_tag=b['tags'][i],
                             inside_selected_count=[i<a['count'],i<b['count']],
                             changed_arrays=changed))
    return dict(counts=[a['count'],b['count']],tags=region(a['tags'],b['tags']),
                arrays={name:region(x,y) for name,x,y in zip(NAMES,a['arrays'],b['arrays'])},
                differing_rows=rows)


def contracts(h3):
    a=lambda off:(h3+off).to_bytes(4,'big');b=bytes.fromhex
    return {
        0x3a8ce:b('70001029000333c0')+a(0xa350)+b('0c4000ff'),
        0x3a8ea:b('3039')+a(0xa350)+b('720041f9')+a(TAGS)+b('600210c151c8fffc4e75'),
        0x38dcc:b('41f9')+a(TAGS)+b('4a300000672ad040d04041f9')+a(ARRAYS[0]),
        0x38dec:b('41f9')+a(ARRAYS[1])+b('22f0000041f9')+a(ARRAYS[2])+b('22b000004e75'),
        0x38ed2:b('41f9')+a(ARRAYS[3])+b('2180400041f9')+a(ARRAYS[4])+b('21814000'),
        0x3b512:b('12bc0003183c0001600e12bc000230032079')+a(0xa426)+b('4e90'),
    }


def check(original,left,right):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original sim')
    code=read_hunks(raw)[0].data
    for off,expected in contracts(0).items():
        if code[off:off+len(expected)]!=expected:raise ValueError(f'Original cache contract {off:x}')
    roots=(left,right);fixtures=[prelude_check(p) for p in roots]
    if len({f['sha256'] for f in fixtures})!=1:raise ValueError('Different frozen builds')
    if [r['tick'] for r in fixtures[0]['rows']]!=[r['tick'] for r in fixtures[1]['rows']]:
        raise ValueError('Different tick sequences')
    loaded=[load(p) for p in roots]
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Unequal snapshots')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        states=[]
        for root,m,bank in zip(roots,loaded,banks):
            ram=Snapshot(root,bank);sim=m[0]['entry']['sim'];h3=m[1]['h3']
            for off,expected in contracts(h3).items():
                if exact(ram.read,sim+off,len(expected))!=expected:raise ValueError('Changed live cache contract')
            states.append(describe(ram.read,h3))
        rows.append(dict(boundary='initial' if not index else index-1,**compare(*states)))
    return dict(sha256=fixtures[0]['sha256'],rows=rows,bytes=256+COUNT*4*5,
                scope='Native per-shape cache extent/tag inventory at equal ticks. All raw differences retained. Tags and current selected count do not prove absence of intervening reads or simulation ownership; no exclusion mask, gameplay or speed verdict.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for n in ('original','left','right'):p.add_argument(n,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.original,a.left,a.right);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Native cache inventory:',result['bytes'],'bytes at',len(result['rows']),'checkpoints')
