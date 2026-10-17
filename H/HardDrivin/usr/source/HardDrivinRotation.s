; Exact zero-coefficient shortcuts for the two native word rotations.
; Count/sign/overflow behavior, overlapping buffers and outgoing X match native.
; Before implementation: current A500 A trace has 21,763 of 35,163 transformed
; vertices with a zero coefficient. A zero MULS costs at least 38 cycles on 000;
; generic zero paths remove two MULS (>=80 cycles/vertex before dispatch).
; Quarter turns remove all four MULS: >=152 cycles/vertex of multiplication
; replaced by <=32 cycles for negation and exact X, plus per-call dispatch.
; General nonzero arithmetic is unchanged. Word-branch dispatch/exit and the
; entry JMP add <=58 cycles per nonempty call on 68000.

_render_rotation_patches:
	PL_START
	; PERF_RANGE VERIFY_RENDER_ROTATION $02a2e $0008: Y rotation
	PL_P $02a2e,_render_rotate_y
	PL_NOP $02a34,2
	; PERF_RANGE VERIFY_RENDER_ROTATION $02a7a $0008: X rotation
	PL_P $02a7a,_render_rotate_x
	PL_NOP $02a80,2
	PL_END

_render_rotate_y:
	movem.l d3-d7,-(sp)
	move.w 24(sp),d0
	move.w 26(sp),d1
	move.w 28(sp),d2
	movea.l 30(sp),a0
	movea.l 34(sp),a1
	subq.w #1,d0
	bmi .done
	tst.w d1
	beq .zero_cos
	tst.w d2
	beq .zero_sin
.general:
	move.w (a1)+,d4
	move.w (a1)+,d6
	move.w (a1)+,d5
	move.w d4,d7
	muls.w d1,d7
	move.w d5,d3
	muls.w d2,d3
	sub.l d3,d7
	asl.l #2,d7
	swap d7
	muls.w d2,d4
	muls.w d1,d5
	add.l d4,d5
	asl.l #2,d5
	swap d5
	move.w d7,(a0)+
	move.w d6,(a0)+
	move.w d5,(a0)+
	dbf d0,.general
	bra .done
.zero_cos:
	cmpi.w #$4000,d2
	beq .quarter_positive
	cmpi.w #$c000,d2
	beq .quarter_negative
.generic_zero_cos:
	move.w (a1)+,d4
	move.w (a1)+,d6
	move.w (a1)+,d5
	muls.w d2,d5
	neg.l d5
	asl.l #2,d5
	swap d5
	move.w d5,d7
	muls.w d2,d4
	asl.l #2,d4
	swap d4
	move.w d4,d5
	move.w d7,(a0)+
	move.w d6,(a0)+
	move.w d5,(a0)+
	dbf d0,.generic_zero_cos
	bra .done
.zero_sin:
	move.w (a1)+,d4
	move.w (a1)+,d6
	move.w (a1)+,d5
	muls.w d1,d4
	asl.l #2,d4
	swap d4
	move.w d4,d7
	muls.w d1,d5
	asl.l #2,d5
	swap d5
	move.w d7,(a0)+
	move.w d6,(a0)+
	move.w d5,(a0)+
	dbf d0,.zero_sin
	bra .done
; For quarter turns, native final X is bit 30 of (signed input * +/-16384).
; Capture the signed input comparison before word negation, including -32768.
.quarter_positive:
	move.w (a1)+,d4
	move.w (a1)+,d6
	move.w (a1)+,d5
	neg.w d5
	tst.w d4
	slt d3
	lsr.b #1,d3
	move.w d5,(a0)+
	move.w d6,(a0)+
	move.w d4,(a0)+
	dbf d0,.quarter_positive
	bra .done
.quarter_negative:
	move.w (a1)+,d4
	move.w (a1)+,d6
	move.w (a1)+,d5
	tst.w d4
	sgt d3
	neg.w d4
	lsr.b #1,d3
	move.w d5,(a0)+
	move.w d6,(a0)+
	move.w d4,(a0)+
	dbf d0,.quarter_negative
.done:
	move.l a0,d0
	movem.l (sp)+,d3-d7
	rts

_render_rotate_x:
	movem.l d3-d7,-(sp)
	move.w 24(sp),d0
	move.w 26(sp),d1
	move.w 28(sp),d2
	movea.l 30(sp),a0
	movea.l 34(sp),a1
	subq.w #1,d0
	bmi .done
	tst.w d1
	beq .zero_cos
	tst.w d2
	beq .zero_sin
.general:
	move.w (a1)+,(a0)+
	move.w (a1)+,d4
	move.w (a1)+,d5
	move.w d4,d7
	muls.w d1,d7
	move.w d5,d3
	muls.w d2,d3
	sub.l d3,d7
	asl.l #2,d7
	swap d7
	muls.w d2,d4
	muls.w d1,d5
	add.l d4,d5
	asl.l #2,d5
	swap d5
	move.w d7,(a0)+
	move.w d5,(a0)+
	dbf d0,.general
	bra .done
.zero_cos:
	cmpi.w #$4000,d2
	beq .quarter_positive
	cmpi.w #$c000,d2
	beq .quarter_negative
.generic_zero_cos:
	move.w (a1)+,(a0)+
	move.w (a1)+,d4
	move.w (a1)+,d5
	muls.w d2,d5
	neg.l d5
	asl.l #2,d5
	swap d5
	move.w d5,d7
	muls.w d2,d4
	asl.l #2,d4
	swap d4
	move.w d4,d5
	move.w d7,(a0)+
	move.w d5,(a0)+
	dbf d0,.generic_zero_cos
	bra .done
.zero_sin:
	move.w (a1)+,(a0)+
	move.w (a1)+,d4
	move.w (a1)+,d5
	muls.w d1,d4
	asl.l #2,d4
	swap d4
	move.w d4,d7
	muls.w d1,d5
	asl.l #2,d5
	swap d5
	move.w d7,(a0)+
	move.w d5,(a0)+
	dbf d0,.zero_sin
	bra .done
; For quarter turns, native final X is bit 30 of (signed input * +/-16384).
; Capture the signed input comparison before word negation, including -32768.
.quarter_positive:
	move.w (a1)+,(a0)+
	move.w (a1)+,d4
	move.w (a1)+,d5
	neg.w d5
	tst.w d4
	slt d3
	lsr.b #1,d3
	move.w d5,(a0)+
	move.w d4,(a0)+
	dbf d0,.quarter_positive
	bra .done
.quarter_negative:
	move.w (a1)+,(a0)+
	move.w (a1)+,d4
	move.w (a1)+,d5
	tst.w d4
	sgt d3
	neg.w d4
	lsr.b #1,d3
	move.w d5,(a0)+
	move.w d4,(a0)+
	dbf d0,.quarter_negative
.done:
	move.l a0,d0
	movem.l (sp)+,d3-d7
	rts
