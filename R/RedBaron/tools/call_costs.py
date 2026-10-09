#!/usr/bin/env python3
"""Measure complete original or replacement calls, separating the observed interrupt stack.

Explicit entry/RTS pairs avoid inferred call trees. Each file is a separate chunk:
open calls are discarded at joins. The interrupt-stack range must be established
from the capture, not copied from another build. KickEmu callbacks can run with
SR in user mode, so SR alone is not an interrupt-context classifier.
"""
import argparse
import json
from pathlib import Path
import barto

ROUTINES = {'mirror': (0x304d0, 0x30570), 'world3d': (0x2c552, 0x2c806),
            'world_step': (0x1098, 0x11c8)}


def measure(paths, sim, irq_low, irq_high, overrides=None):
    routines = {name: (sim+entry, sim+ret) for name, (entry, ret) in ROUTINES.items()}
    routines.update(overrides or {})
    result = dict(calls=[], incomplete=[], irq_stack=[irq_low, irq_high])
    for path in paths:
        trace = barto.load(path)
        active = {}
        for field in trace.fields:
            for pc, cycles, regs in trace.instructions(field):
                sp = regs[15]
                irq = irq_low <= sp < irq_high
                for name, (entry, ret) in routines.items():
                    if pc == entry:
                        if irq:
                            raise ValueError(f'{name} entry lies in the supplied interrupt stack')
                        if name in active:
                            raise ValueError(f'Unmatched/reentrant {name} entry')
                        active[name] = dict(routine=name, chunk=str(path), first_field=field.index,
                                            entry_sp=sp, main_cycles=0, irq_cycles=0,
                                            irq_entry_cycles=0, wall_cycles=0)
                for name, call in list(active.items()):
                    call['wall_cycles'] += cycles
                    if pc == 0x7fffffff:
                        call['irq_entry_cycles'] += cycles
                    elif irq:
                        call['irq_cycles'] += cycles
                    else:
                        # No traced call here uses more than 16 KB below its entry SP.
                        # Reject a new/unclassified stack instead of assigning it to main.
                        if not call['entry_sp'] - 0x4000 <= sp <= call['entry_sp']:
                            raise ValueError(f'Unexpected stack during {name}: {sp:#x}')
                        call['main_cycles'] += cycles
                    if pc == routines[name][1]:
                        if irq or sp != call['entry_sp']:
                            raise ValueError(f'{name} did not restore its entry stack')
                        call['last_field'] = field.index
                        result['calls'].append(call)
                        del active[name]
        result['incomplete'].extend(active.values())
    result['summary'] = {}
    for name in routines:
        rows = [x for x in result['calls'] if x['routine'] == name]
        if rows:
            result['summary'][name] = dict(completed_calls=len(rows),
                main_min=min(x['main_cycles'] for x in rows),
                main_max=max(x['main_cycles'] for x in rows),
                main_mean=sum(x['main_cycles'] for x in rows) / len(rows))
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('traces', nargs='+', type=Path)
    p.add_argument('--sim', required=True, type=lambda x: int(x, 0))
    p.add_argument('--irq-stack', required=True, help='LOW:HIGH, upper bound excluded')
    p.add_argument('--out', type=Path)
    p.add_argument('--routine', action='append', default=[], metavar='NAME:ENTRY:RTS',
                   help='Override/add a routine using absolute live entry and RTS PCs')
    a = p.parse_args()
    low, high = (int(x, 0) for x in a.irq_stack.split(':'))
    if low >= high:
        p.error('Interrupt stack must be a nonempty range')
    overrides = {}
    for spec in a.routine:
        name, entry, ret = spec.split(':')
        if name in overrides:
            p.error('Duplicate routine override')
        overrides[name] = (int(entry, 0), int(ret, 0))
    result = measure(a.traces, a.sim, low, high, overrides)
    if a.out:
        a.out.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result['summary'], indent=2))


if __name__ == '__main__':
    main()
