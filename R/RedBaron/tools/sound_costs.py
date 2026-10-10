#!/usr/bin/env python3
"""Completed L6 sound calls, excluding chunks and any higher-interrupt preemption.

Report routine CPU cycles, not FPS. Queue pending-count and volume inputs allow
like-for-like comparisons. This is intended for 68000/020 instruction traces;
use beam-clock observations for the cached 030.
"""
import argparse
import json
from collections import defaultdict
from pathlib import Path
import barto


def measure(paths, sim, driver, queue_return=None):
    base = driver - 40
    routines = {'queue': (sim+0x34d26, {sim+0x34d94}),
                'volume': (base+0xc10, {base+0xcc8}),
                'sequencer': (sim+0x34d96, {sim+0x34da2, sim+0x34e52})}
    if queue_return is not None: routines['queue'][1].add(queue_return)
    rows, incomplete = [], 0
    for path in paths:
        trace = barto.load(path)
        active = {}
        for field in trace.fields:
            for pc, cycles, regs in trace.instructions(field):
                for name, (entry, returns) in routines.items():
                    if pc == entry:
                        if name in active: raise ValueError('Unexpected reentrant sound call')
                        active[name] = dict(routine=name, cycles=0, sp=regs[15], pending=0,
                                            volume_calls=0, inputs=[0,0,0,0,True], preemptions=0)
                        if name == 'volume' and 'sequencer' in active:
                            active['sequencer']['volume_calls'] += 1
                if 'queue' in active and pc == sim+0x34d4c: active['queue']['pending'] += 1
                if 'volume' in active:
                    args = active['volume']['inputs']
                    if pc == base+0xc34: args[:2] = [regs[3]&255, regs[4]&255]
                    elif pc == base+0xc62: args[2] = regs[3]&255
                    elif pc == base+0xc86: args[3] = (regs[3]&255)>>2
                    elif pc == base+0xcb4: args[4] = False
                for name, row in list(active.items()):
                    row['cycles'] += cycles
                    if pc == 0x7fffffff: row['preemptions'] += 1
                    if pc in routines[name][1]:
                        if regs[15] != row['sp']: raise ValueError('Sound return stack mismatch')
                        rows.append(row);del active[name]
        incomplete += len(active)
    groups = defaultdict(list)
    for row in rows:
        if row['preemptions']: continue
        detail = (str(row['inputs']) if row['routine']=='volume' else
                  f"pending={row['pending']}" if row['routine']=='queue' else
                  f"volume_calls={row['volume_calls']}")
        groups[row['routine']+' '+detail].append(row['cycles'])
    summary = {key:dict(calls=len(v), mean=sum(v)/len(v), minimum=min(v), maximum=max(v))
               for key,v in sorted(groups.items())}
    return dict(summary=summary, calls=rows, cut_calls=incomplete,
                preempted_calls=sum(bool(r['preemptions']) for r in rows))


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('trace',nargs='+',type=Path)
    p.add_argument('--sim',required=True,type=lambda x:int(x,0))
    p.add_argument('--driver',required=True,type=lambda x:int(x,0))
    p.add_argument('--queue-return',type=lambda x:int(x,0))
    p.add_argument('--out',required=True,type=Path)
    a=p.parse_args();result=measure(a.trace,a.sim,a.driver,a.queue_return)
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result['summary'],indent=2))
