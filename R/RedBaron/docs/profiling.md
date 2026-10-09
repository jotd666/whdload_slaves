# Red Baron: 250-field flight profile

Captured 2026-10-09. Source baseline: `1904205` (`redbaron`).

## Findings

The original mixed window contains cockpit redraw events and steady flight. The large
`sim:304d0` hotspot is the **EDASH-B dashboard bitmap**, mirrored twice per redraw. A cockpit
event redraws both display buffers and costs four mirrors: approximately 7.4M main-context
cycles. It is not an unconditional per-frame cost. Five complete calls retained within individual chunks cost 1.8526–1.8550M
main cycles each (mean 1.8541M); six such calls are equivalent to about **31.3%** of a 250-field budget.
The earlier 30.96% was a raw instruction sum across discontinuous capture chunks and must
not be used as a complete-call performance baseline.

Steady frames take approximately **27–29 fields (1.7–1.8 fps)** in the original 68000 + fast
configuration. About **77% of main-context steady-frame cycles** are in the `sim:2c552` 3D
pass. Cockpit-event frames take approximately 59–60 fields. Full analysis and approved work
order are in `performance-plan.md`; sound work is deferred.

**W0 update:** an independent VERIFY VBlank counter has confirmed one unrecorded field at
consecutive profile-command joins. The original 100/100/50 files are not a continuous trace.
Use complete calls within a chunk for cycle costs, and the step/swap logs over at least
2,000 fields for frame rate. No performance patch has been installed yet.

## Capture conditions and evidence

| Item | Value |
| --- | --- |
| Duration | 250 PAL fields, approximately 5 seconds |
| Captures | 100 + 100 + 50 recorded fields, with one-field gaps at joins |
| CPU | 68000, real CPU speed, CPU/memory/blitter cycle-exact settings enabled |
| Memory | 1 MB chip + 2 MB fast + 512 KB slow (inherited A500 default); **not** an A500-equivalent memory baseline |
| Boot | Kickstart 3.1 host, KickEmu 1.3 guest, WHDLoad 20.0 |
| Game | `RedBaron_v2.1.lha`, supported v1 `sim` executable |
| Slave | VERIFY build of the fork source |
| Detail | World maximum, Aircraft maximum, Ground Detail ON IN COMBAT |
| Time Scale | Original archive setting, unchanged |
| Input | Native keyboard tape; host joystick ports disabled |
| Audio | Game sound ON; host audio output uses the dummy driver |
| Starting point | Flight-only checkpoint at gameplay step 1, followed by one screenshot field |
| Ending point | Gameplay step 6; still in flight |

The route skips the scrolling credits, selects the ace mission (Ernst Udet in this fixture),
answers No to the pre-flight mission-tape question, applies the preferences and presses
ACCEPT. The optional banking fixture starts at gameplay step 20; this five-second capture
never reaches it. The profile therefore contains no injected banking input.

The retained baseline evidence includes three trace chunks, the exact VERIFY slave,
before/after fast-memory dumps, emulator settings, routine attribution, exact-PC metrics,
and extracted screenshots. The evidence manifest records hashes. These generated artifacts
remain local and ignored; no binary evidence is included in this repository.

Input/build SHA-256:

| Input | SHA-256 |
| --- | --- |
| Preinstalled archive | `ec6d74e3576bf040269f1c078a9df766a8f6e6dd94c2eb29eb5d34307b87ffe4` |
| Original `sim` | `e9b3889bc6f177e0bcfc74987665cdafbccd984b3a031bdd1f98f6c445dd8839` |
| Retained VERIFY slave | `ade543bd07d9bdc7dc620033a1e11bf7c667495a5972658bb7c7358b5914bfc5` |

## W0 machine bring-up measurements

These are unoptimized **mixed-flight** windows including cockpit events and the scripted
right bank, not the final R-steady/R-event measurement matrix. They establish that the
long-window instruments work on both memory/CPU configurations.

| Configuration | Flight intervals | PAL fields | Observed swaps | Mean display rate |
| --- | ---: | ---: | ---: | ---: |
| 68000, 512 KB chip + 1.5 MB slow, no fast | steps 1–120: 119 | 3,649 | 119 | 1.63 fps |
| 14 MHz 68020, 2 MB chip + 8 MB fast, no slow | steps 1–250: 249 | 2,226 | 249 | 5.58 fps |

