import unittest
from matrix_call_costs import paired
from test_call_costs import trace,insn,SP,IRQ


class MatrixPairCosts(unittest.TestCase):
    def sample(self):
        start=list(insn(10,8));start[2][7]=63;start[2][6]=31
        return [tuple(start),insn(20,10),insn(0x7fffffff,44,IRQ),insn(90,70,IRQ-100),insn(22,16),insn(30,8),insn(40,20,SP-4),insn(32,16)]
    def test_matched_input_and_irq_separation(self):
        rows,cut=paired(trace(self.sample()),10,{'original':(20,22),'candidate':(30,32)},(0x8000,0xa000))
        self.assertFalse(cut);self.assertEqual((rows[0]['case'],rows[0]['ccr']),(0,31))
        self.assertEqual(rows[0]['calls']['original'],dict(main=26,irq=70,irq_entry=44,wall=140))
        self.assertEqual(rows[0]['calls']['candidate']['main'],44)
    def test_partial_pair_is_not_a_comparison(self):
        args=(10,{'original':(20,22),'candidate':(30,32)},(0x8000,0xa000))
        self.assertEqual(paired(trace(self.sample()[:-1]),*args),([],True))
        self.assertEqual(paired(trace(self.sample()[1:]),*args),([],False))
        with self.assertRaises(ValueError):paired(trace([self.sample()[0]]+self.sample()[-3:]),*args)

if __name__=='__main__':unittest.main()
