# Red Baron verification groundwork

The work order and acceptance requirements are in `performance-plan.md`. Performance
patches are not yet installed. This document records the observer ABI and current W0
validation; it does not mark the complete W0 gate as passed.

## W0 acceptance ledger

This ledger is the current gate status; historical observations below retain their
original scope. No rendering optimization is enabled.

| Item | Status | Remaining acceptance work |
| --- | --- | --- |
| W0.1 rebuilt equivalence | Passed at the fixed opening checkpoint | None; differing chip storage is classified below |
| W0.2 continuity | Passed | Manual profile packaging also passed its complete 100-field rerun; see `profiling.md` |
| W0.3 counters | Passed | Trace, independent swap breakpoints and ring agree on the squadron steps 1–2 interval |
| W0.4 scenes and machines | Open | Select an aircraft-dense window; complete strict repeats and event/steady costs for the machine matrix; resolve screenshot-border differences; complete first-draw coverage |
| W0.5 event census | Passed for the complete baseline mission | Top-text branch had zero occurrences; no coverage claim for that branch |
| W0.6 game time | Open | Complete the Time Scale 0/40/60 velocity interpretation and nominal-speed analysis; identify the timer coupling before relying on broader state equality |
| W0.7 framework | Passed | Empty performance-range audits remain explicitly pending until a feature declares ranges |
| W0.8 reference infrastructure | Passed for the initial references | Mirror/projection models and original copies checked; each future replacement must add its own model and live twin under the contract below |

The W6 forced-dt, collision and equal-wall-time design experiments remain separate
from this groundwork. W0 does not authorize a game-time implementation. Release
switch default and icon policy remain user decisions before shipping the switch.

## VERIFY observers

The existing flight-input hook records one entry after incrementing the game-step counter,
when the scripted menu/preferences route is complete. The additional VBlank hook replaces
one complete LEA at `sim:2d348`; it reconstructs the original LEA, counts VBlanks and restores
SR. The callback runs on the interrupt stack; KickEmu callbacks can run in user mode,
so SR alone must not be used to classify interrupt work. Both instruments are VERIFY-only
and apply only to the existing supported v1 patch list.

The live `RBSTEPS1` header contains seven longwords after its eight-byte signature:
version, record stride, capacity, committed count, ring pointer, h3 base, sim base.
A VBlank-count longword follows. Pointers initialize only in the live slave. The ring
has 256 entries, each 44 bytes. It overwrites the oldest entry on wrap. The committed
count advances only after all fields of the new record have been written.

| Record byte offset | Type | Meaning |
| --- | --- | --- |
| 0 | long | Flight step |
| 4 | long | Lifetime CIA ticks, `sim:30006` |
| 8 | long | Beam-position register pair |
| 12 | long | Display-buffer pointer, `h3:09d66` |
| 16 | word | Previous elapsed-time argument, `h3:0483a` |
| 18 | word | World dt, `h3:04834` |
| 20 | word | Secondary dt, `h3:04836` |
| 22 | word | Time-scale divisor F, `h3:04838` |
| 24 | word | Time Scale, `h3:03d56` |
| 26 | word | View redraw counter, `h3:06716` |
| 28 | word | Zero-extended **byte** dirty counter, `h3:0711c` |
| 30 | word | Top-text redraw counter, `h3:045b8` |
| 32 | long | World/frame counter, `h3:03254` |
| 36 | word | Message countdown, `h3:04820` |
| 38 | word | Reserved, zero |
| 40 | long | VBlank count |

The message-dirty variable is byte-sized: reading a word also includes an unrelated
adjacent byte. The other listed counters retain their original widths.

## Checks completed

- A VERIFY build reaches the accepted maximum-detail flight checkpoint with observers.
- The record reports Time Scale 40, F=33 and dt=450 in the measured slow-machine window.
- Eleven read-only breakpoints at `sim:3154a` agreed with the subsequent step records in
  both VBlank and CIA-tick counts, for steps 2–12.
- A single 100-field trace starting after step 12 contained four copper-list updates and
  four subsequent step-log advances. Their VBlank intervals agreed (23, 26 and 24 fields).
- The normal slave remains byte-identical to the pre-observer build and contains neither
  observer marker. This proves exclusion of instrumentation. The separate shipped-slave
  comparison is recorded under “Shipped/rebuilt opening comparison” below.
