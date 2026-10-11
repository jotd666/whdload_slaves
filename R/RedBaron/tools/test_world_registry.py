import copy
import unittest
from world_registry import identity,equal,POOL,STRIDE,COUNT


class WorldRegistryTests(unittest.TestCase):
    def test_only_exact_fixed_slots_relocate(self):
        for off in (0x4860,POOL,POOL+(COUNT-1)*STRIDE):
            self.assertEqual(identity(100000+off,100000),identity(200000+off,200000))
        for off in (0x4861,POOL+1,POOL+COUNT*STRIDE):
            self.assertNotEqual(identity(100000+off,100000),identity(200000+off,200000))
        self.assertEqual(identity(1234,100000),identity(1234,200000))

    def fixture(self):
        return dict(registry=[(('absolute',1234),'01'*26),(('h3',POOL),'02'*26)],lifecycle=[('h3',POOL),('absolute',1234)],pool='00'*(COUNT*STRIDE))

    def test_order_and_prefix_changes_fail(self):
        a=self.fixture();b=copy.deepcopy(a);b['registry'].reverse()
        with self.assertRaises(ValueError):equal(a,b)
        b=copy.deepcopy(a);b['registry'][1]=(b['registry'][1][0],'02'*25+'03')
        with self.assertRaises(ValueError):equal(a,b)

    def test_lifecycle_order_and_unused_pool_tail_fail(self):
        a=self.fixture();equal(a,copy.deepcopy(a));b=copy.deepcopy(a);b['lifecycle'].reverse()
        with self.assertRaises(ValueError):equal(a,b)
        b=copy.deepcopy(a);b['pool']=b['pool'][:-2]+'01'
        with self.assertRaises(ValueError):equal(a,b)