A separate **straight-flight** 50 MHz 68030 window (2 MB chip + 8 MB fast, no slow)
completed 800 swaps in 2,613 PAL fields: **15.28 fps**. It spans steps 186–986 and
uses the explicit no-bank fixture, so it is not the same scene/input window as the
two rows above. Of 800 publications, 507 begin between beam lines 40 and 244; this
shows that swaps are not synchronized to blanking, but is not by itself a complete
tearing diagnosis. Swap and subsequent input-observer clocks agree in 798 cases;
one crosses a CIA tick and one crosses a VBlank. A separate earlier segment that
stopped on a debugger transport error is excluded.

The retained 68030 configuration has CPU and CPU-memory cycle accuracy enabled,
but **blitter cycle accuracy disabled**. Its ten-field DMA-only follow-up contains
bitplane fetches and CPU records, but no blitter DMA records. The 15.28 fps number
therefore describes that emulator configuration; the absent blitter records cannot
be interpreted as evidence of no writes into the displayed buffer. The later optional first-fill diagnostic enables blitter cycle accuracy and makes
those writes observable; its findings are recorded in `verification.md`. That
diagnostic is a different configuration from this retained 15.28 fps result.

Rates use the emulator's measured PAL rate of 49.92041 fields/s. The A500-equivalent
run uses the pre-framework VERIFY build; the 68020 run uses the option-framework build
with no performance patch installed. These are **not** a same-build optimization A/B.
The 68000 remains at dt=450 throughout. The 68020 leaves the clamp, with dt values
between 248 and 450 in the first 120 steps; world states cannot be expected to match
at equal step numbers across these two runs. Time Scale remains 40 in both.

Every observed swap has a subsequent step record. Reading the latter can cross a clock
boundary: of 119 A500 intervals, six have one more VBlank at the input observer and five
have one more CIA tick; of 249 68020 intervals, those counts are two and one. All other
records have identical VBlank/tick counts. This is the short swap-to-input interval,
not a missing frame. The later squadron steps 1–2 check agrees across trace, SWAP_ONLY and the step ring;
see `verification.md` for its exact scope.

## 68030 cache conditions

The optional flight-entry diagnostic resolves an important configuration distinction.
With the unchanged slave and default WHDLoad arguments, the measured CACR is
`0x2000` (both caches disabled), despite policy `0x3b3d` requesting IC/DC. WHDLoad
20.0 disables MMU use by default on a 68030. The slave requests noncacheable BaseMem,
which forces global cache disable without MMU page attributes.

Adding WHDLoad `MMU` to the same diagnostic binary produces CACR `0x2111`, enabling
instruction cache/burst and data cache. Explicitly enabling FS-UAE data-cache
modeling also reaches step 20 with 18 first-fill records and no missed publication.
The saved configuration must show `cpu_data_cache=true`; the register alone does
not prove that the emulator models data caching. See `verification.md` for the
controlled check. These are configuration checks, not optimization results.

For the cached 50 MHz machine, use the following conditions with the existing
flight-entry harness (CUSTOM5=8 only for the optional diagnostic):

```sh
CPU=68030 CHIP_KB=2048 FAST_KB=8192 \
EXTRA_ARGS='--slow_memory=0 --uae_cpu_speed=real --uae_cpu_multiplier=0 --uae_cpu_frequency=50000000 --uae_cpu_cycle_exact=true --uae_blitter_cycle_exact=true --uae_cpu_data_cache=true' \
WHD_ARGS='MMU' python3 tools/reach_flight.py --out tmp/prof/cached-030-entry
```

Keep the diagnostic off for frame-rate measurements. Preserve the saved emulator
configuration, WHDLoad arguments and binary with each capture. Older uncached or
blitter-inexact runs remain separate baselines; changing these settings is not a
slave performance improvement.

## Current-build cached 50 MHz 68030 baseline

The 30,324-byte VERIFY text build, with all performance bits and the first-fill
diagnostic off, runs the explicit cached/MMU configuration above. **Swap 120–700**
completes 580 frames in **2,280 PAL fields**, **12.699 fps**, without dashboard
events. Its dt values are 124, 155 and 186. This is an unoptimized steady baseline;
it is not comparable as a speedup ratio to the old 15.28 fps run, whose blitter and
cache conditions differed.

