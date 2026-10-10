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
