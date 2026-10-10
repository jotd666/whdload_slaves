; W6 message lifetime: 178 active CIA intervals (~3 seconds PAL), VERIFY bit 13.
; Timer word remains a presentation/priority compatibility value (15000..1).
; Expired messages retain 1 until an actual render performs native erasure.
; PERF_RANGE sim:03c06 8 bit=13
; PERF_RANGE sim:03c7c 6 bit=13
; PERF_RANGE sim:0084e 8 bit=13
; PERF_RANGE sim:00ab4 6 bit=13
TIME_MESSAGE_TICKS = 178

time_message_install:
	movem.l d0-a6,-(sp)
	move.l time_loop_h3(pc),d2
	addi.l #$4820,d2
	lea .checks(pc),a3
	moveq #3,d7
.check
	move.l a1,a4
	adda.l (a3)+,a4
	move.w (a3)+,d0
	cmp.w (a4)+,d0
	bne .bad
	move.w (a3)+,d0
	beq .address
	cmp.w (a4)+,d0
	bne .bad
.address
	cmp.l (a4),d2
	bne .bad
	dbf d7,.check
	btst #0,perf_attnflags+3(pc)
	beq .flags_ready
	lea time_message_ccr(pc),a0
	move.w #$42c0,(a0)
.flags_ready
	bsr time_message_selftest
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.bad
	pea time_message_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
.checks:
	dc.l $3c06
	dc.w $33fc,15000
	dc.l $3c7c
	dc.w $33c7,0
	dc.l $84e
	dc.w $0479,500
	dc.l $ab4
	dc.w $4279,0
.patch:
	PL_START
	PL_PSS $3c06,time_message_start,2
	PL_PS $3c7c,time_message_shorten
	PL_PSS $84e,time_message_render,2
	PL_PS $ab4,time_message_clear
	PL_END

; A saved CCR makes the native stores' X semantics independent of instrumentation.
time_message_ccr:
	move.w sr,d0
	rts

time_message_start:
	movem.l d0-a2,-(sp)
	bsr time_message_ccr
	move.w d0,-(sp)
	move.l time_loop_h3(pc),a0
	move.w #15000,$4820(a0)
	lea time_loop_state(pc),a1
	tst.l TIME_LOOP_ACTIVE(a1)
	beq .done
	moveq #1,d2
	move.w #TIME_MESSAGE_TICKS,d0
	bsr time_message_arm
.done
	move.w (sp)+,ccr
	movem.l (sp)+,d0-a2
	movem.l a0,-(sp)
	lea time_message_positive(pc),a0
	tst.w (a0)
	movem.l (sp)+,a0
	rts

time_message_shorten:
	movem.l d0-a2,-(sp)
	bsr time_message_ccr
	move.w d0,-(sp)
	move.l time_loop_h3(pc),a0
	move.w d7,$4820(a0)
	lea time_loop_state(pc),a1
	tst.l TIME_LOOP_ACTIVE(a1)
	beq .done
	moveq #0,d0
	move.w d7,d0
	ble .immediate
	mulu.w #TIME_MESSAGE_TICKS,d0
	addi.l #14999,d0
	divu.w #15000,d0
	andi.l #$ffff,d0
	bra .arm
.immediate
	moveq #0,d0
.arm
	moveq #2,d2
	bsr time_message_arm
	bsr time_message_advance
.done
	move.w (sp)+,ccr
	movem.l (sp)+,d0-a2
	tst.w d7
	rts

; d0 interval, d2 event kind. Called after native text/priority acceptance.
time_message_arm:
	movem.l d0-d2/a0-a2,-(sp)
	lea time_message_state(pc),a2
	lea time_loop_state(pc),a1
	move.l TIME_LOOP_CURSOR(a1),d1
	sub.l TIME_LOOP_PAUSED(a1),d1
	move.l d1,4(a2)
	add.l d0,d1
	move.l d1,(a2)
	move.w #1,8(a2)
	bsr time_message_log_event
	movem.l (sp)+,d0-d2/a0-a2
	rts

