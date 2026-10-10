import unittest
import struct
from copy import deepcopy
from device_replay import direction, fixture_packet, check


class DeviceTests(unittest.TestCase):
    def test_every_hardware_word_against_native_decode_table(self):
        table=(0,2,8,10,1,3,9,11,4,6,12,14,5,7,13,15)
        for joy in range(65536):
            bits=(joy&0x303)^((joy&0x202)>>1)
            index=(bits+(bits>>6))&255
            self.assertEqual(direction(joy),table[index])

    def test_fixture_changes_only_at_prescribed_acquisitions(self):
        transitions=[t for t in range(1,150) if fixture_packet(t)!=fixture_packet(t-1)]
        self.assertEqual(transitions,[2,20,38,56,74,92,110,128])
        self.assertEqual(direction(int.from_bytes(fixture_packet(2)[:2],'big')),8)
        self.assertEqual(fixture_packet(38)[6],0x40)
        self.assertEqual(fixture_packet(74)[4:6],b'\xff\0')
        self.assertEqual(fixture_packet(110)[4:6],b'\0\xff')


class DeviceEvidenceTests(unittest.TestCase):
    def evidence(self):
        queue = bytearray(4112)
        struct.pack_into('>4H', queue, 0, 8, 8, 0, 2)
        acquisition = bytearray()
        rows = []
        axes = (0, 0, 0, 0, -127, -127, -127, -127,
                127, 127, 127, 127, 0, 0, 0, 0)
        for i, elapsed in enumerate((2, 20, 38, 56, 74, 92, 110, 128)):
            packet = fixture_packet(elapsed)
            wall, deadline = 100 + elapsed, elapsed + 1
            acquisition += struct.pack('>III', wall, 100, 1) + packet
            joy = int.from_bytes(packet[:2], 'big')
            struct.pack_into('>IHHII', queue, 16 + i * 16, deadline, 0x200,
                             joy, int.from_bytes(packet[2:6], 'big'), packet[6] << 24)
            flags = ((1 << 29) if elapsed in (38, 74) else
                     (1 << 28) if elapsed == 110 else 0)
            first, second = struct.unpack('>II', packet)
            rows.append([i, deadline, deadline + 20, first, second,
                         axes[direction(joy)], flags, 0])
        return [queue, acquisition, struct.pack('>II', 8, 8), rows, 100,
                axes, struct.pack('>II', 0, 0)]

    def test_complete_native_outputs(self):
        self.assertEqual(check(*self.evidence())['events'], 8)

    def test_corrupted_evidence_is_rejected(self):
        for mutation in ('deadline', 'packet', 'axis', 'fire', 'command',
                         'overflow', 'keyboard_leak', 'acquisition'):
            with self.subTest(mutation=mutation):
                args = deepcopy(self.evidence())
                if mutation == 'deadline':
                    struct.pack_into('>I', args[0], 16, 4)
                elif mutation == 'packet': args[3][0][3] = 0
                elif mutation == 'axis': args[3][0][5] = -127
                elif mutation == 'fire': args[3][2][6] = 0
                elif mutation == 'command': args[3][2][7] = 64
                elif mutation == 'overflow': struct.pack_into('>H', args[0], 4, 1)
                elif mutation == 'keyboard_leak': args[6] = struct.pack('>II', 1, 1)
                elif mutation == 'acquisition': args[1][13] = 0
                with self.assertRaises(ValueError): check(*args)


if __name__ == '__main__': unittest.main()

