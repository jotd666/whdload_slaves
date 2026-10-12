# W6 consistent-speed candidate: acceptance postponed

The normal release enables its verified CPU-specific bundle by default. Its
player selector is On=0, Off=1; developer/VERIFY values below remain bit masks.
Only sim v1 receives performance patches. Current measurements and final release
checks live in [profiling.md](profiling.md), the single results record.
The full pre-condensation ledger is preserved at commit `dd9e8b4`.

## Current status

D1–D4 are implemented; the user postponed D5 on 2026-10-11. Developer bit 13
selects the candidate. It is deliberately absent from the normal verified mask.
Accepting current rendering performance on 2026-10-12 did not resume D5 or
approve this candidate for players. [game-time-plan.md](game-time-plan.md)
retains the design; the completion plan supersedes its obsolete acceptance work.

The candidate uses quantum 450 on 68000 and 225 on 020+, with interpolation only
on 020+. CIA time funds bounded catch-up debt; overload is counted and capped
at approximately one nominal second. Input, modal rebasing and presentation
remain distinct from world updates. All instruments, sabotage fixtures and
observers are VERIFY-only; the common runtime compiles in all modes.

## Accepted evidence and its limits

- The clock models, both quantum tables, stock dt=450 helper twins and deliberate
  checker failures pass. The 68000 bypass check confirms no pose capture/blend
  while retaining drawing. These are kernel/helper checks, not full gameplay proof.
- D5 rate windows cover all six configured machines. A500 passes its Time Scale 0
  sample but drops time at maximum-detail 40; 020–060 pass their sampled 40 windows.
  The scoreboard is the sole numerical rate/capacity record.
- A500/060 throttle taps and pause/rebase passed. The user found A500 steering
  predictable but maximum-detail control difficult, and 060 steering/release good.
  The 060 crash smoke test and one-flight emulated soak passed.
- Remaining catch-up input, Time Compress/mission-exit transitions, A500 Time
  Scale 60 and landing/combat outcomes were not completed. No rate sample
  substitutes for those gates or for the user's handling observations.
- E4's real 030/040/060 captures do not meet every-field cadence. The user
  accepted measured rendering performance; no 50 FPS claim remains in the release.

Cross-CPU full-state convergence and further byte-equivalence studies are not
current acceptance requirements. Rejected orientation/matrix/overlay candidates
remain historical experiments, not enabled runtime. The earlier exhaustive
ledger, raw addresses and abandoned investigations remain in Git history.

## Native reproduction after D5 is resumed

Use the current six-machine definitions and a fresh output directory. From the
development directory, `tools/completion_d5_case.py MACHINE MASK OUTPUT` performs
the native-keyboard route and rate capture. Select the documented developer
bundle plus bit 13; retain CPU policy. `tools/completion_d5_inputs.py`,
`completion_d5_pause.py` and `completion_d5_soak.py` are the retained companion
checks. Inspect their arguments before running; they may use fixed evidence paths.
Do not run these postponed checks as part of the current release.

D2's retained native checker is `tools/completion_d2_twin.py`; its original
output path is fixed, so use a fresh path before intentional reproduction.

## Reproduce

From the repository root, using the shared environment:

```sh
source tmp/dev/amiga/env.sh
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_game_time_model.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_time_capacity.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_input_events.py'
python3 -B -m unittest discover -s R/RedBaron/tools -p 'test_pose_history.py'
VERIFY=1 bash tmp/dev/tools/build.sh
```

Native rechecks require the ignored development game installation, one owned
emulator, a fresh output directory and the corresponding VERIFY options below.
Use the shared machine definitions in `tools/completion_machines.py`; historical
A500 drivers that still select slow RAM must be updated to the approved minimum
before reuse. These commands are for intentional rechecks, not additional
release validation rounds.
