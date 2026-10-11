import copy
import unittest
from shared_display_state import identity,compare,COMPACT,FIXED


class SharedDisplayStateTests(unittest.TestCase):
    def fixture(self):
        return dict(count=1,compact_count=1,storage=[('h3',COMPACT)]+[('absolute',0)]*499,
                    raw_storage=bytes(2000),compact=bytes(600),fixed=bytes(52))

    def test_only_exact_native_objects_relocate(self):
        for off in (FIXED,COMPACT,COMPACT+590):
            self.assertEqual(identity(100000+off,100000),identity(200000+off,200000))
        for off in (FIXED+1,COMPACT+1,COMPACT+600):
            self.assertNotEqual(identity(100000+off,100000),identity(200000+off,200000))

    def test_inactive_differences_remain_visible(self):
        a=self.fixture();b=copy.deepcopy(a);b['storage'][-1]=('h3',COMPACT)
        r=compare(a,b);self.assertTrue(r['active_order_equal'])
        self.assertEqual(r['differing_slots'][0]['slot'],499)
        self.assertFalse(r['differing_slots'][0]['active_left'])

    def test_active_order_and_count_mismatches_are_not_sorted_away(self):
        a=self.fixture();a['count']=2;a['storage'][1]=('h3',COMPACT+10)
        b=copy.deepcopy(a);b['storage'][:2]=reversed(b['storage'][:2])
        self.assertFalse(compare(a,b)['active_order_equal'])
        b=copy.deepcopy(a);b['count']=1
        self.assertFalse(compare(a,b)['active_order_equal'])

    def test_complete_compact_and_fixed_prefix_differences_retained(self):
        a=self.fixture();b=copy.deepcopy(a)
        b['compact']=bytes(599)+b'\x01';b['fixed']=bytes(51)+b'\x01'
        r=compare(a,b)
        self.assertEqual(r['compact']['changed_bytes'],1)
        self.assertEqual(r['fixed_prefix']['changed_bytes'],1)
