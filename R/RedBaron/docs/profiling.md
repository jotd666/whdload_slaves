# Red Baron performance measurements

## W2 individual measurements

The inline normalization candidate at `sim:38c82` is available as developer/VERIFY
CUSTOM2 bit 2. On the A500-equivalent configuration, short same-build captures give
mean complete 3D-pass costs of **2,446,680.5 → 2,416,049.5 main cycles** in R-steady
(four calls each), and **2,310,012.0 → 2,269,088.0** in R-bank (three calls each).
Projection-call means fall from 1,595.1 to 1,435.8 and 1,619.5 to 1,428.8 respectively.
These are 150/100-field cycle samples, not frame-rate measurements. The candidate
passes 451 synthetic and 8,569 live CPU twins; exhaustive host normalization checks
cover both widths. Full conditions, rejected first candidate and build hash are in
`w2-verification.md`. The current combined CPU results and remaining gates
appear below; player enablement stays off.

G4's separately measured low-long dot product (`sim:3b1fa`, developer bit 5)
reduces mean complete 3D-pass costs **2,446,701.5 → 2,378,798.5** main cycles in
R-steady and **2,308,462.0 → 2,254,382.0** in R-bank. There are four and three
complete calls per setting respectively. Dot-product calls fall from roughly
1,850 to 700 main cycles. This is another short same-build cycle comparison,
not an FPS measurement or a cumulative G1+G4 result. See `w2-verification.md`
for its independent models, synthetic/live twins, state differences and build hash.

G2's trivial clipping paths (`sim:39ecc`, developer bit 3) reduce mean complete
3D-pass costs **2,446,701.5 → 2,401,021.5** main cycles in R-steady and
**2,308,462.0 → 2,266,218.0** in R-bank (four/three complete calls per setting).
Clipping averages include both fast and original fallback paths: 1,942.3 → 1,570.3
and 2,418.1 → 2,108.2 cycles. The same-build 150/100-field samples imply
1.87%/1.83% whole-pass savings; they do not establish FPS or combined W2 gains.
Full buffers match in 105 synthetic and 4,187 live twins. See `w2-verification.md`.

G3's merged 32-bit vertex cache-miss path (`sim:38e02`, developer bit 4) gives
**2,446,701.5 → 2,382,304.5** mean complete 3D-pass main cycles in R-steady and
**2,308,462.0 → 2,244,320.0** in R-bank (four/three calls per setting). Vertex
wrapper averages, including unchanged cache hits, fall from 1,109.2 to 936.4 and
1,226.5 to 998.4 cycles. The 150/100-field samples show 2.63%/2.78% whole-pass
savings. 208 synthetic and 8,729 live comparisons pass; the separate 16-bit path
is unchanged. Conditions, state comparison and hash are in `w2-verification.md`.

## Combined W2: current measured results

G1 projection core, G2 trivial clipping, G3 32-bit vertex misses and G4 dot product
(CUSTOM2=60) improve the measured A500-equivalent steady run from **1.8380 to
1.9477 FPS (+5.97%)**. This is the bundle's measured result, not the sum of the
individual routine percentages. At swaps 40–140, the same 100 intervals take
2,716 fields OFF and 2,563 ON. Both windows exceed 2,000 fields, have no dashboard
events, and retain dt=450. The separate 150-field samples show **8.58% lower
3D-pass main cycles** (2,446,701.5 → 2,236,693.0; four complete passes per setting).

The same frozen binary passes all four twins together on A500, 68020 and cached
68030 in banking and dense scenes. A500 equal-step state differs only in known
clock fields; disabled-byte and sampled display-ownership checks pass. Detailed
counts, scope and evidence are in `w2-verification.md`. The 68020 pair also gains **5.54%**, from **6.1654 to 6.5069 FPS** over swaps
80–400 (2,591 → 2,455 fields, no dashboard events). Its separate cost sample
shows 5.43% lower whole-pass main cycles and improvements in all four measured
routines. The 68020 dt is no longer fixed at 450, so its two runs can legitimately
follow different world states. On cached 68030, seven phase-safe early-flight 3D passes per setting fall from
**49.4958 to 48.9081 ms (−1.19%)**, inclusive of interrupts and chip-bus waits.
The long windows are both about 12.8 FPS but have different combat/death events;
that pair does not establish a steady-flight FPS gain. The per-routine check rejects G1 on cached 68030 (projection wrapper mean
7.81 → 9.31 µs; the median also regresses). Dot, clipping and vertex routines
improve. The player policy retains original G1 on 030 and conservatively on
040/060; developer/VERIFY testing uses CUSTOM2=56 for that W2 bundle, whose
early-flight check gives 48.8394 ms/pass versus 49.7041 OFF at matching
accepted steps (−1.74%). Its long window averages 12.9043 FPS with no dashboard
events, but the different OFF history still precludes a clean FPS gain claim.
A500/68020 use 60. The final event/bank/dense cost matrix remains open. The release mask remains zero.

