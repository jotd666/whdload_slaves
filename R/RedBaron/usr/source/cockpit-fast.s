; FC2: forward, non-firing composition before the single viewport transfer.
; Developer bit 22 requires bits 19/20/21 and the measured 030/040/060 gate.
; PERF_RANGE sim:2c144 6 bit=22
; PERF_RANGE sim:00830 6 bit=22
CF_OVERLAY_OFFSET = $6000
CF_OVERLAY_BYTES = 2+1440*14
 IFGT OS_FAST+OS_PIXELS-CF_OVERLAY_OFFSET
 FAIL "Cockpit overlay overlaps program two"
 ENDC
 IFGT CF_OVERLAY_OFFSET+CF_OVERLAY_BYTES-$10000
 FAIL "Cockpit overlay overlaps front artwork"
 ENDC
CF_CLEAR_PAGES MACRO
 lea cockpit_fast_valid(pc),a0
 clr.l (a0)
 IFD VERIFY
 clr.w 4(a0) ; re-arm final pixel checks on both pages after invalidation
 ENDC
 ENDM
cockpit_fast_install:
 movem.l d0-a6,-(sp)
 move.l a1,a3
 move.l a1,a0
 adda.l #$2c144,a0
 cmpi.w #$3239,(a0)
 bne scene_frame_bad
 move.l scene_frame_h3(pc),d0
 addi.l #$9d4e,d0
 cmp.l 2(a0),d0
 bne scene_frame_bad
 move.l a3,a0
 adda.l #$830,a0
 cmpi.w #$3039,(a0)
 bne scene_frame_bad
 move.l scene_frame_h3(pc),d0
 addi.l #$4820,d0
 cmp.l 2(a0),d0
 bne scene_frame_bad
 lea cockpit_fast_native+2(pc),a0
 move.l a3,d0
 addi.l #$2c14a,d0
 move.l d0,(a0)
 lea cockpit_fast_sim(pc),a0
 move.l a3,(a0)
 lea .work(pc),a0
.work
 adda.l #memory_workspace_reserved-.work,a0
 move.l (a0),d0
 addi.l #CF_OVERLAY_OFFSET,d0
 lea cockpit_fast_list(pc),a0
 move.l d0,(a0)
 lea cockpit_fast_enabled(pc),a0
 move.w #1,(a0)
 move.l a3,a1
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 jsr resload_FlushCache(a2)
 movem.l (sp)+,d0-a6
 rts
.patch
 PL_START
 PL_P $2c144,cockpit_fast_overlay
 PL_PS $830,cockpit_fast_end
 PL_END

; Resource lifetime hooks call this before any referenced pixels can be freed.
cockpit_fast_invalidate:
 bsr scene_delta_invalidate
 move.l a0,-(sp)
 lea cockpit_fast_cached(pc),a0
 clr.w (a0)
 CF_CLEAR_PAGES
 move.l (sp)+,a0
 rts

; The shared render entry owns the event invalidations. Conservatively invalidate
; both page slots during redraw, view/background changes, top text and messages.
; No pixel reads are used to establish validity.
cockpit_fast_begin:
 dc.w $42e7
 movem.l d0/a0,-(sp)
 lea cockpit_fast_applied(pc),a0
 clr.w (a0)
 btst #0,cockpit_fast_enabled+1(pc)
 beq .done
 tst.w d7
 bne .dirty
 move.l scene_frame_h3(pc),a0
 adda.l #$4000,a0
 tst.l $922(a0)
 bne .dirty
 tst.w $588(a0)
 bne .dirty
 tst.w $5b8(a0)
 bne .dirty
 tst.l $2712(a0)
 bne .dirty
 tst.w $2716(a0)
 bne .dirty
 tst.w $820(a0)
 bne .dirty
 tst.w $1830(a0) ; h3:5830 firing state, native sim:1216a getter
 beq .done
.dirty
 bsr cockpit_fast_invalidate
.done
 movem.l (sp)+,d0/a0
 move.w (sp)+,ccr
 rts

; Native overlay entry remains available for unsupported/event frames.
cockpit_fast_overlay:
 btst #0,cockpit_fast_applied+1(pc)
 bne cockpit_fast_overlay_done
 move.l a0,-(sp)
 move.l scene_frame_h3(pc),a0
 adda.l #$8000,a0
 move.w $1d4e(a0),d1
 move.l (sp)+,a0
cockpit_fast_native:
 jmp $0.l
cockpit_fast_overlay_done
 rts

