import unittest
from geometry_cache import Cache
from projected_cache import Projected, project, divword


class ProjectionTests(unittest.TestCase):
    def test_native_signed_division_and_rejected_overflow(self):
        self.assertEqual(divword((-7)&0xffffffff,3),0xfffffffe)
        self.assertEqual(divword(7,65533),0xfffffffe)
        for n,d in ((1,0),(32768,1),(0x80000000,65535)):
            with self.assertRaises(ValueError): divword(n,d)

    def test_projection_paths(self):
        for path in (16,32):
            self.assertEqual(project(path,[4,8,2],[4,8,2],3),[4,2])
        for path in (17,33):
            self.assertEqual(project(path,[10,20,30],[14,28,38],24),[12,34])
        self.assertEqual(project(16,[0xfffffffc,8,2],[0xfffffffc,8,2],3),[0xfffffffc,2])

    def fresh(self):
        g=Cache(); g.event('RESET',[2,0]); g.values[0]=[4,8,2]
        return Projected(g,bytes(2040))

    def test_write_read_and_epoch_reset(self):
        m=self.fresh();m.event('BEGIN',[32,0,4,8,2,3]);m.event('END',[32,0,4,2])
        m.event('READ',[0x3b37e,0,0,4]);m.event('READ',[0x3b386,1,0,2])
        m.checkpoint(m.data);m.reset()
        with self.assertRaisesRegex(ValueError,'stale'):m.event('READ',[0x3b37e,0,0,4])

    def test_unobserved_source_result_and_storage(self):
        m=self.fresh()
        with self.assertRaises(ValueError):m.event('BEGIN',[32,1,4,8,2,3])
        m.event('BEGIN',[32,0,4,8,2,3])
        with self.assertRaises(ValueError):m.event('END',[32,0,5,2])
        with self.assertRaises(ValueError):m.checkpoint(m.data)
        m.event('END',[32,0,4,2]);data=bytearray(m.data);data[-1]=1
        with self.assertRaises(ValueError):m.checkpoint(data)

    def test_bad_or_misaligned_consumer(self):
        m=self.fresh();m.event('BEGIN',[32,0,4,8,2,3]);m.event('END',[32,0,4,2])
        for row in ([0x3b37e,1,0,2],[0x3b37e,0,1,4],[0x3b37e,0,1020,4],[0x3b37e,0,0,5]):
            with self.assertRaises(ValueError):m.event('READ',row)

    def test_clip_word_multiply_and_signed_truncation(self):
        # The word clip multiplies low signed words, not full cache deltas.
        self.assertEqual(project(17,[0,5,0],[65543,8,65529],6),[2,0xfffffffe])
        # Shift counts use six bits; a shifted-out numerator produces zero.
        self.assertEqual(project(16,[4,8,2],[4,8,2],64),[0,0])
        self.assertEqual(project(16,[4,8,2],[4,8,2],32),[0,0])
