"""Native C-command compression entry/exit in the controlled transit scenario."""
import argparse,json
from d5_live import Live,r
from d5_report import compression_window
p=argparse.ArgumentParser();p.add_argument('out');a=p.parse_args();l=Live(a.out)
l.until(l.sim+0x21d30)
# Let native flight eligibility refresh after the one-time starting relocation.
l.fields(100)
assert l.w(l.h3+0x45a6)==0
l.irq(0x33);l.until(l.sim+0xf54);l.irq(0x33,True)
l.until(l.sim+0xf9c)
entry=l.snapshot();assert l.w(l.h3+0x45a6)==1,'Native eligibility rejected compression'
# Observe every native situation decision; auto cancellation must not be hidden.
cmd=['delete','set $f=0','set $on=0',f'break *{l.sim+0xf9c:#x}','commands','silent',f'if *(unsigned short*){l.h3+0x45a6:#x} == 1','set $on=$on+1','continue','end','printf "CANCELLED\\n"','end',f'break *{l.sim+0x21f60:#x}','commands','silent','printf "FLIGHT_EXIT\\n"','end',f'break *{l.sim+0x2d34e:#x}','commands','silent','set $f=$f+1','if $f < 200','continue','end','end','continue','printf "COMPRESS %u %u\\n", $f, $on','delete']
raw=l.bounded_command('gdb '+'\n'.join(cmd));(l.out/'compression.log').write_text(raw)
decisions=compression_window(raw)
held=l.snapshot();assert held['steps']>entry['steps'] and l.w(l.h3+0x45a6)==1
l.irq(0x33);l.until(l.sim+0xf54);l.irq(0x33,True);l.until(l.sim+0xf9c)
exit=l.snapshot();assert l.w(l.h3+0x45a6)==0
assert entry['quantum']==held['quantum']==exit['quantum']
l.fields(100);assert l.w(l.h3+0x45a6)==0
(l.out/'compression.json').write_text(json.dumps(dict(passed=True,entry=entry,held=held,exit=exit,compressed_decisions=decisions,scope='Real C IRQs and native eligibility after one-time non-player relocation; no flag, clock or eligibility injection; not a performance sample'),indent=2)+'\n')
print('COMPRESSION PASS',flush=True)
