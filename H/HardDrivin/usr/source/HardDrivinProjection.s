; Fractional extension interpolates adjacent native rounded velocity vectors.
; Integer projection stays native; zero carry preserves native T=1 exactly.
_projection_signature: dc.b 'HDVPROJ1'
; Current XYZ Q16 corrections, previous XYZ, then Q16 position carries.
_projection_state: dcb.l 9,0
_projection_reset:
	move.l a0,-(a7)
	lea _projection_state(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	movea.l (a7)+,a0
	rts
_projection_snapshot:
	move.l a0,-(a7)
	lea _projection_state(pc),a0
	move.l (a0),12(a0)
	move.l 4(a0),16(a0)
	move.l 8(a0),20(a0)
	movea.l (a7)+,a0
	rts
_projection_update:
	movem.l d0-d1/a0,-(a7)
	; Native skidding holds the last projected vector instead of recomputing it.
	tst.b -$50cf(a4)
	bne.s .done
	lea _time_scalar_state(pc),a0
	moveq #0,d0
	move.w -$66d8(a4),d1
	cmp.w SS_VELOCITY_LAST(a0),d1
	bne.s .project
	move.w SS_VELOCITY_CARRY(a0),d0
.project:
	lea _projection_state(pc),a0
	bsr _projection_quantized_components
.done:
	movem.l (a7)+,d0-d1/a0
	rts
; Interpolate the native rounded vector between adjacent integer velocities.
; Projecting only carry*1.5 can make v=1,carry=-7 point backward because native
; 1.5*v was rounded down to1. Native zero-carry states stay exact.
_projection_quantized_components:
	movem.l d0-d2/d7/a1,-(a7)
	move.w d0,d7
	beq.s .zero
	move.w -$66d8(a4),d0
	cmpi.w #21843,d0
	bgt.s .edge
	cmpi.w #-21843,d0
	blt.s .edge
	tst.w d7
	bmi.s .negative
	addq.w #1,d0
	bra.s .neighbor
.negative:
	subq.w #1,d0
	neg.w d7
.neighbor:
	bsr _projection_integer_components
	lea -$66e2(a4),a1
	sub.w (a1)+,d0
	muls.w d7,d0
	lsl.l #8,d0
	lsl.l #5,d0
	move.l d0,(a0)
	sub.w (a1)+,d1
	muls.w d7,d1
	lsl.l #8,d1
	lsl.l #5,d1
	move.l d1,4(a0)
	sub.w (a1),d2
	muls.w d7,d2
	lsl.l #8,d2
	lsl.l #5,d2
	move.l d2,8(a0)
	bra.s .done
.edge:
	; Keep the old bounded fractional projection outside the range where
	; native 1.5*v and both adjacent vectors avoid signed-word wrap.
	; Their wider solver/consumer validity remains a separate open issue.
	move.w d7,d0
	bsr _projection_components
	bra.s .done
.zero:
	clr.l (a0)
	clr.l 4(a0)
	clr.l 8(a0)
.done:
	movem.l (a7)+,d0-d2/d7/a1
	rts
; D0.W velocity; return native word XYZ in D0/D1/D2; preserve D3-D7.
; Only the low word of each native ASR14 product is consumed. Two ADD.L
; operations and SWAP select those exact bits14..29, including signed-word
; wrap, without the 68000 variable-shift loop. Callers narrow before use.
_projection_integer_components:
	move.w d0,d2
	asr.w #1,d2
	add.w d0,d2
	; Flat pitch has exact sine0/cosine16384. Avoid its two multiply/shift
	; pairs without approximating orientation or changing native word wrap.
	tst.w -$6bb4(a4)
	bne.s .pitch
	cmpi.w #16384,-$6bb2(a4)
	bne.s .pitch
	moveq #0,d1
	; Flat cardinal yaw needs only signed word extension/negation. The
	; intermediate p(v) is still narrowed to a word exactly as native MULS.
	tst.w -$6bb6(a4)
	bne.s .yaw
	cmpi.w #16384,-$6bb8(a4)
	beq.s .east
	cmpi.w #-16384,-$6bb8(a4)
	bne.s .yaw
	move.w d2,d0
	ext.l d0
	neg.l d0
	moveq #0,d2
	rts
.east:
	move.w d2,d0
	ext.l d0
	moveq #0,d2
	rts
.pitch:
	move.w d2,d1
	muls.w -$6bb4(a4),d1
	add.l d1,d1
	add.l d1,d1
	swap d1
	muls.w -$6bb2(a4),d2
	add.l d2,d2
	add.l d2,d2
	swap d2
.yaw:
	move.w d2,d0
	muls.w -$6bb8(a4),d0
	add.l d0,d0
	add.l d0,d0
	swap d0
	muls.w -$6bb6(a4),d2
	add.l d2,d2
	add.l d2,d2
	swap d2
	rts

; D0.W eighth-velocity carry [-7,7], A0 -> XYZ Q16, native Q14 trig globals.
; Factor 3/2 maps velocity to long-position units, hence carry*3*65536/16.
_projection_components:
	movem.l d1-d4,-(a7)
	muls.w #12288,d0
	move.l d0,d4
	move.w -$6bb4(a4),d1
	bsr _contact_project_q16
	move.l d0,4(a0)
	move.l d4,d0
	move.w -$6bb2(a4),d1
	bsr _contact_project_q16
	move.l d0,d4
	move.w -$6bb8(a4),d1
	bsr _contact_project_q16
	move.l d0,(a0)
	move.l d4,d0
	move.w -$6bb6(a4),d1
	bsr _contact_project_q16
	move.l d0,8(a0)
	movem.l (a7)+,d1-d4
	rts
_projection_integrate:
	movem.l d0-d5/a0-a1,-(a7)
	lea _projection_state(pc),a0
	lea -$6704(a4),a1
	move.w _time_scalar_fields(pc),d2
	moveq #2,d5
.axis:
	move.l (a0),d0
	move.l 12(a0),d1
	move.l 24(a0),d3
	bsr _projection_delta
	move.l d3,24(a0)
	add.l d0,(a1)+
	addq.l #4,a0
	dbf d5,.axis
	movem.l (a7)+,d0-d5/a0-a1
	rts
; Normalize the two position accumulators together, including their whole-unit
; outputs. Independently truncating opposite integer/fraction contributions can
; move a pixel backward while the combined displacement is still positive.
; A2 -> three positions saved before this update. Leave one Q16 carry per axis.
_projection_merge_carries:
	movem.l d0-d5/a0-a3,-(a7)
	lea _motion_position_state+8(pc),a0
	lea _projection_state+24(pc),a1
	lea -$6704(a4),a3
	moveq #2,d5
.axis:
	move.l (a0),d0
	lsl.l #8,d0
	add.l d0,d0
	add.l (a1),d0
	bsr _time_split_q16
	add.l d0,(a3)
	move.l (a3),d1
	sub.l (a2)+,d1
	beq.s .store
	bmi.s .negative
	tst.l d2
	bpl.s .store
	subq.l #1,(a3)
	addi.l #65536,d2
	bra.s .store
.negative:
	tst.l d2
	ble.s .store
	addq.l #1,(a3)
	subi.l #65536,d2
.store:
	clr.l (a0)+
	move.l d2,(a1)+
	addq.l #4,a3
	dbf d5,.axis
	movem.l (a7)+,d0-d5/a0-a3
	rts

; Same Euler correction as integer position, but for the projected fractional
; extension. D0.L current Q16, D1.L previous Q16 (each abs<=114688), D2.W fields,
; D3.L signed Q16 position carry. Returns integer D0 and Q16 carry D3.
; The /16 rounds down at Q16 precision (<1/65536 long-position unit per call).
_projection_delta:
	cmpi.w #8,d2
	bhi _projection_delta_wide
	movem.l d1-d2/d4-d5,-(a7)
	tst.w d2
	beq.s .zero
	moveq #8,d4
	add.w d2,d4
	bsr _projection_product
	move.l d0,-(a7)
	move.l d1,d0
	moveq #8,d4
	sub.w d2,d4
	bsr _projection_product
	move.l d0,d1
	move.l (a7)+,d0
	sub.l d1,d0
	asr.l #4,d0
	add.l d3,d0
	bsr _time_split_q16
	move.l d2,d3
	bra.s .done
.zero:
	moveq #0,d0
.done:
	movem.l (a7)+,d1-d2/d4-d5
	rts
; Signed long D0 times small unsigned word D4, exact within stated bounds.
_projection_product:
	move.l d0,d5
	swap d5
	muls.w d4,d5
	swap d5
	clr.w d5
	mulu.w d4,d0
	add.l d5,d0
	rts

; Wide equivalent: floor((8*(v-u)+fields*(v+u))/16), still in Q16.
; The intermediate needs signed64 bits at the unsigned field limit; the result
; plus signed Q16 carry fits a long for the documented abs(v/u)<=114688 bound.
_projection_delta_wide:
	movem.l d1-d2/d4-d6,-(a7)
	move.l d0,d4
	move.l d1,d5
	move.w d2,d6
	add.l d1,d0
	move.w d6,d1
	bsr _time_product_s32_u16
	sub.l d5,d4
	lsl.l #3,d4
	moveq #0,d5
	tst.l d4
	bpl.s .correction
	moveq #-1,d5
.correction:
	add.l d4,d0
	addx.l d5,d2
	lsr.l #4,d0
	moveq #28,d4
	lsl.l d4,d2
	or.l d2,d0
	add.l d3,d0
	bsr _time_split_q16
	move.l d2,d3
	movem.l (a7)+,d1-d2/d4-d6
	rts

	IFD VERIFY_PROJECTION_MATH
_projection_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _projection_fake(pc),a4
	adda.l #$6bb8,a4
	lea _projection_component_results(pc),a2
	moveq #-7,d7
.carry:
	lea _projection_trigs(pc),a3
	moveq #3,d6
.trig:
	move.w (a3)+,-$6bb8(a4)
	move.w (a3)+,-$6bb6(a4)
	move.w (a3)+,-$6bb4(a4)
	move.w (a3)+,-$6bb2(a4)
	move.w d7,d0
	lea _projection_state(pc),a0
	bsr _projection_components
	move.l (a0),(a2)+
	move.l 4(a0),(a2)+
	move.l 8(a0),(a2)+
	dbf d6,.trig
	addq.w #1,d7
	cmpi.w #7,d7
	ble.s .carry
	lea _projection_values(pc),a6
	lea _projection_delta_results(pc),a2
	moveq #6,d7
.new:
	move.l (a6)+,d6
	lea _projection_values(pc),a3
	moveq #6,d4
.old:
	move.l (a3)+,d1
	moveq #0,d2
.fields:
	lea _projection_carries(pc),a1
	moveq #2,d5
.fraction:
	move.l d6,d0
	move.l (a1)+,d3
	bsr _projection_delta
	move.l d0,(a2)+
	move.l d3,(a2)+
	dbf d5,.fraction
	addq.w #1,d2
	cmpi.w #8,d2
	ble.s .fields
	dbf d4,.old
	dbf d7,.new
	bsr _projection_reset
	movem.l (a7)+,d0-d7/a0-a6
	rts
_projection_fake: dcb.b 8,0
_projection_trigs:
	dc.w 0,16384,0,16384
	dc.w 11585,11585,8192,14189
	dc.w -11585,11585,-8192,14189
	dc.w 16384,0,16384,0
_projection_values: dc.l -86016,-65535,-1,0,1,65535,86016
_projection_carries: dc.l -65535,0,65535
_projection_component_signature: dc.b 'HDVPCMP1'
_projection_component_results: dcb.b 15*4*12,0
_projection_delta_signature: dc.b 'HDVPDEL1'
_projection_delta_results: dcb.b 7*7*9*3*8,0
	ENDC

	IFD VERIFY_POSITION_WIDE_MATH
_projection_wide_test:
	movem.l d0-d7/a0-a3,-(a7)
	lea _projection_wide_results(pc),a2
	lea _projection_wide_values(pc),a0
	moveq #6,d7
.new:
	move.l (a0)+,d4
	lea _projection_wide_values(pc),a1
	moveq #6,d6
.old:
	move.l (a1)+,d5
	lea _motion_wide_fields(pc),a3
	moveq #6,d2
.fields:
	move.w d2,-(a7)
	move.w (a3)+,d2
	move.l #-65535,d3
	moveq #2,d1
.carry:
	move.l d3,-(a7)
	move.w d1,-(a7)
	move.l d4,d0
	move.l d5,d1
	bsr _projection_delta
	move.l d0,(a2)+
	move.l d3,(a2)+
	move.w (a7)+,d1
	move.l (a7)+,d3
	addi.l #65535,d3
	dbf d1,.carry
	move.w (a7)+,d2
	dbf d2,.fields
	dbf d6,.old
	dbf d7,.new
	movem.l (a7)+,d0-d7/a0-a3
	rts
_projection_wide_values: dc.l -86016,-65535,-1,0,1,65535,86016
_projection_wide_signature: dc.b 'HDRPWID1'
_projection_wide_results: dcb.l 7*7*7*3*2,0
	ENDC

	IFD VERIFY_PROJECTION_QUANTIZED_MATH
	INCLUDE "HardDrivinProjectionVerify.s"
	ENDC
