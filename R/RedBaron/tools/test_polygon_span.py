"""FC4 spans against the independent native blitter pipeline."""
import ctypes
import random
import struct
import unittest
import test_scene_raster as scene
import test_fast_blitter as blit

class PolygonSpanTests(unittest.TestCase):
 pixel=staticmethod(scene.SceneRasterTests.pixel)
 @classmethod
 def setUpClass(cls):
  scene.SceneRasterTests.setUpClass.__func__(cls);blit.FastBlitterTests.setUpClass()
 @classmethod
 def tearDownClass(cls):
  blit.FastBlitterTests.tearDownClass();scene.SceneRasterTests.tearDownClass.__func__(cls)
 def native(self,vertices,data,colour):
  b=blit.FastBlitterTests();b.setup_memory(data)
  def line(a,z,fn,one):
   x,y=a;x2,y2=z
   if y2<y:x,y,x2,y2=x2,y2,x,y
   dx=abs(x2-x);dy=y2-y;major=max(dx,dy);minor=min(dx,dy)
   control=(16|(4 if x2<x else 0)) if dx>dy else (8 if x2<x else 0)
   error=4*minor-2*major
   b.w(0x40,((x&15)<<12)|0xb00|fn);b.w(0x42,1|(2 if one else 0)|control|(64 if error<0 else 0))
   at=40000+y*40+(x//16)*2
   b.p(0x48,at);b.p(0x54,at);b.p(0x50,error&65535)
   b.w(0x60,40);b.w(0x64,4*(minor-major));b.w(0x62,4*minor)
   b.w(0x72,65535);b.w(0x74,32768);b.w(0x58,((major+1)<<6)|2)
   b.run_kernel()
  for i,a in enumerate(vertices):
   z=vertices[(i+1)%len(vertices)]
   if a[1]>z[1]:a,z=z,a
   if a[1]==z[1]:continue
   at=40000+a[1]*40+a[0]//8;b.memory[at]^=128>>(a[0]&7)
   line(a,z,0x5a,True)
  b.w(0x40,0x9f0);b.w(0x42,10);b.w(0x44,65535);b.w(0x46,65535)
  b.p(0x50,47998);b.p(0x54,47998);b.w(0x64,0);b.w(0x66,0);b.w(0x58,200*64+20);b.run_kernel()
  for i,a in enumerate(vertices):
   z=vertices[(i+1)%len(vertices)]
   if a[0]!=z[0]:line(a,z,0xca,False)
  expected=bytearray(data)
  for y in range(200):
   for x in range(320):
    if b.memory[40000+y*40+x//8]&(128>>(x&7)):self.pixel(expected,x,y,colour)
  return expected[:40000]
 def candidate(self,vertices,data,colour,bounds=(0,319,0,199)):
  memory=(ctypes.c_ubyte*len(data)).from_buffer_copy(data)
  v=48800
  for i,(x,y) in enumerate(vertices+[vertices[0]]):
   for j,value in enumerate(struct.pack('>hh',x,y)):memory[v+i*4+j]=value
  ctypes.c_void_p.in_dll(self.lib,'rb_test_memory').value=ctypes.addressof(memory)
  p=(ctypes.c_uint*12)(3,0,v,len(vertices),48000,0,0,colour,*bounds)
  rc=self.lib.rb_scene(p)
  return rc,bytes(memory)[:40000]
 @staticmethod
 def hull(points):
  points=sorted(set(points))
  def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
  def half(pts):
   out=[]
   for p in pts:
    while len(out)>1 and cross(out[-2],out[-1],p)<=0:out.pop()
    out.append(p)
   return out
  return half(points)[:-1]+half(points[::-1])[:-1]
 def test_native_random_convex_polygons(self):
  rng=random.Random(0xfc4)
  cases=[[(0,0),(319,0),(319,199),(0,199)],[(8,8),(9,10),(8,11)],[(5,5),(6,6),(5,7)]]
  cases += [self.hull([(rng.randrange(320),rng.randrange(200)) for _ in range(rng.randrange(3,16))]) for _ in range(250)]
  for v in cases:
   if len(v)<3:continue
   data=rng.randbytes(40000)+bytes(12000);colour=rng.randrange(32)
   rc,got=self.candidate(v,data,colour)
   self.assertEqual(rc,0,v);self.assertEqual(got,self.native(v,data,colour),v)
 def test_small_grid_and_thin_polygons(self):
  from itertools import combinations
  rng=random.Random(0x4fc)
  data=rng.randbytes(40000)+bytes(12000)
  cases=[self.hull(list(v)) for v in combinations([(x+14,y+80) for x in range(4) for y in range(4)],3)]
  cases += [self.hull([(rng.randrange(320),rng.randrange(200)),(x,y),(x+1,y)])
            for x,y in [(rng.randrange(319),rng.randrange(200)) for _ in range(300)]]
  for v in cases:
   if len(v)<3:continue
   rc,got=self.candidate(v,data,21)
   self.assertEqual(rc,0,v);self.assertEqual(got,self.native(v,data,21),v)
 def test_recorded_polygons_all_colours(self):
  import json
  from pathlib import Path
  data=random.Random(24).randbytes(40000)+bytes(12000)
  for case in json.loads(Path(__file__).with_name('polygon_span_cases.json').read_text()):
   for colour in range(32):
    v=case['vertices'];rc,got=self.candidate(v,data,colour)
    self.assertEqual(rc,0);self.assertEqual(got,self.native(v,data,colour))
 def test_clip_bounds_and_winding(self):
  data=random.Random(25).randbytes(40000)+bytes(12000)
  v=[(17,22),(100,22),(82,80),(17,90)]
  for verts in (v,v[::-1]):
   rc,got=self.candidate(verts,data,31,(17,100,22,90))
   self.assertEqual(rc,0);self.assertEqual(got,self.native(verts,data,31))
  for bounds in [(18,100,22,90),(17,99,22,90),(17,100,23,90),(17,100,22,89)]:
   rc,got=self.candidate(v,data,31,bounds)
   self.assertEqual(rc,1);self.assertEqual(got,data[:40000])
 def test_unsupported_returns_without_writing(self):
  data=random.Random(8).randbytes(40000)+bytes(12000)
  for v in [[(0,0),(8,0),(8,8),(0,8)]*2,[(0,0),(5,5),(2,2)],[(0,0),(8,0),(3,3),(8,8),(0,8)],[(-1,0),(20,0),(20,20)]]:
   rc,got=self.candidate(v,data,7);self.assertEqual(rc,1);self.assertEqual(got,data[:40000])

class PolygonCheckerTests(unittest.TestCase):
 def test_complete(self):
  from polygon_span import check
  self.assertEqual(check(struct.pack('>5I',63,0,6,0,0))['primitive_checks'],6)
 def test_missing_type(self):
  from polygon_span import check
  with self.assertRaises(ValueError):check(struct.pack('>5I',31,0,5,0,0))
 def test_pixel_mismatch(self):
  from polygon_span import check
  with self.assertRaises(ValueError):check(struct.pack('>5I',63,0,6,4,0))
 def test_armed_unfinished(self):
  from polygon_span import check
  with self.assertRaises(ValueError):check(struct.pack('>5I',63,1,6,0,0))
