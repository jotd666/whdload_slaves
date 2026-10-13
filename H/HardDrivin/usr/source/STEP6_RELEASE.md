# Hard Drivin' 4.0b release integration

Step 6 is complete within the accepted scope. The ordinary build now includes
the validated enhanced simulation and renderer selection. `HardDrivinRelease.i` supplies the established feature set; the
historical `VERIFY_*` feature names do not imply input injection. Input tapes,
math fixtures, diagnostics and automatic test exits remain absent unless
explicitly requested. `HD_DEVELOPMENT=1` retains isolated feature builds for
investigation. No game, Kickstart, WHDLoad or built-slave bytes are tracked.

## User options and compatibility

- WHDLoad 17.0 minimum, with the standard configuration header and startup UI.
- CUSTOM1: **Enhanced framerate**, jointly controlling simulation and rendering.
  The installer sets CUSTOM1=1 in every selected new icon; unchecked/0 restores
  the existing native simulation and renderer. Command-line use requires
  explicit CUSTOM1=1. No ambiguous distinction between absent and zero options.
- CUSTOM2: existing frame delay, unchanged. The startup list offers 0 through 9;
  existing numeric tooltypes remain supported. A nonzero delay retains the
  original blitter-wait helper.
- CUSTOM3 is ignored in release builds; it remains a development renderer mask.
- New enhancements apply only to SPS 0126. Other editions keep their original
  patches. The installer retains all five editions, seven icon alternatives,
  the licence and KickEmu startup/configuration files.

CPU selection occurs once at patch installation: 68000 uses rotations and lean
waits; 68020 uses those only with code in physical Fast RAM; 68030 retains the
native renderer; 68040/68060 use rotations only. Other configurations fall back
to the native renderer. KickEmu's MEMF_FAST label alone is insufficient: a
Chip-backed expansion arena receives that label too. Physical Chip and the
24-bit non-Fast bus range are excluded before the TypeOfMem check.

## Final validation

The final release code hunk is 48,250 bytes. Both the normal and diagnostic
builds assemble without warnings. A rebuild after documentation and diagnostic
changes is byte-identical to the final release slave. The normal binary contains
no input tape, high-score input fixture or automatic test exit. The instruction
source of all 32 gameplay modules other than the renderer/install/input-fixture
modules is unchanged from the validated pre-integration version.

All seven profiles ran fresh 500-PAL-field gameplay A/B and attract windows
(10.015943522 seconds each). A uses the constant-throttle input fixture; B
uses the full preceding native input tape, starting its sample after 3,999
fields. All 21 runs read back the automatic renderer mask and pass the 13-site
rotation/wait patch audit. These are final-build smoke/performance observations,
not a new equal-scene comparison with the original game:

| Profile | Gameplay A | Gameplay B | Attract |
| --- | ---: | ---: | ---: |
| a500 | 41 | 62 | 72 |
| a500-fast | 43 | 63 | 73 |
| a1200-020 | 159 | 223 | 238 |
| a1200-030-50 | 252 | 284 | 347 |
| a4000-040-25 | 245 | 275 | 298 |
| a4000-040-40 | 247 | 279 | 305 |
| a4000-060-50 | 248 | 275 | 309 |

The post-skid-fix B trajectories differ from the earlier step-5 captures; the
68030 B count in particular must not be interpreted as a renderer regression
against that older table. No new overall net performance claim is made.

Additional checks:

- CUSTOM1=0: all 172 declared enhancement ranges match the original game on
  A500, 020 and 040; the final normal build repeats the A500 check. Existing
  JOTD patches remain present. The branch-range audit passes 161 ranges.
- WHDLoad 17.0 build 5139: final 020 gameplay, 500 fields, 159 swaps; automatic
  selection and all 13 renderer sites pass. The main matrix uses WHDLoad 20.0.
- 68040 with MMU: final 500-field functional run, 388 swaps, nonblank cockpit,
  unchanged executable after gameplay and correct renderer patches. This is
  functional evidence only; its speed is not comparable with NOMMU timings.
