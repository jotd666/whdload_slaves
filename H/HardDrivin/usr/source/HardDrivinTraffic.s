; Gated traffic speed and route-phase integration. Native records stay46bytes.
; Per-record companions are allocated from KickEmu's Exec memory pool after each
; traffic table load and released on the next load; no fixed actor-count limit.
_traffic_install:
	movem.l a0-a2,-(a7)
	lea _traffic_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_traffic_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_TRAFFIC $083c4 $0008: resize traffic companions
	PL_PSS $83c4,_traffic_loaded,2
	; PERF_RANGE VERIFY_TIME_TRAFFIC $0ce52 $0008: initial route reset
	PL_PSS $ce52,_traffic_initial,2
	; PERF_RANGE VERIFY_TIME_TRAFFIC $0d4d6 $0008: race traffic reset
	PL_PSS $d4d6,_traffic_restart,2
	; PERF_RANGE VERIFY_TIME_TRAFFIC $0ce8a $002a: traffic acceleration
	PL_PSS $ce8a,_traffic_speed,$24
	; PERF_RANGE VERIFY_TIME_TRAFFIC $0d36e $0012: traffic route-phase integration
	PL_PSS $d36e,_traffic_phase,$c
	; PERF_RANGE VERIFY_TIME_TRAFFIC $0bc4c $0006: collision velocity reversal
	PL_PS $bc4c,_traffic_collision
	PL_END
_traffic_signature: dc.b 'HDTRAFF1'
_traffic_memory: dc.l 0,0
; Slot: speed remainder/8.w0, last speed.w2, old full speed*8.w4,
; phase remainder/128.w6, last phase.w8, reserved.b10, init.b11,
; phase sub-remainder/768.w12 (signed -5..5), reserved.w14.
_traffic_loaded:
	move.l d0,-$50fa(a4)
	movem.l d0-d2/a0-a2/a6,-(a7)
	movea.l 4.w,a6
	lea _traffic_memory(pc),a2
	move.l (a2),d0
	beq.s .allocate
	movea.l d0,a1
	move.l 4(a2),d0
	jsr _LVOFreeMem(a6)
.allocate:
	clr.l (a2)
	moveq #0,d0
	move.w -$50fc(a4),d0
	lsl.l #4,d0
	move.l d0,4(a2)
	beq.s .done
	move.l #MEMF_PUBLIC|MEMF_CLEAR,d1
	jsr _LVOAllocMem(a6)
	tst.l d0
	beq _failmem
	move.l d0,(a2)
.done:
	movem.l (a7)+,d0-d2/a0-a2/a6
	movea.l -6(a5),a0
	rts
; A0 native record -> A1 companion; valid native iterator/collision index.
_traffic_slot:
	movem.l d0-d1,-(a7)
	move.l a0,d0
	sub.l -$50fa(a4),d0
	divu.w #46,d0
	andi.l #$ffff,d0
	lsl.l #4,d0
	movea.l _traffic_memory(pc),a1
	adda.l d0,a1
	movem.l (a7)+,d0-d1
	rts
_traffic_clear:
	clr.l (a1)
	clr.l 4(a1)
	clr.l 8(a1)
	clr.l 12(a1)
	rts
_traffic_initial:
	movem.l a0-a1,-(a7)
	movea.l a2,a0
	bsr _traffic_slot
	bsr _traffic_clear
	movem.l (a7)+,a0-a1
	clr.l 4(a2)
	clr.b 19(a2)
	rts
_traffic_restart:
	move.w d0,16(a2)
	clr.b 23(a2)
	movem.l a0-a1,-(a7)
	movea.l a2,a0
	bsr _traffic_slot
	bsr _traffic_clear
	st 11(a1)
	movem.l (a7)+,a0-a1
	rts
_traffic_speed:
	movem.l d0-d5/a0-a1,-(a7)
	movea.l 8(a5),a0
	bsr _traffic_slot
	bsr _traffic_speed_step
	movem.l (a7)+,d0-d5/a0-a1
	rts
; A0 record, A1 state; scratch D0-D5. Native acceleration grid starts at zero.
; Preserve its reachable terminal speed ceil(target/accel)*accel. In the SPS0126
; table accel=1..3 and target=9..20, so terminal speeds fit the signed byte.
; Reset's CE70 call is initialization, and consumes one native step regardless T.
_traffic_speed_step:
	move.b 23(a0),d0
	ext.w d0
	cmp.w 2(a1),d0
	beq.s .current
	clr.w (a1)
