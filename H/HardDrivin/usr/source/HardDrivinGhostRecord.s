; Phantom's 12-byte history: X,Z,Y,negated pitch/heading/roll. Sample every
;48 eligible fields, with the native first sample at40 (six pre-increments
;over poses at0,8,16,24,32,40). Charge the PREVIOUS simulation interval because
;the recorder runs before physics. Ghost playback remains separate work.
_ghost_record_install:
	IFD VERIFY_GHOST_RECORD_MATH
	bsr _ghost_record_math_test
	ENDC
	movem.l a0-a2,-(a7)
	lea _ghost_native_ptr(pc),a0
	move.l _code_start(pc),(a0)
	addi.l #$8aa2,(a0)
	lea _ghost_record_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_ghost_record_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_GHOST_RECORD $08a9c $0006: field-timed ghost recording
	PL_P $8a9c,_ghost_record
	; PERF_RANGE VERIFY_TIME_GHOST_RECORD $11858 $000a: ghost recording reset
	PL_PSS $11858,_ghost_record_reset,4
	PL_END
GR_STAMP equ 0
GR_POINTER equ 4
GR_AGE equ 8
GR_EMITTED equ 12
GR_PHASE equ 16
GR_PREV_FIELDS equ 18
GR_VALID equ 20
GR_SIZE equ 24
_ghost_record_signature: dc.b 'HDGHREC1'
_ghost_record_state: dcb.b GR_SIZE,0
_ghost_record_previous: dcb.b 12,0
_ghost_record_current: dcb.b 12,0
_ghost_native_ptr: dc.l 0
_ghost_record_reset:
	movem.l d0/a0,-(a7)
	lea _ghost_record_state(pc),a0
	moveq #GR_SIZE/4-1,d0
.clear:
	clr.l (a0)+
	dbf d0,.clear
	movem.l (a7)+,d0/a0
	move.l -$69bc(a4),-$16dc(a4)
	clr.b -$16de(a4)
	rts
_ghost_record:
	IFD VERIFY_DISPATCH_NATIVE
	bra _ghost_record_native
	ELSE
	move.l a0,-(a7)
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	movea.l (a7)+,a0
	beq.s _ghost_record_native
	tst.b -$5222(a4)
	beq.s _ghost_record_native
_ghost_record_elapsed:
	movem.l d0-d7/a0-a6,-(a7)
	move.l _ghost_record_state+GR_EMITTED(pc),-(a7)
	bsr _ghost_record_timed
	move.l (a7)+,d0
	cmp.l _ghost_record_state+GR_EMITTED(pc),d0
	beq.s .clear_x
	; A native emission leaves X from NEG.W of the current roll. ADDQ of
	; the phase clears X on visits without an emission. Preserve that quirk.
	tst.w -$66b8(a4)
	beq.s .clear_x
	moveq #1,d0
	bra.s .set_x
.clear_x:
	moveq #0,d0
.set_x:
	lsr.w #1,d0
	movem.l (a7)+,d0-d7/a0-a6
	rts
	ENDC
_ghost_record_native:
	link a5,#0
	move.l a2,-(a7)
	move.l _ghost_native_ptr(pc),-(a7)
	rts
; All registers are caller-saved by the wrapper. This private entry also
; permits synthetic arithmetic checks without patching any game state.
_ghost_record_timed:
	lea _ghost_record_state(pc),a3
	tst.b GR_VALID(a3)
	beq.s .first
	move.l -$16dc(a4),d0
	cmp.l GR_POINTER(a3),d0
	bne.s .first
	move.l _dispatch_state+DS_STEPS(pc),d0
	cmp.l GR_STAMP(a3),d0
	beq .done
	lea _ghost_record_current(pc),a0
	lea _ghost_record_previous(pc),a1
	bsr _ghost_copy
	bsr _ghost_capture
	moveq #0,d6
	move.l GR_STAMP(a3),d0
	addq.l #1,d0
	cmp.l _dispatch_state+DS_STEPS(pc),d0
	bne.s .stamp
	move.w GR_PREV_FIELDS(a3),d6
