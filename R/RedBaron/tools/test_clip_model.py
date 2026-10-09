import unittest
from clip_model import bounds,classify,original_pass,check,cases

class ClipTest(unittest.TestCase):
    def test_inherited_upper_word(self):
        self.assertEqual(bounds(-100,100),(-100,-65436))
        self.assertEqual(classify([0,1],-100,100),'outside')
    def test_order_and_empty(self):
        self.assertEqual(original_pass([5,3,9,0],0,9),[0,1,2,3])
        self.assertEqual(original_pass([0],0,9),[])
        self.assertEqual(classify([-1,10],0,9),'fallback')
    def test_all_synthetic_paths(self):
        kinds=set()
        for n,b,x,y in cases():
            kinds.add(check([x]*n,*b[:2]));kinds.add(check([y]*n,*b[2:]))
        self.assertEqual(kinds,{'inside','outside','empty'})

if __name__=='__main__':unittest.main()
