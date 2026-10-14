; Private arithmetic tests; game memory is never used as scratch.
verify_simulation_units:
    movem.l d0-a6,-(sp)
    lea verify_sim_results(pc),a3
    clr.l (a3)+
    clr.l (a3)
    lea sim_n(pc),a1
    move.w #3,(a1)
    lea verify_sim_rates(pc),a2
    moveq #11,d6
.vector
    lea sim_speed_frac(pc),a0
    clr.w (a0)
    moveq #0,d4
    moveq #2,d7
.three
    move.l (a2),d0
    bsr sim_scale_long
    add.l d0,d4
    dbf d7,.three
    move.l d4,d0
    move.l (a2)+,d1
    bsr verify_sim_equal
    moveq #0,d0
    move.w (a0),d0
    moveq #0,d1
    bsr verify_sim_equal
    dbf d6,.vector
    ; Exercise the installed GPC wrappers on private, cleared data, never the
    ; loaded game's live state. Enough space covers signed a4 offsets and BSS.
    move.l #65536,d0
    move.l #$10001,d1
    move.l $4.w,a6
    jsr _LVOAllocMem(a6)
    tst.l d0
    bne.b .allocated
    moveq #1,d1
    bsr verify_sim_equal
    bra .sentinel_test
.allocated
    move.l d0,a4
    adda.l #32766,a4
    ; New race setup must hold simulation until native $707a unpauses it.
    ; A pit screen reset, in contrast, preserves the running phase/carries.
    lea sim_p(pc),a0
    move.w #2,(a0)
    bsr sim_start
    moveq #0,d0
    move.w -31736(a4),d0
    swap d0
    move.w -29928(a4),d0
    move.l #$00010002,d1
    bsr verify_sim_equal
    moveq #0,d0
    move.w sim_phase(pc),d0
    moveq #0,d1
    bsr verify_sim_equal
    move.w #1,4020(a4)
    move.w #1,-29928(a4)
    lea sim_phase(pc),a0
    move.w #2,(a0)
    lea sim_speed_frac(pc),a0
    move.w #1,(a0)
    bsr sim_start
    moveq #0,d0
    move.w sim_phase(pc),d0
    swap d0
    move.w sim_speed_frac(pc),d0
    move.l #$00020001,d1
    bsr verify_sim_equal
    moveq #0,d0
    move.w -29928(a4),d0
    moveq #1,d1
    bsr verify_sim_equal
    lea sim_speed_frac(pc),a0
    clr.w (a0)
    lea sim_phase(pc),a0
    clr.w (a0)

    move.w #7,3718(a4)
    move.w #100,-20718(a4)
    moveq #2,d7
.heat
    bsr sim_heat
    dbf d7,.heat
    moveq #0,d0
    move.w -20718(a4),d0
    moveq #107,d1
    bsr verify_sim_equal

    move.w #6000,-29944(a4)
    moveq #0,d5
    moveq #2,d7
.motion
    bsr sim_motion
    add.l d4,d5
    dbf d7,.motion
    move.l d5,d0
    moveq #69,d1
    bsr verify_sim_equal

    ; No predicted motion after the native speed clamp has reached zero.
    clr.w -29944(a4)
    lea sim_prev_force(pc),a0
    move.l #-500,(a0)
    bsr sim_motion
    move.l d4,d0
    moveq #0,d1
    bsr verify_sim_equal
    lea sim_prev_force(pc),a0
    clr.l (a0)

    ; AI uses new speed: three v=303,306,309 substeps with dv=3 must
    ; reproduce the coarse semi-implicit displacement 300+9=309.
    moveq #2,d3
    move.w #300,-32(a4)
    moveq #0,d5
    moveq #2,d7
.ai_motion
    addq.w #3,-32(a4)
    lea sim_ai_force_value(pc),a0
    move.w #3,2(a0)
    lea -34(a4),a0
    bsr sim_ai_motion
    add.l d4,d5
    dbf d7,.ai_motion
    move.l d5,d0
    move.l #309,d1
    bsr verify_sim_equal

    move.w #1024,-29522(a4)
    move.w #1024,-29528(a4)
    moveq #2,d7
