"""Guarded hardware-key publication for the stripped profiling emulator."""
import importlib.util
from pathlib import Path
import struct
import sys
import types
import unittest
from unittest.mock import patch

class IRQInputTests(unittest.TestCase):
    def setUp(self):
        self.memory={0x2418e6:bytes.fromhex('486305f33d1702'),
                     0x241930:bytes.fromhex('488d15c93d1702893c82890da03d1702'),
                     0x23b56e0:struct.pack('<II',0,0)}
        self.writes=[]
        proc=types.SimpleNamespace(GetState=lambda:5,
            ReadMemory=lambda a,n,e:self.memory.get(a,b'')[:n],
            WriteMemory=lambda a,b,e:self.writes.append((a,b)) or len(b))
        header=types.SimpleNamespace(GetLoadAddress=lambda t:0,GetFileAddress=lambda:0)
        class Module:
            def __iter__(self): return iter(())
            def GetObjectFileHeaderAddress(self): return header
        module=Module()
        target=types.SimpleNamespace(modules=[],GetProcess=lambda:proc,GetModuleAtIndex=lambda i:module)
        stub=types.SimpleNamespace(eStateStopped=5,SBError=lambda:types.SimpleNamespace(Success=lambda:True),
            debugger=types.SimpleNamespace(GetSelectedTarget=lambda:target))
        spec=importlib.util.spec_from_file_location('irq_test_driver',Path(__file__).with_name('completion_lldb_input.py'))
        self.driver=importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules,lldb=stub):spec.loader.exec_module(self.driver)

    def test_payload_before_head(self):
        self.driver.irq_key(0x59)
        self.assertEqual(self.writes,[(0x23b5700,struct.pack('<I',0xb2)),
                                      (0x23b56e0,struct.pack('<I',1))])

    def test_sabotages_do_not_write(self):
        for kind in ('signature','full','index'):
            with self.subTest(kind=kind):
                self.setUp()
                if kind=='signature':self.memory[0x2418e6]=b'\0'*7
                else:self.memory[0x23b56e0]=struct.pack('<II',255 if kind=='full' else 256,0)
                with self.assertRaises(RuntimeError):self.driver.irq_key(0x59)
                self.assertEqual(self.writes,[])
