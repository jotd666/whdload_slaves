"""Raw dynamic inputs of the seven native cockpit gauge callbacks.

A value key is not a complete raster cache key. The cache owner must separately
validate geometry, palette, resources and drawing state. Raw bit patterns retain
native signedness/overflow decisions inside the original callback.
"""
import struct

VALUE_WORDS = {1: 0x71AE, 2: 0x71B0, 3: 0x71B2, 4: 0x71D4, 6: 0x71B8}


def key(read, h3, gauge):
    """Return 12 private key bytes, or None before dereferencing unsupported input."""
    if not 0 <= gauge <= 6:
        return None

    def u16(address):
        return int.from_bytes(read(address, 2), 'big')

    def u32(address):
        return int.from_bytes(read(address, 4), 'big')

    mode = denominator = 0
    if gauge == 0:
        aircraft = u32(h3 + 0x4578)
        if not aircraft:
            return None
        value = u32(aircraft + 0x10)
    elif gauge == 5:
        denominator = u16(h3 + 0x71D2)
        mode = u16(h3 + 0x8D9E)
        value = denominator
        if mode:
            aircraft = u32(h3 + 0x4578)
            if not aircraft:
                return None
            value = u16(aircraft + 0x86)
    else:
        value = u16(h3 + VALUE_WORDS[gauge])
    return struct.pack('>HHII', gauge, mode, value, denominator)
