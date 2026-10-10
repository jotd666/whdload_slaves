; VERIFY-only W6 keyboard producer observation. CUSTOM5 bit 20.
; Observe native key transitions at their acquisition point, not at render polls.
; VERIFY_RANGE sim:308b6 6: whole relocated LEA before the native bitmap store.
; This observer leaves both the native bitmap and native command FIFO untouched.
time_input_observe_install:
	movem.l d0-a6,-(sp)
	btst #4,perf_custom5+1(pc)
	beq .done
	move.l tape_game_steps(pc),d0
	cmpi.l #1,d0
	bne .done
	move.l tape_marker+24(pc),a1
	move.l a1,a3
	adda.l #$308b6,a3
	cmpi.w #$41f9,(a3)
	bne .bad
	move.l a1,d0
	addi.l #$30f8c,d0
	cmp.l 2(a3),d0
	bne .bad
	lea time_input_observe_state(pc),a0
	move.l a1,(a0)+
	move.l d0,(a0)+
	lea .queue_base(pc),a3
.queue_base
	adda.l #time_input_observe_queue-.queue_base,a3
	move.l a3,(a0)
	clr.l (a3)+
	clr.l (a3)+
	clr.l (a3)+
	clr.l (a3)
	move.l time_input_observe_state(pc),a0
	adda.l #$30006,a0
	lea time_input_fixture_epoch(pc),a3
	move.l (a0),(a3)
	lea time_input_observe_patch(pc),a0
	move.l _resload(pc),a2
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
.done
	movem.l (sp)+,d0-a6
	rts
.bad
	pea perf_mismatch(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_input_observe_patch:
	PL_START
	PL_PS $308b6,time_input_observe_irq
	PL_END

; Only the native supervisor keyboard IRQ calls this wrapper. Serialize against
; higher-priority producers before reading the CIA timestamp and publishing data.
; Restore SR exactly: the displaced LEA must preserve every incoming flag.
time_input_observe_irq:
	move.w sr,-(sp)
	ori.w #$0700,sr
	movem.l d0-d3/a1-a2,-(sp)
	lea -16(sp),sp
	move.l time_input_observe_state(pc),a2
	adda.l #$30006,a2
	move.l (a2),d2
	addq.l #1,d2
	move.l d2,(sp)
	move.w d0,4(sp)
	moveq #0,d2
	move.b d1,d2
	move.w d2,6(sp)
	clr.l 8(sp)
	clr.l 12(sp)
	move.l time_input_observe_state+8(pc),a0
	move.l sp,a1
	bsr time_input_push
	lea 16(sp),sp
	movem.l (sp)+,d0-d3/a1-a2
	move.l time_input_observe_state+4(pc),a0
	move.w (sp)+,sr
	rts
	CNOP 0,4
	dc.b "RBTINPUT"
time_input_observe_state:
	dc.l 0,0,0 ; sim, native keyboard bitmap, timestamp FIFO


; CUSTOM5 bit 21: four decoded keyboard transitions from supervisor VBlank.
; Exercise the installed native LEA hook and the unchanged bitmap/FIFO tail.
; This does not test the host keyboard mapping or CIA serial handshake.
time_input_fixture:
	btst #5,perf_custom5+1(pc)
	beq .done
	movem.l d0-a6,-(sp)
	move.w sr,-(sp)
	ori.w #$0700,sr
	move.l time_input_observe_state(pc),a0
	move.l a0,d0
	beq .restore
	lea time_input_fixture_index(pc),a3
	moveq #0,d3
	move.w (a3),d3
	cmpi.w #4,d3
	bhs .restore
	adda.l #$30006,a0
	move.l (a0),d2
	sub.l time_input_fixture_epoch(pc),d2
	move.w d3,d4
	mulu.w #3,d4
	addq.l #2,d4
	cmp.l d4,d2
	blo .restore
	moveq #$4e,d0
	cmpi.w #2,d3
	blo.b .key
	moveq #$40,d0
.key
	moveq #1,d1
	move.w d3,d4
	andi.w #1,d4
	eor.w d4,d1
	; Keep independent acquisition evidence before calling the native hook.
	move.l d3,d4
	lsl.w #3,d4
	lea time_input_fixture_log(pc),a4
	adda.w d4,a4
	move.l (a0),(a4)+
	move.w d0,(a4)+
	move.w d1,(a4)
	addq.w #1,(a3)
	move.l time_input_observe_state(pc),a1
	adda.l #$30f4c,a1 ; native key FIFO argument of decoded keyboard callback
	move.l time_input_observe_state(pc),a2
	adda.l #$308b6,a2
	jsr (a2)
.restore
	move.w (sp)+,sr
	movem.l (sp)+,d0-a6
.done
	rts
time_input_fixture_epoch: dc.l 0
time_input_fixture_index: dc.w 0
	even
time_input_fixture_log: dcb.b 32,0
