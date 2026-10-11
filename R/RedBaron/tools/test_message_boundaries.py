import unittest
from message_boundaries import policy,check_row,logical_events,priority_open


class MessageBoundaryTests(unittest.TestCase):
    def events(self):
        return [[100,278,1,1,14500,0,0,123],[108,126,2,1,1500,0,0,123],[126,126,3,2,1,2,2,123],[128,126,4,0,0,1,2,123]]

    def test_reset_shortening_expiry_and_delayed_erase(self):
        events=self.events();policy(events,14500);policy(events[:-1],14500)
        shifted=[[e[0]+3,e[1]+3,*e[2:]] for e in events]
        self.assertEqual(logical_events(events,100),logical_events(shifted,103))
        self.assertEqual(logical_events(events,100),logical_events(events[:-1],100))

    def test_bad_deadline_and_early_or_repeated_erase(self):
        for index,field,value in ((1,1,127),(2,0,125),(3,0,125),(3,4,1)):
            events=self.events();events[index][field]=value
            with self.assertRaises(ValueError):policy(events,14500)
        events=self.events();events.append(events[-1])
        with self.assertRaises(ValueError):policy(events,14500)

    def test_priority_threshold_and_pending_erase(self):
        self.assertTrue(priority_open(0));self.assertTrue(priority_open(1))
        self.assertTrue(priority_open(7499));self.assertFalse(priority_open(7500))
        for phase,timer in ((0,0),(2,1)):
            self.assertTrue(check_row(dict(phase=phase,timer=timer,deadline=126,now=130)))
        with self.assertRaises(ValueError):check_row(dict(phase=2,timer=0,deadline=126,now=130))

    def test_startup_residue_and_live_scaling(self):
        row=dict(phase=1,timer=14500,deadline=278,now=100)
        self.assertFalse(check_row(row,startup=True))
        with self.assertRaises(ValueError):check_row(row)
        self.assertTrue(check_row(dict(phase=1,timer=1517,deadline=126,now=108)))

    def test_wrapped_clock(self):
        events=[[0xfffffff0,162,1,1,14500,0,0,123],[162,162,3,2,1,2,0,123]]
        policy(events,14500)
        self.assertEqual(logical_events(events,0xfffffff0)[1][:2],[178,178])
