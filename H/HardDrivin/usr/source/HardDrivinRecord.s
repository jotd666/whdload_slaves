; Development fixed-field replay history. Native record format and 90 slots stay
; intact: one sample every 8 eligible simulation fields, with pose resampling.
; D960 records the pose at the START of a step, so consecutive records charge
; the PREVIOUS step's fields. Collision rebuilds replace the same timestamp.
_record_install:
	IFD VERIFY_RECORD_MATH
	bsr _record_math_test
	bsr _record_wrap_test
	ENDC
	movem.l a0-a2,-(a7)
	lea _record_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_record_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_RECORD $08988 $0008: history epoch reset
	PL_PSS $8988,_record_reset,2
	; PERF_RANGE VERIFY_TIME_RECORD $0db0e $0008: fixed-field replay recording
	PL_PSS $db0e,_record_step,2
	; PERF_RANGE VERIFY_TIME_RECORD $089b4 $000c: collision replacement transaction
	PL_P $89b4,_record_rewind
	PL_NOP $89ba,6
	PL_END
RR_STAMP equ 0
RR_WRITE equ 4
RR_AGE equ 8
RR_EMITTED equ 12
RR_REPLACED equ 16
RR_PHASE equ 20
RR_BEFORE equ 22
RR_FIELDS equ 24
RR_PREVIOUS_FIELDS equ 26
RR_VALID equ 28
RR_NEW equ 29
RR_FIRST equ 30
RR_SIZE equ 32
_record_signature: dc.b 'HDRECRD1'
_record_state: dcb.b RR_SIZE,0
_record_previous: dcb.b 158,0
_record_current: dcb.b 158,0
_record_reset:
	movem.l d0/a1,-(a7)
	lea _record_state(pc),a1
	moveq #RR_SIZE/4-1,d0
.clear:
	clr.l (a1)+
	dbf d0,.clear
	movem.l (a7)+,d0/a1
	lea -$4e6e(a4),a0
	move.l a0,-$16e2(a4)
	rts
_record_native:
	movea.l _code_start(pc),a0
	adda.l #$89d8,a0
	jmp (a0)
_record_step:
	IFD VERIFY_DISPATCH_NATIVE
	bsr _record_native
	ELSE
	move.l a0,-(a7)
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	movea.l (a7)+,a0
	bne.s .timed
	bsr _record_native
	bra .done
.timed:
	movem.l d0-d7/a0-a6,-(a7)
	lea _record_state(pc),a3
	clr.b RR_NEW(a3)
	tst.b RR_VALID(a3)
	beq.s .new
	move.l _dispatch_state+DS_STEPS(pc),d0
	cmp.l RR_STAMP(a3),d0
	beq .capture
.new:
	st RR_NEW(a3)
	clr.b RR_FIRST(a3)
	move.l -$16e2(a4),RR_WRITE(a3)
	move.w RR_PHASE(a3),RR_BEFORE(a3)
	clr.w RR_FIELDS(a3)
	tst.b RR_VALID(a3)
	beq.s .first
	; Missing eligible visits freeze history time rather than interpolate a gap.
	move.l RR_STAMP(a3),d0
	addq.l #1,d0
	cmp.l _dispatch_state+DS_STEPS(pc),d0
	bne.s .stamp
	move.w RR_PREVIOUS_FIELDS(a3),RR_FIELDS(a3)
	bra.s .stamp
.first:
	st RR_FIRST(a3)
.stamp:
	move.l _dispatch_state+DS_STEPS(pc),RR_STAMP(a3)
	move.w _time_scalar_fields(pc),RR_PREVIOUS_FIELDS(a3)
	moveq #0,d0
	move.w RR_FIELDS(a3),d0
	add.l d0,RR_AGE(a3)
	lea _record_current(pc),a0
	lea _record_previous(pc),a1
	bsr _record_copy
.capture:
	; The native sampler writes only this record and advances the write pointer.
	; VBL does not consume that pointer. Restore it before any game caller resumes.
	move.l -$16e2(a4),-(a7)
	lea _record_current(pc),a0
	move.l a0,-$16e2(a4)
	bsr _record_native
	move.l (a7)+,-$16e2(a4)
	lea _record_state(pc),a3
	bsr _record_emit
.restore:
	st RR_VALID(a3)
	; The native sampler's valid ring-pointer addition clears X.
	moveq #0,d0
	lsr.w #1,d0
	movem.l (a7)+,d0-d7/a0-a6
.done:
	ENDC
	tst.w -$5226(a4)
	rts