- Normal, DEVELOPER and VERIFY builds have separate local outputs. Assembly listings can
  be retained with captures.

Two fresh boots of the same VERIFY build produced identical instruction records, DMA
records and screenshots for all 100 recorded fields at the initial flight checkpoint.
This covers the initial event window. Later sections record the completed three-way
comparison and the remaining W0.4 scene/repeat limitations. The observer adds code and RAM;
performance measurements must consistently use the same instrumentation build.

## Capture continuity

The VBlank observer confirms that this Barto build advances through an unrecorded interval
when starting a profile command. At consecutive capture boundaries, this is one whole field:

| Requested recorded fields | VBlank advance |
| ---: | ---: |
| 20 | 21 |
| 10 | 11 |
| 10 | 11 |
| 1 | 2 |
| 1 | 2 |
| 1 | 2 |

The initial interval depends on the starting beam position: an arbitrary mid-field
checkpoint need not produce an extra complete VBlank count. Completed captures followed
by another capture have the reproducible one-field gap. Consecutive binary files are
therefore **not a continuous instruction stream**. Reset reconstructed call stacks at
each join and exclude incomplete calls from per-call cost comparisons.

Local tools now mark joins explicitly. Cycle captures default to a single window of at
most 100 fields. Longer frame-rate and event runs use the ring and swap breakpoints rather
than joining instruction captures. No game-time implementation or sound change is included.

## Deterministic mouse input

Disabling emulator joystick/mouse input did not neutralize the hardware mouse counters.
Two fresh boots initially produced identical screenshots but different instruction and
DMA data. The first differing instruction was the mouse-counter read at `sim:2d354`;
its returned value changed the interrupt's mouse deltas.

VERIFY therefore replaces that complete six-byte read with `move.w #0,d1` and a NOP.
It applies only to sim v1 and preserves the destination width and condition-code effects
of the original read. With this change the two 100-field captures matched exactly,
without filtering differing records. Normal and DEVELOPER builds retain the original
mouse read. This is a test-input control, not a rendering optimization.

## Shipped/rebuilt opening comparison

The unmodified rebuilt slave and shipped 2.1 slave both reach the main menu without
the keyboard tape. Each run starts from reset with a read-only breakpoint armed at
`ps:15b3a`, advances to its 1001st crossing, then records 100 PAL fields.

The visible 640×400 menu pixels match exactly. All 40,000 bytes fetched by bitplane
DMA in the last two fields also match. A fresh repeat also has identical final raw
PNGs; the earlier pair differed only outside the game image.

The post-capture chip dumps differ in 2,011 bytes, now classified by ownership:

- 647 are in the low-memory page, including vectors into the differently assembled
  slave/KickEmu and unused fill bytes.
- 31 are in four planes of the inactive framebuffer, within pixels x=80–88,
  y=47–54. The unchanged pointer-position header at `ps:25a88`, decoded through
  the mouse callback, places the pointer at (80,47). These differences lie inside
  its footprint; the active framebuffer remains identical.
- 1,333 are in the sound driver's eight 224-byte chip buffers. The live allocation
  pointer and all eight buffer pointers agree between runs. `sound:1526–1584`
  allocates 1,792 bytes and fills that pointer table, proving ownership. Buffer
  contents can retain different earlier audio phases; audio-sequence equivalence
  has not been established.

None of these differing bytes is fetched by bitplane DMA in the final two fields.
The rebuilt slave passes the fixed visible opening checkpoint with these explicit
storage differences. Full chip-RAM equality and audio-stream equality are not claimed.

## Swap beam positions

The local `frames.py` now matches the actual 24 CPU word writes of the original
`movem.l d2-d7/a1-a6,(a0)` at `sim:3154a` against DMA addresses and data. It reports
first/last write beam slots; incomplete matches stay explicit. Summed instruction
cycles are no longer presented as exact beam positions. At the initial event checkpoint
of the reproducible 100-field capture, its one publication begins at line 14, horizontal
slot 139 and ends at slot 185 of the same line. This single publication is insufficient
to establish tear-free behaviour.

## Option and hook-check framework

All builds now declare WHDLoad interface 17 and a splash configuration. Release builds
show one Faster rendering switch; developer and VERIFY builds expose the individual
CUSTOM2 bits from the plan. The verified release mask is currently zero: this framework
installs no optimization. The default-on/off and icon policy remain user decisions.

