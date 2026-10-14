; VERIFY-only CPU reference test. No table or expected reversed game bytes embedded.
mirror_word_selftest:
	movem.l d0-a6,-(sp)
	lea mirror_verify_header(pc),a0
	clr.l 12(a0)
	lea mirror_table(pc),a3
	moveq #0,d3
	moveq #0,d1
.word
	move.w d3,d0
	REPT 16
	lsr.w #1,d0
	roxl.w #1,d1
	ENDR
	moveq #0,d0
	move.b d3,d0
	move.b (a3,d0.w),d2
	lsl.w #8,d2
	move.w d3,d0
	lsr.w #8,d0
	move.b (a3,d0.w),d2
	cmp.w d1,d2
	bne.b mirror_verify_fail
	addq.l #1,12(a0)
	addq.w #1,d3
	bne.b .word
	movem.l (sp)+,d0-a6
	rts
mirror_verify_fail:
	pea mirror_verify_message(pc)
	pea TDREASON_FAILMSG
	lea .resload_base(pc),a2
.resload_base
	adda.l #_resload-.resload_base,a2
	move.l (a2),a2
	jmp resload_Abort(a2)
mirror_verify_message:
	dc.b "Red Baron: W1 mirror verification mismatch",0
	even
mirror_verify_header:
	dc.b "RBMIRR01"
	dc.l 1,0,0,0

; CUSTOM5 bit 5: run the original on a private copy before each optimized call.
; Diagnostics add allocation and reference execution; never use them for timing.
mirror_live_twin:
	movem.l d0-a6,-(sp)
	lea mirror_twin_context(pc),a5
	move.l a0,(a5)
	moveq #0,d0
	move.w 8(a0),d0
	beq mirror_verify_fail
	cmp.w #320,d0
	bhi mirror_verify_fail
	add.w #15,d0
	lsr.w #4,d0
	add.w d0,d0
	moveq #0,d1
	move.w 10(a0),d1
	beq mirror_verify_fail
	cmp.w #200,d1
	bhi mirror_verify_fail
	mulu.w d1,d0
	move.l mirror_depth_ptr(pc),a1
	mulu.w (a1),d0
	move.l d0,4(a5)
	move.w 8(a0),d0
	add.w #15,d0
	lsr.w #4,d0
	addq.w #1,d0
	add.w d0,d0
	mulu.w d1,d0
	move.l d0,8(a5)
	add.l 4(a5),d0
	move.l d0,12(a5)
	add.l #32,d0
	move.l #1,d1
	move.l 4.w,a6
	jsr _LVOAllocMem(a6)
	tst.l d0
	beq mirror_verify_fail
	move.l d0,16(a5)
	move.l d0,a1
	moveq #7,d1
.guard
	move.l #$6d697272,(a1)+
	dbf d1,.guard
	move.l (a5),a0
	lea mirror_twin_descriptor(pc),a2
	moveq #8,d0
.desc
	move.w (a0)+,(a2)+
	dbf d0,.desc
	lea mirror_twin_descriptor(pc),a2
	move.l 16(a5),d0
	add.l #16,d0
	move.l d0,(a2)
	add.l 4(a5),d0
	move.l d0,4(a2)
	move.l (a5),a0
	move.l (a0),a0
	move.l (a2),a1
	move.l 4(a5),d0
	bsr mirror_twin_copy
	move.l (a5),a0
	move.l 4(a0),a0
	move.l 4(a2),a1
	move.l 8(a5),d0
	bsr mirror_twin_copy
	move.l 16(a5),a1
	adda.l #16,a1
	adda.l 12(a5),a1
	moveq #3,d0
.end_guard
	move.l #$6d697272,(a1)+
	dbf d0,.end_guard
	lea mirror_twin_descriptor(pc),a0
	bsr mirror_checked_original
	move.l (a5),a0
	bsr mirror_checked_fast
	move.l (a5),a0
	move.l (a0),a0
	move.l mirror_twin_descriptor(pc),a1
	move.l 4(a5),d0
	bsr mirror_twin_compare
	move.l (a5),a0
	move.l 4(a0),a0
	move.l mirror_twin_descriptor+4(pc),a1
	move.l 8(a5),d0
	bsr mirror_twin_compare
	; Dimensions, plane size and orientation must remain unchanged too.
	move.l (a5),a0
	addq.l #8,a0
	lea mirror_twin_descriptor+8(pc),a1
	moveq #10,d0
	bsr mirror_twin_compare
	move.l 16(a5),a1
	moveq #3,d0
.guard_check
	cmp.l #$6d697272,(a1)+
	bne mirror_verify_fail
	dbf d0,.guard_check
	adda.l 12(a5),a1
	moveq #3,d0
.end_check
	cmp.l #$6d697272,(a1)+
	bne mirror_verify_fail
	dbf d0,.end_check
	move.l 16(a5),a1
	move.l 12(a5),d0
	add.l #32,d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
	lea mirror_verify_header(pc),a0
	addq.l #1,16(a0)
	movem.l (sp)+,d0-a6
	rts
