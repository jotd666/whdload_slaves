import struct
import unittest
from auxiliary_pools import callbacks,payload


class AuxiliaryPoolTests(unittest.TestCase):
    def test_only_explicit_callbacks_relocate(self):
        def records(sim):
            raw=bytearray(132)
            for i,off in enumerate((0,0xdb70,0xdb9e)):
                struct.pack_into('>I',raw,44*i+26,sim+off if off else 0)
            return raw
        self.assertEqual(callbacks(records(100000),100000),callbacks(records(200000),200000))
        raw=records(100000);raw[29]=1
        with self.assertRaises(ValueError):callbacks(raw,100000)

    def test_inactive_tail_and_record_order_are_retained(self):
        raw=bytearray(88);before=callbacks(raw,100000);raw[-1]=1
        self.assertNotEqual(before,callbacks(raw,100000))
        self.assertNotEqual(callbacks(raw,100000),callbacks(raw[44:]+raw[:44],100000))
        with self.assertRaises(ValueError):callbacks(raw[:-1],100000)

    def test_exact_allocation_extent(self):
        read=lambda at,n:bytes(n)
        self.assertEqual(len(payload(read,[(1000,96)],1008,2,44)),88)
        for extents,pointer in (([(1000,52)],1008),([(1000,96)],1010),([(1000,96),(1000,96)],1008)):
            with self.assertRaises(ValueError):payload(read,extents,pointer,2,44)
        with self.assertRaises(ValueError):payload(lambda at,n:b'',[(1000,96)],1008,2,44)
