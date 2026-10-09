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
	; The table mirror and G1 projection lose on the measured cached 68030.
	; Keep those originals on 030 and conservatively on unmeasured 040/060.
	; DEVELOPER/VERIFY retain explicit bits for comparisons.
	move.l perf_attnflags(pc),d1
	and.l #$8c,d1 ; AFF_68030 | AFF_68040 | AFF_68060
	beq.b .selected
	bclr #0,d0
	bclr #2,d0
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
	IFD VERIFY
	bsr verify_copy_originals
	; CUSTOM5 bit 9: identical native setup for timing comparisons. Install only
	; after the first recorded flight checkpoint, before its original input call.
	btst #1,perf_custom5+2(pc)
	beq.b .immediate
	movem.l d0-a6,-(sp)
	lea perf_pending_sim(pc),a0
	move.l a1,(a0)
	; Do the same preparation/self-tests for every CUSTOM2 mask at boot.
	bsr mirror_prepare
	bsr mirror_word_selftest
	btst #5,perf_custom5+3(pc)
	beq.b .prepared
	bsr mirror_synthetic_tests
.prepared
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
.immediate
	ENDC
perf_apply_v1:
	btst #0,perf_mask+3(pc)
	beq.b .no_mirror
	bsr mirror_install
.no_mirror
	btst #1,perf_mask+3(pc)
	beq.b .no_cache
	bsr cache_install
.no_cache
	btst #2,perf_mask+3(pc)
	beq.b .no_projection
	bsr projection_install
.no_projection
	btst #5,perf_mask+3(pc)
	beq.b .no_dot
	bsr dot_install
.no_dot
	btst #3,perf_mask+3(pc)
	beq.b .no_clip
	bsr clip_install
.no_clip
	btst #4,perf_mask+3(pc)
	beq.b .no_vertex
	bsr vertex_install
.no_vertex
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

	IFD VERIFY
; Pending sim is set only by the supported v1 loader. Never patch sim v2 here.
; The anchor's caller saved only d0/a0/a1, so preserve all registers ourselves.
perf_activate_deferred:
	movem.l d0-a6,-(sp)
	lea perf_pending_sim(pc),a0
	tst.l (a0)
	beq.b .done
	move.l (a0),a1
	clr.l (a0)
	move.l _resload(pc),a2
	bsr perf_apply_v1
.done
	movem.l (sp)+,d0-a6
	rts
perf_pending_sim:
	dc.l 0
	ENDC
