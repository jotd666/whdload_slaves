import unittest
from visibility_scratch import operation, cases


class VisibilityScratchTests(unittest.TestCase):
    def test_only_z_and_named_bit_change(self):
        for old in range(256):
            for clear in (0, 1):
                for ccr in range(32):
                    value, flags = operation(old, clear, ccr)
                    self.assertEqual((value ^ old) & 223, 0)
                    self.assertEqual(value & 32, 0 if clear else 32)
                    self.assertEqual(flags & 27, ccr & 27)
                    self.assertEqual(bool(flags & 4), not bool(old & 32))

    def test_native_case_coverage_and_corruption(self):
        raw = b''.join(bytes((old, clear, *operation(old, clear, 27)))
                       for clear in (0, 1) for old in range(256))
        self.assertEqual(cases(raw), 512)
        for bad in (raw[:-4], raw[4:]+raw[:4], bytes(2048)):
            with self.assertRaises(ValueError): cases(bad)
        bad = bytearray(raw); bad[3] ^= 1
        with self.assertRaises(ValueError): cases(bad)