The final-bundle A500 scene checks also improve sampled 3D-pass main costs:
**8.56% in the initial cockpit event, 8.69% while banking and 4.56% in the dense
scene**. Each is a 100-field routine-cost sample, not an FPS run; banking's ON
window completes an extra pass, so call mixes differ. Per-emitted-face means
also decrease. Same-step state and sampled display/disabled-byte checks pass;
see `w2-verification.md` for counts and scope. The 68020 scene samples likewise
reduce mean 3D-pass main costs by **7.00% event, 7.67% bank and 3.42% dense**.
Its banking ON sample includes an extra dashboard redraw and its call mixes
differ, so these are routine-cost observations, not scene FPS gains. Per-face
means decrease and sampled display/disabled-byte checks pass. Cached-68030
scene pairs are still being collected.

## Running the W2 profile manually

From `tmp/dev`, source `amiga/env.sh` and ensure no other controller is using this
project's emulator. The normal player build still has a zero release mask; these
checks use the VERIFY build with its per-feature options and twins disabled.
`reach_flight.py` builds that variant and reaches the maximum-detail flight fixture:

```sh
MallocScribble=1 CPU=68000 CHIP_KB=512 FAST_KB=0 \
EXTRA_ARGS='--slow_memory=1536 --uae_cpu_multiplier=2 --uae_cpu_speed=real --uae_cpu_cycle_exact=true --uae_cpu_memory_cycle_exact=true --uae_blitter_cycle_exact=true' \
WHD_ARGS='CUSTOM2=60 CUSTOM5=512' \
python3 tools/reach_flight.py --no-shot --out tmp/prof/my-w2-on
python3 tools/step_log.py --step 8
python3 tools/capture_current.py --out tmp/prof/my-w2-on/chunk0 --fields 100
python3 tools/capture_current.py --out tmp/prof/my-w2-on/chunk1 --fields 100
python3 tools/capture_current.py --out tmp/prof/my-w2-on/chunk2 --fields 50
```

This retains **250 recorded PAL fields**. The profiler adds an unrecorded field
at each chunk start; do not treat joins as continuous instruction traces. Routine
costs must exclude calls crossing those joins. Repeat from a fresh boot with
CUSTOM2=0 and a new output directory; keep source/build options unchanged and
compare the saved `entry.json` slave hashes before interpreting the pair.
CUSTOM2=60 selects bits 2–5 only, leaving W1 off. CUSTOM5=512 defers activation
until flight; it enables neither arithmetic twins nor scripted banking.

The local combined-run helper records the longer swap-rate comparison and its
census: `python3 tools/w2_combined_measure.py --machine a500 --mask 60` (or mask 0).
Its output directories must not already exist; use `--suffix=-manual` for another
pair. Use `--machine 020` or `030` for the retained faster-CPU configurations; use mask 56 on 030.
The cached-68030 helper uses inclusive routine wall clocks and DMA traces, not
instruction-cycle claims. Never run two helpers concurrently. Require at least
2,000 elapsed fields and inspect dashboard-event counts before quoting FPS.

## Cached 68030: drawing is the larger bottleneck

A focused unoptimized 50 MHz 68030 check changes the priority for accelerated
machines. The 77% figure from the old 68000 profile is the **whole 3D pass**, not
pure maths. Geometry dominates the older CPU's work, but that conclusion does not
carry over to a cached CPU with fast RAM.

The configuration is 2 MB chip + 8 MB fast, no slow RAM, MMU enabled, instruction
and data-cache configuration as in the validated cached baseline, CPU/memory/blitter
cycle accuracy enabled. Native maximum detail and Time Scale are unchanged.
CUSTOM2=0, CUSTOM5=512: no performance patches or per-call twins are active.
The log confirms MMU activation; emulator data-cache modeling is explicitly on.

These are entry-to-RTS **inclusive wall times**, including interrupts and chip-bus
waiting. The cached core lacks the 68000's usable instruction trace, so debugger
boundary observations read the VBlank counter and beam position. Counter phase
is independently checked; endpoints before line 3 or at ambiguous horizontal
counter boundaries are excluded. Only subordinate calls within accepted complete
3D passes at the same step contribute to the rows below.

| Sample / accepted steps | Work inside 3D pass | Mean ms/frame | Share of that pass |
| --- | --- | ---: | ---: |
| Drawing, 121–125 | Whole 3D pass | 46.915 | 100% |
| Same | Rectangles (`sim:2fc68`) | 12.846 | 27.38% |
| Same | Polygons (`sim:2f292`) | 10.076 | 21.48% |
| Geometry, 127–131 | Whole 3D pass | 46.486 | 100% |
| Same | Vertex transform/cache (`sim:38dcc`) | 2.664 | 5.73% |
| Same | Projection wrapper (`sim:38e9c`) | 1.296 | 2.79% |
| Same | Screen clipping (`sim:39ecc`) | 1.016 | 2.19% |
| Same | Back-face dot (`sim:3b1fa`) | 0.577 | 1.24% |
| Lines, 133–137 | Whole 3D pass | 46.872 | 100% |
| Same | Lines (`sim:2ea28`) | 5.680 | 12.12% |
| Other, 145–147 | Radius projection (`sim:3b282`) | 0.399 | 0.85% |

