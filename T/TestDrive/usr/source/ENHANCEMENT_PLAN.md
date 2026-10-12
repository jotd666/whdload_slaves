# Test Drive: enhancement plan

Goal: bring Test Drive (1987, Distinctive Software / Accolade) to parity with the Test Drive
II slave in this repository (`T/TestDrive2/usr/source`):

- an always-on fix that flushes the caches after the overlay manager rewrites its stubs;
- an opt-in "Enhanced framerate" option (`CUSTOM2`). Game time runs on a fixed simulation
  period, independently of drawing (25 Hz on a 68020 or better). It also gives the blitter
  bus priority and draws the road and cars at fractional positions;
- the original crash screens, acknowledgement and penalties kept in enhanced mode, as in
  Test Drive II after PR #24. A field-timed recovery exists only as a VERIFY instrument;
- fixes for any original display bugs found along the way (Test Drive II's intro DDFSTOP
  fix is the model);
- `CUSTOM2=0` preserves original gameplay, apart from documented always-on fixes.

The method is AmigaXDev `docs/playbooks/new-game-playbook-jotd.md`. Its §12 "ready to improve"
gate comes before gameplay enhancements; VERIFY-only measurement fixtures establish that gate. Generic lessons go back to AmigaXDev `docs/`.

## What carries over from Test Drive II, and what does not

Test Drive II is a later product from the same studio, and the two executables share their
design. Both are Aztec C `HUNK_OVERLAY` executables run on KickEmu Kickstart 1.3. Both have a
created `Road Drawer` task and `Ticks VBLInt` / `Sfx VBLInt` interrupt servers. Code is
`link a5` / a4-relative.

