"""Unfiltered equal-tick state inventory for W6 render-schedule experiments.

This is diagnostic evidence, not a whole-gameplay equality verdict. Full RAM
is retained by the capture; object prefixes do not describe every heap object.
"""
import argparse
import hashlib
import json
from pathlib import Path
from render_mutations import Snapshot, region, spans
from presentation_state import symbol
from pose_history import registry

def compare_states(l,r,h3):
 lp=int.from_bytes(l.read(h3+0x4578,4),'big');rp=int.from_bytes(r.read(h3+0x4578,4),'big')
 out=dict(h3=region(l.read(h3,0xbd0c),r.read(h3,0xbd0c)),player_pointer_equal=lp==rp,
          player=region(l.read(lp,0x118),r.read(rp,0x118)))
 lreg=registry(l.read,h3);rreg=registry(r.read,h3)
 out['registry_equal']=lreg==rreg
 out['object_prefix_differences']=[dict(index=j,pointer=p,changes=region(l.read(p,26),r.read(p,26))) for j,p in enumerate(lreg) if p in rreg and l.read(p,26)!=r.read(p,26)]
 out['registered_objects']=len(lreg)
 if [(b,len(d)) for b,d in l.banks] != [(b,len(d)) for b,d in r.banks]:
  raise ValueError('Different captured RAM maps')
 out['ram']=[]
 for (base,before),(_,after) in zip(l.banks,r.banks):
  changed=spans(before,after)
  out['ram'].append(dict(base=base,size=len(before),changed_bytes=sum(hi-lo for lo,hi in changed),
                         changed_ranges=changed,left_sha256=hashlib.sha256(before).hexdigest(),
                         right_sha256=hashlib.sha256(after).hexdigest()))
 return out

def load(root):
    entry=json.loads((root/'entry.json').read_text())
    poses=json.loads((root/'poses.json').read_text())
    initial=json.loads((root/'world-initial.json').read_text())
    lines=(root/'slave.lst').read_text(encoding='latin-1').splitlines()
    base=entry['entry']['game_anchor']-symbol(lines,'tape_game_anchor')
    return entry,poses,initial,base,lines


def same_tick(left,right,header):
    tick=int.from_bytes(left.read(header+4,4),'big')
    if tick != int.from_bytes(right.read(header+4,4),'big'):
        raise ValueError('Different completed world ticks')
    return tick


def inventory(left,right):
    le,lm,li,lb,ll=load(left)
    re,rm,ri,rb,rl=load(right)
    if not le['slave_sha256']==re['slave_sha256']==lm['sha256']==rm['sha256']==li['sha256']==ri['sha256']:
        raise ValueError('Different capture builds')
    if not lm['h3']==rm['h3']==li['h3']==ri['h3'] or lb!=rb:
        raise ValueError('Different allocation layout; pointers are not normalized')
    h3=lm['h3'];header=lb+symbol(ll,'time_pose_header');loop=lb+symbol(ll,'time_loop_state')
    initial=compare_states(Snapshot(left,li['banks']),Snapshot(right,ri['banks']),h3)
    if len(lm['frames'])!=len(rm['frames']) or not lm['frames']:
        raise ValueError('Missing or unequal boundary sequences')
    rows=[]
    for lf,rf in zip(lm['frames'],rm['frames']):
        l=Snapshot(left,lf['banks']);r=Snapshot(right,rf['banks'])
        tick=same_tick(l,r,header)
        if rows and tick!=rows[-1]['tick']+1:
            raise ValueError('Nonconsecutive completed world ticks')
        row=compare_states(l,r,h3)
        row.update(tick=tick,left_draws=int.from_bytes(l.read(loop+36,4),'big'),
                   right_draws=int.from_bytes(r.read(loop+36,4),'big'),
                   lifecycle_equal=lf['lifecycle']==rf['lifecycle'])
        rows.append(row)
    return dict(sha256=le['slave_sha256'],initial=initial,rows=rows,
                limitation='Diagnostic inventory only. No differing bytes excluded; object prefixes are not complete heap state. No whole-gameplay equality claim.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('left',type=Path);p.add_argument('right',type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=inventory(a.left,a.right)
    a.out.write_text(json.dumps(result,indent=2)+'\n')
    print('Initial h3/player changed bytes:',result['initial']['h3']['changed_bytes'],result['initial']['player']['changed_bytes'])
    for row in result['rows']:
        print('tick',row['tick'],'draws',row['left_draws'],row['right_draws'],
              'h3/player changes',row['h3']['changed_bytes'],row['player']['changed_bytes'],
              'changed object prefixes',len(row['object_prefix_differences']))
