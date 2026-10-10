; W3 S1 empty volume queue and S9 call to a bare RTS.
; PERF_RANGE sim:34d26 6 bit=10
; PERF_RANGE sim:34e06 6 bit=11
; Only perf_apply_v1 reaches this installer. Sound behavior is unchanged.
sound_sequence_install:
	movem.l d0-a6,-(sp)
	btst #2,perf_mask+2(pc)
	beq .no_queue
	move.l #$34d26,d0
	moveq #6,d1
	lea sound_queue_expected(pc),a0
	bsr perf_check_bytes
	lea sound_queue_base(pc),a0
	move.l a1,d0
	add.l #$33308,d0
	move.l d0,(a0)
	lea sound_queue_resume+2(pc),a0
	move.l a1,d0
	add.l #$34d2c,d0
	move.l d0,(a0)
	IFD VERIFY
	move.l a1,a0
	adda.l #$34d26,a0
	lea sound_queue_original(pc),a3
	moveq #($34d96-$34d26)/2-1,d0
.copy
	move.w (a0)+,(a3)+
	dbf d0,.copy
	ENDC
	lea sound_queue_patch(pc),a0
	jsr resload_Patch(a2)
.no_queue
	move.l 36(sp),a1 ; resload_Patch may clobber a0/a1
	btst #3,perf_mask+2(pc)
	beq .done
	; Check the relocated call destination and the complete no-op callee.
	lea sound_noop_expected+2(pc),a0
	move.l a1,d0
	add.l #$34e54,d0
	move.l d0,(a0)
	move.l #$34e06,d0
	moveq #6,d1
	lea sound_noop_expected(pc),a0
	bsr perf_check_bytes
	move.l #$34e54,d0
	moveq #2,d1
	lea sound_noop_rts(pc),a0
	bsr perf_check_bytes
	lea sound_noop_patch(pc),a0
	jsr resload_Patch(a2)
.done
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
sound_queue_expected: dc.w $48e7,$c020,$3f02
sound_noop_expected: dc.w $4eb9
	dc.l 0
sound_noop_rts: dc.w $4e75
sound_queue_base: dc.l 0
sound_queue_patch:
	PL_START
	PL_P $34d26,sound_queue_entry
	PL_END
sound_noop_patch:
	PL_START
	PL_NOP $34e06,6
	PL_END
sound_queue_entry:
	move.l a2,-(sp)
	move.l sound_queue_base(pc),a2
	cmp.l #-1,(a2)
	bne.b sound_queue_pending
	cmp.l #-1,4(a2)
	bne.b sound_queue_pending
	cmp.l #-1,8(a2)
	bne.b sound_queue_pending
	cmp.l #-1,12(a2)
	bne.b sound_queue_pending
	move.l (sp)+,a2
	IFD VERIFY
	btst #6,perf_custom5+2(pc) ; CUSTOM5 bit 14
	bne sound_queue_twin
	ENDC
sound_queue_return:
	rts
sound_queue_pending
	move.l (sp)+,a2
	; Replay precisely the overwritten prologue, then all original queue code.
	movem.l d0-d1/a2,-(sp)
	move.w d2,-(sp)
sound_queue_resume:
	jmp $12345678

	IFD VERIFY
; Empty-only live twin: original is idempotent, makes no driver calls and writes
; the same index back. No sound hardware is touched twice. Nonempty uses original.
sound_queue_twin:
	movem.l d0-a6,-(sp)
	move.l sound_queue_base(pc),a0
	moveq #0,d0
	move.b $56(a0),d0
	lea sound_queue_verify_index(pc),a1
	move.l d0,(a1)
	movem.l (sp),d0-a6
	bsr sound_queue_original
	movem.l d0-a6,-(sp)
	lea (sp),a0
	lea 60(sp),a1
	moveq #14,d0
.regs
	move.l (a0)+,d1
	cmp.l (a1)+,d1
	bne sound_queue_fail
	dbf d0,.regs
	move.l sound_queue_base(pc),a0
	moveq #0,d0
	move.b $56(a0),d0
	cmp.l sound_queue_verify_index(pc),d0
	bne sound_queue_fail
	moveq #3,d0
.queue
	cmp.l #-1,(a0)+
	bne sound_queue_fail
	dbf d0,.queue
	lea sound_queue_header(pc),a0
	addq.l #1,12(a0)
	move.l sound_queue_verify_index(pc),d0
	move.l 16(a0),d1
	bset d0,d1
	move.l d1,16(a0)
	movem.l (sp)+,d0-a6
	lea 60(sp),sp
	rts
sound_queue_fail:
	pea sound_queue_message(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
sound_queue_message: dc.b "Red Baron: sound queue verification mismatch",0
	even
sound_queue_header: dc.b "RBSQUE01"
	dc.l 1,0,0 ; version, successful twins, starting index mask
sound_queue_verify_index: dc.l 0
sound_queue_original: dcb.b $34d96-$34d26,0
	ENDC
