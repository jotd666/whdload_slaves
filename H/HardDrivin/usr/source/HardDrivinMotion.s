; Development-only angle, ordinary-position and falling-motion integration.
; Requires VERIFY_TIME_SCALARS; shares its per-substep field count.
; Rate callers are distinguished from geometry/contact callers of the same
; rotation helpers. Partial contact retains full Q16 correction and rate state.
_motion_install:
	movem.l d0/a0-a2,-(a7)
	movea.l _code_start(pc),a0
	lea _motion_pitch_function(pc),a1
	movea.l a0,a2
	adda.l #$b194,a2
	move.l a2,(a1)+
	movea.l a0,a2
	adda.l #$b1d0,a2
	move.l a2,(a1)+
	movea.l a0,a2
	adda.l #$b508,a2
	move.l a2,(a1)
	movea.l a0,a1
	lea _motion_patches(pc),a0
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,d0/a0-a2
	rts
_motion_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_MOTION $0ccfa $001e: partial roll contact and feedback
	PL_PSS $ccfa,_contact_roll,$18
	; PERF_RANGE VERIFY_TIME_MOTION $0cd2e $0020: partial pitch contact and feedback
	PL_PSS $cd2e,_contact_pitch,$1a
	; PERF_RANGE VERIFY_TIME_MOTION $0cd6e $0012: rear contact pitch feedback
	PL_PSS $cd6e,_contact_pitch_rate_only,$c
	; PERF_RANGE VERIFY_TIME_MOTION $0cd86 $0006: fractional roll-rate constraint
	PL_PS $cd86,_contact_roll_active
	; PERF_RANGE VERIFY_TIME_MOTION $10ef0 $001c: gameplay crash expiry
	PL_PSS $10ef0,_motion_crash_live,$16
	; PERF_RANGE VERIFY_TIME_MOTION $11680 $0024: Phantom crash expiry
	PL_PSS $11680,_motion_crash_phantom,$1e
	; PERF_RANGE VERIFY_TIME_MOTION $0bce0 $0006: object crash timer reset
	PL_PS $bce0,_motion_crash_start
	; PERF_RANGE VERIFY_TIME_MOTION $0bdbe $0006: obstacle crash timer reset
	PL_PS $bdbe,_motion_crash_start
	; PERF_RANGE VERIFY_TIME_MOTION $0bfee $0006: barrier crash timer reset
	PL_PS $bfee,_motion_crash_start
	; PERF_RANGE VERIFY_TIME_MOTION $0cc54 $0006: landing crash timer reset
	PL_PS $cc54,_motion_crash_start
	; PERF_RANGE VERIFY_TIME_MOTION $0b596 $005c: timed crash-drift envelope
	PL_PSS $b596,_motion_drift,$56
	; PERF_RANGE VERIFY_TIME_MOTION $0bc80 $0006: object crash drift initialization
	PL_PS $bc80,_motion_drift_start
	; PERF_RANGE VERIFY_TIME_MOTION $0bd5e $0006: obstacle crash drift initialization
	PL_PS $bd5e,_motion_drift_start
	; PERF_RANGE VERIFY_TIME_MOTION $0bfa6 $0006: barrier crash drift initialization
	PL_PS $bfa6,_motion_drift_start
	; PERF_RANGE VERIFY_TIME_MOTION $0cc66 $0006: landing crash drift initialization
	PL_PS $cc66,_motion_drift_start
	; PERF_RANGE VERIFY_TIME_MOTION $0b5f2 $000a: falling displacement
	PL_PSS $b5f2,_motion_fall_position,4
	; PERF_RANGE VERIFY_TIME_MOTION $0b500 $0008: snapshot previous projected rates
	PL_P $b500,_motion_position_entry
	PL_NOP $b506,2
	; PERF_RANGE VERIFY_TIME_MOTION $0b578 $001e: ordinary position integration
	PL_PSS $b578,_motion_position_add,$18
	; PERF_RANGE VERIFY_TIME_MOTION $0b36a $000c: roll-rate integration
	PL_PSS $b36a,_motion_roll_base,6
	; PERF_RANGE VERIFY_TIME_MOTION $0b380 $0006: pitch-rate caller
	PL_PS $b380,_motion_pitch_rate
	; PERF_RANGE VERIFY_TIME_MOTION $0b38a $0006: spin-rate caller
	PL_PS $b38a,_motion_yaw_rate
	; PERF_RANGE VERIFY_TIME_MOTION $0b448 $0006: steering-rate caller
	PL_PS $b448,_motion_yaw_rate
	; PERF_RANGE VERIFY_TIME_MOTION $0b1c6 $0008: projected pitch increment
	PL_PSS $b1c6,_motion_pitch_add,2
	; PERF_RANGE VERIFY_TIME_MOTION $0b254 $0010: projected yaw/pitch/roll increments
	PL_PSS $b254,_motion_yaw_add,$a
	; PERF_RANGE VERIFY_TIME_MOTION $0ccc2 $0008: inverted-contact fall acceleration
	PL_PSS $ccc2,_motion_fall_inverted,2
	; PERF_RANGE VERIFY_TIME_MOTION $0ccd4 $0008: dispatch airborne fall acceleration
	PL_PSS $ccd4,_motion_fall_airborne,2
	; PERF_RANGE VERIFY_TIME_MOTION $0cc8a $0006: ground constraint dispatch
	PL_PS $cc8a,_motion_fall_ground
	; PERF_RANGE VERIFY_TIME_MOTION $0cca0 $0006: inverted constraint dispatch
	PL_PS $cca0,_motion_fall_ground_end
	; PERF_RANGE VERIFY_TIME_MOTION $0b62a $0012: spin exponential retention
	PL_PSS $b62a,_motion_spin_decay,$c
	; PERF_RANGE VERIFY_TIME_MOTION $0cb6c $0008: hard-contact angular-rate reset
	PL_PSS $cb6c,_motion_contact_rates,2
	; PERF_RANGE VERIFY_TIME_MOTION $0bf80 $0008: barrier angular-rate reset
	PL_PSS $bf80,_motion_contact_rates,2
	; PERF_RANGE VERIFY_TIME_MOTION $0cd96 $0006: roll-to-zero constraint dispatch
	PL_PS $cd96,_motion_roll_snap
	PL_END

