; Development fixed-field replay history. Native record format and 90 slots stay
; intact: one sample every 8 eligible simulation fields, with pose resampling.
; D960 records the pose at the START of a step, so consecutive records charge
; the PREVIOUS step's fields. Collision rebuilds replace the same timestamp.
; Exact resampling is deferred until replay; no sample timestamps are changed.
_record_install:
	; Pending exact samples live outside the native ring until its first reader.
	; Allocate once; if unavailable, retain eager interpolation.
	movem.l d0-d1/a0-a2/a6,-(a7)
	lea _record_pending(pc),a2
	tst.l (a2)
	bne.s .allocated
	movea.l 4.w,a6
	move.l #90*8+91*316,d0
	move.l #MEMF_PUBLIC|MEMF_CLEAR,d1
	jsr _LVOAllocMem(a6)
	move.l d0,(a2)
.allocated:
	movem.l (a7)+,d0-d1/a0-a2/a6
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
	; PERF_RANGE VERIFY_TIME_RECORD $10b44 $000a: resolve exact history before native scan
	PL_PSS $10b44,_record_resolve_entry,4
	PL_END
_record_pending: dc.l 0
_record_pending_write: dc.l 0
_record_pending_origin: dc.l 0
_record_pair_write: dc.l 0
_record_pair_origin: dc.l 0
_record_pair_saved: dc.w 0
_record_previous_ptr: dc.l 0
_record_current_ptr: dc.l 0
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
	; The native reset clears only XYZ, so finish old samples first to retain
	; their untouched tail bytes too. Preserve the native reset's incoming X.
	moveq #0,d0
	roxl.w #1,d0
	move.w d0,-(a7)
	bsr _record_resolve
	lea _record_state(pc),a1
	moveq #RR_SIZE/4-1,d0
.clear:
	clr.l (a1)+
	dbf d0,.clear
	movea.l _record_pending(pc),a1
	move.l a1,d0
	beq.s .cleared
	moveq #89,d0
.clear_pending:
	clr.l (a1)
	addq.l #8,a1
	dbf d0,.clear_pending
.cleared:
	move.l a0,-(a7)
	lea _record_pending_write(pc),a0
	move.l _record_pending(pc),(a0)+
	move.l _record_pending(pc),(a0)+
	move.l _record_pending(pc),d0
	addi.l #90*8,d0
	move.l d0,(a0)+
	clr.l (a0)
	lea _record_previous_ptr(pc),a0
	lea _record_previous(pc),a1
	move.l a1,(a0)+
	lea _record_current(pc),a1
	move.l a1,(a0)
	movea.l (a7)+,a0
	move.w (a7)+,d0
	lsr.w #1,d0
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
	; An ineligible/native visit may overwrite a slot. Finish pending history
	; first, then follow the native write pointer before timed visits resume.
	bsr _record_resolve
	bsr _record_native
	movem.l d0/a0-a1,-(a7)
	lea -$4e6e(a4),a0
	move.l -$16e2(a4),d0
	sub.l a0,d0
	divu.w #158,d0
	lsl.l #3,d0
	add.l _record_pending(pc),d0
	lea _record_pending_write(pc),a1
	move.l d0,(a1)
	movem.l (a7)+,d0/a0-a1
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
	lea _record_pending_origin(pc),a0
	move.l _record_pending_write(pc),(a0)
	lea _record_pair_origin(pc),a0
	clr.l (a0)
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
	lea _record_previous_ptr(pc),a0
	move.l (a0),d0
	move.l 4(a0),(a0)
	move.l d0,4(a0)
.capture:
	; Same words as $89d8, without its C stack frame and repeated pointers.
	movea.l _record_current_ptr(pc),a2
	move.w -$6710(a4),(a2)+
	move.w -$670c(a4),(a2)+
	move.w -$670e(a4),(a2)+
	move.l -$66bc(a4),(a2)+
	move.w -$66b8(a4),(a2)+
	move.w -$69fe(a4),(a2)
	tst.b -$50cf(a4)
	beq.s .no_skid
	ori.w #$8000,(a2)
.no_skid:
	addq.l #2,a2
	movea.l -$50fa(a4),a0
	move.w -$50fc(a4),d0
	cmpi.w #12,d0
	bne .actors_test
HD_RECORD_ACTOR SET 8
	REPT 12
	movea.l HD_RECORD_ACTOR(a0),a1
	move.l 8(a1),(a2)+
	move.w 12(a1),(a2)+
	move.w 16(a1),(a2)+
	move.w 14(a1),(a2)+
	move.w 18(a1),(a2)+
