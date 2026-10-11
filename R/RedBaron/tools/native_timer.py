"""Model the original CIA timer used by sound at h3:03f5a.

This checks the observed timer stores. It does not normalize raw state, prove
all consumers, or certify sound-event delivery or gameplay independence.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
from hunks import read_hunks
from render_mutations import Snapshot

MASK = 0xffffffff


def arm(now, delay):
    return now & MASK, delay & 0xffff


def expire(now):
    return (now-1) & MASK, 0


def elapsed(now, start, delay, enabled=True):
    """Native low-word Boolean: strict unsigned comparison, not >=."""
    return int(not enabled or ((now-start) & MASK) > (delay & 0xffff))


def observations(events):
    rows = []
    pending = None
    for label, values in events:
        if len(values) != 5 or any(not 0 <= n <= MASK for n in values):
            raise ValueError('Malformed native timer observation')
        kind, phase = label.rsplit('_', 1)
        if kind not in ('ARM', 'EXPIRE'):
            raise ValueError('Unknown native timer operation')
        if phase == 'BEFORE':
            if pending is not None:
                raise ValueError('Nested or missing timer result')
            pending = kind, values
            continue
        if phase != 'AFTER' or pending is None or pending[0] != kind:
            raise ValueError('Unmatched native timer result')
        _, before = pending; pending = None
        tick, clock, start, delay, argument = before
        if values[0] != tick or values[4] != argument:
            raise ValueError('Timer call crossed a world step or changed its saved argument')
        expected = arm(clock, argument) if kind == 'ARM' else expire(clock)
        stable = clock == values[1]
        if stable and tuple(values[2:4]) != expected:
            raise ValueError('Native timer write differs from CIA model')
        rows.append(dict(kind=kind, tick=tick, cia_before=clock, cia_after=values[1],
                         observed=values[2:4], verified=stable,
                         reason=None if stable else 'CIA changed across the observed operation; exact store value unverified.'))
    if pending is not None or not rows or not any(r['verified'] for r in rows):
        raise ValueError('Incomplete timer capture or no verified operation')
    return rows


def check(original, root):
    raw = original.read_bytes(); code = read_hunks(raw)[0].data
    digest = hashlib.sha256(code[0x2972c:0x29796]).hexdigest()
    if digest != '977cf8941f9fbf64dd861ebf887fcc2f45cac5545de30333e432662ea040dc49':
        raise ValueError('Unsupported original CIA timer routines')
    entry = json.loads((root/'entry.json').read_text())
    poses = json.loads((root/'poses.json').read_text())
    if entry['slave_sha256'] != poses['sha256']:
        raise ValueError('Capture build mismatch')
    events = []
    checkpoints = []
    last_store = None
    for frame in poses['frames']:
        text = (root/f'pose-{frame["index"]}-events.txt').read_text()
        current = [(label, list(map(int, values.split()))) for label, values in
                   re.findall(r'^TIMER_(ARM_BEFORE|ARM_AFTER|EXPIRE_BEFORE|EXPIRE_AFTER) ([0-9 ]+)$', text, re.M)]
        events += current
        for label, values in current:
            if label.endswith('_AFTER') and len(values) == 5:
                last_store = values[2:4]
        if last_store is None:
            raise ValueError('No observed store seeds this checkpoint')
        ram = Snapshot(root, frame['banks'])
        timer = ram.read(poses['h3']+0x3f5a, 6)
        actual = [int.from_bytes(timer[:4], 'big'), int.from_bytes(timer[4:], 'big')]
        if actual != last_store:
            raise ValueError('Checkpoint timer differs from the last observed store')
        checkpoints.append(dict(index=frame['index'], timer=actual))
    rows = observations(events)
    return dict(sha256=poses['sha256'], sim_sha256=hashlib.sha256(raw).hexdigest(),
                routine_sha256=digest, timer='h3:03f5a', rows=rows, checkpoints=checkpoints,
                verified=sum(r['verified'] for r in rows), unverified=sum(not r['verified'] for r in rows),
                scope='Observed timer stores only; no complete consumer or audio-event acceptance.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('original', type=Path); p.add_argument('capture', type=Path)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args(); result = check(a.original, a.capture)
    a.out.write_text(json.dumps(result, indent=2)+'\n'); print(result)
