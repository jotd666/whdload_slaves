"""Account for every retained field in consecutive W6 capacity windows.

Reports backlog instead of treating conserved credit as proof of real-time speed.
It does not generalize a finite scene/CPU run to full gameplay acceptance.
"""
import argparse
import json
from fractions import Fraction
from pathlib import Path
from field_capacity import check as windows_check
from game_time_core import THRESHOLD
from publication_clock import phase
from time_capacity import interval, MASK


def backlog(row):
    return (Fraction(((row['cia']-row['cursor']) & MASK)*1024, row['divisor']*225)
            + Fraction(phase(row), THRESHOLD) + row['due']
            + ((row['started']-row['completed']) & MASK))


def check(data):
    if len(data['windows']) < 4:
        raise ValueError('Need at least four consecutive 250-field windows')
    result = windows_check(data)
    start = data['windows'][0]['before']
    finish = data['windows'][-1]['after']
    accepted = [start]
    excluded = []
    sample_count = 0
    plateau = longest_plateau = 0
    previous_completed = start['completed']
    for window in data['windows']:
        samples = window['samples']
        if len(samples) != 250:
            raise ValueError('Missing per-field samples')
        if samples[-1] != window['after']:
            raise ValueError('Final field sample differs from window endpoint')
        for i, row in enumerate(samples, 1):
            sample_count += 1
            if row['completed'] == previous_completed:
                plateau += 1
                longest_plateau = max(longest_plateau, plateau)
            else:
                plateau = 0
            previous_completed = row['completed']
            if ((row['field']-window['before']['field']) & MASK) != i:
                raise ValueError('Nonconsecutive field samples')
            if row['compression'] or not row['active'] or row['paused'] != start['paused']:
                raise ValueError('Compression or modal transition in capacity run')
            if row['mask'] != start['mask'] or row['mask'] & 0x2300 != 0x2300:
                raise ValueError('Changed or incomplete W6 selection')
            if row['divisor'] != start['divisor']:
                raise ValueError('Time Scale changed')
            transaction = row['transaction']
            if transaction:
                if transaction not in (1, 2):
                    raise ValueError('Unknown clock transaction marker')
                excluded.append(dict(field=row['field'], transaction=transaction))
                continue
            interval(accepted[-1], row)
            accepted.append(row)
    if start['compression'] or start['transaction']:
        raise ValueError('Invalid first capacity boundary')
    if len(accepted) < 2:
        raise ValueError('No committed clock intervals')
    debt = [((r['cia']-r['cursor']) & MASK) for r in accepted]
    owed = [backlog(r) for r in accepted]
    total = interval(start, finish)
    expected_change = Fraction(total['elapsed_cia_ticks']*1024, start['divisor']*225)-total['completed_world_ticks']
    if owed[-1]-owed[0] != expected_change:
        raise ValueError('Backlog change does not match funded minus completed work')
    total.update(publications=sum(x['publications'] for x in result['windows']),
                 publication_fps=sum(x['publications'] for x in result['windows'])*50/total['elapsed_fields'],
                 completed_world_ticks_per_pal_second=total['completed_world_ticks']*50/total['elapsed_fields'])
    result.update(overall=total, field_samples=sample_count,
                  committed_intervals=len(accepted)-1, transaction_samples=excluded,
                  longest_sampled_no_completion_span_fields=longest_plateau,
                  cia_debt_range=[min(debt),max(debt)],
                  backlog_world_ticks=dict(before=float(owed[0]),after=float(owed[-1]),
                                           minimum=float(min(owed)),maximum=float(max(owed)),
                                           change=float(owed[-1]-owed[0])),
                  scope='Finite constant-rate scene/CPU capacity run. Transaction samples remain retained; no full gameplay or all-scene capacity verdict.')
    return result


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(json.loads(a.manifest.read_text()))
    a.out.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
