#!/usr/bin/env python3
"""Complete original swap costs on uncached CPUs, excluding interrupted work.

Includes the original beam wait and RTS. Use actual swap censuses for FPS;
cached-CPU instruction totals are not timing evidence.
"""
import argparse
import json
from pathlib import Path
import barto
import call_costs


def measure(paths, sim):
    pages = set()
    for path in paths:
        trace = barto.load(path)
        for field in trace.fields:
            for pc, _, regs in trace.instructions(field):
                if pc == sim + 0x2ffcc:
                    pages.add(regs[15] & ~0xfff)
    if len(pages) != 1:
        raise ValueError(f'Expected one timer-interrupt stack page: {pages}')
    low = next(iter(pages))
    return call_costs.measure(paths, sim, low, low + 4096,
                             {'swap': (sim + 0x314be, sim + 0x31552)})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('traces', type=Path, nargs='+')
    parser.add_argument('--sim', type=lambda s: int(s, 0), required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    result = measure(args.traces, args.sim)
    args.out.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result['summary'], indent=2))


if __name__ == '__main__':
    main()
