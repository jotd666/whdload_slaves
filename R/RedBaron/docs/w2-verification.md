# W2 geometry

The normal release enables its verified CPU-specific bundle by default. Its
player selector is On=0, Off=1; developer/VERIFY values below remain bit masks.
Only sim v1 receives performance patches. Current measurements and final release
checks live in [profiling.md](profiling.md), the single results record.
The full pre-condensation ledger is preserved at commit `dd9e8b4`.

## Retained implementation and evidence

Developer bits 2–5 select G1 projection, G2 trivial clipping, G3 32-bit vertex
cache misses and G4 low-long back-face products. G1 is excluded on 030/040/060
by the normal policy; the other verified paths remain available. Completion C3
also retains the face-loop bit 6 on 68000 only.

Independent projection, clipping, transform and dot models were checked against
original traces. Combined native twins passed across A500/020/cached-030 bank
and dense scenes. Edge checks cover signs, overflow, normalization and matrix
forms. Same-build performance pairs and hook audits are in the scoreboard.
The whole 3D-pass cost includes raster drawing; it is not a pure maths cost.

The remaining G1/G3 refinements and G5–G9 were deferred by the original cost
threshold. Completion C1/C2 were implemented, measured and dropped below the
later 2% threshold. No unimplemented refinement is represented as shipped.
Native reproduction driver: `tools/w2_combined_twins.py --machine 020 --scene bank`
from the development directory, using a fresh output location in that driver.

## Reproduce

From the repository root, using the shared environment:

```sh
source tmp/dev/amiga/env.sh
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_projection_model.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_clip_model.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_transform_model.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_dot_model.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_face_model.py'
VERIFY=1 bash tmp/dev/tools/build.sh
```

Native rechecks require the ignored development game installation, one owned
emulator, a fresh output directory and the corresponding VERIFY options below.
Use the shared machine definitions in `tools/completion_machines.py`; historical
A500 drivers that still select slow RAM must be updated to the approved minimum
before reuse. These commands are for intentional rechecks, not additional
release validation rounds.
