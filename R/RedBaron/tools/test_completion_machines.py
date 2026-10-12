import unittest
from completion_machines import MACHINES, environment

class MachinesTest(unittest.TestCase):
    def test_matrix(self):
        for name in MACHINES:
            e = environment(name, environ={'KICKSTART_A1200': 'rom'})
            self.assertIn('CUSTOM2=0', e['WHD_ARGS'])
            self.assertIn('--uae_cpu_cycle_exact=true', e['EXTRA_ARGS'])
            if name in ('040', '060'):
                self.assertEqual(e['FAST_KB'], '0')
                self.assertIn('--uae_z3mem_size=16', e['EXTRA_ARGS'])
                self.assertTrue(e['CPU'].endswith('-NOMMU'))
                f = environment(name, functional=True, environ={'KICKSTART_A1200': 'rom'})
                self.assertNotIn('-NOMMU', f['CPU'])
                self.assertIn(' MMU', f['WHD_ARGS'])

    def test_raised_a500_memory_requirement(self):
        e = environment('a500', environ={})
        self.assertEqual(e['CPU'], '68000')
        self.assertEqual(e['CHIP_KB'], '512')
        self.assertEqual(e['FAST_KB'], '2048')
        self.assertIn('--slow_memory=0', e['EXTRA_ARGS'])
