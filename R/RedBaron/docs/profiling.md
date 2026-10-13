# Red Baron performance measurements

## Current release policy

The user accepted measured performance on 2026-10-12. The normal build now
starts with Faster rendering On when CUSTOM2 is omitted: On=0, Off=1.
Developer/VERIFY CUSTOM2 remains an explicit mask, with zero disabling patches.
The default verified rendering mask is `0x1ff1fff`, filtered by CPU. On
2026-10-13 the user completed W6 release acceptance and authorized normal-build
availability. Consistent game speed is a separate, default-Off checkbox:
`CUSTOM3=1` adds W6 bit 13, independently of Faster rendering. Its existing CPU
gate (68000/020+, not 68010) and safe-swap/one-field-cap dependencies remain.
Developer/VERIFY still use CUSTOM2 bit 13 and ignore CUSTOM3. The user decision
accepts the documented operating limits; it does not change earlier results or
claim 50 FPS. Historical captures retain their original build and option mapping.

The opt-in changes option selection only; W6 runtime and default rendering
selection are unchanged. All 577 host tests, all three builds and their
136/136/150 patch destinations pass. Native 060 normal-build startup with `CUSTOM2=0 CUSTOM3=1` reads the
opt-in and selects effective mask `0x1ff6ffa`, including W6 and its pacing
dependencies (`w6-player-optin/options.json`). This is an option-path check;
existing D5 evidence supplies runtime acceptance. No new FPS claim is made.

## R1: renderer installation on subsequent loads fixed (2026-10-13)

The captured A1200/68040 normal-build abort occurred in `scene_frame_install`,
after its game-code base hooks but before cloning launch trampolines. The
WHDLoad dump retains the failing `fill_setup_custom` address in A0 and the exact
existing `JSR scene_frame_base_a0` in the slave image. That helper belongs to
the persistent slave, unlike the freshly loaded sim code. The installer expected
its original `LEA` on every load and rejected its own redirect on a later load.

The installer now accepts either the complete original `LEA` or the exact
previously installed `JSR` target. Other opcodes/operands still abort. This changes
installation only, remains under the existing sim-v1/CPU/feature gates, and does
not alter rendering or W6 timing. No new FPS claim is made.

| Validation | Result | Evidence |
|---|---|---|
| User normal-build dump, A1200/68040 | Persistent helper already patched; installation guard identified | `player-menu-abort-20261013` |
| Corrected normal build, named A1200/68040 preset; Faster rendering + W6 | First flight → native Abort → main menu → second mission in the same WHDLoad session → five further flight-loop crossings, rendered cockpit; no guard abort | `r1-reload-native/second-flight.txt`, `second-flight-render.txt`, `second-flight-render.png` |
| Existing host regressions | 577 pass | `r1-host-tests.log` |
| Normal/developer/VERIFY builds and patch reach | All compile; 136/136/150 destinations, zero errors | Build listings |
| Hook audit | 136 ranges, zero errors | Source audit |

The first reload-test attempt failed in debugger control before reload and is
not counted. The earlier undumped dogfight quit had the same generic message,
but cannot independently be attributed to this guard. Its preceding bounded
banking/firing/view-switch checks were not reproductions.

The local launcher enables WHDLoad `CoreDump` and mounts a persistent dump volume
outside rebuilt game volumes, selected by `CoreDumpPath` in global preferences.
A throwaway startup-abort slave verified `TDREASON_FAILMSG` saves the message,
register/stack report, memory and complete IFF dump. Preserve a real failure and
its matching build before another game exit: memory/IFF files are overwritten,
while the register log is appended. PC may be unavailable for an explicit abort;
use the saved stack and renderer state, not PC=FFFFFFFF as an instruction fault.

## R2: clipped-sprite firing abort fixed (2026-10-13)

The subsequent normal-build firing dump identifies sim:307b2, the masked-sprite
launch. Its destination is scene-buffer minus two bytes, BLTCON0/1 are DFCA/D000,
first-word mask 1FFF, and dimensions one word by ten rows with a 40-byte pitch.
The initial A shift register is empty and 1FFF shifted right by 13 is zero.
Consequently that first word selects only the existing C pixels and changes
nothing. The private renderer rejected the address before performing this safe
native clipping operation. This is separate from R1's installation failure.

The private scene now starts 16 bytes farther into its existing reservation,
retaining native modulo-16 alignment for MOVE16. The maximum aligned allocation
still ends before the polygon row workspace; the slave RAM requirement does not
increase. The exceptional path admits only destination offset -2, all-channel
ascending A-selects-B-else-C copies, identical C/D addresses, a zero shifted
first-word mask, dimensions 1–20 words by 1–200 rows, and a 40-byte C/D pitch.
Every rejected condition still aborts. Other destination checks, CPU gates and
feature selection are unchanged. No rendering-speed claim is added.

| Validation | Result | Evidence |
|---|---|---|
| User A1200/68040 firing dump | sim:307b2 and fully masked prefix word identified | `player-firing-abort-20261013` |
| Native VERIFY fixture on named A1200/68040 | 18 guard cases; captured register shape replayed through the actual private-blit entry with synthetic source pixels; all ten expected destination words match an independent bitwise reference; prefix unchanged | `r2-fixture-register.txt`; generator `tools/scene_prefix_fixture.py` |
| Normal release, same preset, Faster rendering + W6 | Five 40-frame windows with held native bank/fire inputs and forward/rear/left/right/forward inputs; no renderer abort | `r2-flight` |
| Existing host regressions | 577 pass | `r2-host-tests.log` |
| Normal/developer/VERIFY builds and reach audits | All compile; 136/136/150 destinations, zero errors | Build listings |
| Hook audit | 136 ranges, zero errors | Source audit |

The fixture tests offset, control/mode, mask, C/D pointer, dimension and stride
rejections. Generate its isolated source with `tools/scene_prefix_fixture.py`,
assemble using the normal include paths plus `-DVERIFY=1`, then run with WHDLoad
`CoreDump`; its explicit success message is `R2 prefix replay PASS`. It does not
modify the release source or rely on reaching the same random dogfight state.
The bounded flight is a smoke check, not exhaustive combat coverage.

## D5 automated coverage complete (2026-10-12)

All objective D5 input, transition, envelope and controlled outcome checks now
have results. The prior six-machine rate matrix, 060 soak and user handling/060
crash reports remain the evidence for those completed checks. The user subsequently completed release acceptance on 2026-10-13. A500 Time
Scale 40 still misses the original capacity/playability targets,
and controlled outcome fixtures do not judge manual approaches or dogfighting.
W6 is now a separate normal-build opt-in; no performance optimization or 50 FPS
claim is added. No further manual flight is requested for this automated scope.

| Check | Configuration | Result | Evidence |
|---|---|---|---|
| Time Scale 60, maximum detail, 2,000 fields | A500, 512K Chip + 2M Fast; developer `0x33fff` | 11 publications, 0.274562 FPS; 428 updates / 2,367 CIA ticks, F=10, quantum=450; world/wall 0.794617 ±0.001857; 112 dropped updates / 50,400 units | `d5-auto-a500-s60-native/rate.json` |
| Pause and Preferences, 200 fields each | Same A500 flight | Steps and cursor frozen in modal; excluded interval exactly translated on resume; quantum and pending debt retained | `d5-auto-a500-s60-native/modals.json` |

A500 Time Scale 40, same binary and mask, now also passes the native IRQ
catch-up test (`d5-auto-a500-s40/catchup.json`): throttle 210 → 190 with exactly
one command call, 28 held-bank catch-up pairs with no intervening publication,
and clean release over the following 500 fields. Each half covers 500 fields.
The native combat Abort menu passes (`mission-exit.json`): 38 CIA ticks of
unsampled backlog at modal entry, more than two world quanta at F=33; a
200-field menu hold and exit cause no additional world update. The first
observer attempt held Return down in the native button menu; the corrected
press/release completed that same pending Abort. This was a driver failure,
not a passed first attempt. Native C is rejected with eligibility code 10 in
this combat encounter, as expected; eligible compression remains separate.

060/50, current retained renderer with W6 (`0x1ff2ffa`), passes the same
200-field Pause/Preferences rebase checks at Time Scale 40
(`d5-auto-060-s40/modals.json`). Its first 500+500-field input window had no
consecutive catch-up pair, so it is not a catch-up pass. At native Time Scale
60, `d5-auto-060-s60/catchup.json` passes: throttle 210 → 190 exactly once,
111 held catch-up pairs, then clean release. No artificial render delay or
clock injection is used. The subsequent 060 mission-menu attempt had only
two CIA ticks of backlog and was rejected by the catch-up precondition;
the A500 result above supplies the shared exit-path check. The live rate,
input and soak drivers now trap sim:21f60, the common flight-exit epilogue,
rather than sim:21f4a, which covers only one exit path.


Controlled VERIFY-only outcome fixtures activate at W6 world update 4.
The standard mode sets initial poses/velocities once and isolates other
aircraft; subsequent physics, eligibility, projectile hits, damage and mission results are native.
They do not inject clocks, hits, health or completion flags. The gentle
landing starts with zero throttle; ground tests retain original damage preferences. Combat alone selects the native player
protection preference in a private game copy; enemy damage remains enabled.
The optional bounded firing-line fixture additionally repositions its live
target for at most 64 world updates; it does not accept AI evasion or ordinary
dogfighting behavior. These are functional integration checks, not
ordinary-flight handling or FPS measurements. The VERIFY fixture could not allocate expansion memory on the
2 MB A500 setup, so its 68000 outcome checks use 8 MB Fast RAM for instrumentation.
This is not a minimum-memory pass; the developer input/rate checks above retain
the 2 MB configuration.

| Controlled check | Configuration | Result | Evidence |
|---|---|---|---|
| Eligible native C entry/exit | 060, quantum 225 | 200 fields compressed, 257 native eligibility decisions, then native exit and 100 fields remaining off | `d5-auto-060-transit/compression.json` |
| Eligible native C entry/exit | A500, quantum 450; VERIFY 8 MB Fast | 200 fields compressed, 67 native eligibility decisions, then native exit and 100 fields remaining off | `d5-auto-a500-transit/compression.json` |
| Gentle field landing and End Mission | 060, quantum 225 | All contacts safe under W6; ground altitude 50, automatic mission-over menu, native completed-mission return, no world update while exiting | `d5-auto-060-landing-w6-r2/{ground,outcome}.json` |
| Gentle field landing and End Mission | A500, quantum 450; VERIFY 8 MB Fast | Safe native contacts; ground altitude 50, automatic mission-over menu and completed-mission return, no world update during exit | `d5-auto-a500-landing/{ground,outcome}.json` |
| Destructive crash and automatic flight exit | A500, quantum 450; VERIFY 8 MB Fast | Grade-2 impact at world update 5, destroyed aircraft flags, automatic common flight exit at update 12, native Captured debrief | `d5-auto-a500-crash/{ground,outcome}.json` |
| AI-aircraft damage and kill-credit integration | A500, quantum 450; VERIFY 8 MB Fast, bounded firing-line tracking | Six native hits; target destroyed at world update 9; personal kill credit 150 | `d5-auto-a500-combat-tracked/combat.json` |
| AI shoot-down | 060, quantum 225 | Eight native hits; enemy destroyed at world update 11; personal kill credit 150; native “You just shot down Udet!” message | `d5-auto-060-combat-protected-r2/combat.json` |

The one-time A500 combat starts at both 1,024 and 512 units produced one hit
without destruction in 2,500 fields and are rejected as shoot-down passes.
The retained A500 case keeps the target 512 units on the firing axis, for a
maximum of 64 world updates, while leaving health, native damage and scoring
untouched. It passes the projectile/damage/destruction/credit integration
check. It does **not** pass free-maneuvering AI combat or dogfighting acceptance;
the explicit `--track-target` capture flag prevents conflating those scopes.
The 060 case uses only the one-time starting lineup.

The landing ends behind enemy lines and reaches the captivity debrief. It is
a safe field-touchdown smoke test, not runway navigation or a manual approach
assessment. The A500 landing likewise verifies native contact and completed
mission return; its early post-exit screenshot still shows the loading panel
and is not evidence of a completed debrief screen. An earlier landing touched
down before W6 activation and is explicitly rejected. The first combat setup selected a camera object instead
of an aircraft and was rejected; the fixture now iterates the actual aircraft
pool. An unprotected attempt recorded hits but ended with the player destroyed,
so it supplies no shoot-down pass. The successful protected case requires both
native target destruction and the personal-score credit path at sim:a042;
hits alone cannot pass. The observers trap common flight exit at sim:21f60 and
bound both emulated fields and host debugger time.

From the configured harness, `d5_fixture_case.py <a500|060>
<transit|landing|crash|combat> <capture>` builds a separate VERIFY fixture and
leaves the game paused with native input attached. Optional `--track-target`
is combat-only and must be reported as a firing-line integration fixture.
Follow with
`d5_compression.py <capture>`, or `d5_ground.py <capture>` and then
`d5_end_outcome.py <capture>`, or `d5_combat.py <capture>`. Close the owned
input server and emulator before the next case. The transit observer requires
native eligibility rather than forcing the Time Compress flag. Ground and
combat result validators include deliberately malformed evidence cases.
The A500 transit setup needed a bounded continuation of its Preferences route
before the first test window. No interrupted setup is counted as acceptance.
The crash takes an automatic exit instead of the landing menu. The initial observer incorrectly waited on
the unloaded flight VBL after recording that exit; its owned wait was stopped,
and the same native crash completed the Captured debrief. The driver now treats
automatic destructive exits separately and rejects a field wait interrupted
away from VBL. No crash/menu return value is fabricated.

Validation: 577 host tests pass, including rejected malformed input, modal,
compression, ground and kill-credit evidence. Normal/developer/default VERIFY
builds compile, with 136 hook ranges and 136/136/150 patch destinations checked;
the separate tracked-target VERIFY fixture also passes its 150 destinations.
The normal bundle and default W6 selection are unchanged. These fixtures add no
runtime code to the normal or developer build. No emulator remains running for
this acceptance session.


The unchanged developer binary is SHA-256
`7148764be23e82f999b99b2e6f0359df88b987712010d8ab19caafbd7b330e39`.
Scale 60 exceeds this machine's capacity and exercises the approved debt-drop
policy; it does not pass consistent-speed operation. Setup uses a private copy
of native `SIMPREFS.PRF` and checks h3:3d56 after loading. The old slider-key
attempt overshot to 72 and was rejected before measurement. The overload flight
subsequently failed to reach a scene-entry breakpoint within 2,000 fields;
no input/catch-up pass is inferred from that attempt. Preferences' observer
returns at sim:21c26, after the complete six-byte patched call.

Reproduce from the configured development harness: run `d5_case.py a500 0x33fff
<capture> --scale 60`, then `w6_rate_profile.py <capture>` and `d5_modals.py
<capture>` from the tracked tools directory. The case driver leaves the owned
emulator paused with its native input server attached. Quit that input server
and the owned game before starting another case. The game fixture is copied;
the pristine installation is not edited. Reports reject incomplete windows,
unsafe publications, and malformed input/modal evidence. The rate reporter now
accepts both approved quanta, 225 and 450.

## FC6 — retained-renderer profile, W6 and geometry (complete, 2026-10-12)

Fresh exact capture `fc6-current-aprof`, source `d75a8fa`, uses the **normal
030 selection**: requested developer mask `0x7f0ffa`, effective `0x7b4ffa`.
FC3 gauges and FC4 spans are off on this CPU class. The unmodified VERIFY
slave SHA-256 is
`bc44d2fd6134a2ecf9b499d0c9602d3cc96fd2cc0ed67543828dd13e5e451f82`.
Instrument: aprof, cycle-exact 68EC030/50 NOMMU, CACR `0x2011`, 500 warm-up
PAL fields followed by 50 recorded fields, maximum detail and unchanged Time
Scale. Six artwork twins, three scene twins, both cockpit twins and 68 final
cockpit checks pass. The 17 render/world calls are instrumented workload
counts, **not player FPS**. Chip-bus units are 27.6%; recognized blitter polls
are 8.5% of all recorded units.

| Exclusive routine / work | ms per rendered frame | Chip-bus share |
|---|---:|---:|
| Viewport copy | 8.10 | 96% |
| Polygon compatibility kernel | 7.66 | 0% |
| Direct raster kernel | 7.05 | 0% |
| Native bitmap drawing, sim:30572 | 4.76 | 97% |
| Fast cockpit word composition | 3.61 | 0% |
| Projection, sim:38c82 | 2.92 | 0% |
| Artwork key checks | 2.88 | 73% |
| Face-loop body, sim:3b41a | 2.36 | 0% |
| Existing fast vertex transform | 2.29 | 0% |
| Object setup, sim:3a902 | 0.64 | 0% |
| Object setup, sim:39b42 | 0.21 | 0% |

The complete scene bracket is 45.87 ms in this instrumented workload. The
26.96/26.59/25.07 ms inclusive totals at sim:39b42/sim:3a902/sim:3b41a include
nested rasterization; they must not be described as pure geometry costs.
The earlier FC4 exact capture explicitly enabled spans on 030 to inspect the
shared fast-CPU implementation. Its lower compatibility cost is a different
selection, not evidence that the retained renderer regressed.

