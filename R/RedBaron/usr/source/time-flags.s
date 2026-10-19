; Internal timing feature bit 13, sim v1; called inside time_model_install register envelope.
time_model_flag_install:
	movem.l d0-a6,-(sp)
	lea .checks(pc),a3
	moveq #1,d7
.check
	move.l (a3)+,d0
	move.w (a3)+,d1
	move.l a3,a0
	lea .checker_base(pc),a4
.checker_base
	adda.l #perf_check_bytes-.checker_base,a4
	jsr (a4)
	adda.w d1,a3
	dbf d7,.check
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.checks:
	dc.l $15c82
	dc.w 6,$08eb,$0005,$0024
	dc.l $15ca0
	dc.w 6,$08ab,$0005,$0024
.patch:
	PL_START
	PL_PS $15c82,time_model_flag_set
	PL_PS $15ca0,time_model_flag_clear
	PL_END

; sim:15c62 uses object+36 bit 5 to save byte-zero bit 7 before 3D;
; sim:15cac consumes it afterwards. The projection snapshot starts later.
; Journal the scratch byte at its first write; restore only after the outer
; draw, so the native consumer sees the native temporary value. Reverse undo
; also handles repeated writes. Preserve ALL CCR bits before BSET/BCLR,
; which only replace Z; MOVEQ in the journal setup must not leak NZVC.
time_model_flag_set:
	bsr time_model_flag_record
	bset #5,36(a3)
	rts
time_model_flag_clear:
	bsr time_model_flag_record
	bclr #5,36(a3)
	rts
time_model_flag_record:
	movem.l d0/a0,-(sp)
	bsr time_message_ccr
	move.w d0,-(sp)
	lea 36(a3),a0
	moveq #1,d0
	bsr time_model_record
	move.w (sp)+,ccr
	movem.l (sp)+,d0/a0
	rts
