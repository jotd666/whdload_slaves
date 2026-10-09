# Red Baron: performance plan

> Handoff for the agent that implements the improvements. Written 2026-10-09 from the
> 250-field baseline in `profiling.md` (source `1904205`, VERIFY slave, 68000, 1 MB chip +
> 2 MB fast, maximum detail) and a static/trace analysis of that capture. **Read the
> worktree's `AGENTS.md`, then `profiling.md`, then this file.** Every number is a
> measurement from that capture unless marked *(est.)*; estimates must be replaced by
> measurements before anything is claimed. This opening describes the original baseline;
> implementation status is recorded below and in `w2-verification.md`. The user's decisions
> (2026-10-09) are in §6 and override any option discussed elsewhere.

## Implementation update: CPU-specific priorities

The cached 50 MHz 68030 breakdown in `profiling.md` shows a different bottleneck
from the original 68000 profile. Rectangles and polygons alone take 48.86% of the
measured 3D-pass wall time. Vertex transform/cache, projection, clipping and back-face
dot together take 11.95% in the adjacent steady window. These are scoped short
samples, not a complete frame budget. The 77% figure below always means the whole
3D pipeline, including drawing; it must not be described as pure maths.

W2 remains useful for the 68000. Specialized accelerated-CPU maths rewrites have
less headroom; subsequent fast-CPU work should prioritize drawing and chip-bus
traffic. See the current profiling section before relying on the original estimates.
This finding does not change the sound/game-time decisions in §6.

## W2 implementation status

G1 core normalization, G2 trivial screen clipping, G3 32-bit vertex misses and
G4 low-long dot are implemented behind developer/VERIFY CUSTOM2 bits 2–5, with
original-checked models and per-call twins. Combined twins pass on all three
CPUs in banking/dense scenes. The measured bundle gains 5.97% FPS on A500 and
5.54% on 68020; cached-68030 timing is pending. The player release mask stays zero.

The remaining G1/G3 refinements and G5–G9 are explicitly deferred under §3.8,
not implemented. `w2-verification.md` records the current instruction-cost
assessment and distinguishes routine-cost ceilings from estimated savings.
The historical candidate table below remains the design inventory, not a list
of completed features. Revisit a deferred item when a concrete profile or larger
combined design justifies its cost. Sound and game-time decisions are unchanged.

## 0. Ground rules

These restate `AGENTS.md`, the local playbook (`~/.local/share/amiga/new-game-playbook-jotd.md`)
and the sibling projects' practice, because they bite.

- Every change ships as a patch in the fork's slave source, `R/RedBaron/usr/source/`, applied
  from `_cb_dosLoadSeg`. New code goes in new `.s` modules included from `RedBaronHD.s`, as the
  `testdrive2` branch did. Add every new module to `Makefile_windows.mak`'s dependencies.
- **Only the supported v1 `sim` gets performance patches** (signature at `sim:0a66a`, list
  `pl_sim_v1`). Only v1 is available locally. v2/v3 and the `ps`/`baron` executables keep
  exactly their current patches; say so in the ReadMe.
- Every change is gated by a CUSTOM bit. With the bit off, the original bytes are untouched.
  Declare each hook range beside its patch (`PERF_RANGE sim:OFFSET LEN bit=B`), and check those
  ranges against the original `sim` with relocations applied (§4 W0.7).
- Hooks replace **whole instructions**. Nothing may branch into the replaced bytes, and no
  relocation may point there. Hunk 0 also holds data that must never be overwritten:
  - the tick counters at `sim:30006` and `sim:3015c`;
  - the key queue at `sim:30f4c`;
  - the sound object list at `sim:33168`;
  - the self-modified clip bounds at `sim:39d4c`.
- Use `PL_P` when the replacement does all of the original's work and returns to the caller.
  Use `PL_PS`/`PL_PSS` only when execution resumes after the hook.
- The existing slave patches stay as they are: `patch_bittest`, `kb_delay`, `rename_file`, the
  `baron` cache flush and the DeleteFile filter. So do the VERIFY hooks at `sim:1ed82`
  (`PL_PS`) and `sim:1ef92` (`PL_P`). No performance hook may overlap them.
- Instruments are VERIFY-only: self-tests, twins, per-step logs, slowed drawing, forced
  failures. Normal builds contain none of them.
- Addresses in docs:
  - `sim:OFFSET` is an offset into `sim` hunk 0, the same numbering as the patch lists;
  - `h3:OFFSET` is an offset into `sim` hunk 3 (data + BSS, `$BD0C` bytes);
  - `sound:OFFSET` is a file offset into `amigasnd.drv`, whose code starts at `sound:0028`;
  - `kick:` is a KickEmu ROM address.

  Never quote absolute addresses; chip buffers are named by role.
- One capture at a time. Never `pkill fs-uae`/`gdb`, and never stop an emulator you did not
  start (check the pid against `tmp/dev/amiga/.run/fsuae.pid`).
- **No performance claim without a measurement from the right instrument** (§3).
- Commits: author and committer Vesa Halttunen <vesuri@jormas.com>, unsigned,
  `core.hooksPath=/dev/null`, no assistant trailers. One commit per coherent feature, staged by
  explicit path. No game bytes, traces, dumps, screenshots or built slaves in Git.

## 1. Where the time goes (baseline)

Main-loop iterations in the capture. One iteration is one input poll, one world step, one
render and one swap; see §2.2. "Main" counts main-stack cycles only. The interrupt context
adds 13.4–16.1% of wall time on top.

| Iteration (swap fields) | Fields | Main cycles | Dashboard redraw | 3D world | World step | Kind |
|---|---:|---:|---:|---:|---:|---|
| 60 → 118 | 59.2 | 6.97M | 3.79M (two mirrors: 3.71M) | 2.25M | 0.36M | event |
| 178 → 204 | 27.1 | 3.22M | 0.10M (skipped) | 2.48M | 0.28M | steady |
| 204 → 233 | 28.8 | 3.51M | 0.10M (skipped) | 2.66M | 0.32M | steady |

- **Fields** are true periods taken from the game's own CIA tick counts (70, 71, 32 and 34
  ticks). `profiling.md`'s 58/60/26/29 are recorded fields; the capture appears to lose one
  field at each chunk boundary (§4 W0.2). Main cycles are as recorded, so 178 → 204 is
  missing ~0.1M.
- **Display rate:** about 1.7–1.8 frames/s in steady flight, and about 0.85 frames/s in
  iterations that redraw the dashboard.

**A steady iteration** (main context, per frame, fields 178–231):

| Part | Cycles | Share of main |
|---|---:|---:|
| 3D world `sim:2c552` | 2.48–2.66M | ~77% |
| ├ face loop `sim:3b41a` (transform, projection, clip, emit) | 1.90M | |
| └ object setup, LOD, sort, per-object overhead (`3b0f6`, `3b282`, `3a518`, …) | ~0.6M | |
| (blitter polling inside the 3D pass, part of the rows above) | 0.17–0.19M | |
| World step `sim:01098` (flight model, objects/AI) | 0.28–0.32M | ~9% |
| Instruments `sim:15e96` (three picture-script runs) | 0.18M | ~5.5% |
| Pre-3D `sim:0e782`, overlay `sim:2c144`, cockpit check `sim:19ba6`, rest | ~0.25M | ~8% |

- **Blitter polls** take 7.8% of all steady-state cycles. About 7.0% of that is real waiting *(est.)*.
- **No idle time.** There are no STOP records, no beam or VBL waits in flight, and no frame-rate cap.

**The interrupt tax** is 15.1% of all cycles over 250 fields. It is fixed per second, so it
does not depend on the frame rate:

