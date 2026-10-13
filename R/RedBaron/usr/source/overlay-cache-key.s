; Exact input keys for the sparse static gun-artwork cache.
; a0=OVERLAY_KEY_BYTES buffer, a1=h3, d0.w=program (3 or 4).
; d0.l=1 supported / 0 native fallback; all other registers preserved.
; CPU-neutral. Shared resource lifetime invalidation is required.
; Pixel coverage/geometry is separately accepted by overlay_mask_build.
; Dependencies precede every followed pointer. Snapshot bytes are exact, not hashes.
overlay_cache_key_build:
 link a6,#-20
 movem.l d1-d7/a0-a5,-(sp)
 move.l a0,a5
 move.l a1,a4
 adda.l #$8000,a4
 clr.l (a5)
 clr.l 4(a5)
 clr.w OVERLAY_KEY_EFFECTS(a5)
 cmpi.w #3,d0
 blo .fail
 cmpi.w #4,d0
 bhi .fail
 move.w d0,2(a5)
 lsl.w #2,d0
 lea -$4ae(a4),a1 ; h3:7b52 program table
 adda.w d0,a1
 moveq #4,d0
 bsr .append
 tst.l d0
 beq .fail
 move.l (a1),d0
 beq .fail
 move.l d0,a3
 move.l a3,-4(a6)
 addi.l #512,d0
 move.l d0,-8(a6)
 ; First find the bounded end without following resource pointers.
.scan
 cmpa.l -8(a6),a3
 bhs .fail
 move.w (a3)+,d0
 cmpi.w #$0ff0,d0
 beq .scanned
 bsr .operand_size
 tst.w d0
 bmi .fail
 adda.w d0,a3
 bra .scan
.scanned
 move.l a3,d0
 sub.l -4(a6),d0
 move.l -4(a6),a1
 bsr .append
 tst.l d0
 beq .fail
 ; Geometry and clipping only: mutable output pens are not dependencies.
 lea $1d34(a4),a1
 moveq #28,d0
 bsr .append
 tst.l d0
 beq .fail
 lea -$4549(a4),a1 ; h3:3ab7 original colours and signed selectors
 moveq #10,d0
 bsr .append
 tst.l d0
 beq .fail
 moveq #1,d7
.palette
 lea -$4541(a4),a1 ; h3:3abf selectors
 move.b 0(a1,d7.w),d0
 ext.w d0
 lsl.w #2,d0
 lea -$6fe3(a4),a1 ; h3:101d remapped colours
 adda.w d0,a1
 moveq #4,d0
 bsr .append
 tst.l d0
 beq .fail
 dbf d7,.palette
 clr.l -12(a6) ; selected image table
 clr.l -16(a6) ; selected descriptor
 clr.w -18(a6) ; a colour command dominates each drawing command
 move.l -4(a6),a3
.next
 move.w (a3)+,d0
 cmpi.w #$0ff0,d0
 beq .success
 cmpi.w #$2002,d0
 beq .colour
 cmpi.w #$1051,d0
 beq .set
 cmpi.w #$1031,d0
 beq .image
 tst.w -18(a6)
 beq .fail
 cmpi.w #$a502,d0
 beq .bitmap
 cmpi.w #$a104,d0
 bne .not_rectangle
 ori.w #16,OVERLAY_KEY_EFFECTS(a5)
.not_rectangle
 ; Only lines/filled rectangles survive the bounded first pass.
 addq.l #8,a3
 bra .next
.colour
 ori.w #1,OVERLAY_KEY_EFFECTS(a5)
 move.w #1,-18(a6)
 addq.l #4,a3
 bra .next
.set
 ori.w #2,OVERLAY_KEY_EFFECTS(a5)
 moveq #0,d0
 move.w (a3)+,d0
 bmi .fail
 lsl.l #2,d0
 lea -$44fe(a4),a1 ; h3:3b02 image table slots
 adda.l d0,a1
 moveq #4,d0
 bsr .append
 tst.l d0
 beq .fail
 move.l (a1),-12(a6)
 beq .fail
 clr.l -16(a6)
 bra .next
.image
 ori.w #4,OVERLAY_KEY_EFFECTS(a5)
 move.l -12(a6),d0
 beq .fail
 move.l d0,a1
 moveq #0,d0
 move.w (a3)+,d0
 bmi .fail
 lsl.l #2,d0
 adda.l d0,a1
 moveq #4,d0
 bsr .append
 tst.l d0
 beq .fail
 move.l (a1),-16(a6)
 beq .fail
 move.l -16(a6),a1
 moveq #18,d0
 bsr .append
 tst.l d0
 beq .fail
 bra .next
.bitmap
 ori.w #8,OVERLAY_KEY_EFFECTS(a5)
 move.l -16(a6),d0
 beq .fail
 move.l d0,a2
 tst.w 16(a2) ; only native orientation zero
 bne .fail
 moveq #0,d1
 move.w 8(a2),d1
 beq .fail
 cmpi.w #320,d1
 bhi .fail
 addi.w #15,d1
 lsr.w #4,d1
 add.w d1,d1 ; rounded row pitch
 moveq #0,d2
 move.w 10(a2),d2
 beq .fail
 cmpi.w #200,d2
 bhi .fail
 move.w d1,d0
 mulu.w d2,d0
 cmp.l 12(a2),d0
 bne .fail
 mulu.w #5,d0
 move.l (a2),a1
 move.l a1,d3
 beq .fail
 bsr .append_resource
 tst.l d0
 beq .fail
 addq.w #2,d1 ; native source masks have a pad word per row
 move.w d1,d0
 mulu.w d2,d0
 move.l 4(a2),a1
 move.l a1,d3
 beq .fail
 bsr .append_resource
 tst.l d0
 beq .fail
 addq.l #4,a3
 bra .next
.success
 move.w #1,(a5)
 moveq #1,d0
 bra .done
.fail
 clr.w (a5)
 moveq #0,d0
.done
 movem.l (sp)+,d1-d7/a0-a5
 unlk a6
 rts
.append
 move.l a5,a0
 bra overlay_key_append
; FC11 marks only bitmap/mask bytes. All selecting pointers and the complete
; mutable descriptor stay ordered exact ranges ahead of their resources.
.append_resource
 bsr .append
 tst.l d0
 beq .resource_done
 btst #0,overlay_generation_enabled+1(pc)
 beq .resource_done
 movem.l d1/a0,-(sp)
 moveq #0,d1
 move.w 4(a5),d1
 subq.w #1,d1
 mulu.w #12,d1
 lea 18(a5),a0
 adda.l d1,a0
 move.w overlay_resource_epoch(pc),(a0)
 movem.l (sp)+,d1/a0
.resource_done
 rts
.operand_size
 cmpi.w #$2002,d0
 beq .four
 cmpi.w #$a502,d0
 beq .four
 cmpi.w #$1051,d0
 beq .two
 cmpi.w #$1031,d0
 beq .two
 cmpi.w #$a104,d0
 beq .eight
 cmpi.w #$a0a4,d0
 beq .eight
 moveq #-1,d0
 rts
.two
 moveq #2,d0
 rts
.four
 moveq #4,d0
 rts
.eight
 moveq #8,d0
 rts
