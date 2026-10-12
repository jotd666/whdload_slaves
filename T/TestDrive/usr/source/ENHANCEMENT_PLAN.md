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
gate comes before any patch. Generic lessons go back to AmigaXDev `docs/`.

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
   authoritative source into `tmp/build/`; `VERIFY=1` selects the VERIFY output. Both
   variants are currently identical. The Bash wrappers work with macOS Bash 3.2.
4. Trace tools: `td_report.py` uses TD's root/data sizes, excludes the PRELOAD root copy
   and follows the loaded BPTR chain. `profile_demo.sh`, `ingame.py`, `frames.py`,
   `swap_fields.py` and `fixed_window.sh` are adapted. Captures retain the exact slave,
   launch settings, RAM and evidence. Fixed captures require an explicit TD anchor and
   reject a moved anchor. **The race anchor and buffer-swap marker are still phase 4
   work:** until validated, the tools provide diagnostic windows and CPU/DMA reports,
   not FPS. No TD2 game addresses are silently reused.
5. State tools: `state_fields.py`, `state_writers.py`, `state_report.py`, `state_watch.py`
   and `task_state.py` work on TD captures. The field sampler uses Ticks VBLInt at
   TD:$018BA and checks consecutive counters and a4/a1 against the data hunk. Task
   parsing finds Initial CLI and Road Drawer in a real dump. Writer attribution and
   a live watchpoint corroborate the VBL store.
6. Comparison: `compare_state.py` has a TD-only seven-variable seed map plus full data
   comparison. Two fresh A500 boots at the same VBL window match byte-for-byte across
   all $32A4 data bytes; a different scene differs. Negative controls detect a changed
   non-clock selector and a missing sample. **The full physics/score state map remains
   phase 5 work**, so this is harness validation, not proof of gameplay determinism.
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
shipped-1.4 byte-equivalence claim is made. Later measurement and gameplay gates remain
open; phase 1 does not certify a frame marker, race anchor or simulation design.

## Phase 2: identify the game (complete)

1. Local `docs/internals.md` inventories the slave configuration, all 11 explicit
   patch sites, keyboard interrupt and Exec trackdisk hooks. Original instructions,
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
4. Explicitly not found: a validated per-frame presentation/swap site, TD2's
   exact 52-byte-row/8.8 road walker and CPU span loop, and several secondary
   renderer counterparts. Two drawing passes are present; phase 3 visually confirms
   a rear-view mirror. Timing/state ownership, pass attribution and markers remain later gates.

**Acceptance:** local `tools/identify_game.py` checks pinned inputs, all explicit
patch signatures/source coverage, hunk sizes, root JMP targets and both overlay
node/export lists. Evidence is under ignored `tmp/dev/tmp/phase2/`. Every requested
routine family has an evidenced TD location or an explicit not-found entry in
the local inventory. No slave changes or new gameplay/performance claims.

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
marker, fixed race anchor and timing model remain phases 4 and 5.

## Phase 4: frame counter, fixed window, baseline

1. Find the buffer swap (COP1LC or bitplane-pointer writes per drawn frame), make it the
   frame marker in `frames.py` and `swap_fields.py`, and check it against screenshots.
2. Fixed-window anchor: a deterministic point at the start of the first race, such as the
   race clock initialisation, as in TD2. Then trace `FIELDS` fields.
3. Baseline on the three presets, two fresh boots per arm: frame rate, the share of blitter
   waits, blitter interrupts, span fill, projection and clears (TD2's frame-cost table).

**Done when:** the playbook's §12 gate is met: a reproducible cycle-exact gameplay trace, a
report of where the frame goes, a fixed-window frame rate and the time model below.

## Phase 5: the time model (decides the design)

Answer each of these with traces and state captures, never screenshots:

1. Which context runs physics? Is it the CLI process stepping on a field-counted deadline,
   as TD2 does every 6 fields, or the drawing loop?
2. What is the step period, and where are the field clock, the deadline and the period
   constant?
3. What is the race clock's unit and rate against real PAL time (TD2's ran at 5/6)? How do
   average speed and score derive from it?
