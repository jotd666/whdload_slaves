"""Launch the D5 developer candidate for the user's A500/060 handling test."""
import argparse
import os
from pathlib import Path
import subprocess
import time
from completion_machines import environment


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('machine',choices=('a500','060'))
    parser.add_argument('--check',action='store_true',help='validate setup without building or launching')
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[3]/'tmp/dev'
    mask=0x33fff if args.machine=='a500' else 0x32ffa
    env=environment(args.machine,mask)
    env.update(VERIFY='0',DEVELOPER='1',DEBUG='0',WARP='0',SOUND='1',WINDOW='front',
               JOY0='none',JOY1='none',GAME=str(root/'tmp/game/RedBaron_v2.1/RedBaron'))
    # The untouched installed game's realism settings permit landing/crash tests.
    env['SLAVE']=str(root/'tmp/build/RedBaron-developer.slave')
    env.pop('BOOT_BREAK',None)
    if not (Path(env['GAME'])/'data/sim').is_file():
        parser.error('Install the RedBaron_v2.1 fixture using the project playbook first')
    if args.check:
        print(f'{args.machine}: quantum {450 if args.machine=="a500" else 225}, '
              f'CUSTOM2={mask}, real speed, sound on, original realism preferences')
        return
    pidfile=root/'amiga/.run/fsuae.pid'
    if pidfile.exists():
        status=subprocess.run(['ps','-p',pidfile.read_text().strip(),'-o','stat='],capture_output=True,text=True)
        if status.returncode==0 and not status.stdout.lstrip().startswith('Z'):
            parser.error('Close the existing Red Baron emulator before starting a play-test')
    subprocess.run(['bash','tools/build.sh'],cwd=root,env=env,check=True)
    subprocess.run(['bash','amiga/run.sh'],cwd=root,env=env,check=True)
    pid=int(pidfile.read_text())
    print('Red Baron is running. Close its window when finished.',flush=True)
    while True:
        status=subprocess.run(['ps','-p',str(pid),'-o','stat='],capture_output=True,text=True)
        if status.returncode or status.stdout.lstrip().startswith('Z'):break
        time.sleep(1)


if __name__=='__main__':main()
