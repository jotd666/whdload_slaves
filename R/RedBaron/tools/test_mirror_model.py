"""Host-model checks; live original and VERIFY-twin validation remain separate gates."""
import random,unittest
from mirror_model import mirror,reverse_word,TABLE

class MirrorTests(unittest.TestCase):
    def test_exhaustive_words(self):
        for word in range(65536):
            want=TABLE[word&255]<<8|TABLE[word>>8]
            for previous in (0,1):
                got,x=reverse_word(word,previous)
                self.assertEqual(got,want);self.assertEqual(x,previous&1)
    def test_bitmap_domain_edges_and_padding(self):
        rng=random.Random(304)
        for width in (1,15,16,17,168,319,320):
            for height in (1,2,102,200):
                for depth in (4,5):
                    stride=((width+15)//16)*2
                    data=rng.randbytes(stride*height*depth)
                    original=mirror(data,width,height,depth)
                    self.assertEqual(original,mirror(data,width,height,depth,table=True))
                    restored,mask=mirror(original[0],width,height,depth)
                    self.assertEqual(restored,data)
                    for y in range(height):
                        self.assertEqual(mask[y*(stride+2)+stride:y*(stride+2)+stride+2],b'\0\0')
    def test_mask_is_union_not_supplied_mask(self):
        planes=bytes.fromhex('8000000100000000')
        self.assertEqual(mirror(planes,1,1,4),(bytes.fromhex('0001800000000000'),bytes.fromhex('80010000')))
if __name__=='__main__':unittest.main()
