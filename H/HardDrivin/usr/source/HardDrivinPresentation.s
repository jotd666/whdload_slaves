; Development-only overlay and recovery timing. Constant diagnostic fields
; currently come from TIME_SCALARS; the dispatcher must supply the appropriate
; elapsed interval when it separates simulation substeps from drawing.
_presentation_install:
	movem.l a0-a2,-(a7)
	lea _presentation_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_presentation_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_PRESENTATION $10246 $0008: overlay lifetime
	PL_PSS $10246,_presentation_overlay_tick,2
	; PERF_RANGE VERIFY_TIME_PRESENTATION $08e38 $0006: overlay60 start
	PL_PS $8e38,_presentation_overlay60
	; PERF_RANGE VERIFY_TIME_PRESENTATION $0935a $0006: overlay40 start
	PL_PS $935a,_presentation_overlay40
	; PERF_RANGE VERIFY_TIME_PRESENTATION $093a4 $0006: overlay40 restart
	PL_PS $93a4,_presentation_overlay40
	; PERF_RANGE VERIFY_TIME_PRESENTATION $09470 $0006: checkpoint overlay40
	PL_PS $9470,_presentation_overlay40
	; PERF_RANGE VERIFY_TIME_PRESENTATION $10604 $0006: recovery overlay60
	PL_PS $10604,_presentation_overlay60
	IFND VERIFY_TIME_MOTION
	; PERF_RANGE VERIFY_TIME_PRESENTATION $11694 $0006: Phantom overlay60
	PL_PS $11694,_presentation_overlay60
	ENDC
	; PERF_RANGE VERIFY_TIME_PRESENTATION $108aa $0006: recovery epoch gate
	PL_PS $108aa,_presentation_recovery_gate
	; PERF_RANGE VERIFY_TIME_PRESENTATION $108b8 $0008: recovery initialization once
	PL_PSS $108b8,_presentation_recovery_begin,2
	; PERF_RANGE VERIFY_TIME_PRESENTATION $10aa8 $0010: fractional recovery height
	PL_PSS $10aa8,_presentation_recovery_height,$a
	; PERF_RANGE VERIFY_TIME_PRESENTATION $10ae0 $000c: recovery phase and expiry
	PL_PSS $10ae0,_presentation_recovery_advance,6
	PL_END
_presentation_signature: dc.b 'HDPRES01'
; Overlay remaining fields.w,last visible count.w; recovery fields.w,active.w.
_presentation_overlay: dc.l 0
_presentation_recovery: dc.l 0
_presentation_overlay40:
	movem.l d0/a0,-(a7)
	moveq #40,d0
	bra.s _presentation_overlay_start
_presentation_overlay60:
	movem.l d0/a0,-(a7)
	moveq #60,d0
_presentation_overlay_start:
	lea _presentation_overlay(pc),a0
	move.w d0,2(a0)
	mulu.w #8,d0
	move.w d0,(a0)
	IFD VERIFY_TIME_REPLAY_TIMING
	tst.b -$5229(a4)
	beq.s .no_replay_restart
	bsr _replay_overlay_reset
.no_replay_restart:
	ENDC
	IFD VERIFY_TIME_TIMELINES
	lea _timeline_state(pc),a0
	tst.b TL_ACTIVE(a0)
	beq.s .no_timeline_restart
	bsr _timeline_overlay_reset
.no_timeline_restart:
	ENDC
	IFD VERIFY_TIME_DISPATCH
	; A restart partway through a frame must not consume earlier substeps.
	lea _dispatch_state(pc),a0
	moveq #0,d0
	move.w _time_scalar_fields(pc),d0
	move.l a1,-(a7)
	movea.l DS_PENDING(a0),a1
	adda.l d0,a1
	move.l a1,DS_OVERLAY_FIELDS(a0)
	movea.l (a7)+,a1
	ENDC
	movem.l (a7)+,d0/a0
	; Select the native byte from the state, preserving the caller's D0.
	move.l a0,-(a7)
	lea _presentation_overlay(pc),a0
	move.b 3(a0),-$50ce(a4)
	movea.l (a7)+,a0
	rts
_presentation_overlay_tick:
	movem.l d1-d2/a0,-(a7)
	moveq #0,d0
	move.b -$50ce(a4),d0
	move.w _time_scalar_fields(pc),d1
	IFD VERIFY_TIME_DISPATCH
	moveq #8,d1
	lea _time_state(pc),a0
	tst.b TS_ACTIVE(a0)
	bne.s .gameplay
	IFD VERIFY_TIME_TIMELINES
	lea _timeline_state(pc),a0
	tst.b TL_ACTIVE(a0)
	beq.s .no_timeline
	bsr _timeline_overlay_fields
	bra.s .interval
.no_timeline:
	ENDC
	IFD VERIFY_TIME_REPLAY_TIMING
	tst.b -$5229(a4)
	beq.s .interval
	bsr _replay_overlay_fields
	ENDC
	bra.s .interval
.gameplay:
	move.l _dispatch_state+DS_OVERLAY_FIELDS(pc),d1
	cmpi.l #65535,d1
	bls.s .interval
	move.l #65535,d1
.interval:
	ENDC
	lea _presentation_overlay(pc),a0
	bsr _presentation_countdown
	move.b d0,-$50ce(a4)
	; Native SUBQ on a nonzero unsigned count clears X; its following MOVE
	; then supplies the overlay mode and NZVC flags.
	moveq #0,d1
	lsr.w #1,d1
	movem.l (a7)+,d1-d2/a0
	move.b -$16d2(a4),d0
	rts
