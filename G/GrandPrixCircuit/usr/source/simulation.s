; v1 higher-rate simulation. Only the size-checked CUSTOM2 path installs these hooks.
; Arithmetic kernels below are unchanged from Test Drive 2. GPC uses word speeds,
; explicit (old-speed) player integration and ten indexed AI slots.

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


sim_relax:
    muls.w (a1),d0
    add.l (a0),d0
    move.w d0,2(a0)
    clr.w (a0)
    swap d0
    sub.w d0,(a1)
    movem.l (sp)+,d0/a0-a1
    rts

; Call an intact native routine. Its callers here permit a0 to be scratched.
SIM_BOUNDARY: MACRO
    movem.l d0,-(sp)
    move.w sim_phase(pc),d0
    movem.l (sp)+,d0
    ENDM

SIM_AI_INTERVAL: MACRO
    movem.l d0-d1,-(sp)
    move.w sim_phase(pc),d0
    move.w sim_n(pc),d1
    subq.w #1,d1             ; first fine step: 2 for n=3, 0 for native n=1
    cmp.w d1,d0
    movem.l (sp)+,d0-d1
    ENDM

GPC_CALL: MACRO
    move.l sim_code(pc),a0
    adda.l #\1,a0
    jsr (a0)
    ENDM

sim_configure:
    IFD VERIFY
    bsr verify_simulation_units
    bsr verify_render_units
    ENDC
    lea sim_p(pc),a0
    move.w #6,(a0)
    move.w #1,sim_n-sim_p(a0)
    move.l attnflags(pc),d0
    btst #AFB_68020,d0
    beq.b .done
    IFD VERIFY
    move.l sim_verify_options(pc),d0
    btst #2,d0               ; force native period with the same hooks
    bne.b .done
    ENDC
    move.w #2,(a0)
    move.w #3,sim_n-sim_p(a0)
.done
    rts

sim_patch:
    move.l custom2(pc),d0
    beq.b .done
    move.l attnflags(pc),d0
    btst #AFB_68020,d0
    beq.b .done              ; A500 retains original simulation instructions
    lea pl_simulation(pc),a0
    move.l d7,d0
    lsr.l #2,d0
    move.l d0,a1
    move.l _resload(pc),a2
    jsr resload_PatchSeg(a2)
    ; Hunk 1 initially contains period/countdown 6. Set both before the first
    ; native interrupt can run, as well as at a later new-race reset.
    ; PERF_RANGE h1:B16 4 bit=C2_020 (initial data, not executable bytes)
    move.l d7,a0
    move.l (a0),d0
    lsl.l #2,d0
    move.l d0,a0
    move.w sim_p(pc),d0
    move.w d0,4+$b16(a0)
    move.w d0,4+$b18(a0)
.done
    rts