A reset-armed fresh boot reproduces every field in the step-120 observer record
exactly. The corresponding 20-field DMA trace contains **178,570 framebuffer
writes** and **zero active-display conflicts**. Both live framebuffer allocations
and their actual bitplane fetches are checked. This 68030 core still supplies no
instruction records usable for publication matching, so the trace does not provide
per-call instruction costs or publication-to-first-write margins. The separate
optional diagnostic supplies those beam observations; its overhead is excluded
from this frame-rate measurement. Strict cross-boot trace equality is not claimed
from an observer-record match alone.

The flight-exit-guarded census reaches step 1,015 and retains every step record.
It observes 73 mirror calls, 62 message calls, 28 dirty triggers and 108 bitmap
rejects, with no full/top redraw calls after the starting checkpoint. The initial
screenshot advances one field and can precede part of the first event; these counts
must not be presented as a complete census from the first instruction of flight.

Retained VERIFY SHA-256:
`504738561676440e9d41a8d3a0f6324e88c7d1b1aa500e433a3498c878af4a57`.

## Current-build A500-equivalent baseline

The current VERIFY binary, with performance bits off and no scripted bank, runs
with 512 KB chip, 1.5 MB slow and no fast RAM. The saved configuration confirms
those banks and full CPU/memory/blitter cycle accuracy. **Swap 40–140** completes
100 frames in **2,717 PAL fields**, **1.837 fps**, with no dashboard events and
dt=450 throughout. This differs from the earlier mixed banking baseline.

A fresh boot reproduces the complete step-40 observer record byte-for-byte. A
100+50-field trace at that checkpoint, analyzed as separate chunks, retains six
complete 3D calls at **2.0853–2.1662M main cycles**, mean **2.1241M**, and six
world steps at **0.3189–0.3956M**, mean **0.3691M**. The opening event trace has
two complete mirrors at **1,920,832 and 1,922,038 cycles**. These scene-specific
measurements are unoptimized baselines; the different steady scene on the fast-RAM
68000 does not support a direct memory-speed comparison.

## Current-build 14 MHz 68020 baseline

The current VERIFY binary, with all performance bits off and no scripted bank,
completed a clean **swap 80–400** interval: 320 frames in **2,616 PAL fields**,
**6.106 fps**, with no dashboard events. World dt ranged from 248 to 450. This
is a steady-flight baseline, whereas the earlier 5.58 fps result was a mixed
banking window on an older build. They do not establish an improvement.

The saved configuration explicitly selects 68EC020, clock multiplier 4 (about
14.2 MHz PAL), 2 MB chip and 8 MB fast, no slow RAM, and CPU/memory/blitter cycle
accuracy. An earlier attempted frequency option was ignored and left multiplier
2; that run is marked rejected as a 14 MHz baseline. Always validate the saved
configuration rather than relying on the requested command options.

A fresh boot supplies a 40-field trace at step 80. Its step-80 VBlank, CIA clock
and recorded state match the census; beam position differs, so strict trace
reproducibility for this machine is not claimed yet. Five complete 3D calls cost
**1.3072–1.4135M main CPU cycles**, mean **1.3753M**; five world steps cost
**0.1775–0.2041M**, mean **0.1929M**. An opening 40-field event trace retains one
complete mirror at **808,426 main cycles**. A second mirror crosses the capture
boundary and is excluded. These are CPU-clock cycles: the 68020 trace accounts
for 284,204 cycles per field, twice the 68000 trace's 142,102. Do not compare raw
cycle counts across CPUs as elapsed-time ratios.

The steady trace contains 185,707 writes into the two framebuffers, including
observable blitter destination writes, and **zero writes into the fetched display
buffer during lines 42–243**. Across five measured publications, the first write
to the former display buffer begins 0.999–1.135 fields after publication finishes.
Early publications use the previous field's fetched buffer to identify the old
display; this field already fetches the new one. This establishes the margin for
this unoptimized window only. The optional first-fill/cache observer is documented in `verification.md`;
post-optimization tearing checks and the complete machine matrix remain open.

## Dashboard census through flight exit