.relax
    bsr verify_relax_rates
    dbf d7,.relax
    moveq #0,d0
    move.w -29522(a4),d0
    move.l #960,d1
    bsr verify_sim_near
    move.w -29528(a4),d0
    move.l #896,d1
    bsr verify_sim_near

    ; Steering feedback: three fine affine updates must reproduce the native
    ; quarter-feedback map for both signs. Use a private fake native frame.
    lea 16384(a4),a5
    clr.w -4(a5)
    move.w #1,-29524(a4)
    move.w #-1024,-29528(a4)
    bsr verify_steering_three
    move.l #-592,d1
    bsr verify_sim_near
    move.w #-1,-29524(a4)
    move.w #1024,-29528(a4)
    bsr verify_steering_three
    move.l #592,d1
    bsr verify_sim_near
    ; No active feedback: the constant input remains exactly 176 per interval.
    move.w #1,-29524(a4)
    move.w #1024,-29528(a4)
    bsr verify_steering_three
    move.l #1200,d1
    bsr verify_sim_equal
    ; Saturated force uses the linear rate, not the unconstrained root map.
    move.w #10000,-4(a5)
    move.w #-3000,-29528(a4)
    bsr verify_steering_three
    move.l #-440,d1
    bsr verify_sim_equal
    ; No-input spatial centering remains a full, once-per-crossing impulse.
    clr.w -29524(a4)
    move.w #1000,-29528(a4)
    move.w #-73,-6(a5)
    bsr sim_steer
    move.w -29528(a4),d0
    ext.l d0
    move.l #927,d1
    bsr verify_sim_equal
    ; Native period keeps the complete original update.
    lea sim_n(pc),a0
    move.w #1,(a0)
    move.w #1,-29524(a4)
    move.w #-1024,-29528(a4)
    move.w #432,-6(a5)
    bsr sim_steer
    move.w -29528(a4),d0
    ext.l d0
    move.l #-592,d1
    bsr verify_sim_equal
    lea sim_n(pc),a0
    move.w #3,(a0)

    ; RPM: the nonlinear map includes a preceding -400 and idle clamp.
    ; Three fine calls must equal one native call even from idle (800->2000).
    move.w #1,-29816(a4)
    move.w #16000,-23750(a4)
    move.w #800,-29960(a4)
    moveq #2,d7
.rpm_idle
    bsr sim_rpm_fall
    move.w d4,-29960(a4)
    bsr sim_rpm_rise
    move.w d4,-29960(a4)
    dbf d7,.rpm_idle
    moveq #0,d0
    move.w -29960(a4),d0
    move.l #2000,d1
    bsr verify_sim_equal
    move.w #3000,-29960(a4)
    moveq #2,d7
.rpm_grow
    bsr sim_rpm_fall
    move.w d4,-29960(a4)
    bsr sim_rpm_rise
    move.w d4,-29960(a4)
    dbf d7,.rpm_grow
    moveq #0,d0
    move.w -29960(a4),d0
    move.l #3912,d1
    bsr verify_sim_equal

    ; The gear-completion brake remains a full impulse, while ordinary
    ; braking sums to the same rate over three calls.
    move.w #900,-23742(a4)
    lea sim_shift_step(pc),a0
    move.w #1,(a0)
    bsr sim_brake
    move.l #900,d1
    bsr verify_sim_equal
    moveq #0,d0
    move.w sim_gear_impulse(pc),d0
    moveq #1,d1
    bsr verify_sim_equal
    lea sim_gear_impulse(pc),a0
    clr.w (a0)
    lea sim_shift_step(pc),a0
    clr.w (a0)
    moveq #0,d5
    moveq #2,d7
