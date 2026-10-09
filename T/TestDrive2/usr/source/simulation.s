; duel v1: fixed-period simulation, part of the enhanced framerate option (CUSTOM2).
; A step lasts sim_p PAL fields: 6 on a 68000/010 (the original period, so no
; CPU is spent on steps nobody sees), 2 on a 68020+ (the 25 fps render cap).
; Continuous dynamics use dt = 1/sim_n of the original six-field step,
; sim_n = 6/sim_p. Spatial road-unit loops, event impulses and field-based
; input/audio timers stay intact.
; Private fractional state belongs to the slave, never the read-only debugger.

; Before PatchSeg: read the options, run any VERIFY unit checks (they use the
; default period), then choose the period from the CPU.
sim_init:
    lea sim_tags(pc),a0
    move.l _resload(pc),a2
    jsr (resload_Control,a2)
    lea render_options(pc),a0  ; one switch enables all three features
    tst.l (a0)
    beq.b .options
    moveq #7,d0
    move.l d0,(a0)
.options
    IFD VERIFY
    move.l sim_drive_enabled(pc),d0
    beq.b .configure
    bsr verify_simulation_units
.configure
    ENDC
    move.l sim_attn(pc),d0
; d0 = AttnFlags.
sim_configure:
    movem.l d0/a0-a1,-(sp)
    lea sim_periods(pc),a0
    btst #1,d0                ; AFB_68020
    beq.b .table
    lea SIM_PERIOD_SIZE(a0),a0
.table
    lea sim_p(pc),a1
    moveq #SIM_PERIOD_SIZE/2-1,d0
.copy
    move.w (a0)+,(a1)+
    dbf d0,.copy
    movem.l (sp)+,d0/a0-a1
    rts
; After PatchSeg (d7 = seglist): the two PL_L deadline patches hold
; moveq #1; make them moveq #sim_p.
sim_set_deadline:
    move.l render_options(pc),d0
    btst #0,d0
    beq.b .done
    move.l d7,a1
    add.l a1,a1
    add.l a1,a1               ; root hunk - 4
    move.w sim_p(pc),d0
    or.w #$7000,d0
    move.w d0,4+$05bea(a1)
    move.w d0,4+$05c0c(a1)
    move.l _resload(pc),a2
    jsr (resload_FlushCache,a2)
.done
    rts

sim_start:
    movem.l d0/a0,-(sp)
    move.l -17216(a4),d0
    move.l d0,-17212(a4)       ; displaced initial deadline
    IFD VERIFY
    lea sim_epoch(pc),a0
    move.l d0,(a0)
    ENDC
    lea sim_gear_field(pc),a0
    move.l d0,(a0)
    lea sim_gear_value(pc),a0
    move.w -24720(a4),(a0)
    lea sim_recovery_until(pc),a0
    clr.l (a0)
    lea sim_phase(pc),a0
    moveq #6,d0
    sub.w sim_p(pc),d0
    move.w d0,(a0)            ; the first step is an original six-field boundary
    lea sim_rates(pc),a0
    moveq #SIM_RATE_WORDS-1,d0
.clear_rates
    clr.w (a0)+
    dbf d0,.clear_rates
    lea sim_fractions(pc),a0
    clr.l (a0)+               ; player time / opponent time
    clr.l (a0)                ; player sum / opponent sum
    lea sim_code(pc),a0
    move.l -32266(a4),d0      ; absolute target of RNG jump-table entry
    sub.l #$e9e2,d0
    move.l d0,(a0)
    lea sim_visual_seed(pc),a0
    move.w -18632(a4),d0
    eor.w #$a53c,d0
    move.w d0,(a0)
    movem.l (sp)+,d0/a0
    rts

sim_begin:
    movem.l d0-d2/a0,-(sp)
    lea sim_phase(pc),a0
    move.w sim_p(pc),d0
    add.w d0,(a0)
    cmp.w #6,(a0)
    bcs.b .phase
    clr.w (a0)               ; zero at original six-field boundaries
.phase
    lea sim_tick_force(pc),a0
    move.l (a0),sim_prev_force-sim_tick_force(a0)
    clr.l (a0)
    bsr sim_visual_step
    bsr sim_recovery_step
    IFD VERIFY
    bsr verify_drive_mode
    ENDC
    lea sim_recovery_until(pc),a0
    tst.l (a0)
    beq.b .normal
    movem.l (sp)+,d0-d2/a0
    add.l #$92,(sp)           ; recovering player does not borrow demo AI state
    rts
.normal
    movem.l (sp)+,d0-d2/a0
    tst.w -17282(a4)          ; displaced demo check and branch
    bne.b .demo
    add.l #$92,(sp)           ; return to duel:05af2, bypass demo borrow
.demo
    rts

; Signed 32-bit division by sim_n with a private remainder per accumulator.
; d0 is the rate in original-step units; a0 points to a word in 0..sim_n-1.
; Floor division plus carry also handles INT_MIN without a DIVS overflow.
; sim_n constant-rate calls sum exactly to the original signed rate.
sim_scale_long:
    movem.l d1-d4,-(sp)
    move.w sim_n(pc),d4
    move.l d0,d3
    bpl.b .positive
    neg.l d0                 ; INT_MIN remains its unsigned magnitude
