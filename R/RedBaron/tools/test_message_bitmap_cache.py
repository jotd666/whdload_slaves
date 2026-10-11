import unittest
from message_bitmap_cache import bitmap_size,slots


class MessageBitmapTests(unittest.TestCase):
    def test_native_padding_and_observed_sizes(self):
        self.assertEqual(bitmap_size(121,20,5),1800)
        self.assertEqual(bitmap_size(97,20,5),1600)
        self.assertEqual([bitmap_size(w,1,1) for w in (1,16,17,32,33)],[4,4,6,6,8])
        with self.assertRaises(ValueError):bitmap_size(0,20,5)

    def fixture(self):
        raw=bytearray(0xa000)
        def put(at,v,n=2):raw[at:at+n]=v.to_bytes(n,'big')
        put(0x44e6,0x100,4);put(0x44a4,123);put(0x456e,121);put(0x4570,20);put(0x9d3c,5)
        return raw,[(0xf8,1808)],put

    def test_complete_owned_bitmap_and_stable_dimensions(self):
        raw,e,put=self.fixture();seen={};read=lambda p,n:bytes(raw[p:p+n]);a=slots(read,0,e,seen)
        self.assertEqual(a[0]['size'],1800)
        put(0x456e,97);self.assertEqual(slots(read,0,e,seen)[0]['dimensions'],(121,20,5))
        raw[0x100+1799]=1;self.assertNotEqual(a[0]['sha256'],slots(read,0,e,seen)[0]['sha256'])

    def test_bad_extent_duplicate_owner_and_missing_key_fail(self):
        for kind in ('extent','duplicate','key'):
            raw,e,put=self.fixture()
            if kind=='extent':e=[(0xf8,1608)]
            elif kind=='duplicate':put(0x44ea,0x100,4);put(0x44a6,124)
            else:put(0x44a4,0)
            with self.assertRaises(ValueError):slots(lambda p,n:bytes(raw[p:p+n]),0,e,{})
