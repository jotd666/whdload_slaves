; Performance patch framework. Only sim v1 calls this module's installer.
; No feature is release-enabled until its model, twin and measurements pass.
PERF_VERIFIED_MASK = $71fff ; W1-W5, B1/B2, C3 and E2 gauges; each has its CPU gate
PERF_DEVELOPER_MASK = $f3fff
PERF_VERIFY_MASK = $f7fff ; developer W6 plus VERIFY-only quiescent overlay probe bit 14

perf_read_options:
	movem.l d0-a6,-(sp)
	lea perf_tags(pc),a0
	move.l _resload(pc),a2
	jsr resload_Control(a2)
	move.l perf_custom2(pc),d0
	IFD VERIFY
	and.l #PERF_VERIFY_MASK,d0
	ELSE
	IFD DEVELOPER
	and.l #PERF_DEVELOPER_MASK,d0
	ELSE
	; Normal splash list: On=0 (WHDLoad default), Off=1.
	tst.l d0
	beq.b .player_enabled
	moveq #0,d0
	bra.b .selected
.player_enabled
	move.l #PERF_VERIFIED_MASK,d0
	; The table mirror and G1 projection lose on the measured cached 68030.
	; Keep those originals on 030 and conservatively on unmeasured 040/060.
	; DEVELOPER/VERIFY retain explicit bits for comparisons.
	move.l perf_attnflags(pc),d1
	and.l #$8c,d1 ; AFF_68030 | AFF_68040 | AFF_68060
	beq.b .selected
	bclr #0,d0
	bclr #2,d0
	; S3 has no established material benefit on the cached 030.
	bclr #12,d0
.selected
	ENDC
	ENDC
	; W6 supports the measured 68000 and 020+ classes. Keep 010 unchanged.
	move.l perf_attnflags(pc),d1
	andi.l #3,d1
	cmpi.l #1,d1
	bne .time_cpu_ready
	bclr #13,d0
	bclr #19,d0 ; unmeasured 68010 retains native artwork
.time_cpu_ready
	btst #13,d0
	beq .timing_dependencies_done
	ori.l #$0300,d0
.timing_dependencies_done
	bsr perf_instrument_cpu
	tst.l d1
	bne .instrument_cpu_ready
	bclr #18,d0
.instrument_cpu_ready
	btst #19,d0
	beq .artwork_ready
	bset #14,d0
.artwork_ready
	btst #18,d0
	beq .instrument_ready
	bset #14,d0
.instrument_ready
	lea perf_mask(pc),a0
	move.l d0,(a0)
	movem.l (sp)+,d0-a6
	rts

; E2 persistent gauges: measured +2.19% on 020, +3.00% on 040.
; 030/060 miss 2%. Test higher CPU flags first: faster processors also set
; compatibility flags for earlier CPUs. Preserve d0 (the option mask).
; Return d1=1 only for 020/040, otherwise 0. All modes share this policy.
perf_instrument_cpu:
	move.l perf_attnflags(pc),d1
	btst #7,d1
	bne .no
	btst #3,d1
	bne .yes
	btst #2,d1
	bne .no
	btst #1,d1
	beq .no
.yes
	moveq #1,d1
	rts
.no
	moveq #0,d1
	rts

; a1 = relocated sim hunk 0, a2 = resload. Preserve the loader's registers.
; Add each validated installer here, gated on its own perf_mask bit.
perf_install_v1:
	bsr cpu_cache_install_v1
	bsr memory_install_v1
	IFD VERIFY
	bsr time_core_selftest
	bsr time_input_selftest
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
	btst #6,perf_mask+3(pc)
	beq .no_face
	bsr face_install
.no_face
	lea sound_sim_active(pc),a0
	move.w #1,(a0)
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
	btst #7,perf_mask+3(pc)
	beq.b .no_fill
	bsr fill_install
.no_fill
	bsr pace_install
	bsr sound_sequence_install
	bsr sound_driver_install
	btst #5,perf_mask+2(pc)
	beq.b .no_time
	bsr time_loop_install
.no_time
	btst #2,perf_mask+1(pc)
	beq .no_instrument_cache
	lea .instrument_base(pc),a0
.instrument_base
	adda.l #instrument_cache_install-.instrument_base,a0
	jsr (a0)
	bra .overlays_done
.no_instrument_cache
	IFD VERIFY
	btst #3,perf_mask+1(pc)
	bne .no_overlay_probe
	btst #6,perf_mask+2(pc)
	beq.b .no_overlay_probe
	lea .overlay_probe_base(pc),a0
.overlay_probe_base
	adda.l #overlay_probe_install-.overlay_probe_base,a0
	jsr (a0)
.no_overlay_probe
	ENDC
.overlays_done
	btst #3,perf_mask+1(pc)
	beq .artwork_done
	lea .artwork_base(pc),a0
.artwork_base
	adda.l #artwork_solid_install-.artwork_base,a0
	jsr (a0)
	lea .front_base(pc),a0
.front_base
	adda.l #artwork_front_install-.front_base,a0
	jsr (a0)
	btst #2,perf_mask+1(pc)
	bne .artwork_done
	lea .life_base(pc),a0
.life_base
	adda.l #ovlife_install-.life_base,a0
	jsr (a0)
.artwork_done
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
	dc.l WHDLTAG_CUSTOM4_GET
perf_custom4:
	dc.l 0
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