.positive
    move.l d0,d1
    clr.w d0
    swap d0
    divu.w d4,d0             ; high quotient and remainder
    move.w d0,d2
    clr.w d0
    move.w d1,d0
    divu.w d4,d0             ; remaining high remainder + low word
    swap d2
    move.w d0,d2
    swap d0
    and.l #$ffff,d0           ; remainder
    tst.l d3
    bpl.b .carry
    neg.l d2
    tst.w d0
    beq.b .carry
    subq.l #1,d2
    neg.w d0
    add.w d4,d0
.carry
    add.w (a0),d0
    cmp.w d4,d0
    bcs.b .store
    sub.w d4,d0
    addq.l #1,d2
.store
    move.w d0,(a0)
    move.l d2,d0
    movem.l (sp)+,d1-d4
    rts

; Unsigned 32-bit division with a word divisor and a carry in that divisor's
; units. Keeping the /64 low bits until the FINAL division is essential: early
; shifts would lose creeping motion and the constant-force Euler equivalence.
sim_scale_distance:
    move.l d3,-(sp)
    move.w sim_n(pc),d3
    lsl.w #7,d3              ; 2 * 64 * sim_n
    bsr sim_scale_unsigned
    move.l (sp)+,d3
    rts
sim_scale_ai_motion:
    move.l d3,-(sp)
    move.w sim_n(pc),d3
    add.w d3,d3              ; 2 * sim_n
    bsr sim_scale_unsigned
    move.l (sp)+,d3
    rts
sim_scale_unsigned:
    movem.l d1-d2/d4,-(sp)
    move.l d0,d1
    clr.w d0
    swap d0
    divu.w d3,d0
    move.w d0,d2
    clr.w d0
    move.w d1,d0
    divu.w d3,d0
    swap d2
    move.w d0,d2
    swap d0
    add.w (a0),d0
    cmp.w d3,d0
    bcs.b .store
    sub.w d3,d0
    addq.l #1,d2
.store
    move.w d0,(a0)
    move.l d2,d0
    movem.l (sp)+,d1-d2/d4
    rts

; The original force lookup samples the beginning of a coarse Euler step.
; A finer lookup needs the corresponding half-step correction too: evaluate
; at v - (sim_n-1)/2*dv from the preceding step. Real velocity/RPM remain live;
; only throttle/drag lookup inputs use this modified-Euler reference.
sim_force_reference:
    move.l d1,-(sp)
    move.l sim_prev_force(pc),d1
    bsr sim_times_n_minus_1
    asr.l #1,d0
    neg.l d0
    add.l -13282(a4),d0
    bpl.b .forward
    moveq #0,d0
.forward
    move.l (sp)+,d1
    rts
sim_throttle_curve:
    bsr sim_force_reference
    lsr.l #8,d0
    mulu.w -13034(a4),d0
    swap d0
    lsr.w #7,d0
    rts
sim_drag_curve:
    move.l d0,-(sp)
    bsr sim_force_reference
    swap d0
    move.w d0,d1
    lsr.w #2,d1
    move.l (sp)+,d0
    rts

sim_scale_word:
    ext.l d0
    bra sim_scale_long

; Keep the original semi-implicit Euler displacement: n small steps otherwise
; sum less than v + a. d0 = v, d1 = this step's dv; returns
; max(0, 2v + (n-1)dv), twice the step's displacement.
sim_euler_velocity:
    move.l d0,-(sp)
    bsr sim_times_n_minus_1
    add.l (sp),d0
    add.l (sp)+,d0
    bpl.b .done
    moveq #0,d0
.done
    rts

; d0 = d1 * (sim_n - 1), for the small sim_n used (1, 3 or 6).
sim_times_n_minus_1:
    move.l d2,-(sp)
    moveq #0,d0
    move.w sim_n(pc),d2
    subq.w #2,d2
    bmi.b .done
.add
    add.l d1,d0
    dbf d2,.add
.done
    move.l (sp)+,d2
    rts

; AI rates require independent carries for the opponent, demo driver and police.
; a5 is the original car record. No allocation or gameplay RNG is used here.
sim_ai_remainder:
    movem.l d0-d1,-(sp)
    lea sim_ai_rates(pc),a0
    moveq #3,d1
.find
    move.l (a0),d0
    beq.b .claim
    cmp.l a5,d0
    beq.b .found
    adda.w #14,a0
    dbf d1,.find
    ; All four installed records are bounded by the game's call sites.
    lea sim_ai_rates(pc),a0
.claim
    move.l a5,(a0)
.found
    addq.l #4,a0
    movem.l (sp)+,d0-d1
    rts

sim_speed_add:
    move.l a0,-(sp)
    lea sim_speed_frac(pc),a0
    bsr sim_scale_long
    move.l (sp)+,a0
    bsr sim_record_force
    add.l d0,-13282(a4)
    tst.w -13188(a4)
    rts

