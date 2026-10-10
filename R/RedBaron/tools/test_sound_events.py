import struct
import unittest
from types import SimpleNamespace
from sound_events import decode_fields, compare


def record(kind, reg, address, value):
    data = bytearray(58)
    struct.pack_into('<HI', data, 0, reg, value)
    struct.pack_into('<I', data, 12, address)
    data[29] = kind
    return data


class SoundEventsTests(unittest.TestCase):
    def test_long_pointer_write_and_channel_fetch(self):
        data = record(2, 0x1104, 0xdff0a0, 0x00123456)
        data += record(4, 0xba, 0x123456, 0xabcd)
        data += record(2, 0x1002, 0xdff0a8, 17)  # read, not write
        result = decode_fields([SimpleNamespace(dma_size=58, dma=data)])
        self.assertEqual(result['writes'], {'AUD0LCH': [0x12], 'AUD0LCL': [0x3456]})
        self.assertEqual(result['fetches'], {'AUD1DAT': [0xabcd]})

    def test_comparison_keeps_order_and_repeated_writes(self):
        left = {'writes': {'AUD0VOL': [1, 2, 1]}, 'fetches': {}}
        right = {'writes': {'AUD0VOL': [1, 1, 2]}, 'fetches': {}}
        self.assertEqual(compare(left, right)[0]['first_difference'], 1)
        right['writes']['AUD0VOL'] = [1, 2]
        self.assertEqual(compare(left, right)[0]['first_difference'], 2)
        self.assertEqual(compare(left, left), [])

    def test_reject_unknown_audio_format(self):
        with self.assertRaises(ValueError):
            decode_fields([SimpleNamespace(dma_size=58, dma=record(4, 0, 0, 0))])
