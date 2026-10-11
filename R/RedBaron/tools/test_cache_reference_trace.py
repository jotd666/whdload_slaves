import unittest
import capstone
from cache_reference_trace import operands,overlaps,selected_offsets,range_targets


class CacheReferenceTraceTests(unittest.TestCase):
    def decode(self,code,registers=None):
        c=capstone.Cs(capstone.CS_ARCH_M68K,capstone.CS_MODE_M68K_000);c.detail=True
        i=next(c.disasm(bytes.fromhex(code),0x1000,count=1))
        r=[0]*17;r[15]=0x8000
        if registers:
            for k,v in registers.items():r[k]=v
        return operands(i,r)[:-1]

    def test_brief_index_sign_and_width(self):
        self.assertEqual(self.decode('203000fc',{8:0x2000,0:0xfffe}),[(0x1ffa,4)])
        self.assertEqual(self.decode('203018fc',{8:0x2000,1:0x10002}),[(0x11ffe,4)])

    def test_physical_alias_and_absolute_short(self):
        self.assertEqual(self.decode('3038ffff'),[(0xffffff,2)])
        self.assertEqual(self.decode('3039ffc01234'),[(0xc01234,2)])
        self.assertTrue(overlaps(0xfffffe,4,0,2))
        self.assertFalse(overlaps(0x1000,4,0x1004,0x2000))

    def test_postincrement_predecrement_and_stack_byte(self):
        self.assertEqual(self.decode('20d8',{8:0x2000}),[(0x2000,4),(0x2004,4)])
        self.assertEqual(self.decode('3020',{8:0x2000}),[(0x1ffe,2)])
        self.assertEqual(self.decode('101f'),[(0x8000,1)])

    def test_pc_extension_after_mask_or_immediate(self):
        self.assertEqual(self.decode('303afff0'),[(0xff2,2)])
        self.assertEqual(self.decode('4cfa0001fff0'),[(0xff4,64)])
        self.assertEqual(self.decode('083a0003fff0'),[(0xff4,1)])

    def test_movem_and_movep_conservative_extents(self):
        self.assertEqual(self.decode('48e700fc'),[(0x7fc0,64)])
        self.assertEqual(self.decode('01480004',{8:0x2000}),[(0x2004,8)])

    def test_unlk_reads_frame_even_when_far_from_stack(self):
        self.assertEqual(self.decode('4e5d',{13:0xc01000}),[(0xc01000,4)])

    def test_unknown_memory_mode_cannot_count_as_no_reference(self):
        from types import SimpleNamespace as S
        i=S(mnemonic='move.l',op_size=S(size=4),operands=[S(type=3,address_mode=9)])
        with self.assertRaises(ValueError):operands(i,[0]*17)

    def test_residual_selection_keeps_partial_overlaps(self):
        targets={0,3,4,0xbd0b}
        self.assertEqual(selected_offsets(0xffe,4,0x1000,targets),[0])
        self.assertEqual(selected_offsets(0x1002,4,0x1000,targets),[3,4])
        self.assertEqual(selected_offsets(0xcd0a,4,0x1000,targets),[0xbd0b])
        self.assertEqual(selected_offsets(0xcd0c,4,0x1000,targets),[])

    def test_complete_range_targets_include_all_boundary_bytes(self):
        targets=range_targets([(0x5280,0x54da),(0x129c,0x12d0)])
        self.assertEqual(len(targets),602+52)
        self.assertIn(0x54d9,targets)
        self.assertNotIn(0x54da,targets)
        self.assertEqual(selected_offsets(0x527f,2,0,targets),[0x5280])

    def test_invalid_or_overlapping_range_targets_fail(self):
        for ranges in ([],[(3,3)],[(-1,2)],[(0,0xbd0d)],[(0,5),(4,7)]):
            with self.assertRaises(ValueError):range_targets(ranges)
