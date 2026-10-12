import random
import struct
import unittest
from artwork_sparse import pack
from cockpit_compose import native_static_layer
from cockpit_fast import paint, compare_viewport


class FastCockpitTests(unittest.TestCase):
    def test_overlay_clipping_and_ordered_artwork_both_pages(self):
        rng = random.Random(0xfc2)
        source = rng.randbytes(14400)
        mask = rng.randbytes(2880)
        # The expanded overlay can exceed the artwork cache's 1024-word bound.
        for bottom in (119, 139, 159):
            layer = native_static_layer(source, mask, 3520, 4628, 2880, bottom)
            records = []
            for offset in range(3520, (bottom+1)*40, 2):
                bits = int.from_bytes(layer.mask[offset:offset+2], 'big')
                if bits:
                    colours = [int.from_bytes(layer.pixels[p*8000+offset:p*8000+offset+2], 'big') & bits for p in range(5)]
                    records.append(struct.pack('>7H', offset, bits, *colours))
            overlay = struct.pack('>H', len(records)) + b''.join(records)
            layers = [layer]
            lists = [overlay]
            for _ in range(3):
                artmask = bytearray(8000)
                for offset in rng.sample(range(0, 8000, 2), 200):
                    artmask[offset:offset+2] = rng.randrange(1, 65536).to_bytes(2, 'big')
                from cockpit_compose import Layer
                art = Layer(rng.randbytes(40000), bytes(artmask))
                layers.append(art)
                lists.append(pack(art.pixels, art.mask))
            for _ in range(2):
                original = rng.randbytes(40000)
                fast = original
                expected = bytearray(original)
                for cached, pixels in zip(lists, layers):
                    fast = paint(fast, cached, 21, bottom+1)
                    for p in range(5):
                        for i in range(21*40, (bottom+1)*40):
                            j = p*8000+i
                            expected[j] = (expected[j] & ~pixels.mask[i]) | (pixels.pixels[j] & pixels.mask[i])
                self.assertEqual(fast, expected)

    def test_outside_repair_including_opaque_black(self):
        image = bytes(40000)
        mask = bytearray(8000)
        for row in (0, 20, 21, 139, 140, 199):
            mask[row*40:row*40+4] = b'\xff\xff\x80\x01'
        packed = pack(image, mask)
        original = bytes([255])*40000
        out = paint(original, packed, 21, 140, outside=True)
        for p in range(5):
            for i in range(8000):
                expected = 255 if 840 <= i < 5600 else 255 & ~mask[i]
                self.assertEqual(out[p*8000+i], expected)
        self.assertEqual(paint(out, packed, 21, 140, outside=True), out)

    def test_twin_rejects_three_deliberate_pixel_faults(self):
        native = bytes(40000)
        self.assertTrue(compare_viewport(native, native, 21, 140))
        for at in (21*40, 2*8000+100*40+17, 4*8000+140*40-1):
            candidate = bytearray(native)
            candidate[at] ^= 1
            self.assertFalse(compare_viewport(candidate, native, 21, 140))
