; Optional VERIFY-only recorder of native simulation entries, not completions.
; $E5F2: LINK a5,#-4; MOVEQ #0,d0. JMP hook has no extra return address.
; All entry registers except native A5/D0 and the native MOVEQ flags survive.
SIM_PROBE_RECORD_SIZE = 40
SIM_PROBE_RECORD_COUNT = 256
sim_probe_entry:
 link a5,#-4
 movem.l d0-d2/a0-a1,-(sp)
 moveq #0,d2
 addx.b d2,d2              ; save incoming X (MOVEQ preserves it)
 move.w d2,-(sp)
 IFD SIM_FIXTURE
 bsr sim_fixture_before
 ENDC
 lea sim_probe_count(pc),a0
 move.l (a0),d0
 and.l #SIM_PROBE_RECORD_COUNT-1,d0
 mulu #SIM_PROBE_RECORD_SIZE,d0
 lea sim_probe_records(pc),a1
 adda.l d0,a1
 move.l $2342(a4),(a1)+       ; 0: raw timer clock
 move.l $233a(a4),(a1)+       ; 4: ungated timer clock
 move.l a4,(a1)+             ; 8: data anchor
 move.w $a0(a4),(a1)+        ; 12: producer cursor
 move.w -$940(a4),(a1)+      ; 14: consumer cursor before update
 move.w -$15fa(a4),(a1)+     ; 16: active mode
 move.w -$be(a4),(a1)+       ; 18: timer divider
 move.w -$217c(a4),(a1)+     ; 20: CIA timer latch
 move.b $45(a4),(a1)+        ; 22: live/start/replay mode
 move.b -$68b(a4),(a1)+      ; 23: driving started
 move.l -$92e(a4),(a1)+      ; 24: player position
 move.l -$92a(a4),(a1)+      ; 28: player position
 move.l -$926(a4),(a1)+      ; 32: player position
 move.w $9c(a4),(a1)+        ; 36: scheduling ticks
 move.w -$948(a4),(a1)+      ; 38: event elapsed
 addq.l #1,(a0)             ; publish the completed record last
 move.w (sp)+,d2
 lsr.b #1,d2               ; restore X before flag-neutral transfer
 movem.l (sp)+,d0-d2/a0-a1
 ; Transfer to the remaining native body without borrowing an entry register.
 ; D0 is dead at entry: the displaced MOVEQ establishes it immediately below.
 move.l a0,-(sp)
 move.l tape_game(pc),a0
 adda.l #$e5f8,a0
 move.l a0,d0
 move.l (sp)+,a0
 move.l d0,-(sp)
 moveq #0,d0
 rts
 even
 dc.b "4DSIMPRB"
 dc.w 1,SIM_PROBE_RECORD_SIZE
sim_probe_count:
 dc.l 0
sim_probe_records:
 dcb.b SIM_PROBE_RECORD_SIZE*SIM_PROBE_RECORD_COUNT,0

 IFD SIM_FIXTURE
; Deterministic consumer-side input fixture, VERIFY only. This is deliberately
; not a production input scheduler. Default: first 3.2 seconds at 10 Hz;
; configurable sample count/cadence permits longer gear/contact coverage.
; Snapshots are raw native replay state; compare and classify differences before
; selecting a semantic manifest. No fields are masked here.
 IFND SIM_FIXTURE_SAMPLES
SIM_FIXTURE_SAMPLES = 32
 ENDC
 IFGT SIM_FIXTURE_SAMPLES-64
 FAIL "SIM_FIXTURE_SAMPLES must be 1..64"
 ENDC
 IFLE SIM_FIXTURE_SAMPLES
 FAIL "SIM_FIXTURE_SAMPLES must be 1..64"
 ENDC
 IFND SIM_FIXTURE_SAMPLE_HZ
SIM_FIXTURE_SAMPLE_HZ = 10
 ENDC
 IFNE SIM_FIXTURE_SAMPLE_HZ-5
 IFNE SIM_FIXTURE_SAMPLE_HZ-10
 FAIL "SIM_FIXTURE_SAMPLE_HZ must be 5 or 10"
 ENDC
 ENDC
SIM_FIXTURE_STATE_SIZE = $460
 IFD SIM_A4000
SIM_FIXTURE_RECORD_SIZE = SIM_FIXTURE_STATE_SIZE+10+SIM_PRIVATE_BYTES+SIM_TIME_STATE_BYTES
 ELSE
