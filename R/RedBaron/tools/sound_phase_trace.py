"""Locate known native sound phase accesses in retained traces, including IRQs.

This is a consumer/delivery investigation, not a sound equality mask. It does
not infer memory values from a chunk's earlier snapshot or ignore unknown slots.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import barto
from game_heap import allocations, exact, segments
from hunks import read_hunks
from player_links import SIM_SHA
from render_mutations import Snapshot

SITES = {
    0x33942: ('assign', '11400169'),
    0x339c2: ('assign', '11400169'),
    0x33bf6: ('resume', '0228007f0169'),
    0x33c2c: ('resume', '0228007f0169'),
    0x3405a: ('test', '0c2800000169'),
    0x34066: ('read', '10280169'),
    0x34dfc: ('test', '0c2800000169'),
    0x34e7e: ('test', '0c2800000169'),
    0x34ea6: ('read', '10280169'),
    0x34ec0: ('test', '0c2800100169'),
    0x34ed0: ('start', '002800800169'),
    0x34f5e: ('clear', '117c00000169'),
}


def event(offset, regs, owners, irq_page):
    kind, _ = SITES[offset]
    address = regs[8]
    if address not in owners:
        raise ValueError('Sound phase access has an unowned slot')
    result = dict(site=offset, kind=kind, slot=owners[address],
                  interrupt=irq_page <= regs[15] < irq_page + 4096)
    # Only MOVE's source register gives an actual value here. OR/AND need
    # live memory, which the earlier chunk snapshot cannot supply.
    if kind == 'assign':
        result['assigned'] = regs[0] & 255
    elif kind == 'clear':
        result['assigned'] = 0
    return result


def check(original, root):
    raw = original.read_bytes()
    if hashlib.sha256(raw).hexdigest() != SIM_SHA:
        raise ValueError('Unsupported original sim')
    code = read_hunks(raw)[0].data
    for at, (_, value) in SITES.items():
        if code[at:at + len(bytes.fromhex(value))] != bytes.fromhex(value):
            raise ValueError(f'Changed original sound phase contract {at:x}')
    entry = json.loads((root / 'entry.json').read_text())
    manifest = json.loads((root / 'capacity.json').read_text())
    digest = hashlib.sha256((root / 'slave.slave').read_bytes()).hexdigest()
    if {entry['slave_sha256'], manifest['sha256']} != {digest} or entry['sim_sha256'] != SIM_SHA:
        raise ValueError('Different capture executable')
    sim = entry['entry']['sim']; rows = []; chunks = []
    for chunk in manifest['chunks']:
        directory = root / chunk['path']
        banks = [dict(file=p.name, base=int(p.stem.split('-')[1], 16), size=p.stat().st_size)
                 for p in directory.glob('memory-*.bin')]
        ram = Snapshot(directory, banks); h3 = segments(ram.read, sim)[3][0]
        sizes = {base + 8: size - 8 for base, size in allocations(ram.read, h3)}
        owners = {}
        for slot in range(7):
            address = int.from_bytes(exact(ram.read, h3 + 0xa184 + slot * 4, 4), 'big')
            if sizes.get(address) != 384 or address in owners:
                raise ValueError('Sound slot is not a unique complete tracked allocation')
            if int.from_bytes(exact(ram.read, address + 12, 4), 'big') != address + 366:
                raise ValueError('Changed native sound self-pointer')
            owners[address] = slot
        for at, (_, value) in SITES.items():
            expected = bytes.fromhex(value)
            if exact(ram.read, sim + at, len(expected)) != expected:
                raise ValueError(f'Changed live sound phase contract {at:x}')
        trace = barto.load(directory / 'trace.bin')
        pages = {regs[15] & ~0xfff for field in trace.fields
                 for pc, _, regs in trace.instructions(field) if pc == sim + 0x2ffcc}
        if len(pages) != 1:
            raise ValueError('Ambiguous or missing native CIA interrupt stack')
        irq_page = pages.pop(); count = 0
        for field in trace.fields:
            for pc, _, regs in trace.instructions(field):
                if pc is None or pc - sim not in SITES:
                    continue
                item = event(pc - sim, regs, owners, irq_page)
                rows.append(dict(chunk=chunk['path'], field=field.index, **item)); count += 1
        chunks.append(dict(path=chunk['path'], fields=len(trace.fields), accesses=count))
    counts = Counter((r['site'], r['kind'], r['interrupt']) for r in rows)
    return dict(sha256=digest, sim_sha256=SIM_SHA, chunks=chunks, rows=rows,
                counts=[dict(site=at, kind=kind, interrupt=irq, count=n)
                        for (at, kind, irq), n in sorted(counts.items())],
                scope='Known native phase-byte access sites, with exact original/live opcodes and seven snapshot-owned sound slots. IRQ classification uses observed native CIA stack. No proof of slot lifetime between snapshots, unknown/indirect access absence, sound event equality, latency or gameplay independence. No state bytes masked.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('original', type=Path); p.add_argument('capture', type=Path)
    p.add_argument('--out', type=Path, required=True); a = p.parse_args()
    result = check(a.original, a.capture)
    a.out.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result['counts'], indent=2))
