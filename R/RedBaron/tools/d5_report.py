"""Fail-closed checks for external D5 input and modal observations."""
import re


def input_window(raw, fields):
    ends=re.findall(r'^END (\d+) (\d+)$',raw,re.M)
    rows=[list(map(int,m)) for m in re.findall(r'^INPUT (\d+) (\d+) (\d+) (\d+) (\d+)$',raw,re.M)]
    if len(ends)!=1 or int(ends[0][0])!=fields or 'FLIGHT_EXIT' in raw or not rows:
        raise ValueError('Incomplete input window')
    if any(row[0]>fields or row[4] not in (0,1) for row in rows):
        raise ValueError('Invalid input observation')
    if any(b[0]<a[0] or b[1]<a[1] or b[2]!=a[2]+1 or b[3]<a[3] for a,b in zip(rows,rows[1:])):
        raise ValueError('Missing or unordered world observations')
    return dict(rows=rows,commands=int(ends[0][1]))


def catchup(held,released,before,after):
    if held['commands']!=1 or after!=max(0,before-20):
        raise ValueError('Throttle command missing or repeated')
    bits=[r[4] for r in held['rows']]
    if 1 not in bits or not all(bits[bits.index(1):]):
        raise ValueError('Hold missing on funded ticks')
    pairs=sum(b[1]==a[1] and a[4]==b[4]==1 for a,b in zip(held['rows'],held['rows'][1:]))
    if not pairs:raise ValueError('No held catch-up pair observed')
    bits=[r[4] for r in released['rows']]
    if released['commands'] or 0 not in bits or any(bits[bits.index(0):]):
        raise ValueError('Control did not release cleanly')
    return pairs


def modal(before,held,after):
    if before['active'] or held['active'] or after['active']!=1:
        raise ValueError('Wrong modal ownership')
    if any(s['steps']!=before['steps'] for s in (held,after)) or held['cursor']!=before['cursor']:
        raise ValueError('World advanced in modal')
    if after['cursor']-before['cursor']!=after['paused']-before['paused']:
        raise ValueError('Modal interval not excluded exactly')
    if after['due']!=before['due'] or after['quantum']!=before['quantum']:
        raise ValueError('Lost debt or changed quantum')


def mission_exit(before,held,exiting,backlog,F):
    if before['active'] or held['active']:
        raise ValueError('Mission menu did not release flight ownership')
    if backlog<=before['quantum']*F/1024+2:
        raise ValueError('No full world quantum of catch-up backlog')
    if held['cursor']!=before['cursor'] or any(s['steps']!=before['steps'] for s in (held,exiting)):
        raise ValueError('World advanced in the menu or after the exit command')


def compression_window(raw):
    ends=re.findall(r'^COMPRESS (\d+) (\d+)$',raw,re.M)
    if len(ends)!=1 or int(ends[0][0])!=200 or not int(ends[0][1]) or 'CANCELLED' in raw or 'FLIGHT_EXIT' in raw:
        raise ValueError('Incomplete or cancelled native compression window')
    return int(ends[0][1])


def ground_outcome(ground,scenario,native_return,before,after):
    contacts=ground['contacts']
    if ground['stop'] not in ('menu','flight_exit') or not contacts or any(c[1]<4 for c in contacts):
        raise ValueError('No W6-owned contact and native outcome stop')
    grades=[c[-1] for c in contacts]
    if scenario=='landing':
        if ground['stop']!='menu' or any(grades) or ground['altitude']!=50:raise ValueError('Unsafe or incomplete touchdown')
    elif scenario=='crash':
        if not any(g>0 for g in grades) or not ground['flags']&0x48:raise ValueError('No destructive impact')
    else:raise ValueError('Unknown ground scenario')
    if scenario=='crash' and ground['stop']=='flight_exit':return
    if native_return!=1 or before['steps']!=after['steps']:
        raise ValueError('Mission aborted or simulation continued after menu selection')


def combat_outcome(raw,player,target,kill_pc):
    kills=re.findall(r'^KILL (\d+) (\d+) (\d+) (\d+) (\d+)$',raw,re.M)
    stops=re.findall(r'^COMBAT_STOP (\d+) (\d+) (\d+)$',raw,re.M)
    hits=re.findall(r'^HIT (\d+) (\d+) (\d+) (\d+)$',raw,re.M)
    if len(kills)!=1 or len(stops)!=1 or not hits or 'FLIGHT_EXIT' in raw:
        raise ValueError('No completed native shoot-down')
    field,step,owner,victim,flags=map(int,kills[0])
    pc,stopfield,count=map(int,stops[0])
    if pc!=kill_pc or stopfield!=field or count!=len(hits) or owner!=player or victim!=target or not flags&0x48 or step<4:
        raise ValueError('Wrong native destruction or player credit')
    if any(int(h[2])!=target or int(h[1])<4 or int(h[0])>field for h in hits):
        raise ValueError('Invalid native hit sequence')
    return dict(field=field,step=step,hits=count,destruction_flags=flags&0x48)