All six release configurations retain their current scoreboard values and CPU
policy. The existing normal 040/060 short windows reach the two-field cap;
FC5's long pairs remain near 24 FPS. This profile supplies no new normal-build
FPS or 040/060 cycle claim.

**Authorized FC6 trial (2026-10-12):** a bounded developer-only W6 trial on 040/060,
using one frozen binary per pair and 2,000 fields plus a 250-field held-bank
window. Compare masks `0x17f0ffa`/`0x17f2ffa` on 040 and
`0x1ff0ffa`/`0x1ff2ffa` on 060; inspect both publication cadence and world-time
rate. Bit 13 already supplies fixed ticks, interpolation and the one-field
cap. This trial does not put W6 in the normal mask or complete postponed D5.
The user approved both this trial and subsequent exact geometry processing
optimization, in either order. Geometry comparisons will use W6 to expose
savings hidden by the normal two-field cap. Both follow-ups are complete below.

### FC6 W6 trial: complete; 50 FPS not reached

One frozen developer binary for all four cases, SHA-256
`7148764be23e82f999b99b2e6f0359df88b987712010d8ab19caafbd7b330e39`.
Maximum detail, Time Scale 40, 2,000 PAL fields followed by 250 held-right-bank
fields. The enabled path uses the existing 225-unit world quantum, interpolation
and one-field cap. No guest instrumentation is installed for these timings.

| Configuration | Level FPS W6 off → on | Bank FPS off → on | W6 world / wall rate, level | Dropped steps | FC6 status |
|---|---:|---:|---:|---:|---|
| 68000 / A500 | — | — | — | — | Outside this fast-CPU trial; prior scoreboard retained |
| 020 / A1200 | — | — | — | — | Outside this trial; prior scoreboard retained |
| 030/50 MMU | — | — | — | — | Prior scoreboard retained |
| 030/50 NOMMU | — | — | — | — | Prior scoreboard retained |
| 040/25 NOMMU | 24.012 → 18.321 | 24.960 → 18.171 | 0.998656 | 0 | Correct bounded rate; misses every-field cadence |
| 060/50 NOMMU | 24.012 → 19.594 | 24.960 → 19.369 | 0.998656 | 0 | Correct bounded rate; misses every-field cadence |

Both level windows completed 326 world updates over 2,367 CIA ticks, F=33.
The one-update endpoint uncertainty is ±0.003063 in the rate ratio. Both short
bank windows completed 40 updates over 295 ticks: ratio 0.983183 with one-tick
uncertainty ±0.024580, and no drops. These are counter/rate checks, not renewed
D5 gameplay acceptance or proof across all Time Scale settings.

040 level publication gaps: 252 × two fields, 434 × three, 46 × four, one ×
five. 060: 402 × two, 337 × three, 45 × four. Neither records a one-field gap;
neither passes the 50 FPS cadence requirement. Every recorded publication
avoids lines 41–43. This is the copper-pointer guard check, not a new DMA or
full display-ownership proof. The lower FPS is the measured W6 workload result;
this comparison does not isolate interpolation cost from changed simulation
steps, poses or rendering workload.

Evidence: `fc6-w6-040-off`, `fc6-w6-040-on-r2`, and
`fc6-w6-060-{off,on}`. The first 040 on-attempt stopped before measurement:
F10 was left in the native menu queue. The driver now enters flight and uses
the established hardware IRQ F10 transition before setting preferences.
The corrected run and the 060 route pass. The reporter rejects incomplete
windows, flight exits, missing publications and unsafe pickup positions;
three deliberate corruptions are covered by its host tests.

**Disposition:** retain W6 as the existing developer option; do not enable it
in the normal mask or claim 50 FPS. D5 remains postponed. The geometry evaluation below also uses W6. These FS-UAE 040/060 results do not establish physical
accelerator throughput; the emulator limitation in `rendering-analysis.md`
still applies.

Manual trial from the initialized harness (choose a fresh output name):

```sh
BENCH_DEVELOPER=1 BENCH_BATCH_KEYS=1 \
python3 -B ../../R/RedBaron/tools/scene_profile_case.py \
  060 0x1ff2ffa tmp/prof/manual-w6-060 --fields 2000 --groups rate --bank-after 250
```

Use 040 with `0x17f2ffa` for that CPU. For an A/B, freeze both the developer
slave and its listing and set `BENCH_FROZEN_SLAVE` to that copy for both runs;
clear bit 13 for the off mask and use `--groups fps`. `rate.json` and the bank
subdirectory record simulation rate and publication cadence. Runtime addresses
are confined to ignored capture metadata.

### FC6 geometry extension: dropped

**Drop:** extending bit 6's register-held face loop to 040/060 gains less than
2% on both measured CPU classes; the original 68000-only policy is retained.

The candidate reused the exact sim:3b4cc vertex loop: table pointers, near
bound and output cursor stay in registers, with inline transform-cache hits.
Geometry, clipping, models and detail levels were unchanged. The existing
host model and its three checker sabotages pass. The bounded native 040 twin
passes 2,819 faces (2,419 fast-path faces, 2,198 cache hits, 5,302 misses),
comparing registers, live flags and renderer scratch results. Existing scene,
artwork and cockpit twins also pass (`fc6-geometry-twin`).

One frozen developer binary, SHA-256
`ee02a40aa5864864f354116cc20c104f275e2a206f5a93dd417a1c6429e51280`;
2,000 level-flight fields plus 250 held-bank fields per case, maximum detail,
Time Scale 40, W6 enabled. Only bit 6 differs: 040 masks
`0x17f2fba`/`0x17f2ffa`, 060 `0x1ff2fba`/`0x1ff2ffa`.

| Configuration | Level FPS geometry off → on | Bank FPS off → on | Disposition |
|---|---:|---:|---|
| 68000 / A500 | — | — | Existing measured bit-6 path unchanged; prior scoreboard retained |
| 020 / A1200 | — | — | CPU excluded; prior scoreboard retained |
| 030/50 MMU | — | — | CPU excluded; prior scoreboard retained |
| 030/50 NOMMU | — | — | CPU excluded; prior scoreboard retained |
| 040/25 NOMMU | 18.321 → 18.296 (−0.14%) | 18.171 → 18.171 | Drop |
| 060/50 NOMMU | 19.619 → 19.544 (−0.38%) | 19.569 → 19.569 | Drop |

Evidence: `fc6-geometry-{040,060}-{off,on}`. All four level windows retain
world/wall ratios 0.998234–0.998656 (within one endpoint tick); level and bank windows drop no world steps and have
no publication in the copper-pickup guard. Below-threshold differences do not
establish a speed gain or regression. The candidate is removed from all build
modes; no new geometry or W6 player enablement is shipped.

The restored normal/developer/VERIFY builds pass 569 host tests, 136 hook
ranges and 136/136/150 patch destinations. Runtime hashes remain those of the
retained FC4 release: normal
`dbea82782bc73e9d75febf437cb9b2ec3c1018535da822493a7868e9705ba66d`,
developer `7148764be23e82f999b99b2e6f0359df88b987712010d8ab19caafbd7b330e39`,
VERIFY `bc44d2fd6134a2ecf9b499d0c9602d3cc96fd2cc0ed67543828dd13e5e451f82`.
Normal mask `0x1ff1fff`, minimum RAM and two-field cap are unchanged. The
retained deliverable is the reproducible external W6 rate/cadence tooling and
this measured keep/drop decision. FC7 and postponed D5 remain separate.

## FC5 — changed viewport copying: dropped (2026-10-12)

**Disposition:** drop FC5 under completion-plan §0: the level-flight FPS gain
is below 2% on every measured CPU class. The shipped renderer, verified mask
`0x1ff1fff`, RAM requirements and two-field cap remain unchanged.

The candidate kept two 24 KB Fast shadows keyed by native page identity and
viewport geometry. In supported forward flight it compared longwords above
row 88; cockpit rows were always copied because later native instruments can
modify them. View, message, redraw, modal and resource changes invalidated the
shadows. The measured viewport was rows 21–139, not an assumed zero-origin
120-row rectangle. Four host-model tests covered page reuse, invalidation,
geometry changes and three deliberately corrupted pixel-check cases. The
native check passed 64 exact viewport comparisons plus rear/left/right/front
and firing transitions (`fc5-twin-2`); existing scene/artwork twins also passed.

One frozen developer binary per pair, maximum detail, unchanged Time Scale,
protected fixture and native keyboard input: **2,000 PAL fields of level
flight, followed by 250 fields with right bank held**. Screenshots confirm the
bank. These are FPS measurements under the existing cap, not copy-time or
real-hardware speedup claims. Values below 2% do not establish a reliable gain.

| Configuration | Level FPS off → on | Held-bank FPS off → on | FC5 disposition |
|---|---:|---:|---|
| 68000 / A500 | — | — | CPU excluded; prior scoreboard retained |
| 020 / A1200 | — | — | CPU excluded; prior scoreboard retained |
| 030/50 MMU | 23.887 → 24.037 (+0.63%) | 24.561 → 24.960 (+1.63%) | Drop; `fc5-030-{off,on}` |
| 030/50 NOMMU | — | — | No retained FC5 change; prior scoreboard retained |
| 040/25 NOMMU | 24.037 → 23.562 (−1.97%) | 24.960 → 24.761 (−0.80%) | Drop; `fc5-040-{off,on}` |
| 060/50 NOMMU | 24.012 → 23.987 (−0.10%) | 24.960 → 24.960 (0.00%) | Drop; `fc5-060-fixed-{off,on}` |

The 030/040 pair used SHA-256
`8867628a4e74449f238cd73f76e8f12a93bb4bdfcffe733202f7c19b5bfd6f38`;
the corrected 060 pair used
`8fa8b75cfe2befe0c80b5db6d07261cc753a87c9897a2a1b73063e492d211bfa`.
Masks were `0x7f0ffa`/`0x27f0ffa`, `0x17f0ffa`/`0x37f0ffa`, and
`0x1ff0ffa`/`0x3ff0ffa`, respectively, with the existing CPU filters.
The first 060 on-run was rejected: its allocation failed and it exercised the
full-copy fallback. Only that pair was repeated, after moving production
shadows into the existing unused VERIFY-artwork reservation. The corrected
run confirmed shadow storage was selected. No RAM increase was required.

The below-threshold candidate was removed rather than added to developer or
player defaults. All three release build modes rebuild; 566 host tests, 136
hook ranges and 136/136/150 normal/developer/VERIFY patch destinations pass.
The preceding FC4 normal-build stage timings and exact profile remain the
current release results; no copy-time saving is claimed from this discarded
candidate.

The retained benchmark option `--bank-after 250` adds a held-right-bank FPS
window after the requested level-flight groups, using the same owned emulator
and the established debugger keyboard input. Its results and screenshot are
in the capture's `bank` subdirectory. For example, from the initialized harness:

```sh
BENCH_BATCH_KEYS=1 BENCH_OMIT_CUSTOM2=1 \
python3 -B ../../R/RedBaron/tools/scene_profile_case.py \
  060 0 tmp/prof/manual-level-bank --fields 2000 --groups fps --bank-after 250
```

## FC4 — direct convex polygon spans (2026-10-12)

Bit 24 requires the private scene renderer (bit 20). The normal bundle selects
it on **040/060**; the 030 comparison is below the 2% threshold, so its player
path is retained. Explicit 030 developer/VERIFY selection remains available
for the common-code native twin and exact profiler. 000/010/020 are excluded.

The sim:2f312 hook accepts convex polygons with 3–32 distinct vertices wholly
inside the current clip rectangle. Native line-mode rounding supplies each
row's left/right extent; masked ends and solid interior words directly paint
all five Fast-RAM planes. There is no scratch clear, edge compatibility pass,
area fill or scratch merge on this path. Different-colour outlines still use
sim:2ea28. Clipping, non-convex/repeated vertices, degenerates, larger lists and
alternating-colour fills retain the existing renderer. Extending those fallback
cases is dropped from FC4: their native path remains exact and compatibility
work is no longer a leading measured cost. The row table occupies 800 bytes of
an existing workspace gap; compile-time bounds protect the adjacent buffers.
Minimum RAM, outbound viewport copying, pacing and W6 selection are unchanged.

One frozen developer binary per pair, SHA-256
`736c57b2181575898362079520686f7071b9911f1a878f2c5722e8abc4c11902`;
2,000 PAL fields per case, maximum detail, protected fixture, native keyboard
route and unchanged Time Scale. Masks are `0x7f0ffa` / `0x17f0ffa` for
030/040 and `0xff0ffa` / `0x1ff0ffa` for 060. After freezing, the final source
adds rejection of repeated vertices (a host test demonstrated the native
parity-fill distinction), explicitly flushes installation caches, and applies
the measured player CPU gate. Final native checks use that corrected source.
These paired gains refer to the frozen candidate; final normal timings are
recorded separately, not substituted into the comparison.

| Configuration | FC4 off FPS | FC4 on FPS | Disposition / evidence |
|---|---:|---:|---|
| 68000 / A500 | — | — | CPU-gated off; prior scoreboard retained |
| 020 / A1200 | — | — | CPU-gated off; prior scoreboard retained |
| 030/50 MMU | 23.962 | 24.161 (+0.83%) | Below 2%; normal off; `fc4-ab-030-{off,on}-1` |
| 030/50 NOMMU | — | — | Normal off; explicit common-code native/exact checks pass |
| 040/25 NOMMU | 22.389 | 24.037 (+7.36%) | Retain; `fc4-ab-040-{off,on}-1` |
| 060/50 NOMMU | 23.238 | 24.012 (+3.33%) | Retain; `fc4-ab-060-{off,on}-1` |

All 566 host tests pass. The actual C span routine is compared against
`fast_blitter_model.c`'s native XOR-edge, inclusive-fill and edge-restoration
pipeline over randomized convex hulls, small-grid and thin triangles, both
windings, clip boundaries and three recorded native polygons in every colour.
Unsupported input is checked for rejection without destination writes. Three
deliberately damaged checker results (missing type, mismatch, unfinished twin)
are rejected. All 136 hook ranges and the three builds' patch destinations
(136/136/150) pass; the disabled hook retains its original six bytes.

`fc4-final-aprof-1` passes the three new native full-polygon pixel twins
(triangle, quadrilateral, larger convex), all three prior scene primitive twins,
six artwork twins, both composed-cockpit twins and 72 final cockpit-page checks.
The candidate and native calls receive the same pre-operation pixels; the
native call includes its own edges, fill, merge and outlines. No world replay
or new full-state study is used. The tiny recorded vertex fixtures are retained
in `tools/polygon_span_cases.json` for the host model.

The final exact capture uses explicit bit 24 on 68EC030/50 NOMMU, 500 warm-up
fields and 50 recorded fields, CACR `0x2011`. **This is not the normal 030 CPU
policy.** Its 19 render/world calls are instrumented workload counts, not player
FPS. Remaining exclusive costs: scene rasterization **9.48 ms/frame**, viewport
copy **8.17 ms** (96% Chip-bus), and polygon compatibility only **0.22 ms**.
Overall Chip-bus share is **30.3%** and recognized blitter polling **8.8%**; native
gauges remain on this 030 selection. These are separate-workload attributions,
not an isolated cycle-saving claim. FC5 remains the next ordered step.

The final normal build, CUSTOM2 omitted, passes hook/default selection on both
enabled classes: `fc4-final-normal-{040,060}-1`. Each maximum-detail window
covers 250 PAL fields and records 125 publications, all 124 gaps exactly two
fields, with none on copper-pickup lines 42/43. Final screenshots retain the
scene, cockpit, needles and message. No new DMA-ownership study was needed:
the viewport copy and its fence are unchanged.

| Final normal CPU | FPS | Scene ms | Cockpit ms | World ms | Publication ms |
|---|---:|---:|---:|---:|---:|
| 040 | 24.960 | 33.002 | 3.864 | 1.963 | 0.0214 |
| 060 | 24.960 | 31.596 | 3.031 | 1.818 | 1.3528 |

Stage costs are means of completed brackets, not an additive whole-frame
budget; publication/world return-path coverage differs between cases. These
short initial-flight windows are separate workloads from the long A/B pairs.
They reach the unchanged two-field PAL cap, not 50 FPS.

Final normal/developer/VERIFY text sizes: 143,250 / 143,718 / 330,880 bytes.
SHA-256:

- Normal: `dbea82782bc73e9d75febf437cb9b2ec3c1018535da822493a7868e9705ba66d`
- Developer: `7148764be23e82f999b99b2e6f0359df88b987712010d8ab19caafbd7b330e39`
- VERIFY: `bc44d2fd6134a2ecf9b499d0c9602d3cc96fd2cc0ed67543828dd13e5e451f82`

The final VERIFY artifact is identical to the one used by the final exact
capture. Superseded preliminary captures were removed; the timing pairs,
final normal checkpoints and final exact capture remain.


To reproduce a normal default stage window from the initialized harness:

```sh
BENCH_BATCH_KEYS=1 BENCH_OMIT_CUSTOM2=1 \
python3 -B ../../R/RedBaron/tools/scene_profile_case.py \
  040 0 tmp/prof/fc4-manual-normal --fields 250 --groups stages
```

For an isolated comparison, freeze one developer slave/listing, select
`BENCH_DEVELOPER=1`, `BENCH_BATCH_KEYS=1` and `BENCH_FROZEN_SLAVE`, and use the
mask pair above with distinct output names and `--fields 2000 --groups fps`.
The exact profiler uses explicit `0x17f0ffa` on 030 NOMMU; it requires all six
native scene checks before recording. One owned emulator at a time.

