; CUSTOM5 bit 13: same cache-miss input, original wrapper vs fused candidate.
; Pack: flag/pad, source scratch (6), result scratch (12), cached x/y/z (12).
vertex_snapshot:
	move.l vertex_context(pc),a2
	lea $1a2(a2),a0
	move.b (a0,d0.w),(a1)+
	clr.b (a1)+
	move.l $164(a2),(a1)+
	move.w $168(a2),(a1)+
	lea $182(a2),a0
	move.l (a0)+,(a1)+
	move.l (a0)+,(a1)+
	move.l (a0),(a1)+
	lsl.w #2,d0
	lea $2a2(a2),a0
	adda.w d0,a0
	move.l (a0),(a1)+
	move.l $3fc(a0),(a1)+
	move.l $7f8(a0),(a1)+
	rts
vertex_restore:
	move.l vertex_context(pc),a2
	lea $1a2(a2),a0
	move.b (a1)+,(a0,d0.w)
	addq.l #1,a1
	move.l (a1)+,$164(a2)
	move.w (a1)+,$168(a2)
	lea $182(a2),a0
	move.l (a1)+,(a0)+
	move.l (a1)+,(a0)+
	move.l (a1)+,(a0)
	lsl.w #2,d0
	lea $2a2(a2),a0
	adda.w d0,a0
	move.l (a1)+,(a0)
	move.l (a1)+,$3fc(a0)
	move.l (a1)+,$7f8(a0)
	rts
vertex_twin:
	movem.l d0-a6,-(sp)
	lea vertex_verify_sp(pc),a0
	move.l sp,(a0)
	lea vertex_verify_input(pc),a1
	bsr vertex_snapshot
	movem.l (sp),d0-a6
	bsr original_vertex
	movem.l d0-a6,-(sp)
	lea 60(sp),a0
	cmpa.l vertex_verify_sp(pc),a0
	bne vertex_verify_fail
	move.l 60(sp),d0
	lea vertex_verify_expected(pc),a1
	bsr vertex_snapshot
	move.l 60(sp),d0
	lea vertex_verify_input(pc),a1
	bsr vertex_restore
	movem.l 60(sp),d0-a6
	bsr vertex_fast
	movem.l d0-a6,-(sp)
	lea 120(sp),a0
	cmpa.l vertex_verify_sp(pc),a0
	bne vertex_verify_fail
	lea 8(sp),a0
	lea 68(sp),a1
	moveq #5,d0
.data
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne vertex_verify_fail
	dbf d0,.data
	lea 40(sp),a0
	lea 100(sp),a1
	moveq #4,d0
.address
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne vertex_verify_fail
	dbf d0,.address
	move.l 120(sp),d0
	lea vertex_verify_actual(pc),a1
	bsr vertex_snapshot
	lea vertex_verify_actual(pc),a0
	lea vertex_verify_expected(pc),a1
	moveq #7,d0
.memory
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne vertex_verify_fail
	dbf d0,.memory
	lea vertex_verify_header(pc),a0
	addq.l #1,12(a0)
	movem.l (sp)+,d0-a6
	lea 120(sp),sp
	rts
vertex_verify_fail:
	pea vertex_verify_message(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
vertex_verify_message: dc.b "Red Baron: G3 vertex verification mismatch",0
	even
vertex_verify_header:
	dc.b "RBVERT01"
	dc.l 1,0,0
vertex_verify_sp: dc.l 0
vertex_verify_input: dcb.b 32,0
vertex_verify_expected: dcb.b 32,0
vertex_verify_actual: dcb.b 32,0
vertex_selftest:
	movem.l d0-a6,-(sp)
	move.l vertex_context(pc),a2
	lea vertex_self_context(pc),a1
	move.l 8(a2),(a1)+
	move.l $f4(a2),(a1)+
	move.w (a2),(a1)+
	move.l $104(a2),(a1)+
	move.l $108(a2),(a1)+
	move.l $10c(a2),(a1)
	lea vertex_selftest(pc),a6
	adda.l #vertex_cases-vertex_selftest,a6
	move.w #VERTEX_CASES-1,d7
.case
	moveq #0,d0
	move.w (a6)+,d0
	lea vertex_self_index(pc),a1
	move.l d0,(a1)
	lea vertex_self_saved(pc),a1
	bsr vertex_snapshot
	lea vertex_self_vector(pc),a1
	move.l (a6)+,(a1)+
	move.w (a6)+,(a1)
	lea vertex_self_matrix(pc),a1
	moveq #8,d0
.matrix
	move.w (a6)+,(a1)+
	dbf d0,.matrix
	move.w (a6)+,d0
	move.b d0,(a1)+
	clr.b (a1)
	move.l vertex_context(pc),a2
	move.w (a6)+,(a2)
	lea vertex_self_matrix(pc),a0
	move.l a0,$f4(a2)
	lea vertex_self_vector(pc),a0
	move.l vertex_self_index(pc),d0
	move.w d0,d1
	add.w d0,d0
	lsl.w #2,d1
	add.w d1,d0
	suba.w d0,a0
	move.l a0,8(a2)
	move.l #7,$104(a2)
	move.l #-19,$108(a2)
	move.l #$7ffffffe,$10c(a2)
	move.l vertex_self_index(pc),d0
	lea $1a2(a2),a0
	clr.b (a0,d0.w)
	move.l #$13579bdf,d2
	move.l #$2468ace0,d3
	move.l #$98765432,d4
	move.l #$abcdef01,d5
	move.l #$87654321,d6
	move.l #$12345678,a2
	move.l #$fedcba98,a3
	move.l #$11223344,a4
	move.l #$55667788,a5
	bsr vertex_twin
	lea vertex_verify_header(pc),a0
	addq.l #1,16(a0)
	move.l vertex_self_index(pc),d0
	lea vertex_self_saved(pc),a1
	bsr vertex_restore
	dbf d7,.case
	move.l vertex_context(pc),a2
	lea vertex_self_context(pc),a1
	move.l (a1)+,8(a2)
	move.l (a1)+,$f4(a2)
	move.w (a1)+,(a2)
	move.l (a1)+,$104(a2)
	move.l (a1)+,$108(a2)
	move.l (a1),$10c(a2)
	movem.l (sp)+,d0-a6
	rts
vertex_self_context: dcb.b 22,0
vertex_self_index: dc.l 0
vertex_self_saved: dcb.b 32,0
vertex_self_vector: dcb.b 6,0
vertex_self_matrix: dcb.b 20,0