.current:
	lsl.w #3,d0
	add.w (a1),d0
	move.w d0,4(a1)
	moveq #0,d1
	move.b 21(a0),d1
	beq.s .publish
	moveq #0,d2
	move.b 22(a0),d2
	add.w d1,d2
	subq.w #1,d2
	divu.w d1,d2
	mulu.w d1,d2
	lsl.w #3,d2
	cmp.w d2,d0
	bge.s .publish
	move.w _time_scalar_fields(pc),d3
	tst.b 11(a1)
	beq.s .fields
	moveq #8,d3
.fields:
	mulu.w d3,d1
	; Keep the complete acceleration increment until terminal-speed clamping.
	; A long frame can exceed a signed word even with native accel1..3.
	ext.l d0
	add.l d1,d0
	cmp.l d2,d0
	ble.s .publish
	move.l d2,d0
.publish:
	ext.l d0
	divs.w #8,d0
	move.l d0,d1
	swap d1
	move.w d1,(a1)
	move.b d0,23(a0)
	ext.w d0
	move.w d0,2(a1)
	rts
_traffic_phase:
	movem.l d0-d5/a0-a1,-(a7)
	movea.l 8(a5),a0
	bsr _traffic_slot
	bsr _traffic_phase_step
	movem.l (a7)+,d0-d5/a0-a1
	rts
; Integrate new speed and its fraction with the same semi-implicit Euler bias
; as the car. Phase remains in native units; native geometry consumes it before
; this update. Short steps keep the native single-wrap code. Long steps walk
; every crossed segment here, leaving a normalized phase for the native tail.
_traffic_phase_step:
	move.w 16(a0),d0
	sub.w 8(a1),d0
	beq.s .current
	cmpi.w #200,d0
	beq.s .current
	cmpi.w #-200,d0
	beq.s .current
	clr.w 6(a1)
	clr.w 12(a1)
.current:
	move.w _time_scalar_fields(pc),d3
	tst.b 11(a1)
	beq.s .fields
	moveq #8,d3
.fields:
	tst.w d3
	beq .done
	cmpi.w #8,d3
	bhi.s .wide
	tst.w 12(a1)
	bne.s .wide
	move.b 23(a0),d0
	ext.w d0
	lsl.w #3,d0
	add.w (a1),d0
	moveq #8,d1
	add.w d3,d1
	muls.w d1,d0
	moveq #8,d1
	sub.w d3,d1
	move.w 4(a1),d2
	muls.w d1,d2
	sub.l d2,d0
	move.w 6(a1),d2
	ext.l d2
	add.l d2,d0
	divs.w #128,d0
	move.l d0,d2
	swap d2
	move.w d2,6(a1)
	add.w d0,16(a0)
	bra.s .done
.wide:
	move.w d3,d2
	move.b 23(a0),d0
	ext.w d0
	lsl.w #3,d0
	add.w (a1),d0
	move.w 4(a1),d1
	moveq #0,d3
	move.b 21(a0),d3
	move.w 6(a1),d4
	ext.l d4
	muls.w #6,d4
	move.w 12(a1),d5
	ext.l d5
	add.l d5,d4
	bsr _traffic_phase_delta_wide
	; Retain the existing /128 companion plus its exact sixth-unit residue.
	divs.w #6,d4
	move.w d4,6(a1)
	swap d4
	move.w d4,12(a1)
	move.w 16(a0),d1
	ext.l d1
	add.l d1,d0
	bsr _traffic_route_walk
.done:
	move.w 16(a0),8(a1)
	clr.b 11(a1)
	rts
_traffic_collision:
	movem.l d0-d2/a0-a1,-(a7)
	bsr _traffic_slot
	bsr _traffic_reverse_step
	movem.l (a7)+,d0-d2/a0-a1
	movea.l d6,a0
	rts
; A0 record, A1 companion. Reverse the full velocity impulse, not just its byte.
_traffic_reverse_step:
	move.b 23(a0),d0
	ext.w d0
	cmp.w 2(a1),d0
	beq.s .current
	clr.w (a1)
.current:
	lsl.w #3,d0
	add.w (a1),d0
	neg.w d0
	ext.l d0
	divs.w #8,d0
	move.l d0,d1
	swap d1
	move.w d1,(a1)
	move.b d0,23(a0)
	ext.w d0
	move.w d0,2(a1)
	rts

; A0 record, D0 signed-long phase. Advance route pointers once per crossing,
; applying the native next-segment normalization between crossings. The final
; pending next pointer remains in the same state as the native single-wrap tail.
; TODO: split an in-frame turnaround at its displacement extremum before calling
; this walker, to retain intermediate junction choices hidden by net movement.
_traffic_route_walk:
	movem.l d1/a1-a2,-(a7)
	move.b 20(a0),d1
	ext.w d1
	muls.w #20,d1
