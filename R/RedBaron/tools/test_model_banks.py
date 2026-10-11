import struct
import unittest
from model_banks import owned,resources


class ModelBanksTests(unittest.TestCase):
    def fixture(self, pointer=108, size=12, count=1, terminator=0):
        memory={100:struct.pack('>II',pointer,terminator)+b'abcd'}
        read=lambda at,n:memory.get(at,b'')[:n]
        table=struct.pack('>I4H',100,count,256,256,65535)
        return read,[(92,size+8)],table

    def test_complete_resource_and_empty_records_preserved(self):
        read,extents,table=self.fixture()
        result=resources(read,extents,table+bytes(12),2)
        self.assertEqual(result,[(0,1,struct.pack('>II',108,0)+b'abcd')])
        self.assertEqual(owned(read,extents,100,12),result[0][2])

    def test_reject_stale_pointer_bad_count_and_missing_terminator(self):
        for kwargs in ({'pointer':98},{'pointer':100},{'pointer':112},
                       {'pointer':109},{'count':3},{'count':0},{'terminator':1}):
            args=self.fixture(**kwargs)
            with self.assertRaises(ValueError):resources(*args,1)
        read,extents,table=self.fixture()
        with self.assertRaises(ValueError):resources(read,extents,table[:11],1)
        with self.assertRaises(ValueError):resources(read,extents,struct.pack('>I4H',0,1,0,0,0),1)

    def test_reject_interior_truncated_and_wrong_extent(self):
        read,extents,table=self.fixture()
        for pointer,size in ((102,None),(100,10),(0,None)):
            with self.assertRaises(ValueError):owned(read,extents,pointer,size)
        with self.assertRaises(ValueError):owned(read,[(92,24)],100)
        with self.assertRaises(ValueError):owned(read,extents*2,100)
