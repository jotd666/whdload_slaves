import unittest
from overlay_pack_check import pack,replay,background


class OverlayPackTests(unittest.TestCase):
    def test_opaque_zero_and_background_independence(self):
        mask=bytearray(8000);mask[41]=0x81;mask[82]=0x40
        image=background(0x53)
        descriptor,payload=pack(image,mask)
        self.assertEqual(descriptor,(0,1,4,2,8,48))
        for seed in (0,255,0x5a):
            bg=background(seed)
            expected=bytes((b & (255^mask[i%8000])) | (image[i]&mask[i%8000]) for i,b in enumerate(bg))
            self.assertEqual(replay(bg,descriptor,payload),expected)
        zero_descriptor,zero_payload=pack(bytes(40000),mask)
        self.assertEqual(replay(bytes([255])*40000,zero_descriptor,zero_payload)[41],0x7e)

    def test_drop_uncovered_pixel_bits(self):
        mask=bytearray(8000);mask[0]=0x80
        descriptor,payload=pack(bytes([255])*40000,mask)
        self.assertEqual(descriptor,(0,0,2,1,2,12))
        self.assertEqual(payload,bytes([0x80,0])*6)

    def test_reject_empty_oversize_and_invalid_geometry(self):
        with self.assertRaises(ValueError):pack(bytes(40000),bytes(8000))
        with self.assertRaises(ValueError):pack(bytes(40000),bytes([255])*8000)
        for desc in ((1,0,2,1,2,12),(0,0,2,1,3,18),(40,0,2,1,2,12),(0,200,2,1,2,12)):
            with self.subTest(desc=desc),self.assertRaises(ValueError):replay(bytes(40000),desc,bytes(desc[-1]))


class CombinedCockpitPackTests(unittest.TestCase):
    def test_union_capture_is_independent_of_fill_background(self):
        import random
        from overlay_coverage import composite
        rng = random.Random(234)
        layers = [(rng.randbytes(40000), rng.randbytes(8000)) for _ in range(3)]
        union = bytes(a | b | c for a,b,c in zip(*(m for _,m in layers)))
        captured = rng.randbytes(40000)
        for image,mask in layers:
            captured = composite(captured,image,mask)
        descriptor,payload = pack(captured,union,48000)
        self.assertEqual(descriptor,(0,0,40,200,8000,48000))
        for new_background in (bytes(40000), bytes([255])*40000, rng.randbytes(40000)):
            native = new_background
            for image,mask in layers:
                native = composite(native,image,mask)
            self.assertEqual(replay(new_background,descriptor,payload,48000),native)

    def test_combined_capacity_still_rejects_bad_geometry_and_truncation(self):
        for descriptor,payload in (((0,0,40,201,8040,48240),bytes(48240)),
                                   ((0,0,40,200,8000,48000),bytes(47999)),
                                   ((2,0,40,200,8000,48000),bytes(48000))):
            with self.subTest(descriptor=descriptor), self.assertRaises(ValueError):
                replay(bytes(40000),descriptor,payload,48000)
