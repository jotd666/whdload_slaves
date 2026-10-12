; Full-cockpit cache integration boundary, sim v1, developer bit 19, 020+.
; Native rendering keeps its original target and aliases. Only VERIFY stores
; before/after reference pages, so the timing candidate has no full-frame seed
; or fallback copy and allocates no private chip target. The original scene is
; restored before VERIFY composition to detect missing coverage, then the native
; result is restored on rejection/mismatch. The normal mask excludes bit 19.
; PERF_RANGE sim:0080e 6 bit=19
; PERF_RANGE sim:16226 6 bit=19
CS_PAGE_BYTES = 40000
CS_POOL_BYTES = CS_PAGE_BYTES*2

cockpit_stage_install:
 movem.l d0-a6,-(sp)
 lea .cpu(pc),a0
.cpu
 adda.l #perf_attnflags+3-.cpu,a0
 btst #1,(a0)
 beq .done
 move.l a1,a3
 lea cockpit_stage_sim(pc),a0
 move.l a3,(a0)
 bsr cockpit_static_invalidate
 move.l a3,a0
 adda.l #$301b2,a0
 move.l (a0),d0
 subi.l #$9a2c,d0
 lea cockpit_stage_h3(pc),a0
 move.l d0,(a0)
 addi.l #$6712,d0
 lea cockpit_stage_begin_bytes+2(pc),a0
 move.l d0,(a0)
 lea cockpit_stage_begin_original+2(pc),a0
 move.l d0,(a0)
 IFND VERIFY
 lea cockpit_stage_cached_original+2(pc),a0
 move.l d0,(a0)
 ENDC
 move.l cockpit_stage_h3(pc),d0
 addi.l #$8da0,d0
 lea cockpit_stage_end_bytes+2(pc),a0
 move.l d0,(a0)
 lea cockpit_stage_end_original+2(pc),a0
 move.l d0,(a0)
 lea .check(pc),a6
.check
 adda.l #perf_check_bytes-.check,a6
 move.l #$80e,d0
 moveq #6,d1
 lea cockpit_stage_begin_bytes(pc),a0
 jsr (a6)
 move.l #$16226,d0
 moveq #6,d1
 lea cockpit_stage_end_bytes(pc),a0
 jsr (a6)
 move.l a3,d0
 addi.l #$814,d0
 lea cockpit_stage_begin_tail+2(pc),a0
 move.l d0,(a0)
 IFND VERIFY
 move.l a3,d0
 addi.l #$81a,d0
 lea cockpit_stage_cached_tail+2(pc),a0
 move.l d0,(a0)
 ENDC
 move.l a3,d0
 addi.l #$1622c,d0
 lea cockpit_stage_end_tail+2(pc),a0
 move.l d0,(a0)
 move.l a3,a1
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 jsr resload_FlushCache(a2)
.done
 movem.l (sp)+,d0-a6
 rts
.patch
 PL_START
 PL_P $80e,cockpit_stage_begin
 PL_P $16226,cockpit_stage_end
 PL_END
cockpit_stage_begin_bytes: dc.w $4a79
 dc.l 0
cockpit_stage_end_bytes: dc.w $4a79
 dc.l 0

cockpit_stage_begin:
 dc.w $42e7 ; MOVE CCR,-(SP), 020+ hook preserves X across the replaced TST
 movem.l d0-a6,-(sp)
 lea cockpit_stage_active(pc),a5
 clr.l (a5)
 bsr cockpit_final_reset
 move.l cockpit_stage_h3(pc),a4
 adda.l #$8000,a4
 tst.w -$18ee(a4) ; h3:6712 view
 bne cockpit_stage_begin_done
 ; sim:19bb2 runs the event-only dashboard script before the seven gauges.
 ; It changes pixels outside the steady overlay/gauge/foreground coverage.
 ; Let that refresh finish on the real page; never publish a partial cache.
 tst.b -$ee4(a4) ; h3:711c native dashboard redraw count
 bne cockpit_stage_begin_done
 cmpi.l #8000,$1d34(a4)
 bne cockpit_stage_begin_done
 cmpi.w #5,$1d3c(a4)
 bne cockpit_stage_begin_done
 cmpi.w #320,$1d40(a4)
 bne cockpit_stage_begin_done
 cmpi.w #40,$1d42(a4)
 bne cockpit_stage_begin_done
 cmpi.w #200,$1d44(a4)
 bne cockpit_stage_begin_done
 ; Require the same native target at both renderer entry points.
 move.l $1d6a(a4),d0
 beq cockpit_stage_begin_done
 cmp.l $1d72(a4),d0
 bne cockpit_stage_begin_done
 btst #0,d0
 bne cockpit_stage_begin_done
 moveq #0,d1
 move.b -$ee3(a4),d1 ; h3:711d, page BEFORE native dispatcher toggles it
 cmpi.w #1,d1
 bhi cockpit_stage_begin_done
 lea cockpit_stage_page(pc),a0
 move.w d1,(a0) ; save before the native gauge dispatcher toggles it
 IFD VERIFY
 bsr cockpit_stage_allocate
 move.l cockpit_stage_pool(pc),d1
 beq cockpit_stage_begin_done
 ENDC
 move.l d0,(a5) ; native target throughout the stage
 move.l d0,4(a5)
 bsr cockpit_stage_wait
 bsr cockpit_static_prepare
 IFND VERIFY
 ; Gauges consume the static pixels. Materialize the cached image here in
 ; native order, then bypass only the original sim:00816 blitter call.
 move.l cockpit_static_layer(pc),d0
 beq cockpit_stage_begin_done
 move.l d0,a0
 move.l cockpit_static_layer+4(pc),a1
 move.l (a5),a2
 moveq #20,d0
 move.w #200,d1
 bsr cf_overlay_fast
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
cockpit_stage_cached_original:
 tst.w $0.l
