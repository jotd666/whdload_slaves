#!/usr/bin/env python3
"""Execute normal-build option selection on native 68k; no timing claims.

Source the shared Amiga environment first. Argument: normal slave path;
its vasm listing must be beside it with an additional .lst suffix.
"""
import ctypes as C
import os
from pathlib import Path
import re
import struct
import sys
from hunks import read_hunks

slave = Path(sys.argv[1])
blob = read_hunks(slave.read_bytes())[0].data
symbols = {n: int(v, 16) for n, v in re.findall(
    r'^(\S+)\s+00:([0-9A-Fa-f]+)\s*$',
    slave.with_suffix(slave.suffix + '.lst').read_text(encoding='latin1'), re.M)}
assert b'C2:B:Enhanced framerate (68020+Fast RAM);' in blob
assert b'C3:' not in blob
assert 'perf_custom3' not in symbols
u = C.CDLL(str(Path(os.environ['AMIGA_UNICORN']) / 'lib/libunicorn.2.dylib'))
P, I, Q, Z = C.c_void_p, C.c_int, C.c_uint64, C.c_size_t
for name, args in {
    'uc_open': [I, I, C.POINTER(P)], 'uc_close': [P],
    'uc_ctl': [P, C.c_uint32],
    'uc_mem_map': [P, Q, Q, C.c_uint32],
    'uc_mem_write': [P, Q, P, Z], 'uc_mem_read': [P, Q, P, Z],
    'uc_reg_write': [P, I, P], 'uc_emu_start': [P, Q, Q, Q, Z],
}.items():
    getattr(u, name).argtypes = args
    getattr(u, name).restype = I

def check(result):
    assert result == 0, result

BASE, STACK, STOP, RESLOAD = 0x10000, 0x90000, 0x1000, 0x80000
for cpu, flags in [('000', 0), ('010', 1), ('020', 3),
                   ('030', 7), ('040', 15), ('060', 143)]:
    masks = []
    for rendering in (0, 1, 2, 3):
        h = P()
        check(u.uc_open(7, 1 << 30, C.byref(h)))
        try:
            check(u.uc_ctl(h, 7 | (1 << 26) | (1 << 30), I(2)))
            check(u.uc_mem_map(h, 0, 0x100000, 7))
            def write(at, data):
                check(u.uc_mem_write(h, at, data, len(data)))
            def long(at, value):
                write(at, struct.pack('>I', value))
            write(BASE, blob)
            # Control is stubbed after supplying its tag outputs; the actual
            # assembled selector and all CPU/dependency filters run unchanged.
            write(RESLOAD + 0x34, bytes.fromhex('4e75'))
            for name, value in [('_resload', RESLOAD), ('perf_custom2', rendering),
                                ('perf_attnflags', flags)]:
                long(BASE + symbols[name], value)
            long(STACK, STOP)
            for reg, value in [(17, 0x2700), (8, STACK)]:
                v = C.c_uint32(value)
                check(u.uc_reg_write(h, reg, C.byref(v)))
            check(u.uc_emu_start(h, BASE + symbols['perf_read_options'], STOP, 1000000, 2000))
            data = C.create_string_buffer(4)
            check(u.uc_mem_read(h, BASE + symbols['perf_mask'], data, 4))
            mask = int.from_bytes(data.raw, 'big')
            enabled = bool(rendering & 1) and cpu != '010'
            assert bool(mask & (1 << 13)) == enabled, (cpu, rendering, hex(mask))
            if enabled:
                assert mask & 0x300 == 0x300
            if not rendering & 1:
                assert mask == 0
            masks.append(mask)
        finally:
            check(u.uc_close(h))
    assert masks[0] == masks[2] == 0
    assert masks[1] == masks[3]
    if cpu in ('030', '040'):
        assert masks[1] & (1 << 23)
    if cpu == '030':
        assert masks[1] & (1 << 24) and masks[1] & (1 << 28)
    print(cpu, 'Off/On masks', *(hex(m) for m in masks[:2]))
print('PASS: 24 native option/CPU cases')
