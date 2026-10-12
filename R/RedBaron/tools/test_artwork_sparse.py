import random
import struct
import unittest
from artwork_sparse import pack, repair, PLANE, DEPTH
from cockpit_raster import composite


class ArtworkSparseTests(unittest.TestCase):
    def test_native_composition_identity_and_two_independent_pages(self):
        rng = random.Random(0xBA20)
        image = rng.randbytes(PLANE * DEPTH)
        mask = bytes(rng.randrange(256) if rng.randrange(12) == 0 else 0 for _ in range(PLANE))
        packed = pack(image, mask)
        for _ in range(8):
            page = rng.randbytes(PLANE * DEPTH)
            result, writes = repair(page, packed)
            self.assertEqual(result, composite(page, image, mask))
            self.assertGreater(writes, 0)
            self.assertEqual(repair(result, packed), (result, 0))

    def test_opaque_black_partial_word_and_intervening_damage(self):
        mask = b'\x80\x01' + bytes(PLANE - 2)
        packed = pack(bytes(PLANE * DEPTH), mask)
        page = bytes([255]) * (PLANE * DEPTH)
        result, writes = repair(page, packed)
        self.assertEqual(writes, DEPTH)
        for p in range(DEPTH):
            self.assertEqual(result[p * PLANE:p * PLANE + 2], b'\x7f\xfe')
        damaged = bytearray(result)
        damaged[2 * PLANE] |= 128
        self.assertEqual(repair(damaged, packed), (result, 1))

    def test_empty_and_maximum_coverage_bound(self):
        image = bytes(PLANE * DEPTH)
        self.assertEqual(pack(image, bytes(PLANE)), b'\0\0')
        packed = pack(image, b'\xff' * 2048 + bytes(PLANE - 2048))
        self.assertEqual(len(packed), 14338)
        with self.assertRaises(ValueError):
            pack(image, b'\xff' * PLANE)
        self.assertEqual(repair(image, packed), (image, 0))

    def test_reject_malformed_list(self):
        for packed in (b'', b'\0\1', struct.pack('>8H', 1, 8000, 1, 0, 0, 0, 0, 0)):
            with self.assertRaises(ValueError):
                repair(bytes(PLANE * DEPTH), packed)