time_message_reset:
	movem.l d0-d2/a0-a2,-(sp)
	lea time_message_state(pc),a0
	clr.l (a0)
	clr.l 4(a0)
	clr.w 8(a0)
	lea time_message_count(pc),a0
	clr.l (a0)
	lea time_message_fixture_index(pc),a0
	clr.w (a0)
	move.l time_loop_h3(pc),a0
	move.w $4820(a0),d0
	ble .done
	moveq #1,d2
	move.w #TIME_MESSAGE_TICKS,d0
	bsr time_message_arm
.done
	movem.l (sp)+,d0-d2/a0-a2
	rts

; d0 deadline, d1 now -> d0 positive remaining intervals or zero; modular <2^31.
time_message_remaining:
	sub.l d1,d0
	tst.l d0
	bgt .done
	moveq #0,d0
.done
	rts

; d0 0..178 -> positive legacy timer, ceil(remaining*15000/178), minimum 1.
time_message_scale:
	mulu.w #15000,d0
	addi.l #TIME_MESSAGE_TICKS-1,d0
	divu.w #TIME_MESSAGE_TICKS,d0
	andi.l #$ffff,d0
	bne .done
	moveq #1,d0
.done
	rts

; One main-task service per funded active CIA boundary; never draw from here.
time_message_advance:
	movem.l d0-a2,-(sp)
	lea time_message_state(pc),a2
	cmpi.w #1,8(a2)
	bne .done
	lea time_loop_state(pc),a1
	move.l TIME_LOOP_CURSOR(a1),d1
	sub.l TIME_LOOP_PAUSED(a1),d1
	move.l (a2),d0
	bsr time_message_remaining
	tst.l d0
	beq .expired
	bsr time_message_scale
	move.l time_loop_h3(pc),a0
	move.w d0,$4820(a0)
	bra .done
.expired
	move.w #2,8(a2)
	move.l time_loop_h3(pc),a0
	move.w #1,$4820(a0)
	; Native dirty-rectangle publication only. This helper unions the rectangle
	; and sets the two-buffer dirty count; it performs no blits or redraws.
	pea $456a(a0)
	move.l time_loop_sim(pc),a0
	adda.l #$197ee,a0
	jsr (a0)
	addq.l #4,sp
	moveq #3,d2
	bsr time_message_log_event
.done
	movem.l (sp)+,d0-a2
	rts

; Keep original SUB flags in non-flight/UI mode. The active render's following
; branch consumes only Z: live messages draw, expired ones take native erasure.
time_message_render:
	movem.l d0-d2/a0-a2,-(sp)
	move.l time_loop_h3(pc),a0
	lea time_loop_state(pc),a1
	tst.l TIME_LOOP_ACTIVE(a1)
	beq .original
	lea time_message_state(pc),a2
	cmpi.w #2,8(a2)
	bne .live
	clr.w 8(a2)
	clr.w $4820(a0)
	moveq #4,d2
	bsr time_message_log_event
	move.l time_loop_h3(pc),a0
.live
	tst.w $4820(a0)
	bra .done
.original
	subi.w #500,$4820(a0)
.done
	movem.l (sp)+,d0-d2/a0-a2
	rts

; A temporarily hidden message must not be cancelled by a skipped paint path.
time_message_clear:
	movem.l a0-a1,-(sp)
	lea time_loop_state(pc),a1
	tst.l TIME_LOOP_ACTIVE(a1)
	beq .original
	lea time_message_state(pc),a1
	tst.w 8(a1)
	bne .retain
.original
	move.l time_loop_h3(pc),a0
	clr.w $4820(a0)
	bra .done
.retain
	; The displaced CLR returns Z=1; its destination is clock-owned in flight.
	cmpa.l a0,a0
.done
	movem.l (sp)+,a0-a1
	rts

; VERIFY ledger: active cursor.l, deadline.l, kind.w, phase.w, timer.w,
; dirty byte widened.w, draw opportunities.l, native message pointer.l.
time_message_log_event:
	movem.l d0-d1/a0-a2,-(sp)
	lea time_message_count(pc),a0
	move.l (a0),d0
	cmpi.l #128,d0
	bhs .done
	addq.l #1,(a0)
	mulu.w #24,d0
	lea time_message_log(pc),a0
	adda.w d0,a0
	lea time_loop_state(pc),a1
	move.l TIME_LOOP_CURSOR(a1),d1
	sub.l TIME_LOOP_PAUSED(a1),d1
	move.l d1,(a0)+
	lea time_message_state(pc),a2
	move.l (a2),(a0)+
	move.w d2,(a0)+
	move.w 8(a2),(a0)+
	move.l time_loop_h3(pc),a2
	move.w $4820(a2),(a0)+
	moveq #0,d0
	move.b $711c(a2),d0
	move.w d0,(a0)+
	move.l TIME_LOOP_DRAWS(a1),(a0)+
	move.l $481c(a2),(a0)