.positive:
	cmpi.l #200,d0
	blt.s .negative
	bsr _traffic_route_next
	subi.l #200,d0
	move.l 4(a0),(a0)
	add.l d1,4(a0)
	clr.b 19(a0)
	bra.s .positive
.negative:
	tst.l d0
	bpl.s .done
	bsr _traffic_route_next
	addi.l #200,d0
	move.l (a0),4(a0)
	sub.l d1,(a0)
	clr.b 19(a0)
	bra.s .negative
.done:
	move.w d0,16(a0)
	movem.l (a7)+,d1/a1-a2
	rts
; Native CF02..CFE4 route normalization, without acceleration or pose work.
; Preserve all registers. Route mode belongs to the current->next edge.
_traffic_route_next:
	movem.l a1-a2,-(a7)
	movea.l 4(a0),a1
	movea.l (a0),a2
	tst.b 13(a0)
	bne.s .alternate
	cmpa.l -$50da(a4),a1
	blo.s .main_low
	movea.l -$6720(a4),a1
.main_low:
	cmpa.l -$6720(a4),a1
	bhs.s .junction
	movea.l -$50da(a4),a1
	suba.w #20,a1
.junction:
	tst.b 15(a0)
	beq.s .publish
	cmpa.l -$50f6(a4),a2
	bne.s .reverse_junction
	cmpi.b #1,20(a0)
	bne.s .reverse_junction
	movea.l -$66ae(a4),a1
	adda.w #20,a1
	move.b 15(a0),13(a0)
.reverse_junction:
	cmpa.l -$50f2(a4),a2
	bne.s .publish
	cmpi.b #-1,20(a0)
	bne.s .publish
	movea.l -$50d6(a4),a1
	suba.w #20,a1
	move.b 15(a0),13(a0)
	bra.s .publish
.alternate:
	cmpa.l -$50d6(a4),a1
	blo.s .alternate_low
	movea.l -$50f2(a4),a1
	clr.b 13(a0)
	bra.s .publish
.alternate_low:
	cmpa.l -$66ae(a4),a1
	bhs.s .publish
	movea.l -$50f6(a4),a1
	clr.b 13(a0)
.publish:
	move.l a1,4(a0)
	movem.l (a7)+,a1-a2
	rts

; Wide route-phase arithmetic used by long steps and fractional coasting carry.
; D0.W new and D1.W old speed in eighths (signed-byte speed plus fraction),
; D2.W unsigned fields, D3.W native acceleration0..3, D4.L carry/768.
; Return D0.L phase increment, D4.L signed remainder (-767..767).
; D1-D3/D5 scratch; preserve D6-D7 and all address registers.
; The denominator includes thirds/halves from reaching a speed cap mid-step.
_traffic_phase_delta_wide:
	movem.l d6-d7,-(a7)
	ext.l d0
	ext.l d1
	move.l d0,d5
	sub.l d1,d5
	add.l d1,d0
	move.w d2,d1
	bsr _time_multiply_fields
	move.l d5,d6
	lsl.l #3,d6
	add.l d6,d0
	; Six times the native /128 numerator n*(v+u)+8*(v-u).
	move.l d0,d6
	add.l d0,d0
	add.l d6,d0
	add.l d0,d0
	cmpi.w #8,d2
	bls.s .carry
	tst.l d5
	ble.s .carry
	tst.w d3
	beq.s .carry
	; SPS traffic acceleration is1..3. Compare elapsed acceleration to the
	; actual speed increase: a smaller increase means the car reached its cap.
	move.w d3,d6
	mulu.w d2,d6
	cmp.l d5,d6
	bls.s .carry
	; Replace the endpoint average with acceleration followed by coasting:
	; add6*n*delta - (6/acceleration)*delta^2, exactly for accel1..3.
	move.w d5,d6
	mulu.w d2,d6
	move.l d6,d7
	add.l d6,d6
	add.l d7,d6
	add.l d6,d6
	mulu.w d5,d5
	cmpi.w #3,d3
	beq.s .twice
	move.l d5,d7
	add.l d5,d5
	add.l d7,d5
	cmpi.w #2,d3
	beq.s .correction
.twice:
	add.l d5,d5
.correction:
	sub.l d5,d6
	add.l d6,d0
.carry:
	add.l d4,d0
	move.l d0,d6
	bpl.s .magnitude
	neg.l d0