SIM_FIXTURE_RECORD_SIZE = SIM_FIXTURE_STATE_SIZE+10
 ENDC

 IFD SIM_HISTORY_SEEK_TEST
 IFND SIM_HISTORY_TEST_SPACING
 FAIL "SIM_HISTORY_SEEK_TEST requires shortened checkpoint spacing"
 ENDC
 IFNE SIM_HISTORY_TEST_SPACING-50
 FAIL "SIM_HISTORY_SEEK_TEST requires checkpoint spacing 50"
 ENDC
; Explicit test transition at a completed live tick, then invoke the actual
; native seek routine with target 55. No fixture inputs are written in replay.
sim_history_seek_fixture:
 tst.b $45(a4)
 bne .done
 cmp.w #160,-$940(a4)
 bne .done
 movem.l d0-a6,-(sp)
 move.b #2,$45(a4)
 move.w #55,-(sp)
 move.l tape_game(pc),a0
 adda.l #$e518,a0
 jsr (a0)
 addq.l #2,sp
 movem.l (sp)+,d0-a6
.done:
 rts
 ENDC

 IFD SIM_CAPACITY_FIXTURE
; Call the real native input writer at the old wrapped limit, beyond the old
; allocation, and at the final byte of the new buffer. Restore all test state.
sim_capacity_fixture:
 tst.b $45(a4)
 bne .done
 cmp.w #50,-$15fa(a4)
 bne .done
 cmp.w #160,-$940(a4)
 bne .done
 movem.l d0-a6,-(sp)
 link a5,#-20
 move.w $a0(a4),-2(a5)
 move.w -$1738(a4),-4(a5)
 move.w -$2e0(a4),-6(a5)
 move.l tape_game(pc),a0
 lea sim_capacity_fixture(pc),a1
 adda.l #sim_schedule_modal-sim_capacity_fixture,a1
 move.w (a1),-8(a5)
 move.w #1,(a1)
 move.l -$1770(a4),a0
 move.b 9464(a0),-9(a5)
 move.b 12000(a0),-10(a5)
 move.b 29999(a0),-11(a5)
 lea sim_capacity_fixture_cases(pc),a3
 moveq #2,d7
.case:
 move.w (a3)+,d6
 move.w d6,$a0(a4)
 move.w d6,-$1738(a4)
 move.w (a3)+,-$2e0(a4)
 move.l -$1770(a4),a0
 move.b #$7f,(a0,d6.w)
 move.w #1,-(sp)
 move.l tape_game(pc),a0
 adda.l #$7a66,a0
 jsr (a0)
 addq.l #2,sp
 move.l -$1770(a4),a0
 tst.b (a0,d6.w)
 bne .failed
 addq.w #1,d6
 cmp.w $a0(a4),d6
 bne .failed
 cmp.w -$1738(a4),d6
 bne .failed
 tst.b $42(a4)
 bne .failed
 lea sim_capacity_fixture_passed(pc),a0
 addq.l #1,(a0)
 dbra d7,.case
 move.l -$1770(a4),a0
 cmp.l #$34444755,30000(a0) ; 4DGU
 bne .failed
 cmp.l #$41524421,30004(a0) ; ARD!
 bne .failed
 move.b -9(a5),9464(a0)
 move.b -10(a5),12000(a0)
 move.b -11(a5),29999(a0)
 move.w -2(a5),$a0(a4)
 move.w -4(a5),-$1738(a4)
 move.w -6(a5),-$2e0(a4)
 lea sim_capacity_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_capacity_fixture,a0
 move.w -8(a5),(a0)
 unlk a5
 movem.l (sp)+,d0-a6
.done:
 rts
.failed:
 lea sim_capacity_fixture(pc),a0
 adda.l #perf_failure-sim_capacity_fixture,a0
 move.l #18,(a0)
 illegal
 bra.s .failed
 even
sim_capacity_fixture_cases:
 dc.w 9464,0,12000,0,29999,45000
 dc.b "4DCAPFIX"
 dc.w 1,3
sim_capacity_fixture_passed: dc.l 0
 ENDC

 IFD SIM_HISTORY_END_SEEK_TEST
; Synthetic final checkpoint for the real native seek(capacity) boundary.
; This tests index selection/storage bounds, not 25-minute handling outcomes.
sim_history_end_seek_fixture:
 tst.b $45(a4)
 bne .done
 cmp.w #160,-$940(a4)
 bne .done
 movem.l d0-a6,-(sp)
 move.l -$16bc(a4),a1
 adda.l #19*$460,a1
 lea -$a80(a4),a0
 move.w #$460/4-1,d0