HD_RECORD_ACTOR SET HD_RECORD_ACTOR+46
	ENDR
	bra.s .captured
.actors:
	movea.l 8(a0),a1
	move.l 8(a1),(a2)+
	move.w 12(a1),(a2)+
	move.w 16(a1),(a2)+
	move.w 14(a1),(a2)+
	move.w 18(a1),(a2)+
	adda.w #46,a0
.actors_test:
	dbf d0,.actors
.captured:
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
	lea _record_pending_write(pc),a0
	move.l _record_pending_origin(pc),(a0)
	lea _record_pair_saved(pc),a0
	clr.w (a0)
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
	movea.l _record_previous_ptr(pc),a0
	movea.l _record_current_ptr(pc),a1
	movea.l -$16e2(a4),a2
	bsr _record_defer
	bsr.s .publish
	addq.l #8,d7
	bra.s .samples
.first_sample:
	movea.l _record_current_ptr(pc),a0
	movea.l a0,a1
	movea.l -$16e2(a4),a2
	moveq #1,d2
	moveq #1,d6
	bsr _record_defer
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
; Ninety descriptors retain the exact numerator/denominator and endpoint pair.
; A transaction shares its pair across all crossed sample boundaries. There are
; 91 pairs: before a pair is reused, at least 90 later emitting transactions have
; overwritten every descriptor which could reference it. Collision rebuilding
; reuses its transaction's pair and descriptor origin, without advancing time.
_record_defer:
	IFD VERIFY_RECORD_MATH
	bra _record_interpolate
	ENDC
	movem.l d2/a3,-(a7)
	move.l _record_pending(pc),d0
	beq .eager
	movea.l _record_pair_origin(pc),a3
	move.l a3,d0
	bne.s .pair
	movea.l _record_pair_write(pc),a3
	lea _record_pair_origin(pc),a2
	move.l a3,(a2)
	move.l a3,d0
	addi.l #316,d0
	move.l d0,d1
	sub.l _record_pending(pc),d1
	cmpi.l #90*8+91*316,d1
	blo.s .advance_pair
	move.l _record_pending(pc),d0
	addi.l #90*8,d0
.advance_pair:
	move.l d0,-4(a2)
.pair:
	movea.l _record_pending_write(pc),a2
	move.l a3,(a2)+
	move.w d2,(a2)+
	move.w d6,(a2)+
	move.l a2,d0
	sub.l _record_pending(pc),d0
	cmpi.l #90*8,d0
	blo.s .next
	movea.l _record_pending(pc),a2
.next:
	lea _record_pending_write(pc),a3
	move.l a2,(a3)
	move.w _record_pair_saved(pc),d0
	bne.s .done
	lea _record_pair_saved(pc),a3
	st (a3)
	movea.l _record_pair_origin(pc),a3
	bsr.s _record_pair_copy
	movea.l a1,a0
	bsr.s _record_pair_copy
.done:
	movem.l (a7)+,d2/a3
	rts
.eager:
	movem.l (a7)+,d2/a3
	bra _record_interpolate
; A0 source/A3 destination; A1, A4, D6/D7 survive. The caller already saves the
; other registers. Both endpoints share this copy path.
_record_pair_copy:
	REPT 4
	movem.l (a0)+,d0-d5/a2/a5-a6
	movem.l d0-d5/a2/a5-a6,(a3)
	lea 36(a3),a3
	ENDR
	move.l (a0)+,(a3)+
	move.l (a0)+,(a3)+
	move.l (a0)+,(a3)+
	move.w (a0)+,(a3)+
	rts

_record_resolve_entry:
	bsr _record_resolve
	movea.l -$16e2(a4),a3
	suba.l #14220,a3
	rts
_record_resolve:
	IFND VERIFY_DISPATCH_NATIVE
	movem.l d0-d7/a0-a6,-(a7)
	movea.l _record_pending(pc),a3
	move.l a3,d0
	beq.s .done
	lea -$4e6e(a4),a4
	moveq #89,d7
.slot:
	move.l (a3),d0
	beq.s .next
	clr.l (a3)
	move.w 4(a3),d2
	move.w 6(a3),d6
	movea.l d0,a0
	lea 158(a0),a1
	movea.l a4,a2
	bsr _record_interpolate
