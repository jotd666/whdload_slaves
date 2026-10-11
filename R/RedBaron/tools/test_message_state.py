import unittest
from message_state import state,equal


class MessageStateTests(unittest.TestCase):
    def fixture(self,h3=0):
        raw=bytearray(0x7000);original=bytearray(256);original[16:24]=b'one\0two\0'
        raw[h3+16:h3+24]=original[16:24]
        raw[h3+0x481c:h3+0x4820]=(h3+16).to_bytes(4,'big')
        raw[h3+0x482e]=2
        return raw,bytes(original)

    def test_static_multiline_owner_relocates(self):
        a,o=self.fixture();b,_=self.fixture(0x1000)
        sa=state(lambda p,n:bytes(a[p:p+n]),0,o);sb=state(lambda p,n:bytes(b[p:p+n]),0x1000,o)
        equal(sa,sb);self.assertEqual(sa['owners'][0]['text'],b'one\0two\0'.hex())
        self.assertNotEqual(sa['raw'],sb['raw'])

    def test_descriptor_scalar_and_line_count_not_masked(self):
        for at in (0x4820,0x4828,0x482e,0x482f,0x4831):
            raw,o=self.fixture();read=lambda p,n:bytes(raw[p:p+n]);before=state(read,0,o);raw[at]^=1
            with self.assertRaises(ValueError):equal(before,state(read,0,o))

    def test_wrong_text_or_owner_rejected(self):
        raw,o=self.fixture();raw[16]^=1
        with self.assertRaises(ValueError):state(lambda p,n:bytes(raw[p:p+n]),0,o)
        raw,o=self.fixture();raw[0x481c:0x4820]=(0x400).to_bytes(4,'big')
        with self.assertRaises(ValueError):state(lambda p,n:bytes(raw[p:p+n]),0,o)

    def test_secondary_owner_and_null_selection_are_compared(self):
        raw,o=self.fixture();read=lambda p,n:bytes(raw[p:p+n]);before=state(read,0,o)
        raw[0x482a:0x482e]=(16).to_bytes(4,'big')
        with self.assertRaises(ValueError):equal(before,state(read,0,o))
        raw[0x482a:0x482e]=bytes(4);raw[0x481c:0x4820]=bytes(4)
        self.assertIsNone(state(read,0,o)['owners'][0])
        with self.assertRaises(ValueError):equal(before,state(read,0,o))
