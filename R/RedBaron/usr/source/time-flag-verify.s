; VERIFY bit 13, sim v1; called inside time_model_install register envelope.
time_model_flag_install:
	movem.l d0-a6,-(sp)
	IFD VERIFY
	bsr time_model_flag_selftest
	ENDC
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


; VERIFY-only private native visibility-scratch tests.
; Exhaust every old byte for both operations, preserving X/N/V/C while
; deriving Z from the original bit. Private storage only, no game fixture.
	IFD VERIFY
time_model_flag_selftest:
	movem.l d0-a6,-(sp)
	lea time_present_active(pc),a4
	move.w #1,(a4)
	lea time_model_flag_data(pc),a3
	lea .cases_base(pc),a6
.cases_base
	adda.l #time_model_flag_cases-.cases_base,a6
	moveq #0,d5
.operation
	moveq #0,d6
.value
	move.b d6,36(a3)
	tst.w d5
	bne .clear
	move.w #$1b,ccr
	bsr time_model_flag_set
	bra .checked
.clear
	move.w #$1b,ccr
	bsr time_model_flag_clear
.checked
	bsr time_message_ccr
	andi.w #$1f,d0
	move.b d6,(a6)+
	move.b d5,(a6)+
	move.b 36(a3),(a6)+
	move.b d0,(a6)+
	moveq #$1b,d1
	btst #5,d6
	bne .z_ready
	ori.w #4,d1
.z_ready
	cmp.w d1,d0
	bne time_model_bad
	move.w d6,d1
	bset #5,d1
	tst.w d5
	beq .value_ready
	bclr #5,d1
.value_ready
	cmp.b 36(a3),d1
	bne time_model_bad
	move.w time_model_count(pc),d0
	cmpi.w #1,d0
	bne time_model_bad
	bsr time_model_restore
	cmp.b 36(a3),d6
	bne time_model_bad
	addq.w #1,d6
	cmpi.w #256,d6
	bne .value
	addq.w #1,d5
	cmpi.w #2,d5
	bne .operation
	clr.w (a4)
	; Inactive owner: original operation still executes without a record.
	bsr time_model_flag_set
	bsr time_model_flag_clear
	move.w time_model_count(pc),d0
	bne time_model_bad
	lea time_model_flag_result(pc),a0
	move.l #512,(a0)
	movem.l (sp)+,d0-a6
	rts
time_model_flag_data: dcb.b 40,0
time_model_flag_result: dc.l 0
	ENDC
