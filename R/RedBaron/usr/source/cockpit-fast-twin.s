; One combined overlay/programs 2-4 native viewport twin per physical page.
; Raw scene pixels are installed on Chip before the candidate runs. The native
; interpreter executes on that identical input; compare only the owned rows.
; Existing six per-program twins also check outside rows and drawing state.
cockpit_fast_twin_before:
 movem.l d0-a6,-(sp)
 lea cockpit_fast_twin_result(pc),a5
 clr.l 4(a5)
 moveq #0,d0
 move.b -$ee3(a4),d0
 andi.w #1,d0
 move.l (a5),d1
 btst d0,d1
 bne .done
 move.l #1,4(a5)
 bsr fence_wait
 bsr scene_frame_wait
 move.l scene_frame_storage(pc),a1
 adda.l #PERF_SCENE_TWIN_SCREEN,a1
 move.l scene_frame_original(pc),a0
 move.w #1249,d7
 bsr scene_frame_copy32
 move.l scene_frame_buffer(pc),a0
 move.l scene_frame_original(pc),a1
 move.w #1249,d7
 bsr scene_frame_copy32
.done
 movem.l (sp)+,d0-a6
 rts

cockpit_fast_twin_after:
 movem.l d0-a6,-(sp)
 lea cockpit_fast_twin_result(pc),a5
 tst.l 4(a5)
 beq .done
 move.l scene_frame_h3(pc),a4
 adda.l #$8000,a4
 suba.w #24,sp
 move.l sp,a0
 bsr artwork_cache_read_state
 move.l $1d46(a4),-(sp)
 move.l $1d4a(a4),-(sp)
 move.w $1d4e(a4),-(sp)
 lea scene_frame_active(pc),a0
 clr.w (a0)
 move.l scene_frame_original(pc),$1d72(a4)
 move.l scene_frame_original+4(pc),$1d76(a4)
 move.w $1d4e(a4),d1
 bsr cockpit_fast_native
 bsr scene_frame_wait
 move.w #1,$1d46(a4)
 move.w $d7e(a4),$1d48(a4)
 move.w $d80(a4),$1d4a(a4)
 clr.w $1d4c(a4)
 move.w $d84(a4),$1d4e(a4)
 moveq #2,d7
.program
 bsr artwork_cache_original_program
 addq.w #1,d7
 cmpi.w #5,d7
 bne .program
 bsr scene_frame_wait
 move.l scene_frame_buffer(pc),a0
 move.l scene_frame_original(pc),a1
 moveq #0,d0
 move.w cockpit_fast_lo(pc),d0
 adda.l d0,a0
 adda.l d0,a1
 moveq #4,d6
.plane
 move.l a0,a2
 move.l a1,a3
 move.w cockpit_fast_hi(pc),d7
 sub.w d0,d7
 lsr.w #1,d7
 subq.w #1,d7
.word
 cmpm.w (a2)+,(a3)+
 bne .bad
 dbf d7,.word
 adda.l #8000,a0
 adda.l #8000,a1
 dbf d6,.plane
 move.w (sp)+,$1d4e(a4)
 move.l (sp)+,$1d4a(a4)
 move.l (sp)+,$1d46(a4)
 move.w (sp)+,-$3e9c(a4)
 move.l (sp)+,$1d50(a4)
 move.w (sp)+,-$3de(a4)
 move.l (sp)+,-$3dc(a4)
 move.l (sp)+,-$3d4(a4)
 move.l (sp)+,-$3d8(a4)
 move.w (sp)+,-$3e4(a4)
 move.w (sp)+,$1d54(a4)
 move.l scene_frame_storage(pc),a0
 adda.l #PERF_SCENE_TWIN_SCREEN,a0
 move.l scene_frame_original(pc),a1
 move.w #1249,d7
 bsr scene_frame_copy32
 move.l scene_frame_buffer(pc),d0
 move.l d0,$1d72(a4)
 addi.l #40000,d0
 move.l d0,$1d76(a4)
 lea scene_frame_active(pc),a0
 move.w #1,(a0)
 lea cockpit_fast_twin_result(pc),a5
 moveq #0,d0
 move.b -$ee3(a4),d0
 andi.w #1,d0
 move.l (a5),d1
 bset d0,d1
 move.l d1,(a5)
 clr.l 4(a5)
 addq.l #1,8(a5)
.done
 movem.l (sp)+,d0-a6
 rts
.bad
 move.l a2,12(a5)
 move.l a3,16(a5)
 bra scene_frame_bad
cockpit_fast_twin_result: dc.l 0,0,0,0,0

; At the final cockpit boundary, compare every covered word against the composed
; viewport. This detects a reordered gauge/static overlap and missed persistent
; page invalidation. Once per page per invalidation keeps the steady exact
; profile free of repeated verification scans.
cockpit_fast_check_final:
 lea cockpit_fast_checked(pc),a0
 move.l scene_frame_h3(pc),a1
 moveq #0,d0
 move.b $711d(a1),d0
 andi.w #1,d0
 move.w (a0),d1
 btst d0,d1
 bne .checked
 bset d0,d1
 move.w d1,(a0)
 move.l scene_frame_original(pc),a1
 move.l scene_frame_buffer(pc),a2
 move.l artwork_solid_entry(pc),a5
 move.l OC_PIXELS(a5),a0
 bsr .list
 move.l artwork_front_fast(pc),a5
 move.l OC_PIXELS(a5),a0
 bsr .list
 move.l OC_ENTRY+OC_PIXELS(a5),a0
 bsr .list
 lea cockpit_fast_final_checks(pc),a0
 addq.l #1,(a0)
.checked
 rts
.list
 move.w (a0)+,d7
 beq .done
 subq.w #1,d7
.word
 moveq #0,d0
 move.w (a0)+,d0
 move.w (a0)+,d1
 move.l a1,a3
 adda.w d0,a3
 cmp.w cockpit_fast_lo(pc),d0
 blo .outside
 cmp.w cockpit_fast_hi(pc),d0
 bhs .outside
 move.l a2,a4
 adda.w d0,a4
 moveq #4,d6
.plane
 move.w (a3),d2
 move.w (a4),d3
 eor.w d3,d2
 and.w d1,d2
 bne scene_frame_bad
 adda.l #8000,a3
 adda.l #8000,a4
 dbf d6,.plane
 adda.w #10,a0
 bra .next
.outside
 moveq #4,d6
.out_plane
 move.w (a3),d2
 move.w (a0)+,d3
 eor.w d3,d2
 and.w d1,d2
 bne scene_frame_bad
 adda.l #8000,a3
 dbf d6,.out_plane
.next
 dbf d7,.word
.done
 rts
cockpit_fast_final_checks: dc.l 0