`resload_Control` reads CUSTOM2 and CPU attention flags before loading the game, and
CUSTOM5 in VERIFY. The sim v1 version branch alone calls the performance installer.
The original v2/v3 patch lists are unchanged. VERIFY flight entry on the 68020 confirms
CUSTOM2=513, CUSTOM5=7, the matching developer mask, and the expected CPU flags.
Normal and developer outputs contain neither the tape nor step-ring marker.

`perf_check_bytes` provides the fail-message check for non-relocated hook bytes; each
future installer must invoke it before writing its range. Relocated operands require
checks computed from live hunk bases. The installer currently has no ranges.

The versioned tools alongside these docs provide:

- `check_disabled.py`: apply original HUNK_RELOC32 records using the live BPTR chain,
  then compare each declared PERF_RANGE with the corresponding memory dump.
- `audit_hooks.py`: check whole-instruction boundaries, direct incoming branches and
  relocation targets inside ranges. Indirect callers still require manual review.
- `test_checks.py`: synthetic acceptance and rejection cases without game data.

Both audit commands report PENDING when no performance ranges exist; an empty audit
is not counted as a pass. The parser has also read the original four-hunk sim fixture,
including all 8,686 code relocations and 541 data-hunk relocations. No game bytes are
embedded in the tools. The CUSTOM5 consumers and original-reference infrastructure
are described below; replacement-specific twins remain gates for their features.

## Slowed-drawing and state comparison

CUSTOM5 bit 0 is now a VERIFY-only slowed-drawing probe, installed at the first true
flight step. The hook is the complete JMP at `sim:015b2`, which serves the 3D call
at `sim:007b8`; the four-byte JSR at that call site cannot itself hold a six-byte hook.
The original opcode and relocated destination are checked before installation. Static
boundary/branch/relocation audit passed for the stub. The original renderer receives
its unchanged stack arguments through a tail call.

The off/on runs use the same retained binary, both reach flight, and stay clamped at
dt=450 through step 20. Entry h3 state matches exactly; step 20 differs only in the
elapsed argument and one CIA timer timestamp. See `game-time.md` for the explicit
values and limitations. Normal builds still exclude this probe.

`compare_h3.py` compares the full h3 allocation and separately reports candidate
relocated pointers into sim or h3. It never labels a normalized comparison as strict
byte equality. Seven synthetic checker tests now cover changed data, relocated pointer
candidates, invalid snapshot sizes, hook boundaries and incoming references.

The 68030 mission reached debriefing at flight step 314. The first 200-swap segment
contains only 745 PAL fields and is too short for the required long-window rate.
The interrupted subsequent segment includes UI swaps and is marked incomplete. The
local swap harness now arms an additional read-only breakpoint at `sim:21f4a`, the
flight-loop exit, and rejects a capture that did not reach its requested flight step.
A later complete mission validates that automatic stop; see the census below.

## Explicit straight and bank fixtures

Banking is now opt-in: CUSTOM5 bit 1 holds Right at steps 20–34 and releases it at
35. The local `reach_flight.py --bank` sets that bit while preserving other CUSTOM5
bits. The default fixture keeps Right released. This separates R-bank from the
long steady-flight setup; older captures explicitly described as mixed still include
the old unconditional bank. Both current routes reach their requested checkpoints.

The straight 50 MHz 68030 fixture subsequently completed a clean 800-swap window
over 2,613 fields. An earlier short segment was rejected after a debugger transport
error (`Invalid hex digit`), rather than treated as mission completion. The valid
window is separate and starts at the following flight-step checkpoint.

## Original-code and mirror-model references

VERIFY now copies the relocated original bodies at `sim:304d0` (162 bytes),
`sim:38c82` (330 bytes) and `sim:39df2` (218 bytes) before the performance installer
can modify them. No game bytes are embedded in source. All three live copies were
checked byte-for-byte against the original loaded bodies. Static examination found
no PC-relative reference outside each copied range; absolute data and callback
references continue to use the game context. Future twins must still isolate their
output buffers and callback state. The copies alone are not completed twins.

`mirror_model.py` has independent bit-loop and byte-table paths. Host tests cover
all 65,536 words with both initial low-bit states of the LSR/ROXL accumulator, and
4/5-plane bitmaps at width/height boundaries including nonzero padding bits. Masks
are regenerated as OR(planes) with a zero extra word on each row.

