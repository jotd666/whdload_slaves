; Experimental A4000 arithmetic kernels.
; Selected development hooks exist. Fractions must join the replay extension.
;
; Signed rate conversion: d0.w is a nominal A2500 increment; (a0).w is a
; signed numerator remainder (-4..4). Return d0.w at 50 Hz, update remainder.
; Truncation toward zero is symmetric; retaining the signed remainder makes
; five constant 50 Hz steps sum to two A2500 increments, even at +/-1 units.
; Scratch d1. Full signed-word inputs fit the signed DIVS quotient.
sim_rate_20_to_50:
 muls #2,d0
 move.w (a0),d1
 ext.l d1
 add.l d1,d0
 divs #5,d0
 swap d0
 move.w d0,(a0)
 swap d0
 ext.l d0
 rts

; Steering kernel, derived from $1033A..$10492:
; d0.w current angle; d1.w signed A2500 table command; d2.w positive native
; centering increment (twice table column 1); d3.w nonzero if moving;
; a0 -> private steering fraction. Returns angle d0.w and updated fraction.
; Countersteering multiplier 4, absolute +/-240 and neutral deadzone 8 stay
; native. The per-step +/-80 increment is rate-scaled. Clamp centering AFTER
; rate conversion so reaching the target cannot overshoot or decay forever.
; All registers except d0/d1 and CCR are preserved.
sim_steering_50:
 movem.l d2-d5,-(sp)
 move.w d0,d4
 moveq #0,d5             ; centering flag
 tst.w d1
 beq .neutral
 bmi .left
 cmp.w #-1,d4
 bge .rate
 asl.w #2,d1
 bra .rate
.left:
 cmp.w #1,d4
 ble .rate
 asl.w #2,d1
 bra .rate
.neutral:
 tst.w d3
 beq .deadzone
 tst.w d4
 beq .at_target
 moveq #1,d5
 move.w d2,d1
 tst.w d4
 bmi .rate
 neg.w d1
.rate:
 cmp.w #80,d1
 ble .low
 moveq #80,d1
.low:
 cmp.w #-80,d1
 bge .convert
 moveq #-80,d1
.convert:
 move.w d1,d0
 bsr sim_rate_20_to_50
 add.w d0,d4
 tst.w d5
 beq .limit
 ; Centering: a sign crossing or the native +/-8 neutral zone reaches zero.
 tst.w d0
 beq .deadzone
 bmi .center_from_right
 tst.w d4
 bpl .at_target
 bra .deadzone
.center_from_right:
 tst.w d4
 bmi .at_target
.deadzone:
 cmp.w #8,d4
 bge .limit
 cmp.w #-8,d4
 ble .limit
.at_target:
 clr.w (a0)
 moveq #0,d4
.limit:
 cmp.w #240,d4
 ble .limit_low
 move.w #240,d4
 clr.w (a0)             ; no accumulated demand against the steering stop
.limit_low:
 cmp.w #-240,d4
 bge .unchanged
 move.w #-240,d4
 clr.w (a0)
.unchanged:
 move.w d4,d0
 movem.l (sp)+,d2-d5
 rts

; Preserve A2500's calibrated integer displacement: floor(speed*1408/15360).
; Apply2/5 per50Hz update with unsigned fifths at A0. Five updates at a
; constant speed equal two native20 updates exactly, including its truncation.
; D0.W unsigned speed -> D0.L whole distance; D1 scratch. The first DIVU
; quotient is at most6007; the second numerator at most12018, so both fit.
sim_distance_50:
 mulu #1408,d0
 divu #15360,d0
 and.l #$ffff,d0
 add.l d0,d0
 moveq #0,d1
 move.w (a0),d1
 add.l d1,d0
 divu #5,d0
 swap d0
 move.w d0,(a0)
 swap d0
 and.l #$ffff,d0
 rts

