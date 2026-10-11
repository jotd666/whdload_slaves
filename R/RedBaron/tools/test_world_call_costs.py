import unittest
from world_call_costs import partition, START, END
from test_call_costs import insn, trace, SIM, SP, IRQ


class WorldPartitionTests(unittest.TestCase):
    def test_calls_include_nested_work_and_separate_interrupts(self):
        rows=[insn(SIM+START,10),insn(SIM+0x10a4,20,SP-20),
              insn(0x1234,30,SP-24),insn(0x7fffffff,44,IRQ),
              insn(0x5678,60,IRQ-100),insn(0x1238,16,SP-24),
              insn(SIM+0x10a8,12,SP-20),insn(SIM+END,16)]
        calls,cut=partition(trace(rows),SIM,{0x10a4:4},(0x8000,0xa000))
        self.assertFalse(cut);self.assertEqual(len(calls),1)
        self.assertEqual(calls[0]['groups'],{0x10a4:66,'overhead':38})
        self.assertEqual(calls[0]['wall'],208)
        self.assertEqual((calls[0]['irq'],calls[0]['irq_entry']),(60,44))

    def test_cut_world_and_bad_stack_are_not_accepted(self):
        rows=[insn(SIM+START,10),insn(SIM+0x10a4,20,SP-20)]
        self.assertEqual(partition(trace(rows),SIM,{0x10a4:4},(0x8000,0xa000)),([],True))
        for end in (insn(SIM+0x10a8,12,SP-24),insn(SIM+END,16)):
            with self.assertRaises(ValueError):
                partition(trace(rows+[end]),SIM,{0x10a4:4},(0x8000,0xa000))

if __name__=='__main__':unittest.main()
