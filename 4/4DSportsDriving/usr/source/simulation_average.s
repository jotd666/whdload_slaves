; A4000 average-speed numerator. The native update zero-extends its speed
; word in the displaced $E852..$E85C block. At 75000 ticks its bound is4915125000, beyond32 bits.
; Keep every sample and retain the exact native low32-bit mirror and ADD flags.
sim_average_accumulate:
 moveq #0,d0
 move.w -$902(a4),d0
 cmp.w #50,-$15fa(a4)
 bne .native
 movem.l d1/a0,-(sp)
 lea sim_results_state(pc),a0
 moveq #0,d1
 add.l d0,28(a0)
 addx.l d1,d1
 add.l d1,24(a0)
 movem.l (sp)+,d1/a0
.native:
 add.l d0,-$944(a4)
 rts

; $597E: native signed division plus the final Q8-to-integer conversion.
; Native modes retain that exact operation. A4000 uses the completed summary.
sim_average_finish:
 cmp.w #50,-$15fa(a4)
 beq .wide
 jsr -$78f6(a4)
 asr.l #8,d0
 rts
.wide:
 movem.l d1-d3/a0,-(sp)
 lea sim_results_summary(pc),a0
 move.l 24(a0),d2
 move.l 28(a0),d0
 move.l 16(a0),d1
 bsr sim_average_divide
 movem.l (sp)+,d1-d3/a0
 asr.l #8,d0
 rts

; Unsigned D2:D0 / D1 -> D0 quotient, D2 remainder; D3 scratch.
; Require nonzero divisor <=75000 and high<divisor, so the unsigned quotient
; and shifted remainder fit 32 bits. Average speed additionally bounds the
; quotient to 65535; exact-score formatting also uses this kernel at 6000/10.
; Zero is defensive; the original result guard bypasses zero-time division.
sim_average_divide:
 tst.l d1
 beq .zero
 moveq #31,d3
.bit:
 add.l d0,d0
 addx.l d2,d2
 cmp.l d1,d2
 blo .next
 sub.l d1,d2
 addq.l #1,d0
.next:
 dbra d3,.bit
 rts
.zero:
 moveq #0,d0
 moveq #0,d2
 rts
 even
