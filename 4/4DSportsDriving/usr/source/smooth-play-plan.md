# 4D Sports Driving: smooth play on every Amiga — execution plan

Written 2026-10-11 on HEAD `c70ea93` (branch `4dsportsdriving`). This plan supersedes the
"next steps" sections of optimization-plan.md, simulation-plan.md and open-work.md. Their historical
versions remain reference material for addresses and evidence, not a to-do list.
P1-P6 are complete; the A500 FAST target is deferred and A4000 remains experimental.
Current defaults supersede the earlier opt-in policy: PAL 040/060 use A4000,
020/030 use A2500, and 000/010 use Normal. Valid saved choices still win.
Historical harness research is preserved in `tmp/dev/docs/.git` at `9311a53`;
`docs/open-work.md` is the single current-state guide.
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
  - 040/060: A2500 20 Hz by default; A4000 remains experimental and selectable
    (user decision, 12 October 2026).
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
phase by this decision. P3 is complete below.

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
FAST 9.5-10 FPS target. P2 is complete; P3 is complete below.
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

Completed and validated (12 October 2026). P3 acceptance passes.
P4 is complete below.

The default production build now includes exact CPU rendering into a 32,000-byte
Fast-RAM planar viewport. CUSTOM2 bit 0 selects all validated optimizations;
bit 1 selects the CPU renderer alone. CUSTOM2=0 allocates no staging bitmap and
leaves rendering hooks absent. Runtime gates require 020+, a Fast-RAM game hunk
and a Fast-RAM staging allocation; slow $C00000 RAM is rejected. Allocation
failure keeps the native renderer. Native clipping and circle/wheel construction
remain; solid, two-colour, stipple, clipped-line, degenerate, full-row clear and
aligned sky paths are CPU-drawn. Unsupported writers flush staging before native
fallback. Only viewport rows are copied to Chip RAM; dashboard/text stay native.

Normal/A2500 production keeps its original 10/20 Hz rendering cap. In the opt-in
50 Hz build, stable live frames prepare Fast-RAM geometry/pixels before waiting
for the existing buffer switch. The wait still precedes every Chip write and
occurs early on transitions. No interpolation or triple buffering was added.
A4000 handling and release/default-mode work remain in P5/P6.

Matched FULL, held-throttle, 10-second emulator windows, except the explicitly
labelled A500 FAST gate check:

| Cell / simulation | P2 FPS | P3 FPS | P2 -> P3 mean frame ms | P3 steps/s |
|---|---:|---:|---:|---:|
| A500 FAST / Normal | 7.69653 | 7.69653 | 129.93 -> 129.93 | 9.99549 |
| B, 020/14 / A2500 | 9.99751 | 11.39716 | 100.02 -> 87.74 | 20.09499 |
| C, 030/50 / A2500, data cache on | 18.79531 | 19.89504 | 53.20 -> 50.26 | 19.99501 |
| D, 040/25 / A2500 | 19.59511 | 19.89504 | 51.03 -> 50.26 | 19.99501 |
| E, 060/50 / A2500 | 19.89504 | 19.89504 | 50.26 -> 50.26 | 19.99501 |
| D, 040/25 / 50 Hz | 19.29519 | 44.58887 | 51.83 -> 22.43 | 49.98753 |
| E, 060/50 / 50 Hz | 20.39491 | 45.48865 | 49.03 -> 21.98 | 49.98753 |

Final 50 Hz opponent rows (`p3-final-opponent`) measure 35.19122 FPS on D
and 36.79082 on E, at 50.08750/49.88755 steps/s respectively. Their renderer
has zero fallback, backlog growth or queue overflow; these are separate workloads
from the solo targets. `bench_matrix.sh --collect` produces the hash/window-checked
`p3-acceptance-matrix.json` and `p3-opponent-matrix.json` without repeating runs.

