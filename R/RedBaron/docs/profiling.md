# Red Baron: 250-field flight profile

Captured 2026-10-09. Source baseline: `1904205` (`redbaron`).

## Findings

The strongest optimization candidate in this short maximum-detail flight is the bitmap
horizontal-mirroring routine at **`sim:$304d0`**: it accounts for **30.96%** of all recorded
CPU cycles. Its repeated single-bit reversal alone takes **23.98%**. Geometry processing is
another substantial cost; sound is also measurable. Blitter busy polling costs **6.49%**,
so this sample does not support treating blitter waits as the principal bottleneck.

These are observations from five seconds of early combat, not a steady-state average of
the entire game. The aircraft is hit before the last screenshot. Six bitmap-mirroring
calls occur in the first 161 fields, with none in the remaining 89 fields. Their cost is
real, but their frequency is scene dependent. No optimization has been implemented yet.

## Capture conditions and evidence

| Item | Value |
| --- | --- |
| Duration | 250 PAL fields, approximately 5 seconds |
| Captures | Consecutive 100 + 100 + 50 fields; maximum 100 per profiler command |
| CPU | 68000, real CPU speed, CPU/memory/blitter cycle-exact settings enabled |
| Memory | 1 MB chip + 2 MB fast; **not** an A500-equivalent memory baseline |
| Boot | Kickstart 3.1 host, KickEmu 1.3 guest, WHDLoad 20.0 |
| Game | `RedBaron_v2.1.lha`, supported v1 `sim` executable |
| Slave | VERIFY build of the fork source |
| Detail | World maximum, Aircraft maximum, Ground Detail ON IN COMBAT |
| Time Scale | Original archive setting, unchanged |
| Input | Native keyboard tape; host joystick ports disabled |
| Audio | Game sound ON; host audio output uses the dummy driver |
| Starting point | Flight-only checkpoint at gameplay step 1, followed by one screenshot field |
| Ending point | Gameplay step 6; still in flight |

The route skips the scrolling credits, selects the ace mission (Ernst Udet in this fixture),
answers No to the pre-flight mission-tape question, applies the preferences and presses
ACCEPT. The optional banking fixture starts at gameplay step 20; this five-second capture
never reaches it. The profile therefore contains no injected banking input.

The local evidence is under `tmp/dev/tmp/prof/baseline/`, relative to the Red Baron worktree:

- `trace.bin`: fields 0–99; `trace-100-199.bin`: fields 100–199;
  `trace-200-249.bin`: fields 200–249. Together approximately 1.20 GiB.
- `slave.slave`, `entry.json`, `after.json`, `emulator.uae`, `manifest.json`.
- `fast-before.bin` and `fast-after.bin`: the same process's fast RAM at `$200000–$400000`.
- `report-250.txt`: self/inclusive routine costs, contexts, instructions and call edges.
- `metrics.json`: exact-PC counters, waits, DMA shares and display-update events.
- `field-000.png`, `field-099.png`, `field-100.png`, `field-199.png`,
  `field-200.png`, `field-249.png`: screenshots extracted from the captures without
  advancing the emulator. `first.png` is the separate pre-capture screenshot.

The earlier `report.txt` covers only the first 100 fields; use **`report-250.txt`**.
Raw traces, binaries, RAM dumps and screenshots remain ignored local artifacts.

Input/build SHA-256:

| Input | SHA-256 |
| --- | --- |
| Preinstalled archive | `ec6d74e3576bf040269f1c078a9df766a8f6e6dd94c2eb29eb5d34307b87ffe4` |
| Original `sim` | `e9b3889bc6f177e0bcfc74987665cdafbccd984b3a031bdd1f98f6c445dd8839` |
| Retained VERIFY slave | `ade543bd07d9bdc7dc620033a1e11bf7c667495a5972658bb7c7358b5914bfc5` |

## Validation and attribution