; Endpoint correction to the calibrated native distance Q(speed).
; d0.l distance, d1.w old speed, d2.w new speed; a0 -> unsigned tenths.
; extra=floor((3*(Qnew-Qold)+carry)/10), remainder0..9, including deceleration.
; Preserve all inputs except d0 and the remainder.
sim_endpoint_50:
 movem.l d1-d4,-(sp)
 move.l d0,d4
 mulu #1408,d1
 divu #15360,d1
 and.l #$ffff,d1
 mulu #1408,d2
 divu #15360,d2
 and.l #$ffff,d2
 sub.l d1,d2
 move.l d2,d0
 add.l d2,d0
 add.l d2,d0
 moveq #0,d3
 move.w (a0),d3
 add.l d3,d0
 divs #10,d0
 move.w d0,d2
 swap d0
 tst.w d0
 bpl .remainder
 add.w #10,d0
 subq.w #1,d2
.remainder:
 move.w d0,(a0)
 ext.l d2
 move.l d4,d0
 add.l d2,d0
 movem.l (sp)+,d1-d4
 rts

; Approach target at a nominal A2500 rate (gear actuator uses 6 units/step).
; d0.w current, d1.w target, d2.w positive rate, a0 -> signed fraction.
; Return d0.l signed new current, stop exactly at target and clear carry there.
; Long comparisons avoid signed-word overflow across the full coordinate range.
sim_approach_50:
 movem.l d2-d4,-(sp)
 ext.l d0
 move.l d0,d3
 ext.l d1
 move.l d1,d4
 cmp.l d3,d4
 beq .target
 blt .decrease
 move.w d2,d0
 bsr sim_rate_20_to_50
 add.l d3,d0
 cmp.l d4,d0
 blt .done
 bra .target
.decrease:
 move.w d2,d0
 neg.w d0
 bsr sim_rate_20_to_50
 add.l d3,d0
 cmp.l d4,d0
 bgt .done
.target:
 move.l d4,d0
 clr.w (a0)
.done:
 movem.l (sp)+,d2-d4
 rts

; Airborne wheel pair from $CB48: v += a; y -= v at nominal 20 Hz.
; Native Normal repeats the ordered pair. Its constant-a fractional extension
; for h=2/5 is dv=2a/5, dy=-(2*v/5 + 7*a/25). Here v includes the private
; velocity fraction. Five steps equal two native pairs exactly without collision/velocity wrap.
; d0.w old velocity, d1.w acceleration; a0 -> signed velocity/position
; remainders in fifths/twenty-fifths; a1 -> long position. Return d0.w new v.
; Position remainder measures downward displacement; subtract its quotient.
; Return d1.l = actual downward step for the later collision correction.
; Contact/impulse resets and replay storage belong to integration.
sim_airborne_pair_50:
 movem.l d2-d5,-(sp)
 move.w d0,d2
 move.w d1,d4
 muls #10,d0
 move.w (a0),d3
 ext.l d3
 add.l d3,d3
 add.l d3,d0
 muls #7,d1
 add.l d1,d0
 move.w 2(a0),d1
 ext.l d1
 add.l d1,d0
 divs #25,d0
 swap d0
 move.w d0,2(a0)
 swap d0
 ext.l d0
 move.l d0,d5
 sub.l d0,(a1)
 move.w d4,d0
 bsr sim_rate_20_to_50
 add.w d2,d0
 ext.l d0
 move.l d5,d1
 movem.l (sp)+,d2-d5
 rts

; First airborne pair after a velocity reset. d2.w=h5 (1..5),
; d1.w acceleration, d0.w=0; a0 fractions, a1 position, same return as above.
; h=h5/5; dy=h(h+1)*a/2 using T=3,7,12,18,25 in twenty-fifths.
sim_release_pair_50:
 movem.l d2-d5/a2,-(sp)
 move.w d1,d4
 move.w d2,d3
 add.w d3,d3
 lea .triangular(pc),a2
 move.w -2(a2,d3.w),d0
 muls d4,d0
 move.w 2(a0),d3
 ext.l d3
 add.l d3,d0
 divs #25,d0
 swap d0
 move.w d0,2(a0)
 swap d0
 ext.l d0
 move.l d0,d5
 sub.l d0,(a1)
 move.w d2,d0
 muls d4,d0
 move.w (a0),d3
 ext.l d3
 add.l d3,d0
 divs #5,d0
 swap d0
 move.w d0,(a0)
 swap d0
 ext.l d0
 move.l d5,d1
 movem.l (sp)+,d2-d5/a2
 rts
