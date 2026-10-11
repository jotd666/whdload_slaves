"""Reference for sparse cached-plane composition from fast RAM to chip RAM."""


def compose(background, pixels, mask, words, rows, offset):
    if len(background) != 40000 or not (1 <= words <= 20 and 1 <= rows <= 200):
        raise ValueError('Unsupported planar geometry')
    pitch = words * 2
    size = pitch * rows
    if len(pixels) != size * 5 or len(mask) != size:
        raise ValueError('Truncated packed cache')
    if offset < 0 or offset % 2 or offset % 40 + pitch > 40 or offset // 40 + rows > 200:
        raise ValueError('Cache extends outside the screen')
    result = bytearray(background)
    reads = writes = 0
    for plane in range(5):
        for row in range(rows):
            for word in range(words):
                source = row * pitch + 2 * word
                coverage = int.from_bytes(mask[source:source + 2], 'big')
                if not coverage:
                    continue
                at = plane * 8000 + offset + row * 40 + 2 * word
                value = int.from_bytes(pixels[plane * size + source:plane * size + source + 2], 'big')
                if coverage != 65535:
                    value = (value & coverage) | (int.from_bytes(result[at:at + 2], 'big') & (65535 ^ coverage))
                    reads += 1
                result[at:at + 2] = value.to_bytes(2, 'big')
                writes += 1
    return bytes(result), dict(chip_word_reads=reads, chip_word_writes=writes)
