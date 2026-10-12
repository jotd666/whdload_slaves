"""E3 polygon merge contract: descending filled coverage into one plane.

sim:2f502 merges the scratch mask using FA/0A, BLTCON1=2, no shift,
and full first/last masks. Edges/area fill are upstream and stay unchanged.
"""


def merge_plane(mask, screen, bottom, words, rows, colour, pitch=40):
    if (bottom % 2 or not 1 <= words <= 20 or not 1 <= rows <= 200
            or pitch != 40 or bottom-(rows-1)*pitch-(words-1)*2 < 0
            or bottom+2 > min(len(mask), len(screen))):
        return None
    result = bytearray(screen)
    for y in range(rows):
        at = bottom-y*pitch
        for x in range(words):
            pos = at-2*x
            coverage = int.from_bytes(mask[pos:pos+2], 'big')
            old = int.from_bytes(result[pos:pos+2], 'big')
            value = old | coverage if colour else old & ~coverage
            result[pos:pos+2] = value.to_bytes(2, 'big')
    return result
