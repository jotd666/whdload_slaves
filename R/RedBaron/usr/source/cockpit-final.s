; Complete ordered layer publication, reached only from bit-19/020+ stage.
; Required layers: native static artwork, seven current-page gauges, foreground.
; Until acceptance this remains a development candidate. Native drawing into
; its normal target is retained as fallback; VERIFY saves an exact reference.
; One CPU masked copy publishes the combined cockpit to the original target.
cockpit_final_reset:
 move.l a0,-(sp)
 lea cockpit_foreground_deferred(pc),a0
 clr.w (a0)
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
 bsr cockpit_final_dirty
 tst.l d0
 bmi cf_final_unavailable
 beq cf_final_publish_pixels
 move.l cockpit_final_pool(pc),a1
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
 move.w cockpit_stage_page(pc),d0
 beq .page_ready
 adda.l #CG_STRIDE,a3
.page_ready
 moveq #6,d7
.gauges
 tst.l (a3)
 beq cf_final_unavailable
 bsr cockpit_final_intersection
 tst.l d0
 beq .next_gauge
 move.l a3,a0
 move.l cockpit_final_pool(pc),a1
 adda.l #48000,a1
 bsr cockpit_gauge_expand
 lea cockpit_final_layers(pc),a0
 move.l cockpit_final_pool(pc),a1
 lea cockpit_final_clip(pc),a2
 moveq #2,d0
 bsr cockpit_compose_update
 tst.l d0
 beq cf_final_unavailable
.next_gauge
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
 ; Commit the exact selected generations and bounds only after all updates.
 lea cockpit_final_pending(pc),a0
 lea cockpit_final_keys(pc),a1
 moveq #20,d0
.keys
 move.l (a0)+,(a1)+
 dbf d0,.keys
 lea cockpit_final_valid(pc),a0
 move.w #1,(a0)
cf_final_publish_pixels:
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
 move.l cockpit_stage_pool(pc),a0
 adda.l #CS_PAGE_BYTES,a0
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
 lea cockpit_final_valid(pc),a2
 clr.w (a2)
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
 move.l cockpit_stage_pool(pc),a3
 adda.l #CS_PAGE_BYTES,a3
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
 lea cockpit_final_valid(pc),a0
 clr.w (a0)
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
cockpit_final_valid: dc.w 0
cockpit_final_keys: dcb.b 84,0 ; seven {generation.l, bounds: four words}
cockpit_final_pending: dcb.b 84,0
cockpit_final_rect: dc.w 0,0,40,200
cockpit_final_clip: dcb.w 4,0
cockpit_final_layers: dcb.l 4,0
 IFD VERIFY
cockpit_final_dirty_counts: dc.l 0,0,0 ; full rebuilds, dirty rebuilds, unchanged reuse
cockpit_final_counts: dc.l 0,0,0,0,0 ; attempts, exact matches, mismatches, unavailable, last differing byte
cockpit_final_fault: dcb.b 24,0 ; valid.l, first offset.l, three mask bytes, pad, native/composed five-plane bytes, view.w
 ENDC

; Build the old/new union of changed gauge bounds. Static/foreground changes
; invalidate the whole composition. Return -1 unavailable, 0 reused, 1 dirty.
cockpit_final_dirty:
 movem.l d1-d7/a0-a4,-(sp)
 lea cockpit_final_rect(pc),a4
 move.w #40,(a4)
 move.w #200,2(a4)
 clr.l 4(a4) ; temporarily right/bottom, converted to width/height below
 move.l cockpit_gauge_pool(pc),a3
 cmpa.l #0,a3
 beq .bad
 move.w cockpit_stage_page(pc),d0
 beq .page
 adda.l #CG_STRIDE,a3
.page
 lea cockpit_final_keys(pc),a1
 lea cockpit_final_pending(pc),a2
 moveq #6,d7
.loop
 move.l (a3),d0
 beq .bad
 move.l d0,(a2)+
 move.l CG_AREA(a3),(a2)+
 move.l CG_AREA+4(a3),(a2)+
 cmp.l (a1),d0
 beq .next
 move.w cockpit_final_valid(pc),d1
 beq .next
 lea 4(a1),a0
 bsr cockpit_final_union
 lea CG_AREA(a3),a0
 bsr cockpit_final_union
.next
 adda.w #12,a1
 adda.l #CG_STRIDE*2,a3
 dbf d7,.loop
 move.w cockpit_final_valid(pc),d1
 bne .bounded
 clr.l (a4)
 move.l #$002800c8,4(a4)
 IFD VERIFY
 lea cockpit_final_dirty_counts(pc),a0
 addq.l #1,(a0)
 ENDC
 moveq #1,d0
 bra .done
.bounded
 move.w 4(a4),d0
 beq .unchanged
 sub.w (a4),d0
 move.w d0,4(a4)
 move.w 6(a4),d0
 sub.w 2(a4),d0
 move.w d0,6(a4)
 IFD VERIFY
 lea cockpit_final_dirty_counts(pc),a0
 addq.l #1,4(a0)
 ENDC
 moveq #1,d0
 bra .done
.unchanged
 IFD VERIFY
 lea cockpit_final_dirty_counts(pc),a0
 addq.l #1,8(a0)
 ENDC
 moveq #0,d0
 bra .done
.bad
 moveq #-1,d0
.done
 movem.l (sp)+,d1-d7/a0-a4
 rts

; a0=valid layer rectangle, a4=current left/top/right/bottom union.
; Preserve the signature pointers and record registers.
cockpit_final_union:
 move.w (a0),d0
 cmp.w (a4),d0
 bge .left
 move.w d0,(a4)
.left
 add.w 4(a0),d0
 cmp.w 4(a4),d0
 ble .right
 move.w d0,4(a4)
.right
 move.w 2(a0),d0
 cmp.w 2(a4),d0
 bge .top
 move.w d0,2(a4)
.top
 add.w 6(a0),d0
 cmp.w 6(a4),d0
 ble .done
 move.w d0,6(a4)
.done
 rts

; a3=record. Intersect its fully overwritten scratch rectangle with dirty area.
; Return d0=1 and cockpit_final_clip, or 0 for a disjoint layer.
cockpit_final_intersection:
 movem.l d1-d4/a0-a2,-(sp)
 lea cockpit_final_rect(pc),a0
 lea CG_AREA(a3),a1
 lea cockpit_final_clip(pc),a2
 move.w (a0),d1
 move.w 4(a0),d3
 add.w d1,d3
 move.w (a1),d0
 move.w 4(a1),d4
 add.w d0,d4
 cmp.w d0,d1
 bge .left
 move.w d0,d1
.left
 cmp.w d4,d3
 ble .right
 move.w d4,d3
.right
 sub.w d1,d3
 ble .empty
 move.w d1,(a2)
 move.w d3,4(a2)
 move.w 2(a0),d1
 move.w 6(a0),d3
 add.w d1,d3
 move.w 2(a1),d0
 move.w 6(a1),d4
 add.w d0,d4
 cmp.w d0,d1
 bge .top
 move.w d0,d1
.top
 cmp.w d4,d3
 ble .bottom
 move.w d4,d3
.bottom
 sub.w d1,d3
 ble .empty
 move.w d1,2(a2)
 move.w d3,6(a2)
 moveq #1,d0
 bra .done
.empty
 moveq #0,d0
.done
 movem.l (sp)+,d1-d4/a0-a2
 rts
