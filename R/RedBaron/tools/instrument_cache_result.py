"""Acceptance of one bounded seven-gauge native pixel/state twin capture."""
import struct


def check(header, counters):
    if len(header) != 32 or len(counters) != 8:
        raise ValueError('Truncated gauge twin result')
    checked, active, scratch, passes, failure, offset, gauge, reserved = struct.unpack('>8I', header)
    hits, fills = struct.unpack('>2I', counters)
    if checked != 127 or active or scratch or passes != 7 or failure or offset or gauge or reserved:
        raise ValueError('Incomplete or failed seven-gauge twin')
    if hits == 0 or fills < 7:
        raise ValueError('Missing actual cache exercise')
    return dict(gauges=7, pixel_bytes_per_case=40000, state_bytes_per_case=40,
                hits=hits, fills=fills)
