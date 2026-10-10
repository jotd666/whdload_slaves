; W6 timestamped keyboard consumption. VERIFY integration, CUSTOM2 bit 13.
; PERF_RANGE sim:308b6 6 bit=13
; PERF_RANGE sim:309c0 6 bit=13
; PERF_RANGE sim:309cc 10 bit=13
; Physical bitmap/FIFO remain native for UI; flight uses a private tick snapshot.
time_keys_install:
	movem.l d0-a6,-(sp)
	move.l a1,a3
	adda.l #$309c0,a3
	cmpi.w #$41f9,(a3)
	bne .bad
	move.l a1,d0
	addi.l #$30f8c,d0
	cmp.l 2(a3),d0
	bne .bad
	lea time_keys_physical(pc),a0
	move.l d0,(a0)+
	move.l a1,d0
	addi.l #$3100c,d0
	move.l d0,(a0)+
	move.l a1,a3
	adda.l #$309cc,a3
	cmpi.l #$303c0000,(a3)
	bne .bad
	cmpi.w #$4a79,4(a3)
	bne .bad
	cmp.l 6(a3),d0
	bne .bad
	move.l a3,(a0)
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	lea time_keys_installed(pc),a0
	move.w #1,(a0)
	bsr time_keys_start
	movem.l (sp)+,d0-a6
	rts
.bad
	pea perf_mismatch(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
.patch:
	PL_START
	PL_PS $309c0,time_keys_query
	PL_PSS $309cc,time_keys_pop,4
	PL_END

; Seed once after the VERIFY route. The IRQ takes an atomic physical snapshot
; and establishes the producer's active-time domain before publishing ready.
time_keys_start:
	movem.l d0/a0,-(sp)
	move.w time_keys_ready(pc),d0
	bne .done
	move.w time_keys_installed(pc),d0
	beq .done
	move.l tape_game_steps(pc),d0
	beq .done
	move.l time_input_observe_state+8(pc),d0
	beq .done
	moveq #3,d0
	bsr time_pause_request
.done
	movem.l (sp)+,d0/a0
	rts

time_keys_seed_irq:
	movem.l d0/a0-a2,-(sp)
	move.l time_keys_physical(pc),a0
	lea time_keys_bitmap(pc),a1
	moveq #31,d0
.copy
	move.l (a0)+,(a1)+
	dbf d0,.copy
	move.l time_input_observe_state+8(pc),a0
	move.w (a0),2(a0) ; initial snapshot subsumes earlier transitions
	clr.l 4(a0)
	lea time_keys_commands(pc),a0
	clr.l (a0)
	lea time_keys_consumed(pc),a0
	clr.l (a0)
	clr.l 4(a0)
	bsr time_devices_seed
	lea time_keys_ready(pc),a0
	move.w #1,(a0)
	movem.l (sp)+,d0/a0-a2
	rts

; Called after each CIA cursor increment, before any world updates at that
; boundary. Future records remain queued. Equal-deadline compressed updates
; share the held snapshot; command pops advance only their private tail.
time_keys_advance:
	movem.l d0-d4/a0-a3,-(sp)
	move.w time_keys_ready(pc),d0
	beq .done
	lea time_loop_state(pc),a3
	move.l TIME_LOOP_CURSOR(a3),d4
	sub.l TIME_LOOP_PAUSED(a3),d4
	move.l time_input_observe_state+8(pc),a0
	tst.w 4(a0)
	bne time_keys_bad
	lea time_keys_event(pc),a1
.next
	move.l d4,d0
	bsr time_input_pop
	tst.w d0
	beq .done
	cmpi.w #TIME_DEVICE_CODE,4(a1)
	beq .device
	lea time_keys_consumed(pc),a2
	addq.l #1,(a2)
	move.w 4(a1),d0
	move.w d0,d3
	andi.w #$7f,d0
	lea time_keys_bitmap(pc),a2
	move.w 6(a1),d1
	move.b d1,(a2,d0.w)
	beq .next
	btst #8,d3 ; held-only transitions during a modal interval
	bne .next
	; Original sim:308c2..308ec, with the frozen bitmap as modifier source.
	moveq #0,d1
	or.b $60(a2),d1
	or.b $61(a2),d1
	or.b $62(a2),d1
	ror.w #1,d1
	or.b $63(a2),d1
	ror.w #1,d1
	or.b $64(a2),d1
	or.b $65(a2),d1
	ror.w #1,d1
	or.b $66(a2),d1
	or.b $67(a2),d1
	ror.w #5,d1
	or.w d1,d0
	lea time_keys_commands(pc),a2
	move.w (a2),d1
	move.w d1,d2
	sub.w 2(a2),d2
	cmpi.w #256,d2
	bhs time_keys_bad
	move.w d1,d2
	andi.w #255,d2
	add.w d2,d2
	move.w d0,4(a2,d2.w)
	addq.w #1,d1
	move.w d1,(a2)
	bra .next
.device
	bsr time_devices_apply
	bra .next
.done
	movem.l (sp)+,d0-d4/a0-a3
	rts

; The following native MOVE.B at sim:309c6 supplies flags; LEA's flags are dead.
time_keys_query:
	move.l time_keys_physical(pc),a0
	move.l a1,-(sp)
	lea time_keys_ready(pc),a1
	tst.w (a1)
	beq .done
	lea time_loop_state(pc),a1
	tst.l TIME_LOOP_ACTIVE(a1)
	beq .done
	lea time_keys_bitmap(pc),a0
.done
	move.l (sp)+,a1
	rts

time_keys_pop:
	move.l a0,-(sp)
	lea time_keys_ready(pc),a0
	tst.w (a0)
	beq .native
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_ACTIVE(a0)
	beq .native
	movem.l d1-d2,-(sp)
	lea time_keys_commands(pc),a0
	move.w #0,d0
	move.w 2(a0),d1
	cmp.w (a0),d1
	beq .empty
	move.w d1,d2
	andi.w #255,d2
	add.w d2,d2
	move.w 4(a0,d2.w),d0
	addq.w #1,d1
	move.w d1,2(a0)
	lea time_keys_popped(pc),a0
	addq.l #1,(a0)
.empty
	movem.l (sp)+,d1-d2
	move.l time_loop_sim(pc),a0
	adda.l #$309fc,a0
	move.l a0,4(sp) ; complete the native function at its RTS
	move.l (sp)+,a0
	rts
.native
	move.w #0,d0
	move.l time_keys_native_count(pc),a0
	tst.w (a0)
	move.l (sp)+,a0
	rts

time_keys_bad:
	pea time_keys_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_keys_error: dc.b "Red Baron: W6 keyboard queue overflow",0
	even
time_keys_physical: dc.l 0
time_keys_native_count: dc.l 0
time_keys_native_pop: dc.l 0
time_keys_installed: dc.w 0
time_keys_ready: dc.w 0
time_keys_consumed: dc.l 0
time_keys_popped: dc.l 0
time_keys_event: dcb.b 16,0
time_keys_bitmap: dcb.b 128,0
time_keys_commands: dcb.b 4+512,0