Rectangles plus polygons alone account for **48.86%** of the measured 3D pass;
the four measured geometry categories account for **11.95%** in their adjacent
window. This is not a complete partition: object setup, traversal and other work
remain, and small excluded calls make category totals conservative. The line row
must not be added blindly to the polygon row: polygon fallback can call the line
routine, and these are different windows. No 16-bit transform/projection calls
were seen in this sample.

Outside the 3D pass, the last sample also measures **6.468 ms/frame** for the
cockpit overlay (`sim:2c144`), **6.280 ms/frame** for bitmap draws (`sim:30572`),
and **3.357 ms/frame** for the world step. Earlier drawing samples additionally
contain rectangle, polygon and line work outside the 3D pass. These costs reinforce
the importance of screen drawing on the faster machine, without forming a single
cross-window frame budget or FPS claim.

Each group captures six frame iterations; counter-phase exclusions leave five
whole passes for drawing/geometry/lines and three for the final group. The groups
are adjacent windows from one boot, not independent optimization A/B pairs.
The first all-routine attempt exceeded breakpoint capacity and recorded no calls.
Incomplete early line/overlay endpoint sets were excluded; the separate line and
final overlay captures include all their return paths. Drawing's other complete
routine samples were retained. These failures are not counted as measurements.

**Implication:** continue exact W2 front-end improvements for the 68000, but do not
assume they are the largest opportunity on accelerated machines. In particular,
the original G4 dot accounts for only 1.24% of this 68030 pass; a specialized faster
CPU multiply implementation has a low ceiling. Drawing/fill/blitter traffic should
lead subsequent accelerated-CPU work. Whole-routine wall times identify that cost;
they do not by themselves separate CPU setup, DMA contention and blitter execution.

Evidence: `w2-pipeline-030`, including per-group clock logs, phase-filtered summaries,
and `breakdown.json`. VERIFY SHA-256:
`aa34be83f91045a8fbf3394459eff1a74cced3a1a1e1a69f8df9cf4644bdf73d`.

## Current W1 measurements (further work deferred)

W1a (table mirror) and W1b (chip mirror cache) are implemented for developer/VERIFY
builds. At the user's request, further W1 work is deferred in favor of geometry. Normal
release enablement remains off; developer/VERIFY options are available. These controlled runs share one VERIFY image and identical native
pre-flight setup; only CUSTOM2 changes. See `w1-verification.md` for the contracts
and evidence. Sound and game-time behavior are unchanged.

| Machine / measured swap window | OFF fps | W1a fps | W1a+W1b fps |
| --- | ---: | ---: | ---: |
| A500-equivalent, 8–108 | 1.880 | 1.878 | 1.876 |
| 14 MHz 68020, 80–400 | 6.154 | 6.151 | 5.996 |
| Cached 50 MHz 68030, mixed 1–699 | 12.778 | 12.387 | 12.502 |

Every reported interval spans at least 2,000 PAL fields. The first two rows are
event-free; the 68030 row includes different later mission states and is not an
isolated speedup comparison. The A500 step-8 states
match exactly; its steady window stays clamped. The 68020 starts from identical
state but enters variable dt, so equal-step world/scene states later diverge.
Its lower cache-on steady rate is retained in the table; this comparison alone
does not identify the cause. W1 targets dashboard events, not steady geometry.

| Opening mirror sample | OFF main cycles/call | W1a main cycles/call |
| --- | ---: | ---: |
| A500-equivalent, two complete calls each | 1,921,245 mean | 692,241 mean |
| 14 MHz 68020, one complete call each | 809,072 | 649,716 |

W1b removes in-place dashboard mirrors. Cold-build and later cache-hit costs are
reported separately below as available. These are provisional measured rows;
the unfinished scene and player-enablement checks are deferred (see `open-work.md`).

## Original 250-field profile

Captured 2026-10-09. Source baseline: `1904205` (`redbaron`).

## Original findings

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

## Earlier 30,324-byte cached 50 MHz 68030 baseline

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

## Earlier A500-equivalent baseline

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

## Earlier A500-host 14 MHz 68020 baseline

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
three-way same-window check passed. The final W0 sections below supersede the
earlier scene/machine limitations; optimization claims still require feature-specific checks.

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
target memory. The completed baseline matrix is summarized below.

Never insert `cont`, `wait` or `shot` between captures intended to form one experiment.
Even without those commands, each profile command has an unrecorded alignment interval:
joined files require explicit gap handling. Extract screenshots from existing trace files;
a new `shot` advances emulated time too.

## Current work and limits

The old next-work list is superseded by `performance-plan.md`, including its user decisions.
W0 is complete. See `verification.md` for the acceptance ledger and evidence limits,
and `open-work.md` for the ordered implementation work and outstanding user decisions.
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
capture setting. The final machine matrix is recorded below.

## Earlier-build event-containing long-window baseline rates

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
measurements. The final-build sections below supersede these historical rows.