.copy:
 move.l (a0)+,(a1)+
 dbra d0,.copy
 move.w #28500,$140-$460(a1)
 move.b #1,$3f4-$460(a1)
 ; Distinct high-word values prove the extended result state is restored.
 move.w #2,$14a-$460(a1)
 move.w #9464,$142-$460(a1)
 move.w #9463,$144-$460(a1)
 lea sim_history_end_seek_fixture(pc),a0
 adda.l #sim_results_state-sim_history_end_seek_fixture,a0
 move.l #65538,(a0)+
 move.l #75000,(a0)+
 move.l #74999,(a0)+
 move.l #135000,(a0)
 lea sim_history_end_seek_fixture(pc),a1
 adda.l #sim_a4000_private-sim_history_end_seek_fixture,a1
 lea $228(a4),a2
 moveq #19,d0
 lea sim_history_end_seek_fixture(pc),a0
 adda.l #sim_history_store-sim_history_end_seek_fixture,a0
 jsr (a0)
 lea sim_history_end_seek_fixture(pc),a0
 adda.l #sim_results_state-sim_history_end_seek_fixture,a0
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)
 move.b #2,$45(a4)
 move.w #30000,-(sp)
 move.l tape_game(pc),a0
 adda.l #$e518,a0
 jsr (a0)
 addq.l #2,sp
 movem.l (sp)+,d0-a6
.done:
 rts
 ENDC

 IFD SIM_HISTORY_ROTATION_TEST
 IFND SIM_HISTORY_ROTATION_BASE
SIM_HISTORY_ROTATION_BASE = 0
 ENDC
; Populate all history slots with distinct byte patterns, then execute the
; actual native full-buffer path. External checks compare every moved byte.
; This synthetic boundary fixture deliberately stops instead of driving on.
sim_history_rotation_fixture:
 tst.b $45(a4)
 bne sim_history_rotation_return
 cmp.w #50,-$15fa(a4)
 bne sim_history_rotation_return
 cmp.w #160,-$940(a4)
 bne sim_history_rotation_return
 lea sim_history_rotation_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_history_rotation_fixture,a0
 move.w #1,(a0)              ; retain live clock ownership, close capture
 move.l -$16bc(a4),a0
 move.w #20*$460-1,d0
 moveq #0,d1
.native_bytes:
 move.b d1,(a0)+
 addq.b #1,d1
 dbra d0,.native_bytes
 move.l -$16bc(a4),a0
 moveq #19,d0
 moveq #0,d1
.native_ticks:
 move.w d1,$140(a0)
 move.b #1,$3f4(a0)
 add.w #1500,d1
 lea $460(a0),a0
 dbra d0,.native_ticks
 lea sim_history_rotation_fixture(pc),a0
 adda.l #sim_history_records-sim_history_rotation_fixture,a0
 move.l a0,a1
 move.w #20*SIM_HISTORY_BYTES-1,d0
 moveq #$55,d1
.private_bytes:
 move.b d1,(a0)+
 addq.b #7,d1
 dbra d0,.private_bytes
 moveq #19,d0
.valid:
 move.w #50,(a1)
 lea SIM_HISTORY_BYTES(a1),a1
 dbra d0,.valid
 move.l -$1770(a4),a0
 move.w #30000-1,d0
 moveq #0,d1
.inputs:
 move.b d1,(a0)+
 addq.b #1,d1
 dbra d0,.inputs
 move.w #30000,$a0(a4)
 move.w #30000,-$1738(a4)
 move.w #30000,-$940(a4)
 move.w #SIM_HISTORY_ROTATION_BASE,-$2e0(a4)
 move.b #1,$a9b(a4)          ; full-history warning was already acknowledged
 clr.b $a9a(a4)
 clr.b $42(a4)
sim_history_rotation_ready:
 move.w #1,-(sp)
 move.l tape_game(pc),a0
 adda.l #$7a66,a0
 jsr (a0)
 addq.l #2,sp
sim_history_rotation_done:
 bra.s sim_history_rotation_done
sim_history_rotation_return:
 rts
 ENDC

