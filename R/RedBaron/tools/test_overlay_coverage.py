import random
import unittest
from overlay_coverage import PLANE, PLANES, extract, composite


class OverlayCoverageTests(unittest.TestCase):
    def test_complete_single_bit_truth_table(self):
        for z, w, expected in ((0,0,1), (1,1,1), (0,1,0), (1,0,None)):
            zero = bytearray(PLANE*PLANES)
            one = bytearray([255])*(PLANE*PLANES)
            for plane in range(PLANES):
                zero[plane*PLANE] = z
                one[plane*PLANE] = 254 | w
            mask = extract(zero, one)
            if expected is None:
                self.assertIsNone(mask)
            else:
                self.assertEqual(mask[0], expected)
                self.assertEqual(mask[1:], bytes(PLANE-1))

    def test_opaque_black_is_retained(self):
        zero = bytes(PLANE*PLANES)
        one = bytearray([255])*(PLANE*PLANES)
        for plane in range(PLANES):
            one[plane*PLANE+17] = 0
        mask = extract(zero, one)
        self.assertEqual(mask[17], 255)
        image = composite(bytes([255])*(PLANE*PLANES), zero, mask)
        for plane in range(PLANES):
            self.assertEqual(image[plane*PLANE+17], 0)
            self.assertEqual(image[plane*PLANE+18], 255)

    def test_native_copy_truth_on_arbitrary_backgrounds(self):
        rng = random.Random(917)
        original_mask = rng.randbytes(PLANE)
        colour = rng.randbytes(PLANE*PLANES)
        zero = bytes(colour[i] & original_mask[i % PLANE] for i in range(len(colour)))
        one = bytes(zero[i] | (255 ^ original_mask[i % PLANE]) for i in range(len(colour)))
        self.assertEqual(extract(zero, one), original_mask)
        background = rng.randbytes(PLANE*PLANES)
        expected = bytearray(background)
        for i in range(len(expected)):
            for bit in range(8):
                b = 1 << bit
                if original_mask[i % PLANE] & b:
                    expected[i] = (expected[i] & ~b) | (colour[i] & b)
        self.assertEqual(composite(background, zero, original_mask), bytes(expected))

    def test_inversion_and_plane_specific_writes_are_rejected_at_edges(self):
        for plane in range(PLANES):
            for at in (0, PLANE-1):
                zero = bytearray(PLANE*PLANES)
                one = bytearray([255])*(PLANE*PLANES)
                one[plane*PLANE+at] = 254
                self.assertIsNone(extract(zero, one))
                zero[plane*PLANE+at] = 1
                self.assertIsNone(extract(zero, one))

    def test_bad_sizes(self):
        with self.assertRaises(ValueError):
            extract(bytes(40000), bytes(39999))
        with self.assertRaises(ValueError):
            composite(bytes(40000), bytes(40000), bytes(7999))
