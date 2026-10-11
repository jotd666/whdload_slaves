; E2 cached fast-RAM pixels to chip, 020+ caller only.
; a0=packed five-plane pixels, a1=packed one-plane mask, a2=screen top-left.
; d0=words per row (1..20), d1=rows (1..200). Screen pitch40/stride8000.
; All registers preserved, CCR volatile. Empty mask words touch no chip RAM;
; opaque words do not read the destination. Partial words use exact cookie-cut.
; Input dimensions and resource ownership were accepted at cache fill time.
overlay_fast:
 movem.l d0-a6,-(sp)
 bsr overlay_blit_wait
 move.l a1,a3
 move.w d0,d2
 add.w d2,d2
 neg.w d2
 addi.w #40,d2 ; destination row gap
 moveq #0,d3
 move.w d1,d3
 mulu.w #40,d3
 neg.l d3
 addi.l #8000,d3 ; next-plane gap after all screen rows
 moveq #4,d7
.plane
 move.l a3,a1
 move.w d1,d5
 subq.w #1,d5
.row
 move.w d0,d6
 subq.w #1,d6
.word
 move.w (a1)+,d4
 beq .transparent
 cmpi.w #$ffff,d4
 beq .opaque
 move.w (a0)+,d0
 and.w d4,d0
 not.w d4
 and.w (a2),d4
 or.w d0,d4
 move.w d4,(a2)+
 move.w 2(sp),d0 ; low word of saved D0 (MOVEM ascending order)
 bra .next
.opaque
 move.w (a0)+,(a2)+
 bra .next
.transparent
 addq.l #2,a0
 addq.l #2,a2
.next
 dbf d6,.word
 adda.w d2,a2
 dbf d5,.row
 adda.l d3,a2
 dbf d7,.plane
 movem.l (sp)+,d0-a6
 rts
