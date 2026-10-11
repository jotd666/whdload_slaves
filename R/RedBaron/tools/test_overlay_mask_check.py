import unittest
from overlay_mask_check import GUARD,check_buffer


class OverlayMaskCheckTests(unittest.TestCase):
    def test_opaque_zero_colour_is_still_coverage(self):
        mask=bytes([0x81])+bytes(7999)
        self.assertEqual(check_buffer(GUARD+mask+GUARD,mask),2)

    def test_reject_any_wrong_coverage_guard_or_length(self):
        mask=bytes(8000);data=GUARD+mask+GUARD
        for offset in (0,15,16,8015,8016,8031):
            damaged=bytearray(data);damaged[offset]^=1
            with self.subTest(offset=offset),self.assertRaises(ValueError):check_buffer(damaged,mask)
        with self.assertRaises(ValueError):check_buffer(data[:-1],mask)
