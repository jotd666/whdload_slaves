; W6 timestamped keyboard producer. Runtime ownership is shared by all builds.
; VERIFY also supports the existing observation-only fixture.
; Observe native key transitions at their acquisition point, not at render polls.
; PERF_RANGE sim:308b6 6 bit=13
; Hook: whole relocated LEA before the native bitmap store.
; This observer leaves both the native bitmap and native command FIFO untouched.
time_input_observe_install:
	movem.l d0-a6,-(sp)
	IFD VERIFY
	bsr time_input_option_observe
	bne .selected
	bsr time_input_option_timing
	beq .done
.selected
	move.l tape_game_steps(pc),d0
	cmpi.l #1,d0
	bne .done
	move.l tape_marker+24(pc),a1
	ENDC
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
	IFD VERIFY
	move.l time_input_observe_state(pc),a0
	adda.l #$30006,a0
	lea .fixture_epoch(pc),a3
.fixture_epoch
	adda.l #time_input_fixture_epoch-.fixture_epoch,a3
	move.l (a0),(a3)
	ENDC
	lea time_input_observe_patch(pc),a0
	move.l _resload(pc),a2
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	bsr time_keys_start
.done
	movem.l (sp)+,d0-a6
	rts
.bad
	lea .error_base(pc),a0
.error_base
	adda.l #perf_mismatch-.error_base,a0
	pea (a0)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_input_observe_patch:
	PL_START
	PL_PS $308b6,time_input_observe_irq
	IFND VERIFY
	PL_PS $2d348,time_input_vbl
	ENDC
	PL_END

; Only the native supervisor keyboard IRQ calls this wrapper. Serialize against
; higher-priority producers before reading the CIA timestamp and publishing data.
; Restore SR exactly: the displaced LEA must preserve every incoming flag.
time_input_observe_irq:
	move.w sr,-(sp)
	ori.w #$0700,sr
	movem.l d0-d3/a1-a2,-(sp)
	lea -16(sp),sp
	bsr time_input_option_timing
	beq .capture
	move.w time_keys_ready(pc),d2
	beq .restore
.capture
	move.l time_input_observe_state(pc),a2
	adda.l #$30006,a2
	move.l (a2),d2
	move.w d0,4(sp)
	move.w time_keys_ready(pc),d3
	beq .stamp
	lea time_loop_state(pc),a2
	tst.l TIME_LOOP_ACTIVE(a2)
	beq .modal
	sub.l TIME_LOOP_PAUSED(a2),d2
	bra .stamp
.modal
	move.l TIME_LOOP_PAUSE_START(a2),d2
	sub.l TIME_LOOP_PAUSE_BASE(a2),d2
	ori.w #$100,4(sp) ; held-only: menu commands must not replay into flight
.stamp
	addq.l #1,d2
	move.l d2,(sp)
	moveq #0,d2
	move.b d1,d2
	move.w d2,6(sp)
	clr.l 8(sp)
	clr.l 12(sp)
	move.l time_input_observe_state+8(pc),a0
	move.l sp,a1
	bsr time_input_push
.restore
	lea 16(sp),sp
	movem.l (sp)+,d0-d3/a1-a2
	move.l time_input_observe_state+4(pc),a0
	move.w (sp)+,sr
	rts
	CNOP 0,4
	IFD VERIFY
	dc.b "RBTINPUT"
	ENDC
time_input_observe_state:
	dc.l 0,0,0 ; sim, native keyboard bitmap, timestamp FIFO


; Long-range VERIFY option read, preserving registers and all flags except Z.
time_input_option_timing:
	movem.l a0,-(sp)
	lea .base(pc),a0
.base
	adda.l #perf_mask+2-.base,a0
	btst #5,(a0)
	move.l (sp)+,a0
	rts



; PERF_RANGE sim:2d348 6 bit=13
; Supervisor VBlank handoff; replay the displaced LEA and preserve SR.
	IFND VERIFY
time_input_vbl:
	move.w sr,-(sp)
	bsr time_pause_irq
	move.l time_input_observe_state(pc),a2
	adda.l #$2d41c,a2
	move.w (sp)+,sr
	rts
	ENDC