One complete live original call was stopped at entry and immediately before RTS: a
168×102 five-plane dashboard matched both the bitmap and mask model exactly. All
general registers and SP matched their entry values. SR changes in the original,
so it is recorded separately rather than incorrectly required to be preserved.
This validates the model against an original call; replacement assembly and live
replacement twins remain future gates.

## Fast-CPU DMA visibility limitation

The retained 50 MHz 68030 DMA-only follow-up has ten fields, each with 20,000
bitplane word fetches. The selected framebuffer changes twice. However, the saved
configuration disables blitter cycle accuracy and the log contains no blitter DMA
records. An empty list of conflicting writes is therefore **unobservable**, not a
tear-free pass. P1 still requires the first-draw observer and display-ownership check
specified by W0.4. CPU cycle accuracy alone is insufficient to validate that check.

## Squadron route and frame-counter cross-check

VERIFY CUSTOM5 bit 2 selects a four-versus-four British squadron mission instead of
the ace mission. It leaves the default mission settings unchanged: Sopwith Snipe
against Fokker D.VII, same altitude, light wind and partly cloudy sky. The common
simulation route still declines the mission tape, maximizes detail and accepts the
panel without changing Time Scale 40. The local entry harness accepts `--dense`;
`--bank` may be combined with it. Normal and developer builds exclude this route.

The squadron briefing initially has no keyboard focus: three Tabs select Begin
Mission. The completed route emits 87 keys and reaches the true flight checkpoint.
This creates a candidate R-dense mission; a later window with several aircraft
actually in view still needs selection and geometry-count validation.

Two fresh boots with the flight-entry breakpoint armed at reset produced identical
instruction records, DMA records and screenshot bytes for all 100 recorded fields.
An earlier pair using asynchronous debugger polling during startup had the same
images but a two-field entry-clock difference and failed the strict comparison.
Use a calibrated reset-armed breakpoint for reproducibility checks; its address is
valid only for that exact build and machine configuration. The observed agreement
does not establish reproducibility of every later window.

For the same squadron interval, steps 1 to 2, the trace, independent SWAP_ONLY run
and step ring agree: one publication, 73 elapsed VBlanks and 86 CIA ticks. The two
step records match byte-for-byte across runs. At the publication the swap breakpoint
reads beam line 59, horizontal slot 71; the trace records the 24 pointer-word writes
at slots 76 through 136 on that same line. Both the breakpoint and subsequent step
record report VBlank count 9,357 and lifetime CIA tick 9,691. This validates the
three instruments on one shared interval; the longer scene/machine matrix remains.

## Completed mission census and exit guard

A fresh reset-armed ace/bank boot was observed from flight step 1 through the
`sim:21f4a` exit at step 357. The collector drained the ring at step 201 and retained
every step, with 357 flight swaps and no debriefing records. Its two segments both
completed normally. This validates the automatic flight-exit guard on a real mission
ending, replacing the earlier untested status of that guard.

The six attribution breakpoints counted 33 message calls, 13 dirty triggers, one
full-redraw branch, no top-text branch, 44 mirrors and 65 bitmap rejections. Mirror
entry snapshots identify the same 168×102 descriptor in every call. Reject-path
`a0` is descriptor+8; none of those 65 rejections refers to the dashboard descriptor.
See `profiling.md` for the scope and current rate. The top-text case was not exercised.

## Steady and banking repeats

Fresh reset-armed boots reproduce every instruction and DMA record in the steady
window (step 8, 100+50 recorded fields) and banking window (step 24, 100 fields).
All game-image pixels match. Raw screenshot differences are confined to three
columns at the emulator's far-right border; full PNG byte equality is not claimed.
The known chunk gap remains explicit. The steady window contains six complete 3D
passes; its routine costs are recorded in `profiling.md`.

`call_costs.py` rejects unknown stack contexts and wrong return SP, and never joins
a partial call across files. Synthetic tests cover a user-mode interrupt callback,
a call cut at a chunk boundary and a wrong return stack. It also reproduces the
established original mirror cost using five complete baseline calls.

## Long-window census accounting