All rows have no backlog growth or queue overflow. Native-20 C/D/E count 199
published frames versus 200 simulation steps in the finite window; the native
20 Hz cap remains. B improves 14%, moving toward the directional 15+ FPS target.
The explicit 50 Hz solo targets (>=35 D, >=45 E) pass. The 50 Hz P2 rows use the
same existing 50 Hz physics with P2 rendering; they are not shipped-v1.2 results.
The corrected private emulator's CPU-frequency conversion is used for every
accelerator comparison here; older accelerator tables are not matched baselines.
C uses native IDE images and MMU-disabled 030 emulation: guest CACR=$2111,
DCACHE_EMULATION=1, cycleunit36, CE=1. Directory-drive C trials with actual
DCACHE_EMULATION=0 are superseded. D/E are the specified NOMMU cells, with guest
CACR=$80008000/$A0808000 and cycleunit72/36. These are emulator results; the
MMU-enabled 040/cache-flush test is explicitly P6, not claimed here.

Evidence: `p3-final-native`, `p3-final-p2-native`, `p3-final-dcache-ide`,
`p3-final-50`, `p3-final-p2-50`; native B/A-fast P2 is `p2-cpu-rect-layout`.
Production is 17,136 bytes, SHA-256
`ca21784268294d0ccc421e40bf03c85b4d4c8381b2c1f4ee75ea7d3ef0098e0e`.
The opt-in runtime is 204,056 bytes, SHA-256
`da4db5d958ca0f0c260c3b156d1eae29ede85088b3cab3ee5f2aaa9be8b98d24`.
The 50 Hz benchmark build has keyboard automation, SHA-256
`628c808f517292aaa1cfb2f2bbfb51d436e72b242063db0c9b475197eabe2ef8`;
it is not the production binary or a P5 physics-acceptance claim.

Correctness/compatibility evidence:
- Host models match 88 solid/two-colour primitives, 32 stipple captures,
  32 natural and 72 all-octant synthetic lines, 32 bitmap operations and 25
  circle cases. Native edge construction is retained; wheel emission is covered
  by whole-frame twins. The contracts and evidence paths are in `docs/internals.md`.
- Whole 32,000-byte pixel twins pass all five graphics levels (537 backgrounds
  and scenes), native A2500 replay (all 301 steps; 174 backgrounds/179 scenes),
  and crash/restart/finish (699 backgrounds/978 scenes over 9,141 PAL fields).
  The lifecycle fixture includes a long idle prelude, not continuous driving.
- Final renderer-only CUSTOM2=2 camera/opponent-view testing passes 546 scenes,
  460 backgrounds and 86 partial-background prefixes, zero mismatches, including
  1,015 wheel calls (`p3-final-renderer-only-twin/E`). Short functional setup
  windows are not FPS or simulation-rate evidence.
- A 250-field publication/four-plane DMA check passes. A separate cycle-timed
  blitter capture validates 2,139,280 CPU and 145,476 blitter framebuffer word
  writes, 3,957,692 known fetches, zero mismatches or writes to the displayed
  bitmap before display end (`p3-pipeline-display-dma/E`). Capture joins leave
  42,308 initially unknown words. Both traces are compressed with verified hashes.
- All 35 disabled rendering/timing ranges match original bytes on the final
  runtime with CUSTOM2=0/CUSTOM3=1 (`p3-final-disabled/B`). A500 and 020 without
  Fast RAM allocate no staging buffer; all P3 ranges stay native except the
  explicitly verified pre-existing P2 020 rectangle hook with CUSTOM2=1
  (`p3-final-native/A-fast`, `p3-final-no-fast/B`). Hook audit passes all 1,250
  relocations and 10,102 branch candidates (`p3-production-hook-audit.txt`).
- The full-renderer 060 placement pair measures 31.89204 FPS in Fast RAM versus
  25.39366 in Chip RAM with the same original early display wait. All 16 callbacks
  and actual copied-kernel execution are verified (`p3-full-placement-v2`). The
  copied 16,204-byte prefix includes local state/ownership helpers; this is not
  an instruction-fetch-only attribution. Game and staging remain in Fast RAM.

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

Completed and validated (12 October 2026). P5 has not started in this phase.
No further game-code change was needed: P3 already overlaps Fast-RAM rendering
with the preceding display switch, retaining the buffer-reuse guard before Chip
writes. Two buffers remain; there is no interpolation or cap below the selected
simulation rate. Normal/A2500 still have their native 10/20 FPS ceilings.

