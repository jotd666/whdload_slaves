# Red Baron performance measurements

The host overlay dependency guard now validates selecting pointers before
the resources they select. Its previous address-sorted order could read an
unavailable old resource before recognizing that its pointer had changed.
Regression tests and eight retained native overlay calls pass; this is a host
correctness fix, with no slave change or speed claim. See “Overlay dependency
validation order” in `w6-verification.md`.

The matching current-build 50 MHz cached-68030 capacity census records 163
completed world updates versus 163.426 newly funded over 1,000 PAL fields,
with **201 publications / 10.05 FPS**. Sampled backlog is 0.014–1.925 world
updates and the longest completion gap is 10 fields (0.20 seconds). Exact
funding and native audits pass. See “Current-build cached-68030 capacity window”
in `w6-verification.md`. These fresh-boot windows are not equal-state CPU
comparisons, and real smooth 50 FPS remains unachieved.

A fresh current-build 68EC020 capacity capture completes 163 world updates over
1,000 consecutive PAL fields, against 163.426 newly funded updates, while
publishing 66 frames (**3.3 FPS**). Sampled total backlog remains 0.258–3.134
updates; the longest sampled completion gap is 15 fields (0.30 seconds). The
first 250-field window includes message activity. See “Current-build 68020
capacity window” in `w6-verification.md` for configuration, exact accounting
and limits. This is a VERIFY capacity observation, not a release speedup,
complete capacity-matrix result or 50 FPS demonstration.

The remaining 1,000-byte residual is a native file-stream buffer. Its two
cross-boot differences already exist before W6 activates and remain unchanged
through all 41 controlled checkpoints; both stream handles and descriptors are
inactive at those samples. The companion buffer matches raw. See “Inactive
stream-buffer residual” in `w6-verification.md`. This does not prove absence
of accesses between samples or cover mission-transition file behavior.

The seven 384-byte heap residuals are now bound to native sound playback slots.
All 22 referenced resources (102,352 bytes) match in the controlled 50/25-MHz
comparison, and remaining slot data matches except for explicitly reported
playback counters: 91 unequal slot observations across 38 of 41 checkpoints,
including the initial state. See “Sound-slot residuals across CPU frequencies”
in `w6-verification.md`. Sound is unchanged; audio timing/delivery equivalence
is not established by this inventory.

The native planning table now matches across all 41 controlled 50/25-MHz
checkpoints, including its full 48-byte allocation, index cursor and both linked
148-byte records. Only verified pointers within the table are represented by
slot identity; all other contents remain raw. The linked record pool changes over
the window. See “Native planning table across CPU frequencies” in
`w6-verification.md`. This closes one identified heap residual, not the complete
world-state or performance gates.

The tracked-heap content inventory now covers all 41 controlled 50/25-MHz
checkpoints. Each has 105–107 payloads, with 82–84 exact-content matches and
23 unmatched payload instances per side. Matching content does not establish
object identity; duplicate groups remain explicit. See “Tracked-heap content
inventory” in `w6-verification.md` for the residual sizes and limits. No slave
code or performance result changes.

Two more complete native pools match in the controlled 50/25-MHz comparison:
two 134-byte type-five records and all eighty 44-byte auxiliary records at each
of 41 checkpoints. Both pools change throughout the window. Only the auxiliary
callback field uses an explicit relocation binding; inactive slots remain
checked. See “Complete type-five and auxiliary pools across CPU frequencies” in
`w6-verification.md`. This is additional state-correctness evidence, not a speed
or complete-gameplay result.

The CPU-frequency comparison now checks both full 318-byte aircraft slots and
their linked payloads at all 41 checkpoints. All 82 records match under the
explicit pointer bindings. Earlier 280-byte checks covered only prefixes; their
“full record” wording has been corrected. The added 38-byte tails are constant
in this window. See “Complete aircraft allocation and correction of player-prefix
scope” in `w6-verification.md`; no new performance or broad AI claim is made.

The controlled CPU-frequency comparison now also matches registry order, 1,463
registered object prefixes, 147 observed lifecycle notifications and the entire
2,200-byte projectile pool at all 41 checkpoints. The pool has 31 distinct
states during this window. Only explicitly verified fixed-storage addresses
are relocated; raw addresses remain reported. See “Registry and complete
projectile pool across CPU frequencies” in `w6-verification.md`. This adds
correctness evidence, with no new speed or combat-outcome claim.

The controlled 50/25-MHz captures now pass an explicit player-pointer comparison
at 41 checkpoints. The 280-byte player prefix and its two complete linked heap
payloads agree after validating the three native pointer fields; raw address
differences remain reported. The linked bytes also change identically during
the replay. This is scoped correctness evidence, not whole-gameplay or capacity
acceptance. See “Explicit player-pointer comparison across CPU frequencies” in
`w6-verification.md`.

A VERIFY-only fixed-clock setup fixture now removes the initial position and
velocity mismatch in the 50/25-MHz comparison. Both runs complete 39 world
updates over 241 fields, with 39 versus 32 draws. At all 40 boundaries, 275
player bytes match raw; five address-field bytes still differ and remain in the
report. Exact funding and scheduled-input consumption pass. These instrumented
windows establish no FPS/capacity claim. See “Fixed-clock native prelude for
CPU-frequency comparisons” in `w6-verification.md` for the remaining state gates.

A current-build 50/25-MHz 68030 replay comparison passes exact clock funding
and identical input consumption at 40 world boundaries. However, the native
setup prelude produces different player state before W6 activates, so the runs
cannot prove gameplay equivalence. They are short correctness captures, not
new FPS or capacity measurements. See “CPU-frequency replay: clock/input match,
initial-state gate fails” in `w6-verification.md` for the counts and required
fixture correction.

A further retained-state check accounts for the message rectangle's four differing
bytes after erasure: all 45 ordinary/delayed/no-render boundaries match native
border expansion and the erasure-copy model. The indirect text-layout pointer
also matches. No bytes are excluded from raw comparisons, and this adds no
performance result. See “Message rectangle after render-dependent erasure” in
`w6-verification.md`; complete simulation independence remains unproven.

Native overlay bitmap guards now pass 14 private boundary cases on both A500
and cached 68030. Eight live cache comparisons remain exact across all 320,000
framebuffer bytes; normal/developer builds are unchanged. These VERIFY runs
include added diagnostic work and establish no speed result. See “Native
overlay bitmap eligibility guards” in `w6-verification.md` for the current
build, replay contexts and remaining W6 gates.

The private overlay-cache twin now passes later-frame comparisons during W6's
scheduled-input replay. Cached/native output matches every framebuffer byte on
A500 and cached 68030 despite 888–1,205 changed background bytes at hits,
including 180–245 changed pixels beneath the overlay. The 68030 observations
include held Right and a changing roll rate; A500's samples occur after release.
This is correctness evidence with heavy VERIFY instrumentation, not throughput
or cross-CPU gameplay equivalence. No game drawing is skipped. See “Delayed
cache twins during W6 scheduled input” in `w6-verification.md`; complete cache
guards, view/resource transitions and live hardware replay remain open.

The host overlay model now checks exact dependency bytes and rejects nonzero
bitmap mask padding or unsupported native clipping. All 16 retained calls
across four captures pass; the first-call keys remain stable on subsequent
calls (1,608 bytes for program 3, 1,460 for program 4). All 301 host tests pass.
These are host correctness checks, with no new timing result or runtime cache
guard. See “Exact overlay pixel-model dependency guard” in `w6-verification.md`.

The W6 ground-impact render-scratch leak is fixed in the current VERIFY
candidate. Fresh rendered/no-render runs match all 280 player bytes at all 15
world boundaries, including the formerly divergent flag. The native renderer
still consumes its temporary value before restoration. All 512 private native
byte/CCR cases and 251 host tests pass; normal/developer binaries are unchanged.
This closes one correctness defect, not full frame-rate independence or the
50 FPS requirement. Raw global and sound-state differences remain visible.
See “Ground-impact render scratch restoration” in `w6-verification.md`.

