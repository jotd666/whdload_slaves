# W6 implementation and verification ledger

Status: **in progress**, not player-enabled. The user authorized consistent
simulation speed independent of achieved FPS and smooth 50 FPS on capable PAL
hardware. `game-time-plan.md` records the design and all acceptance gates.

## Gameplay-speed acceptance

The user reaffirmed that gameplay speed must be independent of achieved FPS.
The plan now states separate checks for equal-tick complete state, equal-time
funded ticks and sustainable completed ticks. A smooth display or an exact clock
kernel alone satisfies none of the full gameplay acceptance claims. Retaining
debt proves that elapsed time was not discarded; increasing debt still means the
machine is failing to sustain the requested simulation rate.

## Exact clock foundation

`time-core.s` advances one unprocessed CIA interval. It retains a 128-bit
fractional world phase in units of LCM(10..80), with an exact rate table for
all supported divisors. One interval earns `1024 * LCM / F`, or eight times
that under compression; one world update spends `225 * LCM`. No fraction is
rounded or reinterpreted when F changes. The largest single-interval intermediate
fits four longwords, including a nearly full incoming phase and 8× compression.

The caller must execute all returned world updates (zero to four) before advancing
the CIA cursor again. Unprocessed CIA intervals are retained debt, not multiplied
into the bounded phase. The separate service accumulator earns 1024 and spends
2560, corresponding to 128-unit F=20 updates. It is unaffected by Time Scale or
compression. This is a clock kernel, not yet a replacement game loop.

`game_time_core.py` generates the exact constants and 426 native CPU cases.
The independent rational oracle tests every case and a 10,000-interval mixed-rate
sequence. The actual 68000 assembly executes every generated case at VERIFY
sim-v1 load and aborts on a mismatch. The kernel and vectors are currently
VERIFY-only; no new original-executable byte range is patched by this checkpoint.

The frozen foundation VERIFY image has text size 109,818 bytes and SHA256
`6e955ab6bc08c7e6a54912231d5734fba5da9f95343cce6d9bd878924c0d0654`.
A500, 68020 and cached 68030 boots completed the self-test and reached the native
flight anchor. The 68020 and 68030 completion counters were independently read
as 426. Evidence: `tmp/dev/tmp/prof/w6-core-*/`.
These are arithmetic and boot checks, not timing-mode gameplay or FPS results.
The normal and developer build hashes remain byte-identical to W5 (recorded in
`game-time.md`). Each owned emulator was quit before the next CPU capture.

A first read-only interpolation audit brackets one native `sim:0056c` render on
68030: 394 h3 bytes change, while all 280 captured player-object bytes remain
identical. The changed h3 regions still require classification, and other active
objects/camera modes are not covered by this one-frame sample. Evidence is in
`w6-core-030/render-writes/` beneath the local profile directory.

## Scheduler and input contract

`game_time_scheduler.py` is the rational scheduling oracle. Its tests cover
frame-partition independence of deadlines and input, timer wrap, exact Time Scale
changes, independent services, compression, bounded work batches, retained debt,
pause/rebase and explicit input queue overflow. It accepts a quantum parameter;
the current native arithmetic candidate uses the planned 225 units.

Input acquisition in CIA interval N assigns eligibility N+1, preserving producer
sequence for ties. Freeze the eligible input set before running that boundary's
world updates. This prevents a late keyboard IRQ from changing a second compressed
update at the same boundary differently on faster hardware. Commands are consumed
once; held state persists. Overflow must fault explicitly rather than silently
remove old events. No input implementation is claimed merely from this model.

## Next integration work and gates

1. Reserve the developer timing bit and install sim-v1 hooks with original-byte
   checks; leave the player verified mask unchanged until completion.
2. Add producer-side timestamped input, separate world and presentation ownership,
   and VERIFY logs. Cover keyboard, joystick and mouse; native input polling has
   direct hardware reads and menu side effects, so it is not IRQ-safe as a whole.
3. Split the main loop and execute due world updates in order, including its
   command/world counters and immediate mission/death exits. Keep sound service
   and timestamped menu/pause transitions responsive between bounded batches.
4. Move timed camera/repeat work to the independent service clock and message
   expiry to active-flight time, leaving dirty buffers tied to publications.
5. Add render interpolation of consecutive world states and the one-field PAL
   cap under W6. Audit native render/camera writes; drawing must never feed
   interpolated state back into physics, AI, collision or RNG.
6. Run the full state, physics/combat, input/transition, 50-FPS presentation and
   CPU-capacity matrix in `game-time-plan.md`. No release claim before these pass.

At this checkpoint 79 host tests pass. The clock self-test is not a substitute for
the eventual scheduler twin, full active-object comparisons or live interpolation
checks. W6 remains unfinished until those requirements are handled.


## Native input queue foundation

`time-input.s` implements a 256-entry FIFO with 16-byte timestamped records.
The producer publishes its wrapping sequence number only after the complete
record is stored; the consumer publishes tail only after copying a due event.
Full queues latch overflow and retain every old entry. Producers must be
serialized by the eventual IRQ wrapper; this module does not yet install input
hooks or replace native polling.

The native self-test covers two complete fills/drains, exact four-long payloads,
full-queue rejection without eviction, future/deadline eligibility, 16-bit sequence
wrap and both signed and unsigned 32-bit CIA boundaries. Modular timestamp
comparison explicitly clears subtraction overflow flags before interpreting the
signed distance. The caller requires distances below half the CIA counter range.

A500 VERIFY text size is 114,426 bytes, SHA256
`f79a037322e0c81b1874d81f51189e06a73324044838495713a698b4ed9caea8`.
It reaches native flight with completion counters **426 clock cases and 512 input
events**. The counters were read from the saved RAM snapshot after checking an
exact match of its live marker against all twelve flight-entry metadata fields.
The first live collector failed on a non-UTF-8 copyright byte in the assembler
listing; that collector was corrected, and the retained snapshot avoids requiring
another boot. Evidence: `tmp/dev/tmp/prof/w6-input-a500/selftest-result.json`.

The test buffer and kernel remain VERIFY-only. This is sequential native FIFO
verification, not a claim of live interrupt interleaving, device capture or an
implemented game scheduler. The owned emulator is shut down.


## Keyboard acquisition hook

VERIFY CUSTOM5 bit 20 installs a checked six-byte replacement for the relocated
LEA at `sim:308b6`. Its IRQ wrapper timestamps the decoded transition for the next
CIA boundary, appends the event and restores all incoming registers/flags except
a0, which receives the original keyboard bitmap address. Native code at
`sim:308bc` then performs its original bitmap store and key-command FIFO handling.
The observer does not consume or replace native input. CUSTOM5 bit 21 enables a
four-transition supervisor-VBlank fixture (Right down/up, Fire down/up) through
the actual installed hook and original decoded-key tail. It does not cover the
host key mapping or the CIA serial handshake.

The 68030 fixture uses VERIFY SHA256
`634ca59a93848d7114673787cf049afece305e5e658f28fb3cc15cd4d674d2f5`,
text 118,982 bytes. Four independently logged acquisition timestamps match their
queued eligibility boundaries exactly at acquisition+1. Head/high-water are four,
tail is zero, and overflow is clear. Four debugger entry/exit register pairs verify
all exposed registers and status flags, with only the expected a0 and PC changes.
The native hook's instruction/branch/relocation audit reports zero errors.
Evidence: `tmp/dev/tmp/prof/w6-input-fixture-030/`. `input_events.py` rejects wrong
deadlines, overflow and extra/contaminating events rather than filtering them out.

All 82 host checks pass. This proves the observed keyboard producer contract;
it does not yet connect keyboard events to world ticks, capture mouse/joystick,
or implement the gameplay loop. The owned test emulator is shut down.


## First native flight-loop integration checkpoint

VERIFY-only CUSTOM2 bit 13 (`8192`) now installs four checked sim-v1 hooks:
`sim:21d28` (input/world iteration gate), `sim:21e7a` (draw decision),
`sim:03d5e` (primary clock override) and `sim:21f60` (mission exit).
The normal and developer masks remain unchanged. This is an incomplete timing
experiment, not a selectable player feature or W6 acceptance result.

The gate retains the original input call's stack and `sim:21d30` return address.
It advances the exact clock kernel through unprocessed CIA intervals until a
world tick is due, then lets the original command/world/camera/sound loop run in
its original order with primary dt 225. The draw decision advances that same
cursor: if another world tick is due, it skips drawing and the buffer-dirtiness
decrement. Otherwise it retains the original draw branch. The existing clock
routine still runs, but cannot overwrite the fixed primary dt while this loop
owns flight. Mission exit clears that ownership without changing the native
return value or flags. Input and other elapsed-time consumers are not yet split.

Frozen VERIFY text is 119,686 bytes, SHA256
`49afe22569d9e46d9bd97176bed04488be5010b1c1d12ed3d5bb9d47456dca5f`.
All 17 declared sim hook ranges pass the instruction/direct-branch/relocation
audit; indirect callers still need the usual semantic review. All 82 host tests
pass. Normal/developer binary hashes remain identical to W5.

The cached 68030 run reaches flight and follows exact integer deadlines
`ceil(tick * 225 * 33 / 1024)` from its retained CIA epoch. Its later 201-row
capture spans scheduled ticks 120–320 without a missed or repeated tick ID.
Within it, ticks 240–320 span 580 observed and 580 scheduled CIA intervals;
all those observed boundaries have zero CIA debt. This establishes that the
native gate can wait for deadlines after catching up. It is not a performance
measurement, a completed-world timestamp, or a full-state correctness proof.
Evidence: `tmp/dev/tmp/prof/w6-loop-030/loop-result.json` and `loop.log`.

The immediate-install boot exposes a real integration failure: the setup route's
in-flight panel time accrues as debt. At scheduled tick 120, the cursor trails
observed CIA time by 295 intervals; the loop then skips draws to drain it. The
scheduler must bracket actual pause/menu operations and exclude their duration
without deleting pre-existing debt. Do not treat draining this artificial setup
debt as successful pause behavior. The attempted post-capture byte audit failed
in its host collector before reading RAM; it supplies no 68030 byte-audit claim.

Still missing from this checkpoint: acquisition-timestamped input consumption,
secondary camera/repeat execution, pause/menu rebasing, message/death timing,
compression semantics, render-only iterations/interpolation, full world-state
comparison and the complete gameplay/capacity matrix. Native input remains
render-schedule-dependent during catch-up, and secondary service counts are
currently telemetry only. These limitations explicitly prevent enabling the bit
for players or claiming consistent gameplay from the deadline log.


The same frozen build on A500 follows exact deadlines for scheduled ticks
40–240 (201 rows), with dt 225 and F 33 throughout. Those 200 updates advance
the cursor by 1,450 CIA intervals while observed time advances by 843; setup
debt falls from 7,617 to 7,010 intervals. All 200 draw opportunities are skipped
while draining that debt. This is a catch-up-path check, not normal-flight FPS
or a supported-capacity claim. The byte audit verifies all four selected hook
opcodes/targets, the gate's padding NOP and the original relocated bytes for all
13 disabled sim ranges. Evidence: `tmp/dev/tmp/prof/w6-loop-a500/`.
Both owned emulators have been quit. Pause/menu rebasing is the next integration
fix; the larger A500 setup debt makes this especially important before further
CPU comparison.


## Modal-flight clock rebasing

The next VERIFY candidate adds bit-13 wrappers around the native menu calls at
`sim:21ba2` and `sim:21c02`, Preferences at `sim:21c20`, controls at `sim:21c82`
and the pause-key path at `sim:21bf6`. Each calls the original no-argument
routine and then replays its displaced result operation or branch. During the
outermost modal interval the timing owner is suspended, so the original menu
clock can run. Returning adds the excluded unsigned CIA duration to the existing
cursor, retaining fractional phases, pending updates and prior debt. Nested
modal intervals are counted only once. The wrappers retain native integer
register results and replay NZVC; these call sites do not consume returned X.

Frozen VERIFY text is 120,594 bytes, SHA256
`b241fa69f4f9fa24d9a791d1dfea51a9239feb60944e6238fbe467c2964d443b`.
A native startup test uses private clock/dt storage, restores installer state
and never writes game RAM. Across an unsigned counter wrap, two nested pauses
exclude 48 CIA intervals while retaining five intervals of old debt, world and
service phase, two pending world updates, seven unserviced secondary updates
and the world tick counter. A subsequent zero-duration pause adds no time.
The independently read A500 completion counters are 426 clock cases, 512 FIFO
events and one complete pause scenario.

The repeated A500 Preferences route excludes **7,614 CIA intervals**. At its
first recorded boundary, scheduled tick 40, cursor and current time differ by
one interval. The previous candidate's route accumulated thousands of intervals
of panel debt. This comparison diagnoses the transition fix, not a same-state
performance gain. All 81 boundaries through tick 120 still satisfy the exact
fixed-step deadline after subtracting the recorded excluded duration. Its later
41-interval debt is active-flight work, retained rather than discarded. All nine
selected timing hooks and all 13 disabled ranges pass the live byte audit.
Evidence: `tmp/dev/tmp/prof/w6-pause-a500/`.

All 22 sim ranges pass the static instruction/direct-branch/relocation audit;
82 host tests pass and normal/developer hashes remain byte-identical to W5.
The live route covers Preferences; native pause-key/menu/controls wrappers need
separate transition fixtures. The inline Ctrl-Q confirmation in
`sim:1ef08`–`sim:1ef74` remains outside these wrappers. Rate changes with old debt
and queued input across modal intervals still require the timestamped consumer
integration. Do not interpret this checkpoint as completing all W6 transitions.


On cached 68030 the same candidate excludes 863 panel intervals. All 81 logged
boundaries from scheduled tick 40 through 120 satisfy the paused-time-adjusted
fixed-step deadline. The first boundary is five CIA intervals behind; the final
boundary has zero debt. All nine selected timing hooks, 13 disabled ranges and
native completion counters (426 / 512 / 1) pass. Evidence:
`tmp/dev/tmp/prof/w6-pause-030/`. Both owned emulators are shut down.


## Atomic clock publication for timestamped input

The native flight anchor on cached 68030 has SR zero: it is user mode. Evidence
is `tmp/dev/tmp/prof/w6-input-mode-030/main-mode.log`. Main-task input ownership
must therefore not assume that privileged interrupt-mask instructions are legal.

Pause/resume wrappers now publish a word request and wait for the existing
supervisor VBlank observer to apply the transition. The observer masks input
interrupts, updates cursor, paused total and ownership together, then acknowledges
last and restores its incoming SR. Entry-handshake time is active-flight time;
resume-handshake time is still excluded modal time. The private startup test calls
the same transition kernels directly and does not depend on initialized game IRQs.
The state also retains the cumulative excluded time at outermost pause entry.

Frozen VERIFY text is 120,706 bytes, SHA256
`67889b052b833599b80c152ea601baa1e98b46a43c72fe6d94647b803d288e93`.
The debugger records all six private self-test calls with no pending IRQ request,
then the actual Preferences entry and exit with SR `0x2700` and requests 1 and 2.
The collector initially rejected the extra private-test calls; its corrected
check validates the complete eight-call sequence rather than discarding entries.
The live route excludes 864 CIA intervals. All 81 subsequent boundaries satisfy
the exact deadline, ending with zero CIA debt. All nine selected hooks, 13 disabled
ranges and completion counters (426 / 512 / 1) pass. Evidence:
`tmp/dev/tmp/prof/w6-pause-atomic-030/`. The owned emulator has been quit.
All 82 host tests pass and normal/developer hashes remain unchanged.

This establishes an atomic clock tuple for the upcoming IRQ input producer.
Its active-flight timestamp can be `CIA - paused_total`; during a panel, held
transitions can share `pause_start - pause_base`, with commands suppressed.
The consumer compares against `cursor - paused_total`. Add one CIA boundary to
input eligibility as before. Those conversions and keyboard consumption are not
yet installed. Input fixtures must exercise both sides of the atomic transition,
including queued pre-pause events, rather than flushing old debt or input history.


## Keyboard replay through the native flight reader

VERIFY timing bit 13 now automatically installs the checked keyboard acquisition
hook and redirects `sim:309c0` and `sim:309cc` to a private flight bitmap and
command FIFO. The seed snapshot is taken atomically in VBlank after the automatic
route. Before that snapshot, and in menus, native physical input remains in use.
The VERIFY route stops replacing gameplay commands after ownership transfers.
Its frame-count-based Right fixture is bypassed in this mode; the IRQ fixture
uses CIA thresholds and longer holds instead.

The producer assigns active-flight eligibility `CIA - paused_total + 1`.
During a modal interval it uses `pause_start - pause_base + 1` and marks the
transition held-only, so UI commands are not replayed as flight commands.
The consumer advances the private held state at each processed CIA boundary,
using `cursor - paused_total`, before running due world updates. Key-down commands
are encoded with the original modifier grouping and placed in a separate bounded
FIFO; each native pop advances its tail once. Both queue overflows fault explicitly.
Entering a panel clears stale physical commands already captured for flight;
queued simulation history is retained. Mission exit relinquishes keyboard
ownership, and the next mission reseeds from physical state.

Frozen VERIFY text is 122,194 bytes, SHA256
`62ed35649cc5921cee09b81818bbbeae04fdd6ae0b3ac58aa079c5bf1d5da4f8`.
The cached 68030 fixture acquires Right down/up and Fire down/up through the native
IRQ hook. Forty native post-input observations match every event's active-clock
deadline, held state, bank axis (0/127), fire flag and command history. Four events
are consumed and exactly two commands are popped, with no overflow or extra
input. This checks the actual `sim:1ecc2` output, not just queue bookkeeping.
All twelve selected timing/input hooks and thirteen disabled ranges pass the
live byte audit; native clock/FIFO/pause test counters are 426 / 512 / 1.
Evidence: `tmp/dev/tmp/prof/w6-keys-030/`.

`keyboard_replay.py` independently reconstructs the event and command history
from acquisition records and validates native outputs. Host tests exhaust all
256 modifier combinations against the original word-rotation algorithm and
reject repeated commands, wrong axes/deadlines and overflow. The live fixture
covers bank/fire, not all modifier combinations or physical serial decoding.
Normal/developer builds remain byte-identical to W5.

This does not complete W6 input: mouse and joystick sampling are still native,
modal/restart input fixtures and native modifier twins remain, and rate changes
with old debt still need explicit timeline handling. Full world-state equality
across render schedules, secondary services and interpolated presentation remain
separate required gates. No frame-rate-independent gameplay claim is made yet.


The same frozen keyboard candidate also passes all forty A500 post-input
observations (scheduled ticks 40–79), four consumed transitions, exactly two
commands and every byte/counter audit. The observed debt reaches 93 CIA intervals,
versus nine in the cached-CPU capture: this test does exercise queued input while
catching up after slow drawing. These are input-history checks, not FPS or world
state comparisons. Evidence: `tmp/dev/tmp/prof/w6-keys-a500/`; each capture's
`keyboard-context.json` records its debt and draw counters. Both owned emulators
are shut down. The full host suite now contains 86 tests.


## Live Preferences input-boundary fixture

VERIFY CUSTOM5 bit 22 extends the bit-21 IRQ fixture with F10 down/up and Escape
down/up. It records the independent acquisition clock tuple alongside all eight
transitions. The game itself opens Preferences through the timestamped F10
command and closes it through native physical menu input. The fixture does not
write menu state, simulation state or input-consumer results.

Frozen VERIFY text is 122,470 bytes, SHA256
`cbdbc5557ea44efafc6ef124e6e78256d095db6f3fef770d5d3ade60d768fd77`.
On both A500 and cached 68030, the recorded window has one native Preferences
entry, eighty post-input observations at exact fixed-step deadlines and 79 world
calls, all with active flight ownership. All eight transitions are consumed;
only Right, Fire and F10 become flight commands. Escape is acquired while modal
and does not leak into flight. Native bank/fire outputs match the timestamped
held history throughout the window. The panel excludes 182 CIA intervals on
A500 and 218 on cached 68030; different elapsed panel durations do not alter the
active-time deadline sequence. These fixtures do not compare complete world state.

Both captures pass all twelve selected-hook and thirteen disabled-range byte
audits and native clock/FIFO/pause completion checks. Evidence:
`tmp/dev/tmp/prof/w6-modal-keys-{a500,030}/`, including `keyboard.log`,
`keyboard-result.json` and `modal-result.json`. Both owned emulators are quit.
The host suite has 88 passing tests, including deliberate modal-command leakage
and timestamp corruption. Normal/developer hashes remain byte-identical to W5.
The larger VERIFY fixture crossed the 68000 PC-relative reach of two observer
loader-pointer reads; they now use an observer-local pointer initialized at
startup, with no normal/developer code changes.

This completes the tested F10/Preferences/Escape keyboard transition, not every
modal path. Pause-key, controls, restart and inline quit-confirmation fixtures,
Time Scale changes with old debt, mouse/joystick replay and full world-state
comparisons remain required. Native mouse position is also written/reset by
world control routines (for example `sim:1e8ec`), so analog replay must account
for those resets rather than copying VBlank's accumulated position blindly.


## Timestamped joystick and mouse-button replay

VERIFY bit 13 now captures a device packet at the end of native VBlank, after
its calibrated-axis callback. The packet contains masked JOY1DAT, calibrated
X/Y bytes, native mouse-button state and joystick fire inputs. Changed packets
share the keyboard's timestamped FIFO and active-flight deadline convention.
Flight readers consume a private snapshot advanced by the CIA cursor; menu
readers retain physical input. Initial ownership seeds both input snapshots
atomically. Device packets do not produce keyboard commands. Mouse movement is
not included: native world/camera resets of its accumulator require separate
replay handling.

CUSTOM5 bit 23 supplies eight producer-packet transitions: digital Right,
joystick fire, left mouse and right mouse, each followed by release. It does
not write hardware, world state or consumer results. The native joystick decoder,
button handling and flight poll consume the packet. This fixture verifies the
producer-to-flight path, not host-device delivery or calibrated analog mode.

Frozen VERIFY text is 124,296 bytes, SHA256
`6d423cb1595d44ee1cfa99409b0e25b8ed607692da9f38c48fafc840a0453cfa`.
A500 and cached 68030 each pass 48 native post-input observations: every private
snapshot, bank axis and fire flag matches the independent acquisition history;
all eight events are consumed, with no keyboard commands or overflow. Observed
CIA debt reaches 93 on A500 and 10 on cached 68030. These are input-history
checks under different backlogs, not complete world-state or performance results.
Evidence: `tmp/dev/tmp/prof/w6-devices-{a500,030}/`, including
`devices.log`, `device-result.json`, `byte-audit.json` and `selftest-result.json`.
Both owned emulators are quit.

Both captures pass twenty selected-hook checks, thirteen disabled ranges and
native clock/FIFO/pause counters 426 / 512 / 1. Static instruction/branch/relocation
audit passes all 33 sim ranges. The independent digital-direction model checks
all 65,536 hardware words against the original decode table at `sim:30f20`.
Evidence-validator tests reject corrupted deadlines, packets, native outputs,
overflow and keyboard leakage. The host suite has 92 passing tests.
Normal/developer hashes remain byte-identical to W5. VERIFY observer references
use local aliases and a position-independent long-range bridge where the added
instrumentation exceeds 68000 PC-relative reach. Build dependencies include the
new module and previously omitted timing/pacing includes.

Required input gates still include calibrated analog mode, mouse movement,
mixed devices with modal/restart transitions and native modifier twins. The
remaining service clocks, rate/compression transitions, full state comparisons,
interpolation and sustained-speed/capacity matrix remain required for W6.


## Timestamped relative mouse movement

VERIFY bit 13 now acquires the original signed byte-counter deltas at
`sim:2d35c`. It retains the native physical cursor for menus and uses a separate
flight position advanced from timestamped delta events. Each event freezes both
axis limits and becomes eligible at the next active CIA boundary. Clamping is
performed for every acquisition in order, not once on their summed displacement.
The flight poll at `sim:1ecd0` reads the private position. World and camera
recentering at `sim:1e8ec` and `sim:1eb8a` reset that position at their native
control boundaries, while retaining the original physical writes.

Mouse movement acquired while modal is excluded from flight input. The first
VBlank sample spanning seed/resume is also excluded; it contains motion from
before the ownership boundary. Previously queued active-flight motion remains
intact. This policy is implemented, but a live mixed mouse/modal/restart fixture
is still required. It does not certify every input transition.

CUSTOM5 bit 24 supplies twelve producer-local X/Y deltas, including signed
extremes and multiple acquisitions between world updates. Hardware and consumer
state are not modified by the fixture. `mouse_replay.py` independently rebuilds
positions, native dead-zone/response outputs and recentering from acquisition
records. Its native vector file checks 264 word-add/clamp cases; host tests also
cover all 65,536 counter pairs and every normal X/Y position with every signed
byte delta. Deliberate corruption tests reject wrong inputs, outputs, reset
counts, deadlines, overflow and keyboard leakage.

Frozen VERIFY text is 128,828 bytes, SHA256
`391e8af8b5b447ee02cfb8eb2f5987a903043c1d3d28778ebc3a3a2f9c36bcb2`.
The final cached-68030 capture passes all twelve acquisitions and 48 native
post-input/post-world-control observations, with nine moving world ticks and
three ticks consuming multiple acquisitions. Its maximum observed debt is ten
CIA intervals. Eighteen native reset entry/exit flag pairs preserve X (both
incoming values occur) and produce the original NZVC flags. These flags are
written by CPU instructions: the debugger's cached SR display did not give
reliable NZVC values at the same sites and is not used as evidence.

The control observation precedes that tick's camera call. Its reset is therefore
included in the next counter observation; the independent checker accounts for
that ordering. The captures are checked against their own acquisition history,
not against each other's tick numbers: their seed/VBlank phases differ. They do
not prove complete cross-CPU world-state equality.

The final A500 capture passes the same twelve acquisitions, 48 observations,
nine moving ticks, three multiple-acquisition ticks and eighteen reset flag pairs,
including both X states. Its maximum observed debt is 98 CIA intervals and queue
high-water is eleven events, versus three on cached 68030. Both live audits pass
all 24 selected hooks, thirteen disabled sim ranges and clock/FIFO/pause counters
426 / 512 / 1; both mouse counters are 264. Evidence:
`tmp/dev/tmp/prof/w6-mouse-{a500,030}-r2/`, including `mouse.log`,
`mouse-result.json`, `mouse-flags.bin`, `byte-audit.json` and `selftest-result.json`.
Both owned emulators are quit.
The host suite has 98 passing tests; static audit passes all 37 sim ranges.
Normal/developer hashes remain identical to W5. The large step-observer buffer
now follows code to keep growing VERIFY routines within 68000 branch reach.

Remaining input work includes calibrated analog mode, mixed device/modal/restart
fixtures and native modifier twins. Service clocks, rate/compression changes,
interpolated rendering and full gameplay-state/capacity validation remain W6 gates.


## Time Scale history with retained debt

The native divisor setter at `sim:03ce4` now publishes a timestamped setting
through the serialized VBlank handshake. Native `h3:04838` still receives the
setting immediately, preserving its configuration/UI role. The scheduler uses
its own historical divisor until its active CIA cursor reaches the setting's
eligibility boundary. An active change is eligible at publication CIA minus
excluded modal time plus one. A modal change uses the first active boundary
after modal entry/resume. Each boundary applies eligible input and rate history
before funding the exact clock kernel; fractional world credit is never rounded,
reset or reinterpreted.

The separate 32-record rate FIFO retains all settings while the main task has
old debt, deduplicates unchanged values, and explicitly faults on overflow or an
unsupported divisor. Mission initialization seeds the divisor and clears stale
history. Native private-state tests cover sequence-number wrap, CIA wrap, future
retention, ordered prefix consumption and full-queue rejection without eviction.
The modal publication policy is implemented; live changed-setting Preferences
coverage remains required.

CUSTOM5 bit 25 calls the original main-task divisor API with F=10, 80 and 33.
It does not write physics, fractional clock phase or consumer state. This tests
the installed native setter while rendering leaves debt; it is not a Preferences
UI test. `rate_history.py` independently reconstructs credit using rational
arithmetic from the entry snapshot and acquisition log. Every observed world
count, full 128-bit phase, effective divisor, secondary remainder and earned
service count must match. The secondary service count remains accounting only;
executing those camera/repeat services independently is still open.

Frozen VERIFY text is 131,076 bytes, SHA256
`25a6de631488a8ae3beacaad9fac97663431de73871b6a34c3f36c1c36ce561b`.
Both A500 and cached 68030 pass three native publications and eighty observed
world boundaries. A500's publication debts are 97, 93 and 84 CIA intervals;
cached 68030's are 11, 9 and 5. The native configuration divisor differs from the
historically effective divisor in 21 A500 rows and six cached-68030 rows, while
all phases and tick counts remain exact. Queue high-water is two and one,
respectively. This explicitly exercises old-debt isolation; it is not an FPS,
complete-world-state or sustained-capacity result.

Both captures pass all 25 selected hooks, thirteen disabled sim ranges, the rate
queue self-test and existing clock/FIFO/pause counters 426 / 512 / 1. Evidence:
`tmp/dev/tmp/prof/w6-rates-{a500,030}/`, including `rate-initial-clock.bin`,
`rate-acquisition.bin`, `rate.log`, `rate-result.json` and `byte-audit.json`.
Both owned emulators are quit. The full host suite has 101 passing tests;
corruption tests reject retroactive rates, wrong phases, lost ticks, secondary
accounting errors and overflow. Static audit passes all 38 sim ranges.
Normal/developer hashes remain byte-identical to W5.

Time Compress is not integrated by this checkpoint: the native scheduler still
uses multiplier one. Modal rate changes, independent timed services, interpolation
and the full state/capacity matrix remain required before W6 can be enabled.


## Active-flight message lifetime checkpoint

The VERIFY timing mode now hooks accepted message construction at `sim:03c06`,
native shortening at `sim:03c7c`, render ageing at `sim:0084e` and the hidden-text
clear at `sim:00ab4`. Every hook validates its original instruction and relocated
timer address. Timing off leaves those bytes untouched. Message acceptance,
priority selection, text and combat event generation still use native code.

A full message receives 178 active CIA intervals, approximately three PAL
seconds rounded up to the clock's resolution. The cursor excludes modal time
and advances even when drawing is skipped. Time Scale does not enter the
message calculation. The native timer at `h3:04820` becomes a compatibility
value: ceil(remaining intervals * 15000 / 178), with one retained while native
erasure is pending. The halfway priority threshold at `sim:0114e` still reads
7500. Shortening uses ceil(requested native timer * 178 / 15000); it can round
up by less than one CIA interval. A zero/negative request expires immediately.