| Source | Rate | Share of CPU |
|---|---|---:|
| L6 CIA-B timer B → `sim:2ffcc` → sound sequencer `sim:34d96` and driver | 59.11 Hz | 8.78% |
| L4 AUD0–3 refill of the driver's 224-byte chip buffers | 124/s | 5.38% |
| L3 VERTB → `sim:2d344` (mouse, buttons, pointer sprite) | 49.92 Hz | 0.99% |

The OS dispatch overhead of these interrupts is 2.33% of all cycles. It accounts for all of
KickEmu's 1.9% and almost all of the slave's 0.24%.

## 2. Facts the implementer needs

### 2.1 Program layout

`sim` is an Aztec/Manx-style C program: `link a5` prologues, `jsr`-through-jump-table stubs
around `sim:1492–15c4`, and hand-written assembly for the 3D maths and drawing.

| Hunk | Type | Size | Memory |
|---|---|---|---|
| 0 | code | `$3E384` | any (fast in the profile) |
| 1 | data | `$3BC` | chip |
| 2 | data | `$190` | chip; the copper list's bitplane pointers are at hunk 2 + `$48` |
| 3 | data + BSS | `$4450` file / `$BD0C` alloc | any |

- **Fast RAM is full.** The game takes all of the slave's fast memory (24 bytes free), so the
  rest of its bitmaps live in chip RAM.
- **Chip RAM:** the slave declares 512 KB. At fields 0 and 200 there were 125,920 bytes free;
  the largest chunk was 125,584 bytes.
- **The sound driver** `amigasnd.drv` is a three-hunk executable named in `h3:040ac`. Whether
  it is loaded with `LoadSeg` is to be confirmed (§4 W0.7). If it is, `_cb_dosLoadSeg` sees it,
  and the patch offsets are the file offset − `$28`.

### 2.2 The frame loop

The main loop is `sim:21d0a`. Its body runs `sim:21d28–21f32`, and every iteration runs once
per rendered frame:

1. **`sim:21d2c → 1ecc2`: input poll.** One key event per poll. The VERIFY step counter
   (`RBVERIFY`+44) increments here at `sim:1ed82`, so **game step = loop iteration = frame**.
2. **`sim:21d34 → 21b14`: key commands.**
3. **`sim:21da0`: timing starts.** The tick countdown `sim:3015c` is set to 511. Then
   `sim:21db6/21dce` turn the input into the control struct.
4. **`sim:21e06 → 01098`: world step.** It uses the time step measured over the *previous*
   frame. Inside are `sim:01314` (player/world), `sim:11c2c` (8 objects, likely AI), `12194`,
   `12802`, and others.
5. **`sim:21e10`: frame counter.** `h3:03254` increments. Then `sim:21e74 → 2b1e4`: per-frame
   sound-effect control.
6. **`sim:21e92 → 0056c`: render and swap.**
   - `sim:00730 → 0e782` runs before the 3D pass, then `sim:007b8 → 2c552` draws the 3D world.
   - `sim:00816 → 2c144` blits the front-view overlay: 5 ABCD blits, 320×72.
   - `sim:0081e → 19ba6` handles the dashboard, which is normally skipped (§2.5).
   - `sim:0082a → 15e96` draws the instruments (provisional name).
   - The swap is `sim:00b06` (`moveq #0,d0`) → stub `sim:4b38` → `sim:314be`.
7. **`sim:21ebe–21eda`: elapsed time.**
   - e = 511 − `sim:3015c`, rounded down to a multiple of 4: 4 per CIA tick.
   - If `h3:0000e` ≠ 0, e is forced to 40. Nothing in `sim` writes it.
8. **`sim:21f2a → 24452 → 3d34`: the next step's time step** (§2.4).

**Time Compress** (`h3:045a6`, toggled by key command 13 at `sim:0f48`) forces e = 500 at
`sim:0eca`. It renders only when the frame counter is a multiple of 8 (`sim:21d86`/`21e7a`),
so the loop already supports several world steps per render.

### 2.3 Swap and display

**`sim:314c0`** takes its mode from `d1` (= d0 at `sim:314be`).

1. It exchanges the draw pointer `h3:09d6a` and the display pointer `h3:09d66`.
2. It waits for the blitter: a doubled `btst #6,$dff002`, the early-Agnus workaround. Keep it.
3. It builds six BPLxPT moves, with the plane stride in `h3:09d34`.
4. **Only if d1 ≠ 0:** when the beam is past line 40, it busy-waits until the beam passes line
   244 (`sim:31522–31548`).
5. It writes all 12 longs with one `movem.l` at `sim:3154a`.

**Buffers:** two framebuffers of 5 × 8,000 bytes (320×200, 32 colours). A third buffer
(`h3:09d62`) is the overlay source used by `sim:2c144`.

**The copper** waits for line 42 and loads the pointers; the display covers lines 44–243.
- A swap written before line 42 shows in the same field; a later one shows in the next field.
- **Flight always passes d0 = 0**, so there is no wait. The wait mode exists and is used at
  `sim:1ef64`.

**Tearing margin today.** Drawing only touches the hidden buffer. The first blit into the
just-hidden buffer comes 3.2–4.2 fields after the swap, because the world step and the
pre-3D work come first.

**On a faster machine:**
- **Tearing:** once that gap drops below the visible lines still left in the swap field (at
  most ~0.65 field), drawing lands in the buffer being displayed. That happens at about 5× the
  measured speed *(est.)*, which a 68020/68030 may reach in the world step.
- **Unseen frames:** a frame that is swapped out again before line 42 is never displayed.

### 2.4 Game time

**The clock** is CIA-B timer B, period 12,000 E-clocks: 59.11 Hz on PAL, 59.66 Hz on NTSC.
- It is set up at `sim:2b3aa → 30018` and installed with `AddICRVector` at `sim:3004c` (node
  `sim:30186`, code `sim:2ffcc`).
- **On each tick:**
  - `sim:30006` (lifetime count, long) += 1;
  - `sim:3015c` (countdown, word) −= 4, floored at 0;
  - up to four hooks run. Only the sound sequencer `sim:34d96` is installed.
- In flight nothing else keeps time: no VBL counter, VPOSR read, `timer.device` or `Delay`.

**The time step**, computed by `sim:3d34(e)` → `sim:3cee`:

    h3:04834 (dt) = clamp(e·256 / F, 64, 450)      F = h3:04838 (Time Scale)
    h3:04836      = same with F = h3:00718 (= 20)  h3:0483a = e

**Time Scale** is word 0 of `SIMPREFS.PRF`, held in `h3:03d56`; the archive's value is 40.
`sim:476` (table set up at `sim:45a`) maps slider x ∈ [0, 60] to F = 80 − 70·x/60, so x = 40
gives F = 33. Each tick is worth 1024/F dt units: 31.0 at F = 33.

**Only the world step reads dt.** The readers are helpers:
- `sim:3d68` (x·dt>>8, 69 call sites);
- `sim:3e2e`/`3e5e` (countdowns), `sim:3e4a`/`3e7e` (accumulators);
- `sim:3e0a` and `sim:3e94`.

All ~110 calls per frame come from the `sim:01098` subtree; rendering never reads dt.

**dt was clamped at 450 in every frame of the capture.** The unclamped value was 993–1055 in
steady frames and ~2,180 in redraw frames. At F = 33:

| Frame period | Effect of rendering faster |
|---|---|
| > 14.5 ticks (> ~12.3 fields, below ~4.1 fps): **today** | The world runs at 14.5/ticks of nominal speed: ~44% steady, ~21% in redraw frames. Faster frames make the world proportionally faster in wall time, as well as smoother |
| 3–14.5 ticks (~4.1–29 fps) | dt tracks real time; faster frames are only smoother |
| ≤ 2 ticks (≥ ~29 fps) | The floor of 64 makes the world faster than real time, without limit as fps rises (locked at 64/frame from ~59 fps) |