A deliberately delayed-render control now also matches those same 15 world
boundaries. It completes 10 draws versus the ordinary run's 16, with actual
three-wrap waits verified at the 3D entry. Both preserve exact clock funding
and the same impact/flight exit. This is a short correctness comparison, not
a performance-rate claim; see “Ground contact under deliberately delayed
rendering” for the three-schedule counts and remaining raw differences.

One remaining global difference is now traced to a native sound-service timer:
three observed starts copy the CIA clock exactly, and all 15 snapshots retain
the last six-byte timer value. Sound behavior is unchanged and this field stays
in raw comparisons. See “Sound-service timer provenance” in `w6-verification.md`;
the broader sound/global-state acceptance remains open.

Six more differing global bytes are verified cockpit rectangle history. Native
reads, partial clips and writes match an independent 112-byte table model at
all 15 checkpoints. This history must persist for later drawing; it is not a
field to undo as simulation state. The raw comparison remains unchanged. See
“Cockpit rectangle-history ownership” in `w6-verification.md` for scope.

The vertex-cache investigation now accounts for all 3,060 coordinate bytes at
15 world checkpoints: 218 part resets, 1,482 exact modelled 32-bit misses and
1,567 hits that all follow a calculation in the same part. The final arrays
reproduce two more ordinary/delayed global-byte differences. Projected arrays
and complete consumers remain open; this is correctness evidence, not a speed
measurement. See “Vertex-cache epoch ownership” in `w6-verification.md`.

The next projection trace verifies all four native producer paths (2,568 calls)
and 6,096 sampled current-part reads. Both screen-coordinate arrays, 2,040 bytes,
match the model at all 15 checkpoints and reproduce another 22 final global-byte
differences. Fourteen other reader sites remain unobserved. See “Projected-coordinate
producers and sampled readers” in `w6-verification.md`; this is correctness
evidence only, with no performance or complete-gameplay claim.

The remaining endpoint byte is the original elapsed-time diagnostic; all 42
post-start checkpoints across the three ground schedules retain primary dt 225.
However, the full boundary inventory still has up to 264 residual h3 bytes in
ordinary/delayed and 637 in ordinary/no-render comparisons, outside the scoped
ranges above. Endpoint convergence does not close the all-tick state gate.
See “Legacy elapsed residue and the all-boundary residual inventory” in
`w6-verification.md` for counts and the next ownership checks.

Message-ledger checks now pass at all 15 boundaries across those three schedules:
shortening and expiry occur at the same relative active-clock times, and native
priority inputs match. No-render retains an expired message pending erasure;
ordinary/delayed drawing clears it at different publication times, without
changing the tested priority decision. See “Ground-run message logic versus
pending erasure” in `w6-verification.md`. Other residual ownership checks remain.

The same three ground schedules also match all 19 complete terrain records
(646 bytes), list order/pointer/count and 16 cache-control bytes at every retained
boundary. The adjacent builder-position copy varies with drawing and is reported
separately. See “Complete terrain-list boundary check and builder-position
ownership” in `w6-verification.md`, including the corrected loader/sorter context.

The current full W6 VERIFY bundle also passes the cached-68030 Preferences
clock-boundary check: 222 CIA ticks spent in the native panel are excluded,
one CIA tick of existing simulation debt is preserved, and no world update or
player-record change occurs inside the panel. This is correctness evidence,
not a rendering-speed measurement. See `w6-verification.md`, “Current full-bundle
Preferences clock boundaries,” for raw checkpoints and the remaining modal gates.

The recorded Pause test on A500 excludes 173 CIA ticks while preserving a
48-tick catch-up backlog and the 280-byte player prefix. The same-build 68030 test
excludes 218 ticks and preserves three ticks of debt. Both sets of 80 input
observations pass; this is modal correctness evidence, not proof of sustained simulation
capacity. See “Recorded native Pause input and clock exclusion” in
`w6-verification.md` for the fixture startup correction and exact build.

## W6 A500 per-field capacity, 1,000 PAL fields

The current VERIFY build completes nominal simulation work over a finite
20-second steady-flight window even at **0.35 rendered FPS**. Four consecutive
250-field windows complete **41/41/42/44** world updates against **163.288**
newly funded updates in total. The 168 completions also repay existing backlog:
unprocessed CIA debt falls **50 → 19**, and total outstanding work (including
fractional credit and an update in progress) falls **7.942 → 3.230** world ticks.
However, the longest sampled span without a world completion is **48 fields
(0.96 PAL seconds)**. Average throughput does not establish responsive gameplay.

A same-build no-render control completes **41/40/41/41 = 163** updates against
the same funding. Its outstanding work changes **0.895 → 1.183** ticks, with
one update in progress at the end, and its longest sampled completion stall is
**seven fields**. These runs start at different world states; they are capacity
observations, not an equal-tick gameplay comparison. Both use maximum detail,
Time Scale 40, the full W6 VERIFY mask, and an A500 configuration.

Every field is retained, including clock transactions. Exact funding passes
between committed samples; native self-tests and hook audits pass. See
`w6-verification.md`, “A500 consecutive per-field capacity census,” for build,
transaction exclusions, sampled backlog ranges and reproduction. Event/bank/dense
capacity, full gameplay equivalence and smooth 50 FPS remain open.

## W6 A500 scheduled banking/fire capacity, 2,000 PAL fields

A fresh same-build A500 run begins sampling at the first world update and
includes the timestamped Right-down/up and Fire-down/up replay. **322 native
input observations** verify all four events and exactly two commands, including
the native X axis and Fire flag. Eight consecutive 250-field windows complete
**34/41/40/42/41/41/41/41** world updates and publish **1/2/3/2/2/2/2/2** frames.

Across 40 PAL seconds, **321** updates complete against **326.577** funded, with
one update in progress at the end and **0.40 FPS**. Total backlog changes
**0.138 → 6.426 → 5.715** updates at the start, midpoint and end: the second
20 seconds complete 164 updates against 163.288 funded, slightly reducing the
initial deficit. The longest sampled span without a world completion is
**55 fields (1.10 seconds)**; in the second half it is still **46 fields**.
This is finite throughput evidence with a brief control maneuver, not sustained
banking, combat equivalence or responsive-gameplay acceptance.

The legacy CUSTOM5 bit-1 banking fixture is bypassed when W6 owns the input
bitmap. Selecting that bit alone is **not** evidence of banking under W6.
Use the recorded timestamped replay and verify its native input effects. See
`w6-verification.md`, “A500 capacity with scheduled Right/Fire input.”

## W6 shape-selection isolation checkpoint

The current VERIFY candidate restores the selected shape record and scale pair
after drawing. A native A500 call changes selection from record 6 (255/90) to
record 1 (256/256), then restores record 6 exactly. Both measured calls preserve
the resource table, simulation poses, clocks and shared-list ownership. Three
private native save/restore tests also pass. This closes a named rendering-state
leak in the tested path; it is not a speedup or permission to run simulation
inside an unfinished draw. See `w6-verification.md`, “Shape-selection ownership
across rendering,” for build identities, coverage and rejected debugger fixtures.
The previous timing measurements belong to their recorded builds; this change
has not been benchmarked.

## W6 full-bundle replay regression

After shape restoration, the full VERIFY bundle passes a same-build cached-68030
ordinary/no-render replay comparison at 40 equal world ticks. Complete player
records, 1,352 registered prefixes, camera, registry/display-list state and
lifecycle events match. All eight shape-selection bytes now match at every tick.
Shared game allocations differ only at payload byte 345 in the identified sound
contexts; one drawing-only allocation appears from tick 33.

