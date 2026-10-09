#!/usr/bin/env python3
"""Measure an explicit swap-to-swap interval in a flight-only dashboard census.

The starting swap is a boundary, not a completed interval. Attribute rendering
work to steps start+1 through end, and use swap clocks rather than the subsequent
input observer. This avoids off-by-one frames and swap-to-input clock drift.
"""
import argparse
import collections
import json
from pathlib import Path


def summarize(census, start, end, rate=49.92041):
    if not census.get('segment_complete'):
        raise ValueError('Census has an incomplete segment')
    if not 0 <= start < end or rate <= 0:
        raise ValueError('Require increasing steps and a positive field rate')
    swaps = [e for e in census['events']
             if e['kind'] == 'swap' and start <= e['step'] <= end]
    if [e['step'] for e in swaps] != list(range(start, end + 1)):
        raise ValueError('Missing, duplicate or unordered swap in requested window')
    if any(a['vbl'] > b['vbl'] or a['ticks'] > b['ticks']
           for a, b in zip(swaps, swaps[1:])):
        raise ValueError('Swap clocks run backwards')
    fields = swaps[-1]['vbl'] - swaps[0]['vbl']
    if fields <= 0:
        raise ValueError('Window has no elapsed fields')
    records = [r for r in census['records'] if start < r['step'] <= end]
    if [r['step'] for r in records] != list(range(start + 1, end + 1)):
        raise ValueError('Missing, duplicate or unordered step record')
    counts = dict(collections.Counter(e['kind'] for e in census['events']
                                     if start < e['step'] <= end))
    return dict(start_swap=start, end_swap=end, completed_intervals=end-start,
                elapsed_fields=fields, elapsed_ticks=swaps[-1]['ticks']-swaps[0]['ticks'],
                field_rate=rate, fps=(end-start)*rate/fields,
                meets_2000_fields=fields >= 2000, event_counts=counts,
                mirror_free=counts.get('mirror', 0) == 0,
                dt_values=sorted({r['dt'] for r in records}))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('census', type=Path)
    p.add_argument('--start', required=True, type=int)
    p.add_argument('--end', required=True, type=int)
    p.add_argument('--out', type=Path)
    a = p.parse_args()
    result = summarize(json.loads(a.census.read_text()), a.start, a.end)
    text = json.dumps(result, indent=2) + '\n'
    if a.out:
        a.out.write_text(text)
    print(text, end='')


if __name__ == '__main__':
    main()
