import copy
import unittest
from compare_field_capacity import compare
from game_time_core import DENOMINATOR,THRESHOLD,limbs


class PairedCapacityTests(unittest.TestCase):
    def fixture(self):
        def state(field,cia,draws):
            ticks,credit=divmod(cia*(DENOMINATOR//33)*1024,THRESHOLD)
            return dict(field=field,cia=cia,cursor=cia,started=ticks,completed=ticks,due=0,draws=draws,
                        active=1,paused=0,divisor=33,**{f'phase{i}':v for i,v in enumerate(limbs(credit))})
        e={k:'fixture' for k in ('slave_sha256','sim_sha256','preferences_sha256','cpu','chip_kb','fast_kb','extra_args','detail')}
        entries=[dict(e,whd_args='CUSTOM2=16319 CUSTOM4=0 CUSTOM5=512'),dict(e,whd_args='CUSTOM2=16319 CUSTOM4=0 CUSTOM5=1073742336')]
        censuses=[dict(sha256='fixture',whd_args=x['whd_args'],windows=[dict(before=state(0,0,0),after=state(250,297,2 if i==0 else 0),
                   publications=[dict(field=100,beam=245<<8),dict(field=200,beam=10<<8)] if i==0 else [],events={})]) for i,x in enumerate(entries)]
        return entries,censuses

    def test_equal_funding_with_different_completed_counts_retains_debt(self):
        e,c=self.fixture();row=c[0]['windows'][0]['after'];row['completed']-=1;row['started']-=1;row['due']+=1
        result=compare(e,c)
        self.assertTrue(result['funding_per_cia_tick_equal'])
        self.assertEqual(result['render']['completed_world_ticks']+1,result['no_render']['completed_world_ticks'])
        self.assertAlmostEqual(result['render']['backlog_after']-result['no_render']['backlog_after'],1)

    def test_changed_cpu_or_extra_fixture_is_rejected(self):
        for kind in ('cpu','option','argument'):
            e,c=self.fixture()
            if kind=='cpu':e[1]['cpu']='other'
            elif kind=='option':e[1]['whd_args']=e[1]['whd_args'].replace('CUSTOM4=0','CUSTOM4=1');c[1]['whd_args']=e[1]['whd_args']
            else:e[1]['whd_args']+=' MMU';c[1]['whd_args']=e[1]['whd_args']
            with self.assertRaises(ValueError):compare(e,c)

    def test_missing_rendering_or_wrong_census_identity_rejected(self):
        e,c=self.fixture();c[0]['windows'][0]['publications']=[];c[0]['windows'][0]['after']['draws']=0
        with self.assertRaises(ValueError):compare(e,c)
        e,c=self.fixture();c[1]['sha256']='other'
        with self.assertRaises(ValueError):compare(e,c)
