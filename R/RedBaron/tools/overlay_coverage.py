"""Exact opaque/preserve coverage from native black/white background draws.

Only destination-local bitwise operations are eligible; endpoint draws cannot
identify copies/shifts between destination pixels or planes.
Both draws must have identical renderer inputs and starting drawing context.
This primitive cannot make mismatched captures safe. A caller must restore that
context and key/invalidate all inputs before treating the result as a cache.
"""
PLANE = 8000
PLANES = 5


def extract(zero, one):
    if len(zero) != PLANE * PLANES or len(one) != PLANE * PLANES:
        raise ValueError('Expected two native five-plane frames')
    mask = bytearray(PLANE)
    for at in range(PLANE):
        preserve = None
        for plane in range(PLANES):
            z = zero[plane*PLANE+at]
            w = one[plane*PLANE+at]
            if z & (~w & 255):
                return None  # invert cannot be represented by a masked copy
            delta = z ^ w
            if preserve is None:
                preserve = delta
            elif preserve != delta:
                return None  # a single shared mask would change some planes
        mask[at] = preserve ^ 255
    return bytes(mask)


def composite(background, zero, mask):
    if len(background) != PLANE*PLANES or len(zero) != PLANE*PLANES or len(mask) != PLANE:
        raise ValueError('Invalid native image/mask size')
    return bytes((background[i] & (mask[i % PLANE] ^ 255)) |
                 (zero[i] & mask[i % PLANE]) for i in range(PLANE*PLANES))


def combine(layers):
    """Fold native-order (image, mask) layers into one independent cache.

    Images may contain arbitrary bytes outside their coverage. Later opaque
    pixels replace earlier pixels, including black; masks alone own coverage.
    """
    image = bytes(PLANE*PLANES)
    coverage = bytes(PLANE)
    for source, mask in layers:
        image = composite(image, source, mask)
        coverage = bytes(a | b for a, b in zip(coverage, mask))
    return image, coverage
