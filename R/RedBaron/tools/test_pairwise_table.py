import unittest
from pairwise_table import state,equal,STRIDE


class PairwiseTableTests(unittest.TestCase):
    def fixture(self):
        raw=bytearray(0x10000);extents=[(0x100-8,12),(0x200-8,12),(0x300-8,16),(0x400-8,2*STRIDE+8)]
        def put(at,value,n=4):raw[at:at+n]=value.to_bytes(n,'big')
        for at,value in [(0x4c30,0x100),(0x4c34,0x200),(0x4c38,0x300),(0x5584,0x400),(0x100,0x200),(0x200,123),(0x300,0x400),(0x304,0x400+STRIDE)]:put(at,value)
        for at,value in [(0x4c3c,1),(0x4c3e,2),(0x135c,STRIDE),(0x5578,2),(0x400+106,0),(0x400+STRIDE+106,1)]:put(at,value,2)
        return raw,extents,put

    def test_complete_values_and_ids(self):
        raw,e,put=self.fixture();read=lambda p,n:bytes(raw[p:p+n]);a=state(read,0,e)
        self.assertEqual(a['objects'],[0,1]);self.assertEqual(a['values'],'0000007b')
        put(0x200,124)
        with self.assertRaises(ValueError):equal(a,state(read,0,e))

    def test_rejects_wrong_row_owner_and_duplicate_object(self):
        for at,value in ((0x100,0x204),(0x304,0x400)):
            raw,e,put=self.fixture();put(at,value)
            with self.assertRaises(ValueError):state(lambda p,n:bytes(raw[p:p+n]),0,e)

    def test_rejects_allocation_and_count_mismatch(self):
        raw,e,put=self.fixture();e[1]=(0x200-8,16)
        with self.assertRaises(ValueError):state(lambda p,n:bytes(raw[p:p+n]),0,e)
        raw,e,put=self.fixture();put(0x4c3c,2,2)
        with self.assertRaises(ValueError):state(lambda p,n:bytes(raw[p:p+n]),0,e)

    def test_three_object_triangle_uses_variable_row_lengths(self):
        raw,e,put=self.fixture()
        e=[(0x100-8,16),(0x200-8,20),(0x300-8,20),(0x400-8,3*STRIDE+8)]
        put(0x4c3c,3,2);put(0x4c3e,3,2);put(0x5578,3,2)
        put(0x104,0x204);put(0x204,124);put(0x208,125)
        put(0x308,0x400+2*STRIDE);put(0x400+2*STRIDE+106,2,2)
        read=lambda p,n:bytes(raw[p:p+n])
        a=state(read,0,e)
        self.assertEqual(a['values'],'0000007b0000007c0000007d')
        self.assertEqual(a['objects'],[0,1,2])
        put(0x104,0x208)
        with self.assertRaises(ValueError):state(read,0,e)
