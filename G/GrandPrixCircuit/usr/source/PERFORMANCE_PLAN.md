# Grand Prix Circuit — performance plan

Goal: give GPC the Test Drive II treatment under one `CUSTOM2` "Enhanced framerate" option:
a higher simulation rate on 68020+, smooth (sub-unit) road and car drawing and blitter
priority, with the original game one option away. Method: AmigaXDev
`docs/playbooks/new-game-playbook-jotd.md`. Reference implementation: `T/TestDrive2/usr/source/`
in this fork (offsets do not carry over) and the standalone Test Drive 2 project (harness,
tools, docs). The local harness lives in the worktree's ignored `tmp/dev/`.

## Decisions

- `CUSTOM2` "Enhanced framerate" bundles every performance change; `CUSTOM2=0` is the original.
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
  retargets drawing to the buffer just shown → probable tearing on fast CPUs).
- Player track position: segment pointer -30016, 8-bit in-segment fraction low byte of
  -30012 (h0:7e2c–7e46). The analogue of TD2's camera fraction F.
- Road renderer: per-scanline span lists, 110 rows (loop end h0:8508), stripe phase from the
  latched integer camera at h0:84b2.
- Rebuilt slave (1.1-beta): interface 17, kick13, own LoadSeg; the 94,708-byte executable
  selects `resload_PatchSeg`, other sizes retain JOTD's `resload_Patch` path. The lists
  keep the original busy loop `PL_PS $174`, protection skips, 68010 `move sr`, and song
  INTREQ/DMACON patches. Empty `slv_config` reserves the structure without advertising an
  unimplemented option. `CUSTOM2` currently has no effect. The vasm Makefile builds normal
  and VERIFY outputs separately; Phase 2 adds VERIFY-only RNG/input instruments. The normal
  build remains byte-identical to Phase 1.

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
  ignored. The blinking horizon remains a Phase 5 issue.

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
- Phase 4 is complete under the existing performance-only scope. No Phase 5 patch has
  started. The reported horizon blinking remains to be confirmed and repaired there.

### Phase 5 — Cheap wins (blitter under CUSTOM2, tearing fix always on)
1. Blitter priority + blitter-IRQ suppression (`render.s` `render_interrupt_option`, as-is).
2. Swap tearing: wait for the new view to be live before drawing into the old one
   (WaitTOF/beam wait after LoadView at h0:39e) — the GPC analogue of JOTD's `set_copper`.
   Always on (outside CUSTOM2); first confirm the tearing in a 68020/030 capture, then show
   it gone and the A500 rate unchanged.
   **Check:** fixed-window A/B, two boots per arm, ±0.15 fps noise floor.

### Phase 6 — Higher simulation rate
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
   `check_disabled.py` proves `CUSTOM2=0` leaves the original bytes.

### Phase 7 — Sub-unit rendering
1. Camera fraction: latch -30006 low byte (and the step phase -29932 vs -29930 for
   interpolation between steps, if the step rate stays below the frame rate).
2. Road: feed the fraction into the row projection and the stripe phase at h0:84b2.
3. Cars: interpolate each AI car's 16-bit position (with its byte carry) toward the next.
4. Heading/curve/scenery offsets: as TD2's walker and mountains, if GPC's road has them.
5. Budget: at most ~3% of A500 cycles (TD2 measured 2–2.9%); zero-fraction oracle must be
   byte-identical to CUSTOM2=0 drawing.

### Phase 8 — Hardware, release, upstream
1. Real/MMU runs (68040 with MMU, JIT off), oldest and newest WHDLoad.
2. ReadMe history, `DECL_VERSION`, icon tooltype `CUSTOM2=1`, slv_config entry.
3. Adapt `package_release.py`; focused commits on `grandprixcircuit`; PR via Vesuri.
4. Generic lessons (interrupt-driven simulation, LoadView swap marker) → AmigaXDev docs.

## Open questions
- Attract capture window and publication counter validated in Phase 2; cross-machine
  simulation/handling equivalence is not yet established.
- Clock policy resolved in Phase 4: preserve lap/race ticks at -31424/-31416 and the
  original PAL rate; no wall-time correction.
- Phase 3 maps pause/pit/terminal gates and drawing-dependent starts/collisions in
  `GAME_TIME.md`. Phase 4 retains their native logic; any correction requires a separate
  gameplay decision. Native event coverage and human-handling equivalence remain Phase 6
  requirements; cross-CPU equality cannot be assumed from the fixed VBL cadence.
- Overlay question resolved for the supplied v1: dormant manager, no stub rewrites (Phase 1 evidence above).
