"""Reference admission/key/state policy for the E2 persistent gauge cache.

A cache hit requires a stable native rectangle, unchanged value/resource context
and exact current pixels. This does not establish the native callback's fixed
point or performance; the native twin and FPS windows remain required.
"""
from dataclasses import dataclass
import struct
from instrument_values import key as value_key
from instrument_pixels import capture, matches

KEY_BYTES = 288
COMMON_POST = ((0x9D46, 10),)
NEEDLE_POST = ((0x9D52, 2), (0x791C, 8))


def writes(gauge):
    if not 0 <= gauge <= 6:
        raise ValueError('Unsupported gauge')
    if gauge in (1, 3):
        return COMMON_POST + ((0x712C, 8),)
    extra = ((0x7914, 8),) if gauge == 0 else ((0x7116, 2), (0x711A, 2)) if gauge == 2 else ()
    return COMMON_POST + NEEDLE_POST + extra


def build_key(read, h3, gauge, x, y, background, previous_rect, upper_words=(0, 0, 0, 0)):
    if read(h3+0x1E88, 1) == b'\0':
        return None
    values = value_key(read, h3, gauge)
    if values is None or not background or background & 1:
        return None
    bg = read(background, 18)
    if len(bg) != 18 or bg[16:18] != b'\0\0':
        return None
    dyn = bytes(22)
    if gauge in (1, 3):
        table = int.from_bytes(read(h3+0x7120, 4), 'big')
        if not table or table & 1:
            return None
        pointer = int.from_bytes(read(table+(8 if gauge == 1 else 24), 4), 'big')
        if not pointer or pointer & 1:
            return None
        desc = read(pointer, 18)
        if len(desc) != 18 or desc[16:18] != b'\0\0':
            return None
        dyn = struct.pack('>I', pointer)+desc
    result = (values + struct.pack('>hhI', x, y, background) + bg + dyn +
              read(h3+0x9D72, 4) + read(h3+0x9D34, 18) +
              read(h3+0x1E88, 1) + b'\0' + read(h3+0x1B1A, 2) +
              read(h3+0x7670, 2) + struct.pack('>4h', *previous_rect) +
              read(h3+0x1B1A, 180) + read(h3+0x7114, 2) + read(h3+0x7118, 2))
    assert len(result) == 280
    return result + struct.pack('>4H', *upper_words)


@dataclass
class Entry:
    key: bytes
    area: object
    pixels: bytes
    post: dict


class Cache:
    def __init__(self):
        self.entries = {}

    def invalidate(self):
        self.entries.clear()

    def remember(self, slot, key, area, before_rect, after_rect, screen, post):
        self.entries.pop(slot, None)
        if key is None or len(key) != KEY_BYTES or area is None or before_rect != after_rect:
            return False
        if not 0 <= slot < 14:
            raise ValueError('Invalid native history slot')
        self.entries[slot] = Entry(key, area, capture(screen, area), dict(post))
        return True

    def reuse(self, slot, key, screen, *, forced=False, dirty=False):
        entry = self.entries.get(slot)
        if forced or dirty or entry is None or key != entry.key:
            return None
        if not matches(screen, entry.area, entry.pixels):
            return None
        return dict(entry.post)
