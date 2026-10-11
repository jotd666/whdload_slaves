; Private D2 helper twin: stock sim:03d68 vs its exact dt=450 branch model.
; No physics replacement ships. Exercise real straight/banked-flight arguments.
; PERF_RANGE sim:03d68 8 bit=13
time_quantum_twin_install:
	movem.l d0-a6,-(sp)
	move.l perf_attnflags(pc),d0
	andi.l #$8f,d0
	bne .done
	move.l a1,a3
	adda.l #$3d68,a3
	cmpi.l #$48e70300,(a3)
	bne .bad
	cmpi.l #$3e2f000c,4(a3)
	bne .bad
	lea time_quantum_original(pc),a0
	move.l a3,a4
	moveq #40,d0
.copy
	move.w (a4)+,(a0)+
	dbf d0,.copy
	lea time_quantum_original+36(pc),a0
	move.w #time_quantum_multiply-(time_quantum_original+36),(a0)
	move.l a1,d0
	addi.l #$a77e,d0
	lea time_quantum_multiply+2(pc),a0
	move.l d0,(a0)
	lea .patch(pc),a0
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
.patch
	PL_START
	PL_P $3d68,time_quantum_twin
	PL_NOP $3d6e,2
	PL_END

time_quantum_twin:
	move.l a0,-(sp)
	move.l time_quantum_original+10(pc),a0
	cmpi.w #450,(a0)
	move.l (sp)+,a0
	bne time_quantum_original
	move.w sr,-(sp) ; private 68000 proof build only
	movem.l d0-a6,-(sp)
	subq.w #2,sp
	move.w 68(sp),-(sp)
	movem.l 4(sp),d0-a6
	move.w 64(sp),ccr
	bsr time_quantum_original
	addq.w #4,sp
	move.w sr,-(sp)
	movem.l d0-a6,-(sp)
	subq.w #2,sp
	move.w 130(sp),-(sp)
	movem.l 66(sp),d0-a6
	move.w 126(sp),ccr
	bsr time_quantum_450
	addq.w #4,sp
	move.w sr,-(sp)
	movem.l d0-a6,-(sp)
	move.l sp,a0
	lea 62(sp),a1
	moveq #14,d0
.regs
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne .bad
	dbf d0,.regs
	move.w 60(sp),d0
	move.w 122(sp),d1
	eor.w d1,d0
	andi.w #31,d0
	bne .bad
	lea time_quantum_header(pc),a0
	addq.l #1,12(a0)
	lea .keys_base(pc),a1
.keys_base
	adda.l #time_keys_bitmap+$4e-.keys_base,a1
	tst.b (a1)
	beq .straight
	addq.l #1,20(a0)
	bra .restore
.straight
	addq.l #1,16(a0)
.restore
	movem.l 62(sp),d0-a6
	move.w 122(sp),ccr
	lea 186(sp),sp
	rts
.bad
	lea time_quantum_header(pc),a0
	move.l #1,24(a0)
	pea .message(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
.message: dc.b "Red Baron: dt=450 stock-helper twin mismatch",0
	even

time_quantum_450:
	movem.l d6-d7,-(sp)
	move.w 12(sp),d7
	move.l d7,d1
	add.w d7,d1
	move.w d1,d0
	ext.l d0
	cmpi.l #-32767,d0
	bge .done
	move.l #-32767,d0
.done
	tst.l d0
	movem.l (sp)+,d6-d7
	rts
time_quantum_original: dcb.w 41,$4e71
time_quantum_multiply: dc.w $4ef9
	dc.l 0
time_quantum_header: dc.b "RBTQ4501"
	dc.l 1,0,0,0,0
