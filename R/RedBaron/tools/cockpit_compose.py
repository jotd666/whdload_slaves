"""Reference for dirty updates of the ordered, persistent cockpit composite.

Native renderers produce independent cached layers. A changed layer invalidates
its old/new rectangle union, not just its new bounds. Rebuild that union from
all layers to retain later foreground artwork and expose earlier layers exactly.
This model does not establish native layer capture or runtime integration.
"""
from dataclasses import dataclass


@dataclass(frozen=True)
class Layer:
    pixels: bytes
    mask: bytes


def update(composite, layers, rect, *, pitch=40, rows=200, planes=5):
    """Match the assembly's front-to-back word composition; reject before writes."""
    size = pitch * rows
    left, top, width, height = rect
    if not 1 <= len(layers) <= 10 or len(composite) != (planes + 1) * size:
        raise ValueError('Invalid layer count or composite allocation')
    if (left < 0 or top < 0 or width <= 0 or height <= 0 or left % 2 or width % 2
            or left + width > pitch or top + height > rows):
        raise ValueError('Invalid dirty rectangle')
    for layer in layers:
        if layer is not None and (len(layer.pixels) != planes * size or len(layer.mask) != size):
            raise ValueError('Invalid layer allocation')
    for y in range(top, top + height):
        for x in range(left, left + width, 2):
            offset = y * pitch + x
            coverage = 0
            colours = [0] * planes
            for layer in reversed(layers):
                if layer is None:
                    continue
                mask = int.from_bytes(layer.mask[offset:offset+2], 'big') & ~coverage & 65535
                if not mask:
                    continue
                coverage |= mask
                for plane in range(planes):
                    start = plane * size + offset
                    colours[plane] |= int.from_bytes(layer.pixels[start:start+2], 'big') & mask
                if coverage == 65535:
                    break
            for plane, colour in enumerate(colours + [coverage]):
                start = plane * size + offset
                composite[start:start+2] = colour.to_bytes(2, 'big')


def native_static_layer(image, mask, offset, bltsize, stride, bottom):
    """Expand the supported sim:2c144 packed source into one full-size layer.

    Mirror the native full-width/partial-bottom-copy branches. Unsupported
    layouts return None so their caller retains the native draw. The caller
    invalidates this snapshot on resource changes or native forced redraws.
    """
    width, source_rows = bltsize & 63, bltsize >> 6
    if width != 20 or not source_rows or stride != source_rows * 40:
        return None
    if offset < 0 or offset % 40:
        return None
    rows = source_rows - (159 - bottom if 75 <= bottom < 159 else 0)
    count = rows * 40
    if rows <= 0 or offset + count > 8000:
        return None
    if len(image) < 5 * stride or len(mask) < count:
        return None
    pixels = bytearray(40000)
    coverage = bytearray(8000)
    for plane in range(5):
        begin = plane * 8000 + offset
        pixels[begin:begin+count] = image[plane*stride:plane*stride+count]
    coverage[offset:offset+count] = mask[:count]
    return Layer(bytes(pixels), bytes(coverage))


def native_gauge_layer(image, mask, width, height, x, y, frame, rect):
    """Seed an unmirrored gauge from its resource, then capture its needle.

    The result rectangle must be wholly opaque in the native background mask.
    A rejected case retains native drawing; this is not a colour-derived mask.
    """
    pitch = ((width + 15) // 16) * 2
    if (not 1 <= width <= 64 or not 1 <= height <= 64 or x < 0 or y < 0
            or x + pitch * 8 > 320 or y + height > 200
            or len(image) != pitch * height * 5
            or len(mask) != (pitch + 2) * height or len(frame) != 40000):
        return None
    pixels, coverage = bytearray(40000), bytearray(8000)
    for row in range(height):
        if any(mask[row*(pitch+2)+pitch:(row+1)*(pitch+2)]):
            return None
        for col in range(pitch * 8):
            source_bit = 128 >> (col % 8)
            if not mask[row*(pitch+2)+col//8] & source_bit:
                continue
            dest, bit = (y+row)*40+(x+col)//8, 128 >> ((x+col) % 8)
            coverage[dest] |= bit
            for plane in range(5):
                if image[plane*pitch*height+row*pitch+col//8] & source_bit:
                    pixels[plane*8000+dest] |= bit
    rx, ry, rw, rh = rect
    if rx < 0 or ry < 0 or rw <= 0 or rh <= 0 or rx+rw > 320 or ry+rh > 200:
        return None
    for row in range(ry, ry+rh):
        for col in range(rx, rx+rw):
            dest, bit = row*40+col//8, 128 >> (col % 8)
            if not coverage[dest] & bit:
                return None
            for plane in range(5):
                offset = plane*8000+dest
                pixels[offset] = (pixels[offset] & ~bit) | (frame[offset] & bit)
    return Layer(bytes(pixels), bytes(coverage))