On expiry the service marks the last painted rectangle through the native pure
rectangle publisher at `sim:197ee`. This sets the two-buffer dirty count without
performing a blit or drawing. The next actual paint takes the original erase
path at `sim:00a2c`, clears the timer and republishes dirty work. Hidden world
updates cannot spend either buffer's redraw. Keeping a positive pending timer
also preserves the native old-rectangle cleanup when a new message replaces
expired text before erasure. A hidden-text render branch cannot cancel the
clock-owned message early.

CUSTOM5 bit 26 invokes the original main-task message APIs: initial text,
replacement, shortening, a later full lifetime, then a later shortened lifetime.
Combat remains active. It legitimately interrupts the early shortened fixture:
lowering the timer passes the native priority threshold sooner, allowing
“you're being shot at” and hit messages. Those events are validated too; the
fixture does not suppress them. The later full and shortened lifetimes must
both reach their own deadline; cleanup must use native erasure or the native
old-rectangle path if a new message replaces already-expired text.

`message_time.py` independently checks the native ledger and world-boundary
observations. It rejects wrong full/shortened deadlines, late or premature
expiry, wrong pending timers, missing two-buffer dirtiness, malformed combat
events and incomplete cleanup. The native arithmetic self-test executes all
179 remaining-time scale values plus deadline-wrap checks. Host tests cover all
shortening inputs 0..15000 and different draw schedules. These are service
correctness checks; they do not establish gameplay-state equality or FPS.

Frozen VERIFY text is 135,744 bytes, SHA256
`361ab11d3f0e2dc3a35dff7348ca7e925fb84854c61048633dc188cad6d3b9e6`.
The cached-68030 capture passes 23 ledger events (ten fixture events), 100
world-boundary observations and two native erasures. The later full message
expires at active CIA cursor 831, exactly its deadline; the later shortened
message expires at cursor 988, also exactly its deadline. Native erase follows
at cursors 833 and 993. Both timers and buffer dirtiness finish at zero. These
cursor counts are capture-local, not portable flight landmarks.

The selected-hook audit passes all 29 timing hooks and thirteen disabled sim
ranges. The message self-test counter is 179; clock/FIFO/pause remain 426/512/1.
All 108 host tests pass, and static audit reports 42 sim ranges with zero errors.
Normal/developer hashes remain byte-identical to W5. Local evidence is
`tmp/dev/tmp/prof/w6-messages-030-r3/`, including the message ledger, observations,
result, byte audit and self-test results.

The same-build A500 capture passes 24 ledger events (nine fixture events) and
200 world-boundary observations. Its full lifetime expires at active cursor
1988, exactly its deadline, but another message replaces it before the next
paint. The positive pending timer preserves native old-rectangle cleanup;
the replacement retains dirty count two. The later shortened lifetime expires
at cursor 2146, exactly its deadline, and native erasure follows at cursor 2307.
Thirty-one observed world boundaries retain expired text pending an actual paint.
This is deliberately **not** a claim of three-second visible removal on a slow
renderer: the message clock expires on time, while pixels change only on a paint.
Final phase, timer and dirty count are all zero. Evidence:
`tmp/dev/tmp/prof/w6-messages-a500/`. The A500 selected/disabled byte audit and
179 / 426 / 512 / 1 native counters also pass. Both owned emulators are quit.

The A500 observation window was extended from 100 to 200 world boundaries to
observe final drawing and cleanup; it is not a 250-field performance capture.
No FPS, sustained-capacity or complete-gameplay claim is made.
Modal message restoration, combined Time Scale/compression transitions, hidden
view changes and pixel-level overlay comparisons remain additional integration
coverage. The camera/repeat split, interpolation, full-state comparison and
capacity acceptance are still required before W6 can be enabled for players.


## Mouse ownership for the independent camera service

World and camera movement now accumulate the same timestamped raw deltas into
separate private positions. Native world recentering at `sim:1e8ec` changes only
the world position; camera recentering at `sim:1eb8a` changes only the camera
position. Both retain native physical cursor writes for UI compatibility. The
camera's displacement reads at `sim:1eb5c/1eb70` use its own position while W6
owns active flight; other contexts use the native input packet. At completion of camera input construction (`sim:1ebba`), its private sample is
consumed even when joystick/button priority ignored the mouse. Ignored movement
must not appear in a later camera sample. Mission seeding initializes both from
the physical cursor. Modal acquisition rules are unchanged.

This removes the shared-state dependency that would otherwise let a camera
service tick consume mouse motion before the next world update. It does not yet
dispatch camera services at their independent frequency: that remains the next
integration step. Native camera commands and mission-tape recording also remain
on the existing world path at this checkpoint.

`mouse_ownership.py` provides 192 native interleaving vectors and independent
host checks. The actual acquisition/reset primitives run with separate world
and camera resets, accumulated deltas, clamping and distinct owner positions.
Tests verify that adding camera resets cannot change flight input, and adding
world resets cannot change camera input. Live observations additionally compare
the native camera's gain-four response with its independently predicted input,
its own recentering and the unchanged world position after the camera call.

Frozen VERIFY text is 139,622 bytes, SHA256
`6181df0c000a36550c1466cd87a9f19528be7ccc526012c4300295f35c328246`.
The final A500 capture passes twelve acquired movements, 48 native input/world
observations and 47 native camera observations. Ten world ticks contain motion,
two consume multiple acquisitions, and twenty native resets preserve both
incoming X states and the original NZVC results. Maximum observed debt is 99 CIA
intervals and queue high-water is ten. The ownership self-test completes 192
cases; the existing mouse arithmetic counter remains 264. Evidence:
`tmp/dev/tmp/prof/w6-mouse-owners-a500-r2/`.

The A500 byte audit passes 32 selected timing hooks and thirteen disabled sim
ranges; clock/FIFO/pause counters remain 426/512/1. All 113 host tests pass.
Static audit reports 45 sim ranges and zero errors. Normal and developer builds
remain byte-identical to W5.

The final cached-68030 capture passes the same twelve acquisitions, 48 input/world
observations and 47 camera observations. It has nine moving ticks, three ticks
with multiple acquisitions and eighteen reset flag pairs, including both X
states. Maximum observed debt is ten CIA intervals and queue high-water is three.
The 192/264 native counters, 32 selected hooks, thirteen disabled ranges and
426/512/1 foundation counters all pass. Evidence:
`tmp/dev/tmp/prof/w6-mouse-owners-030-r2/`. Both owned emulators are quit.
The two CPUs are checked against their own acquisition timestamps; this is not
an equal-tick whole-world state comparison. Mixed joystick/analog/modal/restart
coverage remains part of the full W6 integration gate.
These are input ownership checks, not camera-service cadence, full gameplay
convergence, performance or capacity results.

The next service integration must avoid consuming mouse samples once in a
service tick and again in the world camera builder. It must also obtain held
input without letting `sim:1ecc2` pop the world command FIFO. Preserve one-shot
camera commands and the eight-byte camera-control packet recorded by
`sim:21f06`; simply repeating the entire native command/camera pass is insufficient.
The continuous camera routines at `sim:15764/15830` still use their original
secondary-clock calls at this checkpoint.

The secondary-clock inventory also corrects an earlier label: `sim:21b6e` is
an **automatic mission-menu countdown**, not evidence of keyboard repeat.
`sim:21b14..21b64` checks player/mission state and threat conditions;
`sim:21b74` reduces `h3:0783e`, and expiry goes through `sim:21b9e/21ba2` to the
native flight menu. The timer is initialized to 30000 at `sim:24406` and may
reload 10000 at `sim:21b96`. Its two gating words are `h3:07838/0783a`.
This path must get a real-time service policy without replaying the whole
one-shot command dispatcher. The separate keyboard-repeat inventory remains
open; this correction does not remove the clock-independent input requirement.


## Continuous camera service dispatch

`time-camera.s` now samples held input and dispatches continuous camera motion
once per funded 128-unit secondary service tick, after that CIA boundary's input
and rate history are applied and before its world update. Service deadlines
alternate two and three CIA intervals (the exact 1024/2560 accumulator); drawing
cannot create, omit or duplicate one. Catch-up processes the same boundaries.
Before the route's input handoff, native camera behavior remains in use.

The service calls the original input builder with command popping disabled.
It neither consumes a world command nor recenters the world mouse position.
Native F7/F8 held overrides are reflected in its input packet. Native camera
input construction consumes only the camera sample. On a world update, the
original builder still decodes the one-shot view command, while its continuous
fields come from the latest service packet; it does not consume another camera
mouse sample. The original native camera-selection/change-detection pass and
eight-byte mission-tape packet call remain on the world path.

The original continuous orbit/free-camera routines (`sim:15764/15830`) execute
with secondary dt temporarily set to 128; the previous word is restored before
returning to the world loop. The native follow/orbit callback refreshes the pose.
Their old calls within the world camera pass (`sim:16774/16788`) are skipped
while the service owns flight, preventing double motion. The original routines
and UI behavior remain in use outside ownership. All three new hooks validate
whole original instructions, and timing off leaves their bytes unchanged.

CUSTOM5 bit 27 selects free camera through the original `sim:158f4` API once,
as a correctness fixture. Combined with timestamped mouse movement and keyboard
press/release fixtures, this permits direct observation of actual camera motion
and a nonempty command queue. It is not a player-input or performance workload.
The fixture runs on the main-task gate, so initial cockpit services can precede
its mode switch; those must leave angles unchanged. Once selected, the mode
must remain free camera throughout the checked window.

`camera_service.py` independently models the native word shift, signed multiply,
arithmetic shift and wrapped orientation updates. Every service record checks
its exact funding interval/remainder, native camera controls and resulting
angles. It also checks unchanged world mouse state, FIFO head/tail/pop count and
restored secondary dt. Corruption tests reject wrong cadence, input, queued
commands, mode, arithmetic, clocks and missing/extra dispatches.

Frozen VERIFY text is 140,322 bytes, SHA256
`022b82f7bf7161b43ec10452b0117d86faf8977e3b3bdbf66c29ec0790a1c984`.
The cached-68030 capture passes 160 service boundaries, including 158 free-camera
updates, eight moving services and four with unconsumed world commands queued.
Evidence: `tmp/dev/tmp/prof/w6-camera-free-030/`, including `camera.log`,
`camera-result.json` and the initial clock state. An earlier cockpit-only
capture established cadence/isolation but exercised no camera motion; it is not
used as proof of free-camera arithmetic.

The same-build A500 capture passes 160 services, including 157 free-camera
updates, eight moving services and five with world commands still queued.
Evidence: `tmp/dev/tmp/prof/w6-camera-free-a500/`. Each CPU is checked against its
own observed camera inputs and exact CIA funding; this is not a whole-world
cross-CPU state comparison. Both live audits pass all 35 selected timing hooks,
thirteen disabled sim ranges and clock/FIFO/pause counters 426/512/1. Static
audit reports 48 sim ranges and zero errors. All 116 host tests pass, including
word/angle wrap and deliberately corrupted native records. Normal/developer
hashes remain byte-identical to W5. Both owned emulators are quit.

This checkpoint does not establish all camera behavior. Orbit/zoom/translation,
F-key view changes, mode transitions, native mission-tape playback, modal/restart
combinations and service cost remain integration gates. Preserving the tape
packet format/call does not establish replay equivalence when camera updates
occur between world ticks. Automatic mission-menu and other timed effects,
Time Compress, interpolated rendering, full world-state equality and measured
capacity remain open W6 work. The player verified mask remains unchanged.


## Time Compress funding integration

The VERIFY timing path now samples the native compression flag at `h3:045a6`
when funding each new CIA boundary. Clear requests 1× and set requests 8×.
The exact world-phase kernel applies that multiplier to primary credit only;
secondary service credit and message deadlines retain their existing active-time
policies. An already-funded boundary is drained before another is funded, so a
world-step transition cannot rewrite credit or input for its remaining due ticks.
There is no new wall-time publication queue for this flag: its identified native runtime
writers are the world command/situation pass, rather than a physical-input IRQ.

The native initializer clears the flag at `sim:00402`. Command 13 toggles it at
`sim:00f48–00f54`; the native world input builder maps unmodified raw key 51
through `sim:1e9c0/1e9ea` to that command. The situation checks at
`sim:00f60–00f7a` may clear the request. These command and cancellation rules
remain native. Their player-input and automatic-cancellation behavior still
needs live acceptance coverage.

Two byte-checked hooks remove the old timing policy under W6 ownership:

- `sim:00eca`: bypass the elapsed=500 overwrite of both native clocks, then
  continue at `sim:00ee0` through the original compression notification API.
- `sim:21dae`: clear the old seven-of-eight suppression selector while retaining
  the cycle-budget local. That selector previously zeroed continuous controls at
  `sim:21de6` as well as suppressing drawing. W6's debt-aware draw gate now owns
  render skipping; hidden ticks still receive their assigned controls.

Outside timing ownership the displaced instructions retain their native behavior.
The new ranges are VERIFY-only, under CUSTOM2 bit 13, and apply only to sim v1.

CUSTOM5 bit 28 is an isolated correctness fixture. After input handoff it uses
CPU writes to force the compression flag for fixture-relative world steps 5–34
at the draw gate, after native command/situation processing. It changes no clock,
phase or input state. This deliberately overrides native eligibility; it is not
an input, mission, capacity or performance test. Its native writes avoid relying
on debugger writes to cached memory. Earlier debugger-written fixture attempts
never observed an active compression flag and provide no compression coverage.

`compression_clock.py` checks observed per-CIA funding against exact rational
arithmetic, retained phase, cursor continuity, 1×/8× selection and the independent
secondary accumulator. Its corruption tests include changed phase limbs,
multiplier, due counts and missing drain. Host tests also exercise CIA wrap,
Time Scale transitions and multiple world ticks funded by one CIA boundary.
Frozen VERIFY text is 140,630 bytes, SHA256
`dbd7e8ed4bb01e8bdcae7bd8585a98ec312aeacceee8e80245311bf4d9b54d0f`.
The cached-68030 fixture passes 160 consecutive CIA boundaries: 132 normal and
28 compressed, with two transitions, 49 funded world ticks and 64 independent
service ticks. Fifty clock-entry/exit pairs preserve primary dt 225 and the prior
secondary dt across the overwritten-clock bypass; fifty observed suppression
locals are zero, including while the compression flag is set. Evidence:
`tmp/dev/tmp/prof/w6-compress-030-r3/`, including `compression.log` and
`compression-result.json`. The live byte audit passes all 37 selected timing
hooks and thirteen disabled ranges; clock/input self-tests remain 426/512.

The same frozen build on A500 passes the same 160-boundary totals (132 normal,
28 compressed, two transitions, 49 world ticks and 64 service ticks), fifty
clock pairs and fifty selector observations. Evidence:
`tmp/dev/tmp/prof/w6-compress-a500/`. Its live audit also passes 37 selected
hooks, thirteen disabled ranges and 426/512 native clock/input checks. These
matching counts prove funding for the observed fixture; they are not a full
cross-CPU simulation-state comparison.

Static hook audit passes 50 ranges with zero errors; all 118 host tests pass.
Normal/developer builds remain byte-identical to W5. The native entry/exit rules,
held controls during actual accepted compression, same-boundary command handling,
modal transitions, sound delivery, game-state equality and compression capacity
remain acceptance gates. No player W6 promotion or performance claim follows
from this synthetic funding fixture.


## Presentation mutation inventory: first native drawing window

The first read-only inventory uses the frozen 140,630-byte VERIFY build above,
CUSTOM2=8192, with no synthetic compression/input/camera fixture. Complete
configured RAM banks are retained before and after the outer draw at
`sim:0056c`, and separately around its `sim:2c552` 3D pass, for three consecutive
native drawing opportunities. The capture stops at actual caller return
addresses; it does not call drawing artificially or write game state. Evidence:
`tmp/dev/tmp/prof/w6-render-mutations-030/`, `render-mutations.json` and
`render-mutation-report.json`.

| Native draw | Listed objects | Changed h3 bytes, outer draw | Changed h3 bytes, 3D pass | Changed player bytes |
| --- | ---: | ---: | ---: | ---: |
| 0 | 50 | 407 | 353 | 0 |
| 1 | 58 | 433 | 359 | 0 |
| 2 | 58 | 354 | 348 | 0 |

The complete 280-byte player object is unchanged across each interval. All
listed normal object pose prefixes (bytes 0–25), compact prefixes (bytes 0–9)
and normal callback pointers are also unchanged at those boundaries. This does
**not** establish render purity. The report keeps all other RAM changes,
including graphics buffers, stacks, IRQ activity and unidentified heap data;
no arbitrary address ranges are discarded as noise.

One particularly relevant net mutation is the normal object at `h3:0129c`.
Its projection-cache extension changes by four, three and five bytes respectively.
A hardware watchpoint during a further 3D pass identifies `sim:2c700` as a writer
(`watch-12c4.log`). Static inspection establishes the full behavior for objects
whose flag byte has bit 3 set:

- `sim:2c6f6–2c704` copies three transformed-coordinate longs to object bytes
  40–51; this explains the observed changes at `h3:012c4–012cf`.
- `sim:2c70a` clears object flag bit 2. If projection passes the clipping checks,
  `sim:2c780–2c798` stores the projection scale and screen coordinates at bytes
  34–39, and `sim:2c79c` sets bit 2 again.
- These are writes through the actual object pointer, not only global rendering
  scratch space. Pose restoration alone would miss them. Whether any later
  world consumer relies on these results is still an audit item; do not infer
  gameplay independence from the unchanged pose prefixes.

There are also confirmed transient writes invisible to a boundary-only diff.
The first list contains sixteen callback pointers to `sim:0db70`, two to
`sim:0e0ec`, and one to `sim:0f984`. The renderer dispatches object callbacks at
`sim:2c7b8/2c7de` according to flag bit 1. `sim:0db70/0db9e` temporarily changes
that bit and the callback pointer, and sets/clears `h3:04c7c` around drawing.
Thus an unchanged final callback pointer does not mean it was never modified.
The `sim:0e0ec` path can change model data through object byte-30's pointer and
calls the native model-color helper; its untouched branches and model consumers
need further audit. `sim:0f984` reads the camera object's position through
`h3:08d72`, so swapping only the visible-object list would leave this callback
using an inconsistent camera for interpolation.

The outer draw also changes the native object-list order at `h3:07dc8`, buffer
selection/dirty state around `h3:0711c`, and cockpit/redraw counters. These are
not a reason to roll back the whole h3 allocation: that would undo valid buffer
publication and concurrent IRQ progress. The implementation needs explicit
ownership: interpolated object/camera poses and their projection caches must
not leak into the next world tick, while native rendering buffers and drawing
bookkeeping must retain their legitimate changes. Identifying all cache readers,
callback writes and temporary-pose readers comes before enabling render-only
iterations. The world-step path still needs an equal-tick state comparison
under omitted as well as extra renders.

`render_mutations.py` reproduces the inventory from saved full-bank snapshots.
It reports every changed RAM range and separately checks h3, the player, listed
poses, callback pointers and the bit-3 projection extension. It rejects missing
or overlapping RAM snapshots and out-of-bank object reads. Its tests inject
changes in each compared object class and in otherwise unclassified memory.
This is an initial three-draw cockpit window, not a complete mutation audit,
heap-equivalence proof, interpolated-render implementation or FPS measurement.


## Native interpolation arithmetic

`time-present-core.s` implements three presentation-only arithmetic helpers.
They are compiled only in VERIFY and self-tested during CUSTOM2 bit 13 setup;
no render-only iteration or interpolated object write is enabled by this
checkpoint. The simulation kernel and physics arithmetic are unchanged.

- Signed 32-bit positions use `old + floor((new-old)*fraction/65536)` with an
  inclusive Q16 fraction range 0–65536. The endpoint difference can require
  33 signed bits. The 68000 routine uses a 32-bit unsigned magnitude and two
  16×16 unsigned products, retaining the low product remainder for negative
  floor rounding. It therefore handles opposite signed-long extremes without
  wrapping the difference or producing an out-of-range interpolated position.
- Unsigned 16-bit angles use the signed shortest wrapped difference. Exactly
  half a turn chooses the negative arc deterministically. The final angle
  wraps modulo 65536; both endpoints are exact. This is the native angle
  representation, not a newly imposed degrees conversion.
- The blend fraction is `floor(world_phase*65536/world_threshold)`, computed
  using sixteen binary-division steps on a private register copy of the four
  clock-phase longs. The caller must first drain all due world ticks and supply
  a phase below the threshold. The phase itself is not changed. This preserves
  the exact simulation clock and quantizes only visual interpolation.

`presentation_math.py` supplies an independent rational oracle and reproducible
native vectors. The host tests cover signed extremes, negative rounding, exact
endpoints, angle wrap/half-turn policy, every possible angle delta at the final
endpoint, phase bounds/monotonicity and generated-source equivalence. The actual
68000 self-test checks 638 position/angle cases and 133 four-long phase cases.
It also checks preservation of scalar input registers and the phase pointer.

Frozen VERIFY text is 156,498 bytes, SHA256
`37569a11eb2ac307bd3da9568f0a59fb1d123e85fea696595dfaa1315c410ab5`.
A500 reaches flight with all 638/133 interpolation cases passing, together
with the existing 426 clock and 512 input cases. Its live byte audit passes
37 selected timing hooks and thirteen disabled ranges. Evidence:
`tmp/dev/tmp/prof/w6-present-math-a500/`, including `selftest-result.json`.
Static audit remains 50 ranges and zero errors; all 124 host tests pass.
Normal and developer binaries remain byte-identical to W5.

This proves the exercised arithmetic, not rendering integration. The unfinished
work includes lifecycle-safe pose snapshots, cache/callback isolation, coherent
camera interpolation, render-only loop dispatch, one-field publication under
W6, visual/latency measurements and complete equal-world-tick state comparisons.

A subsequent read-watch probe on the known projection-cache longs was explicitly
interrupted after the client timed out. The recovered debugger counter is zero
completed world boundaries (`projection-reader-interrupted.txt` in the A500
capture). It supplies no reader-coverage evidence and does not close the cache
consumer audit. The independently completed arithmetic/byte-audit results above
are retained; the owned emulator was paused and then quit.


## Projection-cache ownership around native drawing

The next VERIFY-only, CUSTOM2 bit 13 checkpoint brackets the complete native
outer draw at `sim:0056c` and `sim:00b16`. At `sim:2c55a`, after replaying the
original argument loads, it saves the listed normal objects with flag bit 3.
Compact objects (flag bit 6) have a different layout and are excluded. Each
28-byte record holds the object pointer, original flag byte, callback pointer
at byte 26, and eighteen projection bytes at offsets 34–51. The capacity is
512 listed objects; invalid counts and nested ownership abort explicitly.

The full outer draw retains access to its freshly computed cache, including
HUD consumers after the 3D pass. On outer return, the hook restores only these
named fields and clears ownership. It preserves the native return value and
stack frame. It does not roll back h3, framebuffers, buffer publication, clocks,
IRQ progress or unrelated object fields. The return hook reproduces native
NZVC from the return value; full CCR equivalence is not claimed. This is still
an experimental isolation step: cache consumers, callbacks and model writes
need complete review and equal-world-tick validation before player use.

`presentation_state.py` independently constructs the exact saved records from
full RAM snapshots. It compares those records and the active/count header with
native memory at 3D return, then checks field restoration and cleared ownership
at outer return. It requires an actual native cache mutation before restoration,
so an unchanged or unexecuted path cannot pass vacuously. Host tests cover
selection, compact exclusion, capacity, duplicate pointers, empty lists,
malformed records and preservation of unrelated memory changes.

Frozen VERIFY text is 171,286 bytes, SHA256
`88ddd7cb9a7dac7b64d05bc5e5b0ed1bd9f5a55d3cbb0d6eea2bb6d82dd06b14`.
Evidence directories are `tmp/dev/tmp/prof/w6-present-state-a500/` and
`tmp/dev/tmp/prof/w6-present-state-030-r3/`. Each contains three complete native
draws: A500 lists 58/64/55 objects and cached 68030 lists 50/58/58. Each draw
contains one eligible cache object, an actual projection mutation and an exact
restoration; all six native records match the byte model. The 68030 collector
also checks the stack pointer at both native returns. The A500 collector did
not yet contain those explicit stack assertions.

Both machines pass forty selected timing-hook checks and thirteen disabled
ranges, plus the 426 clock, 512 input, 638 position/angle and 133 phase native
self-tests. Static audit covers 53 ranges with zero errors; all 126 host tests
pass. Normal and developer binaries remain byte-identical to W5.

This three-draw window per CPU does not establish coverage of all clipped
objects, callbacks, model mutations, object lifecycles or indirect cache readers.
It adds no interpolated poses or render-only iterations and supplies no FPS,
capacity or complete gameplay-convergence result. Those acceptance gates remain
open; the player timing option remains disabled.


## Shared aircraft-model drawing writes

The callback at `sim:0e0ec` has a second ownership domain beyond object
projection caches. After its aircraft-type lookup and early exit, it writes
byte 2 of the shared model referenced by object byte 30. The default write is
`sim:0e12a`; player/custom variant branches replace it at `sim:0e156/0e1ac`.
It selects six color indices from the player configuration, a matching variant
record or the aircraft default and passes them to `sim:0dee2` at `sim:0e1d8`.
These choices depend on aircraft configuration, not interpolated coordinates.

The color helper searches 50-byte records at `h3:04c80`, with count at
`h3:01014`, for the object's model ID. Its six cached color words at record
bytes 14–25 are written at `sim:0df42`. For a changed group it traverses that
record's polygon-offset list and writes polygon bytes 4 and 3 at
`sim:0df92/0df96`. The model resolver is `sim:398aa` through the `sim:0f626`
thunk: it scans 12-byte banks referenced by `h3:04262`, counted at `h3:0426a`,
and subtracts each bank's unsigned 16-bit model count until it finds the ID.
This identifies concrete shared heap/model writes that object-only restoration
cannot cover. It does not establish whether simulation consumers read them.

`render_model_state.py` follows those tables in the full retained RAM snapshots
and enumerates a conservative potential write set for listed aircraft callbacks,
including locations whose values do not change. It deduplicates shared model
locations and rejects inaccessible snapshot reads or a missing model in a
matching color record. It deliberately does not infer callback execution,
visibility, branch coverage or transient values from the final snapshots.
The native color helper reuses its loop counter inside a matching record;
the inventory scans all matching records conservatively rather than claiming
to model that instruction ordering.

On the frozen `88ddd7cb9a7d…` projection-ownership candidate above, all three
draws per CPU contain 147 distinct potential fields: two model variant bytes,
twelve cached color words and 133 pairs of polygon color bytes. None differs
at 3D or outer return in either retained window. The evidence is `model-state.json`
in both projection-ownership capture directories. This is not proof that no
writes occurred; for example the variant callback first stores its default and
can replace it before returning. Three host tests cover bank lookup/subtraction,
missing models, shared-location deduplication, exact field offsets and early
exits. All 129 host tests pass.

The next implementation should journal original values at the actual model
write sites while the outer draw owns presentation state, then restore them
at outer return. Recording actual writes avoids scanning every model polygon
on every frame and handles shared models whose callback runs more than once.
Repeated writes must restore in reverse order or save each original only once.
The journal needs an explicit capacity failure, native validation of each branch,
and consumer review; it is not implemented by this inventory checkpoint.


## Shared-model undo journal

`time-present-model.s` adds five byte-checked hooks under VERIFY timing bit 13
for sim v1 only. They cover the default/player/custom variant stores at
`sim:0e128/0e150/0e1a6`, the cached color store at `sim:0df3e`, and both polygon
color bytes at `sim:0df92`. Each wrapper records the destination's original
value while the outer draw owns presentation state, then replays the displaced
native instructions. The relocated operand at `sim:0e152` is checked against
`h3:04e16` during installation.

The 4,096-entry journal uses eight bytes per record: destination pointer, two
old-value bytes and a one/two-byte length. Reads and undo stores are bytewise,
so odd-address polygon fields are supported on 68000. Outer return applies
records in reverse order and clears the count. This handles duplicate writes,
shared models and overlapping byte/word stores without losing the first value.
Capacity overflow aborts explicitly. No full-memory rollback is used. The
journal preserves registers and the X flag; displaced instructions establish
their native result flags. Address construction in older VERIFY observers now
uses nearby bases plus long offsets where the larger build exceeds PC-relative
68000 displacement reach.

A native installation self-test applies three repeated/overlapping writes,
including a two-byte write at an odd address, verifies exact restoration and
checks that inactive ownership records nothing. `model_journal.py` independently
decodes captured records, checks their first values against outer-entry RAM,
checks reverse-undo ordering and verifies restored memory and an empty journal
at outer return. Host tests reject malformed/oversized records and test the
same overlap semantics. All 131 host tests pass; static audit covers 58 ranges
with zero errors. Normal and developer hashes remain identical to W5.

Frozen VERIFY text is 204,802 bytes, SHA256
`e9dbbc25c6d25207b63194e56efc36db3f6c6192bc2796f9c2c412f086b22ac7`.
The cached-68030 capture `tmp/dev/tmp/prof/w6-model-journal-030/` contains three
native draws with 50/58/58 listed objects. Each records two writes to one
shared-model byte; its first value matches outer-entry RAM and is restored
at outer return. All three projection-cache records also restore correctly.
The native overlap self-test passes, as do 45 selected timing-hook checks,
thirteen disabled ranges and the 426/512/638/133 arithmetic/input self-tests.
Both captured return stack pointers pass the collector's checks.
The matching A500 capture `tmp/dev/tmp/prof/w6-model-journal-a500/` also passes
all of these checks: its three draws list 58/63/55 objects, and each journals
two writes to one byte, restores that byte, clears the journal and restores
its projection cache. Both native return stack pointers are checked there too.

This exercised window does not prove the player/custom variant and changed-color
branches individually. Live polygon/color-cache restoration, journal capacity
stress, callback flag/pointer pairs, indirect simulation consumers, full renderer
mutation coverage and equal-world-tick comparisons remain open. No interpolated
frames or performance result are claimed at this checkpoint.


## Pose history: registry and lifecycle contract

The primary persistent drawing-object registry has a word count at `h3:0859e`
and pointer array at `h3:085a0`. It is distinct from the filtered/reordered
render list at `h3:07dc8`. Registration at `sim:0fdbc` checks both list counts
against 500, marks object byte 1 bit 7 and appends the pointer to both arrays.
Its successful registry store is at `sim:0fe20`; failed registration returns
zero without adding an object. Removal at `sim:0feca` clears the membership bit,
finds the pointer and fills its slot with the final registry element before
reducing the count (`sim:0ff06–0ff18`). It removes the render-list entry separately.
`sim:29914` clears both arrays/counts and the camera context for initialization.

