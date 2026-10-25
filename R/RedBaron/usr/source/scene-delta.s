; CPU policy selective viewport copy, bit 28, CPU-gated with cockpit composition and fixed-step timing.
; Two native page identities, each
; with a 24 KB Fast shadow. No additional native hook or Chip reads.
; Rows 88 onward are always dirty: later native instruments may touch them.
; Event/modal/resource and rejected scene paths invalidate both page histories.
SD_BYTES = 24000
; Optional session-owned storage allocated before the game takes its heap.
; Reuse across missions; WHDLoad reclaims it on exit. Allocation failure
; leaves the original full-copy path selected.
scene_delta_prepare:
 movem.l d0-a6,-(sp)
 lea .mask(pc),a0
.mask
 adda.l #perf_mask-.mask,a0
 btst #4,(a0)
 beq .done
 lea scene_delta_pool(pc),a0
 tst.l (a0)
 bne .done
 move.l $4.w,a6
 move.l #2*SD_BYTES,d0
 moveq #MEMF_FAST,d1
 jsr _LVOAllocMem(a6)
 lea scene_delta_pool(pc),a0
 move.l d0,(a0)
.done
 movem.l (sp)+,d0-a6
 rts

scene_delta_invalidate:
 move.l a0,-(sp)
 lea scene_delta_valid(pc),a0
 clr.l (a0)
 move.l (sp)+,a0
 rts

; Return d0=1 after an exact outbound copy, 0 for the original full copy.
; Called inside the existing saved register frame, after the page fence.
scene_delta_copy:
 lea .mask(pc),a0
.mask
 adda.l #perf_mask-.mask,a0
 btst #4,(a0) ; bit 28
 beq .no
 move.w cockpit_fast_applied(pc),d0
 beq .invalidate
 move.w scene_frame_view(pc),d0
 cmpi.w #88,d0
 bhs .invalidate
 move.w scene_frame_view+2(pc),d1
 cmpi.w #120,d1
 bhi .invalidate
 add.w d1,d0
 cmpi.w #88,d0
 bls .invalidate
 move.l scene_frame_view(pc),d0
 lea scene_delta_view(pc),a0
 cmp.l (a0),d0
 beq .geometry
 move.l d0,(a0)
 bsr scene_delta_invalidate
.geometry
 move.l scene_delta_pool(pc),d0
 beq .no
.allocated
 move.l scene_frame_h3(pc),a0
 moveq #0,d6
 move.b $711d(a0),d6 ; same native page selector as cockpit composition
 andi.w #1,d6
 add.w d6,d6
 lea scene_delta_valid(pc),a5
 adda.w d6,a5
 add.w d6,d6
 lea scene_delta_pages(pc),a0
 move.l scene_frame_original(pc),a1
 cmpa.l 0(a0,d6.w),a1
 beq .identity
 move.l a1,0(a0,d6.w)
 clr.w (a5)
.identity
 move.l scene_delta_pool(pc),a2
 tst.w d6
 beq .shadow
 adda.l #SD_BYTES,a2
.shadow
 move.l scene_frame_buffer(pc),a0
 moveq #0,d0
 move.w scene_frame_view(pc),d0
 mulu #40,d0
 adda.l d0,a0
 adda.l d0,a1
 move.w #88,d4
 sub.w scene_frame_view(pc),d4
 mulu #10,d4
 moveq #0,d3
 move.w scene_frame_view+2(pc),d3
 mulu #10,d3
 move.l d3,d2
 lsl.l #2,d2
 neg.l d2
 addi.l #8000,d2
 sub.w d4,d3
 subq.w #1,d3
 subq.w #1,d4
 move.w (a5),d5
 move.w #1,(a5)
 moveq #4,d6
.plane
 move.w d4,d7 ; viewport rows above the native cockpit
.upper
 move.l (a0)+,d0
 tst.w d5
 beq .write
 cmp.l (a2),d0
 beq .same
.write
 move.l d0,(a1)
.same
 move.l d0,(a2)+
 addq.l #4,a1
 dbf d7,.upper
 move.w d3,d7 ; cockpit rows always overwrite downstream native drawing
.lower
 move.l (a0)+,d0
 move.l d0,(a1)+
 move.l d0,(a2)+
 dbf d7,.lower
 adda.l d2,a0
 adda.l d2,a1
 dbf d6,.plane
 moveq #1,d0
 rts
.invalidate
 bsr scene_delta_invalidate
.no
 moveq #0,d0
 rts

scene_delta_view: dc.l 0
scene_delta_pool: dc.l 0
scene_delta_pages: dc.l 0,0
scene_delta_valid: dc.w 0,0