; Emit every eligible sample from the saved transaction origin. A3 state;
; D6/D7 hold interval/numerator across interpolation and ring publication.
_record_emit:
	; Rebuild the complete emission transaction from its original write slot.
	; A collision can replace several samples, without consuming time again.
	move.l RR_WRITE(a3),-$16e2(a4)
	tst.b RR_FIRST(a3)
	bne.s .first_sample
	moveq #0,d0
	move.w RR_BEFORE(a3),d0
	moveq #0,d6
	move.w RR_FIELDS(a3),d6
	add.l d6,d0
	andi.w #7,d0
	move.w d0,RR_PHASE(a3)
	moveq #8,d7
	sub.w RR_BEFORE(a3),d7
.samples:
	cmp.l d6,d7
	bhi.s .done
	move.w d7,d2
	lea _record_previous(pc),a0
	lea _record_current(pc),a1
	movea.l -$16e2(a4),a2
	bsr _record_interpolate
	bsr.s .publish
	addq.l #8,d7
	bra.s .samples
.first_sample:
	lea _record_current(pc),a0
	movea.l -$16e2(a4),a1
	bsr _record_copy
	bsr.s .publish
	bra.s .done
.publish:
	lea _record_state(pc),a3
	tst.b RR_NEW(a3)
	beq.s .replacement
	addq.l #1,RR_EMITTED(a3)
	bra.s .advance
.replacement:
	addq.l #1,RR_REPLACED(a3)
.advance:
	movea.l -$16e2(a4),a0
	adda.w #158,a0
	lea -$16e2(a4),a1
	cmpa.l a1,a0
	blo.s .pointer
	lea -$4e6e(a4),a0
.pointer:
	move.l a0,-$16e2(a4)
	rts
.done:
	rts
_record_rewind:
	IFND VERIFY_DISPATCH_NATIVE
	move.l a0,-(a7)
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	movea.l (a7)+,a0
	beq.s .native
	; A repeated D960 visit reuses RR_WRITE and RR_BEFORE. No time is charged
	; twice, and a step that emitted no sample must not rewind older history.
	rts
.native:
	ENDC
	subi.l #158,-$16e2(a4)
	lea -$4e6e(a4),a0
	movea.l -$16e2(a4),a1
	cmpa.l a0,a1
	bhs.s .done
	lea -$1780(a4),a0
	move.l a0,-$16e2(a4)
.done:
	rts
; A0 source,A1 destination, D0 clobbered. Native 158-byte record.
_record_copy:
	moveq #38,d0
.copy:
	move.l (a0)+,(a1)+
	dbf d0,.copy
	move.w (a0)+,(a1)+
	rts

; A0 left,A1 right,A2 result, D2 numerator,D6 unsigned denominator 1..65535.
; Exact field-rational weights; numerator is in 1..denominator.
; Unsigned weighted sum is at most 65535 squared, fitting a longword.
_record_interpolate:
	cmp.w d6,d2
	beq.s .right
	bsr _record_unsigned_word
	bsr _record_unsigned_word
	bsr _record_signed_word
	bsr _record_angle_word
	bsr _record_angle_word
	bsr _record_angle_word
	move.w (a0)+,d4
	move.w (a1)+,d1
	move.w d4,d0
	andi.w #$fff,d0
	andi.w #$fff,d1
	bsr _record_lerp_unsigned
	andi.w #$f000,d4
	or.w d4,d0
	move.w d0,(a2)+
	moveq #11,d5
.traffic:
	bsr _record_unsigned_word
	bsr _record_signed_word
	bsr _record_unsigned_word
	bsr _record_angle_word
	bsr _record_angle_word
	bsr _record_angle_word
	dbf d5,.traffic
	rts
.right:
	movea.l a1,a0
	movea.l a2,a1
	bsr _record_copy
	movea.l a1,a2
	rts
_record_unsigned_word:
	move.w (a0)+,d0
	move.w (a1)+,d1
	bsr _record_lerp_unsigned
	move.w d0,(a2)+
	rts
_record_signed_word:
	move.w (a0)+,d0
	move.w (a1)+,d1
	bsr _record_lerp_signed
	move.w d0,(a2)+
	rts
_record_angle_word:
	move.w (a0)+,d0
	move.w (a1)+,d1
	; Equal endpoints still need the native angle normalization below.
	cmp.w d0,d1
	beq.s .normalize
	move.w d1,d3
	sub.w d0,d3
	cmpi.w #720,d3
	ble.s .negative
	subi.w #1440,d1
	bra.s .lerp
