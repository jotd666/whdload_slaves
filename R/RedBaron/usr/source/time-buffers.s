; Session-owned Fast RAM. Allocate before installing any consumer/IRQ hook.
; Reuse across mission loads: outstanding hooks must never see freed storage.
; KickEmu/WHDLoad reclaims the allocations at slave exit. Failure aborts before
; a consumer can use missing storage, without changing the selected timing.
TIME_CACHE_BYTES = TIME_PRESENT_CACHE_CAPACITY*TIME_PRESENT_CACHE_STRIDE
TIME_MODEL_BYTES = TIME_MODEL_CAPACITY*TIME_MODEL_STRIDE
TIME_LIST_BYTES = 500*4
TIME_LIST_ALLOC = TIME_LIST_BYTES
TIME_PRESENT_BYTES = TIME_CACHE_BYTES+TIME_MODEL_BYTES+TIME_LIST_ALLOC
TIME_POSE_BYTES = TIME_POSE_CAPACITY*TIME_POSE_STRIDE

; Reserve before the game takes its heap, before any rendering allocations.
time_buffers_prepare:
	btst #5,perf_mask+2(pc)
	beq .no_w6
	bsr time_buffers_allocate
	bra time_input_allocate
.no_w6:
	rts

time_buffers_allocate:
	movem.l d0-a6,-(sp)
	lea .present(pc),a0
.present
	adda.l #time_present_cache_buffer_ptr-.present,a0
	move.l #TIME_PRESENT_BYTES,d0
	bsr time_buffer_allocate
	move.l (a0)+,d0
	addi.l #TIME_CACHE_BYTES,d0
	move.l d0,(a0)+ ; model journal
	addi.l #TIME_MODEL_BYTES,d0
	move.l d0,(a0)+ ; registration list
	move.l perf_attnflags(pc),d0
	andi.l #$8e,d0 ; 020/030/040/060, no interpolation on 000
	beq .done
	move.l #TIME_POSE_BYTES*3,d0
	bsr time_buffer_allocate
	move.l (a0)+,d0
	addi.l #TIME_POSE_BYTES,d0
	move.l d0,(a0)+ ; previous poses
	addi.l #TIME_POSE_BYTES,d0
	move.l d0,(a0) ; interpolation output
.done:
	movem.l (sp)+,d0-a6
	rts

time_input_allocate:
	movem.l d0-a6,-(sp)
	lea .queue(pc),a0
.queue
	adda.l #time_input_observe_queue_ptr-.queue,a0
	move.l #TIME_INPUT_BYTES,d0
	bsr time_buffer_allocate
	movem.l (sp)+,d0-a6
	rts

; a0 = pointer cell, d0 = size; preserve a0 across Exec's volatile registers.
time_buffer_allocate:
	tst.l (a0)
	bne .done
	movem.l a0-a1,-(sp)
	move.l $4.w,a6
	move.l #MEMF_FAST+MEMF_CLEAR,d1
	jsr _LVOAllocMem(a6)
	movem.l (sp)+,a0-a1
	move.l d0,(a0)
	beq .failed
.done:
	rts
.failed:
	pea .error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
.error:
	dc.b "Red Baron: insufficient Fast RAM for Consistent game speed",0
	even