Matched 10-second FULL, solo, 50 Hz runs reproduce P3 exactly: D (040/25)
44.588874 FPS and E (060/50) 45.488650 FPS. Both complete 49.987527 steps/s,
race-clock ratio 0.999751, no backlog growth or queue overflow, and no renderer
fallback. These use the same calibrated private emulator and NOMMU settings
as P3; they are emulator results, not real-hardware predictions.

Separate 250-PAL-field display captures (100/100/50; joins excluded):

| Capture | Display FPS | 1-field / 2-field intervals | Sample to first containing display |
|---|---:|---:|---:|
| D, after the 10-second window | 43.032787 | 176 / 34 | 2–4 fields (one of 244 takes 4) |
| E, after the 10-second window | 44.834711 | 192 / 25 | 2–3 fields (243 samples) |
| E, near the initial frame-60 anchor | 49.385246 | 238 / 3 | 1–3 fields (245 samples) |

The last row verifies the ≤3-field acceptance at ≥45 FPS in the **same trace**:
98.76% of intervals are one field. Its 0.1-second setup window is not used as a
performance or timing result. D's isolated four-field sample occurs in the
43 FPS scene, below that acceptance's FPS condition; it is not hidden by reporting
only the latest sample selected for each render (which takes 2–3 fields on D).

Every complete captured copper switch maps to one actual four-plane display
transition. Complete pending-buffer waits span zero or one field, never two;
there is no additional multi-field swap wait or unmatched display publication.
The E late capture includes a split COP1LC long write: high word in field 237,
low word in field 238 slot 0, copper fetch in slot 6. The old checker incorrectly
required next-field visibility. The local checker now accepts same-field visibility
only with direct low-word bus-write-before-copper-fetch proof and still requires
an exact match between publications and display transitions. This was a checker
correction, not a missing frame or a change to buffer ownership.

Latency uses the existing `presentation_latency.py` chain: queued input sample →
completed physics → first displayed state containing that step, joined to copper
and bitplane DMA. These are PAL field-index differences (20 ms per field), not
host keyboard arrival, a visible steering-edge measurement, or monitor scanout.
Partial chains and capture joins are excluded. No new latency research was added.

Evidence: `tmp/prof/p4-presentation/{D,E,E-early}/` and its `matrix.json`.
The harness validates the P3 pipeline hook and displaced instructions, and adds
frame-interval and buffer-wait histograms. All cells used frame anchors, port 2471
and 180-second watchdogs; all owned emulators were closed. Traces are compressed
with verified decompression hashes. The game source is unchanged, so P3's twin,
35-range disabled-byte check and hook audit still apply to the identical builds.
Tested 50 Hz keyboard-route slave SHA-256:
`628c808f517292aaa1cfb2f2bbfb51d436e72b242063db0c9b475197eabe2ef8`.
Native production and optional SIM_RUNTIME hashes remain those recorded in P3;
the testing archive is unchanged. Stop before P5.

## P5. Finish the 50 Hz (A4000) mode to release quality, time-boxed

Status (12 October 2026): P5 complete under the user's explicit decision to
keep A4000 experimental. Normal/A2500 are the CPU defaults; 50 Hz is opt-in.
The frozen handling gate remains 27/29 with unchanged bounds. P6 has not started.

1. **Native format-2 replay save/load: complete.**
   - Clean native Save Replay produces a physical 63,912-byte format-2/ABI9
     file; a fresh-process native Load Replay and Play matches all 1,510
     semantic bytes at ticks 200, 400 and 600. CRC and format checks pass.
   - The old fixed-field diagnostic misinterpreted its completion counter:
     zero means the writer has not **returned**, not that it was never reached.
     A separate return-point probe sees zero during readback/CRC and one
     successful completion afterward. No game-code fix was needed.
   - Evidence: `tmp/prof/p5-save-clean/B`, `p5-reload-clean/B/validation.json`
     and `p5-save-return/B`. Native runtime, FULL solo, CUSTOM2=1,
     **NoWriteCache**; default-cache exit persistence is not claimed here.
     All owned emulators closed; short setup windows are not FPS measurements.
