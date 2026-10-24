; Title and intro CPU code/data share the later main-image destination.
; Native Chip copies retain the embedded copper lists, including temporary
; startup lists. Typed absolute operands and audited palette/dispatch pointers
; move; PC-relative copper LEAs use appended stubs to retain their Chip targets.
; All preflight checks precede copy/patch/publication; unsuitable memory or an
; unexpected module retains its original entry. Cache flush publishes each copy.
public_boot_title:
 lea public_boot_title_info(pc),a0
 bra public_boot_copy
public_boot_intro:
 lea public_boot_intro_info(pc),a0
public_boot_copy:
 movem.l d0-d7/a0-a6,-(a7)
 move.l _enhanced_framerate(pc),d0
 beq .done
 move.l _expmem(pc),a5
 cmpa.l #$200000,a5
 bcs .done
 cmpa.l #$a00000,a5
 bcs .placement
 cmpa.l #$1000000,a5
 bcs .done
.placement:
 move.l a0,a6
 cmpi.w #$4ef9,$8000
 bne .done
 move.l (a6)+,d0
 cmp.l $8002,d0
 bne .done
 move.w (a6)+,d6
 move.l (a6)+,d0
 lea _base(pc),a0
 adda.l d0,a0
 lea $8000,a1
 bsr public_boot_validate
 bne .done
 move.w d6,d0
 move.l (a6)+,d1
 move.l (a6)+,d2
 lea $5000(a5),a5
 lea $8000,a0
 move.l a5,a1
.copy:
 move.w (a0)+,(a1)+
 dbf d0,.copy
 move.l a5,d7
 sub.l #$8000,d7
 lea _base(pc),a6
 adda.l d1,a6
.fix:
 moveq #0,d0
 move.w (a6)+,d0
 cmpi.w #-1,d0
 beq .relative
 move.l a5,a1
 adda.l d0,a1
 move.l (a1),d1
 cmpi.l #$8000,d1
 bcs .fix
 cmpi.l #$17e86,d1
 bcc .fix
 add.l d7,(a1)
 bra .fix
.relative:
 lea _base(pc),a6
 adda.l d2,a6
.next:
 moveq #0,d0
 move.w (a6)+,d0
 cmpi.w #-1,d0
 beq .publish
 move.l a5,a1
 adda.l d0,a1
 moveq #0,d1
 move.w (a6)+,d1
 move.l a5,a2
 adda.l d1,a2
 sub.w d0,d1
 subq.w #2,d1
 move.w #$6100,(a1)+
 move.w d1,(a1)
 move.w #$43f9,(a2)+
 move.l (a6)+,(a2)+
 move.w #$4e75,(a2)
 bra .next
.publish:
 cmpi.w #4099,d6
 bne .entry
 lea _base(pc),a0
 adda.l #public_intro_index_install-_base,a0
 jsr (a0)
.entry:
 move.w #$4ef9,$8000
 move.l a5,$8002
 move.l _resload(pc),a2
 jsr (resload_FlushCache,a2)
.done:
 movem.l (a7)+,d0-d7/a0-a6
 rts
public_boot_title_info:
 dc.l $12896
 dc.w 32578
 dc.l public_boot_title_check-_base
 dc.l public_boot_title_refs-_base,public_boot_title_relative-_base
public_boot_intro_info:
 dc.l $8a68
 dc.w 4099
 dc.l public_boot_intro_check-_base
 dc.l public_boot_intro_refs-_base,public_boot_intro_relative-_base
; a0: six-byte (offset, expected longword) records terminated by -1.
; a1: native module base. Return Z only if every audited operand matches.
; Check before copying or publishing, preserving all caller registers.
public_boot_validate:
 movem.l d0-d1/a0-a2,-(a7)
.next:
 moveq #0,d0
 move.w (a0)+,d0
 cmpi.w #-1,d0
 beq .done
 move.l a1,a2
 adda.l d0,a2
 move.l (a0)+,d1
 cmp.l (a2),d1
 beq .next
.done:
 movem.l (a7)+,d0-d1/a0-a2
 rts