sim_player_motion:
    move.l a0,-(sp)
    move.l sim_tick_force(pc),d1 ; spatial impulses are excluded
    bsr sim_euler_velocity
    lea sim_distance_frac(pc),a0
    bsr sim_scale_distance
    move.l (sp)+,a0
    move.l -17238(a4),d1       ; displaced next instruction
    rts

sim_yaw_add:
    move.l a0,-(sp)
    move.w -4(a5),d0
    lea sim_yaw_frac(pc),a0
    bsr sim_scale_word
    move.l (sp)+,a0
    add.w d0,-9862(a4)
    rts

sim_heat_add:
    movem.l d0/a0,-(sp)
    move.w d1,d0
    lea sim_heat_frac(pc),a0
    bsr sim_scale_word
    move.w d0,d1
    movem.l (sp)+,d0/a0
    add.w -24718(a4),d1
    move.w d1,-24718(a4)
    rts

sim_heat_cool:
    movem.l d0/a0,-(sp)
    lsr.w #2,d1
    moveq #0,d0
    move.w d1,d0
    lea sim_heat_frac(pc),a0
    neg.l d0
    bsr sim_scale_long
    neg.w d0
    move.w d0,d1
    movem.l (sp)+,d0/a0
    sub.w d1,-24718(a4)       ; CCR feeds original underflow clamp
    rts

sim_dashboard:
    move.l a0,-(sp)
    lsr.w #7,d1
    moveq #0,d0
    move.w d1,d0
    lea sim_dashboard_frac(pc),a0
    bsr sim_scale_long
    move.w d0,d1
    move.l (sp)+,a0
    move.w -3008(a4),d0
    rts

; d0 is the signed physical speed change just applied by a rate producer.
; Event/gear/collision impulses do not call this accumulator.
sim_record_force:
    move.l a0,-(sp)
    lea sim_tick_force(pc),a0
    add.l d0,(a0)
    move.l (sp)+,a0
    rts

sim_ai_prepare:
    movem.l a0,-(sp)
    bsr sim_ai_remainder
    move.l 10(a5),6(a0)
    movem.l (sp)+,a0
    rts
sim_ai_begin:
    movem.l d0-a6,-(sp)     ; original prologue, before the body's own epilogue
    bsr sim_ai_prepare
    clr.w -2770(a4)         ; original following instruction
    move.l sim_code(pc),-(sp)
    add.l #$d6b6,(sp)
    rts

; The demo record is a predictor, not a second physical car: duel:05a62
; seeds it from the player on EVERY call, then discards its speed/distance.
; Preserve the original prediction horizon; only its lane output is a real rate.
sim_is_demo:
    move.l a0,-(sp)
    lea -10478(a4),a0
    cmpa.l a0,a5
    move.l (sp)+,a0
    rts
sim_ai_scale_speed:
    bsr sim_is_demo
    beq.b .done
    bsr sim_ai_remainder
    bsr sim_scale_long
.done
    rts

sim_ai_accel:
    move.l a0,-(sp)
    mulu.w 22(a5),d0
    clr.w d0
    swap d0
    bsr sim_ai_scale_speed
    move.l (sp)+,a0
    rts

sim_ai_lane:
    movem.l d1/a0,-(sp)
    move.w d0,d1
    move.w d2,d0
    bsr sim_ai_remainder
    addq.l #2,a0
    bsr sim_scale_word
    move.w d0,d2
    move.w d1,d0
    movem.l (sp)+,d1/a0
    add.w d2,d0
    move.w d0,6(a5)
    rts

sim_ai_motion:
    movem.l d1/a0,-(sp)
    move.l 10(a5),d0
    bsr sim_is_demo
    beq.b .predicted
    bsr sim_ai_remainder
    move.l d0,d1
    sub.l 6(a0),d1           ; this step's physical speed change
    bsr sim_euler_velocity
    addq.l #4,a0
    bsr sim_scale_ai_motion
.predicted
    movem.l (sp)+,d1/a0
    add.l 2(a5),d0
    rts

sim_traffic_forward:
    move.l a0,-(sp)
    lea sim_traffic_forward_frac(pc),a0
    bsr sim_scale_long
    move.l (sp)+,a0
    add.l -13470(a4),d0
    move.l d0,-13470(a4)
    rts
sim_traffic_oncoming:
    move.l a0,-(sp)
    move.l -7652(a4),d0
    lea sim_traffic_oncoming_frac(pc),a0
    bsr sim_scale_long
    move.l (sp)+,a0
    sub.l d0,-13466(a4)       ; CCR preserved for original wrap branch
    rts

; These counters retain their six-field time units. Thresholds and one-off
; crash/arrest penalties are therefore unchanged, including police scripts.
sim_crash_timer:
    bsr sim_test_phase
    bne.b .test
    addq.w #1,16(a5)
.test
    cmp.w #40,16(a5)
    rts
sim_police_timer:
    bsr sim_test_phase
    bne.b .test
    addq.w #1,-12980(a4)
.test
    cmp.w #30,-12980(a4)
    rts
