; W6 native modal-flight boundaries, CUSTOM2 bit 13.
; Preserve pre-existing debt and fractional phases by translating the CIA cursor
; by exactly the excluded modal duration. Never reset cursor to current time.
; PERF_RANGE sim:21ba2 6 bit=13
; PERF_RANGE sim:21c02 6 bit=13
; PERF_RANGE sim:21c20 6 bit=13
; PERF_RANGE sim:21c82 6 bit=13
; PERF_RANGE sim:21bf6 8 bit=13

time_pause_install:
	movem.l d0-a6,-(sp)
	move.l #$21ba2,d0
	moveq #6,d1
	lea .menu_a(pc),a0
	bsr perf_check_bytes
	move.l #$21c02,d0
	lea .menu_b(pc),a0
	bsr perf_check_bytes
	move.l #$21c20,d0
	lea .prefs(pc),a0
	bsr perf_check_bytes
	move.l #$21c82,d0
	lea .controls(pc),a0
	bsr perf_check_bytes
	move.l #$21bf6,d0
	moveq #8,d1
	lea .pause(pc),a0
	bsr perf_check_bytes
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.menu_a: dc.w $4eba,$d52e,$2e00
.menu_b: dc.w $4eba,$d4ce,$2e00
.prefs: dc.w $4eba,$df18,$4a40
.controls: dc.w $4eba,$de06,$4a40
.pause: dc.w $6100,$fecc,$6000,$00f0
.patch:
	PL_START
	PL_PS $21ba2,time_pause_menu
	PL_PS $21c02,time_pause_menu
	PL_PS $21c20,time_pause_preferences
	PL_PS $21c82,time_pause_controls
	PL_PSS $21bf6,time_pause_wait,2
	PL_END

; No arguments at these native call sites. Preserve all incoming integer
; registers before entering the native function, and all results afterwards.
; Replay the displaced MOVE/TST for NZVC. Callers do not consume returned X.
time_pause_menu:
	bsr time_pause_begin
	bsr .native
	bsr time_pause_end
	move.l d0,d7
	rts
.native
	bra time_auto_menu_call
time_pause_preferences:
	bsr time_pause_begin
	bsr .native
	bsr time_pause_end
	tst.w d0
	rts
.native
	move.l time_loop_sim(pc),-(sp)
	addi.l #$1fb3a,(sp)
	rts
time_pause_controls:
	bsr time_pause_begin
	bsr .native
	bsr time_pause_end
	tst.w d0
	rts
.native
	move.l time_loop_sim(pc),-(sp)
	addi.l #$1fa8a,(sp)
	rts
time_pause_wait:
	bsr time_pause_begin
	bsr .native
	bsr time_pause_end
	; Replay original unconditional branch instead of falling through its NOP.
	movem.l a0,-(sp)
	move.l time_loop_sim(pc),a0
	adda.l #$21cec,a0
	movem.l a0,4(sp)
	movem.l (sp)+,a0
	rts
.native
	move.l time_loop_sim(pc),-(sp)
	addi.l #$21ac4,(sp)
	rts

; The flight task is user mode. Publish a request and wait for VBlank to make
; the clock transition atomically with respect to every input-producing IRQ.
; The wait on entry is active flight time; the resume wait remains modal time.
time_pause_begin:
	movem.l d0/a0,-(sp)
	moveq #1,d0
	bsr time_pause_request
	movem.l (sp)+,d0/a0
	rts
time_pause_end:
	movem.l a6,-(sp)
	lea .scenery_call_1(pc),a6
.scenery_call_1
	adda.l #time_scenery_invalidate-.scenery_call_1,a6
	jsr (a6)
	movem.l (sp)+,a6
	movem.l d0/a0,-(sp)
	moveq #2,d0
	bsr time_pause_request
	movem.l (sp)+,d0/a0
	rts
time_pause_request:
	lea time_pause_pending(pc),a0
	move.w d0,(a0)
.wait
	tst.w (a0)
	bne .wait
	rts

; Called only from the supervisor VBlank observer. Higher input IRQs cannot
; observe a half-published cursor/paused-total/ownership tuple. Acknowledge last.
time_pause_irq:
	move.w sr,-(sp)
	ori.w #$0700,sr
	movem.l d0/a0-a1,-(sp)
	lea time_pause_pending(pc),a0
	move.w (a0),d0
	beq .done
	cmpi.w #3,d0
	beq .seed
	cmpi.w #4,d0
	beq .rate
	cmpi.w #1,d0
	beq .begin
	bsr time_pause_apply_end
	bra .ack
.rate
	bsr time_rate_publish
	bra .ack
.seed
	bsr time_keys_seed_irq
	bra .ack
.begin
	bsr time_pause_apply_begin
.ack
	clr.w (a0)
.done
	movem.l (sp)+,d0/a0-a1
	move.w (sp)+,sr
	rts
time_pause_pending: dc.w 0

; State-transition kernels: IRQ-owned in game, direct private-state self-test.
; Nested modal calls exclude elapsed time once. Menus retain the native clock.
time_pause_apply_begin:
	movem.l d0/a0-a1,-(sp)
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_PAUSE_DEPTH(a0)
	bne .nested
	tst.l TIME_LOOP_ACTIVE(a0)
	beq .done
	move.l time_loop_cia(pc),a1
	move.l (a1),TIME_LOOP_PAUSE_START(a0)
	move.l TIME_LOOP_PAUSED(a0),TIME_LOOP_PAUSE_BASE(a0)
	clr.l TIME_LOOP_ACTIVE(a0)
	move.w time_keys_ready(pc),d0
	beq .nested
	move.l time_keys_native_count(pc),a1
	clr.w (a1) ; native UI must not replay already captured flight commands