.magnitude:
	; Two unsigned word divisions retain a full longword quotient.
	move.l d0,d1
	swap d1
	andi.l #$ffff,d1
	divu.w #768,d1
	move.l d1,d5
	andi.l #$ffff,d5
	swap d5
	clr.w d1
	andi.l #$ffff,d0
	or.l d1,d0
	divu.w #768,d0
	move.l d0,d4
	swap d4
	andi.l #$ffff,d4
	andi.l #$ffff,d0
	or.l d5,d0
	tst.l d6
	bpl.s .done
	neg.l d0
	neg.l d4
.done:
	movem.l (a7)+,d6-d7
	rts

	IFD VERIFY_TRAFFIC_MATH
_traffic_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _traffic_fake_record(pc),a0
	lea _traffic_fake_state(pc),a1
	lea _traffic_reverse_results(pc),a2
	lea _traffic_test_speeds(pc),a6
	moveq #4,d7
.speed:
	move.w (a6)+,d4
	lea _traffic_test_fractions(pc),a3
	moveq #4,d6
.fraction:
	move.w (a3)+,d5
	moveq #0,d2
.mismatch:
	move.b d4,23(a0)
	move.w d4,2(a1)
	add.w d2,2(a1)
	move.w d5,(a1)
	bsr _traffic_reverse_step
	move.b 23(a0),d0
	ext.w d0
	move.w d0,(a2)+
	move.w (a1),(a2)+
	move.w 2(a1),(a2)+
	bsr _traffic_reverse_step
	move.b 23(a0),d0
	ext.w d0
	move.w d0,(a2)+
	move.w (a1),(a2)+
	addq.w #1,d2
	cmpi.w #1,d2
	ble.s .mismatch
	dbf d6,.fraction
	dbf d7,.speed
	lea _time_scalar_fields(pc),a5
	clr.w (a5)
	bsr _traffic_clear
	clr.b 23(a0)
	move.b #2,21(a0)
	move.b #9,22(a0)
	move.w #50,16(a0)
	st 11(a1)
	bsr _traffic_speed_step
	bsr _traffic_phase_step
	move.w 16(a0),(a2)+
	move.b 23(a0),d0
	ext.w d0
	move.w d0,(a2)+
	move.l (a1),(a2)+
	move.l 4(a1),(a2)+
	move.l 8(a1),(a2)+
	; Initialization consumed one native step; subsequent T=0 consumes nothing.
	bsr _traffic_speed_step
	bsr _traffic_phase_step
	move.w 16(a0),(a2)+
	move.b 23(a0),d0
	ext.w d0
	move.w d0,(a2)+
	move.w (a1),(a2)+
	move.w 6(a1),(a2)+
	move.w #VERIFY_SCALAR_FIELDS,(a5)
	movem.l (a7)+,d0-d7/a0-a6
	rts
_traffic_fake_record: dcb.b 46,0
_traffic_fake_state: dcb.b 16,0
_traffic_test_speeds: dc.w -21,-1,0,1,21
_traffic_test_fractions: dc.w -7,-1,0,1,7
_traffic_math_signature: dc.b 'HDTRMAT1'
_traffic_reverse_results: dcb.b 50*10+24,0
	ENDC

	IFD VERIFY_TRAFFIC_SPEED_MATH
_traffic_speed_math_test:
	movem.l d0-d7/a0-a3,-(a7)
	lea _traffic_speed_fake_record(pc),a0
	lea _traffic_speed_fake_state(pc),a1
	lea _traffic_speed_test_cases(pc),a3
	lea _traffic_speed_test_results(pc),a2
	moveq #17,d7
.case:
	bsr _traffic_clear
	move.w (a3)+,d0
	move.b d0,23(a0)
	move.w (a3)+,(a1)
	move.w (a3)+,2(a1)
	move.w (a3)+,d0
	move.b d0,21(a0)
	move.w (a3)+,d0
	move.b d0,22(a0)
	move.l a0,-(a7)
	lea _time_scalar_fields(pc),a0
	move.w (a3)+,(a0)
	movea.l (a7)+,a0
	move.w (a3)+,d0
	move.b d0,11(a1)
	bsr _traffic_speed_step
	move.b 23(a0),d0
	ext.w d0
	move.w d0,(a2)+
	move.w (a1),(a2)+
	move.w 2(a1),(a2)+
	move.w 4(a1),(a2)+
	dbf d7,.case
	lea _time_scalar_fields(pc),a0
	move.w #VERIFY_SCALAR_FIELDS,(a0)
	movem.l (a7)+,d0-d7/a0-a3
	rts
