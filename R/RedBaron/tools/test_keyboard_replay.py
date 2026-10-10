import unittest
import struct
from copy import deepcopy
from keyboard_replay import modifiers, check_capture


class ModifierTests(unittest.TestCase):
    def test_all_native_modifier_bit_patterns(self):
        # Independent rendition of native byte-OR/word-rotate instructions.
        for bits in range(256):
            held = {0x60+i:(bits >> i) & 1 for i in range(8)}
            d1 = held[0x60] | held[0x61] | held[0x62]
            for keygroup, rotation in (((0x63,),1), ((0x64,0x65),1), ((0x66,0x67),1)):
                d1 = (d1 >> rotation | d1 << (16-rotation)) & 0xffff
                for key in keygroup:
                    d1 |= held[key]
            d1 = (d1 >> 5 | d1 << 11) & 0xffff
            self.assertEqual(modifiers(held),d1)

    def test_caps_and_both_sides_share_native_groups(self):
        self.assertEqual(modifiers({0x62:1}),0x100)
        self.assertEqual(modifiers({0x60:1,0x61:1}),0x100)
        self.assertEqual(modifiers({0x63:1,0x65:1,0x67:1}),0xe00)


class ReplayEvidenceTests(unittest.TestCase):
    def evidence(self):
        queue=bytearray(4112)
        struct.pack_into('>4H',queue,0,4,4,0,4)
        fixture=bytearray()
        for i,(deadline,key,down) in enumerate(((2,78,1),(4,78,0),(6,64,1),(8,64,0))):
            fixture += struct.pack('>IHH',deadline-1+100,key,down)
            struct.pack_into('>IHHII',queue,16+i*16,deadline,key,down,0,0)
        rows=[[1,0,0,0,0,0,0,0,0], [2,2,2,1,0,78,127,0,1],
              [3,4,4,0,0,0,0,0,1], [4,6,6,0,1,64,0,1<<29,2],
              [5,8,8,0,0,0,0,0,2]]
        return [queue,fixture,rows,100,0,127,struct.pack('>HH',2,2),struct.pack('>II',4,2)]

    def test_valid_native_trace(self):
        self.assertEqual(check_capture(*self.evidence())['commands'],2)

    def test_repeated_command_wrong_axis_and_wrong_deadline_rejected(self):
        for mutation in ('command','axis','timestamp','overflow'):
            with self.subTest(mutation=mutation):
                args=deepcopy(self.evidence())
                if mutation=='command':args[2][2][5]=78
                elif mutation=='axis':args[2][1][6]=0
                elif mutation=='timestamp':struct.pack_into('>I',args[0],16,3)
                else:struct.pack_into('>H',args[0],4,1)
                with self.assertRaises(ValueError):check_capture(*args)


if __name__ == '__main__':
    unittest.main()