The parser reads **3,154,859 records** and **35,525,488 CPU cycles**, against the PAL-field
budget of 35,525,500 cycles: a difference of 12 cycles over all 250 fields. PCs are present;
there are no STOP/idle records. Individual fields have small accounting differences from
instruction costs crossing field boundaries; whole-window totals are the useful comparison.
No resume or screenshot command was issued between the three capture chunks.

Live code is identified from the VERIFY marker and the LoadSeg BPTR chain, rather than a
cached copy of a preloaded executable. KickEmu and the sound driver are identified by
byte matching, and the slave by its retained build and live marker. In this boot:

| Region | Address range, end exclusive | Share of total CPU cycles |
| --- | --- | ---: |
| `sim` code | `$3818b0–$3bfc34` | 88.70% |
| `amigasnd.drv` | `$3d7a48–$3d9990` | 8.95% |
| KickEmu ROM copy | `$334000–$374000` | 1.90% |
| WHDLoad slave | `$3fcd60–$3fe6ac` | 0.24% |
| Unmapped instructions | — | 0.04% |
| Interrupt-entry accounting | profiler marker | approximately 0.16% |

`sim` hunk 1 is at `$10660`, hunk 2 at `$10a28`, and hunk 3 at `$3bfc40`.
Offsets below are relative to the **live code hunk**, not file offsets or absolute
addresses. The file-backed code starts at file offset `$2c`.

Self attribution uses observed call targets and `LINK A5` prologues. Inclusive attribution
reconstructs stacks from calls and stack pointers, separating the main and interrupt stacks.
It can be incomplete at capture boundaries or across unconventional control transfers;
inclusive percentages overlap and must not be added. Exact-PC totals corroborate the
largest hotspot independently of inferred function boundaries.

The main stack accounts for 84.9% of cycles and the other observed execution context for
15.0%, excluding interrupt-entry accounting. There are 1,171 IRQ-entry records, 250 calls
to the mouse/VBlank callback at `sim:$2d344`, and 296 timer-callback entries at `sim:$2ffcc`.
Those callback counts are not rendered-frame counts.

## Hot routines

Percentages use the entire 250-field CPU cycle budget, including interrupts and waits.
Calls mean entries reconstructed in this capture, not lifetime counts.

| Routine | Self | Inclusive | Calls | Interpretation |
| --- | ---: | ---: | ---: | --- |
| `sim:$304d0` | **30.96%** | 30.96% | 6 | Horizontal bitmap reflection and mask accumulation |
| `sim:$38c82` | 5.56% | 5.56% | 1,347 | Signed normalization and scaled arithmetic used by geometry |
| `sim:$3afbe` | 3.90% | 3.90% | 1,446 | Coordinate transformation, including multiply/shift paths |
| `sim:$3b41a` | 3.61% | 28.13% | 606 | Geometry-processing caller; substantial work is in its callees |
| `sim:$38dcc` | 2.51% | 6.41% | 2,153 | Geometry helper calling the transformation routine |
| `sound:$1b1e` | 2.43% | — | 325 | Sound-driver routine; exact role not yet named |
| `sim:$2ea28` | 2.17% | — | 388 | Drawing code; semantic label still provisional |
| `sim:$2fc68` | 2.15% | — | 71 | Clipped blitter rectangle setup and polling |
| `sim:$30572` | 2.12% | 2.11% | 94 | Bitmap blitter setup, clipping and waits |
| `sound:$0c10` | 1.99% | — | 702 | Sound-driver routine |
| `sound:$1984` | 1.93% | — | 326 | Sound-driver routine |

Small self/inclusive discrepancies such as `$30572` reflect the different attribution
methods, not negative callee work. The exact-PC report is authoritative when boundaries matter.
The rendering/geometry chain `sim:$2c552 → $39b42 → $3a902 → $3b41a` accounts for
38.86%, 32.41%, 31.73% and 28.13% inclusive respectively. These are nested costs.

### Bitmap reflection: first optimization candidate