.braking
    bsr sim_brake
    add.w d0,d5
    dbf d7,.braking
    move.l d5,d0
    move.l #900,d1
    bsr verify_sim_equal

    moveq #0,d0
    move.w sim_gear_impulse(pc),d0
    moveq #0,d1
    bsr verify_sim_equal

    ; Torque and drag must use the same speed reference, without changing
    ; the live RPM used for gear decisions or the clutch/wheelspin paths.
    move.w #25600,-29944(a4)
    move.w #4000,-29960(a4)
    move.w #$2800,-29964(a4)
    move.w #1,-29818(a4)
    clr.w -29820(a4)
    clr.w -30022(a4)
    lea sim_prev_force(pc),a0
    move.l #80,(a0)
    lea sim_player_reference(pc),a0
    move.w #25520,(a0)
    bsr sim_torque_reference
    moveq #0,d0
    move.w d4,d0
    moveq #30,d1             ; floor(99*40 / 128)
    bsr verify_sim_equal
    move.w #1,-29820(a4)
    lea sim_rpm_reference(pc),a0
    move.w #4000,(a0)
    move.w #4266,-29960(a4)
    bsr sim_torque_reference
    moveq #0,d0
    move.w d4,d0
    moveq #31,d1
    bsr verify_sim_equal
    clr.w -29820(a4)
    move.w #4000,-29960(a4)
    move.w #6,-30022(a4)
    bsr sim_torque_reference
    moveq #0,d0
    move.w d4,d0
    moveq #31,d1
    bsr verify_sim_equal
    clr.w -30022(a4)
    lea sim_n(pc),a0
    move.w #1,(a0)
    bsr sim_torque_reference
    moveq #0,d0
    move.w d4,d0
    moveq #31,d1
    bsr verify_sim_equal
    lea sim_n(pc),a0
    move.w #3,(a0)

    move.l a4,a1
    suba.l #32766,a1
    move.l #65536,d0
    move.l $4.w,a6
    jsr _LVOFreeMem(a6)
.sentinel_test
    ; PSS pushes site+6, not the end of its padded span. A six-byte early
    ; return must hit the failure sentinel, never the clutch-shock instruction.
    lea sim_phase(pc),a0
    move.w #2,(a0)
    bsr sim_gear_motion
.return
    dcb.w ($84-6)/2,$4e71
    moveq #1,d0
    bra.b .sentinel
    nop
.expected
    moveq #0,d0
.sentinel
    moveq #0,d1
    bsr verify_sim_equal
    lea sim_phase(pc),a0
    clr.w (a0)
    lea sim_n(pc),a1
    move.w #1,(a1)
    lea sim_rates(pc),a0
    move.w #SIM_RATE_WORDS-1,d0
.clear
    clr.w (a0)+
    dbf d0,.clear
    lea sim_speed_frac(pc),a0
    clr.w (a0)
    movem.l (sp)+,d0-a6
    rts
verify_sim_equal:
    lea verify_sim_results(pc),a3
    addq.l #1,(a3)
    cmp.l d1,d0
    beq.b .done
    addq.l #1,4(a3)
.done
    rts
verify_sim_near:
    sub.l d1,d0
    bpl.b .positive
    neg.l d0
.positive
    cmp.l #1,d0
    bls.b .pass
    moveq #1,d0
    bra.b .check
.pass
    moveq #0,d0
.check
    moveq #0,d1
    bra verify_sim_equal
verify_sim_results:
    dc.l 0,0
verify_sim_rates:
    dc.l 0,1,-1,2,-2,3,-3,32767,-32768,$7fffffff,$80000000,$12345678

; Exercise the unchanged root-relaxation kernel on private values. GPC's
; moving/straight relaxation is segment-conditioned, so production retains the
; native full impulse at the actual segment crossing, not these time roots.
verify_relax_rates:
    bsr.b .yaw
    movem.l d0/a0-a1,-(sp)
    move.w #2853,d0
    lea sim_steer_decay_frac(pc),a0
    lea -29528(a4),a1
    bra sim_relax
.yaw
    movem.l d0/a0-a1,-(sp)
    move.w #1395,d0
    lea sim_yaw_decay_frac(pc),a0
    lea -29522(a4),a1
    bra sim_relax

; Reconstruct the intact native input/quarter-feedback expression on the private
; fixture. The installed wrapper alone handles rate conversion and carry.
verify_steering_three:
    lea sim_feedback_frac(pc),a0
    clr.l (a0)
    lea sim_steer_frac(pc),a0
    clr.w (a0)
    moveq #2,d7
.loop
    move.w -29524(a4),d0
    muls.w #176,d0
    move.w -29528(a4),d1
    sub.w -4(a5),d1
    tst.w -29524(a4)
    bmi.b .negative
    tst.w d1
    blt.b .feedback
    bra.b .clamp
.negative
    tst.w d1
    ble.b .clamp
.feedback
    asr.w #2,d1
    sub.w d1,d0
.clamp
    cmp.w #2560,d0
    ble.b .low
    move.w #2560,d0
.low
    cmp.w #-2560,d0
    bge.b .call
    move.w #-2560,d0
.call
    move.w d0,-6(a5)
    bsr sim_steer
    dbf d7,.loop
    move.w -29528(a4),d0
    ext.l d0
    rts
