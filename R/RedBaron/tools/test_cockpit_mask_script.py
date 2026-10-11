import struct
import unittest
from cockpit_mask_script import prepare
from cockpit_program import decode


class CockpitMaskScriptTests(unittest.TestCase):
    def test_private_copy_preserves_clipped_polygon_and_geometry(self):
        words = (0x2002, 6, 6, 0xaf2f, 4, 74, 78, 78, 74, 94, 93, 65534, 65534,
                 0x2002, 18, 18, 0xa104, 29, 0, 8, 117, 0xff0)
        source = struct.pack('>22H', *words)
        copied = prepare(source)
        original = decode(lambda a,n: source[a:a+n], 0)
        masked = decode(lambda a,n: copied[a:a+n], 0)
        self.assertNotEqual(source, copied)
        self.assertEqual(source, struct.pack('>22H', *words))
        for old, new in zip(original['commands'], masked['commands']):
            if old['kind'] == 'colours':
                self.assertEqual(new['args'], [1, 1])
            else:
                self.assertEqual(old, new)

    def test_reject_bitmap_incoming_pen_and_different_edge_colour(self):
        for words in ((0x1051, 1, 0xff0), (0xa104, 1, 1, 2, 2, 0xff0),
                      (0x2002, 6, 18, 0xff0)):
            with self.subTest(words=words), self.assertRaises(ValueError):
                prepare(struct.pack('>' + 'H' * len(words), *words))

    def test_solid_key_tracks_inputs_without_bitmap_scans(self):
        from cockpit_mask_script import dependencies
        from cockpit_dependencies import matches
        data = bytearray(0x10000)
        struct.pack_into('>I', data, 0x7b5a, 0xc000)
        struct.pack_into('>I', data, 0x9d34, 8000)
        for at,value in ((0x9d3c,5),(0x9d40,320),(0x9d42,40),(0x9d44,200)):
            struct.pack_into('>H', data, at, value)
        struct.pack_into('>H4h', data, 0x9d46, 1, 0, 319, 0, 139)
        struct.pack_into('>9H', data, 0xc000, 0x2002,6,6,0xa104,29,0,8,117,0xff0)
        read = lambda a,n: bytes(data[a:a+n])
        key = dependencies(read,0)
        self.assertEqual(len(key[1]),7)
        self.assertLess(sum(len(v) for _,v in key[1]),100)
        for at in (0xc004,0x9d4e,0x3ab7,0x101d,0x7b50):
            data[at] ^= 1
            self.assertFalse(matches(key,read,2))
            data[at] ^= 1
        data[0x9d72:0x9d76] = b'\0\1\0\0'
        self.assertTrue(matches(key,read,2))
        data[0x9d47] = 0
        with self.assertRaisesRegex(ValueError,'clipping'):
            dependencies(read,0)

    def test_forced_palette_makes_native_colour_mapping_white(self):
        from cockpit_program import colour_state
        data = bytearray(0xa000)
        for original in (0,1,127,128,255):
            data[0x3ab7:0x3abf] = bytes([original])*8
            data[0x3abf:0x3ac1] = b'\0\0'
            data[0x101d:0x1021] = b'\1'*4
            self.assertEqual(colour_state(lambda a,n: bytes(data[a:a+n]),0,1,1),(1,1,1))
