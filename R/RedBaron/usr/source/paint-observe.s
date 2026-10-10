; VERIFY CUSTOM5 bit 3: diagnostic swap/first solid-fill log, not a speed patch.
; Record the first solid fill into the former display after each publication.
; Other primitives still require the DMA ownership check: this is not a universal
; first-write detector. Use trace evidence to establish coverage for each window.
PAINT_STRIDE = 40
PAINT_CAPACITY = 256
paint_install:
	movem.l d0-a6,-(sp)
	move.l tape_game_steps(pc),d0
	cmpi.l #1,d0
	bne.w .done
	btst #3,perf_custom5+3(pc)
	beq.w .done
	lea paint_header(pc),a0
	lea paint_buffer(pc),a1
	move.l a1,24(a0)
; Query WHDLoad's configured cache/memory policy without changing any policy bits.
; SetCPU flushes caches even with mask zero. This happens once at flight entry,
; only in this diagnostic mode, and must be recorded with the capture conditions.
	moveq #0,d0
	moveq #0,d1
	move.l observe_resload(pc),a2
	jsr resload_SetCPU(a2)
	lea paint_header(pc),a0
	move.l d0,28(a0)
; Read the actual control register through Exec's supported supervisor trampoline.
; MOVEC is never executed on 68000/010; the policy above alone is not raw CACR.
	btst #1,perf_attnflags+3(pc)
	beq.s .no_cacr
	move.l $4.w,a6
	lea paint_read_cacr(pc),a5
	jsr _LVOSupervisor(a6)
	lea paint_header(pc),a0
	move.l d0,56(a0)
	move.l #1,60(a0)
.no_cacr:
	move.l tape_marker+24(pc),a1
	move.l #$3154a,d0
	moveq #8,d1
	lea .swap_bytes(pc),a0
	bsr perf_check_bytes
	move.l #$2fd8a,d0
	moveq #8,d1
	lea .fill_bytes(pc),a0
	bsr perf_check_bytes
; MOVE from SR is user-accessible only on 68000. On 68010+ save CCR instead;
; MOVE to CCR is unprivileged on all supported CPUs. Patch before FlushCache.
	btst #0,perf_attnflags+3(pc)
	beq.s .ccr_ready
	lea paint_swap_ccr(pc),a0
	move.w #$42e7,(a0)
	lea paint_fill_ccr(pc),a0
	move.w #$42e7,(a0)
.ccr_ready:
	lea paint_patches(pc),a0
	jsr resload_Patch(a2)
.done:
	movem.l (sp)+,d0-a6
	rts
.swap_bytes: dc.w $48d0,$7efc,$4cdf,$7cfc
.fill_bytes: dc.w $2141,$0054,$3143,$0058

paint_read_cacr:
	dc.w $4e7a,$0002 ; movec cacr,d0 (68020+, supervisor mode only)
	rte

paint_patches:
	PL_START
; VERIFY_RANGE sim:3154a 8: publication MOVEM and restoring MOVEM, whole instructions.
	PL_P $3154a,paint_swap
	PL_NOP $31550,2
; VERIFY_RANGE sim:2fd8a 8: destination pointer and BLTSIZE writes.
	PL_PSS $2fd8a,paint_fill,2
	PL_END

paint_swap:
	movem.l d2-d7/a1-a6,(a0)
paint_swap_ccr: dc.w $40e7
	movem.l d0-d2/a0-a2,-(sp)
	lea paint_header(pc),a2
	tst.l 32(a2)
	beq.s .new
	addq.l #1,36(a2)
.new:
	move.l #1,32(a2)
	move.l observe_vbl_count(pc),d0
	move.l d0,40(a2)
	move.l $dff004,44(a2)
	move.l observe_header+28(pc),a0
	adda.l #$9d66,a0
	move.l (a0)+,48(a2)
	move.l (a0),52(a2)
	movem.l (sp)+,d0-d2/a0-a2
	move.w (sp)+,ccr
	movem.l (sp)+,d2-d7/a2-a6
	rts

paint_fill:
paint_fill_ccr: dc.w $40e7
	movem.l d0-d2/a0-a2,-(sp)
	lea paint_header(pc),a2
	tst.l 32(a2)
	beq.w .done
	move.l d1,d0
	sub.l 52(a2),d0
	bcs.w .done
	cmpi.l #40000,d0
	bhs.w .done
	move.l 20(a2),d0
	andi.l #PAINT_CAPACITY-1,d0
	mulu.w #PAINT_STRIDE,d0
	move.l 24(a2),a1
	adda.l d0,a1
	move.l tape_game_steps(pc),(a1)+
	move.l 40(a2),(a1)+
	move.l 44(a2),(a1)+
	move.l observe_vbl_count(pc),(a1)+
	move.l $dff004,(a1)+
	move.l d1,(a1)+
	move.l 52(a2),(a1)+
	move.l 48(a2),(a1)+
	move.w d3,(a1)+
	clr.w (a1)+
	move.l tape_marker+24(pc),a0
	adda.l #$30006,a0
	move.l (a0),(a1)+
	clr.l 32(a2)
	addq.l #1,20(a2)
.done:
	movem.l (sp)+,d0-d2/a0-a2
	move.w (sp)+,ccr
	move.l d1,$54(a0)
	move.w d3,$58(a0)
	rts
	CNOP 0,4
; Header: signature, version/stride/capacity/count/buffer/cache-policy,
; pending/missed/swapped-VBlank/swapped-beam/new-display/old-display/raw-CACR/valid.
paint_header:
	dc.b "RBPAINT1"
	dc.l 2,PAINT_STRIDE,PAINT_CAPACITY,0,0,0,0,0,0,0,0,0,0,0
paint_buffer:
	dcb.b PAINT_STRIDE*PAINT_CAPACITY,0
