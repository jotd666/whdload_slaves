# Prince of Persia: A500 performance plan

Goal: the game's intended speed on an A500, which is a frame every 4 PAL fields (12.5 fps).
The VBL countdown is reloaded from `g:$7aba` = 4, and the main loop waits for it at `g:$1bd46`.
Today, on the spikes route on `a500-1.5m`: 10.4 fps. 137 of 206 frames hit 4 fields, 60
overrun to 5–9, and the two room changes take 31 and 35 fields. The game advances one step
per frame, so an overrun frame is slow motion, not dropped frames.

Acceptance, on `a500-1.5m` (68000 7 MHz, 512 KB chip + 1.5 MB slow), PAL:

| Id | Criterion |
|---|---|
| G1 | ≥ 95% of gameplay frames on every benchmark route take 4 fields; none takes more than 5 |
| G2 | Room changes take at most 16 fields (today 31–35) |
| G3 | Game state at every frame and every published frame's pixels are identical to the original, with the same frame-indexed input |
| G4 | No regression on A500 + fast RAM, A1200, 68030/040/060 (functional, caches on), NTSC |

Sizes per frame, steady running / spike death (fields): work 3.72 / 5.41; full-screen copy
0.79 / 0.82; layer draw 0.87 / 1.98 (tile draw `$1c29c` 0.76 / 1.72); logic `$1156a`
1.20 / 1.43 and `$0c0ac` 0.71 / 0.82; tile lookup `$107d0` 0.49 / 0.50; shape blitter
`$05686` 0.36 / 0.84 with 43 / 89 blits; STOP blitter waits 0.95 mean; interrupts 0.17 / 0.31.

## A. Measurement and safety net (no game change)

- **A1 Build.** `tools/build.sh` assembles the normal slave and a `VERIFY` variant into
  `tmp/build` with the shared vasm flags. Gate: the normal build is byte-identical to the
  shipped v4.4 slave (already true by hand).
  *Done.* `CHECK=1 tools/build.sh` builds both and compares the normal one with the shipped
  slave. `VERIFY` adds `PrinceOfPersiaVerify.s` (instruments, version 1 only, chained after
  `pl_v1`) and " (VERIFY)" in the name; the harness takes slave offsets from the vasm listing.
- **A2 Frame-indexed input.** An input tape in the VERIFY slave, indexed by gameplay step,
  replaces host keys. It is better than counted breakpoints: those are very slow on this stub,
  and only a tape gives other CPUs (G4) the same input on the same step.
  *Done.* `CUSTOM4=n` plays tape n:
  - **Steps:** a step is a control poll from gameplay (`g:$1942c` called through `g:$13de2`,
    once per frame). The title, intro and interludes poll in busy loops, as often as time
    allows, so they don't count. The joystick reader (`g:$1b8bc`) returns the tape's mask (1
    up, 2 down, 4 left, 8 right, 16 fire).
  - **Pauses and skips:** outside gameplay, `TAPE_SKIP` (or a level request) is fire, which
    skips the title. `TAPE_RESUME` is fire for the pause loop's button check (`g:$1958a`)
    only. It ends the pauses at the title and at step 1 without the controls seeing fire.
  - **Level requests:** `TAPE_LEVEL+n` writes n to `$47ab8`, as the level skip does.
  - **Live input:** a zero mask lets the game read the keyboard, so `tools/tape_from_route.py`
    can turn a live keypad session into tape entries.
  - **The spikes route** is tape 1 (`tape_spikes`), with no host input. It dies in the spike
    pit by step 274.
  - **Screenshots at chosen steps:** `verify_stop` and a breakpoint at `verify_stopped` stop
    the CPU at the start of a step. Use them outside traces only.

  Gate passed: two boots give identical screenshots at all 14 key-change steps from 2 to 300
  (`tools/tape_run.py`, `tools/sameshots.py`; numbered before steps were limited to
  gameplay, so one higher than now). The stub leaves the screenshots' last two
  columns unwritten, so those are ignored. Note for A4: `g:$1ba58` adds VHPOSR to the RNG seed
  `g:$7cb6` at level start and on fire, so the seed depends on timing.
