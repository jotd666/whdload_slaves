# Sound timing audit

Step 4 still has open audio work. This audit separates field-driven playback,
absolute pitch values, discrete triggers and repeatable requests. Addresses are
SPS 0126 code offsets. The retained `audio-call-audit.json` checks all 21 aligned
direct calls through the native sound-event vector against pristine code,
including their immediate event arguments. This is not proof that no indirect
caller exists, or a listening test.

## Playback clocks and pitch

- `$00760` schedules a sample on a channel. Its 12-byte channel descriptor has
  a two-field startup counter. The VBL handler at `$0030c..$003d4` programs the
  channels and decrements those counters. Requests while the counter is positive
  are rejected. This is field-driven setup, not a sound-duration or physics timer;
  it must not be multiplied by T. The two-field busy gate does not prevent a
  continuously requested sample from restarting more often at higher FPS.
- Music events 0/1 select a module at `$008d2..$0090a`. Re-selecting the same
  module does not restart it. The VBL calls the player at `$00302`, so music
  progression is independent of drawing. Sample lengths and Paula periods stay
  unchanged.
- `$007d0` maps signed G($9602) to `max(130,400-trunc(pitch/5))` for AUD0PER.
  G($8fc6) prevents repeated engine DMA starts; subsequent calls update period.
  `$00840` clears that latch while stopping the channel. `$00864` stops all audio.
- Ordinary driving writes G($9602) at `$0bae2` from the existing RPM conversion.
  It is an absolute function of RPM, not a finite difference. RPM slew already
  has elapsed-time scaling; the conversion and sample period need no additional T.
  Crash paths clear pitch; instant replay restores/interpolates recorded pitch.
- The post-race distance difference at `$111a0` is the identified derivative.
  TIME_GHOST_POST scales it by inverse elapsed time; its focused evidence is in
  GAME_TIME.md. Volume attenuation depends on absolute distance and is unscaled.
- `$008ae` suppresses events when attract/abort G($9604/$9605) is set and stops
  audio instead. During a nonzero crash counter it accepts only event 6. Request
  counts therefore differ from accepted channel starts and audible samples.

## Native event callers

| Call sites | Event | Timing classification and outstanding check |
| --- | --- | --- |
| `$06b94` | 5 | Menu selection changes a sentinel byte immediately after the call. |
| `$07d8e` | 10 | Start transition checks phase zero, then sets phase one; controls run once per outer frame. |
| `$0851a`, `$11486` | 1, 0 | Title/instruction module selection; native module identity suppresses restart. |
| `$08e4c`, `$092f6`, `$093b4`, `$093f4` | 3, 3, 2, 2 | Finish/checkpoint transitions and their state flags. Ghost finish has focused one-event evidence; full lap crossing coverage remains open. |
| `$0b166` | 8 | Off-road/scene condition; TIME_AUDIO now applies the elapsed cadence below. |
| `$0b624` | 4 | Sustained skid condition; TIME_AUDIO now applies its own elapsed request cadence. |
| `$0bc18` | 9 | Special collision-object condition returns without establishing a crash. Repeated contact needs event/cadence validation. |
| `$0bcf6`, `$0bdd6`, `$0c004`, `$0cc4e` | 6 | Crash creation; native crash state suppresses later physics collision paths. Verify once per event across substeps and recovery. |
| `$0cd52` | 7 | Sustained mask-3 pitch correction; TIME_AUDIO now applies its own elapsed cadence. |
| `$0bd02`, `$0bde2` | 7 | Object/obstacle paths. Distinct contact identities and repetition remain open. |
| `$0cc84` | 7 | Sustained zero-fall penetration uses an independent cadence; nonzero-fall landings remain immediate. See below. |
| `$10c24` | 4 | Recorded skid flag; now consumed once per historical record by TIME_REPLAY_TIMING. |
| `$10e10` | 6 | Replay crash effect clears a local one-shot flag after the request. Live focused checks observe one request; completely skipped effect tails still need explicit coverage. |

## Replay skid correction

TIME_REPLAY_TIMING replaces `$10c18..$10c29` with a history-record consumer.
It starts at record -1, examines every newly crossed valid record, and requests
skid event 4 only when that record has its native skid flag. Repeated draws of the
same record add no requests. Final advance consumes the undrawn tail and clamps
at count minus one before reading. The original 90-record ring wrap and Paula
busy arbitration remain intact. VERIFY_DISPATCH_NATIVE uses this same code.

