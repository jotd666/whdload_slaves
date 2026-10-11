"""Match native sound elapsed-counter instructions to retained CPU bus writes.

Each chunk stands alone. Leading increments before an observed reset are retained
but unverified. This does not normalize sound state or certify event delivery.
"""
import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import barto
from frames import cpu_write_words
from hunks import read_hunks

OPS = {0x33768: 'reset', 0x33b64: 'start', 0x34e9a: 'increment',
       0x34eca: 'reset', 0x34f44: 'reset', 0x34f96: 'increment'}
IRQ_OPS = {0x34e9a, 0x34eca, 0x34f44, 0x34f96}


def contract(raw):
    code = read_hunks(raw)[0].data
    expected = {
        0x33768: '317c00000158',
        0x33b5e: '90403140015631400158',
        0x33dd2: '3f0770007200302801583e3c0e1080c74840320048403e3c003c82c7484134014841e24a3e1f4e75',
        0x34e7e: '0c280000016966000006600000e80c280000016867000006600000da526801582468000c',
        0x34eca: '317c00000158',
        0x34f3a: '48400c40000067000008317c00000158',
        0x34f96: '52680158',
        0x35260: '3168015a0158',
        0x3581c: '31680158015a',
    }
    for offset, text in expected.items():
        value = bytes.fromhex(text)
        if code[offset:offset+len(value)] != value:
            raise ValueError(f'Changed sound-counter contract at sim:{offset:05x}')
    return dict(sim_sha256=hashlib.sha256(raw).hexdigest(), context_word=344,
                scope='Named original counter operations/query only; no complete alias or gameplay-consumer proof.')


def counter(events, writes):
    if not events or len(events) != len(writes):
        raise ValueError('Missing, extra or boundary-straddling counter writes')
    value = None
    verified = leading = resets = 0
    for event, write in zip(events, writes):
        if not 0 <= write['field']-event['field'] <= 1:
            raise ValueError('Counter instruction and bus write are not adjacent')
        observed = write['value']
        if not 0 <= observed <= 65535:
            raise ValueError('Counter write is not a word')
        kind = event['kind']
        if kind in ('reset', 'start'):
            value = 0
            resets += 1
        elif kind == 'increment':
            if value is not None:
                value = (value+1) & 65535
        else:
            raise ValueError('Unsupported counter operation')
        if value is None:
            leading += 1
        else:
            if value != observed:
                raise ValueError('Counter bus value differs from reset/increment model')
            verified += 1
    if not verified:
        raise ValueError('No independently reset counter sequence observed')
    return dict(writes=len(writes), verified=verified, leading_unverified=leading,
                resets=resets, final_value=value)


def check(root, chunk):
    meta = json.loads((chunk/'before.json').read_text())
    irq = json.loads((root/'capacity-costs.json').read_text())['irq_stack']
    trace = barto.load(chunk/'trace.bin')
    events = defaultdict(list)
    operations = defaultdict(int)
    for field in trace.fields:
        for pc, cycles, regs in trace.instructions(field):
            if pc is None:
                continue
            offset = pc-meta['sim']
            if offset in (0x35260, 0x3581c):
                raise ValueError('Capture uses counter snapshot/restore; separate model required')
            if offset not in OPS:
                continue
            is_irq = irq[0] <= regs[15] < irq[1]
            if offset in IRQ_OPS and not is_irq:
                raise ValueError('Expected sound interrupt operation ran outside IRQ stack')
            if offset == 0x33b64 and regs[0] & 65535:
                raise ValueError('Sound start did not reset elapsed counter')
            events[regs[8]+344].append(dict(field=field.index, kind=OPS[offset]))
            operations[f'sim:{offset:05x}/'+('irq' if is_irq else 'main')] += 1
    writes = defaultdict(list)
    for field in trace.fields:
        if field.dma_size != 58 or len(field.dma) % 58:
            raise ValueError('Unsupported/incomplete bus records')
        for at in range(0, len(field.dma), 58):
            for address, value in cpu_write_words(field.dma, at):
                if address in events:
                    writes[address].append(dict(field=field.index, value=value))
    if not events:
        raise ValueError('No sound-counter operations')
    rows = [dict(context=address-344, **counter(seq, writes[address]))
            for address, seq in events.items()]
    return dict(sha256=json.loads((root/'entry.json').read_text())['slave_sha256'],
                chunk=chunk.name, fields=len(trace.fields), operations=dict(operations),
                contexts=rows, verified_writes=sum(r['verified'] for r in rows),
                leading_unverified=sum(r['leading_unverified'] for r in rows),
                limitation='Observed reset/increment writes only. No sound-event, gameplay-state or all-path equivalence claim.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('sim', type=Path)
    p.add_argument('capture', type=Path)
    p.add_argument('chunk')
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    result = dict(contract=contract(a.sim.read_bytes()), observed=check(a.capture, a.capture/a.chunk))
    a.out.write_text(json.dumps(result, indent=2)+'\n')
    print(result)
