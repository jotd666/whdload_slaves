import unittest
from render_phase import dirty_after, terrain_cache, shared_list


class RenderPhaseTests(unittest.TestCase):
    def test_dirty_countdown_matches_signed_native_clamp(self):
        for value,expected in [(-32768,0),(-1,0),(0,0),(1,0),(2,1),(32767,32766)]:
            self.assertEqual(dirty_after(value),expected)
        with self.assertRaises(ValueError):dirty_after(32768)

    def test_terrain_cache_rejects_unrestored_state(self):
        original=bytes(0x54ec)
        frame=dict(terrain_rebuilds=1,terrain_reuses=0,terrain_keys=[0xffffffff])
        read=lambda address,size:original[address:address+size]
        terrain_cache(read,read,0,frame)
        for offset in (0x5270,0x54de,0x54e6,0x54ea):
            changed=bytearray(original);changed[offset]=1
            with self.assertRaises(ValueError):
                terrain_cache(read,lambda address,size:changed[address:address+size],0,frame)

    def test_terrain_cache_rejects_reuse_or_missing_rebuild(self):
        read=lambda address,size:bytes(size)
        for rebuilds,reuses,keys in ((0,0,[]),(1,1,[]),(1,0,[1]),(2,0,[])):
            with self.assertRaises(ValueError):
                terrain_cache(read,read,0,dict(terrain_rebuilds=rebuilds,
                                             terrain_reuses=reuses,terrain_keys=keys))
        # Native explicit-refresh argument can bypass the positive-key test.
        terrain_cache(read,read,0,dict(terrain_rebuilds=1,terrain_reuses=0,terrain_keys=[]))

    def test_shared_list_rejects_count_or_order_changes(self):
        initial=bytearray(0x8598)
        initial[0x3fa8:0x3faa]=(2).to_bytes(2,'big')
        initial[0x7dc8:0x7dd0]=bytes.fromhex('0000123400005678')
        read=lambda address,size:initial[address:address+size]
        self.assertEqual(shared_list(read,read,0),2)
        for offset in (0x3fa9,0x7dcb,0x7dcf):
            changed=bytearray(initial);changed[offset]^=1
            with self.assertRaises(ValueError):
                shared_list(read,lambda address,size:changed[address:address+size],0)
        # Inactive slots are overwritten by registration before becoming active.
        changed=bytearray(initial);changed[0x7dd0]=1
        self.assertEqual(shared_list(read,lambda address,size:changed[address:address+size],0),2)
        initial[0x3fa8:0x3faa]=(501).to_bytes(2,'big')
        with self.assertRaises(ValueError):shared_list(read,read,0)


if __name__=='__main__':unittest.main()
