import unittest
from rectangle_scratch import Audit,DIRECT,FORWARDED,SCRATCH


class RectangleScratchTests(unittest.TestCase):
    def helper(self,audit):
        regs=[0]*16
        audit.feed(0x25244,regs)
        for pc,source,destination in [(0x2525c,0x100, SCRATCH),(0x2525e,0x104,SCRATCH+4),
                                      (0x25266,0x200,0x300),(0x25268,0x204,0x304)]:
            regs[8:10]=[source,destination];audit.feed(pc,regs)
        audit.feed(0x2526a,regs)
        regs[0]=SCRATCH;audit.feed(0x25304,regs)
        return regs

    def test_both_callers_consume_complete_result(self):
        for path in (DIRECT,FORWARDED):
            a=Audit(0);r=self.helper(a)
            for pc in path:
                if pc in path[-2:]:
                    part=pc==path[-1];r[8:10]=[SCRATCH+4*part,0x400+4*part]
                a.feed(pc,r)
            self.assertEqual(len(a.calls),1)
            self.assertIsNone(a.active)

    def test_reject_prior_scratch_dependency(self):
        a=Audit(0);r=[0]*16;a.feed(0x25244,r)
        r[8:10]=[SCRATCH,SCRATCH]
        with self.assertRaisesRegex(ValueError,'prior scratch'):a.feed(0x2525c,r)

    def test_reject_read_before_full_initialization(self):
        a=Audit(0);r=[0]*16;a.feed(0x25244,r)
        with self.assertRaisesRegex(ValueError,'before complete'):a.feed(0x2526a,r)

    def test_unclassified_return_is_not_accepted(self):
        a=Audit(0);r=self.helper(a)
        with self.assertRaisesRegex(ValueError,'Unclassified'):a.feed(0x1234,r)

    def test_incomplete_call_is_not_counted(self):
        a=Audit(0);self.helper(a)
        self.assertEqual(a.calls,[])
        self.assertIsNotNone(a.active)