## FC3 — persistent gauges, enabled on 060 (2026-10-12)

FC3 uses bit 23 and the shared bit-18 dispatcher/resource hooks.
Changed gauges restore the clipped background from screen-aligned Fast-RAM
words before the unchanged native needle callback. Unchanged gauges replay
only their native drawing state when their page key matches and the scene plus
all current static artwork end before their retained needle bounds. FC2 must
have composed the frame for this no-read reuse path; other frames redraw.
Full/dirty redraws, views, top text, messages, firing, exceptional foreground,
modal boundaries and resource changes invalidate reuse. The background cache
uses 27,216 bytes; shared per-page entries use 31,640 bytes. Allocation failure
retains native drawing. No minimum-RAM increase is needed.

Frozen candidate developer SHA-256
`61874c03900517abb8cdfb73c09a208afb130c0792183634a9fe293216e1dcfa`;
2,000 PAL fields per case, maximum detail, unchanged Time Scale, protected
fixture and native keyboard route. Candidate masks are `0x7f1fff`/`0xff1fff`
on 020, `0x7f0ffa`/`0xff0ffa` on the faster classes. The later source narrows
the persistence proof to the actual Fast-RAM artwork extents and excludes 020.
The normal bundle selects bit 23 only on 060. Developer/VERIFY can still select
030/040 explicitly for the shared-code twin and exact profiler; 020 is excluded
in all modes. Final normal-build and exact-profile checks pass.

| Configuration | FC3 off FPS | FC3 on FPS | Disposition / evidence |
|---|---:|---:|---|
| 68000 / A500 | — | — | CPU-gated off; prior scoreboard retained |
| 020 / A1200 | 7.563 | 7.089 (−6.27%) | Dropped; retain existing bit 18; `fc3-ab-020-{off,on}-1` |
| 030/50 MMU | 23.912 | 24.137 (+0.94%) | Below 2% resolution; `fc3-ab-030-{off,on}-1` |
| 030/50 NOMMU | — | — | Normal FC3 off; explicit candidate exact profile and native twins pass |
| 040/25 NOMMU | 22.414 | 22.789 (+1.67%) | Below 2% resolution; `fc3-ab-040-{off,on}-1` |
| 060/50 NOMMU | 21.840 | 23.363 (+6.97%) | Retain on 060; `fc3-ab-060-{off,on}-1` |

`fc3-final-twin-1` passes 28 native background comparisons: full and clipped
restores for all seven gauges on both pages. All 14 per-gauge/page unchanged
pixel/state comparisons pass, alongside six artwork, three scene and two
combined-cockpit twins. Native keyboard rear/left/right/front, firing, held
throttle and opposing-bank transitions pass. Five gauge inputs change on the
bounded route; two remain fixed in the protected fixture, so an all-seven-changing
flight is not claimed. Raw-key host tests cover changes to every gauge, including
both fuel branches. Three deliberately damaged result records are rejected.
The final extent-based reuse proof passes its host boundary tests and all native
checks in the final exact capture. The all-seven-changing flight is dropped
from this bounded fixture; per-input key mutation coverage and both-page native
twins are retained. These checks establish correctness separately from FPS.

The final normal build, CUSTOM2 omitted, passes the new hook/default checks in
`fc3-final-normal-060-1`. Its 250-field initial-flight window records **22.364 FPS**,
scene **39.137 ms**, cockpit **3.225 ms**, world **1.842 ms** and publication
**0.0262 ms** per completed call. This is a separate workload from the long A/B
pair; its FPS is not substituted into that comparison. The 112 publications
have 87 two-field and 24 three-field gaps, with none on copper-pickup lines 42/43.
The final screenshot retains the cockpit, needles and native message correctly.

`fc3-final-aprof-1` uses explicit developer selection on 68EC030/50 NOMMU,
500 warm-up fields and 50 recorded fields. **This is not the normal 030 policy.**
All 28 background twins and 14 reuse twins pass, alongside all artwork/scene/
composition checks and 68 final cockpit-page checks. The sample has 19 render
and world calls (19 instrumented FPS, not a normal FPS claim). Gauge dispatch
`sim:19ba6` costs **1.70 ms inclusive**; the CPU background painter costs
**0.61 ms exclusive**, 45% in Chip-bus accesses. Chip-bus share is **20.7%** and
recognized blitter polling **0.4%**. The prior FC2 exact window recorded 6.76 ms
for gauge dispatch, 26.9% Chip-bus share and 8.6% polling. These are separate
instrumented workloads, not an isolated numerical saving claim. They confirm
the gauge blitter waits are no longer a leading cost on the candidate path.

Remaining leading exclusive costs in that sample: viewport copy **7.86 ms**
(96% Chip-bus), polygon compatibility **7.21 ms**, scene rasterization **7.16 ms**,
static cockpit word painting **3.41 ms**, and exact artwork-key checks **2.76 ms**
(73% Chip-bus). FC4 is now complete; FC5 remains the next ordered step.

All 557 host tests pass, including three checker sabotages. The 135 hook ranges
and all three builds' patch destinations (135/135/149) pass. Final hashes:

- Normal: `8cbb1cf9208fa4a51a3c8b66c4a2468a69b2117e0ad2a6118ce46f53c22d84c1`
- Developer: `855202a064432a5e713a39941e16fcff042948bc45527dcc31f25f6882b1e7e0`
- VERIFY: `c1d6b7c049dedf25934570ab9d6f94f271aaf8672d56ffa47d3de9ef2312a66e`

To reproduce from the initialized development harness, use a fresh output name
and one owned emulator at a time. Normal default stage window:

```sh
BENCH_BATCH_KEYS=1 BENCH_OMIT_CUSTOM2=1 \
python3 -B ../../R/RedBaron/tools/scene_profile_case.py \
  060 0 tmp/prof/fc3-manual-normal --fields 250 --groups stages
```

For an isolated long comparison, freeze one developer slave plus its listing,
set `BENCH_DEVELOPER=1`, `BENCH_BATCH_KEYS=1` and `BENCH_FROZEN_SLAVE`, then run
060 with masks `0x7f0ffa` and `0xff0ffa`, `--fields 2000 --groups fps` and distinct
output names. For exact attribution, use the existing aprof method below with
explicit mask `0xff0ffa`; the report must use the live slave base from its entry
metadata. W6, the two-field cap, sound, minimum RAM and non-v1 games are unchanged.

## FC2 — Fast-RAM cockpit composition (2026-10-12)

**FC2 passed.** The three-class timing matrix, native pixel checks and final
normal-build checks pass. Bit 22 requires bits 19–21 and is
CPU-gated to 030/040/060. At the FC2 checkpoint the normal mask was `0x7f1fff`.
No extra RAM was allocated: the overlay word list occupies an unused part of the
existing reserved workspace. Gauges retained their prior implementation at FC2.

Same frozen developer build, masks `0x3f0ffa` / `0x7f0ffa`, maximum detail,
unchanged Time Scale, native keyboard route, 2,000 PAL fields each. SHA-256:
`e79814df4e7f15ec46d88ce5bcd5562610c90ec9bee8c4904427e8e10f79b1c8`.

| Configuration | FC2 off FPS | FC2 on FPS | State |
|---|---:|---:|---|
| 68000 / A500 | — | — | CPU-gated off; prior scoreboard unchanged |
| 020 / A1200 | — | — | CPU-gated off; prior scoreboard unchanged |
| 030/50 MMU | 18.645 | 23.962 (+28.51%) | `fc2-ab-030-{off,on}-2` |
| 030/50 NOMMU | — | — | Same CPU-class gate; final aprof and all native twins pass |
| 040/25 NOMMU | 18.046 | 22.389 (+24.07%) | `fc2-ab-040-{off,on}-1` |
| 060/50 NOMMU | 17.697 | 21.790 (+23.13%) | `fc2-ab-060-{off,on}-1` |

The completed 030 baseline counts publications in the stage trace; the candidate
uses the same publication point and VBlank count with verbose brackets omitted.
Two incomplete traces ended on malformed remote-debugger replies and are excluded.
The long-window driver now records only field/publication counters; stage costs
remain in separate short normal-build brackets. No emulated-time correction is
applied, and no FPS is reported from an incomplete capture.

`fc2-verify-030-3` passes six native artwork twins, three scene primitive twins,
and combined native overlay/programs 2–4 pixel twins on both pages. A VERIFY-only
final cockpit check also checks ordering and persistent outside-viewport pixels;
rear/left/right/front changes and hardware-key firing pass. The later source
change conservatively invalidates the overlay snapshot on redraw/modal events.
The host model covers clipped native overlay equations, ordered masked artwork,
opaque black and outside-viewport repairs; three corrupted-pixel cases fail its
comparison. All 552 host tests and 133 hook ranges pass. Patch reach is valid in
all three builds (133/133/147 destinations).

The final exact profile `fc2-final-aprof-1` uses 68EC030/50, all native VERIFY
checks, 500 warm-up fields and 50 recorded fields. All eleven native twins pass,
plus 68 final cockpit-page checks. Those final checks re-arm after invalidation
and run once per page, so they do not repeatedly scan Chip during steady profiling.
The source's normal/developer drawing code is byte-identical to the frozen A/B
candidate; the last changes enable the normal default and bound VERIFY checks.

The exact sample records 17 render/world calls (**17 instrumented FPS**, not a
normal-build result). Native `sim:2c144` overlay work and `artwork_sparse_update`
are absent from the steady hot path. FC2 composition costs 4.95 ms inclusive;
its four Fast-RAM word-list paints take 3.41 ms exclusive with no Chip-bus units.
Chip-bus share is 26.9% and recognized blitter polling 8.6%, versus 41.5% and
18.3% in the prior FC1 exact window. These are separate instrumented workloads,
not an isolated cycle-saving claim. The remaining major exclusive costs are
polygon compatibility work (7.96 ms), the viewport copy (7.62 ms, 96% Chip-bus),
and rasterization (7.18 ms). Gauge dispatch is 6.76 ms inclusive; its bitmap
routine accounts for 4.46 ms of blitter polling. Exact cache-key checks also cost
2.79 ms exclusive. FC3–FC5 remain the next ordered work.

Final normal-default checks use one binary, CUSTOM2 omitted, maximum detail and
250-field stage windows: `fc2-final-normal-030-1`, `fc2-final-normal-040-1` and
`fc2-final-normal-060-3`. The new hooks and pacing are installed by default.
Final screenshots show the cockpit and native messages intact. The 060 setup
was restarted after a host-controller false error, before any flight measurement;
LLDB diagnostic matching and already-stopped detach handling are now corrected.

| CPU | Normal FPS | Scene ms (includes FC2 composition) | Cockpit ms | Publication ms | Publication gaps, fields:count |
|---|---:|---:|---:|---:|---|
| 030 | 24.361 | 32.601 | 6.512 | 0.034 | 2:116, 3:5 |
| 040 | 20.767 | 40.640 | 4.775 | 0.031 | 2:66, 3:35, 4:2 |
| 060 | 20.767 | 38.702 | 7.046 | 0.024 | 2:63, 3:40 |

These short initial-flight windows differ from the long A/B windows; do not
combine them into an isolated gain. The existing publication logs pass the
two-field cap and avoid the copper-pickup lines on all three CPUs. No new DMA
ownership study was needed: the outbound copy and its fence remain unchanged.

Final text sizes: normal 138,960; developer 139,348; VERIFY 325,354 bytes.
Final SHA-256 values:

- Normal: `22dafcbaf336c0c4b4075c572ff140f961f0d1f7e60e061d9027579a38658181`
- Developer: `e79814df4e7f15ec46d88ce5bcd5562610c90ec9bee8c4904427e8e10f79b1c8`
- VERIFY: `2f2ca276ea924f29582fe3b38a90fda703cc1a5c23754732342f0067b78f58f7`

For a manual normal-build profile, use the configured development harness and a
fresh output name:

```sh
BENCH_BATCH_KEYS=1 BENCH_OMIT_CUSTOM2=1 python3 -B ../../R/RedBaron/tools/scene_profile_case.py 030 0 tmp/prof/manual-fc2 --groups stages --fields 250
```

Choose `040` or `060` for those classes. The driver selects maximum detail using
native keyboard input, detaches the host keyboard debugger, captures the guest
profile and quits its emulator. For a developer comparison, freeze the developer
slave and listing once, set `BENCH_DEVELOPER=1` and `BENCH_FROZEN_SLAVE`, use masks
`0x3f0ffa` / `0x7f0ffa`, and select `--groups fps --fields 2000` in separate fresh
output directories. The two cases must use the same frozen binary. These are
rendering measurements, not acceptance of frame-independent gameplay; W6/D5 is
unchanged.

Map-toggle check dropped: the documented game has no in-flight map command;
the campaign map is outside flight rendering. Its modal fence invalidates cached
page validity, as do the menu/preferences/flight-exit boundaries.

## FC1 — deferred display-page reuse (2026-10-12)

**FC1 passed.** Bit 21 is enabled by Faster rendering on 030/040/060, with
the private scene and pacing as mandatory dependencies. The normal mask at that checkpoint was
`0x3f1fff`, still CPU-filtered. Native fallback frames and 000/010/020 retain
the original beam wait. The two-field cap is unchanged. No third Chip page is
allocated and RAM requirements are unchanged.

The same-build comparison uses one frozen developer binary, maximum detail,
unchanged Time Scale, the damage-protected native-input route, and 2,000 PAL
fields per case. CUSTOM2 differs only by bit 21 (`0x1f0ffa` / `0x3f0ffa`), with
the existing CPU filters. These are whole-window results, not pixel-correctness
proof or a simulation-speed claim. Frozen developer SHA-256:
`f84165a9996c400354e088cd1042ab959d166b0e7ad11b342790de6323310982`.
This comparison predates the exceptional-error fence and the line-42 pickup
guard found by static audit. The final normal-build timings and safety checks below cover both corrections;
the candidate comparison alone does not establish their safety.

| Configuration | FC1 off FPS | FC1 on FPS | Publication off / on ms | State |
|---|---:|---:|---:|---|
| 68000 / A500 | — | — | — | CPU-gated off; prior scoreboard unchanged |
| 020 / A1200 | — | — | — | CPU-gated off; prior scoreboard unchanged |
| 030/50 MMU | 16.374 | 18.595 (+13.57%) | 6.859 / 0.058 | `fc1-ab-030-{off,on}-1`; beam check passes |
| 030/50 NOMMU | — | — | — | Same CPU-class gate; VERIFY and final aprof passed; no separate FPS pair |
| 040/25 NOMMU | 16.274 | 18.096 (+11.20%) | 5.926 / 0.046 | `fc1-ab-040-{off,on}-1`; beam check passes |
| 060/50 NOMMU | 16.299 | 17.697 (+8.58%) | 4.728 / 0.047 | `fc1-ab-060-{off,on}-1`; beam check passes |

The corrected VERIFY build (`fc1-final-verify-030-1`) passes all six artwork
and three scene twins before and after rear/left/right/front view changes and
native firing. Over the steady 20-publication sample, the fence releases 20
pages and actually waits once; startup and transition waits are counted
separately. The expected copper WAIT layout passes its runtime check.

The corrected exact capture `fc1-final-aprof-1` uses 68EC030/50, the full
VERIFY checks, 500 warm-up fields and 50 recorded fields. All nine twins pass.
It contains 15 render/world calls (15.0 **instrumented** FPS), 41.5% Chip-bus
units and 18.3% recognized blitter polls. The native sim:31536 spin executes
zero recorded instructions; the complete fence-wait routine costs 0.0168 ms
per render, the pickup-guard entry 0.0034 ms, and pacing/publication about
0.03 ms. The preceding FC0 exact capture recorded 48.7% Chip-bus units;
these shares describe their respective windows, not an isolated workload twin.
The remaining large costs are the scene (39.54 ms inclusive), instrument
scripts (8.82 ms), gauge dispatch (7.30 ms) and forward overlay (6.41 ms).
Those instrumented costs are not substituted for normal-build FPS.

All three final normal-default captures (`fc1-final-normal-{030,040,060}-1`)
use the same binary, CUSTOM2 omitted, maximum detail and a 250-field stage
window, followed by one 20-field DMA sample. These shorter initial-flight
windows are not the same workload as the 2,000-field developer comparisons;
their FPS must not be used to recompute the isolated candidate gain.

| CPU | Final normal FPS | Scene ms | Cockpit ms | Publication ms | Beam-sampled page writes |
|---|---:|---:|---:|---:|---:|
| 030 | 18.171 | 29.379 | 23.512 | 0.034 | 150,644 |
| 040 | 16.773 | 34.736 | 21.961 | 0.036 | 154,505 |
| 060 | 16.773 | 33.067 | 24.187 | 0.036 | 167,945 |

Every sampled field has exactly one displayed page. All three captures have
zero active-display writes, zero out-of-page bitplane fetches, and repeated
page turnover. Every publication in each 250-field bracket avoids copper pickup
and respects the two-field minimum, checked through `publication_cadence.py`.
The checker rejects page-write, copper-pointer and cadence sabotages. Raw DMA
streams were deleted after preserving compact reports. These are bounded
emulator checks; physical-machine confirmation remains FC7.