4. Does game speed depend on the CPU? Compare state on the A500 and the A1200 at identical
   VBL indices. Do crash and radar sequences block the simulation for a CPU-dependent time?
5. RNG: does it mix the beam position, and which tasks call it? This decides `CUSTOM3`.
6. NTSC (left open, as in TD2): record whether the timing assumes 60 Hz, so the open item
   is precise. Validate on PAL only.
7. Build the state map: position, speed, RPM, gear, heading, lateral position, traffic
   origins, police/radar counters, crash code, fuel or stage, clock and score sums. Record
   each with its writer.

**Done when:** `docs/internals.md` has TD's time-source and state-map tables, and the
simulation design below has been confirmed or revised. If TD has no separate fixed-period
simulation process, stop and revise phases 7 and 9 before writing code.

## Phase 6: always-on fixes (the first deliverable)

1. **Overlay cache flush: implementation and requested emulator smoke test complete.**
   Ported `overlay_unload_end` / `overlay_load_end` from TD2 commit `c4d0af5`,
   unconditionally using `PL_P $06390` / `PL_P $06916`. Each six-byte hook replaces
   `movem.l` plus `rts`; the helper flushes before restoring the original registers.
   Direct branch candidates into unload are `$062EC`, `$0630A`, `$06330`; into load
   `$0689E`, `$068DE`. All target the hook start; no word-aligned direct-branch candidate
   enters either interior. Indirect targets are not statically proven.

   The 1.5b normal and VERIFY builds are identical (no VERIFY instruments yet).
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

1. `CUSTOM3`: reproducible RNG (removes the beam term if phase 5 finds one).
2. `CUSTOM4`: slow drawing only, to prove game time is independent of drawing.
3. `CUSTOM5` fixtures: a field-based joystick tape injected through the existing
   `read_joydat`/`read_fire1` hooks, a straight acceleration/braking tape, forced crash and
   radar events, and the zero-fraction rendering oracle (later).
4. `CUSTOM1` bit: the automatic-recovery instrument only, as in TD2 after PR #24.
5. An assembly assertion runner before PatchSeg, read back by `check_units.py`.
6. Tools: `check_units.py`, `check_disabled.py` (all optional ranges keep the original bytes
   with `CUSTOM2=0`), and `audit_simulation.py` (hook boundaries, overlaps, branches into hooks).

## Phase 8: fixed-time simulation (`CUSTOM2`)

Reuse TD2's design (`simulation.s` and the "Fixed-time simulation" section of the Test Drive 2
project's `docs/simulation-design.md`). Copy the generic routines verbatim into
`T/TestDrive/usr/source/simulation.s`, because each game directory builds alone. Write the
hooks again for TD's offsets.

1. Generic, copied: period selection from AttnFlags (`sim_p` 6 or 2 if TD's original period
   is also 6, otherwise derived from it), deadline patching, signed division with a private
   fractional carry, Q16 n-th-root relaxation with carries, coarse-Euler displacement
   correction, and the clock quanta that make race time follow PAL time.
2. TD-specific: the list of continuous rates to scale (acceleration, braking, drag, steering,
   lane centring, traffic, police motion) and the quantities that stay unscaled
   (road-unit loops, impulses, thresholds). Decide which counters keep their original
   cadence (police/radar scripts, gear decisions, crash scripts). Make dashboard and
   background phases advance with simulation time.
3. Keep the original crash/radar/acknowledgement path. Check that nothing in it depends on
   the step count in a way that the shorter period breaks.
4. Patch list in `simulation-patches.i` behind `PL_IFC2`. Assertions for every new arithmetic
   routine.
5. Validation, as in TD2's handling table, run **for every car**. Period 6 must reproduce the
   original speed and travel exactly up to the first divergence. Period 2 is measured on the
   straight tape and the route tape, and the differences are documented. `check_timing.py`:
   the clock matches PAL time. `compare_state.py --assert-core`: same-period machines match.
   Score and average speed for a fixed tape follow real time.

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
