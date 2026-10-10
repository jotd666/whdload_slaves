"""Read sim v1's allocation chain rooted at h3:04138.

sim:2d214 adds an eight-byte header: allocation length including the header,
then the previous head pointer. sim:2d27e unlinks and frees that same extent.
This covers allocations through sim:2d1ee, not arbitrary OS/library memory.
"""
import struct

ROOT = 0x4138
HEADER = 8


def exact(read, address, size):
    data = read(address, size)
    if len(data) != size:
        raise ValueError('Truncated game allocation or segment')
    return data


def allocations(read, h3):
    address = int.from_bytes(exact(read, h3 + ROOT, 4), 'big')
    result = []
    seen = set()
    while address:
        if address & 1 or address in seen or len(seen) >= 4096:
            raise ValueError('Invalid or cyclic game allocation chain')
        seen.add(address)
        size, following = struct.unpack('>II', exact(read, address, HEADER))
        if size < HEADER:
            raise ValueError('Game allocation shorter than its header')
        data = read(address, size)
        if len(data) != size:
            raise ValueError('Truncated game allocation')
        if any(max(address, other) < min(address + size, other + length)
               for other, length in result):
            raise ValueError('Overlapping game allocations')
        result.append((address, size))
        address = following
    return result


# Supported sim v1 allocations, checked against its original HUNK_HEADER.
SIM_SEGMENT_SIZES = (0x3e384, 0x3bc, 0x190, 0xbd0c)


def segments(read, sim):
    result = []
    address = sim
    for expected in SIM_SEGMENT_SIZES:
        size, following = struct.unpack('>II', exact(read, address - HEADER, HEADER))
        if size != expected + HEADER:
            raise ValueError('Unexpected sim v1 segment extent')
        if len(read(address, expected)) != expected:
            raise ValueError('Truncated sim segment')
        result.append((address, expected))
        address = following * 4 + 4 if following else 0
        if not address and len(result) != len(SIM_SEGMENT_SIZES):
            raise ValueError('Incomplete sim segment chain')
    if address:
        raise ValueError('Extra sim segment')
    return result
