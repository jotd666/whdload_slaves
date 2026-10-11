import struct
import unittest
from shape_selection import selection


class ShapeSelectionTests(unittest.TestCase):
    def setUp(self):
        self.ram = bytearray(0xb000)
        struct.pack_into('>I', self.ram, 0x4262, 0x100)
        struct.pack_into('>H', self.ram, 0x426a, 2)
        struct.pack_into('>I', self.ram, 0xa278, 0x10c)
        struct.pack_into('>IHHHH', self.ram, 0x10c, 0x200, 22, 256, 256, 3)
        self.ram[0x4278:0x427c] = bytes.fromhex('01000100')

    def read(self, address, size):
        return self.ram[address:address + size]

    def test_selected_record_matches(self):
        self.assertEqual(selection(self.read, 0),
                         dict(index=1, list_count=2, scale='01000100'))

    def test_stale_scale_is_rejected(self):
        self.ram[0x427b] = 1
        with self.assertRaisesRegex(ValueError, 'Cached shape scale'):
            selection(self.read, 0)

    def test_pointer_must_be_record_aligned_and_in_table(self):
        for pointer in (0xfe, 0x102, 0x118):
            struct.pack_into('>I', self.ram, 0xa278, pointer)
            with self.assertRaisesRegex(ValueError, 'outside table'):
                selection(self.read, 0)

    def test_empty_selection_rejected(self):
        self.ram[0x10c:0x110] = bytes(4)
        with self.assertRaisesRegex(ValueError, 'empty'):
            selection(self.read, 0)


if __name__ == '__main__':
    unittest.main()
