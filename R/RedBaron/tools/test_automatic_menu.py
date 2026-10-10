import unittest
from automatic_menu import State,service,command_result


class AutomaticMenuTests(unittest.TestCase):
    def test_initial_deadline_and_reload(self):
        state=State()
        for i in range(235):
            state,opens=service(state,True,False,0)
            self.assertEqual(opens,i==234)
        self.assertEqual(state,State(10000,1,0))
        self.assertEqual(service(state,True,False,0),(state,False))

    def test_zero_does_not_expire_until_next_tick(self):
        state,opens=service(State(128),True,False,1)
        self.assertEqual((state.timer,opens),(0,False))
        state,opens=service(state,True,False,1)
        self.assertEqual((state,opens),(State(65408,1,1),True))
        self.assertEqual(service(state,True,False,1),(state,False))

    def test_native_predicate_and_signed_wrap(self):
        for ready,blocked,status in [(False,False,1),(True,True,0)]:
            self.assertEqual(service(State(),ready,blocked,status),(State(),False))
        self.assertEqual(service(State(32768),True,False,1),(State(32640),False))
        self.assertEqual(service(State(0),True,True,1),(State(65408,1,1),True))

    def test_native_menu_result_mapping(self):
        self.assertEqual([command_result(n) for n in range(10)],[4,4,4,4,4,3,4,4,2,4])
