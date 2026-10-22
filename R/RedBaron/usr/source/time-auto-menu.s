; fixed-step timing automatic mission-menu service. Original eligibility/countdown/menu
; code stays in sim; a zero command packet prevents replay of manual commands.

time_auto_install:
	movem.l d0-a6,-(sp)
	move.l #$21b14,d0
	moveq #8,d1
	lea .expected(pc),a0
	bsr perf_check_bytes
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.expected: dc.w $48e7,$0710,$266f,$0014
.patch:
	PL_START
	PL_P $21b14,time_auto_dispatch
	PL_END

time_auto_reset:
	move.l a0,-(sp)
	lea time_auto_sampling(pc),a0
	clr.l (a0)+ ; sampling / pending native exit result
	move.l (sp)+,a0
	rts

; PL_P replaces exactly the original prologue. Only automatic-service calls
; execute its prefix under timing ownership; manual world commands start at
; sim:21bbc. The native MOVEM/argument layout is identical on either path.
time_auto_dispatch:
	movem.l d0/a0,-(sp)
	bsr time_devices_owned
	beq .original
	lea time_auto_sampling(pc),a0
	tst.w (a0)
	bne .service
	movem.l (sp)+,d0/a0
	movem.l d5-d7/a3,-(sp)
	move.l 20(sp),a3
	move.l time_loop_sim(pc),-(sp)
	addi.l #$21bbc,(sp)
	rts
.service

.original
	movem.l (sp)+,d0/a0
	movem.l d5-d7/a3,-(sp)
	move.l 20(sp),a3
	move.l time_loop_sim(pc),-(sp)
	addi.l #$21b1c,(sp)
	rts

; d1 is the number of 128-unit service ticks just funded (zero or one).
; Preserve every register, including the world's due result. The native
; pause wrappers exclude time spent in any automatic menu.
time_auto_advance:
	movem.l d0-a6,-(sp)
	tst.w d1
	beq time_auto_done
	bsr time_devices_owned
	beq time_auto_done
	lea time_auto_sampling(pc),a0
	tst.w 2(a0)
	bne time_auto_done ; pending mission exit: never open another menu
	move.w #1,(a0)
	move.l time_loop_h3(pc),a3
	move.w $4836(a3),-(sp)
	move.w #128,$4836(a3)
	move.l time_loop_state+TIME_LOOP_PAUSED(pc),d7
	pea time_auto_input(pc)
	move.l time_loop_sim(pc),a0
	adda.l #$21b14,a0
	jsr (a0)
	addq.l #4,sp
	move.w (sp)+,$4836(a3)
	lea time_auto_sampling(pc),a0
	clr.w (a0)
.result
	cmpi.w #4,d0
	beq time_auto_observe
	cmpi.w #2,d0
	beq .exit
	cmpi.w #3,d0
	bne time_auto_bad
.exit
	move.w d0,2(a0)
time_auto_observe:
	nop
time_auto_done:
	movem.l (sp)+,d0-a6
	rts

time_auto_bad:
	pea time_auto_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
time_auto_error: dc.b "Red Baron: W6 unexpected automatic menu result",0
	even
time_auto_sampling: dc.w 0
time_auto_exit: dc.w 0
time_auto_input: dcb.b 14,0

; Fixture uses CPU stores, never debugger writes to cacheable game RAM.
; Two real 128-unit decrements must pass through zero before expiry. Repeat
; once after cancellation to exercise the native mission-exit result mapping.
; Called by the existing pause wrapper. Ordinary runs call the real menu.
; Fixture returns cancel-like 0, then native choice 5 (mission exit), while
; still exercising real pause begin/end and original menu-result conversion.
time_auto_menu_call:
.native
	move.l time_loop_sim(pc),-(sp)
	addi.l #$1f0d2,(sp)
	rts
