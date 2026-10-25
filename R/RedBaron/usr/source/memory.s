; B1 reserves the extra declared memory until sim v1 is identified and bit 16
; is selected. Off and other versions retain the original allocation budget.
; The header must reserve the larger block before the loader knows the version.
PERF_EXTRA_FAST = $30000
; Runtime workspace: artwork, scene/scratch and polygon rows.
PERF_WORKSPACE_FAST = (PERF_SCENE_OFFSET+15+PERF_SCENE_SPAN_ROWS+800+7)&-8
; Artwork occupies the first $20000 bytes.
PERF_SCENE_OFFSET = $20000
; Keep clipped top-left sprite reads inside owned Fast RAM; preserve mod-16
; alignment for MOVE16. Fits the existing gap before the polygon row table.
PERF_SCENE_PREFIX = 16
; polygon spans row extents occupy the gap after the aligned scene + scratch.
PERF_SCENE_SPAN_ROWS = 48032
 IFGT PERF_SCENE_PREFIX+48000+15-PERF_SCENE_SPAN_ROWS
 FAIL "Scene buffers overlap polygon row extents"
 ENDC
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
	; Keep the approved renderer workspace reserved. Sparse artwork uses
	; its first two 64 KiB regions on 030+. The player Off selection still
	; retains the original game allocation budget.
.done:
	movem.l (sp)+,d0-a6
	rts
memory_reserved: dc.l 0
memory_workspace_reserved: dc.l 0
memory_error:
	dc.b "Red Baron: insufficient memory for the original allocation budget",0
	even