.stamp:
	bsr _ghost_stamp
	add.l d6,GR_AGE(a3)
	moveq #0,d0
	move.w GR_PHASE(a3),d0
	moveq #48,d7
	sub.w d0,d7
	add.l d6,d0
	divu.w #48,d0
	swap d0
	move.w d0,GR_PHASE(a3)
.samples:
	cmp.l d6,d7
	bhi.s .publish_phase
	move.w d7,d2
	lea _ghost_record_previous(pc),a0
	lea _ghost_record_current(pc),a1
	movea.l -$16dc(a4),a2
	bsr _ghost_interpolate
	bsr _ghost_publish
	addi.l #48,d7
	bra.s .samples
.first:
	bsr _ghost_capture
	bsr _ghost_stamp
	st GR_VALID(a3)
	; Native byte denotes completed pre-increments. The first observation
	; contributes the fixed8-field alignment bias, not fabricated elapsed age.
	moveq #0,d0
	move.b -$16de(a4),d0
	lsl.w #3,d0
	addq.w #8,d0
	cmpi.w #48,d0
	blo.s .seed
	lea _ghost_record_current(pc),a0
	movea.l -$16dc(a4),a1
	bsr _ghost_copy
	bsr _ghost_publish
	moveq #0,d0
.seed:
	move.w d0,GR_PHASE(a3)
.publish_phase:
	move.w GR_PHASE(a3),d0
	lsr.w #3,d0
	move.b d0,-$16de(a4)
	move.l -$16dc(a4),GR_POINTER(a3)
.done:
	rts
_ghost_stamp:
	move.l _dispatch_state+DS_STEPS(pc),GR_STAMP(a3)
	move.w _time_scalar_fields(pc),GR_PREV_FIELDS(a3)
	rts
_ghost_capture:
	lea _ghost_record_current(pc),a0
	move.w -$6710(a4),(a0)+
	move.w -$670c(a4),(a0)+
	move.w -$670e(a4),(a0)+
	move.w -$66bc(a4),d0
	neg.w d0
	move.w d0,(a0)+
	move.w -$66ba(a4),d0
	neg.w d0
	move.w d0,(a0)+
	move.w -$66b8(a4),d0
	neg.w d0
	move.w d0,(a0)+
	rts
_ghost_copy:
	move.l (a0)+,(a1)+
	move.l (a0)+,(a1)+
	move.l (a0)+,(a1)+
	rts
; D2 numerator, D6 denominator; A0 previous,A1 current,A2 output.
; Reuse the validated unsigned/signed/short-angle word interpolators.
_ghost_interpolate:
	cmp.w d6,d2
	bne.s .fraction
	movea.l a1,a0
	movea.l a2,a1
	bra _ghost_copy
.fraction:
	bsr _record_unsigned_word
	bsr _record_unsigned_word
	bsr _record_signed_word
	bsr _record_angle_word
	bsr _record_angle_word
	bra _record_angle_word
_ghost_publish:
	addq.l #1,GR_EMITTED(a3)
	movea.l -$16dc(a4),a0
	adda.w #12,a0
	movea.l -$69bc(a4),a1
	adda.w #3600,a1
	cmpa.l a1,a0
	bhs.s .full
	move.l a0,-$16dc(a4)
.full:
	; Exactly the native capacity rule: keep overwriting slot299, no wrap.
	rts

	IFD VERIFY_GHOST_RECORD_MATH
; Private boot fixture. The actual, still-unpatched native recorder is called
; with separate synthetic globals. No game pose, input or history is injected.
_ghost_record_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	move.l _dispatch_state+DS_STEPS(pc),-(a7)
	move.w _time_scalar_fields(pc),-(a7)
	lea _ghost_test_globals(pc),a4
	adda.l #$69bc,a4
	lea _ghost_test_results(pc),a5
	lea -$49bc(a4),a0
	move.l a0,12(a5)
	lea -$39bc(a4),a0
	move.l a0,4(a5)
	move.b #1,-$5222(a4)
	movea.l _code_start(pc),a6
	adda.l #$8a9c,a6