All 547 host tests, all three builds, 131 sim hook ranges and 131/131/145
normal/developer/VERIFY patch destinations pass. Text sizes are
137,610 / 137,998 / 323,328 bytes. Final SHA-256 values:

- Normal: `5d2ecba728eb7b64e22d9bc76adf2310aebf4a05fdb377637c2bb852401130ff`
- Developer: `fca217d8aea85fd630ec198a4ce42eef619dcfec8e561a2e508d774fc6760083`
- VERIFY: `7c1ee4147f319735fe3488c7e35a411ffc89c75b3e6194494db12c9d9b4cd219`

For a manual normal-build check, run `scene_profile_case.py` from the configured
development harness with `BENCH_BATCH_KEYS=1`, `BENCH_OMIT_CUSTOM2=1`, machine
`030`, `040` or `060`, mask `0`, a fresh output name, and
`--groups stages --fields 250 --dma-fields 20`. The harness supplies keyboard
input, selects maximum detail, captures and analyzes one owned emulator, deletes
the bulky DMA stream after success, and quits it. Developer A/B uses one frozen
binary, `BENCH_DEVELOPER=1`, masks differing only by `0x200000`, and
`--fields 2000`. This describes the FC1 comparison; FC2 results are above.
W6/D5 remains postponed.

## FC0 — native scratch completion and VERIFY snapshots (2026-10-12)

**FC0 passed.** The reproduced failure is a real pixel mismatch,
not a snapshot-allocation failure. On Barto 030 NOMMU with CUSTOM2=0x1f0ffa,
program 2 differs at the top-clipped polygon's first screen word (x=64–79).
The first uninstrumented failure changes eight bytes across four planes outside
the cached coverage mask. Native drawing changes those extra pixels to colour 6.

Bounded native traces locate the divergence before the screen merge: the scratch
word at the top edge varies between $003e, $ffde and $fffc, while the next row is
consistently $003e. CACR is $2011 (030 data cache disabled), excluding stale data
cache reads in this capture. Native mode sim:2fc64 is zero. These observations
rule out the investigated alternate-fill-mode and data-cache explanations.
Evidence: `fc0-barto-mismatch-1`, `fc0-polygon-trace-1`, `fc0-cacr-1`.

Waiting for native scratch operations to complete passes all six artwork twins
(`fc0-edge-trace-1`). Reducing the wait to the scratch clear alone also passes
(`fc0-clear-wait-1`). The final fix gives the existing bit-20 launch at
sim:2f66e a dedicated handler: a hardware scratch clear completes before return;
a private Fast-RAM clear still goes through the software backend. Registers and
the BLTSIZE store's CCR are preserved. Other native launches remain asynchronous.
This fixes the observed completion-order sensitivity; it is not a claim that
these emulator traces establish the behavior of every physical chipset (FC7).

Separately, VERIFY now takes its 80,000-byte artwork snapshot from the existing
reserved workspace range [$3c000,$4f880), after the scene storage and scene-twin
snapshots. Assembly assertions check overlap, alignment slack and the $50000
limit. Completion clears the twin's use pointer, never FreeMems a suballocation.
Missing workspace and pixel/state mismatch have distinct diagnostics. The
reservation already has room: 1 MiB slave Fast reservation and the tested
512 KiB Chip + 2 MiB Fast player minimum are unchanged.

The aprof driver no longer copies source or removes artwork checks. It records
the effective mask, live slave base, binary hash and full twin results, and
refuses profiling unless selected artwork and scene twins pass. The prior
allocation-only candidate passed aprof (`fc0-fixed-030n-1`, 500 warm-up fields,
50 capture fields), but failed Barto (`fc0-fixed-barto-030n-1`); that earlier pass
was not resolution of FC0. Exact committed-source aprof diagnostics also passed
(`fc0-original-1`), so the original ambiguous error never proved allocation loss.

The same final VERIFY binary passes six artwork twins and three scene twins,
then 20 flight steps, on every accelerated configuration:

| Configuration | Capture | Artwork / scene twins | Cache hits / fills |
|---|---|---:|---:|
| 030/50 NOMMU | `fc0-final-030n-1` | 6 / 3 | 309 / 3 |
| 030/50 MMU | `fc0-final-030-1` | 6 / 3 | 309 / 3 |
| 040/25 NOMMU | `fc0-final-040-1` | 6 / 3 | 309 / 3 |
| 060/50 NOMMU | `fc0-final-060-1` | 6 / 3 | 309 / 3 |

All use CUSTOM2=0x1f0ffa, filtered by CPU, maximum detail, and unchanged Time
Scale. VERIFY SHA-256 is
`ed7b2fa450b16432b8b21bd5fbeb6a2c9f9807917ceb5986097916f9753c00c9`.
Eleven existing renderer/cache model tests pass. Normal/developer/VERIFY builds pass (text 136,414 / 136,802 / 322,104
bytes), with 129 / 129 / 143 valid patch destinations. Final normal SHA-256:
`4ae6086c91f68345efe7dbf42a66d5bd668a1173a09cc5d4bd74f51da0e55616`.
`fc0-final-aprof-1` also passes all nine native twins with the same VERIFY hash:
68EC030/50, 2 MiB Chip + 8 MiB Fast, effective mask 0x1b4ffa, 500 warm-up PAL
fields followed by 50 capture fields. The exact report records 13 render/world
calls (13.00 VERIFY FPS), 48.7% Chip-bus units and 17.1% recognized blitter polls.
This remains an instrumented workload, not a new normal-build FPS claim. The
capture and report retain the full original correctness checks; FC0 is closed.

## Final release check (F3)

Passed on 2026-10-12. Normal slave SHA-256:
`d165a358a33712f4daade2a88bf556aa476ee2644c71b98e52cef5aba6202a37`.
The six 2,000-field captures `completion-f-<machine>-1` all use that same
normal binary with CUSTOM2 omitted, and each confirms the selected safe-swap
patch at sim:00b06. The scoreboard's F rows precede the artwork follow-up below:
event-free frame cadence is extracted conservatively from the event window,
not labelled as a separate steady-flight capture. The A500 uses the approved
512 KiB chip + 2 MiB fast minimum; its A2 stock baseline used 1.5 MiB slow RAM.
Cross-checkpoint stock comparisons are descriptive, not isolated feature gains.

All three builds pass (normal/developer/VERIFY text: 119,692 / 120,020 /
305,848 bytes), as do all 528 host tests, 81 sim and three sound hook ranges,
and 122 developer / 136 VERIFY patch destinations. Normal/developer outputs
exclude the checked VERIFY markers. Source did not change during the matrix.
Developer CUSTOM2=0 and normal Off (CUSTOM2=1, effective mask zero) both retain
all 81 sim and three sound ranges' original relocated bytes. Saved evidence:
`completion-f3-disabled-{developer,normal}`, including compact hunk dumps and
`disabled-check.json`; both were independently rechecked with `check_disabled.py`.
The first developer attempt failed on a host Python import before checking
bytes; its emulator exited during debugger cleanup. It is retained as a failed
attempt, and contributes no passing result. The corrected fresh attempt passes.

Icons and JOTD's original history are unchanged. D5 remains explicitly postponed,
and W6 is not in the normal verified mask. The accepted release therefore makes
no 50 FPS or frame-independent normal-game-speed claim. No push was made.

To reproduce the normal final matrix with the established local harness:

```sh
source tmp/dev/amiga/env.sh
cd tmp/dev
python3 -B tools/release_final.py
```

The driver refuses to overwrite completed output directories. Archive completed
results or choose fresh output names before an intentional rerun. It runs one
owned emulator at a time and deletes consumed memory-location scans after saving
compact evidence. The final binary is `tmp/dev/tmp/build/RedBaron.slave` from the
repository root; replace the installed slave with that normal binary to use it.

## Fast-CPU rendering reprofile (2026-10-12)

Post-release investigation; normal runtime unchanged. Interpretation and the next
renderer design are in [rendering-analysis.md](rendering-analysis.md). This section
supersedes any inference that the release's 14–15 FPS is a hardware ceiling.
Only 030/50 MMU, 040/25 NOMMU and 060/50 NOMMU were profiled; no stock A500/A1200.

**Build/workload.** F3 normal SHA-256
`d165a358a33712f4daade2a88bf556aa476ee2644c71b98e52cef5aba6202a37`,
source `a2450f5`, Faster rendering On, no CUSTOM2 argument, no W6 or guest VERIFY
instruments. Same completion-matrix memory/cache/CPU settings, PAL, maximum detail,
Ground IN COMBAT, Time Scale unchanged, protected native flight. External debugger
breakpoints only; input uses the existing host-debugger keyboard driver.

Evidence: `render-fast-{030,040,060}-1` and `render-fast-060-lines`. Four broad
probe groups each cover 250 consecutive PAL fields. The additional 040/060 wait
and launch groups cover 100 each; the fresh 060 line/program groups cover 250
each. These are consecutive evolving scenes, **not** interchangeable A/B windows.
Every accepted window reaches its field bound without flight exit. Costs include
interrupts and bus waits. The unchanged phase filter rejects endpoints below the
observed safe beam line and at horizontal-counter ambiguity; zero-length
sub-slot calls are listed separately, not silently made positive. A transient
parser rejection of such a zero in the first cockpit log was repaired by explicit
sub-resolution accounting, without rerunning or modifying its raw measurements.

### Whole-frame accounting

These rows use the same accepted frames for every column: world entry to the next
world entry, six disjoint brackets, plus the measured residual. They account for
100% of those frame intervals. Unlike a sum of separately filtered routine means,
this is an additive budget. Publication includes synchronization. Opening scenes
are heavier than later windows and the longer release average.

| Config | Matched frames | World ms | Scene ms | Cockpit ms | Messages ms | Publication ms | Background + other ms | Total ms | Whole 250-field opening FPS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 030/50 MMU | 58 | 1.638 | 39.468 | 28.051 | 0.001 | 4.539 | 0.188 | 73.886 | 13.578 |
| 040/25 NOMMU | 33 | 2.071 | 41.417 | 26.757 | 0.175 | 6.651 | 0.223 | 77.294 | 12.580 |
| 060/50 NOMMU | 53 | 1.897 | 40.483 | 27.648 | 0.098 | 9.260 | 0.222 | 79.609 | 12.380 |

The later 250-field bitmap windows publish at **14.577 / 14.776 / 14.377 FPS**
respectively. This reproduces the plateau region with the final binary, while
showing why opening-frame costs must not be divided into the release's average
FPS. These short observations do not replace the F3 release scoreboard above.

### Cockpit subcalls

Separate accepted-call means in the cockpit window; n in parentheses. Different
endpoint exclusions mean these columns must not be added as an exact frame budget.
Gauge dispatch and its nested body are counted only once.

| Config | Forward overlay ms | Gauge dispatch ms | Instrument/foreground scripts ms |
|---|---:|---:|---:|
| 030/50 | 7.024 (49) | 11.182 (49) | 14.162 (44) |
| 040/25 | 7.138 (50) | 9.326 (51) | 13.325 (47) |
| 060/50 | 6.808 (47) | 12.404 (51) | 13.437 (54) |

The settled 040 program census records programs 2/3/4 **30 times each**. Their
accepted call means are **9.965 / 2.367 / 1.986 ms** (25/21/19 calls). The separate
060 program window records 2/3/4 59 times each, at **8.948 / 2.432 / 2.095 ms**
(48/37/38 accepted). It also records program 1 on 20 occasions, 19 accepted at
5.900 ms, explaining additional cockpit event work in that window.

On 060, within 46 accepted cockpit parents (30.620 ms mean), accepted gauge bitmap
calls contribute at least **6.427 ms/frame** and callbacks **2.062 ms/frame**;
restore/clip setup at `sim:19d8c` contributes 0.003 ms. These are lower bounds after
endpoint exclusions. On 040, the retained gauge cache reduces calls reaching these
native sites; absence at those sites is not absence of cache/composition cost.

### Primitive and wait attribution

Only calls contained in an accepted parent are included. Sums below are **lower
bounds**: phase-ambiguous child endpoints are excluded. The report unions nested
intervals. Distinct probe groups remain distinct windows, so do not add their
rows into a synthetic exact budget.

| Config / group | Parent frames | Parent mean ms | Attributed child ms/frame |
|---|---:|---:|---|
| 040 scene / rectangle+polygon | 68 | 40.458 | rectangle ≥9.402; polygon ≥8.606; union ≥18.009 |
| 060 scene / lines | 53 | 40.649 | line ≥8.407; 22.04 accepted calls/frame |
| 060 cockpit / lines | 54 | 27.462 | line ≥2.958; 17.19 accepted calls/frame |
| 030 cockpit / bitmap | 69 | 27.608 | bitmap ≥7.098; overlay body ≥5.353 |
| 040 cockpit / bitmap | 67 | 24.647 | bitmap ≥3.916; overlay body ≥5.803 |
| 040 scene / rectangle waits | 24 | 35.639 | plane waits ≥7.208 |
| 060 scene / rectangle waits | 19 | 34.467 | plane waits ≥6.406 |
| 040 scene / polygon waits | 23 | 36.011 | fill/edge/merge waits ≥3.173 |
| 060 scene / polygon waits | 18 | 33.786 | fill/edge/merge waits ≥3.258 |
| 040 cockpit / rectangle waits | 24 | 24.716 | plane waits ≥5.782 |
| 060 cockpit / rectangle waits | 23 | 27.610 | plane waits ≥5.394 |
| 040 cockpit / overlay waits | 13 | 25.020 | waits ≥5.425 |
| 060 cockpit / overlay waits | 23 | 27.326 | waits ≥4.627 |

Line time can overlap polygon/rectangle parents; it must not be added blindly to
their inclusive costs. Polling intervals include loop instructions and interrupts;
these are not exclusive blitter DMA times or a Chip-bus saturation measurement.

### Work and traffic census

Each launch census has **29 complete frames**. Both 040 and 060 agree on these
counts; sizes are decoded from the native BLTSIZE operand before the write.

| Work per complete frame | Launches | Destination plane-bytes |
|---|---:|---:|
| Scene sky/ground rectangles, all five planes | 10 | 24,000 |
| Cockpit rectangles | 55 | 10,410 |
| Cockpit polygon area fill | 1 | 190 |
| Cockpit polygon five-plane merge | 5 | 950 |
| Forward overlay, 320×52, five planes | 5 | 10,400 |

The scene rectangle heights are 63+57 (040) and 64+56 (060); each pair covers
320×120. Scene polygon counts vary with the evolving view: 040 records 282 fills
and 1,410 merges, 060 290 and 1,450, over those 29 frames. Most cockpit rectangles
are one or two words wide and 94–117 lines tall, plus shorter strips.

The observed rectangle minterms enable D only for the full scene interiors, C+D
for the masked cockpit strips. Native overlay/fill/merge setups enable four/two/
three channels. **Derived:** the sampled cockpit operations therefore request
65,650 bytes of DMA data transfers per frame before bitmap and line work
(20,820 + 380 + 2,850 + 41,600). This is a workload byte count, not measured bus
bandwidth. At 50 FPS that subset alone would request 3.2825 MB/s.

### Discarded CPU backend: scope of the finding

The frozen E3 binary/listing `completion-e3-fast-frame-060-on` has SHA-256
`0d0abc903b8bfd91671da408adfac0c331fe601ddfe86c8058b309982dc303f5`.
Source inspection proves 48,000 bytes copied Chip→Fast at scene entry and 48,000
Fast→Chip on exit: **96,000 Chip-facing bytes/frame**, 2.4 times a single 40,000-
byte final screen copy. It emulates individual planar blitter operations and
leaves native cockpit rendering outside the Fast RAM pass. Its retained C kernel
is in `tools/fast_blitter_model.c`. This is not evidence against a persistent,
span-based CPU renderer with one final transfer.

New timing probes `render-cpu-backend-060-{1,2,3}` are **excluded**: the first hit
a native input-queue conflict before profiling; the hardware-input retry reached
flight but the debugger returned a malformed packet after 20 fields; its follow-up
stalled. Only the verified owned processes were stopped. No new CPU-backend FPS,
copy-time or kernel-time claim is made. The earlier successful whole-window E3
regression remains historical evidence for that particular implementation.

Four focused host accounting controls pass: nested-interval union, same-frame
six-bracket accounting, wrong-return-stack rejection, and discontinuous-field
rejection. The report reprocesses all completed captures. Runtime source, player
settings, release mask and D5 disposition are unchanged.

## Sparse cockpit artwork follow-up (2026-10-12)

New user-authorized scope after release: remove repeated static artwork work.
Bit 19 joins the normal Faster rendering bundle on 030/040/060 only. D5 remains
postponed. Programs 2–4 store only covered words and repair differing masked
pixels on the actual draw page. This does not prevent scene overwrites.

First bounded native pixel/drawing-state twin passes (one hit, 40,000 screen
bytes and 24 drawing-state bytes); four sparse-repair host tests cover independent
pages, opaque black, intervening damage, idempotence and bounded overflow.
The expanded three-program/two-page candidate passes six native twins
(`artwork-sparse-twin-060-4`): 306 hits, three fills, no fallbacks. The six-configuration
CPU timing matrix is complete. Native keyboard view/firing checks pass on 040.
All 536 host tests and 83 hook ranges pass.

