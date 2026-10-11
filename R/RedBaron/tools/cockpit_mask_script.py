"""Prepare a private one-colour program for native solid-primitive coverage.

Only colour, filled rectangle, line and counted polygon commands qualify.
The caller supplies a cleared chip mask, one plane, and palette remaps of one;
native clipping/rasterisation then supplies coverage without approximating edges.
This is a preparation model, not approval of a live program-2 replacement.
"""
import struct
from cockpit_program import decode


def prepare(data):
    program = decode(lambda at, size: data[at:at + size], 0, max_bytes=512)
    result = bytearray(data[:program['bytes']])
    colour_seen = False
    for command in program['commands']:
        kind = command['kind']
        if kind == 'colours':
            # Equal pen/background removes colour-dependent outline drawing.
            if command['args'][0] != command['args'][1]:
                raise ValueError('Mixed polygon/rectangle edge colours')
            struct.pack_into('>2H', result, command['offset'] + 2, 1, 1)
            colour_seen = True
        elif kind not in ('rectangle', 'line', 'polygon'):
            raise ValueError('Non-solid command cannot create a white coverage mask')
        elif not colour_seen:
            raise ValueError('Incoming pen dependency')
    return bytes(result)


def dependencies(read, h3):
    """Exact ordered inputs for the solid program-2 candidate; no bitmap scan."""
    ranges = []
    def take(address, size):
        value = read(address, size)
        if len(value) != size:
            raise ValueError('Truncated solid-program input')
        ranges.append((address, value))
        return value
    pointer = int.from_bytes(take(h3 + 0x7b5a, 4), 'big')
    if not pointer:
        raise ValueError('Missing solid program')
    decoded = decode(lambda at,n: read(pointer + at,n), 0, max_bytes=512)
    prepare(take(pointer, decoded['bytes']))
    geometry = take(h3 + 0x9d34, 28)
    uint = lambda offset, size: int.from_bytes(geometry[offset:offset + size], 'big')
    if (uint(0,4), uint(8,2), uint(12,2), uint(14,2), uint(16,2)) != (8000,5,320,40,200):
        raise ValueError('Unsupported solid-program geometry')
    xmin, xmax, ymin, ymax = struct.unpack_from('>4h', geometry, 20)
    if not uint(18,2) or not (0 <= xmin <= xmax < 320 and 0 <= ymin <= ymax < 200):
        raise ValueError('Private mask requires bounded native clipping')
    if take(h3 + 0x7b50, 1) != b'\0':
        raise ValueError('Alternate polygon mode is unsupported')
    colours = take(h3 + 0x3ab7, 10)
    for selector in reversed(colours[8:]):
        if selector >= 128:
            selector -= 256
        take(h3 + 0x101d + 4 * selector, 4)
    return 2, tuple(ranges)