_traffic_speed_fake_record: dcb.b 46,0
_traffic_speed_fake_state: dcb.b 16,0
; speed,fraction,last speed,acceleration,target,fields,initialization
_traffic_speed_test_cases:
	dc.w 0,0,0,3,20,65535,0
	dc.w -21,-7,-21,3,20,65535,0
	dc.w 0,0,0,1,9,32768,0
	dc.w 9,7,9,2,9,65535,0
	dc.w 21,0,21,2,9,65535,0
	dc.w 0,0,0,0,20,65535,0
	dc.w 0,0,0,3,20,65535,1
	dc.w 0,0,0,2,9,0,1
	dc.w 0,0,0,2,9,0,0
	dc.w 0,0,0,2,9,1,0
	dc.w -1,-7,-1,3,20,9,0
	dc.w -1,7,-1,3,20,9,0
	dc.w 9,7,9,2,9,1,0
	dc.w 0,-7,1,3,20,9,0
	dc.w 0,7,0,3,20,8,0
	dc.w 0,-7,0,3,20,8,0
	dc.w 9,0,9,3,20,255,0
	dc.w 0,0,0,3,20,21846,0
_traffic_speed_test_signature: dc.b 'HDTRSPD1'
_traffic_speed_test_results: dcb.w 18*4,0
	ENDC

	IFD VERIFY_TRAFFIC_PHASE_MATH
_traffic_phase_math_test:
	movem.l d0-d7/a0-a3,-(a7)
	lea _traffic_phase_cases(pc),a3
	lea _traffic_phase_results(pc),a2
	move.w #503,d7
.case:
	move.w (a3)+,d0
	move.w (a3)+,d1
	move.w (a3)+,d2
	move.w (a3)+,d3
	move.w (a3)+,d4
	ext.l d4
	bsr _traffic_phase_delta_wide
	move.l d0,(a2)+
	move.l d4,(a2)+
	dbf d7,.case
	movem.l (a7)+,d0-d7/a0-a3
	rts
HD_TRAFFIC_PHASE_TRIPLE MACRO
HD_TRAFFIC_TEST_V SET \1
	IFGT \4-\1
HD_TRAFFIC_TEST_V SET \1+\2*\3
	IFGT HD_TRAFFIC_TEST_V-\4
HD_TRAFFIC_TEST_V SET \4
	ENDC
	ENDC
	dc.w HD_TRAFFIC_TEST_V,\1,\2,\3,-767
	dc.w HD_TRAFFIC_TEST_V,\1,\2,\3,0
	dc.w HD_TRAFFIC_TEST_V,\1,\2,\3,767
	ENDM
HD_TRAFFIC_PHASE_CASE MACRO
	HD_TRAFFIC_PHASE_TRIPLE \1,\2,0,\1
	HD_TRAFFIC_PHASE_TRIPLE \1,\2,1,72
	HD_TRAFFIC_PHASE_TRIPLE \1,\2,2,80
	HD_TRAFFIC_PHASE_TRIPLE \1,\2,3,168
	ENDM
_traffic_phase_cases:
	HD_TRAFFIC_PHASE_CASE -1031,1
	HD_TRAFFIC_PHASE_CASE -1031,8
	HD_TRAFFIC_PHASE_CASE -1031,9
	HD_TRAFFIC_PHASE_CASE -1031,15
	HD_TRAFFIC_PHASE_CASE -1031,255
	HD_TRAFFIC_PHASE_CASE -1031,32768
	HD_TRAFFIC_PHASE_CASE -1031,65535
	HD_TRAFFIC_PHASE_CASE -1,1
	HD_TRAFFIC_PHASE_CASE -1,8
	HD_TRAFFIC_PHASE_CASE -1,9
	HD_TRAFFIC_PHASE_CASE -1,15
	HD_TRAFFIC_PHASE_CASE -1,255
	HD_TRAFFIC_PHASE_CASE -1,32768
	HD_TRAFFIC_PHASE_CASE -1,65535
	HD_TRAFFIC_PHASE_CASE 0,1
	HD_TRAFFIC_PHASE_CASE 0,8
	HD_TRAFFIC_PHASE_CASE 0,9
	HD_TRAFFIC_PHASE_CASE 0,15
	HD_TRAFFIC_PHASE_CASE 0,255
	HD_TRAFFIC_PHASE_CASE 0,32768
	HD_TRAFFIC_PHASE_CASE 0,65535
	HD_TRAFFIC_PHASE_CASE 71,1
	HD_TRAFFIC_PHASE_CASE 71,8
	HD_TRAFFIC_PHASE_CASE 71,9
	HD_TRAFFIC_PHASE_CASE 71,15
	HD_TRAFFIC_PHASE_CASE 71,255
	HD_TRAFFIC_PHASE_CASE 71,32768
	HD_TRAFFIC_PHASE_CASE 71,65535
	HD_TRAFFIC_PHASE_CASE 167,1
	HD_TRAFFIC_PHASE_CASE 167,8
	HD_TRAFFIC_PHASE_CASE 167,9
	HD_TRAFFIC_PHASE_CASE 167,15
	HD_TRAFFIC_PHASE_CASE 167,255
	HD_TRAFFIC_PHASE_CASE 167,32768
	HD_TRAFFIC_PHASE_CASE 167,65535
	HD_TRAFFIC_PHASE_CASE 1023,1
	HD_TRAFFIC_PHASE_CASE 1023,8
	HD_TRAFFIC_PHASE_CASE 1023,9
	HD_TRAFFIC_PHASE_CASE 1023,15
	HD_TRAFFIC_PHASE_CASE 1023,255
	HD_TRAFFIC_PHASE_CASE 1023,32768
	HD_TRAFFIC_PHASE_CASE 1023,65535
