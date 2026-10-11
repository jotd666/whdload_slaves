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
