# Grand Prix Circuit — performance plan

Goal: give GPC the Test Drive II treatment under one `CUSTOM2` "Enhanced framerate" option:
a higher simulation rate on 68020+, smooth (sub-unit) road and car drawing and blitter
priority, with the original game one option away. Method: AmigaXDev
`docs/playbooks/new-game-playbook-jotd.md`. Reference implementation: `T/TestDrive2/usr/source/`
in this fork (offsets do not carry over) and the standalone Test Drive 2 project (harness,
tools, docs). The local harness lives in the worktree's ignored `tmp/dev/`.

## Decisions

- `CUSTOM2` "Enhanced framerate" bundles every performance change; `CUSTOM2=0` retains
  original simulation/rendering apart from the always-on display handoff fix.
- Pure bug fixes (the swap tearing fix) are always on, like TD2's DDFSTOP fix.
- **Performance only.** What the player experiences stays original: handling, AI, lap and
  race times, crashes, spins, pit stops, penalties and messages. No TD2-style recovery change.
  Every simulation change must be shown equivalent to the original (Phase 6 checks).
- Simulation period: 6 fields on 68000/010 (the original), 2 on 68020+. Go to 1 on 68020+
  only if measurements show the game can actually reach 50 fps there and the step cost fits.
- Preserve the original clock/statistics units: one lap tick per six active fields,
  formatted as a tenth; do not correct the PAL clock's 5/6 real-time rate. Retain native
  pause/pit/finish gates and the drawing-path start/collision logic. Their CPU/drawing
  dependence is an original limitation, not permission to redesign gameplay (Phase 4).
- Only v1.0 (the 94 708-byte executable) is supported; other versions keep JOTD's patches.

Addresses below are hunk-0 offsets of `data/GrandPrixCircuit` (file offset = hunk + $28),
the slave's patch numbering. Static analysis is supplemented by the runtime checks below.

## What we know (static analysis and runtime validation)

- Executable: 94 708 bytes, Aztec C small-data (a4 = hunk1 + $7FFE), hunks CODE $E544,
  DATA $8918 initialised bytes in a $9364 allocation (including its zeroed tail),
  plus a separate BSS $4 hunk. `HUNK_OVERLAY` with an empty table. The linked overlay manager starts at h0:d42c
  (alternate entry d43e; stub writer d4a2), not d414. It is inactive in the supplied v1:
  all 139 hunk-1 jump stubs are already direct jumps, no relocated pointer targets the
  manager, and entry/write breakpoints plus a full-table hardware watchpoint stayed silent
  through startup, car presentations and two attract races. No stub rewrites were observed.
- Shared with TD2 (byte-identical or operand-masked identical): RNG `c11e` (VHPOSR at `c12c`,
  seed 2002(a4)), shape blitter `c7f4`, line drawer `cfd2`, 4-plane span fill `8864`, movem
  clear `ce1e`, VBL/audio server `b126`, sound driver (song1..3), protection `b2f4`.
- **Not shared:** the race engine is a ~18 KB hand-written asm block at h0:6854–af3c. There
  are no TD2 offsets to reuse for simulation, projection, swap or road rows.
- **Different architecture:** GPC is single-task. The simulation runs inside the VBL interrupt
  server "Ticks VBLInt" (AddIntServer at h0:40e, code h0:772a): every field it bumps -31790(a4);
  unless paused (-31736), it bumps -29930, counts down -29928 from the period word -29926
  (= 6, data hunk $B18, never written), then steps: `776a`, `jsr -32514(a4)` → `a288` (AI),
  `782e` (player), `8010`.
  The six-field cadence is independent of drawing, but game state is not: start lights
  and car collisions run in the drawing path. Phase 3 below supersedes the earlier
  assumption of complete decoupling.
- Main loop h0:7094–7264 → `729a`: `a58c`, latch `a6ea` (copies car tables, -30016→-30010,
  -30012→-30006, -29930→-29932; not interrupt-safe), `a77c`, `9a48`, road `818c`, `906a`,
  `6dc4`, `6ae0`, `6a28`, swap `a8ee` (→ h0:372, LoadView at h0:39e; no WaitTOF, then `cf04`
  retargets drawing to the old display buffer before the new View takes over). Phase 5
  confirms visible horizon writes in this interval and fences reuse before raster work.
- Player track position: segment pointer -30016, 8-bit in-segment fraction low byte of
  -30012 (h0:7e2c–7e46). The analogue of TD2's camera fraction F.
- Road renderer: per-scanline span lists, 110 rows (loop end h0:8508), stripe phase from the
  latched integer camera at h0:84b2.
- Rebuilt slave (1.1-beta): interface 17, kick13, own LoadSeg; the 94,708-byte executable
  selects `resload_PatchSeg`, other sizes retain JOTD's `resload_Patch` path. The lists
  keep the original busy loop `PL_PS $174`, protection skips, 68010 `move sr`, and song
  INTREQ/DMACON patches. `slv_config` now exposes `CUSTOM2`: Phase 5 enables blitter priority
  and suppresses unused blitter-finished IRQs when selected. The display handoff fix is
  unconditional for v1. The vasm Makefile builds normal and VERIFY outputs separately;
  only VERIFY exposes RNG/input/traffic/slow-draw and original-swap measurement fixtures.
  The normal build kept Phase 1 bytes through Phase 4; Phase 5 adds the render hooks.

## Plan

Each phase ends with a check. Do not start performance patches before Phase 4 is done (playbook §12).

### Phase 0 — Harness (complete)
1. Copy TD2's `amiga/run.sh`, `run-a1200.sh`, `run-68030.sh` into `tmp/dev/amiga/`, adapted
   like Red Baron/Hard Drivin' (`GAME`, `SLAVE_NAME=GrandPrixCircuit.Slave`, resolve `SLAVE`
   paths absolutely, kick13 images into DH0:devs/Kickstarts, `HARNESS_ROOT`).
2. `tmp/dev/tools/build.sh`: vasm build of `$GAME_SOURCE` into `tmp/build/` (normal and
   `-DVERIFY`), from WHDLoad 20.0 includes/KickEmu, like Red Baron's.
3. Tools: `gpc.py` (rename of the gdb `Server` wrapper), `_amigaxdev.py`, `td2_report.py` →
   `gpc_report.py` (hunk sizes, path, kick13), `frames.py`/`swap_fields.py` (new marker:
   swap at h0:372/39e), `profile_demo.sh` + `ingame.py` (new in-race pixel test),
   `fixed_window.sh` (new anchor), `state_fields.py`, `state_writers.py`, TFH's whole-hunk
   `compare_state.py`, `audit_simulation.py`, `check_disabled.py`, `check_units.py`. Skip
   TD2-specific ones (`task_state`, `state_watch`, `subunit_*`, `sideways_*`).
4. `docs/development.md`, `docs/internals.md` (seeded from "What we know").
   **Check:** shipped slave boots to the title/attract demo on the A500 profile; pristine
   manifest unchanged; `git status` clean.

### Phase 1 — Rebuild and modernise the slave (complete; no game patch changes)
1. Build the unmodified source; fix only what vasm 1.9 needs. Compare behaviour with the
   shipped slave (byte-compare if the shipped one came from the same source).