2. **Opponent route builder: complete.**
   - Only A4000 substitutes a private 256-byte cost table at `$16346`:
     the original 16 defined costs followed by 240 zero costs (the native
     accumulator adds one). Native traversal and tie-breaking are retained.
     The original resource allocation is neither extended nor overwritten.
   - Fresh race/restart initialization rebuilds the route after selecting
     A4000; replay loading instead restores its recorded route. Normal and
     A2500 retain the original pointer and reads; both bypass checks pass.
   - Independent route reconstruction matches fresh D and E runs exactly:
     129 lookups, including 48 formerly beyond the 16-byte resource, select
     the same 59-entry route. The older format-2 fixture retains all 1,802
     recorded route bytes (80 entries) and matches all 1,510 semantic bytes
     at ticks 1500/1550/1600 in fresh-process native playback.
   - Ten-second FULL/opponent samples: D 35.1912 FPS, E 36.8908 FPS;
     both 50.0875 steps/s and clock ratio 1.001750, zero backlog at both
     boundaries and no overflow. Previous P3 values: D 35.1912, E 36.7908
     FPS; the one-frame E difference is not a performance-gain claim.
   - Hook audit passes (1,250 relocations and 10,102 branch candidates).
     CUSTOM3=1 restores all 37 declared original-byte ranges. Short native
     bypass windows are functional checks, not timing measurements.
   - Evidence under `tmp/prof/p5-route-final/{D,E}`, `p5-route-replay/B`,
     `p5-route-native10/B`, `p5-route-native20/B`, `p5-route-disabled/B`.
     Optional runtime SHA256:
     `fe8293924a3b16d7a499ab73f5a831dd96e39dd70ae2d4a9ee109697ad65bdb7`.
     Opponent fixture SHA256:
     `7d926c8e29cc8d361641d953be43f528b47a611c8d8e2f64f15f477b4d4c455e`.
     Native production and the testing archive are unchanged; P6 remains open.
3. **Jump and landing: complete within the time box; A4000 experimental.**
   - Current emulator result remains 27/29. Common Y error is 2,263 against
     a 1,247 limit; common pitch error is 18 against 11 (internal units).
   - Exactly two documented hypotheses were re-run as recurrent offline
     models: native-derived exponential suspension extension leaves these
     errors at 2,263/18; native geometric pitch worsens them to 2,333/56.
     Both fail the unchanged bounds and are rejected; neither was promoted
     into game code. Baseline controls match all 795 reported rows in each
     of three phases. These are rejection results, not acceptance of the
     other 27 checks in the alternative models.
   - Evidence: `tmp/prof/p5-handling/validation.json`; unchanged frozen
     criteria SHA256
     `90570d37e39d7fbdf804bbc497959ffe30e60f51bbb60c3e938f041c1d3401db`.
     The existing emulator gate in `crest-d9e7903/bridge-handling.json`
     remains authoritative; physics code is unchanged.
   - User decision (12 October 2026): keep A4000 experimental, retain
     A2500 as the 040/060 default. No interpolation or further physics
     research; criteria stay unchanged. Defaults and final acceptance
     now pass as recorded below; P6 has not started.
4. **Per-CPU default (D1) at startup: complete.**
   - Missing/invalid `4DPhysics.cfg`: Normal on 68000/010; A2500 on 020+,
     including 040/060 per the experimental-mode decision. A valid saved
     choice wins, retaining the native A2500 benchmark eligibility gate.
     Loading does not write preferences. Ctrl-G remains next-race-only:
     the current keyboard-route check observes selected 50 with active and
     recorded rate still 20, then confirms all three at 50 after restart.
   - Runtime startup checks pass on A500, 020, 030, 040 and 060, including
     matching selected/active/recorded rate and intact preference guards.
     Fresh-process saved 10/50 and corrupt-file fallback checks pass on 020.
     Hook audit passes (1,250 relocations, 10,102 branch candidates); all
     38 declared original ranges match with CUSTOM2=0/CUSTOM3=1.
   - Evidence: `tmp/prof/p5-defaults`. Ten-second default-mode FPS:
     A 2.6988, B 11.2972, C/D/E 19.8950. These startup captures establish
     defaults, not new physics or handling acceptance. Optional runtime SHA:
     `03bf1d2007163a1f376ca7623cfc433c46aaa84c5c9204f1d6a9e6d88b024584`.
     Native production and archive remain unchanged pending P6.
