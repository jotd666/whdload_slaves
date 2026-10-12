# Red Baron performance: completion plan

This plan replaces "Next work" in `open-work.md`. It turns the existing W1–W6
work into a shipped result:

- the game runs as smoothly as each machine allows, up to 50 FPS PAL;
- the world advances at the correct real-time speed regardless of FPS.

Source facts are cited as `file:line` in this directory. Learnings from the
sibling projects are cited by project name.

Release amendment approved 2026-10-12: accept the measured performance and
finish release work. The original FPS targets below remain historical targets,
not release gates or achieved results. Close E with the measured retained/drop
decisions and refresh all six normal-build configurations at F3. D5 remains
postponed; W6 stays outside the normal verified mask. No further renderer
experiments are required for this release.

## 0. Rules for the executing agent

The previous run produced 209 commits in three days. The last 132 did not
change the player build, and 81 of the last 100 were verification or
measurement. The rules below prevent a repeat.

1. **Ship, don't survey.** Each step below is a source change with an
   expected gain. Do not run emulator or probe invocations repeatedly without a
   source edit between them. Do not add new byte-equivalence, cross-CPU
   full-state or "ownership" studies unless a step fails with a concrete bug.
2. **Validation budget per feature:**
   - build all three modes;
   - run the host tests and `audit_hooks.py`;
   - run one same-build A/B FPS window (≥2,000 fields; the A500 may use
     ≥1,000 fields of steady flight) per affected CPU class;
   - for exact-output replacements, one native twin;
   - 2–3 deliberate sabotages for any new checker.

   Run the full matrix only at the phase checkpoints marked ✔.
3. **Measurement limits.** Below about 2%, an FPS window cannot even resolve
   the sign. Bound such changes statically (cycle count × call count) and
   do not chase them. Drop any step that measures below 2% on every CPU class
   after implementation, and record it in one line.
4. **CPU gating.** Gate every change by CPU class (`perf_attnflags`) and, where
   relevant, by memory type. A change may help on the 68000 and hurt on the
   030, as W1a, G1 and S3 already did (`open-work.md:21-23,32-35`).
5. **Docs show the current state; history lives in git.** Update
   `profiling.md`'s scoreboard (step A2) and `open-work.md`. Do not grow
   `w6-verification.md` further; step F2 condenses it.
6. **Commits.** Make one commit per coherent feature, following the identity,
   unsigned, no-hooks and no-trailer rules in `AGENTS.md`. Verify the identity
   before each commit.
7. The §1 decisions are approved. Everything else has a default given in
   this plan.

## 1. Decisions (approved by the user, 2026-10-11)

