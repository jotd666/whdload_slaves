import unittest
from sky_records import state,equal,ROOT


class SkyRecordsTests(unittest.TestCase):
    def fixture(self):
        raw=bytearray(0x10000)
        def put(at,value,n=4):raw[at:at+n]=value.to_bytes(n,'big')
        for at,value in [(ROOT,3),(0x8e0,3)]:put(at,value,2)
        for at,value in [(0x49aa,0x100),(0x49ae,0x200),(0x49bc,0x300),(0x49d0,0x100),(0x49d4,0x8d70),(0x100,0x49b2),(0x104,0x200),(0x108,0x206)]:put(at,value)
        return raw,[(0xf8,20),(0x1f8,20),(0x2f8,14)],put

    def test_compares_all_records_phases_and_scalar_bytes(self):
        for at in (0x200,0x20b,0x300,0x305,0x49b2,0x49d9):
            raw,e,put=self.fixture();read=lambda p,n:bytes(raw[p:p+n]);a=state(read,0,e)
            put(at,1,1)
            with self.assertRaises(ValueError):equal(a,state(read,0,e))

    def test_rejects_wrong_table_and_selected_context(self):
        for at,value in ((0x100,0x200),(0x108,0x204),(0x49d0,0x104),(0x49d4,0x8d74)):
            raw,e,put=self.fixture();put(at,value)
            with self.assertRaises(ValueError):state(lambda p,n:bytes(raw[p:p+n]),0,e)

    def test_requires_exact_allocations_and_count(self):
        raw,e,put=self.fixture();e[1]=(0x1f8,22)
        with self.assertRaises(ValueError):state(lambda p,n:bytes(raw[p:p+n]),0,e)
        raw,e,put=self.fixture();put(0x8e0,2,2)
        with self.assertRaises(ValueError):state(lambda p,n:bytes(raw[p:p+n]),0,e)

    def test_nonuniform_allocation_moves_keep_explicit_identity(self):
        raw,e,put=self.fixture();read=lambda p,n:bytes(raw[p:p+n]);before=state(read,0,e)
        raw[0x600:0x60c]=raw[0x100:0x10c]
        raw[0x700:0x70c]=raw[0x200:0x20c]
        raw[0x800:0x806]=raw[0x300:0x306]
        for at,value in ((0x49aa,0x600),(0x49ae,0x700),(0x49bc,0x800),(0x49d0,0x600),(0x604,0x700),(0x608,0x706)):
            put(at,value)
        after=state(read,0,[(0x5f8,20),(0x6f8,20),(0x7f8,14)])
        equal(before,after)
        self.assertNotEqual(before['raw_descriptor'],after['raw_descriptor'])