pl_simulation:
    PL_START
    PL_PS $7488,sim_start          ; PERF_RANGE h0:7488 6 bit=C2_020
    PL_PS $7754,sim_begin          ; PERF_RANGE h0:7754 6 bit=C2_020
    PL_PSS $782e,sim_counters,10    ; PERF_RANGE h0:782E 16 bit=C2_020
    PL_PSS $783e,sim_controls,4    ; PERF_RANGE h0:783E 10 bit=C2_020
    PL_PSS $784c,sim_input,2       ; PERF_RANGE h0:784C 8 bit=C2_020
    PL_PS $7864,sim_statistics     ; PERF_RANGE h0:7864 6 bit=C2_020
    PL_PSS $7b44,sim_wheelspin,4   ; PERF_RANGE h0:7B44 10 bit=C2_020
    PL_PSS $7e34,sim_motion,8      ; PERF_RANGE h0:7E34 14 bit=C2_020
    PL_PSS $7e7c,sim_gear_motion,6 ; PERF_RANGE h0:7E7C 12 bit=C2_020
    PL_PSS $7784,sim_heat,2        ; PERF_RANGE h0:7784 8 bit=C2_020
    PL_PS $77a4,sim_overheat       ; PERF_RANGE h0:77A4 6 bit=C2_020
    PL_PSS $8030,sim_crash,2       ; PERF_RANGE h0:8030 8 bit=C2_020
    PL_PSS $8042,sim_crash,2       ; PERF_RANGE h0:8042 8 bit=C2_020
    PL_PSS $8058,sim_skid,2        ; PERF_RANGE h0:8058 8 bit=C2_020
    PL_PSS $803a,sim_collision_yaw,2 ; PERF_RANGE h0:803A 8 bit=C2_020
    PL_PSS $7fba,sim_force,2       ; PERF_RANGE h0:7FBA 8 bit=C2_020
    PL_PSS $7f66,sim_brake,2       ; PERF_RANGE h0:7F66 8 bit=C2_020
    PL_PSS $7f16,sim_rpm_fall,2    ; PERF_RANGE h0:7F16 8 bit=C2_020
    PL_PSS $7f44,sim_rpm_rise,8    ; PERF_RANGE h0:7F44 14 bit=C2_020
    PL_PS $7f90,sim_rpm_spin       ; PERF_RANGE h0:7F90 6 bit=C2_020
    PL_PSS $69c6,sim_steer,2       ; PERF_RANGE h0:69C6 8 bit=C2_020
    PL_PSS $7934,sim_gear_and_steering,2 ; PERF_RANGE h0:7934 8 bit=C2_020
    PL_PS $7e5e,sim_crossed_segment ; PERF_RANGE h0:7E5E 6 bit=C2_020
    PL_PSS $806e,sim_torque_reference,2 ; PERF_RANGE h0:806E 8 bit=C2_020
    PL_PS $7f9a,sim_drag_reference ; PERF_RANGE h0:7F9A 6 bit=C2_020
    PL_PS $a226,sim_ai_reference ; PERF_RANGE h0:A226 6 bit=C2_020
    PL_PSS $689a,sim_spin,2        ; PERF_RANGE h0:689A 8 bit=C2_020
    PL_PSS $a2b4,sim_ai_update,6    ; PERF_RANGE h0:A2B4 12 bit=C2_020
    PL_PSS $a23e,sim_ai_force,2    ; PERF_RANGE h0:A23E 8 bit=C2_020
    PL_P $a270,sim_ai_target       ; PERF_RANGE h0:A270 16 bit=C2_020
    PL_PS $a2c4,sim_ai_motion      ; PERF_RANGE h0:A2C4 6 bit=C2_020
    PL_PSS $a182,sim_ai_left,10    ; PERF_RANGE h0:A182 16 bit=C2_020
    PL_PSS $a194,sim_ai_right,10   ; PERF_RANGE h0:A194 16 bit=C2_020
    PL_PSS $a32e,sim_ai_order,6    ; PERF_RANGE h0:A32E 12 bit=C2_020
    PL_PS $a37c,sim_collision_phase ; PERF_RANGE h0:A37C 6 bit=C2_020
    PL_END

sim_start:
    ; $7482 is also the pit-return screen reset. Its native countdown keeps
    ; running through service: do not discard phase or AI carries on return.
    tst.w 4020(a4)
    bne.b .resume
    ; Grid initialisation reads slot 0 back into the player state. A fine VBL
    ; must not overwrite that half-built slot with the old player proxy.
    ; The existing $707a releases this gate after complete race setup; the
    ; native field/audio interrupt remains live throughout.
    move.w #1,-31736(a4)
    movem.l d0/a0,-(sp)
    lea sim_rates(pc),a0
    move.w #SIM_RATE_WORDS-1,d0
.clear
    clr.w (a0)+
    dbf d0,.clear
    lea sim_phase(pc),a0
    clr.w (a0)
    move.w sim_p(pc),d0
    move.w d0,-29926(a4)
    move.w d0,-29928(a4)
    movem.l (sp)+,d0/a0
.resume
    move.w #100,-29930(a4)
    rts

