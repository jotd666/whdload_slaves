; B2: enable instruction caching on 020+ without enabling a disabled data cache.
; KickEmu CACHE marks BaseMem noncacheable. Without an MMU that disables both
; caches globally. If DC is already enabled, preserve the entire memory policy.
; Otherwise request cacheable instructions and explicitly leave DC disabled.
cpu_cache_install_v1:
	movem.l d0-a6,-(sp)
	btst #1,perf_mask+1(pc) ; bit 17
	beq .done
	btst #1,perf_attnflags+3(pc) ; AFF_68020 (also set on later CPUs)
	beq .done
	move.l $4.w,a6
	lea cpu_cache_read(pc),a5
	jsr _LVOSupervisor(a6)
	move.l #WCPUF_IC,d2
	move.l #WCPUF_IC,d3
	move.l perf_attnflags(pc),d1
	and.l #$88,d1 ; 040/060: data-cache enable is CACR bit 31
	beq .early
	btst #15,d0
	bne .done
	tst.l d0
	bmi .apply
	bra .instructions_only
.early:
	btst #0,d0
	bne .done
	btst #8,d0 ; 030 data-cache enable; always clear on 020
	bne .apply
.instructions_only:
	or.l #WCPUF_Base_WT,d2
	or.l #WCPUF_Base|WCPUF_DC,d3
.apply:
	move.l d2,d0
	move.l d3,d1
	move.l _resload(pc),a2
	jsr resload_SetCPU(a2)
.done:
	movem.l (sp)+,d0-a6
	rts
cpu_cache_read:
	dc.w $4e7a,$0002 ; MOVEC CACR,D0, executed only on 020+
	rte