The newer cached 68030 first-draw diagnostic independently correlates ten
logged publications with actual framebuffer DMA. Drawing starts 0.1971–0.2443
fields after the publication observer. One late publication produces 5,599
writes into the fetched display buffer, all behind the raster. See
`verification.md` for scope, cache conditions and the rejected phase control.
Its diagnostic overhead is excluded from the rate table above.

## Final W0-build cached 68030 baseline and routine wall times

The 30,380-byte VERIFY text, CUSTOM2=0 and CUSTOM5=0, with the explicit
MMU/data-cache configuration, completes **swap 120–700** in **2,272 fields**:
580 frames, **12.7438 fps**, no dashboard events, dt 124/155/186. Its
event-containing window, **swap 20–516**, completes 496 frames in
**2,001 fields**, **12.3741 fps**, with 40 mirror calls. The guarded census
starts at step 20 and reaches flight exit at step 1,033 without gaps.
The retained evidence is `w0-final-cached030-entry` and
`w0-final-cached030-census`. The first-fill diagnostic is disabled.

This supersedes the 30,324-byte build's rate for the current binary. The
small numerical difference is not a rendering improvement: no performance
patch is enabled, and the VERIFY build/layout changed.

The 68030 core supplies no usable instruction records, so read-only
entry/return breakpoints measure **inclusive wall time**, with interrupts
included. They check restored SP and omit incomplete calls. A separate
breakpoint after the VBlank counter update records 540 consecutive fields;
the latest observed update is on line 19. Calls with endpoints before
line 20 or without a corresponding counter-phase sample are excluded,
not assigned an ambiguous whole-field duration.

| Window | Routine | Accepted calls | Mean PAL fields | Range | Mean ms |
| --- | --- | ---: | ---: | --- | ---: |
| R-steady, steps 8–20 | 3D pass | 13 | 2.45490 | 2.42047–2.48040 | 49.176 |
| R-steady, steps 8–20 | World step | 13 | 0.16358 | 0.14950–0.19060 | 3.277 |
| R-event, steps 48–71 | Mirror | 23 | 0.86824 | 0.85318–0.88365 | 17.392 |
| R-event, steps 48–71 | 3D pass | 21 | 2.45895 | 2.31044–2.65069 | 49.257 |
| R-event, steps 48–71 | World step | 22 | 0.18606 | 0.15860–0.23572 | 3.727 |

Durations end immediately before RTS and must not be compared as main-only
CPU cycles with the 68000/68020 tables. These short call windows are not
FPS measurements. The rate windows above exceed 2,000 fields independently.

The first 20 steps provide a controlled observer check: all 77 routine
entry/return records and the complete step-20 record match a fresh boot
without the extra VBlank breakpoints exactly. Evidence and raw debugger
output are in `w0-final-cached030-clock`; `tools/routine_wall_time.py`
recomputes the summaries and retains excluded calls. The local read-only
collector is `tools/routine_clock.py --step 120 --out CALL_LOG.json`, run
from the paused first-flight checkpoint; it leaves the game paused at the
requested step.

## Final W0-build A500-equivalent baseline

The same 30,380-byte VERIFY text used for the final cached 68030 row boots
with 512 KB chip RAM, 1.5 MB slow RAM and no fast RAM, with PRELOAD and
CPU/memory/blitter cycle accuracy. All performance and optional diagnostic
bits are off. The saved configuration confirms the requested memory banks.

The event-free **swap 40–140** interval contains 100 frames in **2,717 PAL
fields**, **1.8373 fps**, dt=450 throughout. The event-containing **swap 2–72**
interval contains 70 frames in **2,000 fields**, **1.7472 fps**, including
four mirror calls over two dashboard-redraw frames. The census retains every
step from its post-capture start at step 2 through flight exit at step 243.

| Window | Routine | Complete calls | Mean main cycles | Range |
| --- | --- | ---: | ---: | --- |
| Opening R-event, 100 fields | Mirror | 2 | 1,920,529 | 1,919,652–1,921,406 |
| Opening R-event | 3D pass | 2 | 2,912,981 | 2,480,282–3,345,680 |
| Opening R-event | World step | 1 | 414,442 | Single complete call |
| R-steady at step 40, 100+50 fields | 3D pass | 6 | 2,123,886 | 2,088,160–2,173,562 |
| R-steady | World step | 5 | 373,229.6 | 321,684–397,386 |

The steady chunks retain their known one-field gap; incomplete calls are
excluded. The interrupt stack is established from the traced VBlank/CIA
callbacks, and all accepted routines restore SP. A fresh boot reproduces
the 100-field opening capture in every instruction, DMA, accounting and
full-screenshot byte. Its complete step-40 observer record matches the
census exactly. Both boots use deterministic host allocation.

Evidence: `w0-final-a500-entry`, `w0-final-a500-repeat` and
`w0-final-a500-census`. These supersede the older-build A500 numbers for
future comparisons; no optimization or improvement is claimed.


## Final W0-build A1200 / 14 MHz 68020 baseline