sim_begin:
    movem.l d0/a0,-(sp)
    lea sim_phase(pc),a0
    move.w sim_p(pc),d0
    add.w d0,(a0)
    cmp.w #6,(a0)
    bcs.b .phase
    clr.w (a0)
.phase
    tst.w (a0)
    bne.b .keep_gear_impulse
    clr.w sim_gear_impulse-sim_phase(a0)
.keep_gear_impulse
    lea sim_tick_force(pc),a0
    move.l (a0),sim_prev_force-sim_tick_force(a0)
    clr.l (a0)
    lea sim_shift_step(pc),a0
    clr.w (a0)
    movem.l (sp)+,d0/a0
    GPC_CALL $776a            ; d0 is the period: native cooling consumes it
    movem.l d0/a0,-(sp)
    lea sim_before_force(pc),a0
    move.l sim_tick_force(pc),d0
    move.l d0,(a0)
    SIM_BOUNDARY
    bne.b .held_reference
    move.w -29944(a4),d0
    lea sim_player_reference(pc),a0
    move.w d0,(a0)
.held_reference
    movem.l (sp)+,d0/a0
    jsr -32514(a4)
    rts

sim_counters:
    SIM_BOUNDARY
    bne.b .done
    addq.w #8,-2014(a4)
    cmp.w #7,-29942(a4)
    beq.b .done
    addq.w #1,4024(a4)
.done
    rts
sim_controls:
    clr.w d1
    SIM_BOUNDARY
    bne.b .done
    move.w d1,-29816(a4)
    move.w d1,-29524(a4)
.done
    rts
sim_input:
    SIM_BOUNDARY
    bne.b .steering
    GPC_CALL $786c
    bra.b .done
.steering
    bsr sim_steering_update
.done
    ; Gear completion replaces this interval's engine-force update entirely.
    ; Do not add two coast/acceleration updates after the one-off impulse.
    movem.l d0,-(sp)
    move.w sim_gear_impulse(pc),d0
    movem.l (sp)+,d0
    bne.b .skip_force
    cmp.w #0,-29940(a4)
.skip_force
    rts
sim_statistics:
    SIM_BOUNDARY
    bne.b .done
    move.w 4(sp),-(sp)        ; original C argument below our return address
    jsr -32682(a4)
    addq.w #2,sp
.done
    move.l (sp),d0           ; consume displaced ADDQ #2 without losing return
    move.l d0,2(sp)
    addq.w #2,sp
    rts
sim_wheelspin:
    SIM_BOUNDARY
    bne.b .copy
    subq.w #1,-30022(a4)
.copy
    move.w -30022(a4),-30554(a4)
    rts
sim_gear_motion:
    SIM_BOUNDARY
    bne.b .skip
    move.l a0,-(sp)
    lea sim_shift_step(pc),a0
    move.w #1,(a0)
    move.l (sp)+,a0
    move.w #1,-29950(a4)
    move.w #1,-29924(a4)
    rts
.skip
    add.l #$7f06-$7e82,(sp) ; PSS return is site+6, before its padding NOPs
    rts

; Old-speed integration uses the opposite Euler correction from TD2's
; semi-implicit integrator. Keep the native quantisation before dividing time.
sim_motion:
    movem.l d0-d2/a0,-(sp)
    moveq #0,d0
    move.w -29944(a4),d0
    beq.b .distance
    move.l sim_prev_force(pc),d1
    neg.l d1
    bsr sim_euler_velocity
    lsr.l #1,d0
    move.l d0,d2
    move.l sim_before_force(pc),d1
    bsr sim_times_n_minus_1
    add.l d2,d0              ; thermal force is BEFORE motion, unlike post-force
    bpl.b .forward
    moveq #0,d0
.forward
    lsr.w #7,d0
    move.w d0,d1
    lsr.w #1,d0
    add.w d1,d0
.distance
    lea sim_distance_frac(pc),a0
    bsr sim_scale_long
    move.l d0,d4
    move.w d0,d6
    movem.l (sp)+,d0-d2/a0
    rts

