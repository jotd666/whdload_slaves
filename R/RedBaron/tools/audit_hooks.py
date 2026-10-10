#!/usr/bin/env python3
"""Audit explicit hook boundaries, direct incoming branches and hunk relocations.
Linear disassembly cannot prove indirect-target safety; review those callers separately.
"""
import argparse,re,subprocess,tempfile
from pathlib import Path
from hunks import read_hunks
from hook_ranges import ranges
import struct

def audit(hunks,spans,listing,domain="sim"):
    def label(offset):return f"{domain}:{offset+(40 if domain == 'sound' else 0):05x}"
    ins={};errors=[]
    for line in listing.splitlines():
        m=re.match(r'\s*([0-9a-f]+):\s+((?:[0-9a-f]{4}\s+)+)\s*(.*)',line)
        if m:ins[int(m[1],16)]=(len(m[2].split())*2,m[3].strip())
    for lo,hi,bit,source,line in spans:
        at=lo
        while at<hi:
            if at not in ins:errors.append(f'{label(at)}: no decoded instruction');break
            size,op=ins[at]
            if '(bad)' in op or op.startswith('.'):errors.append(f'{label(at)}: ambiguous instruction')
            at+=size
        if at!=hi:errors.append(f'{label(lo)}: hook ends inside an instruction')
    for at,(_,op) in ins.items():
        if any(lo<=at<hi for lo,hi,*_ in spans):continue
        if not re.match(r'(?:b[a-z]+(?:\.[swl])?|db[a-z]+|jsr|jmp)\s',op):continue
        for dest in re.findall(r'0x([0-9a-f]+)',op):
            dest=int(dest,16)
            if any(lo<dest<hi for lo,hi,*_ in spans):errors.append(f'branch {label(at)} -> {label(dest)} inside hook')
    for index,h in enumerate(hunks):
        for at,target in h.relocations:
            if target!=0:continue
            dest=struct.unpack_from('>I',h.data,at)[0]
            if any(lo<dest<hi for lo,hi,*_ in spans):errors.append(f'hunk {index} relocation {at:05x} -> {label(dest)} inside hook')
    return errors

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original',type=Path)
    p.add_argument('--objdump',default='m68k-amiga-elf-objdump')
    p.add_argument('--domain', choices=['sim', 'sound'], default='sim');a=p.parse_args()
    h=read_hunks(a.original.read_bytes());spans=ranges(domain=a.domain)
    if not spans:raise SystemExit('PENDING: no performance ranges installed')
    with tempfile.TemporaryDirectory(prefix='redbaron-hook-audit-') as tmp:
        path=Path(tmp)/'code.bin';path.write_bytes(h[0].data)
        listing=subprocess.check_output([a.objdump,'-D','-b','binary','-m','m68k:68000',str(path)],text=True)
    errors=audit(h,spans,listing,a.domain)
    for e in errors:print(e)
    print(f'{len(spans)} ranges; {len(errors)} errors; indirect targets still require review')
    raise SystemExit(bool(errors))
if __name__=='__main__':main()