5. **Opponent endurance acceptance: complete.**
   - Both runs exceed two minutes and include native water crash (reason 2),
     native menu restart and native finish (reason 3), with opponent 1 selected.

   | Cell | Lifecycle PAL-field seconds | CIA clock ratio | Observed backlog max | Queue max | Overflow |
   |---|---:|---:|---:|---:|---:|
   | D, 040/25 | 197.34 | 0.998598 | 0 | 2 | 0 |
   | E, 060/50 | 196.72 | 0.998689 | 0 | 2 | 0 |

   - Clock ratios cover 108.35/108.36 seconds of uninterrupted observation;
     both satisfy 1.00 +/-0.5%. Queue returns to zero at the end of the
     prelude and finish; no growing backlog or overflow was observed.
   - Scope: ordinary keyboard controls in a matching VERIFY keyboard-route
     build from committed `c746394`, no synthetic physics fixture/startup
     tests and no guest-state writes. The established scenery-cleared stock
     track is combined with nine established off-course water tiles. The
     sequence includes a long idle/gear-down prelude and menus; it is not
     two minutes of continuous movement or a stock-track handling proof.
   - The same unchanged game code is in the optional runtime identified in
     P5.4. Keyboard-test slave SHA256:
     `510b1ffdf822a2c756e96f9cd1d13f1da5be48d375810caf8b9c183d9ee1e987`.
     Evidence: `tmp/prof/p5-acceptance/{D,E}` and `validation.json`.
     The 0.1-second setup windows are not FPS/timing evidence.
   - Each cell retained its 180-second watchdog (158.26/170.57 seconds wall
     time). Owned emulators are closed. Defaults, ReadMe and results are
     committed; the testing archive and native production binary remain
     unchanged. Stop here; release work belongs to P6.

## P6. Release — complete (2026-10-12)

A4000 remains explicitly experimental by user decision. This phase creates a
local testing archive; nothing has been uploaded or published.

1. **One production build.** The default build contains corrected Normal/A2500
   timing, CUSTOM2 rendering options, CUSTOM3 legacy bypass, preferences and
   experimental A4000 physics/replays. No VERIFY, input fixtures or startup
   self-tests. `SIM_RUNTIME=1` is a compatibility spelling for the same binary,
   not a separate distribution. Both builds reproduce 204608 bytes, SHA256
   `522d97c2ce16e91c2a4edda5078aed1d86688cc9b7774e58f4bcef0edc690cef`.
   All P6 captures below use this SHA.
2. **PAL/NTSC integration.** Native modes retain the beam-detected 50/60 field
   phase accumulator. Experimental A4000 is PAL-only at all three entry points:
   preferences, CTRL-G selection and tagged replay loading. On NTSC, a saved
   50 Hz choice falls back to the CPU default; selection is ignored and replay
   loading reports an error before writing live state. The native menu test
   selects the A4000 row explicitly (the marked A2500 row is skipped).
   NTSC 30-second native check: 19.964129 consumed steps/s, race-clock ratio
   0.99820645, no overflow. Evidence: `tmp/prof/p6-ntsc/B-menu-fixed`.