| # | Decision | Approved choice |
|---|---|---|
| U1 | World quantum | **450 units on the 68000** (the original game's own clamp, which every stock A500 frame already uses, `game-time-plan.md:31-35`); **225 on 020+**, with interpolation |
| U2 | Overload policy | **Bounded debt** of 1 s of world time; the excess is dropped and counted in VERIFY, so gameplay slows gracefully as in the original |
| U3 | More fast RAM | **Raise `FASTMEMSIZE`** in the single slave to cover the measured chip spill; no second slave |
| U4 | Player default | **Faster rendering on by default**; icons unchanged |

Memory amendment approved 2026-10-12: raise the minimum RAM requirement after
E2's 1 MiB reservation failed the former 512 KiB chip + 1.5 MiB slow boot.
Keep one slave. The new minimum test configuration is 512 KiB chip + 2 MiB fast
on the 68000; validate its normal-build flight. Historical A500 scoreboard
measurements retain their original memory configuration until refreshed.

These are settled; do not re-ask. Stop and ask only if a step's evidence
contradicts one of them, e.g. if the amended A500 minimum cannot boot.

Historical line references into the condensed verification ledgers and
`open-work.md` resolve at commit `dd9e8b4`; current evidence summaries are
linked by filename, and current measurements are in `profiling.md`.

## 2. Where the time goes now

Baselines with no patches, in FPS (`profiling.md:2155-2162`):

| Machine | Steady | Event |
|---|---:|---:|
| A500 | 1.84 | 1.75 |
| 68020 + fast | 6.16 | 5.89 |
| 030/50, cached | 12.74 | 12.37 |
| 040 / 060 | never measured | never measured |

The W1–W5 gains were each measured in isolation:
- A500: about +6% for W2 and +2% for W3.
- 68020: about +5.5% for W2 and +3.5% for W4.
- 030: +7.5% for W4.
- W5 costs 0.7–2.5% on each machine.

There is **no combined bundle measurement**.

**A500 frame** (`performance-plan.md:107-121`, `w6-verification.md:5599-5644`):
- The 3D pass `sim:2c552` takes about 77% of the frame, 2.2M cycles.
- Two exact helpers inside it take 17.4% of the whole render:
  - exponent encoding `sim:2c31c`: 9.75%, 574 calls × about 893 cycles;
  - model-bank lookup `sim:398aa`: 7.70%, 1,131 calls × about 452 cycles.
- The world step `sim:01098` takes 365k cycles in steady flight, about 52 ms.
- A 4-versus-4 squadron takes about 880k cycles per world update.
- Interrupts take a fixed 15%, mostly sound.

**W6 on the A500 fails on the quantum, not on the design.** At Time Scale 40,
225 units means 8.15 world updates/s. In the squadron scene that is
8.15 × 124 ms ≈ 101% of the CPU, so the world never catches up
(`w6-verification.md:6765-6780`). At 450 units it is 4.07/s, about 50%.
450 is exactly what a stock A500 already runs every frame, because the native
clock is proportional and clamped at 450. So it changes no physics relative to
the original A500 experience. It only runs the right number of updates per
second.

**The fastest configuration tested** is a cached 030 accelerated to 200 MHz
in emulation (`w6-verification.md:7495-7525`):

| Part | Time | Fields |
|---|---:|---:|
| Scene | ≈ 41 ms | 2.05 |
| Cockpit | ≈ 29 ms | 1.44–1.52 |
| Publication | 4–7 ms | 0.21–0.36 |

That gives 12 FPS. **The CPU is not the limit.** The chip bus is: blitter
fills, `15e96` instrument scripts at 14.5 ms, `19ba6` at 8.7 ms, overlay
`2c144` at 7.3 ms. 50 FPS needs a 20 ms frame.

**Memory:**
- The slave's 512 KB ExpMem is full, with 24 bytes free. The game's remaining
  MEMF_ANY bitmaps spill into chip RAM (`performance-plan.md:141-150`).
- The 030 runs with both caches off unless the WHDLoad `MMU` tooltype is set
  (`verification.md:387-398`).
- Their Finest Hour went from 15.6 to **50 FPS** on a 030/50 mostly by moving
  data out of chip and adding 020+ code paths. Powerdrome reached +130% on
  040/060 by rasterising into fast RAM and copying to chip. Both regressed or
  stayed flat on the 68000.

## 3. Steps

### Phase A — scoreboard (do first)

**A1. Add 040 and 060 machine configs** to the local harness
(`tmp/dev/tools/w1_primary.py` and siblings).
- Machine: A1200 or A4000 AGA, 2 MB chip, 16 MB fast, KS 3.1.
- Timing runs: the cycle-exact `68040-NOMMU` / `68060-NOMMU` CPU types. The
  MMU cores ignore frequency (AmigaXDev `docs/playbooks/new-game-playbook-jotd.md`
  §8, found in Hard Drivin').
- Functional runs: a separate configuration with the MMU on.
- Add a 030/50 configuration *without* the `MMU` tooltype, so the out-of-box
  case is measured too.

**A2. Full-bundle census.** Measure CUSTOM2=0 against CUSTOM2=1 on the same
normal build on:
- A500 (512K chip + 2M fast after the approved E2 memory amendment; A2 used 1.5M slow)
- 020 + 8M fast
- 030/50 with and without MMU
- 040/25
- 060/50

For each, record:
- steady and event FPS;
- world update ms;
- scene, cockpit and publication split, from the existing `profile_flight.py`
  stage spans.

Put this as **one scoreboard table at the top of `profiling.md`**. Every
later step updates the column it touches. Commit: "Record full-bundle
scoreboard on five CPU classes."

### Phase B — memory and caches (cheap, large on 020+)

**B1. Stop spilling to chip.**
1. Log AllocMem calls during boot and the first flight, in VERIFY, with a
   one-shot trap through the kick13 AllocMem vector. List the size, flags and
   requested type of every allocation that lands in chip only because ExpMem
   is full.
2. Confirm those blocks are CPU-only by checking blitter register writes for
   their addresses. They should be: the original was written to run on
   machines with fast RAM.
3. Per U3, raise `FASTMEMSIZE` to cover the measured spill plus headroom,
   rounded to $1000. The original B1 check used 512K chip + 1.5M slow;
   the approved E2 amendment replaces it with 512K chip + 2M fast for the
   final boot/flight check. The 1 MB A500 cannot host 512K + 512K plus
   WHDLoad. Record the new minimum memory in `ReadMe`. Keep the hard rule that only DMA data lives in chip
   (Battlehawks memory rule).
4. Measure on 020, 030, 040 and 060.

**B2. Caches.**
1. Read the CACR at flight start on every config from A1.
2. Make sure the instruction cache is on everywhere through `resload_SetCPU`.
   The data cache stays as WHDLoad sets it: chip is non-cacheable only with
   the MMU.
3. If the 030 without MMU stays uncached for data, document the `MMU` tooltype
   in `ReadMe` with the measured difference. Do not force the data cache on
   without the MMU.
4. Measure.

✔ **Checkpoint B:** update the scoreboard; commit each of B1 and B2.

### Phase C — exact render helpers (mainly A500/020)

**C1. Promote the exponent replacement.**

Disposition: dropped under §0.3; all five CPU-class comparisons are below 2% (see the profiling scoreboard).
- `time-exponent.s` already holds an exact D0/D1/D2/CCR replacement for
  `sim:2c31c`, with a self-test and case table, but only under W6 bit 13
  (VERIFY).
- Move it to its own bit 15, compiled in all builds. Keep the self-test
  VERIFY-only.
- On 020+ use `bfffo`, or keep the table-free path if it already measures
  equal.
- Add bit 15 to `PERF_VERIFIED_MASK`, to the developer mask and to the
  `slv_config` strings.
- Expected on the A500: about −8% of render cycles
  (574 × ~750 cycles saved ≈ 430k of 5.3M).

**C2. Model-bank lookup cache** at `sim:398aa–398f4`.

Disposition: dropped under §0.3; the live-slot cache passed its lifecycle twin, but all five CPU-class FPS comparisons are below 2% (scoreboard).
- Cost: 1,131 calls/frame × about 452 cycles, a linear scan of the 12-byte
  bank records.
- Replace it with a direct index or last-hit cache. Invalidate it at every
  bank load or unload. The overlay-lifetime work has already identified those
  invalidation points (`overlay-lifetime.s`, `fdd095a`).
- Preserve the empty-bank and miss behaviour, using one native twin over a
  mission load, one in-flight bank change and one exit.
- Target: about −5% of A500 render cycles.

**C3. G5 face hub** (`w2-verification.md:319-325`): 223k A500 cycles, with
70–85k expected to be saved, about 3%.

Implemented on 68000 only: the exact vertex-loop replacement gains 3.39% in its same-build A/B window; native twin and host checks pass (scoreboard).
- Do it only if the scoreboard after C1/C2 still shows the A500 below 2.3 FPS
  steady.
- G6–G9 and S2/S4–S8 stay deferred. Each is below 2% (rule 3).

✔ **Checkpoint C complete:** all six normal-build configurations are recorded in the scoreboard; C1/C2 are dropped and C3 is committed.

### Phase D — simulation independent of rendering (the core requirement)

Reuse the existing W6 modules:
- `time-core`, `time-loop`, `time-input`, `time-keys`, `time-mouse`,
  `time-devices`
- `time-pause`, `time-rate`, `time-message`, `time-camera`, `time-compress`,
  `time-auto-menu`
- `time-poses`, `time-pose-blend`, `time-present-*`, `time-render`

They already implement:
- exact funding, retained debt and timestamped input;
- pause, Preferences and Time Compress;
- render interpolation (`open-work.md:83-104`).

What is missing is a feasible quantum, a pragmatic acceptance gate and
promotion out of VERIFY.

**D1. Replace the acceptance gate** in `game-time-plan.md` with this one.

Complete: the implementation contract now reflects the approved gate and accepted residuals.

*Must hold:*
1. **Speed.** At equal wall time, completed world time is within ±1% of
   nominal whenever the measured world cost fits the CPU, for every render
   schedule: normal, slowed, and one-field.
2. **Independence.** The funded tick count never depends on render duration.
   This is already proven by the host model.
3. **Commands.** One-shot commands run exactly once. Held controls apply to
   every catch-up tick.
4. **Transitions.** Pause, menus and Preferences rebase the clock with no
   catch-up. Mission exit during catch-up exits at once.
5. **Isolation.** With the bit off, the original bytes are retained.

*No longer required:* byte-identical full state across CPU classes or
quanta. The 225-versus-100 trajectory difference (1.72%) and the open h3,
message and sound residuals are recorded and accepted. Bring them back only
if a play-test shows a visible problem.

**D2. Quantum chosen per CPU class** (approved U1, U2):

Implemented in all modes after D4: both exact rate tables and bounded debt pass host/native checks, including straight/banked dt=450 helper twins; rate acceptance remains D5.

| CPU class | Quantum |
|---|---|
| 68000 | 450 |
| 020+ | 225 |

- Make it one constant chosen in `time_loop_install` from `perf_attnflags`.
- Precompute both increment tables in `time-core`. The phase arithmetic is
  already rational and exact per tick.
- Add the bounded debt from U2. Count dropped time in VERIFY telemetry and
  show it in the scoreboard.
- Check the >400 helper path on the 68000. It is the original's normal A500
  path, so a same-dt twin against the stock A500 build is enough. Run it once,
  for straight flight and a banked turn.

**D3. No interpolation where it cannot help.**

Implemented in all modes after D4: the 68000 native check records zero capture/blend calls with drawing retained; player measurements remain D5.
- Capture and blend poses only when the expected render interval is shorter
  than one world tick, i.e. on 020+ at 225.
- On the 68000, skip pose capture (23k cycles per tick) and blending (170k
  per frame), and present the latest world state.

**D4. Promote to the player build.**

Implemented: common runtime with VERIFY-only fixtures/logs, developer bit 13, CPU gate and one-field cap. All three builds, 439 host tests, 79 hook ranges and patch-reach audits pass; W6 is available through the independent player opt-in after the 2026-10-13 acceptance decision.
1. Split each `time-*.s` into its player code and its VERIFY instrumentation,
   keeping the instrumentation inside `IFD VERIFY`.
2. Move the includes outside the VERIFY block in `RedBaronHD.s`.
3. Keep bit 13 forcing bits 8 and 9. Under W6 the cap becomes one field, as
   planned (`game-time-plan.md:121-124`).
4. Check the 68000 branch reach with `audit_patch_reach.py`.
5. Add bit 13 to the developer mask, and to the verified mask only after D5
   passes.

**D5. Release acceptance complete (user decision, 2026-10-13).**

Automatable coverage is complete; results and fixture limits remain in
`profiling.md`. The user has accepted W6 for release despite the documented
A500 capacity/playability limits. W6 is a separate normal-build opt-in,
Consistent game speed (`CUSTOM3=1`, default Off), independent of Faster rendering.
This supersedes the earlier requirement to gate all normal-build availability
on the original capacity and gameplay targets. It does not add W6 to the default
rendering mask or claim 50 FPS. No additional acceptance flight is required.
Developer/VERIFY retain CUSTOM2 bit 13. The original checklist follows for context.

*Rate:*
- A500 steady and squadron, at Time Scale 0 and 40.
- 020, 030 and 060 at Time Scale 40.
- Time Scale 60 on the A500 may exceed capacity. Report it as the supported
  envelope, not as a failure.

*Input:*
- A tap and a hold during a long render.
- Throttle ±20 per key press.

*Transitions:*
- Time Compress entry and exit.
- Pause and Preferences.
- A mission ending in the middle of catch-up.

*Smoke tests:*
- Land, crash, and shoot down one AI aircraft on the A500 and on the 060.
- A 30-minute soak with no fault.

*Play-test:* ask the user to fly on A500 and 060 settings. The handling feel is
the user's call. `bash R/RedBaron/tools/playtest.sh a500` (or `060`) launches
the current D5 developer candidate at real speed with sound and the original
realism preferences; close the previous Red Baron window before switching.
Set maximum World/Aircraft detail and Ground ON IN COMBAT with F10; leave
Time Scale at 40 for the handling comparison. On each machine, check short
and held cursor-key inputs (including release), fire, land, crash and shoot
down an AI aircraft. Check C outside combat for Time Compress entry/exit,
then end a mission and start another. Report any delayed release, repeated
command, handling anomaly, visual fault or crash. These user observations
supplement the debugger checks; they do not establish catch-up timing by
themselves.

✔ **Checkpoint D:** update the scoreboard, adding a world-time/wall-time
column, and commit.

### Phase E — 50 FPS on capable hardware (020+/AGA)

Target: one publication per field on the 060, with 040 and 030 as fast as
they can manage. At 50 FPS the frame budget is 20 ms. Using the accelerated
030 figures (§2), the cockpit has to fall from about 29 ms to 4 ms or less,
and the scene from about 41 ms to 14 ms or less.

**E1. Measure the real 040/060 split first**, with the A2 configs after
B and D. Fast-RAM code and the 040/060 caches change the picture. If the
cockpit and scene are both chip-bound, as on the accelerated 030, continue
with E2 and E3 in that order.

E1 diagnostic complete: the scoreboard records both 250-field W6 stage
windows. Scene and cockpit each exceed 20 ms; proceed with E2 then E3. This
is not an A/B FPS result or proof of chip-bus saturation.

**E2. Cockpit cache** for `sim:15e96` instruments, `19ba6` dispatch and
`2c144` overlay. Today all three are redrawn every frame.

Disposition: complete. Retain the measured persistent gauge cache on 020/040
and include it in the normal verified mask. Drop the complete composition
under §0.3: all four affected CPU-class pairs regress by 20–46% (scoreboard).
The other standalone script candidates also missed 2%. Proceed to E3.
1. Run the instrument picture scripts into a persistent fast-RAM or chip
   offscreen copy only when their inputs change. Each gauge has a small value
   set, so key the cache on those inputs.
2. Each frame, composite the cached cockpit with a single masked copy.
3. Reuse the bit-14 overlay work (`overlay-pack.s`, `overlay-mask.s`,
   `overlay-shadow.s`, `overlay-lifetime.s`, `overlay-blit.s`). It already
   builds packed overlays, front-coverage masks and invalidation, but only
   under VERIFY.
4. Gate it on 020+ at first. Enable it on the 68000 only if it measures ≥2%
   there. Rescue on Fractalus found cockpit dirty flags gave about 23× on that
   work.
5. Check pixels with one twin per view: front, left, right and rear.
   Map-toggle check dropped: the bundled Manual's Mission Assignment and
   Navigation sections describe five offline maps; the bundled Keys lists
   no in-flight map command. The campaign transfer map is outside this renderer.

The retained gauge cache passes its front pixel/state twin and native
rear/left/right bypass plus front return. Full-composition view twins remain
part of E2 when that replacement is implemented.

**E3. CPU raster path for 020+.**

Rectangle disposition: direct-to-chip CPU fills are dropped under §0.3; all three AGA CPU-class pairs regress by 5–8% (scoreboard). Polygon merging is also dropped: all three AGA pairs regress by 3–5%, despite passing its pixel twin and both checker sabotages. The fast-memory back buffer is also dropped under §0.3: all four CPU-class pairs regress by 27–44%, despite passing its pixel twin and two checker sabotages. E3 is closed; retain the native blitter scene.
1. Replace the sky/ground rectangle fills, which are 27% of scene time on
   the 030, and the polygon span fills (21%) with CPU code using 32-bit stores
   on AGA.
2. Then measure drawing into a fast-RAM back buffer copied to chip once per
   frame, using MOVEM, or `move16` on 040/060 (Powerdrome, Their Finest Hour,
   Indianapolis 500).
3. Keep the blitter for chip-to-chip copies. It wins there (Hard Drivin).
4. Gate by CPU, and by AGA where 32-bit chip writes are needed. Check with
   one pixel twin per primitive against the existing D1/G2 twins.
5. If the line drawer shows up in E1 at ≥5%, do it in the same commit series.

**E4. Publication — target missed; measured performance accepted.**

The existing captures fail every-field cadence on 030/040/060 (scoreboard).
Beam-safe publication and the one-field W6 cap are already implemented;
rendering, not the cap, misses the budget. Drop the optional third buffer:
E1's publication share is below its threshold. The prescribed E2/E3 candidates
are exhausted. The user accepted this measured performance on 2026-10-12;
checkpoint E is closed with the scoreboard recording the missed targets.
Proceed to F; do not claim every-field rendering.
- With W6 on and the frame within one field, the cap is one field and the
  P1 beam-safe swap is kept.
- Check every field deadline with `publication_cadence.py`. It must pass on
  the 060. Report 040 and 030 cadence honestly.
- Consider a third buffer only if E1 shows publication waits ≥10% of the
  frame on the 060.

✔ **Checkpoint E:** closed by the accepted-performance amendment; E2, E3 and
E4 dispositions and measurements are committed. The six-machine normal-build
refresh is part of F3.

### Phase F — release

**F1.** Implemented in `dd9e8b4`: the normal build enables Faster rendering
by default. On=0 and Off=1 in its splash selector; developer masks are unchanged.
Then:
- Update `ReadMe` with the scoreboard summary, the supported Time Scale
  envelope per CPU, and the 030 `MMU` tooltype note.
- Keep JOTD's history and credits.
- Make the normal build's `slv_config` match the final mask.

**F2. Condense the docs — complete in `b564406`.**
- `w6-verification.md` (7,561 lines) and `w1`–`w5` become a short summary of
  the accepted evidence and their reproduction commands. The full text stays
  in git history.
- `open-work.md` lists only what is still open.

**F3. Final check — passed 2026-10-12:**

All six normal configurations and both disabled-byte selections pass; all
builds, 528 host tests and sim/sound hook plus patch-reach audits pass.
The scoreboard and ReadMe contain the final measurements. D5 remains the
explicitly postponed acceptance work, outside this accepted release.
1. Build all three modes.
2. Run the host tests and the hook audit.
3. Run the CUSTOM2=0 byte check.
4. Rerun the scoreboard on all six configs.
5. Commit.

No push or publication without the user's explicit request.

## 4. Expected outcome

These are targets to confirm in the scoreboard, not claims.

| Machine | Today (stock) | Target |
|---|---|---|
| A500 | 1.8 FPS; world runs at about 44% of real time | about 2.2 FPS, world at real time in steady flight and squadron (C1, C2, D2) |
| 020 + fast | 6.2 FPS | 8–10 FPS (B, C, E2) |
| 030/50 + MMU | 12.7 FPS | 20–30 FPS (B, E2, E3) |
| 040 / 060 AGA + fast | unmeasured | 25 FPS or more on the 040; **50 FPS on the 060** (E) |

On every machine, world speed is independent of FPS within the measured
capacity envelope (D).
