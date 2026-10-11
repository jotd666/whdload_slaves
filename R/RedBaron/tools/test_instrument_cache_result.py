import struct
import unittest
from instrument_cache_result import check


class InstrumentCacheResultTests(unittest.TestCase):
    def test_valid(self):
        self.assertEqual(check(struct.pack('>8I',127,0,0,7,0,0,0,0),
                               struct.pack('>2I',30,14))['gauges'], 7)

    def test_three_sabotages(self):
        for header, counts in [((63,0,0,6,0,0),(30,14)),
                               ((127,0,0,7,2,12),(30,14)),
                               ((127,0,0,7,0,0),(0,14))]:
            with self.assertRaises(ValueError):
                check(struct.pack('>8I', *header, 0, 0), struct.pack('>2I', *counts))

    def test_unreleased_scratch_and_short_records(self):
        with self.assertRaises(ValueError):
            check(struct.pack('>8I',127,0,4096,7,0,0,0,0), struct.pack('>2I',30,14))
        with self.assertRaises(ValueError):
            check(bytes(20), bytes(8))