The ordinary run completes 41 draws over 39 world updates; the control completes
none. Exact time funding passes in both, including the ordinary run's three CIA
ticks of final debt. These are correctness captures, not performance samples.
The final raw inventory still contains 1,229 differing h3 bytes and other segment
differences, so full gameplay equivalence remains open. See `w6-verification.md`,
“Full-bundle equal-tick replay after shape restoration,” for all retained evidence.

## W6 sound-state difference classification

The remaining sound-context word is an interrupt-driven playback elapsed/position
counter. A new independent instruction-to-bus check validates **1,045 writes**
after observed resets in the retained A500 capture; **42 leading writes** remain
explicitly unverified. The three chunks are checked independently across their
missing boundary fields. W6 leaves this counter on the native sound clock.
This classifies the observed byte difference without normalizing it away or
claiming sound-event equivalence. See `w6-verification.md`, “Sound-context
elapsed-word classification.” No slave or sound behavior changed.

## W6 current-bundle rendering breakdown

A follow-up on the same synthetic cached-68030 200 MHz configuration separates
the native frame from W6 interpolation. At native flight checkpoints 84–93,
15 accepted full render calls average **78.559 ms**, and 15 native-draw calls
average **77.796 ms**, including publication waiting and W6 hooks inside the
native path. Pose blending averages **0.104 ms**. The exterior W6 wrapper is
therefore not the large rendering cost in this window; these are per-routine
means, not an independently isolated subtraction measurement.

Subsequent native stages at checkpoints 104–113 show:

| Stage | Boundaries | Accepted calls | Mean wall time |
|---|---|---:|---:|
| Scene construction and 3D drawing | sim:006bc → sim:007c4 | 13 | 42.786 ms |
| Cockpit drawing | sim:007c4 → sim:00830 | 13 | 30.520 ms |
| Publication/end-of-frame | sim:00afe → sim:00b10 | 15 | 4.124 ms |

The background and message stages do negligible work in this later window.
The publication stage includes native end-of-frame calls and beam waiting; it
is not a measurement of pure idle time. A further cockpit breakdown at
checkpoints 114–123 measures `sim:19ba6..19e12` at **8.651 ms** (15 calls),
`sim:15e96..163a0` at **14.455 ms** (15), and the overlay at
`sim:2c144` at **7.250 ms** (14). These native calls are concrete next targets
for a redraw/data-ownership audit. This recurring cockpit work must not be
confused with W1's event-triggered mirrored dashboard bitmap.

At checkpoints 94–103, 146 accepted polygon calls average 1.100 ms and 162
rectangle calls average 1.214 ms; 14 complete 3D passes average 33.395 ms.
Different call counts and phase exclusions prevent summing those means into a
frame breakdown or claiming percentages. Adjacent windows contain different
states. No speedup or real-accelerator claim follows from this diagnostic.
The 50 FPS gate remains open: lowering interpolation cost alone will not remove
the measured native drawing budget. Full capture details and exclusions are in
`w6-verification.md`, “Current-bundle rendering cost localization.”

## W6 high-frequency rendering diagnostic

A current VERIFY full-bundle diagnostic with cached emulated 68030 at **200 MHz**,
2 MB chip / 8 MB fast, cycle-exact CPU/memory/blitter, maximum detail and Time
Scale 40 still publishes **12.0 and 11.6 FPS** in two adjacent exact 250-field
windows. Every publication interval is 4–5 fields and every beam position is
safe. Each window completes 41 world updates against 40.8221 newly nominal;
exact funding passes, with unprocessed CIA debt 1 → 2 → 2 and no update in
progress at any endpoint. Message start/shorten counts are 11/11 and 6/2.
These are eventful windows, not a steady-flight A/B benchmark.

In the following ten native flight checkpoints, fourteen phase-valid 3D passes
at `sim:2c552..2c806` average **1.66687 fields (33.391 ms)**, range
1.63712–1.70720 fields. Nine world updates at `sim:1098..11c8` average
0.10086 fields (2.020 ms). Sixteen overlay calls average 0.37211 fields
(7.454 ms). These are inclusive beam-clock wall times with interrupts; nested
costs must not be summed. There are 293 conservatively excluded call samples
across all measured routines because their counter/beam phase is ambiguous.

The 3D pass alone exceeds one field, so this measured configuration cannot meet
50 FPS in this scene. A higher configured CPU frequency has not demonstrated
that acceptance gate. This is a **synthetic emulator diagnostic**, not a claim
about a real 200 MHz 68030 accelerator, a speedup over the earlier 50 MHz run,
or proof of which bus/routine accounts for the remaining limit. The next
presentation investigation needs a current-bundle rendering-cost breakdown;
relaxing the cap or changing simulation speed cannot fix this measured budget.

Frozen slave: `83f586cb2b477476dd915d2779561abf834cd6ce3abe95fa3f347cafdf20083a`.
See `w6-verification.md`, “High-frequency real-drawing capacity diagnostic,” for
configuration, artifacts and validation. No player build changed.

## W6 timing analysis

The investigation is complete in `game-time.md`; the proposed fixed-step design
is in `game-time-plan.md` and is authorized for implementation, with smooth
50 FPS added as a requirement. No player timing change or new
FPS gain is claimed. Retained W5-only A500 world calls average 420,212 inclusive
cycles (59.24 ms). With proposed 225-unit ticks, the default Time Scale projects
48.3% world utilization and about 0.98 rendered FPS if other frame costs remain
unchanged; the highest setting projects 159% world utilization before drawing.
These are capacity estimates, not measurements of an implemented scheduler.

