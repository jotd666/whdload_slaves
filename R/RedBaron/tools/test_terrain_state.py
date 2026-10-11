import unittest
from terrain_state import state,equal


class TerrainStateTests(unittest.TestCase):
    def fixture(self):
        import struct
        ram=bytearray(0x10050)
        struct.pack_into('>IH',ram,0x526a,0x10008,2)
        ram[0x10008:0x1004c]=bytes(range(68))
        read=lambda at,n:bytes(ram[at:at+n])
        return ram,read,[(0x10000,76)]

    def test_full_records_include_tail_and_order(self):
        ram,read,extents=self.fixture();a=state(read,0,extents)
        self.assertEqual(len(a['records']),68)
        ram[0x1004b]^=1
        with self.assertRaisesRegex(ValueError,'records'):equal(a,state(read,0,extents))
        ram[0x1004b]^=1;ram[0x10008:0x1004c]=ram[0x1002a:0x1004c]+ram[0x10008:0x1002a]
        with self.assertRaisesRegex(ValueError,'records'):equal(a,state(read,0,extents))

    def test_cache_controls_and_transient_context(self):
        ram,read,extents=self.fixture();a=state(read,0,extents)
        ram[0x5274]=1;equal(a,state(read,0,extents))
        self.assertNotEqual(a['builder_position'],state(read,0,extents)['builder_position'])
        for at in (0x5270,0x54de,0x54eb):
            ram[at]^=1
            with self.assertRaisesRegex(ValueError,'controls'):equal(a,state(read,0,extents))
            ram[at]^=1

    def test_invalid_extent_count_and_short_read(self):
        import struct
        ram,read,extents=self.fixture()
        with self.assertRaises(ValueError):state(read,0,[(0x10000,75)])
        struct.pack_into('>H',ram,0x526e,32768)
        with self.assertRaises(ValueError):state(read,0,extents)
        struct.pack_into('>H',ram,0x526e,2)
        with self.assertRaises(ValueError):state(lambda at,n:read(at,max(0,n-1)),0,extents)
