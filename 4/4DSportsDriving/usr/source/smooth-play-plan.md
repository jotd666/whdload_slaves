# 4D Sports Driving: smooth play on every Amiga — execution plan

Written 2026-10-11 on HEAD `c70ea93` (branch `4dsportsdriving`). This plan supersedes the
"next steps" sections of optimization-plan.md, simulation-plan.md and open-work.md. Those
documents remain reference material for addresses and evidence, not a to-do list.
This tracked file is authoritative. Relative paths such as `tools/`, `docs/` and `tmp/prof/`
refer to the ignored development harness at `tmp/dev` in the worktree.

Goal: the game always runs at correct game speed on every machine, and draws as many frames
as the machine allows, up to 50 FPS. Targets run from the A500 (68000, chip + slow RAM) to an
AGA 68040/68060 with fast RAM.

---------------------------------------------------------------------------------------------

## 1. What the measurements say (fresh baseline, same HEAD)

Moving race, held throttle, 10 s windows timed from the game's CIA clock. Evidence is in
`tmp/prof/baseline-2026-10-11/<cell>/window.json`, collected with
`tmp/baseline-tools/run_cell.sh` and `measure_window.py`.

| Machine | Sim | Detail | C2=0 FPS | C2=1 FPS | Sim steps/s |
|---|---|---|---:|---:|---:|
| A500 (512K chip + 1.5M slow) | Normal | FULL | 2.70 | 2.90 | 8.4 (should be 10) |
| A500 | Normal | FAST | 7.50 | 7.60 | 8.3 (capped by sim) |
| A1200 020/14, 4M fast | A2500 | FULL | 8.10 | 9.30 | 19.8 |
| A1200 | A2500 | FAST | – | 15.40 | 19.8 |
| 040/25 NOMMU, fast | A2500 | FULL | 18.10 | 18.50 | 19.8 (capped by sim) |
| 060/50 NOMMU, fast | A2500 | FULL / FAST | – | 18.5 / 19.8 | 19.8 (capped by sim) |
| 040/25, A4000 50 Hz build | 50 Hz | FULL | – | 17.90 | 50.2, no backlog |
| 060/50, A4000 50 Hz build | 50 Hz | FULL | – | 17.50 | 50.2, no backlog |

020 FULL instruction profile (`prof-020-a25-full-c1`): 1.34 M cycles per frame.

| Item | Share |
|---|---:|
| Primitive drawing `$0AB82` (polygon tree 28.7%, `$2C6CC` self 15.1%; lines 5.0%) | 35.4% |
| Object geometry `$00F00` (already W2–W6 optimised) | 30.2% |
| `$21224`→`$21026` once per frame (clear, sky and horizon blits through `$3470E`/`$321DA`) | 9.0% |
| `$0818E` once per frame (dashboard or cockpit; `$32176`/`$336EC`) | 7.3% |
| Simulation, 38.5k cycles per step, solo | 5.2% |
| **Blitter busy-wait loops, overlapping the rows above** | **30.1%** |

Chip-bus slots on the 020 are 50.9% free, so the waits are latency from many small serial
blits, not bandwidth. Simulation costs about 77k cycles per step on a 68000 and 38.5k on a
020 (solo, no opponent).

Conclusions. Each one drives a phase below.

1. **The clock is wrong on the A500.** The sound code programs the shared CIA-B latch to
   12×716, so Normal runs at 8.3 steps/s and game time is 17% slow. A clock independent of the
   timer fixes this. P1 measurements show that correcting the clock alone does not
   lift A500 FAST to 10 FPS; that rendering target is deferred by user decision.
2. **The native loop never renders faster than the simulation.** It waits at `$7118` for a new
   step, so 20 FPS is the ceiling on every fast machine in A2500.
3. **Rendering stops at about 18 FPS on 040/25 and 060/50**, even with 50 Hz physics and a 2×
   faster CPU. The limit is the blitter and chip RAM. This matches Test Drive II and I500,
   which both plateau at about 25 FPS. Reaching 50 FPS requires drawing on the CPU into fast
   RAM on 020+, as Powerdrome did: 040/25 went from 17.9 to 41.2 FPS and 060/50 from 17.9 to
   42.7.
4. **50 Hz physics is affordable only on 020+.** It costs about 14% of a 14 MHz 020 and is
   negligible on 040/060. On the A500 it would cost about 55% of the CPU before any drawing,
   and the sibling projects that tried a higher sim rate there all regressed: Lands of
   Valour, Stellar 7, Red Baron and Revs.
