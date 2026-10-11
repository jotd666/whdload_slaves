import random
import unittest
from cockpit_raster import composite
from overlay_fast import compose


class FastOverlayTests(unittest.TestCase):
    def test_sparse_words_match_independent_bitwise_compositor(self):
        rng = random.Random(0xE2)
        for words, rows, offset in ((1, 1, 7998), (20, 200, 0), (13, 19, 204), (2, 3, 7860)):
            with self.subTest(words=words, rows=rows, offset=offset):
                size = words * rows * 2
                masks = (0, 65535, 0x8001, 0x55aa)
                mask = b''.join(masks[i % 4].to_bytes(2, 'big') for i in range(size // 2))
                pixels = rng.randbytes(size * 5)
                background = rng.randbytes(40000)
                full_mask = bytearray(8000)
                full_pixels = bytearray(40000)
                for row in range(rows):
                    at = offset + row * 40
                    start = row * words * 2
                    full_mask[at:at + words * 2] = mask[start:start + words * 2]
                    for plane in range(5):
                        full_pixels[plane * 8000 + at:plane * 8000 + at + words * 2] = pixels[plane * size + start:plane * size + start + words * 2]
                actual, _ = compose(background, pixels, mask, words, rows, offset)
                self.assertEqual(actual, composite(background, full_pixels, full_mask))

    def test_chip_accesses_skip_transparent_and_opaque_reads(self):
        _, counts = compose(bytes(40000), bytes(30), bytes.fromhex('0000ffff8001'), 3, 1, 0)
        self.assertEqual(counts, dict(chip_word_reads=5, chip_word_writes=10))

    def test_reject_outside_screen_without_partial_write(self):
        for offset in (-2, 1, 38, 7962):
            with self.subTest(offset=offset), self.assertRaises(ValueError):
                compose(bytes(40000), bytes(40), bytes(8), 2, 2, offset)