_traffic_phase_signature: dc.b 'HDTRPHW1'
_traffic_phase_results: dcb.l 1008,0
	ENDC

	IFD VERIFY_TRAFFIC_ROUTE_MATH
; Compare against copies of the actual CF02 and D380 native instruction ranges.
; They contain only internal relative branches, A4/A5 accesses and the native
; direction*20 multiply call. Fake globals supply that multiply and route bounds.
_traffic_route_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$cf02,a0
	lea _traffic_route_native_next(pc),a1
	moveq #113-1,d0
.copy_next:
	move.w (a0)+,(a1)+
	dbf d0,.copy_next
	movea.l _code_start(pc),a0
	adda.l #$d380,a0
	lea _traffic_route_native_walk(pc),a1
	moveq #67-1,d0
.copy_walk:
	move.w (a0)+,(a1)+
	dbf d0,.copy_walk
	movea.l _resload(pc),a2
	jsr resload_FlushCache(a2)
	lea _traffic_route_globals(pc),a4
	adda.l #$7e00,a4
	lea _traffic_route_multiply(pc),a0
	move.w #$4ef9,-$7dfa(a4)
	move.l a0,-$7df8(a4)
	move.l #$10000,-$6720(a4)
	move.l #$10320,-$50da(a4)
	move.l #$100c8,-$50f6(a4)
	move.l #$101f4,-$50f2(a4)
	move.l #$20000,-$66ae(a4)
	move.l #$200a0,-$50d6(a4)
	lea _traffic_route_frame+4(pc),a5
	lea _traffic_route_cases(pc),a6
	lea _traffic_route_results(pc),a2
	move.w #95,d7
.case:
	lea _traffic_route_record(pc),a0
	move.l (a6)+,(a0)
	move.l (a6)+,4(a0)
	move.w (a6)+,d0
	move.b d0,13(a0)
	move.w (a6)+,d0
	move.b d0,15(a0)
	move.w (a6)+,d0
	move.b d0,20(a0)
	clr.w 16(a0)
	clr.b 19(a0)
	move.l (a6)+,d6
	lea _traffic_route_reference(pc),a1
	bsr _traffic_route_copy
	lea _traffic_route_record(pc),a0
	move.l d6,d0
	bsr _traffic_route_walk
	movea.l a2,a1
	bsr _traffic_route_copy
	movea.l a1,a2
	lea _traffic_route_reference(pc),a0
	move.l a0,8(a5)
.positive:
	cmpi.l #200,d6
	blt.s .negative
	bsr .prepare
	movea.l 8(a5),a0
	move.w #200,16(a0)
	bsr _traffic_route_native_walk
	subi.l #200,d6
	bra.s .positive
.negative:
	tst.l d6
	bpl.s .save
	bsr .prepare
	movea.l 8(a5),a0
	move.w #-1,16(a0)
	bsr _traffic_route_native_walk
	addi.l #200,d6
	bra.s .negative
.save:
	movea.l 8(a5),a0
	move.w d6,16(a0)
	movea.l a2,a1
	bsr _traffic_route_copy
	movea.l a1,a2
	dbf d7,.case
	movem.l (a7)+,d0-d7/a0-a6
	rts
.prepare:
	movea.l 8(a5),a0
	movea.l (a0),a3
	move.l 4(a0),-4(a5)
	bsr _traffic_route_native_next
	rts
_traffic_route_copy:
	moveq #23-1,d0