The companion `HDRAUD01` holds the last consumed record and request count. It is
reset on each replay entry and does not alter stored history or playback pitch.
The private VERIFY_REPLAY_AUDIO_MATH fixture saves/restores both playback
companions and supplies a separate ring plus a private event vector. It cannot
program Paula or edit live game history.

Evidence under ignored `tmp/`:

- `s4-replay-audio-math-final`: four cases, 121 consumer visits and 61 exact expected
  requests. They cover duplicates, skipped records, ring wrap, empty/short
  histories, final tail and a one-record-per-step traversal. Unused result slots
  retain their sentinels.
- `s4-replay-audio-a500`: 94 interpolated frames over a 90-record replay; exit age
  721 against target 720 fields. All pose checks and 52 RNG calls pass.
- `s4-replay-audio-020`: 314 frames, exact 720-field exit, all pose checks and
  52 RNG calls pass. Both live histories contain no skid flags: zero skid requests
  is correct, but these runs do not prove live audible skid behavior. Each records
  one event-6 request at history index 64.
- `s4-replay-audio-native-constant`: the established constant-input crash fixture
  produces 77 valid history records. All 77 poses match verbatim, exit age is
  exactly 616 fields, and 52 RNG calls plus one event-6 request are observed.
  This history also has no skid flags. It is not full field-tape equivalence.
- `s4-replay-audio-slow-only64`: VERIFY_REPLAY_SLOW applies CUSTOM4=64 only while
  the instant-replay request/playback flag is set. It draws 11 poses from 90
  records and exits at age 726, six fields beyond the 720-field target. All poses
  and 52 RNG calls pass, with one crash request at history index 66. This history
  also contains no skid flags; skipped nonzero skid requests are covered by the
  private fixture, not this live run. Default VERIFY_SLOW behavior is unchanged.
- The earlier field-tape native-step and globally delayed captures never reached
  the replay anchor before their harness timeout. Both exited through owned
  cleanup and are excluded. They do not establish a replay failure or its cause.
- CUSTOM1-off retained code passes all 143 declared ranges, including the new
  replay site. The direct-branch audit passes 122 timing ranges. The ordinary
  build remains byte-identical to the 8392-byte-text baseline.

The next audio work is contact request cadence and contact-event identity,
followed by sample-start/listening checks. This document does not close step 4.


## Live off-road cadence

`VERIFY_TIME_AUDIO` requires TIME_REPLAY_TIMING and installs HardDrivinAudio.s
behind CUSTOM1/SPS0126. It owns event8 at `$0b162..$0b16b` and event4 at `$0b620..$0b629`, with
independent cadence states. Mask-3 contact event7 at `$0cd4e..$0cd57` also has
an independent state. Landing/penetration at `$0cc80..$0cc89` has a separate
state and preserves immediate nonzero-fall landings. Other live callers remain
separate acceptance work.

The first eligible request in an episode is immediate. Subsequent requests
consume eight-field boundaries from RP_WALL, retaining the remainder when a
frame arrives late. A long frame can consume several boundaries but emits at
most one current request; it does not burst old samples. Multiple scene visits
in the same physics step are suppressed. A gap of at least one entire physics
step without this caller starts a new episode. This is a call-eligibility
boundary, not a claim to identify all physical contact episodes.

Wall fields are intentional: Paula advances in real emulated time even when
physics runs multiple substeps without drawing. Pauses freeze RP_WALL, as with
other presentation epochs. `HDLIVEAU` holds the last consumed cadence boundary,
last step serial, request/emission counts and validity. Native/inactive dispatch
uses the unchanged sound request. VERIFY_DISPATCH_NATIVE deliberately preserves
that native call path; it does not exercise elapsed suppression.

The 1,000-field constant-steering captures retain both requests to `$00760` and
accepted starts at `$007b6`; they do not infer audible starts from event calls.
The accepted event-8 sample uses channel 2 and period 700 in these runs.

| Profile | Ungated requests / starts | Timed requests / starts | Timed request window |
| --- | --- | --- | --- |
| A500 | 111 / 111 | 86 / 86 | fields 239..928 |
| 68020 | 456 / 279 | 90 / 90 | fields 213..925 |

The runs are `s4-audio-live-a500`, `s4-audio-live-020`, and
`s4-audio-cadence-final-a500` / `s4-audio-cadence-final-020`. Every timed decision
matches its captured clock and episode state, allowing up to two fields between
entry/return stops. All emitted off-road requests become accepted starts. The
private VERIFY_AUDIO_MATH cases additionally cover duplicate steps, missing-step
re-entry, cadence boundaries/remainders, frozen clock, long intervals and both
32-bit clock and step-serial wrap (19 cases). An earlier strict minimum-interval
policy discarded the remainder and under-requested on the A500; its captures
without `final` in their names are superseded.

