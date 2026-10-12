; Full-cockpit cache integration boundary, sim v1, developer bit 19, 020+.
; The native static overlay, gauges and picture scripts share a private chip
; target; restore native aliases BEFORE the sector-coordinate text. A source
; alias that names the target must follow it, preserving native read-after-write.
; Separate targets follow the game's two gauge-history pages. No displayed
; bitmap is repointed, and the 3D renderer keeps its original destination.
;
; Development path: seeds a native reference target, then publishes accepted
; layers with one masked copy; unavailable/VERIFY-mismatching layers copy the
; complete native reference. Redundant drawing/seeding must go before FPS acceptance. The normal verified mask deliberately excludes this bit.
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
 bne .done
 ; sim:19bb2 runs the event-only dashboard script before the seven gauges.
 ; It changes pixels outside the steady overlay/gauge/foreground coverage.
 ; Let that refresh finish on the real page; never publish a partial cache.
 tst.b -$ee4(a4) ; h3:711c native dashboard redraw count
 bne .done
 cmpi.l #8000,$1d34(a4)
 bne .done
 cmpi.w #5,$1d3c(a4)
 bne .done
 cmpi.w #320,$1d40(a4)
 bne .done
 cmpi.w #40,$1d42(a4)
 bne .done
 cmpi.w #200,$1d44(a4)
 bne .done
 ; Do not redirect a stage whose two native aliases disagree.
 move.l $1d6a(a4),d0
 beq .done
 cmp.l $1d72(a4),d0
 bne .done
 btst #0,d0
 bne .done
 moveq #0,d1
 move.b -$ee3(a4),d1 ; h3:711d, page BEFORE native dispatcher toggles it
 cmpi.w #1,d1
 bhi .done
 move.w d1,-(sp)
 bsr cockpit_stage_allocate
 move.w (sp)+,d1
 move.l cockpit_stage_pool(pc),d0
 beq .done
 tst.w d1
 beq .page
 addi.l #CS_PAGE_BYTES,d0
.page
 move.l d0,(a5) ; active scratch page; independent of later page toggle
 move.l $1d6a(a4),d1
 move.l d1,4(a5) ; equal native aliases, restored together at stage end
 bsr cockpit_stage_wait
 bsr cockpit_static_prepare
 move.l d1,a0
 move.l d0,a1
 bsr cockpit_stage_copy
 ; h3:9d6e feeds native source-to-destination primitives (sim:2e4ba).
 ; Preserve a genuinely separate source, but do not leave a target alias
 ; pointing at the old public page while native writes go to the private one.
 move.l 4(a5),d0
 cmp.l $1d6e(a4),d0
 bne .source_ready
 move.l (a5),$1d6e(a4)
.source_ready
 move.l (a5),$1d6a(a4)
 move.l (a5),$1d72(a4)
 IFD VERIFY
 lea cockpit_stage_counts(pc),a0
 addq.l #1,(a0)
 ENDC
.done
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
 bsr cockpit_final_publish
 tst.l d0
 bne .published
 move.l (a5),a0
 move.l 4(a5),a1
 bsr cockpit_stage_copy
.published
 move.l cockpit_stage_h3(pc),a4
 adda.l #$8000,a4
 ; Native helpers may replace the source during the stage. Translate only
 ; a reference to our private page; retain other intentional source changes.
 move.l (a5),d0
 cmp.l $1d6e(a4),d0
 bne .source_restored
 move.l 4(a5),$1d6e(a4)
.source_restored
 move.l 4(a5),$1d6a(a4)
 move.l 4(a5),$1d72(a4)
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

cockpit_stage_allocate:
 movem.l d0-d1/a0-a1/a6,-(sp)
 lea cockpit_stage_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 move.l #CS_POOL_BYTES,d0
 move.l #$10002,d1 ; cleared MEMF_CHIP: native renderer uses blitter DMA
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

cockpit_stage_wait:
 tst.w $dff002
.wait
 btst #6,$dff002
 bne .wait
 rts

cockpit_stage_sim: dc.l 0
cockpit_stage_h3: dc.l 0
cockpit_stage_pool: dc.l 0
cockpit_stage_active: dc.l 0,0 ; private page, original native target
cockpit_stage_attempted: dc.w 0
 IFD VERIFY
cockpit_stage_counts: dc.l 0,0 ; redirected entries, restored exits
 ENDC