.done
	movem.l (sp)+,d0-d1/a0-a2
	rts

; CUSTOM5 bit 26: native message API replacement, shortening and full lifetime.
time_message_fixture:
	movem.l d0-a2,-(sp)
	btst #2,perf_custom5(pc)
	beq .done
	move.w time_keys_ready(pc),d0
	beq .done
	lea time_message_fixture_index(pc),a2
	move.w (a2),d0
	cmpi.w #6,d0
	bhs .done
	lea time_loop_state(pc),a1
	move.l TIME_LOOP_CURSOR(a1),d1
	sub.l TIME_LOOP_PAUSED(a1),d1
	tst.w d0
	bne .elapsed
	lea time_message_fixture_epoch(pc),a0
	move.l d1,(a0)
.elapsed
	sub.l time_message_fixture_epoch(pc),d1
	add.w d0,d0
	lea .when(pc),a0
	cmp.w (a0,d0.w),d1
	blo .done
	addq.w #1,(a2)
	cmpi.w #10,d0
	beq .shorten_first
	cmpi.w #4,d0
	beq .shorten
	lea time_message_fixture_first(pc),a1
	tst.w d0
	beq .send
	cmpi.w #8,d0
	beq .send
	lea time_message_fixture_second(pc),a1
	cmpi.w #2,d0
	beq .send
	lea time_message_fixture_third(pc),a1
.send
	clr.w -(sp)
	move.w #1,-(sp)
	move.l a1,-(sp)
	move.l time_loop_sim(pc),a0
	adda.l #$3c36,a0
	jsr (a0)
	addq.l #8,sp
	bra .done
.shorten
	lea time_message_fixture_second(pc),a1
	bra .shorten_send
.shorten_first
	lea time_message_fixture_first(pc),a1
.shorten_send
	move.w #5000,-(sp)
	move.l a1,-(sp)
	move.l time_loop_sim(pc),a0
	adda.l #$3c5c,a0
	jsr (a0)
	addq.l #6,sp
.done
	movem.l (sp)+,d0-a2
	rts
.when: dc.w 0,60,90,240,480,510
time_message_fixture_first: dc.b "W6 first message",0
time_message_fixture_second: dc.b "W6 replacement",0
time_message_fixture_third: dc.b "W6 full lifetime",0
	even

time_message_selftest:
	movem.l d0-d7/a0-a2,-(sp)
	lea time_message_test_result(pc),a0
	clr.l (a0)
	lea time_message_cases(pc),a1
	moveq #0,d7
.next
	move.l d7,d0
	bsr time_message_scale
	cmp.w (a1)+,d0
	bne .bad
	addq.l #1,(a0)
	addq.w #1,d7
	cmpi.w #TIME_MESSAGE_TICKS,d7
	bls .next
	; Deadlines across unsigned wrap and on either side of expiry.
	moveq #3,d0
	moveq #-2,d1
	bsr time_message_remaining
	cmpi.l #5,d0
	bne .bad
	moveq #3,d0
	moveq #4,d1
	bsr time_message_remaining
	tst.l d0
	bne .bad
	moveq #3,d0
	moveq #3,d1
	bsr time_message_remaining
	tst.l d0
	bne .bad
	movem.l (sp)+,d0-d7/a0-a2
	rts
.bad
	pea time_message_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_message_error: dc.b "Red Baron: W6 message bytes or arithmetic mismatch",0
	even
time_message_positive: dc.w 15000
time_message_state: dc.l 0,0
	dc.w 0
time_message_fixture_index: dc.w 0
time_message_fixture_epoch: dc.l 0
time_message_count: dc.l 0
time_message_test_result: dc.l 0
	include "time-message-cases.i"
