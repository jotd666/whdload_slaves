; B1 reserves the extra declared memory until sim v1 is identified and bit 16
; is selected. Off and other versions retain the original allocation budget.
; The header must reserve the larger block before the loader knows the version.
PERF_EXTRA_FAST = $30000
PERF_WORKSPACE_FAST = $50000
memory_reserve:
	movem.l d0-a6,-(sp)
	move.l $4.w,a6
	move.l #PERF_EXTRA_FAST+PERF_WORKSPACE_FAST,d0
	moveq #MEMF_FAST,d1
	jsr _LVOAllocMem(a6)
	lea memory_reserved(pc),a0
	move.l d0,(a0)
	beq .failed
	addi.l #PERF_EXTRA_FAST,d0
	lea memory_workspace_reserved(pc),a0
	move.l d0,(a0)
	movem.l (sp)+,d0-a6
	rts
.failed:
	pea memory_error(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)

memory_install_v1:
	movem.l d0-a6,-(sp)
	btst #0,perf_mask+1(pc) ; bit 16
	beq .done
	; Known 000 and 020/030/040/060 classes; retain the old pool on untested 010.
	move.l perf_attnflags(pc),d0
	and.l #$8e,d0
	bne .supported
	btst #0,perf_attnflags+3(pc)
	bne .done
.supported:
	lea memory_reserved(pc),a0
	move.l (a0),d0
	beq .done
	clr.l (a0)
	move.l d0,a1
	move.l #PERF_EXTRA_FAST,d0
	move.l $4.w,a6
	jsr _LVOFreeMem(a6)
	; Keep the approved spare workspace reserved. The complete cockpit cache
	; was dropped after regressions on every affected CPU class. CUSTOM2=0
	; therefore still retains the original game's allocation budget.
.done:
	movem.l (sp)+,d0-a6
	rts
memory_reserved: dc.l 0
memory_workspace_reserved: dc.l 0
memory_error:
	dc.b "Red Baron: insufficient memory for the original allocation budget",0
	even