The thresholds scale with F; at the extremes F = 10 and F = 80 the upper threshold is 4.4 and
35 ticks.

**Things counted per frame instead of per unit of time:**
- **Input:** sampled once per frame; one key event is consumed per poll.
- **Throttle:** ±20 per key command.
- **Gun cooldown** (`h3:045ae`, 1000): time-scaled, but it can only expire on a frame, so at dt
  450 the guns fire once every 3 frames.
- **Message timer** `h3:04820`: starts at 15,000 and drops by 500 per frame at `sim:84e`, so a
  cockpit message lasts **30 frames**.
- **Render-buffer counters.**

**Sound runs in real time:** it is driven by the timer, and `sim:2b1e4` uses the stopwatch
`sim:29760`/`2972c`.

**A useful consequence for validation (to be confirmed in W0.6).** While both builds stay
above 14.5 ticks per frame, dt is exactly 450 in every step. The input tape is indexed by
steps. So the world state at step N should not depend on rendering speed, and an OFF/ON pair
can be compared state for state at equal step numbers.

### 2.5 The cockpit dashboard and its mirror

**What the bitmap is.** The 168×102 five-plane bitmap is bitmap 0 of `EDASH-B.BMP`: the left
half of the wooden dashboard and its rim. Its other bitmap is 24×17.
- **Loading:** the cockpit init script loads it into slot 0 (`$1051 0; $F02F "EDASH-B.BMP"`).
  The loader `sim:301b0` builds descriptors; its decompressor `sim:307ce` fills the planes and
  mask.
- **Descriptor:** +0 planes, +4 mask, +8 width, +10 height, +12 plane size (`$8C4`), +16
  orientation.
  - Rows are 11 words; mask rows are 12.
  - In the file the mask equals OR(planes) and all pad bits are 0, so mirroring twice is an
    exact identity.

**Script 1** (`h3:07b52`[1], run by the picture-script interpreter `sim:28962` from
`sim:15dc8`) draws the dashboard:

| Opcode | Position | Flip | Effect |
|---|---|---|---|
| (rect fill, lines, two `$AF2F` polygons) | | | background |
| `$A522` | (152, 98) | 2 | mirror 0→2 in place, blit at x = 144 (pad −8) |
| `$A502` | (−1, 98) | 0 | mirror back 2→0, blit |
| guns, sight | (61,95), (209,94), (149,88) | 0 | blits |

**Every script-1 run costs exactly two in-place mirrors and ends in state 0.**

**`sim:30408` draws with an orientation** (d2: bit 1 horizontal, bit 0 vertical).
- If desc+16 differs, it calls `sim:304d0` (horizontal) or `sim:3045e` (vertical) and toggles +16.
- Then it adjusts x for the pad and blits through `sim:30572`.
- `sim:30400` is a second entry that branches to `sim:3040a`.

**`sim:304d0`, the mirror**, costs **1,854,000 ± 700 main cycles per call**. It:
1. clears the mask (h × (W+1) words);
2. reverses each 16-bit word with 16 `LSR`/`ROXL` pairs;
3. reverses the word order of each row through the stack;
4. rewrites the planes in place and ORs them into the mask.

Per word, the bit loop is 256 of 323 cycles.

**When the dashboard is redrawn.** Each trigger sets a counter to 2 (`h3:08dce`, one per
display buffer), so every event costs **two frames × two mirrors ≈ 7.4M cycles (~52 fields)**:

| Path | Trigger | Effect |
|---|---|---|
| `sim:668` | View change (`sim:640`: `h3:06712` ≠ `h3:06714` → `h3:06716` = 2), or main-loop argument `h3:07856` | Full redraw |
| `sim:19bbe` in `sim:19ba6` | Dirty rectangle: `sim:197ee` sets `h3:0711c` = 2 and merges the rectangle into `h3:07124` | Script 1, clipped to the rectangle |
| `sim:7de` | `h3:045b8` = 2 when the top-line text `h3:045c0` ends | Script 1, clipped to y 0–65 |

- **`sim:197ee` has two callers, both message events:**
  - `sim:3bf2`: a new message replaces one still on screen;
  - `sim:aac`: a message expires after 30 frames.
- **In the capture:** two full-redraw frames after flight start, then a message replaced at
  field ~62 (dirty rectangle 104–207 × 175–194, two frames). From field 178 there were none.
- **The `sim:7de` path is pure waste** *(to confirm with a breakpoint)*. The dashboard lies at
  y 98–199, so both halves are mirrored and then rejected by the clip test at `sim:305c8`.

**Safety facts** for replacing the mirror:
- **Descriptor access:**
  - `sim:30408` reads and writes +16;
  - `sim:304d0` and `sim:3045e` rewrite the planes and mask;
  - `sim:30572` reads +0..+12 and temporarily writes +8;
  - the loader writes everything.
- **Freeing:** `sim:303ac`/`3038e` free through `sim:303c6`, via FreeMem on the set's first
  descriptor's planes pointer.
- **No other reader** of the planes or mask was found. The mirrored state never outlives one
  script run, and interrupt code never touches bitmaps.
- **Other flip users:** UI corner widgets call the stub `sim:28e38` with d2 = 2 (`sim:25cd6`,
  `25d6c`, `25f50`, `2634a`, `26396`). These are small bitmaps.
- **Register contract:** `sim:304d0` saves and restores d0–a2 and does not touch a3–a6.
  - The caller's `eori.w #2,d0` at `sim:30424` overwrites NZVC.
  - X is dead: an X-defining instruction always comes first.
  - A replacement must preserve d0–a6 and may clobber CCR.
  - Stack: the original uses 44 + 2W bytes; `sim:3045e` already pushes 2,244 bytes, with SP
    deep in a small stack. Keep stack use at or below the original's.
- **The blitter reads both planes and mask** (A = mask or its right-clip copy, B = planes,
  C = D = screen), so **any cached copy must be in chip RAM**.
- **Race:** `sim:30572` returns with plane 4's blit still running. About 1,000 cycles later the
  next mirror starts clearing that blit's A source. The original survives because its clear is
  slower than the blitter. **A faster replacement must WaitBlit on entry.**

### 2.6 The 3D pipeline

Per steady frame: 51 objects tested, 23 drawn, 151 faces (132 drawn), 425 vertex references,
~259 32-bit and ~46 16-bit transforms, ~216 projections. The projection shift is 7 and the
near plane `h3:0a472` = 128 throughout.

| Stage | Routine | Calls/frame | Cycles |
|---|---|---:|---:|
| Object loop | `sim:2c552` | 1 | 2.57M incl. |
| Object position to camera space (9× `3b2d8`) | `sim:3b0f6` | 51 | 139k |
| Projected radius → LOD | `sim:3b282` (→ `38c82` with z = 0: wasted second divide) | 51 | 90k |
| Draw object: path choice, LOD + selection sort, vertex block | `sim:3a902` (`3a34c`, `3a518`, `3a8b4`) | 23 | 2.12M incl. |
| Face loop (self 239k) | `sim:3b41a` | 107 | 1.90M incl. |
| ├ Back-face test (`3b1fa` + 3× `38b24`) | `sim:38eec` | 64 | 196k |
| ├ Vertex cache + transform (`3afbe`) / 16-bit twin (`3aede`) | `sim:38dcc` / `3abe2` | 401 / 62 | 411k / 71k |
| ├ Projection wrapper → `38c82` / 16-bit `divs.w` | `sim:38e9c` / `3acca` | 171 / 44.5 | 301k / 29k |
| ├ Near-plane clip (`38fac` → `38c82`) | `sim:392a4` | 49 | 89k |
| ├ Add screen centre | `sim:3b30c` | 83 | 57k |
| ├ 2D clip (Sutherland–Hodgman, `39df2` × 2) | `sim:39ecc` | 132 | 232k |
| ├ Remove duplicate vertices | `sim:3b398` | 132 | 37k |
| └ Emit: polygon (`39fa0` → `2f292`) / line (`2ea28`) | | 17 / 23.5 | 180k / 66k |

