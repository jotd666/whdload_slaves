; VERIFY-only CUSTOM2 bit 14: quiescent native cockpit-program boundaries.
; This is a pixel/state diagnostic, never a performance measurement.
; PERF_RANGE sim:28962 8 bit=14
; PERF_RANGE sim:28d52 8 bit=14
; The original interpreter runs unchanged between these two complete prologues.
overlay_probe_install:
	movem.l d0-a6,-(sp)
	lea .check_base(pc),a6
.check_base
	adda.l #perf_check_bytes-.check_base,a6
	move.l #$28962,d0
	moveq #8,d1
	lea .entry_bytes(pc),a0
	jsr (a6)
	move.l #$28d52,d0
	lea .exit_bytes(pc),a0
	jsr (a6)
	move.l a1,d0
	addi.l #$2896a,d0
	lea overlay_probe_resume(pc),a0
	move.l d0,(a0)
	; MOVE from SR is user accessible only on 68000. All supported later
	; processors use MOVE from CCR; restoration is unprivileged on both.
	btst #0,observe_attnflags+3(pc)
	beq.b .cpu_ready
	lea overlay_probe_save_ccr(pc),a0
	move.w #$42e7,(a0)
	lea overlay_pack_save_ccr(pc),a0
	move.w #$42e7,(a0)
.cpu_ready
	bsr overlay_blit_selftest
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
.entry_bytes: dc.w $4e55,$ffdc,$48e7,$3732
.exit_bytes: dc.w $4cdf,$4cec,$4e5d,$4e75
.patch
	PL_START
	PL_P $28962,overlay_probe_enter
	PL_NOP $28968,2
	PL_P $28d52,overlay_probe_leave
	PL_NOP $28d58,2
	PL_END

overlay_probe_enter:
	movem.l d0/a0,-(sp)
	lea overlay_probe_header(pc),a0
	move.w 12(sp),(a0) ; native argument at original SP+4
	addq.l #1,4(a0)
	movem.l (sp)+,d0/a0
	bsr overlay_probe_wait
	bsr overlay_mask_verify
	bsr overlay_shadow_before
; Entry flags are overwritten by native MOVE.W argument load at sim:2896a.
overlay_probe_before:
	nop
	link a5,#-36
	movem.l d2-d3/d5-d7/a2-a3/a6,-(sp)
	move.l overlay_probe_resume(pc),-(sp)
	rts

overlay_probe_leave:
	bsr overlay_probe_wait
	bsr overlay_pack_verify
; D0, all saved registers and the native MOVE.W result flags remain intact.
overlay_probe_after:
	nop
	movem.l (sp)+,d2-d3/d5-d7/a2-a3/a6
	unlk a5
	rts

overlay_probe_wait:
overlay_probe_save_ccr: dc.w $40e7 ; move.w sr,-(sp), changed to CCR on 010+
	; The initial custom-register read also handles the early Agnus busy quirk.
	tst.w $dff002
.wait
	btst #6,$dff002
	bne.b .wait
	move.w (sp)+,ccr
	rts

overlay_probe_resume: dc.l 0
overlay_probe_header: dc.w 0,0 ; current native program, reserved
	dc.l 0 ; entry count (diagnostic only)
