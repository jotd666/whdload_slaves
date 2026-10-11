import unittest
from geometry_cache_state import describe,compare,TAGS,ARRAYS,COUNT


class GeometryCacheStateTests(unittest.TestCase):
    def ram(self,count=2):
        raw=bytearray(0xbd0c);raw[0xa350:0xa352]=count.to_bytes(2,'big')
        return raw

    def state(self,raw):return describe(lambda p,n:bytes(raw[p:p+n]),0)

    def test_retains_invalid_and_outside_count_differences(self):
        a=self.ram();b=self.ram();b[ARRAYS[0]+4]=17;b[ARRAYS[4]+254*4]=23
        r=compare(self.state(a),self.state(b))
        self.assertEqual([x['index'] for x in r['differing_rows']],[1,254])
        self.assertEqual(r['differing_rows'][1]['inside_selected_count'],[False,False])
        self.assertEqual(r['arrays']['screen_y']['changed_bytes'],1)

    def test_rejects_unknown_active_tag_and_bad_count(self):
        a=self.ram();a[TAGS]=4
        with self.assertRaises(ValueError):self.state(a)
        with self.assertRaises(ValueError):self.state(self.ram(COUNT+1))
        a[TAGS]=3;a[TAGS+255]=255
        self.assertEqual(self.state(a)['tags'][255],255)

    def test_rejects_truncated_array(self):
        a=self.ram()
        with self.assertRaises(ValueError):describe(lambda p,n:bytes(a[p:p+n-1]),0)
