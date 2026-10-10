"""D1 register/memory contract for the already-clipped solid rectangle.

No area-fill mode or shifted A DMA: BLTCON1=0, BLTADAT=ffff.
The original FA/0A minterms implement (A & colour) | (~A & C).
Only masks ffff/ffff permit disabling C. Zero encoded widths/heights
retain the hardware's 64/1024 interpretation (the live twin bounds these out).
"""
def setup(x, width):
    assert 0 <= x < 320 and 1 <= width <= 320-x
    first = 0xffff >> (x & 15)
    last = (0xffff << (16-((x+width-1) & 15)-1)) & 0xffff
    words = ((x & 15)+width+15)//16
    return first, last, words


def minterm(a, b, c, table):
    out = 0
    for bit in range(16):
        index = ((a >> bit & 1) << 2) | ((b >> bit & 1) << 1) | (c >> bit & 1)
        out |= (table >> index & 1) << bit
    return out


def blit(row, x, width, colour, *, candidate):
    first,last,words = setup(x,width)
    d_only = candidate and first == last == 0xffff
    result = row.copy()
    for i in range(words):
        mask = 0xffff
        if i == 0: mask &= first
        if i == words-1: mask &= last
        at = x//16+i
        # C is deliberately unrelated stale hardware data in D-only mode.
        c = 0xa55a if d_only else row[at]
        result[at] = minterm(mask, 0x5aa5, c, 0xfa if colour else 0x0a)
    return result


def pixel_reference(row,x,width,colour):
    result=row.copy()
    for p in range(x,x+width):
        mask=1 << (15-p%16)
        result[p//16] = result[p//16] | mask if colour else result[p//16] & ~mask
    return result
