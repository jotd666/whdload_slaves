"""Bounded E2 runtime-key model, independent of the raster dependency recorder.

The native builder uses this storage format. Lifetime invalidation and the
coverage acceptance check are mandatory; a matching key alone cannot enable a
cached native draw. The drawing destination is deliberately not a dependency.
"""
import struct
from cockpit_program import decode, signed_byte

HEADER = 8 + 32 * 12
EFFECTS = HEADER + 8192
KEY_BYTES = EFFECTS + 2


def build(read, h3, program, base=0, resource_epoch=0):
    if program not in (3, 4):
        raise ValueError('Unsupported front program')
    ranges = []
    used = 0

    def append(address, size, resource=False):
        nonlocal used
        if not 1 <= size <= 4096 or len(ranges) == 32 or used + size > 8192:
            raise ValueError('Key capacity exceeded')
        value = read(address, size)
        if len(value) != size:
            raise ValueError('Truncated key input')
        ranges.append((address, value, resource_epoch if resource else 0))
        used += size
        return value

    def pointer(address):
        value = int.from_bytes(append(address, 4), 'big')
        if not value:
            raise ValueError('Missing resource')
        return value

    script = pointer(h3 + 0x7b52 + program * 4)
    commands = decode(read, script, max_bytes=512)
    append(script, commands['bytes'])
    append(h3 + 0x9d34, 28)
    colours = append(h3 + 0x3ab7, 10)
    for selector in reversed(colours[8:10]):
        append(h3 + 0x101d + signed_byte(selector) * 4, 4)
    table = image = None
    colour_seen = False
    effects = 0
    for command in commands['commands']:
        kind, args = command['kind'], command['args']
        if kind == 'polygon':
            raise ValueError('Cockpit polygon is not a runtime cache candidate')
        effects |= {'colours': 1, 'image_set': 2, 'image': 4, 'bitmap': 8, 'rectangle': 16}.get(kind, 0)
        if kind == 'colours':
            colour_seen = True
        elif kind == 'image_set':
            table = pointer(h3 + 0x3b02 + 4 * args[0])
            image = None
        elif kind == 'image':
            if table is None:
                raise ValueError('Incoming image table')
            address = pointer(table + 4 * args[0])
            image = struct.unpack('>IIHHIH', append(address, 18))
        elif kind in ('rectangle', 'line', 'bitmap'):
            if not colour_seen:
                raise ValueError('Incoming pen dependency')
            if kind != 'bitmap':
                continue
            if image is None or command['mode'] != 0:
                raise ValueError('Unsupported bitmap')
            data, mask, width, height, plane_size, orientation = image
            pitch = ((width + 15) // 16) * 2
            if not (1 <= width <= 320 and 1 <= height <= 200) or orientation or plane_size != pitch * height:
                raise ValueError('Unsupported descriptor')
            if not data or not mask:
                raise ValueError('Missing bitmap data')
            append(data, plane_size * 5, True)
            append(mask, (pitch + 2) * height, True)
    result = bytearray(KEY_BYTES)
    struct.pack_into('>4H', result, 0, 1, program, len(ranges), used)
    struct.pack_into('>H', result, EFFECTS, effects)
    cursor = HEADER
    for index, (address, value, epoch) in enumerate(ranges):
        struct.pack_into('>IIHH', result, 8 + 12 * index, address, base + cursor, len(value), epoch)
        result[cursor:cursor + len(value)] = value
        cursor += len(value)
    return bytes(result)
