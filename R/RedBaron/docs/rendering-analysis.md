# Fast-CPU rendering analysis

2026-10-12. New post-release investigation requested after F3. Scope: the shipping
normal renderer on 68030/50, 68040/25 and 68060/50 emulator configurations at maximum
detail. Stock A500/A1200 work and D5 remain outside this investigation.
The measurements, sample counts and evidence names are in the **Fast-CPU rendering
reprofile** section of [profiling.md](profiling.md), the results ledger.

## Findings

The earlier explanation was too strong. These results locate expensive work in the
existing renderer; they do **not** establish a hardware ceiling for a redesigned CPU
renderer. A slower software implementation of blitter operations does not disprove
Fast RAM rendering followed by one display copy.

The shipping frame has three substantial costs: scene drawing, repeated cockpit
composition, and the wait to publish safely. World simulation is small on these
configurations. Same-frame accounting leaves only a small unbracketed residual;
the cockpit measurement is real elapsed work, not accidentally double-counted
simulation or a whole-frame timer mislabelled as drawing.

The scene also changes during the flight. Opening windows are slower than later
ones that approach the release scoreboard. The apparent 14–15 FPS plateau is not
a fixed cap. Neither the normal two-field cap nor the postponed W6 clock explains
all of the drawing time: W6 is absent from these normal-build captures.

## What “cockpit” actually contains

The phase is `sim:007c4–00830`. It includes:

| Part | Bracket | What happens |
|---|---|---|
| Top area | `sim:007c4–0080e` | Conditional top-area restoration; nearly free in these windows |
| Forward overlay | `sim:0080e–0081a`, body `sim:2c144` | Five masked planar blits into the current draw buffer |
| Gauge dispatch | call `sim:0081e–00822`, body `sim:19ba6` | Per-page old bounds, background bitmap restoration, gauge callbacks |
| Instrument/foreground scripts | call `sim:0082a–0082e`, body `sim:15e96` | Replays picture programs, including static-looking cockpit foreground |

The nested body and its caller are the **same cost**, not two independent costs.
Early raw logs call the gauge body `picture_script`; that historical probe label
is misleading. The actual picture interpreter is `sim:28962–28d58`.

In the program census, programs 2, 3 and 4 each execute once per frame. Program 2
is the dominant script. The later launch census finds the same tall, narrow
rectangle dimensions repeated on both 040 and 060, plus one cockpit polygon and
five large overlay blits every frame. This is why “the picture mostly stays the
same” does not make the existing implementation cheap.

There is a useful distinction between two sorts of dashboard work:

- W1 removed much of the **event-driven bitmap mirroring stall**.
- The normal cockpit phase still performs **per-frame composition**. W1 did not
  remove its foreground programs or make all seven gauges persistent.

The retained gauge cache on 040 reduces native bitmap calls compared with the
uncached 030/060 policy, but the overlay and foreground scripts still run. Native
gauge history already belongs to each of two screen pages. A replacement must
preserve that ownership; “unchanged since the previous displayed frame” alone does
not prove that the other page contains the required pixels.

### Why the previous cockpit caches could lose

The retained listings show masked packed-image composition on cache hits. In
`overlay-fast.s`, every word of a rectangular mask is visited separately for each
of five planes; transparent words skip a Chip access but still cost mask reads,
branches and loop work. Partial words read/modify/write Chip RAM. This is pixel
reuse, not elimination of composition.

For sparse foreground artwork made from narrow strips, a large enclosing masked
rectangle can perform more traversal than the original primitives. The complete
cockpit candidate also materialized the static layer before native gauges, then
performed final composition. Its regression rejects that layering/copying design;
it does not reject persistent cockpit pixels, sparse spans or avoiding unchanged
regions altogether. These are source-level explanations of added work, not a new
measured breakdown of those discarded cache implementations.

## Scene drawing and blitter waits

`sim:006bc–007c4` includes setup and drawing; it is not a pure geometry timer.
The ordinary drawing paths remain planar:

- `sim:2fc68` fills rectangles plane by plane.
- `sim:2f292` builds polygon edges, fills a one-plane scratch mask, then merges
  that coverage into five destination planes.
- `sim:2ea28` draws lines.
- `sim:30572` draws bitmaps, also used extensively by the cockpit.

