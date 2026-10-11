"""Exact-content inventory of tracked payloads, not an object-identity proof.

Equal payload bytes may belong to different objects. Duplicate-content groups
retain all addresses and multiplicities; no arbitrary pairing or normalization.
"""
import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
from game_heap import allocations,exact
from prelude_state import check as prelude_check
from render_mutations import Snapshot
from world_comparison import load


def inventory(left,right):
    groups=[]
    for side in (left,right):
        grouped=defaultdict(list)
        for address,data in side.items():grouped[data].append(address)
        groups.append(grouped)
    rows=[]
    for data in sorted(set(groups[0])|set(groups[1]),key=lambda v:(len(v),v)):
        a=sorted(groups[0].get(data,[]));b=sorted(groups[1].get(data,[]));shared=min(len(a),len(b))
        rows.append(dict(size=len(data),diagnostic_sha256=hashlib.sha256(data).hexdigest(),
                         left_addresses=a,right_addresses=b,shared_content_count=shared,
                         left_excess=len(a)-shared,right_excess=len(b)-shared,
                         ambiguous_identity=bool(shared and (len(a)>1 or len(b)>1))))
    return dict(left_count=len(left),right_count=len(right),
                shared_content_count=sum(r['shared_content_count'] for r in rows),
                shared_content_bytes=sum(r['size']*r['shared_content_count'] for r in rows),
                left_excess=sum(r['left_excess'] for r in rows),right_excess=sum(r['right_excess'] for r in rows),groups=rows)


def check(left,right):
    roots=(left,right);loaded=[load(p) for p in roots];verified=[prelude_check(p) for p in roots]
    if len({v['sha256'] for v in verified})!=1:raise ValueError('Different frozen builds')
    if loaded[0][0]['sim_sha256']!=loaded[1][0]['sim_sha256']:raise ValueError('Different original executables')
    sequences=[[m[2]['banks']]+[f['banks'] for f in m[1]['frames']] for m in loaded]
    if len(sequences[0])!=len(sequences[1]):raise ValueError('Unequal checkpoint counts')
    rows=[]
    for index,banks in enumerate(zip(*sequences)):
        payloads=[]
        for root,m,b in zip(roots,loaded,banks):
            ram=Snapshot(root,b)
            payloads.append({a+8:exact(ram.read,a+8,n-8) for a,n in allocations(ram.read,m[1]['h3'])})
        row=inventory(*payloads);row['boundary']='initial' if not index else index-1;rows.append(row)
    return dict(sha256=verified[0]['sha256'],rows=rows,
                scope='Exact byte-content multiset inventory of tracked payloads only. Matching uses bytes, not digests. No object identity, cross-links, header equivalence, lifetime, complete gameplay or capacity conclusion.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('left',type=Path);p.add_argument('right',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();r=check(a.left,a.right);a.out.write_text(json.dumps(r,indent=2)+'\n')
    print('Inventoried',len(r['rows']),'checkpoints; content matching does not prove identity')