The scene builder `sim:0f01c` constructs/caches scenery candidates, then appends
the persistent registry at `sim:0f5cc–0f5ec`. Later outer-draw helpers filter and
sort those candidates. Consequently, render order and visibility cannot serve
as object identity or determine which moving objects receive pose snapshots.
The successful add and removal paths are concrete lifecycle-observer sites;
events must be tracked even when removal and reuse happen within one world tick.
Pointer equality, unchanged model ID and a still-set active flag are not enough
to distinguish those lifetimes. Scenery enumeration also writes visibility and
model-selection data (`sim:0f55c/0f572/0f58e/0f5ae`); this extends the outstanding
render-mutation/consumer audit beyond the aircraft callback journal.

`pose_history.py` defines the executable host reference for the upcoming native
pose integration. It snapshots the normal-object pose payload (three signed
long positions at bytes 8–19 and three wrapped word angles at bytes 20–25),
paired only across consecutive completed world tick IDs, including unsigned
32-bit tick wrap. Registry add assigns a new generation, removal ends it, and
an explicit teleport/discontinuity renews it. Pairing requires the same pointer,
generation and model ID. New/reused objects snap to their current pose; removed
objects are never written through stale pointers. The model uses the independent
rational interpolation helpers already checked against native arithmetic.

A view change invalidates the pose pair immediately, including between ticks.
Mission reset clears the pair and membership. A temporary presentation lease
preflights all target poses, writes only their pose payloads and restores them
on exit, including a failed draw. Lifecycle/world updates during the lease are
rejected; unrelated drawing or IRQ memory changes survive restoration. A camera
pose modified since capture is rejected instead of silently mixing service-clock
motion with a world-clock snapshot. A separate coherent camera-service history
is still needed for that case. The host generation counter is unbounded; native
integration must explicitly handle token exhaustion without aliasing a lifetime.

Retained `pose-registry.json` inventories in `w6-model-journal-030/` and
`w6-model-journal-a500/` use the frozen journal build above. At the three
outer-entry snapshots, cached 68030 has 25/33/33 registered objects and A500
has 33/37/29. Every registered entry has the normal layout in these windows;
the camera pointer from `h3:08d72` is registered in every snapshot. The changing
counts demonstrate why creation/removal cannot be ignored. These draw snapshots
are not consecutive world-tick captures and contain no lifecycle event log;
they cannot validate interpolation continuity or rule out same-address reuse.

Seven new host tests cover pose restoration, angle wrap, unrelated progress,
exception cleanup, same-address reuse, teleport, model/view changes, between-tick
view changes, tick wrap, stale camera detection, registry reordering and invalid
registry entries. All 138 host tests pass. This checkpoint does not add native
pose snapshots or interpolated frames. Remaining work includes native lifecycle
hooks, complete-tick snapshot boundaries, nonregistered camera handling, all
moving-object/compact-layout coverage, explicit teleport/mission transitions,
and validation against live lifecycle events before interpolation is enabled.


## Native consecutive pose snapshots

`time-poses.s` now captures the registered normal-object poses in VERIFY timing
mode. The call is at native loop re-entry before funding the next update;
the previous iteration has completed its world work, post-draw bookkeeping,
sound/tape service and any remaining loop-local countdown work. Mission entry
explicitly clears snapshot readiness; tick zero alone does not imply a new
mission. Subsequent captures require consecutive completed world-step IDs with
unsigned-long wrap. The wrap branch is implemented but a native wrap fixture
remains to be exercised. This does not move any simulation work into drawing.

Two 500-entry arrays retain current and previous records. Each 26-byte record
contains pointer, validity word, model ID and the eighteen pose bytes. Successful
add at `sim:0fe1e` and removal at `sim:0fed2` are byte-checked hooks that clear
validity in both arrays for that address, preserving the native displaced
instructions and flags. This represents lifetime discontinuity for the retained
pair without a wrapping generation token: remove/add at the same address cannot
reuse a valid previous pose. Future interpolation must require both validity
words and model IDs to match. New snapshots mark the currently registered poses
valid; invalidation cannot erase their saved position/angle bytes.

The 36-byte header records both counts/tick IDs, camera pointers from
`h3:08d72`, view modes from `h3:06712`, lifecycle-event and capture counts.
A camera-pointer/view-mode change between captures removes the previous pair.
This boundary check is not the final immediate view-change handling: native
teleport hooks, between-tick view transitions and independently updated camera
poses still need explicit treatment before interpolation is enabled. A null,
odd, compact-layout pointer or count above 500 aborts the VERIFY candidate.
The host checker additionally rejects duplicate registry pointers.

`native_poses.py` checks current record bytes against the live registry and
poses in each full-bank snapshot. Across consecutive captures it independently
copies the prior expected records, invalidates addresses from the debugger's
actual lifecycle-event log, and compares the entire native previous array. It
checks both view metadata sets, completed tick IDs, counters and the number of
observed lifecycle events. A capture without actual invalidation cannot pass.
The first captured boundary establishes the baseline and its earlier event
history is not credited toward the comparison.

Frozen VERIFY text is 231,508 bytes, SHA256
`2aa929eafd6014881feb55d094c9d78b1020738857e3f3890c02412890244697`.
`tmp/dev/tmp/prof/w6-poses-a500-r2/` and
`tmp/dev/tmp/prof/w6-poses-030-r2/` each pass sixteen consecutive completed
boundaries 40–55, with 504 current poses checked, fifty intervening lifecycle
events and 24 invalidated previous records per CPU. These counts do not by
themselves establish cross-CPU whole-game state equivalence. The 47 selected timing hooks and thirteen
disabled ranges pass the live byte audit; native 426/512/638/133 arithmetic/input
checks also pass. Static audit covers sixty ranges without errors; all 139 host
tests pass. Normal and developer builds retain the W5 hashes.

The snapshot arrays do not yet drive drawing. This is native registered-pose
and observed lifecycle evidence, not complete moving-object coverage, teleport
acceptance, coherent free-camera interpolation, smooth 50 FPS or equal-world-tick
gameplay convergence. Journal colour branches and remaining render-state
consumers remain separate open checks.


## Native candidate interpolation buffer

`time-pose-blend.s` now builds a separate 26-byte-per-object output table from
the native current/previous pose snapshots. It resolves previous records by
address, requires both validity words and matching model IDs, and otherwise
copies the current pose unchanged. Valid pairs use the verified signed-position
floor interpolation and shortest wrapped-angle arithmetic. The Q16 fraction
comes from the exact four-long world phase through the verified phase helper;
neither the phase nor native game-object poses are written by this routine.
The output includes count, fraction, blended/snapped counts and a ready flag.

For this integration check the builder runs after each completed-tick snapshot.
That is not yet the render-time invocation: the scheduler must first observe
elapsed time, drain due world work and then rebuild the output for the actual
render fraction. Native drawing currently happens before the completed-tick
snapshot, so it cannot safely consume this table at its existing call site.
The next render-phase change must defer drawing until the completed world state
is available, preserve native post-world bookkeeping and move dirty-countdown
consumption with actual publications. Independently updated camera poses still
need coherent ownership and interpolation before the general render path can
consume the table. The new buffer is not published or leased into game memory.

`native_pose_blend.py` independently derives the fraction from the captured exact
phase and computes every output record with the rational host helpers. It checks
all header fields and output bytes, and requires both interpolated and snapped
objects and at least one pose whose output differs from current state. Tests
cover signed negative rounding, angle wrap, reordered previous records,
lifecycle invalidation, model changes, absent previous records and malformed
or duplicate-address tables.

Frozen VERIFY text is 244,784 bytes, SHA256
`d3df931594c9d1519d3a00e7c10b3455ba39adc741a346f8764bd3fac153f8ab`.
The A500 capture `tmp/dev/tmp/prof/w6-pose-blend-a500/` passes sixteen completed
boundaries with 504 candidate poses: 478 interpolate and 26 snap; 414 output
poses differ from the current pose. Every output byte and Q16 fraction matches
the independent oracle. The underlying consecutive snapshots, fifty lifecycle
events and 24 invalidations still pass, together with 47 timing-hook checks,
thirteen disabled ranges and the 426/512/638/133 native self-tests.
The cached-68030 capture `tmp/dev/tmp/prof/w6-pose-blend-030/` passes the
same checks and object counts: 478 blended, 26 snapped and 414 changed poses
out of 504. Its observed fractions differ from A500 because capture-time clock
credit differs; each output is checked against its own exact phase, not against
the other machine's visual pose.
All 141 host tests pass; the sixty-range static audit has no errors. Normal and
developer binaries retain the W5 hashes.

This validates the candidate buffer, not interpolated frames, render-phase
integration, all camera/view transitions, visual cadence, latency, sustained
simulation speed or gameplay convergence. Those gates remain open.


## Cockpit render-phase integration

`time-render.s` now runs native drawing from the scheduler's no-world-work-due
path after completed-tick snapshots. The old draw site at `sim:21e7a` always
defers its draw and dirty-countdown work in timing mode; the rest of the native
iteration still runs before loop re-entry. After observing elapsed time, the
scheduler consumes due world work first, otherwise draws and polls again.
`TIME_LOOP_DRAWS` counts actual calls in this new phase. At this checkpoint,
`TIME_LOOP_SKIPS` counted cases where debt was already due at the former draw
site; the automatic-menu checkpoint below changes it to count every deferred
legacy draw site. A mission starts
rendering only after its first world iteration has reached that site.

For view mode zero, the render phase preflights the registered poses/model IDs
against the immutable current snapshot and requires the camera pointer to be
among them. It rebuilds candidate poses from the current exact phase, leases
only object bytes 8–25, calls the complete native outer draw at `sim:0056c`,
then restores those bytes. The existing projection-cache and shared-model undo
hooks remain inside the outer draw. A lifecycle mutation while poses are leased
aborts the VERIFY candidate. Only after restoration does the phase consume the
native outer dirty countdown once, using its original signed clamp. The native
stack arguments remain the dirty count followed by one. Other camera modes or
failed preflight use current native poses; this fallback is an unfinished camera
integration path, not acceptance of smooth presentation in those views.

This verification uses CUSTOM2=8960: timing bit 13 plus W5 safe publication and
its existing two-field cap. The required W6 one-field policy is not implemented
by this checkpoint, and timing bit 13 alone does not implicitly install W5.
The player build remains unchanged. Candidate construction now runs only at
draw time; the redundant calculation after every completed world snapshot has
been removed.

`render_phase.py` independently checks the full render-time candidate buffer,
the actual borrowed poses just before native drawing, and exact pose restoration
afterward. It checks that clock credit/cursor, due counts, world steps and skip
counts are unchanged within drawing, that no native world-update entry was
observed, that the stack layout is restored, and that the draw and dirty counters
advance exactly once. Pose, projection and model ownership must all be released.
Its dirty-countdown test includes the signed-word negative-overflow boundary.
This is scoped pose/state ownership evidence, not a full simulation-heap audit.

Frozen VERIFY text is 245,192 bytes, SHA256
`a3a62e69d3ac5db0128dbc2bcd1dc79d3b59055617a61ed6c6cf3769aca4d128`.
`tmp/dev/tmp/prof/w6-render-phase-030/` passes four actual cockpit draws at world
ticks 41–44: 132 leased poses, including 108 whose visual pose differs from the
simulation pose. No world update executes within these draws, all pose bytes
restore, and the clock, dirty-countdown, stack and ownership checks pass.
The retained `cockpit.png` shows the cockpit rendering after these checks; a
single image does not establish visual cadence or absence of every artifact.
An exploratory comparison of registered model IDs and pose payloads against
the prior candidate-only 68030 capture at those four tick IDs finds all 132 equal.
That comparison excludes pointers and does not cover complete object state,
global state, RNG, events or acquired inputs, so it does not close gameplay
convergence. The independent interpolation/restoration checks remain primary.

The live audit passes fifty selected hooks (47 timing and three W5) with ten
remaining disabled ranges. Existing 426/512/638/133 native self-tests pass.
All 142 host tests pass and the sixty-range static hook audit has zero errors;
normal/developer binaries retain W5 hashes. Render-only repeated ticks, all
camera modes, native colour-changing journal branches, one-field publication,
full equal-tick state/events, visual latency/cadence and capacity remain open.

### Removing redundant per-tick candidate construction

The first A500 capture retained three valid render leases at ticks 49, 362 and
583 (108 poses, 95 changed visually). The fourth-draw observation timed out.
The recovered live sim layout no longer passed the disabled-byte audit, so that
late audit is not usable evidence for this run. Native self-test counters still
read 426/512/638/133. No reason for the timeout is inferred from that alone.

That candidate unnecessarily calculated interpolation after every world tick
as well as before every draw. Interpolation is now calculated only for drawing.
The revised VERIFY text is 245,188 bytes, SHA256
`0ca5e5919512837a1d50f96738b9d8a07c84d2f1318d4be2944da00cc7cd340f`.
The retained `tmp/dev/tmp/prof/w6-render-phase-a500-r2/` capture passes three
actual draws at completed ticks 45, 108 and 153: 101 poses, 89 changed visually,
with exact pose restoration, no world calls during drawing, and passing clock,
stack, dirty-counter and ownership checks. Fifty selected hooks and ten disabled
ranges pass the live byte audit; all native self-test counters pass.

These sparse A500 draws expose an open capacity concern. They are correctness
observations with debugger interruptions, not a 250-field capacity measurement,
and must not be reported as FPS or proof of real-time gameplay speed. Measure
completed world ticks, debt and actual publications together before making that
claim. The elapsed-time accounting and full equal-tick gameplay-state gates
remain separate from the successful render-pose checks.

The same revised build passes four cached-68030 draws in
`tmp/dev/tmp/prof/w6-render-phase-030-r2/`: ticks 41, 42, 43 and 43, checking
132 poses (108 changed visually). Fractions are 6416, 49339, 28994 and 65147.
The last pair retains byte-identical previous/current pose buffers for all 33
objects and executes no world update between draws. It therefore covers a real
render-only iteration with a changing interpolation fraction. All render-state
checks, fifty selected hooks, ten disabled ranges and native self-tests pass.
This closes that scoped repeated-tick observation, not general gameplay-state
independence or a 50 FPS cadence claim. The 142 host tests and sixty-range static
audit pass. Rebuilt normal/developer binaries retain the W5 hashes.

## W6 one-field publication policy

The VERIFY option resolver now adds bits 8 and 9 to the effective mask whenever
W6 bit 13 is requested. Thus CUSTOM2=8192 installs effective mask 8960: W6 plus
W5's safe beam publication and field counter. Each original hook keeps its
existing single PERF_RANGE owner. Disabled-byte tools must use the effective
mask (8960), not the raw request (8192). Other bits remain independently selected.
Outside W6, the W5 cap stays at two fields. With W6 selected, `pace_flight` uses
one field from the previous actual publication. Neither policy drops elapsed
CIA time; the scheduler observes publication waits when it next polls.
The normal/developer source paths do not acquire the VERIFY timing policy.

`publication_clock.py` verifies safe beam position, modular field spacing and
native world funding across constant-Time-Scale publication intervals. It checks
that completed ticks plus the change in exact fractional phase equal funded CIA
cursor time, requires zero due world work at publication, and reports outstanding
CIA debt separately. This is a scoped clock-accounting check; it does not compare
complete gameplay state or prove sustained CPU capacity.

Frozen VERIFY text is 245,208 bytes, SHA256
`1a0677e18c874809ae0270549b4efbeaae6d778d4d3e210a6f936fafbca7e1b8`.
`tmp/dev/tmp/prof/w6-one-field-030-stress/` requests CUSTOM2=8192 and the compiled
CUSTOM5 fast-draw/wrap fixture. Forty publication observations cross the 32-bit
field-counter wrap; the intervals are 9, 1, then thirty-seven 2-field intervals.
All publications fall within the native safe beam window. The single 1-field
interval demonstrates that the prior two-field minimum is removed. This fixture
still spends enough time outside the skipped 3D pass to produce mostly 2-field
intervals; it is not evidence of real 50 FPS or of the final limiting routine.
Thirty-eight active W6 intervals satisfy exact clock accounting, with 26 repeated
world-tick pairs and observed debt of 2–3 CIA intervals at publication. Fifty
selected hooks, ten disabled ranges and the native self-test counters pass.
The first publication is before W6 loop ownership begins and is excluded from
the world-clock check.

The W5-only control from the same frozen build,
`tmp/dev/tmp/prof/w6-one-field-w5-control/`, requests CUSTOM2=768 with the same
compiled fixture. All 39 intervals across forty publications are exactly two
fields, including field-counter wrap, and all beam positions are safe. Its three
W5 hooks match; all 57 remaining ranges, including every W6 hook, retain their
original relocated bytes. This validates option isolation and the unchanged W5
publication policy without relying on an A/B performance inference.

The real-drawing capture `tmp/dev/tmp/prof/w6-one-field-030-native/` uses
CUSTOM2=8192 without the fast-draw fixture. Three cockpit leases check 99 poses,
including 79 changed visually, with exact restoration and all ownership/clock
checks passing. Twenty subsequent publications have 3–7-field intervals and safe
beam positions; all nineteen intervals satisfy exact native world funding.
Three adjacent publications share a world tick; observed CIA debt is 4–9 ticks.
The effective mask is 8960, with fifty selected hooks and ten disabled ranges
passing. Native self-tests remain 426/512/638/133. This timing-plus-W5 workload
leaves the other performance bits off and does not establish final-bundle FPS,
steady capacity, full-state convergence or the 50 FPS acceptance target.

All 145 host tests pass; the sixty-range static hook audit has zero errors.
Normal/developer builds retain their W5 hashes. Remaining work includes the
full performance-bundle capacity matrix, frame-cost investigation, all-camera
presentation, full equal-tick gameplay state/events, and the other gameplay and
modal acceptance gates. One-field policy support is implemented; smooth real
50 FPS is still unproven.

## Combined A500 capacity accounting

`time_capacity.py` checks exact native funding at arbitrary profile boundaries,
including already-produced but unstarted due ticks. Completed world work comes
from the last completed pose-snapshot tick; the scheduler's started-tick counter
is reported separately. A boundary may have zero or one world iteration in
progress. The checker rejects modal/rate changes, missing inter-chunk execution,
invalid phase and lost credit. It reports CIA debt rather than equating retained
time with real-time execution capacity. Tests include a deliberately overloaded
sample that conserves funding but completes less than half the newly due work.

The combined A500 capture uses the same frozen `1a0677e1…` build and requests
CUSTOM2=16319. The two adjacent 250-recorded-field windows and complete-call
costs are documented in `profiling.md`. Their boundary intervals cover 505 PAL
fields and 599 CIA ticks: 85 complete world iterations versus 82.6096 newly due,
with unprocessed CIA time changing from 67 to 49 ticks. No time is discarded.
The first window publishes no frame and the second completes two draws. This is
short-window scheduling/capacity evidence, not whole-state convergence, final
frame-rate acceptance, or proof that debt remains bounded indefinitely.

Fifty timing/pacing patch targets and the effective installed mask pass the live
audit. All declared performance ranges are selected in this configuration, so
there is no disabled-range result to claim here; option-off isolation remains
covered by the earlier W5-only control. Native counters remain 426/512/638/133.
The 147 host tests pass. The player/developer source paths are unchanged.

## Exact-field capacity censuses

`field_capacity.py` validates live-counter windows of exactly 250 fields,
retaining independent `sim:3154a` publication observations and message-call
counts. It reuses the completed-work and exact-funding checks in
`time_capacity.py`. A native publication may precede outer-draw completion at
a boundary, so that pair of counts may differ by one; larger discrepancies are
rejected. Beam positions and modular publication spacing are checked directly.
The raw endpoint RAM snapshots allow inspection without rerunning the game.

The cached-68030 combined build and two adjacent windows are documented in
`profiling.md`: 82 completed world iterations, 118 publications, and exact funding
across 500 fields; boundary CIA debt changes 0 → 3 → 0. Fifty timing/pacing targets,
two disabled sim ranges, the effective mask and native self-test counters pass.
This establishes the measured clock/capacity facts only. Full equal-tick gameplay
state/events and the 50 FPS presentation gate remain open.

The 68EC020 combined build also completes 82 world iterations across two exact
250-field windows, publishing 23 and 25 frames (4.6/5.0 FPS). CIA debt changes
0 → 6 → 3 ticks. Each interval conserves exact funding; the bounded world iteration
in progress is reported rather than counted as completed. Fifty timing/pacing
targets, the effective mask and native self-test counters pass. This mask selects
all declared sim ranges, so it provides no disabled-range result. Both CPU
captures retain full RAM endpoints and publication/event logs. Their different
starting tick IDs prohibit using these windows as a full-state convergence test.
All 149 host tests pass. No player or developer code changed in this checkpoint.


## Automatic mission-menu service

The automatic prefix of `sim:21b14` now runs once per funded 128-unit secondary
service tick, with a zero command packet. The original player/threat predicates,
signed-word countdown at `h3:0783e`, menu preparation and result mapping remain
native. Ordinary world-command calls start at `sim:21bbc` after this prefix,
so catch-up iterations cannot advance the automatic countdown again. Before
input ownership, the original entry path remains intact. The new eight-byte
entry hook is VERIFY-only, sim v1, CUSTOM2 bit 13.

Services now execute only on completed-world gate re-entry. The former draw site
always defers; `TIME_LOOP_SKIPS` consequently counts all such deferrals, not debt
observations. A modal return abandons the pre-menu sampled CIA endpoint because
the pause wrapper has rebased the cursor. Native results 2/3 route through
`sim:21d3a` without starting another world iteration; ordinary result 4 continues.
The secondary clock is restored after each service. `automatic_menu.py` models
the predicate, signed subtraction, zero boundary, reload and result mapping.

Frozen VERIFY text is 245,892 bytes, SHA256
`c59f4909f124e96a747974c3272750fce06883a1f691ce7d6d372fcb27f39cb2`.
The compiled CUSTOM5 bit-29 fixture forces eligibility, primes a 128-unit timer,
and substitutes menu choices 0 then 5 inside the real pause wrapper. Both
`tmp/dev/tmp/prof/w6-auto-fixture-a500/` and
`tmp/dev/tmp/prof/w6-auto-fixture-030/` observe the same sequence:

- Four native subtractions of 128, with pre-subtraction values 128, 0, 128, 0.
- Return/timer pairs (4, 0), (4, 10000), (4, 0), (3, 10000).
- Every service observes a completed world boundary. The exit occurs at tick 41
  without another world update; native frame stack position and exit result
  match, and timing/input ownership clears through the original exit hook.

This validates controlled countdown, cancellation-like continuation, modal
rebasing and one native mission-exit route. It does not exercise the actual menu
UI, naturally changing eligibility, or native result 2. An earlier register-only
debugger probe produced no valid countdown observations and is not evidence.

The ordinary cached-68030 capture `tmp/dev/tmp/prof/w6-auto-normal-030/`, without
that fixture, observes 120 service calls at alternating 2/3 active CIA intervals.
All run at completed-world boundaries; none is eligible to decrement the timer.
Three real cockpit draws check 113 poses, including 92 changed visual poses,
against the interpolation/restoration model. A subsequent exact 250-field window
conserves funding and completes 40 world ticks against 40.8221 newly nominal,
with CIA debt changing 1 to 4. It publishes 57 frames (11.4 FPS), with no message
start/shorten calls. This is timing plus W5 only, not the combined performance
mask; it supplies no cross-build gain or full gameplay-state convergence claim.
Earlier capacity tables retain their explicitly named historical build.

All three selected captures pass 51 live timing/pacing targets and ten disabled
ranges. Native self-tests pass 426 clock, 512 input, 638 position/angle and 133
phase vectors. The player/developer hashes remain unchanged from W5.

Code growth exposed a signed patch-list displacement overflow that vasm accepted:
an early candidate failed in `resload_Patch` before entering flight. A nearby
register/flag-preserving bridge now reaches the VBlank observer. Distant VERIFY
option reads also use full-range address construction. `audit_patch_reach.py`
checks emitted signed-word destinations against listing symbols: 118 VERIFY and
58 per player/developer build, zero errors. Its regression cases include the
out-of-range word that assembles successfully. All 156 host tests pass.
The same-build W5-only control (`tmp/dev/tmp/prof/w6-auto-off-020/`,
CUSTOM2=768) passes the three selected W5 hooks and all 58 disabled ranges,
including the new automatic-menu entry. The static sim audit checks 61 ranges
with zero errors.

Full gameplay-state/events/RNG comparison across render schedules, natural menu
and modal transitions, all-camera presentation, sustained capacity and real
smooth 50 FPS remain open. No player timing enablement is claimed.


## Equal-tick normal/no-render diagnostic

A VERIFY-only CUSTOM5 bit-30 fixture returns from `time_render_frame` before
interpolation and native drawing. It does not change the clock, discard due
updates, or advance dirty-buffer counters. Use it with deferred installation
(CUSTOM5 bit 9) so the route and initial native flight state precede selection.
It is an experiment for schedule independence, not a player setting or a
performance workload. The ordinary route uses the same binary without bit 30.

Frozen VERIFY text is 245,910 bytes, SHA256
`8081382dfd28084bbce17f46106c4686acf2cf7c07abc2a5dee2bd7a9fca68e5`.
The two cached-68030 captures are
`tmp/dev/tmp/prof/w6-state-normal-030/` and
`tmp/dev/tmp/prof/w6-state-none-030/`, both requesting CUSTOM2=8192. Complete RAM
banks are retained at the pre-install flight anchor and at completed ticks 0–11.
No controls are injected in this short initial-flight window.

`world_comparison.py` inventories every differing byte in captured RAM, plus
complete h3, the 280-byte player object and the 26-byte registered-object prefixes.
It requires the same binary, allocation layout, matched tick IDs and consecutive
sequences. No differing bytes are normalized away. Its output is diagnostic and
supplies no automatic whole-gameplay pass verdict. Regression tests ensure that
an unknown heap difference is still reported when all named regions match, and
that mismatched ticks are rejected.

The initial complete h3 and player bytes match, as do registry and object
prefixes. Chip RAM is identical; fast RAM has 75 differing bytes in twenty ranges.
These remaining initial differences are retained and unclassified, so identical
complete heap state is **not yet established**. At ticks 0 and 1 the compared h3
also matches. From tick 2, rendering introduces 624–709 h3 byte differences
(677 at tick 11). The comparator reports each range with both byte values.

Across all twelve checkpoints the complete player object, registry ordering,
372 registered-object prefixes and observed add/remove event order match. The
ordinary run completes fifteen draws; the no-render run completes zero. This is
useful scoped convergence evidence, but does not cover complete object extents,
other reachable heap objects, RNG, all gameplay events or timestamped controls.
The final raw RAM comparison still has 1,634 differing chip bytes and 1,944
fast bytes; these include drawing, observer and other unclassified state.

Initial source inspection identifies `h3:04e1a` as the comparison-table pointer
written by sorting setup at `sim:0e498` and read by its comparator at `sim:0e448`.
`h3:0a27c` is an indexed table populated at `sim:3a7be–3a7f2` and sorted at
`sim:3a82e–3a87c`. These references guide the remaining ownership audit; they do
not establish that every changed region is harmless or justify excluding it.

The no-render capture passes 51 selected timing/pacing targets, ten disabled
ranges and native self-test counts 426/512/638/133. All 118 emitted VERIFY patch
destinations fit their signed words. Four new inventory tests pass. Both owned
emulators were quit. Next: classify initial differences and complete simulation
allocation extents, then extend equal-tick comparisons with delayed drawing,
real input/events and the other acceptance scenarios. W6 remains VERIFY-only.


## Complete allocation and executable-state inventory

`game_heap.py` follows the supported sim v1 allocation chain at `h3:04138`.
The allocator at `sim:2d1ee` adds an eight-byte header at `sim:2d214`, records
size including that header, links the previous head at `sim:2d22c`, and returns
the payload eight bytes later. The free path `sim:2d27e–2d2fa` unlinks and frees
the same extent. The reader rejects cycles, overlapping extents, short headers
and truncated allocations. It does not infer object lengths from pointer spacing.
It also follows the four executable segment links and verifies each size against
the original sim v1 HUNK_HEADER before comparing their entire contents.

This expands `world_comparison.py` beyond active object prefixes: inactive pool
records, pointed-to model/resource allocations, allocation headers and embedded
mutable executable data are included. Unknown differences remain in the report.
Every compared boundary also retains its native clocks, and consecutive intervals
must satisfy the existing independent exact-funding model. This is a constant-rate,
nonmodal comparison; the checker rejects rate/pause transitions in these windows.

Reanalysis of the twelve-boundary `8081382d…` captures finds all four executable
segments and all 105 tracked allocations (243,855 bytes including headers)
identical at the initial checkpoint. The previously reported 75 differing fast
RAM bytes therefore do not occur in these tracked allocations or executable
segments. This establishes the named game's initial allocation/segment equality,
not equality of every OS/library allocation or peripheral state.

Allocation-chain layout remains equal at every recorded tick. Only two payload
bytes ever differ in these allocations: the low bytes of the word at offset 344
in sound contexts 0 and 1 from the table at `h3:0a184`. They are 384-byte payloads,
allocated by the seven-context initialization at `sim:35c00–35c40`. The original
sequencer increments the word at `sim:34e9a`/`sim:34f96`, resets it at
`sim:34eca`/`sim:34f44`, and copies it to the neighbouring saved word at
`sim:3581c`. These are sound-domain differences at different physical observation
times, retained rather than normalized away. No sound code is changed.
All other tracked allocation bytes match across these twelve world boundaries.
The first and third executable segments still contain differences outside h3;
they remain explicitly inventoried alongside h3 rather than silently excluded.

Full gameplay equivalence still requires global-state ownership classification,
ordered gameplay/RNG/event evidence and the input/scene/CPU acceptance matrix.
Complete allocation coverage is not a substitute for those gates.


### Five-second extension and uncovered terrain-cache mutation

The unchanged `8081382d…` binary is also captured at ticks 0–39 in
`tmp/dev/tmp/prof/w6-state-normal-40-030/` and
`tmp/dev/tmp/prof/w6-state-none-40-030/`. All 1,271 registered prefixes, complete
player records and observed lifecycle event order match. Exact funding passes
at every consecutive boundary. Ordinary rendering completes 39 world updates
and 52 draws in 242 fields / 286 CIA ticks, ending with three unprocessed CIA
ticks. No rendering completes the same 39 updates in 239 fields / 283 CIA ticks,
ending without debt. These are equal-tick diagnostic windows, not 250-field
performance measurements or sustained capacity acceptance.

The broader allocation inventory exposes two additional differences:

- At tick 32 the ordinary route has a new 1,800-byte payload (1,808 with header),
  referenced by the message-background table at `h3:044e6`. The native drawing
  path computes its size at `sim:00962`, allocates at `sim:0096e`, stores the
  pointer at `sim:0097a`, and fills the saved background at `sim:009ce`. The
  no-render route never executes this allocation. Do not require identical
  allocation chains after this point or hide the extra block from the report.
