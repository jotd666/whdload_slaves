; Performance patch framework. Only sim v1 calls this module's installer.
; No feature is release-enabled until its model, twin and measurements pass.
PERF_VERIFIED_MASK = $1fff1fff ; verified features; CPU-filtered, FC8/FC12 copy additionally require W6
PERF_DEVELOPER_MASK = $1fff3fff
PERF_VERIFY_MASK = $1fff7fff ; developer W6 plus VERIFY-only quiescent overlay probe bit 14

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
	; FC12: 030/040 gauges qualify with W6; 060 retains its prior policy.
	; Explicit developer/VERIFY masks still support isolated comparisons.
	btst #7,perf_attnflags+3(pc)
	bne .gauge_player_ready
	btst #0,perf_custom3+3(pc)
	beq .gauge_player_off
	move.l perf_attnflags(pc),d1
	andi.l #$0c,d1
	bne .gauge_player_ready
.gauge_player_off
	bclr #23,d0
.gauge_player_ready
	; FC12: 030 spans qualify with W6; 040/060 retain their prior policy.
	move.l perf_attnflags(pc),d1
	andi.l #$88,d1
	bne .span_player_ready
	btst #0,perf_custom3+3(pc)
	beq .span_player_off
	btst #2,perf_attnflags+3(pc)
	bne .span_player_ready
.span_player_off
	bclr #24,d0
.span_player_ready
	; FC12 selective copy qualifies on 030; 040/060 retain their MOVE16 copy.
	move.l perf_attnflags(pc),d1
	andi.l #$88,d1
	bne .delta_player_off
	btst #2,perf_attnflags+3(pc)
	bne .delta_player_ready
.delta_player_off
	bclr #28,d0
.delta_player_ready
	; Independent player opt-in. Rendering Off still permits W6 and its
	; required safe-swap/one-field pacing; the shared CPU gate remains below.
	btst #0,perf_custom3+3(pc)
	beq .player_time_ready
	bset #13,d0
.player_time_ready
	ENDC
	ENDC
	; W6 supports the measured 68000 and 020+ classes. Keep 010 unchanged.
	move.l perf_attnflags(pc),d1
	andi.l #3,d1
	cmpi.l #1,d1
	bne .time_cpu_ready
	bclr #13,d0
.time_cpu_ready
	; FC9: private-scene raster only on measured 030/040/060 classes.
	move.l perf_attnflags(pc),d1
	andi.l #$8c,d1
	beq .no_fast_raster
	btst #20,d0
	bne .fast_raster_ready
.no_fast_raster
	bclr #26,d0
.fast_raster_ready
	; FC8 is measured on 040/060 and requires W6.
	move.l perf_attnflags(pc),d1
	andi.l #$88,d1
	beq .no_scenery_cache
	btst #13,d0
	bne .scenery_cache_ready
.no_scenery_cache
	bclr #25,d0
.scenery_cache_ready
	btst #13,d0
	beq .timing_dependencies_done
	ori.l #$0300,d0
.timing_dependencies_done
	btst #23,d0
	beq .persistent_ready
	move.l perf_attnflags(pc),d1
	andi.l #$8c,d1 ; FC3 regresses on 020; retain its bit18 path
	bne .persistent_cpu
	bclr #23,d0
	bra .persistent_ready
.persistent_cpu
	bset #18,d0 ; shared dispatcher hooks and resource lifetime
.persistent_ready
	bsr perf_instrument_cpu
	tst.l d1
	bne .instrument_cpu_ready
	bclr #18,d0
.instrument_cpu_ready
	; Sparse artwork loses on 000 and gives no gain on 020.
	; Artwork and direct scenes select the measured 030/040/060 classes only,
	; in every build mode. 000/010/020 retain their native scene renderer.
	move.l perf_attnflags(pc),d1
	andi.l #$8c,d1
	bne .artwork_cpu_ready
	bclr #19,d0
	bclr #20,d0
	bclr #21,d0
	bclr #22,d0
	bclr #24,d0
.artwork_cpu_ready
	btst #20,d0
	beq .no_scene_dependency
	bset #7,d0 ; private rectangle setup uses the verified D1 entry
	bra .fence_scene_ready
.no_scene_dependency
	bclr #24,d0
	bclr #21,d0
.fence_scene_ready
	btst #21,d0
	beq .scene_dependencies_ready
	ori.l #$0300,d0
.scene_dependencies_ready
	move.l d0,d1
	andi.l #$380000,d1
	cmpi.l #$380000,d1
	beq .compose_dependencies_ready
	bclr #22,d0
.compose_dependencies_ready
	; FC12 copy requires composed frames and W6; CPU policy comes from bit22.
	btst #22,d0
	beq .no_delta
	btst #13,d0
	bne .delta_ready
.no_delta
	bclr #28,d0
.delta_ready
	btst #19,d0
	beq .artwork_ready
	bset #14,d0
.artwork_ready
	; FC11 inherits the explicit 030/040/060 sparse-artwork CPU gate.
	btst #19,d0
	bne .generation_ready
	bclr #27,d0
.generation_ready
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
; FC3 uses the shared dispatcher on its separately gated CPU classes.
; Without FC3 return d1=1 only for 020/040, otherwise 0.
perf_instrument_cpu:
	btst #23,d0
	bne .yes
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
	bsr time_buffers_prepare
	lea .delta_prepare(pc),a0
.delta_prepare
	adda.l #scene_delta_prepare-.delta_prepare,a0
	jsr (a0)
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
	btst #4,perf_mask+1(pc)
	beq .scene_done
	lea .scene_base(pc),a0
.scene_base
	adda.l #scene_frame_install-.scene_base,a0
	jsr (a0)
.scene_done
	btst #5,perf_mask+1(pc)
	beq .fence_done
	lea .fence_base(pc),a0
.fence_base
	adda.l #fence_install-.fence_base,a0
	jsr (a0)
.fence_done
	btst #6,perf_mask+1(pc)
	beq .compose_done
	lea .compose_base(pc),a0
.compose_base
	adda.l #cockpit_fast_install-.compose_base,a0
	jsr (a0)
.compose_done
	btst #7,perf_mask+1(pc)
	beq .gauges_done
	lea .gauges_base(pc),a0
.gauges_base
	adda.l #gauge_fast_install-.gauges_base,a0
	jsr (a0)
.gauges_done
	btst #0,perf_mask(pc)
	beq .spans_done
	lea .spans_base(pc),a0
.spans_base
	adda.l #polygon_span_install-.spans_base,a0
	jsr (a0)
.spans_done
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
	dc.l WHDLTAG_CUSTOM3_GET
perf_custom3:
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
