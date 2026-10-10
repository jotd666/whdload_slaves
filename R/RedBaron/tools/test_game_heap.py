import struct
import unittest
from game_heap import allocations, segments, SIM_SEGMENT_SIZES, ROOT


class HeapTests(unittest.TestCase):
    def setUp(self):
        self.ram = bytearray(0x5000)
        self.ram[ROOT:ROOT+4] = (0x100).to_bytes(4, 'big')
        struct.pack_into('>II', self.ram, 0x100, 17, 0x200)
        struct.pack_into('>II', self.ram, 0x200, 12, 0)

    def read(self, address, size):
        return self.ram[address:address+size]

    def test_complete_unrounded_requested_extents(self):
        self.assertEqual(allocations(self.read, 0), [(0x100, 17), (0x200, 12)])

    def test_reject_cycle(self):
        struct.pack_into('>I', self.ram, 0x204, 0x100)
        with self.assertRaisesRegex(ValueError, 'cyclic'):
            allocations(self.read, 0)

    def test_reject_overlap(self):
        struct.pack_into('>I', self.ram, 0x100, 0x110)
        with self.assertRaisesRegex(ValueError, 'Overlapping'):
            allocations(self.read, 0)

    def test_reject_short_header_or_payload(self):
        for size in (7, 0x5000):
            struct.pack_into('>I', self.ram, 0x100, size)
            with self.assertRaises(ValueError):
                allocations(self.read, 0)


class SegmentTests(unittest.TestCase):
    def test_exact_native_header_sizes_and_bptr_links(self):
        ram = bytearray(0x60000)
        address = 8
        expected = []
        for index, size in enumerate(SIM_SEGMENT_SIZES):
            following = address + size + 8 if index < 3 else 0
            struct.pack_into('>II', ram, address-8, size+8, (following-4)//4 if following else 0)
            expected.append((address, size))
            address = following
        read = lambda at, size: ram[at:at+size]
        self.assertEqual(segments(read, 8), expected)
        ram[3] ^= 4
        with self.assertRaisesRegex(ValueError, 'extent'):
            segments(read, 8)
