"""Tap a command and hold a control during native rendering; observe catch-up."""
import argparse,json,re
from d5_live import Live,r
from d5_report import input_window,catchup
p=argparse.ArgumentParser();p.add_argument('out');a=p.parse_args();live=Live(a.out)
def observe(label,fields=500):
    s=live.sim;state=live.state;bitmap=live.sym('time_keys_bitmap')
    cmd=['delete','set $f=0','set $pub=0','set $commands=0',f'break *{s+0x3154a:#x}','commands','silent','set $pub=$pub+1','continue','end',f'break *{s+0x11ca:#x}','commands','silent','set $commands=$commands+1','continue','end',f'break *{s+0x21d30:#x}','commands','silent',f'printf "INPUT %u %u %u %u %u\\n", $f, $pub, *(unsigned int*){state+28:#x}, *(unsigned int*){state+20:#x}, *(unsigned char*){bitmap+0x4e:#x}','continue','end',f'break *{s+0x21f4a:#x}','commands','silent','printf "FLIGHT_EXIT\\n"','end',f'break *{s+0x2d34e:#x}','commands','silent','set $f=$f+1',f'if $f < {fields}','continue','end','end','continue','printf "END %u %u\\n", $f, $commands','delete']
    raw=r.command('gdb '+'\n'.join(cmd));(live.out/(label+'.log')).write_text(raw)
    return input_window(raw,fields)
live.until(live.sim+0x2c552)
player_controls=live.u(live.h3+0x457c);before=live.w(player_controls+6)
live.irq(0x4e);live.irq(0x4a)
live.fields(2);live.irq(0x4a,True)
held=observe('catchup-held');after=live.w(player_controls+6)
live.irq(0x4e,True);released=observe('catchup-released',500)
pairs=catchup(held,released,before,after)
result=dict(passed=True,throttle_before=before,throttle_after=after,held_catchup_pairs=pairs,held=held,released=released,scope='Real keyboard IRQ tap/hold/release during native rendering; external observers only')
(live.out/'catchup.json').write_text(json.dumps(result,indent=2)+'\n')
print('CATCHUP PASS',before,after,pairs,flush=True)