**Contracts of the hot routines:**

**`sim:38c82`** (projection, 1449 cycles per call from `38e9c`)
- **Inputs:** d0 = x, d1 = z, d2 = y (divisor), d3 = k.
- **Outputs:** d0/d1 = sgn(·^y^k)·shift(⌊N15(a)·N15(k)/N16(y)⌋, E(a)+E(k)−E16(y)).
  - N15 normalises into [2¹⁴, 2¹⁵) and N16 into [2¹⁵, 2¹⁶), one bit per loop iteration.
  - The final shift count is taken mod 64.
  - a0/a1 = x^y^k and z^y^k on exit.
- **Errors:** y = 0 traps.
- **Flags** are dead at all four call sites (`38e9c`, `38fac`, `3b282`, `3b2a8`).
- **Operands:** k = `$80` in 92% of calls, which spends 266 cycles on seven `lsl`s every call.
- **Where the cycles go:** normalisation 660 of 1449, mul/div 359.
- **Model:** a Python model reproduces all 486 traced calls.

**`sim:38dcc`** (vertex cache, d0.w = vertex index)
- **Hit** (`h3:0a4e6`[i] ≠ 0): copies the cached x/y/z (`h3:0a5e6`/`0a9e2`/`0adde`) to
  `h3:0a4c6`.
- **Miss:** transforms with `sim:3afbe` (M·v >> (14 − `h3:0a344`); nine `muls`, about 490 of
  960 cycles). Then adds the object position `h3:0a448..0a450` and stores.
- **Observed:** hit rate 35% (32-bit path). The cache is cleared per object by `sim:3a8b4`, and
  no vertex was transformed twice. vz = 0 in 86% of transforms.

**`sim:3b1fa`** sums three exact 64-bit products from `sim:38b24`, but returns only the low
long, and the caller tests only its sign.

**`sim:3b2d8`** equals ⌊|v||n|/2¹⁴⌋ only while |n| ≤ 2¹⁴. The largest observed |n| is 16,380.
Keep the quirk.

**`sim:39ecc`** forces full 2D clipping in the cockpit view (`h3:0a45c`). Of 264 traced calls:

| Class | Calls | Cycles each |
|---|---:|---:|
| Accept everything | 33 | 2,307 |
| Reject in x | 48 | 1,214 |
| Empty on entry | 39 | 640 |
| Really clipped | 12 | 6,068 |

- **Quirk to preserve:** the upper-bound compare uses a register whose high word comes from
  `ext.l` of the lower bound.
- **Bounds:** the self-modified words at `sim:39d4c`.

### 2.7 2D primitives and the blitter

| Routine | What it does | Calls/frame (steady) | Cycles/call |
|---|---|---:|---:|
| `sim:2ea28` | Clipped line (Cohen–Sutherland), blitter line mode, one blit per plane | 58 | 2.2k |
| `sim:2fc68` | Clipped solid rectangle: per-plane C→D fill with edge masks. Used for struts, sky (`2cddc`) and ground (`2cf90`) | 11 | 10.5k |
| `sim:30572` | Clipped cookie-cut bitmap (minterm `$CA`). The right-clip path copies the mask into the scratch at `h3:09d76` | 11.5 | 4.7k |
| `sim:2f292` | Polygon: edges into scratch (`2f8c4`, 51.5 calls at 0.65k), area fill, per-plane merge, erase | 18 | 10.3k |
| `sim:2c144` | Front-view overlay: OwnBlitter, 5 ABCD blits of 320×72, DisownBlitter | 1 | 48.2k |

- **BLTPRI ("blitter nasty") is set** in DMACON in every field, so the CPU stalls inside the
  first `btst`.
- **Poll share by routine:** `2fc68` 2.61%, `2f292`+`2f8c4` 1.75%, `2ea28` 1.40%, `2c144`
  1.22%, `30572` 0.78% of steady cycles.
- **No cheap overlap exists.** The waits already follow the setup arithmetic, with only a few
  instructions between consecutive planes' blits.

### 2.8 Sound and interrupts

**The driver.** `amigasnd.drv` is a 4-voice sample driver with a MIDI-like interface: no
software mixing or synthesis.
- **Entry:** `sound:0028` → dispatcher `sound:0308`. d7 is the function number, the table is at
  `sound:02c0`, and the driver base is in a4.
- **Functions seen:**
  - 3: tick (`0a66`);
  - 7: controller;
  - 10: pitch bend;
  - 14: note-on;
  - 16: per-sound volume/loop update (`0e2a`).

**L4, sample streaming.** The samples are in fast RAM, so each voice streams through two
224-byte chip buffers.
- The per-channel stubs are `sound:1cb8/1d0c/1d64/1dbc`. They alternate between the fill
  routines `sound:1984` and `sound:1b1e`, which copy 56 `move.l`.
- **Cost per service:** 3,071 cycles, of which:
  - copy 1,168;
  - register save/restore 391;
  - bookkeeping 543;
  - stub 276;
  - OS dispatch ~554.

**L6, the tick: 10,533 cycles.**

| Part | Cycles/tick |
|---|---:|
| OS dispatch | 1,014 |
| `sim:2ffcc` dispatcher | 396 |
| `sim:34d96` object walk; calls the bare-`rts` `sim:34e54` once per object | 844 |
| `sim:34d26` volume-queue scan; no entry was pending in the capture | 1,439 |
| `sim:34e56` → driver function 16 | 1,339 |
| `sound:0c10` volume: three `divu.w #63` at 133 cycles each | 2,384 |
| `sound:0abc` envelope | 669 |
| `sound:0a66` voice loop | 613 |
| Driver dispatcher, `sound:0e2a`, VOL write, rest | ~1,800 |

**How it scales:** about 5% of a 7 MHz 68000 per active voice (L4 + L6) and about 4% with no
voices *(est.)*; four voices could reach ~24% *(est.)*.

**Engine pitch** is not a per-tick cost: there was one function-10 call per rendered frame
(`sim:33ff4`).

## 3. Measurement protocol (every item)

1. **One build, two settings.** Build once and vary only CUSTOM2 (`WHD_ARGS="CUSTOM2=…"`, which
   `amiga/run.sh` passes to WHDLoad). Keep the slave and its listing with each capture.
2. **Fixed windows** (W0.4) on **three machines**, one capture at a time. Use the existing
   68000 + fast configuration only for continuity with `profiling.md`.

   | Machine | Settings |
   |---|---|
   | A500-equivalent | `CPU=68000 CHIP_KB=512 FAST_KB=0 EXTRA_ARGS=--slow_memory=1536`. The game's "fast" memory then lands in slow RAM, so expect different costs. Check that it boots, and whether `PRELOAD` still fits the data volumes |
   | 14 MHz 68020 | `AMIGA_MODEL=A1200 KICKSTART=$KICKSTART_A1200 CPU=68EC020 CHIP_KB=2048 FAST_KB=8192 EXTRA_ARGS=--slow_memory=0` |
   | 68030/50 | `SWAP_ONLY`/step log only (no instruction trace); see the playbook §8 for the cycle-exact options |

