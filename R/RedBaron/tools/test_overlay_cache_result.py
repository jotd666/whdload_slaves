import struct
import unittest
from overlay_cache_result import check


class FrontCacheResultTests(unittest.TestCase):
    def test_native_result(self):
        self.assertEqual(check(struct.pack('>4I', 3, 0, 0, 2),
                               struct.pack('>3I', 306, 2, 0))['programs'], [3, 4])

    def test_three_sabotages_cannot_pass(self):
        for values in ((1, 0, 0, 2), (3, 0, 0, 1), (3, 0, 0x10000, 2)):
            with self.subTest(values=values), self.assertRaises(ValueError):
                check(struct.pack('>4I', *values), struct.pack('>3I', 306, 2, 0))

    def test_solid_native_result_and_three_sabotages(self):
        counter = struct.pack('>3I', 166, 1, 0)
        self.assertEqual(check(struct.pack('>4I', 1, 0, 0, 1), counter, (2,))['programs'], [2])
        for header in ((0,0,0,1), (1,0,0,2), (1,0,0x10000,1)):
            with self.subTest(header=header), self.assertRaises(ValueError):
                check(struct.pack('>4I', *header), counter, (2,))

    def test_empty_case_list_cannot_pass(self):
        with self.assertRaises(ValueError):
            check(bytes(16), bytes(12), ())
