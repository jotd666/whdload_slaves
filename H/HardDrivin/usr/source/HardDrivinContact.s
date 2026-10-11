; Development arithmetic for partial wheel contact. Included with MOTION.
; Live contact hooks are not connected yet. Keep quantities in Q16 until after
; computing both the correction and its derivative; quantizing first loses
; small-T feedback. The zero-time caller must preserve its prior feedback rate.
;
; D0.W signed angular error (abs<=720), D1.W fields0..8, D2.W nonzero=half rate.
; Return D0.L correction Q16, D1.L feedback rate Q16. Preserve other registers.
; Gain=1-(3/4)^T; rate gain=Gain/T. Tables round independently to nearest Q16,
; each with <=0.5 coefficient LSB error. T=1 follows native integer truncation
; and arithmetic half-rate rounding exactly rather than retaining a new fraction.
_contact_response:
	movem.l d2-d4/a0,-(a7)
	tst.w d1
	beq.s .zero
	cmpi.w #8,d1
	beq.s .native
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
	movem.l (a7)+,d0-d7/a0-a6
	rts
_contact_errors: dc.w -720,-361,-5,-1,0,1,5,361,720
_contact_fractions: dc.l -65535,0,65535
_contact_factors: dc.w -16384,-8192,-1,0,1,8192,16384
_contact_response_signature: dc.b 'HDCRESP1'
_contact_response_results: dcb.b 9*9*2*8,0
_contact_projection_signature: dc.b 'HDCPROJ1'
_contact_projection_results: dcb.b 9*3*7*4,0
	ENDC