2. Move to the TD2 slave skeleton: slv_Version 17, `slv_config`, `resload_PatchSeg` with a
   size/CRC-checked v1 list (others fall back to JOTD's), `IFD VERIFY` blocks; replace the
   stale `Makefile` with the vasm build used by the TD2 directory.
3. Runtime checks: overlay manager never rewrites a stub (watchpoint on the jump table /
   h0:d4a2); protection stays bypassed; music fixes intact.
   **Check:** new slave plays identically with `CUSTOM2=0`; `check_disabled.py` sees original bytes.

#### Phase 0/1 results and evidence

- The existing `grandprixcircuit` worktree was clean before the source changes; all harness
  files remain ignored under `tmp/dev`. The retained preinstalled archive has 55 files,
  all still matching `tmp/archives/GrandPrixCircuit_v1.0_0008.files.json`. No game bytes,
  SDK, generated slave or capture is committed.
- `tmp/dev/tools/build.sh` delegates to the authoritative source Makefile; `VERIFY=1`
  selects the separate VERIFY output. Direct `make -C G/GrandPrixCircuit/usr/source`
  works too. Dependencies: vasm 1.9, official WHDLoad 20.0 headers/KickEmu, NDK LVO
  includes via generated guarded wrappers. The sole original-source assembler fix was
  `blk.l` to `dcb.l`. The pre-modernisation build is retained as
  `tmp/dev/tmp/build/GrandPrixCircuit-unmodified.slave`.
- Shipped 1.0, baseline rebuild, modern normal and modern VERIFY all reach the opening
  screens and automatic driving demo with `CUSTOM2=0` on the A500 profile (68000,
  512 KB chip, 1.5 MB slow, no fast RAM; PAL). The normal build was also checked on
  A1200/68EC020 (2 MB chip, 4 MB fast). WHDLoad 20.0 and 19.2 both passed the A500 run.
  WHDLoad 17 itself and real hardware were not available for this check.
- `check_disabled.py` undoes hunk relocations and checks 58,642 original code bytes on
  68000 (58,628 on 68020), plus the six existing JOTD patches (thirteen on 68020), and
  all 139 relocated jump stubs. Only named native mutable slots are excluded: startup
  h0:0008–0017, audio state fields b220–b223/b228–b22b and native runtime storage
  b6ea–b6ed. Corruptions at 039e, 772a and 818c each caused a failure. The existing
  delay/protection hook boundary audit found no errors.
- The three song files have identical driver code. Live checks confirm all three INTREQ
  fixes and eleven DMACON hooks. Baseline-rebuild and modern helper bytes match; the
  shipped BASM build uses shorter branches/other equivalent encodings, so whole-slave
  byte identity is neither expected nor claimed.
- The active opening-screen pixels match exactly between shipped, baseline rebuild and
  VERIFY. Demo driving is visibly functional in all arms. This is code/patch equivalence
  and functional startup/demo coverage, not per-field state equality: RNG pinning and
  repeatable gameplay windows belong to Phase 2. The whole-data comparator rejects
  changed/truncated inputs and distinguishes the two recorded demo states (1,154 bytes).
- Overlay evidence: read-only breakpoints at h0:d42c/d43e/d4a2, armed before h0:0018,
  and a hardware watch over h1:0000–0341 (834 bytes) had no hits. Entry and race snapshots
  match the relocated pristine table. A watch of the same size over the native VBL field
  counter caught its write, validating the debugger mechanism. For this executable the
  manager is dormant; there are no runtime overlay stub replacements to accommodate.
  Other executable versions are not available and are not covered by this conclusion.
- Local reproducible checks: `tools/validate_boot.py`, `check_inputs.py`,
  `check_disabled.py`, `check_music.py`, `check_units.py`, `audit_simulation.py`.
  Evidence under `tmp/dev/tmp/validation/{shipped,unmodified,modern,verify,a1200,whd19}`:
  exact slave/hash, debugger transcripts, entry/title/race RAM and screenshots; summary
  `tmp/dev/tmp/validation/checks.txt`. Commands and coverage limits are in local
  `tmp/dev/docs/development.md` and `internals.md`.
- Prepared GPC report/state tools and candidate capture wrappers. The candidate swap
  marker was h0:039e, VBL entry 772a and first race-loop anchor 7094. They were not
  performance-validated in Phase 1; Phase 2 results below supersede that limitation.

### Phase 2 — Measurement setup (complete; playbook §5–§8)
1. Trace the confirmed attract demo or a scripted race start; name every hot region
   with `gpc_report.py`.
2. Fixed reproducible window: VERIFY `CUSTOM3` removes VHPOSR from the RNG (`c12c`, same patch
   as TD2 `PL_W`); anchor at race start; `CUSTOM5` joystick tape (TD2's `verify_read_joydat`
   idea, at GPC's joystick read).
3. Validate the frame counter (full trace vs `SWAP_ONLY` at the LoadView swap).
4. Baseline fps on A500 (512 chip + 1.5 MB slow), A1200 (68EC020), 68030/25.

#### Phase 2 results and evidence

- Measurement code lives entirely inside `IFD VERIFY` / `verification.s`. `CUSTOM3=1`
  replaces the six-byte VHPOSR read at h0:c12c with `moveq #0,d1; nop; nop`, keeping the
  native RNG otherwise intact. `CUSTOM5=1` replaces the six-byte joystick read at c1de.
  The native field counter drives the tape: accelerate before field 100, up-left 100–105,
  up-right 106–111, accelerate 112–199, brake 200–299, coast 300–399, then accelerate.
  Menus before the first race receive neutral input. Fire/keyboard input is not synthesized.
  The native attract driver remains in control: this establishes capture reproducibility, not handling
  equivalence or coverage of all player controls. Conditional patch commands require
  WHDLoad 17.2+ in VERIFY; these measurements use 20.0.
- The six-byte store at 707a records the native race epoch and replays the original store,
  preserving registers and X. The first loop at 7094 is armed from CPU reset after a
  calibration boot; skip 300 native VBL entries at 772a, then discard the partial current
  field. The 100-field trace covers the start-light transition and initial acceleration;
  the 1,000-field counter continues through the opening driving section. These are fixed
  windows, not whole-race averages. All runs use PAL, `DETERMINISTIC=1`, `CUSTOM2=0`,
  `CUSTOM3=1`, `CUSTOM5=1`, and both joystick devices AND port modes disabled.
- Calibration now requires a live, initialized VERIFY record. A low-quorum byte search
  found a false code address before the 68030 game had loaded; those failed boots are
  excluded. Code/data discovery follows LoadSeg and checks the resident slave's initialized
  resload pointer, excluding PRELOAD/file copies. Each capture retains its exact slave,
  options, RAM, epoch, CACR and emulator logs.
- Two fresh A500 boots match exactly in all 100 instruction/register/cycle records, DMA
  records and active-pixel images, and the entire data hunk at both boundaries. The expanded
  A1200 pair passes the same check. No arbitrary game-state bytes are masked;
  only pointer relocation normalization and the external emulator image border are excluded.
  The 68030 pair matches all 1,000 swap counts AND the complete before/after 4 MB fast RAM.
- Full traces and read-only `SWAP_ONLY` counts agree in every one of the first 100 fields
  on both 68000 and 68EC020. The LoadView site 039e produces exactly one displayed-buffer
  transition on the following field for all 9 A500 and 22 A1200 publications. DMA fetch
  addresses identify exactly two bitplane sets. The counter skips the partial field just
  as the profiler does; starting it at zero instead of -1 would introduce a one-field
  error. This validates publication counting, not correct ownership of the drawing buffer.

| PAL configuration | 1,000-field baseline | Completed intervals / fields | Actual CACR |
| --- | ---: | ---: | --- |
| A500, 68000, 512 KB chip + 1536 KB slow | 5.6402 fps | 111 / 984 | Not present |
| Expanded A1200, 68EC020, 2 MB chip + 4 MB fast | 14.5226 fps | 289 / 995 | $00000000, caches off |
| A1200, 68030/25, 2 MB chip + 4 MB fast | 24.6747 fps | 493 / 999 | $00002000, I/D enable bits clear |

FPS is `50 * completed swap intervals / elapsed fields` between the first and last
publication. The short 100-field trace rates are 4.6512 and 11.4130 fps respectively;
they must not be mixed with the longer baseline. The 68030 uses real CPU speed,
multiplier 0, frequency 25,000,000 and cycle-exact mode, without WHDLoad's MMU option.
Its backend supplies no usable instruction trace, so no CPU-cost figures are claimed.
These are emulator baselines, not hardware measurements; a stock no-fast-RAM A1200 was
not part of this requested matrix. Cache policy is unchanged.

| Cost in the 100-field trace | A500 | Expanded A1200 |
| --- | ---: | ---: |
| Four-plane span-fill region 8864, self | 21.08% | 17.79% |
| Span wrapper 883e, self | 12.90% | 8.67% |
| Shape-blitter region c7f4, self | 8.77% | 16.15% |
| Line drawer cfd2, self | 4.89% | 5.33% |
| Rectangle fill cce2, self | 3.07% | 5.23% |
| Movem clear ce1e, self | 2.47% | 6.56% |
| Draw scene 729a, inclusive | 76.76% | 81.69% |
| Road renderer 818c, inclusive | 44.52% | 51.39% |
| Blitter polling, game + KickEmu | 13.37% | 30.49% |
| Level-3 IRQ entries (VBL / blitter) | 2133 (100 / 2033) | 5156 (100 / 5056) |
| Level-3 inclusive IRQ cost | 12.93% | 7.54% |
| Level-1 entries / cost | 22 / 0.0737% | 21 / 0.0220% |
| Level-4 entries / cost | 13 / 0.0932% | 14 / 0.0226% |
| DMA free / CPU / blitter | 26.19 / 37.53 / 5.95% | 45.19 / 9.88 / 14.59% |
| DMA bitplane / copper / refresh / audio | 28.15 / 0.22 / 1.76 / 0.20% | 28.15 / 0.22 / 1.76 / 0.20% |

No recorded CPU-idle cycles occur. CPU overhead markers account for 0.75% / 0.49% and
are not mislabelled as handler execution. IRQ cost is tracked from vector entry to RTE,
not inferred from stack context. Self ownership uses the nearest known entry; inclusive
ownership follows observed calls. Shared tails and partial calls make these attribution
estimates, not exact function budgets, and inclusive rows overlap. All game regions above
1% self are named, including road rows, object attributes/projection and shape-cache work;
KickEmu waits/clear, Kickstart interrupt/graphics work and WHDLoad interrupt forwarding are
identified separately. Reports retain the call edges and hottest instructions.

- The joystick audit observed all five raw values over 76 reads through field 451,
  each matching the field-indexed schedule. With CUSTOM3=0/CUSTOM5=0 the original
  RNG and joystick bytes are intact; only the VERIFY epoch hook remains.
- The normal slave is byte-identical to the Phase 1 normal build. The final VERIFY slave
  SHA-256 is `00d10fd6d6b01f2499e702bf309fcdfb36181916cdc94b77acfd9aa03ce303ba`.
  The hook audit checks six complete instruction spans, with no direct branch into a
  replaced instruction. Exact live code checks allow only the three named VERIFY sites,
  then check all Phase 1 code/JOTD patches and 139 stubs; a corrupted swap instruction is
  rejected. All 55 pristine game files retain their manifest hashes.
- Local evidence: `tmp/dev/tmp/prof/phase2-{a500-full1,a500-full2,a500-aligned,
  a1200-full1,a1200-full2,a1200-swaps,68030-swaps1,68030-swaps2,tape,fixtures-off}`.
  `metadata.json`, `metrics.json`, `profile.txt`, `frames.txt`, `repeatability.txt`,
  `tape.json`, debugger transcripts and retained slaves make the checks reviewable.
  Consolidated checks are in `tmp/dev/tmp/prof/phase2-checks.txt`.
  Reproduction commands are in `tmp/dev/docs/development.md`; the harness remains ignored.
- The user observed blinking horizon/building graphics during this work, consistent with
  the suspected on-screen drawing/buffer-ownership bug. No renderer or swap fix was applied.
  Confirming causality and fixing it remains Phase 5. No tearing fix is included in Phase 3.

### Phase 3 — Game-time model (complete; playbook §9, `fixed-time-simulation.md`)
1. Map every time source: -31790, -29930/-29928/-29926, 3730(a4) render deltas, race/lap
   clock (-31424/-31416; 4024 is auxiliary; pit time divides -31790 deltas by 6), sound, RNG.
2. Coupling test: CUSTOM4 slow drawing — does race time, lap time and AI progress stay the
   same? Test the VBL cadence separately from state; find the exceptions (crash/spin recovery, pit stops,
   start lights, anything in the main loop instead of the VBL).
3. State map of the step: player (`782e`→`786c`/`7e2c`/`7e66`/`795c`), AI `a288`, `776a`,
   `8010`. List every rate that must scale with the step period.
4. Price the step: interrupt time per step on 68000 and 68020 (decides period per CPU).

#### Phase 3 results and evidence

The complete clock, state/writer, rate/event and pause/pit/crash inventory is in
[GAME_TIME.md](GAME_TIME.md), including source offsets, capture methods and limitations.

- **Fixed step cadence, drawing-dependent state.** All six accepted solo/traffic windows
  on A500, deliberately slowed A500 and expanded A1200 execute 120 steps in 720 fields,
  with period 6 and no pauses. For solo attract, publications are 71 / 41 / 180;
  first observed go fields are 310 / 327 / 305. Lap ticks at field 720 are 68 / 65 / 69.
  Start-light thresholds execute inside drawing, using the previous render delta.
- The corrected traffic fixture populates all ten grid IDs before native initialisation;
  nine opponents move forward. Publications are 66 / 39 / 169; go fields 315 / 321 / 304;
  lap ticks 67 / 66 / 69. A500 normal/slow share simulation phase and raw joystick history.
  Completed-step snapshots confirm the first lap/speed difference at step 54, field 319.
  Matching lap ticks 1..66 gives identical decoded player/AI motion and RNG in that pair.
  Whole allocated data differs across rendering rates; no full-state equality is claimed.
  The CPU comparison also includes differing pre-race countdown/input sampling phase.
- **Actual lap clock:** -31424, with completed-lap sum -31416. 4024 is an auxiliary tick
  counter. Native six-field ticks are displayed as tenths, so PAL clock time runs at
  approximately 5/6 real time. The pit display uses elapsed native fields **divided**
  by six, not qualifying fields multiplied by six. Correcting the PAL clock changes gameplay.
- **Further coupling:** draw-time `$a58c` changes player position, speed, damage and collision
  state using latched opponent speeds. `$a6ea` is not interrupt-safe. Pause freezes active
  fields/countdown without catch-up; the native pit service interval explicitly resumes
  simulation between paused entry/exit. Crash/spin decay is in the VBL, but terminal
  handling/messages wait for the main loop. Human controls, full laps, native pit entry
  and all crash/spin outcomes are mapped statically, not claimed as played-through tests.
- **Other clocks:** audio has a separate VBL age counter; the song drivers really program
  CIA-A timer A. Their clock does not feed the race VBL. The clock scan includes every
  pristine file and all CIA timer/control/TOD registers. No boot benchmark sets the period.
- **Rate inventory:** distinguishes integrated travel/forces from per-segment damage and
  lap events, gear/AI decisions, display timers and collision impulses. Cooling is already
  period-scaled: `$77b0` subtracts d0, loaded with the period at `$774c`. Do not scale it twice.

Populated-traffic native VBL callback cost, 100 fields after 600 warm-up fields, caches
unchanged (020 CACR=0), including callees; each priced step executes nine opponent updates:

| Machine | Step cycles min / mean / max | Proposed period | Projected callback share, mean / sampled-max |
|---|---:|---:|---:|
| A500 68000 | 31,112 / 32,305 / 33,898 | 6 | 4.01% / 4.20% |
| Expanded A1200 68EC020 | 16,563 / 16,921 / 17,285 | 2 | 3.02% / 3.09% |

The projection includes non-step callbacks, but excludes future scaling helpers and
unrelated IRQ/dispatch work; it is not a worst-case guarantee. Period 1 projects to 5.95%
(mean) on the 020, so sampled simulation cost alone does not rule it out. **50 rendered fps
has not been demonstrated**: populated-traffic traces draw at 5.0 / 13.02 fps, and the
Phase 2 68030/25 baseline is 24.67 fps. The proposed 6/2 periods fit this measured budget;
the decision remains Phase 4. No simulation period, cache, handling, timing or renderer fix
was made to the normal slave.

- New hooks are VERIFY-only: `CUSTOM4` waits eight native VBL transitions before drawing,
  replaying complete calls at `$729a/$729e`; it does not delay initial pre-race setup. `CUSTOM1`
  enables an explicitly artificial attract-with-traffic fixture, with a validated 0..9
  grid permutation. An earlier incomplete traffic fixture pushed the player backwards
  (as the user noticed); those captures were rejected and excluded from all figures above.
- The normal slave is byte-identical to Phase 1, SHA-256
  `e7d4b1361817ede24db993d8d19969ac11887352d6e8b45e2c628391a15d908d`.
  Final VERIFY SHA-256:
  `7af8f2f025632252c316c1ef6aa0991b254165edc2fac2d6a14784d41b01d0ed`.
  Both vasm builds pass; all 55 pristine manifest hashes remain unchanged.
- The data capture extent is corrected from the `$8918` file payload to the `$9364`
  allocated hunk, including the zeroed tail that contains race controls. Existing full-RAM
  Phase 2 recordings allow its A500/A1200 repeat comparisons to be rerun: all boundary data,
  instruction/register/cycle records, DMA records and active pixels still match.
  Changed BSS flags and truncated snapshots are rejected by comparator negative controls.
  A fresh accepted traffic boot matches all 720 allocated-data snapshots and every
  step/publication count exactly. The eight hook spans pass their boundary/branch audit;
  original-code/JOTD-patch/stub checks pass on both CPUs, including corruption rejection.
- Local evidence: `tmp/dev/tmp/phase3/accepted-*`, `summary.json`, `clock-scan.json`,
  comparison reports, retained per-run slaves and debugger logs. Step cost is in
  `accepted-cost-{a500,a1200}/step-cost.json`; completed ticks in
  `accepted-ticks-{a500-0,a500-1,a1200}`. `REJECTED.txt` identifies superseded runs.
  Reproduction commands are in `tmp/dev/docs/development.md`; tools and original data stay
  ignored. The reported blinking horizon is resolved in Phase 5 below.

### Phase 4 — Review point (complete)

#### Cadence and rendering budget

Retain the planned period **6 on 68000/010 and 2 on 68020+**. This is a design decision
supported by the measured native cost, not a claim that the unimplemented conversion has
passed its runtime tests. The 68010 choice retains the native cadence; it was not separately
benchmarked. Phase 2 fixed-window baselines are **5.6402 fps on A500, 14.5226 fps on expanded
A1200/68EC020 and 24.6747 fps on 68030/25**, all with the original cache policy. They count
publications at `$39e`; the shorter Phase 3 traffic windows are different workloads.

| Native callback with nine opponent updates | A500 | Expanded A1200/68EC020 |
|---|---:|---:|
| Mean / sampled maximum stepped callback, CPU cycles | 32,305 / 33,898 | 16,921 / 17,285 |
| Chosen period, PAL fields | 6 | 2 |
| Projected callback share, mean / sampled maximum | 4.01% / 4.20% | 3.02% / 3.09% |
| Projected callback share at period 1, mean / sampled maximum | 22.73% / 23.85% | 5.95% / 6.08% |

The projections include light callbacks on intervening fields. The 020 period-2 projection
adds about **1.96 percentage points** to its native period-6 callback share. Cost alone
therefore supports 6/2. It does not predict a frame-rate gain or bound the complete IRQ:
future helpers, interrupt dispatch, sound, blitter IRQs and untested gameplay events remain
outside this sampled budget. Phase 6 must remeasure the actual converted code with traffic,
human input and forced events before accepting it.

Rendering dominates the baseline: the inclusive scene accounts for 76.76% / 81.69% on
A500 / 020, with blitter polling at 13.37% / 30.49%. These overlapping profile categories
must not be added. Cheap blitter work and the buffer-ownership fix remain the next phase;
the simulation budget is not evidence that the renderer can produce 50 complete visible
frames per second. The current swap marker also precedes the pending tearing fix.

#### 50 fps decision

**Period 1 is not selected.** No tested configuration demonstrates 50 rendered fps. Extra
Phase 4 measurements keep the final Phase 3 VERIFY slave, period 6, original cache policy,
2 MB chip / 4 MB fast RAM, 300-field warm-up and 1,000-field solo attract window:

| A1200 / 68030 profile | Completed publication intervals / PAL fields | Publications/s, nominal PAL | CACR |
|---|---:|---:|---:|
| 50 MHz | 612 / 998 | 30.6613 | `$2000`, I/D enable bits clear |
| 100 MHz | 684 / 999 | 34.2342 | `$2000`, I/D enable bits clear |

These are read-only breakpoint counts at `$39e`, not inferred instruction timings. FS-UAE
uses real CPU speed, frequency override, multiplier 0 and cycle-exact mode; no max-speed,
instant-blitter, cache or game patch is used. The 50/100 MHz runs use one identical VERIFY
binary; the older Phase 2 baseline used an earlier VERIFY layout, so it is context rather
than a strict same-build scaling comparison. Neither the higher-frequency emulator profile
nor these publication counts establish a real-hardware limit or tear-free visible output.
The 030 backend has no validated instruction timing, so the step-budget decision uses the
000/020 traces, not extrapolated 030 cycle counts.

The measured answer is **50 fps not demonstrated**, not proof that no accelerator or future
renderer could reach it. Keep period 2 for 020+; revisit period 1 only with demonstrated
50 fps on the intended configuration, a correct buffer handoff, and the implemented
simulation's measured cost and handling checks. Phase 4 does not introduce that option.

#### Gameplay policy and acceptance boundary

The existing **performance-only** decision settles the policy without expanding scope:

- Keep lap/race tick units and statistics on the original six-active-field cadence. On
  nominal PAL, 600 active fields give 100 ticks, displayed as 10 seconds over 12 real
  seconds. Preserve pit elapsed-fields / 6 formatting, sample counts and display holds
  consistently; do not make the clock run three times faster at period 2 or correct it
  to wall time. Audio/CIA clocks keep their independent native timing.
- Keep pause, pit, finish and crash/spin gates and event ordering. Pausing freezes active
  fields and the step countdown without accumulating catch-up work. The Phase 3 inventory
  distinguishes rates, per-distance impulses and discrete decisions; it is not a licence
  to divide every constant by three. In particular, thermal cooling already uses the
  period word and must not be scaled twice.
- Retain the drawing-path start lights and car collisions. Phase 3's A500 traffic control
  and slow-draw run both execute 120 steps in 720 fields, but release the start gate at
  fields 315 and 321 and end at 67 and 66 lap ticks. Their named motion/condition/AI state
  agrees over 66 matched race ticks. Thus fixed step cadence does **not** establish
  drawing-independent gameplay. Collisions also mutate live speed, position, damage and
  RNG from latched state; their cadence/input age changes with drawing.
- Do not silently move start/collision logic into the VBL or change its thresholds to
  obtain cross-machine equality. Faster drawing can change original event sampling even
  when its code is untouched. Record those differences explicitly during later A/B work;
  they cannot be hidden by blanket masks or called equivalent from an attract-only test.
  If meeting the handling/event acceptance criteria requires changing native gameplay,
  bring the concrete discrepancy back for a scope decision before shipping that change.

Phase 6 therefore needs both same-configuration comparisons of the original and converted
simulation and explicit start/contact/modal coverage. Match starting state, input schedule,
native six-field decision boundaries and event phase; report all remaining differences and
set justified tolerances before accepting handling results. The planned same-period
cross-machine core comparison is a diagnostic, not an assertion that the native game is
already identical across CPUs. Full laps, human steering, crashes/spins and pit service
remain implementation acceptance tests, not completed Phase 4 evidence.

#### Review evidence and stop point

- The 100 MHz result repeats from a fresh boot: all 1,000 per-field publication counts,
  metadata, complete `$E544` code and allocated `$9364` data agree at both boundaries.
  The full 4 MB dumps differ in 156 bytes at each boundary, all below the game code;
  every difference is retained in `review.json`. This is game-hunk/count reproducibility,
  not whole-machine or screenshot equality. The 50 MHz figure is a single boot.
- All three new captures pass the original-code, 13 inherited JOTD patches and 139-stub
  checks after restoring exact VERIFY spans; corrupting the swap instruction is rejected.
  The retained normal/VERIFY hashes still match the Phase 3 hashes above. All 55 pristine
  files match their manifest. Only this plan and `GAME_TIME.md` change in the repository;
  no rebuild was necessary for this documentation-only review.
- Local evidence is `tmp/dev/tmp/phase4/{68030-50-1,68030-100-1,68030-100-2}` plus
  `review.json`/`review.txt`. Captures retain the slave, metadata, debugger counts, boundary
  RAM and emulator logs. `tmp/dev/tools/review_phase4.py` checks the repeat and computes
  exact rates; reproduction commands are in `tmp/dev/docs/development.md`.
- Phase 4 is complete under the existing performance-only scope. This review introduced
  no performance patches; Phase 5 below covers the horizon repair and blitter option.

### Phase 5 — Cheap wins (complete)

#### Implementation and causal check

The horizon fault is confirmed on the expanded A1200. The matched original-swap trace
contains 1,216 writes to displayed words before their bitplane fetch, 482 of which change
the word's previous value. Three screenshot pairs change the horizon while the displayed
bitplane set remains the same. This is visible drawing into the front buffer, not merely
a delayed publication counter. Earlier Phase 2 evidence independently shows the same fault.

The native swap changes the View/RastPort pairs at `$372`, calls LoadView at `$39e`, and
selects the old display RastPort through `$cf04`. LoadView schedules the next copper list;
it does not make that old bitmap immediately safe to overwrite. The fix records the native
VBL count after LoadView and waits for a field boundary before reuse. For the race caller
at `$a8ee`, geometry preparation may run first; the fence is just before the sky clear and
horizon blits at `$818c`. If a complete VBL has already passed, there is no wait. Other
swap callers wait immediately. Pause and race-exit paths drain a pending handoff before
their modal drawing or cleanup. The native counter advances even while paused.

| v1 patch | Replacement contract |
|---|---|
| `$39e..$3a4` | Jump to swap tail; execute the original C LoadView call with its stacked argument, remove that argument, fence/defer, then unwind the original LINK frame and return. |
| `$818c..$8192` | Resolve pending handoff, then replay `move.w #72,-30606(a4)` before any race bitmap writes. |
| `$7094..$709a` | Resolve handoff if entering pause; replay the original comparison and its condition codes. |
| `$75c8..$75ce` | Resolve handoff before leaving the race; replay the original sound-stop argument/call. |

The initial unconditional WaitTOF prototype measured 5.36 fps on A500, outside the 0.15 fps
allowance. Deferring only the race fence overlaps the remaining display field with pure
geometry work and preserves the A500 rate. The prototype remains a local diagnostic;
accepted comparisons use the final deferred implementation only.

`render_interrupt_option` / `render_interrupt_restore` are copied unchanged from TD2's
`render.s`, using its bit-1 option representation. Only the size-identified v1 path enables
that bit when CUSTOM2 is selected. The slave calls the helpers around the program entry:
BLTPRI is enabled, the unused BLIT interrupt is disabled, and saved enable bits are restored
on normal return. Existing song, protection and CPU patches remain; unknown executable
sizes follow the inherited path without these display/performance patches. The normal
slave exposes only `C2:B:Enhanced framerate`; no icon default is changed.

VERIFY-only `CUSTOM4` is now a bit field: bit 0 retains slow drawing, bit 1 bypasses all
four display hooks for a matched original-swap control. Thus `CUSTOM4=2` does not also
activate slow drawing. All comparison arms use one identical final VERIFY binary.

#### Measurements and validation

The original/fixed/enhanced arms use CUSTOM2/CUSTOM4 = 0/2, 0/0 and 1/0. All have
CUSTOM1=0, CUSTOM3=1 and CUSTOM5=1, the first-race anchor, 300 warm-up fields and 1,000
counted PAL fields. There are two fresh boots per arm per CPU. The separate 100-field
instruction/DMA traces prove buffer ownership and interrupt behavior; their short-window
fps must not be substituted for the longer measurements.

| Machine (unchanged cache policy) | Original swap | Fixed, CUSTOM2=0 | Fixed, CUSTOM2=1 |
|---|---:|---:|---:|
| A500, 68000, 512 KB chip + 1536 KB slow | 5.6402 fps | 5.6281 fps | 6.1809 fps |
| Expanded A1200, 68EC020, 2 MB chip + 4 MB fast | 14.5015 fps | 12.7767 fps | 14.7295 fps |
| A1200, 68030/25, 2 MB chip + 4 MB fast | 24.6994 fps | 21.4715 fps | 23.8477 fps |

Each figure repeats exactly: all nine boot pairs match all 1,000 per-field counts,
metadata, complete game code and allocated game data at both boundaries. Differences in
RAM outside those hunks are reported in the local review, not masked as whole-machine
identity. The same-build original controls are the reference here, rather than older
VERIFY layouts. Rates use 50 times completed publication intervals divided by the
first-to-last-publication field span; this is nominal PAL, not host wall time.

The A500 fix costs 0.0121 fps, within the ±0.15 fps allowance. Relative to the corrected
CUSTOM2=0 baseline, the blitter option gains 0.5528 / 1.9528 / 2.3762 fps on 000 / 020 /
030: all exceed that allowance. Relative to the unsafe original, the complete enhanced
path gains 0.5407 / 0.2279 fps on 000 / 020 but **loses 0.8517 fps on 030/25**. The safe
handoff cost on faster CPUs is real; this is not an across-the-board speedup claim. No
cache policy, CPU frequency or simulation cadence is changed to hide it.

On both A500 and expanded A1200, all four fixed/enhanced 100-field traces contain **zero
writes to any bitmap word fetched for display in that field**, and zero horizon changes
between screenshots with the same displayed buffer. Each publication maps to the other
bitplane set on the following field. All 100 native VBL callbacks remain present. Actual
DMACONR/INTENAR reads confirm BLTPRI off / BLIT IRQ enabled with CUSTOM2=0, and BLTPRI on /
BLIT IRQ disabled with CUSTOM2=1. On 020 the blitter-finished IRQ count changes from 4,664
to zero, while vertical blank stays at 100; audio DMA and level-4 audio interrupts remain.

No simulation period, rate, clock or collision/start policy changes are implemented.
Faster drawing and corrected handoff timing can still move the native drawing-dependent
start/contact events described in Phase 4; the frame-rate comparison is not a new claim
of cross-CPU handling equivalence. Hardware validation remains Phase 8.

#### Checks, artifacts and stop point

- All 18 performance captures pass exact original-code checks after restoring only the
  four named display hooks and enabled VERIFY spans. The 6/13 inherited JOTD patches and
  all 139 jump stubs remain intact; corrupting the swap instruction is rejected. The
  12-span instruction-boundary/direct-branch audit passes. The normal 000 and 020 runtime
  images also pass the byte checks without any VERIFY exemptions.
- Normal-build intro/attract smoke runs pass on A500 with CUSTOM2=0 and expanded A1200
  with CUSTOM2=1. Both reach the native attract-race exit; the pending handoff changes
  from 1 to 0 there after the recorded swap field has elapsed. Pause-branch and normal
  program-return restoration are statically reviewed, not claimed as played-through
  tests. An attempted debugger-write stimulus was rejected: Barto ignores memory and
  register writes, and the pause flag read back unchanged. Those probe records are
  explicitly excluded; no synthetic pause or restoration pass is claimed.
- Both vasm targets rebuild byte-identically to the binaries used for these checks.
  Normal SHA-256: `b1f05dba337f2fca1984d0566488ef5eb82b15ce0ac38b69d149c37856a5b1ca`.
  VERIFY SHA-256: `5101619760a61d0340130d8e31c50790ae37b594c7d42cdce0b9d2e8c42f9058`.
  All 55 pristine files retain their manifest hashes. No game bytes, generated binaries,
  captures or harness files are tracked. ReadMe and both Makefile dependencies are updated;
  the beta version remains 1.1-beta and the icon default remains unchanged.
- Evidence root: `tmp/dev/tmp/phase5/`. The `{a500,a1200,68030}-{original,fixed,enhanced}-{1,2}`
  directories contain full boundary RAM, metadata, retained slaves, exact field counts and
  emulator/debugger logs. `trace-*` contains the 100-field traces, DMA/pixel-word audit,
  screenshot stability audit and register/IRQ evidence. `normal-*` contains normal-build
  screenshots, read-only debugger transcripts and native-exit results. `review.json`,
  `review.txt`, `byte-checks.txt`, build logs and `REJECTED.txt` delimit accepted evidence.
  Reproduction is in `tmp/dev/docs/development.md` (`phase5_matrix.py`,
  `review_phase5.py`, `phase5_lifecycle.py` and the audit tools).
- These are whole-game fixed-window measurements, not isolated renderer benchmarks:
  native drawing-dependent start/contact sampling can change the scene reached in the
  window. No full human-handling/pit matrix or hardware result is claimed at this phase.
  Phase 5 is complete; the authorised Phase 6 work is described below.

### Phase 6 — Higher simulation rate (complete)
1. Period word -29926 (and the initial -29928) → `sim_p` per CPU (6 on 68000/010, 2 on
   68020+; 1 only after Phase 4 shows 50 fps is reachable), set in a `sim_configure` like
   TD2's (AttnFlags before PatchSeg).
2. Port TD2's `simulation.s` helpers unchanged: `sim_scale_long` (divide by `sim_n` with a
   private fractional carry), Euler correction, force reference, `sim_relax` n-th roots.
   Apply them to each rate found in Phase 3 (player, 10 AI cars at `a2c4..`, clock).
3. Keep discrete counters at the original 6-field cadence (TD2 rule: gears, timers, AI
   decisions). Use the Phase 4 clock/statistics policy: retain native six-field units and
   sampling; do not correct the slow PAL clock to real time.
4. Interrupt-safe latch: guard `a6ea` (Disable or double-read) so a step never lands mid-copy.
5. Crashes, spins, pit stops and penalties keep their original logic and timing; only their
   per-step rates are scaled, so they cost the same game time as in the original.
6. VERIFY: assertions on the helpers (reuse `simulation-verify.s` structure), scripted tape,
   forced events; handling table (same tape, period 6 vs 2: lap times and positions within
   a stated tolerance); `compare_state --assert-core` between same-period machines;
   byte checks prove `CUSTOM2=0` leaves original simulation/optional-render bytes, allowing
   only the named always-on Phase 5 display hooks and inherited JOTD patches.

**Status: complete.** The implementation and final acceptance checks pass.

The size-checked v1 uses period 6 on 68000/010 and period 2 on 68020+ when
`CUSTOM2=1`. A500 keeps its native physics instructions. The initial countdown and
period, and subsequent new-race resets, agree. There is no period-1 or cache change.
The five TD2 arithmetic kernels are unchanged; GPC-specific wrappers retain native
clock/statistics units and six-field discrete decisions. Player input and gears
stay on the native boundary. Internal AI target/lane/cooldown decisions sample at
the first fine step, before positions advance, while close-gap decisions stay on
the ending native boundary. The protected render snapshot uses balanced Exec
Disable/Enable. `GAME_TIME.md` describes the rates, impulses and calling contracts.

Player torque/drag hold the native interval-start reference; active steering uses
the third root of the original feedback map. Spatial centering remains at actual
segment crossings, and spin accumulates crossings for the native boundary. Player
motion retains its old-speed Euler correction. Gear completion remains a once-only
impulse and suppresses the remaining fine-step engine forces in that interval.
New-race setup holds simulation until the existing initialization release; pit
return preserves phase, carries and countdown.

Acceptance bounds were recorded before full replay: both laps undamaged, lap time
within 1%, matched-field distance within 11.84 segments (1% of the 1,184-segment
track), and lateral difference within 280 units (one quarter of the road half-width).
The short tape requires final distance within one segment, exact gear fields and
clock cadence. Traffic requires each car within 11.84 segments, with lane differences
reported. Coast-down must stop within six fields and one segment; pause fields and
native pit service-time units must match. Same-period cross-CPU solo core must match exactly.
These are emulator regression bounds, not hardware or all-circuits coverage.

Final acceptance evidence in ignored `tmp/dev/tmp/phase6/`:

- `matrix-v5-native` versus `matrix-v5-p6`: all named core values match over 720
  fields, including clock, counters, input, player and all ten AI slots.
- `matrix-v5-p6/p2`: short-tape distance error 0.95703125 segment; gear changes at
  fields 618 and 684 and the clock cadence match exactly; both conditions remain 320.
- `matrix-v5-traffic-p6/p2`: identical initial grid, speeds, lanes and RNG. Maximum
  position differences for slots 0–9 are 1, 1.44140625, 0.83984375, 0.8125,
  1.90234375, 2.37890625, 2.125, 0.8125, 2.5859375 and 0.65234375 segments.
  Slot 2 finishes one 80-unit lane step apart (-240/-320); the other nine final
  lanes match. Intermediate lane differences are retained in `final-handling.json`.
- `events-v5-*`: overheat, damaged-engine coast, spin and neutral coast stop within
  2/4/4/2 fields and 0.03515625/0.05859375/0.21875/0.01171875 segment respectively.
  Spin lasts 48 fields in both runs; Ctrl-P pauses exactly fields 180–239. Both
  off-road runs take three native damage events and finish at condition 317.
- Pit entry, service and service-exit markers match; elapsed-fields/6 is 52 in both,
  and repair reaches condition 240. Native race-screen redraw resumes period 2 one
  video field earlier (marker 978 versus 979). This presentation latency is reported,
  not treated as identical wall-field timing: `$7240` draws before `$7250` unpauses.
  At equal post-return active times, 220 observations match exactly for active-field
  count, lap/race clocks, condition, speed, gear, lateral position and pit/go flags.
  Both clocks reach 120 ticks at the capture end. See `final-events.json`.
- `core-a500-p6` and `core-030-p6` match `matrix-v5-p6` exactly at all 720
  sampled fields; `core-030-p2` likewise matches `matrix-v5-p2`. Comparisons retain
  all named player/AI, clock, input and event fields, including inactive AI literals.
- Normal and tape VERIFY rebuild byte-identically in a separate output directory;
  ordinary VERIFY also builds without the private tape include. Normal SHA-256:
  `dd66178176e92f7c16215d24cbb7c0637df0081f4651d731f7cd80e255095829`;
  tape VERIFY: `b6b6193749d4ba81428fce4244a1bbac4718f67a6329d0ea38d0abbe7aba54f8`.
- Normal-build A500 `CUSTOM2=0` and expanded A1200 `CUSTOM2=1` both boot through
  the intro and attract race and reach the native race exit. Intro/race screenshots
  were visually inspected. Both clear the pending handoff from 1 to 0 at exit;
  their runtime code passes the exact byte/JOTD/stub checks and negative control.
  These are boot/exit smoke checks, not performance or human-input measurements.
- All 29 final VERIFY captures pass 51 private guest assertions. The
  code audit checks 58,628 immutable bytes, 13 inherited 020 patches and 139 stubs,
  with a corrupted-instruction negative control. All 51 hook boundaries and direct
  branch entries pass the static audit. All 55 pristine file hashes still match.
- `lap-final-p6/p2` replay the same unretimed joystick recording through a full
  human-code lap. Both finish undamaged. Against the original pilot recording,
  the period-6 replay matches every named core value at all 1,450 shared native
  fields (1 through 8,695). The pilot stops at field 8,700; the sparse replay's
  next observation is 8,701. Those unmatched endpoints are explicitly reported,
  not paired or masked. Both have the same 1,449-tick completed lap.

| Final raw-tape handling check | Period 6 | Period 2 | Acceptance |
|---|---:|---:|---|
| Completed lap ticks | 1,449 | 1,450 | Difference 0.069%, limit 1% |
| Condition at finish | 320 | 320 | Both undamaged |
| Maximum matched-field distance difference | — | 0.5859375 segment | Limit 11.84 |
| Maximum matched-field lateral difference | — | 222 units | Limit 280 |
| Shared observations | 1,451 | 1,451 | Same native fields |

`lap-final-p2/lap-comparison.json` and `lap-final-native-oracle.json` retain the
results and sampling coverage. `completion-capture-audit.json` checks all 29
VERIFY captures against the final binary and 51/0 assertion result, both normal
build hashes/exits, and every acceptance report.

Rejected diagnostics remain separate in ignored harness storage; no acceptance
bound was widened. Final captures retain their exact slaves, listings, options,
RAM, input/state records and debugger/emulator logs. Reproduction commands and
transport-failure exclusions are documented in `tmp/dev/docs/development.md`.

Timing evidence (`cost-020-p6/p2`, 100 fields each, populated
traffic and human-input fixture; unchanged cache policy):

| Expanded A1200 callback | Forced period 6 | Selected period 2 |
|---|---:|---:|
| Stepped callback mean / sampled maximum, CPU cycles | 26,952 / 30,043 | 25,606 / 27,477 |
| Light callback mean / sampled maximum, CPU cycles | 419 / 443 | 384 / 443 |
| Callback share at selected period, mean / sampled maximum projection | 1.70% / 1.89% | 4.57% / 4.91% |
| Maximum complete protected copy, CPU cycles | 1,107 | 1,107 |
| Maximum inclusive Disable/copy/Enable latch, CPU cycles | 1,522 | 1,524 |

Both traces contain 100 native callbacks, 25 complete protected copies with no
foreign instruction inside, and zero CPU/blitter writes to any word fetched for
display. Both short windows publish at 12.5 fps. Callback figures include callees,
exclude outer interrupt dispatch/audio, and are sampled costs rather than worst-case
bounds. The higher simulation rate is not a claim of higher rendered frame rate.
The A500 period-6 trace also has 100 native callbacks, ten complete protected copies
and zero display writes. Its stepped callback mean/maximum is 31,914/33,154 cycles,
light callback 667/680, giving a 4.13%/4.29% selected-period share projection.
The protected copy peaks at 2,688 cycles. Inclusive latch maximum is 67,204 cycles:
that includes pending interrupt work after Enable, not 67,204 cycles with interrupts
disabled. Native simulation instruction bytes remain intact on A500.

The period-2 overheat/spin traffic traces each retain all 100 native callbacks and
zero displayed-bitmap writes. Their callback mean/maximum is 26,475/28,217 and
26,390/28,977 cycles, giving selected-period mean/maximum share projections of
4.73%/5.04% and 4.71%/5.18%. Their 23/25 complete copies contain no foreign PC;
copy maximum is 1,107 cycles and inclusive latch maxima are 1,509/1,520. Across all
five traces, 108 complete copies pass and no display write occurs in 500 fields.
These costs support the chosen period 6/2 policy; period 1 remains disabled.
`final-cost-display.json` retains the complete measurements.

Phase 6 validation is complete. The beta version and icon default are unchanged;
hardware/release work remains Phase 8.

### Phase 7 — Sub-unit rendering
**Status: complete.** All new production hooks are C2-gated and apply only to the size-checked v1 game. `render-subunit.s`
uses the existing protected render latch for camera fraction, lateral position,
yaw and horizon/scenery heading. Table preparation runs after `Enable`, outside
the interrupt exclusion, and never writes live physics state.

The low byte of latched camera position `-30006(a4)` drives main/mirror road
projection, partial integration intervals and row-transition maps used by stripe
phase at `$84b2`. Canonical tables are copied from the loaded game once; every
fraction is calculated from those originals, never cumulatively. Only main Y
indices 2–8 and mirror indices 2–3 can change at sub-segment resolution. Updating
those nine boundaries and their affected row maps keeps the A500 cost down.
The native far projection-selection list stays intact, including its intentional
choice of an earlier duplicate row. An exact fraction cache avoids repeated work.
Native `$2b5e` rebuilds mirror/row tables for each new race. The C2 hook at `$9ee`
restores canonical main/mirror/length inputs before that initializer and invalidates
the projected fraction, preventing shifted tables from becoming the next race's
baseline.

Front cars already form full relative Q8 depth at `$8f50`; retain it before the
native eighth-segment reduction, then interpolate the canonical near/far Y tables.
Using the camera-shifted road tables here would subtract camera fraction twice.
Mirror cars use camera-minus-car Q8 directly, without the roadside walker's
one-segment adjustment. Native sprite-family/size selection remains discrete.
Signed Q8 road angles interpolate the original odd lookup table; exact integer
angles retain the native lookup. A signed word table derived from the original
odd byte table gives bounded-cost interpolation without cache misses.
Horizon and scenery use the same latched heading as the road, without prediction.
The panorama already shifts heading by 6 bits at `$821a`, finer than the road's
old 8-bit lookup. The segment curve is added to both accumulated curve (`$79a0`)
and yaw (`$7a76`), cancelling in their difference; no extra camera-fraction curve
offset is added to that native panorama calculation.

Temporal interpolation is conditional on rendering faster than physics. The
measured profiles draw no faster than the selected simulation rate; each checked
draw has at least one intervening physics update. No temporal prediction or extra
simulation delay is introduced. Spatial sub-unit rendering is independent of that
cadence decision. Real hardware and other profiles remain Phase 8 coverage.

Accepted evidence is retained under ignored `tmp/dev/tmp/phase7/`, with final
capture prefix `accepted-` and the three `normal-*` production captures.
`completion-capture-audit.json` binds all 20 VERIFY captures to their exact slave,
source hashes and acceptance gates; older candidates are diagnostic only.

- Four same-build C2=0/1 zero-fraction pairs cover straight, left, right and shallow
  curves with traffic and mirrors. Every one of eight fields per capture has the
  same 40,000 fetched bitmap bytes across all five planes: no crop, tolerance,
  masking or nearest-frame selection. A changed-byte negative control fails the
  same comparator. The frozen fixture sets added camera/AI fractions and angular
  interpolation to zero and holds wheel history; it is VERIFY-only.
- Nonzero fractions 1, 128 and 255 on the right curve, plus 128 on the left curve,
  pass the retained guest-table checks. An independent model exhausts all 256
  projection fractions and all 45,057 clamped signed angles, including negative
  rounding, endpoint bounds and unchanged native projection-selection bytes.
  All 20 captures pass 63 guest assertions with zero failures.
- All named player/AI, input, clock and event fields match Phase 6 exactly at each
  of 720 native-field observations on all four regression runs. Read-only latch
  observations show at least one physics update per draw on these profiles:

| Profile | Render latches | Fields between draws | Physics updates between draws |
|---|---:|---|---|
| A500 / period 6 | 83 | 8, 9, 10 | 1, 2 |
| 68EC020 / period 2 | 196 | 3, 4 | 1, 2 |
| 68030 25 MHz / period 2 | 330 | 2, 3 | 1, 2 |
| 68EC020 traffic / period 2 | 178 | 4, 5 | 2, 3 |

The A500 budget uses four 100-field windows from the original human joystick
recording, including moving traffic. These count the entire new per-frame helper
range, including replacement native work and VERIFY overhead; no native cost is
subtracted, and this is not an FPS improvement claim. All pass a 3.0% gate:

| A500 window | Helper cycles | Share of all CPU cycles |
|---|---:|---:|
| Solo, skip 2,000 | 394,530 | 2.776% |
| Solo, skip 4,000 | 392,544 | 2.762% |
| Solo, skip 6,000 | 394,420 | 2.776% |
| Traffic, skip 2,000 | 370,780 | 2.609% |

- All 16 final bitmap traces have zero writes to the displayed buffer. The four
  moving traces contain 55 complete native snapshot copies with no foreign PC
  during the protected copy, regardless of interrupt-vector location.
- Normal A500 C2=0/1 and A1200 C2=1 builds boot through the intro and race and drain
  the pending display handoff at native race exit. Both C2-on second-race checks
  start with 48 shifted table words (camera fractions 160 and 182), verify all
  102 canonical words restored and the fraction invalidated, then render 40 more
  swaps. Their second-race tables match the model; intro/race images were inspected.
- Exact runtime code/gating audits preserve inherited JOTD patches and all 139
  jump stubs, with corrupted-code negative controls. All 64 hook boundaries and
  direct branch entries pass. All 55 pristine input hashes remain unchanged.
- Normal and tape VERIFY builds reproduce byte-for-byte in separate output
  directories; ordinary VERIFY also builds without the private tape input. The
  normal build excludes test fixtures and assertion routines. Normal SHA-256:
  `e0765e5035febd4a9a928b440a966d2742c987528b0d7221ec256390f7aeec81`;
  tape VERIFY: `470af2952c6d336c39a95c8dd30db68c3101be031bf8cc9395bdb7f7db08f2e0`.

This establishes the stated emulator coverage, not all-circuit or hardware
handling equivalence. The 030 backend supplies state/cadence observations but no
CPU instruction trace; no 030 cycle-cost claim is made.

### Phase 8 — Hardware, release, upstream
1. Real/MMU runs (68040 with MMU, JIT off). The owner waived further WHDLoad-version testing during hardware acceptance.
2. ReadMe history, `DECL_VERSION`, icon tooltype `CUSTOM2=1`, slv_config entry.
3. Adapt `package_release.py`; focused commits on `grandprixcircuit`; PR via Vesuri.
4. Generic lessons (interrupt-driven simulation, LoadView swap marker) → AmigaXDev docs.

Release candidate: **1.1-beta2**. Physical testing is assigned to the owner on an
A1200 / 68040 at 40 MHz / MMU / 32 MB / WHDLoad 19.x. The owner reports good
framerate and correct-feeling gameplay. The same hardware test found intermittent
missing intro-music notes, stepped horizon motion, and jumpy roadside placement.
The beta2 follow-ups below address those findings; physical confirmation of the
new candidate is pending. This is not unconditional hardware acceptance. Wider circuit, car and traffic coverage remains unestablished.

Further WHDLoad-version testing was stopped at the owner's request. Completed normal
runs cover A500 17.2 C2=0/1 and 68040/MMU 20.0 C2=1 plus 17.2 C2=0. The in-progress
17.2 MMU C2=1 run was cancelled and is not acceptance evidence. The 20.0 MMU run
passed two races, all 102 canonical table-word restorations, exact code/stub/table
audits and positive TC=8000 translation evidence with JIT off. There is no timing
claim from the MMU run.

Release preparation:
- `DECL_VERSION` is `1.1-beta2`; `slv_config` exposes only the normal C2 option.
  The ReadMe now includes fractional presentation and the between-race table reset,
  documents the off path, and preserves JOTD's original history.
- Corrected the normal runtime minimum to **WHDLoad 17.2**: `PL_IFC2` uses the
  conditional patch commands introduced in 17.2. The slave interface remains 17.
  The earlier Phase 1 minimum statement applied before normal C2 patches existed.
- The installer icon gains `CUSTOM2=1`. It previously had no tooltype table;
  only that table and its pointer change, with both planar images and the trailing
  colour-icon chunk byte-identical. The installer already supplies Slave/PreLoad
  and the WHDLoad default tool. The preinstalled game icon gains the same option;
  its other tooltypes, imagery and enclosing drawer icon are preserved.
- Adapted TD2's packager as local `tmp/dev/tools/package_release.py`. Installer and
  preinstalled inputs remain immutable; outputs are local in `tmp/dev/dist/`.
  The installer has 21 files (the obsolete `.asm` source becomes authoritative `.s`,
  with all modules, both build recipes and design notes); the preinstalled archive
  retains exactly 55 files. Only the declared slave/ReadMe/icon/source members
  change. LH5 level-1 archives pass extraction, complete member/hash comparisons,
  and byte-exact normal rebuilding from extracted source; ordinary VERIFY also
  builds without the private tape. The Makefile uses the documented external
  WHDLoad SDK and NDK; this is not a self-contained SDK distribution.
- The first hardware-tested candidate was the Phase 7 normal build
  (`e0765e5035febd4a9a928b440a966d2742c987528b0d7221ec256390f7aeec81`). Beta2
  includes the corrections below. No VERIFY configuration or marker appears in
  the normal build. All 55 pristine input hashes still match.
- Shared lessons are in AmigaXDev `docs/playbooks/simulation-and-presentation.md`,
  commit `39978a5`: interrupt-owned simulation, protected short snapshots,
  LoadView publication versus DMA retirement, and projection-table lifecycle.

Hardware-report follow-ups in beta2:
- **Music:** all three song files contain the same driver. At song `$8c8`, the
  original branch acknowledged a channel even when its bit was absent from the
  entry INTREQR snapshot. Another channel can request service during the existing
  DMA wait, then lose that request at this branch. The branch now returns without
  acknowledging an unsampled request. The `$926` acknowledgement hook also reads
  INTREQR back after writing INTREQ, before returning on a fast CPU. Existing DMA
  waits remain unchanged. An exhaustive 1,024-case four-channel mask model exposes
  lost unsampled requests in the original and preserves them with the correction.
  This establishes the bug, not that it is the sole cause of the reported notes.
- **Horizon/scenery heading:** Phase 7 retained a segment-stepped steering input.
  Native yaw gains half the effective steering plus curve at a crossing, while
  accumulated heading gains the same curve. The curve still cancels; beta2 carries
  the held steering contribution through the partial segment. It copies one extra
  word inside the existing protected latch, respects the native outward-yaw clamp,
  and refreshes the heading even on a projection-table cache hit. It changes only
  presentation, without moving the simulation or adding a frame of latency.
- **Roadside placement:** the original horizontal perspective, road-width and
  shoulder lookups used the already-rounded screen Y. Beta2 interpolates those
  three canonical coefficients at Q8 depth, sharing the result between road edges
  and roadside objects. Mirror interpolation retains the native lookups for the
  unused far entries visited by its shared selection list. Sprite size selection
  and clipping remain discrete. The new hooks apply with C2 on 68020+; an initial
  A500 prototype consumed 6.12% of total CPU cycles in all rendering helpers, above
  the Phase 7 3% gate, so the A500 retains its cheaper horizontal projection.
  The lightweight fractional heading correction remains enabled there.
- The independent coefficient model checks 43,176 fractional vectors and endpoints.
  For a centred nearby roadside object, one-Q8-unit camera increments produce a
  maximum two-pixel horizontal shoulder step versus ten pixels with early rounding.
  This is a coefficient example, not a displayed-frame or all-scene smoothness claim.

Beta2 emulator acceptance is complete. Evidence is retained under
`tmp/dev/tmp/phase8/beta2-*` and `normal-*-beta2`; earlier `followup-*` captures are
development evidence, not the release acceptance set.
- All **81 guest arithmetic assertions** pass. The normal 020 projection path has
  an exact five-plane, 40,000-byte zero-fraction bitmap oracle with a changed-byte
  negative control, plus half-fraction and moving-scene coefficient/heading audits.
- Five rendering traces cover **236 fields**, with zero displayed-buffer writes.
  The moving 000/020 traces contain **48 protected copies**, with no foreign PC.
  Exact code/gating audits preserve the inherited patches and all 139 overlay stubs;
  all **72 hook spans** and their direct branch entries pass the static audit.
- A **720-field / 360-step** same-period 020 comparison against the accepted Phase 7
  build has no named gameplay-state differences. This is the retained solo window,
  not an all-circuit or traffic handling claim.
- A500 rendering helpers cost **2.765%** of total CPU cycles in the 100-field human
  driving window, within the 3% gate. The analogous 020 window costs **3.679%**.
  These include replacement native work and VERIFY overhead, and are not FPS gains.
- Normal A500 and 68040/MMU builds pass intro, race, native race exit, and second
  race. Both restore all **102 canonical table words**, invalidate the fraction,
  and render 40 further swaps. The 040 log confirms **TC=8000 enabled=1**, with
  CPU/MMU 68040 and JIT off. Code/table/music audits pass on both normal builds.
  These runs use the existing WHDLoad 20.0 harness runtime; no version matrix was
  resumed. Pause/Workbench return remain static review, not newly executed tests.
- A 100-field normal A500 intro trace exercises **157 serviced acknowledgements**
  and **471 unsampled-channel returns without acknowledgement**. Observed Paula
  period writes range from 124 to 719, within the existing DMA wait's timing range.
  This observation is limited to that captured music passage; physical missing-note
  resolution remains unconfirmed.
- Normal SHA-256:
  `1825971543c888a99a1dec5abd0959b94719bf5ef3bca6c3cdb4c628e9aefb3c`.
  Tape VERIFY SHA-256:
  `3406083eb45cafc49942476d1d94fbcf68efd7ea22081d77e855dd41faa5b17a`.

`beta2-render-audit.json` and `beta2-normal-audit.json` bind these checks to their
retained binaries; `music-trace.json` is inside the normal A500 capture.
`runtime-manifest.json` pins the retained WHDLoad inputs; `package/report.json`
records the full archive manifests. Both installer and private preinstalled beta2
archives are rebuilt locally; the installer source rebuilds the identical normal
slave and ordinary VERIFY without the private tape. All 55 input hashes match.
No further version matrix is required. The contribution remains a beta/draft
pending the owner's focused recheck of intro notes, horizon motion and roadside
placement on the same A1200/WHDLoad 19 setup.

## Open questions
- Attract capture window/publication counter are validated in Phase 2. Phase 6
  establishes exact same-period solo core on the tested 68000/020/030 profiles and
  bounds higher-rate handling on the recorded circuit; it does not establish
  all-circuit or hardware equivalence.
- Clock policy resolved in Phase 4: preserve lap/race ticks at -31424/-31416 and the
  original PAL rate; no wall-time correction.
- Phase 3 maps pause/pit/terminal gates and drawing-dependent starts/collisions in
  `GAME_TIME.md`. Phase 4 retains their native logic; any correction requires a separate
  gameplay decision. Phase 6's native-event and recorded human-handling checks pass
  the stated bounds. Drawing-dependent starts/contact remain original limitations;
  the exact cross-CPU solo results must not be generalized to every traffic scene.
- Overlay question resolved for the supplied v1: dormant manager, no stub rewrites (Phase 1 evidence above).