mirror_twin_copy:
	subq.l #1,d0
.loop
	move.b (a0)+,(a1)+
	subq.l #1,d0
	bpl.b .loop
	rts
mirror_twin_compare:
	subq.l #1,d0
.loop
	move.b (a0)+,d1
	cmp.b (a1)+,d1
	bne mirror_verify_fail
	subq.l #1,d0
	bpl.b .loop
	rts
mirror_checked_original:
	movem.l d0-a6,-(sp)
	bsr original_mirror
	bra.b mirror_check_registers
mirror_checked_fast:
	movem.l d0-a6,-(sp)
	bsr mirror_fast
mirror_check_registers:
	movem.l d0-a6,-(sp)
	move.l sp,a0
	lea 60(sp),a1
	moveq #14,d0
.compare
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne mirror_verify_fail
	dbf d0,.compare
	lea 60(sp),sp
	movem.l (sp)+,d0-a6
	rts
mirror_twin_context: dcb.l 5,0
mirror_twin_descriptor: dcb.b 18,0

; Sixty-four deterministic synthetic CPU twins: boundary dimensions plus random
; dimensions/data, both depths, arbitrary padding and deliberately unrelated masks.
mirror_synthetic_tests:
	movem.l d0-a6,-(sp)
	lea mirror_synthetic_state(pc),a3
	move.l mirror_depth_ptr(pc),a0
	move.w (a0),12(a3)
	clr.l 8(a3)
	move.l #$304d0,4(a3)
	move.l #48432,d0
	moveq #1,d1
	move.l 4.w,a6
	jsr _LVOAllocMem(a6)
	tst.l d0
	beq mirror_verify_fail
	move.l d0,(a3)
.case
	lea mirror_synthetic_descriptor(pc),a4
	move.l (a3),d0
	add.l #16,d0
	move.l d0,(a4)
	bsr mirror_test_random
	and.l #$ffff,d0
	divu.w #320,d0
	swap d0
	addq.w #1,d0
	move.l 8(a3),d1
	cmp.w #14,d1
	bhs.b .width
	and.w #$fffe,d1
	lea mirror_test_widths(pc),a0
	move.w (a0,d1.w),d0
.width
	move.w d0,8(a4)
	bsr mirror_test_random
	and.l #$ffff,d0
	divu.w #200,d0
	swap d0
	addq.w #1,d0
	move.l 8(a3),d1
	cmp.w #14,d1
	bhs.b .height
	moveq #1,d0
	btst #1,d1
	beq.b .height
	move.w #200,d0
.height
	move.w d0,10(a4)
	moveq #4,d2
	btst #0,d1
	beq.b .depth
	addq.w #1,d2
.depth
	move.l mirror_depth_ptr(pc),a0
	move.w d2,(a0)
	move.w 8(a4),d1
	add.w #15,d1
	lsr.w #4,d1
	add.w d1,d1
	mulu.w d0,d1
	move.l d1,12(a4)
	mulu.w d2,d1
	move.l (a4),d2
	add.l d1,d2
	move.l d2,4(a4)
	add.w d0,d0
	ext.l d0
	add.l 12(a4),d0
	add.l d1,d0
	move.l d0,16(a3)
	bsr mirror_test_random
	move.w d0,16(a4)
	move.l (a4),a1
	move.l 16(a3),d6
	lsr.l #1,d6
	subq.w #1,d6
.fill
	bsr mirror_test_random
	move.w d0,(a1)+
	dbf d6,.fill
	moveq #3,d6
.end_guard
	move.l #$abcdef98,(a1)+
	dbf d6,.end_guard
	move.l (a3),a1
	moveq #3,d6
.start_guard
	move.l #$abcdef98,(a1)+
	dbf d6,.start_guard
	move.l a4,a0
	bsr mirror_live_twin
	move.l (a3),a1
	moveq #3,d6
.start_check
	cmp.l #$abcdef98,(a1)+
	bne mirror_verify_fail
	dbf d6,.start_check
	adda.l 16(a3),a1
	moveq #3,d6
.end_check
	cmp.l #$abcdef98,(a1)+
	bne mirror_verify_fail
	dbf d6,.end_check
	lea mirror_verify_header(pc),a0
	addq.l #1,20(a0)
	addq.l #1,8(a3)
	cmp.l #64,8(a3)
	bne .case
	move.l mirror_depth_ptr(pc),a0
	move.w 12(a3),(a0)
	move.l (a3),a1
	move.l #48432,d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
	movem.l (sp)+,d0-a6
	rts
mirror_test_random:
	move.l 4(a3),d0
	rol.l #7,d0
	add.l #$9e3779b9,d0
	move.l d0,4(a3)
	rts
mirror_test_widths: dc.w 1,15,16,17,168,319,320
mirror_synthetic_state: dcb.l 5,0
mirror_synthetic_descriptor: dcb.b 18,0
