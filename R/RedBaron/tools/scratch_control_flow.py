"""Prove local scratch-store dominance in sim:1e3a6; calls are opaque."""
import argparse
import hashlib
import json
from pathlib import Path
import capstone
from hunks import read_hunks
from lookup_context import contracts
from player_links import SIM_SHA

START=0x1e3a6
STORE=0x1e3ba
READ=0x1e4b2
END=0x1e4d0


def reachable(graph,start,omit=None):
    seen=set();todo=[start]
    while todo:
        pc=todo.pop()
        if pc==omit or pc in seen:continue
        if pc not in graph:raise ValueError('Control flow leaves decoded routine')
        seen.add(pc);todo.extend(graph[pc])
    return seen


def dominance(graph,start,store,read):
    live=reachable(graph,start)
    if store not in live or read not in live:raise ValueError('Store or read unreachable')
    if read in reachable(graph,start,store):raise ValueError('Scratch read can bypass assignment')
    return len(live)


def check(original):
    raw=original.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=SIM_SHA:raise ValueError('Unsupported sim')
    code=read_hunks(raw)[0].data
    for at,data in contracts(0).items():
        if code[at:at+len(data)]!=data:raise ValueError('Native context contract changed')
    cs=capstone.Cs(capstone.CS_ARCH_M68K,capstone.CS_MODE_M68K_000);cs.detail=True
    instructions=list(cs.disasm(code[START:END],START));graph={};calls=[];cursor=START
    for ins in instructions:
        if ins.address!=cursor or ins.mnemonic.startswith('dc.'):raise ValueError('Incomplete routine decode')
        pc=ins.address;cursor+=ins.size;name=ins.mnemonic.split('.')[0]
        if name=='rts':edges=[]
        elif name in ('jmp','rte','rtr','stop') or name.startswith('db'):
            raise ValueError('Unsupported local control transfer')
        elif name in ('bsr','jsr'):
            # A callee may re-enter or mutate the global. This proof deliberately
            # does not model that effect; report every opaque call for follow-up.
            edges=[cursor];calls.append(dict(pc=pc,instruction=ins.mnemonic+' '+ins.op_str))
        elif ins.operands and ins.operands[0].type==capstone.m68k.M68K_OP_BR_DISP:
            target=pc+2+ins.operands[0].br_disp.disp
            edges=[target] if name=='bra' else [target,cursor]
        else:edges=[cursor]
        graph[pc]=edges
    if cursor!=END or instructions[-1].mnemonic!='rts':raise ValueError('Unexpected routine extent/exit')
    if any(t not in graph for edges in graph.values() for t in edges):raise ValueError('Branch outside native routine')
    nodes=dominance(graph,START,STORE,READ)
    exits=[pc for pc,edges in graph.items() if not edges]
    if exits!=[0x1e4ce] or code[0x1e4cc:0x1e4d0]!=bytes.fromhex('4e5d4e75'):
        raise ValueError('Unexpected frame release/return')
    return dict(sim_sha256=SIM_SHA,routine_sha256=hashlib.sha256(code[START:END]).hexdigest(),
                capstone_version=capstone.__version__,start=START,end=END,store=STORE,read=READ,
                reachable_instructions=nodes,local_read_dominated=True,opaque_calls=calls,
                graph={hex(k):[hex(v) for v in values] for k,values in graph.items()},
                scope='Intraprocedural original sim control flow only: every local path to the conditional scratch read passes the frame-local assignment. Calls treated as returning fallthrough; no proof of callee/IRQ effects, reentrancy, indirect external entry, live read-path execution, target contents or whole-gameplay independence.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('original',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(a.original);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Local scratch assignment dominates read;',result['reachable_instructions'],'instructions,',len(result['opaque_calls']),'opaque calls')