This run uses the specified A1200 host and A1200 Kickstart, 68EC020 at PAL
multiplier 4 (about 14.2 MHz), 2 MB chip and 8 MB fast RAM, no slow RAM,
and CPU/memory/blitter cycle accuracy. The saved emulator configuration
confirms those settings. It uses the same final VERIFY binary as the A500
and cached 68030, with CUSTOM2=0, CUSTOM5=0 and the existing BaseNC cache
policy. Earlier A500-host 68020 runs remain compatibility controls only.

The event-free **swap 80–400** interval contains 320 frames in **2,593 PAL
fields**, **6.1606 fps**, dt 248–450. The event-containing **swap 4–241**
interval contains 237 frames in **2,007 fields**, **5.8949 fps**, including
20 mirror calls, eight message calls and eight dirty triggers. The census
retains all records from its post-capture step 4 through flight exit at 509.

| Window | Routine | Complete calls | Mean main cycles | Range |
| --- | --- | ---: | ---: | --- |
| Opening R-event, 40 fields | Mirror | 1 | 809,322 | Single complete call |
| Opening R-event | 3D pass | 4 | 1,576,117.5 | 1,561,484–1,590,117 |
| Opening R-event | World step | 3 | 186,790.7 | 170,387–196,207 |
| R-steady at step 80, 40 fields | 3D pass | 5 | 1,377,861.6 | 1,316,690–1,411,958 |
| R-steady | World step | 5 | 191,119.6 | 170,735–205,420 |

A fresh boot reproduces every instruction, DMA record, accounting value and
whole screenshot in the 40-field opening capture. The entire step-80 record,
including beam position, matches the census. The interrupt stack is confirmed
from the callbacks; cut calls are excluded and accepted calls restore SP.

The steady trace contains 188,960 framebuffer word writes, with observable
blitter destinations and **zero active-display conflicts**. All five copper
publications match their 24 word values. AGA writes two words in one chip slot;
`frames.py` now decodes that longword format as well as the ECS word format.
The first write into the former display begins **0.9613–1.1071 fields after
publication finishes**. This establishes the unoptimized window's margin,
not tear freedom after future rendering changes. Regression tests require both
formats to match every register value and reject a corrupted publication.

Evidence: `w0-final-a1200-entry`, `w0-final-a1200-repeat` and
`w0-final-a1200-census`. To reproduce the machine configuration from the local
harness directory, source `amiga/env.sh`, then use:

```sh
MallocScribble=1 AMIGA_MODEL=A1200 KICKSTART="$KICKSTART_A1200" \
CPU=68EC020 CHIP_KB=2048 FAST_KB=8192 \
EXTRA_ARGS='--slow_memory=0 --uae_cpu_multiplier=4 --uae_cpu_speed=real --uae_cpu_cycle_exact=true --uae_cpu_memory_cycle_exact=true --uae_blitter_cycle_exact=true' \
python3 tools/reach_flight.py --out tmp/prof/a1200-calibration
```

Use the resulting retained flight anchor as `BOOT_BREAK` for fresh fixed-point
boots; anchors depend on build/layout and are not portable constants. Capture
40 fields at entry with `capture_current.py`, or advance to step 80 with
`step_log.py` before the steady capture. Use `dashboard_census.py` for the
long swap windows; analysis must use the live sim base and callback stack.

## Completed W0 baseline matrix

All final machine rows use VERIFY SHA-256
`2dc372da8f46efb03988c3df851fae5a3bc37edd2bb8c6020a5b8a3a6451b126`,
30,380 bytes of text, maximum detail, Time Scale 40 and no optimization bits.

| Machine | Event-free fps | Event-containing fps |
| --- | ---: | ---: |
| A500-equivalent, 512 KB chip + 1.5 MB slow | 1.8373 | 1.7472 |
| A1200, 14 MHz 68020, 2 MB chip + 8 MB fast | 6.1606 | 5.8949 |
| Cached 50 MHz 68030, 2 MB chip + 8 MB fast | 12.7438 | 12.3741 |

Every rate spans at least 2,000 fields. The rows use the same source binary,
but CPU-dependent dt produces different world trajectories; these are baseline
rates, not equal-world-state speedup ratios. Routine costs and sample counts
appear above. The 68030 values are inclusive wall time, whereas the other
machines support main-context cycle attribution. Fast-CPU ownership checks
are scoped to their actual recorded windows. No rendering, sound or game-time
change is enabled by completion of W0.


## W1a initial complete-call check (matrix pending)

The initial W1a implementation uses one VERIFY binary, SHA-256
`6f84584180b17ce7f5b27e46088dba7630f6c829aa581079cf1317695658b7ac`,
with CUSTOM2=0/1 and CUSTOM5=0. Two separate 100-field opening captures use
the continuity configuration (68000, 1 MB chip + 2 MB fast + 512 KB slow).
They retain the following completed dashboard mirror calls:

| Setting | Complete calls | Mean main cycles | Range |
| --- | ---: | ---: | --- |
| Original, CUSTOM2=0 | 2 | 1,853,636 | 1,852,524–1,854,748 |
| W1a, CUSTOM2=1 | 2 | 630,106 | 629,354–630,858 |

