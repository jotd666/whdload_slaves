; Small-picture/shop and local-player descriptions in two 128-byte slots.
; Pixels and shared blitter scratch stay Chip. Readers are patched only after
; a complete bounded copy; load/depack and native SET relocation stay Chip.
public_menu_init:
 lea public_menu_readers(pc),a0
.check:
 move.l (a0)+,d0
 bmi .ready
 move.l a5,a1
 adda.l d0,a1
 cmpi.w #$41f9,(a1)
 bne .done
 move.l (a0)+,d0
 cmp.l 2(a1),d0
 bne .done
 bra .check
.ready:
 lea public_menu_image(pc),a0
 move.l a5,(a0)
 move.l a5,a1
 adda.l #$28a64,a1
 cmpi.w #$4eb9,(a1)
 bne .done
 move.l a5,d0
 addi.l #$327fc,d0
 cmp.l 2(a1),d0
 bne .done
 lea public_menu_joystick_call+2(pc),a0
 move.l d0,(a0)
 lea public_menu_joystick(pc),a0
 move.l a0,2(a1)
.done:
 rts
public_menu_relocate:
 movem.l d0-d3/a0-a4,-(a7)
 move.l public_menu_image(pc),a4
 cmpa.l #0,a4
 beq .done
 move.l _expmem(pc),a1
 adda.l #$4e080,a1
 moveq #0,d3
 cmpa.l #$da7e,a0
 beq .selected
 move.l $4ee.w,d0
 addi.l #$da7e,d0
 cmp.l a0,d0
 bne .done
 adda.w #128,a1
 moveq #1,d3
.selected:
 move.l a0,d1
 moveq #0,d0
 move.w (a0),d0
 beq .publish
 mulu.w #14,d0
 addq.l #2,d0
 cmpi.l #128,d0
 bhi .publish
 move.l a1,d1
 lsr.w #1,d0
 subq.w #1,d0
.copy:
 move.w (a0)+,(a1)+
 dbf d0,.copy
.publish:
 tst.w d3
 bne .local
 addq.l #2,d1
 move.l a4,a1
 adda.l #$1e70,a1
 move.l d1,(a1)
 move.l a4,a1
 adda.l #$4a82,a1
 move.l d1,(a1)
 bra .flush
.local:
 sub.l $4ee.w,d1
 move.l a4,a1
 adda.l #$1d60,a1
 move.l d1,(a1)
.flush:
 move.l _resload(pc),a2
 jsr (resload_FlushCache,a2)
.done:
 movem.l (a7)+,d0-d3/a0-a4
 rts
public_menu_image:
 dc.l 0
public_menu_readers:
 dc.l $1e6e,$da80
 dc.l $4a80,$da80
 dc.l $1d5e,$da7e
 dc.l -1

; Joystick image is CPU-copied to the Chip portrait scratch before
; drawing. Keep its 2224-byte stored source in an existing 3584-byte gap.
public_menu_joystick:
public_menu_joystick_call:
 jsr $12345678
 move.w sr,-(a7)
 movem.l d0-d1/a0-a1,-(a7)
 move.l $4f2.w,d0
 beq .done
 cmpi.l #$e00,d0
 bhi .done
 btst #0,d0
 bne .done
 move.l _expmem(pc),a1
 adda.l #$4e180,a1
 move.l a1,d1
 move.l $4e6.w,a0
 lsr.w #1,d0
 subq.w #1,d0
.copy:
 move.w (a0)+,(a1)+
 dbf d0,.copy
 move.l d1,$4e6.w
.done:
 movem.l (a7)+,d0-d1/a0-a1
 move.w (a7)+,ccr
 rts
