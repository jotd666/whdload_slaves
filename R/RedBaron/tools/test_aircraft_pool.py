import copy
import struct
import unittest
from aircraft_pool import state,equal,STRIDE
from player_links import CALLBACK


class AircraftPoolTests(unittest.TestCase):
    def fixture(self):
        data=bytearray(0x20000);base=0x10000;sim=0x100000
        struct.pack_into('>H',data,0x135c,STRIDE);struct.pack_into('>H',data,0x5578,2);struct.pack_into('>I',data,0x5584,base+8)
        extents=[(base,8+2*STRIDE)]
        for i in range(2):
            p=base+8+i*STRIDE;a=0x18000+i*32;b=a+16
            struct.pack_into('>II',data,p+26,sim+CALLBACK,a+8);struct.pack_into('>I',data,p+120,b+8)
            extents.extend([(a,11),(b,12)]);data[p+317]=i
        return data,lambda a,n:bytes(data[a:a+n]),extents,sim

    def test_complete_pool_including_tail(self):
        data,read,extents,sim=self.fixture();a=state(read,0,sim,extents);equal(a,copy.deepcopy(a))
        data[0x10008+STRIDE+317]^=1
        with self.assertRaises(ValueError):equal(a,state(read,0,sim,extents))

    def test_reject_partial_pool_or_changed_stride(self):
        data,read,extents,sim=self.fixture();extents[0]=(0x10000,8+STRIDE)
        with self.assertRaises(ValueError):state(read,0,sim,extents)
        data,read,extents,sim=self.fixture();struct.pack_into('>H',data,0x135c,280)
        with self.assertRaises(ValueError):state(read,0,sim,extents)

    def test_slot_order_is_preserved(self):
        data,read,extents,sim=self.fixture();a=state(read,0,sim,extents);b=copy.deepcopy(a);b['rows'].reverse()
        with self.assertRaises(ValueError):equal(a,b)
