#!/usr/bin/env python3
"""Inventory original sim-v1 clock relocations and direct helper/stub calls.

This is a static candidate inventory, not an indirect-control-flow proof.
Inspect call sites against the disassembly before assigning semantic names.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from hunks import read_hunks

HELPERS = (0x3d68, 0x3dba, 0x3e0a, 0x3e2e, 0x3e4a, 0x3e5e, 0x3e7e, 0x3e94)


def inventory(raw):
    hunks = read_hunks(raw)
    code = hunks[0]
    refs, stubs, pointers, calls = [], {}, [], []
    for number, hunk in enumerate(hunks):
        for at, target in hunk.relocations:
            value = struct.unpack_from('>I', hunk.data, at)[0]
            if target == 3 and 0x4834 <= value < 0x483c:
                refs.append(dict(hunk=number, operand=at, target=f'h3:{value:05x}'))
            if target == 0 and value in HELPERS:
                is_stub = number == 0 and hunk.data[at-2:at] == b'\x4e\xf9'
                pointers.append(dict(hunk=number, operand=at, helper=f'sim:{value:05x}', jump_stub=is_stub))
                if is_stub:
                    stubs[at-2] = value
    targets = set(HELPERS) | set(stubs)
    for at in range(0, len(code.data)-5, 2):
        op = struct.unpack_from('>H', code.data, at)[0]
        if op in (0x4eba, 0x6100):
            dest = at+2+struct.unpack_from('>h', code.data, at+2)[0]
        elif op & 0xff00 == 0x6100 and op & 255 not in (0, 255):
            dest = at+2+struct.unpack_from('>b', code.data, at+1)[0]
        else:
            continue
        if dest in targets:
            calls.append(dict(site=f'sim:{at:05x}', via=f'sim:{dest:05x}', helper=f'sim:{stubs.get(dest, dest):05x}'))
    return dict(sim_sha256=hashlib.sha256(raw).hexdigest(), clock_relocations=refs,
                helper_pointers=pointers, calls=calls,
                counts={f'sim:{h:05x}': sum(c['helper'] == f'sim:{h:05x}' for c in calls) for h in HELPERS})


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('sim', type=Path)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    result = inventory(a.sim.read_bytes())
    a.out.write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result['counts'], indent=2))
