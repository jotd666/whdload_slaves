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
