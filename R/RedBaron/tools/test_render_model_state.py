import struct
import unittest
from render_model_state import fields, model_pointer


class RenderModelStateTests(unittest.TestCase):
    def setUp(self):
        self.memory = bytearray(65536)
        self.read = lambda a, n: bytes(self.memory[a:a+n])
        self.h3 = 0
        self.sim = 0x10000
        self.obj = 0x7000
        self.word(0x426a, 2)
        self.long(0x4262, 0x6000)
        self.long(0x6000, 0x6100)
        self.word(0x6004, 2)
        self.long(0x600c, 0x6200)
        self.word(0x6010, 2)
        self.long(0x6204, 0x8000)  # Model 3 in second bank.
        self.long(self.obj+26, self.sim+0xe0ec)
        self.long(self.obj+30, 0x8000)
        self.word(self.obj+2, 3)
        self.word(0x1014, 1)
        self.word(0x4c80, 3)
        self.word(0x4c82, 2)
        self.long(0x4c80+26, 0x6300)
        self.word(0x6300, 0x10)
        self.word(0x6302, 0x20)

    def word(self, a, n): self.memory[a:a+2] = struct.pack('>H', n)
    def long(self, a, n): self.memory[a:a+4] = struct.pack('>I', n)

    def test_banked_lookup_and_missing_model(self):
        self.assertEqual(model_pointer(self.read, 0, 3), 0x8000)
        self.assertEqual(model_pointer(self.read, 0, 4), 0)
        self.long(0x6000, 0)  # Empty bank still subtracts its count.
        self.assertEqual(model_pointer(self.read, 0, 3), 0x8000)

    def test_shared_models_deduplicated_and_exact_fields(self):
        actual = fields(self.read, 0, [self.obj, self.obj], self.sim)
        expected = [(0x4c80+14+2*i, 2, ['cached_color']) for i in range(6)]
        expected += [(0x8002, 1, ['model_variant']), (0x8013, 2, ['polygon_colors']), (0x8023, 2, ['polygon_colors'])]
        self.assertEqual(actual, expected)

    def test_native_early_exits_and_missing_model_fault(self):
        self.memory[self.obj] = 64
        self.assertEqual(fields(self.read, 0, [self.obj], self.sim), [])
        self.memory[self.obj] = 0
        self.memory[0x1075] = 17
        self.assertEqual(fields(self.read, 0, [self.obj], self.sim), [])
        self.memory[0x1075] = 0
        self.long(0x6204, 0)
        with self.assertRaises(ValueError): fields(self.read, 0, [self.obj], self.sim)


if __name__ == '__main__': unittest.main()
