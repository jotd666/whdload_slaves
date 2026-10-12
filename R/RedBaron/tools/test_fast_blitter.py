"""Exercise the actual freestanding C kernel against independent pixel rules."""
import ctypes
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import unittest

class FastBlitterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='redbaron-kernel-test-')
        output=Path(cls.tmp.name)/'kernel.so'
        source=Path(__file__).resolve().with_name('fast_blitter_model.c')
        subprocess.run(['cc','-O2','-DRB_HOST_TEST','-fPIC',
                        '-dynamiclib' if sys.platform=='darwin' else '-shared',
                        '-o',str(output),str(source)],check=True,capture_output=True)
        cls.lib=ctypes.CDLL(str(output))
        cls.lib.rb_blit.argtypes=[ctypes.POINTER(ctypes.c_ushort)]
        cls.lib.rb_blit.restype=ctypes.c_uint
    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()
    def setup_memory(self,data):
        self.memory=(ctypes.c_ubyte*len(data)).from_buffer_copy(data)
        ctypes.c_void_p.in_dll(self.lib,'rb_test_memory').value=ctypes.addressof(self.memory)
        self.regs=(ctypes.c_ushort*128)()
    def w(self,off,value):self.regs[off//2]=value&65535
    def p(self,off,value):ctypes.c_uint.from_buffer(self.regs,off).value=value
    def run_kernel(self):self.assertEqual(self.lib.rb_blit(self.regs),0)
    def test_every_minterm(self):
        rng=random.Random(0xe3)
        for table in range(256):
            a,b,c=[rng.randrange(65536) for _ in range(3)]
            self.setup_memory(bytes(64));self.p(0x54,16)
            self.w(0x40,0x100|table);self.w(0x44,65535);self.w(0x46,65535)
            self.w(0x74,a);self.w(0x72,b);self.w(0x70,c);self.w(0x58,65)
            expected=sum(((table>>(((a>>i&1)<<2)|((b>>i&1)<<1)|(c>>i&1)))&1)<<i for i in range(16))
            self.run_kernel()
            self.assertEqual(bytes(self.memory)[16:18],expected.to_bytes(2,'big'))
    def test_area_fill_resets_carry_on_each_row(self):
        rng=random.Random(0xf11)
        for inclusive in (False,True):
            for initial in (0,1):
                for width in (1,2,7,20):
                    data=bytearray(rng.randbytes(400));expected=bytearray(data)
                    bottom=300
                    for row in range(4):
                        carry=initial
                        for x in range(width):
                            at=bottom-row*40-x*2
                            word=int.from_bytes(data[at:at+2],'big');value=0
                            for bit in range(16):
                                old=(word>>bit)&1
                                value|=((old|carry) if inclusive else (old^carry))<<bit
                                carry^=old
                            expected[at:at+2]=value.to_bytes(2,'big')
                    self.setup_memory(data);self.p(0x50,bottom);self.p(0x54,bottom)
                    self.w(0x40,0x9f0);self.w(0x42,2|(8 if inclusive else 16)|(initial<<2))
                    self.w(0x44,65535);self.w(0x46,65535)
                    self.w(0x64,40-width*2);self.w(0x66,40-width*2);self.w(0x58,4*64+width)
                    self.run_kernel();self.assertEqual(bytes(self.memory),expected)
    def test_descending_scratch_clear_alignment_and_bounds(self):
        rng=random.Random(0xc1ea)
        for width in range(1,21):
            for rows in (1,2,17):
                for alignment in (0,2):
                    bottom=rows*40+40+alignment
                    data=rng.randbytes(1000);expected=bytearray(data)
                    for row in range(rows):
                        end=bottom-row*40+2
                        expected[end-width*2:end]=bytes(width*2)
                    self.setup_memory(data);self.p(0x54,bottom)
                    self.w(0x40,0x100);self.w(0x42,2)
                    self.w(0x66,40-width*2);self.w(0x58,rows*64+width)
                    self.run_kernel();self.assertEqual(bytes(self.memory),expected)
                    self.assertEqual(ctypes.c_uint.from_buffer(self.regs,0x54).value,bottom-rows*40)

    def test_long_solid_paths_against_pixel_model(self):
        from fill_model import cpu_plane,setup
        rng=random.Random(0x32f1)
        for base in (0,2):
            for _ in range(160):
                x=rng.randrange(320);width=rng.randrange(1,321-x)
                rows=rng.choice((1,2,17));colour=rng.randrange(2)
                first,last,words=setup(x,width)
                data=rng.randbytes(8004);at=base+40+(x//16)*2
                expected,_=cpu_plane(data,at,words,rows,first,last,colour)
                self.setup_memory(data);self.p(0x48,at);self.p(0x54,at)
                channels=0x100 if first==last==65535 else 0x300
                self.w(0x40,channels|(0xfa if colour else 0x0a))
                self.w(0x44,first);self.w(0x46,last);self.w(0x74,65535)
                self.w(0x60,40-words*2);self.w(0x66,40-words*2)
                self.w(0x58,rows*64+words);self.run_kernel()
                self.assertEqual(bytes(self.memory),expected,(base,x,width,rows,colour))
    def test_long_coverage_merge_against_pixel_model(self):
        from cpu_span_model import merge_plane
        rng=random.Random(0x32ca)
        for words in range(1,21):
            for rows in (1,2,17):
                for colour in (0,1):
                    for right in (19,words-1):
                        data=rng.randbytes(16000);bottom=rows*40+right*2
                        expected=bytearray(data)
                        expected[8000:]=merge_plane(data[:8000],data[8000:],bottom,words,rows,colour)
                        self.setup_memory(data);self.p(0x50,bottom)
                        self.p(0x48,8000+bottom);self.p(0x54,8000+bottom)
                        self.w(0x40,0xb00|(0xfa if colour else 0x0a));self.w(0x42,2)
                        self.w(0x44,65535);self.w(0x46,65535)
                        for off in (0x60,0x64,0x66):self.w(off,40-words*2)
                        self.w(0x58,rows*64+words);self.run_kernel()
                        self.assertEqual(bytes(self.memory),expected,(words,rows,colour,right))
    def test_shifted_masked_copies_against_bit_stream(self):
        rng=random.Random(0xca)
        for descending in (False,True):
            for shift in range(16):
                for width in (1,3,9):
                    data=bytearray(rng.randbytes(2048));expected=bytearray(data)
                    first,last=rng.randrange(65536),rng.randrange(65536)
                    base=128+ (128 if descending else 0)
                    dest=1024+ (128 if descending else 0)
                    step=-2 if descending else 2
                    ahistory=[0]*16;bhistory=[0]*16
                    for row in range(3):
                        for col in range(width):
                            offset=step*col+(-32 if descending else 32)*row
                            a=int.from_bytes(data[base+offset:base+offset+2],'big')
                            b=int.from_bytes(data[base+512+offset:base+514+offset],'big')
                            if col==0:a &= first
                            if col==width-1:a &= last
                            abits=[a>>i&1 for i in range(16)]
                            bbits=[b>>i&1 for i in range(16)]
                            result=0
                            c=int.from_bytes(data[dest+offset:dest+offset+2],'big')
                            for bit in range(16):
                                index=bit-shift if descending else bit+shift
                                av=abits[index] if 0<=index<16 else ahistory[index%16]
                                bv=bbits[index] if 0<=index<16 else bhistory[index%16]
                                result|=(bv if av else (c>>bit&1))<<bit
                            expected[dest+offset:dest+offset+2]=result.to_bytes(2,'big')
                            ahistory,bhistory=abits,bbits
                    self.setup_memory(data)
                    for off,ptr in ((0x50,base),(0x4c,base+512),(0x48,dest),(0x54,dest)):
                        self.p(off,ptr)
                    self.w(0x40,(shift<<12)|0xfca)
                    self.w(0x42,(shift<<12)|(2 if descending else 0))
                    self.w(0x44,first);self.w(0x46,last)
                    for off in (0x60,0x62,0x64,0x66):self.w(off,32-2*width)
                    self.w(0x58,3*64+width);self.run_kernel()
                    self.assertEqual(bytes(self.memory),expected,(descending,shift,width))
    def test_lines_all_octants_and_word_boundaries(self):
        rng=random.Random(0x11ee)
        for _ in range(256):
            x0,x1=rng.randrange(320),rng.randrange(320)
            y0,y1=rng.randrange(140),rng.randrange(140)
            dx,dy=abs(x1-x0),abs(y1-y0);xmajor=dx>=dy
            major,minor=(dx,dy) if xmajor else (dy,dx)
            for colour in (0,1):
                data=rng.randbytes(8000);expected=bytearray(data)
                x,y=x0,y0;error=2*minor-major
                for i in range(major+1):
                    at=y*40+x//8;bit=128>>(x%8)
                    expected[at]=expected[at]|bit if colour else expected[at]&~bit
                    if error>=0:
                        if xmajor:y+=1 if y1>=y0 else -1
                        else:x+=1 if x1>=x0 else -1
                        error-=2*major
                    error+=2*minor
                    if xmajor:x+=1 if x1>=x0 else -1
                    else:y+=1 if y1>=y0 else -1
                control=1|(16 if xmajor else 0)
                if (x1<x0 if xmajor else y1<y0):control|=4
                if (y1<y0 if xmajor else x1<x0):control|=8
                if 4*minor-2*major<0:control|=64
                self.setup_memory(data);at=y0*40+(x0//16)*2
                self.p(0x48,at);self.p(0x54,at);self.p(0x50,(4*minor-2*major)&65535)
                self.w(0x40,((x0%16)<<12)|0xb00|(0xfa if colour else 0x0a))
                self.w(0x42,control);self.w(0x60,40);self.w(0x62,4*minor)
                self.w(0x64,4*(minor-major));self.w(0x66,40);self.w(0x72,65535);self.w(0x74,32768)
                self.w(0x58,(major+1)*64+2)
                self.run_kernel();self.assertEqual(bytes(self.memory),expected,(x0,y0,x1,y1,colour))

if __name__=='__main__':unittest.main()
