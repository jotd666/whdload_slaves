import struct
import unittest
from instrument_cache import Cache, KEY_BYTES, build_key, writes
from instrument_pixels import Region


class InstrumentCacheTests(unittest.TestCase):
    def setUp(self):
        self.mem = bytearray(0x30000)
        self.h3 = 0x1000
        self.bg = 0x20000
        self.table = 0x21000
        self.dyn = 0x22000
        self.aircraft = 0x23000
        self.put(self.h3+0x4578, self.aircraft)
        self.put(self.h3+0x7120, self.table)
        self.put(self.table+8, self.dyn)
        self.put(self.table+24, self.dyn)
        self.mem[self.h3+0x1e88] = 1
        self.rect = (112, 143, 20, 15)

    def put(self, address, value):
        self.mem[address:address+4] = value.to_bytes(4, 'big')

    def read(self, address, size):
        return bytes(self.mem[address:address+size])

    def key(self, gauge=0):
        return build_key(self.read, self.h3, gauge, 103, 130, self.bg, self.rect)

    def test_layout_matches_native_fixed_record(self):
        for gauge in range(7):
            data = self.key(gauge)
            self.assertEqual(len(data), KEY_BYTES)
            self.assertEqual(data[12:16], struct.pack('>hh', 103, 130))
            self.assertEqual(data[16:20], struct.pack('>I', self.bg))
            self.assertEqual(data[88:96], struct.pack('>4h', *self.rect))
            self.assertEqual(data[280:], bytes(8))

    def test_resource_descriptors_and_context_change_key(self):
        for gauge in range(7):
            original = self.key(gauge)
            addresses = [self.bg, self.bg+8, self.h3+0x9d72, self.h3+0x9d34,
                         self.h3+0x1e88, self.h3+0x7670, self.h3+0x1b1a,
                         self.h3+0x1bcd, self.h3+0x7114, self.h3+0x7118]
            if gauge in (1, 3):
                addresses.append(self.dyn+8)
            for at in addresses:
                self.mem[at] ^= 1
                self.assertNotEqual(self.key(gauge), original)
                self.mem[at] ^= 1

    def test_native_upper_coordinate_flags_are_keyed(self):
        original = self.key()
        for i in range(4):
            high = [0, 0, 0, 0]; high[i] = 2
            changed = build_key(self.read, self.h3, 0, 103, 130, self.bg,
                                self.rect, tuple(high))
            self.assertNotEqual(changed, original)
            self.assertEqual(changed[280:], struct.pack('>4H', *high))

    def test_extended_clip_uses_native_drawing(self):
        self.mem[self.h3+0x1e88] = 0
        self.assertIsNone(self.key())

    def test_mirrored_resources_require_native_drawing(self):
        self.mem[self.bg+17] = 2
        self.assertIsNone(self.key())
        self.mem[self.bg+17] = 0
        self.mem[self.dyn+17] = 1
        self.assertIsNone(self.key(1))
        self.assertIsNone(self.key(3))
        self.assertIsNotNone(self.key(4))

    def test_cache_requires_fixed_bounds_context_pixels_and_same_page(self):
        c = Cache(); screen = bytearray(40000); area = Region(12, 142, 6, 19)
        k = self.key(); post = {(0x9d46, 10): bytes(10)}
        self.assertFalse(c.remember(0, k, area, self.rect, (113, 143, 20, 15), screen, post))
        self.assertIsNone(c.reuse(0, k, screen))
        self.assertTrue(c.remember(0, k, area, self.rect, self.rect, screen, post))
        self.assertEqual(c.reuse(0, k, screen), post)
        for kwargs in ({'forced': True}, {'dirty': True}):
            self.assertIsNone(c.reuse(0, k, screen, **kwargs))
        self.assertIsNone(c.reuse(1, k, screen))
        self.assertIsNone(c.reuse(0, bytes(KEY_BYTES), screen))
        screen[142*40+12] = 1
        self.assertIsNone(c.reuse(0, k, screen))
        screen[142*40+12] = 0
        c.invalidate()
        self.assertIsNone(c.reuse(0, k, screen))

    def test_state_replay_does_not_restore_other_gauges_scratch(self):
        self.assertEqual(writes(1), writes(3))
        self.assertNotIn((0x9d52, 2), writes(1))
        self.assertIn((0x7914, 8), writes(0))
        self.assertNotIn((0x7914, 8), writes(4))
        self.assertIn((0x7116, 2), writes(2))
        self.assertIn((0x711a, 2), writes(2))
        for gauge in (0, 1, 3, 4, 5, 6):
            self.assertNotIn((0x7116, 2), writes(gauge))


if __name__ == '__main__':
    unittest.main()
