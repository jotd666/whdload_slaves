; fast gauges: per-page lower-panel persistence and clipped CPU background restore.
; Shared bit18 hooks retain their original behaviour without bit23.
GF_AREA = 36
GF_PIXELS = 48
GF_PLANE = 640
GF_MASK = GF_PIXELS+GF_PLANE*5
GF_STRIDE = GF_MASK+GF_PLANE

gauge_fast_install:
 movem.l d0-a6,-(sp)
 move.l a1,a3
 lea .check(pc),a6
.check
 adda.l #perf_check_bytes-.check,a6
 move.l #$19ba6,d0
 moveq #8,d1
 lea .entry_bytes(pc),a0
 jsr (a6)
 move.l #$19d98,d0
 moveq #6,d1
 lea .restore_bytes(pc),a0
 jsr (a6)
 move.l a3,d0
 addi.l #$19bae,d0
 lea gauge_fast_entry_tail+2(pc),a0
 move.l d0,(a0)
 move.l a3,d0
 addi.l #$30408,d0
 lea gauge_fast_native+2(pc),a0
 move.l d0,(a0)
 lea gauge_fast_enabled(pc),a0
 move.w #1,(a0)
 move.l a3,a1
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 jsr resload_FlushCache(a2)
 movem.l (sp)+,d0-a6
 rts
.entry_bytes: dc.w $4e55,$ffe0,$48e7,$2f32
.restore_bytes: dc.w $4eba,$072c,$2004
.patch
 PL_START
 PL_P $19ba6,gauge_fast_entry
 PL_NOP $19bac,2
 PL_PS $19d98,gauge_fast_restore
 PL_END

gauge_fast_invalidate:
 movem.l d0/a0,-(sp)
 move.l gauge_fast_pool(pc),a0
 cmpa.l #0,a0
 beq .done
 moveq #6,d0
.clear
 clr.l (a0)
 adda.l #GF_STRIDE,a0
 dbf d0,.clear
.done
 movem.l (sp)+,d0/a0
 rts

; Called even on 020 without the private scene renderer. Native full redraw,
; dirty dashboard, view/fullscreen, top text, firing and live messages all
; invalidate BOTH pages. Resource changes use the shared bit14 lifetime hooks.
gauge_fast_entry:
 movem.l d0/a0,-(sp)
 move.l instrument_cache_h3(pc),a0
 adda.l #$4000,a0
 tst.w 12(sp) ; original stack argument (saved d0/a0 + return)
 bne .dirty
 tst.b $311c(a0)
 bne .dirty
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
 tst.w $24f6(a0) ; exceptional foreground scripts 28/29
 bne .dirty
 tst.w $1830(a0)
 beq .done
.dirty
 bsr instrument_cache_invalidate
.done
 movem.l (sp)+,d0/a0
 link a5,#-32
 movem.l d2/d4-d7/a2-a3/a6,-(sp)
gauge_fast_entry_tail:
 jmp $0.l

; Reuse only while cockpit composition has established the exact current static layers. The
; viewport and ALL later artwork must end before the retained needle bounds.
; Sparse lists are ordered by offset, so their final record proves that bound
; in O(1), without reading Chip RAM or assuming a particular aircraft layout.
; d0=1 accepted, 0 redraw. a6=IC slot. Preserve all other registers.
gauge_fast_can_reuse:
 movem.l d1-d3/a0-a1,-(sp)
 btst #0,cockpit_fast_applied+1(pc)
 beq .bad
 moveq #0,d3
 move.w scene_frame_view(pc),d3
 add.w scene_frame_view+2(pc),d3
 mulu.w #40,d3
 move.l artwork_solid_entry(pc),a0
 bsr .extent
 move.l artwork_front_fast(pc),a0
 bsr .extent
 move.l artwork_front_fast(pc),a0
 adda.l #OC_ENTRY,a0
 bsr .extent
 moveq #0,d0
 move.w IC_AREA+2(a6),d0
 mulu.w #40,d0
 cmp.l d3,d0
 blo .bad
 moveq #1,d0
 bra .done
.bad
 moveq #0,d0
.done
 movem.l (sp)+,d1-d3/a0-a1
 rts
.extent
 move.l OC_PIXELS(a0),a0 ; cockpit composition applied implies all three valid entries
 moveq #0,d0
 move.w (a0),d0
 beq .empty
 subq.w #1,d0
 mulu.w #14,d0
 adda.l d0,a0
 moveq #0,d0
 move.w 2(a0),d0
 addq.l #2,d0
 cmp.l d3,d0
 bls .empty
 move.l d0,d3
.empty
 rts

gauge_fast_allocate:
 movem.l d0-d1/a0-a1/a6,-(sp)
 lea gauge_fast_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 move.l #GF_STRIDE*7,d0
 move.l #$10004,d1
 jsr _LVOAllocMem(a6)
 lea gauge_fast_pool(pc),a0
 move.l d0,(a0)
