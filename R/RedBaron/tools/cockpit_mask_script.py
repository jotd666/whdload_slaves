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
