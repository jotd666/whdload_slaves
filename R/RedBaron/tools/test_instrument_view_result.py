import copy
import struct
import unittest
from instrument_view_result import check


class InstrumentViewResultTests(unittest.TestCase):
    def setUp(self):
        self.header = struct.pack('>8I', 127, 0, 0, 7, 0, 0, 0, 0)
        self.counters = struct.pack('>2I', 100, 7)
        self.rows = [dict(label=n, view=v, publications=5, gauge_entries=35 if v == 0 else 0)
                     for n,v in [('front',0),('rear',1),('left',2),('right',3),('front-return',0)]]

    def test_complete_sequence(self):
        self.assertEqual(len(check(self.header,self.counters,self.rows)['views']),5)

    def test_three_sabotages(self):
        for field,value in [('view',0),('gauge_entries',1),('publications',0)]:
            rows=copy.deepcopy(self.rows);rows[1][field]=value
            with self.subTest(field=field), self.assertRaises(ValueError):
                check(self.header,self.counters,rows)

    def test_front_return_and_native_twin_are_required(self):
        rows=copy.deepcopy(self.rows);rows[-1]['gauge_entries']=0
        for header,case in [(self.header,rows),(bytes(32),self.rows),(self.header,self.rows[:-1])]:
            with self.assertRaises(ValueError):check(header,self.counters,case)