sim_police_time_motion:
    bsr sim_test_phase
    bne.b .read
    addq.w #1,-7642(a4)
.read
    bra sim_ai_motion
sim_police_time_read:
    bsr sim_test_phase
    bne.b .read
    addq.w #1,-7642(a4)
.read
    move.w -7642(a4),d0
    rts
sim_police_limit_branch:
    bsr sim_test_phase
    bne.b .jump
    subq.w #1,-7642(a4)
.jump
    add.l #12,(sp)           ; return to original counter test at duel:0e074
    rts
sim_police_limit:
    move.w d1,d2            ; displaced negative-limit clamp
    bsr sim_test_phase
    bne.b .test
    subq.w #1,-7642(a4)
.test
    rts
sim_police_return_lane:
    movem.l d0/a0,-(sp)
    moveq #-41,d0
    bsr sim_ai_remainder
    addq.l #2,a0
    bsr sim_scale_word
    add.w d0,6(a5)
    movem.l (sp)+,d0/a0
    rts

; Gear audio can be called in the VBL as well as by physics. Elapsed fields,
; rather than call count or the step's phase, govern this envelope counter.
sim_gear_timer:
    movem.l d0-d1/a0,-(sp)
    bsr sim_test_active
    beq.b .advance          ; retain pre-race behaviour
    move.l -17216(a4),d0
    lea sim_gear_value(pc),a0
    move.w -24720(a4),d1
    cmp.w (a0),d1
    beq.b .elapsed
    move.w d1,(a0)          ; a new gear event resets the envelope epoch
    lea sim_gear_field(pc),a0
    move.l d0,(a0)
    bra.b .test
.elapsed
    lea sim_gear_field(pc),a0
    sub.l (a0),d0
    cmp.l #6,d0
    bcs.b .test
    add.l #6,(a0)
.advance
    addq.w #1,-24720(a4)
    lea sim_gear_value(pc),a0
    move.w -24720(a4),(a0)
.test
    movem.l (sp)+,d0-d1/a0
    cmp.w #25,-24720(a4)
    rts

; Continuous verge drag is called once per step with f3c0 set. The same
; routine also serves spatial collision checks, where the impulse stays whole.
sim_verge_low:
    move.l #12800,d0
    bra.b sim_verge_rate
sim_verge_high:
    move.l #29184,d0
sim_verge_rate:
    tst.w -3136(a4)
    beq.b .impulse
    move.l a0,-(sp)
    lea sim_verge_frac(pc),a0
    bsr sim_scale_long
    move.l (sp)+,a0
.impulse
    rts

; Crash recovery is simulation state, not a blocking drawing/acknowledgement
; loop. Forty original six-field crash ticks = 240 fields. Opponents, traffic,
; clock and input continue. Terminal crashes retain the original race-end path.
; Engine damage used the same CPU-paced life-loss path as a crash.
sim_overheat_check:
    tst.w -12938(a4)
    beq.b .done
    movem.l d0-d1/a0-a1,-(sp)
    moveq #1,d1
    lea -10870(a4),a1         ; damage count
    bsr sim_life_event
    movem.l (sp)+,d0-d1/a0-a1
    bne.b .done
    add.l #44,(sp)           ; original damage/race-end path at duel:05ca6
.done
    rts
sim_crash_check:
    tst.w -14916(a4)
    beq.b .done
    movem.l d0-d1/a0-a1,-(sp)
    moveq #0,d1
    lea -10872(a4),a1         ; crash count
    bsr sim_life_event
    movem.l (sp)+,d0-d1/a0-a1
    bne.b .done
    add.l #32,(sp)           ; original race-end handler at duel:05ca6
.done
    rts
; d1 = recovery kind, a1 = its event counter. Z set: end the race instead.
sim_life_event:
    move.l sim_trainer(pc),d0
    btst #0,d0
    bne.b .pending
    cmp.w #17,-14916(a4)      ; fatal crashes override an existing recovery
    beq.b .terminal
.pending
    lea sim_recovery_until(pc),a0
    tst.l (a0)
    bne.b .continue
    btst #0,d0
    bne.b .recover
    cmp.w #1,-17228(a4)
    ble.b .terminal
    subq.w #1,-17228(a4)
.recover
    addq.w #1,(a1)
    lea sim_recovery_kind(pc),a0
    move.w d1,(a0)
    beq.b .begin
    move.w #1,-14916(a4)      ; engine damage: inhibit player physics while cooling
.begin
    bsr sim_begin_recovery
.continue
    moveq #1,d0
    rts
.terminal
    lea sim_recovery_until(pc),a0
    clr.l (a0)
    moveq #0,d0
    rts

sim_begin_recovery:
    lea sim_recovery_until(pc),a0
    add.l #200,-10146(a4)
    add.l #200,-10864(a4)
    move.l -17216(a4),d0
    add.l #240,d0
    move.l d0,(a0)
    clr.l -13282(a4)
    clr.l -13188(a4)
    clr.w -13036(a4)
    clr.w -13038(a4)
    clr.w -9862(a4)
    clr.w -13390(a4)
    move.w #-1,-24720(a4)
    clr.w -2988(a4)
    bra sim_idle_sound

