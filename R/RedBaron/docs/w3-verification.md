# W3 exact-output sound

The normal release enables its verified CPU-specific bundle by default. Its
player selector is On=0, Off=1; developer/VERIFY values below remain bit masks.
Only sim v1 receives performance patches. Current measurements and final release
checks live in [profiling.md](profiling.md), the single results record.
The full pre-condensation ledger is preserved at commit `dd9e8b4`.

## Retained implementation and evidence

Developer bits 10/11/12 select S1 queue access, S9 no-op call removal and S3
bounded volume division. The normal policy keeps original S3 on 030/040/060.
The loader handles both observed sound-driver loads; sound: offsets are relative
to the driver code entry convention documented in the hook tools.

Queue and exhaustive/live division twins passed on A500/020/cached-030.
Ordered Paula/control writes and per-channel fetch observations agreed in the
bounded cached-CPU windows. These support the local exact-output proofs, not
arbitrary wall-time-aligned audio equality after a frame-rate change.
Sample data, buffer sizes, service ownership and tick/envelope timing are unchanged.

S2/S3-prime/S4–S8 were deferred below the original cost threshold. The broader
B-series sound/OS behavior changes are not part of this release.
Saved native evidence includes `w3-div-twin-a500-r2`, `w3-div-twin-020` and
`w3-div-twin-030`. The live checker is `tools/w3_twin_check.py ENTRY --step 8`
from the development directory after a matching fresh VERIFY twin boot.

## Reproduce

From the repository root, using the shared environment:

```sh
source tmp/dev/amiga/env.sh
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_sound_model.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_sound_hooks.py'
VERIFY=1 bash tmp/dev/tools/build.sh
```

Native rechecks require the ignored development game installation, one owned
emulator, a fresh output directory and the corresponding VERIFY options below.
Use the shared machine definitions in `tools/completion_machines.py`; historical
A500 drivers that still select slow RAM must be updated to the approved minimum
before reuse. These commands are for intentional rechecks, not additional
release validation rounds.