.triangular:
 dc.w 3,7,12,18,25

; Positive-clearance suspension extension from $10226..$10286. The input is
; geometric wheel clearance, but native code accumulates it into extension on
; EVERY call. Treat min(clearance,192) as the nominal A2500 extension rate.
; d0.w extension, d1.w positive clearance; a0 -> signed fifths remainder.
; Return d0.w extension capped at the native absolute limit 384. Negative
; penetration correction remains instantaneous in the original routine.
sim_extension_50:
 movem.l d1-d2,-(sp)
 move.w d0,d2
 move.w d1,d0
 cmp.w #192,d0
 ble .rate
 move.w #192,d0
.rate:
 bsr sim_rate_20_to_50
 add.w d2,d0
 cmp.w #384,d0
 blt .done
 move.w #384,d0
 clr.w (a0)
.done:
 movem.l (sp)+,d1-d2
 rts

; Nominal 20 Hz gear-transition engine decrement is 40: exactly 16 at 50 Hz.
; Preserve native word wrap here; the existing engine helper subsequently
; applies its car-spec minimum. d0.w engine state -> d0.w updated engine state.
sim_engine_decay_50:
 sub.w #16,d0
 rts

; Unsigned nominal A2500 duration -> whole 50 Hz ticks, ceil(5*n/2).
; Round deadlines UP: a 250 ms delay lasts 260 ms, never 240 ms. Known C6
; assignments 5/10/30 become 13/25/75 and fit the native byte. Return d0.l;
; the general arithmetic accepts a word, but callers must check storage width.
sim_duration_20_to_50:
 mulu #5,d0
 addq.l #1,d0
 lsr.l #1,d0
 rts

; Terrain: native v' = v-floor(v/k). Write q=floor(v/k), R=v-k*q:
; v' = R+(1-1/k)*(v-R). Freeze R for this substep and use h=2/5:
; loss = q*k*(1-(1-1/k)^h). Recompute q each 50 Hz physics update.
; This fractional affine step retains the native floor; v<k is a fixed point.
; d0.w unsigned speed, d1.w native k, d2.w Q16 loss coefficient;
; a0 -> unsigned Q16 carried loss. Return d0.l unsigned reduced speed.
; q<=1023 and coefficient<=26338: product plus carry fits unsigned long.
; The carried loss is in speed units, independent of the current wheel count.
sim_terrain_drag_50:
 movem.l d2-d4,-(sp)
 and.l #$ffff,d0
 move.l d0,d3
 move.w d1,d4
 divu d1,d0
 tst.w d0
 beq .floor
 mulu d2,d0
 moveq #0,d1
 move.w (a0),d1
 add.l d1,d0
 move.w d0,(a0)
 swap d0
 and.l #$ffff,d0
 sub.l d0,d3
 cmp.w d4,d3
 bhs .done
.floor:
 clr.w (a0)
.done:
 move.l d3,d0
 movem.l (sp)+,d2-d4
 rts

; Convert a nominal A2500 skid loss BEFORE the native pair of speed clamps.
; d0.w loss (0..1024), d1.w/d2.w unsigned speeds; a0 -> fifths remainder.
; Return d0.l scaled loss, preserve d1-d3. If either speed will clamp to zero,
; discard the fraction so a later acceleration cannot inherit stopped skid.
sim_skid_loss_50:
 movem.l d1-d3,-(sp)
 move.w d1,d3
 cmp.w d2,d3
 bls .minimum
 move.w d2,d3
.minimum:
 bsr sim_rate_20_to_50
 cmp.w d3,d0
 bcs .done
 clr.w (a0)
.done:
 movem.l (sp)+,d1-d3
 rts