The current unoptimized 68000 + fast-RAM banking fixture was observed from the
maximum-detail flight checkpoint through the actual flight-loop exit. It completed
357 swaps in 9,135 PAL fields (**1.95 fps**, a whole-flight mixed window), including
the late-flight changes of view/scene. This is not an optimization A/B or a substitute
for the fixed steady/event windows. All 357 step records were retained by draining
the ring in segments, and the exit breakpoint excluded debriefing.

| Observed path | Calls |
| --- | ---: |
| Message routine `sim:3ba2` | 33 |
| Dirty-rectangle trigger `sim:197ee` | 13 |
| Full-redraw branch `sim:668` | 1 |
| Top-text redraw branch `sim:7de` | 0 |
| Dashboard mirror `sim:304d0` | 44 |
| Bitmap clip rejection `sim:305c8` | 65 |

All 44 mirrors used the same 168×102 dashboard descriptor, two calls in each of
22 frames. Thus **22 of 357 frames (6.2%)** invoked the mirror in this mission
window; the original five-second profile's 31.3% cycle share must not be generalized
to steady flight or a whole mission. The 65 clip rejections belonged to other
bitmap descriptors, not the dashboard. No top-text event occurred, so its proposed
wasted-mirror path remains untested. The initial menu/preferences frames precede
this census and are not included.

The census also identifies useful clean windows: steps 8–16 contain eight rendered
intervals without a dashboard event; steps 24–30 are within the scripted right bank
and also contain no mirror. Their cross-boot trace checks now pass as described below; the complete machine
matrix remains outstanding.

The retained census also contains a longer clean interval: **swap 80 to swap 180**
completes 100 frames in **2,524 PAL fields**, or **1.978 fps**, with no message,
dirty, full-redraw, top-text or mirror events inside the interval. Every world dt
is 450. This exceeds the 2,000-field rate requirement on the current 68000 + fast
build. It is a later scene than the short step-8 trace, so their cycle costs and
frame rates must not be combined as if they described the same window.

`census_window.py` uses the actual boundary swaps. Measuring input checkpoints
80–180 instead gives 2,528 fields because input precedes that step's rendering;
that is a different interval. The tool excludes the starting boundary from its
frame count and rejects missing or duplicate swaps and incomplete step histories.

## Current fixed-window cycle checks

The 30,380-byte VERIFY text build passes strict fresh-boot comparison for the
100-field opening event, 150-field steady window at step 8 (chunks 100+50),
and 100-field banking window at step 24. Every instruction/DMA/accounting
record and full screenshot byte matches. Both boots use `MallocScribble=1` to
initialize unused host framebuffer storage; see `verification.md`. Earlier
unscribbled captures retain their recorded border mismatches. The steady
chunks retain the known one-field gap and are analyzed independently.

On the 68000 + fast-RAM continuity configuration, the maximum-detail ace/bank
fixture gives these complete-call main-context cycle costs:

| Window | Routine | Complete calls | Mean cycles | Range |
| --- | --- | ---: | ---: | --- |
| R-event | Dashboard mirror | 2 | 1,853,636 | 1,852,524–1,854,748 |
| R-event | 3D pass | 2 | 2,238,834 | 2,237,690–2,239,978 |
| R-event | World step | 1 | 362,378 | Single complete call |
| R-steady | 3D pass | 6 | 2,202,846.7 | 2,173,760–2,254,076 |
| R-steady | World step | 5 | 328,008.8 | 274,440–368,586 |
| R-bank | 3D pass | 4 | 1,993,287.5 | 1,902,588–2,055,104 |
| R-bank | World step | 4 | 314,158.5 | 284,560–346,770 |

The steady trace has six publications and no dashboard-event entries. These
are scene-specific baseline costs, not a speedup or an FPS estimate. Retained
evidence is `w0-windows-scribble-{a,b}`. The interrupt stack is independently
confirmed from the VBlank/CIA callbacks and all measured calls restore SP.

The versioned `call_costs.py` uses explicit original entry/RTS offsets and checks
that SP is restored. It discards open calls at each file boundary and separates
the observed interrupt stack, including KickEmu callbacks running in user mode.
Using SR alone misclassifies those callbacks and inflates the apparent mirror cost.
Its results reproduce the original baseline's approximately 1.854M mirror cost;
five baseline calls are complete within chunks. The sixth is cut and is excluded.

