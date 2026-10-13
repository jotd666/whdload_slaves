; Discrete native start/score events on an eight-field cadence. Keeping native
; BCD addition intact preserves its invalid-digit/carry quirks at native T.
; Each D960 scene rebuild may visit these hooks; only its first visit per
; elapsed substep accrues time. Forced-native verification retains every visit.
_events_install:
	IFD VERIFY_EVENTS_MATH
	bsr _events_math_test
	ENDC
	movem.l a0-a2,-(a7)
	lea _events_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_events_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_DISPATCH $0db1e $0014: score cadence, native BCD intact
	PL_PSS $db1e,_events_score,$e
	; PERF_RANGE VERIFY_TIME_DISPATCH $0db40 $000a: start phase cadence
	PL_PSS $db40,_events_start,4
	; PERF_RANGE VERIFY_TIME_DISPATCH $07d9a $0006: start phase restart
	PL_PS $7d9a,_events_start_one
	; PERF_RANGE VERIFY_TIME_DISPATCH $08860 $0008: start and overlay reset
	PL_PSS $8860,_events_race_clear,2
	; PERF_RANGE VERIFY_TIME_DISPATCH $108f4 $0008: recovery start reset
	PL_PSS $108f4,_events_recovery_clear,2
	; PERF_RANGE VERIFY_TIME_DISPATCH $1170c $0008: Phantom start reset
	PL_PSS $1170c,_events_phantom_clear,2
	; PERF_RANGE VERIFY_TIME_DISPATCH $0886c $0008: race score reset
	PL_PSS $886c,_events_score_clear,2
	; PERF_RANGE VERIFY_TIME_DISPATCH $06ac6 $0008: menu score reset
	PL_PSS $6ac6,_events_score_clear,2
	PL_END
_events_signature: dc.b 'HDEVENT1'
; Each slot is carry.w, charged.b, padding.b.
_events_score_state: dc.l 0
_events_start_state: dc.l 0
; A0 slot, D0 unsigned fields0..65535. Return the number of due events.
; D1 scratch. Long addition retains the carry at the unsigned-word boundary.
_events_tick:
	tst.b 2(a0)
	bne.s .not_due
	st 2(a0)
	andi.l #$ffff,d0
	moveq #0,d1
	move.w (a0),d1
	add.l d0,d1
	move.l d1,d0
	andi.w #7,d1
	move.w d1,(a0)
	lsr.l #3,d0
	rts
.not_due:
	moveq #0,d0
	rts
_events_score:
	IFND VERIFY_DISPATCH_NATIVE
	; Keep the repeat count on the stack: the native BCD routine may clobber
	; scratch registers. Restore entry registers before its first invocation.
	subq.w #2,a7
	movem.l d0-d1/a0,-(a7)
	move.w #1,12(a7)
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	beq.s .restore
	lea _events_score_state(pc),a0
	move.w _time_scalar_fields(pc),d0
	bsr _events_tick
	move.w d0,12(a7)
.restore:
	movem.l (a7)+,d0-d1/a0
	tst.w (a7)
	beq.s .done
.repeat:
	bsr.s _events_score_native
	subq.w #1,(a7)
	bne.s .repeat
.done:
	addq.w #2,a7
	rts
	ENDC
_events_score_native:
	pea -$6878(a4)
	move.w -$66d4(a4),d0
	asr.w #4,d0
	ext.l d0
	move.l d0,-(a7)
	jsr -$7f0e(a4)
	addq.w #8,a7
	rts
_events_start:
	IFND VERIFY_DISPATCH_NATIVE
	movem.l d0-d1/a0,-(a7)
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	beq.s .native_restore
	lea _events_start_state(pc),a0
	move.w _time_scalar_fields(pc),d0
	bsr _events_tick
	moveq #0,d1
	move.b -$5222(a4),d1
	bsr.s _events_start_phase
	move.b d0,-$5222(a4)
	movem.l (a7)+,d0-d1/a0
	bra.s .compare
.native_restore:
	movem.l (a7)+,d0-d1/a0
	ENDC
	addq.b #1,-$5222(a4)
.compare:
	; Native DB4A enables throttle when the resulting phase reaches six.
	cmpi.b #6,-$5222(a4)
	rts
; D0 due count, D1 current eligible phase1..6. Stop at terminal phase7;
; crossing six and seven in one update must still enable throttle at DB4A.
_events_start_phase:
	add.l d1,d0
	cmpi.l #7,d0
	bls.s .done
	moveq #7,d0
.done:
	rts
_events_reset_start:
	move.l a0,-(a7)
	lea _events_start_state(pc),a0
	clr.l (a0)
	movea.l (a7)+,a0
	rts
_events_start_one:
	bsr _events_reset_start
	move.b #1,-$5222(a4)
	rts
_events_race_clear:
	bsr _events_reset_start
	clr.b -$5222(a4)
	clr.b -$50ce(a4)
	rts
_events_recovery_clear:
	bsr _events_reset_start
	clr.b -$5222(a4)
	clr.b -$5224(a4)
	rts
_events_phantom_clear:
	bsr _events_reset_start
	clr.b -$5222(a4)
	clr.b -$522a(a4)
	rts
_events_score_clear:
	move.l a0,-(a7)
	lea _events_score_state(pc),a0
	clr.l (a0)
	movea.l (a7)+,a0
	clr.l -$6878(a4)
	clr.l -$6870(a4)
	rts

	IFD VERIFY_EVENTS_MATH
_events_math_test:
	movem.l d0-d7/a0-a2,-(a7)
	lea _events_test_slot(pc),a0
	lea _events_test_results(pc),a2
	lea _events_test_fields(pc),a1
	moveq #16-1,d5
.fields:
	moveq #0,d7
	move.w (a1)+,d7
	moveq #0,d6
.carry:
	move.w d6,(a0)
	clr.w 2(a0)
	move.w d7,d0
	bsr _events_tick
	move.w d0,(a2)+
	move.w (a0),(a2)+
	move.w d7,d0
	bsr _events_tick
	move.w d0,(a2)+
	move.w (a0),(a2)+
	clr.b 2(a0)
	move.w d7,d0
	bsr _events_tick
	move.w d0,(a2)+
	move.w (a0),(a2)+
	addq.w #1,d6
	cmpi.w #8,d6
	blt.s .carry
	dbf d5,.fields
	lea _events_phase_results(pc),a2
	moveq #1,d6
.phase:
	lea _events_test_due(pc),a1
	moveq #9-1,d7
.due:
	moveq #0,d0
	move.w (a1)+,d0
	move.l d6,d1
	bsr _events_start_phase
	move.w d0,(a2)+
	dbf d7,.due
	addq.l #1,d6
	cmpi.l #7,d6
	blo.s .phase
	movem.l (a7)+,d0-d7/a0-a2
	rts
_events_test_fields: dc.w 0,1,2,3,4,5,6,7,8,9,15,16,255,32768,65528,65535
_events_test_due: dc.w 0,1,2,5,6,7,8,8191,8192
_events_test_slot: dc.l 0
_events_math_signature: dc.b 'HDEVMAT1'
_events_test_results: dcb.w 16*8*6,0
_events_phase_signature: dc.b 'HDEVPH01'
_events_phase_results: dcb.w 6*9,0
	ENDC
