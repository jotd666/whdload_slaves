import copy,unittest
from d5_report import input_window,catchup,modal,mission_exit,compression_window,ground_outcome,combat_outcome

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

    def test_exit_and_sabotages(self):
        b=dict(active=0,steps=12,cursor=100,quantum=450)
        h=dict(b);e=dict(b,active=1)
        mission_exit(b,h,e,38,33)
        for e1,lag in [(dict(e,steps=13),38),(e,10)]:
            with self.assertRaises(ValueError):mission_exit(b,h,e1,lag,33)

    def test_compression_sabotages(self):
        self.assertEqual(compression_window('COMPRESS 200 257\n'),257)
        for raw in ('COMPRESS 199 257\n','COMPRESS 200 0\n','CANCELLED\nCOMPRESS 200 257\n','FLIGHT_EXIT\nCOMPRESS 200 257\n'):
            with self.assertRaises(ValueError):compression_window(raw)

    def test_ground_outcome_sabotages(self):
        g=dict(stop='menu',contacts=[[20,4,49,-10,0]],altitude=50)
        b=dict(steps=30)
        ground_outcome(g,'landing',1,b,b)
        for bad,ret in [(dict(g,contacts=[[20,0,49,-10,0]]),1),(dict(g,contacts=[[20,4,49,-10,2]]),1),(g,0)]:
            with self.assertRaises(ValueError):ground_outcome(bad,'landing',ret,b,b)
        ground_outcome(dict(g,contacts=[[20,4,-30,-1000,3]],flags=8),'crash',1,b,b)
        with self.assertRaises(ValueError):ground_outcome(dict(g,contacts=[[20,4,-30,-1000,3]],flags=0),'crash',1,b,b)
        ground_outcome(dict(g,stop='flight_exit',contacts=[[20,4,-30,-1000,3]],flags=8),'crash',None,None,None)
        with self.assertRaises(ValueError):ground_outcome(dict(g,stop='flight_exit'),'landing',None,None,None)

    def test_combat_sabotages(self):
        raw='HIT 7 5 200 0\nKILL 30 8 100 200 8\nCOMBAT_STOP 42 30 1\n'
        self.assertEqual(combat_outcome(raw,100,200,42)['hits'],1)
        for bad in (raw.replace('100 200 8','101 200 8'),raw.replace('100 200 8','100 200 0'),raw.replace('HIT 7 5','HIT 7 0'),raw+'FLIGHT_EXIT\n'):
            with self.assertRaises(ValueError):combat_outcome(bad,100,200,42)
