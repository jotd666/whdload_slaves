import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
from call_costs import measure

SIM = 0x100000
SP = 0x5000
IRQ = 0x9000


def insn(pc, cycles, sp=SP, sr=0):
    regs = [0] * 17
    regs[15], regs[16] = sp, sr
    return pc, cycles, regs


def trace(rows):
    return SimpleNamespace(fields=[SimpleNamespace(index=0)], instructions=lambda _: iter(rows))


class CompleteCalls(unittest.TestCase):
    def test_user_mode_interrupt_callback_is_not_main(self):
        rows = [insn(SIM+0x304d0, 40), insn(SIM+0x304d4, 8, SP-44),
                insn(0x7fffffff, 44, IRQ), insn(0x1234, 100, IRQ-100, 0),
                insn(SIM+0x30570, 16)]
        with patch('call_costs.barto.load', return_value=trace(rows)):
            call = measure([Path('one')], SIM, 0x8000, 0xa000)['calls'][0]
        self.assertEqual((call['main_cycles'], call['irq_cycles'],
                          call['irq_entry_cycles'], call['wall_cycles']), (64, 100, 44, 208))

    def test_chunk_boundary_does_not_complete_a_cut_call(self):
        chunks = [trace([insn(SIM+0x304d0, 40)]), trace([insn(SIM+0x30570, 16)])]
        with patch('call_costs.barto.load', side_effect=chunks):
            result = measure([Path('one'), Path('two')], SIM, 0x8000, 0xa000)
        self.assertEqual(result['calls'], [])
        self.assertEqual(len(result['incomplete']), 1)

    def test_wrong_return_stack_is_rejected(self):
        rows = [insn(SIM+0x304d0, 40), insn(SIM+0x30570, 16, SP-4)]
        with patch('call_costs.barto.load', return_value=trace(rows)):
            with self.assertRaisesRegex(ValueError, 'restore'):
                measure([Path('one')], SIM, 0x8000, 0xa000)


if __name__ == '__main__':
    unittest.main()
