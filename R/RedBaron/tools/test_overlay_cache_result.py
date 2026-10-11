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
