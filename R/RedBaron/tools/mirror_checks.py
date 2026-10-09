#!/usr/bin/env python3
"""Read W1a VERIFY check counters from a retained RAM dump (no target writes).
A completed synthetic run is required; timing captures must keep CUSTOM5 bit 5 off.
"""
import argparse
import json
import struct
from pathlib import Path


def read_checks(data):
    matches = []
    start = 0
    while (at := data.find(b'RBMIRR01', start)) >= 0:
        start = at + 8
        if at + 24 > len(data):
            continue
        version, words, twins, synthetic = struct.unpack_from('>4I', data, at+8)
        if version == 1 and words == 65536 and synthetic == 64 and twins >= synthetic:
            matches.append(dict(word_checks=words, synthetic_twins=synthetic,
                                live_twins=twins-synthetic, total_twins=twins))
    if len(matches) != 1:
        raise ValueError(f'Expected one completed live W1a check record; got {len(matches)}')
    return matches[0]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('dump', type=Path)
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    result = read_checks(args.dump.read_bytes())
    text = json.dumps(result, indent=2)+'\n'
    if args.out:
        args.out.write_text(text)
    print(text, end='')


if __name__ == '__main__':
    main()