`census_window.py` measures explicit swap-to-swap intervals and attributes work to
steps after the starting swap through the ending swap. Synthetic tests cover the
starting-boundary exclusion, the 2,000-field threshold, events inside the interval,
and missing/duplicate/partial evidence. The retained 68000 + fast census passes
for swaps 80–180: 100 completed intervals, 2,524 fields, and no dashboard events.
A step-input interval is not substituted for a swap interval.

## 68020 display-ownership check

The versioned `frames.py` locates copper publications through the complete set of
24 CPU DMA writes. `display_ownership.py` checks CPU and blitter destination writes
against the two live framebuffer allocations and actual bitplane fetches in each
field. A log without framebuffer blitter writes is reported as unobservable.
Synthetic tests cover that failure mode and the old-display selection for a swap
before copper pickup. The current 14 MHz steady trace has observable DMA and no
active-display conflicts; see `profiling.md` for the measured first-write margins.

## Optional publication/first-fill observer

VERIFY CUSTOM5 bit 3 enables the `RBPAINT1` diagnostic at flight step 1. It hooks
whole instructions at `sim:3154a` (publication and register restore) and
`sim:2fd8a` (solid-fill destination and BLTSIZE writes), after checking their bytes.
Static boundary, incoming-branch and relocation audits pass. Both original ranges
remain untouched when this diagnostic bit is off. Normal/developer builds exclude
its code and ring. It is not a performance feature.

Each 40-byte record contains the game step; publication VBlank and beam; first-fill
VBlank and beam; destination, old-display and new-display pointers; BLTSIZE; a zero
reserved word; and CIA ticks. The 256-entry ring publishes its count only after a
record is complete. A pending-publication flag and missed-publication count expose
swaps without a matching fill. Only the first solid fill into the former display
is recorded; other drawing paths still require DMA coverage checks.

The header's version, stride, capacity, count and buffer pointer occupy longwords
after its signature. Offset 28 holds WHDLoad's cache policy; offsets 32–52 hold
pending/missed counts and the latest publication state. Version 2 adds raw CACR at
offset 56 and a validity flag at 60. The cache-policy query uses SetCPU with a zero
mask, so no policy bits change, but that API **flushes caches once at flight entry**.
The actual CACR read runs through Exec Supervisor only on 68020+; 68000/010 skip it.
The generic WHDLoad policy must not be mistaken for supported hardware cache bits.

An initial diagnostic used MOVE from SR in user mode on the 68030 and raised a
privilege-violation Guru. The corrected installer selects MOVE from CCR on 68010+,
retains MOVE from SR on 68000, and restores with unprivileged MOVE to CCR. The
uninterrupted 68020 trace checks 145 fill calls and two swaps; the 68000 trace
checks 260 fills and three swaps. All required general registers and SP agree
with the original contract, and synchronized saved/restored CCR values match.

Raw debugger/trace SR values away from a synchronizing instruction can be stale:
the local CPU implementation stores flags separately and assembles SR in MakeSR.
Comparisons therefore use the state immediately after MOVE from/to CCR (or SR on
68000), not arbitrary instruction-record SR values. This is separate from the
earlier rule to classify interrupts by stack rather than supervisor-mode bits.

With blitter cycle accuracy explicitly enabled, the 50 MHz 68030 now exposes
blitter DMA. A 20-field diagnostic trace records 166,723 framebuffer writes,
including 5,672 writes into the displayed buffer during lines 42–243. None of
those addresses is fetched again later in that same field: the writes are behind
the raster. This violates the proposed strict buffer-ownership rule but does not
prove visible tearing. The observer reports first fills at matching beam lines;
its execution adds overhead, so this diagnostic is not an uninstrumented FPS run.

The final version-2 68030 diagnostic reaches step 20 with 18 completed first-fill
records and no missed publication. Its flight-entry sample reports WHDLoad policy
`0x3b3d`, but **raw CACR is `0x2000`**: the 68030 instruction- and data-cache enable
bits are clear. The saved emulator settings also have `cpu_data_cache=false`.
The policy flags are therefore not sufficient evidence of active hardware caches.
The discrepancy is now explained by WHDLoad's documented 68030 default: it
**disables MMU use unless `MMU` is explicitly requested**. With any memory region
noncacheable, WHDLoad must disable both caches globally when it cannot use the MMU.
The slave's KickEmu `CACHE` setup requests BaseMem noncacheable and ExpMem/Slave
copyback, which decodes exactly to the observed policy. The generic IC/DC flags
alone cannot override the region constraint.

