import unittest
from world_comparison import compare_states, same_tick


class Memory:
    def __init__(self):
        self.data = bytearray(0xd000)
        self.data[0x4578:0x457c] = (0xc000).to_bytes(4, 'big')
        self.data[0x859e:0x85a0] = (1).to_bytes(2, 'big')
        self.data[0x85a0:0x85a4] = (0xc200).to_bytes(4, 'big')
        self.banks = [(0, self.data)]

    def read(self, address, size):
        return self.data[address:address+size]


class WorldComparisonTests(unittest.TestCase):
    def test_reports_unknown_heap_changes_even_when_named_regions_match(self):
        left, right = Memory(), Memory()
        right.data[0xc280] = 1
        result = compare_states(left, right, 0)
        self.assertEqual(result['h3']['changed_bytes'], 0)
        self.assertEqual(result['player']['changed_bytes'], 0)
        self.assertEqual(result['object_prefix_differences'], [])
        self.assertEqual(result['ram'][0]['changed_ranges'], [(0xc280, 0xc281)])
        self.assertNotEqual(result['ram'][0]['left_sha256'], result['ram'][0]['right_sha256'])

    def test_does_not_ignore_global_or_object_prefix_changes(self):
        left, right = Memory(), Memory()
        right.data[0x123] = 1
        right.data[0xc208] = 2
        result = compare_states(left, right, 0)
        self.assertEqual(result['h3']['changed_bytes'], 1)
        self.assertEqual(result['object_prefix_differences'][0]['changes']['changed_bytes'], 1)
        self.assertEqual(result['ram'][0]['changed_bytes'], 2)

    def test_rejects_different_tick(self):
        left, right = Memory(), Memory()
        self.assertEqual(same_tick(left, right, 0), 0)
        right.data[7] = 1
        with self.assertRaisesRegex(ValueError, 'Different completed'):
            same_tick(left, right, 0)

    def test_reports_different_registry_without_pointer_normalization(self):
        left, right = Memory(), Memory()
        right.data[0x85a0:0x85a4] = (0xc300).to_bytes(4, 'big')
        self.assertFalse(compare_states(left, right, 0)['registry_equal'])