sim_idle_sound:
    movem.l d0-a6,-(sp)
    move.w #1800,-2792(a4)    ; original engine period at zero RPM
    move.w #-1,-(sp)         ; retain channel volume
    move.w #1800,-(sp)
    move.w #3,-(sp)           ; engine channel
    jsr -32544(a4)
    addq.l #6,sp
    movem.l (sp)+,d0-a6
    rts

sim_recovery_step:
    lea sim_recovery_until(pc),a0
    move.l (a0),d0
    beq .done
    sub.l -17216(a4),d0
    bgt.b .animate
    clr.l (a0)
    clr.w -14916(a4)
    clr.w -7694(a4)
    clr.w -7692(a4)
    clr.w -10462(a4)          ; demo driver's crash timer
    clr.w -10460(a4)
    clr.l -10468(a4)          ; demo driver's speed
    move.l -17238(a4),-10476(a4)
    move.l #$700000,-13386(a4)
    move.l -13386(a4),-10472(a4)
    clr.w -12938(a4)
    clr.w -12936(a4)
    clr.w -24718(a4)
    clr.w -10150(a4)
    move.w #-1,-24648(a4)
    move.w #-1,-24652(a4)
    bra.b .done
.animate
    neg.w d0
    add.w #240,d0            ; elapsed fields: derived, never render-call count
    cmp.w #120,d0
    bcs.b .height
    move.w #120,d0
.height
    move.w d0,-7692(a4)
.done
    rts

; The ordinary renderer owns the crash message. No game state is advanced here.
sim_dashboard_draw:
    bsr sim_original_dashboard
    movem.l d0-d3/a0-a2,-(sp)
    lea sim_recovery_until(pc),a0
    tst.l (a0)
    beq.b .done
    lea sim_crash_message(pc),a0
    move.w sim_recovery_kind(pc),d0
    beq.b .message
    lea sim_heat_message(pc),a0
.message
    move.l a0,-(sp)
    move.w #20,-(sp)
    bsr sim_original_text
    addq.l #6,sp
.done
    movem.l (sp)+,d0-d3/a0-a2
    unlk a5                  ; displaced original renderer epilogue
    rts
sim_original_dashboard:
    move.l -32266(a4),-(sp)  ; renderer also runs before the race anchor
    sub.l #$e9e2-$b45e,(sp)
    rts
sim_original_text:
    ; A tail jump preserves the original stack-based font arguments.
    move.l -32266(a4),-(sp)
    sub.l #$e9e2-$686e,(sp)
    rts
sim_crash_message: dc.b "CRASH - 20 SECOND PENALTY",0
    even
sim_heat_message: dc.b "ENGINE DAMAGE - 20 SECOND PENALTY",0
    even
sim_recovery_kind: dc.w 0
sim_recovery_until: dc.l 0

; One PAL field = 1/5 of a nominal tenth, a step sim_p/5. Carry fractions
; instead of truncating each step. Speed sums use the same weighting as time.
sim_player_time:
    movem.l d0-d1/a0,-(sp)
    lea sim_player_sum_frac(pc),a0
    bsr sim_fifths
    add.l d0,-7674(a4)
    lea sim_player_time_frac(pc),a0
    bsr sim_tenths
    add.l d0,-10146(a4)
    movem.l (sp)+,d0-d1/a0
    rts
; d0.w speed * sim_p / 5 with the carry word at a0 (in fifths); d0 = quotient.
sim_fifths:
    move.l d3,-(sp)
    mulu.w sim_p(pc),d0
    moveq #5,d3
    bsr sim_scale_unsigned
    move.l (sp)+,d3
    rts
; Whole nominal tenths elapsed in this step; the carry word at a0 is in fifths.
sim_tenths:
    moveq #0,d0
    move.w (a0),d1
    add.w sim_p(pc),d1
.carry
    cmp.w #5,d1
    bcs.b .done
    subq.w #5,d1
    addq.l #1,d0
    bra.b .carry
.done
    move.w d1,(a0)
    rts
sim_opponent_sum:
    asr.l d1,d0             ; displaced speed conversion
    movem.l d0-d1/a0,-(sp)
    lea sim_opponent_sum_frac(pc),a0
    bsr sim_fifths
    add.l d0,-10836(a4)
    movem.l (sp)+,d0-d1/a0
    rts
sim_opponent_time:
    movem.l d0/a0,-(sp)
    tst.w -7670(a4)         ; original running/finish conditions
    beq.b .done
    move.w -13356(a4),d0
    cmp.w -10076(a4),d0
    bge.b .done
    move.l d1,-(sp)
    lea sim_opponent_time_frac(pc),a0
    bsr sim_tenths
    add.l d0,-10844(a4)
    move.l (sp)+,d1
.done
    movem.l (sp)+,d0/a0
    jsr -32238(a4)          ; displaced input/exit check
    tst.w d0               ; displaced result test
    rts