`sim:$30408` tests the orientation flags in the bitmap descriptor. When the horizontal
orientation differs, it calls `$304d0`, then toggles the corresponding descriptor flag.
The routine:

1. Clears the auxiliary mask area.
2. Walks the bitmap planes and rows.
3. Reads each 16-bit word and reverses its bits using **16 `LSR`/`ROXL` pairs**.
4. Pushes reversed words onto the stack, then pops them back in reverse word order.
5. Writes the mirrored image in place and ORs the pixels into the mask.

The exact range `$304d0–$30570` costs **10,999,770 cycles**. The 32 shift/rotate
instructions at `$3050e–$3054c` alone cost **8,518,472 cycles**, or **23.98% of the total**.
All six observed entries use descriptor `$32e84`. In the pre-capture snapshot it describes
a 168×102 bitmap, source `$3a0b0`, mask `$3cc84`; the global plane count is five.
Descriptor fields may change during execution, so these dimensions describe the snapshot.
Calls start in fields **2, 18, 86, 100, 145 and 160**.

A byte-reversal lookup table or a faster verified word-reversal sequence is a focused
candidate. Preserve word order, in-place semantics, mask accumulation, registers and
flags expected by callers. A broader option is to cache both orientations, but that needs
more memory and proof that the underlying image is not modified between uses.

For scale only: halving the whole routine's cost would give an idealized **1.18×** speedup
for this sample; removing it entirely would cap that model at **1.45×**. Neither is a
prediction or measured improvement. The final 89 fields have no calls to this routine.

### Geometry and sound

The next investigation should separate repeated transformations from required per-frame
work. `$3afbe` has both shift-only and multiply-based coordinate paths; `$38c82` repeatedly
normalizes signed values. Check actual ranges, overflow and rounding before replacing
arithmetic. Changes here can alter geometry even when the result looks similar.

The sound binary itself costs 8.95%, with additional sound sequencing in `sim`, notably
`$34d96`, `$34e56` and `$34d26`. Dummy host audio does not disable emulated sound work.
The two execution contexts and timer callbacks make audio worth investigating after the
bitmap hotspot, but this profile does not establish which sound operations can be removed.

## Blitter, DMA and display updates

Confirmed DMACONR bit-6 tests cost **5.42%** and their immediately associated backward
branches cost **1.07%**, for **6.49%** in those polling sequences. This includes their
instruction/bus cost, not exclusively time when the blitter is busy. Recognition checks
the effective custom-register address rather than counting every `BTST` instruction.
Hot examples are `$30798/$3079e` and `$2fd7a`. No execution was recorded in the
beam-position waiting loop at `$31522–$31548`.

DMA shares use the existing Barto 58-byte record decoder (type byte at offset 29), also
used by the other project tools. The total is 17,762,750 slots: 250 × 313 × 227.

| Recorded slot type | Share |
| --- | ---: |
| Free | 63.075% |
| Bitplane | 28.149% |
| Blitter | 4.468% |
| CPU chip-bus access | 2.014% |
| Refresh | 1.762% |
| Audio | 0.410% |
| Copper | 0.100% |
| Sprite | 0.023% |

These are chip-bus slot shares, not CPU utilization. Fast-RAM CPU work does not require
those chip-bus slots. The free share is therefore compatible with a CPU-bound routine.

A display-update candidate is now identified: `$314c0` exchanges framebuffer pointers,
and `$3154a` writes the six bitplane pointer pairs into the active copper list at `$10a70`.
Five such writes occur in fields **60, 118, 178, 204 and 233**, alternating between the
two buffers (the recorded post-construction pointer values alternate `$1c738/$263c8`).
Each is followed by a flight-step checkpoint in the same field.

The four complete intervals are **58, 60, 26 and 29 fields**: approximately **1.16 display
updates/second** between the first and last observed updates. Counting the five writes
against the whole window gives 1.0/second but includes incomplete boundary intervals.
This is a useful provisional display-update rate, not a fully calibrated FPS claim:
confirm it against copper/bitplane presentation or a separate swap-only run before
using it as an optimization acceptance metric. The input-step marker alone is insufficient.