; Signed word rate in d0; every producer owns a carry. Spatial impulses never
; call these helpers. Record continuous speed changes for explicit integration.
sim_scale_word:
    ext.l d0
    bra sim_scale_long
sim_record_force:
    move.l a0,-(sp)
    lea sim_tick_force(pc),a0
    add.l d0,(a0)
    move.l (sp)+,a0
    rts
sim_force:
    move.l a0,-(sp)
    asr.w #3,d0
    lea sim_speed_frac(pc),a0
    bsr sim_scale_word
    bsr sim_record_force
    move.l (sp)+,a0
    add.w d0,d4
    move.w d4,-29944(a4)
    rts
sim_brake:
    ; The branch from $7f04 is a once-only gear-completion impulse. Normal
    ; throttle braking is a rate; sharing the native code does not make the
    ; gear impulse a rate too.
    move.w sim_shift_step(pc),d0
    beq.b .rate
    tst.w -29814(a4)
    bne.b .rate
    move.l a0,-(sp)
    lea sim_gear_impulse(pc),a0
    move.w #1,(a0)
    move.l (sp)+,a0
    move.w -23742(a4),d0
    move.w -29944(a4),d4
    rts
.rate
    move.l a0,-(sp)
    moveq #0,d0
    move.w -23742(a4),d0
    neg.l d0
    lea sim_speed_frac(pc),a0
    bsr sim_scale_long
    bsr sim_record_deceleration
    neg.w d0
    move.l (sp)+,a0
    move.w -29944(a4),d4
    rts
; d0 is a requested negative rate. The native zero-speed clamp may apply
; less: record that actual change, but return the original request to native
; arithmetic. Otherwise previous-force correction makes a stopped car creep.
sim_record_deceleration:
    movem.l d0-d1,-(sp)
    moveq #0,d1
    move.w -29944(a4),d1
    neg.l d1
    cmp.l d1,d0
    bge.b .actual
    move.l d1,d0
.actual
    bsr sim_record_force
    movem.l (sp)+,d0-d1
    rts
sim_heat:
    movem.l d0/a0,-(sp)
    move.w 3718(a4),d0
    lea sim_heat_frac(pc),a0
    bsr sim_scale_word
    move.w d0,d4
    movem.l (sp)+,d0/a0
    add.w d4,-20718(a4)
    rts
sim_overheat:
    move.w #768,d4
    bra.b sim_decelerate
sim_crash:
    move.w #1280,d4
    bra.b sim_decelerate
sim_skid:
    move.w #1536,d4
sim_decelerate:
    move.l d0,-(sp)
    move.w d4,d0
    ext.l d0
    neg.l d0
    lea sim_speed_frac(pc),a0
    bsr sim_scale_long
    bsr sim_record_deceleration
    neg.w d0
    move.w d0,d4
    move.l (sp)+,d0
    GPC_CALL $77c0
    rts
sim_collision_yaw:
    movem.l d0/a0,-(sp)
    move.w -29968(a4),d0
    lea sim_yaw_frac(pc),a0
    bsr sim_scale_word
    move.w d0,d4
    movem.l (sp)+,d0/a0
    add.w d4,-29522(a4)
    rts

sim_rpm_fall:
    movem.l d0/a0,-(sp)
    tst.w -29818(a4)
    bne.b .fall
    tst.w -29816(a4)
    ble.b .fall
    ; Neutral throttle combines fall, idle clamp and nonlinear rise. Applying
    ; those separately at each substep changes the native affine map at idle.
    move.w -29960(a4),d4
    bra.b .done
.fall
    SIM_BOUNDARY
    bne.b .rpm_reference_ready
    move.w -29960(a4),d0
    sub.w #400,d0
    cmp.w #800,d0
    bge.b .rpm_reference_store
    move.w #800,d0
.rpm_reference_store
    lea sim_rpm_reference(pc),a0
    move.w d0,(a0)