.done
 movem.l (sp)+,d0-d1/a0-a1/a6
 rts

gauge_fast_restore:
 movem.l d0-a6,-(sp)
 move.l instrument_cache_h3(pc),a4
 adda.l #$8000,a4
 cmpi.w #6,d4
 bhi .native
 cmpa.l #0,a2
 beq .native
 cmpi.l #8000,$1d34(a4)
 bne .native
 cmpi.w #5,$1d3c(a4)
 bne .native
 cmpi.w #320,$1d40(a4)
 bne .native
 cmpi.w #40,$1d42(a4)
 bne .native
 cmpi.w #200,$1d44(a4)
 bne .native
 ; Avoid high-coordinate flag adjustment in sim:30408.
 move.l d6,d0
 swap d0
 tst.w d0
 bne .native
 move.l d5,d0
 swap d0
 tst.w d0
 bne .native
 bsr gauge_fast_allocate
 move.l gauge_fast_pool(pc),d0
 beq .native
 move.l d0,a6
 move.w d4,d0
 mulu.w #GF_STRIDE,d0
 adda.l d0,a6
 lea gauge_fast_key(pc),a1
 move.l a2,(a1)+
 move.w d6,(a1)+
 move.w d5,(a1)+
 move.l a2,a0
 moveq #8,d0
.key
 move.w (a0)+,(a1)+
 dbf d0,.key
 tst.l (a6)
 beq .refill
 lea gauge_fast_key(pc),a0
 lea 4(a6),a1
 moveq #12,d0
.compare
 cmpm.w (a0)+,(a1)+
 bne .refill
 dbf d0,.compare
 bra .ready
.refill
 clr.l (a6)
 lea gauge_fast_key(pc),a0
 lea 4(a6),a1
 moveq #12,d0
.copy_key
 move.w (a0)+,(a1)+
 dbf d0,.copy_key
 lea GF_PIXELS(a6),a0
 move.w #GF_PLANE*6/4-1,d0
.clear
 clr.l (a0)+
 dbf d0,.clear
 move.l a2,a0
 bsr gauge_fast_pack
 tst.l d0
 beq .native
 move.l #1,(a6)
.ready
 bsr gauge_fast_wait
 bsr gauge_fast_paint
 movem.l (sp)+,d0-a6
 move.l d4,d0 ; displaced sim:19d9c, native temporary outputs dead here
 rts
.native
 movem.l (sp)+,d0-a6
 bsr gauge_fast_native
 move.l d4,d0
 rts
gauge_fast_native:
 jmp $0.l

; Packed screen-aligned resource words, clipped to the native inclusive limits.
; All source/mask reads are Fast RAM. Opaque words need no Chip read.
; a6=record, a4=h3+$8000. Native callback runs immediately afterward.
gauge_fast_paint:
 movem.l d0-d7/a0-a5,-(sp)
 move.w GF_AREA+2(a6),d3
 move.w GF_AREA+6(a6),d7
 subq.w #1,d7
 lea GF_MASK(a6),a2
 lea GF_PIXELS(a6),a3
.row
 move.w GF_AREA(a6),d2
 move.w GF_AREA+4(a6),d6
 lsr.w #1,d6
 subq.w #1,d6
.word
 move.w (a2)+,d0
 tst.w $1d46(a4)
 beq .mask_ready
 cmp.w $1d4c(a4),d3
 blt .next
 cmp.w $1d4e(a4),d3
 bgt .next
 move.w d2,d1
 lsl.w #3,d1
 move.w $1d48(a4),d4
 sub.w d1,d4
 ble .left_ready
 cmpi.w #16,d4
 bge .next
 moveq #-1,d5
 lsr.w d4,d5
 and.w d5,d0
.left_ready
 addi.w #15,d1
 sub.w $1d4a(a4),d1
 ble .mask_ready
 cmpi.w #16,d1
 bge .next
 moveq #-1,d5
 lsl.w d1,d5
 and.w d5,d0
.mask_ready
 tst.w d0
 beq .next
 move.w d3,d1
 mulu.w #40,d1
 add.w d2,d1
 move.l $1d72(a4),a0
 adda.l d1,a0
 move.l a3,a1
 move.w d2,-(sp)
 moveq #4,d4
 move.w d0,d5
 not.w d5
.plane
 move.w (a1),d1
 and.w d0,d1
 tst.w d5
 beq .opaque
 move.w (a0),d2
 and.w d5,d2
 or.w d2,d1
.opaque
 move.w d1,(a0)
 adda.l #8000,a0
 adda.l #GF_PLANE,a1
 dbf d4,.plane
 move.w (sp)+,d2
.next
 addq.l #2,a3
 addq.w #2,d2
 dbf d6,.word
 addq.w #1,d3
 dbf d7,.row
 movem.l (sp)+,d0-d7/a0-a5
 rts