The first VERIFY-only W6 loop checkpoint now executes fixed-step world updates
and skips drawing while catching up. On cached 68030, scheduled ticks 240–320
span 580 observed CIA intervals, matching 580 scheduled intervals with no debt
at those boundaries. This is a scheduling check, **not an FPS, capacity or
consistent-gameplay result**. The subsequent modal-boundary candidate excludes
7,614 CIA intervals spent in the A500 setup Preferences route; its first recorded
flight boundary has one interval of debt instead of thousands. This is transition
verification, not an FPS result. Input, secondary services and presentation remain
incomplete. The subsequent keyboard candidate passes native bank/fire and
exactly-once command checks on A500 and cached 68030, including up to 93 observed
CIA intervals of A500 debt. This is input-history evidence, not a gameplay-speed
or FPS claim. The device candidate also passes 48 native input observations
on each machine for joystick direction/fire and both mouse buttons, with up to
93/10 CIA intervals of A500/68030 debt. The subsequent relative-mouse candidate
passes twelve acquisitions and 48 native input/control observations per machine,
including recentering and CPU-written flag checks, with 98/10 CIA intervals of
A500/68030 debt. Analog mode and mixed modal/restart input remain unverified.
These are input correctness checks, not FPS or sustained gameplay-speed results.
The rate-history candidate subsequently passes eighty native world boundaries
per CPU across three divisor changes, including 97 CIA intervals of A500 debt.
World credit, tick counts and secondary credit match the independent rational
model exactly; secondary service execution was not implemented at that checkpoint. This is timing
accounting evidence, not an FPS or complete-gameplay result.
The message-service checkpoint passes exact active-time expiry on A500 and
cached 68030, with 200/100 observed world boundaries. A500 retains expired text
through 31 observed hidden-update boundaries; native erasure or replacement
cleans it on actual paints. Both captures finish with timer and buffer dirtiness
zero. This validates service timing and cleanup, not three-second visible
removal, FPS or sustained simulation capacity.
The camera-input ownership checkpoint then passes twelve mouse acquisitions,
48 world-input and 47 camera-input observations on each CPU, plus 192 native
mixed-owner reset cases. Camera resets no longer alter the world mouse position.
The subsequent continuous-camera service candidate passes 160 exact funded
service boundaries on each CPU, including 157 A500 / 158 cached-68030 free-camera
updates. Eight services on each machine move the camera; five/four execute with
world commands still queued without consuming them. Native orientation changes
match the independent 128-unit arithmetic model, and the service restores the
secondary clock and leaves flight mouse input unchanged. These are scoped camera
correctness checks, not overall FPS, gameplay convergence or capacity results.
The compression timing candidate then passes 160 CIA funding boundaries on each
CPU: 132 normal and 28 at the 8× request, two transitions, 49 world ticks and
64 independent service ticks. Fifty clock-pair checks per CPU preserve dt
across the legacy compression overwrite site. This is a synthetic flag fixture;
native command/cancellation, gameplay state and capacity remain unverified.
An initial presentation audit then records three complete native draws, with
50/58/58 listed objects. The 3D pass changes 353/359/348 h3 bytes, including an
object projection cache; the player and listed pose prefixes remain unchanged.
These are mutation-inventory counts, not frame costs or proof of render purity.
The interpolation arithmetic checkpoint passes 638 native position/angle cases
and 133 exact-phase-to-Q16 cases on A500. It adds no render-only frames and has
no FPS or gameplay-speed measurement yet.
The projection-cache ownership checkpoint restores the named object fields after
three native draws on each of A500 and cached 68030. All six changed cache
records match the independent byte model and are restored at outer return.
This is scoped rendering-state isolation, not a complete mutation audit,
interpolated-frame implementation or gameplay-speed result.
The shared-model journal candidate additionally passes three draws per CPU on A500 and cached 68030:
each records two writes to a shared model byte and restores its outer-entry
value. The native overlapping-write self-test passes. Colour-changing branches
remain unexercised in that window; this adds no FPS or gameplay-speed result.
The native pose-snapshot checkpoint passes sixteen consecutive completed-world
boundaries on each of A500 and cached 68030: 504 poses match live state per
CPU, with fifty lifecycle events and 24 correctly invalidated previous records. These are snapshot checks;
they do not yet add interpolated frames or establish gameplay-speed convergence.
The candidate interpolation buffer then passes 504 pose outputs per CPU on
A500 and cached 68030 against the rational model: 478 interpolate and 26 snap; 414 differ from current pose.
This table is not yet used by drawing and supplies no FPS or speed result.
The first cockpit render-phase integration then passes four native 68030 draws:
132 object poses are checked during and after drawing, with 108 changed visual
poses and no world update inside a draw. These runs explicitly enable W5's safe
two-field cap. The subsequent W6 one-field policy is verified below; full
capacity and smooth-50-FPS acceptance remain open.
See `w6-verification.md` for frozen builds and limitations.

## W6 automatic-menu timing checkpoint

The current automatic-menu VERIFY candidate is SHA256
`c59f4909f124e96a747974c3272750fce06883a1f691ce7d6d372fcb27f39cb2`.
Its cached-68030 timing-plus-W5 capture (`CUSTOM2=8192`, effective 8960) completes
40 world ticks against 40.8221 newly nominal over exactly 250 PAL fields, while
publishing 57 frames (11.4 FPS). CIA debt changes 1 → 4 ticks and exact funding
passes. There are no message start/shorten calls in this window. This follows
120 ordinary automatic-service observations and three verified cockpit draws;
it is not a full-bundle steady-flight benchmark or a comparison against earlier
builds. Services now run only at completed-world boundaries. See
`w6-verification.md` for the controlled A500/68030 menu-expiry evidence and limits.
Consistent gameplay still requires full state/event convergence across rendering
schedules and sustained nominal execution; retained time debt alone is insufficient.

## W6 equal-tick state comparison

The shared-list-owner VERIFY build `f92e9eed…` completes the same 39 simulation
updates with 44 draws in 240 fields and with no draws in 239 fields. Exact funding
passes; endpoint CIA debt is one and zero ticks respectively. These equal-tick
windows are diagnostic, not a 250-field FPS comparison. Both the leaked terrain
data and its native cache controls are now restored. Four directly observed draws
rebuild terrain and change the shared display list, then restore its active order,
count and terrain controls; 133 simulation poses and their clock state survive
those draws unchanged. Rebuilding
every draw has a cost that future capacity and 50 FPS measurements must include.
280-byte player prefixes, 1,279 registered prefixes, lifecycle order and the active
display list match at all 40 checkpoints. The previous build had list-order
differences at 33 checkpoints; world registration/removal uses that same list. Shared allocations differ only in identified sound-sequencer
fields; global-state classification and broader gameplay/capacity acceptance remain
open. See `w6-verification.md` for the evidence and the inter-frame cache issue
that equal-tick snapshots alone did not cover.

The earlier `b6bc9c01…` build's delayed-drawing correctness fixture completes those 39 updates
with 29 draws in 249 fields, ending with eleven CIA ticks of debt. Exact funding
and the same scoped state/lifecycle comparisons pass. Nine same-field update pairs
show catch-up with no intervening draw, reducing debt from 7–9 ticks to 0–2.
This extends render-schedule coverage; it is neither a performance workload nor
proof that the final debt is sustainable. The requested 250-field capacity
measurements and complete gameplay/global-state acceptance remain open.

The subsequent unchanged `9f72992c…` bank/fire correctness pair passes identical
acquisition-deadline replay and all 40 equal-tick input snapshots. Complete player
records, 1,332 registered prefixes, primary/shared-list order and lifecycle events
match with 43 draws versus none. The 39 updates span 243 fields / 287 CIA ticks
with drawing (four ticks of final debt), and 239 fields / 283 CIA ticks without
(zero debt). These are controlled fixtures, not a full-bundle FPS measurement.
Shared allocation differences remain in the identified sound word and the
rendering-only message background; 924 global bytes remain explicit in the final
raw inventory. Combat outcomes and broader gameplay acceptance are still open.

The flight-relative synthetic replay build `4f682c6d…` then completes identical
bank/fire consumption under ordinary, delayed and no rendering. All three
40-boundary histories match 280-byte player prefixes, 1,352 registered prefixes,
registry/list ordering and lifecycle events. Their 39 updates take respectively
244/245/239 PAL fields, with 39/27/0 draws and final CIA debt 5/6/0. Eleven delayed
same-field catch-up pairs preserve the input/state comparison. These controlled
fixtures are not 250-field performance samples or full gameplay acceptance.
The previous physical-acquisition fixture's delayed variant was rejected because
its Right hold ended before flight activation; it is not an identical-input
comparison. See `w6-verification.md` for the distinction, fixture isolation,
remaining global differences and reproducible evidence.

## W6 attached-camera presentation checkpoint

VERIFY build `eb743015…` extends render-only interpolation to the native attached
camera pose-copy family. A cached-68030 rear-view capture passes 24 world
boundaries (649 poses), including history reset on the view change at tick 5.
Four view-1 draws check 125 object poses, of which 102 change visually; all four
private camera poses change and are restored exactly after drawing. No world
update occurs inside a draw. These are correctness counts, not frame costs or
FPS measurements. Other camera modes, full gameplay convergence, sustained
simulation capacity and smooth 50 FPS remain open. See `w6-verification.md` for
the frozen build, fixture and limits.

Its subsequent ordinary/no-render rear-view pair matches all 24 equal-tick input
histories, full player and camera poses, 649 registered prefixes and registry/list
ordering. The runs complete 23 world updates with 20/0 draws over 143/141 actual
PAL fields; final CIA debt is 2/0 and exact funding passes. Raw global and sound
state differences remain visible. This shorter boundary-controlled check is
correctness evidence, not a 250-field performance sample or full gameplay result.

## W6 bank physics reference

The separate VERIFY fixture `83f586cb…` compares 225- and 100-unit native steps
under constant Right input at equal primary-time budget 9,900. The 225 run
travels 1.7192% less distance, with 657.494 raw-unit endpoint separation. Initial
world/heap state matches except the intentional dt; exact airborne integration
passes. This is an unresolved step-size fidelity result, not an FPS measurement
or a failure of equal-tick rendering independence. The W6 physics acceptance
gate remains open; see `w6-verification.md` for scope and reproduction.

