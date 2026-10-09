import struct
import unittest
from types import SimpleNamespace
from unittest.mock import patch
import frames


class PublicationTests(unittest.TestCase):
    def test_word_and_longword_publications_match_all_registers(self):
        for width in (2, 4):
            with self.subTest(width=width):
                registers = list(range(17))
                registers[8] = 0x10000
                values = [0xf64488 + n*0x10001 for n in range(12)]
                for index, value in zip((*range(2, 8), *range(9, 15)), values):
                    registers[index] = value
                words = [w for v in values for w in (v >> 16, v & 0xffff)]
                data = bytearray(58*100)
                payload = words if width == 2 else values
                for n, value in enumerate(payload):
                    offset = (n+10)*58
                    struct.pack_into('<H', data, offset, 0x1100+width)
                    struct.pack_into('<H' if width == 2 else '<I', data, offset+2, value)
                    struct.pack_into('<I', data, offset+12, 0x10000+n*width)
                    data[offset+29] = 2
                field = SimpleNamespace(index=0, dma_size=58, dma=data)
                trace = SimpleNamespace(fields=[field], instructions=lambda f: [(0x3154a, 0, registers)])
                with patch.object(frames.barto, 'load', return_value=trace):
                    result = frames.analyse(['unused'], 0)['swaps'][0]
                    self.assertTrue(result['dma_complete'])
                    self.assertEqual(result['first_write']['hpos'], 10)
                    self.assertEqual(result['last_write']['hpos'], 10+len(payload)-1)
                    data[10*58+2] ^= 1
                    self.assertFalse(frames.analyse(['unused'], 0)['swaps'][0]['dma_complete'])

    def test_longword_second_half_is_a_separate_memory_word(self):
        data = bytearray(58)
        struct.pack_into('<HI', data, 0, 0x1104, 0x1234abcd)
        struct.pack_into('<I', data, 12, 0x10000)
        data[29] = 2
        self.assertEqual(frames.cpu_write_words(data, 0), [(0x10000, 0x1234), (0x10002, 0xabcd)])