gauge_fast_pack:
 link a5,#-16
 movem.l d1-d7/a0-a4,-(sp)
 tst.w 16(a0)
 bne gf_pack_bad
 move.l (a0),d0
 beq gf_pack_bad
 btst #0,d0
 bne gf_pack_bad
 move.w d6,d2
 bmi gf_pack_bad
 move.w d5,d3
 bmi gf_pack_bad
 moveq #0,d4
 move.w 8(a0),d4
 beq gf_pack_bad
 cmpi.w #96,d4
 bhi gf_pack_bad
 addi.w #15,d4
 lsr.w #4,d4
 add.w d4,d4 ; colour pitch
 move.w 10(a0),d5
 beq gf_pack_bad
 cmpi.w #64,d5
 bhi gf_pack_bad
 move.w d4,d0
 mulu.w d5,d0
 cmp.l 12(a0),d0
 bne gf_pack_bad
 move.w d4,-2(a5)
 addq.w #2,-2(a5) ; source mask pitch includes one zero pad word
 lsl.w #3,d4
 move.w d2,d0
 add.w d4,d0
 bcs gf_pack_bad
 cmpi.w #320,d0
 bhi gf_pack_bad
 move.w d3,d1
 add.w d5,d1
 bcs gf_pack_bad
 cmpi.w #200,d1
 bhi gf_pack_bad
 move.l 4(a0),a1
 move.l a1,d0
 beq gf_pack_bad
 btst #0,d0
 bne gf_pack_bad
 move.w d2,d0
 lsr.w #4,d0
 add.w d0,d0
 move.w d0,GF_AREA(a6)
 move.w d3,GF_AREA+2(a6)
 move.w d2,d1
 add.w d4,d1
 addi.w #15,d1
 lsr.w #4,d1
 add.w d1,d1
 sub.w d0,d1
 move.w d1,GF_AREA+4(a6)
 move.w d5,GF_AREA+6(a6)
 move.w d1,d0
 mulu.w d5,d0
 cmpi.l #GF_PLANE,d0
 bhi gf_pack_bad
 move.l a6,a4
 adda.l #GF_MASK,a4
gf_pack_row:
 move.w -2(a5),d0
 subq.w #2,d0
 tst.w 0(a1,d0.w)
 bne gf_pack_bad
 moveq #0,d6
gf_pack_pixel:
 move.w d6,d0
 lsr.w #3,d0
 move.w d6,d1
 andi.w #7,d1
 moveq #7,d7
 sub.w d1,d7
 btst d7,0(a1,d0.w)
 beq gf_pack_next
 move.w d2,d0
 add.w d6,d0
 move.w d0,d1
 andi.w #7,d1
 moveq #7,d7
 sub.w d1,d7
 lsr.w #3,d0
 sub.w GF_AREA(a6),d0
 move.w d3,d1
 sub.w GF_AREA+2(a6),d1
 mulu.w GF_AREA+4(a6),d1
 add.w d0,d1
 bset d7,0(a4,d1.w)
 ; Seed colour from the resource, never from the old rendered frame. Native
 ; background redraws can be clipped to the previous needle rectangle.
 movem.l d2/d4/a2-a3,-(sp)
 moveq #0,d0
 move.w d6,d0
 lsr.w #3,d0
 move.l (a0),a2
 ; a1 advances by mask pitch; colour rows omit the trailing mask pad word.
 move.l a1,d2
 sub.l 4(a0),d2
 divu.w -2(a5),d2
 andi.l #$ffff,d2
 move.w -2(a5),d4
 subq.w #2,d4
 mulu.w d4,d2
 add.l d2,d0
 adda.l d0,a2
 lea GF_PIXELS(a6),a3
 adda.w d1,a3
 move.w d6,d2
 andi.w #7,d2
 neg.w d2
 addq.w #7,d2
 moveq #4,d4
.colour
 btst d2,(a2)
 beq .colour_next
 bset d7,(a3)
.colour_next
 adda.l 12(a0),a2
 adda.l #GF_PLANE,a3
 dbf d4,.colour
 movem.l (sp)+,d2/d4/a2-a3
gf_pack_next:
 addq.w #1,d6
 cmp.w d4,d6
 blo gf_pack_pixel
 adda.w -2(a5),a1
 addq.w #1,d3
 subq.w #1,d5
 bne gf_pack_row
 moveq #1,d0
 bra gf_pack_done
gf_pack_bad:
 moveq #0,d0
gf_pack_done:
 movem.l (sp)+,d1-d7/a0-a4
 unlk a5
 rts

gauge_fast_wait:
 tst.w $dff002
.wait
 btst #6,$dff002
 bne .wait
 rts

gauge_fast_enabled: dc.w 0
gauge_fast_attempted: dc.w 0
gauge_fast_pool: dc.l 0
gauge_fast_key: dcb.b 28,0