.rpm_reference_ready
    lea sim_free_rpm_left(pc),a0
    clr.w (a0)
    move.l #-400,d0
    lea sim_rpm_frac(pc),a0
    bsr sim_scale_long
    move.w -29960(a4),d4
    add.w d0,d4
.done
    movem.l (sp)+,d0/a0
    rts
sim_rpm_rise:
    movem.l d0-d1/a0,-(sp)
    lea sim_free_rpm_left(pc),a0
    tst.w (a0)
    bne.b .advance
    move.w sim_n(pc),(a0)
    move.w -29960(a4),d0
    sub.w #400,d0
    cmp.w #800,d0
    bge.b .idle
    move.w #800,d0
.idle
    move.w d0,d1
    lsr.w #4,d1
    add.w #1150,d0
    add.w d1,d0
    cmp.w -23750(a4),d0
    ble.b .limit
    move.w -23750(a4),d0
.limit
    sub.w -29960(a4),d0
    move.w d0,sim_free_rpm_rate-sim_free_rpm_left(a0)
    clr.w sim_free_rpm_frac-sim_free_rpm_left(a0)
.advance
    subq.w #1,(a0)
    move.w sim_free_rpm_rate(pc),d0
    lea sim_free_rpm_frac(pc),a0
    bsr sim_scale_word
    move.w -29960(a4),d4
    add.w d0,d4
    movem.l (sp)+,d0-d1/a0
    rts
sim_rpm_spin:
    movem.l d0/a0,-(sp)
    moveq #40,d0
    lea sim_rpm_frac(pc),a0
    bsr sim_scale_long
    add.w d0,-29960(a4)
    movem.l (sp)+,d0/a0
    rts
sim_steer:
    movem.l d1/a0,-(sp)
    move.w -6(a5),d0
    move.w sim_n(pc),d1
    cmp.w #1,d1
    beq.b .apply
    move.w -29524(a4),d1
    beq.b .apply             ; per-crossing centering is an impulse
    bmi.b .negative
    move.w -29528(a4),d1
    cmp.w -4(a5),d1
    blt.b .feedback
    bra.b .linear
.negative
    move.w -29528(a4),d1
    cmp.w -4(a5),d1
    ble.b .linear
.feedback
    cmp.w #2560,d0
    bge.b .linear
    cmp.w #-2560,d0
    ble.b .linear
    ; Native active feedback is x += 176*u + (target-x)/4. Its
    ; third-root map scales that complete delta by 4*(1-cuberoot(3/4)),
    ; not 1/3. Preserve the fractional part across fine steps.
    muls.w #23970,d0
    lea sim_feedback_frac(pc),a0
    add.l (a0),d0
    move.w d0,2(a0)
    clr.w (a0)
    swap d0
    bra.b .apply
.linear
    lea sim_steer_frac(pc),a0
    bsr sim_scale_word
.apply
    movem.l (sp)+,d1/a0
    add.w d0,-29528(a4)
    rts
; A segment-conditioned spin is one impulse per native decision interval,
; not a rate to divide on the (possibly only one) substep which crosses a segment.
sim_spin:
    SIM_BOUNDARY
    bne.b .done
    muls.w #7680,d0
    add.w d0,-29522(a4)
.done
    rts
sim_crossed_segment:
    move.l a0,-(sp)
    lea sim_crossed(pc),a0
    move.w #1,(a0)
    move.l (sp)+,a0
    move.w #1,-29802(a4)
    rts
sim_gear_and_steering:
    GPC_CALL $7c04
sim_steering_update:
    movem.l d2/a1,-(sp)
    move.w -29802(a4),d2
    lea sim_crossed(pc),a1
    ; Ordinary centering follows the actual segment crossing. Spin is a
    ; discrete native-interval impulse: remember crossings in earlier fine
    ; steps so it still fires exactly once at the six-field boundary.
    tst.w -30610(a4)
    beq.b .call
    SIM_BOUNDARY
    bne.b .call
    tst.w (a1)
    beq.b .call
    move.w #1,-29802(a4)
.call
    GPC_CALL $6854
    move.w d2,-29802(a4)
    SIM_BOUNDARY
    bne.b .done
    clr.w (a1)
