; Performance patch framework. Only sim v1 calls this module's installer.
; No feature is release-enabled until its model, twin and measurements pass.
PERF_VERIFIED_MASK = 0
PERF_DEVELOPER_MASK = $3ff

perf_read_options:
	movem.l d0-a6,-(sp)
	lea perf_tags(pc),a0
	move.l _resload(pc),a2
	jsr resload_Control(a2)
	move.l perf_custom2(pc),d0
	IFD VERIFY
	and.l #PERF_DEVELOPER_MASK,d0
	ELSE
	IFD DEVELOPER
	and.l #PERF_DEVELOPER_MASK,d0
	ELSE
	tst.l d0
	beq.b .selected
	move.l #PERF_VERIFIED_MASK,d0
.selected
	ENDC
	ENDC
	lea perf_mask(pc),a0
	move.l d0,(a0)
	movem.l (sp)+,d0-a6
	rts

; a1 = relocated sim hunk 0, a2 = resload. Preserve the loader's registers.
; Add each validated installer here, gated on its own perf_mask bit.
perf_install_v1:
	rts

; Check a non-relocated hook range before installing it.
; d0 = sim offset, d1 = length (positive), a0 = expected bytes, a1 = sim base.
; Relocated operands need a separately computed check in their installer.
perf_check_bytes:
	movem.l d0-d2/a0-a1,-(sp)
	adda.l d0,a1
	subq.l #1,d1
.check
	move.b (a0)+,d2
	cmp.b (a1)+,d2
	bne.b .mismatch
	subq.l #1,d1
	bpl.b .check
	movem.l (sp)+,d0-d2/a0-a1
	rts
.mismatch
	pea perf_mismatch(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)

perf_mismatch:
	dc.b "Red Baron: unexpected sim v1 performance hook bytes",0
	even
perf_tags:
	dc.l WHDLTAG_CUSTOM2_GET
perf_custom2:
	dc.l 0
	dc.l WHDLTAG_ATTNFLAGS_GET
perf_attnflags:
	dc.l 0
	IFD VERIFY
	dc.l WHDLTAG_CUSTOM5_GET
perf_custom5:
	dc.l 0
	ENDC
	dc.l TAG_DONE
perf_mask:
	dc.l 0
