"""Inventory h3 differences with exact, unchanged loader relocation bindings.

Only entries matching their original relocated value at every retained snapshot
are classified. Mutable pointers and all other bytes remain raw residuals.
This is not a complete simulation-state comparator or a proof of immutability.
"""
import argparse
import hashlib
import json
from pathlib import Path
from game_heap import segments
from hunks import read_hunks
from player_links import SIM_SHA
from prelude_state import check as prelude_check
from render_mutations import Snapshot, region, spans
from world_comparison import load


def classify(original, relocations, bases, sequences):
    if len(bases)!=2 or len(sequences)!=2 or not sequences[0] or len(sequences[0])!=len(sequences[1]):
        raise ValueError('Requires two nonempty matched checkpoint sequences')
    size=len(original)
    if any(len(raw)!=size for sequence in sequences for raw in sequence):
        raise ValueError('Incomplete global segment')
    occupied=set();bound=[];mutable=[]
    for at,target in relocations:
        covered=set(range(at,at+4))
        if at<0 or at%2 or at+4>size or occupied&covered or any(not 0<=target<len(b) for b in bases):
            raise ValueError('Invalid or overlapping relocation')
        occupied|=covered
        addend=int.from_bytes(original[at:at+4],'big')
        expected=[(b[target]+addend)&0xffffffff for b in bases]
        good=all(all(int.from_bytes(raw[at:at+4],'big')==value for raw in seq)
                 for value,seq in zip(expected,sequences))
        entry=dict(offset=at,target_segment=target,original_addend=addend,expected=expected)
        (bound if good else mutable).append(entry)
    classified={i for entry in bound for i in range(entry['offset'],entry['offset']+4)}
    rows=[];union=set()
    for index,(left,right) in enumerate(zip(*sequences)):
        changed={i for i,(a,b) in enumerate(zip(left,right)) if a!=b}
        residual=changed-classified;union|=residual
        # Retain the full raw comparison; these ranges are additional labels.
        marker=bytes(int(i in residual) for i in range(size))
        rows.append(dict(boundary='initial' if index==0 else index-1,
                         raw=region(left,right),relocation_changed_bytes=len(changed&classified),
                         residual_changed_bytes=len(residual),
                         residual_ranges=spans(bytes(size),marker)))
    return dict(segment_bytes=size,unchanged_relocations=bound,mutable_relocations=mutable,
                residual_union=sorted(union),rows=rows)


def check(original,left,right):
    binary=original.read_bytes()
    if hashlib.sha256(binary).hexdigest()!=SIM_SHA:raise ValueError('Unsupported sim executable')
    hunks=read_hunks(binary);roots=(left,right);loaded=[load(p) for p in roots]
    fixtures=[prelude_check(p) for p in roots]
    if len({x['sha256'] for x in fixtures})!=1:raise ValueError('Different frozen slaves')
    if any(m[0]['sim_sha256']!=SIM_SHA for m in loaded):raise ValueError('Different original sim')
    if [r['tick'] for r in fixtures[0]['rows']]!=[r['tick'] for r in fixtures[1]['rows']]:
        raise ValueError('Different world boundaries')
    sequences=[];bases=[]
    for root,m in zip(roots,loaded):
        raw=[];layout=None
        for banks in [m[2]['banks']]+[f['banks'] for f in m[1]['frames']]:
            ram=Snapshot(root,banks);current=segments(ram.read,m[0]['entry']['sim'])
            if current[3][0]!=m[1]['h3'] or current[3][1]!=hunks[3].allocation:
                raise ValueError('Unexpected global segment identity')
            if layout is not None and current!=layout:raise ValueError('Segments moved within capture')
            layout=current;raw.append(ram.read(current[3][0],current[3][1]))
        bases.append([p for p,n in layout]);sequences.append(raw)
    # The initialized DATA is shorter than its allocation. Padding only defines
    # the comparison extent; no uninitialized byte is treated as a binding.
    original_extent=hunks[3].data.ljust(hunks[3].allocation,b'\0')
    result=classify(original_extent,hunks[3].relocations,bases,sequences)
    result.update(sha256=fixtures[0]['sha256'],sim_sha256=SIM_SHA,
                  scope='Original loader relocation identity at all retained equal-tick snapshots only. Raw differences retained; mutable pointers and other globals remain residuals. No whole-gameplay or capacity acceptance.')
    return result


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for n in ('original','left','right'):p.add_argument(n,type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.original,a.left,a.right)
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Unchanged relocation bindings:',len(result['unchanged_relocations']),
          '; mutable:',len(result['mutable_relocations']),
          '; residual byte union:',len(result['residual_union']))
