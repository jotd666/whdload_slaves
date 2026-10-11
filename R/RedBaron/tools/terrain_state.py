"""Compare complete retained terrain-list records and cache controls at world boundaries.

Reports transient builder coordinates separately. Equality here does not prove
all terrain consumers or runtime cache reuse, which has a separate phase check.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
from game_heap import allocations, exact
from hunks import read_hunks
from presentation_state import symbol
from render_mutations import Snapshot
from world_comparison import load

STRIDE=34
SIM_SHA='e9b3889bc6f177e0bcfc74987665cdafbccd984b3a031bdd1f98f6c445dd8839'


def state(read,h3,extents):
    pointer,count=struct.unpack('>IH',exact(read,h3+0x526a,6))
    if count>32767 or pointer & 1:
        raise ValueError('Invalid native terrain count or alignment')
    size=count*STRIDE
    owners=[(base,length) for base,length in extents if base+8<=pointer and pointer+size<=base+length]
    if not pointer or len(owners)!=1:
        raise ValueError('Terrain list is not contained in one tracked payload')
    records=exact(read,pointer,size)
    controls=exact(read,h3+0x5270,2)+exact(read,h3+0x54de,14)
    return dict(pointer=pointer,count=count,records=records,controls=controls,
                builder_position=exact(read,h3+0x5272,12))


def equal(a,b):
    for key in ('pointer','count','records','controls'):
        if a[key]!=b[key]: raise ValueError(f'Terrain {key} differs across schedules')


def references(raw):
    result=[]
    for number,hunk in enumerate(read_hunks(raw)):
        for at,target in hunk.relocations:
            value=struct.unpack_from('>I',hunk.data,at)[0]
            if target==3 and 0x526a<=value<0x527e:
                result.append(dict(hunk=number,operand=f'{at:05x}',target=f'h3:{value:05x}'))
    return result


def check(original,roots):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported original terrain layout')
    refs=references(raw)
    builder_refs=[r for r in refs if 0x5272<=int(r['target'][3:],16)<0x527e]
    if len(builder_refs)!=10 or any(r['hunk']!=0 or not 0xf01c<=int(r['operand'],16)<0xf5f4 for r in builder_refs):
        raise ValueError('Unexpected direct builder-position reference')
    code=read_hunks(raw)[0].data
    if code[0xefa6:0xefaa]!=bytes.fromhex('4eba1baa'):
        raise ValueError('Unexpected loader-to-sorter call')
    runs=[];builds=set();bases=set();ticks=None
    for root in roots:
        entry,poses,initial,base,listing=load(root)
        digest=hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()
        if {entry['slave_sha256'],poses['sha256'],initial['sha256']}!={digest} or entry['sim_sha256']!=SIM_SHA:
            raise ValueError('Mismatched original or frozen capture build')
        builds.add(digest);bases.add(poses['h3'])
        rows=[];h3=poses['h3'];header=base+symbol(listing,'time_pose_header')
        for frame in poses['frames']:
            ram=Snapshot(root,frame['banks']);tick=int.from_bytes(exact(ram.read,header+4,4),'big')
            if tick!=len(rows):raise ValueError('Missing or nonconsecutive world boundary')
            rows.append(state(ram.read,h3,allocations(ram.read,h3)))
        if not rows or (ticks is not None and ticks!=len(rows)):raise ValueError('Unequal boundary counts')
        ticks=len(rows);runs.append(rows)
    if len(runs)<2 or len(builds)!=1 or len(bases)!=1:raise ValueError('Need matching allocated builds from two or more schedules')
    output=[]
    for tick,reference in enumerate(runs[0]):
        for rows in runs[1:]:equal(reference,rows[tick])
        output.append(dict(tick=tick,record_count=reference['count'],record_bytes=len(reference['records']),
                           records_sha256=hashlib.sha256(reference['records']).hexdigest(),
                           controls=reference['controls'].hex(),builder_positions={root.name:rows[tick]['builder_position'].hex() for root,rows in zip(roots,runs)}))
    return dict(sha256=next(iter(builds)),rows=output,direct_references=refs,builder_position_direct_references=len(builder_refs),
                sorter_call=dict(site='sim:0efa6',target='sim:10b52'),
                scope='Complete active terrain records/order, pointer/count and 16 cache-control bytes at retained boundaries only; no claim about all consumers, runtime cache reuse or other gameplay state.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('original',type=Path);p.add_argument('captures',type=Path,nargs='+')
    p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.original,a.captures)
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Complete terrain records and cache controls match at',len(result['rows']),'boundaries across',len(a.captures),'schedules')
