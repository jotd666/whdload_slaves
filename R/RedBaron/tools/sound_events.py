#!/usr/bin/env python3
"""Extract ordered Paula writes/audio fetches from one uninterrupted Barto chunk.

Compare matching service windows only. Equal lists are supporting observations,
not proof of sound equivalence; differing wall-time windows may contain different
numbers of ticks. Never silently concatenate chunks across their lost field.
"""
import argparse
import json
import struct
from collections import defaultdict
from pathlib import Path
import barto
from frames import cpu_write_words

REGISTERS = {0x96: 'DMACON', 0x9a: 'INTENA', 0x9c: 'INTREQ', 0x9e: 'ADKCON'}
for channel in range(4):
    for offset, name in ((0, 'LCH'), (2, 'LCL'), (4, 'LEN'), (6, 'PER'), (8, 'VOL'), (10, 'DAT')):
        REGISTERS[0xa0 + 16*channel + offset] = f'AUD{channel}{name}'


def decode_fields(fields):
    writes, fetches = defaultdict(list), defaultdict(list)
    count = 0
    for field in fields:
        if field.dma_size != 58 or len(field.dma) % 58:
            raise ValueError('Expected complete 58-byte DMA records')
        count += 1
        for at in range(0, len(field.dma), 58):
            for address, value in cpu_write_words(field.dma, at):
                reg = address - 0xdff000
                if reg in REGISTERS:
                    writes[REGISTERS[reg]].append(value)
            if field.dma[at+29] == 4:
                reg, value = struct.unpack_from('<HH', field.dma, at)
                if reg not in (0xaa, 0xba, 0xca, 0xda):
                    raise ValueError(f'Unexpected audio-fetch register {reg:#x}')
                fetches[f'AUD{(reg-0xaa)//16}DAT'].append(value)
    return dict(fields=count, writes=dict(writes), fetches=dict(fetches))


def compare(left, right):
    differences = []
    for category in ('writes', 'fetches'):
        for key in sorted(left[category].keys() | right[category].keys()):
            a, b = left[category].get(key, []), right[category].get(key, [])
            if a != b:
                first = next((i for i, (x, y) in enumerate(zip(a, b)) if x != y), min(len(a), len(b)))
                differences.append(dict(category=category, register=key, first_difference=first,
                                        left_count=len(a), right_count=len(b)))
    return differences


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('trace', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--compare', type=Path, help='Previously extracted, service-aligned JSON')
    args = parser.parse_args()
    result = decode_fields(barto.load(args.trace).fields)
    args.out.write_text(json.dumps(result, indent=2) + '\n')
    print({k: {name: len(v) for name, v in result[k].items()} for k in ('writes', 'fetches')})
    if args.compare:
        differences = compare(json.loads(args.compare.read_text()), result)
        print(json.dumps(differences, indent=2))
        raise SystemExit(bool(differences))
