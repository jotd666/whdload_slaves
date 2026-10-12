"""Bounded artwork twins plus native keyboard view/firing transitions.

Run from tmp/dev after sourcing the shared environment. VERIFY-only flight route;
never use its elapsed time as a performance measurement. One owned emulator.
"""
import argparse
import json
import re
import socket
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path.cwd() / 'tools'))
from completion_machines import environment
import route_status as r

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('machine', choices=('030', '040', '060'))
p.add_argument('out', type=Path)
p.add_argument('--transitions', action='store_true')
a = p.parse_args()
if a.out.exists():
    raise SystemExit('Refusing overwrite')
pid = Path('amiga/.run/fsuae.pid')
if pid.exists():
    owned = subprocess.run(['ps', '-p', pid.read_text().strip(), '-o', 'stat=,command='], capture_output=True, text=True)
    if owned.returncode == 0 and not owned.stdout.lstrip().startswith('Z'):
        raise SystemExit('Inspect existing emulator first: ' + owned.stdout)
mask = 0xf0ffa if a.machine == '040' else 0xb0ffa
env = environment(a.machine, mask)
env.update(BOOT_TIMEOUT='240', GAME=str(Path('tmp/game/completion-benchmark/RedBaron').resolve()))
subprocess.run([sys.executable, '-B', 'tools/reach_flight.py', '--no-shot', '--out', str(a.out)], env=env, check=True)
symbols = {m[1]: int(m[2], 16) for line in (a.out / 'slave.lst').read_text(encoding='latin1').splitlines()
           if (m := re.match(r'^(\w+)\s+00:([0-9A-Fa-f]+)\s*$', line))}
entry = json.loads((a.out / 'entry.json').read_text())['entry']
base = entry['game_anchor'] - symbols['tape_game_anchor']
sim = entry['sim']


def advance(count):
    return r.command(f'gdb delete\nbreak *{entry["game_anchor"]:#x}\nignore $bpnum {count - 1}\ncontinue\ndelete')


def dump(name, size, label):
    address = base + symbols[name]
    path = a.out / (label + '-' + name + '.bin')
    r.command(f'gdb dump binary memory {path} {address:#x} {address + size:#x}')
    return path.read_bytes()


def twins(label):
    result = dump('artwork_cache_twin_result', 16, label)
    checked, active, scratch, passes = [int.from_bytes(result[i:i+4], 'big') for i in range(0, 16, 4)]
    assert (checked, active, scratch, passes) == (63, 0, 0, 6), result.hex()
    stats = dump('artwork_cache_stats', 12, label)
    print(label, 'six native twins passed', stats.hex(), flush=True)
    return dict(label=label, checks=6, hits=int.from_bytes(stats[:4], 'big'), fills=int.from_bytes(stats[4:8], 'big'))


advance(20)
rows = [twins('initial')]
if a.transitions:
    tracked = Path(__file__).resolve().parent
    with (a.out / 'input.log').open('w') as log:
        host = subprocess.Popen([sys.executable, '-B', str(tracked / 'completion_host_input.py'), '--serve', '--irq-only'], stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    (a.out / 'input-server.pid').write_text(str(host.pid))
    deadline = time.monotonic() + 1000
    while 'INPUT READY' not in (a.out / 'input.log').read_text():
        if host.poll() is not None or time.monotonic() > deadline:
            raise RuntimeError('Input controller did not attach; inspect owned session')
        time.sleep(1)

    def key(raw, up=False):
        with socket.socket(socket.AF_UNIX) as sock:
            sock.connect(str(Path('amiga/.run/completion-input.sock').resolve()))
            sock.sendall(f'irq-{"up" if up else "down"}:{sim},200588,{raw}'.encode())
            reply = sock.recv(65536).decode()
            assert reply.startswith('OK '), reply

    h3raw = r.command(f'gdb printf "H3 %u\\n", *(unsigned int*){base + symbols["artwork_cache_h3"]:#x}')
    h3 = int(re.search(r'H3 (\d+)', h3raw)[1])
    for label, raw, expected in [('rear', 0x51, 1), ('left', 0x52, 2), ('right', 0x53, 3), ('front', 0x50, 0)]:
        key(raw)
        advance(2)
        key(raw, True)
        advance(4)
        result = r.command(f'gdb printf "VIEW %u\\n", *(unsigned short*){h3 + 0x6712:#x}')
        assert int(re.search(r'VIEW (\d+)', result)[1]) == expected, result
        r.command('shot ' + str((a.out / (label + '.png')).resolve()))
        rows.append(dict(label=label, view=expected))
        print(label, 'view passed', flush=True)
    # Actual hardware fire key. Native firing programs remain outside the cache.
    key(0x40)
    fire = r.command(f'gdb delete\nset $firing=0\nbreak *{sim + 0x15f62:#x}\ncommands\nsilent\nset $firing=$firing+1\ncontinue\nend\nbreak *{entry["game_anchor"]:#x}\nignore $bpnum 5\ncontinue\nprintf "FIRING %u\\n", $firing\ndelete')
    (a.out / 'firing.log').write_text(fire)
    assert int(re.search(r'FIRING (\d+)', fire)[1]) > 0, fire
    r.command('shot ' + str((a.out / 'firing.png').resolve()))
    key(0x40, True)
    advance(4)
    rows.append(twins('after-views-fire'))
    subprocess.run([sys.executable, '-B', str(tracked / 'completion_host_input.py'), 'quit'], check=True)
    host.wait(timeout=20)
r.command('shot ' + str((a.out / 'final.png').resolve()))
(a.out / 'result.json').write_text(json.dumps(dict(passed=True, rows=rows), indent=2) + '\n')
r.command('quit')
print('ARTWORK VERIFICATION COMPLETE', a.out, flush=True)
