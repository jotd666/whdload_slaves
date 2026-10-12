"""Run one D5 flight soak in bounded debugger reads, without resetting the game."""
import argparse
import json
from pathlib import Path
import re
import sys

PAL_HZ = 49.92041


def check_segment(raw, anchor):
    """A command tail also runs after a fault: require the actual VBL stop."""
    if 'FLIGHT_EXIT' in raw or 'SOAK_SEGMENT_COMPLETE' not in raw:
        raise ValueError('Flight exited or the soak segment did not finish')
    stops = re.findall(r'^(?:Breakpoint \d+,\s+)?0x([0-9a-fA-F]+)\s+in\b', raw, re.M)
    if not stops or int(stops[-1], 16) != anchor:
        raise ValueError('Soak stopped somewhere other than the requested VBL')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=Path, help='Existing live D5 case with sim.json')
    parser.add_argument('--fields', type=int, default=90000)
    parser.add_argument('--chunk', type=int, default=10000,
                        help='Bound each response; the same flight continues between chunks')
    args = parser.parse_args()
    if args.fields <= 0 or not 0 < args.chunk <= 10000:
        parser.error('Use positive fields and a chunk of at most 10000 fields')
    harness = Path(__file__).resolve().parents[3] / 'tmp/dev'
    sys.path.insert(0, str(harness / 'tools'))
    import route_status as r
    sim = json.loads((args.capture / 'sim.json').read_text())['sim']
    if (args.capture / 'soak.json').exists():
        parser.error('Refusing to replace an existing soak result')
    r.command('stop')
    done = 0
    segments = []
    while done < args.fields:
        count = min(args.chunk, args.fields - done)
        commands = ['delete', f'break *{sim + 0x21f60:#x}', 'commands',
                    'silent', 'printf "FLIGHT_EXIT\\n"', 'end',
                    f'break *{sim + 0x2d34e:#x}', f'ignore $bpnum {count - 1}',
                    'continue', 'printf "SOAK_SEGMENT_COMPLETE\\n"', 'delete']
        raw = r.command('gdb ' + '\n'.join(commands))
        (args.capture / f'soak-{done:06d}.log').write_text(raw)
        check_segment(raw, sim + 0x2d34e)
        done += count
        segments.append(count)
        print(f'Soak: {done}/{args.fields} PAL fields', flush=True)
    (args.capture / 'soak.json').write_text(json.dumps(dict(
        fields=done, seconds=done / PAL_HZ, segments=segments,
        scope='Same live flight across bounded debugger reads; no guest reset or input'),
        indent=2) + '\n')


if __name__ == '__main__':
    main()