3. **Final matrix.** `tools/bench_matrix.sh` produced and collected all 20
   A–E/FULL–FAST/CUSTOM2=0–1 rows in `tmp/prof/p6-default-matrix.json`.
   Ten-second PAL moving windows; FPS counts display-buffer switches. Every
   cell had its own 180-second watchdog and frame anchor, never `--tick`.
   A uses Normal 10 Hz; B–E use A2500 20 Hz, with no A2500 request on A500.

   | Cell / CPU | C2=0 FULL | C2=0 FAST | C2=1 FULL | C2=1 FAST |
   |---|---:|---:|---:|---:|
   | A / 68000 | 2.40 | 7.40 | 2.60 | 7.60 |
   | B / 020 | 8.20 | 17.10 | 11.30 | 19.90 |
   | C / 030/50 | 18.20 | 19.90 | 19.90 | 19.90 |
   | D / 040/25 | 19.70 | 20.00 | 19.90 | 19.90 |
   | E / 060/50 | 19.70 | 20.00 | 19.90 | 19.90 |

   A: 512 KB Chip + 1.5 MB slow. B/C: 2 MB Chip + 4 MB Fast. D/E:
   2 MB Chip + 8 MB Z2 Fast + 8 MB motherboard RAM. C uses native IDE boot
   and confirmed emulated data cache (`CACR=2111`, DCACHE_EMULATION=1).
   D/E use calibrated CPU clocks, MMU off and no emulated data cache.
   All rows retain actual cache state and effective emulator configuration.
   The ReadMe labels these "Emulator measurements; real-hardware reports welcome."
   No claim of fresh full-window DMA/pixel equivalence is made by this matrix.

   Separate opt-in 50 Hz matrix: `tmp/prof/p6-a4000-matrix.json`, same method:

   | Cell | C2=0 FULL | C2=0 FAST | C2=1 FULL | C2=1 FAST |
   |---|---:|---:|---:|---:|
   | D / 040/25 | 20.39 | 23.59 | 45.89 | 49.89 |
   | E / 060/50 | 17.80 | 29.49 | 45.49 | 49.89 |

   A4000 consumed rates are 49.88755–50.08750 steps/s, no queue overflow.
   Short native windows include queue-boundary catch-up: A FULL C2=0 consumes
   103 steps while funding 100 (queue 3→0), so its 10.29535 consumed steps/s
   is not a claim that the clock runs fast. Phase and endpoint quantization
   also affect individual ten-second counts. P1/P2 longer-window timing and
   P5 long lifecycle evidence retain their documented scope.
   The A500 FAST 9.5–10 FPS target remains deferred, and no real-hardware FPS
   prediction follows from these emulator-specific rows.
4. **Bypass and state checks.** `tmp/prof/p6-legacy/B` passes all 38 disabled
   ranges with CUSTOM2=0/CUSTOM3=1. Every C2=0 matrix row separately passes
   the rendering-byte check. `tmp/build/p6-hook-audit.txt` checks all hooks,
   1250 relocations and 10102 aligned PC-relative branch candidates, with no
   interior targets. No new game hook was introduced in P6.
   PAL opponent replay restores all 1802 recorded route bytes and matches all
   1510 semantic state bytes at steps 1500/1550/1600 against the preserved
   format-2 regression fixture (`tmp/prof/p6-route-replay/B`). This is existing
   replay Load/Play evidence; P5 owns the actual disk Save/Load proof.
   Native Normal/A2500 replays both load and play all 301 steps, matching all
   1120 legacy state bytes at step 200 (`tmp/prof/p6-native-replay-final`).
   The short setup windows for replay checks are not FPS/timing evidence.
5. **68040 MMU functional pass.** `tmp/prof/p6-mmu-fixed/D` uses a full 68040,
   native IDE with the matching A1200 motherboard/ROM, JIT off, MMU enabled
   and no NoMMU option. It passes startup, 50 Hz gameplay, preference load,
   change/save with physical disk CRC verification, normal quit and shell
   continuation. The matching WHDLoad report says `TC=8000`, `CACR=80008000`
   and `Return OK`. This is functional compatibility, not an FPS measurement
   or real-hardware cache proof. The first setup used a mismatched A4000
   motherboard/A1200 ROM and did not boot IDE; it is not acceptance evidence.