- At tick 39 a byte at offset 143 in the 199-byte payload rooted at `h3:054da`
  is FF with rendering and 00 without it. This block is allocated at
  `sim:0ee14` and assigned to static-object records through their offset-30
  pointers at `sim:0ef26`. The terrain visibility path writes zero at
  `sim:0f55c` and FF at `sim:0f572`. These stores are outside the current model
  write journal. Their nearby static-object model selection writes at
  `sim:0f58e` and `sim:0f5ae` also need an ownership review.

Apart from the sound words, this is the first differing byte in an allocation
shared by both runs. It is concrete missing restoration evidence; no assertion
that it is harmless is made. Next work is to cover the terrain cache and related
model-selection writes with exact native replay and restoration checks, then
repeat the comparison. Global scratch/ordering state, RNG and other gameplay
acceptance gates remain open. The no-render endpoint passes the 51 selected
hooks, ten disabled ranges and native self-test counts 426/512/638/133.


### Terrain visibility and model-selection restoration

VERIFY build `2c04ec3a3620092277d101710bf6c8dd267551a2745d75dd3b17c34e8dd377ff`
extends the existing reverse write journal to the terrain visibility stores at
`sim:0f55c` and `sim:0f572`, and the static-object model word at `sim:0f58e`.
The word is saved before its initial selection, covering the later conditional
increment at `sim:0f5ae`. The patch deliberately leaves the incoming branch target
at `sim:0f5b2` intact. Each wrapper replays the original stores and resulting
condition flags; restoration happens at the existing outer drawing return.
The hooks remain sim-v1, VERIFY-only CUSTOM2 bit 13.

Two native self-test cases exercise the actual wrappers with signed negative
indexing, both X states, zero/nonzero model IDs, overlapping visibility writes
and the subsequent model increment. Each checks the native results and flags,
then verifies exact reverse restoration. Both pass (`time_model_terrain_result=2`).
The larger VERIFY image also requires a full-range call to the existing load-segment
observer; its saved-register envelope and inputs remain intact.

The paired cached-68030 captures are retained in
`tmp/dev/tmp/prof/w6-terrain-normal-40-030/` and
`tmp/dev/tmp/prof/w6-terrain-none-40-030/`. They use timing plus W5, deferred
activation and unchanged Time Scale 40. All four executable segments and all 105
tracked allocations (243,855 bytes) match initially. Across ticks 0–39, complete
player records, registry ordering, 1,279 object prefixes and lifecycle event order
match. The terrain allocation now matches at every boundary, including tick 39.
All other shared allocation bytes also match apart from the sound-sequencer word
at payload offset 344 in contexts 0, 1 and 2. The separately identified 1,800-byte
message-background payload still exists only with drawing from tick 32 onward.
No differences are removed from the report.

Ordinary drawing completes 39 updates and 52 draws in 242 PAL fields / 286 CIA
ticks; omitted drawing completes 39 updates in 239 fields / 283 CIA ticks. Final
unprocessed CIA debt is three and zero ticks respectively. Every consecutive
boundary passes exact funding. These are equal-tick correctness diagnostics,
not a 250-field performance claim or sustained simulation-capacity acceptance.
The final h3 comparison still has 901 differing bytes; global ownership,
RNG/gameplay events and the wider input/scene/CPU matrix remain open.

Both endpoints pass all 54 selected timing/pacing targets, ten disabled ranges,
and native core/input/presentation/phase counts 426/512/638/133. All 166 host tests
pass; static checks report 64 ranges and 121 patch destinations with zero errors
(subject to the documented indirect-target limits). Normal and developer slaves
retain their W5 hashes. Both owned emulators were quit. Next is classification of
remaining executable/global differences and the broader acceptance matrix, not
promotion of this VERIFY candidate to players.


### Terrain-cache controls must share the drawing lease

The following audit finds a limitation in the preceding restoration-only build.
The terrain builder at `sim:0f01c`, called through `sim:01522` by the outer draw
at `sim:006dc`, can skip rebuilding at `sim:0f038–0f068`. With no forced refresh,
a positive cached camera height and a sufficiently small camera displacement
let it reuse the prior list and visibility/model selections. Restoring those
selections while retaining a newly populated cache key makes that reuse unsafe.
Equal-world-tick snapshots alone did not test this inter-frame dependency.

The cache-coherent VERIFY candidate is
`b6bc9c0193084fa386f939dde113f6492095006bcb3131d424ce27585ae3a359`.
The existing outer drawing owner now saves `h3:054de–054eb` (three camera-position
longwords and the recomputation flag) and `h3:05270–05271` (view-change countdown).
It sets the cached height to the native invalid value −1 before drawing, forcing
the native builder past its reuse test. On return it restores the controls along
with the visibility/model journal. Native refresh arguments and branch code stay
unchanged; the additional work remains VERIFY bit 13 only. This deliberately
rebuilds terrain on every draw. Its cost must be included in future capacity and
50 FPS measurements; the earlier throughput figures do not establish that budget.
A future reusable presentation cache must own the key and all dependent data
together, without exposing its intermediate state to simulation.

A native self-test overwrites every saved control field after invalidation and
checks exact restoration (`time_terrain_cache_result=1`). Four real consecutive
draws in `tmp/dev/tmp/prof/w6-terrain-cache-030/` each observe the invalid key at
`sim:0f03e`, enter rebuild at `sim:0f06c` once, and never take the reuse return at
`sim:0f066`. The independent `render_phase.py` checker verifies restored controls,
133 original poses, exact funded clock state and no world update during a draw;
107 visual poses change under interpolation. The captured completed ticks are
39, 40, 41 and 43. These observations establish neither visual cadence nor 50 FPS.
The checker also rejects missing rebuilds, reuse and any unrestored control field;
its two new negative tests bring the passing host suite to 168 tests.

The extra VERIFY code moves one mouse-test table beyond signed PC-relative reach;
that test reference now uses a full-range address. Native core/input/pose/phase
counts remain 426/512/638/133, and both terrain-store cases pass. The live audit
still checks 54 selected timing/pacing targets and ten disabled ranges.


The matching no-render capture is
`tmp/dev/tmp/prof/w6-terrain-cache-none-030/`. Initial executable segments and all
105 tracked allocations again match exactly. At ticks 0–39, all 1,279 registered
prefixes, complete player records, registry/lifecycle order and the restored
terrain cache controls match. The drawing run completes 39 updates and 44 draws
in 240 fields / 284 CIA ticks with one tick of final CIA debt; no drawing completes
39 updates in 239 fields / 283 CIA ticks with zero debt. Every consecutive funding
interval passes. These remain diagnostic equal-tick windows, not FPS benchmarks.

Shared allocations differ only in sound contexts: the previously identified word
at payload offset 344, plus context 2's byte at offset 361 at tick 31 (82 versus
02). The latter high bit is set by the sequencer at `sim:34ed0`, masked for its
selection at `sim:34eaa`, and cleared by `sim:33bf6`/`sim:33c2c`. It is retained
in the report, not normalized away or treated as proof of equivalent sound-event
delivery. The message-background allocation still appears only with drawing from
tick 32. Other globals remain unclassified; final h3 differences total 892 bytes.
Both endpoints pass the native counters and hook audits. Static audits report
64 ranges and 121 patch destinations with zero errors; normal/developer binaries
remain byte-identical to W5. Both owned emulators were quit.


### Delayed rendering preserves the observed world sequence

The unchanged `b6bc9c01…` binary is also captured with CUSTOM5 bit 0 in
`tmp/dev/tmp/prof/w6-terrain-cache-slow-030/`, compared against the preceding
no-render capture. The fixture is installed only at first flight and replaces
the 3D jump stub at `sim:015b2`; its beam-wrap loop adds two complete PAL fields
plus the initial partial field before each 3D call. It retains the native draw
arguments. This is a correctness stress fixture, not a performance workload.

Initial tracked allocations and all data segments match. The only initial sim
segment differences are the three changed address bytes in the fixture's jump
operand at `sim:015b5–015b7`. They remain visible in the report. Across ticks
0–39, all 1,279 registered prefixes, complete player records, registry ordering
and lifecycle event order match the no-render case. Shared allocation differences
are confined to the previously identified sound-context word at payload offset
344 in contexts 0–2. The message-background block appears only with drawing from
tick 32 onward. The final h3 comparison retains 930 differing bytes; this remains
an inventory with unresolved global ownership, not complete gameplay equivalence.

| Render schedule, same VERIFY binary | Completed updates | Draws | PAL fields | CIA ticks | Final unprocessed CIA ticks |
| --- | ---: | ---: | ---: | ---: | ---: |
| Ordinary | 39 | 44 | 240 | 284 | 1 |
| Delayed | 39 | 29 | 249 | 294 | 11 |
| Omitted | 39 | 0 | 239 | 283 | 0 |

Every consecutive boundary in the delayed comparison passes exact clock funding.
There are nine same-field catch-up pairs after the initial update: ticks 5→6,
9→10, 13→14, 18→19, 22→23, 26→27, 30→31, 33→34 and 36→37. No draw occurs between
either member of these pairs, and CIA debt falls from 7–9 ticks to 0–2 ticks.
Observed debt ranges from zero to eleven ticks; the window ends just before
another catch-up. Do not call 39 completed versus 40.5463 newly nominal ticks a
sustained-speed pass: the difference remains explicitly funded debt/fractional
credit. These equal-tick windows also are not the requested 250-field performance
measurements. A long-run capacity check and equal-active-time comparison remain
separate gates.

Native counters and all 54 selected timing/pacing targets plus ten disabled
ranges pass. A five-field trace subsequently captured at a world-update boundary
contains DMA but zero instruction records in this cached-68030 mode. It supplies
no evidence about world memory accesses and must not be used to classify the
remaining globals. Use an instruction-recording CPU configuration for that audit.
The owned emulator was quit. No game/slave code changed for this comparison.


### Shared display-list order is simulation-visible

An exploratory operand scan of 21 complete world updates in the retained
A500 `w6-capacity-a500-full/capacity-0` instruction trace identified accesses to
`h3:07dc8` during world registration/removal. This is older-build evidence used
to locate a dependency, not current-build equivalence or a complete memory-access
proof: the exploratory decoder reports unsupported indexed operands explicitly.
Native inspection confirms the dependency. `sim:0fdf6–0fe04` increments the count
at `h3:03fa8` and appends a pointer to `h3:07dc8`; `sim:0ff22–0ff5a` searches the
same active prefix, decrements its count and replaces a removed entry with the
last pointer. Registration checks the 500-entry capacity at `sim:0fdc6`.

The outer drawing path also writes that count at `sim:006e0`, `00700`, `0071a`
and `00738`, and reorders the same table. It is distinct from the primary registry
at `h3:0859e`/`085a0`, which the earlier explicit registry check covered. Re-reading
the `b6bc9c01…` ordinary/no-render snapshots finds differing active display-list
order at 33 of 40 checkpoints, starting at tick 6. Counts match in those pairs,
but 16–30 active pointer positions differ. The raw h3 report already retained
these bytes; they were not proven harmless. No actual changed collision or AI
outcome is claimed from that short run.

VERIFY candidate
`f92e9eeded113644cac9d79b5addc08d988ae51aab984f2bbd3686887a5123ee`
now leases the shared count and active pointer prefix for the entire outer draw.
It rejects a count above 500, saves the prefix before native drawing and restores
both order and count on return. Inactive tail bytes remain explicit in the raw
inventory: registration unconditionally writes the appended slot before returning,
and removal reads only entries below the current count. No simulation
object is removed merely to make the report match. The existing VERIFY bit-13
owner and sim-v1 installation checks control these additions.

Two native copy cases exercise zero and 500 entries, with a guard after the
500-entry destination (`time_present_list_result=2`). Four real draws in
`tmp/dev/tmp/prof/w6-list-owner-030/` capture the table before the restore routine:
all four demonstrably change it, then return the original active order and count.
The restored counts are 53, 60, 60 and 60 at completed ticks 39–42. All 133 poses,
the terrain cache controls and funded clock state also restore exactly; 108 visual
poses change. `render_phase.py` now checks those properties independently, while
`world_comparison.py` reports shared-list counts/order explicitly at each world
boundary, in addition to the primary registry and full raw h3 inventory.

All 170 host tests pass. The larger VERIFY data area requires a full-range address
for the existing delayed-draw mismatch diagnostic; only that diagnostic reference
changes in the observer. Native core/input/pose/phase counts remain 426/512/638/133,
both terrain-store cases and the cache-control case pass, and the live hook audit
retains 54 selected timing/pacing targets and ten disabled ranges.


The paired no-render capture is `tmp/dev/tmp/prof/w6-list-owner-none-030/`.
Initial executable segments and all 105 tracked allocations (243,855 bytes) match.
The active display list now matches at every one of the 40 world boundaries,
alongside all 1,279 registered prefixes, complete player records, primary registry
order and lifecycle events. With drawing there are 39 updates and 44 draws over
240 fields / 284 CIA ticks, ending with one unprocessed CIA tick; without drawing,
39 updates take 239 fields / 283 CIA ticks and end without debt. Every consecutive
funding interval passes. This is the same diagnostic window, not a new FPS or
sustained-capacity claim.

All shared allocation differences remain in the previously identified sound
contexts: payload word 344 and context 2's offset-361 high bit. The rendering-only
message-background allocation remains explicit. Final h3 differences fall to
819 bytes, including inactive list slots and other still-unclassified state;
the result does not certify complete RNG/combat/gameplay equivalence. Both live
endpoints pass the native counters and byte audits. Static checks report 64 ranges
and 121 patch destinations with zero errors, subject to their existing limitations.
Normal/developer slaves retain their W5 hashes. Both owned emulators were quit.


## Coherent clock snapshots

VERIFY build
`9f72992cb50d3a16ac09923d4b1420dbb092ec0b90335dda9980be036735b8e8`
adds a separate observation word: zero for a coherent primary ledger, one while
advancing cursor/credit, and two while handing a due update to the started count.
The markers are confined to the existing VERIFY scheduler. They do not change
world quantum, funding policy, rendering eligibility or player builds.

The profiler can stop between individual accounting instructions. In the retained
`w6-list-capacity-a500` capture, chunk residuals were zero, minus one CIA credit,
and plus one CIA credit. Whole-window accounting balanced. This was an invalid
intermediate observation, not evidence of discarded simulation time. The original
capture remains intact and is not counted as per-chunk acceptance.

The local collector refreshes the GDB register cache before reading its endpoint.
For a pending transaction it retains the raw snapshot, continues to the matching
commit breakpoint, verifies the cleared marker and program counter, and retains
the settled snapshot. Elapsed field/CIA accounting includes that execution.
`time_capacity.py` rejects a nonzero marker at either endpoint; legacy manifests
without the field retain their previous interpretation and still must pass exact
funding checks.

In `tmp/dev/tmp/prof/w6-transaction-capacity-a500/transaction-probes.json`, forced
read-only breakpoints stop immediately after cursor increment and between due
removal and started increment. Both report the expected pending marker and settle
at their named commit boundary. No game-state writes are used. The first settles
credit without changing the cursor again; the second increases started by one
without changing phase. These are diagnostic probes before the capacity windows.

Two subsequent, continuous 250-field captures pass every funding interval. Their
505 elapsed fields / 599 CIA ticks complete 88 world updates and two draws, with
CIA debt 70 → 12 → 28 and one update still in progress at the final endpoint.
Neither capture needs a natural endpoint settlement; forced probes cover that
branch. The two windows remain a short capacity diagnostic, not full gameplay,
long-term convergence or 50 FPS acceptance. `profiling.md` records the individual
windows and comparison limits.

All 172 host tests pass, including pending-marker rejection at either endpoint
and unchanged results for a cleared marker. Native core/input/pose/phase counts
are 426/512/638/133; terrain stores/cache/list cases are 2/1/2. All 54 timing/pacing
hook targets match. This full mask has no disabled declared ranges; static audits
report 64 ranges and 121 patch destinations with zero errors, subject to their
existing limits. Normal/developer binaries retain their W5 hashes. The owned
emulator was quit after capture. W6 remains VERIFY-only and incomplete.


## Rectangle scratch dependency classification

The remaining raw h3 differences include the eight-byte rectangle scratch area
at `h3:07914–0791b`. The native helper `sim:25244` copies its first input into
all eight bytes at `sim:2525c`/`2525e`, copies its second input to stack storage,
then reads and updates the scratch rectangle. It returns the scratch address at
`sim:252f6–25304`. A returned pointer alone is not proof of transient ownership:
its consumers must be followed.

The direct caller at `sim:19804` copies the result at `sim:19814`/`19816` into
`h3:07124–0712b`. The other caller at `sim:1a026` forwards the pointer through
`sim:1a032`. Its enclosing function `sim:19f62` appears in the callback table at
`h3:01b78`; the dispatcher calls it at `sim:19dd2` and copies the returned eight
bytes at `sim:19ddc`/`19dde` before advancing to another callback. Thus this
observed indirect path also consumes the result immediately.

`rectangle_scratch.py` validates complete observed lifetimes from instruction
records, excluding the capture's measured IRQ stack. It checks initialization
order/destinations, rejects either input overlapping the scratch buffer, checks
reads occur after both initialization writes, verifies the returned address and
requires the exact direct or forwarded return path followed by two contiguous
copy stores from the scratch result. Unknown return paths, nested unconsumed
calls and malformed copies fail. Incomplete calls are reported rather than
counted; a trace with no complete calls cannot produce a passing result.

The current `9f72992c…` capture has 17 complete lifetimes across
`capacity-0`, `capacity-1`, `capacity-next-0` and `capacity-next-1`: fifteen direct
and two forwarded callback results. All pass. Neither final 50-field chunk
contains a complete helper call, so those invocations correctly reject a
vacuous pass. The preceding `f92e9eed…` capture independently has thirteen
passing direct lifetimes in its first two chunks. This classifies the observed
scratch uses; it does not prove every possible caller or every world-global
byte harmless. No bytes are removed or normalized in the equal-tick reports,
and no speculative save/restore is added to the game.

Reproduce against the retained current capture (the cost report supplies its
measured interrupt-stack bounds):

```sh
python3 R/RedBaron/tools/rectangle_scratch.py tmp/dev/tmp/prof/w6-transaction-capacity-a500 capacity-next-0 --out tmp/dev/tmp/prof/w6-transaction-capacity-a500/capacity-next-0/rectangle-scratch.json
```

All 177 host tests pass. Five new cases cover both caller paths, prior-scratch
input aliasing, premature reads, unknown returns and incomplete lifetimes.
There is no slave change or new FPS measurement in this classification.


## Equal-tick bank/fire input checkpoint

The unchanged VERIFY build `9f72992c…` now has a paired cached-68030 capture with
the four-transition keyboard fixture, ordinary rendering versus no rendering:
`tmp/dev/tmp/prof/w6-controls-owner-030/` and
`tmp/dev/tmp/prof/w6-controls-owner-none-030/`. CUSTOM2 is 8192 (the scheduler
also enables its W5 pacing prerequisites). CUSTOM5 selects deferred activation
and the keyboard observer/fixture, plus no-render only in the second run.
These are controlled correctness fixtures, not full-bundle performance workloads.

Initial contents of all four executable segments, h3, the complete player record,
registries and all 105 allocations / 243,855 bytes match. The first Right press
is acquired before flight ownership activates. Its independent acquisition-clock
tuple marks it held-only; its queued key includes the modal flag. Treating all
four fixture acquisitions as active-flight commands would be incorrect. The
Right release and Fire press/release have identical deadlines in both runs,
respectively 10, 27 and 45 CIA ticks after the initial world-clock boundary.

The new `world_controls.py` verifies the queue against acquisition timestamps
and clock-owner tuples, then independently replays event deadlines, held keys
and at-most-one command pop per world tick. Both captures pass that replay and
match all 40 input snapshots. Right is held at completed tick 1, then released;
Fire is held at ticks 4–6. All four transitions are consumed, with exactly one
active-flight command pop (Fire). The early held-only Right transition does not
produce a one-shot command. No acquisition timestamps are adjusted to make the
runs agree, and the full 128-byte held bitmap is compared.

At every equal tick, complete 280-byte player records, all 1,332 registered
26-byte prefixes, primary-registry order, active shared-display-list order/count
and lifecycle events match. All shared allocation differences across the window
are confined to the low byte of payload word 344 in sound contexts 0–2, verified
against `h3:0a184`. The 1,800-byte message-background payload appears only with
drawing from tick 32. Raw differences remain in the report; the final h3 inventory
contains 924 changed bytes. This is not a blanket full-world-state verdict.

Both runs complete 39 world updates. Ordinary rendering produces 43 draws over
243 PAL fields / 287 CIA ticks and ends with four unprocessed CIA ticks; no-render
uses 239 fields / 283 CIA ticks and ends with zero debt. Every consecutive funding
interval passes. This extends render-schedule correctness to bank/fire input;
it does not establish hit/near-miss outcomes, projectile collision correctness,
stall/landing behavior, sustained capacity or smooth 50 FPS.

Reproduce the retained comparison:

```sh
python3 R/RedBaron/tools/world_controls.py tmp/dev/tmp/prof/w6-controls-owner-030 tmp/dev/tmp/prof/w6-controls-owner-none-030 --out tmp/dev/tmp/prof/w6-controls-owner-none-030/controls-comparison.json
python3 R/RedBaron/tools/world_comparison.py tmp/dev/tmp/prof/w6-controls-owner-030 tmp/dev/tmp/prof/w6-controls-owner-none-030 --out tmp/dev/tmp/prof/w6-controls-owner-none-030/heap-inventory.json
```

All 183 host tests pass, including six input-history tests covering wrap,
acquisition disagreement, overflow/unconsumed events, differing builds or
consumption, explicit preflight ownership, and independent timestamp replay.
The final live endpoint passes native counters 426/512/638/133, terrain/cache/list
cases 2/1/2, all 54 timing/pacing targets and ten disabled ranges. Both owned
emulators were quit. No slave source or release binary changes in this checkpoint.


## Flight-relative scheduled input fixture

The original VBlank acquisition fixture cannot by itself guarantee identical
flight-relative input under a changed startup render schedule. In
`tmp/dev/tmp/prof/w6-controls-owner-slow-030/`, the deliberate drawing delay
moves flight activation past the short Right hold. `world_controls.py` rejects
that run because no completed update holds Right; its different player states
must not be reported as a scheduler divergence under identical input. The raw
capture remains retained. The earlier ordinary/no-render acquisition pair is
still valid, with its explicitly documented preflight held-only transition.

VERIFY build
`4f682c6dc6ae6efc0aa4fc6843c00e7a49531869028a4744a014dab27f748a63`
adds CUSTOM5 bit 31 for a separate **synthetic scheduled-input fixture**. It
requires the W6 scheduler, rejects simultaneous physical-acquisition fixtures
(bits 21/22), and does not emulate host keyboard/CIA serial acquisition. It
publishes Right down/up and Fire down/up at active-flight cursor offsets
32/64/96/128. The normal input-consumption path processes those records.

The main task publishes the complete flight origin followed by one atomic
request word. The existing supervisor VBlank observer, after input seeding,
serializes queue publication and marks the request complete. It rejects an
unready owner, a nonempty queue, or publication after the first deadline. This
separates main-task clock-origin publication from supervisor-only interrupt
masking. The initially attempted main-task masking caused a privilege fault;
that failed build/capture is retained separately and is not validation evidence.
The final fixture passes the native delayed-draw run without that fault.

AmigaDOS numeric arguments are signed 32-bit values. Use the signed decimal
representation of the high-bit CUSTOM5 mask; an unsigned positive representation
fails before the slave loads. The local boot helper's `--replay` option handles
this conversion and leaves `--input-fixture` unselected. For example, replay,
deferred activation and observation with the slow-draw fixture use
`CUSTOM5=-2146434559`. These flags are development fixtures, not player options.

`world_controls.py` labels scheduled replay separately from native acquisition
and refuses comparisons between the two kinds. It checks every retained queue
record against independently constructed flight-relative deadlines, verifies
complete publication/consumption, and applies the existing independent held-key
and command-pop replay at every completed tick. The new generator check also
covers unsigned CIA wrap and rejects altered deadlines or queue records.
No raw world-state differences are removed by this fixture.


The corrected fixture is validated on cached 68030 in three fresh captures:
`tmp/dev/tmp/prof/w6-replay-normal-030/`, `w6-replay-slow-030-v2/` and
`w6-replay-none-030/` (the latter two under the same profiling directory).
All use the frozen build above and CUSTOM2=8192. The independent replay agrees
at all 40 completed-tick boundaries in every run: Right is held at ticks 5–8,
Fire at ticks 14–17, all four transitions are consumed, and exactly two one-shot
commands are popped. This proves scheduled consumption for these fixtures;
it does not replace the separate native acquisition checks.

| Render schedule | Completed updates | Draws | PAL fields / CIA ticks | Final CIA debt |
| --- | ---: | ---: | --- | ---: |
| Ordinary | 39 | 39 | 244 / 288 | 5 |
| Delayed | 39 | 27 | 245 / 289 | 6 |
| None | 39 | 0 | 239 / 283 | 0 |

Every consecutive funding interval passes. Eleven delayed-run pairs complete in
the same PAL field with no intervening draw: 5→6, 9→10, 12→13, 15→16, 18→19,
21→22, 25→26, 29→30, 33→34, 35→36 and 37→38. Their CIA debt decreases from
7–10 ticks to 0–3. This includes held bank/fire input during catch-up.

Initial h3, player and all 105 allocations / 243,855 bytes match. Ordinary and
no-render executable segments match; delayed drawing differs only in the three
address bytes at `sim:015b5–015b7`, independently checked against the
`observe_slow_draw` target of the expected JMP at `sim:015b2`. At all 40 equal
ticks, complete player records, 1,352 registered prefixes, primary registry and
shared display-list order/count, and lifecycle events match in both comparisons.
All differing shared allocations are the low byte of payload word 344 in sound
contexts 0–2. The separately retained 1,800-byte drawing/message background appears
only with drawing from tick 33. Final raw h3 differences remain 1,233 bytes for
ordinary/no-render and 1,238 for delayed/no-render; none is silently normalized.

All three native endpoints pass the existing counters (426/512/638/133), terrain
stores/cache/list cases (2/1/2), 54 selected timing/pacing targets and ten disabled
ranges. All 184 host tests pass; static audits report 64 ranges and 121 patch
destinations with zero errors and their existing indirect-target limitations.
Normal and developer binaries retain their W5 hashes. All owned emulators were
quit. The fixture is VERIFY-only, and these 40-boundary controlled captures are
not 250-field performance samples, complete gameplay acceptance, or proof of
smooth 50 FPS.

For a new local fixture capture, use the existing helper with `--replay` instead
of `--input-fixture`, adding `--slow` or `--no-render` as appropriate. Run one
capture at a time and use a new evidence directory. Reproduce retained checks:

```sh
python3 R/RedBaron/tools/world_controls.py tmp/dev/tmp/prof/w6-replay-slow-030-v2 tmp/dev/tmp/prof/w6-replay-none-030 --out tmp/dev/tmp/prof/w6-replay-slow-030-v2/controls-comparison.json
python3 R/RedBaron/tools/world_comparison.py tmp/dev/tmp/prof/w6-replay-slow-030-v2 tmp/dev/tmp/prof/w6-replay-none-030 --out tmp/dev/tmp/prof/w6-replay-slow-030-v2/heap-inventory.json
```


## Attached-camera presentation checkpoint

VERIFY candidate `eb743015c665a5893fba0cb12158c9cceb33704f06e6631ccf61235fd0f30896`
extends the render-only pose lease to the native attached camera family. The
world remains fixed-step; this changes only the pose used during a draw. W6's
acceptance requirement remains consistent gameplay/simulation speed independently
of achieved rendering FPS, plus smooth 50 FPS on capable PAL hardware.

The native callback at `sim:15666` copies the followed object's 18-byte position
and orientation into the private camera pose at `h3:06782`. View setup at
`sim:158f4` selects this callback for modes 1–5. The candidate requires that exact
callback at `h3:01a70`, the private camera at `h3:0677a`, a registered target at
`h3:067ae`, and unchanged current object poses. It additionally requires the
private camera pose to equal the current target pose before leasing. Otherwise
it keeps the native drawing path. Orbit/free cameras remain outside this lease.

During drawing, the private camera receives the same independently modelled
visual pose as its target. The exact original private pose is saved and restored
on return, alongside registered object poses. Camera history now includes the
followed target identity: a different target invalidates the previous pair even
when the private camera pointer and view mode stay the same. Host checks cover
this identity change; an in-game target-switch capture remains open.

The scheduled replay fixture uses F2 instead of Right when CUSTOM5 bit 4 is set
alongside bit 31. This sends the command through W6's input queue at the same
32/64/96/128 flight-relative deadlines; Fire remains the second key. The earlier
tape shortcut did not deliver this view command through the private W6 input
owner. A retained attempted debugger-memory injection also failed its immediate
write readback and is not input evidence. The successful capture uses the
in-game queue fixture, not debugger writes.

Cached-68030 capture `tmp/dev/tmp/prof/w6-attached-camera-030/`, CUSTOM2=8192,
uses the local boot helper's `--replay --scene dense`. All 24 world boundaries
pass the input replay and pose-history checks: 649 poses, 45 lifecycle events,
20 invalidated records. F2 changes view 0→1 at tick 5, where previous history
correctly becomes empty; subsequent captures have consecutive histories.
Four actual view-1 draws at ticks 23–26 check 125 object poses, with 102 changed
visual poses. All four private camera poses also change during drawing and are
restored exactly afterward. No world update occurs inside a draw. Shared-list
and terrain-cache restoration and exact rendering-phase clock checks pass.

Native self-tests retain counts 426/512/638/133, terrain stores/cache/list 2/1/2;
the live audit passes 54 selected targets and ten disabled ranges. Static audits
report 64 ranges and 121 patch destinations with zero errors and the existing
indirect-target caveat. All 189 host tests pass. Normal and developer binaries
retain their W5 hashes. This is scoped view-1/camera-ownership evidence, not full
camera-mode acceptance, gameplay convergence, capacity, or a 50 FPS result.
Modes 2–5 are guarded by the same native callback contract but still need native
coverage. Target changes, other camera callbacks and modal/restart cases remain
open. This candidate remains VERIFY-only under CUSTOM2 bit 13.


Same-build cockpit regression `tmp/dev/tmp/prof/w6-camera-cockpit-030/` uses
`--replay` without the rear-view selection. Its 24 boundaries pass independent
bank/fire consumption and pose-history checks: 802 poses, 68 lifecycle events,
32 invalidations. Four cockpit draws check 140 poses, with 116 visual changes,
zero private-camera leases and no world update during drawing. Clock, list and
terrain-cache restoration pass. Both native endpoints pass the self-test and
live patch audits above; both owned emulators were quit. The two scenes are
separate correctness captures, not an A/B speed comparison.


