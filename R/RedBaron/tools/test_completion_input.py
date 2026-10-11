"""Input-driver safeguards: malformed keys, stale owners and occupied queues."""
import importlib.util
import io
import struct
import sys
import types
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

class Error:
    def Success(self): return True

class Process:
    def __init__(self): self.memory = {}; self.writes = []
    def ReadMemory(self, address, size, error): return self.memory.get(address, bytes(size))
    def WriteMemory(self, address, data, error):
        self.writes.append((address, data)); self.memory[address] = data; return len(data)

class InputTest(unittest.TestCase):
    def setUp(self):
        self.p = Process()
        fake = types.SimpleNamespace(SBError=Error, debugger=types.SimpleNamespace(
            GetSelectedTarget=lambda: types.SimpleNamespace(GetProcess=lambda: self.p)))
        spec = importlib.util.spec_from_file_location('input_fixture', Path(__file__).with_name('completion_lldb_input.py'))
        self.m = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, lldb=fake): spec.loader.exec_module(self.m)
        self.m._mapping = 0x10000000
        self.base, self.bitmap = 0x200000, 0x2ba5c
        self.owner = self.m._mapping+self.base+0x15b3a
        self.p.memory[self.owner] = b'\x4e\xf9'+struct.pack('>I',self.base+0x2b4f4)

    def test_native_queue_only(self):
        with redirect_stdout(io.StringIO()): self.m.key(self.base,self.bitmap,0x44)
        at = self.m._mapping+self.base+self.bitmap
        self.assertEqual(self.p.writes,[(at-0x40,b'\0D'),(at+0x80,b'\0\2'),(at+0x44,b'\1')])

    def test_bad_key_does_not_write(self):
        with self.assertRaises(ValueError): self.m.key(self.base,self.bitmap,128)
        self.assertEqual(self.p.writes,[])

    def test_stale_owner_does_not_write_or_release(self):
        self.p.memory[self.owner] = bytes(6)
        with self.assertRaises(ValueError): self.m.key(self.base,self.bitmap,0x44)
        with redirect_stdout(io.StringIO()): self.m.release(self.base,self.bitmap,0x44)
        self.assertEqual(self.p.writes,[])

    def test_occupied_queue_is_preserved(self):
        self.p.memory[self.m._mapping+self.base+self.bitmap+0x80] = b'\0\2'
        with self.assertRaises(ValueError): self.m.key(self.base,self.bitmap,0x44)
        self.assertEqual(self.p.writes,[])

    def test_repeated_key_fits_native_64_byte_queue(self):
        with redirect_stdout(io.StringIO()): self.m.key(self.base,self.bitmap,0x4e,32)
        at=self.m._mapping+self.base+self.bitmap
        self.assertEqual(self.p.writes,[(at-0x40,b'\0N'*32),(at+0x80,b'\0@'),(at+0x4e,b'\1')])

    def test_zero_negative_and_overflow_counts_do_not_write(self):
        for count in (0,-1,33):
            with self.assertRaises(ValueError): self.m.key(self.base,self.bitmap,0x4e,count)
        self.assertEqual(self.p.writes,[])
