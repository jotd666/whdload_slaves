import random
import struct
import unittest
from scenery_cache import coalesce, matches, install, restore, check


class SceneryCacheTest(unittest.TestCase):
    def test_repeated_native_rebuild_and_world_edits(self):
        rng = random.Random(0xfc8)
        for _ in range(200):
            memory = bytearray(rng.randbytes(256))
            world = bytes(memory)
            journal = []
            for i in range(50):
                address = rng.randrange(32)*4
                size = 1 + (address//4 % 2)
                journal.append((address, bytes(memory[address:address+size])))
                memory[address:address+size] = rng.randbytes(size)
            expected = bytes(memory)
            cached = coalesce(journal, memory)
            restore(journal, memory)
            self.assertEqual(memory, world)
            self.assertTrue(matches(cached, memory))
            undo = install(cached, memory)
            self.assertEqual(memory, expected)
            # Later drawing may overwrite terrain bytes too: reverse journals
            # must recover the original world, not the cached presentation.
            address = cached[0][0]
            undo.append((address, bytes(memory[address:address+2])))
            memory[address:address+2] = b'XY'
            restore(undo, memory)
            self.assertEqual(memory, world)
            memory[address] ^= 1
            self.assertFalse(matches(cached, memory))

    def test_native_evidence_rejects_missing_or_corrupt_checks(self):
        self.assertEqual(check(struct.pack('>4I', 10, 2, 3, 12))['installs'], 10)
        for values in [(0, 2, 3, 12), (10, 0, 3, 12), (10, 2, 2, 12), (10, 2, 3, 9)]:
            with self.assertRaises(ValueError):
                check(struct.pack('>4I', *values))
        with self.assertRaises(ValueError):
            check(b'')


if __name__ == '__main__':
    unittest.main()