- **A3 Frame-time counter (VERIFY).** The slave hooks the frame-wait entry and exit and the VBL
  handler, and keeps a per-frame log in slave memory: fields per frame, work in beam
  positions, and the blit count. gdb reads it once at the end, with no stop inside the window.
  Gate: on the baseline its period histogram equals `tools/frames.py`'s exactly.
  *Done.* The VERIFY slave replaces the frame wait `g:$1bd46` with a copy (`verify_wait`) and
  counts VERTB and blitter interrupts. Time is in raster lines (fields × 313 + VPOS).
  - **Log format:** each wait exit appends (step, period, work, blits) to `verify_log`, which
    has 2048 entries.
  - **Tools:** `profile_run.py` saves the block as `verify.bin` and marks the VERIFY wait and
    poll. `tools/frame_log.py` summarises the log.
  - **Gate passed:** `tools/check_frame_log.py`, on the spikes tape traced for 1700 fields,
    matched all 304 frames that lie inside one chunk to the field. `frames.py` miscounts frames
    that cross a chunk boundary, because a field runs untraced between chunks, so the log is
    the reference from now on.
  - **First figures (tape 1, from boot):** periods of 4 × 191, 5 × 46, 6 × 51, 7–10 × 12. The
    room changes at steps 124 and 244 take 32 and 36 fields; the level start takes 57.
  - **Hooks change timing:** the tape's screenshots stay the same apart from the torch flames.
    Those come from the RNG, whose seed takes VHPOSR (A4).
- **A4 Faithfulness probes (VERIFY).** At each frame-wait end, hash the game state: kid and
  guard character records, level and room buffers, timer, RNG, and the sound request queue
  once B1 has located them. At each display swap (`g:$1a0e6`, the buffer in `$49d1c`), hash the
  published frame's bitplanes. Write both to a slave ring buffer and dump it at the end. Gate:
  two baseline runs match; a deliberate one-byte sabotage, such as skipping one shape blit,
  is detected.
  *Done, revised in A5.* The hashes are taken by the harness (`tools/state_run.py`). At every
  step's frame-wait exit (`verify_wait_stopped`) it stops the emulator, reads memory, and
  hashes the frame shown and the state.
  - **Why not in the slave:** the first version hashed in the slave with interrupts off, and
    took about 60 fields per frame. The game behaves differently with frames that long, so
    those hashes measured a perturbed game.
  - **State hash:** chip `$1000`–`$80000` plus the image's data parts (`g:$1000`–`$5320`,
    `g:$1f7d0`–`$47800`).
  - **Excluded from the state hash** (`EXCLUDE`):
    - the stack below `$1000`;
    - the VBL countdown and swap at `$49d10`–`$49d1f`;
    - the two display buffers at `$53c2e`–`$674ad`;
    - the image's code;
    - real-time sound state: `$47420`–`$4743f`, the driver's channel records at
      `$49dc0`–`$49e3f`, and the channel table at `g:$7080`–`$70bf`.
  - **Entropy pinned:** VERIFY adds 0 instead of VHPOSR to the RNG seed in `g:$1ba58`.
    `g:$19610` only waits for line 0 during hardware init.
  - **Probes**, selected by bits of `CUSTOM5`:
    - 1: work delay, one extra VBL at each step's start, before the frame is published;
    - 2: one extra VBL after publishing;
    - 4: skip one `g:$53d6` blit at step 150. The hook is patched in only with this bit
      (`PL_IFC5X`), because it costs 2 fields per room change.
  - **Tools:** `tools/hash_cmp.py` compares two runs step by step.

  Gate, spikes tape, steps 1–350:
  - **Two boots:** equal.
  - **Sabotage:** detected at step 150 in both hashes. It also changes the state again from
    step 289, so the effect of the missing blit persists.
  - **Delay after publishing:** equal.
  - **Work delay: not equal.** The game keeps real-time state, see B7. On tapes 1 and 5 only
    the state differs, never the pixels: the timer records at `$46ea6`–`$46eec` during the
    level-start message (steps 11–48), and the pre-shifted kid shapes at `$26400` and
    `$32000`, which are filled at other times. On tapes 3 and 4 the pixels differ too.
    So G3 can't be bit-identical against the original as long as frame times differ. B7
    must pin the game's view of time first.
