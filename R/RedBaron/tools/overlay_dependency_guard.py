"""Independent model of the private ordered native overlay-key comparator.

Descriptors and resource lifetimes must be trusted by the caller. This does
not construct a complete cache key or make stale native pointers safe to read.
"""
import struct


def matches(read, key, program):
    accesses = 0
    def exact(address, size):
        value = read(address, size)
        if len(value) != size:
            raise ValueError('Truncated dependency key/read')
        return value
    valid, identity, count = struct.unpack('>HHH', exact(key, 6))
    if valid != 1 or identity != program or not 1 <= count <= 32:
        return False, accesses
    for i in range(count):
        at = key + 8 + i * 12
        length = int.from_bytes(exact(at + 8, 2), 'big')
        if not 1 <= length <= 4096:
            return False, accesses
        source, expected = struct.unpack('>II', exact(at, 8))
        for j in range(length):
            accesses += 1
            if exact(source + j, 1) != exact(expected + j, 1):
                return False, accesses
    return True, accesses


def fixture(base=0x1000):
    data = bytearray(80)
    struct.pack_into('>HHHH', data, 0, 1, 3, 2, 0)
    struct.pack_into('>IIHH', data, 8, base+48, base+64, 4, 0)
    struct.pack_into('>IIHH', data, 20, base+52, base+68, 8, 0)
    data[48:60] = data[64:76] = bytes(range(32, 44))
    return data


def cases():
    # Each mutation is applied to a fresh, private fixture.
    return [(60, 0, 1, 12)] + [(48+i, 128, 0, i+1) for i in range(12)] + [
        (1, 0, 0, 0), (0, 1, 0, 0), (3, 4, 0, 0), (2, 1, 0, 0),
        (5, 0, 0, 0), (5, 33, 0, 0), (4, 1, 0, 0),
        (17, 0, 0, 0), (16, 16, 0, 0), (29, 0, 0, 4), (28, 16, 0, 4)]
