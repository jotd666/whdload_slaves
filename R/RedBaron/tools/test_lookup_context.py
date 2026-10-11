import unittest
from lookup_context import lookup


class LookupContextTests(unittest.TestCase):
    def fixture(self,h3=0):
        raw=bytearray(0xb000);raw[h3+0x48fc:h3+0x491c]=bytes(range(32))
        raw[h3+0x8d86:h3+0x8d8a]=(h3+0x48fc).to_bytes(4,'big')
        return raw

    def test_exact_owner_can_relocate(self):
        a=self.fixture();b=self.fixture(0x1000)
        pa,da=lookup(lambda p,n:bytes(a[p:p+n]),0)
        pb,db=lookup(lambda p,n:bytes(b[p:p+n]),0x1000)
        self.assertNotEqual(pa,pb);self.assertEqual(da,db)

    def test_interior_owner_and_last_byte_changes_fail(self):
        for at in (0x8d89,0x491b):
            raw=self.fixture();raw[at]^=1
            with self.assertRaises(ValueError):lookup(lambda p,n:bytes(raw[p:p+n]),0)

    def test_truncated_lookup_fails(self):
        raw=self.fixture()
        with self.assertRaises(ValueError):lookup(lambda p,n:bytes(raw[p:p+n-1]),0)
