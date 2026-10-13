"""Watch non-stack native scenery stores in one presentation rebuild.

Run from the configured harness after reach_flight.py --no-shot --out CAPTURE:
  python3 -B ../../R/RedBaron/tools/scenery_write_watch.py CAPTURE
Leaves the same emulator paused at the native scenery return. Guest memory is
never modified. Stack locals and IRQ-owned memory are not scenery outputs.
"""
import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path.cwd()/'tools'))
import route_status as r


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('capture', type=Path)
    a = p.parse_args()
    meta = json.loads((a.capture/'entry.json').read_text())
    entry = meta['entry']
    sim = entry['sim']
    listing = (a.capture/'slave.lst').read_text(encoding='latin1')
    def offset(name):
        return int(re.search(r'^'+name+r'\s+00:([0-9a-fA-F]+)', listing, re.M)[1], 16)
    base = entry['game_anchor']-offset('tape_game_anchor')
    sym = lambda name: base+offset(name)
    r.command('stop')
    raw = r.command('gdb '+ '\n'.join([
        'delete', f'break *{sym("time_model_bad"):#x}',
        f'break *{sim+0xf01c:#x} if *(short*){sym("time_present_active"):#x} != 0',
        'continue', 'delete', 'printf "ENTRY %x\\n", $pc',
        f'printf "H3 %x\\n", *(unsigned int*){sym("time_loop_h3"):#x}']))
    if f'ENTRY {sim+0xf01c:x}' not in raw:
        raise RuntimeError('Did not reach the presentation scenery entry: '+raw)
    h3 = int(re.search(r'H3 ([0-9a-f]+)', raw)[1], 16)
    commands = []
    def watch(pc, address, size):
        commands.extend([f'break *{pc:#x}', 'commands', 'silent',
                         f'printf "WRITE %x %u\\n", {address}, {size}', 'continue', 'end'])
    for pc, off in [(0xf060,0x54ea), (0xf074,0x5270), (0xf090,0x54ea),
                    (0xf0a8,0x527e), (0xf0be,0x54d8), (0xf370,0x54d8)]:
        watch(sim+pc, str(h3+off), 2)
    for pc in [0xf08a,0xf08c,0xf08e]:
        watch(sim+pc, '$a6', 4)
    for pc in [0xf0b4,0xf0b6,0xf0b8,0xf382,0xf384]:
        watch(sim+pc, '$a0', 4)
    watch(sim+0xf386, '$a0', 2)
    for pc in [0xf33a,0xf5ba]:
        watch(sim+pc, '$a2+$d0', 4)
    watch(sim+0xf5e6, '$a0', 1)
    # The W6 wrappers journal the three displaced visibility/model stores.
    watch(sym('time_model_record'), '$a0', '$d0')
    commands += [f'break *{sym("time_scenery_return"):#x}', 'continue', 'delete',
                 'printf "RETURN %x\\n", $pc']
    raw = r.command('gdb '+'\n'.join(commands))
    (a.capture/'write-watch.log').write_text(raw)
    if f'RETURN {sym("time_scenery_return"):x}' not in raw:
        raise RuntimeError('Native scenery return not reached')
    writes = [(int(addr,16),int(size)) for addr,size in re.findall(r'WRITE ([0-9a-f]+) (\d+)',raw)]
    if not any(h3+0x5280 <= addr < h3+0x54d8 for addr,size in writes):
        raise RuntimeError('No compact scenery rebuild observed')
    (a.capture/'write-watch.json').write_text(json.dumps(dict(h3=h3,writes=writes),indent=2)+'\n')
    print(f'{len(writes)} non-stack scenery writes; paused at return')


if __name__ == '__main__':
    main()
