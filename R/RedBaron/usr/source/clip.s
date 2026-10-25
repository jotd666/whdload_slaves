; G2: preserve both clipping passes' observable buffers and bound words.
clip_install:
	movem.l d0-a6,-(sp)
	move.l #$39ecc,d0
	moveq #8,d1
	lea clip_expected(pc),a0
	bsr perf_check_bytes
	move.l a1,a0
	adda.l #$39f04,a0
	lea clip_buffer(pc),a3
	move.l (a0),(a3)+
	move.l a1,a0
	adda.l #$39ed6,a0
	move.l (a0),(a3)+
	move.l a1,d0
	add.l #$39d4c,d0
	move.l d0,(a3)
	lea clip_original_tail+2(pc),a0
	move.l a1,d0
	add.l #$39ed4,d0
	move.l d0,(a0)
	lea clip_patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
clip_expected: dc.w $4e55,$0000,$48e7,$3f3a
clip_buffer: dc.l 0
clip_bounds: dc.l 0
clip_work_bounds: dc.l 0
clip_patch:
	PL_START
	PL_P $39ecc,clip_entry
	PL_END
clip_entry:
clip_fast:
	movem.l d2-d6/a2-a4,-(sp)
	move.l clip_buffer(pc),a2
	move.l clip_bounds(pc),a3
	moveq #0,d2
	move.w (a2),d2
	cmp.w #1,d2
	bls .empty
	cmp.w #20,d2
	bhi clip_fallback
	lea 2(a2),a0
	move.w (a3),d3
	ext.l d3
	move.l d3,d4
	move.w 2(a3),d4
	bsr clip_uniform
	tst.w d0
	bmi clip_fallback
	bne .empty
	lea 82(a2),a0
	move.w 4(a3),d3
	ext.l d3
	move.l d3,d4
	move.w 6(a3),d4
	bsr clip_uniform
	tst.w d0
	bmi clip_fallback
	; The original X pass writes both temporary arrays, including on Y reject.
	move.w d2,162(a2)
	tst.w d0
	beq.b .copy
	clr.w (a2)
.copy
	lea 2(a2),a0
	lea 164(a2),a1
	move.w d2,d6
	subq.w #1,d6
.copy_loop
	move.l 80(a0),80(a1)
	move.l (a0)+,(a1)+
	dbf d6,.copy_loop
	bra.b .finish
.empty
	clr.w (a2)
	clr.w 162(a2)
.finish
	move.l clip_work_bounds(pc),a0
	move.l 4(a3),(a0)
	movem.l (sp)+,d2-d6/a2-a4
clip_return:
	rts
clip_fallback:
	movem.l (sp)+,d2-d6/a2-a4
clip_original:
	link a5,#0
	movem.l d2-d7/a2-a4/a6,-(sp)
clip_original_tail:
	jmp $0.l
; Uniform outcode (0/1/2), or -1 for mixed. d3/d4 carry the original
; sign-extended lower bound and high word inherited by the upper bound.
clip_uniform:
	moveq #-1,d5
	move.w d2,d6
	subq.w #1,d6
.scan
	move.l (a0)+,d1
	moveq #1,d0
	cmp.l d3,d1
	blt.b .classified
	moveq #2,d0
	cmp.l d4,d1
	bgt.b .classified
	moveq #0,d0
.classified
	tst.w d5
	bmi.b .first
	cmp.w d5,d0
	bne.b .mixed
.first
	move.w d0,d5
	dbf d6,.scan
	rts
.mixed
	moveq #-1,d0
	rts
