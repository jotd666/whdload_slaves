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
; Game domain: nonzero divisor <=75000 and numerator <=65535*divisor,
; so high<divisor and the quotient fits32 bits. Remainder shifts fit32 bits.
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
 dc.b "4DAVGST!"
 dc.w 1,30
sim_average_passed: dc.l 0
sim_average_accum_cases:
 dc.l $00000000,$00000000,$00000000,$00000000,$00000000,$00000000
 dc.w 10
 dc.b $ff,0,0,0
 dc.w 0
 dc.l $00000000,$00000000,$0000ffff,$00000000,$00000000,$0000ffff
 dc.w 10
 dc.b 0,0,0,0
 dc.w 0
 dc.l $00000000,$7fffffff,$00000001,$00000000,$00000000,$80000000
 dc.w 10
 dc.b 0,0,$ff,$ff
 dc.w 0
 dc.l $00000000,$ffffffff,$00000001,$00000000,$00000000,$00000000
 dc.w 10
 dc.b $ff,$ff,0,0
 dc.w 1
 dc.l $00000001,$00000000,$0000ffff,$00000000,$00000000,$0000ffff
 dc.w 10
 dc.b 0,0,0,0
 dc.w 0
 dc.l $00000001,$24f5db09,$0000ffff,$00000000,$00000000,$24f6db08
 dc.w 10
 dc.b 0,0,0,0
 dc.w 0
 dc.l $00000000,$00000000,$00000000,$00000000,$00000000,$00000000
 dc.w 20
 dc.b $ff,0,0,0
 dc.w 0
 dc.l $00000000,$00000000,$0000ffff,$00000000,$00000000,$0000ffff
 dc.w 20
 dc.b 0,0,0,0
 dc.w 0
 dc.l $00000000,$7fffffff,$00000001,$00000000,$00000000,$80000000
 dc.w 20
 dc.b 0,0,$ff,$ff
 dc.w 0
 dc.l $00000000,$ffffffff,$00000001,$00000000,$00000000,$00000000
 dc.w 20
 dc.b $ff,$ff,0,0
 dc.w 1
 dc.l $00000001,$00000000,$0000ffff,$00000000,$00000000,$0000ffff
 dc.w 20
 dc.b 0,0,0,0
 dc.w 0
 dc.l $00000001,$24f5db09,$0000ffff,$00000000,$00000000,$24f6db08
 dc.w 20
 dc.b 0,0,0,0
 dc.w 0
 dc.l $00000000,$00000000,$00000000,$00000000,$00000000,$00000000
 dc.w 50
 dc.b $ff,0,0,0
 dc.w 0
 dc.l $00000000,$00000000,$0000ffff,$00000000,$0000ffff,$0000ffff
 dc.w 50
 dc.b 0,0,0,0
 dc.w 0
 dc.l $00000000,$7fffffff,$00000001,$00000000,$80000000,$80000000
 dc.w 50
 dc.b 0,0,$ff,$ff
 dc.w 0
 dc.l $00000000,$ffffffff,$00000001,$00000001,$00000000,$00000000
 dc.w 50
 dc.b $ff,$ff,0,0
 dc.w 1
 dc.l $00000001,$00000000,$0000ffff,$00000001,$0000ffff,$0000ffff
 dc.w 50
 dc.b 0,0,0,0
 dc.w 0
 dc.l $00000001,$24f5db09,$0000ffff,$00000001,$24f6db08,$24f6db08
 dc.w 50
 dc.b 0,0,0,0
 dc.w 0
sim_average_div_cases:
 dc.l $00000000,$00000000,$00000001,$00000000,$00000000
 dc.l $00000000,$0000ffff,$00000001,$0000ffff,$00000000
 dc.l $00000000,$0001fffe,$00000002,$0000ffff,$00000000
 dc.l $00000000,$7d000000,$00010000,$00007d00,$00000000
 dc.l $00000000,$7fffffff,$000124f8,$00006fd9,$000021c7
 dc.l $00000000,$80000000,$000124f8,$00006fd9,$000021c8
 dc.l $00000000,$ffffffff,$000124f8,$0000dfb2,$0000438f
 dc.l $00000001,$00000000,$000124f8,$0000dfb2,$00004390
 dc.l $00000001,$24f6db08,$000124f8,$0000ffff,$00000000
 dc.l $00000000,$499602d2,$00007530,$0000a0c0,$00001ed2
 dc.l $00000000,$39381a10,$00007530,$00007cff,$00001f40
 dc.l $00000000,$00000000,$00000000,$00000000,$00000000
sim_average_selftest:
 movem.l d0-a6,-(sp)
 lea sim_average_selftest(pc),a4
 adda.l #sim_results_test_arena+$1600-sim_average_selftest,a4
 lea sim_average_accum_cases(pc),a2
 moveq #17,d7
.accum:
 move.w 24(a2),-$15fa(a4)
 move.l 4(a2),-$944(a4)
 lea sim_results_state(pc),a0
 clr.l 24(a0)
 clr.l 28(a0)
 cmp.w #50,24(a2)
 bne .invoke
 move.l (a2),24(a0)
 move.l 4(a2),28(a0)
.invoke:
 move.l 8(a2),d0
 move.w d0,-$902(a4)
 move.l #$12345678,d1
 bsr sim_average_accumulate
 seq d2
 scs d3
 smi d4
 svs d5
 moveq #0,d6
 addx.w d6,d6
 cmp.w 30(a2),d6
 bne .failed
 cmp.b 26(a2),d2
 bne .failed
 cmp.b 27(a2),d3
 bne .failed
 cmp.b 28(a2),d4
 bne .failed
 cmp.b 29(a2),d5
 bne .failed
 cmp.l 8(a2),d0
 bne .failed
 cmp.l #$12345678,d1
 bne .failed
 lea sim_results_state(pc),a0
 move.l 24(a0),d0
 cmp.l 12(a2),d0
 bne .failed
 move.l 28(a0),d0
 cmp.l 16(a2),d0
 bne .failed
 move.l -$944(a4),d0
 cmp.l 20(a2),d0
 bne .failed
 lea sim_average_passed(pc),a0
 addq.l #1,(a0)
 lea 32(a2),a2
 dbra d7,.accum
 move.w #50,-$15fa(a4)
 lea sim_average_div_cases(pc),a2
 moveq #11,d7
.divide:
 move.l (a2),d2
 move.l 4(a2),d0
 move.l 8(a2),d1
 bsr sim_average_divide
 cmp.l 12(a2),d0
 bne .failed
 cmp.l 16(a2),d2
 bne .failed
 lea sim_results_summary(pc),a0
 move.l (a2),24(a0)
 move.l 4(a2),28(a0)
 move.l 8(a2),16(a0)
 move.l #$12345678,d1
 bsr sim_average_finish
 cmp.l #$12345678,d1
 bne .failed
 move.l 12(a2),d1
 lsr.l #8,d1
 cmp.l d1,d0
 bne .failed
 lea sim_average_passed(pc),a0
 addq.l #1,(a0)
 lea 20(a2),a2
 dbra d7,.divide
 lea sim_results_state(pc),a0
 lea sim_results_summary(pc),a1
 moveq #SIM_TIME_STATE_BYTES/4-1,d0
.clear:
 clr.l (a0)+
 clr.l (a1)+
 dbra d0,.clear
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #24,(a0)
 illegal
 bra .failed
