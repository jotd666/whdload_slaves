import random
import struct
import unittest
from gauge_fast import paint, check, retained


class GaugeFastTests(unittest.TestCase):
    def test_clipped_words_against_independent_pixel_reference(self):
        rng = random.Random(23)
        area = (6, 130, 10, 40)
        pixels, mask = rng.randbytes(2000), rng.randbytes(400)
        frame = rng.randbytes(40000)
        for left in range(46, 82):
            clip = (left, left+19, 137, 161)
            expected = bytearray(frame)
            for y in range(137, 162):
                for x in range(max(48,left), min(127,left+19)+1):
                    at=(y-130)*10+x//8-6; bit=128>>(x%8)
                    if not mask[at]&bit:
                        continue
                    for plane in range(5):
                        pos=plane*8000+y*40+x//8
                        expected[pos]=(expected[pos]&~bit)|(pixels[plane*400+at]&bit)
            self.assertEqual(paint(frame,pixels,mask,area,clip),expected)

    def test_opaque_black_and_empty_clip(self):
        frame=bytes([255])*40000
        result=paint(frame,bytes(10),bytes([255,255]),(0,170,2,1),None)
        for p in range(5):
            self.assertEqual(result[p*8000+6800:p*8000+6802],bytes(2))
        self.assertEqual(paint(frame,bytes(10),b'\xff\xff',(0,170,2,1),(0,15,171,172)),frame)

    def test_checker_rejects_three_sabotages(self):
        bg=struct.pack('>2I',0xfffffff,28)
        reuse=struct.pack('>8I',0x3fff,0,0,14,0,0,0,0)
        draws=struct.pack('>I',30)
        self.assertEqual(check(bg,reuse,draws)['background_cases'],28)
        for b,r,d in ((struct.pack('>2I',0xffffffe,28),reuse,draws),
                      (bg,struct.pack('>8I',0x3fff,0,0,14,1,0,0,0),draws),
                      (bg,reuse,bytes(4))):
            with self.assertRaises(ValueError): check(b,r,d)


class RetainedGaugeTests(unittest.TestCase):
    def test_scene_and_every_foreground_layer_bound_the_retained_area(self):
        art=[[0,4640],[2840,4000],[2880,4080]]
        self.assertTrue(retained(140,(21,119),art,composed=True))
        self.assertFalse(retained(139,(21,119),art,composed=True))
        self.assertFalse(retained(140,(21,119),art,composed=False))
        for i in range(3):
            changed=[x[:] for x in art];changed[i].append(5600)
            self.assertFalse(retained(140,(21,119),changed,composed=True))
        self.assertTrue(retained(141,(21,119),changed,composed=True))

    def test_empty_or_changed_viewport(self):
        self.assertTrue(retained(140,(21,119),[[],[],[]],composed=True))
        self.assertFalse(retained(140,(0,200),[[],[],[]],composed=True))
        with self.assertRaises(ValueError):retained(140,(21,119),[[8,2]],composed=True)