## Repeat the profiling run manually

The following commands use this machine's **ignored local harness** in `tmp/dev`, its
installed FS-UAE/Barto debugger, shared Amiga SDK/tools and pristine game archive. Those
inputs are not shipped by this Git commit. Recreate the harness using the local
`~/.local/share/amiga/new-game-playbook-jotd.md` when using another checkout or machine.

The convenience command builds the VERIFY slave, starts a fresh game, sets maximum
detail, takes the three consecutive captures, writes RAM dumps and generates both reports:

```sh
cd "$HOME/Projects/Red Baron"
python3 tmp/dev/tools/profile_flight.py
```

It creates a timestamped directory below `tmp/dev/tmp/prof/`. To choose a destination:

```sh
python3 tmp/dev/tools/profile_flight.py --out tmp/prof/manual-profile
```

The destination must not already exist and must have no spaces below `tmp/dev`.
Paths passed to `--out` are relative to `tmp/dev`, regardless of your shell's directory.
The wrapper leaves the emulator paused. It implements the individually exercised commands
below; its complete fresh-boot wrapper path has not been separately rerun after packaging.

For direct control, use a fresh, unused `manual` directory:

```sh
cd "$HOME/Projects/Red Baron/tmp/dev"
python3 tools/reach_flight.py --out tmp/prof/manual
python3 tools/redbaron.py gdb dump binary memory tmp/prof/manual/fast-before.bin 0x200000 0x400000
python3 tools/redbaron.py profile 100 "$PWD/tmp/prof/manual/trace.bin"
python3 tools/redbaron.py profile 100 "$PWD/tmp/prof/manual/trace-100-199.bin"
python3 tools/redbaron.py profile 50 "$PWD/tmp/prof/manual/trace-200-249.bin"
python3 tools/redbaron.py gdb dump binary memory tmp/prof/manual/fast-after.bin 0x200000 0x400000
SLAVE="$PWD/tmp/prof/manual/slave.slave" python3 tools/redbaron_report.py \
  tmp/prof/manual/trace.bin tmp/prof/manual/fast-before.bin \
  --more-traces tmp/prof/manual/trace-100-199.bin tmp/prof/manual/trace-200-249.bin \
  --top 25 > tmp/prof/manual/report-250.txt
python3 tools/profile_metrics.py tmp/prof/manual > tmp/prof/manual/metrics.log
```

Do not issue `cont`, `wait` or `shot` between capture chunks. `shot` advances one field.
The native debugger's first attachment can take minutes even though the emulated window
is only five seconds. Allow approximately 1.3 GB for raw evidence plus analysis memory.
The profile command fixes this installed emulator's PC-filter window through LLDB;
that fix is binary-specific and must be rechecked when replacing FS-UAE.

```sh
python3 tools/redbaron.py cont   # resume; this fixture uses warp mode
python3 tools/redbaron.py quit   # close this harness's emulator/debugger
```

The normal interactive launcher remains `tmp/dev/amiga/run.sh` with the normal built slave.
VERIFY hooks and their scripted input are excluded from that normal build.

## Next work and limits

1. Implement and compare a narrowly scoped bitmap-bit-reversal improvement, with exhaustive
   16-bit input equivalence and image/mask comparisons, then an identical 250-field capture.
2. Validate `$3154a` as the display metric and cross-boot state reproducibility before
   treating timing differences as an A/B benchmark.
3. Profile another representative scene to determine how often bitmap reflection occurs.
4. Investigate geometry arithmetic and audio with their own correctness checks.

No 68020 comparison, long mission sample, all-version validation or complete game-time
model is claimed. The profiler measures the instrumented VERIFY build; its source hooks
and the single pre-capture screenshot must remain consistent for future comparisons.
The original archive remains pristine, and no game data or generated binary is committed.
