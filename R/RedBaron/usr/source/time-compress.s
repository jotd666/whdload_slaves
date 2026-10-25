; fixed-step timing compression timing ownership, CUSTOM2 bit 13, sim v1 only.
;
; The native command/situation dispatcher owns h3:045a6. It runs on world
; ticks, never in an IRQ or render-only pass. Poll samples it only when funding
; the next CIA boundary; already-funded same-boundary ticks retain their credit.
time_compress_install:
	movem.l d0-a6,-(sp)
	move.l a1,a0
	adda.l #$eca,a0
	cmpi.w #$4a79,(a0)
	bne .bad
	move.l time_loop_h3(pc),d0
	addi.l #$45a6,d0
	cmp.l 2(a0),d0
	bne .bad
	move.l #$21dae,d0
	moveq #8,d1
	lea .bytes(pc),a0
	bsr perf_check_bytes
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.bad
	pea time_loop_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
.bytes: dc.w $3b40,$ffd0,$3b41,$ffd2
.patch:
	PL_START
	PL_PS $eca,time_compress_clock
	PL_PSS $21dae,time_compress_selector,2
	PL_END

; Skip only the historical elapsed=500 clock overwrite. Continue at sim:00ee0
; so the original compression notification API still executes. Outside flight
; ownership reproduce TST, including CCR, and use the original branch.
time_compress_clock:
	move.l a0,-(sp)
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_ACTIVE(a0)
	beq .original
	add.l #16,4(sp) ; patch return sim:00ed0 -> sim:00ee0
	move.l (sp)+,a0
	rts
.original
	move.l time_loop_h3(pc),a0
	tst.w $45a6(a0)
	move.l (sp)+,a0
	rts

; Native compression suppresses controls and seven of eight draw opportunities
; through this local selector. fixed-step timing uses its debt-aware draw gate instead. Retain
; the cycle budget local and the flags of the second displaced MOVE.
time_compress_selector:
	move.l a0,-(sp)
	lea time_loop_state(pc),a0
	tst.l TIME_LOOP_ACTIVE(a0)
	beq .original
	moveq #0,d0
.original
	move.l (sp)+,a0
	move.w d0,-48(a5)
	move.w d1,-46(a5)
	rts