.done
    movem.l (sp)+,d2/a1
    rts

; GPC quantises both RPM torque and drag into lookup-table bins. Re-evaluating
; an extrapolated reference on every fine step crosses those bins at different
; times and drifts even on a straight. Hold the native interval-start reference
; for both tables; live speed still advances each fine step and drives thresholds.
sim_force_reference:
    moveq #0,d0
    move.w sim_n(pc),d0
    cmp.w #1,d0
    beq.b .native
    move.w sim_player_reference(pc),d0
    rts
.native
    move.w -29944(a4),d0
    rts
sim_torque_reference:
    move.w -29960(a4),d4
    movem.l d0-d1,-(sp)
    move.w sim_n(pc),d0
    cmp.w #1,d0
    beq.b .native
    tst.w -29818(a4)
    beq.b .native
    cmp.w #1,-29820(a4)
    bne.b .engaged
    cmp.w #5,-30022(a4)
    bgt.b .native
    move.w sim_rpm_reference(pc),d4
    bra.b .native
.engaged
    cmp.w #5,-30022(a4)
    bgt.b .native
    bsr sim_force_reference
    lsr.l #8,d0
    moveq #0,d1
    move.b -29964(a4),d1
    mulu.w d1,d0
    cmp.l #800,d0
    bge.b .idle
    move.l #800,d0
.idle
    moveq #0,d1
    move.w -23750(a4),d1
    cmp.l d1,d0
    ble.b .rpm
    move.l d1,d0
.rpm
    move.w d0,d4
.native
    movem.l (sp)+,d0-d1
    lsl.w #1,d4
    lsr.w #8,d4
    rts

sim_drag_reference:
    move.l d0,-(sp)
    bsr sim_force_reference
    move.w d0,d6
    move.w -29944(a4),d4
    move.l (sp)+,d0
    rts
sim_ai_reference:
    movem.l d0-d1/a0,-(sp)
    lea sim_ai_prev_force(pc),a0
    move.w (a0,d3.w),d1
    ext.l d1
    bsr sim_times_n_minus_1
    asr.l #1,d0
    sub.w d0,d6
    bpl.b .forward
    clr.w d6
.forward
    movem.l (sp)+,d0-d1/a0
    lsr.w #3,d6
    add.w -31126(a4),d6
    rts

sim_ai_update:
    SIM_AI_INTERVAL
    bne.b .rates
    GPC_CALL $a09a
.rates
    GPC_CALL $a20e
    SIM_AI_INTERVAL
    bne.b .lane
    ; Native avoidance may deliberately choose no lane movement this interval.
    ; Only the actual native motion branches arm a rate for the two extra steps.
    lea sim_ai_lane_rate_value(pc),a0
    clr.w (a0,d3.w)
    GPC_CALL $a12a
    rts
.lane
    movem.l d0-a6,-(sp)
    lea sim_ai_lane_rate_value(pc),a0
    move.w (a0,d3.w),d0
    bsr sim_ai_lane_apply
    movem.l (sp)+,d0-a6
    rts
sim_ai_left:
    movem.l d0/a0,-(sp)
    lea 66(a4),a0
    move.w (a0,d3.w),d0
    neg.w d0
    bra.b sim_ai_lane_record
sim_ai_right:
    movem.l d0/a0,-(sp)
    lea 66(a4),a0
    move.w (a0,d3.w),d0
sim_ai_lane_record:
    lea sim_ai_lane_rate_value(pc),a0
    move.w d0,(a0,d3.w)
    bsr sim_ai_lane_apply
    movem.l (sp)+,d0/a0
    rts
sim_ai_lane_apply:
    lea sim_ai_lane_frac(pc),a0
    adda.w d3,a0
    bsr sim_scale_word
    move.w d0,d4
    lea -14(a4),a0
    add.w d4,(a0,d3.w)
    rts
