"""Validate the bounded external W6 counter log without modifying the guest."""
import re
from publication_cadence import cadence


def report(raw, fields, quantum, time_scale):
    starts = re.findall(r'^BEGIN (\d+) (\d+) (\d+)$', raw, re.M)
    ends = re.findall(r'^END (\d+) (\d+) (\d+) (\d+) (\d+) (\d+)$', raw, re.M)
    if len(starts) != 1 or len(ends) != 1 or any(s in raw for s in ('FLIGHT_EXIT', 'Invalid hex digit')):
        raise ValueError('Incomplete W6 counter capture')
    cia0, step0, f0 = map(int, starts[0])
    observed, drop, pub, cia1, step1, f1 = map(int, ends[0])
    ticks = (cia1-cia0) & 0xffffffff
    steps = (step1-step0) & 0xffffffff
    if observed != fields or f0 != f1 or not ticks or not f0 or quantum != 225:
        raise ValueError('Invalid or changing W6 clock')
    pubs = [dict(field=int(v), beam=int(b)) for v, b in re.findall(r'^PUB (\d+) (\d+)$', raw, re.M)]
    if len(pubs) != pub or not pubs:
        raise ValueError('Missing publication evidence')
    timing = cadence(0, fields, pubs)
    unsafe = sum(41 <= ((p['beam'] >> 8) & 511) <= 43 for p in pubs)
    if unsafe:
        raise ValueError('Publication inside copper pickup guard')
    return dict(quantum=quantum, time_scale=time_scale, F=f0, fields=fields,
                publications=pub, fps=pub*49.92041/fields, world_steps=steps,
                cia_ticks=ticks, world_rate=steps*quantum*f0/(ticks*1024),
                endpoint_rate_quantum=quantum*f0/(ticks*1024),
                dropped_steps=drop, dropped_units=drop*quantum, cadence=timing,
                pickup_guard_violations=unsafe,
                scope='Uninstrumented developer runtime; external CIA/step counters. Endpoint uncertainty is one world quantum; gameplay acceptance remains separate.')
