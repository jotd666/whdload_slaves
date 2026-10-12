"""Reference for CPU-neutral sparse artwork repair (five 320x200 planes).

Coverage must come from the native renderer, not from nonzero image colours.
Actual destination pixels guard both pages; no assumption about intervening draws.
"""
import struct

PLANE = 8000
DEPTH = 5
CAPACITY = 1024


def pack(image, mask):
    if len(image) != PLANE * DEPTH or len(mask) != PLANE:
        raise ValueError('Unexpected planar geometry')
    records = []
    for offset in range(0, PLANE, 2):
        bits = int.from_bytes(mask[offset:offset + 2], 'big')
        if bits:
            if len(records) == CAPACITY:
                raise ValueError("Coverage exceeds bounded cache")
            colours = [int.from_bytes(image[p * PLANE + offset:p * PLANE + offset + 2], 'big') & bits
                       for p in range(DEPTH)]
            records.append(struct.pack('>7H', offset, bits, *colours))
    return struct.pack('>H', len(records)) + b''.join(records)


def repair(destination, packed):
    if len(destination) != PLANE * DEPTH or len(packed) < 2:
        raise ValueError('Invalid buffers')
    count = int.from_bytes(packed[:2], 'big')
    if count > CAPACITY or len(packed) != 2 + 14 * count:
        raise ValueError('Invalid sparse list')
    result = bytearray(destination)
    writes = 0
    previous = -2
    for offset, bits, *colours in struct.iter_unpack('>7H', packed[2:]):
        if offset % 2 or not previous < offset < PLANE or not bits:
            raise ValueError('Invalid sparse word')
        previous = offset
        for plane, colour in enumerate(colours):
            at = plane * PLANE + offset
            old = int.from_bytes(result[at:at + 2], 'big')
            difference = (old ^ colour) & bits
            if difference:
                struct.pack_into('>H', result, at, old ^ difference)
                writes += 1
    return bytes(result), writes
