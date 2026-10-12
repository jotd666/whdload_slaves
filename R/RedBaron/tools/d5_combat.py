"""Hold the real fire key; require native player hit, destruction and kill credit."""
import argparse,json
from d5_live import Live,r
from d5_report import combat_outcome
p=argparse.ArgumentParser();p.add_argument('out');a=p.parse_args();l=Live(a.out)
player=l.u(l.h3+0x4578);target_slot=l.sym('d5_scenario_target')
l.irq(0x40)
for _ in range(8):
    l.until(l.sim+0x21d30)
    if l.u(l.state+28)>=4:break
target=l.u(target_slot);pool=l.u(l.h3+0x5584);count=l.w(l.h3+0x5578)
assert target and 0<=target-pool<count*318 and (target-pool)%318==0,'No real aircraft target'
assert not l.u(target+34)&0x48,'Target already destroyed'
assert (l.u(target+34)^l.u(player+34))&0x400,'Target is not an enemy'
condition=f'*(unsigned int*)($a5-58)=={player:#x} && *(unsigned int*)($a5-4)==*(unsigned int*){target_slot:#x}'
cmd=['delete','set $f=0','set $hits=0',f'break *{l.sim+0x111ac:#x} if '+condition,'commands','silent','set $hits=$hits+1',f'printf "HIT %u %u %u %u\\n", $f, *(unsigned int*){l.state+28:#x}, *(unsigned int*)($a5-4), *(unsigned int*)(*(unsigned int*)($a5-4)+34)','continue','end',f'break *{l.sim+0xa042:#x} if $a3=={player:#x} && $a2=={target:#x}','commands','silent',f'printf "KILL %u %u %u %u %u\\n", $f, *(unsigned int*){l.state+28:#x}, $a3, $a2, *(unsigned int*)($a2+34)','end',f'break *{l.sim+0x21f60:#x}','commands','silent','printf "FLIGHT_EXIT\\n"','end',f'break *{l.sim+0x2d34e:#x}','commands','silent','set $f=$f+1','if $f < 2500','continue','end','end','continue','printf "COMBAT_STOP %u %u %u\\n", $pc, $f, $hits','delete']
raw=l.bounded_command('gdb '+'\n'.join(cmd));(l.out/'combat.log').write_text(raw)
l.irq(0x40,True)
result=combat_outcome(raw,player,target,l.sim+0xa042)
fixture=json.loads((l.out/'entry.json').read_text())
result.update(passed=True,track_target=fixture.get('track_target',False),personal_score=l.w(l.h3+0x4be8),scope=('Bounded firing-line tracking fixture; excludes AI evasion/ordinary combat acceptance. ' if fixture.get('track_target') else 'One-time initial target pose/velocity lineup. ')+'Native player-protection preference, fire IRQ, projectile damage, destruction and personal kill credit; enemy health and outcome unchanged')
(l.out/'combat.json').write_text(json.dumps(result,indent=2)+'\n')
l.fields(100);print(r.command('shot '+str((l.out/'combat.png').resolve())))
print('COMBAT PASS',flush=True)