sim_fixture_before:
 IFD SIM_HISTORY_ROTATION_TEST
 bsr sim_history_rotation_fixture
 ENDC
 IFD SIM_HISTORY_END_SEEK_TEST
 bsr sim_history_end_seek_fixture
 ENDC
 IFD SIM_CAPACITY_FIXTURE
 bsr sim_capacity_fixture
 ENDC
 IFD SIM_HISTORY_SEEK_TEST
 bsr sim_history_seek_fixture
 ENDC
 move.l tape_configured(pc),d0
 beq .done
 tst.b $45(a4)
 bne .done
 lea sim_fixture_active(pc),a0
 tst.w (a0)
 bne .active
 tst.w -$940(a4)
 bne .done
 tst.b -$68b(a4)
 bne .done
 move.w #1,(a0)
 IFD SIM_FIXTURE_OPPONENT_BRAKE
 IFND TAPE_OPPONENT
 FAIL "SIM_FIXTURE_OPPONENT_BRAKE requires TAPE_OPPONENT"
 ENDC
 ; Explicit synthetic recovery state for brake-branch coverage. Menu loading,
 ; original opponent initialization and all subsequent decisions stay native.
 move.w #1000,-$832(a4)
 move.w #64,-$828(a4)
 move.b #1,-$79e(a4)
 clr.b -$795(a4)
 ENDC
 IFD SIM_FIXTURE_OPPONENT_SPIN
 IFND TAPE_OPPONENT
 FAIL "SIM_FIXTURE_OPPONENT_SPIN requires TAPE_OPPONENT"
 ENDC
 ; Explicit synthetic angular pose. Subsequent damping and motion are native
 ; in reference captures; only the selected50 Hz hooks change prototype runs.
 move.w #SIM_FIXTURE_OPPONENT_SPIN,-$820(a4)
 move.w #64,-$828(a4)
 move.w #10000,-$832(a4)
 ENDC
 IFD SIM_FIXTURE_OPPONENT_SLIP
 IFND TAPE_OPPONENT
 FAIL "SIM_FIXTURE_OPPONENT_SLIP requires TAPE_OPPONENT"
 ENDC
 ; Synthetic disabled opponent: +$C9 suppresses AI steering/throttle and
 ; its zero-speed recovery reset, isolating slip decay from body movement.
 move.w #SIM_FIXTURE_OPPONENT_SLIP,-$828(a4)
 move.b #1,-$795(a4)
 clr.w -$832(a4)
 clr.w -$820(a4)
 ENDC
 IFD SIM_FIXTURE_CONTACT_RAMP
 IFD TAPE_OPPONENT
 FAIL "SIM_FIXTURE_CONTACT_RAMP requires the stock solo start"
 ENDC
 ; Synthetic pose over the stock Default track ramp at column 22, row 4.
 ; Ground meshes and all later contact decisions remain native.
 ; Translate cached world wheel coordinates along with the body. Native
 ; contact compares these previous coordinates against new projected wheels.
 lea -$8ba(a4),a0           ; player+$74, four world XYZ word triplets
 moveq #3,d1
.ramp_wheels:
 add.w #15324,(a0)+         ; (1474560-493824)/64
 add.w #312,(a0)+           ; (20480-512)/64
 sub.w #917,(a0)+           ; floor(288358/64)-floor(347008/64)
 dbra d1,.ramp_wheels
 move.l #1474560,-$92e(a4)
 move.l #20480,-$92a(a4)
 move.l #288358,-$926(a4)
 move.w #10000,-$902(a4)
 ENDC
 IFD SIM_FIXTURE_HEADING
 ; Synthetic near-cardinal initial heading for rate/word-wrap coverage.
 move.w #SIM_FIXTURE_HEADING,-$916(a4)
 ENDC
 IFD SIM_FIXTURE_DROP
 ; Synthetic initial pose for airborne/contact coverage. Native physics handles
 ; the fall; 1024 position units is small enough to test an ordinary landing.
 add.l #1024,-$92a(a4)
 ENDC
 IFD SIM_FIXTURE_SUSPENSION
 ; Explicit synthetic preload exercises otherwise-zero suspension bias and
 ; target approach. It is not a normal saved race state or a handling proof.
 move.w #16,-$8c2(a4)
 move.w #16,-$8c0(a4)
 move.w #16,-$8be(a4)
 move.w #16,-$8bc(a4)
 ENDC
 IFD SIM_A4000
 IFND SIM_A4000_NATIVE
 ; Verification tables can exceed a 68000 relative-call displacement.
 lea sim_fixture_before(pc),a0
 adda.l #sim_a4000_arm-sim_fixture_before,a0
 jsr (a0)
 ENDC
 ENDC
.active:
 ; Throttle throughout, steering right from 1.0 to 1.5 seconds and left
 ; from 1.5 to 2.0 seconds. Boundaries are exact in all three planned modes.
 moveq #1,d1
 move.w -$15fa(a4),d0
 cmp.w -$940(a4),d0
 bhi .input
 moveq #5,d1
 move.w d0,d2
 lsr.w #1,d2
 add.w d2,d0
 cmp.w -$940(a4),d0
 bhi .input
 moveq #9,d1
 move.w -$15fa(a4),d0
 add.w d0,d0
 cmp.w -$940(a4),d0
 bhi .input
 moveq #1,d1
