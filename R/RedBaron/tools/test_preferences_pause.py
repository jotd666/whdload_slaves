import unittest
from preferences_pause import check, clock


def fixture():
    base = dict(cursor=95,steps=1,skips=0,draws=1,active=1,paused=0,
                start=0,depth=0,base=0,phase=bytes(20),due=0,services=1)
    rows = []
    for label, cia in [('before',100),('entered',101),('leaving',301),('resumed',302),('world',303)]:
        c = dict(base)
        if label != 'before':
            c.update(start=101)
        if label in ('entered','leaving'):
            c.update(active=0,depth=1)
        if label in ('resumed','world'):
            c.update(cursor=296,paused=201)
        rows.append(dict(label=label,cia=cia,completed=1 if label=='world' else 0,
                         dt=225,player=0x1000,player_bytes=bytes(280),clock=c))
    return rows


class PreferencesPauseTests(unittest.TestCase):
    def test_preserves_old_debt(self):
        result=check(fixture())
        self.assertEqual((result['excluded_cia_ticks'],result['entry_debt'],result['resume_debt']),
                         (201,6,6))

    def test_reset_cursor_is_not_equivalent_to_exclusion(self):
        rows=fixture();rows[3]['clock']['cursor']=302
        with self.assertRaisesRegex(ValueError,'pre-existing debt'):
            check(rows)

    def test_reject_world_or_player_progress_inside_panel(self):
        for field,value in [('completed',1),('player_bytes',b'x'*280)]:
            rows=fixture();rows[2][field]=value
            with self.assertRaises(ValueError):check(rows)

    def test_reject_phase_change(self):
        rows=fixture();rows[2]['clock']['phase']=b'x'*20
        with self.assertRaisesRegex(ValueError,'clock advanced'):
            check(rows)

    def test_counter_wrap(self):
        rows=fixture()
        shift=0xffffff80
        for row in rows:
            row['cia']=(row['cia']+shift)&0xffffffff
            row['clock']['cursor']=(row['clock']['cursor']+shift)&0xffffffff
            if row['label']!='before':
                row['clock']['start']=(row['clock']['start']+shift)&0xffffffff
        self.assertEqual(check(rows)['excluded_cia_ticks'],201)

    def test_incomplete_clock(self):
        with self.assertRaisesRegex(ValueError,'Incomplete'):
            clock(bytes(59))


if __name__=='__main__':unittest.main()
