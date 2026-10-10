#!/usr/bin/env python3
"""Complete rectangle/3D call costs; includes RTS, excludes chunk-cut calls.

Routine return does not imply completion of its asynchronous final plane.
Whole 3D-pass costs include subsequent waits. Full-width vs other rectangles
are classified by entry arguments; this is not a claim of equal pixel areas.
"""
import argparse
import json
from pathlib import Path
import barto
import call_costs


def measure(paths, sim):
    pages=set()
    for path in paths:
        trace=barto.load(path)
        for field in trace.fields:
            for pc,_,regs in trace.instructions(field):
                if pc==sim+0x2ffcc:pages.add(regs[15]&~0xfff)
    if len(pages)!=1:
        raise ValueError(f'Expected one observed timer interrupt stack page, got {pages}')
    low=next(iter(pages))
    result=call_costs.measure(paths,sim,low,low+4096,
        {'rectangle':(sim+0x2fc68,(sim+0x2fca4,sim+0x2fdfe))})
    def full(c):return (c['entry_d0']&65535)==0 and (c['entry_d2']&65535)==320
    for name,predicate in [('full_width',full),('other_rectangles',lambda c:not full(c))]:
        rows=[c for c in result['calls'] if c['routine']=='rectangle' and predicate(c)]
        if rows:result['summary'][name]=dict(completed_calls=len(rows),
            main_mean=sum(c['main_cycles'] for c in rows)/len(rows))
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('traces',type=Path,nargs='+')
    p.add_argument('--sim',type=lambda x:int(x,0),required=True)
    p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=measure(a.traces,a.sim)
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result['summary'],indent=2))

if __name__=='__main__':main()
