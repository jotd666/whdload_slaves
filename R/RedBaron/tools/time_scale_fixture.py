#!/usr/bin/env python3
"""Copy a game installation and change only the saved Time Scale word for W0.

sim:47c8/47ce reads the 22-byte preferences block; sim:480e copies its first
word to h3:03d56. The remaining preference-file bytes are preserved verbatim.
The native Preferences route still sets detail and leaves this word alone.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil


def create(source, destination, value):
    if value not in (0, 40, 60):
        raise ValueError('W0 fixtures use Time Scale 0, 40 or 60')
    prefs = source / 'data/SIMPREFS.PRF'
    original = prefs.read_bytes()
    if len(original) < 22 or int.from_bytes(original[:2], 'big') != 40:
        raise ValueError('Expected original Time Scale 40 and a complete preferences block')
    # copytree refuses an existing destination. Never edit the source installation.
    shutil.copytree(source, destination)
    changed = value.to_bytes(2, 'big') + original[2:]
    (destination / 'data/SIMPREFS.PRF').write_bytes(changed)
    manifest = dict(time_scale=value, original_time_scale=40,
                    changed_offsets=[i for i, (a, b) in enumerate(zip(original, changed)) if a != b],
                    original_preferences_sha256=hashlib.sha256(original).hexdigest(),
                    preferences_sha256=hashlib.sha256(changed).hexdigest(),
                    sim_sha256=hashlib.sha256((destination/'data/sim').read_bytes()).hexdigest())
    (destination/'time-scale-fixture.json').write_text(json.dumps(manifest, indent=2)+'\n')
    return manifest


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('source', type=Path)
    p.add_argument('destination', type=Path)
    p.add_argument('--value', required=True, type=int)
    a = p.parse_args()
    print(json.dumps(create(a.source, a.destination, a.value), indent=2))


if __name__ == '__main__':
    main()