; Pure state updates on simulation ticks; no drawing or gameplay RNG calls.
; The rare visual event's probability/countdown keep six-field quanta.
sim_visual_step:
    move.l -14920(a4),a0
    tst.w 2(a0)
    beq.b .event
    lea sim_background_frac(pc),a0
    move.l #4000,d0
    bsr sim_scale_long
    add.l d0,-3120(a4)
    addq.l #2,a0
    move.l #5000,d0
    bsr sim_scale_long
    add.l d0,-3116(a4)
    addq.l #2,a0
    move.l #6000,d0
    bsr sim_scale_long
    add.l d0,-3112(a4)
    addq.l #2,a0
    move.l #7000,d0
    bsr sim_scale_long
    add.l d0,-3108(a4)
.event
    bsr sim_test_phase
    bne .done
    tst.w -7640(a4)
    bne.b .animate
    cmp.w #95,-13282(a4)
    bcs .done
    tst.b -13378(a4)
    bmi .done
    bsr sim_visual_random
    and.w #$fff,d0
    bne .done
    st -7640(a4)
    bsr sim_visual_random
    and.w #$ff,d0
    add.w #32,d0
    move.w d0,-7638(a4)
    bsr sim_visual_random
    and.w #$7f,d0
    move.w d0,-7636(a4)
    move.l -14786(a4),-7634(a4)
    clr.l -7630(a4)
    move.w #5,-7626(a4)
.animate
    move.w -7626(a4),d2
    beq.b .done
    subq.w #2,-7636(a4)
    subq.w #1,-7626(a4)
    cmp.w #3,d2
    bge.b .done
    cmp.w #1,d2
    beq.b .final_shape
    move.l -14782(a4),-7634(a4)
    bra.b .done
.final_shape
    bsr sim_visual_random
    and.w #3,d0
    lsl.w #2,d0
    lea -14778(a4),a0
    move.l (a0,d0.w),-7634(a4)
.done
    rts
sim_visual_random:
    lea sim_visual_seed(pc),a0
    moveq #0,d0
    move.w (a0),d0
    mulu.w #6907,d0
    add.l #130253,d0
    move.w d0,(a0)
    rts

sim_draw_event:
    tst.w -7640(a4)
    beq.b .done
    movem.l d0-d3/a0-a2,-(sp)
    move.w #117,-18556(a4)
    lea -7638(a4),a2
    move.w (a2)+,d0
    move.w (a2)+,d1
    move.l (a2)+,a0
    suba.l a1,a1
    jsr -32148(a4)
    movem.l (sp)+,d0-d3/a0-a2
.done
    rts

sim_test_phase:
    move.l a0,-(sp)
    lea sim_phase(pc),a0
    tst.w (a0)
    movem.l (sp)+,a0
    rts
sim_test_active:
    move.l a0,-(sp)
    lea sim_code(pc),a0
    tst.l (a0)
    movem.l (sp)+,a0
    rts


; An original gear command returns before the player's physics/motion for
; that whole six-field step. Preserve that 120 ms hold, not just one 20 ms tick.
sim_gear_hold:
    movem.l d0/a0,-(sp)
    move.l -17216(a4),d0
    addq.l #6,d0
    lea sim_player_hold_until(pc),a0
    move.l d0,(a0)
    movem.l (sp)+,d0/a0
    clr.w -13446(a4)
    move.w #7,-12672(a4)     ; displaced command-handler prefix
    rts
sim_controller_hold:
    movem.l d0/a0,-(sp)
    move.l sim_player_hold_until(pc),d0
    sub.l -17216(a4),d0
    bgt.b .hold
    movem.l (sp)+,d0/a0
    clr.w -13446(a4)
    cmp.w #4,-14912(a4)      ; displaced controller prefix; CCR feeds branch
    rts
.hold
    movem.l (sp)+,d0/a0
    addq.l #4,sp             ; discard the hook return, then return to its caller
    rts

 ; Gear selection and lever/clutch travel count original steps, not fields.
; Keep that bookkeeping at six fields while motion and controls run every field.
sim_auto_gear:
    bsr sim_test_phase
    beq.b .original
    add.l #$38,(sp)          ; JSRed return is site+6, not site+8; skip automatic decisions to duel:0af6c
    rts
.original
    move.w -17200(a4),d0
    cmp.w -13188(a4),d0
    rts
sim_gear_update:
    bsr sim_test_phase
    bne.b .tail
    bsr sim_original_gear
.tail
    jsr -32754(a4)          ; displaced next call
    rts
sim_original_gear:
    move.l sim_code(pc),-(sp)
    add.l #$623e,(sp)
    rts

; Continuous speed changes share one signed carry; impulses remain unscaled.
sim_clutch_brake:
    movem.l d0/a0,-(sp)
    move.l #-352256,d0
    bra.b sim_speed_rate
sim_assisted_clutch:
    movem.l d0/a0,-(sp)
    move.l #-851968,d0
    bra.b sim_speed_rate
sim_neutral_drag:
    movem.l d0/a0,-(sp)
    move.l #-32768,d0
    bra.b sim_speed_rate
