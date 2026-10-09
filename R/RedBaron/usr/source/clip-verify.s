; CUSTOM5 bit 12: compare both passes' complete buffers, bounds and preserved regs.
clip_twin:
	movem.l d0-a6,-(sp)
	lea clip_verify_sp(pc),a0
	move.l sp,(a0)
	move.l clip_buffer(pc),a0
	lea clip_verify_input(pc),a1
	bsr clip_copy_buffer
	move.l clip_work_bounds(pc),a0
	lea clip_verify_initial_bound(pc),a1
	move.l (a0),(a1)
	movem.l (sp),d0-a6
	bsr original_clip_wrapper
	movem.l d0-a6,-(sp)
	lea 60(sp),a0
	cmpa.l clip_verify_sp(pc),a0
	bne clip_verify_fail
	move.l clip_buffer(pc),a0
	lea clip_verify_expected(pc),a1
	bsr clip_copy_buffer
	move.l clip_work_bounds(pc),a0
	lea clip_verify_expected_bound(pc),a1
	move.l (a0),(a1)
	lea clip_verify_input(pc),a0
	move.l clip_buffer(pc),a1
	bsr clip_copy_buffer
	move.l clip_work_bounds(pc),a0
	move.l clip_verify_initial_bound(pc),(a0)
	movem.l 60(sp),d0-a6
	bsr clip_fast
	movem.l d0-a6,-(sp)
	lea 120(sp),a0
	cmpa.l clip_verify_sp(pc),a0
	bne clip_verify_fail
	lea 8(sp),a0
	lea 68(sp),a1
	moveq #5,d0
.data
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne clip_verify_fail
	dbf d0,.data
	lea 40(sp),a0
	lea 100(sp),a1
	moveq #4,d0
.address
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne clip_verify_fail
	dbf d0,.address
	move.l clip_buffer(pc),a0
	lea clip_verify_expected(pc),a1
	moveq #80,d0
.memory
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne clip_verify_fail
	dbf d0,.memory
	move.l clip_work_bounds(pc),a0
	move.l (a0),d0
	cmp.l clip_verify_expected_bound(pc),d0
	bne clip_verify_fail
	lea clip_verify_header(pc),a0
	addq.l #1,12(a0)
	movem.l (sp)+,d0-a6
	lea 120(sp),sp
	rts
clip_copy_buffer:
	moveq #80,d0
.copy
	move.l (a0)+,(a1)+
	dbf d0,.copy
	rts
clip_verify_fail:
	pea clip_verify_message(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
clip_verify_message: dc.b "Red Baron: G2 clip verification mismatch",0
	even
clip_verify_header:
	dc.b "RBCLIP01"
	dc.l 1,0,0
clip_verify_sp: dc.l 0
clip_verify_initial_bound: dc.l 0
clip_verify_expected_bound: dc.l 0
clip_verify_input: dcb.b 324,0
clip_verify_expected: dcb.b 324,0
clip_selftest:
	movem.l d0-a6,-(sp)
	move.l clip_buffer(pc),a0
	lea clip_self_saved(pc),a1
	bsr clip_copy_buffer
	move.l clip_bounds(pc),a0
	move.l (a0)+,(a1)+
	move.l (a0),(a1)+
	move.l clip_work_bounds(pc),a0
	move.l (a0),(a1)
	lea clip_selftest(pc),a6
	adda.l #clip_cases-clip_selftest,a6
	move.w #CLIP_CASES-1,d7
.case
	move.l clip_buffer(pc),a0
	moveq #80,d0
	move.l #$a55a1234,d1
.fill
	move.l d1,(a0)+
	dbf d0,.fill
	move.l clip_buffer(pc),a0
	move.w (a6)+,(a0)+
	move.l clip_bounds(pc),a1
	move.l (a6)+,(a1)+
	move.l (a6)+,(a1)
	move.l (a6)+,d0
	move.l (a6)+,d1
	moveq #19,d2
.coords
	move.l d1,80(a0)
	move.l d0,(a0)+
	dbf d2,.coords
	move.l #$13579bdf,d2
	move.l #$2468ace0,d3
	move.l #$98765432,d4
	move.l #$abcdef01,d5
	move.l #$87654321,d6
	move.l #$12345678,a2
	move.l #$fedcba98,a3
	move.l #$11223344,a4
	move.l #$55667788,a5
	bsr clip_twin
	lea clip_verify_header(pc),a0
	addq.l #1,16(a0)
	dbf d7,.case
	lea clip_self_saved(pc),a0
	move.l clip_buffer(pc),a1
	bsr clip_copy_buffer
	move.l clip_bounds(pc),a1
	move.l (a0)+,(a1)+
	move.l (a0)+,(a1)
	move.l clip_work_bounds(pc),a1
	move.l (a0),(a1)
	movem.l (sp)+,d0-a6
	rts
clip_self_saved: dcb.b 336,0