A fresh boot of the identical VERIFY binary, changing only the WHDLoad arguments
to `CUSTOM5=8 MMU`, reaches flight and reports the same policy `0x3b3d` but CACR
**`0x2111`**: instruction cache, instruction burst, data cache and write allocation
are enabled. The emulator log confirms activation of the 68030 MMU. This controlled
check supports the explanation; it is not a rendering speedup measurement.

There is a second independent condition: FS-UAE's saved `cpu_data_cache=false`
bypasses its data-cache access functions even when CACR requests caching. Cached
68030 measurements must explicitly request and verify `cpu_data_cache=true`, in
addition to checking the guest register and WHDLoad MMU option. The local WHDLoad
20.0 documentation's “MMU Usage in WHDLoad” and “CPU Cache Handling” sections and
the emulator's `set_x_funcs` implementation establish these distinctions. Earlier
captures retain their original configuration and must not be relabelled as cached
measurements. Cache-enabled and cache-disabled runs are different machine baselines.

The explicit data-cache-model boot of the same binary also reports CACR `0x2111`
and reaches step 20: 18 completed first-fill records, one pending publication and
zero missed publications. Its eight potential active-display first fills require
DMA analysis before any claim of visible tearing.

## Reference-model and future twin contract

`projection_model.py` is now independent of the local trace-analysis environment.
It checks both loop normalization and independent bit-length normalization against
explicit original input/output records. All **486 complete retained original
`sim:38c82` calls** match on d0, d1, a0 and a1: 972 model comparisons, no mismatch.
The ignored scalar fixture is `projection-calls.json` beside the geometry analysis.
Three host tests also cover normalization boundaries plus 200,000 seeded 32-bit
samples, shift-count wrapping, signs, zero operands, division by zero, and rejection
of an incorrect captured output. This is sampled domain coverage, not the W2/G1
exhaustive 2³² normalization check or verification of a future replacement.

The original-copy ABI is `RBORIG01`, version 1, three entries. Each entry has the
sim offset, byte count and live copy pointer; pointer fields are at header bytes
24 (mirror), 36 (projection) and 48 (near-plane clip). Copies are taken after game
relocation, before performance patch installation, and followed by a cache flush.
They are executable references, not independent copies of the entire game context.

Each replacement's VERIFY twin must obey this contract:

1. Capture inputs at the original entry, including required globals, preserved
   registers, live flags and SP. Preserve entry X where an instruction consumes it.
2. Run the copied original and candidate with identical inputs. For a bitmap,
   duplicate the descriptor, plane bytes and mask and redirect their pointers.
   Include padding and canaries. For a geometry routine, isolate its output arrays
   and restore any global scratch state or callback side effects between paths.
3. Compare defined outputs and the declared preserved-register/flag/SP contract.
   Do not require flags to be preserved when the original changes them; identify
   which callers actually consume them. Record and abort on the first mismatch.
4. Restore the candidate's intended live result only after comparison. Ensure
   off-switch bytes still match the relocated original, and exclude every twin
   and diagnostic from normal/developer builds.

The mirror and projection host models, original copies and hook checkers provide
W0's reference infrastructure. Replacement-specific assembly wrappers, synthetic
inputs and live twins belong to the corresponding W1/W2 acceptance gates. No
replacement or completed live replacement twin is claimed by this groundwork.

## Dense-scene search: forward squadron view rejected

The current VERIFY build was reset into the four-versus-four squadron route, then
observed through flight step 200. A read-only breakpoint at `sim:39d30`, after
object culling and before the model draw dispatch, recorded 4,290 object visits
over steps 1–199. Every recorded descriptor has flags $10. These are the scenery
descriptors or the common converted terrain descriptor, not evidence of aircraft
geometry. The step-200 screenshot also shows no visible aircraft.

The retained `w0-dense-search-entry/scene-census.json` contains each step, object
identity, flags and model identifier, plus the raw debugger log and final ring.
The collector stopped at the requested flight anchor and includes a flight-exit
guard. Its object count is a post-cull dispatch count, not a count of visible
polygons or aircraft. The current forward-view window therefore does **not**
satisfy R-dense. A controlled view change or different mission setup is required
before collecting the dense trace and its strict repeat.
