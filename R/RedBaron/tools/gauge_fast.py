"""FC3 clipped packed-background painter and bounded native-twin acceptance."""
import struct


def paint(frame, pixels, coverage, area, clip):
    left, top, pitch, height = area
    if left < 0 or left % 2 or pitch <= 0 or pitch % 2 or left+pitch > 40 or not 0 <= top < top+height <= 200:
        raise ValueError('Invalid packed bounds')
    if len(pixels) != pitch*height*5 or len(coverage) != pitch*height:
        raise ValueError('Truncated packed background')
    result = bytearray(frame)
    for y in range(top, top+height):
        for x in range(left, left+pitch, 2):
            at = (y-top)*pitch+x-left
            mask = int.from_bytes(coverage[at:at+2], 'big')
            if clip is not None:
                l, r, t, b = clip
                if y < t or y > b:
                    continue
                low, high = max(0, l-x*8), max(0, x*8+15-r)
                mask &= 0xffff >> low if low < 16 else 0
                mask &= (0xffff << high) & 0xffff if high < 16 else 0
            for plane in range(5):
                pos = plane*8000+y*40+x
                src = plane*pitch*height+at
                colour = int.from_bytes(pixels[src:src+2], 'big')
                old = int.from_bytes(result[pos:pos+2], 'big')
                result[pos:pos+2] = ((old & ~mask) | (colour & mask)).to_bytes(2, 'big')
    return bytes(result)


def check(background, reuse, draws):
    if len(background) != 8 or len(reuse) != 32 or len(draws) != 4:
        raise ValueError('Truncated FC3 result')
    checked, passes = struct.unpack('>2I', background)
    gauges, active, scratch, reuse_passes, failure, offset, gauge, reserved = struct.unpack('>8I', reuse)
    if checked != 0xfffffff or passes != 28 or not int.from_bytes(draws, 'big'):
        raise ValueError('Incomplete per-page background twins')
    if failure or active or scratch or offset or gauge or reserved or gauges != 0x3fff or reuse_passes != 14:
        raise ValueError('Failed or missing unchanged-gauge twins')
    return dict(background_cases=passes, reuse_gauges=hex(gauges), reuse_cases=reuse_passes,
                cpu_restores=int.from_bytes(draws, 'big'))


def retained(area_top, viewport, ordered_artwork_offsets, *, composed):
    """Sufficient no-write proof; empty artwork lists have no covered pixels."""
    if not composed:
        return False
    end=(viewport[0]+viewport[1])*40
    for offsets in ordered_artwork_offsets:
        if offsets != sorted(offsets) or any(x < 0 or x >= 8000 or x%2 for x in offsets):
            raise ValueError('Invalid sparse list')
        if offsets:
            end=max(end, offsets[-1]+2)
    return area_top*40 >= end
