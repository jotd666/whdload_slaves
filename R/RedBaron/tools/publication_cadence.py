"""Check every PAL-field publication deadline, rather than accepting mean FPS.

A passing cadence does not prove changing pixels, interpolation correctness,
input latency or simulation speed. Those remain separate W6 acceptance gates.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
from field_capacity import check as capacity_check
from pacing_model import MASK


def cadence(start, fields, publications):
    if type(fields) is not int or not 0 < fields < 1 << 31:
        raise ValueError('Invalid cadence observation extent')
    offsets = [(row['field'] - start) & MASK for row in publications]
    if any(n > fields for n in offsets):
        raise ValueError('Publication outside cadence observation')
    if any(b <= a for a, b in zip(offsets, offsets[1:])):
        raise ValueError('Repeated or out-of-order publication across windows')
    # Offset zero belongs to the initial boundary's already-started field.
    # Keep it in the report but do not use it to cover a later deadline.
    observed = set(offsets)
    missing = [i for i in range(1, fields + 1) if i not in observed]
    gaps = Counter(b - a for a, b in zip(offsets, offsets[1:]))
    return dict(fields=fields, publications=len(offsets),
                initial_boundary_publication=0 in observed,
                covered_field_deadlines=fields - len(missing),
                missing_field_offsets=missing,
                interval_fields={str(k): v for k, v in sorted(gaps.items())},
                every_field_published=not missing,
                scope='Native publication at every observed PAL field deadline, including leading/trailing gaps and cross-window boundaries. Not fresh-pixel, interpolation, input-latency or gameplay-speed acceptance.')


def check(data):
    result = capacity_check(data)
    windows = data['windows']
    start = windows[0]['before']['field']
    fields = (windows[-1]['after']['field'] - start) & MASK
    if fields != 250 * len(windows):
        raise ValueError('Cadence windows do not cover a continuous field extent')
    report = cadence(start, fields, [p for w in windows for p in w['publications']])
    report['sha256'] = result['sha256']
    return report


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest', type=Path); p.add_argument('--out', type=Path, required=True)
    a = p.parse_args(); result = check(json.loads(a.manifest.read_text()))
    a.out.write_text(json.dumps(result, indent=2) + '\n')
    print({k: v for k, v in result.items() if k != 'missing_field_offsets'})
