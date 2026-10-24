; Intro picture bundle is CPU-decoded into Chip display planes. It occupies
; $8000..$297b1 during the intro; boot music uses $30000..$3ffff.
; Both allocations end before the loader and are overwritten by the main image.
public_intro_index_install:
 lea public_intro_exp(pc),a0
 move.l a5,d0
 subi.l #$5000,d0
 move.l d0,(a0)
 move.l a5,a1
 adda.l #$cf0,a1
 cmpi.w #$4279,(a1)
 bne .done
 move.l a5,d0
 addi.l #$1a,d0
 cmp.l 2(a1),d0
 bne .done
 lea public_intro_index_reset(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 ; Native clears returned while the blitter was still writing. Fast image
 ; decoding exposes that race; wait before the CPU writes the same planes.
 move.l a5,a1
 adda.l #$1f88,a1
 bsr .clear_exit
 move.l a5,a1
 adda.l #$1fb4,a1
 bsr .clear_exit
 bra .done
.clear_exit:
 cmpi.l #$4cdf0101,(a1)
 bne .clear_done
 cmpi.w #$4e75,4(a1)
 bne .clear_done
 lea public_intro_clear_done(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
.clear_done:
 rts
.done:
 rts
public_intro_index_reset:
 pea 0.w
 move.w sr,-(a7)
 movem.l d0-d3/a0-a4,-(a7)
 move.l public_intro_exp(pc),a4
 move.l a4,a1
 adda.l #$8000,a1
 adda.l #$5000,a4
 move.l $12(a4),a0
 cmpa.l a1,a0
 beq .done
 cmpi.w #11,(a0)
 bne .done
 ; Validate the final picture endpoint before the bounded bundle copy.
 move.l 82(a0),d0
 add.l 86(a0),d0
 cmpi.l #137138,d0
 bne .done
 move.l a1,a2
 move.w #34283,d0
.copy:
 move.l (a0)+,(a1)+
 dbf d0,.copy
 move.w (a0)+,(a1)+
 move.l a2,$12(a4)
.done:
 move.l a4,a0
 adda.l #$cf6,a0
 move.l a0,38(a7)
 move.w 36(a7),ccr
 clr.w $1a(a4)
 movem.l (a7)+,d0-d3/a0-a4
 addq.l #2,a7
 rts
public_intro_exp:
 dc.l 0

public_intro_clear_done:
 movem.l (a7)+,d0/a0
 move.w sr,-(a7)
 btst #6,$dff002
.wait:
 btst #6,$dff002
 bne .wait
 move.w (a7)+,ccr
 rts
