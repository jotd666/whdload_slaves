import unittest
from w6_rate_report import report

LOG = 'BEGIN 100 10 32\nPUB 1 11264\nPUB 3 11264\nEND 4 0 2 110 11 32\n'

class RateReportTests(unittest.TestCase):
    def test_rate_and_cadence(self):
        r = report(LOG, 4, 225, 40)
        self.assertEqual(r['world_steps'], 1)
        self.assertEqual(r['world_rate'], 225*32/(10*1024))
        self.assertEqual(r['cadence']['interval_fields'], {'2': 1})
        self.assertFalse(r['cadence']['every_field_published'])

    def test_three_sabotages(self):
        for broken in (LOG.replace('END 4', 'END 3'), LOG+'FLIGHT_EXIT\n',
                       LOG.replace('11264', str(42<<8))):
            with self.assertRaises(ValueError):report(broken,4,225,40)

    def test_reject_missing_publication(self):
        with self.assertRaises(ValueError):report(LOG.replace('PUB 3 11264\n',''),4,225,40)

    def test_68000_quantum_and_drops(self):
        r=report(LOG.replace('END 4 0','END 4 2'),4,450,60)
        self.assertEqual(r['world_rate'],450*32/(10*1024))
        self.assertEqual(r['dropped_units'],900)
        with self.assertRaises(ValueError):report(LOG,4,451,60)
