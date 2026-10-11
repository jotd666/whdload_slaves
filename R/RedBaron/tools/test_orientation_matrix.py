import random
import unittest
from orientation_matrix import matrix,lookup


class OrientationMatrixTests(unittest.TestCase):
    def test_all_word_lookup_indices(self):
        table=list(range(2049))
        for angle in range(65536):
            q=angle//16
            self.assertEqual(lookup(table,angle),min(q,4096-q))
            self.assertEqual(lookup(table,angle+65536),lookup(table,angle))

    def test_identity_and_single_axis(self):
        table=[0]*2049;table[0]=16384;table[1024]=-3
        self.assertEqual(matrix(table,(0,0,0)),(bytes.fromhex('40000000000000004000000000000000400000'),0))
        raw,reads=matrix(table,(0,0,16384))
        self.assertEqual(raw,bytes.fromhex('fffd40000000c000fffd000000000000400001'))
        self.assertEqual(reads,2)

    def test_reuse_preserves_word_rounding_and_reduces_reads(self):
        r=random.Random(3648)
        table=[r.randrange(-32768,32768) for _ in range(2049)]
        for _ in range(10000):
            angles=[r.randrange(65536) for _ in range(3)]
            original,n=matrix(table,angles)
            candidate,m=matrix(table,angles,reuse=True)
            self.assertEqual(candidate,original)
            self.assertEqual(n,17)
            self.assertLessEqual(m,14)
        # Quantizing operands separately loses carries before table lookup.
        self.assertNotEqual(lookup(list(range(2049)),15+1),lookup(list(range(2049)),0+0))

if __name__=='__main__':unittest.main()
