; E2 persistent full-cockpit composition, ordered back to front.
; Runtime integration supplies cached static artwork, seven gauge layers and
; foreground scripts. This primitive updates only the union of old/new dirty
; rectangles; the completed image/mask is suitable for one masked publication.
; No game hooks yet: this is the update core, not an enabled feature.
;
; a0=array of {image.l,mask.l}, d0.w=1..10 layers, back to front.
; Each nonempty image has five 8000-byte planes, mask has 8000 bytes.
; A null image AND null mask denotes an empty layer. Sources are private FAST
; caches and disjoint from the output. Caller owns their allocation bounds.
; a1=48000-byte composite (40000 pixel bytes, then shared 8000-byte mask).
; a2=dirty rectangle: left byte, top row, byte width, row count (four words).
; Left/width are even; the rectangle must lie within 40 bytes x 200 rows.
; First update covers the full screen; later rectangles include old AND new
; coverage of every changed layer. Layer pixels need not be premasked.
; d0=1 success, 0 unsupported; preserve all other registers, CCR volatile.
; Rejected inputs leave the composite untouched. 020+ only.
;
; Walk front to back. Once a pixel is covered, lower layers cannot change it.
; Rebuilding the dirty union also removes pixels exposed by a moving/shrinking
; layer. OR-of-colours is never used as a coverage test: opaque black is data.
cockpit_compose_update:
 link a6,#-24
 movem.l d1-d7/a0-a5,-(sp)
 lea .cpu(pc),a3
.cpu
 adda.l #perf_attnflags+3-.cpu,a3
 btst #1,(a3)
 beq cc_update_bad
 cmpi.w #1,d0
 blo cc_update_bad
 cmpi.w #10,d0
 bhi cc_update_bad
 move.l a0,d1
 beq cc_update_bad
 move.l a1,d2
 beq cc_update_bad
 or.l d2,d1
 move.l a2,d2
 beq cc_update_bad
 or.l d2,d1
 btst #0,d1
 bne cc_update_bad
 move.l a0,-4(a6)
 lsl.w #3,d0
 adda.w d0,a0
 move.l a0,-8(a6) ; end of layer array
 move.w (a2),d0
 bmi cc_update_bad
 btst #0,d0
 bne cc_update_bad
 move.w 4(a2),d1
 ble cc_update_bad
 btst #0,d1
 bne cc_update_bad
 add.w d1,d0
 bcs cc_update_bad
 cmpi.w #40,d0
 bhi cc_update_bad
 move.w 2(a2),d0
 bmi cc_update_bad
 move.w 6(a2),d1
 ble cc_update_bad
 add.w d1,d0
 bcs cc_update_bad
 cmpi.w #200,d0
 bhi cc_update_bad
 ; Validate every layer before the first destination write.
 move.l -4(a6),a3
cc_update_validate:
 move.l (a3)+,d0
 move.l (a3)+,d1
 tst.l d0
 beq cc_update_empty
 tst.l d1
 beq cc_update_bad
 or.l d1,d0
 btst #0,d0
 bne cc_update_bad
 bra cc_update_validated
cc_update_empty:
 tst.l d1
 bne cc_update_bad
cc_update_validated:
 cmpa.l -8(a6),a3
 blo cc_update_validate
 moveq #0,d0
 move.w 2(a2),d0
 mulu.w #40,d0
 add.w (a2),d0
 move.l d0,-12(a6) ; current screen byte offset
 move.w 6(a2),-14(a6)
 move.w 4(a2),d0
 lsr.w #1,d0
 move.w d0,-18(a6) ; words per row
 moveq #40,d0
 sub.w 4(a2),d0
 move.w d0,-20(a6) ; row gap
cc_update_row:
 move.w -18(a6),-16(a6)
cc_update_word:
 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 moveq #0,d6
 moveq #0,d7 ; accumulated coverage
 move.l -8(a6),a3
cc_update_layer:
 subq.l #8,a3
 move.l 4(a3),d0
 beq cc_update_next_layer
 move.l d0,a4
 adda.l -12(a6),a4
 move.w d7,d0
 not.w d0
 and.w (a4),d0 ; only coverage not already supplied by later layers
 beq cc_update_next_layer
 or.w d0,d7
 move.l (a3),a4
 adda.l -12(a6),a4
 move.w (a4),d1
 and.w d0,d1
 or.w d1,d2
 move.w 8000(a4),d1
 and.w d0,d1
 or.w d1,d3
 move.w 16000(a4),d1
 and.w d0,d1
 or.w d1,d4
 move.w 24000(a4),d1
 and.w d0,d1
 or.w d1,d5
 move.w 32000(a4),d1
 and.w d0,d1
 or.w d1,d6
 cmpi.w #$ffff,d7
 beq cc_update_store
cc_update_next_layer:
 cmpa.l -4(a6),a3
 bhi cc_update_layer
cc_update_store:
 move.l a1,a4
 adda.l -12(a6),a4
 move.w d2,(a4)
 move.w d3,8000(a4)
 move.w d4,16000(a4)
 move.w d5,24000(a4)
 move.w d6,32000(a4)
 adda.l #40000,a4
 move.w d7,(a4)
 addq.l #2,-12(a6)
 subq.w #1,-16(a6)
 bne cc_update_word
 moveq #0,d0
 move.w -20(a6),d0
 add.l d0,-12(a6)
 subq.w #1,-14(a6)
 bne cc_update_row
 moveq #1,d0
 bra cc_update_done
cc_update_bad:
 moveq #0,d0
cc_update_done:
 movem.l (sp)+,d1-d7/a0-a5
 unlk a6
 rts
