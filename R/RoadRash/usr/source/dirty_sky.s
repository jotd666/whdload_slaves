; Conservative full-width dirty rectangles, one per back buffer. Opaque scenery
; and the road/ground boundary seed the next rectangle; clipped bobs extend it
; upwards. Unknown CPU rendering and overlays invalidate the optimization.
e_dirty_reset:
 lea e_dirty_top(pc),a0
 clr.l (a0)
 rts

e_dirty_prepare:
 movem.l d0-d7/a0-a6,-(a7)
 bsr e_dirty_slot
 bcs .done
 move.w (a0),d7
 ; Native CPU bobs have additional write paths: conservatively redraw all sky.
 tst.w $416.w
 bne .invalidate
 move.l e_main(pc),a1
 adda.l #$2720a,a1
 cmpi.w #366,(a1)
 blt .known
.invalidate:
 moveq #0,d7
.known:
 lea e_ring(pc),a1
 move.w d6,d0
 move.w 14(a1),d1
 lsr.w #6,d1
 cmp.w d1,d0
 bls .mountain
 move.w d1,d0
.mountain:
 move.w 22(a1),d1
 lsr.w #6,d1
 cmp.w d1,d0
 bls .next_top
 move.w d1,d0
.next_top:
 move.w d0,(a0)
 ; Each descriptor retains its own end (the opaque overwrite boundary).
 moveq #42,d5
 mulu.w d7,d5
 moveq #3,d4
.clip:
 move.w 6(a1),d0
 lsr.w #6,d0
 sub.w d7,d0
 ble .empty
 add.l d5,(a1)
 lsl.w #6,d0
 ori.w #20,d0
 move.w d0,6(a1)
 bra .next
.empty:
 clr.w 6(a1)
.next:
 addq.l #8,a1
 dbf d4,.clip
.done:
 movem.l (a7)+,d0-d7/a0-a6
 rts

; Return A0 = matching dirty-top word, carry set for an unknown buffer.
e_dirty_slot:
 lea e_dirty_top(pc),a0
 cmpi.l #$6f780,$408.w
 beq .known
 addq.l #2,a0
 cmpi.l #$77cc0,$408.w
 beq .known
 ori #1,ccr
 rts
.known:
 andi #$fe,ccr
 rts

; A3 is the clipped destination in plane 0, before native pointer increments.
e_dirty_mark:
 move.w sr,-(a7)
 movem.l d0-d1/a0,-(a7)
 bsr e_dirty_slot
 bcs .done
 move.l a3,d0
 sub.l $408.w,d0
 bmi .top
 cmpi.l #8400,d0
 bcc .done
 divu.w #42,d0
 cmp.w (a0),d0
 bcc .done
 move.w d0,(a0)
 bra .done
.top:
 clr.w (a0)
.done:
 movem.l (a7)+,d0-d1/a0
 move.w (a7)+,ccr
 rts

e_dirty_alt:
 bsr e_dirty_mark
 lsr.w #3,d4
 adda.w d4,a1
 lsr.w #3,d5
 rts

e_dirty_top: dc.w 0,0