sim_fuel_drag:
    movem.l d0/a0,-(sp)
    move.l #-32768,d0
    bra.b sim_speed_rate
sim_brake:
    movem.l d0/a0,-(sp)
    move.l #-278528,d0
    bra.b sim_speed_rate
sim_assisted_brake:
    movem.l d0/a0,-(sp)
    move.l #-786432,d0
    bra.b sim_speed_rate
sim_scrub:
    movem.l d0/a0,-(sp)
    move.l #-88064,d0
sim_speed_rate:             ; d0 = rate; the hook saved d0/a0
    lea sim_speed_frac(pc),a0
    bsr sim_scale_long
    bsr sim_record_force
    add.l d0,-13282(a4)
    movem.l (sp)+,d0/a0
    rts
sim_free_rpm:
    movem.l d0/a0,-(sp)
    tst.w -13038(a4)
    beq.b .free
    ; Original clutch map is rpm' = (15/16)*rpm + 700. Its n-th-root
    ; affine map needs 700*(1-rho^(1/n))/(1-rho), not simply 700/n.
    lea sim_clutch_rise_frac(pc),a0
    move.l sim_q_rise(pc),d0 ; Q16: 700 * 16 * sim_q_clutch per step
    add.l (a0),d0
    move.w d0,2(a0)
    clr.w (a0)
    swap d0
    add.w d0,-13188(a4)
    bra.b .done
.free
    move.l #700,d0
    lea sim_rpm_frac(pc),a0
    bsr sim_scale_long
    add.w d0,-13188(a4)
.done
    movem.l (sp)+,d0/a0
    rts

sim_centre_limit:
    movem.l d0/a0,-(sp)
    moveq #20,d0
    lea sim_centre_frac(pc),a0
    bsr sim_scale_long
    move.w d0,d1
    movem.l (sp)+,d0/a0
    cmp.w d2,d1
    rts
sim_return_limit:
    movem.l d0/a0,-(sp)
    moveq #20,d0
    lea sim_centre_frac(pc),a0
    bsr sim_scale_long
    move.w d0,d1
    movem.l (sp)+,d0/a0
    cmp.w d0,d1
    rts

sim_effect_phase:
    move.l a0,-(sp)
    lsr.l #5,d0
    lea sim_effect_frac(pc),a0
    bsr sim_scale_long
    move.l (sp)+,a0
    add.l d0,-14970(a4)
    rts
sim_ai_stop:
    movem.l d0/a0,-(sp)
    move.l #-6144,d0
    bra.b sim_ai_speed_rate
sim_ai_pursuit:
    move.l a0,-(sp)
    move.l #-1536,d0
    bra.b sim_ai_brake_rate
sim_ai_brake:
    move.l a0,-(sp)
    move.l #-2432,d0
sim_ai_brake_rate:          ; d0 = rate; returns its magnitude, the hook saved a0
    bsr sim_ai_scale_speed
    neg.l d0
    move.l (sp)+,a0
    rts
sim_ai_curve:
    movem.l d0/a0,-(sp)
    move.l #-1024,d0
    bra.b sim_ai_speed_rate
sim_police_brake:
    movem.l d0/a0,-(sp)
    move.l #-1536,d0
    bra.b sim_ai_speed_rate
sim_police_accel:
    movem.l d0/a0,-(sp)
    move.l #1536,d0
sim_ai_speed_rate:          ; d0 = rate; the hook saved d0/a0
    bsr sim_ai_scale_speed
    add.l d0,10(a5)
    movem.l (sp)+,d0/a0
    rts
sim_heading_decay:
    movem.l d0/a0-a1,-(sp)
    move.w sim_q_heading(pc),d0 ; Q16 1-(7/8)^(1/n)
    lea sim_heading_decay_frac(pc),a0
    lea -13390(a4),a1
    bra.b sim_relax
sim_yaw_decay:
    movem.l d0/a0-a1,-(sp)
    move.w sim_q_yaw(pc),d0  ; Q16 1-(3/4)^(1/n)
    lea sim_yaw_decay_frac(pc),a0
    lea -9862(a4),a1
    bra.b sim_relax
sim_clutch_decay:
    movem.l d0/a0-a1,-(sp)
    move.w sim_q_clutch(pc),d0 ; Q16 1-(15/16)^(1/n)
    lea sim_clutch_decay_frac(pc),a0
    lea -13188(a4),a1
; (a1) -= d0 * (a1) in Q16, carrying the fraction in the low word at a0.
sim_relax:
    muls.w (a1),d0
    add.l (a0),d0
    move.w d0,2(a0)
    clr.w (a0)
    swap d0
    sub.w d0,(a1)
    movem.l (sp)+,d0/a0-a1
    rts

