import unittest
from overlay_mask_check import GUARD
from overlay_shadow_check import retain,checked_frame,replay_held


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


class ReplayWindowTests(unittest.TestCase):
    def test_eligible_boundaries_and_wrap(self):
        for origin in (1000,0xfffffff0):
            records=[((origin+d)&0xffffffff,k,v,0,0) for d,k,v in ((32,78,1),(64,78,0),(96,64,1),(128,64,0))]
            for elapsed,right,fire in ((31,0,0),(32,1,0),(63,1,0),(64,0,0),(95,0,0),(96,0,1),(127,0,1),(128,0,0)):
                self.assertEqual(replay_held(origin,(origin+elapsed)&0xffffffff,records),(elapsed,{78:right,64:fire}))

    def test_reject_changed_schedule_or_old_cursor(self):
        records=[(1000+d,k,v,0,0) for d,k,v in ((32,78,1),(64,78,0),(96,64,1),(128,64,0))]
        with self.assertRaises(ValueError):replay_held(1000,999,records)
        records[0]=(1033,78,1,0,0)
        with self.assertRaises(ValueError):replay_held(1000,1040,records)
