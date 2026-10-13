; SPS 0126 rendering experiments, separately gated from elapsed-time physics.
; VERIFY_RENDER compiles the module. CUSTOM3 bit 0 selects Fast edge arrays;
; bit 1 selects exact zero-coefficient rotation on all supported CPUs.
; Normal builds and other game versions retain the original instructions.
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
	beq .restore
	; This path uses only 68000 instructions; applies to 68000 and all successors.
	lea _render_rotation_patches(pc),a0
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

_render_tags: dc.l WHDLTAG_CUSTOM3_GET
_render_options: dc.l 0
	dc.l WHDLTAG_ATTNFLAGS_GET
_render_attn: dc.l 0
	dc.l 0
_render_edges: dc.l 0

	INCLUDE "HardDrivinRotation.s"