cockpit_stage_cached_tail:
 jmp $0.l
 ENDC
 IFD VERIFY
 move.l (a5),a0
 move.l cockpit_stage_pool(pc),a1
 bsr cockpit_stage_copy ; save scene only for the exact-output checker
 lea cockpit_stage_counts(pc),a0
 addq.l #1,(a0)
 ENDC
cockpit_stage_begin_done
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
cockpit_stage_begin_original:
 tst.w $0.l
cockpit_stage_begin_tail:
 jmp $0.l

cockpit_stage_end:
 dc.w $42e7 ; MOVE CCR,-(SP), only installed on 020+
 movem.l d0-a6,-(sp)
 lea cockpit_stage_active(pc),a5
 tst.l (a5)
 beq .done
 bsr cockpit_stage_wait
 IFD VERIFY
 move.l (a5),a0
 move.l cockpit_stage_pool(pc),a1
 adda.l #CS_PAGE_BYTES,a1
 bsr cockpit_stage_copy ; independent native reference, before publication
 move.l cockpit_stage_pool(pc),a0
 move.l (a5),a1
 bsr cockpit_stage_copy ; checker publishes onto the original scene
 ENDC
 bsr cockpit_final_publish
 tst.l d0
 bne .published
 IFD VERIFY
 move.l cockpit_stage_pool(pc),a0
 adda.l #CS_PAGE_BYTES,a0
 move.l (a5),a1
 bsr cockpit_stage_copy
 ELSE
 ; All other native draws already reached the real target. If composition
 ; rejected, publish the one deferred foreground hit in its original order.
 bsr cockpit_foreground_fallback
 ENDC
.published
 clr.l (a5)
 IFD VERIFY
 lea cockpit_stage_counts(pc),a0
 addq.l #1,4(a0)
 ENDC
.done
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
cockpit_stage_end_original:
 tst.w $0.l
cockpit_stage_end_tail:
 jmp $0.l

 IFD VERIFY
cockpit_stage_allocate:
 movem.l d0-d1/a0-a1/a6,-(sp)
 lea cockpit_stage_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 move.l #CS_POOL_BYTES,d0
 move.l #$10002,d1 ; cleared CHIP reference storage: preserves the existing VERIFY RAM budget
 jsr _LVOAllocMem(a6)
 lea cockpit_stage_pool(pc),a0
 move.l d0,(a0)
.done
 movem.l (sp)+,d0-d1/a0-a1/a6
 rts

cockpit_stage_copy:
 move.w #CS_PAGE_BYTES/4-1,d2
.copy
 move.l (a0)+,(a1)+
 dbf d2,.copy
 rts

 ENDC

cockpit_stage_wait:
 tst.w $dff002
.wait
 btst #6,$dff002
 bne .wait
 rts

cockpit_stage_sim: dc.l 0
cockpit_stage_h3: dc.l 0
cockpit_stage_active: dc.l 0,0 ; active native target, publication target
cockpit_stage_page: dc.w 0
 IFD VERIFY
cockpit_stage_pool: dc.l 0 ; scene and native result, checker-only
cockpit_stage_attempted: dc.w 0
cockpit_stage_counts: dc.l 0,0 ; accepted entries, completed exits
 ENDC
