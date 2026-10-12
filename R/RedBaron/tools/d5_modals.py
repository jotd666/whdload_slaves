"""Check native Pause and Preferences exclude modal time without losing debt."""
import argparse,json
from d5_report import modal
from d5_live import Live
p=argparse.ArgumentParser();p.add_argument('out');a=p.parse_args();live=Live(a.out)
results={}
for name,key,entry,exit_key,returned in [('pause',0x19,0x21ac4,0x44,0x21cec),('preferences',0x59,0x1fb3a,0x45,0x21c26)]:
    live.irq(key);live.until(live.sim+entry);live.irq(key,True)
    before=live.snapshot();assert before['active']==0,before
    live.fields(200);held=live.snapshot()
    assert held['steps']==before['steps'] and held['cursor']==before['cursor'],(before,held)
    live.irq(exit_key);live.until(live.sim+returned);live.irq(exit_key,True)
    after=live.snapshot()
    modal(before,held,after)
    results[name]=dict(before=before,held=held,after=after,passed=True)
    (live.out/'modals.json').write_text(json.dumps(results,indent=2)+'\n')
    print(name,'PASS',flush=True)