sim_rates:
sim_speed_frac: dc.w 0
sim_distance_frac: dc.w 0
sim_yaw_frac: dc.w 0
sim_heat_frac: dc.w 0
sim_dashboard_frac: dc.w 0
sim_traffic_forward_frac: dc.w 0
sim_traffic_oncoming_frac: dc.w 0
sim_verge_frac: dc.w 0
sim_rpm_frac: dc.w 0
sim_centre_frac: dc.w 0
sim_effect_frac: dc.w 0
sim_background_frac: dcb.w 4,0
sim_ai_rates: dcb.b 56,0
sim_player_hold_until: dc.l 0
sim_tick_force: dc.l 0
sim_prev_force: dc.l 0
sim_heading_decay_frac: dc.l 0
sim_yaw_decay_frac: dc.l 0
sim_clutch_decay_frac: dc.l 0
sim_clutch_rise_frac: dc.l 0
SIM_RATE_WORDS equ (*-sim_rates)/2

sim_phase: dc.w 5
sim_visual_seed: dc.w 0
sim_fractions:
sim_player_time_frac: dc.w 0
sim_opponent_time_frac: dc.w 0
sim_player_sum_frac: dc.w 0
sim_opponent_sum_frac: dc.w 0
sim_gear_value: dc.w 0
sim_gear_field: dc.l 0
sim_code: dc.l 0
; Period parameters, copied from sim_periods by sim_configure (68000 / 68020+).
; The defaults (one-field steps, sim_n = 6) are what the VERIFY unit checks use.
sim_p: dc.w 1                 ; fields per step
sim_n: dc.w 6                 ; steps per original six-field step
sim_q_heading: dc.w 1442
sim_q_yaw: dc.w 3068
sim_q_clutch: dc.w 701
sim_q_rise: dc.l 7851200
SIM_PERIOD_SIZE equ *-sim_p
sim_periods:
    dc.w 6,1,8192,16384,4096  ; 68000: the original step
    dc.l 45875200
    dc.w 2,3,2853,5993,1395   ; 68020+: a third of it
    dc.l 15624000

; Read only v1 options. Control fills tag values; render_options becomes the
; internal feature mask (bits 0-2), all set when CUSTOM2 is nonzero.
sim_tags:
    dc.l WHDLTAG_CUSTOM2_GET
render_options: dc.l 0
    dc.l WHDLTAG_CUSTOM1_GET
sim_trainer: dc.l 0
    dc.l WHDLTAG_ATTNFLAGS_GET
sim_attn: dc.l 0
    IFD VERIFY
    dc.l WHDLTAG_CUSTOM5_GET
sim_drive_enabled: dc.l 0
    ENDC
    dc.l 0

    IFD VERIFY
sim_epoch: dc.l 0
; Actual joystick decoding and normal player physics consume this field-based
; tape. It starts after the race anchor; no debugger writes are involved.
verify_original_begin:
    movem.l d0-d2/a0,-(sp)
    bsr verify_drive_mode
    movem.l (sp)+,d0-d2/a0
    tst.w -17282(a4)
    bne.b .demo
    add.l #$92,(sp)
.demo
    rts
verify_drive_mode:
    move.l sim_drive_enabled(pc),d0
    btst #0,d0
    beq.b .done
    clr.w -17282(a4)           ; play the first race, rather than borrow demo AI
    clr.w -12(a5)              ; also clear the race frame's cached attract flag
    move.l d0,d1
    move.l -17216(a4),d0
    sub.l sim_epoch(pc),d0
    btst #2,d1
    beq.b .heat
    cmp.l #900,d0
    bne.b .heat
    move.w #17,-14916(a4)      ; exercise original fatal-race path once
.heat
    btst #1,d1
    beq.b .done
    cmp.l #450,d0
    bne.b .done
    move.w #1,-12938(a4)       ; exercise actual engine-damage recovery once
.done
    rts
verify_read_joydat:
    bsr read_joydat
    movem.l d1/a0,-(sp)
    move.l sim_drive_enabled(pc),d1
    btst #0,d1
    beq .done
    bsr sim_test_active
    beq .done
    move.l -17216(a4),d1
    sub.l sim_epoch(pc),d1
    move.l sim_drive_enabled(pc),d0
    btst #4,d0
    beq.b .steer_tape
    move.w #$0100,d0
    cmp.l #400,d1
    bcs .done
    cmp.l #600,d1
    bcc.b .straight_coast
    moveq #1,d0
    bra .done
.straight_coast
    cmp.l #800,d1
    bcc .done
    moveq #0,d0
    bra .done
.steer_tape
    move.w #$0100,d0           ; accelerate, including from idle
    cmp.l #100,d1
    bcs .done
    cmp.l #106,d1
    bcc.b .right
    move.w #$0200,d0           ; up + left
    bra .done
.right
    cmp.l #112,d1
    bcc.b .brake
    move.w #$0103,d0           ; up + right
    bra .done
.brake
    cmp.l #200,d1
    bcs .done
    cmp.l #300,d1
    bcc.b .coast
    moveq #1,d0               ; brake
    bra .done
.coast
    cmp.l #400,d1
    bcc .done
    moveq #0,d0               ; neutral joystick/coast
.done
    movem.l (sp)+,d1/a0
    rts
    ENDC

    IFD VERIFY
    include "simulation-verify.s"
    ENDC
