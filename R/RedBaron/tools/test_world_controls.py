import copy
import struct
import unittest
from world_controls import EXPECTED,events,compare,validate_consumption,scheduled_events


class WorldControlsTests(unittest.TestCase):
    def fixture(self,origin=100,paused=1000):
        q=bytearray(4112);log=bytearray(32)
        struct.pack_into('>4H',q,0,4,4,0,2)
        for i,(key,down) in enumerate(EXPECTED):
            deadline=(origin+3+18*i)&0xffffffff
            acquired=(deadline+paused-1)&0xffffffff
            struct.pack_into('>IHH',log,i*8,acquired,key,down)
            struct.pack_into('>IHHII',q,16+i*16,deadline,key,down,0,0)
        return q,log

    def test_exact_acquisition_deadlines_and_wrap(self):
        for origin in (100,0xfffffff0):
            q,log=self.fixture(origin)
            self.assertEqual([e['deadline'] for e in events(q,log,origin,1000)],[3,21,39,57])

    def test_reject_timestamp_disagreement(self):
        q,log=self.fixture();q[19]^=1
        with self.assertRaisesRegex(ValueError,'timestamp'):events(q,log,100,1000)

    def test_reject_unconsumed_or_overflowed_events(self):
        for index,value in ((0,5),(2,3),(4,1)):
            q,log=self.fixture();struct.pack_into('>H',q,index,value)
            with self.assertRaises(ValueError):events(q,log,100,1000)

    def test_equal_tick_matching_is_strict(self):
        left=dict(sha256='build',events=[dict(deadline=3,key=78,down=1)],
                  rows=[dict(tick=1,cursor=8,held='01',consumed=1,popped=1)])
        self.assertTrue(compare(left,copy.deepcopy(left))['same_input_history'])
        for field in ('cursor','consumed','popped','tick'):
            right=copy.deepcopy(left);right['rows'][0][field]+=1
            with self.assertRaisesRegex(ValueError,'equal-tick'):compare(left,right)
        right=copy.deepcopy(left);right['events'][0]['deadline']+=1
        with self.assertRaisesRegex(ValueError,'input histories'):compare(left,right)
        right=copy.deepcopy(left);right['sha256']='other'
        with self.assertRaisesRegex(ValueError,'builds'):compare(left,right)

    def test_preflight_held_transition_requires_modal_clock_evidence(self):
        q,log=self.fixture();clocks=bytearray(64)
        for i in range(4):struct.pack_into('>IIII',clocks,i*16,1,1000,0,0)
        struct.pack_into('>IIII',clocks,0,0,1000,1100,1000)
        struct.pack_into('>IHHII',q,16,101,0x14e,1,0,0)
        result=events(q,log,100,1000,clocks)
        self.assertEqual(result[0],dict(deadline=1,key=78,down=1,modal=True))
        with self.assertRaises(ValueError):events(q,log,100,1000)

    def test_consumption_replays_timestamps_including_held_only_event(self):
        history=[dict(deadline=-4,key=78,down=1,modal=True),
                 dict(deadline=10,key=78,down=0,modal=False),
                 dict(deadline=12,key=64,down=1,modal=False),
                 dict(deadline=25,key=64,down=0,modal=False)]
        held=bytearray(128)
        rows=[dict(tick=0,cursor=0,held=held.hex(),consumed=0,popped=0)]
        held[78]=1;rows.append(dict(tick=1,cursor=8,held=held.hex(),consumed=1,popped=0))
        held[78]=0;held[64]=1;rows.append(dict(tick=2,cursor=16,held=held.hex(),consumed=3,popped=1))
        held[64]=0;rows.append(dict(tick=3,cursor=26,held=held.hex(),consumed=4,popped=1))
        validate_consumption(rows,history)
        rows[1]['popped']=1
        with self.assertRaisesRegex(ValueError,'timestamp replay'):validate_consumption(rows,history)

    def test_scheduled_records_are_exact_and_wrap(self):
        for origin in (100,0xfffffff0):
            q=bytearray(4112);records=bytearray(64)
            struct.pack_into('>4H',q,0,4,4,0,4)
            for i,(key,down) in enumerate(EXPECTED):
                struct.pack_into('>IHHII',records,i*16,(origin+32*(i+1))&0xffffffff,key,down,0,0)
            q[16:80]=records
            self.assertEqual([e['deadline'] for e in scheduled_events(q,records,origin)],[32,64,96,128])
            q[19]^=1
            with self.assertRaisesRegex(ValueError,'queue differs'):scheduled_events(q,records,origin)
            records[3]^=1
            with self.assertRaisesRegex(ValueError,'flight-relative'):scheduled_events(q,records,origin)

    def test_scheduled_view_command_requires_explicit_fixture_selection(self):
        q=bytearray(4112);records=bytearray(64)
        struct.pack_into('>4H',q,0,4,4,0,4)
        for i,(key,down) in enumerate(((0x51,1),(0x51,0),(0x40,1),(0x40,0))):
            struct.pack_into('>IHHII',records,i*16,100+32*(i+1),key,down,0,0)
        q[16:80]=records
        self.assertEqual([e['key'] for e in scheduled_events(q,records,100,first_key=0x51)],
                         [0x51,0x51,0x40,0x40])
        with self.assertRaises(ValueError):scheduled_events(q,records,100)
        with self.assertRaises(ValueError):scheduled_events(q,records,100,first_key=0x52)