The candidate count includes the hook, option check and entry blitter wait.
The interrupt stack is established from this capture's callbacks. Calls cut
at the edges are excluded. `call_costs.py --routine NAME:ENTRY:RTS` accepts
live replacement endpoints from the retained listing and slave marker, with
the same SP/context checks as original calls. Evidence is `w1a-{off,on}-entry`.

These are preliminary routine measurements, not the required three-machine
W1 result or a frame-rate claim. No release bit is promoted. Full fixed-window,
long-swap and cache measurements remain in progress; correctness evidence and
remaining gates are in `w1-verification.md`.

## W1 controlled-start update

Enabling W1 during the native menu/preferences route changes the state that reaches
flight. The first A500 OFF/W1a pair differs in 3,039 h3 bytes at entry and 1,490 at
step 8; its performance captures remain exploratory. VERIFY CUSTOM5=512 now
activates the selected CUSTOM2 bits only after the first recorded flight checkpoint.
With this fixture, OFF, W1a and W1a+W1b match **all 48,396 h3 bytes**, both at entry and at
step 8, without pointer normalization or timer exclusions. The recorded steps remain
at dt=450. All three disabled performance ranges retain the original relocated bytes
in the OFF run.

This comparison uses the 34,332-byte VERIFY text build, SHA-256
`99c490efbde1b312d42c77ffeb3b7d348cacb6364b402fa9d15803765485d313`.
Evidence is `w1-deferred-entry-{0,1,3}` and `w1-deferred-step-control-0`.
The fixture changes test setup only; player builds still install at load time.
The complete three-machine performance matrix remains in progress; no new FPS claim
is made from this state check.

The controlled OFF A500 census now starts before the first flight checkpoint
resumes and reaches the flight-loop exit at step 358. It retains every step and
counts 358 swaps, one full redraw, 18 mirror calls, 37 message calls, 12 dirty
triggers and 24 clip rejections. **Swap 8–108** completes 100 event-free frames
in **2,656 PAL fields: 1.880 fps**, with dt=450 throughout. The complete swap
1–358 interval is 357 frames over 9,705 fields (**1.836 fps**), but includes
late-flight view transitions with dt values 124–450; it is not a steady-flight
rate or a clamped-state comparison.

The opening trace retains two original mirror calls at **1,919,746 and 1,922,744
main-thread cycles** (mean **1,921,245**). The steady step-8 traces retain four
3D calls averaging **2,419,059.5 cycles** and five world steps averaging
**344,458.8 cycles**. Chunk-boundary calls are excluded and interrupt stacks
are established independently from the VBlank and CIA callbacks. These are
current OFF measurements, not yet a completed optimization comparison.

The matching W1a-only A500 run retains two completed mirrors at **692,132 and
692,350 main cycles** (mean **692,241**). Its two W1b hook ranges remain original.
Swap 8–108 takes **2,658 fields: 1.878 fps**, also event-free with dt=450 throughout;
this steady window shows no gain from a dashboard-event optimization. Its entire
step-8 h3 snapshot matches the measured OFF run exactly. The full census reaches
step 358 with 18 mirrors, 35 message calls and 11 dirty triggers; late-flight
tracking-regime event counts are not expected to be identical. These A500 rows
are provisional until the required three-machine matrix is complete.

The A500 W1a+W1b census also reaches step 358, with **zero entries to the game's
mirror routine**, 35 message calls and 11 dirty triggers. The initial two dashboard
draws cost **1,149,754 cycles** for the mirrored side (including its one-time cache
build) and **86,202 cycles** for the ordinary side. These must not be reported as
hot-cache lookup costs. The corresponding original draws cost 2,005,374 and
1,988,400 cycles. Swap 8–108 takes **2,661 fields: 1.876 fps**, with no events;
the step-8 h3 state still matches OFF exactly.

On the 14 MHz 68020, OFF and W1a also have identical complete entry snapshots.
The opening traces each retain one complete mirror: **809,072 cycles OFF** and
**649,716 with W1a**. A call crossing the capture boundary is excluded. Event-free
swap 80–400 takes **2,596 fields (6.154 fps) OFF** and **2,597 fields (6.151 fps)
with W1a**. Both intervals exceed 2,000 fields. Their dt values range from 248 to
450, so later equal-step state equality is not a correctness requirement.

All retained A500 event/steady chunks for masks 0, 1 and 3, and the completed
68020 event/steady chunks for masks 0 and 1, have observable blitter writes and
**zero active-display write conflicts**. This is scoped to those recorded windows,
not a universal tear-free guarantee. The cached 68030 and remaining scene checks
are still pending.

The 68020 W1a+W1b run also starts with an identical h3 snapshot and reaches
flight exit at step 516 with no in-place mirror calls. Event-free swap 80–400
spans **2,664 fields (5.996 fps)**, with dt values 279–450. This is lower than
the OFF result and must not be described as a steady-flight gain. The changed
frame timing alters the subsequent world trajectory, so an equal-step FPS
comparison does not isolate code overhead on this tracking-regime machine.

## Cached 68030 primary results and fallback correction

