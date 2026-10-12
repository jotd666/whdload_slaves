; Experimental reference integrator, not a performance-accepted policy.
; Grounded automatic driving advances engine and projected position in fields.
; Steering, contact/scene work and input sampling remain once per outer pass.
; Zero/eight-field intervals and other driving modes keep the native pair.
_drivetrain_install:
	movem.l d0/a0-a2,-(a7)
	lea _drivetrain_engine(pc),a0
	move.l _code_start(pc),d0
	addi.l #$b662,d0
	move.l d0,(a0)+
	move.l _code_start(pc),d0
	addi.l #$b500,d0
	move.l d0,(a0)+
	move.l _code_start(pc),d0
	addi.l #$baea,d0
	move.l d0,(a0)
	lea _drivetrain_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,d0/a0-a2
	rts
_drivetrain_patches:
	PL_START
	; PERF_RANGE VERIFY_DRIVETRAIN_REFERENCE $0cdb6 $0008: engine/position reference integration
	PL_PSS $cdb6,_drivetrain_frame,2
	; PERF_RANGE VERIFY_DRIVETRAIN_REFERENCE $0baca $0006: publish engine pitch once per outer pass
	PL_PS $baca,_drivetrain_audio
	PL_END
_drivetrain_engine: dc.l 0
_drivetrain_position: dc.l 0
_drivetrain_audio_exit: dc.l 0
	dc.b 'HDDRIVE1'
; Original interval, remaining fields, held brake, active; engine calls, frames.
; Active1 integrates ticks; active2 publishes the already-integrated final pose.
_drivetrain_state: dc.w 0,0,0,0
	dc.l 0,0
	dc.b 'HDDTICK1'
_drivetrain_tick_offsets:
	dc.l _drivetrain_tick_before-_drivetrain_tick_offsets
	dc.l _drivetrain_tick_after-_drivetrain_tick_offsets

_drivetrain_frame:
	movem.l d0/a0,-(a7)
	lea _drivetrain_state(pc),a0
	clr.w 6(a0)
	move.w _time_scalar_fields(pc),d0
	move.w d0,(a0)
	beq .single
	cmpi.w #8,d0
	beq .single
	move.b _dispatch_state+DS_ACTIVE(pc),d0
	beq .single
	tst.b -$69fa(a4)
	bne .single
	tst.b -$50cf(a4)
	bne .single
	cmpi.b #15,-$66f0(a4)
	bne .single
	tst.w -$66f2(a4)
	bne .single
	tst.b -$66c2(a4)
	beq .single
	cmpi.w #1,-$66ca(a4)
	blt .single
	cmpi.w #4,-$66ca(a4)
	bgt .single
	move.w (a0),2(a0)
	moveq #0,d0
	move.b -$66ef(a4),d0
	move.w d0,4(a0)
	move.w #1,6(a0)
	addq.l #1,12(a0)
	lea _time_scalar_fields(pc),a0
	move.w #1,(a0)
	movem.l (a7)+,d0/a0
.loop:
	movem.l d0/a0,-(a7)
	lea _drivetrain_state(pc),a0
	move.w 4(a0),d0
	move.b d0,-$66ef(a4)
	addq.l #1,8(a0)
	movem.l (a7)+,d0/a0
	bsr _drivetrain_engine_tick
	; Keep outputs and incoming X from the last native position call.
	movem.l d0/a0,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _drivetrain_state(pc),a0
	subq.w #1,2(a0)
	beq.s .finish
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0/a0
	bra.s .loop
.finish:
	move.w (a0),d0
	move.w #2,6(a0)
	lea _time_scalar_fields(pc),a0
	move.w d0,(a0)
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0/a0
	pea .published(pc)
	move.l _drivetrain_position(pc),-(a7)
	rts
.published:
	move.l a0,-(a7)
	lea _drivetrain_state(pc),a0
	clr.w 6(a0)
	movea.l (a7)+,a0
	rts
.single:
	addq.l #1,8(a0)
	addq.l #1,12(a0)
	movem.l (a7)+,d0/a0
	; This common pair also exercises the original n=8 compatibility path.
_drivetrain_pair:
	pea .position(pc)
	move.l _drivetrain_engine(pc),-(a7)
	rts
.position:
	move.l _drivetrain_position(pc),-(a7)
	rts

; The engine does not consume word positions. Accumulate the exact fieldwise
; projected displacement here; run native word-pose/gravity/skid housekeeping
; once after the final tick, with the full original interval restored.
_drivetrain_engine_tick:
	pea .position(pc)
	move.l _drivetrain_engine(pc),-(a7)
	rts
.position:
	movem.l d0-d4/a0,-(a7)
	bsr _projection_snapshot
	lea _motion_position_state(pc),a0
	move.w -$66e2(a4),(a0)+
	move.w -$66e0(a4),(a0)+
	move.w -$66de(a4),(a0)
	move.w -$66d8(a4),d0
	bsr _projection_integer_components
	move.w d0,-$66e2(a4)
	move.w d1,-$66e0(a4)
	move.w d2,-$66de(a4)
_drivetrain_tick_before:
	bsr _motion_position_add
_drivetrain_tick_after:
	movem.l (a7)+,d0-d4/a0
	rts

_drivetrain_audio:
	move.l a0,-(a7)
	lea _drivetrain_state(pc),a0
	tst.w 6(a0)
	beq.s .native
	cmpi.w #1,2(a0)
	bhi.s .skip
.native:
	tst.b -$5224(a4)
	bne.s .done
.skip:
	move.l _drivetrain_audio_exit(pc),4(a7)
.done:
	movea.l (a7)+,a0
	rts
