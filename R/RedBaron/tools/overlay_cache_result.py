"""Validate the bounded native front-cache twin result, not E2 acceptance."""
import struct


def check(header, counters, programs=(3, 4)):
    if tuple(programs) not in ((2,), (3, 4)):
        raise ValueError('Unsupported or empty front-cache acceptance set')
    if len(header) != 16 or len(counters) != 12:
        raise ValueError('Truncated front-cache result')
    checked, active, scratch, passes = struct.unpack('>4I', header)
    hits, fills, fallbacks = struct.unpack('>3I', counters)
    if checked != (1 << len(programs)) - 1 or passes != len(programs):
        raise ValueError('All selected front-program pixel/state twins must finish')
    if active or scratch:
        raise ValueError('Front twin must be idle with private scratch released')
    if hits < len(programs) or fills < len(programs) or fallbacks:
        raise ValueError('Front fixture did not exercise every cached program cleanly')
    return dict(programs=list(programs), pixel_bytes_per_case=40000,
                drawing_state_bytes=24, hits=hits, fills=fills, fallbacks=fallbacks)
