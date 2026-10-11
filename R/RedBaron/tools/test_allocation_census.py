import struct
import unittest
from allocation_census import decode, summarize

class AllocationCensusTest(unittest.TestCase):
    def header(self, count=2, overflow=0, active=0):
        return b'RBALLOC1'+struct.pack('>9I',count,overflow,active,0,0,0,0,8192,24)

    def records(self):
        return struct.pack('>12I',100,1,0x10000,24,0,0,100,0xffffffff,0x10000,0,0,1)

    def test_lifetime_peak(self):
        r = summarize(decode(self.header(),self.records()))
        self.assertEqual(r['peak_spill_bytes'],104)
        self.assertEqual(r['live_spill_bytes'],0)
        self.assertEqual(len(r['spill_requests']),1)

    def test_overflow_rejected(self):
        with self.assertRaises(ValueError): decode(self.header(overflow=1),self.records())

    def test_active_rejected(self):
        with self.assertRaises(ValueError): decode(self.header(active=1),self.records())

    def test_truncated_rejected(self):
        with self.assertRaises(ValueError): decode(self.header(),self.records()[:-1])
