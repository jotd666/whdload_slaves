"""Exact pixel-model dependency snapshots; not a complete native cache key.

Keep input identity and bytes, not just a collision-prone digest. Native helper
side effects, return state and complete read-path coverage remain separate gates.
"""
import argparse
import hashlib
import json
from pathlib import Path
from cockpit_raster import render,audit as raster_audit
from render_mutations import Snapshot


def dependencies(read,h3,program):
    observed={}
    order=[]
    def tracked(address,size):
        data=read(address,size)
        if len(data)!=size:raise ValueError('Truncated dependency read')
        for offset,value in enumerate(data,address):
            if offset in observed and observed[offset]!=value:
                raise ValueError('Dependency changed during snapshot')
            if offset not in observed:order.append(offset)
            observed[offset]=value
        return data
    render(tracked,h3,program,bytes(40000))
    ranges=[];start=None;values=bytearray()
    # Preserve the first-read dependency order. Sorting addresses could read
    # a stale resource before its changed selecting pointer invalidates the key.
    for address in order:
        value=observed[address]
        if start is None or address!=start+len(values):
            if start is not None:ranges.append((start,bytes(values)))
            start=address;values=bytearray()
        values.append(value)
    if start is not None:ranges.append((start,bytes(values)))
    return (program,tuple(ranges))


def matches(key,read,program):
    # Compare in original dependency order: selecting pointers/program bytes
    # precede their dependent reads. Resource lifetime without a changed selector
    # still requires a separate invalidation contract.
    if key[0]!=program:return False
    try:return all(read(address,len(value))==value for address,value in key[1])
    except (ValueError,IndexError):return False


def check(path):
    raster_audit(path)
    root=path.parent;meta=json.loads(path.read_text());seeds={};rows=[]
    for frame in meta['frames']:
        before=Snapshot(root,frame['before']['banks']);program=frame['before']['program']
        key=dependencies(before.read,meta['h3'],program)
        if program not in seeds:seeds[program]=key
        same=matches(seeds[program],before.read,program)
        rebuilt_same=key==seeds[program]
        if same!=rebuilt_same:raise ValueError('Direct guard differs from reconstructed dependency snapshot')
        rows.append(dict(program=program,ranges=len(key[1]),bytes=sum(len(v) for _,v in key[1]),
                         seed_matches=same,diagnostic_digest=hashlib.sha256(repr(key).encode()).hexdigest()))
    return dict(sha256=meta['sha256'],cases=rows,
                scope='Exact model-read dependency guard only. No proof of complete native dependencies, runtime guard, invalidation transitions, speed or W6 acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.capture);a.out.write_text(json.dumps(result,indent=2)+'\n');print(result)