; Quantized native half filter, coupled to its post-update angle integration.
; n=trunc0(word(a+q)/2), rho=(1/2)^(2/5), alpha=2*(1-rho).
; Freeze the affine target 2*n-a over this step: nominal rate advances using
; alpha*(n-a)-(1-rho)*R, where R is its carried Q16 fraction.
; Native integrates the ENDPOINT rate. Its fractional-step equivalent is
; h*a_new+k*(a_new-a_old), k=h/alpha/(1-1/2)-1/(1-1/2)+1-h.
; h=2/5; k=0.251925184. Angle uses denominator 1280 and round(1280*k)=322.
; This is physical integration, not interpolation of rendered states.
;
; d0.w old nominal rate, d1.w command; a0 -> angle fraction.w, cache.w,
; nominal Q16 fraction.l. Return d0.l nominal rate, d1.l actual angle step.
; Preserve d2-d7/a1. Carry clears at native integer fixed points/stopped spin.
; Separate word products retain full differences across native ADD.W wraps.
sim_spin_filter_50:
 movem.l d2-d7/a1,-(sp)
 lea sim_spin_half_coefficients(pc),a1
 move.w d0,d3
 add.w d0,d1
 ext.l d1
 divs #2,d1
 ext.l d1
 bra.s sim_spin_filter_common

; Native alternate filter is ASR.W(15*a,4), including low-word wrap.
; rho=(15/16)^(2/5), alpha=(1-rho)/(1-15/16), beta=1-rho.
; Coupled endpoint integration k=(2/5)*rho/(1-rho)-15.
sim_spin_alternate_50:
 movem.l d2-d7/a1,-(sp)
 lea sim_spin_alternate_coefficients(pc),a1
 move.w d0,d3
 move.w d0,d1
 muls #15,d1
 asr.w #4,d1
 ext.l d1
sim_spin_filter_common:
 move.l d1,d7             ; native quantized endpoint
 move.w d1,d2
 muls (a1),d2
 muls (a1),d0
 sub.l d0,d2
 move.l 4(a0),d5          ; old signed Q16 fraction
 move.l d5,d6
 bpl .beta_positive
 neg.l d6
.beta_positive:
 mulu 2(a1),d6
 tst.l d5
 bpl .beta_signed
 neg.l d6
.beta_signed:
 bsr sim_spin_trunc_q16
 sub.l d6,d2
 add.l d5,d2
 move.l d2,d6
 bsr sim_spin_trunc_q16
 move.w d6,d0
 add.w d3,d0
 cmp.w d7,d0
 bne .remainder
 tst.w 8(a1)
 beq .target
 ; Alternate decay keeps progress through intermediate integer endpoints.
 ; Only an actual native fixed point may discard the nominal fraction.
 move.w d7,d4
 muls #15,d4
 asr.w #4,d4
 cmp.w d7,d4
 beq .target
.remainder:
 swap d6
 clr.w d6
 sub.l d6,d2
 bra .rate_ready
.target:
 moveq #0,d2
.rate_ready:
 move.l d2,4(a0)
 ; Angle numerator: (512+K)*new -K*old, including both rate fractions.
 move.w d0,d1
 muls 4(a1),d1
 move.w d3,d4
 muls 6(a1),d4
 sub.l d4,d1
 move.l d2,d4
 bpl .new_fraction_positive
 neg.l d4
.new_fraction_positive:
 mulu 4(a1),d4
 tst.l d2
 bpl .new_fraction_signed
 neg.l d4
.new_fraction_signed:
 move.l d5,d6
 bpl .old_fraction_positive
 neg.l d6
.old_fraction_positive:
 mulu 6(a1),d6
 tst.l d5
 bpl .old_fraction_signed
 neg.l d6
.old_fraction_signed:
 sub.l d6,d4
 move.l d4,d6
 bsr sim_spin_trunc_q16
 add.l d6,d1
 move.w (a0),d4
 ext.l d4
 add.l d4,d1
 divs #1280,d1
 swap d1
 move.w d1,(a0)
 swap d1
 ext.l d1
 tst.w d0
 bne .done
 tst.w d7
 bne .done
 clr.w (a0)               ; no residual rotation after the native stop gate
 moveq #0,d1
.done:
 ext.l d0
 movem.l (sp)+,d2-d7/a1
 rts

; alpha Q16,beta Q16,512+K,K,alternate fixed-point rule; angle /1280.
sim_spin_half_coefficients: dc.w 31738,15869,834,322,0
sim_spin_alternate_coefficients: dc.w 26723,1670,890,378,1