All three cached-CPU primary cases start with identical complete h3 snapshots.
The shared **swap 1–699** interval covers 698 frames: OFF takes **2,727 fields
(12.778 fps)**, W1a **2,813 fields (12.387 fps)** and W1a+W1b **2,787 fields
(12.502 fps)**. These are mixed intervals with different subsequent world states
and event counts, not an isolated rendering-speed ratio. The longest completely
event-free OFF interval is only 1,993 fields, below the required rate window;
no steady FPS claim is made from it.

The full guarded censuses end at steps 699, 817 and 1,007 respectively. OFF has
62 mirror entries, W1a 78 and the cache run none. World dt and mission events
diverge after the common starting state. In the common rate interval, OFF has
60 mirrors after its boundary swap, W1a has 36 and cache-on has none. Such counts
must not be compared as if they were identical world trajectories.

The saved settings select 50 MHz, MMU, CPU data-cache modeling and full blitter
accuracy. The OFF event trace has no active-display write conflicts; W1a has
**1,961** and cache-on **6,269**. None of those written words is fetched later in
its field, so these records do not establish a visible tear. All three steady
traces have zero such conflicts. This remains a display-ownership warning for W5,
not a tear-free guarantee.

The primary matrix above uses SHA-256
`99c490efbde1b312d42c77ffeb3b7d348cacb6364b402fa9d15803765485d313`.
A subsequent reproduced fallback-invalidation defect is fixed in default VERIFY
SHA-256 `5c0918ccbccb27ad301478873e1aeab8398f057211b2749ce7d16fe949f23475`.
Only two branch-displacement bytes change, with unchanged layout. Neither branch
is taken in the retained A500/68020 cache-on CPU traces. Correctness regressions
pass; see `w1-verification.md`. Remaining scene and call-cost captures use the
corrected binary, and the older matrix retains its explicit build attribution.

## Corrected-build warm dashboard costs

These runs use corrected VERIFY SHA-256
`5c0918ccbccb27ad301478873e1aeab8398f057211b2749ce7d16fe949f23475`,
with twin/paint diagnostics off. A500 and 68020 samples begin at each setting's
first later natural dirty event identified by its census. They measure completed
calls, not equal-state frame-rate comparisons. The same 168×102 EDASH-B bitmap
is drawn through `sim:30408`; request 2 is mirrored and request 0 is ordinary.

| Machine / warm draw | OFF main cycles (calls) | W1a main cycles (calls) | W1a+W1b main cycles (calls) |
| --- | ---: | ---: | ---: |
| A500, mirrored | 1,940,090 (1) | 715,830 (2) | 31,845 (3) |
| A500, ordinary | 1,930,434 (1) | 703,760 (2) | 10,713 (3) |
| 68020, mirrored | 840,277 (2) | 689,456 (3) | 38,073 (4) |
| 68020, ordinary | 824,497 (2) | 656,225 (3) | 12,876 (4) |

Values are means rounded to whole cycles. The ordinary original draw also pays
to mirror the game bitmap back. No in-place mirror calls remain in either
cache-on trace. Cache-on draws still pay for clipping and the original blitter;
these numbers are not cache-lookup costs. Evidence: `w1-hot-{a500,020}-{0,1,3}`.

The cached 68030 uses read-only entry/return breakpoints and VBlank/beam clocks,
with counter-phase validation. These are elapsed times including interrupts,
from entry to just before RTS; they are not main-context CPU cycles. Samples
come from steps 1–119 of `w1-clock-030-{0,1,3}`. Endpoint records at horizontal
positions 0/1 are excluded because the captured horizontal wrap can retain the
preceding vertical count. Ambiguous VBlank-phase endpoints are also excluded;
17, 17 and 16 dashboard/lookup/mirror records respectively remain excluded.
A negative duration away from those boundaries is an error, not repaired data.

| Cached 68030 measurement | Calls | Mean elapsed time |
| --- | ---: | ---: |
| Original in-place mirror | 33 | 17.486 ms |
| W1a in-place mirror, including its required entry wait | 29 | 23.157 ms |
| OFF mirrored dashboard draw | 18 | 20.384 ms |
| OFF ordinary dashboard draw | 16 | 18.301 ms |
| W1a mirrored dashboard draw | 11 | 26.812 ms |
| W1a ordinary dashboard draw | 19 | 24.589 ms |
| W1b first mirrored draw, including build | 1 | 47.945 ms |
| W1b cache build alone | 1 | 41.681 ms |
| W1b later mirrored draw | 19 | 2.936 ms |
| W1b later ordinary draw | 19 | 0.915 ms |
| W1b cache hit alone | 21 | 0.01455 ms |

The first ordinary cache-on draw takes 9.750 ms and is excluded from the later
ordinary mean. There is one observed build; later draws reuse it. The mirror
regression is a measured whole-call result, including waits and interrupts;
these clocks do not isolate its microarchitectural cause. Accordingly the normal
player selection retains the original in-place mirror on 68030 and conservatively
on unmeasured 68040/68060. Developer/VERIFY masks still allow explicit W1a tests.
W1b still uses the table once to build its private chip copy. This selection
policy does not change the existing default-off preference or icon tooltypes.