| Candidate / CPU | Fields per window | Opening FPS off → on | Cockpit mean ms off → on | Status |
|---|---:|---:|---:|---|
| Sparse program 2 / 060 NOMMU | 250 | 12.380 → 13.179 (+6.45%) | 28.029 → 26.494 | Initial candidate; not release policy |
| Sparse programs 2–4 / A500 | 250 | 2.196 → 1.997 (−9.09%) | 53.578 → 85.914 | Rejected on 68000 |
| Sparse programs 2–4 / 020 | 250 | 6.789 → 6.789 (0.00%) | 30.860 → 31.278 | Dropped on 020: no gain |
| Sparse programs 2–4 / 030 MMU | 250 | 13.578 → 14.377 (+5.88%) | 27.965 → 23.273 | Enabled on this CPU class |
| Sparse programs 2–4 / 030 NOMMU | 250 | 13.578 → 14.577 (+7.35%) | 28.025 → 23.100 | Enabled on this CPU class |
| Sparse programs 2–4 / 040 NOMMU | 250 | 12.780 → 13.778 (+7.81%) | 26.478 → 22.025 | Enabled on this CPU class |
| Sparse programs 2–4 / 060 NOMMU | 250 | 12.380 → 13.578 (+9.68%) | 27.351 → 24.383 | Enabled on this CPU class |

Evidence: `artwork-sparse-060-{off,on}-1`, identical developer SHA-256
`71db1669ccd2634d9261fafa0d0c155cd43d9a258aa4fcd4d72f707835d68046`. Masks differ only by bit 19
(`0x30ffa` / `0xb0ffa`). Established native maximum-detail route; Time Scale
unchanged, W6 off. Costs include interrupts and waits. Opening windows are
matched by route, not step-locked; scene means were 40.584 / 40.746 ms.
The subsequent program census is a separate evolving window, not an additive
frame budget. Native comparison: `artwork-sparse-twin-060-3`. Earlier attempt
2 safely fell back after allocation failure and supplies no passing cache test;
attempt 1 failed assembly before boot. The current candidate uses the already
reserved renderer workspace to avoid competition with the game's allocation pool.

All six expanded-candidate pairs use identical developer SHA-256
`8f49045d4021ba13b5a1e8d0c749a95d84417ed0e347995e6df8037a74307cc1`, frozen
from the A500-on capture. Evidence is `artwork-sparse-<machine>-{off,on}-1`,
except the 060 pair uses suffix `-2`. Every pair differs only by bit 19. Each
opening and subsequent artwork window is 250 fields.
On 68000, the static framework alone rises from 15.043 to 38.309 ms: CPU
pixel checking is a regression, so that class must retain native drawing.
The initial 060 result is superseded by the three-program row for this candidate.

Final policy drops the candidate on 000 (regression) and 020 (no FPS gain), and
retains native artwork on unmeasured 010. The normal bundle starts at `0xf1fff`
and applies that CPU gate; developer/VERIFY bit 19 uses the same gate. The
normal build's other verified policies and the minimum RAM requirement are
unchanged. Cache storage uses the reserved Fast workspace and 8,000 extra Chip
bytes for the framework mask, with native fallback.

`artwork-final-verify-040-4` passes six initial native pixel/state twins (three
programs × two pages), then hardware F2/F3/F4/F1 transitions and six firing frames
(five actual native firing-branch visits). The warmed cache returns to forward
flight: 345 hits, three fills, no fallback; all six initial twin flags remain
passed. They are not six additional post-transition comparisons. Screenshots of
firing and the final cockpit were inspected. Attempt 1 exposed the completed
VERIFY tape swallowing commands, then its host debugger exited; attempt 2
confirmed debugger writes did not restore the tape hook; attempt 3 failed
assembly before boot. These supply no passing transition evidence. The VERIFY
route now hands input back to the native pop after menus with CUSTOM5=0;
nonzero scripted fixtures and W6's own input path retain their prior behavior.

Normal/developer/VERIFY builds pass (text: 123,596 / 123,960 / 308,702 bytes),
as do 536 host tests and 83 hook ranges. Normal SHA-256:
`6ed8664416b9eadf75595a608a4a26ad3a0941155a26dca6654b98ad460cace2`.
Normal smoke checks `artwork-final-normal-{a500,030}-1` use that same binary,
CUSTOM2 omitted, and native menu/preferences input. Both reach flight and confirm
default-on safe swaps. The A500 boots at 512 KB Chip + 2 MB Fast and retains the
original entries at sim:15f1e/sim:15f8a; the 030 installs both artwork hooks.
These are selection/boot checks, not new FPS windows. All owned emulators and
input controllers were closed after validation.

Reproduce an isolated developer comparison from the local harness with
`BENCH_BATCH_KEYS=1 BENCH_DEVELOPER=1 BENCH_FROZEN_SLAVE=<capture>/slave.slave`
and `../../R/RedBaron/tools/artwork_profile_case.py <machine> <mask> <new-output>`.
Use the identical binary for both masks and change only bit 19; each group is
250 PAL fields. Current source gates that bit off on 000/010/020, so the rejected
slow-CPU experiments require their frozen pre-policy binary. The bounded native
comparison and keyboard transitions use
`python3 -B ../../R/RedBaron/tools/artwork_verify.py 040 <new-output> --transitions`.
VERIFY timings are not performance evidence. Run one owned emulator at a time.

## Direct scene viewport development (2026-10-12)

User-authorized scene follow-up, bit 20; now selected by Faster rendering on
030/040/060 after the comparisons below. 000/010/020 retain native drawing. Native scene setup/clip remain. Direct rectangles
and lines write all five colours, polygon coverage is traversed once for all
planes, and uncommon primitives retain the compatibility kernel. The guarded
full-width viewport has a native background clear, so no inbound screen copy is
performed. Only its rows are published to Chip RAM; scratch is not exported.

`scene-direct-twin-060-1` passes one native pixel comparison per direct primitive
(rectangle, line, polygon merge; result bits 7, count 3), over the same input
pixels. Final flight screenshot inspected. The capture driver's first attempt
to save the passing result used an unquoted absolute path; it was saved from the
same paused session with a relative path, without rerunning the guest. These are
bounded primitive twins, not performance evidence or a world-state replay.
Three host tests cover randomized fills, line octants/ties and five-plane merges.
All 539 initial host tests and 122 hook ranges pass.

First frozen 060 pair (`scene-direct-060-{on,off}-1`, same slave SHA-256
`c459e80cbec398dc89b9bb6b843b5883004ae2d219477ec225b5dbdd447733d4`, only
bit 20 differs): each group captures 250 PAL fields, native input, maximum detail.

| Stage window | Native | Direct scene | Change |
|---|---:|---:|---:|
| FPS | 13.578 | 13.778 | +1.47% |
| Scene ms | 41.062 | 41.018 | −0.11% |
| Cockpit ms | 23.873 | 24.052 | +0.75% |
| Publication ms | 7.231 | 6.284 | −13.10% |

The following draw windows both deliver 12.780 FPS. Accepted rectangle mean falls
from 3.770 to 0.636 ms, while polygon mean rises from 0.793 to 1.319 ms. These are
consecutive changing scenes and differing accepted samples, not paired primitive
inputs; they identify the remaining general scratch clear/fill loops for revision.
The first candidate misses 2% and is **not release-enabled**. Revision 2 replaces
native polygon scratch clear and inclusive fill with direct loops, retaining
register postconditions and the existing independent fill model; a bounds/alignment
clear test was added. All 540 host tests and 122 hook ranges pass; normal,
developer and VERIFY builds pass.

Revision 2 frozen slave SHA-256:
`cfa9cfcfe053bce137a47c4a7d8c9f549b7dd989efd7ce814dcdc1fe403c2d71`.
Each CPU pair uses this identical developer binary and differs only by bit 20;
native keyboard entry, maximum detail, 250 PAL fields per stage window, W6 off.
Evidence: `scene-direct-<machine>-{on,off}-2`.

| CPU | Native FPS | Direct FPS | FPS change | Native scene ms | Direct scene ms |
|---|---:|---:|---:|---:|---:|
| 030/50 MMU | 14.377 | 16.574 | +15.28% | 39.286 | 29.917 |
| 030/50 NOMMU | 14.577 | 16.574 | +13.70% | 39.312 | 28.624 |
| 040/25 | 13.578 | 15.975 | +17.65% | 42.550 | 35.053 |
| 060/50 | 13.778 | 16.574 | +20.29% | 40.800 | 33.456 |

The 060 follow-on draw window also improves, 12.979 → 13.978 FPS (+7.69%):
scene 43.312 → 35.450 ms, accepted rectangle mean 4.026 → 0.621 ms and
polygon mean 0.809 → 0.804 ms. This supports the intended reduction in rectangle
work without the first revision's polygon regression. These are different windows,
not a steady 16.6 FPS claim; changed frame timing also changes the subsequent
frame-dependent native flight. Primitive models/twins establish correctness.
All four comparisons exceed 2%; bit 20 is retained on 030/040/060. The normal
bundle starts at `0x1f1fff`, with the existing per-CPU exclusions; W6 stays out.

Functional revision-2 evidence:
- `scene-direct-verify-040-transitions-2`: native twins for all three direct
  primitives pass (bits 7, count 3); rear/left/right/front views select correctly,
  ownership is inactive again at each flight anchor, and five native firing
  calls execute. All five screenshots inspected, without stale cockpit/view pixels.
- `scene-direct-verify-030-bank-2`: banked fixture to step 40, then ten further
  anchors; all three twins pass. Banked screenshot inspected. This exercises the
  MOVEM publication path, while 040 exercises MOVE16.
- No world-state replay or new byte-equivalence study. VERIFY timing is excluded.

✔ Final normal-build checks pass: `scene-final-normal-{a500,060}-1` reaches
flight with CUSTOM2 omitted and confirms Faster rendering selected. The A500
at 512 KiB Chip + 2 MiB Fast retains the native line/rectangle hooks; the 060
selects both direct hooks. These are entry/selection smoke checks, not additional
FPS captures. Both use normal slave SHA-256
`6788b1248a974b378566fa9d96dce8c0648fb65f6db757bf42d008594bb42960`.

Final normal/developer/VERIFY text sizes: 136,376 / 136,764 / 322,024 bytes.
Normal/developer contain neither RBVERIFY nor RBSTEPS1; the rebuilt developer
hash is identical to the measured frozen binary. All 540 host tests, 122 sim
hook ranges and 129 / 129 / 143 patch destinations pass. The CPU policy and
primitive code are final; D5 and W6 acceptance remain postponed.

## Completion scoreboard

This is the single results table for `completion-plan.md` A–F. “Pending”
means not yet measured on the normal build; historical isolated-feature
results below are not combined-bundle results. The A2 A/B pairs each used one slave
binary with CUSTOM2=0 and CUSTOM2=1. Later checkpoints retain that stock
baseline and update the normal-bundle columns; their checkpoint labels identify
which rows have been refreshed. Stage spans are inclusive wall time;
scene, cockpit and publication are separate stages, not CPU-only costs.

| Configuration | Checkpoint | Stock steady / event FPS | Bundle steady / event FPS | World update ms | Scene / cockpit / publication ms | DASH markers stock / bundle | Clean fields stock / bundle | World time / wall time | Dropped world time | B1 isolated pool FPS, off → on | B2 raw CACR, before → after | B2 isolated cache FPS, off → on | C1 discarded pair FPS, off → on | C2 discarded pair FPS, off → on | C3 isolated face-loop FPS, off → on | D5 candidate whole-window FPS (Time Scale 40) | E1 W6 scene / cockpit / publication ms | E2 gun-cache FPS off → on (dropped) | E2 solid-cache FPS off → on (dropped) | E2 persistent-gauge candidate FPS off → on | E2 combined front-script FPS off → on (dropped) | E2 complete cockpit FPS off → on (dropped) | E3 CPU rectangle FPS off → on (dropped) | E3 CPU polygon merge FPS off → on (dropped) | E3 Fast-RAM scene FPS off → on (dropped) | E4 field deadlines covered / 2,000 (W6 candidate) |
|---|---|---|---|---|---|---|---|---|---| --- |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A500, 512K chip + 2M fast (F); A2 stock used 1.5M slow | F bundle / A2 stock | 1.844 / 1.722 | 2.235 / 2.221 | 57.68 → 51.14 | 399.51 / 73.70 / 0.28 → 327.74 / 53.75 / 6.45 | 3 / 3 | 1516 / 1296 | 0.924744 (candidate D5) | 5,400 units / 12 steps | Minimum-memory flight passes | N/A (68000) | No cache hardware | 1.955 → 1.975 (+1.01%) | 1.970 → 1.936 (-1.72%) | 1.931 → 1.997 (+3.39%) | 0.824 | — | CPU-gated off | CPU-gated off | CPU-gated off | CPU-gated off | CPU-gated off | CPU/AGA-gated off | CPU/AGA-gated off | CPU-gated off | Not evaluated for E4 |
| 020, 2M chip + 8M fast | F bundle / A2 stock | 6.008 / 5.666 | 7.244 / 7.638 | 13.79 → 10.17 | 116.77 / 41.40 / 0.08 → 86.61 / 29.36 / 5.71 | 44 / 23 | 1196 / 696 | 1.001296 (candidate D5) | 0 | 6.398 → 6.695 (+4.6%) | 0x0000 → 0x0001 | 6.754 → 7.280 (+7.8%) | 7.266 → 7.258 (-0.11%) | 7.193 → 7.210 (+0.24%) | CPU-gated off | 4.568 | — | 4.568 → 4.443 (-2.73%, fast compositor) | 4.593 → 4.343 (-5.43%) | 4.568 → 4.668 (+2.19%) | 4.568 → 4.343 (-4.92%) | 4.568 → 2.446 (−46.45%) | 4.418 → 4.093 (-7.34%) | 4.643 → 4.393 (-5.38%) | 4.643 → 2.596 (−44.09%) | Not evaluated for E4 |
| 030/50, 2M chip + 8M fast, MMU | F bundle / A2 stock | 12.974 / 11.881 | 14.860 / 14.502 | 3.33 → 1.72 | 44.19 / 34.08 / 0.08 → 34.96 / 28.46 / 4.52 | 191 / 56 | 1154 / 877 | 0.998656 (candidate D5) | 0 | 12.878 → 14.546 (+12.9%) | 0x2111; unchanged | Already enabled | 14.562 → 14.595 (+0.22%) | 14.556 → 14.514 (-0.29%) | CPU-gated off | 12.280 | — | 12.305 → 12.305 (+0.00%, fast compositor) | 12.305 → 12.330 (+0.20%) | 12.305 → 12.305 (+0.00%) | 12.280 → 12.330 (+0.41%) | 12.305 → 9.784 (−20.49%) | CPU/AGA-gated off | CPU/AGA-gated off | 12.305 → 8.736 (−29.01%) | 493; fails every-field cadence |
| 030/50, 2M chip + 8M fast, no MMU tooltype | F bundle / A2 stock | 12.377 / 11.931 | 14.857 / 14.477 | 3.94 → 1.66 | 48.31 / 31.23 / 0.04 → 34.92 / 28.61 / 4.50 | 58 / 62 | 1262 / 948 | 0.998656 (candidate D5) | 0 | 030 class measured with MMU | 0x2000 → 0x2011 | 12.889 → 14.537 (+12.8%) | 030 class measured with MMU | 030 class measured with MMU | CPU-gated off | 12.280 | — | CPU class measured with MMU | CPU class measured with MMU | CPU class measured with MMU | CPU class measured with MMU | CPU class measured with MMU | CPU/AGA-gated off | CPU/AGA-gated off | CPU class measured with MMU | CPU class evaluated with MMU |
| 040/25 NOMMU, AGA, 2M chip + 16M Z3 fast | F bundle / A2 stock | 12.476 / 11.507 | 14.754 / 14.352 | 3.34 → 2.09 | 47.56 / 36.26 / 0.06 → 38.03 / 25.51 / 4.72 | 116 / 47 | 1144 / 1144 | 0.998656 (candidate D5) | 0 | 12.392 → 13.277 (+7.1%) | 0x80008000; unchanged | Already enabled | 13.384 → 13.428 (+0.32%) | 13.393 → 13.437 (+0.33%) | CPU-gated off | 11.631 | 45.42 / 32.53 / 2.89 | 11.656 → 11.557 (-0.86%, fast compositor) | 11.631 → 11.557 (-0.64%) | 11.631 → 11.981 (+3.00%) | 11.631 → 11.806 (+1.50%) | 11.656 → 6.714 (−42.40%) | 12.031 → 11.407 (-5.19%) | 12.031 → 11.706 (-2.70%) | 11.981 → 8.711 (−27.29%) | 480; fails every-field cadence |
| 060/50 NOMMU, AGA, 2M chip + 16M Z3 fast | F bundle / A2 stock | 12.786 / 12.206 | 14.200 / 14.003 | 3.16 → 1.98 | 44.63 / 33.43 / 0.03 → 36.48 / 28.06 / 5.03 | 64 / 51 | 1452 / 1515 | 0.998656 (candidate D5) | 0 | 12.585 → 13.909 (+10.5%) | 0xa0808000; unchanged | Already enabled | 13.953 → 13.959 (+0.04%) | 13.982 → 13.998 (+0.11%) | CPU-gated off | 12.006 | 53.03 / 29.37 / 4.41 | 12.056 → 11.981 (-0.62%, fast compositor) | 12.031 → 12.006 (-0.21%) | 12.031 → 12.206 (+1.45%) | 12.031 → 12.081 (+0.41%) | 12.081 → 7.089 (−41.32%) | 12.081 → 11.157 (-7.64%) | 12.056 → 11.706 (-2.90%) | 12.056 → 8.711 (−27.74%) | 483; fails required every-field cadence |

