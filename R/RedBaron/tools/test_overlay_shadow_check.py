import unittest
from overlay_mask_check import GUARD
from overlay_shadow_check import retain,checked_frame


class OverlayShadowCheckTests(unittest.TestCase):
    def test_hits_keep_same_allocation_and_frozen_bytes(self):
        previous={};data=bytearray(5240)
        self.assertFalse(retain(previous,3,0x1000,data))
        self.assertTrue(retain(previous,3,0x1000,data))
        self.assertFalse(retain(previous,4,0x3000,data))
        with self.assertRaises(ValueError):retain(previous,3,0x4000,data)
        data[100]^=1
        with self.assertRaises(ValueError):retain(previous,3,0x1000,data)
        with self.assertRaises(ValueError):retain(previous,3,0x1000,b'')

    def test_compare_entire_frame_and_both_guards(self):
        pixels=bytes(40000);data=GUARD+pixels+GUARD
        checked_frame(data,pixels)
        for off in (0,15,16,20000,40015,40016,40031):
            altered=bytearray(data);altered[off]^=1
            with self.subTest(off=off),self.assertRaises(ValueError):checked_frame(altered,pixels)
