#!/usr/bin/env python3
"""Read the game's own player position/orientation history from a complete h3 dump.

sim:15128 receives the player object from sim:01102, advances h3:067c6 modulo
100, then copies object bytes 8..19 to h3:067cc and 20..25 to h3:06c7c.
Coordinates and angles are raw game values; physical units are not assumed.
"""
import argparse
import json
import struct
from pathlib import Path


def decode(raw, count=1):
    if len(raw) != 0xbd0c:
        raise ValueError('Expected the complete h3 allocation (0xbd0c bytes)')
    if not 1 <= count <= 100:
        raise ValueError('History count must be 1..100')
    latest = struct.unpack_from('>H', raw, 0x67c6)[0]
    if latest >= 100:
        raise ValueError('Invalid player-history index')
    rows = []
    for age in range(count - 1, -1, -1):
        slot = (latest - age) % 100
        rows.append(dict(age=age, slot=slot,
                         position=list(struct.unpack_from('>3i', raw, 0x67cc + 12 * slot)),
                         orientation=list(struct.unpack_from('>3h', raw, 0x6c7c + 6 * slot))))
    return dict(latest_slot=latest, records=rows,
                notice='Raw coordinates/angles. Caller must ensure requested history slots have been initialized.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('h3', type=Path)
    parser.add_argument('--count', type=int, default=1)
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    result = json.dumps(decode(args.h3.read_bytes(), args.count), indent=2) + '\n'
    if args.out:
        args.out.write_text(result)
    else:
        print(result, end='')


if __name__ == '__main__':
    main()
