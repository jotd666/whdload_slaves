"""Completion-plan machine matrix, shared by local flight/census drivers.

Timing 040/060 cores deliberately have no MMU: those emulator cores honour
CPU frequency. Functional mode uses the MMU cores and is not timing evidence.
"""
import os

MACHINES = ('a500', '020', '030', '030-nommu', '040', '060')


def environment(machine, mask=0, *, functional=False, environ=None):
    env = dict(os.environ if environ is None else environ)
    if machine not in MACHINES:
        raise ValueError(machine)
    flags = (' --uae_cpu_speed=real --uae_cpu_cycle_exact=true'
             ' --uae_cpu_memory_cycle_exact=true --uae_blitter_cycle_exact=true')
    env.update(MallocScribble='1', WHD_ARGS=f'CUSTOM2={mask} CUSTOM5=0',
               CHIP_KB='2048', FAST_KB='8192')
    if machine == 'a500':
        env.update(AMIGA_MODEL='A500', CPU='68000', CHIP_KB='512', FAST_KB='2048',
                   EXTRA_ARGS='--slow_memory=0 --uae_cpu_multiplier=2' + flags)
    elif machine == '020':
        env.update(AMIGA_MODEL='A1200', CPU='68EC020',
                   KICKSTART=env['KICKSTART_A1200'],
                   EXTRA_ARGS='--slow_memory=0 --uae_cpu_multiplier=4' + flags)
    else:
        cpu = '68030' if machine.startswith('030') else '68' + machine
        frequency = 25000000 if machine == '040' else 50000000
        aga = machine in ('040', '060')
        env.update(AMIGA_MODEL='A1200' if aga else 'A500',
                   CPU=cpu + ('-NOMMU' if aga and not functional else ''),
                   FAST_KB='0' if aga else '8192',
                   EXTRA_ARGS=f'--slow_memory=0 --uae_cpu_multiplier=0'
                   f' --uae_cpu_frequency={frequency} --uae_cpu_data_cache=true' + flags)
        if aga:
            env['KICKSTART'] = env['KICKSTART_A1200']
            # Zorro-II is limited to 8 MB; use a 32-bit bank for the 16 MB case.
            env['EXTRA_ARGS'] += ' --uae_z3mem_size=16 --uae_z3mem_start=0x10000000'
        if machine == '030' or (aga and functional):
            env['WHD_ARGS'] += ' MMU'
    return env