.input:
 IFD SIM_FIXTURE_OFFROAD
 ; Accelerate straight, then hold right. Delay the turn to exercise spin
 ; at greater speed without changing the car, track or surface state.
 IFND SIM_FIXTURE_TURN_SECONDS
SIM_FIXTURE_TURN_SECONDS = 3
 ENDC
 IFLT SIM_FIXTURE_TURN_SECONDS
 FAIL "SIM_FIXTURE_TURN_SECONDS must be 0..30"
 ENDC
 IFGT SIM_FIXTURE_TURN_SECONDS-30
 FAIL "SIM_FIXTURE_TURN_SECONDS must be 0..30"
 ENDC
 moveq #1,d1
 move.w -$15fa(a4),d0
 mulu #SIM_FIXTURE_TURN_SECONDS,d0
 cmp.w -$940(a4),d0
 bhi .offroad_input
 moveq #5,d1
.offroad_input:
 IFD SIM_FIXTURE_RECOVERY
 ; Countersteer 1.5 seconds after the turn starts, then release at 2.5 s.
 ; All boundaries are exact in 10, 20 and 50 Hz modes.
 move.w -$15fa(a4),d0
 mulu #2*SIM_FIXTURE_TURN_SECONDS+3,d0
 lsr.l #1,d0
 cmp.w -$940(a4),d0
 bhi .recovery_input
 moveq #9,d1
 move.w -$15fa(a4),d0
 mulu #2*SIM_FIXTURE_TURN_SECONDS+5,d0
 lsr.l #1,d0
 cmp.w -$940(a4),d0
 bhi .recovery_input
 moveq #1,d1
.recovery_input:
 ENDC
 ENDC
 IFD SIM_FIXTURE_GEARS
 ; One native upshift input at 0.5s, one downshift at 2.0s.
 move.w -$15fa(a4),d0
 lsr.w #1,d0
 cmp.w -$940(a4),d0
 bne .not_up
 or.b #$10,d1
.not_up:
 move.w -$15fa(a4),d0
 add.w d0,d0
 cmp.w -$940(a4),d0
 bne .not_down
 or.b #$20,d1
.not_down:
 ENDC
 moveq #0,d0
 move.w -$940(a4),d0
 move.l -$1770(a4),a1
 move.b d1,(a1,d0.l)
 ; Capture BEFORE the native update: sample 0 is the untouched initial state.
 move.w -$15fa(a4),d1
 divu #SIM_FIXTURE_SAMPLE_HZ,d1
 divu d1,d0
 swap d0
 tst.w d0
 bne .done
 lea sim_fixture_count(pc),a0
 cmp.w #SIM_FIXTURE_SAMPLES,(a0)
 bhs .done
 moveq #0,d0
 move.w (a0),d0
 mulu #SIM_FIXTURE_RECORD_SIZE,d0
 lea sim_fixture_records(pc),a1
 adda.l d0,a1
 move.w -$940(a4),(a1)+
 move.w -$15fa(a4),(a1)+
 lea -$a80(a4),a0
 move.w #SIM_FIXTURE_STATE_SIZE/4-1,d0
.copy:
 move.l (a0)+,(a1)+
 dbf d0,.copy
 ; Native replay save omits live RNG byte +$22C. Record all six directly.
 move.l $228(a4),(a1)+
 move.w $22c(a4),(a1)+
 IFD SIM_A4000
 lea sim_fixture_before(pc),a0
 adda.l #sim_a4000_private-sim_fixture_before,a0
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.private:
 move.l (a0)+,(a1)+
 dbra d0,.private
 lea sim_fixture_before(pc),a0
 adda.l #sim_results_state-sim_fixture_before,a0
 moveq #SIM_TIME_STATE_BYTES/4-1,d0
.times:
 move.l (a0)+,(a1)+
 dbra d0,.times
 ENDC
 lea sim_fixture_count(pc),a0
 addq.w #1,(a0)
.done:
 rts
 even
 dc.b "4DSIMFIX"
 IFD SIM_A4000
 dc.w 4,SIM_FIXTURE_RECORD_SIZE
 ELSE
 dc.w 2,SIM_FIXTURE_RECORD_SIZE
 ENDC
sim_fixture_active: dc.w 0
sim_fixture_count: dc.w 0
sim_fixture_records:
 dcb.b SIM_FIXTURE_SAMPLES*SIM_FIXTURE_RECORD_SIZE,0
 ENDC
