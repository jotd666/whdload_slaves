; Cached opaque masks use the abandoned main-image Chip storage only after a
; validated public relocation. The low entry trampoline and native heap remain.
; CPU-only lookup entries live in the optional public extension.
e_masks_init:
 bsr e_cpu_init
 move.l a5,a1
 adda.l #$34296,a1
 lea e_dirty_alt(pc),a0
 move.w #$4eb9,(a1)
 move.l a0,2(a1)
 ; Recolour cache maintenance costs more than native mask blits on 68020.
 btst #2,cpu_attention+3(pc)
 beq .no_recolor
 ; Update cached masks after each native four-plane recolour exchange.
 move.l a5,a1
 adda.l #$30ee4,a1
 lea e_mask_recolor(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 move.w #$4e71,6(a1)
 lea e_recolor_jump(pc),a0
 move.l a5,d0
 addi.l #$30ec2,d0
 move.l d0,2(a0)
.no_recolor:
 lea e_mask_table(pc),a0
 move.l a5,d0
 addi.l #$60000,d0 ; main base = allocation + $5000
 move.l d0,(a0)
 lea e_masks_dirty(pc),a0
 move.w #1,(a0)
 move.l a5,a1
 adda.l #$33ba2,a1
 lea e_mask_enter(pc),a0
 move.w #$4eb9,(a1)
 move.l a0,2(a1)
 move.l a5,a1
 adda.l #$33c6e,a1
 lea e_mask_other(pc),a0
 move.w #$4eb9,(a1)
 move.l a0,2(a1)
 move.l a5,a1
 adda.l #$33c78,a1
 lea e_mask_draw(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 rts

e_masks_build:
 movem.l d0-d7/a0-a6,-(a7)
 move.w e_masks_dirty(pc),d0
 beq .done
 move.l e_mask_table(pc),a0
 cmpa.l #0,a0
 beq .done
 move.w #8192-1,d0
.clear:
 clr.l (a0)+
 dbf d0,.clear
 bsr e_cpu_reset
 lea e_mask_cursor(pc),a0
 move.l #$80010,(a0)
 lea $432.w,a6
 moveq #11,d7
.owners:
 move.l (a6)+,a0
 bsr e_mask_set
 dbf d7,.owners
 lea public_asset_fixed(pc),a6
 moveq #2,d7
.fixed:
 addq.l #4,a6
 move.l (a6)+,a0
 bsr e_mask_set
 dbf d7,.fixed
 lea e_masks_dirty(pc),a0
 clr.w (a0)
.done:
 movem.l (a7)+,d0-d7/a0-a6
 rts

e_mask_set:
 movem.l d0-d7/a0-a6,-(a7)
 cmpa.l #$400,a0
 bcs .done
 move.w (a0)+,d7
 beq .done
 cmpi.w #600,d7
 bhi .done
 subq.w #1,d7
.next:
 move.l a0,a6
 adda.w #14,a0
 move.l a0,-(a7)
 cmpi.w #15,12(a6)
 bne .skip
 move.l (a6),d4
 btst #2,cpu_attention+3(pc)
 bne .source
 cmpi.l #$19a7e,d4
 bcs .source
 cmpi.l #$5c2cc,d4
 bcs .skip
.source:
 moveq #0,d2
 move.w 4(a6),d2
 beq .skip
 cmpi.w #320,d2
 bhi .skip
 addi.w #15,d2
 lsr.w #4,d2
 add.w d2,d2
 moveq #0,d3
 move.w 6(a6),d3
 beq .skip
 cmpi.w #200,d3
 bhi .skip
 move.l d2,d5
 mulu.w d3,d5
 move.l d5,d0
 lsl.l #2,d0
 add.l d4,d0
 cmpi.l #$100000,d0
 bhi .skip
 cmpi.l #$80000,d4
 bcs .below
 cmpi.l #$bc3ec,d4
 bcs .skip
 bra .hash
.below:
 cmpi.l #$80000,d0
 bhi .skip
.hash:
 move.l e_mask_table(pc),a2
 move.l d4,d0
 lsr.l #1,d0
 andi.w #2047,d0
 lsl.w #4,d0
 move.w #2047,d6
.probe:
 lea (a2,d0.w),a3
 tst.l (a3)
 beq .new
 cmp.l (a3),d4
 beq .skip
 addi.w #16,d0
 andi.w #$7ff0,d0
 dbf d6,.probe
 bra .skip
.new:
 move.l e_mask_cursor(pc),a4
 move.l a4,d0
 add.l d5,d0
 ; Preserve menu image scratch and embedded pixels in the upper Chip image.
 cmpi.l #$a5de0,d0
 bhi .skip
 lea e_mask_cursor(pc),a1
 move.l d0,(a1)
 move.l d4,(a3)
 move.l a4,4(a3)
 move.w d2,8(a3)
 move.w d3,10(a3)
 bsr e_cpu_cache
 move.l d4,a1
 subq.w #1,d3
.row:
 move.l a1,a2
 move.w d2,d6
 lsr.w #1,d6
 subq.w #1,d6
.word:
 move.w (a2),d0
 or.w (a2,d2.w),d0
 adda.w d2,a2
 or.w (a2,d2.w),d0
 adda.w d2,a2
 or.w (a2,d2.w),d0
 suba.w d2,a2
 suba.w d2,a2
 move.w d0,(a4)+
 addq.l #2,a2
 dbf d6,.word
 move.w d2,d0
 lsl.w #2,d0
 adda.w d0,a1
 dbf d3,.row
.skip:
 move.l (a7)+,a0
 dbf d7,.next
.done:
 movem.l (a7)+,d0-d7/a0-a6
 rts

e_mask_enter:
 movem.l d0-d2/a0-a2,-(a7)
 lea e_mask_current(pc),a0
 clr.l (a0)
 move.w e_masks_dirty(pc),d0
 bne .done
 move.l e_mask_table(pc),a2
 cmpa.l #0,a2
 beq .done
 move.l a1,d1
 btst #2,cpu_attention+3(pc)
 bne .hash
 cmpi.l #$19a7e,d1
 bcs .hash
 cmpi.l #$5c2cc,d1
 bcs .done
.hash:
 move.l d1,d0
 lsr.l #1,d0
 andi.w #2047,d0
 lsl.w #4,d0
 move.w #2047,d2
.probe:
 lea (a2,d0.w),a1
 tst.l (a1)
 beq .done
 cmp.l (a1),d1
 beq .found
 addi.w #16,d0
 andi.w #$7ff0,d0
 dbf d2,.probe
 bra .done
.found:
 move.l a1,(a0)
.done:
 movem.l (a7)+,d0-d2/a0-a2
 bsr e_cpu_try
 move.w #$ffff,$55c.w
 rts

e_mask_other:
 bsr e_dirty_mark
 move.l a0,-(a7)
 lea e_mask_current(pc),a0
 clr.l (a0)
 move.l (a7)+,a0
 move.w #$ffff,$55c.w
 rts

e_mask_draw:
 bsr e_dirty_mark
 move.l a6,-(a7)
 move.l e_mask_current(pc),a6
 cmpa.l #0,a6
 bne .cached
 move.l (a7)+,a6
 asr.w #3,d4
 adda.w d4,a1
 asr.w #3,d5
 move.l e_main(pc),-(a7)
 addi.l #$33c7e,(a7)
 rts
.cached:
 movem.l d0-d7/a0-a5,-(a7)
 asr.w #3,d4
 adda.w d4,a1
 asr.w #3,d5
 lsr.w #4,d3
 move.w d3,d2
 add.w d2,d2
 ; Convert the clipped source address into its full-width mask address.
 move.l a1,d0
 sub.l (a6),d0
 move.w d2,d1
 lsl.w #2,d1
 divu.w d1,d0
 move.l d0,d1
 andi.l #$ffff,d0
 mulu.w d2,d0
 swap d1
 andi.l #$ffff,d1
 add.l d1,d0
 move.l 4(a6),a4
 adda.l d0,a4
 ; Width, source modulo and destination modulo for the clipped rectangle.
 move.w d4,d0
 add.w d5,d0
 move.w d0,d1
 lsr.w #1,d1
 sub.w d1,d3
 move.w d3,d1
 add.w d1,d1
 moveq #42,d4
 sub.w d1,d4
 move.w d2,d5
 add.w d5,d5
 add.w d2,d5
 add.w d0,d5
 ; d0 = A modulo; d5 = B modulo; d4 = C/D modulo.
 tst.w d6
 beq .size
 tst.w $55e.w
 bne .size
 addq.w #1,d3
 subq.w #2,d0
 subq.w #2,d4
 subq.w #2,d5
.size:
 lsl.w #6,d7
 add.w d3,d7
 bsr e_blitter_wait
 move.w d0,$64(a0)
 move.w d5,$62(a0)
 move.w d4,$60(a0)
 move.w d4,$66(a0)
 move.l #$ffffffff,$44(a0)
 tst.w d6
 beq .control
 move.w $55c.w,$44(a0)
 move.w $55e.w,$46(a0)
.control:
 ror.w #4,d6
 move.w d6,$42(a0)
 ori.w #$0fca,d6
 move.w d6,$40(a0)
 moveq #3,d5
.plane:
 bsr e_blitter_wait
 move.l a4,$50(a0)
 move.l a1,$4c(a0)
 move.l a3,$48(a0)
 move.l a3,$54(a0)
 move.w d7,$58(a0)
 adda.w d2,a1
 adda.l #$20d0,a3
 dbf d5,.plane
 movem.l (a7)+,d0-d7/a0-a5
 move.l (a7)+,a6
 rts

e_mask_table: dc.l 0
e_mask_cursor: dc.l 0
e_mask_current: dc.l 0
e_masks_dirty: dc.w 0
 even

; The original loop has already swapped planes 0..2; A4 points at plane 3.
e_mask_recolor:
 move.w d0,(a4)
 move.w sr,-(a7)
 movem.l d0-d6/a0-a3,-(a7)
 move.w e_masks_dirty(pc),d0
 bne .done
 move.l e_mask_table(pc),a0
 move.l a2,d4
 move.l d4,d0
 lsr.l #1,d0
 andi.w #2047,d0
 lsl.w #4,d0
 move.w #2047,d6
.probe:
 lea (a0,d0.w),a1
 tst.l (a1)
 beq .done
 cmp.l (a1),d4
 beq .found
 addi.w #16,d0
 andi.w #$7ff0,d0
 dbf d6,.probe
 bra .done
.found:
 moveq #0,d2
 move.w 8(a1),d2
 move.l a4,a3
 suba.w d2,a3
 suba.w d2,a3
 suba.w d2,a3
 bsr e_cpu_recolor
 move.l a3,d0
 sub.l d4,d0
 move.w d2,d3
 lsl.w #2,d3
 divu.w d3,d0
 move.l d0,d3
 andi.l #$ffff,d0
 mulu.w d2,d0
 swap d3
 andi.l #$ffff,d3
 add.l d3,d0
 move.l 4(a1),a0
 adda.l d0,a0
 move.w (a3),d0
 adda.w d2,a3
 or.w (a3),d0
 adda.w d2,a3
 or.w (a3),d0
 adda.w d2,a3
 or.w (a3),d0
 move.w d0,(a0)
.done:
 movem.l (a7)+,d0-d6/a0-a3
 move.w (a7)+,ccr
 dbf d7,e_recolor_jump
 rts
e_recolor_jump:
 jmp $0.l ; filled before the loader's final cache flush
