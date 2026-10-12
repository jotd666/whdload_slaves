"""FC1 acceptance over compact beam/DMA and publication evidence.

This checks the bounded recorded window only. The DMA reader establishes the
actual displayed page independently of CPU instruction traces; publication
cadence uses the external native-swap brackets and retains the two-field cap.
"""
import argparse
import json
import re
from pathlib import Path
from publication_cadence import cadence


def check(display, raw, fields, *, pickup_guard=False):
    if not display['observable'] or display['fields'] < 10:
        raise ValueError('Insufficient observable display evidence')
    if any(len(pages) != 1 for pages in display['shown']):
        raise ValueError('Mixed or missing displayed page')
    if display.get('unmapped_bitplane_fetches') != 0:
        raise ValueError('Missing coverage or bitplane fetch outside both display pages')
    if display['active_display_conflicts']:
        raise ValueError('Write to a displayed page during active scanning')
    switches = sum(a != b for a, b in zip(display['shown'], display['shown'][1:]))
    if switches < 2:
        raise ValueError('No repeated page turnover in beam sample')
    samples = re.findall(r'^PUB (\d+) (\d+)$', raw, re.M)
    if pickup_guard and any(42 <= ((int(beam) >> 8) & 511) < 44 for _, beam in samples):
        raise ValueError('Publication during copper pointer pickup')
    publications = [dict(field=int(f)) for f, _ in samples]
    report = cadence(0, fields, publications)
    if len(publications) < 3 or any(int(gap) < 2 for gap in report['interval_fields']):
        raise ValueError('Missing publications or violated two-field cap')
    return dict(passed=True, pickup_guard_checked=pickup_guard, display_fields=display['fields'], page_turnovers=switches,
                cadence=report,
                scope='Every field in the DMA sample has one display page and no active-display writes; the separate publication window obeys P2. No physical-hardware claim.')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('display', type=Path); p.add_argument('publications', type=Path)
    p.add_argument('--pickup-guard', action='store_true')
    p.add_argument('--fields', type=int, required=True); p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    result = check(json.loads(a.display.read_text()), a.publications.read_text(), a.fields, pickup_guard=a.pickup_guard)
    a.out.write_text(json.dumps(result, indent=2) + '\n')
    print({k: v for k, v in result.items() if k != 'cadence'})
