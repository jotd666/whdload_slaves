"""FC2 sparse viewport painter, checked against the native cookie-cut model."""
import struct
from artwork_sparse import PLANE, DEPTH


def paint(page, packed, first_row, end_row, *, outside=False):
    if len(page) != PLANE * DEPTH or not 0 <= first_row < end_row <= 200:
        raise ValueError('Invalid viewport')
    count = int.from_bytes(packed[:2], 'big')
    if len(packed) != 2 + 14 * count:
        raise ValueError('Invalid sparse list')
    out = bytearray(page)
    for offset, mask, *colours in struct.iter_unpack('>7H', packed[2:]):
        if offset & 1 or not 0 <= offset < PLANE or not mask:
            raise ValueError('Invalid word')
        if (first_row * 40 <= offset < end_row * 40) == outside:
            continue
        for plane, colour in enumerate(colours):
            at = plane * PLANE + offset
            old = int.from_bytes(out[at:at+2], 'big') if mask != 65535 else 0
            struct.pack_into('>H', out, at, (old & ~mask) | (colour & mask))
    return bytes(out)


def compare_viewport(candidate, native, first_row, end_row):
    """Exact word comparison used by the native FC2 twin, including black pixels."""
    if len(candidate) != 40000 or len(native) != 40000:
        raise ValueError('Invalid framebuffer')
    return all(candidate[p*8000+first_row*40:p*8000+end_row*40] ==
               native[p*8000+first_row*40:p*8000+end_row*40] for p in range(5))
