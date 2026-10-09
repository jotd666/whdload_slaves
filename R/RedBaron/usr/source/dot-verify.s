; CUSTOM5 bit 11: synthetic and live twins against the relocated original.
dot_twin:
	movem.l d0-a6,-(sp)
	lea dot_verify_sp(pc),a0
	move.l sp,(a0)
	movem.l (sp),d0-a6
	move.l 68(sp),-(sp)
	move.l 68(sp),-(sp)
	bsr original_dot
	lea 8(sp),sp
	movem.l d0-a6,-(sp)
	lea 60(sp),a0
	cmpa.l dot_verify_sp(pc),a0
	bne dot_verify_fail
	movem.l 60(sp),d0-a6
	move.l 128(sp),-(sp)
	move.l 128(sp),-(sp)
	bsr dot_fast
	lea 8(sp),sp
	movem.l d0-a6,-(sp)
	lea 120(sp),a0
	cmpa.l dot_verify_sp(pc),a0
	bne dot_verify_fail
	move.l (sp),d0
	cmp.l 60(sp),d0
	bne dot_verify_fail
	lea 8(sp),a0
	lea 68(sp),a1
	moveq #5,d0
.data
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne dot_verify_fail
	dbf d0,.data
	lea 40(sp),a0
	lea 100(sp),a1
	moveq #4,d0
.address
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne dot_verify_fail
	dbf d0,.address
	lea dot_verify_header(pc),a0
	addq.l #1,12(a0)
	movem.l (sp)+,d0-a6
	lea 120(sp),sp
	rts
dot_verify_fail:
	pea dot_verify_message(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
dot_verify_message: dc.b "Red Baron: G4 dot verification mismatch",0
	even
dot_verify_header:
	dc.b "RBDOT001"
	dc.l 1,0,0
dot_verify_sp: dc.l 0
dot_selftest:
	movem.l d0-a6,-(sp)
	lea dot_selftest(pc),a6
	adda.l #dot_cases-dot_selftest,a6
	move.w #DOT_CASES-1,d7
.case
	move.l #$13579bdf,d2
	move.l #$2468ace0,d3
	move.l #$98765432,d4
	move.l #$abcdef01,d5
	move.l #$87654321,d6
	move.l #$12345678,a2
	move.l #$fedcba98,a3
	move.l #$11223344,a4
	move.l #$55667788,a5
	pea 12(a6)
	move.l a6,-(sp)
	bsr dot_twin
	lea 8(sp),sp
	lea dot_verify_header(pc),a0
	addq.l #1,16(a0)
	lea 18(a6),a6
	dbf d7,.case
	movem.l (sp)+,d0-a6
	rts

