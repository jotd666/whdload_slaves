import unittest
from weapon_links import state, equal, AIRCRAFT_STRIDE, POOL, STRIDE


class WeaponLinkTests(unittest.TestCase):
    def fixture(self,h3=0,shift=0):
        raw=bytearray(0x10000)
        def put(at,v,n=4):raw[at:at+n]=v.to_bytes(n,'big')
        aircraft=0x100+shift;ammo=0x500+shift
        put(h3+0x5578,1,2);put(h3+0x135c,AIRCRAFT_STRIDE,2);put(h3+0x5584,aircraft)
        put(aircraft+120,ammo);put(ammo,17);put(h3+0x583c,ammo)
        put(h3+0x5844+20,h3+POOL+3*STRIDE)
        raw[h3+0x5844+239-4]=7
        return raw,[(aircraft-8,AIRCRAFT_STRIDE+8),(ammo-8,12)],put

    def test_explicit_owners_survive_independent_relocation(self):
        a,e,_=self.fixture();b,f,_=self.fixture(0x1000,0x80)
        sa=state(lambda p,n:bytes(a[p:p+n]),0,e)
        sb=state(lambda p,n:bytes(b[p:p+n]),0x1000,f)
        equal(sa,sb);self.assertEqual(sa['selected'],0);self.assertEqual(sa['records'][0]['owner'],3)
        self.assertNotEqual(sa['raw_table'],sb['raw_table'])

    def test_rejects_pointer_into_payload_or_projectile(self):
        for at,value in ((0x583c,0x502),(0x5844+20,POOL+1),(0x5844+20,POOL+50*STRIDE)):
            raw,e,put=self.fixture();put(at,value)
            with self.assertRaises(ValueError):state(lambda p,n:bytes(raw[p:p+n]),0,e)

    def test_all_bodies_and_ammunition_remain_exact(self):
        for at in (0x500,0x5844,0x5844+235):
            raw,e,_=self.fixture();read=lambda p,n:bytes(raw[p:p+n]);before=state(read,0,e);raw[at]^=1
            with self.assertRaises(ValueError):equal(before,state(read,0,e))

    def test_null_selection_is_distinct_and_wrong_extent_rejected(self):
        raw,e,put=self.fixture();read=lambda p,n:bytes(raw[p:p+n]);before=state(read,0,e)
        put(0x583c,0);after=state(read,0,e);self.assertIsNone(after['selected'])
        with self.assertRaises(ValueError):equal(before,after)
        e[1]=(e[1][0],16)
        with self.assertRaises(ValueError):state(read,0,e)
