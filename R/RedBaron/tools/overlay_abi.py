"""Verify native overlay epilogue and retain its caller-visible register contract."""
import argparse
import json
from pathlib import Path
from cockpit_poststate import check as check_poststate
from render_mutations import Snapshot
from presentation_state import symbol

SAVED=('d2','d3','d5','d6','d7','a2','a3','a6')
REGISTERS=tuple(f'd{i}' for i in range(8))+tuple(f'a{i}' for i in range(7))+('sp','pc','ps')


def registers(record):
    values=dict(record['values'])
    if 'ps' not in values and 'sr' in values:values['ps']=values.pop('sr')
    if set(values)!=set(REGISTERS):raise ValueError('Incomplete register observation')
    return values


def epilogue(read,values):
    """MOVEM.L (SP)+,D2-D3/D5-D7/A2-A3/A6; UNLK A5; RTS."""
    out=dict(values)
    def long(at):
        data=read(at,4)
        if len(data)!=4:raise ValueError('Truncated native stack')
        return int.from_bytes(data,'big')
    for i,name in enumerate(SAVED):out[name]=long(values['sp']+4*i)
    frame=values['a5']
    if values['sp']+32!=frame-36:raise ValueError('Unexpected native frame layout')
    out['a5']=long(frame);out['pc']=long(frame+4);out['sp']=frame+8
    return out


def check(path):
    poststate=check_poststate(path)
    root=path.parent;metadata=json.loads(path.read_text());rows=[]
    entry=json.loads((root/'entry.json').read_text())
    lines=(root/'slave.lst').read_text(encoding='latin-1').splitlines()
    base=entry['entry']['game_anchor']-symbol(lines,'tape_game_anchor')
    for frame in metadata['frames']:
        before=registers(frame['before']['registers'])
        after=registers(frame['after']['registers'])
        returned=registers(frame['returned'])
        for label,values in (('before',before),('after',after)):
            if values['pc']!=base+symbol(lines,'overlay_probe_'+label) or values['sp']!=frame[label]['sp']:
                raise ValueError('Register observation is not at native probe boundary')
        if after['a5']!=before['sp']-4:raise ValueError('Native frame does not belong to entry')
        memory=Snapshot(root,frame['after']['banks'])
        wanted=epilogue(memory.read,after)
        if wanted!=returned:
            raise ValueError('Native return differs: '+','.join(n for n in REGISTERS if wanted[n]!=returned[n]))
        for name in SAVED+('a5',):
            if returned[name]!=before[name]:raise ValueError('Native callee-save changed: '+name)
        if returned['sp']!=before['sp']+4:raise ValueError('Native return stack differs')
        if returned['d0']&65535!=1 or returned['ps']&15:
            raise ValueError('Unexpected interpreter success word/flags')
        rows.append(dict(index=frame['index'],program=frame['before']['program'],
                         changed_registers=[n for n in REGISTERS if before[n]!=returned[n]],
                         returned=returned))
    return dict(sha256=poststate['sha256'],frames=rows,
                scope='Observed native return contract only; no cached replacement, complete dependency key, hardware-state or performance claim.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();result=check(a.capture);a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Native overlay return matches',len(result['frames']),'calls')