## W6 current full-bundle capacity checkpoint

Frozen VERIFY build `eb743015c665a5893fba0cb12158c9cceb33704f06e6631ccf61235fd0f30896`
was measured with CUSTOM2=16319, maximum detail, original Time Scale 40 (F=33),
deferred installation and the scheduled bank/fire replay fixture. There is no
slow-draw or no-render fixture. Both recordings start after the first completed
draw at completed-world tick 1. These are short observed workloads, not matched
cross-CPU state comparisons or coverage of all steady/event/bank/dense scenes.

| Machine / window | Actual fields / CIA ticks | Completed world updates | Newly nominal updates | Published frames | CIA debt before → after |
| --- | --- | ---: | ---: | ---: | --- |
| A500-equivalent, first | 252 / 299 | 47 | 41.2358 | 1 | 62 → 25 |
| A500-equivalent, next | 253 / 299 | 42 | 41.2358 | 2 | 25 → 13 |
| Cached 50 MHz 68030, first | 250 / 296 | 41 | 40.8221 | 43 | 0 → 2 |
| Cached 50 MHz 68030, next | 250 / 296 | 41 | 40.8221 | 53 | 2 → 3 |

The A500-equivalent configuration uses 512 KiB chip and 1.5 MiB slow RAM with
cycle-exact 68000 timing. Each window retains 250 traced fields; measured elapsed
fields include profile alignment. Boundaries are consecutive and coherent, with
no transaction settlement needed. The final boundary has one update in progress.
All three actual publications match complete chip-write sequences, starting at
PAL lines 245, 245 and 259. This gives 0.1984 and 0.3953 published FPS over actual
elapsed fields. The 89 completed updates across both windows pay down some
existing debt; they are not evidence that the world runs faster than nominal.
The main-task trace records zero message-start/shortening calls and 14/28 bitmap
mirror entries. Chunk gaps mean traced entry counts are not complete elapsed-time
work counts. Forty-five complete original world calls average 401,231 main-task
cycles (range 327,984–474,190), or 476,775 inclusive cycles. The one fully traced
outer drawing call costs 5,067,702 main-task / 5,989,438 inclusive cycles. Nested
routine costs are not additive. These are observed call costs, not a whole-window
cycle budget or a before/after speedup claim.

The cached-68030 configuration uses 2 MiB chip / 8 MiB fast RAM. A read-only native
field census avoids cached-CPU instruction-trace timing claims. Each window is
exactly 250 fields; clock transaction markers are zero at all four boundaries.
Actual publication rates are 8.6 and 10.6 FPS, with intervals of 5–6 and 4–6 fields.
All publications satisfy the safe blanking-line check. Message-start/shortening
counts are 11/11 then 1/1, so this is not labelled an event-free steady window.
Every consecutive interval on both machines conserves funded time exactly.

These measurements show backlog recovery on the observed A500 workload and near
nominal real-time update throughput in the two 68030 windows. They do not close
sustained capacity, the wider scene/CPU matrix, gameplay equivalence, input-latency
acceptance or smooth 50 FPS. The slower rendering is a visible cost of doing the
additional simulation work; it must not be hidden behind the world-update count.
Both native endpoints pass core/input/presentation/phase self-tests
426/512/638/133, terrain stores/cache/list 2/1/2, and all 54 selected timing/pacing
targets. Both owned emulators were quit. No slave code changed for this checkpoint.

Retained evidence is in `tmp/dev/tmp/prof/w6-current-capacity-a500/` and
`tmp/dev/tmp/prof/w6-current-capacity-030/`: capacity manifests/checks, frame DMA
checks, routine costs and event census for A500; exact-field manifest/check and
publication logs for 68030. Reproduce the accounting with `time_capacity.py` on
each A500 manifest and `field_capacity.py` on the 68030 field census.

## W6 coherent clock-boundary capacity checkpoint

VERIFY build `9f72992c…` adds transaction markers for debugger observations of
cursor/credit updates and the due-to-started handoff. It passes two consecutive
250-recorded-field A500 windows, CUSTOM2=16319, maximum detail, default Time Scale
(F=33), without a draw-delay fixture. Actual elapsed fields include chunk alignment:

| Window | Elapsed fields / CIA ticks | Completed world updates | Completed draws | CIA debt before → after |
| --- | --- | --- | --- | --- |
| First | 252 / 299 | 49 | 0 | 70 → 12 |
| Next | 253 / 300 | 39 | 2 | 12 → 28 |

Every chunk conserves exact funded time. The windows are continuous, with 88
completed updates against 82.6096 newly funded nominal updates; the surplus pays
down pre-existing debt. The final boundary has one update in progress. Two
completed draws over 505 elapsed fields do not establish a usable steady frame
rate, sustained capacity, or consistent-gameplay acceptance. The zero-draw first
window is catch-up, not a speed gain. Evidence is
`tmp/dev/tmp/prof/w6-transaction-capacity-a500/`.

The preceding `f92e9eed…` raw capture stopped during a credit transaction. Its
second chunk appeared short by exactly one CIA credit and the third gained that
credit back; the overall window balanced. Those raw snapshots remain unchanged.
The collector now refreshes debugger registers, recognizes pending transactions,
and can continue to the corresponding commit boundary while retaining both raw
and settled snapshots. Both transaction types pass forced native breakpoint
checks; neither occurred naturally at the endpoints of these two new windows.
The checker rejects explicitly pending snapshots. See `w6-verification.md` for
validation and remaining limits.

## W6 combined A500 capacity checkpoint

The VERIFY build `1a0677e18c874809ae0270549b4efbeaae6d778d4d3e210a6f936fafbca7e1b8`
uses CUSTOM2=16319: all currently verified W1–W5 bits plus W6, at maximum detail
and default Time Scale (F=33). The A500-equivalent configuration retains 512 KB
chip RAM, 1.5 MB slow RAM and cycle-exact 68000 timing. No fast-draw fixture is
active. Evidence is `tmp/dev/tmp/prof/w6-capacity-a500-full/`.

Two adjacent windows each retain 250 PAL fields in 100/100/50 chunks. Boundary
counters include profiler alignment fields; the measured intervals are 252 and
253 fields respectively. They are not treated as an uninterrupted 500-field trace.

| Window | Elapsed PAL fields / CIA ticks | Completed / newly nominal world ticks | Unprocessed CIA ticks, start → end | Completed draws |
| --- | --- | --- | --- | --- |
| Initial post-draw catch-up | 252 / 299 | 45 / 41.2358 | 67 → 38 | 0 |
| Immediately adjacent | 253 / 300 | 40 / 41.3737 | 38 → 49 | 2 |

The first trace contains no `sim:3154a` publication; the adjacent trace contains
two, both with complete matching copper DMA writes. Completed-draw counters and
actual publication census therefore agree. The initial recorded window has
fifteen message-start calls at `sim:03c06` and ten shorten calls at `sim:03c7c`;
these count call attempts, not necessarily distinct displayed messages. The
retained final image shows “You've been hit!”. Treat these as combat/message-activity
windows, not an R-steady acceptance sample. Both windows conserve exact
funded time, including fractional phase, queued due updates and the bounded
world update in progress at each chunk boundary. Across 505 elapsed fields,
85 updates complete versus 82.6096 newly nominal updates; initial backlog falls
by 18 CIA ticks. This supports short-window catch-up, not sustained nominal-speed
acceptance or full gameplay-state independence. Rendering is sparse in this
candidate; the adjacent window's completed-draw rate is 0.3953 per PAL second.
The full scene/CPU/Time Scale matrix and longer bounded-debt check remain open.

The initial window's complete-call analysis separates the observed interrupt
stack and excludes calls cut by chunk boundaries:

