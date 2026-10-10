; W6 native modal-flight boundaries. Included only by VERIFY, installed bit 13.
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
	move.l time_loop_sim(pc),-(sp)
	addi.l #$1f0d2,(sp)
	rts
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

; Main-task owner only. Nested modal calls exclude elapsed time just once.
; Suspending ownership also lets menus use their original variable clock.
time_pause_begin:
	movem.l d0/a0-a1,-(sp)
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_PAUSE_DEPTH(a0)
	bne .nested
	tst.l TIME_LOOP_ACTIVE(a0)
	beq .done
	move.l time_loop_cia(pc),a1
	move.l (a1),TIME_LOOP_PAUSE_START(a0)
	clr.l TIME_LOOP_ACTIVE(a0)
.nested
	addq.l #1,TIME_LOOP_PAUSE_DEPTH(a0)
.done
	movem.l (sp)+,d0/a0-a1
	rts

time_pause_end:
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
	move.l time_loop_h3(pc),a1
	move.w #225,$4834(a1)
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
time_pause_selftest:
	movem.l d0-a6,-(sp)
	move.l time_loop_cia(pc),-(sp)
	move.l time_loop_h3(pc),-(sp)
	lea time_loop_state(pc),a0
	moveq #13,d7
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
	moveq #13,d7
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
	bsr time_pause_begin
	tst.l TIME_LOOP_ACTIVE(a0)
	bne .bad
	cmpi.l #1,TIME_LOOP_PAUSE_DEPTH(a0)
	bne .bad
	move.l #$10,(a1)
	bsr time_pause_begin
	cmpi.l #2,TIME_LOOP_PAUSE_DEPTH(a0)
	bne .bad
	bsr time_pause_end
	tst.l TIME_LOOP_PAUSED(a0)
	bne .bad
	cmpi.l #$fffffff0,TIME_LOOP_CURSOR(a0)
	bne .bad
	move.l #$25,(a1)
	bsr time_pause_end
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
	cmpi.w #225,(a1)
	bne .bad
	; A matched zero-duration pause changes neither credit nor cursor.
	bsr time_pause_begin
	bsr time_pause_end
	cmpi.l #$30,TIME_LOOP_PAUSED(a0)
	bne .bad
	cmpi.l #$20,TIME_LOOP_CURSOR(a0)
	bne .bad
	lea time_pause_test_result(pc),a1
	move.l #1,(a1)
	lea time_loop_state+56(pc),a0
	moveq #13,d7
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
