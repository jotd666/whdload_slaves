# Hard Drivin' performance investigation

These findings apply to the SPS 0126 variant supported by `HardDrivinHD.s`.
Game addresses below are offsets into its decompressed code (length `$11a4e`),
not runtime addresses. No performance optimization has been implemented.

## Repeatable attract baseline

The measured machine is PAL A500-equivalent, cycle-exact 68000, with 512 KiB
Chip RAM, 1,536 KiB slow RAM and no true Fast RAM. WHDLoad PRELOAD is enabled;
CUSTOM2 is zero. Host input is disabled during the deterministic capture.
Warp affects host throughput, not the emulated time reported here.

The start anchor is `$10844`, immediately after the initial eight-step dissolve
into the clean cockpit view. Capture starts at the following PAL field boundary,
less than one field later. The high-score overlay appearing around ten seconds
is included; driving continues beneath it.

| Measure | Baseline |
| --- | --- |
| Consecutive PAL fields | 1,000 |
| Emulated CPU clocks | 142,102,000 |
| Emulated duration at 7,093,790 Hz | 20.031887 seconds |
| Completed display-buffer swaps | 129 |
| Displayed frames / whole capture duration | 6.4397 FPS |
| First-to-last swap interval rate | 6.4609 FPS |
| Intervals between completed frames | 6–11 fields |

Two fresh-boot captures match in every instruction record, DMA record and
screenshot in all 1,000 fields. Before/after Chip and slow RAM snapshots also
match byte-for-byte. A third run using read-only breakpoints, without instruction
tracing, reproduces every swap in the same field. The VBL handler executes
1,000 times. Input files retain their pristine hashes.

Define `VERIFY_ATTRACT` when assembling the slave to enable the benchmark startup
fixture. At `$08520`, it preserves the keyboard read and supplies one space on
the first empty poll. Normal builds omit the fixture entirely. An input-disabled
boot otherwise waits for a title-screen key or mouse event. The fixture changes
no driving routine; it is not evidence of full shipped-versus-rebuilt gameplay
or player-physics equivalence.

## Rendering and memory

The display is 320 × 200 with four separate bitplanes: 16 palette colours,
40 bytes per scanline and 8,000 bytes per plane. Each of the two screen images
occupies 32,000 bytes. The renderer writes planar pixels directly; no chunky
framebuffer or chunky-to-planar conversion appears in this path.

The CPU performs vertex rotation, polygon clipping, edge calculations and span
filling. At `$0329a`, the polygon routine builds edges and writes the four planes
using masked boundary words and unrolled interior word stores. It also supports
patterned fills. The large background-fill routine at `$03a28` uses CPU stores.
The blitter assists with bitmap operations: `$01566`, for example, copies a
rectangle plane by plane. The main polygon filler does not use blitter fill mode.

The VBL handler at `$00044` tests the frame-ready byte through `a4-$703e`.
Only when ready, `$000b4`–`$000be` exchange the buffer pointers at `a4-$6a12`
and `a4-$6a0e`. From `$000e0`, it writes the four hardware bitplane pointers,
spaced by `$1f40` bytes. Those hardware writes happen on other VBLs too, so they
must not be counted as newly rendered frames.

| Inspected contents | Placement in this configuration |
| --- | --- |
| Display and drawing buffers | Chip RAM |
| Sprite data | Chip RAM |
| Polygon-edge scratch arrays through `a4-$69dc` and `a4-$69e0` | Chip RAM |
| Main decompressed game code | Slow RAM |
| Main globals and working vertex arrays | Slow RAM |
| Drawing-pattern data through `a4-$69e4` at the capture anchor | Slow RAM |

This is an observed layout, not a claim about every allocation or configurations
with Fast RAM. Some CPU-only working data is in Chip RAM. Whether relocating it
helps must be measured; slow RAM must not be described as true Fast RAM.

## Time model

The attract loop at `$1084e` calls the demo/view update at `$0d960`, then scene
and cockpit rendering, and submits the screen for display before repeating.
When the attract flag is set, `$0d960` calls the route-following routine `$0d54c`.

That routine interpolates position and orientation between route entries using
an integer phase divided by ten. At `$0d8fe` it increments `a4-$6b2c` once per
call; at ten it resets the phase and advances the route pointer by `$14` bytes.
There is no elapsed-time multiplier in this phase update. Thus the demo moves
one interpolation step per rendering-loop iteration: faster rendering advances
it faster in real time. This conclusion follows from the code; an accelerated
A/B run has not yet quantified the resulting change.

Clock/countdown routines `$02c4c` and `$02c8a` are instead called by the VBL
handler while `a4-$6a13` is enabled. Their cadence is independent of completed
rendered frames. Movement and timers therefore do not share a single timebase.
Separate functions do not imply independently scheduled simulation and rendering.

Player-controlled acceleration, steering, collisions and physics timing remain
unverified. The attract route uses a distinct movement path and cannot establish
the full player-physics model.

Consequently, keep the fixed-duration benchmark, but also compare the same
sequence of demo updates/scenes when assessing rendering changes. Otherwise a
faster run can cover more track, changing the workload within twenty seconds.

## Profile and remaining work

Call-target-aware self-time estimates, as percentages of the whole window:

| Code offset | Inspected role | Share |
| --- | --- | --- |
| `$0329a` | Polygon edges and planar span rendering | 20.15% |
| `$02a2e` | Fixed-point vertex rotation | 7.94% |
| `$03a28` | Bitplane background fill | 6.85% |
| `$03736` | Polygon bounds/clipping (inferred) | 6.45% |

The slave's exact blitter-check/wait range costs 2.657%, including 1.729% in its
polling/CIA-wait body. These figures include checking overhead; they are not pure
stalled time. Blitter transfers occupy 1.61% of recorded DMA slots and display
bitplanes 22.52%. DMA shares are not CPU-time percentages.

Before performance patches, establish player-physics timing, validate broader
shipped-versus-rebuilt equivalence, and capture a 68020 baseline. Intro
optimization is deferred. No claim of an optimization speedup is made.

Raw traces, executable bytes, screenshots, memory dumps, build outputs and local
capture tools remain under ignored `tmp/`. Local evidence includes the benchmark
report, both full captures, exhaustive repeatability results and independent
per-field swap counts. These artifacts are not distributed with this source.
To reproduce with a suitable local harness, build with `VERIFY_ATTRACT`, resolve
the code origin afresh, stop at `$10844`, and capture the next 1,000 consecutive
PAL fields. Count conditional swaps, retain exact configuration/input hashes,
and repeat from a fresh boot. Recalibrate breakpoints when the layout changes.
