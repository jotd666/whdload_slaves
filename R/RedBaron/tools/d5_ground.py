"""Observe native ground contacts and subsequent mission state; no guest writes."""
import argparse,json,re
from d5_live import Live,r
p=argparse.ArgumentParser();p.add_argument('out');a=p.parse_args();l=Live(a.out);player=l.u(l.h3+0x4578)
cmd=['delete','set $f=0']
cmd += [f'break *{l.sim+0x193a2:#x} if *(unsigned int*)($a5+16)=={player:#x}','commands','silent',f'printf "CONTACT %u %u %d %d %u\\n", $f, *(unsigned int*){l.state+28:#x}, *(int*){player+16:#x}, *(short*){player+254:#x}, *(unsigned char*){player+266:#x}','continue','end']
cmd += [f'break *{l.sim+0x1f0d2:#x}',f'break *{l.sim+0x21f60:#x}']
cmd += [f'break *{l.sim+0x2d34e:#x}','commands','silent','set $f=$f+1','if $f < 2000','continue','end','end','continue','printf "GROUND_STOP %u %u\\n", $pc, $f','delete']
raw=l.bounded_command('gdb '+'\n'.join(cmd));(l.out/'ground.log').write_text(raw)
match=re.search(r'GROUND_STOP (\d+) (\d+)',raw);assert match,raw[-1000:]
contacts=[list(map(int,m)) for m in re.findall(r'^CONTACT (\d+) (\d+) (-?\d+) (-?\d+) (\d+)$',raw,re.M)]
pc,fields=map(int,match.groups());assert pc in (l.sim+0x1f0d2,l.sim+0x21f60,l.sim+0x2d34e),raw[-1000:]
assert contacts,'No native player ground contact'
assert all(c[1]>=4 for c in contacts),'Contact preceded W6 fixture activation'
result=dict(contacts=contacts,fields=fields,stop='menu' if pc==l.sim+0x1f0d2 else 'flight_exit' if pc==l.sim+0x21f60 else 'window',state=l.snapshot(),altitude=l.u(player+16),flags=l.u(player+34),scope='Native collision/impact observations from controlled initial conditions; outcome verdict requires native mission-exit evidence')
(l.out/'ground.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='contacts'},indent=2),flush=True)
if result['stop']=='flight_exit':r.command('wait 12')
else:l.fields(30)
print(r.command('shot '+str((l.out/'ground.png').resolve())))