; Called with the private viewport still active, before the only outbound copy.
cockpit_fast_compose:
 btst #0,cockpit_fast_enabled+1(pc)
 beq .done
 move.l scene_frame_h3(pc),a4
 adda.l #$8000,a4
 tst.l -$18ee(a4) ; current and previous view
 bne .done
 tst.w -$27d0(a4) ; firing
 bne .done
 tst.w -$3a48(a4) ; top background restoration precedes native overlay
 bne .done
 tst.w -$18ea(a4)
 bne .done
 move.l -$66a4(a4),a0 ; native program-two height selector
 cmpi.w #40,(a0)
 ble .done
 tst.w -$1b0a(a4) ; exceptional foreground programs 28/29
 bne .done
 move.l scene_frame_original(pc),d0
 cmp.l $1d6a(a4),d0
 bne .done
 IFD VERIFY
 lea artwork_cache_twin_result(pc),a0
 cmpi.l #63,(a0)
 bne .done
 ENDC
 ; Both page roles must match the supported full-width viewport geometry.
 move.w scene_frame_view(pc),d0
 mulu #40,d0
 lea cockpit_fast_lo(pc),a0
 move.w scene_frame_view+2(pc),d1
 mulu #40,d1
 add.w d0,d1
 cmp.w (a0),d0
 bne .new_view
 cmp.w 2(a0),d1
 beq .same_view
.new_view
 move.l a0,-(sp)
 CF_CLEAR_PAGES
 move.l (sp)+,a0
.same_view
 move.w d0,(a0)
 move.w d1,2(a0)
 ; Native overlay is at row 88, full width, clipped by its exact bottom rule.
 move.w $1d4e(a4),d0
 move.w #72,d1
 cmpi.w #75,d0
 blt .height
 cmpi.w #159,d0
 bge .height
 subi.w #159,d0
 add.w d0,d1
.height
 tst.w d1
 ble .done
 cmpi.w #72,d1
 bhi .done
 mulu #40,d1
 addi.w #3520,d1
 cmp.w cockpit_fast_hi(pc),d1
 bhi .done
 move.w cockpit_fast_lo(pc),d0
 cmpi.w #3520,d0
 bhi .done
 lea cockpit_fast_overlay_end(pc),a0
 move.w d1,(a0)
 ; Check all three exact cache keys using the clip installed by sim:15e68.
 ; Only geometry changes here; input pens are deliberately not dependencies.
 move.l $1d46(a4),-(sp)
 move.l $1d4a(a4),-(sp)
 move.w $1d4e(a4),-(sp)
 move.w #1,$1d46(a4)
 move.w $d7e(a4),$1d48(a4)
 move.w $d80(a4),$1d4a(a4)
 clr.w $1d4c(a4)
 move.w $d84(a4),$1d4e(a4)
 move.l artwork_solid_entry(pc),d0
 beq .reject
 move.l d0,a0
 moveq #2,d0
 bsr overlay_key_matches
 tst.l d0
 beq .reject
 move.l artwork_front_fast(pc),d0
 beq .reject
 move.l d0,a0
 moveq #3,d0
 bsr overlay_key_matches
 tst.l d0
 beq .reject
 adda.l #OC_ENTRY,a0
 moveq #4,d0
 bsr overlay_key_matches
 tst.l d0
 beq .reject
 moveq #1,d6
 bra .clip_back
.reject
 moveq #0,d6
.clip_back
 move.w (sp)+,$1d4e(a4)
 move.l (sp)+,$1d4a(a4)
 move.l (sp)+,$1d46(a4)
 tst.w d6
 beq .done
 bsr cockpit_fast_prepare
 tst.l d0
 beq .done
 IFD VERIFY
 bsr cockpit_fast_twin_before
 ENDC
 move.l cockpit_fast_list(pc),a0
 move.l scene_frame_buffer(pc),a1
 move.w cockpit_fast_overlay_end(pc),d5
 bsr cockpit_fast_words
 move.l artwork_solid_entry(pc),a5
 move.l OC_PIXELS(a5),a0
 move.w cockpit_fast_hi(pc),d5
 bsr cockpit_fast_words
 move.l artwork_front_fast(pc),a5
 move.l OC_PIXELS(a5),a0
 bsr cockpit_fast_words
 move.l OC_ENTRY+OC_PIXELS(a5),a0
 bsr cockpit_fast_words
 lea cockpit_fast_applied(pc),a0
 move.w #1,(a0)
 IFD VERIFY
 bsr cockpit_fast_twin_after
 ENDC
.done
 btst #0,cockpit_fast_applied+1(pc)
 bne .ret
 CF_CLEAR_PAGES
.ret
 rts

; Cache the native overlay's exact cookie-cut operands once per resource lifetime.
; The supported descriptor is five planes, 320 x 72 at row 88, mask starts at 0.
cockpit_fast_prepare:
 move.l cockpit_fast_sim(pc),a3
 adda.l #$2c2b2,a3
 cmpi.w #3520,4(a3)
 bne .no
 cmpi.w #$1214,6(a3)
 bne .no
 cmpi.w #2880,8(a3)
 bne .no
 move.l (a3),d0
 beq .no
 move.l $1d62(a4),d1
 beq .no
 btst #0,cockpit_fast_cached+1(pc)
 beq .fill
 cmp.l cockpit_fast_source(pc),d0
 bne .fill
 cmp.l cockpit_fast_mask(pc),d1
 bne .fill
 moveq #1,d0
 rts
.fill
 lea cockpit_fast_source(pc),a0
 move.l d0,(a0)+
 move.l d1,(a0)
 move.l d0,a0
 move.l d1,a1
 move.l cockpit_fast_list(pc),a2
 move.l a2,a6
 clr.w (a2)+
 move.w #3520,d2
 move.w #1439,d7