5. **Further 68000 gains are modest and come from blitter latency.** The candidates are
   polygon plane blits, the once-per-frame clears and the dashboard, plus interrupt tax.
   Geometry is already optimised.

## 2. Decisions (defaults the executing agent uses unless the user overrides)

- **D1. Simulation rate per CPU, fixed for the whole race, chosen at race start.**
  - 68000/010: Normal 10 Hz on the corrected clock. The native A2500 benchmark gate stays as it is.
  - 020/030 without fast RAM: A2500 20 Hz.
  - 020+ with fast RAM: A2500 by default; A4000 50 Hz selectable.
  - 040/060: A4000 50 Hz by default.
  - The user can still choose any allowed rate in Ctrl-G. Never switch rate during a race.
- **D2. No render interpolation in this plan.** The 50 Hz mode already exists and holds
  50.2 steps/s on 040/060. Interpolating 20 Hz would add 50 ms of latency, which users
  rejected in I500 and in the triple-buffering trials.
  - Interpolation is the fallback only if the user drops 50 Hz physics because of handling
    differences (see P5).
  - The design is documented in AmigaXDev `docs/playbooks/simulation-and-presentation.md`.
- **D3. Pixel output must stay identical.** The CPU rasterizer must reproduce the blitter
  line and area-fill output bit for bit; verify it with pixel twins. If exact reproduction
  proves impossible for a primitive class, keep the blitter for that class. Do not accept
  "visually similar".
- **D4. Options.**
  - CUSTOM2 keeps rendering optimisations. Add bits; bit 0 keeps the meaning of "all
    validated".
  - CUSTOM3 keeps legacy timing (1 = original timing).
  - Each new rendering path is auto-gated by CPU and memory type, and stays off where it
    measures slower.
- **D5. Scope discipline.** This was the main brake in the previous run and in Red Baron and
  Powerdrome.
  - **One verification set per change:**
    - the pixel or state twin;
    - `check_disabled.py`;
    - `hook_audit.py`;
    - one A/B matrix row on each affected machine.
  - **No new open-work items** unless they describe a demonstrated defect.
  - **Docs are current state only.** Each phase updates one short section; history lives in git.
  - **Do not re-derive physics in P5** beyond the time box stated there.

## 3. Ground rules for every commit

- Follow AGENTS.md exactly.
  - Before each commit, check `git config user.name/user.email`, `GIT_AUTHOR_*` and
    `GIT_COMMITTER_*`. Both identities must be Vesa Halttunen <vesuri@jormas.com>.
  - Also check `commit.gpgsign=false` and `core.hooksPath=/dev/null`.
  - Add no Co-Authored-By or other assistant trailers.
- Commit only tracked source under `4/4DSportsDriving/usr/`. The harness `tmp/dev` stays ignored.
- Each commit is one coherent change with its measured result in the message: machine, cell
  and FPS before and after.
- Shared emulators: never kill an fs-uae that another project owns. Check its cwd with
  `lsof -a -p PID -d cwd`. Pick a free DEBUG_PORT of 2471 or higher.
- **Run every capture with a watchdog of 3 minutes to driving.**
  - The A500 cannot select A2500, so never request that cell.
  - The native build cannot use `--tick` anchors; use frame anchors.

## 4. Benchmark harness (do first, about 1 hour, no source changes)

1. Move `tmp/baseline-tools/run_cell.sh` and `measure_window.py` into `tools/` as
   `bench_cell.sh` and `bench_window.py`.
2. Add `tools/bench_matrix.sh`.
   - It takes a slave and a list of cells, and runs each cell with a watchdog.
   - It writes `bench.json` holding FPS, steps/s, backlog, timer latch and slave SHA.
3. Define the standard cells:

   | Cell | Machine | Sim | Detail |
   |---|---|---|---|
   | `A` | A500-equivalent | Normal | FULL |
   | `A-fast` | A500-equivalent | Normal | FAST |
   | `B` | A1200 020, 4M fast | A2500 | FULL |
   | `C` | 030/50 cycle-exact, fast, DCache on | A2500 | FULL |
   | `D` | 040/25 NOMMU, 16M fast | A2500 or 50 Hz | FULL |
   | `E` | 060/50 NOMMU, AGA | 50 Hz | FULL |

   - Add a FAST variant of each cell as needed.
   - Cells D and E must also run once with an opponent. Fix the `--opponent 1` assertion in
     the 50 Hz route first; it failed in the baseline.