## Sorting-context difference classification

The ordinary/no-render inventories retain differing bytes within the longword
at `h3:04e1a`. It is the temporary comparator context for `sim:0e470`, not an
RNG state. `sim:0e498` stores the current key-array pointer before handing the
`sim:0e428` callback to the sorter. The callback loads that pointer at
`sim:0e448`, then compares two indexed longwords. A relocation audit of the
original v1 sim finds only those two references into this four-byte context.
`tools/sort_context.py` checks those references and the exact original store,
callback handoff, indexed reads and return bytes. Computed aliases are not
claimed covered by a relocation scan.

The independent trace checker requires a fresh owner and context publication
before each observed comparator read, then checks the loaded pointer against
that publication. Nested owners, stale pointers and reads before initialization
fail. Incomplete or leading calls are never counted as complete evidence; a
chunk with no complete comparator use fails instead of passing vacuously.

Retained A500 build `9f72992c…`, `w6-transaction-capacity-a500`, supplies four
complete lifetimes in its second capacity window: two in `capacity-next-0`
with 267 comparator reads and two in `capacity-next-1` with 283 reads. All 550
reads use their current owner's pointer. The other four chunks contain no
complete qualifying lifetime and are explicitly rejected as evidence. The
machine's previously measured IRQ stack is excluded from this main-task audit.
These observations classify the retained pointer after the inspected calls;
they do not establish full global-state independence, RNG/combat correctness,
or an exclusion rule. Raw world comparisons continue reporting every differing
byte. The slave is unchanged. All 195 host tests pass, including rejection of
changed source contracts and extra references.


## Rear-view world state across render schedules

The same frozen `eb743015…` candidate now has a paired no-render capture,
`tmp/dev/tmp/prof/w6-attached-camera-none-030/`, using `--replay --scene dense
--no-render` on cached 68030 with CUSTOM2=8192. Both captures start with identical
four sim segments, player and 116 tracked allocations / 238,364 bytes. The
independent four-event replay agrees at all 24 boundaries, including F2 at the
view transition and Fire. No pointer or byte normalization is applied.

All 24 equal ticks match the complete player record, 649 registered pose
prefixes, primary registry, shared display-list order/count and lifecycle
events. The full camera position/orientation, view, camera pointer and followed
target also match at every tick. `world_comparison.py` now records this camera
state explicitly, including differing target identity even if the private
camera pointer does not change. This is reproducible evidence for the observed
rear-view lease and input sequence, not coverage of every camera or combat path.

| Render schedule | Completed updates | Draws | Actual PAL fields / CIA ticks | Final CIA debt |
| --- | ---: | ---: | --- | ---: |
| Ordinary | 23 | 20 | 143 / 169 | 2 |
| None | 23 | 0 | 141 / 167 | 0 |

Every consecutive funding interval passes exactly. These boundary-controlled
captures are shorter than 250 fields and are not performance samples. The
ordinary path retains a separate 1,800-byte drawing/message-background payload.
At the final tick, the differing shared allocations are single bytes at payload
offset 345 (the low byte of word 344) in sound contexts 0, 1, 2 and 4, identified
through the pointer table at `h3:0a184`. Raw differences remain in 1,464 h3 bytes
and 110 hunk-0 bytes, including clock/drawing state; none is excluded from the
inventory or treated as proof of whole-gameplay equality.

The no-render endpoint passes native self-tests 426/512/638/133, terrain
stores/cache/list 2/1/2, 54 selected targets and ten disabled ranges. Its owned
emulator was quit. All 196 host tests pass. The slave has not changed since the
attached-camera checkpoint. Full gameplay/global-state/event convergence,
physics/combat acceptance, sustained capacity and smooth 50 FPS remain open.


## Current full-bundle capacity evidence

The `eb743015…` A500-equivalent and cached-68030 runs are recorded together in
`profiling.md`, “W6 current full-bundle capacity checkpoint.” Two consecutive
250-recorded-field A500 windows complete 47/42 world updates with 1/2 publications
and reduce CIA debt 62→25→13. Two exact-250-field 68030 windows complete 41/41
updates with 43/53 publications and debt 0→2→3. All funding checks, native
self-tests and 54 selected timing/pacing targets pass. These are limited observed
workloads; they do not certify the wider capacity matrix or smooth 50 FPS.
The field collector now records the clock transaction marker explicitly; all
four 68030 endpoints are coherent. No uncommitted snapshot is silently treated
as a completed timing transaction. Both owned emulators were quit.


## Constant-bank small-step reference

VERIFY fixture build `83f586cb2b477476dd915d2779561abf834cd6ce3abe95fa3f347cafdf20083a`
adds CUSTOM4 bit 16 to hold Right at every native flight-input checkpoint when
forcing primary dt. The low word still selects an existing allowed dt. It
rejects use with the active timestamped W6 input owner. This deliberately tests
the native physics path with CUSTOM2=0; it does not change the scheduler quantum
or any player option. The old tape's step-20–34 hold cannot be used for this
comparison because its input duration changes with the chosen dt.

Both cached-68030 runs begin with identical complete player state, 105 tracked
allocations / 243,855 bytes and four sim segments, except the deliberately
forced primary dt at `h3:04834`. Actual held Right is recorded as 1 at every
sample. Both remain at Time Scale 40, F=33. `physics_reference.py` requires those
initial-state and control conditions and compares equal accumulated primary time.
It retains the raw initial segment difference instead of concealing it.

| Primary dt | Completed updates | Primary-time budget | Travelled distance, raw |
| ---: | ---: | ---: | ---: |
| 225 | 44 | 9,900 | 10,926.783 |
| 100 reference | 99 | 9,900 | 11,117.925 |

The 225-unit path is **1.7192% shorter**, with endpoint separation 657.494 raw
units and final orientation differences `(0, 800, 22)` in native signed-word
units. This is a larger difference than the earlier 0.4% straight-flight result.
It is not accepted under an invented tolerance. The native-history checks and
exact airborne velocity/position model pass 870 velocity conversions and 429
coordinate/remainder updates across both runs. Thus the difference is upstream
of that checked position arithmetic, including differing native velocity and
orientation histories; aerodynamic/control integration and per-step rounding
still need investigation. A passing position model does not certify those
forces or a contact/hit outcome.

This does not contradict equal-225-tick state agreement across rendering
schedules: step-size fidelity and rendering independence are separate checks.
The bank physics acceptance gate remains open, along with other Time Scale
settings, stall/recovery, climb/descent, landing/crash and combat cases. No
forced-dt run is a wall-time performance sample. Secondary clocks are still
native in this isolated probe; it is not a full W6 scheduler comparison.

Retained captures: `tmp/dev/tmp/prof/w6-bank-reference-225/` and
`tmp/dev/tmp/prof/w6-bank-reference-100/`, including raw initial RAM, player
records, held-key observations and step logs. With the local development
environment loaded, reproduce the probes using the current boot helper with
`030 0`, `--dt 65761` for 225 or `--dt 65636` for 100. Collect through steps 45
and 100 respectively with `w6_players.py --key-code 0x4e`, then run the versioned
`physics_reference.py CANDIDATE REFERENCE --out RESULT` checker. Use fresh evidence
directories and one owned emulator at a time. Both owned captures were quit.

All 200 host tests pass. Static audits retain 64 ranges / 121 patch destinations
with zero errors and their existing indirect-target limitation. Normal and
developer binaries retain their W5 hashes. Only the VERIFY physics fixture and
its analysis tooling changed; the 225-unit W6 scheduler is unchanged.


## Native rotation quantization investigation

The banked physics discrepancy has a confirmed per-update quantization source,
although its complete trajectory contribution is not yet isolated. Native
`sim:18ba2` calls `sim:193d0`, a stub for the matrix-to-angle converter at
`sim:3688e`. The converter takes matrix word 5, discards its low five magnitude
bits at `sim:368aa`, looks up the pitch table at `sim:37d5a`, then scales the
angle by 16 at `sim:368c4`. Its other angles use `sim:38a12`: a nine-bit integer
ratio selects `sim:3855e`'s atan table, with explicit cardinal/diagonal cases,
quadrant reflections and a final left shift by four at `sim:38aa2`.
Those converted angles therefore occupy a 16-unit grid. Final aircraft headings
can receive an additional scalar correction afterward at `sim:18c3e`, so the
claim is about conversion output, not every stored final angle.

`angle_quantization.py` independently models these integer/table operations and
checks observed input/output registers inside native world-update boundaries.
It verifies the original executable hash, quantizing opcodes and source tables;
traces exclude the capture's established IRQ stack. Across all six chunks of
`w6-current-capacity-a500` (frozen slave `eb743015…`), 127 pitch conversions and
602 atan calls match exactly. Inputs before the first observed world entry are
not counted. This uses retained native execution and adds no emulator or slave
instrumentation. All 203 host tests pass, including sign/quadrant, ratio-index,
cardinal/diagonal and discarded-matrix-bit cases.

The AND masks at `sim:18c68`, `18c76` and `18c86` are change-detection tests;
they do not themselves round and store the aircraft angles. The actual table
conversion above is the observed quantization mechanism. More small steps mean
more conversions and feedback, so a smaller-step path is not an exact golden
trajectory for this native integer engine. This is a reason to classify the
banking result carefully, not permission to accept its whole discrepancy as
rounding. Control response, force integration, collision outcomes and the full
physics matrix remain open. No timing or physics patch changed in this audit.

## Native bank roll-response classification

The follow-up `roll_response.py` audit models the native airborne response at
`sim:16c4e..16d4e`, inside the flight model entered at `sim:16a50`. This is
not the simpler control ramp at `sim:18542`. The native control target in the
retained bank trace is 1,404 (control value 248, aircraft gain 1,450). With a
current signed roll rate `r`, native code computes a truncated signed quotient
`(target-r)*256/gain`, takes its magnitude and clamps it to 32..256. It scales
450 acceleration, or 700 when reversing direction, by that factor before
applying primary dt and clamping overshoot to the target. Negative products
retain native arithmetic-shift rounding. This response approaches its target
progressively, with integer rounding at each update.

The independent model matches **all 143 consecutive recorded roll-rate
transitions** in the constant-bank reference: 44 at dt=225 and 99 at dt=100,
using the aircraft parameters from the retained initial memory and signed rate
at player-relative offset 0xd6. Both histories hold Right throughout. Their
first six rates are respectively `381, 658, 860, 1007, 1115, 1193` and
`169, 318, 448, 563, 664, 753`. This snapshot check assumes the traced constant
control target; it does not independently decode keyboard acquisition.

The existing full-bundle A500 `capacity-0` instruction trace independently
checks **eight complete response calculations**, including release/reversal:
24 factor/acceleration/delta results match exactly. The checker reads the
actual dt at `sim:3d76`, filters interrupts, requires an observed world entry,
and checks the original executable hash and relevant instruction bytes. The
other five retained chunks contain no complete qualifying response calls;
they are rejected as empty evidence. The full host suite passes **207 tests**.
Neither the slave nor the frozen builds changed: the bank-reference build is
`83f586cb2b477476dd915d2779561abf834cd6ce3abe95fa3f347cafdf20083a`;
the retained A500 trace uses
`eb743015c665a5893fba0cb12158c9cceb33704f06e6631ccf61235fd0f30896`.

Reproduce with the `roll_response.py` capture argument pointing to each retained
`w6-bank-reference-225` / `w6-bank-reference-100` directory and `--out` naming the
result. For the trace, use `w6-current-capacity-a500` with `--sim` pointing to
the original executable, `--chunk capacity-0`, and `--out` naming the result.
The ignored results are named `roll-response.json` and
`capacity-0-roll-response.json` in their respective captures.

This classifies the observed roll-rate histories as native discrete control
response. Together with the angle-table audit, it establishes why changing
physics step size changes banking, but **does not fully attribute the 1.7192%
trajectory-distance difference**: coupled pitch/yaw, lift/drag and contact or
combat outcomes remain separate physics gates. The dt=100 reference measures
step-size sensitivity, not rendering-rate dependence. W6 retains the approved
fixed225 step for every render schedule; no tolerance, quantum, player policy,
or performance claim changes on this evidence.

## High-frequency real-drawing capacity diagnostic

The full VERIFY bundle (CUSTOM2=16319, CUSTOM4=0, CUSTOM5=512, MMU) was measured
at maximum detail / Time Scale 40 on a synthetic cached-68030 configuration:
2 MB chip, 8 MB fast, no slow memory, CPU multiplier zero, CPU frequency
200,000,000, real CPU speed, cycle-exact CPU/memory/blitter. The retained
`debug.uae` confirms the requested frequency and CPU model. No fast-draw,
no-render or slow-draw fixture is selected. The slave remains
`83f586cb2b477476dd915d2779561abf834cd6ce3abe95fa3f347cafdf20083a`.

Local evidence is `tmp/dev/tmp/prof/w6-capacity-030-200mhz/`: frozen slave/listing,
configuration and entry metadata, `field-census.json`, raw before/after RAM,
publication/event logs, `field-capacity.json`, `clock.json` / `clock.txt`, and
`clock-summary.json`. Two adjacent 250-field windows publish 60 and 58 frames
(12.0 and 11.6 FPS); all intervals span 4–5 fields and all publications use the
safe beam window. Each consumes 296 CIA intervals and completes 41 world ticks,
versus 40.8220875 newly nominal. CIA debt is 1 → 2 → 2; due work and transaction
markers are zero at all endpoints. Draw counts equal publication counts. The
native self-tests remain 426/512/638/133, terrain/cache/list tests 2/1/2; all
54 selected timing/pacing hook destinations pass.

Following that census, routine-clock entry/return observations span flight
checkpoints 84–93. The unchanged `routine_wall_time.py` checker accepts fourteen
3D passes (mean 1.666873 fields; minimum 1.637120, maximum 1.707196) and nine
world calls (mean 0.100863 fields). It also accepts sixteen overlays (mean
0.372115 fields), 318 bitmaps and 650 radius calls. The complete capture has
1,300 paired calls; 293 are excluded for uncertain beam/counter phase. Timing
uses VBlank plus beam position, not cached-CPU instruction-cycle estimates.
It includes interrupts and nested work. The isolated emulator was then quit.

The 3D pass exceeds the one-field rendering budget in every accepted sample.
This contradicts 50 FPS acceptance for this configuration/scene; it does not
contradict its observed exact world-clock funding. It also does not establish
a real accelerator's speed or attribute the residual cost specifically to chip
accesses, blitter waits or W6 render-state isolation. The earlier 50 MHz run uses
a different input fixture, so no frequency-scaling speedup is claimed. Continue
with a current-bundle rendering-cost breakdown while retaining the complete
physics/state and capacity gates. Smooth 50 FPS remains required and unproven.

## Current-bundle rendering cost localization

The follow-up local capture `tmp/dev/tmp/prof/w6-render-cost-200mhz/` retains the
same slave hash and configuration as the preceding high-frequency diagnostic:
VERIFY `83f586cb2b477476dd915d2779561abf834cd6ce3abe95fa3f347cafdf20083a`,
CUSTOM2=16319, CUSTOM4=0, CUSTOM5=512, maximum detail, Time Scale 40, cached
200 MHz emulated 68030 with cycle-exact memory/blitter. No rendering is skipped.
A fresh boot advances to native flight checkpoint 84 before measuring.

Four consecutive ten-checkpoint windows use the same native beam/VBlank clock
and `routine_wall_time.py` phase rules. All entry/exit pairs restore their SP;
only complete pairs enter the analysis. `capture-clock.py` freezes the exact
read-only collector alongside the evidence. For the native draw call its return
probe is immediately before argument cleanup, preserving equal SP. W4 changes
rectangle setup internally, leaving the measured native entry/returns valid.

| Capture | Checkpoints | Paired calls | Phase-excluded pairs |
|---|---:|---:|---:|
| budget-clock.json | 84–93 | 80 | 4 |
| draw-clock.json | 94–103 | 387 | 65 |
| stage-clock.json | 104–113 | 75 | 6 |
| cockpit-clock.json | 114–123 | 360 | 4 |

The corresponding `*-summary.json` files retain accepted and excluded samples.
The full outer render averages 3.921673 fields (15 accepted calls), native draw
3.883593 fields (15), pose blending 0.005177 fields (15), and 3D pass 1.666185
fields (15) in the first window. Native draw includes publication waits and W6
hooks inside the original path. Thus its name does not imply W6 is disabled.

The disjoint native frame-stage window measures scene work at
`sim:006bc..007c4` at 2.135874 fields (13 calls), cockpit work at
`sim:007c4..00830` at 1.523577 fields (13), and publication/end-of-frame at
`sim:00afe..00b10` at 0.205876 fields (15). The background stage
`sim:005fe..006bc` and message stage `sim:00830..00afe` average less than
0.00004 fields each (14 accepted calls each). Shared stage boundaries have a
single breakpoint that emits both records, rather than competing command lists.

The last window localizes recurring cockpit work: `sim:19ba6..19e12` averages
0.431846 fields (15), `sim:15e96..163a0` 0.721613 fields (15), and overlay
`sim:2c144` 0.361944 fields (14). The whole cockpit stage averages 1.515575
fields (14). Meanwhile the earlier drawing window accepts 146 polygon and
162 rectangle calls with means 0.054906 and 0.060590 fields; its 14 accepted
3D passes average 1.667103 fields. No percentage decomposition is inferred
from sums across different accepted sample sets or adjacent world states.

Two initial oversized breakpoint sets were rejected by the debugger before
execution; their `*-rejected.json` and `.txt` files remain separate, incomplete,
and excluded. Smaller sets completed without changing the slave. At the end,
all 54 selected timing/pacing hook destinations and native 426/512/638/133 plus
terrain/cache/list 2/1/2 checks pass. The owned emulator was quit.

This is cost localization, not optimization or acceptance. The measurements
make the native scene/cockpit drawing path the next presentation target; they
do not justify removing state restoration, lowering detail, changing physics
speed, or relaxing the 50 FPS requirement. Audit redraw dependencies and compare
pixels before changing the expensive native cockpit calls. The full gameplay,
capacity and hardware acceptance gates remain open.

## Front-cockpit cache dependency audit

The expensive call at `sim:15e96` dispatches numbered drawing programs through
`sim:168c8` to the interpreter at `sim:28962`. The ordinary front-view path
selects programs 3 and 4 when the gun-status word returned by `sim:1216a` is zero;
other statuses select different programs. This is conditional behavior, not a
claim that those two programs cover all flight or combat states.

`cockpit_program.py` now decodes those two programs from the retained initial
bank-reference memory, using the pointer table at `h3:7b52`. It accepts only
the observed colour, line, rectangle, resource-selection and bitmap commands;
unknown commands, incoming bitmap-resource dependencies, truncated data and
missing terminators fail closed. The expected original sim hash is checked.
The retained `cockpit-programs.json` reports:

| Program | Bytes including terminator | Lines | Rectangles | Bitmaps | Colour commands |
|---|---:|---:|---:|---:|---:|
| 3 | 138 | 6 | 2 | 3 | 3 |
| 4 | 108 | 5 | 2 | 2 | 2 |

For example, both programs draw lines between (89,72) and (231,72), plus struts
near x=73/247 and y=76..90. Program 3 places bitmaps at (67,74), (85,93) and
(149,71); program 4 places them at (204,74) and (255,93). These are view-overlay
coordinates. Unchanged cockpit inputs do not imply unchanged destination pixels:
the preceding scene render can replace the pixels beneath this drawing. A
whole-call skip keyed only on simulation tick or cockpit inputs is therefore
not an acceptable optimization.

The other costly call, `sim:19ba6`, already tracks seven pairs of per-buffer
rectangles at `h3:7134`, indexed with the selector at `h3:711d`. It clips/redraws
using those previous bounds, dispatches instrument callbacks, replaces their
bounds, decrements the dirty byte at `h3:711c`, and updates the selector. Thus
neither expensive caller is a pure bitmap copy that can simply be omitted.
The interpreter also changes drawing state and resource selectors. Its colour
command can call native helpers; the command inventory does not establish
constant colours or a complete cache key.

The concrete candidate is a cached **composited overlay**, still applied to each
fresh scene, not reuse of the prior destination or removal of instrument updates.
Before implementation, verify immutable program/resource bytes, effective
colour/clip/mode dependencies and native post-call state. Derive a transparency
mask with native reference rendering, and check the resulting pixels against
native execution on changing backgrounds, both buffers, gun states and view
changes. Unsupported commands or dependencies must take the original path.
Do not claim the whole measured `sim:15e96` cost as potential savings: it also
contains other drawing and state work.

This audit adds no runtime patch and no FPS improvement. All **210 host tests**
pass, including operand/terminator distinction, bitmap-resource tracking and
rejection of incomplete or unsupported programs. Reproduce with
`cockpit_program.py` on the retained `w6-bank-reference-225` capture and an
`--out` result path. The supported command inventory advances the rendering
investigation; pixel equivalence and the 50 FPS gate remain unproven.

## Quiescent native overlay pixel probe

A new **VERIFY-only CUSTOM2 bit 14** provides complete native drawing-program
boundaries for the overlay investigation. It is instrumentation, not a cache or
speed feature. `overlay-probe.s` patches complete entry/exit sequences at
`sim:28962` and `sim:28d52`, executes the original interpreter between them,
and drains pending blitter work before each debugger marker. The entry records
the program argument and a diagnostic count. The exit preserves the native
result flags and register/frame restoration. The wait routine saves SR on
68000 and is changed to user-accessible CCR saving on 68010+; restoration uses
MOVE to CCR. Adding this VERIFY code also required long-distance calls for the
VERIFY startup helper and vertex-error handler. Neither is a player change.

Frozen VERIFY text is 250,048 bytes, SHA256
`99d2a366c3e15865bfe03754908caf730f0bfdad09ea9e8002b117beec404bbf`.
Normal and developer builds retain their existing W5 hashes. Static audits
cover 66 hook ranges and 123 patch destinations with zero errors. Host tests
pass 213 cases. The cached-68030 live run verifies both probe JMP/NOP pairs and
the CCR-save opcode, alongside the existing 54 timing/pacing destinations and
native 426/512/638/133, terrain/cache/list 2/1/2 checks.

The local `w6-overlay-probe-030` capture selects CUSTOM2=32703 (full bundle plus
probe), CUSTOM4=0, CUSTOM5=512 and MMU on the established cached 50 MHz 68030,
maximum detail / Time Scale 40. `overlay-capture.json` and its full raw RAM
snapshots record programs 3 and 4 on each of the two physical draw buffers.
All eight entry/exit DMACONR reads report the blitter idle. Each program's
entry count and identity match at exit. `overlay_snapshot.py` verifies fixed
320×200, five-plane framebuffer geometry and produces the retained
`overlay-inventory.json`:

| Program | Changed pixels per execution | Changed bytes | Inclusive changed-pixel bounds |
|---|---:|---:|---|
| 3 | 1,022 on both buffers | 792 | (67,71)–(248,99) |
| 4 | 735 on both buffers | 511 | (204,74)–(272,102) |

These are observed differences, **not a transparency/coverage mask**. In
particular, program 4 repeats lines already drawn by program 3; drawing the same
colour again cannot be discovered by subtracting these snapshots. The tool
retains every h3 difference rather than hiding renderer/interrupt fields:
1/10/7/10 bytes differ across the four calls. Their ownership must be resolved
before replaying or caching interpreter state.

The extra blitter waits can alter timing and interrupt placement. No performance,
full gameplay equivalence or pixel-cache correctness claim uses this run.
This establishes a trustworthy native pixel reference for the next cache twin;
it does not implement the cache. The probe remains excluded from normal and
developer builds, and the 50 FPS gate is unchanged. Native 68000 probe execution
has not yet been tested.

A same-build cached-68030 control, `w6-overlay-probe-off-030`, requests
CUSTOM2=16319. After deferred installation and the second flight checkpoint,
the live disabled-byte checker verifies both eight-byte probe ranges against
the original executable; the entry counter remains zero. Existing 54 selected
timing/pacing destinations still pass. Both owned runs were quit. This confirms
probe-option isolation for the tested v1 configuration, not untested hardware.

## Independent front-overlay raster and mask model

`cockpit_raster.py` independently interprets the observed programs' lines,
solid rectangles, colour remapping and masked planar bitmaps. It models the
colour-map lookup at `sim:28a96..28b12`, reads the selected bitmap descriptors
and mask/data planes, and rejects unsupported orientation, clipped primitives,
mixed rectangle edge colours, screen geometry or program selection. It requires
the preceding quiescent-snapshot checks and the captured original executable
identity. This is an offline model, not an installed rendering replacement.

Against the four `w6-overlay-probe-030` native before/after pairs, the model
matches **all 160,000 framebuffer bytes**. A second comparison renders the
model onto zero, then composites that image through its independently accumulated
coverage mask over the actual original framebuffer. All 160,000 bytes again
match native output. Coverage includes opaque pixels whose colour already
matches the destination, including opaque zero-colour pixels:

| Program | Covered pixels | Word-aligned bounds (x,y,width,height) | Five-plane image | Mask | Packed chip bytes |
|---|---:|---|---:|---:|---:|
| 3 | 1,070 | (64,71,192,30) | 3,600 | 720 | 4,320 |
| 4 | 1,003 | (64,72,224,31) | 4,340 | 868 | 5,208 |

The combined packed payload is **9,528 bytes**, excluding descriptors, allocator
headers or any implementation-specific row padding. No chip allocation is made
by this model. Program 3's coverage reaches y=100 even though the earlier
changed-pixel inventory stopped at y=99; program 4's coverage also includes
lines already drawn by program 3. This is why the previous pixel differences
could not serve as the coverage mask.

The raster model records 75 read ranges for program 3 and 60 for program 4.
Each program's read-dependency digest agrees across its two captured physical
buffers. These include program/bitmap content, palette-remapping inputs,
clipping and drawing geometry. They describe the model's reads, not a proof
that every native interpreter dependency has been identified. The actual
before-framebuffers differ by six bytes between the paired buffers per program;
this is limited native background variation, not a randomized native test.

The retained result is `w6-overlay-probe-030/raster-check.json`. Reproduce with
`cockpit_raster.py` on that capture's `overlay-capture.json` and an `--out` path.
All **218 host tests** pass, including mask preservation across planes, opaque
zero-colour pixels, aligned bounds and the line cases. The native slave remains
`99d2a366c3e15865bfe03754908caf730f0bfdad09ea9e8002b117beec404bbf`.

The next runtime candidate must preserve post-call resource/colour state, validate
its complete cache key, composite onto each freshly drawn buffer, and run a
native pixel twin on materially different backgrounds and view/gun transitions.
This model does not authorize omitting the interpreter's state writes or reusing
stale destination pixels. No runtime cache, measured speedup or 50 FPS result is
claimed; all wider W6 gameplay gates remain open.


## Private native overlay compositor check

The VERIFY-only overlay probe now runs a private-buffer blitter self-test before
installing its interpreter hooks. `overlay-blit.s` implements synchronous,
word-aligned five-plane cookie-cut composition with one shared mask. It waits
for the blitter before setup, between planes and before returning. This is a
component for a possible cache; it does not replace any game drawing.

Two cases use the model's program-3/program-4 bounds: (64,71,192,30) and
(64,72,224,31). A deterministic byte LFSR initializes source, mask, destination
and guards. Both cases exercise all eight mask/image/destination bit combinations.
A native CPU reference uses `old XOR ((old XOR image) AND mask)`; the host oracle
independently uses the raster model's masked composition. Every byte of the
45,240-byte chip allocation is checked, including untouched destination, source,
mask and guards. The separate 40,000-byte CPU reference is also checked. Both
allocations are observed freed after the two cases.

The frozen VERIFY slave is
`51b84ed0c5c1070c9875cde576d1e44e3f586d33646ba36a019dd5c582d09046`
(text 250,714 bytes). Local captures `w6-overlay-blit-a500` and
`w6-overlay-blit-030` select CUSTOM2=32703, CUSTOM4=0 and CUSTOM5=512, maximum
detail / Time Scale 40, on the established A500 and cached 50 MHz 68030 setups.
**Each** passes two cases: 90,480 chip bytes and 80,000 CPU-reference bytes match
the host oracle, and both observed completion points have an idle blitter.

After the self-test, each boot captures ordinary programs 3 and 4 on both game
buffers. All 160,000 framebuffer bytes per boot again match `cockpit_raster.py`.
The existing native timing/input/presentation counters pass 426/512/638/133,
terrain/cache/list checks pass 2/1/2, and all 54 selected timing/pacing hook
checks pass. This also exercises the overlay probe on 68000. Both owned test
instances were quit. Host tests pass 220 cases; static audits cover 66 ranges
and 123 patch destinations with zero errors. Normal/developer builds retain
their W5 hashes.

Reproduce the private-buffer comparison with `overlay_blit_check.py` on the
capture's `blit-capture.json`, supplying an `--out` path. Raw chip and CPU buffers,
completion/free observations and the capture helper are retained with the local
evidence. These tests establish neither runtime cache integration nor a speedup.
Cache-key completeness, interpreter post-state, live pixel twins and measurements
remain required. W6's primary invariant remains consistent simulation speed
across rendering schedules; no rendering-component result closes that gate or
the separate smooth-50-FPS requirement.

The final source removes a redundant pre-68010-CCR-patch self-test invocation
from the captured build. The guarded test had already completed and freed its
buffers before the common invocation, which was a no-op on that path. The
common invocation remains once for all CPUs; the compositor and test bodies
are unchanged. The capture hash above identifies the measured binary, not this
subsequent call-site cleanup.
The cleaned build has 250,710 text bytes and SHA-256
`b85e2e4224fe32c99503ede9b07711eaa8c619b94cb081670e62b6e70ed35491`;
its 66-range and 123-destination static audits pass. Native captures above
precede this cleanup.


## Shape-list scale globals in equal-tick replay

The four differing bytes at `h3:04278..0427b` are the selected shape-list's
scale parameters. Native `sim:3994e` searches 12-byte records using the table
at `h3:04262` and count at `h3:0426a`. On a successful lookup it saves the
selected record pointer to `h3:0a278` at `sim:3997c`, then copies record words
6 and 8 to the two scale globals at `sim:39982` and `sim:3998a`.

The caller `sim:3a902` invokes lookup at `sim:3a91c`, saves the returned shape
pointer and tests it. Only successful lookup proceeds to `sim:3a34c` at
`sim:3a92e`. That helper reads the scale globals at `sim:3a350`, `sim:3a362`,
`sim:3a38a` and `sim:3a396`: 256 preserves the current value, -1 assigns the
second parameter, and the other branch multiplies, shifts and clamps. The
original executable's h3 relocation records identify exactly these six direct
scale operands (two writes, four reads). The selected-record pointer also has
two direct reads in `sim:399b0`, so its separate consumers cannot be assumed
irrelevant merely because this draw path initializes it.

