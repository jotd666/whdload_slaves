; W6 Time Scale history, bit 13; original divisor setter only on sim v1.
; PERF_RANGE sim:03ce4 6 bit=13
; Queue header: head.w tail.w overflow.w high-water.w current_F.w last_F.w.
; 32 records: active deadline.l F.w reserved.w. Publish on serialized VBlank.
TIME_RATE_BYTES = 12+32*8

time_rate_install:
	movem.l d0-a6,-(sp)
	move.l a1,a0
	adda.l #$3ce4,a0
	cmpi.w #$33c7,(a0)
	bne .bad
	move.l time_loop_h3(pc),d0
	addi.l #$4838,d0
	cmp.l 2(a0),d0
	bne .bad
	IFD VERIFY
	bsr time_rate_selftest
	ENDC
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.bad
	pea time_rate_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
.patch:
	PL_START
	PL_PS $3ce4,time_rate_write
	PL_END

; Original native setter. Publish on the next VBlank before resuming main code.
; The simulation divisor changes only when its retained cursor reaches the event.
time_rate_write:
	movem.l d0/a0,-(sp)
	move.l time_loop_h3(pc),a0
	move.w d7,$4838(a0)
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_ACTIVE(a0)
	bne .publish
	tst.l TIME_LOOP_PAUSE_DEPTH(a0)
	beq .done
.publish
	lea time_rate_pending(pc),a0
	move.w d7,(a0)
	moveq #4,d0
	bsr time_pause_request
.done
	movem.l (sp)+,d0/a0
	tst.w d7 ; displaced MOVE flags; all intervening operations preserve X
	rts

time_rate_reset:
	movem.l d0/a0-a1,-(sp)
	lea time_rate_queue(pc),a0
	clr.l (a0)
	clr.l 4(a0)
	move.l time_loop_h3(pc),a1
	move.w $4838(a1),8(a0)
	move.w $4838(a1),10(a0)
	IFD VERIFY
	lea time_rate_count(pc),a0
	clr.l (a0)
	lea time_rate_fixture_index(pc),a0
	clr.w (a0)
	ENDC
	movem.l (sp)+,d0/a0-a1
	rts

; Called with interrupts serialized by time_pause_irq. Main waits for ack.
time_rate_publish:
	movem.l d0-a6,-(sp)
	lea time_rate_queue(pc),a0
	move.w time_rate_pending(pc),d1
	cmp.w 10(a0),d1
	beq .done
	cmpi.w #10,d1
	blo .bad
	cmpi.w #80,d1
	bhi .bad
	lea time_loop_state(pc),a3
	move.l time_loop_cia(pc),a1
	move.l (a1),d0
	tst.l TIME_LOOP_ACTIVE(a3)
	beq .modal
	sub.l TIME_LOOP_PAUSED(a3),d0
	bra .stamp
.modal
	move.l TIME_LOOP_PAUSE_START(a3),d0
	sub.l TIME_LOOP_PAUSE_BASE(a3),d0
.stamp
	addq.l #1,d0
	IFD VERIFY
	lea time_rate_count(pc),a4
	move.l (a4),d2
	cmpi.l #32,d2
	bhs .enqueue
	mulu.w #24,d2
	lea time_rate_log(pc),a5
	adda.w d2,a5
	move.l (a1),(a5)+
	move.l TIME_LOOP_PAUSED(a3),(a5)+
	move.l TIME_LOOP_CURSOR(a3),(a5)+
	move.l d0,(a5)+
	move.w d1,(a5)+
	move.w 8(a0),(a5)+
	move.l TIME_LOOP_ACTIVE(a3),(a5)
.enqueue
	addq.l #1,(a4)
	ENDC
	bsr time_rate_push
	bra .done
.bad
	move.w #1,4(a0) ; main owner faults; never call resload_Abort in an IRQ
.done
	movem.l (sp)+,d0-a6
	rts

; a0 queue, d0 deadline, d1 divisor; d0=0 success/1 full. No eviction.
time_rate_push:
	movem.l d2-d4/a1,-(sp)
	move.w (a0),d2
	move.w d2,d3
	sub.w 2(a0),d3
	cmpi.w #32,d3
	bhs .full
	move.w d2,d4
	andi.w #31,d4
	lsl.w #3,d4
	lea 12(a0),a1
	adda.w d4,a1
	move.l d0,(a1)
	move.w d1,4(a1)
	clr.w 6(a1)
	move.w d1,10(a0)
	addq.w #1,d3
	cmp.w 6(a0),d3
	bls .publish
	move.w d3,6(a0)
.publish
	addq.w #1,d2
	move.w d2,(a0)
	moveq #0,d0
	bra .done
