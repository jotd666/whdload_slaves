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
