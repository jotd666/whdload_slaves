; Development arithmetic for partial wheel contact. Included with MOTION.
; Keep quantities in Q16 until after
; computing both the correction and its derivative; quantizing first loses
; small-T feedback. The zero-time caller must preserve its prior feedback rate.
;
; D0.W signed angular error (abs<=720), D1.W unsigned fields0..65535, D2.W nonzero=half rate.
; Return D0.L correction Q16, D1.L feedback rate Q16. Preserve other registers.
; Gain=1-(3/4)^T; rate gain=Gain/T. Up to8 fields, tables round both
; independently (<=0.5 coefficient LSB error). Above8, feedback derives from
; the rounded gain, with <=0.5+4/fields LSB error. T=1 uses native truncation
; and arithmetic half-rate rounding exactly rather than retaining a new fraction.
_contact_response:
	movem.l d2-d4/a0,-(a7)
	tst.w d1
	beq .zero
	cmpi.w #8,d1
	beq.s .native
	bhi.s .wide
	move.w d0,d3
	add.w d1,d1
	lea _contact_gain(pc),a0
	muls.w (a0,d1.w),d0
	lea _contact_rate_gain(pc),a0
	muls.w (a0,d1.w),d3
	tst.w d2
	beq.s .rate
	asr.l #1,d3
.rate:
	move.l d3,d1
	bra .done
.wide:
	moveq #0,d4
	move.w d1,d4
	move.w d0,d3
	bsr _decay_contact
	cmpi.l #$10000,d1
	beq.s .full_correction
	tst.w d0
	bpl.s .positive_error
	neg.w d0
	mulu.w d1,d0
	neg.l d0
	bra.s .feedback
.positive_error:
	mulu.w d1,d0
	bra.s .feedback
.full_correction:
	swap d0
	clr.w d0
.feedback:
	cmp.w _time_frame_constants(pc),d4
	bne.s .rate_uncached
	move.l _time_frame_constants+FC_RATE(pc),d1
	bra.s .rate_ready
.rate_uncached:
	; Round Gain/T to Q16 after the independently rounded Gain. Maximum
	; coefficient error versus the exact function is <=0.5+4/fields LSB.
	lsl.l #3,d1
	move.l d4,-(a7)
	lsr.l #1,d4
	add.l d4,d1
	move.l (a7)+,d4
	divu.w d4,d1
.rate_ready:
	muls.w d1,d3
	tst.w d2
	beq.s .wide_rate
	asr.l #1,d3
.wide_rate:
	move.l d3,d1
	bra.s .done
.native:
	ext.l d0
	divs.w #4,d0
	ext.l d0
	move.w d0,d1
	tst.w d2
	beq.s .native_rate
	asr.w #1,d1
.native_rate:
	swap d0
	clr.w d0
	swap d1
	clr.w d1
	bra.s .done
.zero:
	moveq #0,d0
	moveq #0,d1
.done:
	movem.l (a7)+,d2-d4/a0
	rts
_contact_gain:
	dc.w 0,2315,4548,6702,8780,10785,12719,14584,16384
_contact_rate_gain:
	dc.w 0,18519,18192,17872,17560,17256,16958,16668,16384

; D0.L signed Q16 value (abs<=16383 units), D1.W signed Q14 factor (abs<=16384).
; Return floor(D0*D1/16384) in Q16; preserve D1 and other registers. Split the
; signed integer and unsigned fractional parts to avoid a 48-bit product on 000.
; This supports wide pitch/velocity projection without rounding the input first.
_contact_project_q16:
	; Exact zero and Q14 identity cases; callers consume the value, not CCR.
	tst.l d0
	beq.s .identity
	cmpi.w #16384,d1
	beq.s .identity
	movem.l d1-d3,-(a7)
	move.l d0,d2
	andi.l #$ffff,d2
	swap d0
	muls.w d1,d0
	lsl.l #2,d0
	move.w d1,d3
	bpl.s .positive
	neg.w d1
.positive:
	mulu.w d1,d2
	tst.w d3
	bpl.s .product
	neg.l d2
.product:
	asr.l #7,d2
	asr.l #7,d2
	add.l d2,d0
	movem.l (a7)+,d1-d3
.identity:
	rts

