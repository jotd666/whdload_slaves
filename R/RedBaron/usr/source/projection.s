; G1: exact sim:38c82 arithmetic, preserving its register and shift contracts.
projection_install:
	movem.l d0-a6,-(sp)
	move.l #$38c82,d0
	moveq #6,d1
	lea projection_expected(pc),a0
	bsr perf_check_bytes
	lea projection_original_tail+2(pc),a0
	move.l a1,d0
	add.l #$38c88,d0
	move.l d0,(a0)
	lea projection_patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
projection_expected: dc.w $48e7,$3c3c,$2800
projection_patch:
	PL_START
	PL_P $38c82,projection_entry
	PL_END
projection_entry:
; Inline normalization avoids a BSR/RTS for each coordinate. Short exponent
; cases bypass the lookup; large/small magnitudes use the same exact byte table.
PROJECT_NORMALIZE:MACRO
	moveq #0,d1
	cmp.l #$10000,d0
	bhs .high\@
	tst.w d0
	beq .done\@
	cmp.w #$8000,d0
	IFEQ \1-16
	bhs .done\@
	ELSE
	bhs .one\@
	ENDC
	cmp.w #$4000,d0
	IFEQ \1-15
	bhs .done\@
	ELSE
	bhs .one\@
	ENDC
	move.l d0,d6
	moveq #-\1,d1
	cmp.w #$100,d6
	blo.b .left_lookup\@
	lsr.w #8,d6
	addq.w #8,d1
.left_lookup\@
	move.b (a2,d6.w),d6
	add.w d6,d1
	neg.w d1
	lsl.w d1,d0
	neg.w d1
	bra.b .done\@
.one\@
	IFEQ \1-15
	moveq #1,d1
	lsr.l #1,d0
	ELSE
	moveq #-1,d1
	lsl.w #1,d0
	ENDC
	bra.b .done\@
.high\@
	move.l d0,d6
	swap d6
	and.l #$ffff,d6
	moveq #16-\1,d1
	cmp.w #$100,d6
	blo.b .right_lookup\@
	lsr.w #8,d6
	addq.w #8,d1
.right_lookup\@
	move.b (a2,d6.w),d6
	add.w d6,d1
	lsr.l d1,d0
.done\@
	ENDM

projection_fast:
	; A zero denominator retains the original DIVU trap and its original PC.
	tst.l d2
	beq projection_original
	movem.l d2-d6/a2-a5,-(sp)
	move.l d0,d4
	eor.l d2,d4
	eor.l d3,d4
	move.l d4,a0
	move.l d1,d4
	eor.l d2,d4
	eor.l d3,d4
	move.l d4,a1
	tst.l d0
	bpl.b .x
	neg.l d0
.x
	tst.l d1
	bpl.b .z
	neg.l d1
.z
	tst.l d2
	bpl.b .y
	neg.l d2
.y
	tst.l d3
	beq .zero
	bpl.b .k
	neg.l d3
.k
	move.l d0,d4
	or.l d1,d4
	beq .zero
	move.l d0,d4
	move.l d1,d5
	lea projection_lengths(pc),a2
	cmp.l #128,d3
	bne.b .general_k
	move.l #$4000,d3
	moveq #-7,d1
	bra .k_ready
.general_k
	move.l d3,d0
	PROJECT_NORMALIZE 15
	move.l d0,d3
.k_ready
	move.l d1,a3
	move.l d4,d0
	PROJECT_NORMALIZE 15
	move.l d0,d4
	move.l d1,a4
	move.l d5,d0
	PROJECT_NORMALIZE 15
	move.l d0,d5
	move.l d1,a5
	move.l d2,d0
	PROJECT_NORMALIZE 16
	move.l d0,d2
	move.l d1,a2
	moveq #0,d0
	tst.w d4
	beq.b .no_x
	move.w d4,d0
	mulu.w d3,d0
	divu.w d2,d0
	and.l #$ffff,d0
.no_x
	moveq #0,d1
	tst.w d5
	beq.b .no_z
	move.w d5,d1
	mulu.w d3,d1
	divu.w d2,d1
	and.l #$ffff,d1
.no_z
	adda.w a3,a4
	suba.w a2,a4
	adda.w a3,a5
	suba.w a2,a5
	move.w a4,d4
	bmi.b .x_right
	lsl.l d4,d0
	bra.b .x_shifted
.x_right
	neg.w d4
	lsr.l d4,d0
.x_shifted
	move.w a5,d5
	bmi.b .z_right
	lsl.l d5,d1
	bra.b .z_shifted
.z_right
	neg.w d5
	lsr.l d5,d1
.z_shifted
	move.l a0,d2
	bpl.b .x_sign
	neg.l d0
.x_sign
	move.l a1,d2
	bpl.b .done
	neg.l d1
	bra.b .done
.zero
	moveq #0,d0
	moveq #0,d1
.done
	movem.l (sp)+,d2-d6/a2-a5
projection_return:
	rts
projection_original:
	movem.l d2-d5/a2-a5,-(sp)
	move.l d0,d4
projection_original_tail:
	jmp $0.l

projection_lengths:
	dc.b 0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4
	dc.b 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	dc.b 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
	dc.b 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
	dc.b 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	dc.b 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	dc.b 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	dc.b 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	dc.b 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	dc.b 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	dc.b 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	dc.b 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	dc.b 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	dc.b 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	dc.b 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	dc.b 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
