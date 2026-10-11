import struct
import unittest
from cockpit_dependencies import dependencies,matches


class CockpitDependencyTests(unittest.TestCase):
    def fixture(self):
        data=bytearray(0x20000)
        struct.pack_into('>I',data,0x9d34,8000)
        for at,value in ((0x9d3c,5),(0x9d40,320),(0x9d42,40),(0x9d44,200)):
            struct.pack_into('>H',data,at,value)
        struct.pack_into('>I',data,0x7b52+12,0xc000)
        words=[0x2002,8,8,0x1051,1,0x1031,0,0xa502,10,10,0xff0]
        struct.pack_into('>'+str(len(words))+'H',data,0xc000,*words)
        struct.pack_into('>I',data,0x3b06,0xc100)
        struct.pack_into('>I',data,0xc100,0xc180)
        struct.pack_into('>IIHHIH',data,0xc180,0xc200,0xc300,16,2,4,0)
        data[0xc300:0xc308]=bytes.fromhex('8000000040000000')
        return data,lambda a,n:bytes(data[a:a+n])

    def test_exact_key_ignores_destination_and_background(self):
        data,read=self.fixture();key=dependencies(read,0,3)
        data[0x9d72:0x9d76]=(0x10000).to_bytes(4,'big');data[0x10000]=255
        self.assertEqual(key,dependencies(read,0,3))
        self.assertTrue(matches(key,read,3));self.assertFalse(matches(key,read,4))

    def test_resource_palette_program_and_geometry_changes_invalidate(self):
        for offset in (0x3b06,0xc100,0xc180,0xc200,0xc300,0xc004,0x3ab7,0x101d,0x9d40):
            data,read=self.fixture();key=dependencies(read,0,3);data[offset]^=1
            with self.subTest(offset=offset):self.assertFalse(matches(key,read,3))

    def test_changed_pointer_does_not_follow_new_resource(self):
        data,read=self.fixture();key=dependencies(read,0,3)
        struct.pack_into('>I',data,0x3b06,0xffffff00)
        def checked(a,n):
            self.assertLess(a,0x20000)
            return read(a,n)
        self.assertFalse(matches(key,checked,3))

    def test_reject_nonzero_native_mask_padding_and_screen_width(self):
        data,read=self.fixture();data[0xc302]=1
        with self.assertRaisesRegex(ValueError,'pad word'):dependencies(read,0,3)
        data,read=self.fixture();struct.pack_into('>H',data,0x9d40,304)
        with self.assertRaisesRegex(ValueError,'screen extent'):dependencies(read,0,3)

    def test_reject_clipped_native_padding_even_if_opaque_pixels_fit(self):
        data,read=self.fixture();struct.pack_into('>H4h',data,0x9d46,1,0,25,0,199)
        with self.assertRaisesRegex(ValueError,'footprint is clipped'):dependencies(read,0,3)

    def test_missing_reads_fail_closed(self):
        data,read=self.fixture();key=dependencies(read,0,3)
        self.assertFalse(matches(key,lambda a,n:b'',3))
        with self.assertRaises(ValueError):dependencies(lambda a,n:b'',0,3)

    def test_changed_selector_precedes_unavailable_lower_address_resource(self):
        for selector,unavailable in ((0x3b06,0xc100),(0x7b52+12,0xc000)):
            original,_=self.fixture();h3=0x20000;data=bytearray(0x40000)
            data[:len(original)]=original
            data[h3:h3+0xc000]=original[:0xc000]
            read=lambda a,n:bytes(data[a:a+n])
            key=dependencies(read,h3,3)
            struct.pack_into('>I',data,h3+selector,0xffffff00)
            reads=[]
            def guarded(address,size):
                reads.append((address,size))
                if address<=unavailable<address+size:
                    self.fail('Stale resource read before selecting pointer was checked')
                return read(address,size)
            with self.subTest(selector=selector):
                self.assertFalse(matches(key,guarded,3))
                self.assertTrue(any(a<=h3+selector<a+n for a,n in reads))

    def test_overlapping_reads_retain_first_use_order(self):
        data,read=self.fixture();key=dependencies(read,0,3)
        flattened=[address+i for address,value in key[1] for i in range(len(value))]
        self.assertEqual(len(flattened),len(set(flattened)))
        self.assertLess(flattened.index(0x7b52+12),flattened.index(0xc000))
        self.assertLess(flattened.index(0x3b06),flattened.index(0xc100))
        self.assertLess(flattened.index(0xc180),flattened.index(0xc200))