.loop:
	move.w (a5),d0
	mulu.w #7,d0
	addi.w #1000,d0
	move.w d0,-$6710(a4)
	move.w (a5),d0
	mulu.w #5,d0
	neg.w d0
	addi.w #60000,d0
	move.w d0,-$670c(a4)
	move.w (a5),d0
	subi.w #500,d0
	move.w d0,-$670e(a4)
	move.w #-700,-$66bc(a4)
	move.w #700,-$66ba(a4)
	clr.w -$66b8(a4)
	btst #1,1(a5)
	beq.s .roll_ready
	move.w #-16,-$66b8(a4)
.roll_ready:
	lea -$49bc(a4),a0
	move.l a0,-$69bc(a4)
	move.l 12(a5),-$16dc(a4)
	move.b 16(a5),-$16de(a4)
	moveq #0,d0
	move.w (a5),d0
	addq.l #1,d0
	lea _dispatch_state(pc),a0
	move.l d0,DS_STEPS(a0)
	lea _time_scalar_fields(pc),a0
	move.w #8,(a0)
	bsr _ghost_record_elapsed
	moveq #0,d0
	roxl.b #1,d0
	move.b d0,17(a5)
	move.l -$16dc(a4),12(a5)
	move.b -$16de(a4),16(a5)
	lea -$39bc(a4),a0
	move.l a0,-$69bc(a4)
	move.l 4(a5),-$16dc(a4)
	move.b 8(a5),-$16de(a4)
	jsr (a6)
	moveq #0,d0
	roxl.b #1,d0
	move.b d0,9(a5)
	move.l -$16dc(a4),4(a5)
	move.b -$16de(a4),8(a5)
	move.b 9(a5),d0
	cmp.b 17(a5),d0
	bne.s .mismatch
	move.b 8(a5),d0
	cmp.b 16(a5),d0
	bne.s .mismatch
	move.l 4(a5),d0
	subi.l #$1000,d0
	cmp.l 12(a5),d0
	beq.s .next
.mismatch:
	addq.l #1,20(a5)
.next:
	addq.w #1,(a5)
	cmpi.w #1860,(a5)
	blo .loop
	lea _ghost_record_state(pc),a0
	lea 24(a5),a1
	moveq #GR_SIZE/4-1,d0
.copy_native:
	move.l (a0)+,(a1)+
	dbf d0,.copy_native
	; A full unsigned-word interval crosses 1365 sample boundaries, including
	; many overwrites of the final slot. Exercise signed height and angle wrap.
	lea -$29bc(a4),a0
	move.l a0,-$69bc(a4)
	bsr _ghost_record_reset
	move.w #65535,-$6710(a4)
	clr.w -$670c(a4)
	move.w #-32768,-$670e(a4)
	move.w #-700,-$66bc(a4)
	move.w #700,-$66ba(a4)
	move.w #-16,-$66b8(a4)
	lea _dispatch_state(pc),a0
	move.l #1,DS_STEPS(a0)
	lea _time_scalar_fields(pc),a0
	move.w #65535,(a0)
	bsr _ghost_record_timed
	clr.w -$6710(a4)
	move.w #65535,-$670c(a4)
	move.w #32767,-$670e(a4)
	move.w #700,-$66bc(a4)
	move.w #-700,-$66ba(a4)
	move.w #17,-$66b8(a4)
	lea _dispatch_state(pc),a0
	move.l #2,DS_STEPS(a0)
	lea _time_scalar_fields(pc),a0
	move.w #8,(a0)
	bsr _ghost_record_timed
	lea _ghost_record_state(pc),a0
	lea 48(a5),a1
	moveq #GR_SIZE/4-1,d0
.copy_wide:
	move.l (a0)+,(a1)+
	dbf d0,.copy_wide
	bsr _ghost_record_reset
	lea _time_scalar_fields(pc),a0
	move.w (a7)+,(a0)
	lea _dispatch_state(pc),a0
	move.l (a7)+,DS_STEPS(a0)
	movem.l (a7)+,d0-d7/a0-a6
	rts
_ghost_test_signature: dc.b 'HDGHRMT1'
_ghost_test_results: dcb.b 72,0
; Three guarded histories live in otherwise unused private global space.
_ghost_test_globals:
	dcb.b $2000,0
	dcb.b 3600,$a5
	dcb.b $1000-3600,$5a
	dcb.b 3600,$a5
	dcb.b $1000-3600,$5a
	dcb.b 3600,$a5
	dcb.b $5300-$4000-3600,$5a
	ENDC
