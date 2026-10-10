"""Decode W6 producer FIFO evidence without discarding overflow or extra events."""
import argparse
import json
import struct
from pathlib import Path


def decode(data):
    if len(data) != 16 + 256*16:
        raise ValueError('Unexpected native input FIFO size')
    head, tail, overflow, high_water = struct.unpack_from('>4H', data)
    count = (head-tail) & 0xffff
    if count > 256 or high_water > 256 or overflow not in (0, 1):
        raise ValueError('Invalid native input queue header')
    rows = []
    for sequence in range(tail, tail+count):
        fields = struct.unpack_from('>IHHII', data, 16+(sequence & 255)*16)
        rows.append(dict(zip(('eligible', 'code', 'value', 'payload0', 'payload1'), fields)))
    return dict(head=head, tail=tail, overflow=bool(overflow), high_water=high_water, events=rows)


def check_fixture(queue, fixture):
    result = decode(queue)
    if len(fixture) != 32 or result['overflow'] or len(result['events']) != 4:
        raise ValueError('Incomplete, overflowed or externally contaminated input capture')
    expected = []
    for at in range(0, 32, 8):
        stamp, code, value = struct.unpack_from('>IHH', fixture, at)
        expected.append(dict(eligible=(stamp+1) & 0xffffffff, code=code, value=value,
                             payload0=0, payload1=0))
    if [(e['code'], e['value']) for e in expected] != [(78,1),(78,0),(64,1),(64,0)]:
        raise ValueError('Unexpected decoded-key fixture sequence')
    if result['events'] != expected:
        raise ValueError('Producer event does not match its independently logged acquisition')
    return result


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('queue', type=Path)
    p.add_argument('--fixture', type=Path)
    args = p.parse_args()
    result = check_fixture(args.queue.read_bytes(), args.fixture.read_bytes()) if args.fixture else decode(args.queue.read_bytes())
    print(json.dumps(result, indent=2))
