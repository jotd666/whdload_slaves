import unittest
from heap_content import inventory


class HeapContentTests(unittest.TestCase):
    def test_content_match_does_not_require_same_address(self):
        r=inventory({10:b'abc'},{20:b'abc'})
        self.assertEqual((r['shared_content_count'],r['shared_content_bytes']),(1,3))
        self.assertEqual(r['groups'][0]['left_addresses'],[10])
        self.assertEqual(r['groups'][0]['right_addresses'],[20])

    def test_duplicate_multiplicity_keeps_ambiguity(self):
        r=inventory({10:b'x',20:b'x'},{30:b'x'})
        self.assertEqual((r['shared_content_count'],r['left_excess'],r['right_excess']),(1,1,0))
        self.assertTrue(r['groups'][0]['ambiguous_identity'])
        self.assertEqual(r['groups'][0]['left_addresses'],[10,20])

    def test_tail_changes_and_length_are_not_hidden(self):
        r=inventory({10:b'abc',20:b'ab'},{30:b'abd'})
        self.assertEqual((r['shared_content_count'],r['left_excess'],r['right_excess']),(0,2,1))
        self.assertEqual(inventory({}, {})['groups'],[])
