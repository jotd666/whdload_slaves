; W4 D1: omit C DMA only when BOTH computed edge masks are all ones.
; The original plane loop, minterms, waits, modulos and pointers remain intact.
fill_install:
	movem.l d0-a6,-(sp)
	move.l #$2fd2c,d0
	moveq #10,d1
	lea fill_expected(pc),a0
	bsr perf_check_bytes
	lea fill_patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
fill_expected: dc.w $383c,$03fa,$41f9,$00df,$f000
fill_patch:
	PL_START
	PL_PSS $2fd2c,fill_setup,4
	PL_END
fill_base:
fill_setup:
	move.w #$03fa,d4
	cmp.l #-1,d7
	bne.b .masked
	move.w #$01fa,d4
.masked
fill_setup_custom:
	lea $dff000,a0
	rts
