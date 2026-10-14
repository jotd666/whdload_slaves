; Per-face vertex-loop twin. Only the renderer's scratch context is replayed.
FACE_CONTEXT_BYTES = $16a4
face_copy:
	move.w #FACE_CONTEXT_BYTES/4-1,d0
.loop
	move.l (a0)+,(a1)+
	dbf d0,.loop
	rts
face_twin:
face_twin_ccr_input: dc.w $40e7
	movem.l d0-a6,-(sp)
	move.l face_flags(pc),a0
	suba.w #$1a2,a0
	lea .input_base(pc),a1
.input_base
	adda.l #face_verify_input-.input_base,a1
	bsr face_copy
	movem.l (sp),d0-a6
	move.w 60(sp),ccr
	bsr face_original
face_twin_ccr_original: dc.w $40e7
	movem.l d0-a6,-(sp)
	move.l face_flags(pc),a0
	suba.w #$1a2,a0
	lea .expected_base(pc),a1
.expected_base
	adda.l #face_verify_expected-.expected_base,a1
	bsr face_copy
	lea .restore_base(pc),a0
.restore_base
	adda.l #face_verify_input-.restore_base,a0
	move.l face_flags(pc),a1
	suba.w #$1a2,a1
	bsr face_copy
	movem.l 62(sp),d0-a6
	move.w 122(sp),ccr
	bsr face_fast
face_twin_ccr_fast: dc.w $40e7
	movem.l d0-a6,-(sp)
	move.l sp,a0
	lea 62(sp),a1
	moveq #14,d0
.regs
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne .bad
	dbf d0,.regs
	move.w 60(sp),d0
	move.w 122(sp),d1
	eor.w d1,d0
	andi.w #31,d0
	bne .bad
	move.l face_flags(pc),a0
	suba.w #$1a2,a0
	lea .compare_base(pc),a1
.compare_base
	adda.l #face_verify_expected-.compare_base,a1
	move.w #FACE_CONTEXT_BYTES/4-1,d0
.memory
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne .bad
	dbf d0,.memory
	lea face_verify_header(pc),a0
	addq.l #1,12(a0)
	movem.l 62(sp),d0-a6
	move.w 122(sp),ccr
	lea 186(sp),sp
	rts
.bad
	lea face_verify_header(pc),a0
	move.l #1,16(a0)
	pea .message(pc)
	pea TDREASON_FAILMSG
	lea .resload(pc),a2
.resload
	adda.l #_resload-.resload,a2
	move.l (a2),a2
	jmp resload_Abort(a2)
.message: dc.b "Red Baron: G5 face-loop twin mismatch",0
	even
face_verify_header: dc.b "RBFACE01"
	dc.l 1,0,0,0,0,0
