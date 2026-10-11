import unittest
from geometry_cache import Cache


class GeometryCacheTests(unittest.TestCase):
    def fresh(self):
        c = Cache(); c.event('RESET', [3, 0]); return c

    def miss(self, c):
        c.event('FETCH', [32, 1, 0, 999, 999, 999])
        # Identity, scale one, signed word -1, translated with longword wrap.
        c.event('INPUT', [65535, 2, 3]+[0]*9+[0, 1, 1, 0xffffffff, 10])
        c.event('RESULT', [32, 1, 1, 0xffffffff, 3, 16, 0xffffffff, 3, 16])

    def test_miss_then_hit_and_new_epoch(self):
        c = self.fresh(); self.miss(c)
        c.event('FETCH', [32, 1, 3, 0xffffffff, 3, 16])
        c.event('RESULT', [32, 1, 3, 0xffffffff, 3, 16, 0xffffffff, 3, 16])
        c.checkpoint()
        c.event('RESET', [3, 0])
        with self.assertRaisesRegex(ValueError, 'epoch'):
            c.event('FETCH', [32, 1, 1, 0xffffffff, 3, 16])

    def test_corrupted_miss_or_scratch(self):
        for bad in (3, 6):
            c = self.fresh(); c.event('FETCH', [32, 0, 0, 0, 0, 0])
            c.event('INPUT', [1, 2, 3]+[0]*9+[0, 0, 0, 0, 0])
            result = [32, 0, 1, 1, 2, 3, 1, 2, 3]; result[bad] += 1
            with self.assertRaises(ValueError): c.event('RESULT', result)

    def test_missing_input_and_incomplete_call(self):
        c = self.fresh(); c.event('FETCH', [32, 0, 0, 0, 0, 0])
        with self.assertRaises(ValueError): c.checkpoint()
        with self.assertRaises(ValueError): c.event('RESULT', [32, 0, 1, 1, 2, 3, 1, 2, 3])
        with self.assertRaises(ValueError): c.event('RESET', [3, 0])

    def test_index_bounds_and_dirty_reset(self):
        for row in ([32, 3, 0, 0, 0, 0], [32, -1, 0, 0, 0, 0]):
            with self.assertRaises(ValueError): self.fresh().event('FETCH', row)
        with self.assertRaises(ValueError): Cache().event('RESET', [3, 1])

    def test_16_bit_provenance_and_word_copy(self):
        c = self.fresh()
        c.event('FETCH', [16, 0, 0, 99, 99, 99])
        c.event('RESULT', [16, 0, 1, 0xffffffff, 2, 3, 65535, 2, 3])
        c.event('FETCH', [17, 0, 1, 0xffffffff, 2, 3])
        c.event('RESULT', [17, 0, 1, 0xffffffff, 2, 3, 65535, 2, 3])
        c.checkpoint()
        self.assertEqual(c.stats['16_miss'], 1)
        self.assertEqual(c.stats['17_hit'], 1)

    def test_whole_arrays_reject_unobserved_write(self):
        import struct
        c = Cache(bytes(3060)); c.event('RESET', [3, 0]); self.miss(c)
        expected = bytearray(3060)
        for axis, value in enumerate((0xffffffff, 3, 16)):
            struct.pack_into('>I', expected, axis*1020+4, value)
        c.checkpoint(expected)
        c.event('RESET', [0, 0]); c.checkpoint(expected)
        expected[-1] = 1
        with self.assertRaisesRegex(ValueError, 'Unobserved'):
            c.checkpoint(expected)
