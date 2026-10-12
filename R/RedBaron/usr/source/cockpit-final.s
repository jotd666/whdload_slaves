; Complete ordered layer publication, reached only from bit-19/020+ stage.
; Required layers: native static artwork, seven current-page gauges, foreground.
; Until acceptance this remains a development candidate. Native drawing into
; the private page is retained as fallback and VERIFY's exact-output reference.
; One CPU masked copy publishes the combined cockpit to the original target.
cockpit_final_reset:
 move.l a0,-(sp)
 lea cockpit_gauge_seen_bits(pc),a0
 clr.w (a0)
 lea cockpit_foreground_layer(pc),a0
 clr.l (a0)+
 clr.l (a0)
 move.l (sp)+,a0
 rts

; Return d0=1 if the original target has been published, 0 for native copy.
; Preserve all other registers, in particular the stage's a5 active pair.
cockpit_final_publish:
 movem.l d1-d7/a0-a6,-(sp)
 lea cockpit_gauge_seen_bits(pc),a0
 cmpi.w #$7f,(a0)
 bne cf_final_unavailable
 lea cockpit_final_layers(pc),a0
 lea cockpit_static_layer(pc),a1
 move.l (a1)+,d0
 beq cf_final_unavailable
 move.l d0,(a0)+
 move.l (a1),(a0)+
 move.l cockpit_foreground_layer(pc),d0
 beq cf_final_unavailable
 bsr cockpit_final_allocate
 move.l cockpit_final_pool(pc),d0
 beq cf_final_unavailable
 move.l d0,a1
 lea cockpit_final_layers(pc),a0
 lea cockpit_final_rect(pc),a2
 moveq #1,d0
 bsr cockpit_compose_update
 tst.l d0
 beq cf_final_unavailable
 ; Accumulated composition is layer zero for each ordered dirty update.
 lea cockpit_final_layers(pc),a0
 move.l cockpit_final_pool(pc),d0
 move.l d0,(a0)+
 addi.l #40000,d0
 move.l d0,(a0)+
 addi.l #8000,d0
 move.l d0,(a0)+
 addi.l #40000,d0
 move.l d0,(a0)
 move.l cockpit_gauge_pool(pc),a3
 cmpa.l #0,a3
 beq cf_final_unavailable
 move.l cockpit_stage_active(pc),d0
 cmp.l cockpit_stage_pool(pc),d0
 beq .page_ready
 adda.l #CG_STRIDE,a3
.page_ready
 moveq #6,d7
.gauges
 tst.l (a3)
 beq cf_final_unavailable
 move.l a3,a0
 move.l cockpit_final_pool(pc),a1
 adda.l #48000,a1
 bsr cockpit_gauge_expand
 lea cockpit_final_layers(pc),a0
 move.l cockpit_final_pool(pc),a1
 lea CG_AREA(a3),a2
 moveq #2,d0
 bsr cockpit_compose_update
 tst.l d0
 beq cf_final_unavailable
 adda.l #CG_STRIDE*2,a3
 dbf d7,.gauges
 lea cockpit_foreground_layer(pc),a0
 lea cockpit_final_layers+8(pc),a1
 move.l (a0)+,(a1)+
 move.l (a0),(a1)
 lea cockpit_final_layers(pc),a0
 move.l cockpit_final_pool(pc),a1
 lea cockpit_final_rect(pc),a2
 moveq #2,d0
 bsr cockpit_compose_update
 tst.l d0
 beq cf_final_unavailable
 move.l cockpit_final_pool(pc),a0
 move.l a0,a1
 adda.l #40000,a1
 move.l cockpit_stage_active+4(pc),a2
 moveq #20,d0
 move.w #200,d1
 bsr cf_overlay_fast
 IFD VERIFY
 ; The original target still held the untouched scene before this masked copy.
 ; Native stage output includes both covered and uncovered pixels, so this
 ; comparison also detects missing coverage and scene pixels captured as art.
 lea cockpit_final_counts(pc),a6
 addq.l #1,(a6)
 move.l cockpit_stage_active(pc),a0
 move.l cockpit_stage_active+4(pc),a1
 move.w #39999,d0
.compare
 cmpm.b (a0)+,(a1)+
 bne .mismatch
 dbf d0,.compare
 addq.l #1,4(a6)
 ENDC
 moveq #1,d0
 bra cf_final_done
 IFD VERIFY
.mismatch
 addq.l #1,8(a6)
 move.l #39999,d1
 sub.w d0,d1
 move.l d1,16(a6)
 ; Retain the first faulty pixel even if a later frame or view replaces the
 ; cache. This bounded diagnostic is only for the concrete native twin failure.
 lea cockpit_final_fault(pc),a2
 tst.l (a2)
 bne .fault_saved
 move.l #1,(a2)
 move.l d1,4(a2)
 move.l d1,d2
 divu.w #8000,d2
 swap d2
 andi.l #$ffff,d2
 move.l cockpit_final_pool(pc),a3
 adda.l #40000,a3
 move.b 0(a3,d2.w),8(a2)
 move.l cockpit_static_layer+4(pc),a3
 move.b 0(a3,d2.w),9(a2)
 move.l cockpit_foreground_layer+4(pc),a3
 move.b 0(a3,d2.w),10(a2)
 move.l cockpit_stage_active(pc),a3
 adda.l d2,a3
 move.l cockpit_stage_active+4(pc),a4
 adda.l d2,a4
 lea 12(a2),a0
 lea 17(a2),a1
 moveq #4,d3
.fault_planes
 move.b (a3),(a0)+
 move.b (a4),(a1)+
 adda.l #8000,a3
 adda.l #8000,a4
 dbf d3,.fault_planes
 move.l cockpit_stage_h3(pc),a3
 move.w $6712(a3),22(a2)
.fault_saved
 ; Caller restores the entire native result on a mismatch.
 moveq #0,d0
 bra cf_final_done
 ENDC
cf_final_unavailable:
 IFD VERIFY
 lea cockpit_final_counts(pc),a0
 addq.l #1,12(a0)
 ENDC
 moveq #0,d0
cf_final_done:
 movem.l (sp)+,d1-d7/a0-a6
 rts

cockpit_final_allocate:
 movem.l d0-d1/a0-a1/a6,-(sp)
 lea cockpit_final_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 move.l #96000,d0
 move.l #$10004,d1 ; cleared FAST; CPU-only compositor storage
 jsr _LVOAllocMem(a6)
 lea cockpit_final_pool(pc),a0
 move.l d0,(a0)
.done
 movem.l (sp)+,d0-d1/a0-a1/a6
 rts
cockpit_final_pool: dc.l 0
cockpit_final_attempted: dc.w 0
cockpit_final_rect: dc.w 0,0,40,200
cockpit_final_layers: dcb.l 4,0
 IFD VERIFY
cockpit_final_counts: dc.l 0,0,0,0,0 ; attempts, exact matches, mismatches, unavailable, last differing byte
cockpit_final_fault: dcb.b 24,0 ; valid.l, first offset.l, three mask bytes, pad, native/composed five-plane bytes, view.w
 ENDC
