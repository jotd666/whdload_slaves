; Normalize player heading and conserve ground displacement at 50 Hz.
; Selected only by the enhanced simulation patch list.
	IFNE STEP_FIELDS-1
	FAIL "Normalized steering requires one-field simulation"
	ENDC

step_steering_heading:
	move.l $26(a1),d0
	lsr.l #8,d0
	move.l d0,d1
	tst.b $6e(a1)
	bpl .native
; Heading/pose uses the existing four-field timing reference. The ground
; motion hook applies the same reference before native rounding and grip.
	moveq #0,d0
	move.w $12(a1),d0
	lsl.l #2,d0
	lsr.l #8,d0
.native:
	muls.w $42(a1),d0
	asr.l #8,d0
	move.w d0,$c(a1)
	jmp $8b94c
public_ref_142 equ *-4

step_steering_motion:
	tst.b $6e(a1)
	bpl .native
; Evaluate the complete native displacement at the reference quantum. Do not
; accumulate road-only fractions that native /256 and *13/16 discard.
	moveq #0,d0
	move.w $12(a1),d0
	lsl.l #2,d0
	lsr.l #8,d0
.native:
	muls.w d1,d0
	asr.l #8,d0
	btst #5,$68(a1)
	jmp $8b984
public_ref_143 equ *-4

step_steering_store:
	tst.b $6e(a1)
	bpl .native
	btst #0,$68(a1)
	bne .native
; Native rounding and skid scaling have finished. Integrate one quarter of
; that signed reference displacement, retaining quarter-unit position.
	movem.l d1-d2/a0,-(a7)
	lea step_steering_fraction(pc),a0
	ext.l d0
	add.l (a0),d0
	move.l d0,d1
	bpl .positive
	neg.l d0
.positive:
	move.l d0,d2
	andi.l #3,d2
	lsr.l #2,d0
	tst.l d1
	bpl .store
	neg.l d0
	neg.l d2
.store:
	move.l d2,(a0)
	movem.l (a7)+,d1-d2/a0
	bra .write
.native:
	move.l a0,-(a7)
	lea step_steering_fraction(pc),a0
	clr.l (a0)
	move.l (a7)+,a0
.write:
	move.w d0,$22(a1)
	add.w d0,(a1)
	rts

; Airborne crash states bypass the ground-motion hook altogether. Clear at
; the completed simulation boundary too, before any later remount can reuse
; a residual from the pre-crash trajectory.
step_steering_finish:
	tst.b $a5dce
public_ref_144 equ *-4
	bmi .done
	move.l a0,-(a7)
	lea step_steering_fraction(pc),a0
	clr.l (a0)
	lea step_road_fraction(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)
	move.l (a7)+,a0
.done:
	rts

	cnop 0,4
step_steering_fraction:
	dc.l 0

	include road_timing.s
