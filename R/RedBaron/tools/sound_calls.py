#!/usr/bin/env python3
"""Check the volume byte model against complete ORIGINAL sound:0c10 calls.

--entry is the live sound:0028 code entry. Each profile chunk is independent;
incomplete calls at its ends are discarded. Input values come from the original
instructions after their loads, not from a guessed driver-memory snapshot.
"""
import argparse
import json
from pathlib import Path
import barto
from sound_model import volume, divide63


def check(paths, entry):
    rows = []
    for path in paths:
        pending = None
        trace = barto.load(path)
        for field in trace.fields:
            for pc, cycles, regs in trace.instructions(field):
                if pc is None: continue
                offset = pc - entry + 40
                if offset == 0xc10:
                    pending = dict(inputs=[0, 0, 0, 0, True], start_field=field.index, sp=regs[15])
                if pending is None: continue
                if offset == 0xc34:
                    pending['inputs'][:2] = [regs[3] & 255, regs[4] & 255]
                elif offset == 0xc62:
                    pending['inputs'][2] = regs[3] & 255
                elif offset == 0xc86:
                    pending['inputs'][3] = (regs[3] & 255) >> 2
                elif offset == 0xcb4:
                    pending['inputs'][4] = False
                elif offset == 0xcba:
                    if regs[15] != pending['sp'] - 16:
                        raise ValueError('Original volume stack does not match its prologue')
                    got = regs[4] & 255
                    for divide in (lambda n: n // 63, divide63):
                        expected = volume(*pending['inputs'], divide=divide)
                        if expected != got:
                            raise ValueError(f'Original volume mismatch: {pending}, expected {expected}, got {got}')
                    rows.append(dict(inputs=pending['inputs'], output=got, field=field.index))
                    pending = None
    if not rows: raise ValueError('No complete original volume calls observed')
    return dict(calls=len(rows), model_checks=2*len(rows), mismatches=0, rows=rows)


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('trace', nargs='+', type=Path)
    p.add_argument('--entry', required=True, type=lambda x: int(x, 0))
    p.add_argument('--out', required=True, type=Path)
    args = p.parse_args()
    result = check(args.trace, args.entry)
    args.out.write_text(json.dumps(result, indent=2)+'\n')
    print({k:v for k,v in result.items() if k != 'rows'})