`shape_selection.py` validates the selected pointer's alignment and membership
in the live table, requires a nonempty shape list, and checks both cached words
against that exact record. All **120 boundaries** of `w6-replay-normal-030`,
`w6-replay-slow-030-v2` and `w6-replay-none-030` pass. The rendered runs select
record indices 1 and 6, with scale words 256/256 and 255/90 respectively; the
no-render run retains record 6 throughout. Thus these observed four-byte
differences follow the last selected drawing resource rather than a differing
simulation integration result.

This identifies the source of the observed values, not a proof that every
indirect consumer is harmless. Raw differences remain in `world_comparison.py`;
no mask or normalization was added. In particular, the selected-record pointer's
other consumer and pointer aliases require their own dependency audit before
excluding this state from a whole-gameplay verdict. Reproduce with
`shape_selection.py CAPTURE --out REPORT`. Four host checks cover exact metadata,
stale scale, misaligned/out-of-table pointers and empty selected records.


## Current full-bundle Preferences clock boundaries

The current VERIFY build `b85e2e4224fe32c99503ede9b07711eaa8c619b94cb081670e62b6e70ed35491`
passes a real Preferences visit on the cached 50 MHz 68030 with CUSTOM2=16319,
CUSTOM4=0 and the existing CUSTOM5 bit-21/22 IRQ input fixture plus observer and
deferred activation. The fixture enters through F10 and leaves through Escape
using native keyboard state stores; it does not prove host keyboard mapping or
the CIA serial handshake. Maximum detail and Time Scale 40 remain selected.

`w6-current-modal-030` retains raw clock/player records at the Preferences wrapper,
native panel entry, pause-end entry, native caller return, and next completed
world boundary. Every stop's PC is checked. The completed world tick remains 8
through all four panel boundaries and advances to 9 after flight resumes.

| Boundary | CIA clock | PAL field counter | Completed world tick |
|---|---:|---:|---:|
| Before pause wrapper | 1191 | 66 | 8 |
| Native Preferences entry | 1191 | 67 | 8 |
| Native Preferences return, before resume handshake | 1412 | 254 | 8 |
| Resume complete | 1413 | 255 | 8 |
| Next completed world update | 1414 | 255 | 9 |

The panel excludes **222 CIA ticks**. The cursor advances by exactly the same
amount, preserving the existing **one CIA tick of debt**, rather than resetting
the cursor to the current clock. Primary/secondary fractional phases, due/service
counts and step/draw/skip counters remain unchanged across the panel. The full
280-byte player record matches at panel entry, exit and resumed caller return.
Flight ownership changes 1→0→0→1 and the native primary dt is 225 on resume.
This is a modal timing result, not an FPS sample or a whole-gameplay verdict.

`preferences_pause.py` independently checks these records, including duration
bounds from the observed CIA clocks and the first resumed world tick. Six host
tests cover preserved debt, an incorrect reset-to-now cursor, player/world
progress during the panel, phase corruption, counter wrap and truncated state.
Reproduce with `preferences_pause.py CAPTURE/preferences-capture.json --out REPORT`.
The native 426/512/638/133 checks, terrain/cache/list 2/1/2 checks and all 54 selected
timing/pacing destinations pass; both disabled overlay-probe ranges stay original.

An earlier decoded-register F10 attempt (`w6-natural-prefs-030`) never reached
its requested Preferences wrapper and is rejected. Subsequent decoded-register
Pause attempts (`pause-key` and `pause-key-v2` under the successful capture) also
failed to reach the pause wrapper; neither establishes a pause-key result. The
first Pause attempt was not restricted to the world input reader; restricting
the second did not resolve entry. Do not diagnose this as a game pause failure
without first proving that the injected command reached the dispatcher. These
attempts were interrupted at their checked stop assertions and retained separately.
Both owned emulator instances were quit. Native Pause, other modal paths and
restart/exit acceptance remain open; the next test should use a decoded IRQ
fixture with recorded acquisition and command consumption, not an unverified
register injection.


## Recorded native Pause input and clock exclusion

The VERIFY-only modal IRQ fixture now accepts **CUSTOM4=131072 ($20000)** to
select the native P/Pause command instead of F10. It requires W6 and CUSTOM5
fixture bits 21 and 22, retains the original eight recorded Right/Fire/modal/ESC
transitions, and never forces primary dt in this mode. Other unsupported CUSTOM4
combinations still fail. No player/developer feature or additional sim hook is
introduced. Native pause remains `sim:21ac4..21af2`, wrapped at `sim:21bf6`.

The frozen VERIFY build has 250,766 text bytes and SHA-256
`514ff999e0874a14f49ba34904a5d0fb396b63697de6bb8af2861b0858c1c528`.
`w6-pause-irq-030` uses CUSTOM2=16319, CUSTOM4=131072, the recorded modal IRQ
fixture, maximum detail / Time Scale 40 and the established cached 50 MHz 68030.
Unlike the preceding rejected register injections, this capture records native
command 25 at the post-input world boundary and then reaches the actual pause
wrapper and wait loop. Escape arrives through the native keyboard stores.

The five pause boundaries repeat the Preferences timing result: completed world
tick 8 before/inside/after the modal loop, then tick 9 on return to flight;
**222 CIA ticks excluded**, **one tick of old debt preserved**, unchanged clock
phases and due/service/step/draw/skip counters, and all **280 player bytes** equal
at entry/exit/resumed caller. `preferences_pause.py` checks this same modal
contract from the retained raw records and the PC-checked stop log.

All **80** post-input observations pass independent keyboard replay: eight
transitions are consumed and two commands (Fire and Pause) are popped exactly
once. The first Right-down occurs before flight owns input, with independently
recorded ownership tuple active=0, paused=0, start=0, base=0. It establishes held
Right but cannot become a flight command. Escape-down is modal and also remains
held-only. The old checker incorrectly assumed exactly three commands whenever
a modal fixture was selected. It now derives the command count from each
validated acquisition's ownership; an explicit corruption test rejects replaying
the preflight press as a command. Both earlier A500/68030 Preferences captures
still pass with their recorded three-command histories.

The native timing/presentation counters retain 426/512/638/133 and
terrain/cache/list 2/1/2; all 54 selected timing/pacing destinations pass, and
the two disabled overlay-probe ranges remain original. Normal/developer binaries
retain their W5 hashes. This establishes the recorded Pause path and its clock
boundaries, not host-keyboard acquisition, every modal/restart path, sustained
simulation capacity or complete frame-rate-independent gameplay.


The first A500 run of that same build did not validate Pause. Its retained
`w6-pause-irq-a500/interrupted-state.log` and acquisition clocks show all three
key-downs (Right, Fire and Pause) occurred before flight input ownership became
active. The native game correctly treated them as held-only; Escape later
arrived in flight and opened a different modal path. The capture was interrupted
for inspection and then quit. It is not a game pause failure or passing evidence.

The Pause fixture now establishes its acquisition epoch only after timestamped
input is ready and flight is active. This applies only to CUSTOM4=$20000;
the existing Preferences fixture keeps its original behavior. The revised build
has 250,834 text bytes. This corrects a CPU-dependent startup race in the test
fixture without changing the scheduler or discarding preflight input in the
checker. The revised collector also requires all first six fixture acquisitions
to have active-flight ownership and retains the epoch-ready marker.


The corrected build is
`15005c2aa3b8e0c826fabbe7be6f38ce1178e2acc251c21c3f16117bfc559eb3`.
Its A500 capture `w6-pause-irq-a500-v2` passes all 80 input observations, eight
recorded acquisitions and three commands. All first six acquisitions occur
under active flight ownership; Escape-down occurs in the native pause loop.
At the pause boundaries, completed world tick 10 remains fixed; the next
completed update is tick 11. Entry/resumed CIA clocks are 10319/10492 and the
excluded duration is **173 CIA ticks**. The pre-existing **48 CIA ticks of debt**
remain 48, demonstrating that the pause path preserves a substantial catch-up
backlog. Fractional phases, due/service and step/draw/skip counts stay unchanged,
and all 280 player bytes match. Native counters and the 54 selected/two disabled
hook checks pass. The owned A500 run was quit.


The same corrected build also passes `w6-pause-irq-030-v2`: 80 input observations,
eight acquisitions, three commands, and all first six acquisitions under active
flight ownership. Its native pause excludes **218 CIA ticks**, preserving **three
ticks of debt** and the same 280-byte player/clock invariants. Completed world
tick 10 is unchanged across the panel, then advances to 11. Both CPU runs pass
the native counters and selected/disabled hook audits; both owned emulators
were quit. The final static audits cover 66 ranges and 123 patch destinations
with no errors, and all **232 host tests** pass. Player/developer hashes remain
unchanged. This closes the tested native Pause input/accounting path, including
substantial old debt on A500, without claiming the remaining modal/restart,
full-state, combat, capacity or smooth-50-FPS gates.

To reproduce, boot the full W6 VERIFY mask with CUSTOM4=131072 and CUSTOM5=7340544
(observer, decoded-input fixture, modal extension and deferred activation).
Retain the capture's `capture-pause.py` alongside its exact slave/listing; run
it from the development harness after reaching the first flight checkpoint.
The helper records the real native Pause path and eight acquisition tuples,
checks all 80 post-input observations, and verifies the epoch-ready marker.
Then run `preferences_pause.py` on `preferences-capture.json` for the independent
modal clock/player comparison. This fixture is not a performance run.


## A500 consecutive per-field capacity census

The same VERIFY slave as the corrected Pause fixture,
`15005c2aa3b8e0c826fabbe7be6f38ce1178e2acc251c21c3f16117bfc559eb3`
(text 250834), was measured with CUSTOM2=16319, CUSTOM4=0, maximum detail,
Time Scale 40 (F=33), and no time compression. The rendered run uses CUSTOM5=512;
the control adds the no-render bit (CUSTOM5=1073742336). Each accepted run retains
four consecutive windows of exactly 250 PAL fields, 1,000 fields / 1,184 CIA ticks
overall. These are native publication/clock observations, not sampled CPU-cycle
profiles or a release-build performance claim.

| Observation | Rendered steady flight | No-render control |
|---|---:|---:|
| Completed world ticks per window | 41 / 41 / 42 / 44 | 41 / 40 / 41 / 41 |
| Newly funded world ticks, overall | 163.288350 | 163.288350 |
| Completed world ticks, overall | 168 | 163 |
| Started world ticks, overall | 167 | 164 |
| Update in progress, start → end | 1 → 0 | 0 → 1 |
| Publications per window | 2 / 1 / 2 / 2 | 0 / 0 / 0 / 0 |
| Overall rendered FPS | 0.35 | 0 |
| CIA debt, start → end | 50 → 19 | 0 → 1 |
| Sampled committed CIA debt range | 0–56 | 0–4 |
| Total backlog in world ticks, start → end | 7.941684 → 3.230034 | 0.895084 → 1.183434 |
| Sampled committed backlog range | 0.747609–8.853064 | 0.444579–1.686869 |
| Longest sampled span without world completion | 48 fields | 7 fields |
| Committed sample intervals | 975 | 984 |
| Retained transaction samples | 25 | 16 |

Total backlog includes fractional primary credit, queued due updates, the update
in progress and CIA time not yet collected by the scheduler. Its change equals
newly funded minus completed world ticks exactly, using rational arithmetic.
Both runs have zero MESSAGE/SHORTEN events; WORLD_BODY_DONE equals the completed
count in every window. Every rendered publication is in the safe beam region and
respects the one-field minimum. Native counters 426/512/638/133 and terrain/cache/
list counters 2/1/2 pass, as do 54 selected and two disabled hook ranges. Both
owned emulators were verified and quit after capture.

`sustained_capacity.py` requires at least four consecutive 250-field windows and
all 250 samples per window. It rejects missing fields, changed selection/rate,
compression, modal transitions and unknown transaction markers. Known clock
transactions remain in the evidence but their partially updated phase is not
interpreted: exact funding is checked from the preceding committed sample to
the next one. Rendered samples include 24 type-1 and one type-2 transaction;
the control includes 16 type-1 transactions. Sampled ranges are not proofs of
unsampled instantaneous maxima. The completion counter remains observable during
transactions, so those rows are retained in the completion-stall calculation.

The rendered capture is `tmp/dev/tmp/prof/w6-sustained-steady-a500-v2/`.
It continues the same boot after `w6-sustained-steady-a500/`, whose opening sample
was inside a type-1 clock transaction. That opening run is rejected, despite
apparently plausible aggregate counts. The collector was corrected to wait for
a committed VBlank before beginning the accepted census. The continuation is
explicitly recorded; this is not a fresh-state equivalence test. The control,
`tmp/dev/tmp/prof/w6-sustained-none-a500/`, starts on a fresh same-build boot after
at least ten completed world updates. Each capture retains `capture-census.py`,
`field-census.json`, raw endpoint RAM, per-window publication/event logs and
`sustained-check.json` / `sustained-check.log`.

To reproduce, boot the indicated A500 VERIFY selection with the development
harness, then run the retained `capture-census.py` with the capture directory and
`--windows 4`. Run `sustained_capacity.py` on `field-census.json`, supplying
`--out` for the JSON report. The collector samples the native pacing VBlank and
publication at sim:3154a, with event observers at sim:3c06, sim:3c7c and sim:11c8.
Debugger host pauses do not fund emulated CIA time. Use one capture at a time and
retain the exact slave/listing and native endpoint audits.

The rendered window executes nominal newly funded work and repays old debt over
20 PAL seconds, but its 0.96-second completion stall is a responsiveness limit.
The no-render control stays within a small sampled backlog. Different initial
states prevent treating these counts as a complete gameplay-state comparison.
Neither finite window closes event/bank/dense or cross-CPU capacity, input latency,
full-state/physics/combat correctness, or smooth 50 FPS. W6 remains VERIFY-only.
Four new host tests cover fractional accounting, conserved time with growing
debt, retained transactions and malformed/changed-rate samples; the full suite
passes 236 tests. No slave bytes changed for this analysis.


## A500 capacity with scheduled Right/Fire input

The previous build (`15005c2aa3b8e0c826fabbe7be6f38ce1178e2acc251c21c3f16117bfc559eb3`,
text 250834) was booted afresh with the full W6 VERIFY mask, maximum details,
Time Scale 40 and the existing CUSTOM5 bit-31 replay plus bit-20 observer and
bit-9 deferred activation. No forced dt or time compression is used. The four
scheduled events are Right-down/up then Fire-down/up at active-CIA origin 10155
plus 32/64/96/128 ticks. This is a brief input maneuver, not continuous banking
or physical keyboard acquisition.

First, inspection rejected the legacy CUSTOM5 bit-1 banking preset for W6:
`tape.s` skips that bitmap injection once `time_keys_ready` owns flight input.
The boot-only `w6-sustained-bank-a500` evidence is marked rejected and was quit;
it supplies no banking/capacity claim. No emulators ran concurrently.

The accepted capture is `tmp/dev/tmp/prof/w6-sustained-replay-a500/`. Its census
starts at the first completed world update, then the next committed pacing
VBlank. It samples four 250-field windows, followed by four more from exactly
the paused endpoint. The collector asserts the complete opening state of each
appended window equals the preceding closing state; no flight time is discarded.
The independent `sustained_capacity.py` checker validates all eight windows and
both four-window halves separately.

| Window | Completed world ticks | Native publications |
|---|---:|---:|
| 1 | 34 | 1 |
| 2 | 41 | 2 |
| 3 | 40 | 3 |
| 4 | 42 | 2 |
| 5 | 41 | 2 |
| 6 | 41 | 2 |
| 7 | 41 | 2 |
| 8 | 41 | 2 |

Each window spans 250 fields / 296 CIA ticks and funds 40.822087542 world
updates. Across 2,000 fields / 2,368 CIA ticks, 321 world updates complete versus
326.576700337 newly funded; 322 start, leaving one update in progress. The
16 publications yield 0.40 FPS. Every window has zero MESSAGE/SHORTEN events,
and WORLD_BODY_DONE equals its completed-world count. Publication beam/cap and
exact funding checks pass.

Total backlog (fractional credit, due work, in-progress update and uncollected
CIA time) is 0.137912458 initially, 6.426262626 at the midpoint and 5.714612795
finally. Thus the first 20 seconds add 6.288350168 ticks of debt, while the next
20 seconds repay 0.711649832. Uncollected CIA debt is 1 → 40 → 34. Committed
samples range from 0 to 64 CIA ticks of debt and 0.137912458 to 9.895084175 world
ticks of total backlog; the second-half maxima are 53 and 8.439326599. These
are sampled ranges, not instantaneous bounds.

All 2,000 fields are retained. There are 1,963 committed intervals and 37
transaction samples bridged by exact funding checks. The longest sampled span
without a world completion is 55 fields (1.10 PAL seconds); it remains 46 fields
in the second half. The deficit therefore does not keep increasing in this
finite continuation, but rendering still stalls simulation for visibly long
intervals. Neither retained debt nor this aggregate completion rate establishes
responsive gameplay or full W6 acceptance.

The collector also observes native post-input sim:21d30 on every world update.
`check-replay.py` validates the four 16-byte scheduled records against their
origin and spacing, then uses `keyboard_replay.py` to check all 322 observed
rows against those deadlines. Its acquisition-oracle adapter uses deadline−1
solely to express the scheduled eligibility boundary; it does not claim physical
acquisition. All four events are consumed, exactly two commands are popped,
held Right/Fire and releases reach their expected ticks, and the native X axis
and Fire flag agree. The final queue and counters have no dropped, repeated,
overflowed or pending events. This verifies input consumption, not projectile
outcomes, aircraft trajectory or full simulation-state equivalence.

Native self-test counters 426/512/638/133 and terrain/cache/list 2/1/2 pass;
54 selected and two disabled hook ranges pass. The owned emulator was verified
and quit. Retained evidence includes the exact slave/listing, `capture-census.py`,
`check-replay.py`, native queue/record/counter bytes, per-window logs and RAM,
`scheduled-replay-check.json`, and the complete and half-run capacity reports.
Reproduce with the existing replay boot selection, run the retained collector
with `--windows 4 --from-first-world`, then `--windows 4 --append` at its paused
endpoint; run the retained replay checker and `sustained_capacity.py` afterward.
No source/slave bytes changed. Event/dense/continuous-bank and cross-CPU capacity,
full gameplay correctness, input latency and smooth 50 FPS remain open.


## Shape-selection ownership across rendering

W6 now leases the named shape-selection globals with the existing outer-render
owner: scale words at h3:4278..427b and selected-record pointer at h3:a278..a27b.
The native lookup at sim:3994e sets all eight bytes together; the separate part
lookup at sim:399b0 also consumes the pointer. Restoring the pair prevents the
last drawn resource from becoming the simulation's next selected resource.
This changes only VERIFY CUSTOM2 bit 13 through the existing sim-v1 render
hooks. No whole-h3 snapshot or global-state exclusion is introduced.

The entry/exit helpers copy the eight named bytes; they do not dereference the
selected resource. `shape_lease.py` independently checks entry, pre-restore and
return snapshots, the exact saved bytes, pointer/scale coherence and unchanged
resource descriptor/table contents. Changed-value coverage is mandatory by
default. Its explicit `--allow-unchanged` mode reports preservation with
`changed_value_coverage=false` rather than implying a changed value was restored.
Resource reload, other consumers and full gameplay-state comparisons remain
separate gates.

The same native copy helpers also run a startup self-test on private guarded
storage. Three scale/pointer patterns include zero/all-ones and both observed
scale pairs. Each case verifies saved bytes, complements both private values,
restores them, compares every byte and checks both guard words. The host checks
the exact case table, final private state and three-case completion counter.
No fixture writes live h3 or changes input/gameplay. The self-test is placed
after the existing patch targets: an intermediate layout exceeded the signed
patch displacement to the flight observer and was rejected before boot.
The final 123-destination reachability audit passes.

The final VERIFY build has 251082 text bytes, SHA-256
`63f553029f241ff1ac2242fd1ec34f363ff70b55023e14a67044651674577484`.
In `tmp/dev/tmp/prof/w6-shape-selftest-a500/`, both natural complete render calls
preserve the resource table and restore entry state. At completed tick 34,
selection changes **record 6 / scales 255,90 → record 1 / scales 256,256 →
record 6 / scales 255,90**. Thus one naturally changed selection is restored,
with no debugger mutation. The earlier tick-1 call retains record 6 throughout.
All three native private cases pass (24 restored bytes), including guards.
The existing render-phase checker validates 70 poses, 54 changed visual poses,
shared-list restoration, terrain state, clocks and stack boundaries, with no
world update inside either render call.

Earlier cached-68030 captures from the intermediate build
`05685957192b124fbd39b4ddd13bdde3e5067718b9684987ae9d225effd68f9e`
are retained under `w6-shape-restore-030/`. Their natural calls preserved entry
selection but did not exercise a different final selection. The first capture
also crossed a no-draw startup invocation and one world update; that row was
rejected. The collector now waits for `time_render_started` before taking an
entry snapshot. Attempts in `seeded/` and `restore-fixture/` to create changed
values with debugger memory writes were ineffective: the Barto stub ignores
those writes, as documented in the development playbook. Both directories are
explicitly marked rejected as mutation evidence. Their fixture labels describe
attempted actions, not observed state. They do not substitute for the final
native self-test or natural A500 changed-value capture.

Five host checks cover changed selection, missing restoration, mismatched saved
bytes, resource-table mutation, truncated state and native private-test evidence
corruption. All 241 host tests and the 66-range hook audit pass. No rendering
speedup, safe mid-render simulation yield, complete global-state isolation or
50 FPS acceptance follows from this ownership change.

The same final build in `w6-shape-selftest-030/` passes all three private cases
on the cached 50 MHz 68030 configuration. Its two natural render calls both
retain their entry selection, explicitly reported as no changed-value coverage;
the A500 call above supplies the natural changed case. These 68030 calls check
66 poses (42 changed visual poses), with two render iterations at completed
world tick 1 and no world execution inside either. Both configurations pass
the existing 426/512/638/133 and terrain/cache/list 2/1/2 self-test counters,
54 selected hooks and two disabled ranges. Both owned emulators were verified
and quit.

Normal/developer output hashes remain respectively
`5256542f87ec1c6d3eca174416560597a60e76e1cc785cd0fbf5e3efff3f0ba8` and
`01a00068d799b01c9b17a06bc7b2ce87acf88f22c23f870afd476d4e46a6adc3`.
Each final capture retains its exact slave/listing, before/pre-restore/after RAM,
private test bytes, capture/check helpers and JSON results. Reproduce with the
full W6 replay selection, the retained `capture-render.py --frames 2`, then
`shape_lease.py` and `render_phase.py` on `render-phase.json`. The retained
`check-native.py` reads private test evidence without writing guest memory.
Use `--allow-unchanged` only when explicitly reporting the 68030 preservation
case; the A500 changed-selection check passes without it.


## Full-bundle equal-tick replay after shape restoration

The shape-restoration build
`63f553029f241ff1ac2242fd1ec34f363ff70b55023e14a67044651674577484`
was booted independently on cached 50 MHz 68030 with CUSTOM2=16319, maximum
detail and Time Scale 40. Both boots use the existing scheduled Right/Fire
replay, observer and deferred activation. One additionally selects CUSTOM5 bit
30 to omit rendering; no other option differs. This tests the full VERIFY
performance bundle, unlike the earlier timing-only CUSTOM2=8192 comparison.

Evidence is `tmp/dev/tmp/prof/w6-shape-replay-normal-030/` and
`tmp/dev/tmp/prof/w6-shape-replay-none-030/`. Each retains full RAM at 40 consecutive
completed-world boundaries (ticks 0–39), an untouched initial checkpoint, lifecycle
records, exact slave/listing and native endpoint checks. Both initial states have
identical h3, complete player record, all four sim segments, and all 105 tracked
game allocations (243,855 bytes). Pointer/layout differences are not normalized.

`world_controls.py` confirms the same four-event input history and all 40
per-tick snapshots, including bank/fire held intervals and exactly two command
pops. `native_poses.py` independently checks 1,352 poses, 129 lifecycle events
and 59 invalidated history records in each capture. At every equal tick:

- The complete 280-byte player record matches.
- All 1,352 registered object prefixes across the window match, as do the
  primary registry, camera state, shared display-list order/count and lifecycle
  events. Prefixes alone are not a complete-object proof.
- The selected shape pointer and both scale words match (320 bytes compared):
  both retain record 6 with scales 255/90. The earlier observed scale divergence
  is absent without excluding these fields from comparison.
- Every differing shared allocation is a 392-byte sound context, with only
  payload byte 345 (the low byte of word 344) changed. Each address is checked
  against the sound pointer table at h3:a184; contexts 0, 1 and 2 appear across
  the window. This identifies the differing bytes, not sound-event equivalence.
- One extra 1,808-byte allocation (1,800 payload bytes plus header) appears only
  with drawing at ticks 33–39. All other shared game-allocation bytes agree.

| Schedule | World updates between endpoints | Completed draws | PAL fields / CIA ticks | Final uncollected CIA debt |
|---|---:|---:|---:|---:|
| Ordinary | 39 | 41 | 242 / 286 | 3 |
| No rendering | 39 | 0 | 239 / 283 | 0 |

Exact funding passes for every interval. These are equal-tick correctness
captures, not fixed 250-field performance samples or sustained-capacity evidence.
In particular, 41 draws for 39 world updates exercises render-only iterations
without adding simulation updates. The differing elapsed time/debt is retained.

The raw final h3 inventory still differs in 1,229 bytes. The other sim segments
retain respectively 87, zero and 15 differing bytes. The 15-byte auxiliary
segment difference lies in copper bitplane-pointer data; the primary segment
also contains embedded mutable drawing data and the CIA lifetime counter.
These observations do not classify every byte or computed consumer. All raw
ranges remain in `heap-inventory.json`; no whole-gameplay equality verdict or
new exclusion mask is introduced. Broader physics/combat, camera/modal, sound,
CPU/scene capacity and smooth-50-FPS gates remain open.

Both endpoints pass native counters 426/512/638/133, terrain/cache/list 2/1/2,
all three private shape-restoration cases, and 54 selected plus two disabled
hook ranges. Both owned emulators were verified and quit. No slave/source bytes
changed for this comparison. Retained `summarize.py` checks the scoped facts
above against raw snapshots; it does not substitute for the unfiltered inventory.
Reproduce using each retained `capture-poses.py --steps 40`, followed by
`world_controls.py` and `world_comparison.py` with the ordinary and no-render
capture directories. Run `native_poses.py` on each `poses.json` and
`shape_selection.py` on each capture. The summary and all raw differences remain
available beside those reports.


## Sound-context elapsed-word classification

The differing shared-allocation byte in the equal-tick replays is the low byte
of the context word at payload offset 344. Original sim code treats this as an
elapsed/position counter for sound playback. `sim:33b64` clears it when starting
a context; `sim:34e9a` increments it only after testing playback state byte 361
and the pause byte 360. `sim:34eca` clears it on the start path, and `sim:34f44`
clears it after a nonzero driver result. A second sequencer path increments it
at `sim:34f96`. The native query at `sim:33dd2` reads it, divides by 3600 then
60 and halves the final remainder to produce position components. This describes
its arithmetic; it does not establish a measured interrupt frequency.

`sound_elapsed.py` checks the exact original instruction bytes for these named
operations, the query, and the separate counter snapshot/restore instructions
at `sim:35260` and `sim:3581c`. Those latter paths require another dynamic model
and are rejected if encountered in the audited capture. This is not a complete
computed-alias or gameplay-consumer proof, so the word remains visible in all
raw state comparisons.

The independent dynamic check uses already-retained A500 instruction and CPU
bus-write records from `tmp/dev/tmp/prof/w6-capacity-a500-full/`, build
`1a0677e18c874809ae0270549b4efbeaae6d778d4d3e210a6f936fafbca7e1b8`.
It groups operations by the actual context pointer, checks the recorded IRQ
stack for the audio-service operations, then matches every counter write against
the separate bus stream. An observed reset establishes zero; later increments
must equal the preceding word plus one modulo 65536. An operation/write count
mismatch or a bus write outside the same/next field fails. Unseeded leading
increments remain retained but unverified. Each chunk starts a fresh model;
no state is carried over the known missing profile-boundary fields.

| Chunk | Recorded fields | Counter writes | Verified after observed reset | Leading unverified |
|---|---:|---:|---:|---:|
| capacity-0 | 100 | 436 | 430 | 6 |
| capacity-1 | 100 | 501 | 468 | 33 |
| capacity-2 | 50 | 150 | 147 | 3 |
| Total observations | 250 | 1087 | 1045 | 42 |

Across these separate chunks, `sim:34e9a` executes 853 increments on the IRQ
stack, `sim:34f44` executes 220 IRQ resets and `sim:34eca` executes seven IRQ
start-path resets. Seven main-task resets occur at `sim:33b64`. All 1,045 seeded
bus values agree with the model. Five distinct contexts occur in the first two
chunks and two in the final chunk. These counts are observations, not a
continuous 250-field timing window or an audio-event equivalence result.

This explains why equal simulation ticks may retain different sound-counter
values when their actual elapsed time and audio-interrupt progress differ. W6
must not force this counter onto the world clock or restore it after rendering:
that would alter the explicitly preserved native sound domain. It does not yet
prove identical event requests, Paula delivery or every consumer, so those sound
checks remain open. No sound behavior or slave bytes changed in this work.

Retained results are `capacity-0-sound-counter.json`,
`capacity-1-sound-counter.json` and `capacity-2-sound-counter.json` beside the
capture. Reproduce with `sound_elapsed.py ORIGINAL_SIM CAPTURE CHUNK --out REPORT`.
Four new host tests cover reset/increment sequences, explicitly unverified
leading data, unsigned-word wrap and corrupted/missing/misaligned writes. The
full host suite passes 245 tests.


## Ground-impact grading and native flight exit

The same full-bundle VERIFY build `63f553029f241ff1ac2242fd1ec34f363ff70b55023e14a67044651674577484`
was booted twice on cached 68030 at 50 MHz, maximum detail, Time Scale 40,
CUSTOM2=16319. The native ground fixture supplies a synthetic descent; the
control additionally disables rendering. These are correctness captures, not
performance measurements or safe-landing/convergence acceptance.

Retained captures are `w6-ground-normal-030-v2` and `w6-ground-none-030` in the
ignored profiling directory. Initial h3, all four sim segments, player record
and 105 game allocations (243,855 bytes) agree. The fixture begins at altitude
512 and vertical velocity −1024, but deferred activation includes a native
prelude: completed-pose boundary zero already has altitude 208 and velocity
−920. Do not attribute that prelude to one W6 update.

