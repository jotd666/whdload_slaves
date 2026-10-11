import copy
import unittest
from world_registry import identity,equal,storage,POOL,STRIDE,COUNT,REGISTRY_CAPACITY


class WorldRegistryTests(unittest.TestCase):
    def test_only_exact_fixed_slots_relocate(self):
        for off in (0x4860,POOL,POOL+(COUNT-1)*STRIDE):
            self.assertEqual(identity(100000+off,100000),identity(200000+off,200000))
        for off in (0x4861,POOL+1,POOL+COUNT*STRIDE):
            self.assertNotEqual(identity(100000+off,100000),identity(200000+off,200000))
        self.assertEqual(identity(1234,100000),identity(1234,200000))

    def fixture(self):
        return dict(storage=[('absolute',0)]*REGISTRY_CAPACITY,registry=[(('absolute',1234),'01'*26),(('h3',POOL),'02'*26)],lifecycle=[('h3',POOL),('absolute',1234)],pool='00'*(COUNT*STRIDE))

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

    def test_unused_registry_slots_are_compared(self):
        a=self.fixture();b=copy.deepcopy(a)
        b['storage'][-1]=('h3',POOL)
        with self.assertRaises(ValueError):equal(a,b)

    def test_storage_retains_every_slot_and_requires_exact_extent(self):
        raw=bytearray(2000);raw[-4:]=(100000+POOL).to_bytes(4,'big')
        result=storage(lambda p,n:bytes(raw[:n]),100000)
        self.assertEqual(len(result),500)
        self.assertEqual(result[-1],('h3',POOL))
        self.assertEqual(result[0],('absolute',0))
        with self.assertRaises(ValueError):storage(lambda p,n:bytes(raw[:-1]),100000)
