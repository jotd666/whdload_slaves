; IFF inputs are CPU-only. Reuse the 16 KiB colour table during screen loads;
; each recolouring invocation regenerates that table before consuming it.
; Preserve native output registers, CCR and the original source-relative A0.
public_iff_init:
 move.l a5,a1
 adda.l #$2eef6,a1
 cmpi.l #$7eff0c90,(a1)
 bne .done
 cmpi.l #$464f524d,4(a1)
 bne .done
 cmpi.l #$67085488,8(a1)
 bne .done
 cmpi.l #$51cffff4,12(a1)
 bne .done
 cmpi.w #$603e,16(a1)
 bne .done
 move.l a5,d0
 addi.l #$2ef08,d0
 lea public_iff_found+2(pc),a0
 move.l d0,(a0)
 addi.l #$3e,d0
 lea public_iff_missing+2(pc),a0
 move.l d0,(a0)
 lea public_iff_decode(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 move.w #$4e71,6(a1)
.done:
 rts
public_iff_decode:
 pea 0.w
 move.w sr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 cmpi.l #$464f524d,(a0)
 bne .native
 move.l 4(a0),d0
 addq.l #8,d0
 bcs .native
 cmpi.l #12,d0
 bcs .native
 cmpi.l #$4000,d0
 bhi .native
 btst #0,d0
 bne .native
 move.l _expmem(pc),a1
 adda.l #$61000,a1
 cmpa.l a1,a0
 beq .native
 move.l a0,d1
 sub.l a1,d1
 move.l d1,62(a7)
 move.l a1,32(a7)
 lsr.w #1,d0
 subq.w #1,d0
.copy:
 move.w (a0)+,(a1)+
 dbf d0,.copy
.native:
 movem.l (a7)+,d0-d7/a0-a6
 move.w (a7)+,ccr
 bsr .scan
 move.w sr,-(a7)
 move.l a1,-(a7)
 move.l 6(a7),a1
 adda.l a1,a0
 movem.l (a7)+,a1
 move.w (a7)+,ccr
 addq.l #4,a7
 rts
.scan:
 moveq #-1,d7
.next:
 cmpi.l #$464f524d,(a0)
 beq public_iff_found
 addq.l #2,a0
 dbf d7,.next
public_iff_missing:
 jmp $12345678
public_iff_found:
 jmp $12345678
