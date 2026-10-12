#!/usr/bin/env python3
"""Check PAL framebuffer writes against actual bitplane fetches in a Barto trace.

Requires the two live 40,000-byte framebuffer bases, not guessed allocation bounds.
Reports missing blitter observability explicitly. No finding generalizes beyond
this trace. Publication positions come from matched CPU DMA writes in frames.py.
"""
import argparse
import json
import struct
from collections import Counter
from pathlib import Path
import barto
import frames


def previous_display(shown, field, line):
    # Before copper pickup, this field's fetches already use the newly published
    # buffer. The old display is the previous field's fetch source.
    index = field - (line < 42)
    return shown[index] if index >= 0 else []


def analyse(path, sim, buffers):
    if len(buffers) != 2 or abs(buffers[1]-buffers[0]) < 40000:
        raise ValueError('Require two non-overlapping framebuffer allocations')
    trace = barto.load(path)
    counts = Counter()
    writes, shown, conflicts = [], [], []
    unmapped_fetches = 0
    for field in trace.fields:
        if field.dma_size != 58 or len(field.dma)//58 != 313*227:
            raise ValueError('Expected Barto 58-byte DMA records and 313-line PAL fields')
        visible = set()
        last_fetch = {}
        field_writes = []
        for slot in range(len(field.dma)//58):
            i = slot*58
            kind = field.dma[i+29]
            reg = struct.unpack_from('<H', field.dma, i)[0]
            addr = struct.unpack_from('<I', field.dma, i+12)[0]
            counts[kind] += 1
            if kind == 6 and not any(base <= addr < base+40000 for base in buffers):
                unmapped_fetches += 1
            for role, base in enumerate(buffers):
                if not base <= addr < base+40000:
                    continue
                if kind == 6:
                    visible.add(role)
                    last_fetch[addr] = slot
            destinations = ([addr] if kind == 5 and reg == 0 else
                            [a for a, _ in frames.cpu_write_words(field.dma, i)])
            for destination in destinations:
                for role, base in enumerate(buffers):
                    if base <= destination < base+40000:
                        field_writes.append(dict(field=field.index, line=slot//227,
                            hpos=slot%227, role=role, kind=kind, offset=destination-base))
        shown.append(sorted(visible))
        writes.extend(field_writes)
        for w in field_writes:
            if w['role'] in visible and 42 <= w['line'] <= 243:
                address = buffers[w['role']] + w['offset']
                w['fetched_later_in_field'] = (last_fetch.get(address, -1) >
                                              w['line']*227 + w['hpos'])
                conflicts.append(w)
    observable = (counts[5] > 0 and any(w['kind'] == 5 for w in writes)
                  and all(len(s) == 1 for s in shown))
    swaps = frames.analyse([path], sim)['swaps']
    first_writes = []
    for swap in swaps:
        if not swap['dma_complete']:
            first_writes.append(dict(swap=swap, incomplete=True))
            continue
        q = swap['last_write']
        pos = (q['field'], q['line'], q['hpos'])
        old = previous_display(shown, q['field'], q['line'])
        first = next((w for w in writes if w['role'] in old and
                      (w['field'], w['line'], w['hpos']) > pos), None)
        gap = None if first is None else (
            (first['field']-q['field'])*313*227 +
            (first['line']-q['line'])*227 + first['hpos']-q['hpos'])/(313*227)
        first_writes.append(dict(swap=swap, old_display_roles=old,
                                 first_write=first, gap_fields=gap))
    return dict(buffers=buffers, fields=len(trace.fields), dma_types=dict(counts),
                observable=observable, framebuffer_writes=len(writes), shown=shown,
                unmapped_bitplane_fetches=unmapped_fetches,
                active_display_conflicts=conflicts,
                conflicts_fetched_later=sum(w["fetched_later_in_field"] for w in conflicts),
                swap_first_writes=first_writes,
                scope='Only this recorded window; absence of blitter writes is unobservable.')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('trace', type=Path)
    p.add_argument('--sim', required=True, type=lambda x: int(x, 0))
    p.add_argument('--buffers', required=True, help='First:second live buffer bases')
    p.add_argument('--out', required=True, type=Path)
    a = p.parse_args()
    result = analyse(a.trace, a.sim, [int(x, 0) for x in a.buffers.split(':')])
    a.out.write_text(json.dumps(result, indent=2)+'\n')
    print(dict(observable=result['observable'], writes=result['framebuffer_writes'],
               conflicts=len(result['active_display_conflicts'])))


if __name__ == '__main__':
    main()
