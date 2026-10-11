"""Validate the bounded native front-cache twin result, not E2 acceptance."""
import struct


def check(header, counters):
    if len(header) != 16 or len(counters) != 12:
        raise ValueError('Truncated front-cache result')
    checked, active, scratch, passes = struct.unpack('>4I', header)
    hits, fills, fallbacks = struct.unpack('>3I', counters)
    if checked != 3 or passes != 2:
        raise ValueError('Both front-program pixel/state twins must finish')
    if active or scratch:
        raise ValueError('Front twin must be idle with private scratch released')
    if hits < 2 or fills < 2 or fallbacks:
        raise ValueError('Front fixture did not exercise two cached programs cleanly')
    return dict(programs=[3, 4], pixel_bytes_per_case=40000,
                drawing_state_bytes=24, hits=hits, fills=fills, fallbacks=fallbacks)
