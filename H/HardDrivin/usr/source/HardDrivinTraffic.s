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
; phase remainder/128.w6, last phase.w8, reserved.b10, init.b11,pad.l12.
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
; this update and native route code wraps it afterwards. One wrap is sufficient:
; signed-byte speed and T<=1 cannot traverse a 200-unit segment twice.
_traffic_phase_step:
	move.w 16(a0),d0
	sub.w 8(a1),d0
	beq.s .current
	cmpi.w #200,d0
	beq.s .current
	cmpi.w #-200,d0
	beq.s .current
	clr.w 6(a1)
.current:
	move.w _time_scalar_fields(pc),d3
	tst.b 11(a1)
	beq.s .fields
	moveq #8,d3
.fields:
	tst.w d3
	beq.s .done
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