The profiles do not follow precisely identical trajectories or episode windows;
these counts prove the caller's cadence and actual starts, not cross-machine
handling or sound quality. `s4-audio-native-off` / `s4-audio-native-on` match all
247 event/request/start/engine-start observations over 108 physics returns and
911 fields. Only the event-handler return address is excluded because the
wrapper changes that address. This is focused native sound equivalence, not
full game-state equivalence.

CUSTOM1-off retained code passes all 144 declared ranges. The direct-branch
audit passes 123 timing ranges; the ordinary build is byte-identical to the
8392-byte-text baseline. Special-object and contact repetition, listening
checks, large-step physics and full step-4 acceptance remain open.


## Live skid cadence and contact coverage

TIME_AUDIO uses the same elapsed decision helper for live skid event4, with its
own20-byte HDSKIDAU state. Off-road and skid requests cannot consume each other's
cadence. The patch surrounds only the native sound call; spin decay, skid exit,
heading, velocity and throttle remain in their existing physics paths. As with
off-road sound, inactive/forced-native dispatch uses the exact original request.

`VERIFY_STEPINPUT_STEER_AT=N` is an input-only diagnostic requiring STEPINPUT.
It holds mouse X=320 until race field N, then uses VERIFY_STEPINPUT_X; both VBL
publication and controls entry use that boundary. It writes no skid/velocity/pose
state. The final diagnostic uses N=300 and X=639 after accelerating straight.
This fixture is separate from the established driving tape.

The800-field runs observe event calls, native sample requests and accepted starts:

| Profile | Before skid gating: requests / starts | With skid gating: visits / requests / starts |
| --- | --- | --- |
| A500 | 39 / 39 | 38 / 37 / 37 |
| 68020 | 170 / 170 | 168 / 55 / 55 |

Before captures are s4-skid-input-a500 and s4-skid-input-020. Gated captures are
s4-skid-cadence-a500 and s4-skid-cadence-020. Every decision matches the captured
pause-aware wall clock and step serial, including first requests and eligibility
gaps. Both also pass the19 private cadence cases. The sample uses channel3,
period1100. Changes in instruction timing slightly change the captured trajectory
and episode duration, so these counts are not equal-path handling evidence or a
listening test. The gate changes the request frequency; sample length and period
remain native. Every emitted skid request becomes an accepted start in these runs.

The integrated6000-field driving-tape captures s4-all-tape-audio-a500 and
s4-all-tape-audio-020 contain no skid requests. They instead establish live coverage
of event7 at `$0cd52` (4 versus21 requests) and `$0bd02` (1 versus3); the A500 also
visits `$0cc84` once. The020 visits the crash-event6 site `$0bcf6` once. Several
020 contact requests occur two fields apart. This is evidence for further contact
identity/cadence work, not justification for suppressing distinct impacts with a
blanket shared timer. Neither capture exercises special-object event9.

The skid build passes all145 CUSTOM1-off range checks and the124-range branch
audit; the normal build remains byte-identical to the8392-byte-text baseline.

`s4-skid-native-held` matches all108 car-state snapshots from
`s4-skid-native-reference`, G($98f6)..G($9951), after relocating the gear-table
pointer. Both use constant X=639; a field-delayed input transition would not be a
matched per-step input reference when the build changes wall timing. This is
car-state compatibility evidence, not full-world equality or sound-timestamp equality.


## Partial-contact sound cadence

The `$0cd52` caller is reached only with wheel-contact mask3. It follows the
pitch relaxation in `$0cd20..$0cd4d`, rather than a new object-collision or
hard-landing event. The mask is calculated from the four wheel gaps, with bits
set where a gap is less than4. In s4-contact-audit-020, eight successive mask3
visits at fields524..540 request the same sample with fall velocity0 throughout.
The corresponding A500 episode has two visits, at fields556 and566.

TIME_AUDIO now wraps only `$0cd4e..$0cd57` in the established eight-field cadence,
using a separate20-byte HDCONTAU state. First eligibility and re-entry after a
missing eligible step request immediately; continuous correction visits retain
the cadence remainder and do not burst historical sounds. The pitch correction,
contact flags, fall update and every other event7 caller remain unchanged.
Forced-native/inactive dispatch retains the original call and its returned X.

The6000-field input-tape captures record every newly computed wheel mask and the
contact caller, including wheel gaps, fall velocity and object pointer where
applicable. The gated runs additionally check each gate entry/return against its
wall clock and step serial, plus the19 private cadence cases.

