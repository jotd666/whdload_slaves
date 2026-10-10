; W5: flight-only original beam wait and field-based minimum publication interval.
; PERF_RANGE sim:00b06 2 bit=8
; PERF_RANGE sim:00b08 8 bit=9
; PERF_RANGE sim:2d34e 6 bit=9
PACE_MIN_FIELDS = 2
pace_install:
	movem.l d0-a6,-(sp)
	btst #0,perf_mask+2(pc)
	beq.b .no_safe
	move.l #$b06,d0
	moveq #2,d1
	lea pace_safe_expected(pc),a0
	bsr perf_check_bytes
	lea pace_safe_patch(pc),a0
	jsr resload_Patch(a2)
.no_safe
	btst #1,perf_mask+2(pc)
	beq.w .done
	move.l 36(sp),a1
	move.l #$b08,d0
	moveq #8,d1
	lea pace_call_expected(pc),a0
	bsr perf_check_bytes
	move.l #$2d34e,d0
	moveq #6,d1
	lea pace_vbl_expected(pc),a0
	bsr perf_check_bytes
	lea pace_state(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.w (a0)+
	move.l a1,d0
	add.l #$4b38,d0
	move.l d0,(a0)+
	move.l a1,d0
	add.l #$156a,d0
	move.l d0,(a0)
	lea pace_cap_patch(pc),a0
	jsr resload_Patch(a2)
	IFD VERIFY
	; CUSTOM5 bit 17: deliberately fast drawing fixture for cap/wrap tests.
	; Never use this workload for game performance or pixel claims.
	btst #1,perf_custom5+1(pc)
	beq.w .done
	move.l 36(sp),a1
	cmpi.w #$4ef9,$15b2(a1)
	bne pace_stress_bad
	move.l a1,d0
	add.l #$2c552,d0
	cmp.l $15b4(a1),d0
	bne pace_stress_bad
	lea pace_state(pc),a0
	move.l #$fffffff0,(a0)
	lea pace_stress_patch(pc),a0
	jsr resload_Patch(a2)
	ENDC
.done
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
pace_safe_expected: dc.w $7000
pace_call_expected: dc.w $4eba,$402e,$4eba,$0a5c
pace_vbl_expected: dc.w $4cd9,$7800,$3011
pace_safe_patch:
	PL_START
	PL_W $b06,$7001
	PL_END
pace_cap_patch:
	PL_START
	PL_PSS $b08,pace_flight,2
	PL_PS $2d34e,pace_vbl
	PL_END

; a3/a4 are about to be overwritten by the original MOVEM. Address arithmetic
; preserves X; the replayed MOVE supplies exactly the original NZVC. No SR access.
pace_vbl:
	lea pace_state(pc),a3
	move.l (a3),a4
	addq.l #1,a4
	move.l a4,(a3)
	movem.l (a1)+,a3-a6
	move.w (a1),d0
	rts

; Replace both original flight calls. Preserve inputs while waiting, then use
; tail calls to retain the original second call's register/CCR result.
; No catch-up debt: anchor each deadline to the preceding actual publication.
pace_flight:
	movem.l d0-d1/a0,-(sp)
	lea pace_state(pc),a0
	tst.w 8(a0)
	beq.b .first
.wait
	move.l (a0),d1
	sub.l 4(a0),d1
	cmp.l #PACE_MIN_FIELDS,d1
	blo.b .wait
.first
	movem.l (sp)+,d0-d1/a0
	bsr.b .swap
	movem.l d0/a0,-(sp)
	lea pace_state(pc),a0
	move.l (a0),d0
	move.l d0,4(a0)
	move.w #1,8(a0)
	movem.l (sp)+,d0/a0
	move.l pace_after(pc),-(sp)
	rts
; The original swap has no stack arguments. This preserves all register inputs.
.swap
	move.l pace_swap(pc),-(sp)
	rts
pace_state:
	dc.l 0,0 ; field count, previous publication's field
	dc.w 0 ; first publication has no preceding deadline
pace_swap: dc.l 0
pace_after: dc.l 0

	IFD VERIFY
; VERIFY_RANGE sim:015b2 6: fast-frame fixture, mutually exclusive with slow draw.
pace_stress_patch:
	PL_START
	PL_P $15b2,pace_skip_draw
	PL_END
pace_skip_draw:
	rts
pace_stress_bad:
	pea perf_mismatch(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
	ENDC