Both captures reach one actual player call to `sim:192d8` during world tick 1.
Its arguments are angles 256/0, horizontal speed 1286, vertical speed −886,
prior damage zero, and limits 1845/277/6000/8000/−3200. Native grading returns
2, exactly matching the independent signed-width model in `ground_contact.py`.
The model binds the original routine bytes and checks entry/result pairing;
it covers angle and speed thresholds, arithmetic-word overflow, the native
most-negative-angle special case and prior signed-byte damage. It does not
model collision detection. Immediately before correction the player altitude
is 36; completed boundary 1 has altitude 50 and vertical velocity zero,
which persist through boundary 14.

**The full player-state comparison fails and remains an open W6 gate.**
Boundaries 0–2 match all 280 bytes. At boundaries 3–14, byte +36 is 0x41 with
rendering and 0x61 without it (bit 5). The other 279 bytes agree. All 463
registered-object prefixes, camera state, registry, shared display list and
lifecycle events agree. Held keys, command queue and consumption counters also
agree at every boundary. Prefix equality does not cover this player flag.
Static inspection identifies `sim:15c82`/`sim:15ca0` as setters/clearers of
object byte +36 bit 5; `sim:15cc6` reads it when restoring object byte zero
bit 7. Dynamic provenance and complete consumer scope remain to be established;
this difference must not be normalized away or declared harmless.

Both clocks pass exact funding. Across the 14 completed-update intervals the
rendered run advances 90 fields/106 CIA ticks with 16 draws and four remaining
uncollected CIA ticks; the control advances 86 fields/102 CIA ticks with zero
draws and zero uncollected ticks. Final raw h3 differs in 3,108 bytes; the other
three sim segments differ in 138/0/0 bytes. The final shared-allocation difference
is the same single player byte. All raw differences remain in
`heap-inventory.json`; this is not a whole-state equality verdict.

Both runs return value 1 through the native flight-exit caller after started
tick 15, with last captured pose boundary 14. The pose header is updated at the
next loop entry, so these counters alone do not mean tick 15 was abandoned.
The return value survives W6 cleanup, and active/input-ready flags become zero.
Native counters 426/512/638/133, terrain/cache/list 2/1/2, all three private
shape cases and the live 54-selected/two-disabled hook audit pass before unload.
Both owned emulators were verified and quit.

The first ordinary attempt (`w6-ground-normal-030`) retained the same impact
but its collector waited for another pose boundary after flight exit. Its late
hook audit encountered unloaded sim memory and is rejected. The corrected
collector explicitly catches the exit before unload; only the v2/control pair
supports the exit and hook claims above.

Each successful capture retains `capture-ground.py`, `check-exit.py`, raw
entry/result events, full RAM snapshots, `contact-check.json`,
`flight-exit.json` and `exit-cleanup.json`. Reproduce the grading check with
`ground_contact.py ORIGINAL_SIM CAPTURE --out REPORT`; compare raw states with
`world_comparison.py`. Four new host tests bring the passing suite to 249.
No slave bytes changed. Next: trace the byte +36 bit-5 divergence and preserve
native temporary-state semantics before claiming ground-contact independence.


## Ground-impact render scratch restoration

The byte +36 discrepancy above is resolved in VERIFY build
`c54a84f748481dfb0583651ab79e04a0321086b17d3325172138ad9060122e7b`
(text 253,532 bytes). It remains behind W6 bit 13 for sim v1. Normal/developer
binaries retain their W5 hashes; there is no release promotion or performance claim.

The read-only native trace `w6-ground-flags-030` confirms the writer and consumer:
after completed tick 2, `sim:15ca0` sees player byte +36 = 97 (0x61), then
`sim:15cc6` consumes 65 (0x41). The next completed-world snapshot retains 65.
The outer renderer calls `sim:15c62` via `sim:007a0` before the 3D pass, then
`sim:15cac` via `sim:007bc` afterwards. The former saves object byte-zero bit 7
in byte +36 bit 5; the latter restores byte-zero bit 7 from that temporary bit.
W6's projection-cache snapshot begins after this temporary write, so it cannot
recover the earlier scratch value.

Two original-byte-checked hooks now journal byte +36 before native BSET/BCLR
at `sim:15c82`/`sim:15ca0`. The original operations and their consumer still
execute; reverse undo at the outer draw return restores the pre-draw byte.
The journal remains inactive outside W6 presentation. Wrappers preserve all
registers and incoming CCR before replaying BSET/BCLR, which modify only Z.
The existing journal handles duplicate/overlapping writes in reverse order.
This deliberately restores named temporary state, not the entire object or h3.

`visibility_scratch.py` independently models both byte operations and their
condition codes. The private native test exhausts all 256 old bytes for each
operation: 512 retained byte/CCR results match Python, each journaled byte
restores exactly, and inactive-owner calls create no records. Host tests also
exhaust all 32 incoming CCR combinations and reject truncated, reordered and
corrupted result streams. All 251 host tests pass. Static checks cover 68 hook
ranges and 125 signed patch destinations with no errors. The late VERIFY
installer and data buffers preserve patch reach; the observer's distant CUSTOM5
load uses full-displacement position-independent access.

A first candidate passed the private cases but failed activation because its
nested installer did not preserve registers across `resload_Patch`. The native
error and rejected capture `w6-ground-restore-030` are retained. The corrected
installer has its own saved-register envelope; that failed boot supplies no
gameplay evidence.

Fresh same-build cached-68030 50 MHz ground runs, maximum detail and Time Scale
40, are retained as `w6-ground-restore-030-v2` and
`w6-ground-restore-none-030`. Initial h3, all four sim segments and game
allocations agree. All 15 completed-world boundaries now match the full
280-byte player record, including byte +36, without exclusions. All 463
registered prefixes and 463 separately checked normal-object scratch bytes
match, as do registry, camera, display-list/lifecycle state and the held-key,
command-queue and consumption histories. Both actual impact calls still match
the independent grade-2 model. Both return value 1 at native flight exit with
started tick 15/last pose 14 and clear active/input-ready state correctly.

Across the 14 completed intervals, the ordinary run has 16 draws over 91 fields
and 106 CIA ticks; the no-render run has zero draws over 87 fields and 102 CIA
ticks. Their uncollected CIA debt ends at four/zero respectively. Exact funding
passes both. These short correctness windows are not FPS/capacity measurements.
Native counters 426/512/638/133, terrain/cache/list 2/1/2, three shape cases,
512 scratch cases and 56 selected plus two disabled hook ranges pass in each.
Both owned emulators were verified and quit.

Raw differences remain: final h3 differs in 3,108 bytes and the other segments
in 138/0/0. Some intermediate boundaries differ in sound context slot 1 at
payload bytes 345, 348, 349 and 361; only the first is covered by the earlier
elapsed-word classification. These are retained as open sound-state/consumer
work, not normalized away. Final shared game allocations agree. No claim of
all-global, sound-event, combat or cross-CPU equivalence follows from this fix.

Each capture retains the exact collector, exit checker, expanded hook audit,
full snapshots and reports. `summarize.py`/`ground-summary.json` assert the
scoped comparison without changing `heap-inventory.json`. Reproduce private
cases with `visibility_scratch.py CAPTURE --out REPORT`. The broader physics,
modal/camera/combat, sustained-capacity and smooth-50-FPS gates remain open.


The same-build A500 check `w6-ground-restore-a500` also passes all 512 private
scratch cases, the existing native counters/shape cases and 56-selected/two-off
hook audit. Fifteen boundaries validate 463 poses; native impact grade 2 matches
the model with angles 192/0, speeds 1301/−869 and pre-correction altitude −70.
Its prelude differs from the 68030, so it is not an equal-initial-state CPU
comparison. It reaches the same return-value-1 flight exit and clears ownership.
There are **zero W6 draws** by boundary 14: only the pre-activation flag consumer
appears in the trace. This validates the 68000 private wrappers and flight path,
not natural changed-scratch render coverage on that CPU. The owned emulator was
verified and quit. Retained collectors and all raw results remain with the run.


## Ground contact under deliberately delayed rendering

The scratch-restoration candidate above also passes the scoped ground comparison
with the existing CUSTOM5 bit-0 delay fixture. The fresh capture
`w6-ground-restore-slow-030` uses the same `c54a84f7…` VERIFY binary, cached
68030 at 50 MHz, CUSTOM2=16319, maximum detail and Time Scale 40. It is compared
with `w6-ground-restore-030-v2`; the no-render reference remains
`w6-ground-restore-none-030`.

Initial h3, full player record and game allocations agree. The only initial
sim-code difference is the JMP destination at `sim:015b2`: ordinary rendering
jumps directly to `sim:2c552`, while the fixture jumps through its beam-wait
wrapper. The exact target is checked against each capture's frozen listing;
all other initial sim segments agree. This explicit test-code difference remains
in the raw inventory rather than being masked as gameplay state.

Read-only breakpoints bracket each wait. Eleven observed calls each cross
three VBlank-counter increments and three or four CIA ticks. One call belongs
to the native prelude; ten have started-world IDs greater than zero. The
corresponding W6 completed-draw count is ten. Thus the fixture demonstrably
changed the draw schedule, not merely a selected option.

| Schedule | Completed update intervals | Draws | PAL fields | CIA ticks | Final uncollected CIA debt |
|---|---:|---:|---:|---:|---:|
| Ordinary | 14 | 16 | 91 | 106 | 4 |
| Delayed 3D | 14 | 10 | 89 | 105 | 3 |
| No rendering | 14 | 0 | 87 | 102 | 0 |

These are tick-bounded correctness observations, not 250-field performance or
sustained-capacity samples. Delaying each draw reduces the number of draws;
it need not increase the time to the same simulation endpoint. Exact funding
passes all three, with remaining debt and fractional credit retained.

Across all 15 boundaries, ordinary versus delayed rendering agrees on all
280 player bytes, 463 registered prefixes, 463 normal-object scratch bytes,
registry, camera, display-list order and lifecycle events. Held keys, the command
queue and consumed-input counters agree. The observed ground-impact call has
the same arguments and independently modelled grade 2. Flight exit still returns
1 with started tick 15/last captured pose 14 and clears active/input-ready state.
This adds a third rendering schedule for this fixture; it does not replace
independent physics/flag models or cover other gameplay scenes.

The final raw h3 difference is 32 bytes, and the other sim segments differ in
12/0/0 bytes (including the deliberate JMP target). Shared allocation differences
throughout this comparison occur only in sound contexts 0/1 at payload byte 345,
the elapsed-word low byte previously classified. They remain visible. The
remaining global differences are not all classified, so this is not a complete
world-state equivalence verdict or an audio-event acceptance result.

The delayed run passes native counters 426/512/638/133, terrain/cache/list 2/1/2,
three private shape cases, 512 scratch cases, 56 selected/two disabled hook ranges,
and 463 pose checks with 40 lifecycle events/16 invalidations. The owned emulator
was verified and quit. No source/slave bytes changed for this comparison.

Retained `capture-ground.py` records `DELAY_ENTER`/`DELAY_LEAVE` alongside the
world snapshots, impact and flag-consumer observations. `summarize.py` verifies
the named state, exact initial JMP targets and delay pairing, producing
`scoped-state.json` and `delay-check.json`; `heap-inventory.json` remains the
unfiltered comparison. Reproduce with `w6_boot_current.py 030 16319 CAPTURE
--probe ground --slow`, the retained collector (`--steps 20`), the native checks
before unload, then `world_comparison.py` against the ordinary reference. The
same-build reference and matching initial world state are required.


## Sound-service timer provenance in the remaining global differences

The ordinary/delayed ground comparison's changed byte at `h3:03f5d` belongs to
a six-byte timer rooted at `h3:03f5a`: a CIA start timestamp followed by a
16-bit duration. It is distinct from the per-context elapsed counter at sound
payload offset 344 discussed above. Original code passes this timer to the
start routine from `sim:2abce` and `sim:2ad8a`, in paths that inspect or operate
on sound contexts. The former follows the context byte-348 inactive test;
`sim:2b476` passes the same timer to the force-expired routine.

The original shared timer contract is precise:

- `sim:29760` stores `sim:30006` as the start and truncates the supplied duration
  to a word. It reads the native CIA lifetime counter, not W6 world ticks.
- `sim:2977e` clears the duration and stores CIA-now minus one, modulo 2^32.
- `sim:2972c` returns a true low-word Boolean when unsigned
  `(CIA-now − start) > duration`; equality has not expired. If the timer-service
  enable word at `sim:3015a` is zero, it returns true directly.

`native_timer.py` independently models these unsigned-width operations and binds
the complete original `sim:2972c–29794` routine bytes by hash. It rejects missing
or mismatched entry/result pairs. A CIA change between observed endpoints is
retained explicitly as an unverified store; the checker never silently treats
a possible interrupt crossing as an exact match. At least one verified store
is required. Every full snapshot must also match the last observed six-byte
store, so a later unobserved net mutation cannot pass the checkpoint check.

A fresh read-only capture, `w6-ground-sound-timer-030`, uses the same
`c54a84f7…` full W6 VERIFY build, cached 68030 at 50 MHz, Time Scale 40 and the
ground/delayed-drawing fixtures. Breakpoints bracket the actual timer store at
`sim:2976c` and its result at `sim:29778`, conditioned on the exact timer address.
All three observed starts agree with the model:

| Started world tick | CIA before and after | Stored start | Stored duration |
|---|---:|---:|---:|
| 0 (native prelude) | 1114 | 1114 | 5 |
| 1 | 1138 | 1138 | 5 |
| 10 | 1206 | 1206 | 5 |

There are zero interrupt-straddling/unverified observations. All 15 completed
pose snapshots retain exactly the most recent observed timestamp/duration;
the last is 1206/5. No force-expired or predicate call is claimed as dynamically
covered by this run: their semantics have original-code and host-model evidence
only. The timer's complete indirect consumer scope and sound request/delivery
sequence are still open. This explains the clock-derived differing field; it
does not authorize removing it from raw comparisons or certify sound equivalence.

Native counters 426/512/638/133 and terrain/cache/list 2/1/2 pass; 56 selected
and two disabled hooks pass before unload. The native flight return remains 1
and ownership cleanup succeeds. The owned emulator was verified and quit.
No sound behavior or slave/source bytes changed. Three new host tests cover
unsigned clock wrap, duration truncation, strict expiry, disabled service,
corrupt/missing pairs and retained interrupt uncertainty; the suite passes 254.

The capture retains `capture-timer.py`, raw event logs and full snapshots,
`timer-check.json`, the exit checker and hook audit. Reproduce the model check
with `native_timer.py ORIGINAL_SIM CAPTURE --out REPORT`. Remaining raw global
ranges, including cockpit/geometry scratch candidates, still need their own
writer/consumer audit; this does not close the whole-state W6 gate.


## Cockpit rectangle-history ownership

Six bytes in the ordinary/delayed ground run's final 32-byte h3 difference lie
inside `h3:07134–071a3`. This is a 112-byte history table: seven cockpit items,
each with two eight-byte `(x, y, width, height)` records. The native code indexes
it as `16 × item + 8 × selector`; the observed selector is zero or one.
It is initialized with size 112 at `sim:19760`, read before drawing at
`sim:19d02–19d20`, and updated with callback-produced bounds at
`sim:19da2–19dde`. The native selector is then XORed with `h3:08dcc` at
`sim:19df6–19e06`. This is stored drawing history, not an aircraft pose.

On the partial redraw path, the previous rectangle determines the clip:
`xmin = x − px`, `xmax = x + width + 2×px`, and the analogous Y pair.
All arithmetic wraps as signed native words; padding at `h3:01b1a/01b1b`
is signed bytes. The full redraw path instead calls the viewport helper.
After drawing, two native longword copies replace just the selected eight-byte
record with the callback result. The other thirteen records must persist.
Restoring this table to its pre-draw contents would discard history that the
next draw uses; it must not be added blindly to the simulation undo journal.

`cockpit_history.py` binds the original `sim:19cfc–19e0a` bytes and independently
checks slot selection, the old value consumed, the partial clip arithmetic,
copy source/result and the complete table at each checkpoint. It rejects
reordered/incomplete operations, stale reads, wrong destinations and any net
mutation not accounted for by the observed copies. It does not model the
callbacks' geometry or the full-viewport helper, and it never masks raw h3.

The fresh read-only `w6-ground-cockpit-rect-030` capture uses the unchanged
`c54a84f7…` full W6 VERIFY binary, cached 68030 at 50 MHz, maximum detail,
Time Scale 40, synthetic ground contact and the draw-delay fixture. It observes:

- 14 copies, covering every item/selector pair once; four actually change bytes.
- Seven partial clips matching the independent model exactly.
- Seven full-viewport paths retained but not modelled as partial clips.
- All 112 bytes matching the sequential model at all 15 world checkpoints.

The final table is byte-identical to the earlier delayed-run table, reproducing
its six-byte difference from ordinary drawing. The changed table offsets are
`h3:07139`, `07155`, `07159`, `0715b`, `07197` and `0719b`. This establishes
what owns those observed bytes and how the native draw consumes them. It is
not a blanket proof of every indirect consumer or of rendered pixels, and
it does not establish whole-gameplay independence.

Native counters 426/512/638/133 and terrain/cache/list 2/1/2 pass; 56 selected
and two disabled hooks pass before unload. Native flight exit returns 1 and
clears W6 ownership. The owned emulator was verified and quit. No slave/source
bytes or sound behavior changed. Four model tests cover all disjoint slots,
signed clipping/wrap, exact copies/untouched storage, stale data and missing or
corrupt event sequences. The full host suite passes 258 tests.

The capture retains `capture-rect.py`, all `RECT_READ/CLIP/STORE/AFTER` logs,
full snapshots, the exit checker and hook audit. Reproduce with
`cockpit_history.py ORIGINAL_SIM CAPTURE --out REPORT`; `rect-check.json` records
the model and coverage counts. Remaining geometry/global ranges and broader
physics/combat/camera/capacity/50-FPS requirements are still open.


## Vertex-cache epoch ownership

The three coordinate arrays at `h3:0a5e6`, `h3:0a9e2` and `h3:0adde`
contain 255 longwords each (3,060 bytes total). `sim:3a8b4–3a900`
selects a model part's source vertex table and clears exactly its vertex-count
bytes at `h3:0a4e6`. The coordinate arrays themselves are not cleared.
A nonzero validity byte permits reuse within that part. Therefore a final
array difference alone does not establish a simulation leak: the next part
must invalidate its entries before reuse.

`geometry_cache.py` checks the observed sequence of resets, fetches and results,
binding the original reset and three fetch routines by their code hashes.
Every hit must match a preceding calculation in the same epoch; indices must
be below the current part's count. Every observed reset has an all-zero sum of
its unsigned validity bytes. The 32-bit miss path at `sim:38dcc` uses the
existing independent original/candidate transform models, plus wrapped longword
translation. The verifier also checks the scratch copy for all three paths
and compares all 3,060 coordinate bytes with the accumulated writes at every
world checkpoint, rejecting any unobserved net mutation. It never filters the
raw state comparison.

The unchanged `c54a84f7…` full W6 VERIFY build was captured read-only in
`w6-ground-geometry-030`: cached 50 MHz 68030, maximum detail, Time Scale 40,
the synthetic ground-contact fixture and deliberately delayed rendering.
Across all 15 world boundaries, the checks pass:

| Native path | Misses | Hits |
| --- | ---: | ---: |
| 32-bit transformed/translated, `sim:38dcc` | 1,482 | 689 |
| Word result, `sim:3ab1c` | 366 | 165 |
| Word result with translation, `sim:3abe2` | 1,539 | 713 |

There are 218 reset epochs. All 1,482 32-bit misses match the exact transform
models and translation. All 1,567 hits match a calculation from their own epoch.
All 3,060 array bytes match the observed writes at all 15 boundaries. The final
arrays reproduce the previous delayed run exactly, including its two changed
bytes versus ordinary rendering, `h3:0aa85` and `h3:0ae81`.

The word-result misses are recorded as provenance for later hits; their
arithmetic is not independently modelled by this checker. The projected screen
arrays at `h3:0b1da` and `h3:0b5d6`, clipping and all indirect consumers remain
outside this result. This is evidence for the observed cache lifetime and
writes, not a blanket proof that no simulation consumer can read these arrays.
It does not close the whole-state, physics/combat, camera, capacity or 50-FPS
gates, and does not justify a performance claim.

Native counters 426/512/638/133 and terrain/cache/list 2/1/2 pass. All 56 selected
and two disabled hook checks pass before unload. Flight returns 1 after 15
started updates (last pose 14), preserving the return value and clearing W6
ownership/input readiness. The owned emulator was identified and quit.
No slave bytes changed. Six host tests cover stale epochs, corrupt results and
scratch, missing calls/inputs, index bounds, word copies and unobserved writes;
the full host suite passes 264 tests.

The capture retains `capture-geometry.py`, `GEO_RESET/FETCH/INPUT/RESULT` logs,
all RAM checkpoints, the frozen slave/listing, exit checker and hook audit.
Run `geometry_cache.py ORIGINAL_SIM CAPTURE --out REPORT` to reproduce the
model check; `geometry-check.json` records counts and `geometry-comparison.json`
records the final-array comparison. Projected-array producer/consumer tracing
is the next unresolved part of this geometry-state investigation.


## Projected-coordinate producers and sampled readers

`projected_cache.py` extends the epoch check to both 255-longword screen arrays,
`h3:0b1da` and `h3:0b5d6` (2,040 bytes). Normal projection at `sim:38e9c`
uses the existing exact `sim:38c82` model with two independent normalization
implementations. Near-plane intersection at `sim:38fac` uses that model on
coordinate differences and adds the first vertex's X/Z coordinates. The word
paths at `sim:3acca` and `sim:3add6` model native shifts, signed-word multiply,
signed long-by-word division with truncation toward zero, sign extension and
wrapped longword addition. Divide-by-zero and DIVS overflow are rejected as
unsupported evidence; neither occurs in the accepted trace.

Each projection's source coordinates must match calculations observed in the
current part epoch by `geometry_cache.py`. Each resulting pair must match the
independent arithmetic before the verifier records the write. The entire
2,040-byte arrays must equal the accumulated writes at every world checkpoint.
A sampled screen read must use a pair already produced in its current epoch;
its exact axis, aligned index and value are checked. Source, projection and
consumer routine bytes are bound to the original executable. This proves the
observed dataflow, not pixel correctness or the absence of indirect consumers.

The accepted read-only `w6-ground-projection-030-v2` capture uses unchanged
`c54a84f7…` VERIFY code, cached 50 MHz 68030, maximum detail, Time Scale 40,
ground-contact fixture and deliberately delayed draws. At all 15 boundaries,
both the 3,060-byte vertex arrays and 2,040-byte screen arrays match their models.

| Producer | Verified native calls |
| --- | ---: |
| Word normal projection, `sim:3acca` | 1,414 |
| Word near-plane intersection, `sim:3add6` | 6 |
| Long normal projection, `sim:38e9c` | 1,016 |
| Long near-plane intersection, `sim:38fac` | 132 |

The sampled normal polygon assembly reads at `sim:3b37e` and `sim:3b386`
consume 3,048 values each: **6,096 current-epoch reads**, with no stale or
unexplained value. The other fourteen identified reader sites, including the
mirrored branch and clipped-polygon assembly, were not instrumented in this
accepted capture. They are listed explicitly in `projection-check.json`;
no coverage is inferred for them. The earlier vertex-cache counts reproduce
exactly: 218 epochs, 1,482 modelled long misses and 1,567 hits.

The final screen arrays exactly reproduce the prior delayed run. They account
for 22 of the ordinary/delayed final h3 differences, spanning `h3:0b274–0b2bd`
and `h3:0b66e–0b6b9`. Combined with the earlier scoped timer, cockpit-history
and vertex-cache evidence, this leaves `h3:0483b` as the sole final h3 byte
outside those investigated ranges (ordinary 0, delayed 4). This is an inventory
of that particular endpoint, not an all-tick or complete-gameplay verdict.
Raw snapshots remain unfiltered. Other memory regions, indirect consumers and
the wider physics/combat/camera/capacity/50-FPS matrix remain required.

The first `w6-ground-projection-030` attempt stalled while installing an
8,444-byte debugger batch; the same batch parsed successfully offline, but the
precise live transport/pipe cause was not established. It collected no world
checkpoints and is excluded. Only its identified owned debugger/emulator were
closed. On the next boot, separate complete breakpoint blocks installed, but
the 39-breakpoint set was rejected on resume before leaving the flight anchor.
That rejected log is retained. Reducing to 20 breakpoints allowed the same
paused boot to produce the accepted capture. Lifecycle/contact observers were
omitted to fit this set and are explicitly marked unobserved in its metadata;
empty event arrays are not evidence that those events did not occur.

Native self-tests 426/512/638/133 and terrain/cache/list 2/1/2 pass; 56 selected
and two disabled hooks pass before unload. Flight returns 1 with 15 started
updates and last pose 14; cleanup preserves the return value and clears W6
ownership/input readiness. The identified owned emulator was quit. No slave
code or player policy changed, and no FPS claim follows from debugger tracing.
Six new host tests cover signed division, word multiplication, shift counts,
stale epochs, bad sources/results/reads and unexplained writes. All 270 host
tests pass.

The capture retains `capture-projection.py`, bounded setup responses, all
`GEO_*` and `SCREEN_*` observations, full RAM, frozen slave/listing and the
exit/hook checkers. Reproduce with
`projected_cache.py ORIGINAL_SIM CAPTURE --out REPORT`;
`projection-comparison.json` records the final-array comparison.


## Legacy elapsed residue and the all-boundary residual inventory

The final ordinary/delayed difference at `h3:0483b` belongs to the legacy
elapsed word `h3:0483a`. Re-running `game_time_inventory.py` finds exactly one
direct relocated reference to that word: the `move.w d7,h3:0483a` store at
`sim:03d58`. The original six bytes are `33c7 0000 483a` before relocation.
All 45 retained ground snapshots (15 each for ordinary, delayed and no-render)
contain the exact relocated store. No direct relocated reader exists in this
supported executable. This does not formally exclude arbitrary computed aliases.

The store records the original elapsed argument; it is not W6's funded-time
ledger. The selected hook at `sim:03d5e` supplies primary dt 225 while W6 owns
flight. The world gate also writes 225 before dispatching each scheduled tick.
At every retained boundary 1–14 in all three schedules, the primary word is
225, the secondary word is 64 and the native divisor is 33 (displayed Time
Scale 40). The legacy elapsed value can be 0 or 4 without changing these words.
At boundary 0, before the first W6 scheduled update, the old primary values
are 403/450/403 for ordinary/delayed/no-render and secondary is 450; those
startup residues must not be mistaken for a differing W6 physics quantum.
The corresponding initial elapsed values are 52/64/52.

This accounts for the last previously unclassified byte at the particular
ordinary/delayed endpoint. It **does not close the complete-global gate**.
An inventory of every retained boundary, retaining all raw differences, finds:

| Comparison | Maximum residual bytes at one boundary | Distinct residual byte offsets across all boundaries | Residual bytes at boundary 14 |
| --- | ---: | ---: | ---: |
| Ordinary / delayed | 264 | 392 | 0 |
| Ordinary / no-render | 637 | 755 | 617 |

“Residual” here means outside the investigated six-byte sound timer, legacy
elapsed word, 112-byte cockpit history, 3,060-byte vertex arrays and 2,040-byte
screen arrays. These are reporting labels with the earlier scoped evidence,
not a normalization mask or a claim that every possible reader has been proven.
The ordinary/delayed union includes the one-byte startup-primary residue above.
The table describes h3 only; other executable/heap regions remain in the raw
comparison. The already verified full player record and object-prefix results
are unchanged by this broader inventory.

Ordinary/delayed residual counts for boundaries 0–14 are
`1, 0, 264, 10, 9, 178, 1, 0, 0, 221, 0, 0, 0, 160, 0`.
Ordinary/no-render counts are
`0, 0, 324, 630, 628, 637, 592, 613, 602, 601, 637, 599, 631, 627, 617`.
Thus final-state convergence hides intermediate differences and must never
substitute for the equal-tick complete-state requirement.

The remaining ranges include terrain-render context around `h3:05272`,
cockpit selectors `h3:0711c/0711d`, drawing/clipping fields, model/transform
context beginning around `h3:0a27c`, validity bytes at `h3:0a4e6`, and polygon
assembly scratch after `h3:0b9d2`. The no-render comparison additionally exposes
message-layout fields around `h3:04820` and other earlier globals. Static
references identify candidates; they are not all newly established owners.
Prioritize cross-domain readers and persistent cache keys before expanding
arithmetic models for scratch that is unconditionally overwritten. In particular,
retain the original terrain list at `h3:0526a/0526e`, used by the native sorter
at `sim:10bd4/10bdc`; do not treat the surrounding page as disposable render memory.
The later terrain-list audit below identifies its loader call context; this
reference alone does not establish a per-tick physics reader.

`w6-ground-residual-inventory/analyze.py` and `inventory.json` retain the
reproducible analysis of `w6-ground-restore-030-v2`,
`w6-ground-restore-slow-030` and `w6-ground-restore-none-030`, all `c54a84f7…`.
The analysis checks frozen build hashes, equal allocation bases, consecutive
matched world-tick IDs, original/live elapsed-store bytes, post-start clock
words, and that each row's labelled counts plus residuals exactly equals its
raw changed-byte count. It launches no emulator and changes no slave bytes.
This is a diagnostic advance, with the wider gameplay/capacity/50-FPS gates
still open; the 270-test host suite is unchanged.


## Ground-run message logic versus pending erasure

`message_boundaries.py` checks the retained full message ledger and snapshots
from the ordinary, delayed and no-render ground runs (`c54a84f7…`). It reuses
the independent deadline/legacy-timer policy from `message_time.py`, binds the
original and all 45 live copies of the native priority consumer at `sim:0114e`,
and requires the same original game, frozen VERIFY build and h3 allocation.
All three runs pass at every one of their 15 matched world boundaries.

The startup reset inherits the existing timer 14500 and arms a new 178-CIA
interval deadline. This differs deliberately from a new native message arm,
which stores 15000. The first snapshot is therefore checked as startup state;
subsequent live snapshots must match exact `ceil(remaining × 15000 / 178)`
scaling. Native arithmetic counter 179 is present in every snapshot. Ledger
prefixes must remain unchanged as new events are appended; saturated, truncated,
reordered or inconsistent state is rejected.

The three boot-local active cursors start at 1127, 1130 and 1127 respectively.
Keeping these raw values in the report, their event times relative to the first
boundary are identical for all logical events:

| Event | Active CIA intervals after the first boundary | Deadline relative to the first boundary |
| --- | ---: | ---: |
| Inherited-message reset | 0 | 178 |
| Native shortening to 1500 | 8 | 26 |
| Expiry | 26 | 26 |

Shortening to 1500 requests `ceil(1500 × 178 / 15000) = 18` intervals.
The first post-start snapshot accordingly has the recomputed legacy word 1517.
The message pointer, format/state/priority bytes at `h3:0482e–04830`, relative
clock/deadline/start and live-versus-expired state match at every boundary.
The signed native `timer < 7500` priority decision also matches throughout.

Publication differs as expected: ordinary rendering erases at relative cursor
26; delayed rendering erases at 28; no-render retains expired-pending state
through the final snapshot. At boundaries 4–14 the rendered timer is zero while
no-render retains one. Both values satisfy the same native priority predicate.
The corresponding erasure ledger events, phases, raw timers and draw counts
remain in the output; only logical-event comparison separates publication events
by their documented kind. The checker does not discard differing raw snapshots.

This establishes the intended reason for the differing `h3:04820` timer in
these runs. It does not validate message rectangle pixels, every native
shortening/replacement edge case, arbitrary indirect readers, terrain ownership
or all gameplay events. Message-layout differences and other residual globals
remain in the broader inventory. The player timing option remains VERIFY-only.

Five new host tests cover deadline/expiry and erasure order, pending erasure
versus the signed priority threshold, inherited startup state, exact live
scaling, and CIA wrap. All 275 host tests pass. No new emulator was launched,
no slave bytes changed and no performance result is inferred. Reproduce with
`message_boundaries.py ORIGINAL_SIM ORDINARY DELAYED NO_RENDER --out REPORT`;
`w6-ground-residual-inventory/message-boundaries.json` retains the full result.


## Complete terrain-list boundary check and builder-position ownership

`terrain_state.py` checks the three retained current-build ground schedules:
ordinary, deliberately delayed and no-render. The list pointer/count at
`h3:0526a/0526e` identifies **19 records of 34 bytes**, a complete 646-byte
payload in a tracked 654-byte allocation including its eight-byte header.
The count-to-size relationship is explicit in the native allocation at
`sim:0ed96–0eda0`. The checker requires the complete active list to fit in one
tracked payload, reads every record byte in order, and rejects changed pointers,
counts, record tails/order or truncated memory.

All 15 matched boundaries in all three runs have identical complete records,
order and list pointer/count. The view-change countdown at `h3:05270` and
14-byte camera-key/recomputation state at `h3:054de–054eb` also match exactly:
16 control bytes per boundary. The payload and controls remain constant over
this particular ground window. This confirms preservation in these captures;
it does not exercise terrain destruction or every transition. The earlier
native phase test remains the evidence for forced rebuild versus unsafe reuse;
equal boundary bytes alone do not replace that test.

The adjacent 12 bytes at `h3:05272–0527d` are a distinct builder-position copy.
At `sim:0f0a0–0f0b8`, the builder loads its camera object, takes the position at
object offset 8 and copies three longwords into this range. The original
relocation inventory has ten direct references to the range, all inside
`sim:0f01c–0f5f4`. The later reads subtract those coordinates when evaluating
terrain positions or use the copied height. The list pointer/count immediately
before it is not part of that scratch copy.

The builder-position copy differs between ordinary and delayed runs at
boundaries 2, 5, 9 and 13. It differs between ordinary and no-render at every
boundary 2–14. The checker retains all three raw copies in the report and
compares the persistent records/controls separately; it does not erase these
raw differences. The static assignment and confined direct uses support the
position's drawing role. Arbitrary computed aliases and all consumers are not
formally excluded by a relocation inventory.

**Ownership wording correction:** the previous residual-inventory paragraph
called the `sim:10bd4/10bdc` list access “world code.” Its enclosing sorter starts
at `sim:10b52`, and the inspected direct call at `sim:0efa6` is in the terrain
loader. The sorter compares model-ID-derived keys and swaps whole 34-byte
records. That reference alone does not prove per-tick physics access. The
complete list remains preserved; no restoration code is removed on this basis.

The verifier binds the supported original executable, allocation bounds,
frozen capture hashes, matching global bases and consecutive world IDs. It
also checks the loader-to-sorter call bytes and the builder-position reference
inventory. Three host tests cover full-record tail/order corruption, persistent
controls versus separately reported scratch, invalid extents/counts and short
reads. All 278 host tests pass. No emulator was launched, slave bytes changed,
or new performance/capacity claim made.

Reproduce with `terrain_state.py ORIGINAL_SIM ORDINARY DELAYED NO_RENDER --out REPORT`.
The retained result is `w6-ground-residual-inventory/terrain-state.json`.
Message-layout, other globals, remaining consumers and the broader gameplay,
CPU-capacity and 50-FPS requirements remain open.


## Front-overlay h3 post-state model

`cockpit_poststate.py` independently models the h3 writes of the audited front
programs 3 and 4. Across `w6-overlay-probe-030`, `w6-overlay-blit-a500` and
`w6-overlay-blit-030`, all 12 native calls match the complete 48,396-byte h3
post-state: **580,752 bytes checked**, including unchanged bytes. These are
retained before/after captures on both physical buffers, not new runtime runs.
The checker binds the original executable and each frozen slave hash through
the existing overlay audit. Results are retained as `poststate-check.json`.

The model follows resource selection at `sim:28c66..28c9e`: the selected set
word at `h3:7c22`, table pointers at `h3:7c24/7c2c`, and selected descriptor at
`h3:7c28`. Bitmap mode is stored at `h3:7c1c`; the accepted rectangle operation
sets `h3:9d54` to one at `sim:28be8` (opcode A104). The different A114
outline path clears then restores it and is not accepted by this model. Colour operations retain the unmapped pen at
`h3:4164` and mapped foreground/background at `h3:9d52/9d50`. The shared colour
model now follows native sign extension for palette selectors and table bytes,
including comparison against the original argument words and last-match wins.
Negative resource indices are rejected rather than silently treated as unsigned;
they are outside the audited programs. Incoming resource dependencies and
unsupported bitmap modes also fail closed.

The corrected raster model still matches all **480,000 framebuffer bytes**
across those same 12 calls, both by direct rendering and by independent image
plus coverage-mask composition. The packed payload remains **9,528 bytes**.
Five added host tests cover post-state writes and untouched bytes, signed palette
semantics, unmapped pen preservation, mapping precedence, and unsupported inputs.
All 283 host tests pass. This is correctness groundwork only. Registers/CCR,
hardware state, other memory,
a complete cache key, live cache twins and performance measurements remain open.
No runtime cache or slave change is introduced; 50 FPS is not achieved by this
host model.

Reproduce with `cockpit_poststate.py CAPTURE/overlay-capture.json --out REPORT`.


## Native overlay caller-return contract

A fresh cached 50 MHz 68030 capture, `w6-overlay-abi-030`, uses the current
VERIFY slave `c54a84f748481dfb0583651ab79e04a0321086b17d3325172138ad9060122e7b`,
CUSTOM2=32703, CUSTOM4=0 and CUSTOM5=512, maximum details and Time Scale 40.
It records every integer register and status register before the interpreter,
at its quiescent exit, and at the actual caller return for programs 3 and 4
on both physical buffers. No debugger memory injection or slave edit is used.

`overlay_abi.py` independently executes the native epilogue's stack semantics:
restore D2-D3/D5-D7/A2-A3/A6, unlink A5 and return. All 18 observed registers,
including stack/program counters and status, match at all four caller returns.
The verifier binds the observations to the frozen listing's probe locations,
entry stack frame, original executable identity and existing full h3 post-state
check. The nine explicitly saved registers retain their entry values. D4/A4
also stay unchanged in this capture, but are not assumed callee-saved by the
model. All calls return success word one with N/Z/V/C clear.

**A cached return-register image would be incorrect.** Program 3 returns full
D0 values `0x00000001` and `0x00950001` in the two observed calls; program 4
returns `0x00010001`. The native final `MOVE.W` at `sim:28d4e` preserves the
upper half. A1 for program 3 and D1 for program 4 also vary with destination.
The two observed caller return sites are `sim:15f94` and `sim:15f9c`. These
observations require either an exact dependency-aware return model or a proven
caller-specific liveness contract before a replacement may omit these effects;
copying the first call's registers is not acceptable.

The same new four calls pass complete h3 post-state comparison (193,584 bytes)
and both raster and image/mask composition checks (160,000 framebuffer bytes
each). Packed image/mask storage remains 9,528 bytes. Native timing/input/
presentation counters pass 426/512/638/133; terrain/cache/list checks pass 2/1/2,
and three private shape cases pass. The live timing/pacing audit passes all
56 enumerated destinations with zero disabled declared ranges under this mask.
The verified owned emulator was quit after capture.

The collector is retained as `capture-abi.py` beside `overlay-capture.json`,
`abi-check.json` and `raster-check.json`. Reproduce the offline return check with
`overlay_abi.py CAPTURE/overlay-capture.json --out REPORT`. Three host tests
exercise register/flag preservation, exact stack restoration, incomplete data
and unexpected frame rejection. All 286 host tests pass. No runtime cache,
hardware-state equivalence,
performance gain or full W6 acceptance is claimed.


## Native front-overlay coverage component

`overlay-mask.s` adds a 68000 coverage builder under the existing VERIFY-only
CUSTOM2 bit 14 probe. It interprets the audited colour/resource-selection,
rectangle, line and unoriented bitmap commands into an 8,000-byte CPU mask.
Lines use integer Bresenham coverage; bitmap coverage comes from the native
mask, including its padded row layout. It does not infer transparency from
before/after pixel differences and therefore retains opaque zero-colour pixels.
The builder writes private storage, returns supported/fallback status, preserves
its input registers except D0/CCR, and has bounded command scanning. Unsupported
commands, geometry, clipping and negative resource indices reject. Resource
pointers come from the trusted loaded game; this is not an untrusted-file parser.
The rejection branches have not yet received a private native fault-injection
matrix, so those paths remain an integration prerequisite.

For the first four front-program calls the probe allocates 8,032 private bytes,
sets 16-byte guards at each end, builds the mask, exposes an observation marker,
and frees the allocation. It then runs the original interpreter in full.
No drawing is skipped, no cache is installed and no game framebuffer is written
by this component. A larger VERIFY image required changing the message-log
address calculation to a long PC-relative base calculation; its behavior is
unchanged.

Fresh `w6-overlay-mask-030` and `w6-overlay-mask-a500` captures use identical
VERIFY SHA256 `d3b4bb914a775f943dbef303d9c31dbb514af881030bf69e5548fae36005f778`
(text 254,544 bytes), CUSTOM2=32703, CUSTOM4=0 and CUSTOM5=512, maximum detail
and Time Scale 40. **Each** captures programs 3/4 on both physical buffers.
All 32,000 mask bytes per boot match the independent raster model, and all
128 guard bytes remain intact. Coverage is 1,070/1,003 pixels; the eventual
packed image/mask payload remains 9,528 bytes. Final allocation pointers are
observed zero after all four frees (`mask-freed.txt`).

Each boot also passes the complete h3 post-state, full original framebuffer,
independent compositing and all-register caller-return checks for the four
native draws that follow. Native timing/input/presentation counters pass
426/512/638/133, terrain/cache/list checks pass 2/1/2, and three private shape
cases pass. The live timing/pacing audit passes its 56 enumerated destinations;
static audits cover 68 ranges and 125 patch destinations with no errors.
All 288 host tests pass. Normal/developer W5 hashes remain unchanged. Both owned
emulators were quit after verification.

Reproduce with `overlay_mask_check.py CAPTURE/overlay-capture.json --out REPORT`.
The collector, raw allocations and result are retained as `capture-mask.py`,
`mask-N.bin` and `mask-check.json` in each capture. This supplies a native
coverage component for a possible cache fill from a completed original draw.
Complete cache guards, packed image capture, final-command/state preservation,
live cached/native twins and cost measurement still precede any rendering
replacement. It establishes neither a speedup nor W6 gameplay/50-FPS acceptance.


A final guard isolates the mask component from standalone bit-14 diagnostics:
when W6 bit 13 is off, it returns before reading W6's stored h3 pointer. The
final VERIFY SHA256 is
`bb546da124913064fdead4d8260afc2f0ac1ed6be68581a82304009430419fd7`
(text 254,564 bytes). Its 820-byte builder/point body is byte-identical to the
A500/030-tested component (SHA256
`4faee9e8a135fbe98c5614cd04c19fbd92d56edf7a39b6c03911729c29a5cbd1`).
The active-path captures above belong to the preceding build; they are not
mislabelled as whole-build validation of this guard revision.

A fresh final-build `w6-overlay-mask-standalone-030` boot requests CUSTOM2=16384.
All four original overlay calls pass the h3, framebuffer/compositing and complete
caller-return checks. All four mask-result longs remain zero, proving no private
mask allocation or build occurred; all 66 disabled patch ranges retain original
bytes. Static audits again pass 68 ranges/125 destinations. The owned instance
was quit. The new guard's W6-enabled branch is source-reviewed; the unchanged
native builder retains the two-CPU evidence above.


## Native packed overlay capture and host replay

`overlay-pack.s` packs a completed original draw using the independently built
coverage mask. It derives word-aligned bounds, copies five tightly packed
planes with uncovered bits cleared, and appends one packed coverage plane.
The descriptor records left byte, top row, row bytes, height, plane bytes and
total bytes. Empty masks and payloads above the 5,208-byte component capacity
return failure. It reads the original framebuffer without changing it, writes
only private CPU storage, and performs no blitter operation. The first four
front calls retain their private mask until packing after the native draw;
both allocations are then freed. The exit helper preserves registers/CCR,
using user-accessible SR reads on 68000 and CCR reads on later CPUs.

Fresh `w6-overlay-pack-030` and `w6-overlay-pack-a500` captures use VERIFY
SHA256 `eee2db0777e138ddcd8635849766260b50a909d5d67c8a331fca4edc44c6f7c1`
(text 254,988 bytes), CUSTOM2=32703, CUSTOM4=0 and CUSTOM5=512, maximum detail
and Time Scale 40. Each observes both front programs on both physical buffers.
All four 5,240-byte packed allocations per boot match the independent host
packer, including guards and unused trailing bytes. The existing four mask,
full h3 post-state, native framebuffer, image/mask and complete caller-return
checks also pass. Both allocation pointers are observed zero after the fourth
call; the raw free observations are in `freed.json`.

| Program | Descriptor (left byte, top, row bytes, rows, plane bytes, total) | Packed payload SHA256 |
| --- | --- | --- |
| 3 | 8, 71, 24, 30, 720, 4320 | `007b303399d22074838c0d4be219013a2e096f5ce623c5d4ca29d248257061fc` |
| 4 | 8, 72, 28, 31, 868, 5208 | `458f8cea16980077082791c012d7dd97694dd24dde988ddf0a075569d163f3b8` |

Payloads match between physical buffers and between the two CPUs. For every
native payload, the host replays it onto all-zero, all-one and deterministic
LFSR backgrounds, comparing all 40,000 output bytes against independently
rendering the program on that background. All **480,000 replay bytes per boot**
match. This is host replay of native-produced data; it is not a native cached
render against a native reference on those new backgrounds. The earlier private
blitter test remains separate component evidence, not a live cache twin.

Native timing/input/presentation counters pass 426/512/638/133, terrain/cache/
list checks pass 2/1/2, three private shape cases pass, and the live timing/pacing
audit passes 56 enumerated destinations on each CPU. Static audits pass 68 ranges
and 125 patch destinations. All 291 host tests pass. Normal/developer W5 hashes
are unchanged. Both verified owned instances were quit.

Reproduce with `overlay_pack_check.py CAPTURE/overlay-capture.json --out REPORT`.
The retained collector is `capture-pack.py`; native buffers/descriptors are
`pack-N.bin` and `pack-N-header.bin`, with results in `pack-check.json`.
Native rejection-path tests, complete input guards, persistent cache lifetime,
live replay with state preservation and native pixel twins remain necessary
before skipping drawing. No gain, sustainable capacity or 50-FPS result is
claimed, and broader W6 gameplay acceptance remains open.


## Persistent private overlay cache twin

`overlay-shadow.s` retains the first packed allocation for each front program
through the four-call diagnostic window. Before each original draw it copies
the complete framebuffer into guarded private memory. After the draw it replays
the retained image/mask onto that private copy with a native CPU compositor,
using `old XOR ((old XOR image) AND mask)`, and compares every byte against the
original renderer's completed framebuffer. The game always receives its original
draw; the twin does not write game pixels or blitter registers. Geometry must
match the retained descriptor before reuse. Other dependency changes are not yet
guarded: a discrepancy is diagnostic evidence, not permission to display a stale
cache. Complete cache-key/invalidation work remains open.

`overlay_shadow_check.py` independently verifies the pre-draw copy and guards,
persistent allocation identity and frozen bytes at each hit, saved geometry,
native counters, and the entire replayed/native framebuffer. Its host compositor
uses the separate AND/OR expression. Current-frame packing remains reference
information; a hit must reuse the earlier allocation and bytes already present
in the pre-draw RAM snapshot. This prevents a rebuilt current-frame image from
being counted as cache reuse. The existing full h3, original pixels, coverage,
packed-data and caller-return checks also run on the same capture.

Final VERIFY SHA256 is
`e9da528982d41aafbec0580d681c46e65d0f398d6b4b0af68631f99c3c00ce96`
(text 255,666 bytes). Fresh `w6-overlay-shadow-a500` and
`w6-overlay-shadow-bank-030` captures use CUSTOM2=32703, CUSTOM4=0, maximum detail
and Time Scale 40. A500 uses CUSTOM5=512; 68030 uses 514. The latter name/config
requests the bank fixture, but the retained live fixture counter is **step 2**;
The legacy fixture schedules Right at steps 20–34 only while it owns the
keyboard; its branch is bypassed once W6's timestamped consumer is ready.
This capture therefore establishes early-flight coverage only, **not a bank
window or banking convergence**. Use the W6 replay described below for input
coverage under W6.

Each final-build run records **two fills and two hits**, with zero native byte
mismatches or unsupported cases. All four 40,000-byte private frames and guards
match the original native output. At each hit, A500's background differs from
its seed by 52 bytes and 68030's by two bytes. This is limited natural background
variation; view/gun/resource changes and materially different native backgrounds
still need coverage. The earlier three-background host replay remains separate
evidence. The initial `w6-overlay-shadow-030` run also passed with six changed
background bytes per hit on the preceding build
`0acdfc01c7a2f475fa21f3c9b13a0b568ccff33c1b234986eeb02789e62cfd88`.

Cleanup follows the fourth **mask attempt**, including a rejected mask/pack,
rather than requiring four successful twins. This prevents a rejected final
attempt from retaining earlier successful cache allocations. The successful
captures observe both cache pointers, the private target and selected-cache
pointer cleared after the fourth call, with counters 2/2/4 and no unsupported
case. The final 68030 capture also observes mask and current-pack pointers zero.
Native rejection-path injection is still required; the successful-path cleanup
observations do not claim to exercise those failure branches.

Native timing/input/presentation counters pass 426/512/638/133, terrain/cache/
list checks pass 2/1/2, three private shape cases pass, and the live timing/pacing
audit passes 56 enumerated destinations on each final-build CPU run. Static
audits pass 68 ranges/125 destinations. All 293 host tests pass; normal/developer
W5 hashes are unchanged. Every owned test instance was quit.

Reproduce with `overlay_shadow_check.py CAPTURE/overlay-capture.json --out REPORT`.
The retained collector is `capture-shadow.py`; private headers, framebuffers and
cache bytes are `shadow-N-header.bin`, `shadow-N-target.bin`, `shadow-N-cache.bin`.
Results and cleanup observations are `shadow-check.json` and `shadow-freed.txt`.
No live rendering replacement, measured speedup, sustainable CPU capacity or
50-FPS acceptance is claimed. W6's complete simulation-state/event invariants
remain separate, unfinished requirements.


## Delayed cache twins during W6 scheduled input

The four-call overlay diagnostic now waits until world tick 4 when CUSTOM5
bit 31 selects the existing scheduled-input replay. Other modes retain the early
window. This is a lower bound: a slow renderer may first reach the diagnostic
much later. The legacy CUSTOM5 bit-1 bank fixture cannot substitute for this
replay under W6: `tape_game_record` bypasses its bitmap writes as soon as
`time_keys_ready` is set. The earlier bank-named capture was not a steering test.

The verifier now binds each delayed sample to the frozen replay records, their
active-clock origin, current cursor, replay-ready state and private consumed
Right/Fire bytes. It checks the unchanged four-record schedule: Right down/up
at relative CIA boundaries 32/64 and Fire down/up at 96/128, including modular
clock wrap. These are synthetic scheduled records, not physical acquisitions.
It reports world tick and raw player roll rate separately; the held bitmap at
a render observation does not assert which earlier world tick first used it.

Both `w6-overlay-shadow-replay-030` and `w6-overlay-shadow-replay-a500` use VERIFY
SHA256 `728a03ecbd7af31de7e65d60b2eabf977b3507588e21203995eef24f70ce1fcb`
(text 255,706 bytes), CUSTOM2=32703, CUSTOM4=0, maximum detail and Time Scale 40.
CUSTOM5 selects deferred activation, input observation and scheduled replay
(bits 9/20/31); the boot helper emits its signed AmigaDOS representation.

| CPU | Seed tick / relative cursor | Hit tick / relative cursor | Right / Fire at seed and hit | Raw roll rate, seed → hit | Changed background bytes, programs 3 / 4 | Changed covered pixels, programs 3 / 4 |
| --- | --- | --- | --- | --- | --- | --- |
| Cached 50 MHz 68030 | 4 / 32 | 7 / 52 | 1 / 0 at both | 0 → 860 | 982 / 888 | 224 / 234 |
| A500 | 34 / 252 | 87 / 635 | 0 / 0 at both | 0 → 0 | 1,205 / 1,129 | 245 / 180 |

“Covered pixels” counts changed background pixels beneath the cached paint,
combining the five planes before counting each pixel once. Each run has two
fills and two genuine reuse hits. All four full 40,000-byte native/private
outputs, guards, retained cache identity/bytes, h3 post-state, packed data and
caller-return checks pass. This supplies materially changed native backgrounds
for the CPU twin, including active steering on 68030. The A500 window is after
both scheduled controls were released; neither run observes active firing.
The samples are at different world ticks and are not a cross-CPU gameplay-state
comparison. Instrumentation overhead also precludes capacity/FPS conclusions.

Native timing/input/presentation counters pass 426/512/638/133; terrain/cache/
list and shape checks pass 2/1/2 and three cases. Live timing/pacing audits pass
56 destinations on each CPU, and cache/target cleanup is observed. Static audits
pass 68 ranges/125 destinations; all 295 host tests pass. Normal/developer W5
binaries are unchanged. Both verified owned instances were quit.

Use the existing boot helper with `--replay`, then the retained
`capture-shadow.py`; run `overlay_shadow_check.py CAPTURE/overlay-capture.json
--out REPORT` for the offline result. The added capture context is reproducible
from the saved RAM banks without another emulator run. Complete invalidation
keys, view/resource transitions, native rejection-path tests and live hardware
replay still precede a rendering replacement. Broader W6 state/event, capacity
and smooth-50-FPS gates remain open.


## Exact overlay pixel-model dependency guard

`cockpit_dependencies.py` stores the program identity and exact bytes read by
`cockpit_raster.py`, merging adjacent reads into ranges. Matching compares those
bytes directly, not a hash, and does not follow a changed resource pointer.
The diagnostic digest is only an aid to inspecting reports. Destination-buffer
identity and background pixels are deliberately outside this pixel-model key.
This is a host analysis tool, not a native cache guard or a proof that the model
covers every native dependency. In particular, comparing saved resource ranges
is not a runtime resource-lifetime or memory-safety protocol.

Native inspection identified two missing eligibility checks. The bitmap helper
compares its padded width against `h3:9d40` at `sim:3070c`, and the mask contains
an extra word per row. The host model now requires a 320 by 200 screen, zero
mask pad words, and the complete padded native footprint inside both screen
and active clip bounds. It rejects unsupported cases instead of silently
omitting possible pixels. At this host-only checkpoint the native diagnostic mask builder had not acquired
these guards; the native follow-up below adds them alongside the original draw.

Retained captures `w6-overlay-shadow-replay-030`,
`w6-overlay-shadow-replay-a500`, `w6-overlay-shadow-a500` and
`w6-overlay-shadow-bank-030` pass all 16 raster comparisons and dependency
checks. For each capture, both later calls retain the exact first-call key:
program 3 has 15 merged ranges totalling 1,608 bytes, and program 4 has 11
ranges totalling 1,460 bytes. These are within-capture comparisons, not
cross-boot pointer equality or native invalidation-transition tests. The
misnamed older bank capture does not establish steering; only the delayed
68030 replay observes held Right as documented above.

Six host tests cover program/resource/command/palette/geometry changes,
background independence, changed pointers without following the new address,
nonzero mask pads, clipped padded footprints, and missing/short reads. All
301 host tests pass. No slave code changes, new emulator runs, performance
claims or W6 acceptance claims accompany this host guard. Complete native
read/side-effect coverage, return-state handling, resource transitions and
runtime cache invalidation remain open before any original draw can be skipped.


## Native overlay bitmap eligibility guards

The VERIFY mask builder now matches the host model's screen-extent, padded
bitmap-footprint and zero-mask-pad requirements. It checks the entire native
footprint against screen and clip bounds before iterating covered pixels, and
checks each extra mask word before using that row. Rejection returns unsupported;
callers must discard any partial mask. Original game drawing remains unconditional.

`overlay-mask-guards.s` runs 14 private native cases once under the existing
W6/overlay diagnostic selection. A 48,992-byte normal-memory allocation holds
synthetic h3/resource/program data plus an 8,000-byte mask with 16-byte guards
on each side. Cases cover the accepted baseline, wrong screen width/height,
nonzero first/second mask pads, accepted/rejected exact right and bottom screen
edges, accepted/rejected right clip edges, and rejected left/top/bottom clips.
Every case checks its explicit expected supported result and both guards. No
live resource is mutated. The allocation is freed on successful completion;
as with existing VERIFY fixtures, a mismatch aborts diagnostic execution.

Both `w6-overlay-guards-030` and `w6-overlay-guards-a500` use VERIFY SHA256
`be253e7f5b5ddd8a7ca73f94dcd7fe913e6a9d49091d46ebdbe210f3716b8cca`
(text 256,214 bytes). `mask-guards.txt` records **14 passed, allocation zero**
on each CPU. Four live front calls per boot also pass all mask, packing,
full-frame CPU-cache, h3 post-state and return-contract checks: **320,000
framebuffer bytes** across eight calls, two fills and two hits per boot.
Exact host dependency keys remain stable within each capture.

| Capture | Seed/hit world ticks | Changed background bytes at hits (program 3/4) | Changed covered pixels (3/4) |
| --- | --- | --- | --- |
| Cached 68030 | 4 / 9 | 1,827 / 1,691 | 437 / 252 |
| A500 | 34 / 114 | 1,169 / 1,089 | 246 / 182 |

The additional private fixtures consume emulated time. On 68030 the seed still
observes held Right at relative cursor 32; hits occur at cursor 67, after its
release, with roll rate 368. A500 samples are after both scheduled inputs have
released (cursors 252 and 832, roll rate zero). These are not matched world-state
comparisons across CPUs and the large gaps are not capacity measurements.

Both boots pass existing native counters (426/512/638/133, terrain/cache/list
2/1/2 and shape 3), all 56 selected timing/pacing hook checks, and complete
shadow-cache cleanup. Static audits pass 68 ranges/125 destinations; all 301
host tests pass. Normal/developer binaries retain their W5 hashes. Both owned
emulators were quit after collection. Reproduce with the existing shadow
capture/checker, followed by the retained `capture-mask-guards.py` read-only
counter collector.

This closes the newly identified bitmap eligibility mismatch, not all native
rejection paths or cache invalidation. Complete resource lifetime/transition
handling, native dependencies and side effects, cached return state, hardware
replay and performance remain open. W6 is still VERIFY-only, with consistent
full gameplay and smooth 50 FPS unproven.


## Message rectangle after render-dependent erasure

`message_layout.py` accounts for another raw difference in the retained
ordinary/delayed/no-render ground window. All 45 boundaries match a native
border-expansion/erasure model. The original rectangle at `h3:04822..04829`
is `(93,178,128,14)`; the four-word draw scratch at `h3:0456a..04571` is
`(90,175,134,20)`. Native `sim:008d2..008f0` subtracts three from x/y and adds
six to width/height, with word arithmetic. On erasure, `sim:00a7e..00aa4`
copies the expanded draw scratch back to the saved rectangle.

The model binds both instruction sequences to the supported original executable
and uses the independently checked message ledger to distinguish pending expiry
from completed erasure. Ordinary and delayed runs retain the original rectangle
through boundary 3 and the expanded rectangle at boundaries 4–14. No-render
retains the original throughout. The four changed low bytes are retained in
raw state reports, not masked or restored. Re-expanding an already expanded
rectangle on every tick would be incorrect; this check supports exactly one
inherited message and rejects replacements or repeated erasures.

The relocation inventory also exposes an indirect consumer: `h3:00706` points
to this rectangle. All 45 snapshots preserve that exact pointer. The text
renderer at `sim:03868` reads its y coordinate through the alias at `sim:03884`,
reads x/width/height at `sim:03894`, and reads x again at `sim:039be` when
positioning text. Thus a direct-reference-only audit would miss real readers.
This evidence supports a presentation role for this window; it does not prove
that all computed aliases or future message replacements are harmless.

The checker reuses the existing message clock/priority verification, binds all
three frozen builds, retains the full direct-reference inventory, and checks
all eight saved rectangle bytes plus all eight scratch bytes at every boundary.
Three host tests cover one-time erasure, 16-bit arithmetic wrap, invalid scratch,
changed pointers and unsupported lifecycles. All **304 host tests pass**.
The report is `w6-ground-residual-inventory/message-layout.json`; reproduce with:

```sh
python3 R/RedBaron/tools/message_layout.py \
  tmp/dev/tmp/game/RedBaron_v2.1/RedBaron/data/sim \
  tmp/dev/tmp/prof/w6-ground-restore-030-v2 \
  tmp/dev/tmp/prof/w6-ground-restore-slow-030 \
  tmp/dev/tmp/prof/w6-ground-restore-none-030 \
  --out tmp/dev/tmp/prof/w6-ground-residual-inventory/message-layout.json
```

No slave changes or new emulator run accompany this analysis. Both-buffer pixel
cleanup, message replacement, other residual globals, broader simulation-state
independence, supported capacity and smooth 50 FPS remain open.