| Routine | Complete calls | Mean main cycles | Mean inclusive cycles |
| --- | ---: | ---: | ---: |
| Native world body, `sim:01098` | 42 | 405,096.9 | 504,957.0 |
| Completed-world pose snapshot | 43 | 25,603.8 | 31,347.5 |
| Render-time pose interpolation | 1 | 199,798.0 | 234,530.0 |
| Scheduler poll, including its services | 87 | 26,669.5 | 32,651.7 |
| Exact one-CIA-tick kernel | 322 | 748.8 | 809.0 |

These costs overlap where calls nest and must not be added as disjoint shares.
The native world body excludes other per-world-iteration work. The render and
3D calls present at the final boundary are incomplete, so this sample supplies
no complete render-call mean or steady frame-rate claim. W6's cost/capacity and
smooth-50-FPS requirements remain open.

## W6 exact-field 68020/68030 capacity checkpoints

The same frozen `1a0677e1…` VERIFY build is measured with the native field
counter and `sim:3154a` publication census, avoiding cached-CPU instruction-cycle
estimates. Each window runs from one `pace_vbl` entry to the entry exactly 250
fields later. Full RAM snapshots retain both endpoints. `field_capacity.py`
checks exact clock funding, the completed/started-world distinction, adjacent
window continuity, safe beam positions and publication/completed-draw agreement.
These are native-counter windows, not Barto trace chunks, so no profile-join
fields are omitted or inferred.

Cached 68030/50 uses CUSTOM2=12218: W6 plus the current CPU-adapted verified
performance selection (table mirror, G1 and S3 remain disabled on this CPU).
Evidence is `tmp/dev/tmp/prof/w6-capacity-030-full/`.

| Window | CIA ticks | Completed / newly nominal world ticks | CIA debt, start → end | Publications / FPS | Message start / shorten calls |
| --- | ---: | --- | --- | --- | --- |
| First 250 fields | 296 | 40 / 40.8221 | 0 → 3 | 56 / 11.2 | 15 / 10 |
| Adjacent 250 fields | 296 | 42 / 40.8221 | 3 → 0 | 62 / 12.4 | 0 / 0 |

Across ten PAL seconds, 82 world iterations complete against 81.6442 newly due;
boundary debt returns to zero. All intervals conserve exact funded time. Actual
publications and completed outer draws agree. The first window has message
activity; absence of new message calls in the second does not by itself certify
all R-steady conditions. The sample supports short-window nominal simulation
progress while rendering at 11.2–12.4 FPS, not full-state gameplay consistency,
sustained capacity across the acceptance matrix, or smooth 50 FPS.

The A1200-class 68EC020 configuration uses 2 MB chip RAM, 8 MB fast RAM and
CUSTOM2=16319. Its capture `tmp/dev/tmp/prof/w6-capacity-020-full/` uses the same
binary and exact-field procedure:

| Window | CIA ticks | Completed / newly nominal world ticks | CIA debt, start → end | Publications / FPS | Message start / shorten calls |
| --- | ---: | --- | --- | --- | --- |
| First 250 fields | 296 | 40 / 40.8221 | 0 → 6 | 23 / 4.6 | 15 / 10 |
| Adjacent 250 fields | 296 | 42 / 40.8221 | 6 → 3 | 25 / 5.0 | 0 / 0 |

One world iteration is in progress at both first-window boundaries; none is in
progress at the final boundary. Completed versus started counts account for it
explicitly. Exact funding, native-body completion counts, publication/completed-
draw agreement and safe beam checks pass. The two CPU captures start at different
completed ticks: 44 on 68020 and 42 on 68030. Their equal totals of 82 completed
updates across 500 fields are a clock/capacity observation, **not** an equal-tick
world-state comparison or proof of identical gameplay. Neither configuration
reaches the 50 FPS presentation requirement in these samples.

## W5 current measurements

The frozen VERIFY candidate is SHA256
`3e3ddb5ccacfbb072658847716dc8d3b9eba3c941ec2e5587af0086437e2eae3`.
Developer/VERIFY CUSTOM2=256 selects the original beam wait; 512 selects the
two-field flight cap; 768 selects both. See `w5-verification.md` for contracts
and the independently observed cap/wrap stress test. The stress fixture is not
a game-performance workload.

The same-build A500 OFF baseline (`tmp/dev/tmp/prof/w5-a500-0-r2/`) spans swaps
140–240: **2,905 fields, 3,441 CIA ticks, 1.7184 FPS**. Its event census has one
message call and no mirror call, with dt=450 throughout. Separate 250-recorded-
field samples (100/100/50, two unrecorded joins) contain eight complete swap
calls at `sim:314be`: **2,073 mean main cycles** (1,746–2,676), excluding IRQs
and including RTS. Its thirteen sim and three sound disabled ranges match the
original bytes. The first 100-field DMA sample has 129,365 framebuffer writes
and zero active-display conflicts. This is an OFF baseline, not a W5 gain or cost.

P1 alone (`tmp/dev/tmp/prof/w5-a500-256/`) takes **2,921 fields**, or
**1.7090 FPS: a 0.55% frame-rate cost** against that OFF baseline. The 100
intervals add 16 fields in total (0.16 field/frame). Both censuses contain the
same single message call and no mirror event, with dt=450. Complete h3 snapshots
at first flight, step 140 and step 241 are byte-identical. Eight complete swap
calls average **18,897 main cycles** (1,818–65,786); the extra 16,824-cycle mean
is from the separate short trace, not inferred from the long FPS window.
Its twelve disabled sim ranges and three sound ranges pass, and its first
100-field DMA sample observes 128,350 framebuffer writes with zero conflicts.
P1 remains selected on A500; the measured cost does not justify removing its
publication safety there.

With both P1/P2 (`tmp/dev/tmp/prof/w5-a500-768/`), the same A500 window takes
**2,926 fields, 1.7061 FPS: a 0.72% total cost**. The event census and dt match;
entry and step-140 h3 snapshots are byte-identical, and step 241 differs only
in the elapsed-time word at `h3:0483a`. The short trace's eight swap calls average
33,841.25 main cycles (1,398–77,570); wait-phase sensitivity makes this a different
sample, not a direct estimate of the counter's overhead. Selected/disabled byte
audits pass, with zero conflicts among 128,350 observed framebuffer writes.

The 68020 OFF baseline (`tmp/dev/tmp/prof/w5-020-0/`) spans swaps 80–400:
**2,596 fields, 3,075 ticks, 6.1535 FPS**, with no dashboard events. Twenty
complete swap calls in its separate 250-field sample average **2,553.5 main
cycles** (573–5,271). All disabled byte ranges pass, with zero conflicts among
394,259 framebuffer writes in its first 100-field DMA sample.

With P1/P2 on 68020 (`tmp/dev/tmp/prof/w5-020-768/`), swaps 80–400 take
**2,661 fields, 3,151 ticks, 6.0032 FPS: a 2.44% rate cost**. Both windows
have no dashboard events. Variable dt permits world-state divergence; this
is the observed same-step window, not an identical world trajectory. The
separate short sample has 21 complete swap calls averaging **54,990.71 main
cycles** (608–180,418). Byte audits pass and the first 100-field DMA sample
has zero conflicts among 386,093 framebuffer writes. End screenshots remain
in flight with intact cockpit/world rendering; they are not correctness twins.

On cached 68030/50, swaps 120–780 take **2,585 → 2,650 fields** and
**3,062 → 3,138 ticks**, or **12.7456 → 12.4330 FPS: a 2.45% rate cost**.
Both windows have 660 intervals, no dashboard events and variable dt; do not
interpret this as a bit-identical trajectory. Evidence:
`tmp/dev/tmp/prof/w5-030-{0,768}/`. Separate 20-field DMA samples observe
185,818 / 175,070 framebuffer writes and zero active-display conflicts.
Disabled/selected byte audits pass. No cached instruction-cycle cost is claimed.
The recorded configuration is 68030/50 with data cache and cycle-exact
CPU/memory/blitter enabled, WHDLoad MMU; no new raw CACR read is claimed.

