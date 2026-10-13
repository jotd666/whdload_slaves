import struct
import unittest
from overlay_cache_key import build
from overlay_dependency_guard import matches
import test_cockpit_dependencies

class OverlayGenerationTests(unittest.TestCase):
 def fixture(self):
  data,read=test_cockpit_dependencies.CockpitDependencyTests().fixture()
  key=build(read,0,3,0x40000,resource_epoch=7)
  def memory(address,size):
   return key[address-0x40000:address-0x40000+size] if address>=0x40000 else read(address,size)
  return data,key,memory
 def test_only_bulk_pixels_and_masks_are_tagged(self):
  data,key,read=self.fixture();count=int.from_bytes(key[4:6],'big')
  tagged=[struct.unpack_from('>IIHH',key,8+i*12) for i in range(count) if int.from_bytes(key[18+i*12:20+i*12],'big')]
  self.assertEqual([r[0] for r in tagged],[0xc200,0xc300])
  self.assertTrue(matches(read,0x40000,3,7)[0])
  self.assertLess(matches(read,0x40000,3,7)[1],matches(read,0x40000,3)[1])
 def test_lifetime_change_rejects_before_freed_bitmap_read(self):
  data,key,read=self.fixture()
  def guarded(at,n):
   self.assertFalse(0xc200<=at<0xc400);return read(at,n)
  self.assertFalse(matches(guarded,0x40000,3,8)[0])
 def test_selector_descriptor_clip_and_colour_mutations_still_reject(self):
  for at in (0x7b5e,0xc000,0xc100,0xc180,0xc188,0x9d48,0x3ab7):
   data,key,read=self.fixture();data[at]^=1
   self.assertFalse(matches(read,0x40000,3,7)[0],hex(at))
 def test_unguarded_bulk_mutation_is_detected_by_legacy_twin(self):
  for at in (0xc200,0xc300):
   data,key,read=self.fixture();data[at]^=1
   self.assertTrue(matches(read,0x40000,3,7)[0])
   self.assertFalse(matches(read,0x40000,3)[0])
