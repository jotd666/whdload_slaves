"""Decode the bounded VERIFY allocation census; incomplete logs are not evidence."""
import struct

NAMES = ('size', 'flags', 'address', 'largest_fast', 'caller', 'step')


def decode(header, records):
    if len(header) != 44 or header[:8] != b'RBALLOC1':
        raise ValueError('Invalid allocation header')
    count, overflow, active, _, _, _, _, capacity, stride = struct.unpack('>9I', header[8:])
    if overflow or active or count > capacity or stride != 24:
        raise ValueError('Allocation census is incomplete or overflowed')
    if len(records) != count * stride:
        raise ValueError('Truncated allocation records')
    return [dict(zip(NAMES, row)) for row in struct.iter_unpack('>6I', records)]


def is_spill(row, chip_size=0x80000):
    return (row['flags'] != 0xffffffff and 0 < row['address'] < chip_size
            and not row['flags'] & 2 and row['largest_fast'] < row['size'])


def summarize(rows):
    live = {}
    peak = 0
    spills = []
    for row in rows:
        address = row['address']
        if row['flags'] == 0xffffffff:
            live.pop(address, None)
        elif address:
            if address in live:
                raise ValueError('Allocation reuses a live address: incomplete free history')
            live[address] = row
            if is_spill(row):
                spills.append(row)
            peak = max(peak, sum((r['size'] + 7) & ~7 for r in live.values() if is_spill(r)))
    return dict(records=len(rows), spill_requests=spills, peak_spill_bytes=peak,
                live_spill_bytes=sum(r['size'] for r in live.values() if is_spill(r)),
                live=list(live.values()))


if __name__ == '__main__':
    import argparse
    import json
    from pathlib import Path
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('header', type=Path)
    p.add_argument('records', type=Path)
    a = p.parse_args()
    print(json.dumps(summarize(decode(a.header.read_bytes(), a.records.read_bytes())), indent=2))
