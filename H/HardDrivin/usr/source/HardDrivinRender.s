; SPS 0126 rendering experiments, separately gated from elapsed-time physics.
; VERIFY_RENDER compiles the module. CUSTOM3 bit 0 selects Fast edge arrays;
; bit 1 selects exact zero-coefficient rotation on all supported CPUs;
; bit 2 selects the lean blitter wait only when CUSTOM2 is zero.
; Release builds select measured variants automatically under CUSTOM1.
; HD_DEVELOPMENT retains the CUSTOM3 experiment mask; other editions are unchanged.
; CPU-only edge storage: two 200-word arrays. The native pool reservation is
; deliberately retained so every later Chip allocation keeps its old address.
; Patterns already live in the globals hunk; no DMA buffer is relocated.

_render_install:
	cmpi.l #$11a4e,d0
	bne .done
	movem.l d0-d2/a0-a2/a6,-(sp)
	lea _render_tags(pc),a0
	lea _render_install(pc),a2
	adda.l #_resload-_render_install,a2
	movea.l (a2),a2
	jsr resload_Control(a2)
	IFND HD_DEVELOPMENT
	bsr _render_select
	lea _render_options(pc),a0
	move.l d0,(a0)
	ENDC
	move.l _render_options(pc),d0
	btst #0,d0
	beq .rotation
	IFND VERIFY_RENDER_000_MEMORY
	move.l _render_attn(pc),d0
	btst #AFB_68020,d0
	beq .rotation
	ENDC
	; Fast-only allocation fails harmlessly on machines without Fast RAM.
	; Lifetime is the game session, like the existing permanent native pool.
	movea.l 4.w,a6
	move.l #800,d0
	move.l #MEMF_FAST|MEMF_CLEAR,d1
	jsr _LVOAllocMem(a6)
	tst.l d0
	beq .rotation
	lea _render_edges(pc),a0
	move.l d0,(a0)
	lea _render_memory_patches(pc),a0
	lea _render_install(pc),a1
	adda.l #_code_start-_render_install,a1
	movea.l (a1),a1
	jsr resload_Patch(a2)
.rotation:
	move.l _render_options(pc),d0
	btst #1,d0
	beq .wait
	; This path uses only 68000 instructions; applies to 68000 and all successors.
	lea _render_rotation_patches(pc),a0
	lea _render_install(pc),a1
	adda.l #_code_start-_render_install,a1
	movea.l (a1),a1
	jsr resload_Patch(a2)
.wait:
	move.l _render_options(pc),d0
	btst #2,d0
	beq .restore
	lea _render_install(pc),a1
	adda.l #_ct_ct2-_render_install,a1
	tst.l (a1)
	bne .restore
	; Redirect the existing game wait sites; do not patch WHDLoad slave memory.
	lea _render_wait_patches(pc),a0
	lea _render_install(pc),a1
	adda.l #_code_start-_render_install,a1
	movea.l (a1),a1
	jsr resload_Patch(a2)
.restore:
	movem.l (sp)+,d0-d2/a0-a2/a6
.done:
	rts

_render_memory_patches:
	PL_START
	; PERF_RANGE VERIFY_RENDER_MEMORY $01a1c $0008: CPU-only edge pointers
	PL_PSS $01a1c,_render_set_edges,2
	PL_END

_render_set_edges:
	movea.l _render_edges(pc),a0
	move.l a0,-$69e0(a4)
	; Displaced MOVE.L D0 sets NZVC, MOVEA changes no flags; preserve X.
	tst.l d0
	rts

	IFND HD_DEVELOPMENT
; Returns only variants selected by the measured matrix. Do not infer newer
; CPU generations from a single flag: test 060/040 before 030 before 020.
_render_select:
	moveq #0,d0
	lea _render_install(pc),a0
	adda.l #_ct_ct1-_render_install,a0
	tst.l (a0)
	beq.s .done
	move.l _render_attn(pc),d1
	and.l #AFF_68040|AFF_68060,d1
	bne.s .rotation
	move.l _render_attn(pc),d1
	btst #AFB_68030,d1
	bne.s .done
	btst #AFB_68020,d1
	beq.s .old_cpu
	; 020 was measured with the executable in Fast RAM. Retain the original
	; renderer for unmeasured Chip/Slow-only placements.
	lea _render_install(pc),a1
	adda.l #_code_start-_render_install,a1
	movea.l (a1),a1
	; KickEmu can label its expansion arena MEMF_FAST even when WHDLoad
	; placed that arena in physical Chip/Slow RAM. Reject those bus ranges.
	cmpa.l #$200000,a1
	blo.s .done
	cmpa.l #$a00000,a1
	blo.s .fast_address
	cmpa.l #$1000000,a1
	blo.s .done
.fast_address:
	movea.l 4.w,a6
	jsr _LVOTypeOfMem(a6)
	and.l #MEMF_FAST,d0
	beq.s .done
	bra.s .lean
.old_cpu:
	btst #AFB_68010,d1
	bne.s .done
.lean:
	moveq #6,d0
	rts
.rotation:
	moveq #2,d0
.done:
	rts
	ENDC

_render_tags:
	IFD HD_DEVELOPMENT
	dc.l WHDLTAG_CUSTOM3_GET
_render_options: dc.l 0
	ENDC
	dc.l WHDLTAG_ATTNFLAGS_GET
_render_attn: dc.l 0
	dc.l 0
	IFND HD_DEVELOPMENT
_render_options: dc.l 0
	ENDC
_render_edges: dc.l 0

	INCLUDE "HardDrivinRotation.s"

; These sites already contain the original slave's JSR _blitwait + two NOPs.
; Their disabled baseline is that existing patch, not pristine game bytes.
; PERF_EXISTING_RANGE declarations are checked against the retained listing.
_render_wait_patches:
	PL_START
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $0141c $000a: existing blitter wait
	PL_PS $0141c,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $0143c $000a: existing blitter wait
	PL_PS $0143c,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $014fe $000a: existing blitter wait
	PL_PS $014fe,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $0151e $000a: existing blitter wait
	PL_PS $0151e,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $015b4 $000a: existing blitter wait
	PL_PS $015b4,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $015ce $000a: existing blitter wait
	PL_PS $015ce,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $01774 $000a: existing blitter wait
	PL_PS $01774,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $017a6 $000a: existing blitter wait
	PL_PS $017a6,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $017e0 $000a: existing blitter wait
	PL_PS $017e0,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $0795c $000a: existing blitter wait
	PL_PS $0795c,_render_wait
	; PERF_EXISTING_RANGE VERIFY_RENDER_WAIT $0799a $000a: existing blitter wait
	PL_PS $0799a,_render_wait
	PL_END

; No changed registers. Retain the proven BLITWAIT hardware-read sequence,
; including CIA backoff while busy: tight polling slowed the A1200 blitter.
; Only the register spills and zero-delay option checks are removed. Final
; NZVC reflect the final DMACONR high byte; X remains unchanged. All CPUs use
; 68000 instructions. CUSTOM2 nonzero retains the original helper.
_render_wait:
	BLITWAIT
	rts