The fresh 040 brackets put a substantial lower bound on scene time in rectangles
and polygons alone. Two scene rectangles cover the 320-by-120 viewport in the
settled launch sample: five planes for each sky/ground rectangle. Polygon coverage
is then filled separately and merged five times. The captured work count is more
informative than the number of visible polygons: it exposes repeated passes and
custom-register setup for each plane.

Explicit polling brackets confirm material waits in rectangle plane loops,
polygon fill/merge sequencing and the cockpit overlay. The first wait can be
waiting for a *previous* operation; the final asynchronous blit can finish in a
later routine. Consequently, “time inside primitive X” is not precisely the
hardware execution time of X. The report uses parent-contained intervals and
unions overlapping child spans; it never adds an inclusive child to its parent.

The wait census is selective, not a full Chip-bus utilization measurement. The
unmeasured remainder includes line work, setup, geometry, interrupts and other
wait sites. It must not all be labelled “maths” or “Chip contention”.

## What was wrong with the rejected Fast RAM experiment

The frozen E3 listing and retained `tools/fast_blitter_model.c` show a
**software blitter behind the native renderer**, not a purpose-built CPU renderer:

1. At `sim:2c552`, it copies the entire 40,000-byte planar screen **from Chip to
   Fast RAM**, plus 8,000 bytes of scratch.
2. It retains native clipping, primitive dispatch, per-plane operations and
   blitter-register descriptions. Each intercepted launch saves registers and
   invokes a general software operation. The generic loop tests channel enables,
   shifts words, evaluates minterms and emulates fill state; line mode works
   pixel by pixel. Solid and merge specializations help only those cases.
3. At `sim:2c800`, it copies both screen and scratch **back to Chip RAM**.
4. The cockpit remains outside this redirected scene and still draws natively.

That is **96,000 bytes of Chip-facing transfers per scene**, before cockpit work,
versus 40,000 bytes for one final five-plane screen copy. At 50 draws/s the former
alone asks for 4.8 MB/s of Chip transfers, versus 2.0 MB/s for the latter. These
are derived byte counts, not measured bandwidth or a proof that either rate is
sustainable under a particular display/DMA configuration.

It also retains the polygon mask/fill/five-plane-merge algorithm instead of
writing final colour spans directly. There is no chunky-to-planar conversion in
that candidate: it renders planar data with CPU equivalents of blitter commands.

The new historical-binary timing attempt failed in the debugger protocol and is
excluded from the results. We therefore do not assign a measured percentage of
its regression to copies versus kernel execution. Its successful earlier whole-
window comparison remains in the ledger, with its original W6-enabled workload;
it is not directly comparable to this normal-build profile.

## Emulator limits

All fresh normal captures use the identical F3 slave and the established timing
configurations. They are observations of FS-UAE, not measurements on physical
accelerators. In particular, the locally available UAE source routes the 040/060
through the same `m68k_run_3ce` loop. It contains a fallback charging a fixed
emulator cycle quantum after four instructions that otherwise advance no time.
That is not a detailed model of 060 execution throughput or superscalar issue.
The installed binary is stripped; this source audit is not a binary-level proof
of every timing detail in that executable.

The similarity of these configurations must not be used to conclude that a real
060 cannot outperform a real 030, or that a CPU implementation cannot reach
50 FPS. Keep hardware capability separate from repeatable emulator comparisons.

## Static artwork repair implementation

The follow-up implements sparse repair for the forward cockpit's static programs
2–4. On a cache miss the original renderer supplies the artwork and exact coverage;
the cache stores only covered 16-pixel words, with five planar colours. Subsequent
calls compare those words on the actual destination page and write only differing
covered bits. Opaque black is covered correctly; transparent pixels keep the scene.
This removes repeated script interpretation and primitive construction, preserves
both pages independently and repairs intervening damage without assuming that a
page remained untouched. Program/resource, clipping and palette inputs guard reuse;
shared resource-lifetime hooks invalidate entries before their owners are released.

The measured CPU policy enables this on 030/040/060 and retains native drawing on
000/010/020. The sparse lists use the already reserved Fast RAM workspace, plus an
8,000-byte Chip mask for program 2; allocation or unsupported coverage falls back
to native drawing. Programs 3 and 4 retain their native order so shared framework
pixels overlap correctly. Firing artwork and non-forward views remain native.

