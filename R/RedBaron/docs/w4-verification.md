# W4 solid rectangle fills

The normal release enables its verified CPU-specific bundle by default. Its
player selector is On=0, Off=1; developer/VERIFY values below remain bit masks.
Only sim v1 receives performance patches. Current measurements and final release
checks live in [profiling.md](profiling.md), the single results record.
The full pre-condensation ledger is preserved at commit `dd9e8b4`.

## Retained implementation and evidence

Developer bit 7 selects D1 at sim:2fd2c. When both edge masks are full, the
blitter can omit the destination read channel; masked edges retain the original
read/modify/write path. Clipping, plane order, pointers, pitch, BLTSIZE, wait and
BLTPRI policy are unchanged. This is still a blitter renderer, not C2P.

Independent fill models, three-CPU pixel twins and disabled-byte checks passed.
The completion E3 work also fixed VERIFY's pre-flight h3 pointer initialization;
the retained D1 path passed its native pixel comparisons afterward.
Its CPU rectangle and polygon replacements were separately measured and dropped;
the Fast RAM full-scene backend was also dropped. Their models remain, while
none of those rejected runtime implementations ships.

Overlay queueing was deferred below the original threshold. The later standalone
gauge cache is retained only on 020/040; complete cockpit composition was dropped.
See the E2/E3 scoreboard for measurements and scope.
The live checker is `tools/w4_twin_check.py ENTRY --step 8` from the development
directory after a matching VERIFY fill-twin boot.

## Reproduce

From the repository root, using the shared environment:

```sh
source tmp/dev/amiga/env.sh
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_fill_model.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_cpu_span_model.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_fast_blitter.py'
VERIFY=1 bash tmp/dev/tools/build.sh
```

Native rechecks require the ignored development game installation, one owned
emulator, a fresh output directory and the corresponding VERIFY options below.
Use the shared machine definitions in `tools/completion_machines.py`; historical
A500 drivers that still select slow RAM must be updated to the approved minimum
before reuse. These commands are for intentional rechecks, not additional
release validation rounds.
