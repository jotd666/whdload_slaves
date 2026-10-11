"""Measure scheduled control deadlines to native world-input dispatch.

This separates world-tick quantization from scheduler lateness. It does not
measure physical input acquisition or the time until a displayed response.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
from keyboard_replay import check_capture
from sustained_capacity import check as capacity_check

MASK=0xffffffff


def distance(after,before):
    value=(after-before)&MASK
    if value>=1<<31:raise ValueError('Reversed or ambiguous input clock interval')
    return value


def latencies(rows,deadlines,origin):
    if not rows or len(deadlines)!=4:raise ValueError('Missing native input history')
    if rows[0][0]!=1:raise ValueError('Missing first world-input dispatch')
    previous=None
    for row in rows:
        if len(row)!=9:raise ValueError('Malformed native input row')
        tick,cursor,now,*_=row
        if previous is not None:
            if distance(tick,previous[0])!=1:raise ValueError('Nonconsecutive world-input rows')
            distance(cursor,previous[1]);distance(now,previous[2])
        distance(now,cursor);distance(cursor,origin);previous=row
    relative=[distance(d,origin) for d in deadlines]
    if relative!=[32,64,96,128]:raise ValueError('Unexpected scheduled fixture deadlines')
    if distance(rows[0][1],origin)>=relative[0]:raise ValueError('Missing input history before first deadline')
    result=[]
    for i,deadline in enumerate(deadlines):
        eligible=next((row for row in rows if distance(row[1],origin)>=relative[i]),None)
        if eligible is None:raise ValueError('Unreached scheduled event')
        tick,cursor,now,*_=eligible
        quantization=distance(cursor,deadline);lateness=distance(now,cursor)
        total=distance(now,deadline)
        if total!=quantization+lateness:raise ValueError('Inconsistent dispatch timing')
        result.append(dict(event=i,tick=tick,deadline=deadline,cursor=cursor,now=now,
                           world_quantization_cia_ticks=quantization,
                           scheduler_lateness_cia_ticks=lateness,
                           deadline_to_dispatch_cia_ticks=total))
    return result


def check(root):
    manifest=json.loads((root/'field-census.json').read_text())
    capacity=capacity_check(manifest)
    entry=json.loads((root/'entry.json').read_text())
    digest=hashlib.sha256((root/'slave.slave').read_bytes()).hexdigest()
    if entry['slave_sha256']!=manifest['sha256'] or digest!=manifest['sha256']:
        raise ValueError('Capture build mismatch')
    start=manifest['windows'][0]['before']
    if start['started'] or start['completed']:
        raise ValueError('Latency census must start before the first world update')
    read=lambda name:(root/(name+'.bin')).read_bytes()
    status,origin=struct.unpack('>HI',read('time_input_replay_done'))
    if status!=2:raise ValueError('Scheduled replay incomplete')
    records=read('time_input_replay_records');fixture=b'';deadlines=[]
    for i,(key,down) in enumerate(((0x4e,1),(0x4e,0),(0x40,1),(0x40,0))):
        deadline,k,d,x,y=struct.unpack_from('>IHHII',records,i*16)
        if (deadline,k,d,x,y)!=((origin+32*(i+1))&MASK,key,down,0,0):
            raise ValueError('Unexpected scheduled event')
        deadlines.append(deadline);fixture+=struct.pack('>IHH',(deadline-1)&MASK,key,down)
    rows=[]
    for i in range(len(manifest['windows'])):
        rows.extend(list(map(int,v.split())) for v in re.findall(r'^KEY ([0-9 -]+)$',(root/f'census-{i}.log').read_text(),re.M))
    h3=(root/'entry-h3.bin').read_bytes()
    replay=check_capture(read('time_input_observe_queue'),fixture,rows,0,
                         struct.unpack_from('>h',h3,0x1e30)[0],struct.unpack_from('>h',h3,0x1e40)[0],
                         read('time_keys_commands'),read('time_keys_consumed'))
    result=latencies(rows,deadlines,origin)
    return dict(sha256=entry['slave_sha256'],replay=replay,events=result,
                overall_capacity=capacity['overall'],
                scope='Scheduled deadline to native per-world input dispatch, in CIA ticks. Not physical acquisition, visible response, combat outcome or complete gameplay acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();r=check(a.capture);a.out.write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2))