- **A5 Benchmark routes.** Besides the spikes route, add (a) the first guard fight in level 1,
  (b) a busy later level reached with the level-skip trainer option (CUSTOM1 bit 2), and
  (c) a stretch of standing still, the floor case. Record each route's baseline A3 histogram
  and A4 hashes in `INTERNALS.md`.
  *Done*, as VERIFY tapes (`CUSTOM4`). Steps count only gameplay polls (`g:$13de2`): the title,
  intro and interludes poll in busy loops at whatever rate time allows. Later levels come from
  the tape's `TAPE_LEVEL+n`, which writes the level-skip request `$47ab8` itself. Baselines are
  recorded in this plan instead.

  | Tape | Route | Through step |
  |---|---|---|
  | 1 | spikes (level 1) | 274 dies, 350 |
  | 3 | level 2's first guard: run left from step 45 to 84, then fire, fire, up every 10 steps; fight from step 90, the kid dies at about step 218 | 290 |
  | 4 | level 4 (palace): right from step 45 to 100, then left to 200, past an arcade guard, three room changes | 290 |
  | 5 | idle in level 1's first room | 360 |

  (a) uses level 2's guard, not level 1's: level 1's is far into the level, while level 2's is
  one room from the start.

  A3 baseline, steps 2–300, on `a500-1.5m` (`tools/timing_run.py`, `tools/frame_log.py`).
  Tapes 3 and 4 include the interlude and the level load, logged at steps 10–11:

  | Tape | Frames | Period histogram (fields × frames) | Mean period / work | Work > 4 |
  |---|---|---|---|---|
  | 1 | 301 | 4×200 5×46 6×42 7–10×11, room changes 32, 36 | 4.79 / 4.29 | 101 |
  | 3 | 355 | 4×57 5×227 6×23 7–11×46, load 23, 45 | 5.55 / 4.99 | 270 |
  | 4 | 357 | 4×151 5×109 6×20 7×48 9–10×24, load/room changes 23–42 | 5.62 / 5.03 | 177 |
  | 5 | 299 | 4×296 5×1 6×2 | 4.02 / 3.45 | 3 |

  A4 baseline hash digests (`tools/hash_cmp.py`, unchanged VERIFY build): tape 1
  `343c39cbd12a`, 3 `6d5be796a068`, 4 `c111c939510d`, 5 `3808b037eb1d`. A changed slave
  reproduces these only while B7 is still open if it does not change frame times, so for
  now they guard VERIFY-only and timing-neutral changes.
  - The VERIFY hooks add a little time (frame wait copy, VBL and blitter interrupt
    counters). The shipped slave's keypad-route profile (`tmp/prof-a500`) remains the
    absolute reference.
  - The guard fight is the worst route: only 16% of its frames make 4 fields.

## B. Understanding (documented in `INTERNALS.md`; no game change)

- **B1 Buffers.** Name the screen buffers behind `$674b2`, `$674ba` and `$49d1c` and the
  buffer-id lookup `g:$1c0f6`. Establish what `g:$1bd5e` copies (40,000 bytes, called from
  draw at `g:$0baca` after layers 0 and 1), from where to where, and which later code reads
  the destination.
  *Done* (`INTERNALS.md` B1). Buffer 0 (`$49fee`) is the room background, and 1 and 2
  (`$53c2e`, `$5d86e`) are the display pair. `$674b2` is the shown one and `$674ba` the draw
  target. `$49d1c` is the buffer the VBL handler will show next. Each frame draws layers 0
  and 1 into buffer 0, copies buffer 0 over the hidden display buffer (`g:$1bd5e(0, 4)`),
  then draws the characters and layer 1 on top. Only blits read the copy's destination
  before the publish. For C2(b), the dirty rectangles are the shape blits of two frames
  earlier plus buffer 0's own changes.
- **B2 Blitter users.** List every routine that writes blitter registers or waits for the
  blitter: `$053a2`, `$053d6`, the `$1a24` flag, `btst #6,$dff002`, `BLTSIZE` writes. For
  each, record whether the CPU touches a blit's source or destination before the next blit
  starts.
  *Done* (`INTERNALS.md` B2). `g:$053a2` and `g:$053d6` are the only `BLTSIZE` writers, and
  both STOP until the blitter interrupt clears `$1a24`. Seven routines set blits up. In
  4,218 traced blits on four routes, including two room changes, the CPU never touched a
  blit's destination, or wrote its sources, before the next blit started. So C1 needs a wait
  only before blitter register writes and the swap. The same traces bound C1's own gain at
  0.16–0.28 fields per frame plus the per-blit interrupt cost, because plane blits run back
  to back.
- **B3 Tile lookup.** `g:$107d0` (C, stack arguments, about 127 calls per frame): its inputs,
  outputs and side effects, the tables it reads (`$499fc`, `g:$7b18a`, `$49a94/98`), and its
  two callers, `$108c6` and `$1099a`.
