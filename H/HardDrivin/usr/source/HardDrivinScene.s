; Development gate: omit render-only object transforms on intermediate steps.
; Keep all near/clipped objects (byte34 !=0), terrain and visibility/traffic work.
; The native byte34 branch selects A194 (contact side effects) versus9AEC (only
; projected vertices). Final substeps and all presentation loops stay complete.
_scene_cull_install:
	movem.l a0-a2,-(a7)
	lea _scene_cull_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_scene_cull_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_SCENE_CULL $0b09e $0006: intermediate auxiliary-list object gate
	PL_PS $b09e,_scene_auxiliary_gate
	; PERF_RANGE VERIFY_TIME_SCENE_CULL $0b10c $0006: intermediate main-list object gate
	PL_PS $b10c,_scene_main_gate
	IFD VERIFY_SCENE_TWIN
	; PERF_RANGE VERIFY_SCENE_TWIN $0b142 $0006: compare intermediate contact preparation
	PL_PS $b142,_scene_twin_gate
	ENDC
	PL_END
_scene_signature: dc.b 'HDSCENE1'
_scene_counts: dc.l 0,0
_scene_auxiliary_gate:
	movem.l d0/a0-a1,-(a7)
	tst.b 29(a2)
	beq.s .skip
	bsr _scene_cull_test
	beq.s .keep
	lea _scene_counts(pc),a0
	movea.l (a0),a1
	adda.w #1,a1
	move.l a1,(a0)
.skip:
	movea.l _code_start(pc),a0
	adda.l #$b0c4,a0
	move.l a0,12(a7)
.keep:
	movem.l (a7)+,d0/a0-a1
	tst.b 29(a2)
	rts
_scene_main_gate:
	movem.l d0/a0-a1,-(a7)
	tst.b 30(a2)
	beq.s .skip
	tst.b 29(a2)
	beq.s .keep
	bsr _scene_cull_test
	beq.s .keep
	lea _scene_counts(pc),a0
	movea.l 4(a0),a1
	adda.w #1,a1
	move.l a1,4(a0)
.skip:
	movea.l _code_start(pc),a0
	adda.l #$b138,a0
	move.l a0,12(a7)
.keep:
	movem.l (a7)+,d0/a0-a1
	tst.b 30(a2)
	rts
; Return Z if the full native object path is required; preserve the native X.
_scene_cull_test:
	moveq #0,d0
	; Race exit cancels pending steps and can draw this pass immediately.
	tst.b -$522c(a4)
	beq.s .full
	IFD VERIFY_SCENE_TWIN
	lea _scene_twin_stage(pc),a0
	tst.l (a0)
	bne.s .full
	ENDC
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	beq.s .full
	tst.l DS_PENDING(a0)
	beq.s .full
	tst.b 34(a2)
	bne.s .full
	moveq #1,d0
.full:
	tst.b d0
	rts

	IFD VERIFY_SCENE_TWIN
; Validation only: repeat native preparation at the same pre-tail state. The
; reference invocation stops before its tail, so gameplay/audio events run once.
; A read-only harness compares contact flags, object metadata and near vertices
; at BEFORE/AFTER. Reference buffers remain live for the subsequent physics.
_scene_twin_signature: dc.b 'HDSCTWN1'
_scene_twin_stage: dc.l 0
_scene_twin_gate:
	movem.l d0-d7/a0-a6,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _scene_twin_stage(pc),a0
	tst.l (a0)
	bne.s _scene_twin_reference_done
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	beq.s _scene_twin_native_tail
	tst.l DS_PENDING(a0)
	beq.s _scene_twin_native_tail
	lea _scene_twin_stage(pc),a0
	move.l #1,(a0)
_scene_twin_before:
	nop
	movea.l _code_start(pc),a0
	adda.l #$b0d6,a0
	jsr (a0)
_scene_twin_after:
	nop
	lea _scene_twin_stage(pc),a0
	clr.l (a0)
	bra.s _scene_twin_native_tail
_scene_twin_reference_done:
	movea.l _code_start(pc),a0
	adda.l #$b18c,a0
	bra.s _scene_twin_redirect
_scene_twin_native_tail:
	tst.b -$16b6(a4)
	beq.s _scene_twin_restore
	movea.l _code_start(pc),a0
	adda.l #$b188,a0
_scene_twin_redirect:
	move.l a0,62(a7)
_scene_twin_restore:
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d7/a0-a6
	tst.b -$16b6(a4)
	rts
	ENDC