; Signed long Q16 -> signed integer in D6, truncating toward zero.
sim_spin_trunc_q16:
 tst.l d6
 bpl .positive
 add.l #65535,d6
.positive:
 swap d6
 ext.l d6
 rts

; Held nominal rate (airborne/alternate path) in the same angle-carry units.
; d0.w rate, a0 -> angle remainder, cache, signed Q16 rate fraction. Scratch D1.
sim_spin_step_50:
 muls #512,d0
 move.l 4(a0),d1
 bpl .positive_fraction
 add.l #127,d1
.positive_fraction:
 asr.l #7,d1             ; 512/65536 times the held fractional nominal rate
 add.l d1,d0
 move.w (a0),d1
 ext.l d1
 add.l d1,d0
 divs #1280,d0
 swap d0
 move.w d0,(a0)
 swap d0
 ext.l d0
 rts

; Unsigned opponent recovery speed; nominal loss512 converted with fifths.
; d0.w speed,a0 -> remainder0..4. Return d0.l speed,d1.l strict overshoot.
; Equality stops speed but leaves native slip clearing until the next step.
; A stopped car retains no braking remainder. Preserve d2.
sim_opponent_brake_50:
 move.l d2,-(sp)
 moveq #0,d2
 move.w d0,d2
 move.w #512,d0
 bsr sim_rate_20_to_50
 moveq #0,d1
 cmp.w d2,d0
 bls.s .subtract
 moveq #1,d1
 moveq #0,d2
 bra.s .stopped
.subtract:
 sub.w d0,d2
 bne.s .done
.stopped:
 clr.w (a0)
.done:
 move.l d2,d0
 move.l (sp)+,d2
 rts

; Repeated canonical slip decay: unsigned angle1..1023, a0 -> Q16 pending
; loss. Native decrement is ceil(angle/16); rho=(15/16)^(2/5).
; Pending loss is retained through intermediate endpoints and cleared at0.
; Out-of-range signed words undergo the original one-time canonicalization
; (including MULS/ASR.W wrap), not an invented repeated signed decay.
; d0.w angle -> d0.l canonical angle; preserve d1-d3.
sim_slip_relax_50:
 movem.l d1-d3,-(sp)
 tst.w d0
 beq .zero
 bmi .negative_event
 cmp.w #1023,d0
 bhi .positive_event
 move.w d0,d3
 add.w #15,d0
 lsr.w #4,d0
 mulu #26723,d0
 moveq #0,d1
 move.w (a0),d1
 add.l d1,d0
 mulu #1670,d1
 swap d1
 and.l #$ffff,d1
 sub.l d1,d0
 move.w d0,(a0)
 swap d0
 and.l #$ffff,d0
 sub.w d0,d3
 ble .zero
 moveq #0,d0
 move.w d3,d0
 bra .done
.negative_event:
 neg.w d0
 muls #15,d0
 asr.w #4,d0
 neg.w d0
 bra .canonical
.positive_event:
 muls #15,d0
 asr.w #4,d0
.canonical:
 and.l #$3ff,d0
 clr.w (a0)
 bra .done
.zero:
 moveq #0,d0
 clr.w (a0)
.done:
 movem.l (sp)+,d1-d3
 rts

; Native $F974 cardinal-heading correction: within seven angle units and with
; neutral steering, approach the nearest multiple of 256 at 20 units/second.
; d0.w heading, d1.w steering, a0 signed fifths. Preserve d1-d3.
; Keep native word wrapping; a completed/inactive correction discards carry.
sim_heading_50:
 movem.l d1-d3,-(sp)
 move.w d0,d2
 tst.w d1
 bne.s .clear
 ext.w d0
 move.w d0,d3
 beq.s .clear
 cmp.w #7,d0
 bgt.s .clear
 cmp.w #-7,d0
 blt.s .clear
 moveq #-1,d0
 tst.w d3
 bpl.s .rate
 moveq #1,d0
.rate:
 bsr sim_rate_20_to_50
 add.w d0,d2
 move.w d2,d0
 tst.b d0
 bne.s .done
.clear:
 clr.w (a0)
.done:
 move.w d2,d0
 movem.l (sp)+,d1-d3
 rts

 include "simulation_yaw.s"

 include "simulation_centroid.s"