; Full Q16 roll/pitch feedback, plus last published integer word. Native
; absolute writers invalidate the full value; same-value resets call reset.
_contact_rate_signature: dc.b 'HDCRATE1'
_contact_rates: dcb.b 16,0
_contact_reset:
	move.l a0,-(a7)
	lea _contact_rates(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	movea.l (a7)+,a0
	rts
; A0 -> full rate,last word; A1 -> game rate. Return D0 Q16.
_contact_read_rate:
	move.w (a1),d0
	cmp.w 4(a0),d0
	beq.s .current
	move.w d0,4(a0)
	swap d0
	clr.w d0
	move.l d0,(a0)
.current:
	move.l (a0),d0
	rts
; D1 Q16 -> full shadow and truncated native word. Return integer D0.
_contact_write_rate:
	move.l d1,(a0)
	move.l d1,d0
	bsr _time_split_q16
	move.w d0,4(a0)
	move.w d0,(a1)
	rts
; D0 full Q16 rate, abs<16383; return floor(rate*fields/8). Preserve D1/D2.
_contact_scale_rate:
	movem.l d1-d2,-(a7)
	move.w _time_scalar_fields(pc),d1
	move.l d0,d2
	andi.l #$ffff,d2
	swap d0
	muls.w d1,d0
	lsl.l #8,d0
	lsl.l #5,d0
	mulu.w d1,d2
	lsr.l #3,d2
	add.l d2,d0
	movem.l (a7)+,d1-d2
	rts
; Integrate a full Q16 angular rate into A1's angle with A0's companion.
; Short intervals keep the original helpers. At fields>8, retain the complete
; signed64 rate*fields product until after adding the prior Q16 remainder.
; Normalize the complete angle before its word store. D0 is scratch; preserve
; D1-D5/A0/A1.
_contact_integrate_rate:
	; With zero rate/carry and an already canonical angle the result is
	; unchanged, even after a stale LAST value. Publish LAST as usual.
	tst.l d0
	bne.s .integrate
	tst.l (a0)
	bne.s .integrate
	cmpi.w #720,(a1)
	bgt.s .integrate
	cmpi.w #-720,(a1)
	blt.s .integrate
	move.w (a1),4(a0)
	; Preserve even the historical scratch result: wide returns the angle,
	; short returns a zero integer increment. No caller needs new semantics.
	move.l d1,-(a7)
	move.w _time_scalar_fields(pc),d1
	cmpi.w #8,d1
	bls.s .zero_done
	move.w (a1),d0
	ext.l d0
.zero_done:
	move.l (a7)+,d1
	rts
.integrate:
	movem.l d1-d4,-(a7)
	move.w _time_scalar_fields(pc),d1
	cmpi.w #8,d1
	bhi.s .wide
	movem.l (a7)+,d1-d4
	bsr _contact_scale_rate
	bra _contact_add_angle
.wide:
	move.w (a1),d2
	sub.w 4(a0),d2
	beq.s .current
	cmpi.w #1440,d2
	beq.s .current
	cmpi.w #-1440,d2
	beq.s .current
	clr.l (a0)
.current:
	bsr _time_product_s32_u16
	lsr.l #3,d0
	move.l d2,d4
	; Only the low three high-product bits enter the low long. A rotate
	; and mask is identical to <<29 without a 29-bit 68000 shift.
	ror.l #3,d4
	andi.l #$e0000000,d4
	or.l d4,d0
	asr.l #3,d2
	move.l (a0),d3
	moveq #0,d4
	tst.l d3
	bpl.s .carry
	moveq #-1,d4
.carry:
	add.l d3,d0
	addx.l d4,d2
	move.l d0,d3
	andi.l #$ffff,d3
	swap d0
	andi.l #$ffff,d0
	swap d2
	clr.w d2
	or.l d2,d0
	tst.l d0
	bpl.s .angle
	tst.l d3
	beq.s .angle
	addq.l #1,d0
	subi.l #$10000,d3
.angle:
	move.l d3,(a0)
	move.w (a1),d1
	ext.l d1
	add.l d1,d0
	bsr _time_normalize_angle
	move.w d0,(a1)
	move.w d0,4(a0)
	movem.l (a7)+,d1-d4
	rts

; A0 angle carry/last, A1 game angle, D0 Q16 correction. Preserve D1/D2.
_contact_add_angle:
	movem.l d1-d2,-(a7)
	move.w (a1),d1
	sub.w 4(a0),d1
	beq.s .current
	cmpi.w #1440,d1
	beq.s .current
	cmpi.w #-1440,d1
	beq.s .current
	clr.l (a0)
.current:
	add.l (a0),d0
	bsr _time_split_q16
	move.l d2,(a0)
	add.w d0,(a1)
	move.w (a1),4(a0)
	movem.l (a7)+,d1-d2
	rts
; Native roll cosine, retaining a Q16 input until after projection. At T=1
; retain the game's word projection rounding for exact native-step equivalence.
_contact_pitch_projection:
	; Zero rate stays zero for every roll angle, including native n8 rounding.
	tst.l d0
	beq.s .zero
	movem.l d1-d3/a0-a1,-(a7)
	move.l d0,-(a7)
	move.w -$66b2(a4),-(a7)
	jsr -$7f2c(a4)
	addq.w #2,a7
	move.w d0,d1
	move.l (a7)+,d0
	bsr _contact_project_q16
	move.w _time_scalar_fields(pc),d1
	cmpi.w #8,d1
	bne.s .done
	clr.w d0
.done:
	movem.l (a7)+,d1-d3/a0-a1
.zero:
	rts

_contact_roll:
	movem.l d1-d4/a0-a2,-(a7)
	IFD VERIFY_CONTACT_TRACE
	lea _contact_rates(pc),a0
	move.w d0,6(a0)
	ENDC
	move.w _time_scalar_fields(pc),d1
	beq.s .done
	neg.w d0
	moveq #1,d2
	bsr _contact_response
	move.l d0,d4
	lea _contact_rates(pc),a0
	lea -$66ec(a4),a1
	bsr _contact_write_rate
	move.l d0,-(a7)
	move.l d4,d0
	lea _motion_state+MS_ROLL(pc),a0
	lea -$66b2(a4),a1
	bsr _contact_add_angle
	move.l (a7)+,d0
.done:
	movem.l (a7)+,d1-d4/a0-a2
	rts
_contact_pitch:
	movem.l d1-d4/a0-a2,-(a7)
	IFD VERIFY_CONTACT_TRACE
	lea _contact_rates(pc),a0
	move.w d0,14(a0)
	ENDC
	move.w _time_scalar_fields(pc),d1
	beq.s .done
	neg.w d0
	moveq #1,d2
	bsr _contact_response
	move.l d0,d4
	lea _contact_rates+8(pc),a0
	lea -$66ea(a4),a1
	bsr _contact_write_rate
	move.l d0,-(a7)
	move.l d4,d0
	bsr _contact_pitch_projection
	lea _motion_state+MS_PITCH(pc),a0
	lea -$66b4(a4),a1
	bsr _contact_add_angle
	move.l (a7)+,d0
.done:
	movem.l (a7)+,d1-d4/a0-a2
	rts
_contact_pitch_rate_only:
	movem.l d1-d2/a0-a1,-(a7)
	IFND VERIFY_DISPATCH_NATIVE
	; Native arcsine returns zero outside its domain. At variable intervals
	; a rendered end face can supply that invalid input; retain angular motion
	; instead of treating the sentinel as a real zero-rate constraint.
	move.w _time_scalar_fields(pc),d1
	cmpi.w #8,d1
	beq.s .valid_input
	cmpi.w #180,-4(a5)
	bgt.s .done
	cmpi.w #-180,-4(a5)
	blt.s .done
.valid_input:
	ENDC
	IFD VERIFY_CONTACT_TRACE
	lea _contact_rates(pc),a0
	move.w d0,14(a0)
	ENDC
	move.w _time_scalar_fields(pc),d1
	beq.s .done
	neg.w d0
	moveq #0,d2
	bsr _contact_response
	lea _contact_rates+8(pc),a0
	lea -$66ea(a4),a1
	bsr _contact_write_rate
.done:
	movem.l (a7)+,d1-d2/a0-a1
	rts
; Do not snap roll to zero while its integer rate is zero but fraction is not.
_contact_roll_active:
	movem.l d0/a0-a1,-(a7)
	lea _contact_rates(pc),a0
	lea -$66ec(a4),a1
	bsr _contact_read_rate
	tst.l d0
	beq.s .done
	movea.l _code_start(pc),a0
	adda.l #$cda0,a0
	move.l a0,12(a7)
.done:
	movem.l (a7)+,d0/a0-a1
	rts

	IFD VERIFY_CONTACT_MATH
_contact_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _contact_errors(pc),a6
	lea _contact_response_results(pc),a2
	moveq #8,d7
.error:
	move.w (a6)+,d4
	moveq #0,d5
.fields:
	moveq #0,d2
.half:
	move.w d4,d0
	move.w d5,d1
	bsr _contact_response
	move.l d0,(a2)+
	move.l d1,(a2)+
	addq.w #1,d2
	cmpi.w #1,d2
	ble.s .half
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .fields
	dbf d7,.error
	lea _contact_errors(pc),a6
	lea _contact_wide_results(pc),a2
	moveq #8,d7
.wide_error:
	move.w (a6)+,d4
	lea _contact_wide_fields(pc),a3
	moveq #11,d6
.wide_field:
	move.w (a3)+,d5
	moveq #0,d2
.wide_half:
	move.w d4,d0
	move.w d5,d1
	bsr _contact_response
	move.l d0,(a2)+
	move.l d1,(a2)+
	addq.w #1,d2
	cmpi.w #1,d2
	ble.s .wide_half
	dbf d6,.wide_field
	dbf d7,.wide_error
	lea _contact_errors(pc),a6
	lea _contact_projection_results(pc),a2
	moveq #8,d7
.projection_value:
	move.w (a6)+,d4
	swap d4
	clr.w d4
	lea _contact_fractions(pc),a3
	moveq #2,d6
.projection_fraction:
	move.l d4,d5
	add.l (a3)+,d5
	lea _contact_factors(pc),a1
	moveq #6,d3
.projection_factor:
	move.l d5,d0
	move.w (a1)+,d1
	bsr _contact_project_q16
	move.l d0,(a2)+
	dbf d3,.projection_factor
	dbf d6,.projection_fraction
	dbf d7,.projection_value
	lea _contact_roll_fake(pc),a4
	adda.l #$66ec,a4
	lea _time_scalar_fields(pc),a5
	lea _contact_roll_errors(pc),a6
	lea _contact_roll_results(pc),a2
	moveq #4,d7
.live_roll_error:
	move.w (a6)+,d4
	moveq #0,d5
.live_roll_fields:
	bsr _motion_reset
	move.w d5,(a5)
	move.w #100,-$66b2(a4)
	move.w #100,-$66b8(a4)
	clr.w -$66ec(a4)
	move.w d4,d0
	bsr _contact_roll
	move.w -$66b2(a4),(a2)+
	move.w -$66ec(a4),(a2)+
	move.l _contact_rates(pc),(a2)+
	move.l _motion_state+MS_ROLL(pc),(a2)+
	move.w -$66b2(a4),-$66b8(a4)
	bsr _motion_roll_base
	move.w -$66b2(a4),(a2)+
	move.l _motion_state+MS_ROLL(pc),(a2)+
	; Same-integer reset must clear the full feedback, including tiny fractions.
	bsr _motion_contact_rates
	move.l _contact_rates(pc),(a2)+
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .live_roll_fields
	dbf d7,.live_roll_error
	lea _contact_pitch_fake(pc),a4
	move.w #$4ef9,(a4)
	lea _contact_cos_stub(pc),a0
	move.l a0,2(a4)
	; This diagnostic JMP must be coherent before the pitch test calls it.
	bsr _fcache
	adda.l #$7f2c,a4
	lea _contact_pitch_errors(pc),a6
	lea _contact_pitch_results(pc),a2
	moveq #2,d7
.live_pitch_error:
	move.w (a6)+,d4
	moveq #0,d5
.live_pitch_fields:
	lea _contact_pitch_factors(pc),a3
	moveq #4,d6
.live_pitch_factor:
	bsr _motion_reset
	move.w d5,(a5)
	lea _contact_cos_value(pc),a0
	move.w (a3)+,(a0)
	move.w #100,-$66b4(a4)
	clr.w -$66ea(a4)
	move.w d4,d0
	bsr _contact_pitch
	move.w -$66b4(a4),(a2)+
	move.w -$66ea(a4),(a2)+
	move.l _contact_rates+8(pc),(a2)+
	move.l _motion_state+MS_PITCH(pc),(a2)+
	; The patch wrapper consumes the original native word argument itself.
	move.w -$66ea(a4),-(a7)
	bsr _motion_pitch_rate
	move.w -$66b4(a4),(a2)+
	move.l _motion_state+MS_PITCH(pc),(a2)+
	bsr _motion_contact_rates
	move.l _contact_rates+8(pc),(a2)+
	dbf d6,.live_pitch_factor
	addq.w #1,d5
	cmpi.w #8,d5
	ble.s .live_pitch_fields
	dbf d7,.live_pitch_error
	move.w #VERIFY_SCALAR_FIELDS,(a5)
	bsr _motion_reset
	movem.l (a7)+,d0-d7/a0-a6
	rts
; Private fake jump vector supplies a controlled cosine; no game state writes.
_contact_cos_stub:
	move.w _contact_cos_value(pc),d0
	rts
_contact_cos_value: dc.w 0
_contact_pitch_errors: dc.w -5,1,5
_contact_pitch_factors: dc.w -16384,-8192,0,8192,16384
_contact_pitch_fake: dcb.b $1880,0
_contact_pitch_signature: dc.b 'HDCPITC1'
_contact_pitch_results: dcb.b 3*9*5*22,0
_contact_roll_errors: dc.w -5,-1,0,1,5
_contact_roll_fake: dcb.b 64,0
_contact_roll_signature: dc.b 'HDCLIVE1'
_contact_roll_results: dcb.b 5*9*22,0
_contact_errors: dc.w -720,-361,-5,-1,0,1,5,361,720
_contact_fractions: dc.l -65535,0,65535
_contact_factors: dc.w -16384,-8192,-1,0,1,8192,16384
_contact_response_signature: dc.b 'HDCRESP1'
_contact_response_results: dcb.b 9*9*2*8,0
_contact_projection_signature: dc.b 'HDCPROJ1'
_contact_projection_results: dcb.b 9*3*7*4,0
_contact_wide_fields: dc.w 9,15,31,63,127,255,327,328,655,32767,32768,65535
_contact_wide_signature: dc.b 'HDCWIDE1'
_contact_wide_results: dcb.l 9*12*2*2,0
	ENDC

	IFD VERIFY_ANGLE_WIDE_MATH
HD_ANGLE_CASE: MACRO
	dc.l \1
	dc.w \2,\3,\4
	dc.l \5
	ENDM
_angle_wide_test:
	movem.l d0-d7/a0-a4,-(a7)
	lea _angle_normalize_inputs(pc),a3
	lea _angle_normalize_results(pc),a4
	move.w #18,d7
.normalize:
	move.l (a3)+,d0
	bsr _time_normalize_angle
	move.l d0,(a4)+
	dbf d7,.normalize
	lea _angle_contact_inputs(pc),a3
	lea _angle_contact_results(pc),a4
	move.w #95,d7
.contact:
	bsr _angle_fixture_load
	bsr _contact_integrate_rate
	bsr _angle_fixture_save
	dbf d7,.contact
	lea _angle_motion_inputs(pc),a3
	lea _angle_motion_results(pc),a4
	move.w #91,d7
.motion:
	bsr _angle_fixture_load
	bsr _motion_angle_rate
	add.w d0,(a1)
	bsr _angle_fixture_save
	dbf d7,.motion
	lea _time_scalar_fields(pc),a0
	move.w #VERIFY_SCALAR_FIELDS,(a0)
	movem.l (a7)+,d0-d7/a0-a4
	rts
; Each input is rate.l,fields.w,current.w,last.w,carry.l.
_angle_fixture_load:
	move.l (a3)+,d0
	lea _time_scalar_fields(pc),a0
	move.w (a3)+,(a0)
	lea _angle_fixture_current(pc),a1
	move.w (a3)+,(a1)
	lea _angle_fixture_state(pc),a0
	move.w (a3)+,4(a0)
	move.l (a3)+,(a0)
	rts
_angle_fixture_save:
	move.w (a1),(a4)+
	move.w 4(a0),(a4)+
	move.l (a0),(a4)+
	rts
_angle_fixture_state: dc.l 0
	dc.w 0
_angle_fixture_current: dc.w 0
_angle_normalize_inputs:
	dc.l -2147483648,-134000000,-2881,-2161,-1441,-1440,-721,-720,-1,0,1,720,721,1440,1441,2161,2881,134000000,2147483647
_angle_normalize_signature: dc.b 'HDANORM1'
_angle_normalize_results: dcb.l 19,0
_angle_contact_inputs:
	HD_ANGLE_CASE -1073676287,9,719,719,65535
	HD_ANGLE_CASE -1073676287,9,-719,721,-65535
	HD_ANGLE_CASE -1073676287,9,100,20,-1
	HD_ANGLE_CASE -1073676287,15,719,719,65535
	HD_ANGLE_CASE -1073676287,15,-719,721,-65535
	HD_ANGLE_CASE -1073676287,15,100,20,-1
	HD_ANGLE_CASE -1073676287,255,719,719,65535
	HD_ANGLE_CASE -1073676287,255,-719,721,-65535
	HD_ANGLE_CASE -1073676287,255,100,20,-1
	HD_ANGLE_CASE -1073676287,65535,719,719,65535
	HD_ANGLE_CASE -1073676287,65535,-719,721,-65535
	HD_ANGLE_CASE -1073676287,65535,100,20,-1
	HD_ANGLE_CASE -360448,9,719,719,65535
	HD_ANGLE_CASE -360448,9,-719,721,-65535
	HD_ANGLE_CASE -360448,9,100,20,-1
	HD_ANGLE_CASE -360448,15,719,719,65535
	HD_ANGLE_CASE -360448,15,-719,721,-65535
	HD_ANGLE_CASE -360448,15,100,20,-1
	HD_ANGLE_CASE -360448,255,719,719,65535
	HD_ANGLE_CASE -360448,255,-719,721,-65535
	HD_ANGLE_CASE -360448,255,100,20,-1
	HD_ANGLE_CASE -360448,65535,719,719,65535
	HD_ANGLE_CASE -360448,65535,-719,721,-65535
	HD_ANGLE_CASE -360448,65535,100,20,-1
	HD_ANGLE_CASE -1,9,719,719,65535
	HD_ANGLE_CASE -1,9,-719,721,-65535
	HD_ANGLE_CASE -1,9,100,20,-1
	HD_ANGLE_CASE -1,15,719,719,65535
	HD_ANGLE_CASE -1,15,-719,721,-65535
	HD_ANGLE_CASE -1,15,100,20,-1
	HD_ANGLE_CASE -1,255,719,719,65535
	HD_ANGLE_CASE -1,255,-719,721,-65535
	HD_ANGLE_CASE -1,255,100,20,-1
	HD_ANGLE_CASE -1,65535,719,719,65535
	HD_ANGLE_CASE -1,65535,-719,721,-65535
	HD_ANGLE_CASE -1,65535,100,20,-1
	HD_ANGLE_CASE 0,9,719,719,65535
	HD_ANGLE_CASE 0,9,-719,721,-65535
	HD_ANGLE_CASE 0,9,100,20,-1
	HD_ANGLE_CASE 0,15,719,719,65535
	HD_ANGLE_CASE 0,15,-719,721,-65535
	HD_ANGLE_CASE 0,15,100,20,-1
	HD_ANGLE_CASE 0,255,719,719,65535
	HD_ANGLE_CASE 0,255,-719,721,-65535
	HD_ANGLE_CASE 0,255,100,20,-1
	HD_ANGLE_CASE 0,65535,719,719,65535
	HD_ANGLE_CASE 0,65535,-719,721,-65535
	HD_ANGLE_CASE 0,65535,100,20,-1
	HD_ANGLE_CASE 1,9,719,719,65535
	HD_ANGLE_CASE 1,9,-719,721,-65535
	HD_ANGLE_CASE 1,9,100,20,-1
	HD_ANGLE_CASE 1,15,719,719,65535
	HD_ANGLE_CASE 1,15,-719,721,-65535
	HD_ANGLE_CASE 1,15,100,20,-1
	HD_ANGLE_CASE 1,255,719,719,65535
	HD_ANGLE_CASE 1,255,-719,721,-65535
	HD_ANGLE_CASE 1,255,100,20,-1
	HD_ANGLE_CASE 1,65535,719,719,65535
	HD_ANGLE_CASE 1,65535,-719,721,-65535
	HD_ANGLE_CASE 1,65535,100,20,-1
	HD_ANGLE_CASE 360448,9,719,719,65535
	HD_ANGLE_CASE 360448,9,-719,721,-65535
	HD_ANGLE_CASE 360448,9,100,20,-1
	HD_ANGLE_CASE 360448,15,719,719,65535
	HD_ANGLE_CASE 360448,15,-719,721,-65535
	HD_ANGLE_CASE 360448,15,100,20,-1
	HD_ANGLE_CASE 360448,255,719,719,65535
	HD_ANGLE_CASE 360448,255,-719,721,-65535
	HD_ANGLE_CASE 360448,255,100,20,-1
	HD_ANGLE_CASE 360448,65535,719,719,65535
	HD_ANGLE_CASE 360448,65535,-719,721,-65535
	HD_ANGLE_CASE 360448,65535,100,20,-1
	HD_ANGLE_CASE 1073676287,9,719,719,65535
	HD_ANGLE_CASE 1073676287,9,-719,721,-65535
	HD_ANGLE_CASE 1073676287,9,100,20,-1
	HD_ANGLE_CASE 1073676287,15,719,719,65535
	HD_ANGLE_CASE 1073676287,15,-719,721,-65535
	HD_ANGLE_CASE 1073676287,15,100,20,-1
	HD_ANGLE_CASE 1073676287,255,719,719,65535
	HD_ANGLE_CASE 1073676287,255,-719,721,-65535
	HD_ANGLE_CASE 1073676287,255,100,20,-1
	HD_ANGLE_CASE 1073676287,65535,719,719,65535
	HD_ANGLE_CASE 1073676287,65535,-719,721,-65535
	HD_ANGLE_CASE 1073676287,65535,100,20,-1
	HD_ANGLE_CASE -360448,1,100,100,-1
	HD_ANGLE_CASE -360448,1,100,100,1
	HD_ANGLE_CASE -360448,8,100,100,-1
	HD_ANGLE_CASE -360448,8,100,100,1
	HD_ANGLE_CASE 360448,1,100,100,-1
	HD_ANGLE_CASE 360448,1,100,100,1
	HD_ANGLE_CASE 360448,8,100,100,-1
	HD_ANGLE_CASE 360448,8,100,100,1
	HD_ANGLE_CASE -94371840,16,719,719,-65535
	HD_ANGLE_CASE -94371840,16,719,719,65535
	HD_ANGLE_CASE 94371840,16,719,719,-65535
	HD_ANGLE_CASE 94371840,16,719,719,65535
_angle_contact_signature: dc.b 'HDACONT1'
_angle_contact_results: dcb.b 96*8,0
_angle_motion_inputs:
	HD_ANGLE_CASE -16383,9,719,719,65535
	HD_ANGLE_CASE -16383,9,-719,721,-65535
	HD_ANGLE_CASE -16383,9,100,20,-1
	HD_ANGLE_CASE -16383,15,719,719,65535
	HD_ANGLE_CASE -16383,15,-719,721,-65535
	HD_ANGLE_CASE -16383,15,100,20,-1
	HD_ANGLE_CASE -16383,255,719,719,65535
	HD_ANGLE_CASE -16383,255,-719,721,-65535
	HD_ANGLE_CASE -16383,255,100,20,-1
	HD_ANGLE_CASE -16383,65535,719,719,65535
	HD_ANGLE_CASE -16383,65535,-719,721,-65535
	HD_ANGLE_CASE -16383,65535,100,20,-1
	HD_ANGLE_CASE -5,9,719,719,65535
	HD_ANGLE_CASE -5,9,-719,721,-65535
	HD_ANGLE_CASE -5,9,100,20,-1
	HD_ANGLE_CASE -5,15,719,719,65535
	HD_ANGLE_CASE -5,15,-719,721,-65535
	HD_ANGLE_CASE -5,15,100,20,-1
	HD_ANGLE_CASE -5,255,719,719,65535
	HD_ANGLE_CASE -5,255,-719,721,-65535
	HD_ANGLE_CASE -5,255,100,20,-1
	HD_ANGLE_CASE -5,65535,719,719,65535
	HD_ANGLE_CASE -5,65535,-719,721,-65535
	HD_ANGLE_CASE -5,65535,100,20,-1
	HD_ANGLE_CASE -1,9,719,719,65535
	HD_ANGLE_CASE -1,9,-719,721,-65535
	HD_ANGLE_CASE -1,9,100,20,-1
	HD_ANGLE_CASE -1,15,719,719,65535
	HD_ANGLE_CASE -1,15,-719,721,-65535
	HD_ANGLE_CASE -1,15,100,20,-1
	HD_ANGLE_CASE -1,255,719,719,65535
	HD_ANGLE_CASE -1,255,-719,721,-65535
	HD_ANGLE_CASE -1,255,100,20,-1
	HD_ANGLE_CASE -1,65535,719,719,65535
	HD_ANGLE_CASE -1,65535,-719,721,-65535
	HD_ANGLE_CASE -1,65535,100,20,-1
	HD_ANGLE_CASE 0,9,719,719,65535
	HD_ANGLE_CASE 0,9,-719,721,-65535
	HD_ANGLE_CASE 0,9,100,20,-1
	HD_ANGLE_CASE 0,15,719,719,65535
	HD_ANGLE_CASE 0,15,-719,721,-65535
	HD_ANGLE_CASE 0,15,100,20,-1
	HD_ANGLE_CASE 0,255,719,719,65535
	HD_ANGLE_CASE 0,255,-719,721,-65535
	HD_ANGLE_CASE 0,255,100,20,-1
	HD_ANGLE_CASE 0,65535,719,719,65535
	HD_ANGLE_CASE 0,65535,-719,721,-65535
	HD_ANGLE_CASE 0,65535,100,20,-1
	HD_ANGLE_CASE 1,9,719,719,65535
	HD_ANGLE_CASE 1,9,-719,721,-65535
	HD_ANGLE_CASE 1,9,100,20,-1
	HD_ANGLE_CASE 1,15,719,719,65535
	HD_ANGLE_CASE 1,15,-719,721,-65535
	HD_ANGLE_CASE 1,15,100,20,-1
	HD_ANGLE_CASE 1,255,719,719,65535
	HD_ANGLE_CASE 1,255,-719,721,-65535
	HD_ANGLE_CASE 1,255,100,20,-1
	HD_ANGLE_CASE 1,65535,719,719,65535
	HD_ANGLE_CASE 1,65535,-719,721,-65535
	HD_ANGLE_CASE 1,65535,100,20,-1
	HD_ANGLE_CASE 5,9,719,719,65535
	HD_ANGLE_CASE 5,9,-719,721,-65535
	HD_ANGLE_CASE 5,9,100,20,-1
	HD_ANGLE_CASE 5,15,719,719,65535
	HD_ANGLE_CASE 5,15,-719,721,-65535
	HD_ANGLE_CASE 5,15,100,20,-1
	HD_ANGLE_CASE 5,255,719,719,65535
	HD_ANGLE_CASE 5,255,-719,721,-65535
	HD_ANGLE_CASE 5,255,100,20,-1
	HD_ANGLE_CASE 5,65535,719,719,65535
	HD_ANGLE_CASE 5,65535,-719,721,-65535
	HD_ANGLE_CASE 5,65535,100,20,-1
	HD_ANGLE_CASE 16383,9,719,719,65535
	HD_ANGLE_CASE 16383,9,-719,721,-65535
	HD_ANGLE_CASE 16383,9,100,20,-1
	HD_ANGLE_CASE 16383,15,719,719,65535
	HD_ANGLE_CASE 16383,15,-719,721,-65535
	HD_ANGLE_CASE 16383,15,100,20,-1
	HD_ANGLE_CASE 16383,255,719,719,65535
	HD_ANGLE_CASE 16383,255,-719,721,-65535
	HD_ANGLE_CASE 16383,255,100,20,-1
	HD_ANGLE_CASE 16383,65535,719,719,65535
	HD_ANGLE_CASE 16383,65535,-719,721,-65535
	HD_ANGLE_CASE 16383,65535,100,20,-1
	HD_ANGLE_CASE -5,1,100,100,-1
	HD_ANGLE_CASE -5,1,100,100,1
	HD_ANGLE_CASE -5,8,100,100,-1
	HD_ANGLE_CASE -5,8,100,100,1
	HD_ANGLE_CASE 5,1,100,100,-1
	HD_ANGLE_CASE 5,1,100,100,1
	HD_ANGLE_CASE 5,8,100,100,-1
	HD_ANGLE_CASE 5,8,100,100,1
_angle_motion_signature: dc.b 'HDAMOTN1'
_angle_motion_results: dcb.b 92*8,0
	ENDC
