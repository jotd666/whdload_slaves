#!/usr/bin/env python3
"""Summarize read-only routine-clock logs after checking VBlank counter phase.

Costs run from entry to immediately before RTS and include interrupts. They are
not main-only CPU cycles. Conservative phase exclusions remain in the report.
"""
import argparse
import json
import statistics
from pathlib import Path


def summarize(log, first, last, rate=49.92041):
    if not log.get('complete') or first > last or rate <= 0:
        raise ValueError('Require a completed capture and valid interval/rate')
    phase = log['vblank_phase']
    if len(phase) < 2 or any(b['vbl'] != a['vbl'] + 1 for a, b in zip(phase, phase[1:])):
        raise ValueError('VBlank phase observations must be consecutive')
    known = {p['vbl'] for p in phase}
    threshold = max(p['line'] for p in phase) + 1
    if not 0 < threshold < 313:
        raise ValueError('Invalid VBlank counter phase')
    accepted, excluded = [], []
    for call in log['calls']:
        a, b = call['entry'], call['return_record']
        if not first <= a['step'] <= last:
            continue
        if a['step'] != b['step'] or a['sp'] != b['sp']:
            raise ValueError('Call crosses a step or does not restore SP')
        if any(not 0 <= r['line'] < 313 or not 0 <= r['hpos'] < 227 for r in [a, b]):
            raise ValueError('Invalid PAL beam position')
        if any(r['vbl'] not in known or r['line'] < threshold for r in [a, b]):
            excluded.append(dict(routine=call['routine'], step=a['step'], reason='Unverified/ambiguous counter phase'))
            continue
        # A captured VHPOSR read at horizontal zero can retain the preceding
        # vertical count. Do not invent a line increment to repair that sample.
        # Exclude the boundary plus one slot of margin at either endpoint.
        if any(r['hpos'] <= 1 for r in [a, b]):
            excluded.append(dict(routine=call['routine'], step=a['step'], reason='Ambiguous horizontal-counter boundary'))
            continue
        slots = (b['vbl']-a['vbl'])*313*227 + (b['line']-a['line'])*227 + b['hpos']-a['hpos']
        if slots <= 0:
            raise ValueError('Nonpositive whole-call duration')
        accepted.append(dict(routine=call['routine'], step=a['step'], fields=slots/(313*227)))
    summaries = {}
    for name in sorted({c['routine'] for c in accepted}):
        values = [c['fields'] for c in accepted if c['routine'] == name]
        summaries[name] = dict(calls=len(values), mean_fields=statistics.mean(values),
            min_fields=min(values), max_fields=max(values), mean_ms=statistics.mean(values)*1000/rate)
    return dict(first_step=first, last_step=last, phase_observations=len(phase),
        phase_safe_from_line=threshold, summaries=summaries, accepted=accepted, excluded=excluded,
        scope='Inclusive wall time from entry to before RTS; not main-only CPU cycles or an FPS measurement.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('log', type=Path)
    p.add_argument('--first-step', type=int, required=True)
    p.add_argument('--last-step', type=int, required=True)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    result = summarize(json.loads(a.log.read_text()), a.first_step, a.last_step)
    a.out.write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result['summaries'], indent=2))