C2 is dropped under §0.3: every 2,000-field same-build CPU-class pair is below 2%; the live-slot cache passed its native mission-load/bank-change/exit twin (54,020 calls, 11 invalidations, zero mismatches), 437 host tests and the hook audit. Candidate developer SHA-256 `eeadc00619d796c3850f4d83f4bf51a87ea80019737935e5a78418ef17b502ea`; evidence `completion-c2-{a500,020,030,040,060}-{off,on}` and `completion-c2-twin-r2`. The normal bundle is unchanged.

C3 is enabled only on the 68000 through bit 6: the register-held face vertex loop at `sim:3b4cc` improves the same-build 2,000-field comparison by 3.39%. The native per-face twin passes 1,455 calls (1,091 fast-path faces, 1,234 inline cache hits, 2,412 misses), checking all registers/CCR and the renderer scratch context; 435 host tests, three checker sabotages, all builds and hook/reach audits pass. Other transform dispatches retain the original loop. Candidate developer SHA-256 `a6393b6f7eea27881352387249649bdb2f3545f0617dbb5a168bf919d42f1b95`; evidence `completion-c3-a500-{off,on}` and `completion-c3-twin`. Checkpoint C is complete on all six normal-build configurations (one 2,000-field event window each), SHA-256 `a2dac77b7a4da658dcf198fc371fdd3274d3ef622f20753693951de99172cbdf`; evidence `completion-c-<machine>-1`. The table retains the A2 stock baseline, so cross-checkpoint deltas are not same-scene causal gains; C3's isolated pair establishes its gain.

D2 is compiled in all modes after D4; D5 acceptance remains open: 450 units on 68000, 225 on 020+, exact normalized phase with both precomputed tables, and a retained-debt ceiling of 1800 primary units (about 0.98 nominal seconds at Time Scale 40). Excess funded updates are counted as dropped, while input and real-time services retain chronological consumption. The private native stock-helper twin passes 1,377 dt=450 calls (935 straight, 442 banked), and both clock tables pass all 852 arithmetic cases; 439 host tests and three checker sabotages pass. Evidence `completion-d2-twin-r2`. This heavily instrumented run is not FPS/capacity evidence; the candidate D5 rate/drop results above are separate uninstrumented measurements.

D3 is compiled in all modes after D4: the 68000 skips pose capture/blending and their lifecycle hooks, while 020+ keeps interpolation. The native `completion-d3-a500` check spans 19 world-loop intervals with zero pose-capture calls, zero blend calls and five completed native draws; all three modes, 439 host tests and hook/reach audits pass. This is a functional bypass check, not a standalone FPS claim; player measurements remain D5.

D4 runtime promotion is complete, with no new performance claim: normal/developer/VERIFY code sizes are 116,898 / 117,214 / 302,184 bytes. All 441 host tests, 79 hook ranges, and 134 VERIFY / 113 developer patch destinations pass. Developer bit 13 enables timing on 68000/020+, forces bits 8/9 with a one-field cap, and modal resume restores the selected quantum. Player fixtures/logs are excluded; normal verified-mask activation awaits D5 acceptance. First-flight entry resets draw eligibility on both CPU paths, including the 68000 path that skips pose capture.

### E3 rectangle disposition

Direct-to-chip CPU rectangle fills are **dropped under §0.3**: all three affected AGA classes regress (scoreboard); retain the original blitter path and proceed to polygon merging, then the fast-memory back buffer.

The same-build 2,000-PAL-field pairs use maximum detail, Time Scale 40 and
W6, plus the retained gauge cache on 020/040. Developer SHA-256
`0954f493be5a247f88b29edcd1d853739845473f50f830e442da7cc452f79b11`; evidence `completion-e3-rect-{020,040,060}-{off,on}`.
The A500 and OCS 030 classes were gated off, not measured for this primitive.
The existing native pixel twin passed 11,780 CPU planes (2,060 aligned,
9,720 masked), comparing 2,632,585 words without a mismatch; evidence
`completion-e3-rect-twin-r3`. Correct pixels did not imply a speed gain.

The discarded runtime is preserved as `completion-e3-rect-candidate/candidate.patch`
against `6bd76f0`; host models remain for the fast-memory path. The twin now
initializes its h3 pointer at installation, so menu checks no longer depend
on the flight observer having run. Its original-blitter path also passed
11,910 comparisons in `completion-e3-rect-twin-r2`. No new checker was added.
All three retained-code builds pass (normal/developer/VERIFY text sizes
119,680 / 120,020 / 305,848 bytes), with 518 feature-suite tests, 81 hook
ranges and 136 VERIFY patch destinations. The normal verified mask remains
`0x71fff`; D5 is still postponed.

### E3 polygon-merge disposition

Direct-to-chip CPU polygon coverage merging is **dropped under §0.3**: all three affected AGA classes regress (scoreboard); keep the native blitter merge and continue with the fast-memory back buffer.

Each same-build pair covers 2,000 PAL fields at maximum detail and Time Scale
40 with W6, retaining the gauge cache on 020/040. Developer SHA-256
`fd6d7ed4fa82537f0a76feece94948cb0388c23dde280f43ddbe273b074d24e3`; evidence `completion-e3-span-{020,040,060}-{off,on}`.
A500 and OCS 030 were CPU/AGA-gated off. The candidate used aligned longword
merges, skipped transparent coverage, and avoided destination reads for opaque
coverage. Its native twin passed 1,095 planes / 436,475 words with no fallback
or mismatch (`completion-e3-span-twin`). Both deliberate corruptions were
caught: first word immediately, last word after 747 successful comparisons
in a 748-word rectangle (`completion-e3-span-fault-{1,2}`).

The discarded source is retained as `completion-e3-span-candidate/candidate.patch`
against `7cfe314`; its host model remains. All retained-code builds, 521 host
tests, 81 hook ranges and 136 VERIFY patch destinations pass. No direct-to-chip
CPU raster option is shipped. The fast-memory back-buffer comparison and E4
remain open; the normal verified mask is still `0x71fff` and D5 is postponed.

### E4 publication — target missed; accepted for release

`publication_cadence.cadence` checked every deadline in the existing 2,000-field
E3 off captures (same developer binary, W6 selected, native blitter scene).
No new emulator round was needed. The scoreboard records the covered fields;
none of 030/040/060 publishes every field. On 060, publication gaps are three
fields 8 times, four fields 400 times, five fields 71 times and six fields
3 times. Leading and trailing deadlines are included in the failed verdict.
Reports: `completion-e3-fast-frame-{030,040,060}-off/publication-cadence.json`.

The source already forces beam-safe publication and a one-field minimum under
W6 (`perf.s`, `pacing.s`). The cap cannot make unfinished frames complete.
In the 060 capture, the scene averages 48.30 ms, cockpit 30.41 ms and publication
1.31 ms. E1's publication share was already below the plan's 10% threshold;
therefore the optional third buffer is dropped. No publication code change is
justified by this evidence.

The original every-field and FPS targets were not met. On 2026-10-12 the user
accepted measured performance and requested completion of release work.
Checkpoint E is closed on that basis, without a 50 FPS claim. The six-machine
normal-build refresh is complete at F3. D5 stays postponed; W6 is outside the normal mask.
The normal release selector is On=0 (default), Off=1; historical normal-build
captures before F1 used the opposite mapping. Developer/VERIFY masks are unchanged.

### E3 Fast-RAM scene — dropped

Drop under §0.3: all four same-build 2,000-field CPU-class pairs regress
(020 −44.09%, 030 −29.01%, 040 −27.29%, 060 −27.74%; scoreboard).
The native blitter scene remains in every build. No new RAM requirement or
player option remains from this candidate.

The discarded bit-19 backend redirected the planar scene at sim:2c552 through
unchanged geometry/clipping into Fast RAM, with CPU equivalents of the blitter
operations. It seeded the frame and scratch from chip and copied them back at
sim:2c800, using MOVEM on 020/030 and alignment-gated MOVE16 on 040/060.
It used the existing reserved workspace and left outside-scene blits native.

Its native pixel twin reached flight after 1,557 operations and 37,368,000
compared words without a mismatch. Per-launch counters cover rectangles,
lines, area fills and merges; this is primitive pixel evidence, not all-view
acceptance. Corruptions at bytes 0 and 47,999 were detected at longword offsets
0 and 47,996. Evidence: `completion-e3-fast-frame-twin-r3` and
`completion-e3-fast-frame-fault-{first,last}`. The actual C kernel's minterm,
fill, line, solid, merge and shifted masked-copy host models remain in
`tools/fast_blitter_model.c` and `tools/test_fast_blitter.py`.

Measurement developer SHA-256:
`0d0abc903b8bfd91671da408adfac0c331fe601ddfe86c8058b309982dc303f5`.
Evidence: `completion-e3-fast-frame-{020,030,040,060}-{off,on}`. A small
`completion-e3-fast-frame-candidate/candidate.patch` against `1926d53`
preserves the complete source, generator and native checker. The candidate
passed all three builds, 528 host tests, 117 hook ranges and 138 patch
locations before timing. After removal, all three retained builds, 528 host
tests, 81 hook ranges and 136 VERIFY patch destinations pass. The normal
verified mask remains `0x71fff`; no discarded E3 runtime ships.

### E2 memory gate — higher minimum approved

The first complete-composition attempt (`completion-e2-full-compose`) made no
pixel comparisons: all 109 completed native stage intervals fell back because
the gauge and foreground allocations failed. The gauge pool was then compacted
from 676,480 to 58,240 bytes, with a shared 48,000-byte expansion scratch.
A trial increased the declared fast pool from 704 KiB to 1 MiB, reserving the
additional 320 KiB unless bit 19 was selected on 020+. The normal A500 build
could not boot on 512 KiB chip + 1.5 MiB slow: the AmigaDOS screen repeatedly
reported “Can't allocate ExpMem.” This contradicts the approved minimum-memory
requirement, so the trial was stopped under completion-plan §1. On 2026-10-12
the user approved raising the minimum RAM requirement. The 1 MiB reservation
is reinstated; 512 KiB chip + 2 MiB fast is the new A500 validation configuration.
The existing A500 scoreboard row remains historical until refreshed. This is a memory failure,
not a new FPS result or a passed pixel twin. Evidence:
`completion-e2-memory-a500/{boot.png,slave.slave,memory-trial.patch}`;
trial normal SHA-256 `5a7ad2dfc6afe2271778dabadd6b81ec6f376490cd5e7862166caae07751424d`.

The amended minimum passes on that same normal binary: 68000, 512 KiB chip
and 2 MiB fast, CUSTOM2=1, maximum detail. Five native publication crossings
complete without the mission-exit breakpoint firing; the cockpit screenshot
shows normal flight. Evidence: `completion-e2-memory-a500-raised-flight`.
This is a boot/flight check, not an FPS window. All three builds, 511 host tests,
84 hook ranges and 139 VERIFY patch destinations pass. An earlier attempt
reached flight but used a timing driver whose 1,000-field minimum rejected the
short check; its host debugger then terminated the emulator during teardown.
The passing dedicated driver detached cleanly before quitting the emulator.

### E2 disposition — retain measured gauges; drop full composition

The persistent gauge cache is retained on **020 and 040 only**, with its
previously measured +2.19% / +3.00% gains, seven-gauge native pixel/state twin
and front/rear/left/right checks. It is now in the normal verified mask
`0x71fff`; CPU policy removes it elsewhere. W6 remains outside that mask.

The complete cockpit cache is **dropped under completion-plan §0.3**: every
2,000-field same-build CPU-class pair regresses (table above). The candidate
is preserved at commit `4451847`, developer SHA-256
`c98208522e70e12696b7089917adeaa9458bbca85ca229cc163da9f41eb9520f`.
Evidence: `completion-e2-complete-{020,030,040,060}-{off,on}`. All eight windows
use maximum detail, Time Scale 40 and W6. The 030 class was tested with MMU;
the no-MMU row shares that class result, not a separate full-cache measurement.
A500 was CPU-gated off. These are whole-window FPS, including cockpit events.

That candidate captured static/gauge/foreground layers, rebuilt changed bounds,
used a single final masked composition, reused six stable gauge dispatches and
materialized the cached static artwork before the remaining native gauge work.
It had no timing-build full-frame seed or fallback copy. Native ordering required
the static copy before gauges; the complete composition still cost more than
it saved. The last bounded native check passed 69/69 frames and six admitted
gauge reuse twins; altitude reuse was excluded. Those correctness results did
not establish performance and do not justify keeping the slower runtime.

The seven full-composition source modules, bit-19 option and integration hooks
are removed. Reusable host models remain; implementation history is in git.
The approved 1 MiB reservation and 512 KiB chip + 2 MiB fast tested minimum
remain. The former 320 KiB cockpit quota is reserved, not released to the game.
All three retained-code builds pass (normal/developer/VERIFY text sizes
119,680 / 120,020 / 305,824 bytes), with 515 host tests, 81 hook ranges and
136 VERIFY patch destinations. E2 is closed; E3 CPU rasterization is next.
The normal switch still defaults off until F1; nothing has been pushed.

### Historical D5 candidate checkpoint — superseded open list

The current D5 status and subsequent checks are at the top of this ledger.
The following retains the original measurements and user feedback.

The added candidate FPS and world-rate/drop columns use **developer bit 13**,
not the normal verified mask. Each window covers 2,000 PAL fields at maximum
World/Aircraft detail with Ground ON IN COMBAT, using the protected combat
fixture. These are whole-window publication rates, with no dashboard-event
filter; they are not directly comparable to checkpoint C's steady column.
Completed world units are divided by elapsed CIA ticks at the observed native
rate. Endpoint quantum rounding remains in the reported ratios.

The 020–060 Time Scale 40 cases meet ±1% with no dropped updates, on developer
SHA-256 `da9d08274619d59a60331023dde90de073c83901b1218ecff2ea56d5c9e09886`.
Evidence: `completion-d5-{020,030,030-nommu,040,060}-1`.
The A500 cases use the corrected first-flight reset build,
SHA-256 `1c582227647e156ff87638b526bb6992ec2d917423e8137bdd8cce22840ea5a7`:

- Ace, Time Scale 0: **0.948 FPS**, world ratio **1.009981**, no drops.
- Squadron, Time Scale 0: **0.549 FPS**, ratio **1.009128**, no drops.
- Ace, Time Scale 40: **0.824 FPS**, ratio **0.924744**, 12 dropped steps
  (5,400 units), as in the scoreboard.
- Squadron, Time Scale 40: **0.200 FPS**, ratio **0.943117**, 10 dropped
  steps (4,500 units).

Evidence: `completion-d5-a500-{ace0,squadron0,steady40,squadron40}`.
Time Scale 0 passes the rate gate in both measured scenes. Time Scale 40
hits the bounded-debt overload policy and misses the rate and FPS targets;
this is **not** accepted as successful consistent-speed operation there.
E2 still offers the planned cockpit-cost reduction, including a measured
68000 option. Time Scale 60 is unmeasured: the keyboard slider attempt did
not reach its asserted setting and was discarded before rate capture.

Hardware keyboard IRQ input reaches Preferences on all six configurations.
On the corrected A500 and 060 builds, one throttle-down/up tap during rendering changes
210 → 190 → 210, with no extra dispatch over 20 later world-input crossings
per command. This establishes taps, not held-input coverage. A 200-field
native Pause retains the world cursor and step count; Return translates the
cursor by the excluded modal interval and restores the selected quantum (450
on A500, 225 on 060).
Evidence: `completion-d5-a500-steady40/{input-commands,pause}.json` and
`completion-d5-060-input-soak/{input-commands,pause}.json`.
The same 060 flight completes 90,000 PAL fields (1,802.87 emulated seconds)
without mission exit or observed fault. The old response limit interrupted the
host after 60,283 fields; the remaining 29,717 continued from that point, with
no guest reset or input. This is one flight across two debugger reads, not
30 minutes of host time. Evidence: `completion-d5-060-input-soak/soak*.{log,json}`.
Held-input, Time Compress, catch-up mission exit, flight outcomes and user
handling acceptance remain open. Bit 13 remains outside the normal
verified mask.

User A500 handling feedback (2026-10-11, `feedback-a500-1`, real speed,
sound and original damage settings): taps and held controls were predictable,
with no stuck keys or other reported faults. The user described the frame rate
as abysmal and steering as very sensitive, producing large left/right turns.
Reducing World detail improved frame rate and made control easier. This is
qualitative evidence of functional input, **not** satisfactory maximum-detail
playability or a measured sensitivity defect. Do not infer a cause or change
the approved quantum from this report alone.

User 060 handling feedback (2026-10-11, `feedback-060-1`, maximum detail,
Time Scale 40, real speed, sound and original damage settings): steering was
great, controls released cleanly, and no problems were reported. This passes
the short 060 tap/hold/release handling check. Together with the A500 report,
it supports functional held controls on both machines, but does not establish
per-catch-up-tick delivery, flight-outcome smoke tests or full D5 acceptance.
The A500 maximum-detail playability problem remains open. The user then
completed a deliberate 060 crash and confirmed that the crash sequence and
return to debrief worked correctly, with no reported fault. This passes the
060 crash smoke test; landing and AI shoot-down checks remain open on both
machines, as does the A500 crash check.