6. **Documentation and archive.** ReadMe v1.3 describes corrected speed, CPU
   defaults, options, renderer eligibility, experimental handling limits and
   the measured matrices. `tools/package_testing.py` builds
   `dist/4DSportsDriving_v1.3_1461.lha` (928591 bytes), SHA256
   `bba31739993eec7b668294ec919a919da43a5adfc89d9855a09a22f35b7ece33`.
   Re-extraction verifies all 124 original member names: exactly the slave
   and ReadMe changed; the remaining 122 files are byte-identical. LH5,
   level-1 headers. Archive remains local and unpublished.
   Harness research is condensed into `docs/open-work.md` with compatibility
   entry-point links. All 29 prior notes are recoverable from local personal
   Git history in `docs/.git`, commit `9311a53`, with no remote.

The earlier outcome estimates are superseded by these measured results.
P6 makes no further physics/handling changes: the frozen gate remains 27/29,
and the two failed bounded trials remain documented in P5.

## Splash simplification — v1.3b (13.10.2026)

The splash now offers only `Enhanced framerate (68020+Fast for CPU renderer)`
(CUSTOM2 bit 0). It selects all compatible rendering optimizations; the CPU
renderer still checks 68020+ and real Fast RAM, while other improvements can
benefit 68000 machines. Renderer-only CUSTOM2=2 and legacy CUSTOM3=1 remain
advanced tooltypes and are no longer shown as splash checkboxes. Corrected
simulation timing remains the default; A4000 stays an in-game experimental
opt-in. Credits include `Enhancements by Vesuri`.

The rebuilt slave is 204608 bytes, SHA256
`e5b5d52a1fdfc9890029a47dbc805b54c15f117c449c9816beefe70d3544b7ec`.
The executable/data payload from file offset 5174 is byte-identical to the
P6 build measured above (199434 bytes); only header/text metadata differs.
No gameplay or gating code changed, so the P6 measurements remain applicable.
The actual splash is captured in `tmp/prof/splash-v13b/splash.png`; its binary
metadata/payload verification is in `check.json` alongside it.

Current local testing archive: `dist/4DSportsDriving_v1.3b_1461.lha`, 928822 bytes,
SHA256 `0cacd1d4eaa3a54bfb5013e2107f5fd6ae631740a37738c0d587238524d6cb90`.
All 124 members were re-extracted and checked; only the slave and ReadMe differ
from the original v1.2 pack. Nothing was published.

## Automatic A4000 default on PAL 68040/68060 — v1.3b

At the user's request, missing/invalid preferences now choose A4000 (50 Hz)
on PAL 68040/68060. The CPU mask checks the 040 and 060 attention bits;
68000/010 retain Normal (10 Hz), 020/030 retain A2500 (20 Hz), and NTSC
040/060 retain A2500. Valid saved choices retain precedence. CUSTOM3=1
still bypasses corrected timing/default selection entirely. The splash
rendering checkbox remains independent. A4000 is still experimental (27/29
handling checks); the previous manual-opt-in-only policy is superseded.

No physics integrator, replay format or rendering algorithm changed. The
production slave is 204640 bytes, SHA256
`4d6772b1256620dc5722eb9522b6af8702cca263693f3053bcc43be17c18517f`.
The local archive is `dist/4DSportsDriving_v1.3b_1461.lha`, 928885 bytes,
SHA256 `9efc20751c347531bd4997e799b4c4bf7b2d3c8c2e85e81c3a393ff456cd6a24`.
All 124 members were verified; only the slave and ReadMe differ from v1.2.
The earlier P6/splash hashes above identify their historical captures.

Validation on this build: `tmp/prof/default-040060`. D and E start with
selected/active/recorded rates all 50 and no saved file; ten-second FULL
benchmarks are 45.88855/45.98853 FPS at 49.98753 steps/s, no queue overflow.
Saved 20 Hz on D and saved 10 Hz on E override the CPU defaults. NTSC D
with a saved 50 Hz choice falls back to 20 Hz (status 5). Guard checks pass.
The legacy B check preserves all 38 disabled hook ranges; the hook audit
passes with no new hook or interior branch/relocation target. Short setup
windows for preference/legacy checks are functional evidence, not FPS rows.
Each emulator had its own 180-second watchdog and was closed afterward.

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