_motion_roll_base:
	movem.l d1-d2/a0-a1,-(a7)
	move.w -$66b8(a4),-$66b2(a4)
	lea _contact_rates(pc),a0
	lea -$66ec(a4),a1
	bsr _contact_read_rate
	bsr _contact_scale_rate
	lea _motion_state+MS_ROLL(pc),a0
	lea -$66b2(a4),a1
	bsr _contact_add_angle
	move.w (a1),d0
	movem.l (a7)+,d1-d2/a0-a1
	tst.w d0
	rts

; The original argument remains beneath the patch-call return address. Pitch
; consumes its full-rate shadow; yaw passes a copy to the native helper. Both
; remove the original argument with the displaced ADDQ #2,SP.
_motion_pitch_rate:
	movem.l d0-d3/a0-a1,-(a7)
	lea _contact_rates+8(pc),a0
	lea -$66ea(a4),a1
	bsr _contact_read_rate
	bsr _contact_pitch_projection
	bsr _contact_scale_rate
	lea _motion_state+MS_PITCH(pc),a0
	lea -$66b4(a4),a1
	bsr _contact_add_angle
	movem.l (a7)+,d0-d3/a0-a1
	move.l (a7),2(a7)
	addq.w #2,a7
	rts
_motion_yaw_rate:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	st MS_RATE(a0)
	movea.l (a7)+,a0
	move.w 4(a7),-(a7)
	movea.l _motion_yaw_function(pc),a0
	jsr (a0)
	addq.w #2,a7
_motion_rate_return:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.b MS_RATE(a0)
	movea.l (a7)+,a0
	move.l (a7),2(a7)
	addq.w #2,a7
	rts

_motion_pitch_add:
	move.w 8(a5),d0
	movem.l d1-d2/a0-a1,-(a7)
	lea _motion_state+MS_PITCH(pc),a0
	lea -$66b4(a4),a1
	bsr _motion_angle_component
	movem.l (a7)+,d1-d2/a0-a1
	add.w d0,-$66b4(a4)
	rts
_motion_yaw_add:
	movem.l d1-d2/a0-a1,-(a7)
	move.w 8(a5),d0
	lea _motion_state+MS_YAW(pc),a0
	lea -$66b6(a4),a1
	bsr _motion_angle_component
	add.w d0,(a1)
	move.l d0,-(a7)
	move.w d4,d0
	lea _motion_state+MS_PITCH(pc),a0
	lea -$66b4(a4),a1
	bsr _motion_angle_component
	add.w d0,(a1)
	move.w d5,d0
	lea _motion_state+MS_ROLL(pc),a0
	lea -$66b2(a4),a1
	bsr _motion_angle_component
	add.w d0,(a1)
	move.l (a7)+,d0
	movem.l (a7)+,d1-d2/a0-a1
	rts

; A0 -> signed Q16 carry.l, last integer angle.w. A1 -> current game angle.
; Accept the native +/-1440 wrap without dropping the fractional angle.
; Explicit mode/reset writers clear the companions independently of this
; mismatch check, including same-value resets. D1/D2 are scratch.
_motion_angle_component:
	move.l d0,-(a7)
	move.b _motion_state+MS_RATE(pc),d0
	beq.s .constraint
	move.l (a7)+,d0
	bra.s _motion_angle_rate
.constraint:
	move.l (a7)+,d0
	clr.l (a0)
	move.w (a1),d1
	add.w d0,d1
	move.w d1,4(a0)
	rts
_motion_angle_rate:
	move.w (a1),d1
	sub.w 4(a0),d1
	beq.s .current
	cmpi.w #1440,d1
	beq.s .current
	cmpi.w #-1440,d1
	beq.s .current
	clr.l (a0)
.current:
	move.w _time_scalar_fields(pc),d1
	move.l (a0),d2
	bsr _time_scale_q16
	move.l d2,(a0)
	move.w (a1),d1
	add.w d0,d1
	move.w d1,4(a0)
	rts

_motion_fall_inverted:
	move.w -14(a5),d0
	bsr _motion_fall_delta
	add.w d0,-$66f2(a4)
	rts