This is not full cockpit persistence: the world can still overwrite foreground
pixels, the dashboard masked overlay still runs, and instrument updates retain
their existing CPU policy. Avoiding those overwrites and restoring only changed
instrument bounds remain distinct work. All timings and validation are in the
sparse-artwork section of `profiling.md`; no new 50 FPS claim is made.

## Direct scene follow-up

The developer candidate replaces several parts of the rejected E3 structure.
A guarded 320-pixel-wide viewport whose native background initializes every
pixel is owned by Fast RAM for the duration of the scene. It imports neither
the old Chip page nor scratch, and exports only the completed viewport rows.
The normal forward viewport therefore transfers 24,000 bytes once instead of
the previous 96,000 bytes of screen/scratch traffic. Unsupported layouts retain
native drawing. Scratch stays private; native screen pointers and custom state
are restored before cockpit composition.

Clipping remains native. Direct rectangles and lines write final five-plane
colours without constructing a blitter operation per plane. Polygon colour
merging traverses coverage once for all planes. Its scratch clear and inclusive
fill have direct loops, removing per-word channel, shift and minterm dispatch.
Uncommon primitives use the compatibility backend. Every change is gated by
sim v1, the CPU policy and bit 20; the normal mask is unchanged pending validation.

This is deliberately bounded: polygons still construct and correct coverage,
and the cockpit remains outside the private viewport. It is not a complete
span renderer or a claim of 50 FPS. The results and disposition are recorded
only in `profiling.md`; the earlier E3 rejection still applies to that earlier
implementation, not to the changed transfer/primitive design.

## Recommended next implementation

1. **Make cockpit persistence remove work.** Track valid static pixels per draw
   page, invalidate them on actual view/message/resource changes, and restore
   only the old/new bounds of changed gauges. Preserve the native draw order.
   Where the world currently overwrites foreground pixels, either exclude those
   covered spans or compose them in Fast RAM before the single final copy.
2. **Replace primitive algorithms, not hardware registers.** Use a persistent
   Fast RAM target. Clear/fill its viewport directly, generate polygon spans,
   and write final colours without an intermediate blitter coverage buffer and
   five separate merge launches. Choose planar spans versus chunky plus C2P by
   measuring complete render-plus-publication cost, rather than assuming either.
3. **Avoid inbound Chip copies.** Keep render-owned screen/scratch state in Fast
   RAM across frames. Copy the completed visible output to the hidden Chip page
   once; do not export scratch or seed the next frame from Chip. Special view and
   menu transitions need explicit ownership/invalidation.
4. **Measure the actual new budget.** Separate rasterization, cockpit changes,
   final transfer/conversion and synchronization. Include a register-only and a
   Fast-RAM copy calibration before using 040/060 emulator timings as CPU-speed
   evidence; confirm the promising design on a representative real accelerator.

The direct-scene candidate above addresses parts of recommendations 2 and 3.
The remaining recommendations are not shipped changes or a promise of 50 FPS. D5 remains postponed. Correct simulation timing and
rendering throughput remain separate acceptance requirements.

## Reproducing the profiles

Use the existing local development harness, source `tmp/dev/amiga/env.sh`, then
change into `tmp/dev`. One owned emulator at a time; the driver refuses an
existing live emulator and refuses to overwrite a capture directory.

```sh
BENCH_BATCH_KEYS=1 BENCH_OMIT_CUSTOM2=1 python3 -B \
  ../../R/RedBaron/tools/render_profile_case.py 060 0 tmp/prof/my-render-060
```

Use `030` or `040` for the other configurations. Input goes through the established
debugger keyboard driver. The normal Faster rendering bundle is on; Time Scale
is unchanged, World/Aircraft detail is maximal and Ground is enabled IN COMBAT.
The protected flight fixture avoids damage ending the capture. Four broad groups
use 250 PAL fields each; narrower groups use 100. Groups are consecutive windows,
not an identical scene replay and not an optimization A/B test.

```sh
python3 -B ../../R/RedBaron/tools/render_profile_report.py \
  tmp/prof/my-render-060 --out tmp/my-render-report.json
```

No instruction trace or full memory-history capture is needed. Retain compact
logs, metadata and the frozen slave/listing. Phase-ambiguous endpoints are excluded;
child-cost sums are reported as lower bounds. Failed or incomplete captures do
not qualify as FPS results. A failed driver leaves the owned session available
for diagnosis; use the harness's normal quit procedure before another run.
