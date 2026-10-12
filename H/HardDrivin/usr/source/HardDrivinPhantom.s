; Experimental elapsed dispatcher for the separate Phantom challenge loop.
; This covers challenge physics only. The six-pass ghost record/playback and
; post-race presentation are separate unfinished work, not acceptance evidence.
_phantom_install:
	movem.l a0-a2,-(a7)
	lea _phantom_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_phantom_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_PHANTOM $11894 $0006: challenge outer epoch/exit
	PL_P $11894,_phantom_outer
	; PERF_RANGE VERIFY_TIME_PHANTOM $11668 $0008: controls once per outer frame
	PL_PSS $11668,_phantom_controls,2
	; PERF_RANGE VERIFY_TIME_PHANTOM $116bc $0008: challenge substep or draw
	PL_PSS $116bc,_phantom_after_physics,2
	; PERF_RANGE VERIFY_TIME_PHANTOM $116e6 $0008: replay exclusion and native return
	PL_P $116e6,_phantom_replay_exit
	PL_END
_phantom_outer:
	movem.l d0-d1/a0-a1,-(a7)
	moveq #0,d1
	roxl.b #1,d1
	move.w d1,-(a7)
	lea _time_state(pc),a0
	tst.b -$16cf(a4)
	beq.s .leave
	tst.b TS_ACTIVE(a0)
	bne.s .measure
	st TS_ACTIVE(a0)
	bsr _time_reset_scalars
	move.l TS_FIELDS(a0),TS_PREVIOUS(a0)
.measure:
	move.l TS_FIELDS(a0),d0
	move.l d0,d1
	sub.l TS_PREVIOUS(a0),d0
	move.l d1,TS_PREVIOUS(a0)
	move.l d0,TS_ELAPSED(a0)
	add.l d0,TS_OBSERVED(a0)
	addq.l #1,TS_PASSES(a0)
	bsr _dispatch_begin
	movea.l _code_start(pc),a1
	adda.l #$1189a,a1
	bra.s .return
.leave:
	clr.b TS_ACTIVE(a0)
	movea.l _code_start(pc),a1
	adda.l #$118a4,a1
.return:
	move.l a1,TS_RETURN(a0)
	move.w (a7)+,d1
	lsr.b #1,d1
	movem.l (a7)+,d0-d1/a0-a1
	move.l _time_state+TS_RETURN(pc),-(a7)
	tst.b -$16cf(a4)
	rts
_phantom_controls:
	move.l a0,-(a7)
	lea _dispatch_state(pc),a0
	tst.b DS_FIRST(a0)
	beq.s .held
	clr.b DS_FIRST(a0)
	movea.l (a7)+,a0
	jsr -$7e7e(a4)
	bra.s .done
.held:
	movea.l (a7)+,a0
	bsr _dispatch_held_ramps
.done:
	tst.b -$6864(a4)
	rts
_phantom_after_physics:
	movem.l d0-d2/a0-a1,-(a7)
	lea _dispatch_state(pc),a0
	tst.b -$16cf(a4)
	bne.s .continuing
	move.l DS_PENDING(a0),d0
	add.l d0,DS_DISCARDED(a0)
	clr.l DS_PENDING(a0)
.continuing:
	tst.l DS_PENDING(a0)
	beq.s .draw
	bsr _dispatch_take
	movea.l _code_start(pc),a1
	; Re-enter inside the existing LINK frame, never recurse through11664.
	adda.l #$11668,a1
	move.l a1,20(a7)
	movem.l (a7)+,d0-d2/a0-a1
	rts
.draw:
	clr.b DS_ACTIVE(a0)
	movem.l (a7)+,d0-d2/a0-a1
	jsr -$7fec(a4)
	move.l _dispatch_scene_ptr(pc),-(a7)
	rts
_phantom_replay_exit:
	bsr _time_replay_call
	; Native11664 frame. Its caller1189e submits exactly once.
	unlk a5
	rts