.negative:
	cmpi.w #-720,d3
	bge.s .lerp
	addi.w #1440,d1
.lerp:
	bsr _record_lerp_signed
.normalize:
	cmpi.w #720,d0
	ble.s .low
	subi.w #1440,d0
.low:
	cmpi.w #-720,d0
	bge.s .store
	addi.w #1440,d0
.store:
	move.w d0,(a2)+
	rts
_record_lerp_unsigned:
	; A weighted mean of identical words is that word for every valid weight.
	; Callers consume D0.W only; D1/D3 and CCR are scratch.
	cmp.w d0,d1
	beq.s .equal
	move.w d6,d3
	sub.w d2,d3
	mulu.w d3,d0
	mulu.w d2,d1
	add.l d1,d0
	divu.w d6,d0
.equal:
	rts
_record_lerp_signed:
	; Bias both endpoints into 0..65535. Their weighted mean has the same
	; bias, so unsigned division gives floor even for negative signed values.
	; This also avoids interpreting a field weight above 32767 as negative.
	eori.w #$8000,d0
	eori.w #$8000,d1
	bsr _record_lerp_unsigned
	eori.w #$8000,d0
	rts

	IFD VERIFY_RECORD_MATH
_record_math_test:
	movem.l d0-d7/a0-a2,-(a7)
	lea _record_math_results(pc),a2
	moveq #1,d6
.denominator:
	moveq #1,d7
.numerator:
	lea _replay_math_left(pc),a0
	lea _replay_math_right(pc),a1
	move.w d7,d2
	bsr _record_interpolate
	addq.w #1,d7
	cmp.w d6,d7
	ble.s .numerator
	addq.w #1,d6
	cmpi.w #8,d6
	ble.s .denominator
	lea _record_wide_results(pc),a2
	lea _record_wide_inputs(pc),a0
	moveq #24-1,d7
.wide:
	move.w (a0)+,d2
	move.w (a0)+,d6
	move.l a0,-(a7)
	lea _replay_math_left(pc),a0
	lea _replay_math_right(pc),a1
	bsr _record_interpolate
	movea.l (a7)+,a0
	dbf d7,.wide
	movem.l (a7)+,d0-d7/a0-a2
	rts
_record_math_signature: dc.b 'HDRRMAT1'
_record_math_results: dcb.b 36*158,0
_record_wide_inputs:
	dc.w 1,9
	dc.w 4,9
	dc.w 8,9
	dc.w 9,9
	dc.w 1,15
	dc.w 7,15
	dc.w 14,15
	dc.w 15,15
	dc.w 1,16
	dc.w 8,16
	dc.w 15,16
	dc.w 16,16
	dc.w 1,255
	dc.w 127,255
	dc.w 254,255
	dc.w 255,255
	dc.w 1,32768
	dc.w 16384,32768
	dc.w 32767,32768
	dc.w 32768,32768
	dc.w 1,65535
	dc.w 32767,65535
	dc.w 65534,65535
	dc.w 65535,65535
_record_wide_signature: dc.b 'HDRRWM01'
_record_wide_results: dcb.b 24*158,0
_record_wrap_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _record_wrap_ring(pc),a4
	adda.l #$4e6e,a4
	lea _record_state(pc),a3
	moveq #RR_SIZE/4-1,d0
	movea.l a3,a0
.clear:
	clr.l (a0)+
	dbf d0,.clear
	lea _record_wrap_ring(pc),a0
	adda.l #88*158,a0
	move.l a0,RR_WRITE(a3)
	move.w #7,RR_BEFORE(a3)
	move.w #728,RR_FIELDS(a3)
	st RR_NEW(a3)
	lea _replay_math_left(pc),a0
	lea _record_previous(pc),a1
	bsr _record_copy
	lea _replay_math_right(pc),a0
	lea _record_current(pc),a1
	bsr _record_copy
	bsr _record_emit
	lea _record_wrap_results(pc),a1
	movea.l a3,a0
	moveq #RR_SIZE/4-1,d0
.save:
	move.l (a0),(a1)+
	clr.l (a0)+
	dbf d0,.save
	move.l -$16e2(a4),(a1)
	movem.l (a7)+,d0-d7/a0-a6
	rts
_record_wrap_signature: dc.b 'HDRRWRA1'
_record_wrap_results: dcb.b RR_SIZE+4,0
_record_wrap_ring: dcb.b 90*158+4,0
	ENDC