.nested
	addq.l #1,TIME_LOOP_PAUSE_DEPTH(a0)
.done
	movem.l (sp)+,d0/a0-a1
	rts

time_pause_apply_end:
	movem.l d0/a0-a1,-(sp)
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_PAUSE_DEPTH(a0)
	beq .done
	subq.l #1,TIME_LOOP_PAUSE_DEPTH(a0)
	bne .done
	move.l time_loop_cia(pc),a1
	move.l (a1),d0
	sub.l TIME_LOOP_PAUSE_START(a0),d0
	tst.l d0
	bmi .bad ; same unsigned half-range clock contract as active flight
	add.l d0,TIME_LOOP_CURSOR(a0)
	add.l d0,TIME_LOOP_PAUSED(a0)
	move.l #1,TIME_LOOP_ACTIVE(a0)
	bsr time_mouse_resume
	move.l time_loop_h3(pc),a1
	move.w time_loop_quantum(pc),$4834(a1)
.done
	movem.l (sp)+,d0/a0-a1
	rts
.bad
	pea time_loop_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)

; VERIFY startup check against a private CIA word and private primary-dt word.
; Existing game RAM is never modified. Preserve installer state and pointers.
	IFD VERIFY
time_pause_selftest:
	movem.l d0-a6,-(sp)
	move.l time_loop_cia(pc),-(sp)
	move.l time_loop_h3(pc),-(sp)
	lea time_loop_state(pc),a0
	moveq #14,d7
.save
	move.l (a0)+,-(sp)
	dbf d7,.save
	lea time_loop_cia(pc),a0
	lea time_pause_test_cia(pc),a1
	move.l a1,(a0)
	lea time_loop_h3(pc),a0
	lea time_pause_test_dt(pc),a1
	suba.l #$4834,a1
	move.l a1,(a0)
	lea time_loop_state(pc),a0
	move.l a0,a1
	moveq #14,d7
.clear
	clr.l (a1)+
	dbf d7,.clear
	move.l #$12345678,(a0)
	move.w #1536,16(a0)
	move.l #$fffffff0,TIME_LOOP_CURSOR(a0)
	move.w #2,TIME_LOOP_DUE(a0)
	move.w #7,TIME_LOOP_SERVICES(a0)
	move.l #9,TIME_LOOP_STEPS(a0)
	move.l #1,TIME_LOOP_ACTIVE(a0)
	lea time_pause_test_cia(pc),a1
	move.l #$fffffff5,(a1)
	bsr time_pause_apply_begin
	tst.l TIME_LOOP_ACTIVE(a0)
	bne .bad
	cmpi.l #1,TIME_LOOP_PAUSE_DEPTH(a0)
	bne .bad
	move.l #$10,(a1)
	bsr time_pause_apply_begin
	cmpi.l #2,TIME_LOOP_PAUSE_DEPTH(a0)
	bne .bad
	bsr time_pause_apply_end
	tst.l TIME_LOOP_PAUSED(a0)
	bne .bad
	cmpi.l #$fffffff0,TIME_LOOP_CURSOR(a0)
	bne .bad
	move.l #$25,(a1)
	bsr time_pause_apply_end
	cmpi.l #$30,TIME_LOOP_PAUSED(a0)
	bne .bad
	cmpi.l #$20,TIME_LOOP_CURSOR(a0)
	bne .bad
	cmpi.l #1,TIME_LOOP_ACTIVE(a0)
	bne .bad
	tst.l TIME_LOOP_PAUSE_DEPTH(a0)
	bne .bad
	cmpi.l #$12345678,(a0)
	bne .bad
	cmpi.w #1536,16(a0)
	bne .bad
	cmpi.w #2,TIME_LOOP_DUE(a0)
	bne .bad
	cmpi.w #7,TIME_LOOP_SERVICES(a0)
	bne .bad
	cmpi.l #9,TIME_LOOP_STEPS(a0)
	bne .bad
	lea time_pause_test_dt(pc),a1
	move.w time_loop_quantum(pc),d0
	cmp.w (a1),d0
	bne .bad
	; A matched zero-duration pause changes neither credit nor cursor.
	bsr time_pause_apply_begin
	bsr time_pause_apply_end
	cmpi.l #$30,TIME_LOOP_PAUSED(a0)
	bne .bad
	cmpi.l #$20,TIME_LOOP_CURSOR(a0)
	bne .bad
	lea time_pause_test_result(pc),a1
	move.l #1,(a1)
	lea time_loop_state+60(pc),a0
	moveq #14,d7
.restore
	move.l (sp)+,-(a0)
	dbf d7,.restore
	lea time_loop_h3(pc),a0
	move.l (sp)+,(a0)
	lea time_loop_cia(pc),a0
	move.l (sp)+,(a0)
	movem.l (sp)+,d0-a6
	rts
.bad
	pea time_pause_test_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_pause_test_error: dc.b "Red Baron: W6 pause self-test mismatch",0
	even
time_pause_test_cia: dc.l 0
time_pause_test_dt: dc.w 0
time_pause_test_result: dc.l 0
	ENDC
