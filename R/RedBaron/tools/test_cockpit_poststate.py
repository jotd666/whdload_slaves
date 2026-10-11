import struct
import unittest
from cockpit_program import colour_state
from cockpit_poststate import expected


class CockpitPoststateTests(unittest.TestCase):
    def fixture(self):
        data=bytearray(0x10000)
        struct.pack_into('>I',data,0x7b52+12,0xc000)
        words=[0x2002,8,8,0x1051,2,0x1031,1,0xa502,50,50,0xa104,20,20,4,4,0x0ff0]
        struct.pack_into('>'+str(len(words))+'H',data,0xc000,*words)
        struct.pack_into('>I',data,0x3b02+8,0xc100)
        struct.pack_into('>I',data,0xc104,0xc200)
        data[0x7000]=123
        return data,lambda a,n:bytes(data[a:a+n])

    def test_resource_colour_and_mode_outputs(self):
        data,read=self.fixture();out,writes=expected(read,0,3)
        for off,width,value in ((0x4164,2,8),(0x9d50,2,8),(0x9d52,2,8),(0x9d54,2,1),
                                (0x7c22,2,2),(0x7c24,4,0xc100),(0x7c28,4,0xc200),(0x7c2c,4,0xc100),(0x7c1c,2,0)):
            self.assertEqual(int.from_bytes(out[off:off+width],'big'),value)
        self.assertEqual(out[0x7000],123)
        touched={i for off,width,_ in writes for i in range(off,off+width)}
        self.assertTrue(all(a==b for i,(a,b) in enumerate(zip(data,out)) if i not in touched))

    def test_signed_palette_selector_and_original_word_match(self):
        data,read=self.fixture()
        data[0x3abf]=255  # native sign extension: selector -1, not 255
        data[0x3ab7]=255;data[0x1019]=7
        self.assertEqual(colour_state(read,0,65535,65535),(65535,7,7))
        # Original argument 255 does not equal sign-extended table word -1.
        self.assertEqual(colour_state(read,0,255,255),(65535,65535,65535))

    def test_pen_keeps_unmapped_colour_and_later_group_wins(self):
        data,read=self.fixture();data[0x3ab7]=8;data[0x3abb]=8
        data[0x3abf]=1;data[0x3ac0]=2;data[0x1021]=4;data[0x1025]=7
        self.assertEqual(colour_state(read,0,8,8),(8,7,7))

    def test_reject_incoming_resource_and_nonzero_bitmap_mode(self):
        data,read=self.fixture()
        struct.pack_into('>4H',data,0xc000,0x1031,1,0x0ff0,0)
        with self.assertRaises(ValueError):expected(read,0,3)
        data,read=self.fixture();struct.pack_into('>H',data,0xc000+14,0xa512)
        with self.assertRaises(ValueError):expected(read,0,3)
