; G1 reference is copied before installation; no original game bytes embedded.
; CUSTOM5 bit 10 enables synthetic and live complete-register twins.
projection_twin:
	movem.l d0-a6,-(sp)
	lea projection_verify_sp(pc),a0
	move.l sp,(a0)
	movem.l (sp),d0-a6
	bsr original_project
	movem.l d0-a6,-(sp)
	lea 60(sp),a0
	cmpa.l projection_verify_sp(pc),a0
	bne projection_verify_fail
	movem.l 60(sp),d0-a6
	bsr projection_fast
	movem.l d0-a6,-(sp)
	lea 120(sp),a0
	cmpa.l projection_verify_sp(pc),a0
	bne projection_verify_fail
	move.l sp,a0
	lea 60(sp),a1
	moveq #14,d0
.compare
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne projection_verify_fail
	dbf d0,.compare
	lea projection_verify_header(pc),a0
	addq.l #1,12(a0)
	movem.l (sp)+,d0-a6
	lea 120(sp),sp
	rts
projection_verify_fail:
	pea projection_verify_message(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
projection_verify_message:
	dc.b "Red Baron: G1 projection verification mismatch",0
	even
projection_verify_header:
	dc.b "RBPROJ01"
	dc.l 1,0,0
projection_verify_sp: dc.l 0

projection_selftest:
	movem.l d0-a6,-(sp)
	lea projection_selftest(pc),a6
	adda.l #projection_cases-projection_selftest,a6
	move.w #PROJECTION_CASES-1,d7
.case
	movem.l (a6)+,d0-d3
	move.l #$13579bdf,d4
	move.l #$2468ace0,d5
	move.l #$87654321,d6
	move.l #$12345678,a2
	move.l #$fedcba98,a3
	move.l #$11223344,a4
	move.l #$55667788,a5
	bsr projection_twin
	lea projection_verify_header(pc),a0
	addq.l #1,16(a0)
	dbf d7,.case
	movem.l (sp)+,d0-a6
	rts
