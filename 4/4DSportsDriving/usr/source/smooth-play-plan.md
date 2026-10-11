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
   timer fixes this. It also lifts A500 FAST from a cap of 8.3 FPS to 10 FPS for free.
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

The independent field clock, the input queue and the legacy option already exist in the
SIM_RUNTIME build. They are not yet in the production slave.

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
   - A500 FAST rises from 7.6 to about 9.5–10 FPS;
   - native 10/20 replays still load and play;
   - the queue never overflows in a 2-minute drive including a crash and the finish.
4. Commit: "Run Normal and A2500 at their true rate on every machine".

## P2. Blitter latency work (helps every machine, required ceiling for 68000)

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
(existing `PIXELS=1` route), and `check_disabled.py`. Expected total is +5–15% on A and B.
Commit each item separately.

## P3. Fast-RAM CPU rasterizer for 020+ with real fast RAM (the step that breaks 18 FPS)

The model is Powerdrome (`~/Projects/Powerdrome/docs/performance-implementation.md`):
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
