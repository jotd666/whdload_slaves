import unittest
from sound_phase_trace import event


class SoundPhaseTraceTests(unittest.TestCase):
    def regs(self, sp=0x8200):
        r = [0] * 17; r[8] = 0x2000; r[15] = sp; r[0] = 0x123402
        return r

    def test_assignment_records_value_and_owner(self):
        e = event(0x339c2, self.regs(), {0x2000: 2}, 0x8000)
        self.assertEqual((e['slot'], e['assigned'], e['interrupt']), (2, 2, True))

    def test_bit_mutations_do_not_invent_live_values(self):
        for pc in (0x33bf6, 0x33c2c, 0x34ed0):
            e = event(pc, self.regs(0x9000), {0x2000: 0}, 0x8000)
            self.assertFalse(e['interrupt']); self.assertNotIn('assigned', e)
        self.assertEqual(event(0x34f5e, self.regs(), {0x2000: 0}, 0x8000)['assigned'], 0)

    def test_unknown_owner_fails(self):
        with self.assertRaises(ValueError):
            event(0x34ea6, self.regs(), {}, 0x8000)