4. Fix the frame counting so the FPS reported for a 10 s window is display-validated.
   - Do this on 000/020 with `display_check.py`.
   - On 040/060, count COP1LC writes at `$35332` with a breakpoint counter (SWAP_ONLY style).
5. Sanity-check the CPU speed setting: an 040 at 8 MHz must measure slower than at 25 MHz.
   Record the cache state in `bench.json`.

Acceptance: re-running the baseline reproduces the table in §1 within ±3%.

## P1. Correct game speed on every machine, native rates (highest value, smallest risk)

Completed and validated (11 October 2026): the production slave contains the
independent field clock and input queue for Normal/A2500, without VERIFY, SIM_RUNTIME,
A4000 physics or fixtures. CUSTOM3=1 skips all five timing hooks and clock installation.
The beam maximum-line detector selects a 50/60-field phase denominator. A4000 remains
an opt-in SIM_RUNTIME build. **P1 acceptance passes.** At the user's direction, the
A500 FAST 9.5-10 FPS requirement was moved to P2 and subsequently deferred
to close P2; it is not an outstanding acceptance gate.

Production slave: 11,286 bytes, SHA-256
`938f7b22b65fb2c56a15906e78724978da0e1f2d043620a30c593380334009e5`.
The 30-second windows below use the native race-clock formatter's actual input
(history base + consumed steps), divided by the selected rate and CIA emulated time.

| Cell | Display FPS | Steps/s | Race clock / emulated time | Queue start -> end |
|---|---:|---:|---:|---:|
| A, PAL | 3.96648 | 10.03286 | 1.003286 | 2 -> 1 |
| A-fast, PAL | 7.96629 | 10.03286 | 1.003286 | 1 -> 0 |
| B, PAL | 13.16781 | 20.00174 | 1.000087 | 1 -> 0 |
| B, NTSC | 13.46496 | 19.99746 | 0.999873 | 1 -> 0 |

All timing rows pass the +/-0.5% rate and clock limits, with no overflow or failure.
Evidence: `tmp/prof/p1-native-sync/{A,A-fast,B}` and `p1-ntsc-uae/B`.
These 30-second FPS values are not before/after speedups against the 10-second baseline:
scene content changes during the longer window.

The matched 10-second A-fast comparison establishes the P2 starting point: CUSTOM2=1/CUSTOM3=1
measures 7.69653 FPS, 8.29626 steps/s; corrected timing measures 7.59657 FPS,
9.99549 steps/s (race clock 0.999549). The baseline recheck was 7.59657 FPS,
8.29626 steps/s. Thus the predicted free rise to 9.5-10 FPS is not observed.
The 250-field profile attributes about 0.705% of samples to clock/queue work;
rendering and blitter waits dominate. Evidence: `p1-fast-legacy/A-fast`,
`p1-fast-ten/A-fast`, `p1-fast-profile/A-fast/clock-cost.json`.
The user approved moving the 9.5-10 FPS requirement to P2; it is not a P1 timing gate.

The disabled check passes all 21 rendering/timing ranges with CUSTOM2=0/CUSTOM3=1
(`p1-disabled/A-fast`). Hook audit passes all five timing hooks, 1,250 relocations
and 10,102 candidate branches; the native resource-name table is classified as data
only after exact byte and reference assertions (`tmp/build/p1-hook-audit.txt`).
Native 10/20 Hz replays load through the game UI and play all 301 recorded steps.
At step 200, all 1,120 captured simulation-state bytes match CUSTOM3=1 for both rates
(`p1-replay-final/state-check.json`). The legacy A2500 oracle pauses at consumer 299
with producer 301; its state comparison is deliberately at step 200, before that tail.

The 120.02-second stock-track runs on A, A-fast and B have no overflow; their maximum
sampled private queue depths are 3, 1 and 2 respectively (`p1-long-drive/{A,A-fast,B}`).
All remain in live mode; none reaches a crash or finish in this straight-line route.
Combined live crash -> native menu restart -> native finish checks also pass without
overflow on the same production build:

| Cell | PAL fields | Emulated seconds | Native outcomes |
|---|---:|---:|---|
| A | 8,880 | 177.60 | crash 1, restart, finish 3 |
| A-fast | 8,836 | 176.72 | crash 1, restart, finish 3 |
| B | 9,126 | 182.52 | crash 1, restart, finish 3 |