| Profile | Before: pitch requests | Gated visits / requests / accepted starts | New mask3 episodes |
| --- | ---: | ---: | ---: |
| A500 | 4 | 5 / 4 / 4 | 3 |
| 68020 | 23 | 24 / 16 / 16 | 14 |

Before runs are s4-contact-audit-a500/020; gated runs are
s4-contact-cadence-a500/020. Every observed new mask3 episode requests immediately;
all actual callers have mask3. Every emitted request is accepted on channel3,
period500. The A500 also retains one native object-contact request, and the020
retains two. Different episode counts/trajectories after instruction-timing
changes prevent an equal-path handling claim. These are sample-start checks,
not an audible-quality assessment.

The initial verifier rejected returns at `$0cd58` without a preceding hook entry.
That address is also the native branch target for masks other than3. Retained
captures were rechecked without rerunning: every such bypass has a non3 mask and
unchanged cadence state (one A500 bypass, eight020 bypasses). Every actual hook
entry has its paired return and passes the gate model.

`s4-contact-native` matches all108 car-state snapshots from the original
s4-skid-native-reference with constant X639, relocating only the gear pointer.
This is the established G($98f6)..G($9951) comparison, not whole-world equality.
`s4-pitch-audio-off` passes all146 declared ranges; the125-range direct-branch
audit passes and the normal8392-byte-text slave is byte-identical to baseline.

Object event7 at `$0bd02` repeats against the same object in two020 visits five
fields apart in the ungated audit. That requires object-contact semantics beyond
the mask3 correction policy. Event9 remains unobserved. The landing/penetration extension below adds focused
coverage; object/obstacle repetition, full collision-event validation, listening,
large-step physics and step-4 handling/performance acceptance remain open.


## Landing and sustained ground penetration

The native `$0cc80` event7 path serves both landings and ground penetration.
It follows the position correction when average wheel penetration is below -5
or the car's orientation requires the effect, provided falling speed does not
exceed the hard-landing threshold of 50. The hard-landing event6 path is separate.
In a 2000-field A500 capture of the airborne-reference steering fixture,
`s4-air-contact-audit-a500`, ten visits have falling velocity 0: the ground
correction repeats across frames without a new fall. The corresponding 68020
capture has no visits to this site; it is not cross-machine landing equivalence.

TIME_AUDIO now wraps `$0cc80..$0cc89` using a separate HDLANDAU cadence state.
Zero-fall visits use the existing eight-field wall-clock rule, including first
eligibility, missing-step re-entry and remainder retention. A nonzero falling
velocity makes the request immediate and anchors the following penetration
cadence to that landing. It therefore cannot be suppressed by a recent
zero-fall correction. Collision impulses, position correction, gravity reset,
hard-landing crashes and Paula arbitration remain unchanged. Forced-native or
inactive dispatch executes the original event call.

The assembled 68000 helper passes 480 cases, including 400 immediate nonzero-fall
landings, 16 suppressed sustained requests, duplicate/adjacent/missing steps,
clock wrap and register/stack checks. The live `s4-landing-a500` capture has 11
visits and 11 emitted requests, one with falling velocity 29. All decisions match
the observed wall clock and step serial. It also verifies 161 direct bypasses to
`$0cc8a` leave cadence state unchanged; that native address is shared by paths
which do not call event7. An initial verifier rejected these bypasses; the
retained capture passes after checking the branch semantics explicitly.

All 11 landing requests reach the native sample scheduler on channel 3/period 500,
but none become accepted starts in this fixture: another same-channel request
has already armed its startup counter. Each follows an accepted channel 3 skid
start by zero or one field, within that two-field busy window. This preserves native arbitration and
is not evidence of audible landing quality. A delayed 68020 run,
`s4-landing-020-slow4`, reaches no landing calls and fails the verifier's coverage
requirement; it is excluded from passing landing evidence. Actual short-interval
live suppression remains unproven, although the assembled helper covers it.


Native-step captures `s4-landing-native-off/on` match all 208 observations when
compared by physics-step serial and event/sample parameters, excluding wrapper
return addresses. Their elapsed capture lengths differ (893 versus925 fields),
so this is event-order compatibility, not wall-time equivalence. All 108 native
car snapshots also match the reference. CUSTOM1-off passes152 patch ranges,
the direct-branch audit passes131 ranges, and the normal8392-byte build remains
byte-identical. Object/obstacle and special-object semantics, fast live landing
coverage, listening and full step-4 acceptance remain open.