## Validation and attribution

The parser reads **3,154,859 records** and **35,525,488 CPU cycles**, against the PAL-field
budget of 35,525,500 cycles: a difference of 12 cycles over all 250 fields. PCs are present;
there are no STOP/idle records. Individual fields have small accounting differences from
instruction costs crossing field boundaries; whole-window totals are the useful comparison.
No resume or screenshot command was issued between chunks, but the profiler itself
advances through an unrecorded field at each join. Thus the total only covers recorded
cycles, not the complete elapsed period. Reconstructed call stacks must reset at joins.

Live code is identified from the VERIFY marker and the LoadSeg BPTR chain, rather than a
cached copy of a preloaded executable. KickEmu and the sound driver are identified by
byte matching, and the slave by its retained build and live marker. Region shares in the **recorded** samples are sim code 88.70%, sound 8.95%,
KickEmu 1.90%, slave 0.24%, unmapped instructions 0.04%, with approximately 0.16% interrupt
entry accounting. These are mixed-window raw shares, not normalized completed-call costs.

Offsets below refer to `sim` hunk 0, `h3` data/BSS or the sound-driver file. Runtime load
addresses and chip-buffer pointers are deliberately omitted: they change between builds.

Self attribution uses observed call targets and `LINK A5` prologues. Inclusive attribution
reconstructs stacks from calls and stack pointers, separating the main and interrupt stacks.
It can be incomplete at capture boundaries or across unconventional control transfers;
inclusive percentages overlap and must not be added. Exact-PC totals corroborate the
largest hotspot independently of inferred function boundaries.

The main stack accounts for 84.9% of cycles and the other observed execution context for
15.0%, excluding interrupt-entry accounting. There are 1,171 IRQ-entry records, 250 calls
to the mouse/VBlank callback at `sim:$2d344`, and 296 timer-callback entries at `sim:$2ffcc`.
Those callback counts are not rendered-frame counts.

## Hot routines

Percentages use the entire 250-field CPU cycle budget, including interrupts and waits.
Calls mean entries reconstructed in this capture, not lifetime counts.

| Routine | Self | Inclusive | Calls | Interpretation |
| --- | ---: | ---: | ---: | --- |
| `sim:$304d0` | **30.96%** | 30.96% | 6 | Horizontal bitmap reflection and mask accumulation |
| `sim:$38c82` | 5.56% | 5.56% | 1,347 | Signed normalization and scaled arithmetic used by geometry |
| `sim:$3afbe` | 3.90% | 3.90% | 1,446 | Coordinate transformation, including multiply/shift paths |
| `sim:$3b41a` | 3.61% | 28.13% | 606 | Geometry-processing caller; substantial work is in its callees |
| `sim:$38dcc` | 2.51% | 6.41% | 2,153 | Geometry helper calling the transformation routine |
| `sound:$1b1e` | 2.43% | — | 325 | Sound-driver routine; exact role not yet named |
| `sim:$2ea28` | 2.17% | — | 388 | Drawing code; semantic label still provisional |
| `sim:$2fc68` | 2.15% | — | 71 | Clipped blitter rectangle setup and polling |
| `sim:$30572` | 2.12% | 2.11% | 94 | Bitmap blitter setup, clipping and waits |
| `sound:$0c10` | 1.99% | — | 702 | Sound-driver routine |
| `sound:$1984` | 1.93% | — | 326 | Sound-driver routine |

Small self/inclusive discrepancies such as `$30572` reflect the different attribution
methods, not negative callee work. The exact-PC report is authoritative when boundaries matter.
The rendering/geometry chain `sim:$2c552 → $39b42 → $3a902 → $3b41a` accounts for
38.86%, 32.41%, 31.73% and 28.13% inclusive respectively. These are nested costs.

### Bitmap reflection: first optimization candidate

`sim:$30408` tests the orientation flags in the bitmap descriptor. When the horizontal
orientation differs, it calls `$304d0`, then toggles the corresponding descriptor flag.
The routine:

1. Clears the auxiliary mask area.
2. Walks the bitmap planes and rows.
3. Reads each 16-bit word and reverses its bits using **16 `LSR`/`ROXL` pairs**.
4. Pushes reversed words onto the stack, then pops them back in reverse word order.
5. Writes the mirrored image in place and ORs the pixels into the mask.

The exact range `$304d0–$30570` costs **10,999,770 cycles**. The 32 shift/rotate
instructions at `$3050e–$3054c` alone cost **8,518,472 cycles**, or **23.98% of the total**.
All six observed entries use the first EDASH-B descriptor: a 168×102 bitmap with five
planes and a separate mask.
Descriptor fields may change during execution, so these dimensions describe the snapshot.
Calls start in fields **2, 18, 86, 100, 145 and 160**.

A byte-reversal lookup table or a faster verified word-reversal sequence is a focused
candidate. Preserve word order, in-place semantics, mask accumulation, registers and
flags expected by callers. A broader option is to cache both orientations, but that needs
more memory and proof that the underlying image is not modified between uses.

For scale only: halving the whole routine's cost would give an idealized **1.18×** speedup
for this sample; removing it entirely would cap that model at **1.45×**. Neither is a
prediction or measured improvement. The final 89 fields have no calls to this routine.

### Geometry and sound

The next investigation should separate repeated transformations from required per-frame
work. `$3afbe` has both shift-only and multiply-based coordinate paths; `$38c82` repeatedly
normalizes signed values. Check actual ranges, overflow and rounding before replacing
arithmetic. Changes here can alter geometry even when the result looks similar.

The sound binary itself costs 8.95%, with additional sound sequencing in `sim`, notably
`$34d96`, `$34e56` and `$34d26`. Dummy host audio does not disable emulated sound work.
The two execution contexts and timer callbacks make audio worth investigating after the
bitmap hotspot, but this profile does not establish which sound operations can be removed.

## Blitter, DMA and display updates

Confirmed DMACONR bit-6 tests cost **5.42%** and their immediately associated backward
branches cost **1.07%**, for **6.49%** in those polling sequences. This includes their
instruction/bus cost, not exclusively time when the blitter is busy. Recognition checks
the effective custom-register address rather than counting every `BTST` instruction.
Hot examples are `$30798/$3079e` and `$2fd7a`. No execution was recorded in the
beam-position waiting loop at `$31522–$31548`.

DMA shares use the existing Barto 58-byte record decoder (type byte at offset 29), also
used by the other project tools. The total is 17,762,750 slots: 250 × 313 × 227.

| Recorded slot type | Share |
| --- | ---: |
| Free | 63.075% |
| Bitplane | 28.149% |
| Blitter | 4.468% |
| CPU chip-bus access | 2.014% |
| Refresh | 1.762% |
| Audio | 0.410% |
| Copper | 0.100% |
| Sprite | 0.023% |

These are chip-bus slot shares, not CPU utilization. Fast-RAM CPU work does not require
those chip-bus slots. The free share is therefore compatible with a CPU-bound routine.

A display-update candidate is now identified: `$314c0` exchanges framebuffer pointers,
and `$3154a` writes the six bitplane pointer pairs into the active copper list at hunk 2 offset `$48`.
Five such writes occur in fields **60, 118, 178, 204 and 233**, alternating between the
two buffers (identified by the two framebuffer roles).
Each is followed by a flight-step checkpoint in the same field.

The recorded field differences were 58, 60, 26 and 29. They are not valid elapsed periods
across chunk joins. The CIA-tick reconstruction gives approximately **59.2, 60.0, 27.1 and
28.8 fields**. Do not use the earlier 1.16-fps mixed-window estimate as a steady-state rate.
The W0 observer/breakpoint validation is documented in `verification.md`. The
three-way same-window check passed; the remaining scene/machine cross-boot checks
are still prerequisites for optimization claims.

## Repeat the profiling run manually

From the worktree root, using the established local harness and shared Amiga inputs:

```sh
python3 tmp/dev/tools/profile_flight.py
```

The default is now **one 100-field cycle capture**, with no internal joins. Use `--fields`
for a shorter window (1–100). It creates a fresh evidence directory and retains the slave,
assembly listing, memory snapshots, settings and reports. The first native-debugger attach
may take minutes even though the emulated window is short.

