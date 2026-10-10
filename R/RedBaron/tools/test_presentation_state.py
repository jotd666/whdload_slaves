import unittest
from presentation_state import records, restore, STRIDE, CAPACITY


class PresentationStateTests(unittest.TestCase):
    def test_selection_and_exact_restoration_without_global_rollback(self):
        memory = bytearray(range(256))*128
        addresses = [64, 128, 192]
        memory[64], memory[128], memory[192] = 8, 72, 0
        read = lambda at, n: bytes(memory[at:at+n])
        saved = records(read, addresses)
        self.assertEqual(len(saved), 1)
        self.assertEqual(len(saved[0]), STRIDE)
        before = memory.copy()
        memory[64] ^= 6
        memory[90:94] = b'abcd'
        memory[98:116] = bytes(18)
        memory[65] ^= 1  # A field outside the restoration contract.
        memory[500] ^= 1  # Unrelated progress must survive.
        changed = memory.copy()
        def write(at, data): memory[at:at+len(data)] = data
        restore(write, saved)
        for at in range(len(memory)):
            selected = at == 64 or 90 <= at < 94 or 98 <= at < 116
            self.assertEqual(memory[at], before[at] if selected else changed[at])

    def test_capacity_duplicates_and_empty_lists(self):
        memory = bytearray(64)
        memory[0] = 8
        read = lambda at, n: bytes(memory[at:at+n])
        self.assertEqual(records(read, []), [])
        self.assertEqual(len(records(read, [0]*CAPACITY)), CAPACITY)
        with self.assertRaises(ValueError): records(read, [0]*(CAPACITY+1))
        with self.assertRaises(ValueError): restore(lambda *args: None, [bytes(27)])


if __name__ == '__main__': unittest.main()