_motion_fall_airborne:
	tst.b -1(a5)
	bne.s .contact
	move.l d0,-(a7)
	moveq #5,d0
	bsr _motion_fall_delta
	add.w d0,-$66f2(a4)
	move.l (a7)+,d0
	move.l a0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$cd86,a0
	move.l a0,4(a7)
	movea.l (a7)+,a0
.contact:
	rts
_motion_fall_delta:
	movem.l d1-d2/a0,-(a7)
	lea _motion_state(pc),a0
	move.w -$66f2(a4),d1
	cmp.w MS_FALL_LAST(a0),d1
	beq.s .current
	clr.w MS_FALL_CARRY(a0)
.current:
	move.w d0,MS_FALL_ACCEL(a0)
	move.w _time_scalar_fields(pc),d1
	move.w MS_FALL_CARRY(a0),d2
	ext.l d2
	bsr _time_scale_word
	move.w d2,MS_FALL_CARRY(a0)
	move.w -$66f2(a4),d1
	add.w d0,d1
	move.w d1,MS_FALL_LAST(a0)
	movem.l (a7)+,d1-d2/a0
	rts
_motion_fall_ground:
	tst.b -$86f(a4)
	beq.s _motion_fall_reset_fraction
	move.l a0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$cc96,a0
	move.l a0,4(a7)
	movea.l (a7)+,a0
	rts
_motion_fall_ground_end:
	cmpi.w #320,d0
	bgt.s .done
	move.l a0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$cccc,a0
	move.l a0,4(a7)
	movea.l (a7)+,a0
	bra.s _motion_fall_reset_fraction
.done:
	rts
_motion_fall_reset_fraction:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.l MS_FALL_CARRY(a0)
	clr.w MS_FALL_ACCEL(a0)
	movea.l (a7)+,a0
	rts

_motion_contact_rates:
	bsr _contact_reset
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.l MS_PITCH(a0)
	clr.l MS_ROLL(a0)
	movea.l (a7)+,a0
	clr.w -$66ea(a4)
	clr.w -$66ec(a4)
	rts
_motion_roll_snap:
	cmpi.w #3,d0
	blt.s .zero
	move.l a0,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$cda0,a0
	move.l a0,4(a7)
	movea.l (a7)+,a0
	rts
.zero:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.l MS_ROLL(a0)
	clr.w MS_ROLL+4(a0)
	movea.l (a7)+,a0
	rts

_motion_spin_decay:
	movem.l d1-d4/a0-a1,-(a7)
	lea _motion_state(pc),a0
	move.w -$66e6(a4),d0
	cmp.w MS_SPIN_LAST(a0),d0
	beq.s .current
	clr.l MS_SPIN_CARRY(a0)
.current:
	move.w _time_scalar_fields(pc),d1
	cmpi.w #8,d1
	beq.s .native
	swap d0
	clr.w d0
	add.l MS_SPIN_CARRY(a0),d0
	move.l d0,d3
	bpl.s .magnitude
	neg.l d0
.magnitude:
	move.l d0,d4
	bsr _decay_spin
	cmpi.l #$10000,d1
	beq.s .zero_retention
	swap d0
	mulu.w d1,d0
	move.l d4,d2
	mulu.w d1,d2
	clr.w d2
	swap d2
	add.l d2,d0
	sub.l d0,d4
	tst.l d3
	bpl.s .positive
	neg.l d4
.positive:
	move.l d4,d0
	bsr _time_split_q16
	move.l d2,MS_SPIN_CARRY(a0)
	bra.s .save
.zero_retention:
	moveq #0,d0
	clr.l MS_SPIN_CARRY(a0)
	bra.s .save
.native:
	muls.w #9,d0
	ext.l d0
	divs.w #10,d0
	clr.l MS_SPIN_CARRY(a0)
.save:
	move.w d0,MS_SPIN_LAST(a0)
	movem.l (a7)+,d1-d4/a0-a1
	move.w d0,-$66e6(a4)
	rts
_motion_spin_reset:
	move.l a0,-(a7)
	lea _motion_state(pc),a0
	clr.l MS_SPIN_CARRY(a0)
	movea.l (a7)+,a0
	rts

; Crash lifetime is 25 native steps, or 200 active fields. Expiry effects are
; emitted exactly once on crossing zero, independently of display/substep count.
_motion_crash_start:
	move.l a0,-(a7)
	lea _motion_crash_state(pc),a0
	clr.l (a0)
	movea.l (a7)+,a0
	move.b #25,-$69fa(a4)
	rts
_motion_crash_live:
	move.l d0,-(a7)
	bsr _motion_crash_tick
	tst.b d0
	beq.s .done
	clr.b -$50ce(a4)
	st -$5229(a4)
.done:
	move.l (a7)+,d0
	rts
_motion_crash_phantom:
	move.l d0,-(a7)
	bsr _motion_crash_tick
	tst.b d0
	beq.s .done
	st -$5229(a4)
	IFD VERIFY_TIME_PRESENTATION
	bsr _presentation_overlay60
	ELSE
	move.b #60,-$50ce(a4)
	ENDC
	move.b #5,-$16d2(a4)
.done:
	move.l (a7)+,d0
	rts