.full
	move.w #1,4(a0)
	moveq #1,d0
.done
	movem.l (sp)+,d2-d4/a1
	rts

; a0 queue, d0 active cursor. Consume all due settings BEFORE funding the tick.
; Return d0 consumed count; preserve phases, queue future records and registers.
time_rate_consume:
	movem.l d1-d4/a1,-(sp)
	move.l d0,d4
	moveq #0,d0
.next
	move.w 2(a0),d1
	cmp.w (a0),d1
	beq .done
	move.w d1,d2
	andi.w #31,d2
	lsl.w #3,d2
	lea 12(a0),a1
	adda.w d2,a1
	move.l (a1),d2
	sub.l d4,d2
	tst.l d2
	bgt .done
	move.w 4(a1),8(a0)
	addq.w #1,d1
	move.w d1,2(a0)
	addq.w #1,d0
	bra .next
.done
	movem.l (sp)+,d1-d4/a1
	rts

time_rate_advance:
	movem.l d0/a0-a1,-(sp)
	lea time_loop_state(pc),a1
	move.l TIME_LOOP_CURSOR(a1),d0
	sub.l TIME_LOOP_PAUSED(a1),d0
	lea time_rate_queue(pc),a0
	tst.w 4(a0)
	bne .bad
	bsr time_rate_consume
	movem.l (sp)+,d0/a0-a1
	rts
.bad
	pea time_rate_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)

	IFD VERIFY
; CUSTOM5 bit 25: call the original main-task divisor API at three wall times.
; No physics/clock phase/consumer writes. This is not a Preferences UI fixture.
time_rate_fixture:
	movem.l d0-a2,-(sp)
	btst #1,perf_custom5(pc)
	beq .done
	move.w time_keys_ready(pc),d0
	beq .done
	lea time_rate_fixture_index(pc),a1
	move.w (a1),d0
	cmpi.w #3,d0
	bhs .done
	lsl.w #2,d0
	lea .cases(pc),a2
	adda.w d0,a2
	move.l time_loop_cia(pc),a0
	move.l (a0),d0
	sub.l time_devices_epoch(pc),d0
	cmp.w (a2),d0
	blo .done
	addq.w #1,(a1)
	move.l time_loop_sim(pc),a0
	adda.l #$3cde,a0
	move.w 2(a2),-(sp)
	jsr (a0)
	addq.l #2,sp
.done
	movem.l (sp)+,d0-a2
	rts
.cases: dc.w 2,10,100,80,200,33

; Private native queue test: sequence and CIA wrap, future retention and overflow.
time_rate_selftest:
	movem.l d0-a6,-(sp)
	lea time_rate_test_queue(pc),a0
	move.l #$fff0fff0,(a0)
	clr.l 4(a0)
	move.l #$00210021,8(a0)
	moveq #0,d7
.fill
	move.l #$fffffff0,d0
	add.l d7,d0
	moveq #10,d1
	add.w d7,d1
	bsr time_rate_push
	tst.w d0
	bne .bad
	addq.w #1,d7
	cmpi.w #32,d7
	blo .fill
	moveq #16,d0
	moveq #33,d1
	bsr time_rate_push
	cmpi.w #1,d0
	bne .bad
	cmpi.w #$10,(a0)
	bne .bad
	cmpi.w #1,4(a0)
	bne .bad
	cmpi.w #32,6(a0)
	bne .bad
	clr.w 4(a0)
	move.l #$fffffff3,d0
	bsr time_rate_consume
	cmpi.w #4,d0
	bne .bad
	cmpi.w #13,8(a0)
	bne .bad
	move.l #$fffffff3,d0
	bsr time_rate_consume
	tst.w d0
	bne .bad
	moveq #15,d0
	bsr time_rate_consume
	cmpi.w #28,d0
	bne .bad
	cmpi.w #41,8(a0)
	bne .bad
	cmpi.w #$10,2(a0)
	bne .bad
	lea time_rate_test_result(pc),a0
	move.l #1,(a0)
	movem.l (sp)+,d0-a6
	rts
.bad
	pea time_rate_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)

	ENDC
time_rate_error: dc.b "Red Baron: W6 rate history bytes, value or queue fault",0
	even
time_rate_pending: dc.w 0
	IFD VERIFY
time_rate_fixture_index: dc.w 0
time_rate_count: dc.l 0
time_rate_test_result: dc.l 0
	ENDC
time_rate_queue: dcb.b TIME_RATE_BYTES,0
	IFD VERIFY
time_rate_test_queue: dcb.b TIME_RATE_BYTES,0
time_rate_log: dcb.b 24*32,0
	ENDC
