; W6 presentation projection-cache ownership. VERIFY bit 13, sim v1 only.
; PERF_RANGE sim:0056c 8 bit=13
; PERF_RANGE sim:00b16 8 bit=13
; PERF_RANGE sim:2c55a 12 bit=13
TIME_PRESENT_CACHE_CAPACITY = 512
TIME_PRESENT_CACHE_STRIDE = 28

time_present_state_install:
	movem.l d0-a6,-(sp)
	lea .checks(pc),a3
	moveq #2,d7
.check
	move.l (a3)+,d0
	move.w (a3)+,d1
	move.l a3,a0
	bsr perf_check_bytes
	adda.w d1,a3
	dbf d7,.check
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.checks:
	dc.l $56c
	dc.w 8,$4e55,$fffc,$48e7,$3b00
	dc.l $b16
	dc.w 8,$4cdf,$00dc,$4e5d,$4e75
	dc.l $2c55a
	dc.w 12,$266d,$0008,$246d,$000c,$3e2d,$0010
.patch:
	PL_START
	PL_P $56c,time_present_begin
	PL_P $b16,time_present_end
	PL_PSS $2c55a,time_present_capture,6
	PL_END

; PL_P: no extra return word. Reconstruct the native prologue before entering
; sim:00574. The full outer draw, including HUD consumers, owns these caches.
time_present_begin:
	movem.l d0-a6,-(sp)
	lea time_present_active(pc),a1
	tst.w (a1)
	bne time_present_state_bad ; no silently overwritten nested owner
	clr.w 2(a1)
	bsr time_devices_owned
	beq .ready
	move.w #1,(a1)
.ready
	move.l time_loop_sim(pc),d0
	addi.l #$574,d0
	lea time_present_resume(pc),a0
	move.l d0,(a0)
	movem.l (sp)+,d0-a6
	link a5,#-4
	movem.l d2-d4/d6-d7,-(sp)
	move.l time_present_resume(pc),-(sp)
	rts

; Entry has original LINK/MOVEM frame. Replay displaced argument loads.
time_present_capture:
	move.l 8(a5),a3
	move.l 12(a5),a2
	move.w 16(a5),d7
	movem.l d0-a6,-(sp)
	lea time_present_active(pc),a4
	tst.w (a4)
	beq .done
	tst.w 2(a4)
	bne time_present_state_bad ; only one 3D pass per native outer draw
	tst.w d7
	bmi time_present_state_bad
	cmpi.w #TIME_PRESENT_CACHE_CAPACITY,d7
	bhi time_present_state_bad
	lea .buffer_base(pc),a1
.buffer_base
	adda.l #time_present_cache_buffer-.buffer_base,a1
	move.w d7,d6
	beq .done
	subq.w #1,d6
.next
	move.l (a2)+,a0
	btst #6,(a0) ; compact objects have a different, shorter layout
	bne .skip
	btst #3,(a0)
	beq .skip
	move.l a0,(a1)+
	move.b (a0),(a1)+
	clr.b (a1)+
	move.l 26(a0),(a1)+
	lea 34(a0),a0
	moveq #8,d5
.copy
	move.w (a0)+,(a1)+
	dbf d5,.copy
	addq.w #1,2(a4)
.skip
	dbf d6,.next
.done
	movem.l (sp)+,d0-a6
	rts

; Restore only named object fields, never clocks, IRQ state, framebuffers or
; h3 wholesale. Return value d0 and every native saved register are retained.
time_present_end:
	movem.l d0-a6,-(sp)
	lea time_present_active(pc),a4
	tst.w (a4)
	beq time_present_end_done
	lea .buffer_base(pc),a1
.buffer_base
	adda.l #time_present_cache_buffer-.buffer_base,a1
	move.w 2(a4),d6
	beq .clear
	subq.w #1,d6
.next
	move.l (a1)+,a0
	move.b (a1)+,(a0)
	addq.l #1,a1
	move.l (a1)+,26(a0)
	lea 34(a0),a0
	moveq #8,d5
.copy
	move.w (a1)+,(a0)+
	dbf d5,.copy
	dbf d6,.next
.clear
	clr.l (a4)
time_present_restored:
	nop
time_present_end_done:
	movem.l (sp)+,d0-a6
	tst.l d0 ; match native MOVEQ return NZVC
	movem.l (sp)+,d2-d4/d6-d7
	unlk a5
	rts

time_present_state_bad:
	pea time_present_state_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_present_state_error: dc.b "Red Baron: W6 nested draw or invalid object count",0
	even
time_present_active: dc.w 0,0 ; active, saved cache count
time_present_resume: dc.l 0
