import struct
import unittest
from cockpit_program import decode
from cockpit_raster import render
from overlay_cache_key import build
import test_cockpit_dependencies


class CockpitPolygonDecodeTests(unittest.TestCase):
    def test_counted_separate_coordinate_arrays(self):
        # Program 2's narrow strut: native reads count, all x, then all y.
        words = (0xaf2f, 4, 74, 78, 78, 74, 94, 93, 65534, 65534, 0x2002, 6, 6, 0xff0)
        data = struct.pack('>14H', *words)
        result = decode(lambda a,n: data[a:a+n], 0)
        self.assertEqual(result['bytes'], 28)
        self.assertEqual(result['commands'][0]['args'], list(words[1:10]))
        self.assertEqual(result['commands'][1]['kind'], 'colours')

    def test_bad_count_and_truncated_payload_rejected(self):
        for words in ((0xaf2f, 0), (0xaf2f, 65), (0xaf2f, 4, 74, 78)):
            data = struct.pack('>' + 'H' * len(words), *words)
            with self.subTest(words=words), self.assertRaises(ValueError):
                decode(lambda a,n: data[a:a+n], 0)

    def test_decoder_support_does_not_silently_enable_polygon_cache(self):
        data, read = test_cockpit_dependencies.CockpitDependencyTests().fixture()
        struct.pack_into('>11H', data, 0xc000, 0xaf2f, 4, 74, 78, 78, 74, 94, 93, 65534, 65534, 0xff0)
        with self.assertRaisesRegex(ValueError, 'polygon'):
            render(read, 0, 3, bytes(40000))
        with self.assertRaisesRegex(ValueError, 'polygon'):
            build(read, 0, 3)
