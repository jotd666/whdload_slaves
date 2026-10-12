"""Actual C raster primitives against independent planar pixel operations."""
import ctypes
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest
from cpu_span_model import merge_plane

class SceneRasterTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.tmp=tempfile.TemporaryDirectory(prefix='redbaron-scene-test-')
  out=Path(cls.tmp.name)/'scene.so'
  subprocess.run(['cc','-O2','-DRB_HOST_TEST','-fPIC','-dynamiclib' if sys.platform=='darwin' else '-shared','-o',str(out),str(Path(__file__).with_name('scene_raster.c'))],check=True,capture_output=True)
  cls.lib=ctypes.CDLL(str(out));cls.lib.rb_scene.argtypes=[ctypes.POINTER(ctypes.c_uint)];cls.lib.rb_scene.restype=ctypes.c_uint
 @classmethod
 def tearDownClass(cls):cls.tmp.cleanup()
 def run_scene(self,data,op,x,y,w,h,colour):
  memory=(ctypes.c_ubyte*len(data)).from_buffer_copy(data)
  ctypes.c_void_p.in_dll(self.lib,'rb_test_memory').value=ctypes.addressof(memory)
  packet=(ctypes.c_uint*8)(op,0,40000,x,y,w,h,colour)
  self.assertEqual(self.lib.rb_scene(packet),0)
  return bytes(memory)
 @staticmethod
 def pixel(data,x,y,colour):
  for plane in range(5):
   at=plane*8000+y*40+x//8;bit=128>>(x&7)
   data[at]=(data[at]&~bit)|(bit if colour>>plane&1 else 0)
 def test_rectangles_all_alignments_and_colours(self):
  rng=random.Random(20)
  for colour in range(32):
   for x in range(16):
    width=rng.choice((1,2,16,17,32,320-x));y=rng.randrange(190);height=rng.randrange(1,11)
    data=rng.randbytes(48000);expected=bytearray(data)
    for yy in range(y,y+height):
     for xx in range(x,x+width):self.pixel(expected,xx,yy,colour)
    self.assertEqual(self.run_scene(data,0,x,y,width,height,colour),expected)
 def test_merges_against_five_native_plane_operations(self):
  rng=random.Random(21)
  for _ in range(120):
   data=rng.randbytes(48000);expected=bytearray(data);words=rng.randrange(1,21);rows=rng.randrange(1,201);bottom=(rows-1)*40+(words-1)*2;colour=rng.randrange(32)
   for plane in range(5):expected[plane*8000:(plane+1)*8000]=merge_plane(data[40000:],data[plane*8000:(plane+1)*8000],bottom,words,rows,colour>>plane&1)
   self.assertEqual(self.run_scene(data,2,bottom,words,rows,0,colour),expected)
 def test_lines_native_error_ties_and_both_endpoints(self):
  # Independent integer rounding: nearest minor coordinate, half ties up.
  rng=random.Random(22)
  for _ in range(240):
   x,x2=rng.randrange(320),rng.randrange(320);y=rng.randrange(200);y2=rng.randrange(y,200);colour=rng.randrange(32)
   data=rng.randbytes(48000);expected=bytearray(data);dx=abs(x2-x);dy=y2-y;n=max(dx,dy);sx=1 if x2>=x else -1
   for i in range(n+1):
    minor=(2*i*min(dx,dy)+n)//(2*n) if n else 0
    xx=x+sx*(i if dx>dy else minor);yy=y+(minor if dx>dy else i)
    self.pixel(expected,xx,yy,colour)
   self.assertEqual(self.run_scene(data,1,x,y,x2,y2,colour),expected)
