# Enhanced handling: skid onset and recovery

The A1200 play report of easy, prolonged sideways slides exposed two errors in
elapsed-time physics. Both are corrected; the original steering/grip thresholds,
engine force law and clocks are preserved. This is a targeted handling correction,
not a claim that every deferred full-lap test has now passed.

## Skid onset must use current speed

The phase integrator evaluates engine endpoints from an older phase anchor.
Steering also used that anchor's velocity and RPM-derived MPH. During braking,
this could start a skid after the current speed was already below the original
threshold. During acceleration, it could miss a threshold crossing.

A concrete counterexample uses the pristine engine's braking endpoint:
velocity/RPM/gear `(260, 3200, 4)` becomes `(244, 3060, 4)` in one native step.
After seven of its eight elapsed fields, the current state is `(246, 3077.5, 4)`.
The native MPH conversion gives 68, while the anchor still gives 71. Applying
full steering on the next field starts a skid with the old enhanced code but
not with original steering at the current state.

`HardDrivinPhase.s` now supplies current velocity and current RPM-derived MPH
to steering, then restores anchor velocity before evaluating the engine endpoint.
The engine still runs at the requested per-frame cadence. No grip threshold has
been relaxed. Native steering at `$0b398..$0b444` retains its contact, braking,
speed and steering-force conditions.

Validation executes original game instructions and assembled enhanced code:

- 4,752 matched-input steering cases cover the mouse range, speeds around the
  threshold, braking, on/off-road classification and wheel contact. The decision
  itself agrees when it receives the same current inputs.
- 5,544 phase-frame cases cover all seven interior phase positions, rising and
  falling speed, steering, braking and contact. Corrected onset/turn/spin outputs
  exactly match original steering at current speed. The old implementation has
  1,120 extra skid entries and 480 missed entries in this deliberately targeted
  matrix; these are test counts, not estimates of normal driving frequency.
- The falling-speed cases use the pristine braking endpoint above. The rising
  cases are controlled phase states, not a claimed complete driving trajectory.

## Recovery must retain native integer rounding

At `$0b62a`, the original computes `spin = trunc(signed_word(spin*9)/10)` once
per native step. The enhanced exponential decay retained fractions that the
original discarded. Smaller frame intervals therefore prolonged a slide and
increased its total rotation, despite matching one isolated eight-field step.

For initial spin 11, original recovery reaches zero after 80 fields; the old
one-/two-field enhanced paths take 183/184. For spin 24, the corresponding
values are 128 versus 242 fields. During a skid the original holds its movement
vector, so this extra recovery time also prolongs sideways motion.

`HardDrivinMotion.s` now holds each native spin rate for eight elapsed fields,
then applies the exact original integer recurrence, including signed-word
narrowing. Angular integration splits at those decay boundaries, so a long
render interval does not apply the old rate throughout. The decay is published
at the original position-update site, after steering's skid-entry decision.
Zero-spin driving retains the existing short path.

The state longword at motion offset 24 now stores elapsed phase 0..7, rather than
a Q16 spin remainder. Exit/reset paths clear it. The embedded diagnostic is
identified by `HDSPIN02` and tests initial phases 0,1,3,6,7.

- 180 assembled recovery sequences / 5,886 checks cover both spin directions,
  signed-word extremes, fixed and mixed frame intervals, zero elapsed time,
  external changes, and intervals through 65535. Native decay instructions are
  the oracle. Rate, recovery phase and flat accumulated rotation agree.
- 297 complete eight-field physics comparisons remain byte-exact in the car
  state against original orientation/engine/position, including 135 reverse-
  velocity cases, manual/automatic gears and partial/zero wheel contact.
- The embedded emulator suite passes 595 spin cases, 135 angle cases, 81 falling
  cases, 1,323 position cases, 405 falling-position cases, 56 full crash-drift
  sequences and eight crash-timer sequences. Sixty independent position
  subdivision checks also pass.

## Running-game evidence and limits

A 700-field input-only fixture accelerates straight and applies full right
steering from race field 300. It neither seeds skid state nor replaces terrain.
The final 68020 and 68040 captures each include a road skid, its exit, departure
from the road, another skid, and its exit. The first skid consumes 128 fields on
both CPUs, including the entry pass. The later off-road skid consumes 128/129
fields; the extra field is the observation interval crossing its expiry.
The preceding 68020 code took about 240 fields between its first observed entry
and exit. Different subsequent positions/contacts are expected after correcting
that earlier trajectory, and are not treated as equal-scene performance data.

The A500 capture also completes both recoveries with its longer frame intervals.
Across the three final captures, all 268 pre-existing skid returns match the
original recurrence and saved phase (101 on 020, 142 on 040, 25 on A500),
including six observed exits.

The unchanged normal build remains byte-identical. No new FPS claim is made.
The previous full-lap and clock exceptions remain as documented; these tests do
not certify every terrain trajectory or replace the user's handling assessment.
The speed in the report was approximate, so the controlled 68-versus71 example
is not asserted to be the exact incident the user experienced.

Local evidence remains under the ignored harness: `spin-recovery-before.json`,
`spin-recovery-check.json`, `skid-onset-check.json`, `skid-current-speed-check.json`,
`physics-skid-native-frame.json`, `live-spin-check.json`, and the `physics-handling-v2-*` and
`physics-motion-math` capture directories. No game bytes or traces are committed.
