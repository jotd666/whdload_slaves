"""Bounded pixel guard for reusing a native gauge's persistent screen pixels.

This is a runtime cache primitive model, not whole-frame equivalence evidence.
Input/state keys and native output-state replay are separate prerequisites.
"""
from dataclasses import dataclass


@dataclass(frozen=True)
class Region:
    left: int
    top: int
    row_bytes: int
    rows: int

    def valid(self):
        return (0 <= self.left <= 38 and self.left % 2 == 0 and
                0 <= self.top < 200 and 0 < self.row_bytes <= 8 and
                self.row_bytes % 2 == 0 and self.left + self.row_bytes <= 40 and
                0 < self.rows <= 48 and self.top + self.rows <= 200)

    def offsets(self):
        if not self.valid():
            raise ValueError('Unsupported gauge region')
        return [plane * 8000 + row * 40 + self.left + byte
                for plane in range(5)
                for row in range(self.top, self.top + self.rows)
                for byte in range(self.row_bytes)]


def region(rect, padding):
    """Bound the native partial background clip from sim:19d3c–19d86.

    The right/bottom limits are inclusive and intentionally follow the native
    width-plus-padding expression, not a conventional half-open rectangle.
    No wrapping/off-screen native input is accepted by this cache path.
    """
    x, y, width, height = rect
    px, py = padding
    if not all(-32768 <= n <= 32767 for n in rect):
        return None
    if not all(0 <= n <= 127 for n in padding) or width <= 0 or height <= 0:
        return None
    x0, x1 = x-px, x+width+2*px
    y0, y1 = y-py, y+height+2*py
    if not (0 <= x0 <= x1 < 320 and 0 <= y0 <= y1 < 200):
        return None
    left = (x0 // 16) * 2
    right = ((x1 // 16) + 1) * 2
    result = Region(left, y0, right-left, y1-y0+1)
    return result if result.valid() else None


def capture(screen, area):
    if len(screen) != 40000:
        raise ValueError('Expected native planar screen')
    return bytes(screen[offset] for offset in area.offsets())


def matches(screen, area, packed):
    if len(packed) != area.row_bytes * area.rows * 5:
        return False
    return capture(screen, area) == packed
