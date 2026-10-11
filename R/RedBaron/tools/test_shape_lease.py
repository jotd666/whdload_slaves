import struct
import unittest
from shape_lease import check_draw, check_selftest, state


class ShapeLeaseTests(unittest.TestCase):
    def setUp(self):
        self.before = bytearray(0xb000)
        struct.pack_into('>I', self.before, 0x4262, 0x100)
        struct.pack_into('>H', self.before, 0x426a, 2)
        for i, scale in enumerate(((256, 256), (255, 90))):
            struct.pack_into('>IHHHH', self.before, 0x100+12*i, 0x200, 22, *scale, 3)
        self.select(self.before, 0)
        self.rendered = self.before.copy()
        self.select(self.rendered, 1)
        self.after = self.before.copy()

    @staticmethod
    def select(ram, index):
        pointer = 0x100+12*index
        struct.pack_into('>I', ram, 0xa278, pointer)
        ram[0x4278:0x427c] = ram[pointer+6:pointer+10]

    @staticmethod
    def read(ram):
        return lambda at, n: ram[at:at+n]

    def check(self, saved=None):
        before = self.read(self.before)
        return check_draw(before, self.read(self.rendered), self.read(self.after),
                          0, state(before, 0) if saved is None else saved)

    def test_changed_selection_restored(self):
        self.assertEqual(self.check(), 1)

    def test_restore_must_include_pointer_and_scales(self):
        self.after = self.rendered.copy()
        with self.assertRaisesRegex(ValueError, 'leaked'):
            self.check()

    def test_saved_bytes_and_resource_lifetime(self):
        with self.assertRaisesRegex(ValueError, 'Saved'):
            self.check(bytes(8))
        self.after[0x117] ^= 1  # unrelated record metadata cannot be normalized
        with self.assertRaisesRegex(ValueError, 'resource table changed'):
            self.check()

    def test_native_private_selftest_evidence(self):
        cases = struct.pack('>6I', 0, 0xffffffff, 0x01000100, 0x002468ac, 0x00ff005a, 0x0013579c)
        storage = struct.pack('>4I', 0x13579bdf, 0x00ff005a, 0x0013579c, 0x2468ace0)
        result = struct.pack('>I', 3)
        self.assertEqual(check_selftest(cases, storage, result)['cases'], 3)
        for i, part in enumerate((cases, storage, result)):
            parts = [cases, storage, result]
            parts[i] = part[:-1] + bytes([part[-1] ^ 1])
            with self.subTest(part=i), self.assertRaises(ValueError):
                check_selftest(*parts)

    def test_truncated_state(self):
        with self.assertRaisesRegex(ValueError, 'Truncated'):
            state(lambda at, n: bytes(n-1), 0)


if __name__ == '__main__':
    unittest.main()
