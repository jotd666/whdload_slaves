# W1 dashboard mirrors

The normal release enables its verified CPU-specific bundle by default. Its
player selector is On=0, Off=1; developer/VERIFY values below remain bit masks.
Only sim v1 receives performance patches. Current measurements and final release
checks live in [profiling.md](profiling.md), the single results record.
The full pre-condensation ledger is preserved at commit `dd9e8b4`.

## Retained implementation and evidence

Developer bits 0/1 select the exact table mirror and cached chip mirror.
The table hook is sim:304d0, with WaitBlit on entry; cached drawing hooks
sim:30412 and invalidates at sim:303c6. The cache has allocation fallback and
keeps DMA data in chip RAM. The normal policy retains original table mirroring
on 030/040/060 while retaining the separate mirror cache.

The table model, original/optimized twins and corrected bank/dense checks passed
on A500/020. Corrected cached-030 bank checks also passed. The fallback invalidation
bug was fixed before those captures. Disabled-range and bounded display checks
are recorded in the scoreboard; they are not an all-scenes tearing guarantee.
The dashboard is event-driven, not a per-frame 3D maths cost.

Evidence families: `w1-*` in the local capture collection; the corrected scene
build and its exact hashes are identified in the retained profiling history.
Do not treat unfinished cached-030 dense directories as completed evidence.

Further cached-030 dense/cache-only extension, return-flag write-up and additional
lifecycle refinements were deferred by the user to prioritize larger costs.
They are not required by the accepted release scope.

## Reproduce

From the repository root, using the shared environment:

```sh
source tmp/dev/amiga/env.sh
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_mirror*.py'
VERIFY=1 bash tmp/dev/tools/build.sh
```

Native rechecks require the ignored development game installation, one owned
emulator, a fresh output directory and the corresponding VERIFY options below.
Use the shared machine definitions in `tools/completion_machines.py`; historical
A500 drivers that still select slow RAM must be updated to the approved minimum
before reuse. These commands are for intentional rechecks, not additional
release validation rounds.