sim_ai_force:
    movem.l d0/a1,-(sp)
    move.w d6,d0
    lea sim_ai_speed_frac(pc),a0
    adda.w d3,a0
    bsr sim_scale_word
    lea sim_ai_force_value(pc),a1
    move.w d0,(a1,d3.w)
    move.w d0,d6
    movem.l (sp)+,d0/a1
    lea -34(a4),a0
    add.w d6,(a0,d3.w)
    rts
sim_ai_target:
    lea 106(a4),a0
    move.w (a0,d3.w),d6
    lea -34(a4),a0
    sub.w (a0,d3.w),d6
    bsr sim_ai_force
    move.l sim_code(pc),a0
    adda.l #$a248,a0
    jmp (a0)
sim_ai_motion:
    movem.l d0-d1/d3/a0,-(sp)
    moveq #0,d0
    move.w (a0,d3.w),d0
    lea sim_ai_force_value(pc),a0
    move.w (a0,d3.w),d1
    ext.l d1
    clr.w (a0,d3.w)
    lea sim_ai_prev_force(pc),a0
    move.w d1,(a0,d3.w)
    bsr sim_euler_velocity
    lea sim_ai_distance_frac(pc),a0
    adda.w d3,a0
    move.w sim_n(pc),d3
    add.w d3,d3
    bsr sim_scale_unsigned
    move.l d0,d4
    movem.l (sp)+,d0-d1/d3/a0
    rts
sim_ai_order:
    GPC_CALL $a3b8
    GPC_CALL $a43e
    SIM_BOUNDARY
    bne.b .done
    GPC_CALL $a464
.done
    rts
sim_collision_phase:
    move.w -29970(a4),d4
    SIM_BOUNDARY
    bne.b .done
    addq.w #1,d4
.done
    rts

; The native latch has no calls or side effects beyond its destination copy.
; Preserve its existing MOVEM frame, and balance Exec Disable/Enable around the
; entire copy, including the latched active-field count. No busy retry loop.
sim_latch_enter:
    movem.l d0-a6,-(sp)
    move.l $4.w,a6
    jsr _LVODisable(a6)
    move.l sim_code(pc),a0
    adda.l #$a6f2,a0
    move.w #10,d1
    jmp (a0)
sim_latch_leave:
    bsr render_pose_latch
    move.l $4.w,a6
    jsr _LVOEnable(a6)
    bsr render_subunit
    movem.l (sp)+,d0-a6
    rts

sim_code: dc.l 0
sim_p: dc.w 6
sim_n: dc.w 1
sim_phase: dc.w 0
sim_rates:
sim_player_reference: dc.w 0
sim_rpm_reference: dc.w 0
sim_gear_impulse: dc.w 0
sim_speed_frac: dc.w 0
sim_distance_frac: dc.w 0
sim_heat_frac: dc.w 0
sim_yaw_frac: dc.w 0
sim_rpm_frac: dc.w 0
; Neutral RPM samples the complete native map once per three substeps and
; distributes its exact signed difference. Three calls reproduce even the
; idle clamp; it is not an Euler approximation to the nonlinear rise.
sim_free_rpm_left: dc.w 0
sim_free_rpm_rate: dc.w 0
sim_free_rpm_frac: dc.w 0
sim_feedback_frac: dc.l 0
sim_steer_frac: dc.w 0
sim_crossed: dc.w 0
sim_shift_step: dc.w 0
sim_tick_force: dc.l 0
sim_prev_force: dc.l 0
sim_before_force: dc.l 0
sim_yaw_decay_frac: dc.l 0
sim_steer_decay_frac: dc.l 0
sim_ai_speed_frac: dcb.w 10,0
sim_ai_distance_frac: dcb.w 10,0
sim_ai_lane_frac: dcb.w 10,0
sim_ai_lane_rate_value: dcb.w 10,0
sim_ai_force_value: dcb.w 10,0
sim_ai_prev_force: dcb.w 10,0
SIM_RATE_WORDS equ (*-sim_rates)/2
    IFD VERIFY
    include "simulation-verify.s"
    ENDC