For a live D5 flight, `python3 R/RedBaron/tools/completion_soak.py <capture>`
counts 90,000 PAL fields in bounded 10,000-field debugger reads, with no guest
reset or input between them. Each segment requires the native VBL stop and
rejects mission exit or faults. The host suite passes 443 tests, including
three deliberate malformed-soak cases. This fixes the single-response harness
limit; it does not alter the slave.

### E1: W6 render-stage diagnostic

The E1 column records one complete 250-PAL-field diagnostic on each of 040/25
and 060/50, developer mask `0x32ffa`, maximum detail and Time Scale 40. Both
use SHA-256 `1c582227647e156ff87638b526bb6992ec2d917423e8137bdd8cce22840ea5a7`.
These are inclusive wall-time spans, with the existing phase-safe filter;
the stages are not CPU-only or blitter-only costs. They are **not** 2,000-field
A/B FPS comparisons and do not replace the existing FPS scoreboard columns.
The 040 window follows tooling recovery and is later in its flight than the
060 window; different scene costs are not evidence of relative CPU speed.

Cockpit dispatch `sim:19ba6–19e12` averages 10.64 ms on 040 and 9.33 ms on 060;
instrument scripts `sim:15e96–163a0` average 14.30 and 13.63 ms. The nested 3D
pass `sim:2c552–2c806` averages 29.20 and 38.48 ms; world updates average 2.53
and 2.04 ms. Do not add nested spans to their parent costs. Both whole scene
and cockpit stages exceed a 20 ms frame on both CPUs, supporting E2 followed
by E3. These timings alone do not prove chip-bus saturation or the line
primitive's share. Publication is substantially smaller; there is no evidence
here requiring a third buffer.

Evidence: `completion-e1-040/diagnostic.{log,json}` and
`completion-e1-060/opening.{log,json}`. Both have 250 consecutive field samples.
The discarded 040 `opening.log` failed before field recording (too many
breakpoints); `stages.log` was interrupted by a debugger protocol error at
field 211. Neither is used as a result. The corrected collector explicitly
stops before commands and limits E1 to 16 breakpoints. No binary instruction
trace was captured. Reproduce with local `completion_e1_case.py <040|060>
0x32ffa <fresh-output>` under `BENCH_DEVELOPER=1 BENCH_BATCH_KEYS=1`.

E2's gun-overlay cache (programs 3/4) is **dropped**: all four CPU-class
2,000-field same-build pairs miss 2% (020 −2.73%, 030 0.00%, 040 −0.86%,
060 −0.62%). Evidence `completion-e2-fast-{020,030,040,060}-{off,on}`,
developer SHA-256 `4f8434e6cec01ce0294365276b98ca3f5b6bbdcb313d19ccbe17103aca01720b`. The earlier byte-guard/chip-blit
variant also regressed on 060 (−7.45%). Neither variant entered the normal
verified mask. Disposable completed-case bank scans were removed; frozen slaves,
listings, timing logs, results and screenshots remain.

E2's solid front-script cache is **dropped**: all four 2,000-field same-build CPU-class pairs miss 2% (020 −5.43%, 030 +0.20%, 040 −0.64%, 060 −0.21%). Evidence `completion-e2-solid-{020,030,040,060}-{off,on}`, developer SHA-256 `a3f1077723812ee803a4f617d5646c7ab0793a5b33bbd592141d7f4cf2f85e63`.

Its native front-view twin passed 40,000 pixel bytes and 24 drawing-state bytes
with 166 hits, one fill and no fallbacks (`completion-e2-solid-twin`, VERIFY
SHA-256 `b610d83c52e8591d3472cfaf4ef894f09727b2973bc1273476d8a057f4daa6cd`).
Correctness did not translate to an FPS gain. The program-2 runtime hook and
bit-18 option are removed; reusable coverage/composition helpers return to
VERIFY-only builds. Neither discarded cache entered the normal verified mask.
After removal, all three builds, 463 host tests, the 79-range hook audit and
134-destination VERIFY patch-reach audit pass.
The instrument/dispatcher cache, combined composition and other-view/map twins
remain open; these two partial front-script attempts do not complete E2.


The E2 bit-18 persistent-gauge cache is CPU-gated to 020 and 040 after measurement.
Its 14 gauge/page records occupy 31,640 bytes of fast RAM. Reuse requires an
identical raw value/context key, a stable native rectangle and an exact bounded
pixel guard; selective state replay preserves the other gauges' scratch fields.
Forced redraws, extended clips and unsupported geometry retain native drawing.
All three builds, 484 host tests, 81 hook ranges and 136 VERIFY patch destinations
pass. The seven-gauge native twin passes 40,000 pixels and 40 drawing-state bytes
per case, with 986 cache reuses and 200 fills, no mismatches and released twin
scratch. Six gauges use natural hits; altitude uses one VERIFY-only same-input
repeat after a stable native rectangle, because its raw value changes each frame.
The checker rejects three sabotages and unreleased scratch. Evidence
`completion-e2-gauge-twin-r4`, VERIFY SHA-256
`66847823e18558d1c5998de65f9caa376df8535805b9071d10ad6b7b656e5e1b`.
The earlier attempts lacked a usable fast-RAM snapshot or altitude-hit coverage;
neither is accepted as the seven-gauge result. The temporary VERIFY snapshot now
allows any RAM; the runtime cache still requires fast RAM. The completed
2,000-field A/B pairs gain 2.19% on 020, 3.00% on 040, 1.45% on 060 and
0.00% on 030. The shared selection/installer policy therefore permits only
020/040, rejecting the higher compatibility flags first. Evidence
`completion-e2-gauge-{020,030,040,060}-{off,on}`, same developer SHA-256
`399ff9d384c2de9d5f1f91ba3182bee751726b4478006a7d2af6e3ce3357cdec`.
This is the dispatcher portion of E2, not combined cockpit composition or the
remaining view/map acceptance. Bit 18 remains outside the normal verified mask
until that E2 acceptance is complete. The A500 stays gated off; the no-MMU 030
uses the measured 030-class decision.


The combined front-script cache is dropped: all four 2,000-field CPU-class
pairs miss 2% (020 −4.92%, 030 +0.41%, 040 +1.50%, 060 +0.41%). Evidence
`completion-e2-combined-{020,030,040,060}-{off,on}`, one developer SHA-256
`3a2741158498c18b707e1897faa59adb588d2713a60e13a7d7fb5fc2b39e0a7a`.
Its bit-19 runtime and option are removed; it never entered the normal mask.
The bounded native front twin had passed 40,000 pixel and 24 drawing-state bytes
for the combined 2/3/4 sequence, with 171 hits, one fill and zero fallback calls;
scratch was released (`completion-e2-combined-twin-r2`). Correctness did not
produce a retained performance gain. The first allocation-failed attempt is
not accepted evidence. The retained pack model covers full-frame capacity and
background independence. The separate static-overlay/gauge integration and
view/map acceptance are still open; dropping this partial script sequence
neither closes E2 nor establishes a bound for full cockpit composition.
After removal, all three builds, 495 host tests, 81 hook ranges and 136 VERIFY
patch destinations pass.


