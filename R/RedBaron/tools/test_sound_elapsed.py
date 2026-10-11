import unittest
from sound_elapsed import counter


class SoundElapsedTests(unittest.TestCase):
    def check(self, kinds, values):
        return counter([dict(field=i, kind=k) for i,k in enumerate(kinds)],
                       [dict(field=i, value=v) for i,v in enumerate(values)])

    def test_reset_then_increment(self):
        r = self.check(['start','increment','increment','reset','increment'], [0,1,2,0,1])
        self.assertEqual((r['verified'],r['resets'],r['final_value']), (5,2,1))

    def test_leading_increments_remain_unverified(self):
        r = self.check(['increment','increment','reset','increment'], [13,14,0,1])
        self.assertEqual((r['leading_unverified'],r['verified']), (2,2))
        with self.assertRaisesRegex(ValueError, 'No independently reset'):
            self.check(['increment'], [12])

    def test_unsigned_word_wrap(self):
        r = self.check(['reset']+['increment']*65536, [0]+list(range(1,65536))+[0])
        self.assertEqual(r['final_value'],0)

    def test_corrupt_or_incomplete_write_stream(self):
        for kinds, values in [(['reset'],[1]), (['reset','increment'],[0,2]),
                              (['reset','increment'],[0]), (['unknown'],[0])]:
            with self.subTest(kinds=kinds,values=values), self.assertRaises(ValueError):
                self.check(kinds,values)
        with self.assertRaisesRegex(ValueError, 'adjacent'):
            counter([dict(field=0,kind='reset')], [dict(field=2,value=0)])


if __name__ == '__main__':
    unittest.main()