These functional runs use the existing scenery-cleared stock-track fixture and ordinary
keyboard input, with no guest-state writes. They include a long idle/gear-down prelude;
they do not claim continuous movement for their whole duration. The separate stock-track
runs above supply the 120-second moving-simulation coverage. A/A-fast use controls from a
previous successful native finish; B uses position/heading feedback to center its finish
approach. Evidence: `p1-crash-finish/{A,A-fast}/combined-lifecycle.json` and
`p1-crash-finish-centered/B/combined-lifecycle.json`.

Aggregate current results: `tmp/prof/p1-current-results.json`. All P1 timing and
compatibility gates pass. P1 test emulators are closed.

1. Make the field clock drive Normal and A2500 in the production build, independent of the
   A4000 code.
   - Create a build split: clock and queue in `simulation_clock.s`, `simulation_schedule.s`
     and `simulation_time.s`; A4000 physics stays separate.
   - Production = clock + CUSTOM2 rendering + CUSTOM3 legacy.
   - Disabled (CUSTOM3=1) must keep the original bytes; prove it with `check_disabled.py`.
2. NTSC: detect PAL or NTSC from beam line count (312/262) and fund ticks with a 50/60 phase
   accumulator. If that cannot be finished in this phase, force legacy timing on NTSC and say
   so in the ReadMe.
3. **Acceptance, all on cell A, A-fast and B:**
   - steps/s is 10.0 (Normal) or 20.0 (A2500) ±0.5%;
   - race clock / emulated time is 1.00 ±0.5%;
   - native 10/20 replays still load and play;
   - the queue never overflows in a 2-minute drive including a crash and the finish.
4. Commit: "Run Normal and A2500 at their true rate on every machine".

## P2. Blitter latency work (helps every machine, required ceiling for 68000)

Status: complete (11 October 2026). The user approved deferring the unachieved
A500 FAST 9.5-10 FPS target and closing P2 with the validated changes below.
The matched A-fast result is 7.69653 FPS; Normal/A2500 timing remains correct.
The deferred target is not a P2 acceptance gate and is not assigned to a later
phase by this decision. P3 has not started.

Current measurements (11 October 2026): the fresh A/250-field FULL profile
attributes 7.142% to explicit blitter polls and 11.9% to the main interrupt
context. The four-plane primitive tree is 25.81% inclusive; object geometry
is 36.72%. Clear/horizon and dashboard are 2.41% and 2.63% respectively in
this moving A500 window. These are workload shares, not additive speedups.
Evidence: `tmp/prof/p2-baseline/A/{summary.json,report.txt}`; the raw trace is
losslessly compressed with a verified SHA-256 in `trace-storage.json`.

P2.1 complete: CUSTOM2=1 now enables BLTPRI only after OwnBlitter returns
inside the primitive drawer. The saved priority bit is restored before
DisownBlitter; existing interrupt guards and waits are unchanged. PERF_MASK
bit 128 isolates the change; the priority-only measurement used mask 255. No tested CPU
regressed, so this path is enabled on all CPUs under CUSTOM2=1.

| Cell, matched 10 s | Before FPS | Priority FPS | Change |
|---|---:|---:|---:|
| A FULL | 2.69878 | 2.69878 | 0.00% |
| A FAST | 7.59657 | 7.79648 | +2.63% |
| B FULL | 9.29768 | 9.59761 | +3.23% |
| D FULL | 17.79556 | 18.39541 | +3.37% |

Evidence: `p2-baseline` and `p2-priority-built`. Production output is 11,342
bytes. The existing VERIFY/PIXELS stationary comparison matches all 32,000
output bytes for 16 primitive-input pairs on each of A/B; starting bitmaps
are not identical, so this is scoped output equivalence, not a whole-renderer
twin (`p2-priority-pixels-path`). CUSTOM2=0/CUSTOM3=1 preserves all 21 original
ranges (`p2-priority-disabled/A-fast`); hook audit passes 1,250 relocations
and 10,102 branch candidates. No new game hook is introduced by P2.1.
The FAST target is deferred; the remaining evaluations are recorded below.