.next:
	addq.l #8,a3
	adda.w #158,a4
	dbf d7,.slot
.done:
	movem.l (a7)+,d0-d7/a0-a6
	ENDC
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
	REPT 39
	move.l (a0)+,(a1)+
	ENDR
	move.w (a0)+,(a1)+
	rts

; Word classes: player U,U,S,A,A,A,packed; twelve traffic U,S,U,A,A,A.
; All 79 words remain interpolated, except the packed high nibble held left.
; Compute the exact weights once. Inline the word paths so unchanged words
; need no subroutine call, multiplication or division.
HD_RECORD_WORD MACRO
	move.w (a0)+,d0
	move.w (a1)+,d1
	cmp.w d0,d1
	beq.s .same\@
	IFC \1,A
	move.w d1,d4
	sub.w d0,d4
	cmpi.w #720,d4
	ble.s .negative\@
	subi.w #1440,d1
	bra.s .angle_ready\@
.negative\@:
	cmpi.w #-720,d4
	bge.s .angle_ready\@
	addi.w #1440,d1
.angle_ready\@:
	ENDC
	IFNC \1,U
	eori.w #$8000,d0
	eori.w #$8000,d1
	ENDC
	; With n<=255 and |delta|<=255 the Q16 coefficient error is
	; <1/n. Directed rounding therefore gives the exact rational floor.
	cmpi.w #255,d6
	bhi.s .general\@
	move.w d1,d4
	sub.w d0,d4
	bcs.s .falling\@
	cmpi.w #255,d4
	bhi.s .general\@
	move.l a5,d1
	mulu.w d4,d1
	swap d1
	add.w d1,d0
	bra.s .blended\@
.falling\@:
	neg.w d4
	cmpi.w #255,d4
	bhi.s .general\@
	move.l a6,d1
	mulu.w d4,d1
	addi.l #65535,d1
	swap d1
	sub.w d1,d0
	bra.s .blended\@
.general\@:
	mulu.w d3,d0
	mulu.w d2,d1
	add.l d1,d0
	divu.w d6,d0
.blended\@:
	IFNC \1,U
	eori.w #$8000,d0
	ENDC
.same\@:
	IFC \1,A
	cmpi.w #720,d0
	ble.s .low\@
	subi.w #1440,d0
.low\@:
	cmpi.w #-720,d0
	bge.s .store\@
	addi.w #1440,d0
.store\@:
	ENDC
	move.w d0,(a2)+
	ENDM

; A0 left,A1 right,A2 result, D2 numerator,D6 denominator (1..65535).
; D2/D6/D7 and A3-A6 preserved, D0/D1/D3-D5 scratch as before.
_record_interpolate:
	cmp.w d6,d2
	beq .right
	movem.l a5-a6,-(a7)
	moveq #0,d0
	move.w d2,d0
	swap d0
	divu.w d6,d0
	move.w d0,a6
	move.w d0,d1
	swap d0
	tst.w d0
	beq.s .coefficient
	addq.w #1,d1
.coefficient:
	move.w d1,a5
	move.w d6,d3
	sub.w d2,d3
	HD_RECORD_WORD U
	HD_RECORD_WORD U
	HD_RECORD_WORD S
	HD_RECORD_WORD A
	HD_RECORD_WORD A
	HD_RECORD_WORD A
	move.w (a0)+,d4
	move.w (a1)+,d1
	move.w d4,d0
	andi.w #$fff,d0
	andi.w #$fff,d1
	cmp.w d0,d1
	beq.s .packed
	mulu.w d3,d0
	mulu.w d2,d1
	add.l d1,d0
	divu.w d6,d0
.packed:
	andi.w #$f000,d4
	or.w d4,d0
	move.w d0,(a2)+
	moveq #11,d5
.traffic:
	HD_RECORD_WORD U
	HD_RECORD_WORD S
	HD_RECORD_WORD U
	HD_RECORD_WORD A
	HD_RECORD_WORD A
	HD_RECORD_WORD A
	dbf d5,.traffic
	movem.l (a7)+,a5-a6
	rts
.right:
	movea.l a1,a0
	movea.l a2,a1
	bsr _record_copy
	movea.l a1,a2
	rts

; Shared scalar helpers also serve the Phantom recorder.
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
	lea _record_previous_ptr(pc),a0
	lea _record_previous(pc),a1
	move.l a1,(a0)+
	lea _record_current(pc),a1
	move.l a1,(a0)
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
