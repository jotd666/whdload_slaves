# W5 display pacing and player policy

The normal release enables its verified CPU-specific bundle by default. Its
player selector is On=0, Off=1; developer/VERIFY values below remain bit masks.
Only sim v1 receives performance patches. Current measurements and final release
checks live in [profiling.md](profiling.md), the single results record.
The full pre-condensation ledger is preserved at commit `dd9e8b4`.

## Retained implementation and evidence

Bit 8 changes the flight swap argument at sim:00b06 to select the native beam
wait. Bit 9 wraps the flight calls at sim:00b08 and observes native VBlank at
sim:2d34e. The original publication at sim:3154a, blitter wait and copper data
remain in place. Non-flight callers are unchanged.

The normal bundle uses a two-field minimum between actual publications. First
publication has no predecessor; slow drawing does not accumulate cap debt.
Developer W6 bit 13 forces bits 8/9 and changes the minimum to one field.
The normal build does not enable W6, so it does not promise independent world
speed or 50 FPS. NTSC pacing has not been measured.

The independent modular-clock model and native compiled wrap/fast-draw fixture
passed. The fixture deliberately omits drawing, and cannot establish game FPS,
interpolation or pixel correctness. Bounded display checks and the real E4
per-field deadline failure are recorded in the scoreboard. The user accepted
measured performance on 2026-10-12; no missed deadline was relabelled a pass.

The verified mask is `0x71fff`, filtered by CPU in `perf.s`; D5 bit 13 is absent.
The normal splash list is “Faster rendering: On, Off”, with zero meaning On.
To disable the player bundle use CUSTOM2=1. Developer/VERIFY CUSTOM2=0 still
means all performance bits off. Icons remain unchanged, WHDLoad 17+ is required,
and normal/developer binaries contain no VERIFY fixtures or scripted input.

For a fresh native stress fixture from the development directory:
`python3 tools/w5_boot.py 030 768 tmp/prof/w5-recheck --stress`.
Use `publication_cadence.py` on a continuous saved field-census manifest; its
passed verdict requires every deadline, including both observation edges.

## Reproduce

From the repository root, using the shared environment:

```sh
source tmp/dev/amiga/env.sh
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_pacing_model.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_publication_cadence.py'
VERIFY=1 bash tmp/dev/tools/build.sh
```

Native rechecks require the ignored development game installation, one owned
emulator, a fresh output directory and the corresponding VERIFY options below.
Use the shared machine definitions in `tools/completion_machines.py`; historical
A500 drivers that still select slow RAM must be updated to the approved minimum
before reuse. These commands are for intentional rechecks, not additional
release validation rounds.
