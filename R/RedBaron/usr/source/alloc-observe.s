; Private VERIFY allocation census for completion-plan B1. No player hooks.
; Wrap the KickEmu Exec vectors from program boot through flight step eight.
; Record size, flags (-1 for FreeMem), result/address, largest fast block before
; allocation, caller and flight step. The original Exec operations still run.
ALLOC_LOG_CAPACITY = 8192
ALLOC_LOG_STRIDE = 24
alloc_observe_start:
	movem.l d0-a6,-(sp)
	lea alloc_observe_header(pc),a0
	lea .buffer_base(pc),a1
.buffer_base:
	adda.l #alloc_observe_buffer-.buffer_base,a1
	move.l a1,20(a0)
	move.l $4.w,a6
	move.l a6,24(a0)
	cmpi.w #$4ef9,_LVOAllocMem(a6)
	bne .bad
	cmpi.w #$4ef9,_LVOFreeMem(a6)
	bne .bad
	move.l _LVOAllocMem+2(a6),28(a0)
	move.l _LVOFreeMem+2(a6),32(a0)
	btst #0,observe_attnflags+3(pc)
	beq .ccr_ready
	lea alloc_observe_ccr(pc),a1
	move.w #$42e7,(a1) ; MOVE CCR,-(SP), user-accessible on 010+
.ccr_ready:
	lea alloc_observe_alloc(pc),a1
	move.l a1,_LVOAllocMem+2(a6)
	lea alloc_observe_free(pc),a1
	move.l a1,_LVOFreeMem+2(a6)
	move.l #1,16(a0)
	move.l observe_resload(pc),a2
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
.bad:
	pea alloc_observe_error(pc)
	pea TDREASON_FAILMSG
	move.l observe_resload(pc),a2
	jmp resload_Abort(a2)

alloc_observe_alloc:
	movem.l d2-d4/a2-a3,-(sp)
	move.l d0,-(sp) ; requested size
	move.l d1,-(sp) ; requested flags
	move.l #MEMF_FAST|MEMF_LARGEST,d1
	jsr _LVOAvailMem(a6)
	move.l d0,-(sp) ; available fast block before the allocation
	move.l 4(sp),d1
	move.l 8(sp),d0
	move.l alloc_observe_header+28(pc),a3
	jsr (a3)
alloc_observe_ccr:
	move.w sr,-(sp) ; patched to CCR on 010+
	movem.l d0-d1/a0-a1,-(sp)
	move.l 22(sp),d1
	move.l 26(sp),d2
	move.l 18(sp),d3
	move.l 50(sp),d4
	bsr alloc_observe_record
	movem.l (sp)+,d0-d1/a0-a1
	move.w (sp)+,ccr
	lea 12(sp),sp
	movem.l (sp)+,d2-d4/a2-a3
	rts

alloc_observe_free:
	movem.l d0-d4/a0-a1,-(sp)
	move.l a1,d0
	moveq #-1,d1
	move.l (sp),d2
	moveq #0,d3
	move.l 28(sp),d4
	bsr alloc_observe_record
	movem.l (sp)+,d0-d4/a0-a1
	move.l alloc_observe_header+32(pc),-(sp)
	rts

; d0=address, d1=flags, d2=size, d3=largest fast, d4=caller
alloc_observe_record:
	move.l d5,-(sp)
	lea alloc_observe_header(pc),a0
	move.l 8(a0),d5
	cmpi.l #ALLOC_LOG_CAPACITY,d5
	bhs .overflow
	move.l 20(a0),a1
	mulu #ALLOC_LOG_STRIDE,d5
	adda.l d5,a1
	move.l d2,(a1)
	move.l d1,4(a1)
	move.l d0,8(a1)
	move.l d3,12(a1)
	move.l d4,16(a1)
	move.l tape_game_steps(pc),20(a1)
	addq.l #1,8(a0)
	move.l (sp)+,d5
	rts
.overflow:
	addq.l #1,12(a0)
	move.l (sp)+,d5
	rts

alloc_observe_stop:
	movem.l d0-a6,-(sp)
	move.l tape_game_steps(pc),d0
	cmpi.l #8,d0
	blo .done
	lea alloc_observe_header(pc),a0
	tst.l 16(a0)
	beq .done
	move.l 24(a0),a6
	move.l 28(a0),_LVOAllocMem+2(a6)
	move.l 32(a0),_LVOFreeMem+2(a6)
	clr.l 16(a0)
	move.l observe_resload(pc),a2
	jsr resload_FlushCache(a2)
.done:
	movem.l (sp)+,d0-a6
	rts
alloc_observe_error:
	dc.b "Red Baron allocation census: unexpected Exec vector",0
	even
alloc_observe_header:
	dc.b "RBALLOC1"
	dc.l 0,0,0,0,0,0,0,ALLOC_LOG_CAPACITY,ALLOC_LOG_STRIDE