The retained gauge cache's view check passes on 040 in
`completion-e2-gauge-views`, VERIFY SHA-256
`3822b0bbf52c148cb7a121ce7ade4bdd81ffebd5afda5de3914f951cd1e88c22`.
The front native twin passes all seven gauges (40,000 pixel bytes and 40
state bytes per case, 968 hits and 198 fills). Native F2/F3/F4/F1 hardware
keyboard events then select rear/left/right/front. Each view completes five
publications at `sim:3154a`; gauge entries at `sim:19d22` are respectively
0/0/0/35, matching the original non-front early exit at `sim:19c12`.
This proves gauge-patch bypass and return, not full-composition pixel twins.
The original front window also has 35 gauge entries. The three checker
sabotages reject a wrong view, unexpected non-front patch activity and missing
publications. The old guest-memory input attempt did not enqueue a key and is
not accepted transition evidence; the completed sequence uses native CIA IRQ
input via the owned emulator's host debugger. `completion_host_input.py
--serve --irq-only` supports this without a live boot-module RAM mapping.
Map-toggle acceptance is dropped: the bundled Manual describes five offline
navigation maps, and Keys has no in-flight map command. The campaign transfer
map is outside the patched flight renderer. Full cockpit composition and its
view twins remain open; bit 18 is still outside the normal verified mask.


The full-composition transport's first bounded 040 integration run completes
ten publication crossings. At the final stop its lifetime counters are 114
entries / 114 exits, active redirection is zero, and the native framebuffer
aliases are outside its private chip allocation. The screenshot retains the
cockpit and the native message. Evidence `completion-e2-cockpit-stage`, VERIFY
SHA-256 `b3cd1e9906722b8686c300bb31c09e1e2c8fafef62c1372663b628ebf56e4fad`. This is not a
pixel twin or FPS result. Publication has already switched one framebuffer
alias, so equality of both aliases at that breakpoint is not a valid check;
neither may retain the private target. After this run, source adds the static
base-layer capture and lifetime invalidation. That newer capture path has host
model coverage, not native acceptance yet. All three updated builds, 505 host
tests, 83 hook ranges and 138 VERIFY patch destinations pass. Development bit
19 remains excluded from the normal mask. Its temporary full-frame transport
copies must be replaced by dirty-layer updates and one masked composition
before any performance measurement; the normal-bundle scoreboard is unchanged.


040/060 functional checks use separate MMU-core configurations. Their timing
results will use the frequency-sensitive NOMMU cores. Configuration generation
passes all six cases and the functional variants. All three builds pass; the
A2 checkpoint passes 427 host tests and the 76-range hook audit. The normal-build matrix uses
native keyboard queues through the host debugger. The input driver writes only
keys, never simulation or executable state. Maximum World/Aircraft detail and
Ground ON IN COMBAT are selected; Time Scale stays at 40. A separate benchmark
copy has aircraft damage disabled in its native realism preferences, preventing
an early combat death from truncating a window; original game files are unchanged.

Combat can produce spontaneous dashboard events. Therefore the steady value is
**event-free complete-frame cadence**, calculated from consecutive publications
inside the same ≥2,000-field event capture. Any interval touching the field of a
DASH event is excluded conservatively, as are ambiguous beam-counter samples.
The event value is the FPS of the entire window, including the queued cockpit
view change. This is not a claim that the whole capture is event-free. The
initial 1,000/2,000-field opening window is retained as setup evidence only.
`completion_cadence.py` reports the clean interval count and covered fields;
`routine_wall_time.py` reports phase-safe inclusive stage spans. No VERIFY
measurement substitutes for a normal-build result.

All twelve A2 cases are complete, on the same normal slave SHA-256
`5256542f87ec1c6d3eca174416560597a60e76e1cc785cd0fbf5e3efff3f0ba8`.
Stage columns show stock → bundle means from the event window. DASH counts
are marker hits, not distinct redraw counts: a redraw may reach several markers.
Combat activity differs between windows, and before W6 frame rate also affects
world progression. These are observed whole-game rates, not isolated-routine
speedup estimates. Differences below 2% are unresolved. A2 does not claim consistent simulation speed; the separate D5 candidate
columns record the current rate/debt evidence.

Reproduction from the prepared local harness: use `completion_matrix_case.py`
with machine (`a500`, `020`, `030`, `030-nommu`, `040`, `060`), option (`0` or
`1`), and a fresh output directory. It builds normal mode, applies the maximum
detail keyboard route, records an opening window and a 2,000-field cockpit
view-change window, then detaches its debugger and quits its owned emulator.
Run one case at a time. The 040/060 use Zorro-III RAM because Zorro-II is limited
to 8 MB; scan the emulator's actual mapped bank, not just its requested address.
The retained case includes `entry.json`, `event.log`, `event.json`, frozen slave
and listing; later cases also retain the final screen and emulator configuration.
The benchmark realism file has SHA-256
`659d36ca563ba4622daabb36a71dafaf6060cdcbf89bb12e75426198496d272c`.

Recalculate steady cadence without another capture:

```sh
python3 R/RedBaron/tools/completion_cadence.py <capture>/event.log --fields 2000
```

### B1: larger game memory pool

The added B1 column is an isolated **developer-build** comparison: the existing
CPU-specific bundle stays selected and only bit 16 changes. It uses one
2,000-field opening window per option, with the same event-free interval filter.
The normal-build A2 columns remain the baseline until checkpoint B. The 020 pair
uses SHA-256 `c2877a4a…0496ff4`. Its complete opening logs are retained; an extra
view-change reader timed out after the emulator reached 2,000 fields, so that
unrecorded secondary window is not a result. Remaining B1 cases collect only the
required opening window. The local reader now allows the debugger's full timeout.

The private allocation census recorded 4,755 AllocMem/FreeMem operations through
flight step eight, without overflow or reused-live-address errors. Peak live
spill was 181,568 bytes; 127,312 requested bytes remained live in flight. The live
MEMF_ANY spill comes from the generic allocator returning at `sim:2d222` and
bitmap descriptors returning at `sim:30296`. A 100-field trace touches none of
those live blocks through DMA. Reconstructed enabled blitter pointers also have
no overlap; 40 initial pointer states precede a complete observed register pair,
so the actual DMA address records supply the coverage there.

The implementation increases the declared game pool from 512 to 704 KB, covering
that peak plus 15,040 bytes of headroom. An initial compatibility reservation
keeps the old game budget until bit 16 is selected on sim v1 and a supported CPU.
The minimum A500 configuration boots and flies with this final gate. Original
MEMF_CHIP requests remain unchanged. The post-change census records 4,756
operations and zero live spill in flight. The preflight temporary peak remains
181,568 bytes because the extra pool is released only after sim v1 is identified.
All four isolated CPU comparisons are complete on the same developer binary.
Whole-window FPS rises 6.390 → 6.639 (020), 12.705 → 14.377 (030),
12.255 → 13.404 (040), and 12.405 → 13.753 (060). The final A500 normal
bundle also completes its 2,000-field event window at 2.072 FPS.
The larger diagnostic build exposed a signed patch-offset overflow in the
VERIFY keyboard hooks; nearby branch bridges fix it, and the corrected build
reaches flight and completes the census. All three standard builds, 431 host tests and the
76-range hook audit pass.

Reproduce the allocation reader with `allocation_census.py <header> <records>`.
The private build adds `VERIFY_ALLOC_LOG=1` alongside `VERIFY`; its bounded
observer restores the Exec vectors at flight step eight. The reader rejects
active, overflowing and truncated logs. The initial 1,024-entry attempt overflowed
and was discarded; the completed census uses 8,192 entries.

### B2: instruction-cache policy

The instruction cache was disabled on the 020 and the 030 without the MMU
option. KickEmu requested noncacheable BaseMem, which disables caches globally
when WHDLoad cannot apply separate region policies. Bit 17 now reads CACR on
020+ and, only when IC is off, uses `resload_SetCPU` to enable it. When DC was
off, it explicitly stays off; when DC was on, the memory policy is retained.
Already-enabled IC and 68000 configurations require no change. WHDLoad's
NoCache override is respected.

The scoreboard includes flight-entry CACR on all applicable configurations.
The 68000 has no CACR. Its full VERIFY build exceeds minimum-memory capacity;
the normal-build minimum-memory flight remains the applicable player check.
The existing VERIFY paint observer supplies these readings; its one-time
cache flush is not part of the uninstrumented FPS comparisons.

Both affected configurations pass a same-developer-build, 2,000-field opening
pair, changing only bit 17 with the B1 pool and other CPU-specific bits fixed.
The common binary SHA-256 is
`f6db162e8b41fff3a752854224c37526b066ef8024b07c53995cd46268825b1e`.
Clean-frame gains are recorded in the scoreboard; whole-window FPS rises
6.664 → 7.338 on 020 and 13.404 → 14.377 on 030 without MMU.
The 030 with MMU and both later CPUs already have IC enabled, so no redundant
cache-policy change or isolated timing pair is needed there. All three builds,
431 host tests, the 76-range hook audit and patch-destination reach checks pass.
The normal bundle now includes bit 17; the six-machine checkpoint B is complete.
It captures the 2,000-field cockpit-view-change window directly after the initial
flight warm-up, omitting A2's preceding 1,000/2,000-field opening capture. Thus
its event-free cadence describes an earlier flight scene. Cross-checkpoint
rate differences are not isolated speedup estimates; the matched B1/B2 pairs
above supply those claims. The checkpoint binary SHA-256 is
`3b38a60175741b20cc6ae3130d95aa20e9db7e1fb91f1e520f4a1861d8c93e9d`.
The 030 MMU/no-MMU clean rates differ by −0.55% and whole-window rates by
−0.17%, both unresolved under the 2% rule. MMU enables fast-memory data caching
while retaining noncacheable ChipMem; the ReadMe describes that capability
without claiming a measured FPS gain in this window.

C1 dropped under §0.3: all five same-build, 2,000-field CPU-class pairs are below 2%; the 000 and BFFFO candidates passed 40,960 native comparisons, but the player keeps the original routine (candidate SHA-256 `93f22148fd4d0ef24b5a6004be799ec0edfc151bdad274e1f8bde3c20a52fc88`).

## Earlier measurements

A warmed accelerated-emulation frame-time check places the main cost in
rendering, not the publication cap: the native draw averages **3.87 fields**,
with scene spans **2.05–2.14 fields**, cockpit **1.44–1.52**, and publication
**0.21–0.36** across two separate 250-field windows. These are inclusive
wall-time samples with different phase-filtered populations; nested spans
must not be added. See “Accelerated frame-time breakdown” in
`w6-verification.md`. Scene and cockpit work remain targets for the 50-FPS gate.

An accelerated-emulation cached-68030 probe completes **163 world updates**
in 1,000 PAL fields with exact funding and outstanding work below 1.685
updates, but publishes only **243 frames (12.15 FPS)**. Its three-to-five-field
cadence fails the one-field requirement, including later event-free windows.
This is not a physical CPU benchmark or a 50-FPS success. See “Accelerated-
emulation cadence and capacity probe” in `w6-verification.md`.

The second private matrix candidate now saves **2.13% of routine main-task
cycles** in 2,021 matched A500 pairs after removing nested lookup calls.
All 2,048 native output/register/flag twins pass. It is still unhooked and
excluded from ordinary builds: this small constructor result does not resolve
the A500 squadron capacity failure or establish a game FPS improvement.
See “Inlined private matrix candidate” in `w6-verification.md`.

The sound-phase audit now observes a native main-task request followed by
CIA-interrupt playback start in the same recorded PAL field. Across the two
retained A500 traces, playback status reads/tests occur on the IRQ stack.
See “Sound phase access and CIA delivery census” in `w6-verification.md`.
Matched sound request/delivery equivalence remains open; sound is unchanged.

The W6 message-consumer census now covers 87 complete world calls and 93
service calls in retained A500 steady/replay traces. None touches the differing
redraw flag; the world does consume the message timer to update priority.
See “Message descriptor consumer census” in `w6-verification.md`. The strict
render/no-render comparison remains failing pending indirect/bulk-copy and
message lifecycle coverage; this is correctness evidence, not a speed result.

A fresh ordinary-W6 **68EC020 squadron run** completes **162 updates** from
163.288 newly funded over 1,000 PAL fields, publishing **47 frames (2.35 FPS)**.
After the opening message burst, endpoint outstanding work decreases from
4.098 to 1.564 updates; its sampled maximum is 4.512. The longest completion
gap is 22 fields (440 ms). See “68020 squadron capacity after the A500 failure”
in `w6-verification.md`. This supports finite catch-up capacity in this CPU/RAM
configuration, not a declared minimum machine or complete gameplay acceptance.

**The first matrix-reuse assembly candidate is rejected for A500 use.** In a
250-recorded-field native twin trace, 2,022 matched original/candidate pairs
cost **5,939,058 versus 6,029,602 main-task cycles**: the candidate is **1.52%
slower**. Every input case's aggregate regresses. It remains available only
under `VERIFY_MATRIX_EXPERIMENT`; ordinary VERIFY again has the pre-experiment
`ac1d47ba…` hash. See “Matrix candidate timing rejection” in
`w6-verification.md`. Correct output and fewer table reads were insufficient.

A **private VERIFY assembly matrix candidate** now passes **2,048 native A500
twins**: all D0–D7/A0–A6 values, XNZVC and the 20-byte output buffer match the
original. The candidate reuses three fixed expressions and has **no installed
game hook**. Normal/developer hashes remain unchanged. See “Private native
matrix candidate” in `w6-verification.md`. Timing, other CPUs, alias handling
and the W6 capacity deficit remain open.

An integer model of `sim:3648c` now matches **all 19 output bytes in 400
complete native matrix calls** from the squadron trace. Reusing identical
word-valued expressions reduces modeled table reads from **6,800 to 4,843**
without changing those outputs. See “Exact orientation-matrix model” in
`w6-verification.md`. This is output evidence and an algorithm candidate;
no assembly replacement, cycle saving or FPS improvement is claimed.

The squadron bottleneck resolves further into the native physics core:
`sim:1a852` → `sim:17f84` accounts for **90.38%** of 228 complete
`sim:1a60c` calls. Within 199 complete full-physics calls at `sim:18470`,
two orientation-matrix builds take **16.15%**, while **20.29%** is inline
work outside immediate callees. See “Native physics-core cost breakdown”
in `w6-verification.md`. This rules out treating the outer dispatcher alone
as the optimization; arithmetic, matrix construction and inline physics work
need exact treatment. No performance improvement is claimed.

The failed A500 squadron profile now has a call-level breakdown. In 27 complete
world updates, the `sim:10c8` call into `sim:1314` consumes **84.63%** of
main-task world cycles. Its object-update driver spends **58.95%** of its own
cycles calling `sim:8fce`. A separate population of 228 complete aircraft
calls traces the largest path through `sim:193ee` to **`sim:1a60c`**. See
“Squadron world-call partition” in `w6-verification.md`. These nested costs
identify the next investigation target; they are not additive savings or a
measured optimization gain.

**W6 fails the A500 squadron capacity gate.** A fresh four-versus-four fixture
completes only **99 of 163.288 funded updates in 1,000 PAL fields**, while
publishing **zero frames**. Outstanding work increases in every 250-field
window, reaching **64.288 updates**. A following 250-field instruction profile
finds 27 complete native world calls averaging **880,073 main-task cycles**
(**1,068,517 including interrupts**). Rendering optimization alone cannot fix
this observed overload. See “A500 squadron overload and world-cost evidence”
in `w6-verification.md`; world-loop capacity work is now a W6 prerequisite for
supporting this machine/scene at Time Scale 40.

A fresh current-build cached-68030 event/replay run covers four consecutive
250-field windows (20 PAL seconds). It completes **162 world updates** from
**163.288350168 funded**, publishes **204 frames (10.2 FPS)**, and keeps total
outstanding credit below **1.823704 updates**. Endpoint credit oscillates rather
than growing throughout the run; the final 1.288350 includes one update in
progress. Native self-tests, patch isolation, scheduled inputs and exact funding
pass. See “Current-build sustained 68030 event capacity” in `w6-verification.md`.
This establishes finite capacity evidence for this scenario, not the minimum
CPU envelope, complete gameplay equivalence or 50 FPS.

All tracked heap differences in the current render/no-render state pair now
have explicit owners: native message-background bitmaps or sound slots. The
1,800/1,600-byte bitmap payloads match the native size calculation and exact
cache-slot ownership at all 41 checkpoints. See “Native message-background
cache ownership” in `w6-verification.md`. Differences are retained; this is
not a consumer-isolation, sound-equivalence or gameplay-speed verdict.

Fresh current-build render/no-render captures start with identical game
segments and all 105 tracked allocations. At 41 retained checkpoints, complete
aircraft, projectile, auxiliary, weapon, planning, model-bank and sky checks
pass despite 39 versus zero draws. Strict message/sound checks still fail on
the redraw flag and one sound status bit; raw rendering caches and extra
allocations remain recorded. See “Current-build equal-tick render/no-render
state pair” in `w6-verification.md`. This is substantial scoped state evidence,
not a whole-gameplay or release verdict.

A paired current-build 68030 check now compares **8.4 FPS versus no rendering**
over equal 250-field / 296-CIA-tick windows. Both complete **40 world updates**
and retain exactly **0.822087542 updates of credit**, with nine message-start
and nine shortening calls each. Same configuration/build and exact funding
checks pass. See “Paired rendering/no-render time accounting” in
`w6-verification.md`. This supports timing independence in this short scenario,
not full state equality or sustained/all-scene acceptance.

A fresh current-build 50-MHz cached-68030 replay/event window covers exactly
250 PAL fields: **40 world updates**, **40.822 newly funded**, **42 publications
(8.4 FPS)**, and nine message-start plus nine shortening calls. Total
uncompleted credit ends at 0.822 updates (including fractional credit), with
a sampled maximum of 1.824; no completion gap exceeds nine fields. Exact
funding, scheduled inputs and selected/disabled byte audits pass. See
“Current 68030 replay/event speed window” in `w6-verification.md`. This is a
five-second capacity observation, not sustained acceptance or smooth 50 FPS.

Native control-flow analysis proves that every local path to the conditional
stack-scratch read passes its fresh frame-local assignment first. This covers
95 reachable instructions, with ten subroutine calls explicitly outside the
proof. See “Stack-scratch local control-flow proof” in `w6-verification.md`.
This does not close callee/reentrancy or live read-path coverage.

The remaining lookup-context pointer resolves to the exact native 32-byte
identity table at all 41 controlled checkpoints. A complete-range replay
trace sees assignments, but no reads, of the remaining stack-scratch pointer
in its 45 world calls. A native read path exists and remains uncovered. See
“Lookup context and stack-scratch references” in `w6-verification.md`.

A full-range trace search finds no compact-pool/count reference candidates in
87 complete world updates and 93 service polls across retained steady and
Right/Fire replay windows. This supports isolation in those measured paths;
the observed compact-state mismatch is retained. See “Compact pool consumer
census” in `w6-verification.md`. No runtime or performance change.

Explicit native inline-object identities resolve the shared display list’s
active order: it matches at all 41 controlled checkpoints. Full storage does
not: seven checkpoints differ in inactive slots, and boundary 21 differs in
112 compact-record bytes plus the compact count (19 versus 18). See “Shared
display list owners and remaining compact state” in `w6-verification.md`.
These differences remain unresolved; no gameplay-speed acceptance claim.

All 500 dynamic registry slots, including the unused tail, now match under
explicit object identities at all 41 controlled 50/25-MHz checkpoints. The
registry takes 27 distinct states; raw differences remain recorded. See
“Complete dynamic registry storage” in `w6-verification.md`. The separate
shared display list and broader gameplay-speed acceptance remain open.

The complete message descriptor and referenced static text now match at all
41 controlled 50/25-MHz checkpoints, including “You’re being shot at!” and
“You’ve been hit!” transitions. Exact deferred message-hook installation is
checked. See “Complete message descriptor and static text” in
`w6-verification.md`. This is state evidence, not gameplay-speed acceptance.

Selected ammunition ownership and all ten projectile-linked records now match
at all 41 controlled 50/25-MHz checkpoints. The proof includes complete
aircraft/ammunition and projectile-pool prerequisites; only native pointer
fields receive explicit owner bindings. See “Selected ammunition and
projectile-linked records” in `w6-verification.md`. No runtime change or
whole-gameplay-speed acceptance claim.

The complete 16/12-byte auxiliary lists now match raw at all 41 controlled
50/25-MHz checkpoints, including owner pointers, inactive slots, record tails
and six control bytes. Both lists change during the window. See “Complete
auxiliary list records” in `w6-verification.md`. Recursive owner-state and
real-time gameplay-speed acceptance remain open; no runtime change.

The sun/star subsystem now matches completely at all 41 controlled 50/25-MHz
checkpoints: 33 records, phase storage, descriptor fields and selected-context
ownership. This accounts for two more simulation-consumed global roots,
including changing record state. See “Complete sun/star state and
selected-context ownership” in `w6-verification.md`. Broader gameplay-state,
real-time speed and 50-FPS acceptance remain open; no runtime change.

The complete triangular pairwise simulation table now matches at all 41
controlled 50/25-MHz checkpoints, including changing values, row ownership
and object identities. A trace-driven search identifies 78 remaining differing
global byte positions referenced by world updates; the service-poll residual
reference resolves to this validated table root. See “Referenced global
residuals and complete pairwise table” in `w6-verification.md`. Broader state
and real-time-speed acceptance remain open; no runtime or performance change.

A native A500 instruction census finds no vertex-cache reference candidates
in 87 complete world updates and 93 clock/service polls across steady flight
and a scheduled Right/Fire replay. This supports isolation in the measured
paths; snapshot-code and scenario limits remain explicit. See “World and
service reference census for the vertex caches” in `w6-verification.md`.
No cache differences are excluded and no gameplay-speed acceptance is claimed.

The equal-tick global audit now identifies 2,176 of 2,938 residual differing
byte positions as the native per-shape vertex caches. Active rows also differ;
these bytes remain in the comparison until gameplay-consumer ownership is
proven. See “Native vertex-cache extent and state inventory” in
`w6-verification.md`. This is correctness-investigation progress, with no
runtime change or performance result.

The VERIFY W6 exponent replacement now passes 20,480 native condition-code
cases on both A500 and 68030, and 1,148 complete A500 calls against its exact
register model. Including
the installed jump, calls measure **292–382 main-task cycles (mean 337.3)**;
the earlier original window measured 762–1,006 (mean 893.3). These are helper
cost observations, not a whole-game FPS gain. See “Bounded exact exponent
encoding under W6” in `w6-verification.md`. Gameplay-speed independence,
sustained capacity/latency and smooth 50 FPS remain open acceptance gates.

A current 250-field A500 profile identifies two concrete render-cost targets:
`sim:2c31c` costs 513,040 main-task cycles and `sim:398aa` costs 405,114 inside
one complete 5,263,418-cycle render (**17.4% combined**). The same render's
3D pass costs 2,212,788 cycles. See “Current A500 render cost and next targets”
in `w6-verification.md`. These are single-window cost observations, not an
optimization result or a general claim that 3D maths dominate drawing.

An A500 census starting at W6's first world boundary now covers the scheduled
Right/Fire replay. All four transitions and two commands are applied exactly,
but deadline-to-world-input dispatch takes **58/47/40/32 CIA ticks**; scheduler
lateness accounts for 53/45/34/29 ticks. Over 1,000 fields it completes 157
updates against 163.288 funded, publishes eight frames (**0.4 FPS**) and ends
with 6.426 updates outstanding. The longest completion gap is **1.12 seconds**.
See “A500 scheduled-input dispatch delay” in `w6-verification.md`. These are
scheduled-input delays, not physical-key or visible-response latency. No
message/shorten event occurred, so this does not close cockpit-event coverage.

The current A500 default-Time-Scale census completes **168 world updates**
against **163.288 newly funded** over 1,000 PAL fields, publishing seven frames
(**0.35 FPS**). Total backlog falls from 9.343 to 4.632 updates; its sampled
range is 0.749–9.895. The longest gap without a completed update is 48 fields
(**0.96 seconds**). No message/shorten event occurs inside this window. See
“Current-build A500 capacity window” in `w6-verification.md`. This demonstrates
repayment of initial debt in this scene, not universal capacity or smooth
simulation delivery; event/bank/dense and latency gates remain open.

The complete native shape-bank table and all seven loaded model allocations
now match raw across 41 controlled 50/25-MHz checkpoints: 216 table bytes and
85,876 resource bytes containing 174 shapes. Native constructor/list contracts,
allocation extents and terminators pass. See “Complete shared model banks across
CPU frequencies” in `w6-verification.md`. This adds shared-resource correctness
evidence; complete gameplay independence and the capacity/50-FPS gates remain open.

The controlled 50/25-MHz state comparison now binds 539 unchanged h3 loader
relocations across all 41 checkpoints, explaining 623 raw differing bytes per
checkpoint. Mutable fields remain unfiltered: 210–1,873 residual bytes at a
checkpoint, with 2,938 distinct residual offsets over the window. See “Global
loader relocation inventory” in `w6-verification.md`. This is state-audit
progress, not gameplay-independence acceptance or a performance result.

The private overlay invalidation/refill fixture now passes on A500 and 68030:
both poisoned cache entries are rebuilt in their existing allocations, with
complete pixel/state checks and cleanup. These are synthetic private
invalidations, not actual resource free/reload coverage. Normal/developer builds
remain byte-identical to W5. See “Private cache refill after invalidation” in
`w6-verification.md`; no speed or W6 acceptance claim follows from this test.

VERIFY bit 14 now installs seven resource-lifetime invalidation hooks for the
private overlay cache. Both A500 and 68030 pass 32 native condition-code cases
and four complete overlay twins each; normal/developer binaries remain W5.
No actual lifecycle operation occurred in these early-flight samples, so live
free/reload/failure coverage is still required. See “Native private-cache
lifetime invalidation hooks” in `w6-verification.md`. Native drawing remains
in use and no speedup is claimed.

The overlay lifetime audit found stale derived program selectors after owner
release and a stale bitmap registry slot on a loader-failure path. An ordered
byte guard alone cannot safely certify these resources. The verification ledger
now records the checked native paths, candidate pre-operation invalidation
entries and required failure/reuse tests. No runtime cache or new performance
claim is introduced; see “Overlay resource lifetime: stale selectors and failure
cleanup” in `w6-verification.md`.

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

| Configuration | Flight intervals | PAL fields | Observed swaps | Mean display rate | E2 solid-cache FPS off → on (dropped) | E3 Fast-RAM scene FPS off → on (dropped) | E4 field deadlines covered / 2,000 (W6 candidate) |
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
| A500, mirrored | 1,940,090 (1) | 715,830 (2) | 31,845 (3) | — | CPU-gated off | CPU-gated off | CPU-gated off | Not evaluated for E4 |
| A500, ordinary | 1,930,434 (1) | 703,760 (2) | 10,713 (3) | — | CPU-gated off | CPU-gated off | CPU-gated off | Not evaluated for E4 |
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
| A500, 1–358 | 9,705 / 1.8363 | 9,536 / 1.8689 | 9,457 / 1.8845 | — | CPU-gated off | CPU-gated off | CPU-gated off | Not evaluated for E4 |
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
