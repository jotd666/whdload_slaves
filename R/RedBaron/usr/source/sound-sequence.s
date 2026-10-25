; sound S1 empty volume queue and S9 call to a bare RTS.
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
	lea sound_queue_patch(pc),a0
	bsr sound_install_patch
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
	bsr sound_install_patch
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
sound_queue_return:
	rts
sound_queue_pending
	move.l (sp)+,a2
	; Replay precisely the overwritten prologue, then all original queue code.
	movem.l d0-d1/a2,-(sp)
	move.w d2,-(sp)
sound_queue_resume:
	jmp $12345678