P2.2 evaluated: removing only the extra wait in `perf_blit_on` regresses
A-fast 7.79648 -> 7.69653, B 9.59761 -> 9.39766 and D 18.39541 -> 17.89553
FPS; A stays 2.69878. The candidate is discarded (`p2-async`). Native waits
at $2CCD2/$2CD10 protect immediately following blitter-register writes, not
independent trailing work, so they remain. The added terminal wait remains too.

P2.3 retained on 68020 only: replace selected D-only rectangle planes with
32-bit CPU stores, preserving native clipping, plane selection and all pixels
outside the rectangle. Wait for preceding DMA before CPU access; preserve
registers and the original condition codes. PERF_MASK bit 256 isolates this
path; default mask 511. 68000/010 and 030+ retain the native rectangle hook.

Matched production 10-second results, P2.1 -> current:
A FULL 2.69878 -> 2.69878; A FAST 7.79648 -> 7.69653;
B FULL 9.59761 -> 9.99751 (+4.17%); D FULL 18.39541 -> 18.19546.
The 040 trial with CPU stores regressed to 17.89553, so it is excluded. Final
memory snapshots confirm native rectangle bytes on 040 and the new hook on
020. Small changes on excluded CPUs are reported, not claimed as speedups.
Evidence: `p2-cpu-rect-layout` (final), `p2-cpu-rect` (ungated trial).
All 12 sampled full 8,000-byte planes match the exact D-only fill model,
including unchanged pixels outside the rectangle and register preservation.
The completion audit adds an in-process native-blitter twin: an ignored
VERIFY source copy saves the full initial plane, runs the CPU fill, restores
the initial pixels, executes the original D-only blitter register writes,
waits for DMA completion, and compares all 8,000 bytes. All 568 plane pairs
match, with zero failures (`p2-rect-native-twin/B/rect-twin.json`). The original
production source and slave SHA are unchanged. This is a correctness test;
its slower instrumented FPS is not used in the production matrix. An earlier
cross-boot native comparison matched the fill model but had different outside
pixels; it is not counted as a same-input twin.
All 22 disabled ranges match; hook audit passes 1,250 relocations and 10,102
branch candidates (branches wholly removed by their own replacement are not
incoming edges). Production size is 11,490 bytes.

The A-fast clear census shows 320-pixel-wide bands of 113/118/121 rows,
starting at byte 360 in 8,000-byte planes. Flattening them into one tall
multi-plane blit would overwrite pixels outside the bands. The native clear
already returns without waiting for its final DMA. Clear/bitmap-copy waits
elsewhere stay intact; they cannot be removed without auditing their consumers.

P2.4 evaluated: the original mask uses different row strides for the temporary
mask and 8,000-byte destination planes; a single tall masked blit cannot restart
the source at each plane without changing pixels. The 250-field census contains
475 mask applications, 150 at one/two rows. A guarded CPU application of those
tiny native masks (one/two words, exact OR/AND minterms) gives A/A-fast/B/D
2.69878/7.69653/9.99751/17.79556 FPS: no qualifying gain, so it is discarded.
Evidence: `p2-baseline/A/polygon-plane-census.json` and `p2-tiny-mask`.

Further ownership trials are also discarded. Extending priority to all owned
intervals gives 2.69878/7.69653/9.99751/17.49563 FPS. Holding ownership over the
primitive list, while retaining every completion wait, gives
2.69878/7.69653/10.09748/18.09548 FPS. Neither meets the >=2% gain rule against
the retained build (`p2-all-owned-priority`, `p2-batch-owned`). Direct CPU dot
writers at $333B2 explain why completion waits between primitives must remain.

P2.5 reviewed: the native CIA dispatcher registers exactly $006F8 (engine
sound) and $07964 (game timing) in the driving snapshot. The player channel is
active; only the second engine channel is idle. The A profile attributes 1.58%
self time to engine sound, 0.87% to the native callback dispatcher, 0.43% to
the native timer and 0.46% to its division helper; the shared kick interrupt
dispatch accounts for 2.92%. The player sound accumulator is still approaching
its target, so skipping its callback changes sound. The private field clock
was about 0.705% in the P1 A-fast profile. No safe idle callback elimination
with a measured >=2% gain was identified; no interrupt change is retained.

Current retained production, 11,490 bytes, SHA-256
`f6a1d01be326b2a59506fefd85d2d07bff18d8b6460a1d0ac5ce9d5d0a459a2c`:

| Matched 10-second cell | P2 baseline FPS | Current FPS | Change |
|---|---:|---:|---:|
| A FULL | 2.69878 | 2.69878 | 0.00% |
| A FAST | 7.59657 | 7.69653 | +1.32% |
| B FULL | 9.29768 | 9.99751 | +7.53% |
| D FULL | 17.79556 | 18.19546 | +2.25% |

The final 60-second timing check on this same build passes: Normal on A/A-fast
is 9.99952 steps/s (clock 0.999952); B is 19.98171 (clock 0.999085), without
queue overflow. Longer-window FPS is not compared with the table above because
the moving scene changes. Evidence: `p2-final-timing`; aggregate current report
`tmp/prof/p2-current-results.json`. Retained changes: `29079b3` and `4d2a4e0`.
P2 acceptance passes with the user-approved deferral of the unachieved A500
FAST 9.5-10 FPS target. P2 is complete; P3 has not started.
Rejected candidates are absent from source;
large rejected-run snapshots are losslessly compressed with verified hashes.

Profile cell A first: a fresh 250-field FULL trace with CUSTOM2=1. Then attack these in order
and keep only what measures ≥2% on some machine. Gate each one per CPU (playbook §10).

1. **Blitter priority (BLTPRI/BLITHOG) inside the owned drawing intervals.** Use the existing
   W1 OwnBlitter hooks.
   - Test Drive II measured A500 +4%, A1200 +3.7% and 020/100 +18%.
   - Measure on A, B and D.
2. **Make the last wait of each primitive asynchronous.** Instead of the poll at `$2CD10`,
   `$2CCD2` and slave `$182C`, wait at the next blitter-register write or the next CPU access
   to the bitmap (as I500 did).
   - Find every consumer first: CPU reads or writes of the back buffer between primitives.
3. **The once-per-frame clears and fills `$21026` (9%) and `$0818E` (7.3%).**
   - Identify exactly what they draw.
   - Collapse the per-plane blits into one D-only blit per contiguous plane range, using
     modulo tricks for interleaved or consecutive planes (Red Baron W4 gained +3–7%).
   - Start the clear blit early and do geometry while it runs. The CPU must not touch the
     chip buffer meanwhile.
   - On 020+, consider CPU 32-bit stores only if they measure faster (I500 got background
     planes 0/1 this way). Keep blitter chip-to-chip copies.
4. **The polygon `$2AB90` per-plane mask blits.** Where a polygon's colour sets several planes
   identically, the four sequential plane blits can sometimes become fewer.
   - This needs the colour/pattern analysis in P3 step 1. Do it only if P3 is not taken on
     the machine in question, i.e. on 68000 and chip-only 020.
5. **Interrupt tax (A500 ctx1 15.5%).**
   - Split it into CIA-B sound sequencer `$36E0E`/`$6F8`/`$7964`, audio, VERTB and kick
     dispatch `$8E6`.
   - Take only exact reductions, e.g. skip callbacks with no work (Red Baron W3 +1.9% A500).
   - With the P1 clock, the timer no longer schedules simulation, so sound timing changes
     cannot affect game speed.

Acceptance: an A and B matrix row per change, the pixel twin for every drawing change
(existing `PIXELS=1` route), and `check_disabled.py`. The original +5–15% estimate was not an acceptance gate;
actual gains are recorded above. The user deferred the A500 FAST 9.5-10 FPS target.
Commit each item separately.

## P3. Fast-RAM CPU rasterizer for 020+ with real fast RAM (the step that breaks 18 FPS)

Status: in progress (11 October 2026). A VERIFY-only solid/two-colour span
rasterizer preserves the native clipped edge arrays and draws into private fast
RAM. On B it passes 1,996 same-input native/CPU comparisons of all 32,000 bitmap
bytes, including untouched pixels (`p3-span-twin-final/B/span-twin.json`).
The diagnostic runs both paths and copies/compares whole bitmaps per primitive;
its 1.100 FPS is not a production performance result. Production remains the
P2 build. Native stipple and non-display bitmaps are deliberately excluded from
this initial verifier; P3 is not yet enabled or complete.

All 26 disabled hook ranges match original bytes (`p3-span-disabled-final/B`);
hook audit passes 1,250 relocations and 10,102 candidate branches. The rebuilt
production slave is still 11,490 bytes with SHA-256
`f6a1d01be326b2a59506fefd85d2d07bff18d8b6460a1d0ac5ce9d5d0a459a2c`.
The disabled VERIFY row is only a byte-preservation check: its consumed-step
counter remains zero across the window, so it is not accepted as a timing test.