## Event-containing rates over common intervals

The retained primary measurement build gives these mixed rates. Every interval
exceeds 2,000 fields and uses the same boundary swaps for all three settings.
The boundary swap itself is not counted as a completed frame.

| Machine / swaps | OFF fields / fps | W1a fields / fps | W1a+W1b fields / fps |
| --- | ---: | ---: | ---: |
| A500, 1–358 | 9,705 / 1.8363 | 9,536 / 1.8689 | 9,457 / 1.8845 |
| 68020, 1–516 | 4,321 / 5.9498 | 4,250 / 6.0492 | 4,102 / 6.2674 |
| Cached 68030, 1–699 | 2,727 / 12.7776 | 2,813 / 12.3869 | 2,787 / 12.5025 |

These include dashboard events and late mission transitions. Timing and event
histories differ after the common starting state; the numbers are observations,
not isolated code-speed ratios. In particular, do not discard the slower 68030
rows or generalize the warm-draw savings to steady flight. The per-call results
justify retaining the original in-place mirror on that CPU. Evidence is each
primary case's `common-mixed-rate.json`, derived from its complete guarded census.

## Repeating the W1 checks manually

Run from the local development harness after sourcing `amiga/env.sh`. Use a fresh
output directory per boot and stop only this project's recorded emulator before
starting another. Do not run a second capture controller alongside a queue.

For controlled comparisons, use the same VERIFY binary and `CUSTOM5=512` for
every setting: CUSTOM2=0 is OFF, 1 is table-only, 3 is table plus cache, and 2 is
cache-only (the player policy on the cached 68030). Leave twin and paint bits off.
For example, an A500-equivalent calibration boot is:

```sh
MallocScribble=1 CPU=68000 CHIP_KB=512 FAST_KB=0 \
EXTRA_ARGS='--slow_memory=1536 --uae_cpu_multiplier=2 --uae_cpu_speed=real --uae_cpu_cycle_exact=true --uae_cpu_memory_cycle_exact=true --uae_blitter_cycle_exact=true' \
WHD_ARGS='CUSTOM2=3 CUSTOM5=512' \
python3 tools/reach_flight.py --no-shot --out tmp/prof/my-w1-entry
```

The saved `entry.json` contains the build hash, machine settings and first-flight
anchor. Set `BOOT_BREAK` to that retained anchor on subsequent fresh boots of the
same layout; do not copy an address from another build. The common checkpoint
precedes activation. `capture_current.py --out tmp/prof/my-w1-event --fields 100`
records the A500 event window; use 40 fields on the 68020 or 20 DMA fields on the
cached 68030. Advance with `step_log.py --step 8` for the ace steady checkpoint,
or with `--step 24` for the banking checkpoint. Each profile chunk is separate.

For bank, set CUSTOM5=514; for the rear-view dense fixture, use CUSTOM5=532.
The current scene matrix uses step 24 and step 8 respectively. These short
traces provide routine costs and display checks, not FPS. Use the separately
fresh-booted `dashboard_census.py` run and `census_window.py` swap boundaries
for rates spanning at least 2,000 fields. For the ace A500 window, start again
at a fresh no-shot flight checkpoint, then run:

```sh
python3 tools/dashboard_census.py --out tmp/prof/my-w1-census
python3 ../../R/RedBaron/tools/census_window.py \
  tmp/prof/my-w1-census/census.json --start 8 --end 108 \
  --out tmp/prof/my-w1-census/rate.json
```

Check the resulting field count and event list; other scenes/CPUs need suitable
swap boundaries, not an assumed 8–108 rate window. The primary matrix's old binary hash
is retained explicitly above; rebuilding the corrected image is a new capture.

On a cached 68030 use the documented MMU/data-cache configuration, then collect
read-only routine clocks instead of instruction costs:

```sh
python3 tools/w1_clock.py --entry tmp/prof/my-w1-entry --mask 2 \
  --step 120 --out tmp/prof/my-w1-entry/clock.json
python3 ../../R/RedBaron/tools/routine_wall_time.py \
  tmp/prof/my-w1-entry/clock.json --first-step 1 --last-step 119 \
  --out tmp/prof/my-w1-entry/costs.json
```

The mask must match the boot. The clock collector takes replacement return
addresses from that capture's retained listing and validates restored SP. Keep
its phase exclusions; do not reinterpret elapsed time as main CPU cycles.
For CPU traces, `call_costs.py` accepts explicit replacement entry/RTS pairs
with `--routine`, and requires an interrupt-stack interval established from
that trace's VBlank/CIA callbacks. The local `w1_window_cost_report.py` helper
performs that derivation for the retained W1 window layout.

Correctness boots use CUSTOM5=864 (deferred activation, mirror/pixel/lifecycle
twins); add 2 for bank or 20 for dense. CUSTOM5 bit 7 additionally forces chip
allocation failure. These are separate from timing runs. `mirror_checks.py`
reads the completed counters; the cache status must also show completed build,
pixel and lifecycle checks. Model/test checks and the three-range static audit
are in the versioned tools directory.
