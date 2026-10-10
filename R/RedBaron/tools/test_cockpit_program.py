import struct
import unittest
from cockpit_program import decode


class CockpitProgramTests(unittest.TestCase):
    def parse(self,*values,limit=1024):
        raw=struct.pack('>'+str(len(values))+'H',*values)
        return decode(lambda a,n:raw[a:a+n],0,limit)

    def test_terminator_is_not_an_operand(self):
        r=self.parse(0x2002,0x0ff0,7,0xa104,1,2,3,4,0x0ff0)
        self.assertEqual(r['bytes'],18)
        self.assertEqual([c['kind'] for c in r['commands']],['colours','rectangle'])

    def test_resource_selection_tracks_each_bitmap(self):
        r=self.parse(0x1051,1,0x1031,2,0xa502,43,74,0x1051,3,0xa532,90,80,0x0ff0)
        images=[c for c in r['commands'] if c['kind']=='bitmap']
        self.assertEqual([(c['image_set'],c['image'],c['mode']) for c in images],[(1,2,0),(3,2,3)])

    def test_reject_unproven_or_incomplete_programs(self):
        for values in [(0xa502,1,2,0x0ff0),(0xffff,0x0ff0),(0xa104,1,2)]:
            with self.subTest(values=values),self.assertRaises(ValueError):self.parse(*values)
        with self.assertRaises(ValueError):self.parse(0x2002,1,2,0x0ff0,limit=6)


if __name__=='__main__':unittest.main()