3. **Frame rate** comes from the swap counter `sim:3154a` (`frames.py` over a trace, breakpoints
   for `SWAP_ONLY`), cross-checked with the VERIFY step log's tick counts (W0.3).
   - A 100-field trace holds only 2–4 frames, so quote fps from step-log runs of ≥ 2,000 fields.
   - Use traces for cycles.
4. **Routine cost:** compare **cycles per completed call**, main context separate from
   interrupts, and exclude calls cut by a window or chunk boundary.
   - Mirror: cycles per `sim:304d0` call, and per dashboard event.
   - Geometry: cycles per drawn face and per frame of `sim:2c552`.
   - Sound: cycles per tick and per L4 service.
5. **Behaviour.**
   - **While both builds stay clamped** (frames > 14.5 ticks), compare `h3` snapshots at equal
     step numbers (W0.6).
   - **Once the ON build drops below 14.5 ticks per frame**, the states legitimately diverge.
     Then rely on twins and models, and on first/last screenshots of the same step.
6. **Correctness comes from VERIFY self-tests, twins and Python models, not from A/B.**
7. **Recording results.** Put the current numbers and the commands that reproduce them in
   `profiling.md`, updating it in place: docs describe the current state.
8. **Size threshold.** Skip anything worth under 3% of a frame unless it is free.
   - Before writing a candidate, bound its cost by summing its instructions' cycles.
   - Re-measure on the 68020: a change that helps the 68000 can do nothing on a 68020, or the
     reverse. Keep the original code on CPUs where the replacement does not measure better.

## 4. Work items, in order

Order:
1. W0 groundwork.
2. W1 (the mirror), then W2 (geometry).
3. W5 (tear-free swap and frame cap).
4. W6, the frame-rate-independent game speed. Its investigation can run alongside W1–W2 once
   the W0.6 observers exist.
5. W4 and W7 later.

W3 (sound) is deferred.

### W0. Groundwork (required before any patch)

Most of this is the playbook's §12 "ready to improve" list, which Red Baron does not yet meet.

**W0.1 Rebuilt-slave equivalence.** Compare the rebuilt, unmodified normal slave with the
shipped 2.1 slave.
- Find a fixed point both can reach without the tape: the opening sequence after N fields in
  warp with `DETERMINISTIC=1`.
- Compare the screenshot and chip RAM, and list any expected differences.

**W0.2 Capture continuity.** Consecutive `profile` commands appear to lose one field: the tick
countdown drops by 8 and 12 across the 99/100 and 199/200 boundaries.
- **Confirm it:** read `sim:30006` around each boundary, or capture 100 fields once and as
  50 + 50.
- **If confirmed:**
  - mark boundary fields as gaps in `trace_series.py` and in every report;
  - correct `profiling.md` (true periods 59.2/60.0/27.1/28.8 fields; mirror share 31.3%, not
    30.96%);
  - make `profile_flight.py` default to windows of at most 100 fields, or flag its chunk joins.

**W0.3 Frame counter and per-step log.**
- **`tools/frames.py`:** counts `sim:3154a` executions per field; field and line of each swap.
- **`tools/swap_fields.py`:** a read-only breakpoint at `sim:3154a` for CPUs without a trace.
- **A VERIFY-only per-step ring buffer**, written from the existing `tape_flight` hook (which
  already runs once per iteration). Per step it records:
  - `sim:30006` (lifetime ticks);
  - `h3:0483a` (e) and `h3:04834` (dt);
  - the display pointer `h3:09d66` (a change means a swap);
  - the dashboard counters `h3:06716`, `h3:0711c` and `h3:045b8` (a value of 2 marks an
    event, W0.5).

  It is read back with `gdb dump` at the end of a run. This gives fps, tick periods and event
  counts over thousands of fields at full emulator speed on any CPU.
- **Acceptance:** trace, `SWAP_ONLY` and step log agree on the same window.

