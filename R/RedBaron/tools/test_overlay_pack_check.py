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
