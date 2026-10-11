import struct
import unittest
from player_links import linked_state,compare,CALLBACK


class PlayerLinkTests(unittest.TestCase):
    def fixture(self,shift=0):
        record=bytearray(280);sim=0x10000+shift
        struct.pack_into('>II',record,26,sim+CALLBACK,1008+shift)
        struct.pack_into('>I',record,120,2008+shift)
        payloads={1008+shift:b'abc',2008+shift:b'defg'}
        return record,lambda at,n:payloads[at][:n],[(1000+shift,11),(2000+shift,12)],sim

    def test_explicit_relocation_with_full_payloads(self):
        compare(linked_state(*self.fixture()),linked_state(*self.fixture(400)))

    def test_other_numeric_bytes_are_not_normalized(self):
        a=self.fixture();b=self.fixture(400);b[0][16]=1
        with self.assertRaises(ValueError):compare(linked_state(*a),linked_state(*b))

    def test_payload_tail_and_callback_changes_rejected(self):
        a=self.fixture();b=list(self.fixture(400));b[1]=lambda at,n:(b'abc' if at==1408 else b'defX')[:n]
        with self.assertRaises(ValueError):compare(linked_state(*a),linked_state(*b))
        b=self.fixture();b[0][29]^=2
        with self.assertRaises(ValueError):linked_state(*b)

    def test_owner_extent_alignment_and_short_reads(self):
        for extents in ([(1000,12),(2000,12)],[(999,12),(2000,12)],[(1000,11),(1000,11),(2000,12)]):
            b=list(self.fixture());b[2]=extents
            with self.assertRaises(ValueError):linked_state(*b)
        b=list(self.fixture());b[1]=lambda at,n:b''
        with self.assertRaises(ValueError):linked_state(*b)
