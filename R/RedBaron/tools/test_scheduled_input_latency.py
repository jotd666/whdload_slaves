import unittest
from scheduled_input_latency import latencies,MASK


class ScheduledInputLatencyTests(unittest.TestCase):
    def rows(self,origin=0):
        return [[i+1,(origin+c)&MASK,(origin+c+lag)&MASK,0,0,0,0,0,0]
                for i,(c,lag) in enumerate(((8,0),(35,40),(67,30),(99,20),(131,10))) ]

    def test_separates_tick_quantization_and_scheduler_delay(self):
        result=latencies(self.rows(),[32,64,96,128],0)
        self.assertEqual([r['world_quantization_cia_ticks'] for r in result],[3]*4)
        self.assertEqual([r['scheduler_lateness_cia_ticks'] for r in result],[40,30,20,10])
        self.assertEqual([r['deadline_to_dispatch_cia_ticks'] for r in result],[43,33,23,13])

    def test_clock_wrap(self):
        origin=MASK-63
        result=latencies(self.rows(origin),[(origin+d)&MASK for d in (32,64,96,128)],origin)
        self.assertEqual([r['deadline_to_dispatch_cia_ticks'] for r in result],[43,33,23,13])

    def test_missing_history_and_reversed_clock_fail(self):
        rows=self.rows()
        for sequence in ([],rows[1:],rows[:-1],rows[:2]+rows[3:]):
            with self.assertRaises(ValueError):latencies(sequence,[32,64,96,128],0)
        rows[2][2]=rows[2][1]-1
        with self.assertRaises(ValueError):latencies(rows,[32,64,96,128],0)
