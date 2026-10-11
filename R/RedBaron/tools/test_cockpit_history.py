import struct
import unittest
from cockpit_history import BASE, SIZE, History, slot, clip


class CockpitHistoryTests(unittest.TestCase):
    def test_slots_do_not_alias(self):
        self.assertEqual(sorted(slot(i,p) for i in range(7) for p in (0,1)),list(range(0,SIZE,8)))
        for i,p in [(-1,0),(7,0),(0,2)]:
            with self.assertRaises(ValueError): slot(i,p)

    def test_clip_widths_padding_and_wrap(self):
        self.assertEqual(clip([10,20,30,40],[2,3]),[8,44,17,66])
        self.assertEqual(clip([32767,-32768,2,-2],[-1,1]),[-32768,32767,32767,-32768])
        with self.assertRaises(ValueError): clip([0,0,0,0],[128,0])

    def test_history_sequence_and_untouched_storage(self):
        m=History(bytes(SIZE));at=slot(6,1)
        m.event('READ',[1,6,1,BASE+at,0,0,0,0,2,3,0])
        m.event('CLIP',[-2,4,-3,6]);m.event('STORE',[BASE+at,10,20,30,40])
        m.event('AFTER',[BASE+at,10,20,30,40])
        expected=bytearray(SIZE);struct.pack_into('>4h',expected,at,10,20,30,40)
        m.checkpoint(expected);self.assertEqual(m.partial_clips,1)
        self.assertEqual(m.changed_copies,1)
        expected[0]=1
        with self.assertRaises(ValueError): m.checkpoint(expected)

    def test_reject_stale_read_or_reordered_copy(self):
        with self.assertRaises(ValueError): History(bytes(SIZE)).event('READ',[1,0,0,BASE,1,0,0,0,0,0,0])
        m=History(bytes(SIZE));m.event('READ',[1,0,0,BASE,0,0,0,0,0,0,1])
        with self.assertRaises(ValueError): m.event('STORE',[BASE,0,0,0,0])
        m.event('CLIP',[1,2,3,4]);m.event('STORE',[BASE,1,2,3,4])
        with self.assertRaises(ValueError): m.event('AFTER',[BASE,1,2,3,5])
        with self.assertRaises(ValueError): m.checkpoint(bytes(SIZE))