The local host models match 88 solid/two-colour draws, 32 natural clipped lines
and 72 explicitly synthetic line cases covering all octants and degenerate
lines. Evidence: `p3-spans`, `p3-spans-more`, `p3-lines-screen`,
`p3-lines-octants`. The renderer contract is in `docs/internals.md` under P3.
The native solid mask writer has a one-pixel edge quirk when the following
packed span is empty; the CPU path reproduces it. Remaining work is the rest
of the existing P3 scope below, including complete primitive/lifecycle twins,
frame staging, production gating and the B/C/D/E performance matrix.

The model is Powerdrome (its repository's `docs/performance-implementation.md`):
render into a 32,000-byte fast-RAM staging bitmap with code in fast RAM, then MOVEM-copy the
changed region to the chip back buffer.

1. **Reverse-engineer the drawing contract.**
   - Inputs: the primitive stream that `$0AB82` dispatches (polygon `$2AB90`, line `$2A898`,
     other `$2Axxx` helpers), the colour and pattern tables, the clip rectangle, and the
     descriptor at `a4+$BEA` (plane pointers +$14, stride +$EA, rows +$EC).
   - Outputs: the exact pixels the blitter produces. This covers line mode with one-dot
     edges, exclusive or inclusive fill, fill-carry, masks and dithered patterns.
   - Also cover every CPU or blitter writer of the back buffer within a frame: the clear,
     horizon and sky from P2.3, the dashboard and text.
   - Write the findings into internals.md: a table of primitive kinds and the blitter
     settings each uses.
2. **Write a host-side Python model of the blitter output for one primitive.**
   - Check it against native output from captured primitive streams with the existing
     `draw-pixels` captures; use 100+ primitives covering every kind.
   - This is the correctness oracle. Do not write 68k code before the model matches 100%.
3. **Implement the 020+ CPU path in slave code.**
   - Use edge stepping identical to the blitter line algorithm (Bresenham with the same
     octant and sign rules), span fill with the same inclusive or exclusive edge semantics,
     and 32-bit planar span writes with left and right masks.
   - Use static code only: no self-modifying code (Powerdrome used 16 span-loop copies plus a
     dispatcher). Keep the inner loops under the 256-byte 020 i-cache.
   - Target the staging bitmap when the whole frame is CPU-drawn. Otherwise draw direct to
     chip, but only after measuring.
4. **Frame flow on the CPU path.**
   - Clear the staging bitmap (CPU MOVEM or move16 on 040/060), draw everything into it,
     then copy the viewport rows to the chip back buffer.
   - If the dashboard is static between frames, copy only the 3D viewport. The dashboard and
     text keep their native routines, drawing into the chip buffer after the copy.
   - Flush caches after copying any code to fast RAM.
5. **Gate it.**
   - On only when AttnFlags ≥ 020 and the game hunk and staging buffer are in real fast RAM
     (use `TypeOfMem` MEMF_FAST and reject slow `$C00000` RAM).
   - Off on 68000: Powerdrome measured −17% there.
   - New bit: CUSTOM2 bit 1, also included in "all validated".
6. **Verify.**
   - VERIFY pixel twin: render each frame both ways (native blitter into a shadow buffer, CPU
     into staging) and compare all 4 planes. Run it on every graphics level, a crash, a
     replay and the finish (the existing routes).
   - Run `hook_audit.py` and `check_disabled.py`.
7. **Acceptance.**
   - **Matrix B, C, D, E at FULL in A2500.** The native 20 FPS cap still applies here, so the
     expected result is that B moves toward 15+ FPS and D and E reach 20/20.
   - **The real test: D and E at 50 Hz.** Target ≥35 FPS on 040/25 and ≥45 on 060/50 at FULL.
     If the copy dominates, profile and reduce the copied region; do not micro-optimise
     spans.
   - On 060, measure with and without fast-RAM code. Powerdrome's win came from code fetch,
     not from the bitmap.
8. Commit in three steps: the model and harness are local only, then "CPU rasterizer
   (VERIFY-only, twin)", then "enable on 020+ fast RAM".

## P4. Present up to 50 FPS cleanly

1. With 50 Hz physics, the `$7118` gate already allows one frame per tick. Measure on D and E
   after P3 that frames are not lost to a buffer-swap wait.
   - The swap writes COP1LC at `$35332` and the d9e7903 wait keeps the displayed buffer safe.
   - Collect a histogram of fields per frame. The target is mostly 1 at FULL on 060.
2. Do not add triple buffering (rejected for latency elsewhere). Do not add a frame cap below
   the simulation rate.
3. Measure input-to-display latency on D and E with the existing `presentation_latency.py`.
   The acceptance is ≤3 fields at ≥45 FPS. Report it; do not open new latency research.

## P5. Finish the 50 Hz (A4000) mode to release quality, time-boxed

The state is in open-work.md "Current status". It is close: 27/29 crest checks pass, replay
format 2 exists, and 040/060 capacity holds.

1. **Native format-2 replay save/load through the game UI.**
   - The last attempt left a zero-byte file and the writer was never reached. Find out why
     (likely the save path hook or the file-name dialog), fix it, then do a fresh-process load
     and play.
   - Acceptance: state matches at 3 checkpoints.
2. **The opponent route builder's out-of-resource read (`$1642A`).**
   - For 50 Hz races only, build the route from a deterministic, replay-recorded choice. That
     is already serialised; make fresh starts deterministic by initialising the read region.
   - Leave Normal and A2500 untouched.
3. **Jump and landing: time box of 2 working sessions.** Try at most two principled
   candidates from natural-jump-handling.md, using the existing frozen 29-check gate.
   - If it still fails, stop. Report the two failing metrics (common Y and pitch) with the
     numbers to the user, and let them choose: ship with the documented difference, use
     interpolation (D2 fallback), or keep 50 Hz experimental.
   - Do not widen criteria, and do not start new physics research.
4. **Per-CPU default (D1) at startup.** The default applies when no saved `4DPhysics.cfg`
   exists. The Ctrl-G choice persists and still takes effect at the next race.
5. Acceptance: 2-minute drives on D and E with an opponent, a crash and the finish. There
   must be no backlog growth, no queue overflow, and the race clock ratio must be 1.00 ±0.5%.

## P6. Release

1. **Single production build.** It contains the clock, CUSTOM2 bits, CUSTOM3 legacy and the
   A4000 mode, with no VERIFY, fixtures or startup tests.
   - Record the size and SHA. Run `check_disabled.py` for CUSTOM2=0 and CUSTOM3=1.
2. **Final matrix A–E, FULL and FAST, CUSTOM2=0/1.** Put it in the ReadMe as "emulator
   measurements; real-hardware reports welcome".
3. Rewrite the ReadMe version notes (1.3) to say:
   - true game speed on all machines;
   - per-CPU simulation defaults;
   - the fast-RAM renderer on 020+;
   - the options (CUSTOM2/CUSTOM3);
   - the known limitations.
4. **Functional test with the MMU enabled on 040 (`CPU=68040`).** This checks that cache
   flushes are correct: Test Drive II overlay stubs black-screened a real 040.
5. Rebuild the dist archive with `tools/package_testing.py`. Do not publish without asking
   the user.
6. Collapse the harness docs: open-work.md and the 200 KB research notes become one
   current-state page, and history lives in git.

## Expected outcome (emulator, FULL detail)

| Machine | Now | After P1–P2 | After P3–P5 |
|---|---:|---:|---:|
| A500 FULL / FAST | 2.9 / 7.6 FPS at 0.83× speed | ~3.1–3.3 / ~10 FPS at 1.00× | same |
| A1200 020 FULL | 9.3 | ~10 | ~13–16 (20 Hz cap) |
| 040/25 FULL | 18.5 (20 Hz cap) | ~19 | ~35–42 at 50 Hz |
| 060/50 FULL | 18.5 | ~19 | ~45–50 at 50 Hz |

These are estimates derived from the sibling-project results. Every claimed number must come
from `bench_matrix.sh` on the build being committed.

## Not doing (with reasons)

- **Projection by reciprocal table:** it changes rounding and gets no cache hits on
  per-vertex depths (Red Baron).
- **A higher simulation rate on the 68000:** measured regressions in four sibling projects.
- **Triple buffering, or the slave forcing caches:** both rejected by the user in sibling
  projects.
- **A chunky renderer with C2P:** the game is planar and blitter-based. A fast-RAM planar
  staging buffer gives the gain without C2P.
- **AGA FETCH64 and BLTPRI-off experiments:** no gain in I500.
- **Further W-series geometry micro-optimisation:** geometry is already optimised. On 020+, P3
  dominates; on 68000, P2 dominates.