**W0.4 Windows and machines.**
- **Reproducibility:** check that two fresh boots of the same window are identical in every
  instruction record, DMA record and screenshot (the playbook's `compare_traces.py`).
- **The windows to build:**
  - **R-event:** the current ace fixture, which contains a dashboard event.
  - **R-steady:** a window of ≥ 4 frames with no dashboard event. Find a mission or anchor with
    no messages, using the step log to check.
  - **R-bank:** the existing `--bank` fixture (Right held at steps 20–34), for different
    geometry.
  - **R-dense:** many aircraft in view, for geometry scaling.
- **Baselines:** fps and per-routine costs for R-steady and R-event on all three machines.
- **Tearing on the 68020 and 68030:** from traces, the first framebuffer write after each swap
  against the copper pickup; on the 68030, a VERIFY-logged VPOSR at the first draw after the
  swap.

**W0.5 Dashboard event census.** Over a full mission in warp, count dashboard events from the
per-step log's counters. Confirm the attribution with breakpoints on:
- `sim:197ee`, `sim:668`, `sim:7de`, `sim:3ba2`;
- `sim:304d0`, and rejects at `sim:305c8`.

That decides how much of real play W1 removes, compared with W2.

**W0.6 Game-time observers and the coupling test.**
- **State snapshots:** snapshot `h3` at a given step (`STATE_ONLY`), and compare with an
  adaptation of Their Finest Hour's `compare_state.py`, which treats pointers into `sim` at
  equal offsets as equal.
- **Step-locked equality (§2.4):** a VERIFY-only slowed-drawing delay (an extra busy-wait in
  `sim:2c552`'s caller) must leave the `h3` state at step N unchanged while frames stay above
  14.5 ticks.
  - If the state differs, find the coupling (RNG from timers, sound feedback, dt-free state)
    before relying on state comparisons.
- **Meaning of nominal speed:** log the player's position and airspeed per step at Time Scale
  0, 40 and 60 to establish what "nominal" dt means in real time.

**W0.7 Patch framework.**
- **Interface version:** raise `slv_Version` to 17 and add `slv_config`, as `testdrive2` did.
  This follows from decision 1: one splash-window switch, so the ReadMe requires WHDLoad 17+.
  `PL_IFCx` needs WHDLoad 17.2.
- **CUSTOM reads:** read these with `resload_Control` before the sim patch list is applied:
  - CUSTOM2. In release builds any nonzero value selects every verified bit: this is the single
    "faster rendering" switch. In developer/VERIFY builds it is the per-item mask below.
  - CUSTOM5, the VERIFY instruments.
  - `WHDLTAG_ATTNFLAGS_GET`, for the CPU.
- **Version restriction:** apply performance sublists only in the v1 branch of
  `SIM_VERSION_TEST`.
- **Byte checks:** at install time, verify the original non-relocated bytes of each hook range,
  and abort with `TDREASON_FAILMSG` on a mismatch (Legends of Valour's practice).
- **Sound driver hooks:** not needed while sound is deferred (decision 4). Later, confirm
  whether `amigasnd.drv` arrives through `LoadSeg`. If it does, add an `am…` name test to
  `_cb_dosLoadSeg`; if it is read raw, hook the `sim` call that starts it.
- **Builds:** add normal, `DEVELOPER` (individual switches) and `VERIFY` modes to
  `tmp/dev/tools/build.sh`, with separate outputs, and update `Makefile_windows.mak`.
- **Checker tools:**
  - **`tools/check_disabled.py`** compares every `PERF_RANGE` with the original `sim` hunk 0,
    using the relocation table and the live hunk bases from a dump.
  - **`tools/audit_hooks.py`** lists static branch targets and relocations inside each range
    (Test Drive 2's `audit_simulation.py`).

**W0.8 Twin and model infrastructure.**
- **VERIFY copies of originals:** the VERIFY build keeps runtime copies of each original body it
  replaces, so it can run original against replacement on copies of the same inputs and compare
  outputs, preserved registers, live flags and SP.
  - `sim:304d0`, `38c82` and `39df2` are self-contained (absolute or internal references only).
  - Check each body for PC-relative references to the outside before copying it.
- **Python models** for each replaced routine, as in Their Finest Hour's `xform_check.py`:
  first check them against the original's traced calls, then against the replacement in the
  fixed window.

**Proposed CUSTOM2 bit map.** This is for developer/VERIFY builds. Release builds expose only
the single switch (decision 1), which turns on every bit that has passed its verification.

| Bit | Item | CPUs |
|---|---|---|
| 0 | W1a table-driven mirror | all |
| 1 | W1b pre-mirrored chip copy (falls back to bit 0's routine if set, else the original) | all |
| 2 | G1 projection normalisation | 68000/10 code, 68020+ variant |
| 3 | G2 + G7 clip fast paths | all |
| 4 | G3 vertex transform in registers | all |
| 5 | G4 back-face dot product | 68000 code, 68020+ variant |
| 6 | G5 + G6 face loop and object setup in registers | all |
| 7 | D1 D-only fills | all |
| 8 | P1 tear-free swap | all (decision 5) |
| 9 | P2 frame cap | all (decision 5) |

W6, the frame-rate-independent game speed, gets its own bit once its design is approved.

### W1. Dashboard mirror (`sim:304d0`)

The largest single cost, but it is event-driven: it removes ~52 fields per dashboard event.
Do W1a and W1b back to back.

**W1a: table-driven exact mirror (bit 0).**
- **Hook:** `PL_P $304d0`. It replaces `movem.l d0-a2,-(sp)` + `movea.l (a0)+,a1` (6 bytes),
  whose only caller is `sim:30420`. The replacement does the whole job and returns with `rts`
  to `sim:30424`.
- **Algorithm:**
  1. WaitBlit (double `btst`) on entry.
  2. Clear the mask exactly as the original does (h × (W+1) words; the last word of each mask
     row stays 0).
  3. Per plane (count from `h3:09d3c`; 4-plane modes exist, see `sim:2f342`) and per row:
     - reverse the row's bytes through a 256-byte bit-reversal table into a W-word scratch
       row, working backwards:

           move.b (a1)+,d0
           move.b (a3,d0.w),-(a4)

       twice per word, with d0 bits 8–15 kept 0 (52 cycles per word);
     - copy the scratch row back:

           move.w (a4)+,d2
           move.w d2,(a1)+
           or.w d2,(a2)+

       (28 cycles per word);
     - skip the extra mask word.
  4. Preserve d0–a6.
- **Placement:** the table and scratch live in the slave (the scratch holds W ≤ 20 words for a
  320-pixel row). Generate the table at boot or assemble it.
- **Cost** *(est.)*: 0.50M per call unrolled, 0.62M with `dbf`, against 1.854M. That saves
  ~5M cycles (~35 fields) per dashboard event.
- **Verify:**
  - a VERIFY boot self-test of all 65,536 words, table against the original
    `LSR`/`ROXL` sequence executed on the CPU;
  - a twin on copies, comparing planes, mask, registers and SP. Inputs: `EDASH-B`; random
    bitmaps of width 1–320 (multiples of 16 and not) and height 1–200, with 4 and 5 planes,
    nonzero pad bits, and masks that differ from OR(planes);
  - a live twin on every call in R-event.

**W1b: pre-mirrored chip copy, never mutating the game's buffer (bit 1; the end state; chip
RAM use is approved, decision 3).**
- **Hook:** `PL_PS $30412` over `swap d0` + `move.w 16(a0),d0` (6 bytes). It cannot go at
  `sim:30408`, because `sim:30400` branches into `sim:3040a`; audit `sim:30412–30417`.
- **When a cached draw applies:** the horizontal bit differs (`(req ^ desc+16) & 2`) and
  neither the request nor desc+16 has bit 0 set. Then:
  1. build the cache entry on first use (§ below);
  2. copy the 18-byte descriptor to the stack, pointing its +0/+4 at the cache;
  3. load d0 = `(req & 3) << 16 | (x − pad)` and d1 = y, exactly as `sim:30438–30454` would;
  4. `bsr` `sim:30572`;
  5. restore a0 to the real descriptor and return to `sim:3045a`.

  Desc+16 and the game's planes stay untouched. Otherwise, run the two replaced instructions
  and continue the original path.
- **Cache entry:**
  - **Key:** descriptor address, +0, +4, width, height, plane size and `h3:09d3c`.
  - **Memory:** planes + mask of the mirrored image, `AllocMem(MEMF_CHIP)`: 13,668 bytes for
    `EDASH-B` against ~123 KB free in the capture.
  - **Build** once per bitmap-set load with the W1a routine on a copy, never in place.
  - **Game mask:** at build time also set the game's mask to OR(planes). The original leaves it
    in that state after its first mirror; for `EDASH-B` it is a no-op.
  - **Size limit:** cache only bitmaps above a threshold (the UI corners stay on W1a or the
    original).
- **Invalidation:** hook `sim:303c6` to free and drop any entry whose descriptor set is freed.
  A vertical-flip request drops the entry and takes the original path. If `AllocMem` fails, use
  W1a.
- **Cost** *(est.)*: ~0.3k cycles per flip plus ~0.5M per bitmap-set load. That removes the
  whole ~7.4M per event; redraw frames should fall to near a steady frame plus the clipped
  script blits.
- **Verify:**
  - at build time, compare the cache with the original `sim:304d0` run on a scratch copy;
  - a VERIFY pixel twin per cached draw: draw through both paths into the real and a shadow
    framebuffer, compare all planes, and check desc+16;
  - an event census before and after.
- **This also removes the `sim:7de` waste.** Without W1b, an optional W1c skips the mirror when
  `sim:30572`'s clip test would reject the whole blit.

### W2. Geometry (`sim:2c552` subtree)

Every frame pays for it; these candidates total ~600k per steady frame *(est.)*.

**Rules for every item:**
- Bit-exact outputs, with the documented dead registers and flags.
- A Python model checked against traced originals first.
- A VERIFY twin comparing outputs, preserved registers and live flags on every call in R-steady
  and R-bank.
- Exhaustive host checks where the domain allows.
- Paths with no trace coverage must be covered by synthetic twin inputs: `sim:3b2d8`'s corner
  projection, matrix types 0 and 1, `h3:0a344` values other than 7/3/2/1, and s ≠ 7.

| # | Change | Saving/frame *(est.)* | Exactness | Verification |
|---|---|---:|---|---|
| G1 | `sim:38c82` family (with `38e9c`, `3b282`): bit-length normalisation from a table instead of 1-bit loops; a k = 2ˢ fast path (N = 2¹⁴, E = s − 14, s ≤ 30); early out on zero operands; no second divide when z = 0 in `3b282`; fewer saved registers; `38e9c` folded in | 150–200k | Same N/E values; the same `mulu.w`/`divu.w`; same shifts mod 64; `lsl` overflow, the y = 0 trap and a0/a1 kept | Host: loop vs table normalisation for all 2³² inputs at widths 15/16. Model strata (bit length × sign × edge values). Live twin on d0/d1/a0/a1 |
| G2 | `sim:39ecc` trivial paths: n ≤ 1 → empty; all outcodes 0 → unchanged; all x (or y after an all-inside x pass) codes equal and nonzero → empty; else original | ~120k | Sutherland–Hodgman copies an inside polygon in order and emits nothing when all vertices are out on one side. Must still write `h3:0b9e6`, the bounds at `sim:39d4c` and `h3:0ba88`, with the same `move.w`/`ext.l` compare (quirk) | Host model on random polygons n = 0–8 around the bounds; live twin of `h3:0b9e6`, `h3:0b9e8`/`0ba38`[0..n) and `sim:39d4c` |
| G3 | `sim:38dcc` + `3afbe` merged in registers (`movem.w` load, shift count once, skip zero-coordinate products, direct stores); likewise `3abe2`/`3aede` | 80–100k + 20k | Same `muls`/`add`/`asr`, addition mod 2³², 0·m = 0. Keep the flag, the tables, `h3:0a4c6..0a4ce` and all three matrix types | Twin restoring `h3:0a4e6`[i]; compare tables, `h3:0a4c6..`, registers |
| G4 | `sim:3b1fa` as a low-32 dot product: 3 × (2 `mulu` + sign), no `38b24` | ~70k | Modular identity. d1 at return differs and is dead: document it | 10⁷ random host cases plus edges (`$80000000`); live twin on d0 |
| G5 | `sim:3b41a` vertex loop in registers: list pointer, count, table bases and near bound; inlined cache-hit test | 70–85k | Keep `h3:0b9d2`/`0b9e6`, the flag semantics and dispatch through `h3:0a41e..0a42e` | Per-face twin. Moderate risk: this is the hub |
| G6 | Inline the nine `sim:3b2d8` calls in `sim:3b0f6`, quirk included | ~50k | Same instructions | Twin |
| G7 | Early out when every vertex of a face is behind the near plane: `h3:0b9e6` = 0, skip `392a4`/`39ecc`/`3b398` (39 such faces/frame) | ~35k beyond G2 | `392a4` emits nothing in that case | Twin |
| G8 | Register rewrites of `sim:3a518`/`3a902` (compiled C) | 40–80k | — | Twin. Low priority |
| G9 | `sim:3a8b4` flag clear with longs/`movem` | ~10k | — | Twin |

- **Not recommended:** reciprocal tables or a quotient cache for `divu` on the 68000. The
  divisors are per-vertex depths, so there are no hits, and `mulu` + correction costs more
  than `divu`.
- **Changes that would alter the image** (out of scope unless the user asks):
  - frustum rejection before projection;
  - moving objects to the 16-bit path;
  - clearing `h3:0a45c`;
  - replacing the `sim:39f5c` bisection with a divide;
  - "fixing" the bound or multiply quirks.
- **68020+ variants** (measure; keep the original if there is no gain):
  - `sim:38c82`: `bfffo` per normalisation, keeping `mulu.w`/`divu.w`. `divu.l` would change
    rounding.
  - `sim:3b1fa`: 3 × `muls.l`.
  - `sim:38b24`: `muls.l d1,d1:d0`.
  - `sim:3b2d8`: `mulu.l` to 64 bits, guarded by |n| ≤ 2¹⁴.
  - G2, G5 and G7 are CPU-neutral.

### W3. Interrupt and sound tax (exact output): deferred

**Deferred by decision 4:** sound stays exactly as it is for now and will be analysed later. Do
not implement S1–S9 or B1–B6 without a new decision. The analysis is kept here for that work.

Fixed cost per second, so the saving applies to every scene. Main-loop wall time scales by
1/(1 − tax): from 15.1% to ~11% is ~1.05× everywhere *(est.)*.

| # | Change | Where | Saving *(est.)* |
|---|---|---|---:|
| S1 | Fast path when all 16 queue bytes are `$ff` (four long compares). The original then only rewrites the index at `sim:3335e`; the caller ignores flags | `sim:34d26` | 1.07% |
| S2 | Interrupt-only fill entry saving only d3/a2/a3 (the stub and exec save the rest). Keep the full-save entry, because note-on calls `sound:1984` from L6 | `sound:1984`, `1b1e` | 0.59% |
| S3 | `divu.w #63` → `addq.w #1; mulu.w #$1041; swap; lsr.w #2`. Exact for n ≤ 65,025 (checked for every n; fails only at 65,535), and the remainder is never read. **Prove the n bound** from the operand ranges, or guard it | `sound:0c56/0c7c/0ca0` | 0.46% |
| S3′ | Alternative to S3: memoise `sound:0c10`'s result per voice on all four inputs; still write VOL and `660(a4)` | `sound:0c10` | 0.9% |
| S4 | Precomputed per-channel pointers instead of the shift/`lea` chains. Check first whether anything else reads the LEN tables at `sound:5338`/`5346` | fill routines | 0.45% |
| S5 | `sim:34e56` calls driver function 16 directly (a4 set), skipping the dispatcher | `sim:34e56` | 0.3% |
| S6 | 56 `move.l` → `movem.l` blocks | fill routines | 0.27% |
| S7 | Hoist the byte-swapped pointer arithmetic, unused on the common path | `sim:34e9e–34ebe` | 0.25% |
| S8 | Save only the registers each routine uses | stubs, `sound:0abc` | 0.39% |
| S9 | Drop the `jsr` to the bare `rts` at `sim:34e54` | `sim:34d96` | 0.09% |

- **Verification:**
  - **Paula log:** compare the per-register ordered value sequences, the CPU writes in the
    trace's DMA records (type 2, reg `$1100`). The interleaving of L4 and L6 may shift.
  - **Audio fetches:** compare the per-channel `AUDxDAT` fetches (type 4).
  - **Strict proof:** a VERIFY twin per tick/service: snapshot the driver state (a4 + 0…`$1500`),
    run the original copy against a shadow custom-register block, run the candidate live, and
    compare buffers, state and the written register values.
- **Behaviour or OS changes, for the user to decide (not recommended by default):**
  - **B1:** own level-4 autovector, keeping the AUD1, AUD3, AUD0, AUD2 service order: 0.75%.
  - **B2:** own CIA-B handler instead of `ciab.resource`: 0.68%.
  - **B3:** 448-byte buffers: 1.6%.
  - **B4:** samples in chip RAM with hardware looping: costs scarce chip RAM and changes looping.
  - **B5:** skip repeated VOL writes: 0.2%.
  - **B6:** a lower tick rate, which changes envelope timing.

### W4. Drawing primitives (small)

- **D1:** D-only blits for full-width sky and ground fills (`sim:2cddc`, `2cf90` via
  `sim:2fc68`): ~0.6–0.8% of steady time *(est.)*. Verify with a pixel twin of the framebuffer
  after the fill.
- **Keep:** the doubled `btst` and BLTPRI.
- **Later only:** queueing `sim:2c144`'s overlay blits so the next frame's world step overlaps
  them (≤1.2%, complex).

### W5. Display pacing and fast CPUs

Both apply under the faster-rendering switch (decision 5). W0.4's measurements choose the cap
rate and give P1's cost.

- **P1, tear-free swap (bit 8).** Use the game's own wait: `PL_W $b06,$7001` (`moveq #1,d0`
  before the swap).
  - It writes the copper pointers either at or above line 40, or after line 244, so the
    just-hidden buffer is no longer displayed when drawing resumes.
  - Cost: up to ~0.65 field per frame, ~0.2 on average *(est.)*.
  - On the 68000 it only costs time, because the measured margin is 3–4 fields. Measure that
    cost; if it is significant, report it to the user instead of quietly limiting P1 to fast
    CPUs.
  - Verify by trace: no write to the displayed buffer between the copper pickup and line 243.
  - Alternative, for unseen frames: Their Finest Hour's CUSTOM3 pattern, a VBL-side swap
    request plus a wait before drawing into the pending buffer.
- **P2, frame cap (bit 9).** Hold the swap until a minimum number of fields has passed since
  the previous one. Two fields gives 25 fps, which is also the ceiling of the tear-free swap's
  usual cadence.
  - **Why it matters:** above the cap, dt's floor of 64 makes the world run faster than real
    time, and frames swapped out before line 42 are never seen.
  - **What it does not fix:** the floor binds whenever a frame is shorter than F/16 ticks. A
    25 fps cap (2.37 ticks) therefore protects only Time Scale settings of 36 and above
    (F ≤ 37.9); the archive's 40 is covered. Lower Time Scale settings need W6.
  - **Implementation:** wait on a field counter kept by the slave (a VERTB hook, or the CIA
    lifetime ticks at `sim:30006` converted to fields) next to P1's wait, in the same routine.
- **68020+ caches:** the slave defines KickEmu's `CACHE`. Record the cache state of every fast-CPU
  figure (playbook §8). The self-modified words at `sim:39d4c` are read as data, so they are
  safe with an instruction cache.

### W6. Frame-rate-independent game speed (the goal; investigate first)

**Goal (decision 2):** for a given Time Scale, the world runs at the same wall-clock speed at
any frame rate and on any machine.

Until this lands, every rendering speedup also speeds up the world on slow machines, because
dt is clamped at 450 while frames exceed ~12.3 fields (§2.4). That is accepted as an
intermediate state.

**Known couplings to remove** (§2.4):
- **Slow machines:** the dt clamp at 450 (`sim:3d16/3d1c`).
- **Fast machines and low Time Scale:** the dt floor of 64.
- **Counted per frame:**
  - the message timer (30 frames);
  - gun-cooldown expiry, which can only happen on a frame;
  - the throttle step of ±20 per key command;
  - the render-buffer counters.
- **Input:** sampled once per frame.
- **Lag:** dt is measured over the previous frame.

**Investigation, before any design.** It builds on the W0.6 observers. Write the findings and
a recommended design into a new `docs/game-time.md`, and get the user's approval before
implementing.

1. **What dt means.** Establish dt in real time for each Time Scale, from per-step position,
   airspeed and heading logs at Time Scale 0, 40 and 60, and decide what "nominal" speed is.
2. **Inventory.**
   - List every dt reader: the helpers `sim:3d68`, `3e0a`, `3e2e`, `3e4a`, `3e5e`, `3e7e` and
     `3e94`, plus any direct reads of `h3:04834`/`04836`.
   - List every per-frame counter or decrement in `sim:01098`, `sim:0056c` and the input path.
   - Find what reads the F = 20 clock `h3:04836` (`sim:21b6e`, `1577e–1589a`, `5a82`/`5b0c`).
3. **Step-size behaviour.** In VERIFY, force dt (patch `sim:3cee`'s clamp) to 225, 450, 900
   and ~2,200 over the same input. Compare trajectories against small-step references:
   flight model, ground contact, bullet hits (tunnelling), AI and collisions. Look for integer
   truncation at small dt, which Their Finest Hour found at large T.
4. **Coupling test in the tracking regime** (3–14.5 ticks per frame, e.g. on the 68020 or with
   a VERIFY delay). Compare world state at equal wall time between a fast and a slowed build,
   rather than at equal steps.

**Candidate designs** to evaluate with that evidence:
- **(a) Sub-stepping.** When the frame's dt exceeds 450, run the world step `sim:01098` k
  times with dt/k ≤ 450, so each step stays inside the original's tested range.
  - Time Compress already runs several world steps per render (§2.2).
  - Cost on the 68000: one extra world step (0.28–0.36M) per sub-step. At today's ~27 fields
    per frame that is k ≈ 3, about +25% of the frame *(est.)*, so it competes with W1/W2's
    gains.
- **(b) Fixed world ticks with catch-up,** as in Legends of Valour's 25 Hz simulation: a
  per-tick input history and catch-up ticks that skip rendering.
- **(c) Variable step with the clamp raised,** as in Their Finest Hour's per-frame T: only if
  the step-size tests show the flight model is stable and accurate at large dt.
- **Per-frame counters:** convert them to time where the original intent is time (the message
  duration) or keep them per world step.
- **High frame rates:** remove or lower the floor, keeping any truncation in check with
  fractional accumulators. P2's cap limits how small dt gets.

### W7. Later, only with measurements

- **World step `sim:01098`** (~9% of a steady frame) and its object loop `sim:11c2c`: not yet
  analysed.
- **Instruments `sim:15e96`** (~5.5%): three picture-script runs per frame. Find out whether
  unchanged gauges are redrawn. Skipping them would be an algorithmic change; analyse it first.
- **The other mirror users** (`sim:28e38` UI corners) and `sim:3045e` vertical flips, if the
  census shows them.
- **Sound (W3)**, when the user reopens it.
- **A500-equivalent memory:** with the code in slow RAM, recheck every saving, the blitter
  interplay and the interrupt tax (it is likely higher; the driver's code and samples contend
  for the chip bus).

## 5. Expected outcome (*estimates*, to be replaced by measurements)

These are for the measured 68000 + fast configuration; the A500-equivalent needs its W0.4
baseline first.

| Scene | Today | After W1b | After W1b + W2 |
|---|---:|---:|---:|
| Steady frame | 27–29 fields | unchanged | ~23–25 fields (~2.0–2.2 fps) |
| Dashboard event (2 frames) | ~59–60 fields each | ~27–30 each | ~23–25 each |
| The 250-field fixture | 5 frames | ~9 | ~10 |

**World speed.** Until W6 lands, it stays clamped and rises with fps: from ~44% to ~51% of
nominal in steady flight, and it roughly doubles during dashboard events. W6's goal is
nominal speed at any fps; its cost (e.g. sub-steps) comes out of these gains.

The 68020 has not been measured. It should gain more from W1 (the mirror is CPU-bound), and
P1/P2 apply there.

## 6. Decisions (user, 2026-10-09)

1. **One "faster rendering" switch** for players.
   - It turns on every verified performance bit; developer/VERIFY builds keep the individual
     bits for A/B work.
   - Shown in the splash window through `slv_config`, which means WHDLoad interface 17
     (WHDLoad 17+), as in Test Drive II.
   - **Still open:** the switch's default state, and whether the icons enable it.
2. **Game speed:** the ultimate goal is frame-rate-independent game speed. It needs
   investigation first (W6). Until then, faster frames raising the world speed on slow machines
   is an accepted intermediate state.
3. **Chip RAM use is allowed** (W1b's ~13.7 KB cache).
4. **Sound is kept as it is for now** and will be analysed later. W3 is deferred: no S or B
   changes.
5. **The tear-free swap and a frame cap apply** (W5, under the switch). The cap rate and P1's
   68000 cost come from measurement.

## 7. Local evidence (ignored, this machine)

| What | Where |
|---|---|
| Baseline capture, reports, RAM dumps, screenshots | `tmp/dev/tmp/prof/baseline/` (see `profiling.md`) |
| Live disassembly of hunk 0 (`sim-live.dis`) and the range printer `r.py` | `tmp/dev/tmp/plan/` |
| Per-frame window reports | `tmp/dev/tmp/plan/report-steady-178-231.txt`, `report-mirror-60-117.txt` |
| Frame loop and swap analysis | `tmp/dev/tmp/plan/frame/` (`frames.py`, `pipeline.py`, `waits.py`, `dmawrites.py`, `frames.json`) |
| Dashboard bitmap and decompressor | `tmp/dev/tmp/plan/cockpit/` (`cockpit-composite.png`, `lzns.py`, `extract.py`, `waits.py`) |
| Geometry call tree and models | `tmp/dev/tmp/plan/geometry/` (`model38c82.py`, `tree.py`, `out-*.txt`) |
| Interrupt and sound passes | `tmp/dev/tmp/plan/sound/` (`pass.py`, `ann.py`, `paula.py`, `div63.py`) |

None of these is shipped; any of them can be regenerated from the baseline capture.