All three same-build comparisons and production-order combined flight checks
are complete. See `w5-verification.md` for the completion audit and current
player policy. Do not compare these rates directly with W4: code layout changes
the later flight event history. Earlier sections below retain their historical
build-specific results; statements that the release mask was zero describe
those earlier checkpoints, superseded by the W5 player selection.

To repeat W5 locally, source `amiga/env.sh` from the development workspace, then
run `python3 tools/w5_measure.py a500 0 --suffix=-manual-off` followed by
`python3 tools/w5_measure.py a500 768 --suffix=-manual-on`. Use `020` or `030`
for the other retained configurations; use 256 for A500 P1 alone. These local
ignored orchestration helpers require the retained CPU fixtures and frozen
build. Run one capture at a time and choose unused suffixes. They boot to flight,
record the short profile and long swap census, and save byte/display audits.
The committed `pacing_costs.py` analyzes complete uncached swap calls;
`swap_fields.py` and the census tools provide the frame-rate evidence. Never
use the fast-draw stress fixture as a game-performance workload.

## W4 current measurements

D1 solid fills use developer/VERIFY **CUSTOM2=128**; normal player enablement
was off at this W4 checkpoint (W5 now supplies player selection). Both all-one
edge masks select D-only DMA;
masked rectangles retain the original C+D blit. The frozen VERIFY SHA256 is
`18395ab2cc6fc1271b6b9e56919bf98c2fe8e3ea886f8e7bbd76a2354ef33241`.
The independent models and three-CPU hardware pixel twins pass; see
`w4-verification.md` for the contract and proof.

A500-equivalent OFF/ON swaps 140–240 take **3,511 → 3,488 fields**:
**1.4218 → 1.4312 FPS (+0.66%)**. These are event-containing windows: each has
20 message calls, nine dirty events, 26 mirror calls, 39 bitmap rejections and
four full-redraw branches. Both retain dt=450. Step 8's complete h3 snapshots
are byte-identical; step 140 differs only at `h3:0483a`, and step 241 only at
that elapsed-time word and the clock at `h3:03f5a`. This build's later event
history differs from W3: do not compare the raw rates across those experiments.

Separate 250-recorded-field samples (100/100/50, two unrecorded joins) give:

| A500 complete call | OFF mean main cycles | ON mean main cycles | OFF/ON calls |
|---|---:|---:|---:|
| Full-width rectangle, `sim:2fc68` | 36,991.00 | 27,067.89 | 18 / 18 |
| Whole 3D pass, `sim:2c552` | 2,440,723.75 | 2,418,786.00 | 8 / 8 |

Costs include RTS and exclude IRQ cycles and chunk-cut calls. A rectangle's
last plane remains asynchronous: whole-pass costs include later waits. Other
rectangle shapes have different call mixes (88/97); no paired per-shape claim
is made from their pooled averages. These are W4-only results. Evidence:
`tmp/dev/tmp/prof/w4-a500-{0,128}/`.


On the 14 MHz 68020, swaps 80–400 take **2,594 → 2,507 fields**:
**6.1583 → 6.3720 FPS (+3.47%)**. Both windows contain 320 swap intervals
and no dashboard events. Variable dt permits world-state divergence; these
rates describe the observed windows, not bit-identical world histories.
Separate 250-field samples give full-width rectangle means of
**73,202.06 → 53,828.28 main cycles** (51/54 calls). This is a CPU-cycle
comparison within the 68020 configuration, not a direct time comparison with
68000 cycles. Evidence: `tmp/dev/tmp/prof/w4-020-{0,128}/`.

On the cached 50 MHz 68030, swaps **120–780** take **2,591 → 2,411 fields**:
**12.7161 → 13.6655 FPS (+7.47%)**, over 660 intervals with no dashboard events.
The original ON window 120–660 was only 1,968 fields, so both settings were
extended to satisfy the 2,000-field minimum. The fresh OFF rate-only boot's
120–660 overlap takes 2,117 fields versus the earlier capture's 2,118 (2,508
versus 2,509 ticks): about 0.05% baseline variation. Variable dt again means
these are observed rates, not identical world histories or cumulative W1–W4 gains.
Evidence: `tmp/dev/tmp/prof/w4-030-0-rate/` and `w4-030-128/`.

Separate steps 8–59 give these phase-checked beam-clock measurements:

| Cached 68030 complete call | OFF mean ms | ON mean ms | OFF/ON calls |
|---|---:|---:|---:|
| Whole 3D pass, `sim:2c552` | 48.4996 | 42.8794 | 49 / 40 |
| Full-width rectangle, height 56 | 6.0163 | 5.0591 | 43 / 40 |
| Full-width rectangle, height 64 | 7.8910 | 4.2690 | 47 / 41 |

These are inclusive wall times, including interrupts, from entry to before RTS;
last-plane completion can occur later. They are not cached instruction-cycle
counts. Phase/horizontal-boundary checks exclude 55 OFF and 129 ON observations
across all sampled routines. Different acceptance and world-state histories limit
paired interpretation. Rejected height-22 rectangles are excluded from the fill
comparison. Evidence: `tmp/dev/tmp/prof/w4-030-{0,128}/`. Cache configuration:
68030/50, data cache enabled, cycle-exact CPU/memory/blitter, WHDLoad MMU;
no new raw CACR read is claimed.

All three machines' OFF/ON byte audits pass, including exact selected bytes and
absence of pixel-twin hooks during timing. A500/68020 first 100-field chunks show
observable framebuffer writes and zero active-display conflicts. Cached OFF's
20-field DMA audit observes 147,479 framebuffer writes, including 4,820 into the
buffer fetched in that field, all after that address's last fetch (zero later
fetches). ON observes 143,234 writes with zero active-display conflicts.
This does not establish visible tearing in OFF or replace W5's publication safety.
D1 is retained on all three measured CPUs; normal release enablement remains off.

### Running W4 manually

From `tmp/dev`, source `amiga/env.sh`. The local helpers use the recorded
machine settings and require the exact frozen binary above:

```sh
python3 tools/w4_measure.py a500 0 --suffix=-manual
python3 tools/w4_measure.py a500 128 --suffix=-manual
```

Use `020` for the 68020. For cached 68030, use
`python3 tools/w4_measure_030.py 0 --suffix=-manual` followed by mask `128`.
The cached rate census uses swaps 120–780. Each run needs a fresh suffix. They run sequentially, retain the slave/listing,
record 250 slow-CPU trace fields or cached beam clocks plus a separate DMA
sample, and count actual swaps over at least 2,000 fields. They leave the game
paused. Stop it with `python3 tools/redbaron.py quit` after checking it belongs
to this worktree.

For another binary, use the generic flight-entry workflow with CUSTOM2=128
and CUSTOM5=512, advance to step 8, then record **100 + 100 + 50 fields** with
`tools/capture_current.py` into three new directories. Analyze them using
`R/RedBaron/tools/fill_costs.py` with the live sim base from entry metadata.
Do not join cut calls across the two missing fields, or use cached-CPU
instruction cycles as timings. Record the long swap census separately.
For pixel verification, use CUSTOM2=128 and CUSTOM5=66048 (steady), 66050
(bank), or 66068 (dense); those runs are correctness checks, never timings.
Time Scale stays at 40 and details remain maximal. Avoid input during the tape.

## W3 current measurements

The sound queue fast path (S1), no-op call removal (S9), and bounded volume
reciprocal (S3) are developer/VERIFY bits 10, 11 and 12: CUSTOM2=7168.
Normal player enablement remains off. The frozen VERIFY binary is SHA256
`bad57261d0593f51eb42c79dde6e53a9d15c0154d52d0831ec8edfc8f825469a`.
Queue and exhaustive/live division twins pass on A500, 68020 and cached 68030.
See `w3-verification.md` for contracts, loader lifetime and original-model replay.