.word
 move.w (a1)+,d3
 beq .next
 addq.w #1,(a6)
 move.w d2,(a2)+
 move.w d3,(a2)+
 move.l a0,a3
 moveq #4,d6
.plane
 move.w (a3),d4
 and.w d3,d4
 move.w d4,(a2)+
 adda.w #2880,a3
 dbf d6,.plane
.next
 addq.l #2,a0
 addq.w #2,d2
 dbf d7,.word
 lea cockpit_fast_cached(pc),a0
 move.w #1,(a0)
 moveq #1,d0
 rts
.no
 moveq #0,d0
 rts

; a0=list, a1=Fast framebuffer, d5=exclusive bottom byte. No Chip access.
; Only rows owned by the scene are touched; remaining artwork is page-persistent.
cockpit_fast_words:
 movem.l d0-d4/a0-a2,-(sp)
 move.w (a0)+,d4
 beq .done
 subq.w #1,d4
.word
 moveq #0,d0
 move.w (a0)+,d0
 cmp.w d5,d0
 bhs .done
 cmp.w cockpit_fast_lo(pc),d0
 blo .skip
 move.l a1,a2
 adda.w d0,a2
 move.w (a0)+,d1
 not.w d1
 REPT 5
 move.w (a2),d2
 and.w d1,d2
 or.w (a0)+,d2
 move.w d2,(a2)
 adda.l #8000,a2
 ENDR
 bra .next
.skip
 adda.w #12,a0
.next
 dbf d4,.word
.done
 movem.l (sp)+,d0-d4/a0-a2
 rts

; Existing cache hits replay state in original order. Only unowned rows need
; repair here. A page slot remembers each program until a redraw/event invalidates
; it; pointer identity protects against page reuse. Opaque words never read Chip.
cockpit_fast_update:
 btst #0,cockpit_fast_applied+1(pc)
 beq .native
 movem.l d0-d7/a0-a3,-(sp)
 moveq #0,d6
 move.b -$ee3(a4),d6
 andi.w #1,d6
 add.w d6,d6
 lea cockpit_fast_valid(pc),a3
 adda.w d6,a3
 add.w d6,d6
 lea cockpit_fast_pages(pc),a2
 cmpa.l 0(a2,d6.w),a1
 beq .page
 move.l a1,0(a2,d6.w)
 clr.w (a3)
.page
 move.w (a3),d6
 btst d7,d6
 bne .done
 bset d7,d6
 move.w d6,(a3)
 bsr artwork_wait
 move.w (a0)+,d4
 beq .done
 subq.w #1,d4
.word
 moveq #0,d0
 move.w (a0)+,d0
 cmp.w cockpit_fast_lo(pc),d0
 blo .paint
 cmp.w cockpit_fast_hi(pc),d0
 blo .skip
.paint
 move.l a1,a2
 adda.w d0,a2
 move.w (a0)+,d1
 not.w d1
 moveq #4,d3
.plane
 move.w (a0)+,d2
 tst.w d1
 beq .opaque
 move.w (a2),d0
 and.w d1,d0
 or.w d0,d2
.opaque
 move.w d2,(a2)
 adda.l #8000,a2
 dbf d3,.plane
 bra .next
.skip
 adda.w #12,a0
.next
 dbf d4,.word
.done
 movem.l (sp)+,d0-d7/a0-a3
 rts
.native
 bra artwork_sparse_update

; Modal drawing can reuse either page outside the flight render entry.
cockpit_fast_boundary:
 dc.w $42e7
 bsr cockpit_fast_invalidate
 bsr instrument_cache_invalidate
 move.w (sp)+,ccr
 bra fence_wait

; Explicit message boundary, before native message painting can replace artwork.
cockpit_fast_end:
 movem.l d0-a6,-(sp)
 IFD VERIFY
 btst #0,cockpit_fast_applied+1(pc)
 beq .checked
 bsr cockpit_fast_check_final
.checked
 ENDC
 move.l scene_frame_h3(pc),a0
 move.w $4820(a0),d0
 beq .done
 bsr scene_delta_invalidate
 CF_CLEAR_PAGES
.done
 movem.l (sp)+,d0-a6
 move.l a0,-(sp)
 move.l scene_frame_h3(pc),a0
 move.w $4820(a0),d0 ; replay the original MOVE, including the high word
 move.l (sp)+,a0
 rts

cockpit_fast_enabled: dc.w 0
cockpit_fast_applied: dc.w 0
cockpit_fast_cached: dc.w 0
cockpit_fast_valid: dc.w 0,0
 IFD VERIFY
cockpit_fast_checked: dc.w 0
 ENDC
cockpit_fast_pages: dc.l 0,0
cockpit_fast_sim: dc.l 0
cockpit_fast_list: dc.l 0
cockpit_fast_source: dc.l 0
cockpit_fast_mask: dc.l 0
cockpit_fast_lo: dc.w 0
cockpit_fast_hi: dc.w 0
cockpit_fast_overlay_end: dc.w 0
 IFD VERIFY
 include "cockpit-fast-twin.s"
 ENDC