| | Test Drive (`data/TD`) | Test Drive II (`data/duel` v1) |
|---|---|---|
| File size | 90 112 (one version, JOTD's decrypted executable) | 108 868 |
| Root code hunk | `$7C0C` | `$1156C` |
| Data hunk, file / allocated | `$1E94` / `$32A4` | `$3A38` / `$7A70` |
| Hunk-0 offset → file offset | + `$28` | + `$28` |

A byte match over 12-byte windows found about 3.8 KB of the 31.7 KB root hunk identical to
`duel`: the Aztec runtime, the overlay manager and some library glue. **The overlay stub
rewrites are byte-identical**: the unload rewrite is at `TD:0637E` (duel `0FE7E`) and the load
rewrite at `TD:06908` (duel `0FF0C`). Their exits, confirmed in memory, are `TD:06390`
(`movem.l (a7)+,a2-a3/a6; rts`) and `TD:06916` (`movem.l (a7)+,d0-d2/a0-a4; rts`), the same
instructions TD2's fix displaces at duel `0FE90` / `0FF1A`. The game engine does not byte-match: a4 offsets, the RNG and the
physics differ. Engine knowledge carries over **by structure** (which routine, which task,
which kind of variable), and every offset must be found again. Reuse the method, the tools
and the generic assembly; never reuse a `duel` offset without proving it in `TD`.

Known differences that change the design:

- No opponent car: you race the clock against traffic and the police radar, with gas-station
  stages, a score and a high-score table. TD2's opponent and demo-AI work becomes
  traffic/police/score work.
- Five selectable cars, each with its own data under `data/Cars`: the handling validation has
  to cover all of them, not one.
- The score and the high-score table depend on time and average speed. Clock fixes therefore
  change scores; the high-score file is written into the disposable `DH1:`.
- The slave gives only `$20000` of fast memory (`FASTMEMSIZE`). Private slave memory for caches
  (TD2's tangent cache is 4 KiB) must fit the slave or the existing memory sizes.
- NTSC stays open, as in TD2: validate PAL only and document the NTSC behaviour.
- The ReadMe says the game "flies with fastmem & caches". Whether the game's speed depends on
  the CPU is an open question; §5 decides it with measurements.
- The slave has no `slv_config` options yet and no buffer-swap patch, so the frame marker has
  to be found (§4).
- Source to copy from: the fork's `T/TestDrive2/usr/source` (it includes PR #24 and #25),
  not the standalone Test Drive 2 repository's `whdload/`. Diff the two before copying a
  routine.

## Phase 1: local harness (complete; in `tmp/dev/`, never committed)

1. Runner/debug server: disposable per-launch game copy, worktree-owned emulator and
   debugger, shared environment defaults, pinned runtime inputs checked before use.
   `TD_SETUP=a500|a1200|a1200-030` reproduces TD2's reference settings (512 KiB chip +
   1536 KiB slow; expanded A1200 with 4 MiB fast; 68030/25 MHz). Shared `AMIGA_SETUP`
   presets remain available. Effective launch options are recorded before boot; buffered
   emulator logs are not used to guess RAM sizes at an early breakpoint.
2. Profiler: the installed FS-UAE hash and both setup writes/capture-command reads for
   its PC window are pinned and checked. A short A500 trace contains real instruction PCs.
3. Build: `tools/build.sh` checks the selected compiler/include trees and builds the
   authoritative source into `tmp/build/`; `VERIFY=1` selects the VERIFY output.
   The normal variant remains byte-identical to the 1.5b hardware handoff. The VERIFY
   variant has the phase-4 CUSTOM3 fixture. Bash wrappers work with macOS Bash 3.2.
4. Trace tools: `td_report.py` uses TD's root/data sizes, excludes the PRELOAD root copy
   and follows the loaded BPTR chain. `profile_demo.sh`, `ingame.py`, `frames.py`,
   `swap_fields.py` and `fixed_window.sh` are adapted. Captures retain the exact slave,
   launch settings, RAM and evidence. Fixed captures reject a moved anchor. Phase 4
   supplies the validated first-attract-race anchor, LoadView frame marker and
   overlay-aware reports. Explicit root anchors remain available for diagnostics.
   No TD2 game addresses are silently reused.
5. State tools: `state_fields.py`, `state_writers.py`, `state_report.py`, `state_watch.py`
   and `task_state.py` work on TD captures. The field sampler uses Ticks VBLInt at
   TD:$018BA and checks consecutive counters and a4/a1 against the data hunk. Task
   parsing finds Initial CLI and Road Drawer in a real dump. Writer attribution and
   a live watchpoint corroborate the VBL store.
6. Comparison: `compare_state.py` has a TD-only seven-variable seed map plus full data
   comparison. Two fresh A500 boots at the same VBL window match byte-for-byte across
   all $32A4 data bytes; a different scene differs. Negative controls detect a changed
   non-clock selector and a missing sample. **The full physics/score state map is
   documented in phase 5**, so this seed sampler is harness validation,
   not proof of gameplay determinism.
7. Later-phase `check_*`, simulation audits, sub-unit/sideways tools and the full release
   packager remain deliberately deferred until their features exist. The phase-1
   acceptance checker is `tools/check_harness.py`; the phase-6.1 A/B bundle is preserved.
8. Current local references: `docs/development.md`, `docs/testing.md`,
   `docs/internals.md` and `docs/open-work.md`. Commands and evidence are documented
   there; acceptance artifacts are under ignored `tmp/dev/tmp/phase1/`.

**Acceptance:** the shipped 1.3 and rebuilt 1.5b slaves boot through startup into the
A500 attract/driving sequence from copies of the same pristine drawer. Normal/VERIFY
builds pass, input hashes remain unchanged, and the delivered phase-6.1 fixed slave is
unchanged. The available public archives contain 1.3, not 1.4; the user accepted an
unmodified repository-1.4 rebuild for the separate A/B baseline. No unavailable
shipped-1.4 byte-equivalence claim is made. Phases 3 and 4 supply gameplay and
measurement validation; the phase-5 time model below now defines the simulation design.

## Phase 2: identify the game (complete)

1. Local `docs/internals.md` inventories the slave configuration, all 11 normal patch sites
   plus five VERIFY-only sites, keyboard interrupt and Exec trackdisk hooks. Original instructions,
   replacement behavior and unresolved observations are recorded.
2. Parsed all five hunks and both overlay nodes. The suffix from HUNK_OVERLAY at
   file `$9F2C` is 49,364 bytes including metadata; actual overlay code is 49,220
   bytes. Node 1 exports three entries from hunk 3; node 2 exports twenty from
   hunk 4. The data base is obtained through the loaded root's BPTR chain, and
   a4 is data-base + `$7FFE`.
3. Root and both overlays are disassembled. Confirmed: VBL servers, Road Drawer
   creation in hunk 4, WaitTOF, beam-mixed RNG, overlay manager, road traversal,
   horizontal blitter spans and five-plane shape blitter. Overlay addresses are
   hunk-qualified; 107 data JMP stubs resolve their calls into the root.
4. The presentation marker is validated in phase 4. TD2's exact 52-byte-row/8.8
   road walker and CPU span loop, and several secondary renderer counterparts,
   remain not found. Two drawing passes are present; phase 3 visually confirms
   a rear-view mirror. Timing/state ownership is mapped in phase 5; view-pass geometry
   attribution remains phase 10 work.

**Acceptance:** local `tools/identify_game.py` checks pinned inputs, all explicit
patch signatures/source coverage, hunk sizes, root JMP targets and both overlay
node/export lists. Evidence is under ignored `tmp/dev/tmp/phase2/`. Every requested
routine family has an evidenced TD location or an explicit not-found entry in
the local inventory. Performance measurements are recorded separately in phase 4.

## Phase 3: first boot and traces with PCs (complete)

1. Windowed real-speed PAL A500 boot, using rebuilt 1.5b and the disposable game
   drawer. All five cars were selected and driven through native keyboard events.
   Acceleration, shifting and steering were observed; read-only state corroborates
   the screenshots. Porsche wall-crash acknowledgement restores the intact cockpit.
2. A Ferrari first-stage route reached a radar pursuit, braking to zero speed,
   the speeding-ticket screen and return to driving. It then reached Don's
   Gas-O-Rama; fire continued to stage 2. No persistent visual defect was observed
   in the inspected startup, car/cockpit, crash/recovery, ticket or station screens.
   Partial draws and the station's scrolling text were checked against settled views.
3. `td.py serve` attached at reset within the stub's 20-second window. Startup and
   driving traces contain instruction PCs. The native-input diagnostic build's
   three-field driving trace contains 8,939 / 9,456 / 9,154 instruction PCs.
4. Leaving the game untouched repeats car introductions, a driving demo and the
   logo sequence. The local demo-capture wrapper documents that diagnostic route.
   A bounded native-keyboard helper also logs player routes, reading telemetry
   without writing game state. No host accessibility or window input is used.

**Acceptance:** local `docs/phase3.md` identifies the screenshots, state captures,
input logs, exact slave/configuration and pinned diagnostic emulator. Pristine
inputs and the phase-6.1 slave remain unchanged. The cockpit includes a working
rear-view mirror; attribution of the two renderer passes remains analysis work.
These are gameplay/trace checks, not a deterministic FPS benchmark. The frame
marker and fixed race window are validated in phase 4; the timing model is established in phase 5.

## Phase 4: frame counter, fixed window, baseline — complete

1. **Publication marker:** TD:$7AAA, the LoadView wrapper called by h3:$175E from
   Road Drawer h4:$C0E. The two Views alternate; every measured A500/A1200 publication
   is followed by the next field's bitplane DMA from the selected buffer. Screenshots
   confirm the displayed race. `frames.py` and `swap_fields.py` use this marker, and
   their 100-field patterns agree exactly. Menu LoadView calls are not gameplay FPS.
2. **Fixed window:** first h4:$F6 since reset, before the physics deadline copies the
   VBL counter, then 100 fields. This is the first attract race (stage 3), using the
   game's demo controls. Captures verify the anchor, mode, stage, car parameter and
   seed. `fixed_window.sh` defaults to the pinned fixture and rejects uncalibrated inputs.
3. **Necessary VERIFY fixture:** CUSTOM3 removes the RNG's beam operand, fixes its
   initial seed, and resets the seed at the demo-car selection call. Intro RNG call
   counts differ across CPUs, so removing the beam alone is insufficient. All three
   presets now start with Porsche index 0 and seed $1DC9. This small part of phase 7
   is implemented for measurement; no simulation or rendering enhancement is enabled.
4. **Two fresh boots per preset:** all $32A4 game-data bytes at both endpoints and every
   displayed game pixel match. A500/A1200 instruction PCs and cycle costs match in
   every field; trace and breakpoint frame counts agree. The 68030's breakpoint
   pattern repeats on two fresh boots. Local `docs/phase4.md` documents raw-record
   exceptions: a discarded INTREQR bit, screenshot edge padding, and unavailable
   68030 CPU/blitter timing. Whole raw-trace byte equality is not claimed.

| Preset | Presentations / 100 fields | FPS at nominal PAL 50 Hz | Blitter-wait routine | Blitter IRQ service |
|---|---:|---:|---:|---:|
| A500, 512 KiB chip + 1536 KiB slow | 8 | 4.0 | 21.16% | 11.36% |
| A1200/68EC020, 2 MiB chip + 4 MiB fast | 17 | 8.5 | 34.63% | 6.64% |
| A1200/68030 25 MHz, same RAM | 20 | 10.0 | unavailable | unavailable |

These are fixed-window baselines, not improvement claims or whole-race averages.
The 68030 backend emits no instruction records and has no validated CPU/blitter
cost model; its frame count is measured with read-only breakpoints. The local
frame-cost table includes span fill, projection, clears, interrupts, idle time
and DMA shares. The normal 1.5b build remains byte-identical to the hardware A/B slave;
CUSTOM3=0 leaves the original demo call and RNG instructions intact in VERIFY builds.

**Acceptance:** the measurement portion of playbook §12 is satisfied, with evidence
under ignored `tmp/dev/tmp/phase4/base-*` and reproducible commands in the local docs.
The phase-5 time model below completes the “ready to improve” analysis gate.
The traced vehicle and road calls are five fields apart on both CPUs in this window.
Phase 5 identifies why cross-CPU endpoint state differs and establishes the
clock/score/event model required before implementing enhanced simulation.

## Phase 5: the time model — complete

The local `docs/internals.md` now contains the time-source and state-writer tables;
`docs/phase5.md` contains field-indexed captures, instruction attribution, score formulas
and event evidence. The design below is revised for TD, not copied from TD2's constants.

- The priority-4 CLI runs vehicle integration at h4+$43B0/$3F26, road crossings at
  h4+$1C3A and traffic/police at h4+$14EA. Road Drawer is a separate priority -1 task.
  The period is **5 fields**, stored at race-frame -16(a5) by h4+$42. Deadline -12(a5)
  is initialized at $F6, waited at $16A..$190 and reset to current VBL at $192. There
  is no catch-up after an overrun. Root+$18BA increments the field clock -31782(a4).
- Race count -36(a5) starts at 1, then increments once per counted simulation tick;
  speed sum -44(a5) adds integer mph. Counting starts after first gear. The results
  divide count by **12**, yielding **5/6 nominal PAL time**. Average is speed sum/count;
  crash adds 240 count units, without speed, a 20-second penalty. Stage score is
  `M*1000000/max(N-B,100) + 100*max(100-(N-B),0)` with integer division, N=count,
  M=stage+4 and B the stage table value. It is not based on elapsed VBL time.
- Equal-field A500/A1200 captures confirm five-field ticks but disprove drawing
  independence. First gear is selected at sample 65 on both; clutch clears at 100 vs
  85, waiting for both rendered shifter buffers. Speed/position/RPM diverge at 85.
  Wall collision also consumes renderer-saved x (-22372(a4), h4+$B10/$1240/$127A).
  Renderer-written road widths and traffic collision origins/lane offsets also feed
  CLI decisions. Enhanced mode needs simulation-owned geometry and lane motion;
  original mode must preserve these behaviors.
- Crash animation/acknowledgement blocks the main loop. Natural Porsche crashes took
  37 vs 31 fields inside h4+$32D8 on A500/A1200; both applied exactly one +240 penalty.
  The count and speed sum froze through a 100-field acknowledgement wait. Drawing work
  adds CPU-dependent blocking time, independently of the explicit penalty. Radar uses
  five-field script counters; stopped ticks suppress vehicle integration while traffic,
  scripts and counted race time continue. The tested patrol stop held the vehicle for
  490 fields on both CPUs and released without acknowledgement input or a crash penalty.
  The original event paths remain part of the design.
- All 14 original direct RNG callers are mapped: root demo selection and stage commentary;
  h3 intro/car-selection waits; h4 road-crossing traffic/radar choices; and Road Drawer's
  high-speed windscreen effects. Later 100-field traces show 9 visual calls on A500 vs
  17 on A1200 plus one traffic call. CUSTOM3's current shared stream is insufficient
  for later cross-CPU windows; phase 7 must isolate visual consumption.
- PAL only is validated. The 12 ticks/second result conversion corresponds to 60 Hz / 5;
  NTSC timing and enhanced-mode clock conversion remain explicit unvalidated work.

The separate simulation process supports the overall design, but phase 8 needs rational
2/5 integration, original five-field script cadence and removal of the identified drawing
dependencies. The period-6 and integer-subdivision assumptions are rejected.

## Phase 6: always-on fixes (the first deliverable)

1. **Overlay cache flush: implementation and requested emulator smoke test complete.**
   Ported `overlay_unload_end` / `overlay_load_end` from TD2 commit `c4d0af5`,
   unconditionally using `PL_P $06390` / `PL_P $06916`. Each six-byte hook replaces
   `movem.l` plus `rts`; the helper flushes before restoring the original registers.
   Direct branch candidates into unload are `$062EC`, `$0630A`, `$06330`; into load
   `$0689E`, `$068DE`. All target the hook start; no word-aligned direct-branch candidate
   enters either interior. Indirect targets are not statically proven.

   The normal 1.5b build is unchanged by the VERIFY-only phase-4 instrumentation.
   `AMIGA_SETUP=a1200-040`: startup, driving demo and attract cycle passed, both helpers
   hit, and debugger checks confirmed return from `_flushcache`, restored registers,
   stack and return PC. MMU trace shows `TC=8000`; PAL, 25 MHz preset, 2 MB chip / 8 MB
   fast, JIT disabled, WHDLoad 20.0. Evidence and reproducible commands are in the local
   harness docs. The earlier emulation result described as “shipped 1.4” was actually 1.3.

   A/B slaves are under ignored `tmp/dev/dist/overlay-cache-ab/`: fixed 1.5b and the
   unmodified repository-1.4 rebuild, both built with the same pinned dependencies.
   No equivalence to an unavailable shipped 1.4 is claimed. Real A1200/68040 A/B testing
   and normal user quit remain open; debugger shutdown is not a normal-quit test.
   FS-UAE success does not prove hardware cache coherency.
2. **Original display bugs.** For each glitch seen in phase 3, trace the copper and display
   registers on the affected line. Fix it in the slave only if it is an original defect.
3. Source, ReadMe and this plan belong to "Test Drive: flush caches after overlay stub
   rewrites". No push is requested. Any later display fix gets a separate commit.

## Phase 7: VERIFY scaffolding

Built only with `-DVERIFY`; the normal slave contains none of it. Copy the framework from
TD2's `simulation-verify.s` and the slave's `IFD VERIFY` config.

1. `CUSTOM3`: the fixed seed, beam removal and demo-selection reset are implemented
   for the phase-4 first-race window. For later windows, isolate renderer RNG (private
   stream or suppressed visual consumption in VERIFY), reset at a player-race anchor,
   and verify traffic/radar draws stay in the same order across CPUs. Beam removal alone
   does not make a shared stream deterministic.
2. `CUSTOM4`: slow drawing only. The original shifter handshake and renderer-owned
   collision geometry are expected negative controls; enhanced physics must pass the
   independence check.
3. `CUSTOM5` fixtures: a field-based joystick tape injected through the existing
   `read_joydat`/`read_fire1` hooks, a straight acceleration/braking tape, forced crash and
   radar events, and the zero-fraction rendering oracle (later).
4. `CUSTOM1` bit: the automatic-recovery instrument only, as in TD2 after PR #24.
5. An assembly assertion runner before PatchSeg, read back by `check_units.py`.
6. Tools: `check_units.py`, `check_disabled.py` (all optional ranges keep the original bytes
   with `CUSTOM2=0`), and `audit_simulation.py` (hook boundaries, overlaps, branches into hooks).

## Phase 8: fixed-time simulation (`CUSTOM2`)

Reuse TD2's architecture and tested arithmetic where its assumptions apply. Keep game-local
sources (`simulation.s`, `simulation-patches.i`) so each slave builds alone. TD's original
period is five fields; **do not copy integer `sim_n=6/sim_p` or six-field constants**.

1. Choose `sim_p=5` on 68000/010 and 2 on 68020+, subject to the measured CPU budget.
   Scale continuous changes by the rational `sim_p/5`, with a signed private remainder
   per accumulator. Five period-2 updates must compose to two original updates for a
   constant rate. Audit intermediate overflow and negative/near-zero cases. Relaxation
   requires retention `r^(sim_p/5)` with carries; TD2's integer n-th-root selection is
   insufficient. Derive and test the matching coarse-Euler displacement correction for
   this rational ratio, rather than applying a second scale to speed>>6 displacement.
2. Scale acceleration, braking, drag, steering, lane centring, traffic displacement and
   physical police motion. Leave road-segment loops, collision impulses, limits and
   thresholds unscaled. Keep gear decisions, shifter movement, police/radar counters and
   scripted decisions at the original five-field cadence, using an elapsed-field
   accumulator (period 2 does not divide 5). Separate gear/clutch progress from the
   renderer's two-buffer acknowledgements. Compute road-edge widths, current lateral
   position and traffic collision origins in the simulation; move lane-offset returns
   out of draw cadence. Changing only the wall-collision saved-x read is insufficient.
   Keep snapshots for drawing, and advance background/dashboard phases from simulation.
3. Use PAL elapsed-field quanta for the counted race clock and speed-weighted sum:
   12 legacy clock units per 50 fields, i.e. `6*sim_p/25` units per enhanced step with
   retained fractions. Preserve neutral-start exclusion, original blocking pauses and
   the explicit 240-unit crash penalty. Keep the stage score/reference tables in their
   documented clock units; test displayed time, average and score together.
4. Keep the original crash animation, acknowledgement and recovery path, including its
   CPU-dependent blocking duration. Radar stops suppress vehicle integration but keep
   script/traffic/counting active. Preserve these distinctions. Automatic recovery is
   VERIFY-only. Isolate visual RNG at a simulation-owned cadence and keep the gameplay
   stream free of beam/draw-rate input in enhanced mode.
5. Gate every gameplay change behind `PL_IFC2`; assertions for every arithmetic routine,
   hook-boundary/incoming-branch audits and disabled-byte checks are required.
6. Validate all five cars. Period-5 arithmetic must reproduce original rates/travel before
   intentional clock, RNG, clutch or collision changes intervene; label those divergences
   separately. Period 2 needs straight and route tapes and quantified handling differences.
   `check_timing.py` must prove PAL clock correctness, and the phase-7 state oracle must
   prove same-period core-state equality across CPUs/slow drawing outside the deliberately
   original blocking event intervals. Test event entry, one penalty, acknowledgement and
   recovery separately. NTSC remains open; no 50 Hz conversion may silently claim NTSC.

## Phase 9: blitter priority and interrupts

Copy TD2's blitter-priority and unused-blitter-interrupt patches, behind `CUSTOM2`. Find TD's
equivalents of the shape blitter's BBUSY polls and the blitter-finished interrupts in the
phase 4 profile. Keep the patch only if fixed windows show a gain (±0.15 fps is noise).

## Phase 10: sub-unit rendering

Reuse TD2's `render.s` design: road rows interpolated with the camera fraction, gradient
records converted once per view and source pointer, the exact tangent cache, fractional car
projection, sideways/heading smoothing and smoothing of mountains and hill crests.

1. Map TD's road renderer (row records, scale tables, segment walker, scanline table) and
   compare it with TD2's. Test Drive's mountain roads and cliffs make the vertical (slope)
   path more important than in TD2. TD has two statically identified drawing passes;
   establish their screen roles before deciding whether TD2's mirror path has a counterpart.
2. Port each piece behind `CUSTOM2` with its VERIFY fixture. Check the zero oracle (byte-identical
   rows and scanlines with zero fractions) before judging any visual result.
3. Budget: at most 3% of A500 cycles (`subunit_cost.py`), with no frame-rate regression on
   any preset.
4. Geometry and sideways reports (`subunit_geometry.py`, `sideways_report.py`), adapted.

## Phase 11: regression, release and contribution

1. The full TD2 regression checklist adapted to TD (both builds assemble, the audit, units,
   disabled bytes, timing, all cars, zero oracle, cost, two fixed windows per arm, the oldest
   and newest WHDLoad).
2. Player-facing: `ReadMe` history entry (slave 1.5b), `slv_config`
   `"C2:B:Enhanced framerate;"`, and an icon tooltype `CUSTOM2=1`.
   `Makefile_windows.mak` gets the new source dependencies.
3. Release archives through `package_release.py` / `amigaxdev.release` into `tmp/dev/dist/`.
   Release candidate on the user's A1200/68040.
4. Commits: one per coherent feature, author and committer Vesa Halttunen, unsigned, no hooks,
   no attribution trailers. PR to the Vesuri fork, then upstream, as TD2 did.

## Phase 12: lessons back to AmigaXDev

Record in AmigaXDev `docs/` what generalises: transferring an engine between games of one
studio by structure rather than offsets, and the overlay cache fix as a pattern for every
Aztec overlay executable. Update `docs/projects.md` with this branch.

## Open questions

- Does the unmodified repository-1.4 rebuild fail on real A1200/68040 hardware? Emulation cannot tell
  (phase 6.1).
- Which original display bugs, if any, are worth fixing (phase 3)?
