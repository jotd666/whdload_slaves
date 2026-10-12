; Sparse artwork drawing-state replay and bounded native pixel twin.
OC_DESC = (OVERLAY_KEY_BYTES+3)&-4
OC_STATE = OC_DESC+12
OC_PIXELS = OC_STATE+24
OC_ENTRY = OC_PIXELS+4

; Called by the shared resource-lifetime hook with CCR saved.
artwork_cache_invalidate:
 bsr artwork_front_invalidate
 move.l a0,-(sp)
 move.l artwork_solid_entry(pc),a0
 cmpa.l #0,a0
 beq .done
 clr.w (a0)
.done
 move.l (sp)+,a0
 rts

artwork_cache_original_program:
 movem.l d0-a6,-(sp)
 subq.l #2,sp
 move.w d7,-(sp)
artwork_cache_native:
 jsr $0.l
 addq.l #4,sp
 movem.l (sp)+,d0-a6
 rts

; Capture output values, replay only fields written by this program's commands.
artwork_cache_save_state:
 lea OC_STATE(a5),a0
artwork_cache_read_state:
 move.w -$3e9c(a4),(a0)+ ; h3:4164 pen
 move.l $1d50(a4),(a0)+ ; background, foreground
 move.w -$3de(a4),(a0)+ ; h3:7c22 image set
 move.l -$3dc(a4),(a0)+ ; table
 move.l -$3d4(a4),(a0)+ ; alternate table
 move.l -$3d8(a4),(a0)+ ; image descriptor
 move.w -$3e4(a4),(a0)+ ; bitmap mode
 move.w $1d54(a4),(a0)+ ; filled rectangle mode
 rts

artwork_cache_restore_state:
 lea OC_STATE(a5),a0
 move.w OVERLAY_KEY_EFFECTS(a5),d0
 btst #0,d0
 beq .set
 move.w (a0),-$3e9c(a4)
 move.l 2(a0),$1d50(a4)
.set
 btst #1,d0
 beq .image
 move.w 6(a0),-$3de(a4)
 move.l 8(a0),-$3dc(a4)
 move.l 12(a0),-$3d4(a4)
.image
 btst #2,d0
 beq .bitmap
 move.l 16(a0),-$3d8(a4)
.bitmap
 btst #3,d0
 beq .rectangle
 move.w 20(a0),-$3e4(a4)
.rectangle
 btst #4,d0
 beq .done
 move.w 22(a0),$1d54(a4)
.done
 rts

artwork_cache_h3: dc.l 0
 IFD VERIFY
artwork_cache_stats: dc.l 0,0,0 ; hits, fills, fallbacks
 ENDC

 IFD VERIFY
; One pixel/post-state twin per native page and static program (2, 3, 4).
; Native output is retained. The pixel guard itself is page-independent.
; Only private snapshots are allocated; no redirected DMA or hidden game state.
artwork_cache_twin_before:
 movem.l d0-a6,-(sp)
 lea artwork_cache_twin_result(pc),a6
 clr.l 4(a6)
 moveq #0,d0
 move.b -$ee3(a4),d0
 andi.w #1,d0
 move.w d7,d1
 subq.w #2,d1
 add.w d1,d1
 add.w d1,d0
 move.l (a6),d1
 btst d0,d1
 bne .done
 move.l 8(a6),d0
 bne .allocated
 move.l a6,-(sp)
 move.l 4.w,a6
 move.l #80000,d0
 moveq #0,d1
 jsr _LVOAllocMem(a6)
 move.l (sp)+,a6
 move.l d0,8(a6)
 beq artwork_bad
.allocated
 bsr artwork_wait
 move.l d0,a1
 move.l $1d72(a4),a0
 move.w #9999,d0
.copy
 move.l (a0)+,(a1)+
 dbf d0,.copy
 move.l #1,4(a6)
.done
 movem.l (sp)+,d0-a6
 rts

artwork_cache_twin_after:
 movem.l d0-a6,-(sp)
 lea artwork_cache_twin_result(pc),a6
 tst.l 4(a6)
 beq .done
 suba.w #48,sp
 move.l sp,a0
 bsr artwork_cache_read_state
 move.l 8(a6),a0
 move.l a0,a1
 adda.l #40000,a1
 move.l $1d72(a4),a2
 move.w #9999,d0
.swap
 move.l (a2),(a1)+
 move.l (a0)+,(a2)+
 dbf d0,.swap
 bsr artwork_cache_original_program
 bsr artwork_wait
 move.l 8(a6),a0
 adda.l #40000,a0
 move.l $1d72(a4),a1
 move.w #39999,d0
.compare
 cmpm.b (a0)+,(a1)+
 bne artwork_bad
 dbf d0,.compare
 lea 24(sp),a0
 bsr artwork_cache_read_state
 move.l sp,a0
 lea 24(sp),a1
 moveq #5,d0
.state
 cmpm.l (a0)+,(a1)+
 bne artwork_bad
 dbf d0,.state
 adda.w #48,sp
 moveq #0,d0
 move.b -$ee3(a4),d0
 andi.w #1,d0
 move.w d7,d1
 subq.w #2,d1
 add.w d1,d1
 add.w d1,d0
 move.l (a6),d1
 bset d0,d1
 move.l d1,(a6)
 addq.l #1,12(a6)
 cmpi.l #63,d1
 bne .done
 move.l a6,-(sp)
 move.l 8(a6),a1
 clr.l 8(a6)
 move.l 4.w,a6
 move.l #80000,d0
 jsr _LVOFreeMem(a6)
 move.l (sp)+,a6
.done
 movem.l (sp)+,d0-a6
 rts
artwork_cache_twin_result: dc.l 0,0,0,0 ; checked bits, active, scratch, passes
 ENDC

