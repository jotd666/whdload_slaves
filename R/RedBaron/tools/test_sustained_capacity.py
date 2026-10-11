import copy
import unittest
from game_time_core import DENOMINATOR, THRESHOLD, limbs
from sustained_capacity import check


def fixture(growing=False):
    rows=[]
    for field in range(1001):
        cia=field*297//250
        cursor=cia-(field//50 if growing else 0)
        ticks,credit=divmod(cursor*(DENOMINATOR//33)*1024,THRESHOLD)
        rows.append(dict(field=field,cia=cia,cursor=cursor,started=ticks,completed=ticks,due=0,
                         draws=field//100,active=1,paused=0,divisor=33,mask=16319,
                         transaction=0,compression=0,
                         **{f'phase{i}':n for i,n in enumerate(limbs(credit))}))
    windows=[]
    for begin in range(0,1000,250):
        windows.append(dict(before=copy.deepcopy(rows[begin]),after=copy.deepcopy(rows[begin+250]),
                            samples=copy.deepcopy(rows[begin+1:begin+251]),events={},
                            publications=[dict(field=f,beam=245<<8) for f in range(begin+1,begin+251) if f%100==0]))
    return dict(sha256='fixture',windows=windows)


class SustainedCapacityTests(unittest.TestCase):
    def test_consecutive_fields_and_fractional_backlog(self):
        r=check(fixture())
        self.assertEqual(r['committed_intervals'],1000)
        self.assertEqual(r['cia_debt_range'],[0,0])
        self.assertEqual(r['overall']['publications'],10)
        self.assertLess(r['backlog_world_ticks']['change'],1)
        self.assertGreater(r['longest_sampled_no_completion_span_fields'],0)
        self.assertLess(r['longest_sampled_no_completion_span_fields'],10)

    def test_conserved_time_does_not_hide_growing_debt(self):
        r=check(fixture(True))
        self.assertTrue(r['overall']['exact_funding'])
        self.assertEqual(r['cia_debt_range'],[0,20])
        self.assertGreater(r['backlog_world_ticks']['change'],2)
        self.assertLess(r['overall']['completed_over_nominal'],1)

    def test_transaction_is_reported_and_bridged(self):
        d=fixture();row=d['windows'][0]['samples'][10]
        row.update(transaction=1,phase0=0xffffffff)
        r=check(d)
        self.assertEqual(r['committed_intervals'],999)
        self.assertEqual(r['transaction_samples'],[dict(field=11,transaction=1)])

    def test_reject_missing_time_or_changed_rate(self):
        for mutation in ('missing','field','compression','divisor','transaction','completion'):
            d=fixture();row=d['windows'][0]['samples'][10]
            if mutation=='missing':d['windows'][0]['samples'].pop()
            elif mutation=='field':row['field']+=1
            elif mutation=='compression':row['compression']=1
            elif mutation=='divisor':row['divisor']=40
            elif mutation=='transaction':row['transaction']=7
            else:row['completed']+=1
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):check(d)


if __name__=='__main__':unittest.main()