On the A500-equivalent configuration, same-build OFF/ON swaps 140–240 take
**2,905 → 2,850 fields**, or **1.7184 → 1.7516 FPS (+1.93%)**. Both windows
exceed 2,000 fields, retain dt=450, and have the same single message event at
step 221 with no mirror event. Step 8 and the final step 241 match outside the
known clocks at `h3:03f5a` and `h3:0483a`. The OFF start snapshot was taken after
an extra screenshot field and is not phase-matched; it is not used as a state
comparison. FPS uses actual swap boundaries, unaffected by that snapshot phase.
This later flight window is not the earlier W2 window and its raw FPS must not
be compared against W2’s earlier baseline.

Separate **250-recorded-field** samples, in 100/100/50 chunks, give:

| A500 complete routine | OFF mean cycles | ON mean cycles | OFF/ON calls |
|---|---:|---:|---:|
| Empty queue, `sim:34d26` | 1,687.04 | 249.57 | 295 / 297 |
| Sequencer with two volume calls, `sim:34d96` | 9,132.89 | 7,181.66 | 295 / 296 |
| Volume for inputs 63/63/63, master 15, enabled | 1,197.95 | 966.04 | 295 / 297 |

Costs include each complete RTS and exclude cut calls at chunk joins. No measured
L6 call was preempted by a higher interrupt. Variation includes chip/slow-memory
bus contention; group volume inputs before comparing. The two inter-chunk gaps
remain unrecorded. OFF retains all nine sim and three sound hook ranges; ON’s
seven disabled sim ranges remain original, and the five selected ranges match
the intended assembled bytes. Evidence: `tmp/dev/tmp/prof/w3-a500-{0,7168}/`.
On the 14 MHz 68020, swaps 80–400 take **2,594 → 2,582 fields**:
**6.1583 → 6.1869 FPS (+0.46%)**. Both censuses are free of dashboard events.
The world is not continuously dt-clamped on this CPU, so its state can diverge;
this is the observed window’s rate, not a bit-identical world-state comparison.

Its separate 250-field samples improve empty-queue means **947.80 → 111.93
cycles** (292/294 calls) and volume means for 63/63/63, master 15, enabled
**527.53 → 486.82 cycles** (293/294 calls). Sequencer means grouped by two,
three and four volume calls are respectively **4,676.35 → 3,676.46**,
**6,125.92 → 5,150.95**, and **7,824.74 → 6,686.76 cycles**. The groups contain
104/145, 153/105 and 19/34 calls; do not pool the different activity mixes.
27 OFF and 13 ON routine observations containing IRQ-entry markers are excluded.
Every timed call lies in the observed timer-dispatch interrupt stack. OFF/ON
byte audits pass, including exact selected bytes. Evidence:
`tmp/dev/tmp/prof/w3-020-{0,7168}/`.

Cached 50 MHz 68030 beam clocks at steps 8–59, after VBlank-phase and horizontal
boundary exclusions, give the following **inclusive wall times before RTS**:

| Routine | OFF mean µs | S1/S9 mean µs | OFF/ON calls |
|---|---:|---:|---:|
| Queue | 3.466 | 1.738 | 256 / 257 |
| Sequencer | 53.373 | 51.420 | 259 / 258 |
| Volume, unchanged code | 4.694 | 4.686 | 632 / 636 |

The full S1/S9/S3 bundle’s volume mean is 4.621 µs (635 accepted calls): too small
and sensitive to phase/input mix to establish a material S3 benefit. Normal policy
therefore retains original S3 on 030/040/060; developer/VERIFY testing uses
**CUSTOM2=3072** on cached 030. OFF and full-bundle swaps 120–660 each take
2,118 fields (12.7276 FPS). The reduced bundle takes 2,117 (12.7336 FPS): a
one-field difference, **not an established FPS gain**. All three windows have
no dashboard events; their variable dt means their world states need not match.

Separate 20-field DMA observations have exactly matching per-register ordered
Paula/control writes and all four channels’ sample-fetch value sequences across
OFF, full and reduced settings. Original-byte and selected-byte audits pass.
Evidence: `tmp/dev/tmp/prof/w3-030-{0,7168,3072}/`. The routine samples have 103,
100 and 99 phase/boundary exclusions respectively; no instruction-cycle claim is
made for the cached CPU. These W3 results are not cumulative W2+W3 gains.

### Running W3 manually

Use the manual 250-field procedure below with **CUSTOM2=7168** on A500/68020
(or **3072** on cached 68030), CUSTOM5=512, and fresh `my-w3-on` output names.
Use CUSTOM2=0 for OFF. For queue/division twins use CUSTOM2=7168 and CUSTOM5=49664;
do not use those instrumented costs as timings. Time Scale remains 40.

For the exact recorded build, the local helpers automate the same comparisons
from `tmp/dev` after sourcing `amiga/env.sh`:

```sh
python3 tools/w3_measure.py a500 0 --suffix=-manual
python3 tools/w3_measure.py a500 7168 --suffix=-manual
```

Use `020` for the 68020. For cached 68030 use
`python3 tools/w3_measure_030.py 0 --suffix=-manual` and then mask `3072`.
Each suffix must be new. These helpers intentionally require the frozen hash;
use the generic procedure when developing a different binary. Never overlap
controllers/captures. The helpers retain models’ input groups, byte audits,
250 slow-CPU trace fields, actual swap clocks and dashboard-event censuses.
Cached timings use beam clocks and a separate 20-field DMA observation.


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
A500/68020 use 60. The final event/bank/dense cost matrix is complete. The release mask remains zero.

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
common-step pass samples show smaller differences: 0.34% event, 2.71% bank and
0.71% dense, with only two common accepted passes in bank/dense. These are
inclusive wall times, not FPS gains. All three enabled routine means improve.
The dense OFF DMA sample has 730 writes to the buffer fetched earlier in the
field, with no later fetch of those written addresses; this does not prove visible
tearing, and ON’s zero count does not make W2 a swap fix. W5 remains open.
The complete W2 development audit and explicit low-value deferrals are in
`w2-verification.md`; normal player enablement remains separate.

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
That historical helper requires the recorded W2 revision/hash, not the newer W3
binary. Its output directories must not already exist; use `--suffix=-manual` for another
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
the current W2 matrix and bounded display checks are recorded above and in
`w2-verification.md`. Tear-free publication itself remains W5 work.

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
| `sound:$1b1e` | 2.43% | — | 325 | Alternating 224-byte sample-buffer refill |
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

The revised cockpit render phase removes redundant interpolation after every
world tick. Its A500 correctness capture checks 101 poses over three draws at
completed ticks 45, 108 and 153, with exact restoration and 89 visual changes.
The long gaps between draws remain a capacity concern, not a measured FPS result;
250-field completed-tick/debt/publication measurements remain required.

On cached 68030 the same revised build passes 132 pose checks over four draws,
including two changing interpolated frames at completed tick 43 with identical
world-pose snapshots and no intervening world update. This verifies a render-only
iteration; it does not measure 50 FPS or establish full gameplay convergence.

W6 now selects safe publication automatically and uses a one-field minimum;
W5 alone retains two fields. On the frozen `1a0677e1…` VERIFY build, the fast-draw
fixture crosses field-counter wrap and preserves exact world-clock funding.
The W5-only control retains 39/39 two-field intervals and original W6 hook bytes.
With real 68030 cockpit drawing, 99 poses restore exactly, and nineteen observed
publication intervals satisfy exact clock funding. Those intervals are 3–7 fields,
with 4–9 CIA ticks of debt observed at publication. This is timing plus W5 only,
not the complete performance bundle or a 250-field capacity measurement. The
one-field cap is available, but real smooth 50 FPS has not yet been demonstrated.