- Chip-only A1200: 200 fields, 33 swaps, native renderer selected despite
  CUSTOM3=7. A Fast-RAM A1200 with CUSTOM2=1 retains the original wait helper
  despite CUSTOM3=1; all 13 sites pass.
- Natural GAME OVER: 020 completes 105 presentation frames in exactly 280
  eligible fields; the final frame starts at field 277.
- End-to-end 020 tape: 4,216 physics returns including 66 crash returns, replay
  at field 3,356, natural GAME OVER at 10,677, high-score name entry at 11,570,
  save at 11,631 and ordinary WHDLoad exit at 11,735. The diagnostic adds only
  mouse input at name entry and an exit after saving; it injects no score,
  pose, velocity or race flags. The 380-byte disk file matches the original
  encryption of the live table, and a fresh boot reloads all 380 bytes exactly.

- WHDLoad 17 buffered-write end-to-end run: the same 4,216 physics returns
  and 66 crash returns reach replay, GAME OVER, name entry, save and normal
  exit. The 380-byte file again matches the original encryption exactly.

### Storage-test environment limitation

The end-to-end disk check uses WHDLoad 20 with NoWriteCache and WriteDelay=0.
With buffered writes, the save API returns success but WHDLoad hangs during
exit in this debugger/emulator setup. A separate 500-byte standalone slave,
containing only SaveFile and Abort calls and **no game code**, reproduces the
same hang at the same WHDLoad routine. The identical standalone test passes
with WHDLoad 17 and buffered writes, as does the full game test. Direct writes
and a subsequent cached
read both pass. This isolates the buffered-write failure from Hard Drivin's
changes; it is not a claimed successful WHDLoad 20 cached-write test or a demonstrated
physical-Amiga fault. The installer does not force a storage workaround.

## Retained scope limits

Original Amiga handling is preserved, including abrupt skid entry. The native
physics comparisons and fixed spin recovery are described in
`PHYSICS_ACCURACY.md`; this release does not tune the handling to improve it.
Original clock defects and the accepted C2/C5/P4 performance exceptions remain.
P3, automated full-lap timing, human A500/040 full laps and intro optimization
remain explicitly deferred, not silently marked as passed. Other game editions
have not acquired the SPS 0126 enhancements.

Local evidence: `s6f-*` final matrix, `s6-final-*` compatibility/disabled checks,
`s6-gameover` presentation timing, `s6-delay` delay-option check,
`s6-flow-direct-020`, `s6-flow-cached-17` and `s6-score-reload` storage checks and `s6-save-api-20`
standalone buffered-write reproducer. Earlier
`s6-*` matrix captures precede the physical-memory guard and are superseded.
Raw evidence, build outputs and tooling remain in ignored `tmp/`; memory dumps
are compressed with verified round trips after inspection.

## Dead-code cleanup after integration

The unselected Fast edge-array experiment (allocation, patch and pointer state)
was removed, including its development override; CUSTOM3 bit 0 is now unused.
Three helpers with no runtime callers were also removed: `_events_begin_step`,
`_phase_scalar_step` and the preserving `_phase_project` wrapper. Their active
inline replacements / projection core remain. The square-root cache is now
assembled only when its reference-only hook is selected; phase builds had
included its unreachable routine and state despite omitting the hook.

The older fieldwise integrator remains a live fallback of `_phase_frame`, and
other explicitly selectable development checks are retained. The release code
hunk is now 47,906 bytes, down 344 bytes. No active physics formulas or renderer
selection rules changed. Release, gameplay-fixture and reference-only builds
assemble; the dead-symbol and 160-range branch audits pass.
Short post-cleanup gameplay checks pass on A500 and A1200/020 (200 fields each),
including all 13 renderer patch sites and unchanged native edge-pointer setup.
With enhancements disabled, all 171 remaining declared ranges match native
bytes. These smoke checks do not establish a new performance comparison.
