import unittest
from global_relocations import classify


class GlobalRelocationsTests(unittest.TestCase):
    def test_only_declared_unchanged_relocations_are_bound(self):
        original=bytes.fromhex('0000000400000004')
        left=bytes.fromhex('0000100400001004');right=bytes.fromhex('0000200400002004')
        result=classify(original,[(0,0)],[[0x1000],[0x2000]],[[left],[right]])
        self.assertEqual(len(result['unchanged_relocations']),1)
        row=result['rows'][0]
        self.assertEqual(row['raw']['changed_bytes'],2)
        self.assertEqual(row['relocation_changed_bytes'],1)
        self.assertEqual(row['residual_changed_bytes'],1)
        self.assertEqual(result['residual_union'],[6])

    def test_transient_mutation_disqualifies_binding_at_every_checkpoint(self):
        original=bytes.fromhex('00000004')
        left=bytes.fromhex('00001004');right=bytes.fromhex('00002004')
        changed=bytes.fromhex('00002008')
        r=classify(original,[(0,0)],[[0x1000],[0x2000]],
                   [[left,left,left],[right,changed,right]])
        self.assertFalse(r['unchanged_relocations'])
        self.assertEqual(len(r['mutable_relocations']),1)
        self.assertEqual([x['residual_changed_bytes'] for x in r['rows']],[1,2,1])

    def test_reject_incomplete_or_ambiguous_input(self):
        raw=bytes(8);bases=[[0],[0]];seq=[[raw],[raw]]
        for rel in ([(0,0),(2,0)],[(1,0)],[(6,0)],[(0,1)]):
            with self.assertRaises(ValueError):classify(raw,rel,bases,seq)
        for sequences in ([[],[]],[[raw],[]],[[raw],[raw[:4]]]):
            with self.assertRaises(ValueError):classify(raw,[],bases,sequences)
