"""Independent digital-joystick/button oracle for W6 post-poll captures."""
import struct


def direction(joy):
    return (((joy >> 8) ^ (joy >> 9)) & 1
            | ((joy ^ (joy >> 1)) & 1) << 1
            | ((joy >> 9) & 1) << 2 | ((joy >> 1) & 1) << 3)


def fixture_packet(elapsed):
    packet=bytearray(b'\0\0\0\0\0\0\xc0\0')
    if 2 <= elapsed < 20:packet[1]=3
    if 38 <= elapsed < 56:packet[6]=0x40
    if 74 <= elapsed < 92:packet[4]=0xff
    if 110 <= elapsed < 128:packet[5]=0xff
    return bytes(packet)


def check(queue, acquisition, counters, rows, epoch, axis_table, keyboard_counters):
    produced, consumed=struct.unpack('>II',counters)
    head,tail,overflow,high=struct.unpack_from('>4H',queue)
    if (produced,consumed,head,tail,overflow)!=(8,8,8,8,0) or not 1<=high<=8:
        raise ValueError('Missing/extra device input, overflow or unconsumed events')
    if struct.unpack('>II',keyboard_counters)!=(0,0):
        raise ValueError('Device packets leaked into keyboard events/commands')
    events=[]
    for i in range(8):
        wall,paused,active=struct.unpack_from('>III',acquisition,i*20)
        packet=acquisition[i*20+12:i*20+20]
        if active!=1 or packet!=fixture_packet((wall-epoch)&0xffffffff):
            raise ValueError('Unexpected physical-sample fixture or modal acquisition')
        eligible=(wall-paused+1)&0xffffffff
        expected=(eligible,0x200,int.from_bytes(packet[:2],'big'),int.from_bytes(packet[2:6],'big'),packet[6]<<24)
        if struct.unpack_from('>IHHII',queue,16+i*16)!=expected:
            raise ValueError('Device event differs from independently acquired packet/time')
        events.append((eligible,packet))
    at=0;packet=fixture_packet(0);seen=set()
    for tick,cursor,now,first,second,axis,flags,command in rows:
        while at<8 and ((cursor-events[at][0])&0xffffffff)<2**31:
            packet=events[at][1];at+=1
        if struct.pack('>II',first,second)!=packet:
            raise ValueError(f'Retroactive or missed packet at tick {tick}')
        joy=int.from_bytes(packet[:2],'big')
        fire=not(packet[6]&0x80) or bool(packet[4])
        secondary=bool(packet[5])
        if axis!=axis_table[direction(joy)] or bool(flags&(1<<29))!=fire or bool(flags&(1<<28))!=secondary or command:
            raise ValueError(f'Native input disagrees with the scheduled device state at tick {tick}')
        if joy:seen.add('direction')
        if not packet[6]&0x80:seen.add('joystick_fire')
        if packet[4]:seen.add('mouse_left')
        if packet[5]:seen.add('mouse_right')
    if at!=8 or seen!={'direction','joystick_fire','mouse_left','mouse_right'}:
        raise ValueError('Incomplete native device control coverage')
    return {'events':8,'rows':len(rows),'controls':sorted(seen),'acquisition_deadlines':True,'native_outputs':True}
