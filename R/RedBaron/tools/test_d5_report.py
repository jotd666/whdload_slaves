import copy,unittest
from d5_report import input_window,catchup,modal

class D5ReportTests(unittest.TestCase):
    def test_catchup_and_three_sabotages(self):
        held=input_window('INPUT 3 0 1 10 1\nINPUT 4 0 2 11 1\nEND 5 1\n',5)
        released=input_window('INPUT 1 0 3 12 1\nINPUT 2 0 4 13 0\nEND 5 0\n',5)
        self.assertEqual(catchup(held,released,210,190),1)
        for mutate in ('repeat','stuck','no_catchup'):
            h,r=copy.deepcopy(held),copy.deepcopy(released)
            if mutate=='repeat':h['commands']=2
            if mutate=='stuck':r['rows'][-1][4]=1
            if mutate=='no_catchup':h['rows'][-1][1]=1
            with self.assertRaises(ValueError):catchup(h,r,210,190)
    def test_incomplete_input(self):
        for raw in ('END 5 0\n','INPUT 1 0 1 1 0\nEND 4 0\n','INPUT 1 0 1 1 0\nFLIGHT_EXIT\nEND 5 0\n'):
            with self.assertRaises(ValueError):input_window(raw,5)
    def test_modal_and_three_sabotages(self):
        before=dict(active=0,steps=8,cursor=10,paused=20,due=2,quantum=450)
        held=dict(before);after=dict(before,active=1,cursor=210,paused=220)
        modal(before,held,after)
        for key,value in [('steps',9),('cursor',211),('due',0)]:
            bad=dict(after);bad[key]=value
            with self.assertRaises(ValueError):modal(before,held,bad)
