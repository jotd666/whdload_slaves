import random
import unittest
from cpu_span_model import merge_plane


class CpuSpanTests(unittest.TestCase):
    def test_descending_merge_against_individual_pixels(self):
        rng = random.Random(0x2f502)
        for rows in (1, 2, 17, 200):
            for words in range(1, 21):
                for colour in (0, 1):
                    for right in (19, words-1):
                        mask = rng.randbytes(40*(rows+2))
                        original = rng.randbytes(len(mask))
                        bottom = rows*40+right*2
                        actual = merge_plane(mask, original, bottom, words, rows, colour)
                        expected = bytearray(original)
                        for y in range(1, rows+1):
                            for x in range((right+1-words)*16, (right+1)*16):
                                at = y*40+x//8
                                bit = 128 >> (x%8)
                                if mask[at] & bit:
                                    if colour:
                                        expected[at] |= bit
                                    else:
                                        expected[at] &= ~bit
                        self.assertEqual(actual, expected)

    def test_transparent_and_opaque_coverage(self):
        for value in (0, 255):
            for colour in (0, 1):
                screen = bytes([0x5a])*8000
                actual = merge_plane(bytes([value])*8000, screen, 7998, 20, 200, colour)
                self.assertEqual(actual, screen if value == 0 else bytes([255 if colour else 0])*8000)

    def test_rejects_invalid_rectangles(self):
        for bottom, words, rows in ((1,1,1),(0,2,1),(40,20,3),(7998,21,1),(7998,20,201)):
            self.assertIsNone(merge_plane(bytes(8000), bytes(8000), bottom, words, rows, 1))


if __name__ == '__main__':
    unittest.main()