.copy:
	move.w (a0)+,(a1)+
	dbf d0,.copy
	rts
_traffic_route_multiply:
	muls.w d1,d0
	rts
_traffic_route_native_next: dcb.b 226,0
	rts
_traffic_route_native_walk: dcb.b 134,0
	rts
_traffic_route_globals: dcb.b $2d30,0
_traffic_route_frame: dcb.b 16,0
_traffic_route_record: dcb.b 46,0
_traffic_route_reference: dcb.b 46,0
HD_TRAFFIC_ROUTE_CASE MACRO
	dc.l \1,\2
	dc.w \3,\4,\5
	dc.l \6
	ENDM
_traffic_route_cases:
	HD_TRAFFIC_ROUTE_CASE $1030c,$10320,0,0,1,-601
	HD_TRAFFIC_ROUTE_CASE $1030c,$10320,0,0,1,-201
	HD_TRAFFIC_ROUTE_CASE $1030c,$10320,0,0,1,-1
	HD_TRAFFIC_ROUTE_CASE $1030c,$10320,0,0,1,0
	HD_TRAFFIC_ROUTE_CASE $1030c,$10320,0,0,1,199
	HD_TRAFFIC_ROUTE_CASE $1030c,$10320,0,0,1,200
	HD_TRAFFIC_ROUTE_CASE $1030c,$10320,0,0,1,401
	HD_TRAFFIC_ROUTE_CASE $1030c,$10320,0,0,1,1801
	HD_TRAFFIC_ROUTE_CASE $10000,$ffec,0,0,-1,-601
	HD_TRAFFIC_ROUTE_CASE $10000,$ffec,0,0,-1,-201
	HD_TRAFFIC_ROUTE_CASE $10000,$ffec,0,0,-1,-1
	HD_TRAFFIC_ROUTE_CASE $10000,$ffec,0,0,-1,0
	HD_TRAFFIC_ROUTE_CASE $10000,$ffec,0,0,-1,199
	HD_TRAFFIC_ROUTE_CASE $10000,$ffec,0,0,-1,200
	HD_TRAFFIC_ROUTE_CASE $10000,$ffec,0,0,-1,401
	HD_TRAFFIC_ROUTE_CASE $10000,$ffec,0,0,-1,1801
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,1,1,-601
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,1,1,-201
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,1,1,-1
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,1,1,0
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,1,1,199
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,1,1,200
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,1,1,401
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,1,1,1801
	HD_TRAFFIC_ROUTE_CASE $101f4,$101e0,0,1,-1,-601
	HD_TRAFFIC_ROUTE_CASE $101f4,$101e0,0,1,-1,-201
	HD_TRAFFIC_ROUTE_CASE $101f4,$101e0,0,1,-1,-1
	HD_TRAFFIC_ROUTE_CASE $101f4,$101e0,0,1,-1,0
	HD_TRAFFIC_ROUTE_CASE $101f4,$101e0,0,1,-1,199
	HD_TRAFFIC_ROUTE_CASE $101f4,$101e0,0,1,-1,200
	HD_TRAFFIC_ROUTE_CASE $101f4,$101e0,0,1,-1,401
	HD_TRAFFIC_ROUTE_CASE $101f4,$101e0,0,1,-1,1801
	HD_TRAFFIC_ROUTE_CASE $2008c,$200a0,1,1,1,-601
	HD_TRAFFIC_ROUTE_CASE $2008c,$200a0,1,1,1,-201
	HD_TRAFFIC_ROUTE_CASE $2008c,$200a0,1,1,1,-1
	HD_TRAFFIC_ROUTE_CASE $2008c,$200a0,1,1,1,0
	HD_TRAFFIC_ROUTE_CASE $2008c,$200a0,1,1,1,199
	HD_TRAFFIC_ROUTE_CASE $2008c,$200a0,1,1,1,200
	HD_TRAFFIC_ROUTE_CASE $2008c,$200a0,1,1,1,401
	HD_TRAFFIC_ROUTE_CASE $2008c,$200a0,1,1,1,1801
	HD_TRAFFIC_ROUTE_CASE $20000,$1ffec,1,1,-1,-601
	HD_TRAFFIC_ROUTE_CASE $20000,$1ffec,1,1,-1,-201
	HD_TRAFFIC_ROUTE_CASE $20000,$1ffec,1,1,-1,-1
	HD_TRAFFIC_ROUTE_CASE $20000,$1ffec,1,1,-1,0
	HD_TRAFFIC_ROUTE_CASE $20000,$1ffec,1,1,-1,199
	HD_TRAFFIC_ROUTE_CASE $20000,$1ffec,1,1,-1,200
	HD_TRAFFIC_ROUTE_CASE $20000,$1ffec,1,1,-1,401
	HD_TRAFFIC_ROUTE_CASE $20000,$1ffec,1,1,-1,1801
	HD_TRAFFIC_ROUTE_CASE $100c8,$100b4,0,1,-1,-601
	HD_TRAFFIC_ROUTE_CASE $100c8,$100b4,0,1,-1,-201
	HD_TRAFFIC_ROUTE_CASE $100c8,$100b4,0,1,-1,-1
	HD_TRAFFIC_ROUTE_CASE $100c8,$100b4,0,1,-1,0
	HD_TRAFFIC_ROUTE_CASE $100c8,$100b4,0,1,-1,199
	HD_TRAFFIC_ROUTE_CASE $100c8,$100b4,0,1,-1,200
	HD_TRAFFIC_ROUTE_CASE $100c8,$100b4,0,1,-1,401
	HD_TRAFFIC_ROUTE_CASE $100c8,$100b4,0,1,-1,1801
	HD_TRAFFIC_ROUTE_CASE $101f4,$10208,0,1,1,-601
	HD_TRAFFIC_ROUTE_CASE $101f4,$10208,0,1,1,-201
	HD_TRAFFIC_ROUTE_CASE $101f4,$10208,0,1,1,-1
	HD_TRAFFIC_ROUTE_CASE $101f4,$10208,0,1,1,0
	HD_TRAFFIC_ROUTE_CASE $101f4,$10208,0,1,1,199
	HD_TRAFFIC_ROUTE_CASE $101f4,$10208,0,1,1,200
	HD_TRAFFIC_ROUTE_CASE $101f4,$10208,0,1,1,401
	HD_TRAFFIC_ROUTE_CASE $101f4,$10208,0,1,1,1801
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,0,1,-601
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,0,1,-201
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,0,1,-1
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,0,1,0
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,0,1,199
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,0,1,200
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,0,1,401
	HD_TRAFFIC_ROUTE_CASE $100c8,$100dc,0,0,1,1801
	HD_TRAFFIC_ROUTE_CASE $20050,$20064,1,1,1,-601
	HD_TRAFFIC_ROUTE_CASE $20050,$20064,1,1,1,-201
	HD_TRAFFIC_ROUTE_CASE $20050,$20064,1,1,1,-1
	HD_TRAFFIC_ROUTE_CASE $20050,$20064,1,1,1,0
	HD_TRAFFIC_ROUTE_CASE $20050,$20064,1,1,1,199
	HD_TRAFFIC_ROUTE_CASE $20050,$20064,1,1,1,200
	HD_TRAFFIC_ROUTE_CASE $20050,$20064,1,1,1,401
	HD_TRAFFIC_ROUTE_CASE $20050,$20064,1,1,1,1801
	HD_TRAFFIC_ROUTE_CASE $20050,$2003c,1,1,-1,-601
	HD_TRAFFIC_ROUTE_CASE $20050,$2003c,1,1,-1,-201
	HD_TRAFFIC_ROUTE_CASE $20050,$2003c,1,1,-1,-1
	HD_TRAFFIC_ROUTE_CASE $20050,$2003c,1,1,-1,0
	HD_TRAFFIC_ROUTE_CASE $20050,$2003c,1,1,-1,199
	HD_TRAFFIC_ROUTE_CASE $20050,$2003c,1,1,-1,200
	HD_TRAFFIC_ROUTE_CASE $20050,$2003c,1,1,-1,401
	HD_TRAFFIC_ROUTE_CASE $20050,$2003c,1,1,-1,1801
	HD_TRAFFIC_ROUTE_CASE $10064,$10078,0,0,1,-601
	HD_TRAFFIC_ROUTE_CASE $10064,$10078,0,0,1,-201
	HD_TRAFFIC_ROUTE_CASE $10064,$10078,0,0,1,-1
	HD_TRAFFIC_ROUTE_CASE $10064,$10078,0,0,1,0
	HD_TRAFFIC_ROUTE_CASE $10064,$10078,0,0,1,199
	HD_TRAFFIC_ROUTE_CASE $10064,$10078,0,0,1,200
	HD_TRAFFIC_ROUTE_CASE $10064,$10078,0,0,1,401
	HD_TRAFFIC_ROUTE_CASE $10064,$10078,0,0,1,1801
_traffic_route_signature: dc.b 'HDTRROU1'
_traffic_route_results: dcb.b 8832,0
	ENDC