The complete command passed an end-to-end rerun (`w0-manual-workflow`) with the
current VERIFY build and default 68000 configuration. It reached the 72-key flight
checkpoint, saved one 100-field trace, then generated `report.txt` and `metrics.json`
and left the emulator paused. The trace contains 1,286,718 instruction records,
100 mouse callbacks, 118 CIA callbacks, three mirror entries and one publication.
Recorded cycles total 14,210,196 against the nominal 14,210,200; the four-cycle
accounting difference is retained explicitly. There are
no internal chunk joins. This verifies the manual workflow, not a new steady FPS
baseline. Machine overrides require their corresponding RAM/analysis setup; this
packaging command is validated for its default configuration.

For longer frame-rate measurements use `step_log.py` and `swap_fields.py`, with a start/end
window from the approved route and at least 2,000 elapsed fields. Both read the VERIFY ring;
`swap_fields.py` additionally uses read-only breakpoints at `sim:3154a`. It does not patch
target memory. The full machine/window matrix is still being established in W0.

Never insert `cont`, `wait` or `shot` between captures intended to form one experiment.
Even without those commands, each profile command has an unrecorded alignment interval:
joined files require explicit gap handling. Extract screenshots from existing trace files;
a new `shot` advances emulated time too.

## Current work and limits

The old next-work list is superseded by `performance-plan.md`, including its user decisions.
W0 observers and capture-gap confirmation are implemented; the complete groundwork gate
has not passed. See `verification.md` for checks and remaining acceptance requirements.
There are no new performance claims, no sound changes and no game-time implementation.
Performance candidates remain disabled until their required models, twins, hook audits,
off-path checks and machine/window measurements pass.

## Rear-view squadron geometry sample

The VERIFY-only rear-view squadron candidate starts at flight step 8, Time Scale
40, maximum detail, CUSTOM2=0 and CUSTOM5=20. On the default 68000 + fast setup,
its 100-field capture has three complete 3D calls: mean **2,266,544 main cycles**,
range 2,186,006–2,318,154. Two complete world updates average **759,255 main
cycles**, range 748,338–770,172. Calls cut by either edge are excluded. These are
scene costs, not a rendering speedup or a long-window FPS measurement.

Each complete 3D pass dispatches seven aircraft models. Two fresh boots with
`MallocScribble=1` now match all 100 fields exactly, including the complete
screenshot bytes. Initializing host allocation removes the unused-border
differences; every instruction/DMA record and all game pixels also match the
preceding uninitialized capture. See `verification.md` for the evidence and
capture setting. The baseline machine matrix remains open.

## Event-containing long-window baseline rates

The complete retained ace-mission censuses also supply bounded R-event rate
windows. The selection rule is the first complete captured swap through the
first later swap at least 2,000 PAL fields afterwards. These fixed intervals
contain dashboard events **and steady frames between them**; they are not
event-only frame rates. The current-build steady rates above retain their
separate event-free windows. No optimization is enabled.

| Machine | Swap boundaries | Frames | Fields | Mean fps | Mirror calls / frames with mirrors |
| --- | --- | ---: | ---: | ---: | --- |
| A500-equivalent | 3–74 | 71 | 2,022 | 1.7529 | 4 / 2 |
| 14 MHz 68020 | 4–236 | 232 | 2,003 | 5.7821 | 24 / 12 |
| Cached 50 MHz 68030 | 1–493 | 492 | 2,003 | 12.2620 | 44 / 22 |

The A500 and 68020 censuses begin after their opening trace captures, so the
first two/three flight frames are not represented here. Starting-boundary
work is excluded from both the interval count and event counts. The retained
`event-window.json` beside each machine's census records the exact selection,
step history checks and event-bearing steps. Different machine trajectories
are expected because their dt values differ; these rows are not speedup
ratios for equal world state. Per-routine event/steady costs remain separate
measurements, and the remaining baseline-matrix work is tracked in
`verification.md`.

The newer cached 68030 first-draw diagnostic independently correlates ten
logged publications with actual framebuffer DMA. Drawing starts 0.1971–0.2443
fields after the publication observer. One late publication produces 5,599
writes into the fetched display buffer, all behind the raster. See
`verification.md` for scope, cache conditions and the rejected phase control.
Its diagnostic overhead is excluded from the rate table above.
