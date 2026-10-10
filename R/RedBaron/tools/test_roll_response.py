import unittest
from roll_response import response


class RollResponseTests(unittest.TestCase):
    def test_native_initial_sequences(self):
        for dt,expected in [(225,[381,658,860,1007,1115,1193]),(100,[169,318,448,563,664,753])]:
            rate=0
            for native in expected:
                rate=response(rate,1404,1450,450,700,dt)['rate']
                self.assertEqual(rate,native)

    def test_reversal_and_signed_rounding(self):
        r=response(1007,0,1450,450,700,225)
        self.assertEqual((r['factor'],r['acceleration'],r['delta'],r['rate']),(177,-484,-426,581))

    def test_floor_and_overshoot_clamp(self):
        self.assertEqual(response(1403,1404,1450,450,700,225)['rate'],1404)
        self.assertEqual(response(-1403,-1404,1450,450,700,225)['rate'],-1404)
        self.assertEqual(response(1404,1404,1450,450,700,225)['delta'],0)

    def test_unsupported_division(self):
        with self.assertRaises(ValueError):response(0,100,0,450,700,225)
        with self.assertRaises(ValueError):response(0,32767,1,450,700,225)


if __name__=='__main__':unittest.main()