_motion_crash_tick:
	movem.l d1-d2/a0,-(a7)
	lea _motion_crash_state(pc),a0
	moveq #0,d1
	move.b -$69fa(a4),d1
	cmp.w 2(a0),d1
	beq.s .current
	lsl.w #3,d1
	move.w d1,(a0)
.current:
	moveq #0,d0
	move.w (a0),d1
	beq.s .publish
	move.w _time_scalar_fields(pc),d2
	sub.w d2,d1
	bhi.s .publish
	moveq #0,d1
	moveq #1,d0
.publish:
	move.w d1,(a0)
	addq.w #7,d1
	lsr.w #3,d1
	move.w d1,2(a0)
	move.b d1,-$69fa(a4)
	movem.l (a7)+,d1-d2/a0
	rts
_motion_crash_signature: dc.b 'HDCRASH1'
_motion_crash_state: dc.l 0

; Preserve the native 30-sample linear crash envelope, including each signed
; MUL/DIV truncation. Each envelope sample lasts eight fields; a variable step
; may cross one boundary, so at most two segments are integrated. This avoids
; a continuous Euler approximation reversing drift at the end of the envelope.
; The car still advances on every substep, with signed eighth-position carries.
_motion_drift_start:
	bsr _motion_drift_reset
	move.b #30,-$66ee(a4)
	rts
