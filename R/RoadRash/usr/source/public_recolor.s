; CPU-only colour conversion lifetime of the shared Chip graphics scratch.
; All six generators and their twelve consumers use a separate 16 KiB table.
; Blitter scratch and menu images retain their original Chip addresses.
public_recolor_init:
 lea public_recolor_sites(pc),a0
.check:
 move.l (a0)+,d0
 bmi .install
 move.l a5,a1
 adda.l d0,a1
 move.w (a0)+,d1
 cmp.w (a1),d1
 bne .done
 cmpi.l #$da7e,2(a1)
 bne .done
 bra .check
.install:
 move.l _expmem(pc),d1
 addi.l #$61000,d1
 lea public_recolor_sites(pc),a0
.next:
 move.l (a0)+,d0
 bmi .done
 addq.l #2,a0
 move.l a5,a1
 adda.l d0,a1
 move.l d1,2(a1)
 bra .next
.done:
 rts
public_recolor_sites:
 dc.l $31dde
 dc.w $43f9
 dc.l $31dee
 dc.w $4df9
 dc.l $31dfc
 dc.w $4df9
 dc.l $31e0a
 dc.w $4df9
 dc.l $31e18
 dc.w $4df9
 dc.l $31edc
 dc.w $43f9
 dc.l $31eec
 dc.w $4df9
 dc.l $31efa
 dc.w $4df9
 dc.l $31f08
 dc.w $4df9
 dc.l $31f86
 dc.w $43f9
 dc.l $31f94
 dc.w $4df9
 dc.l $31fdc
 dc.w $43f9
 dc.l $31fea
 dc.w $4df9
 dc.l $32032
 dc.w $43f9
 dc.l $32040
 dc.w $4df9
 dc.l $3204e
 dc.w $4df9
 dc.l $320a4
 dc.w $43f9
 dc.l $320b2
 dc.w $4df9
 dc.l -1