- **B4 Overrun frames.** Give `profile_run.py` per-frame call trees, split at the frame marks.
  Compare 4-field frames with 5–9-field frames on every route, and list what grows: in the
  death, layer and tile draw double and the shape blits rise from 43 to 89.
- **B5 Room change.** Break `g:$0aba0` down: `$0bafa` full-room tile draw (50%), `$0f3e2`
  (13%), and the parts that are loading or decompression rather than drawing.
- **B6 Bus budget.** From the DMA records, the free chip-bus slots per frame on the A500,
  with code running from slow RAM, which shares the chip bus. This is the ceiling on what
  overlapping blits with CPU work (C1, C2) can win.
- **B7 Real-time state.** Find what the game runs on real time rather than per step: the
  copper and CIA-B interrupts post events (`g:$1d5b8`), the sound driver, timers and
  animation. Under the A4 work delay these change state (timer records `$46ea6`, the shape
  caches) and, on tapes 3 and 4, the guard and level-start behaviour (`g:$b882`). Then add a
  VERIFY time pin that drives them from the step, so the game sees the same time per step
  whatever the frame takes, and G3 can be checked bit for bit. Gate: under the pin, the work
  delay leaves every route's hashes equal.

## C. Optimisations

Each one is a slave patch for version 1 (UK; also used for 1b), switchable for A/B at first
and then always on. Each must pass A4 (G3, under B7's time pin) on all routes, and is kept
only if A3 shows a gain.
Expected gains are fields per frame of CPU time, before bus contention.

- **C1 Deferred blitter waits.** Replace "start the blit, then STOP until the blitter
  interrupt" in `$053a2` and `$053d6` with "wait for the previous blit before touching the
  blitter, start, return". Add a wait wherever B2 found the CPU touching blit memory, and before
  the display swap. Turn off the per-blit blitter interrupt. Expected 0.3–0.5 of the 0.95
  STOP fields, plus most of the per-blit interrupt cost.
- **C2 The full-screen copy.** Depending on B1:
  - (a) Chain its six `$1000`-word blits from the blitter interrupt, so the 40 KB copy runs
    behind the CPU until the first reader waits for it. Expected 0.3–0.5.
  - (b) Copy only the regions that changed, or skip the copy when its source is unchanged.
    Expected up to 0.7.

  Pick (b) only if B1 shows the dirty regions are cheap to track exactly.
- **C3 Tile lookup in assembler.** Register arguments and the same results as `$107d0`,
  called from patched `$108c6` and `$1099a`. Expected 0.49 → about 0.15.
- **C4 Logic hot spots.** Rewrite the self-time leaders of `$1156a` (`$11584`, `$108c6`,
  `$0f730`) and `$0c0ac` (`$14e8c`, `$12bea`), in the order B4 ranks them by growth in overrun
  frames. Compiled-C overhead (`link`, `movem`, reloaded stack arguments) is the target; the
  algorithms stay.
- **C5 Draw path.** In `$11904` → `$1c29c` → `$1cb94` → `$05686`, remove repeated per-shape
  setup. Batch shape blits so C1's deferred wait overlaps the next shape's setup. Expected:
  most of the death frames' extra 1 field.
- **C6 Room change.** Apply C1, C3 and C5 to `$0aba0`, then deal with what B5 shows is left,
  such as redundant clears or a double full-room draw. Target G2.
- **C7 Gate after each step.** Run all A5 routes for A3 and A4 and the C-step's own profile,
  and record the result in `INTERNALS.md`. Stop when G1 and G2 hold; don't optimise past
  the goal.

## D. Validation and release

- **D1 Machine matrix (G4).** `a500-1.5m`, A500 + 1 MB fast RAM, `a1200`, `a1200-fast`, and
  `a1200-030`/`-040`/`-060` with the CACHE options. Deferred blitter waits must not race with
  data caches on chip memory. Also NTSC: 15 fps, so a budget of 3.33 PAL-field-equivalents per
  frame; report it separately.
- **D2 Other versions.** Versions 2 (US), 3 (German) and 4 (French) have different offsets
  (the slave's patch lists show a regular shift). They need the user's disk images to find
  and verify their offsets. Until then, keep the patches version-1-only.
- **D3 Real hardware.** A real A500 with 1.5 MB, plus an accelerated machine if one is
  available, run by the user.
- **D4 Release.** Slave 4.5 with ReadMe history, the default-on decision recorded (no
  option needed if G3 holds), and a contribution to JOTD following the playbook's §13.