_motion_drift_reset:
	move.l a0,-(a7)
	lea _motion_drift_state(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	movea.l (a7)+,a0
	rts
_motion_drift:
	movem.l d0-d7/a0-a3,-(a7)
	lea _motion_drift_state(pc),a3
	moveq #0,d0
	move.b -$66ee(a4),d0
	cmp.w 2(a3),d0
	beq.s .current
	move.w d0,2(a3)
	lsl.w #3,d0
	move.w d0,(a3)
	clr.l 4(a3)
	clr.w 8(a3)
.current:
	move.w _time_scalar_fields(pc),d7
.segment:
	tst.w d7
	beq .done
	move.w (a3),d4
	beq .done
	subq.w #1,d4
	move.w d4,d6
	andi.w #7,d6
	addq.w #1,d6
	cmp.w d7,d6
	bls.s .bounded
	move.w d7,d6
.bounded:
	lsr.w #3,d4
	lea -$66f8(a4),a0
	lea -$6704(a4),a1
	lea 4(a3),a2
	moveq #2,d5
.axis:
	move.w (a0)+,d0
	muls.w d4,d0
	divs.w #30,d0
	; Low quotient is the original signed native drift rate.
	move.w d6,d1
	move.w (a2),d2
	ext.l d2
	bsr _time_scale_word
	move.w d2,(a2)+
	add.l d0,(a1)+
	dbf d5,.axis
	sub.w d6,(a3)
	sub.w d6,d7
	bra.s .segment
.done:
	move.w (a3),d0
	addq.w #7,d0
	lsr.w #3,d0
	move.w d0,2(a3)
	move.b d0,-$66ee(a4)
	movem.l (a7)+,d0-d7/a0-a3
	rts
_motion_drift_signature: dc.b 'HDDRIFT1'
; remaining fields.w, last visible counter.w, XYZ signed carries.w, pad.w
_motion_drift_state: dcb.b 12,0

; Entry uses a jump patch, so LINK sees the original caller's stack frame.
; Pushing the continuation and using RTS preserves registers and native TST CCR.
_motion_position_entry:
	link a5,#-2
	bsr _projection_snapshot
	move.l a0,-(a7)
	lea _motion_position_state(pc),a0
	move.w -$66e2(a4),(a0)+
	move.w -$66e0(a4),(a0)+
	move.w -$66de(a4),(a0)
	movea.l (a7)+,a0
	move.l _motion_position_continue(pc),-(a7)
	tst.b -$69fa(a4)
	rts

; Terrain translations preserve fractions. Explicit motion resets discard them.
; Crash drift bypasses this block just as it bypassed native projected motion.
_motion_position_add:
	movem.l d1-d4/a0-a2,-(a7)
	bsr _projection_update
	lea _motion_position_state(pc),a0
	lea -$6704(a4),a1
	lea -$66e2(a4),a2
	move.w _time_scalar_fields(pc),d2
	move.w (a2)+,d0
	move.w (a0),d1
	move.l 8(a0),d3
	bsr _motion_position_delta
	move.l d3,8(a0)
	add.l d0,(a1)+
	move.w (a2)+,d0
	move.w 2(a0),d1
	move.l 12(a0),d3
	bsr _motion_position_delta
	move.l d3,12(a0)
	add.l d0,(a1)+
	move.w (a2),d0
	move.w 4(a0),d1
	move.l 16(a0),d3
	bsr _motion_position_delta
	move.l d3,16(a0)
	add.l d0,(a1)
	bsr _projection_integrate
	movem.l (a7)+,d1-d4/a0-a2
	rts

; Native gravity integrates position before updating fall velocity. Use the
; last contact pass's acceleration for the explicit-Euler bias correction.
; Clear the sample after consumption: partial contact may apply no acceleration.
_motion_fall_position:
	movem.l d1-d5/a0-a1,-(a7)
	lea _motion_state(pc),a0
	lea _motion_position_state(pc),a1
	move.w -$66f2(a4),d0
	cmp.w MS_FALL_LAST(a0),d0
	beq.s .current
	clr.w MS_FALL_CARRY(a0)
	clr.w MS_FALL_ACCEL(a0)
.current:
	move.w MS_FALL_CARRY(a0),d1
	move.w MS_FALL_ACCEL(a0),d2
	move.l 12(a1),d3
	move.w _time_scalar_fields(pc),d4
	bsr _motion_fall_displacement
	move.l d3,12(a1)
	clr.w MS_FALL_ACCEL(a0)
	add.l d0,-$6700(a4)
	movem.l (a7)+,d1-d5/a0-a1
	rts

; D0.W fall velocity, D1.W eighth-unit velocity remainder, D2.W acceleration,
; D3.L position remainder /128, D4.W unsigned fields0..65535. Returns D0.L
; Y delta,D3.L remainder. Preserve other inputs. Acceleration is a signed word.
; Y = -v*T + a*T*(1-T)/2; positive fall velocity moves toward negative Y.
_motion_fall_displacement:
	cmpi.w #8,d4
	bhi _motion_fall_displacement_wide
	movem.l d1-d2/d4-d5,-(a7)
	tst.w d4
	beq.s .zero
	muls.w d4,d0
	lsl.l #4,d0
	neg.l d0
	muls.w d4,d1
	add.l d1,d1
	sub.l d1,d0
	moveq #8,d5
	sub.w d4,d5
	mulu.w d4,d5
	muls.w d5,d2
	add.l d2,d0
	add.l d3,d0
	move.l d0,d3
	asr.l #7,d0
	tst.l d3
	bpl.s .remainder
	move.l d3,d5
	andi.l #127,d5
	beq.s .remainder
	addq.l #1,d0
.remainder:
	move.l d0,d5
	lsl.l #7,d5
	sub.l d5,d3
	bra.s .done
.zero:
	moveq #0,d0
.done:
	movem.l (a7)+,d1-d2/d4-d5
	rts

; Wide numerator: -fields*(16*v+2*velocity_carry)
;                 -acceleration*fields*(fields-8)+position_carry.
; Signed64 holds every word velocity/acceleration and unsigned-word interval.
; Return the low32 quotient bits for the native ADD.L coordinate representation;
; remainder sign comes from the wide numerator, even if that quotient wraps.
_motion_fall_displacement_wide:
	movem.l d1-d2/d4-d7,-(a7)
	move.w d2,d5
	ext.l d0
	lsl.l #4,d0
	ext.l d1
	add.l d1,d1
	add.l d1,d0
	move.w d4,d1
	bsr _time_product_s32_u16
	neg.l d0
	negx.l d2
	move.l d0,d7
	move.l d2,d6
	move.w d5,d0
	bsr _time_multiply_fields
	move.w d4,d1
	subq.w #8,d1
	bsr _time_product_s32_u16
	sub.l d0,d7
	subx.l d2,d6
	moveq #0,d0
	tst.l d3
	bpl.s .carry
	moveq #-1,d0
.carry:
	add.l d3,d7
	addx.l d0,d6
	move.l d6,d5
	move.l d7,d3
	move.l d7,d0
	lsr.l #7,d0
	moveq #25,d4
	lsl.l d4,d6
	or.l d6,d0
	andi.l #127,d3
	tst.l d5
	bpl.s .done
	tst.l d3
	beq.s .done
	addq.l #1,d0
	subi.l #128,d3
.done:
	movem.l (a7)+,d1-d2/d4-d7
	rts

	IFD VERIFY_FALL_WIDE_MATH
_motion_fall_wide_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _fall_wide_results(pc),a6
	lea _fall_wide_velocities(pc),a0
.velocity:
	move.w (a0)+,d5
	lea _fall_wide_fractions(pc),a1
.fraction:
	move.w (a1)+,d6
	lea _fall_wide_accelerations(pc),a2
.acceleration:
	move.w (a2)+,d7
	lea _fall_wide_fields(pc),a3
.fields:
	move.w (a3)+,d4
	lea _fall_wide_carries(pc),a4
.carry:
	move.l (a4)+,d3
	move.w d5,d0
	move.w d6,d1
	move.w d7,d2
	bsr _motion_fall_displacement
	move.l d0,(a6)+
	move.l d3,(a6)+
	lea _fall_wide_carries_end(pc),a5
	cmpa.l a5,a4
	blo.s .carry
	lea _fall_wide_fields_end(pc),a5
	cmpa.l a5,a3
	blo.s .fields
	lea _fall_wide_accelerations_end(pc),a5
	cmpa.l a5,a2
	blo.s .acceleration
	lea _fall_wide_fractions_end(pc),a5
	cmpa.l a5,a1
	blo.s .fraction
	lea _fall_wide_velocities_end(pc),a5
	cmpa.l a5,a0
	blo.s .velocity
	movem.l (a7)+,d0-d7/a0-a6
	rts
_fall_wide_velocities: dc.w -32768,-1,0,1,32767
_fall_wide_velocities_end:
_fall_wide_fractions: dc.w -7,0,7
_fall_wide_fractions_end:
_fall_wide_accelerations: dc.w -32768,-2340,-5,0,5,2340,32767
_fall_wide_accelerations_end:
_fall_wide_fields: dc.w 9,15,31,255,32767,32768,65535
_fall_wide_fields_end:
_fall_wide_carries: dc.l -127,0,127
_fall_wide_carries_end:
_fall_wide_signature: dc.b 'HDFPWID1'
_fall_wide_results: dcb.l 5*3*7*7*3*2,0
	ENDC

; Semi-implicit position increment in native long-position units.
; D0.W new projected velocity, D1.W old velocity, D2.W unsigned fields0..65535,
; D3.L signed remainder (-127..127). Returns D0.L displacement, D3.L carry.
; D1/D2 preserved. Live caller snapshots the previous projected velocity;
; collision/recovery reset paths discard position fractions.
; At T=1 this gives exactly the native new velocity (plus retained fraction).
; At T=0 no motion is consumed, even if a discrete writer changed the velocity.
; For T>0: v*T + (1-T)*(v-u)/2. The second term preserves the native
; semi-implicit Euler displacement under subdivision of constant acceleration.
_motion_position_delta:
	cmpi.w #8,d2
	bhi _motion_position_wide
	movem.l d1-d2/d4,-(a7)
	tst.w d2
	beq.s .zero
	moveq #8,d4
	add.w d2,d4
	muls.w d4,d0
	moveq #8,d4
	sub.w d2,d4
	muls.w d4,d1
	sub.l d1,d0
	lsl.l #3,d0
	add.l d3,d0
	move.l d0,d3
	asr.l #7,d0
	; ASR rounds negative values down; companions use truncation toward zero.
	tst.l d3
	bpl.s .remainder
	move.l d3,d4
	andi.l #127,d4
	beq.s .remainder
	addq.l #1,d0
.remainder:
	move.l d0,d4
	lsl.l #7,d4
	sub.l d4,d3
	bra.s .done
.zero:
	moveq #0,d0
.done:
	movem.l (a7)+,d1-d2/d4
	rts

; Numerator /128 = 64*(v-u)+8*fields*(v+u)+carry. Keep it in
; signed64 bits: the full unsigned field range needs up to36 signed bits,
; although the final displacement fits a signed long for all word velocities.
_motion_position_wide:
	movem.l d1-d2/d4-d7,-(a7)
	move.w d0,d4
	ext.l d4
	move.w d1,d5
	ext.l d5
	move.w d2,d6
	move.l d3,d7
	move.l d4,d0
	add.l d5,d0
	move.w d6,d1
	bsr _time_product_s32_u16
	add.l d0,d0
	addx.l d2,d2
	add.l d0,d0
	addx.l d2,d2
	add.l d0,d0
	addx.l d2,d2
	sub.l d5,d4
	lsl.l #6,d4
	add.l d7,d4
	moveq #0,d5
	tst.l d4
	bpl.s .correction
	moveq #-1,d5
.correction:
	add.l d4,d0
	addx.l d5,d2
	move.l d0,d3
	lsr.l #7,d0
	moveq #25,d4
	lsl.l d4,d2
	or.l d2,d0
	andi.l #127,d3
	tst.l d0
	bpl.s .done
	tst.l d3
	beq.s .done
	addq.l #1,d0
	subi.l #128,d3
.done:
	movem.l (a7)+,d1-d2/d4-d7
	rts

	IFD VERIFY_POSITION_WIDE_MATH
_motion_position_wide_test:
	movem.l d0-d7/a0-a3,-(a7)
	lea _motion_wide_results(pc),a2
	lea _motion_wide_values(pc),a0
	moveq #6,d7
.new:
	move.w (a0)+,d4
	lea _motion_wide_values(pc),a1
	moveq #6,d6
.old:
	move.w (a1)+,d5
	lea _motion_wide_fields(pc),a3
	moveq #6,d2
.fields:
	move.w d2,-(a7)
	move.w (a3)+,d2
	move.l #-127,d3
	moveq #2,d1
.carry:
	move.l d3,-(a7)
	move.w d1,-(a7)
	move.w d4,d0
	move.w d5,d1
	bsr _motion_position_delta
	move.l d0,(a2)+
	move.l d3,(a2)+
	move.w (a7)+,d1
	move.l (a7)+,d3
	addi.l #127,d3
	dbf d1,.carry
	move.w (a7)+,d2
	dbf d2,.fields
	dbf d6,.old
	dbf d7,.new
	lea _motion_product_values(pc),a0
	lea _motion_product_results(pc),a2
	moveq #8,d7
.product_value:
	move.l (a0)+,d4
	lea _motion_product_fields(pc),a1
	moveq #5,d6
.product_fields:
	move.l d4,d0
	move.w (a1)+,d1
	bsr _time_product_s32_u16
	move.l d2,(a2)+
	move.l d0,(a2)+
	dbf d6,.product_fields
	dbf d7,.product_value
	movem.l (a7)+,d0-d7/a0-a3
	rts
_motion_product_values: dc.l $80000000,-65537,-65536,-1,0,1,65535,65536,$7fffffff
_motion_product_fields: dc.w 0,1,8,32767,32768,65535
_motion_product_signature: dc.b 'HDMULW01'
_motion_product_results: dcb.l 9*6*2,0
_motion_wide_values: dc.w -32768,-257,-1,0,1,257,32767
_motion_wide_fields: dc.w 9,15,31,255,32767,32768,65535
_motion_wide_signature: dc.b 'HDPOSW01'
_motion_wide_results: dcb.l 7*7*7*3*2,0
	ENDC

_motion_reset:
	bsr _projection_reset
	bsr _contact_reset
	bsr _motion_drift_reset
	move.l a0,-(a7)
	lea _motion_crash_state(pc),a0
	clr.l (a0)
	lea _motion_state(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	lea _motion_position_state(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	movea.l (a7)+,a0
	rts
MS_YAW equ 0
MS_PITCH equ 6
MS_ROLL equ 12
MS_FALL_CARRY equ 18
MS_FALL_LAST equ 20
MS_RATE equ 22
MS_SPIN_CARRY equ 24
MS_SPIN_LAST equ 28
MS_FALL_ACCEL equ 30
_motion_pitch_function: dc.l 0
_motion_yaw_function: dc.l 0
_motion_position_continue: dc.l 0
_motion_position_live_signature: dc.b 'HDPOSST1'
_motion_position_state: dcb.b 20,0
_motion_signature: dc.b 'HDMOTN01'
_motion_state: dcb.b 32,0

	IFD VERIFY_MOTION_MATH
; Isolated arithmetic fixtures use private fake globals and restore every
; register/state slot before game initialization; no debugger writes required.
_motion_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _motion_fake_globals(pc),a4
	adda.l #$66f2,a4
	lea _time_scalar_fields(pc),a5
	lea _motion_angle_values(pc),a6
	lea _motion_angle_results(pc),a2
	moveq #4,d7
.angle_value:
	move.w (a6)+,d4
	moveq #0,d5
.angle_fields:
	move.w d5,(a5)
	lea _motion_angle_configs(pc),a3
	moveq #2,d6
.angle_case:
	lea _motion_state+MS_YAW(pc),a0
	lea _motion_fake_globals+60(pc),a1
	move.w (a3)+,(a1)
	move.w (a3)+,4(a0)
	move.l (a3)+,(a0)
	move.w d4,d0
	bsr _motion_angle_rate
	move.l d0,(a2)+
	move.l (a0),(a2)+
	move.w 4(a0),(a2)+
	dbf d6,.angle_case
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .angle_fields
	dbf d7,.angle_value

	lea _motion_spin_values(pc),a6
	lea _motion_spin_results(pc),a2
	moveq #6,d7
.spin_value:
	move.w (a6)+,d4
	moveq #0,d5
.spin_fields:
	lea _motion_spin_fields(pc),a3
	move.w (a3,d5.w),(a5)
	lea _motion_spin_carries(pc),a3
	moveq #4,d6
.spin_case:
	lea _motion_state(pc),a0
	move.w d4,-$66e6(a4)
	move.w d4,MS_SPIN_LAST(a0)
	move.l (a3)+,MS_SPIN_CARRY(a0)
	bsr _motion_spin_decay
	move.w -$66e6(a4),(a2)+
	move.l MS_SPIN_CARRY(a0),(a2)+
	dbf d6,.spin_case
	addq.w #2,d5
	cmpi.w #34,d5
	blo.s .spin_fields
	dbf d7,.spin_value
	lea _motion_fall_values(pc),a6
	lea _motion_fall_results(pc),a2
	moveq #2,d7
.fall_value:
	move.w (a6)+,d4
	moveq #0,d5
.fall_fields:
	move.w d5,(a5)
	lea _motion_fall_configs(pc),a3
	moveq #2,d6
.fall_case:
	lea _motion_state(pc),a0
	move.w (a3)+,-$66f2(a4)
	move.w (a3)+,MS_FALL_LAST(a0)
	move.w (a3)+,MS_FALL_CARRY(a0)
	move.w d4,d0
	bsr _motion_fall_delta
	move.l d0,(a2)+
	move.w MS_FALL_LAST(a0),(a2)+
	move.w MS_FALL_CARRY(a0),(a2)+
	dbf d6,.fall_case
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .fall_fields
	dbf d7,.fall_value
	lea _motion_position_results(pc),a2
	lea _motion_position_values(pc),a6
	moveq #6,d7
.position_new:
	move.w (a6)+,d4
	lea _motion_position_values(pc),a3
	moveq #6,d6
.position_old:
	move.w (a3)+,d1
	moveq #0,d2
.position_fields:
	lea _motion_position_carries(pc),a1
	moveq #2,d5
.position_carry:
	move.w d4,d0
	move.l (a1)+,d3
	bsr _motion_position_delta
	move.l d0,(a2)+
	move.l d3,(a2)+
	dbf d5,.position_carry
	addq.w #1,d2
	cmpi.w #8,d2
	ble.s .position_fields
	dbf d6,.position_old
	dbf d7,.position_new
	lea _motion_fall_position_results(pc),a2
	lea _motion_fall_position_values(pc),a6
	moveq #4,d7
.fall_position_value:
	move.w (a6)+,d6
	moveq #-7,d1
.fall_position_fraction:
	moveq #-5,d2
.fall_position_accel:
	moveq #0,d4
.fall_position_fields:
	move.w d6,d0
	move.l #127,d3
	bsr _motion_fall_displacement
	move.l d0,(a2)+
	move.l d3,(a2)+
	addq.w #1,d4
	cmpi.w #8,d4
	ble.s .fall_position_fields
	addq.w #5,d2
	cmpi.w #5,d2
	ble.s .fall_position_accel
	addq.w #7,d1
	cmpi.w #7,d1
	ble.s .fall_position_fraction
	dbf d7,.fall_position_value
	lea _motion_drift_fake(pc),a4
	adda.l #$6704,a4
	lea _motion_drift_values(pc),a6
	lea _motion_drift_results(pc),a2
	moveq #6,d7
.drift_value:
	move.w (a6)+,d4
	moveq #1,d5
.drift_fields:
	move.w d5,(a5)
	clr.l -$6704(a4)
	clr.l -$6700(a4)
	clr.l -$66fc(a4)
	move.w d4,-$66f8(a4)
	move.w d4,-$66f6(a4)
	move.w d4,-$66f4(a4)
	bsr _motion_drift_start
	moveq #0,d6
	moveq #0,d3
.drift_step:
	bsr _motion_drift
	rol.l #5,d3
	move.l -$6704(a4),d0
	eor.l d0,d3
	moveq #0,d0
	move.w _motion_drift_state(pc),d0
	eor.l d0,d3
	addq.w #1,d6
	tst.b -$66ee(a4)
	bne.s .drift_step
	move.l -$6704(a4),(a2)+
	move.l -$6700(a4),(a2)+
	move.l -$66fc(a4),(a2)+
	move.w d6,(a2)+
	move.w _motion_drift_state+4(pc),(a2)+
	move.l d3,(a2)+
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .drift_fields
	dbf d7,.drift_value
	lea _motion_crash_fake(pc),a4
	adda.l #$69fa,a4
	lea _motion_crash_results(pc),a2
	moveq #1,d5
.crash_fields:
	move.w d5,(a5)
	bsr _motion_crash_start
	moveq #0,d6
	moveq #0,d7
.crash_step:
	bsr _motion_crash_tick
	add.w d0,d7
	addq.w #1,d6
	tst.b -$69fa(a4)
	bne.s .crash_step
	; An additional empty call must not emit expiry twice.
	bsr _motion_crash_tick
	add.w d0,d7
	move.w d6,(a2)+
	move.w d7,(a2)+
	move.l _motion_crash_state(pc),(a2)+
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .crash_fields
	clr.w (a5)
	bsr _motion_crash_start
	bsr _motion_crash_tick
	move.w d0,(a2)+
	move.l _motion_crash_state(pc),(a2)+
	move.w #1,(a5)
	bsr _motion_crash_tick
	; Reinitialize while visible byte is still25: mismatch checks alone fail.
	bsr _motion_crash_start
	bsr _motion_crash_tick
	move.l _motion_crash_state(pc),(a2)+
	move.w #VERIFY_SCALAR_FIELDS,(a5)
	bsr _motion_reset
	movem.l (a7)+,d0-d7/a0-a6
	rts
_motion_fake_globals: dcb.b 68,0
_motion_angle_values: dc.w -5,-1,0,1,5
_motion_angle_configs:
	dc.w 719,719
	dc.l 32768
	dc.w -719,721
	dc.l 16384
	dc.w 100,20
	dc.l -65535
_motion_angle_signature: dc.b 'HDANGLE1'
_motion_angle_results: dcb.b 5*9*3*10,0
_motion_spin_fields: dc.w 0,1,2,3,4,5,6,7,8,9,15,31,127,255,894,895,65535
_motion_spin_values: dc.w -52,-11,-1,0,1,11,52
_motion_spin_carries: dc.l -65535,-8192,0,8192,65535
_motion_spin_signature: dc.b 'HDSPIN01'
_motion_spin_results: dcb.b 7*17*5*6,0
_motion_fall_values: dc.w -5,0,5
_motion_fall_configs: dc.w 49,49,-7,49,49,7,49,0,7
_motion_fall_signature: dc.b 'HDFALL01'
_motion_fall_results: dcb.b 3*9*3*8,0
_motion_position_values: dc.w -32768,-257,-1,0,1,257,32767
_motion_position_carries: dc.l -127,0,127
_motion_position_signature: dc.b 'HDPOS001'
_motion_position_results: dcb.b 7*7*9*3*8,0
_motion_fall_position_values: dc.w -32768,-1,0,1,32767
_motion_fall_position_signature: dc.b 'HDFPOS01'
_motion_fall_position_results: dcb.b 5*3*3*9*8,0
_motion_drift_values: dc.w -32768,-301,-1,0,1,301,32767
_motion_drift_fake: dcb.b 32,0
_motion_drift_math_signature: dc.b 'HDDRIFTM'
_motion_drift_results: dcb.b 7*8*20,0
_motion_crash_fake: dc.w 0
_motion_crash_math_signature: dc.b 'HDCRASHT'
_motion_crash_results: dcb.b 74,0
	ENDC