; D0.W visible unsigned count, D1.W elapsed fields, A0 remaining/last words.
; Saturating subtraction and ceiling publication; D0 returns new count.
_presentation_countdown:
	cmp.w 2(a0),d0
	beq.s .current
	lsl.w #3,d0
	move.w d0,(a0)
.current:
	move.w (a0),d2
	cmp.w d1,d2
	bhi.s .subtract
	moveq #0,d2
	bra.s .publish
.subtract:
	sub.w d1,d2
.publish:
	move.w d2,(a0)
	move.w d2,d0
	addq.w #7,d0
	lsr.w #3,d0
	move.w d0,2(a0)
	rts
_presentation_recovery_gate:
	move.l a0,-(a7)
	tst.b -$69fb(a4)
	bne.s .active
	lea _presentation_recovery(pc),a0
	clr.l (a0)
	bra.s .done
.active:
	movea.l _code_start(pc),a0
	adda.l #$108b8,a0
	move.l a0,4(a7)
.done:
	movea.l (a7)+,a0
	tst.b -$69fb(a4)
	rts
_presentation_recovery_begin:
	movem.l d0/a0,-(a7)
	moveq #0,d0
	move.b -$7314(a4),d0
	lea _presentation_recovery(pc),a0
	bsr _presentation_recovery_enter
	tst.b d0
	bne.s .initialize
	movea.l _code_start(pc),a0
	adda.l #$10972,a0
	move.l a0,8(a7)
.initialize:
	movem.l (a7)+,d0/a0
	rts
; D0 phase on entry, A0 state; returns1 only for the first phase-zero call.
_presentation_recovery_enter:
	tst.w 2(a0)
	bne.s .continuing
	move.w #1,2(a0)
	move.w d0,(a0)
	mulu.w #8,d0
	move.w d0,(a0)
	tst.w d0
	bne.s .continuing
	moveq #1,d0
	rts
.continuing:
	moveq #0,d0
	rts
_presentation_recovery_height:
	move.l a0,-(a7)
	lea _presentation_recovery(pc),a0
	bsr _presentation_height
	movea.l (a7)+,a0
	add.w d1,-$6708(a4)
	rts
; D1 word-height offset. Native ninth interval holds ground for eight fields.
_presentation_height:
	move.w (a0),d1
	cmpi.w #64,d1
	bhs.s .ground
	lsl.w #2,d1
	neg.w d1
	addi.w #256,d1
	rts
.ground:
	moveq #0,d1
	rts
_presentation_recovery_advance:
	movem.l d0-d2/a0,-(a7)
	lea _presentation_recovery(pc),a0
	move.w _time_scalar_fields(pc),d1
	bsr _presentation_recovery_step
	move.b d0,-$7314(a4)
	tst.w d2
	bne.s .expired
	movea.l _code_start(pc),a0
	adda.l #$10af8,a0
	move.l a0,16(a7)
.expired:
	movem.l (a7)+,d0-d2/a0
	rts
; A0 recovery state,D1 fields0..8; return D0 phase,D2 one-shot expiry.
_presentation_recovery_step:
	moveq #0,d0
	moveq #0,d2
	tst.w 2(a0)
	beq.s .done
	move.w (a0),d0
	add.w d1,d0
	cmpi.w #72,d0
	blo.s .publish
	moveq #72,d0
	clr.w 2(a0)
	moveq #1,d2
.publish:
	move.w d0,(a0)
	lsr.w #3,d0
.done:
	rts

	IFD VERIFY_PRESENTATION_MATH
; Execute the real helpers against private state, retaining every transition.
_presentation_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _presentation_test_state(pc),a0
	lea _presentation_results(pc),a2
	moveq #0,d7
.interval:
	clr.l (a0)
	moveq #0,d0
	bsr _presentation_recovery_enter
	move.w d0,(a2)+
	moveq #73,d6
.recovery:
	moveq #0,d0
	bsr _presentation_recovery_enter
	move.w d0,(a2)+
	bsr _presentation_height
	move.w d1,(a2)+
	move.w d7,d1
	bsr _presentation_recovery_step
	move.w d0,(a2)+
	move.w d2,(a2)+
	move.l (a0),(a2)+
	; Stop re-entering after expiry; test a second step is not another event.
	tst.w d2
	bne.s .expired
	dbf d6,.recovery
	bra.s .overlay
.expired:
	move.w d7,d1
	bsr _presentation_recovery_step
	move.w d0,(a2)+
	move.w d2,(a2)+
	move.l (a0),(a2)+
.overlay:
	; Fixed-size separate blocks avoid depending on the recovery loop length.
	lea _presentation_overlay_results(pc),a2
	move.w d7,d0
	mulu.w #500,d0
	adda.l d0,a2
	clr.l (a0)
	moveq #60,d0
	moveq #124,d6
.countdown:
	move.w d7,d1
	bsr _presentation_countdown
	move.w d0,(a2)+
	move.w (a0),(a2)+
	dbf d6,.countdown
	addq.w #1,d7
	lea _presentation_results(pc),a2
	move.w d7,d0
	mulu.w #900,d0
	adda.l d0,a2
	cmpi.w #8,d7
	ble .interval
	movem.l (a7)+,d0-d7/a0-a6
	rts
_presentation_test_state: dc.l 0
_presentation_math_signature: dc.b 'HDPRMAT1'
_presentation_results: dcb.b 9*900,0
_presentation_overlay_results: dcb.b 9*500,0
	ENDC
