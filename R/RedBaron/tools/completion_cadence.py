"""Event-free publication cadence within a complete normal-build census.

A whole combat window is not called steady. DASH timestamps have field precision,
so frames touching either endpoint field of an event are excluded conservatively.
"""
import re
import statistics

PAL_HZ = 49.92041

def summarize(text, fields):
    observed = [int(v) for v in re.findall(r'^FIELD (\d+) ', text, re.M)]
    if observed != list(range(1, fields + 1)) or 'FLIGHT_EXIT' in text:
        raise ValueError('Require a complete consecutive flight window')
    pubs = [(int(f), int(b)) for f, b in re.findall(r'^PUB (\d+) (\d+)$', text, re.M)]
    if len(pubs) < 2:
        raise ValueError('Require at least two publications')
    events = [int(v) for v in re.findall(r'^DASH \w+ (\d+)$', text, re.M)]
    phase = max((int(b) >> 8) & 511 for b in re.findall(r'^FIELD \d+ (\d+)$', text, re.M)) + 1
    clean = []
    for (a, ab), (b, bb) in zip(pubs, pubs[1:]):
        al, bl = (ab >> 8) & 511, (bb >> 8) & 511
        ah, bh = ab & 255, bb & 255
        if not (1 <= a <= b <= fields and phase <= al < 313 and phase <= bl < 313 and 1 < ah < 227 and 1 < bh < 227):
            continue
        duration = b - a + (bl - al) / 313 + (bh - ah) / (313 * 227)
        if duration <= 0:
            raise ValueError('Nonpositive publication interval')
        if not any(a <= event <= b for event in events):
            clean.append(duration)
    return dict(window_fields=fields, window_fps=len(pubs)*PAL_HZ/fields,
                dashboard_events=len(events), clean_intervals=len(clean),
                clean_fields=sum(clean),
                event_free_frame_fps=PAL_HZ/statistics.mean(clean) if clean else None)
