"""Conservative 68000 memory-operand census during complete native world/service calls.

Uses snapshot instruction bytes and traced pre-instruction registers. Address
forming operands and possible implicit stack traffic are included. No read/write
or gameplay-purity claim is inferred from a zero candidate count.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
import capstone
import barto
from game_heap import segments
from player_links import SIM_SHA
from render_mutations import Snapshot
from presentation_state import symbol


def signed(value,bits):
    value&=(1<<bits)-1
    return value-(1<<bits) if value&(1<<(bits-1)) else value


def operands(insn,registers):
    """Conservative byte extents, including LEA/PEA/branch target addresses.

    MOVEM uses its maximum 64-byte extent; MOVEP includes its spaced bytes.
    Unsupported addressing modes fail rather than being silently skipped.
    Returned addresses are physical 24-bit addresses for a 68000 only.
    """
    r=list(registers);result=[];name=insn.mnemonic.split('.')[0]
    width=max(1,insn.op_size.size)
    if name=='movem':width=64
    if name=='movep':width=8
    for o in insn.operands:
        if o.type!=capstone.m68k.M68K_OP_MEM:continue
        mode=o.address_mode
        if mode in (3,4,5):
            index=o.reg-1
            if not 8<=index<16:raise ValueError('Invalid address register')
            step=max(2,width) if index==15 else width
            address=r[index]
            if mode==5:address-=step;r[index]=address
            if mode==4:r[index]+=step
        elif mode in (6,7,8,11,12,13):
            if mode in (11,12,13):
                # MOVEM has a register mask before its EA extension; immediate
                # bit operations likewise have their bit number before the EA.
                extension=4 if name=='movem' or (name=='btst' and insn.operands[0].type==2) else 2
                address=insn.address+extension
            else:
                index=o.mem.base_reg-1
                if not 8<=index<16:raise ValueError('Invalid displacement base')
                address=r[index]
            address+=o.mem.disp
            if o.mem.index_reg:
                if o.mem.in_disp or o.mem.out_disp or o.mem.scale not in (0,1):
                    raise ValueError('Not a 68000 brief index')
                index=o.mem.index_reg-1
                if not 0<=index<16:raise ValueError('Invalid index register')
                address+=signed(r[index],32 if o.mem.index_size else 16)
        elif mode in (16,17):address=signed(o.imm,16) if mode==16 else o.imm
        else:raise ValueError(f'Unsupported memory address mode {mode}')
        result.append((address&0xffffff,width))
    if name=='unlk':
        index=insn.operands[0].reg-1
        if not 8<=index<16:raise ValueError('Invalid UNLK frame register')
        result.append((registers[index]&0xffffff,4))
    # Ordinary pushes/pops fit in this conservative neighborhood. UNLK's
    # independently addressed frame read is included above. Keep
    # this independent of instruction decoding (LINK/UNLK/RTS and traps too).
    result.append(((registers[15]-64)&0xffffff,128))
    return result


def overlaps(address,size,lo,hi):
    if size<1 or size>0x1000000 or not 0<=address<0x1000000:raise ValueError('Invalid extent')
    end=address+size
    return (address<hi and end>lo) or (end>0x1000000 and end-0x1000000>lo)


def check(root,routine="world"):
    entry=json.loads((root/'entry.json').read_text());manifest=json.loads((root/'capacity.json').read_text())
    digest=hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()
    if {entry['slave_sha256'],manifest['sha256']}!={digest}:raise ValueError('Different frozen build')
    if entry['sim_sha256']!=SIM_SHA or entry['cpu']!='68000':raise ValueError('Requires supported sim and 68000')
    sim=entry['entry']['sim'];cs=capstone.Cs(capstone.CS_ARCH_M68K,capstone.CS_MODE_M68K_000);cs.detail=True
    if routine=='world':start,end=sim+0x1098,sim+0x11c8
    elif routine=='services':
        lines=(root/'slave.lst').read_text(encoding='latin-1').splitlines()
        base=entry['entry']['game_anchor']-symbol(lines,'tape_game_anchor')
        offset=symbol(lines,'time_loop_poll');start=base+offset
        ends=[int(m[1],16) for line in lines if (m:=re.match(r'00:([0-9A-F]+)\s+4E75\s',line)) and int(m[1],16)>=offset]
        if not ends:raise ValueError('Missing service-poll return')
        end=base+min(ends)
    else:raise ValueError('Unknown census routine')
    rows=[];incomplete=[];decoded={}
    for chunk in manifest['chunks']:
        directory=root/chunk['path']
        banks=[dict(file=p.name,base=int(p.stem.split('-')[1],16),size=p.stat().st_size) for p in directory.glob('memory-*.bin')]
        ram=Snapshot(directory,banks);h3=segments(ram.read,sim)[3][0];lo,hi=h3+0xa4e6,h3+0xb9d2
        trace=barto.load(directory/'trace.bin');cache={};active=None
        # Establish the interrupt stack from the game's retained IRQ entry.
        irq={r[15]&~0xfff for f in trace.fields for pc,_,r in trace.instructions(f) if pc==sim+0x2ffcc}
        if len(irq)!=1:raise ValueError('Ambiguous or missing interrupt stack')
        irq_lo=irq.pop()
        for field in trace.fields:
            for pc,_,regs in trace.instructions(field):
                if pc==start:
                    if active is not None:raise ValueError('Nested census call')
                    active=dict(chunk=chunk['path'],first_field=field.index,sp=regs[15],instructions=0,candidates=[])
                if active is None or pc in (None,0x7fffffff):continue
                if irq_lo<=regs[15]<irq_lo+4096:continue
                if not active['sp']-0x4000<=regs[15]<=active['sp']:raise ValueError('Unclassified census stack')
                if pc not in cache:
                    try:raw=ram.read(pc,22)
                    except ValueError:
                        offset=pc-(0x1000000-len(trace.rom))
                        if not 0<=offset<len(trace.rom):raise ValueError('Instruction outside captured code')
                        raw=trace.rom[offset:offset+22]
                    insn=next(cs.disasm(raw,pc,count=1),None)
                    if insn is None or insn.mnemonic.startswith('dc.'):raise ValueError('Undecoded instruction')
                    code=bytes(insn.bytes)
                    if pc in decoded and decoded[pc]!=code:raise ValueError('Instruction changed between snapshots')
                    decoded[pc]=code;cache[pc]=insn
                insn=cache[pc];active['instructions']+=1
                for address,size in operands(insn,regs):
                    if overlaps(address,size,lo,hi):
                        active['candidates'].append(dict(pc=pc,field=field.index,address=address,size=size,instruction=insn.mnemonic+' '+insn.op_str))
                if pc==end:
                    if regs[15]!=active['sp']:raise ValueError('Census call did not restore stack')
                    active['last_field']=field.index;rows.append(active);active=None
        if active is not None:incomplete.append(active)
    if not rows:raise ValueError('No complete census calls')
    return dict(sha256=digest,routine=routine,capstone_version=capstone.__version__,rows=rows,incomplete=incomplete,
                complete_calls=len(rows),instructions=sum(r['instructions'] for r in rows),
                candidates=sum(len(r['candidates']) for r in rows),decoded_pcs=len(decoded),
                scope='Snapshot-decoded 68000 operand/stack reference candidates during complete traced calls to the selected routine, excluding IRQ stack. Same-PC code agrees between snapshots; transient self-modifying code is not proven absent. Not all scenarios, unselected services, DMA, cached CPUs or whole-gameplay purity. No cache bytes excluded.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--routine',choices=['world','services'],default='world');p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.capture,a.routine);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print({k:result[k] for k in ('complete_calls','instructions','candidates','decoded_pcs')})
