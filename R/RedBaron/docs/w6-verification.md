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
