; Exact persistent-score arithmetic, shared by all three simulation modes.
; Canonical unsigned 64-bit hundredths represent 10/20/50 Hz without rounding.
; UINT64_MAX is the empty-record sentinel. Native .hig words are 20 Hz,
; independent of the selected simulation rate ($3E06 and $3D9A).
; These helpers are not yet connected to disk I/O or the high-score UI.

; D0 unsigned tick count, D1 full rate -> D2:D0 hundredths, D1=0 success.
; Unsupported rates return D1=-1 and the empty sentinel. Preserve D3-D7/A0-A6.
sim_score_from_ticks:
 cmp.l #50,d1
 beq .twice
 cmp.l #20,d1
 beq .five
 cmp.l #10,d1
 beq .ten
 moveq #-1,d0
 moveq #-1,d1
 moveq #-1,d2
 rts
.twice:
 moveq #0,d2
 add.l d0,d0
 addx.l d2,d2
 moveq #0,d1
 rts
.ten:
 bsr .five
 add.l d0,d0
 addx.l d2,d2
 rts
.five:
 movem.l d3-d4,-(sp)
 move.l d0,d3
 moveq #0,d4
 moveq #0,d2
 add.l d0,d0
 addx.l d2,d2
 add.l d0,d0
 addx.l d2,d2
 add.l d3,d0
 addx.l d4,d2
 moveq #0,d1
 movem.l (sp)+,d3-d4
 rts

; D0 low word from a native .hig row -> D2:D0 hundredths, D1=0.
; Ignore the caller's upper word. FFFF is empty, not 3276.75 seconds.
sim_score_from_native:
 and.l #$ffff,d0
 cmp.w #$ffff,d0
 beq .empty
 moveq #20,d1
 bra sim_score_from_ticks
.empty:
 moveq #-1,d0
 moveq #-1,d2
 moveq #0,d1
 rts

; Compare unsigned big-endian 64-bit scores at A0 and A1.
; Returns CMP flags for (A0)-(A1): BLO is faster, BEQ is equal.
; Empty sorts last. D0 scratch; other registers and X unchanged.
sim_score_compare:
 move.l (a0),d0
 cmp.l (a1),d0
 bne .done
 move.l 4(a0),d0
 cmp.l 4(a1),d0
.done:
 rts

 even
 IFNE SIM_STARTUP_TESTS
 dc.b "4DSCORE!"
 dc.w 1,89
sim_score_passed: dc.l 0
sim_score_conversion_cases:
 dc.l $00000000,$0000000a,$00000000,$00000000,$00000000
 dc.l $00000001,$0000000a,$00000000,$0000000a,$00000000
 dc.l $00000002,$0000000a,$00000000,$00000014,$00000000
 dc.l $00000003,$0000000a,$00000000,$0000001e,$00000000
 dc.l $00000005,$0000000a,$00000000,$00000032,$00000000
 dc.l $0000fffe,$0000000a,$00000000,$0009ffec,$00000000
 dc.l $0000ffff,$0000000a,$00000000,$0009fff6,$00000000
 dc.l $00010000,$0000000a,$00000000,$000a0000,$00000000
 dc.l $000124f8,$0000000a,$00000000,$000b71b0,$00000000
 dc.l $19999999,$0000000a,$00000000,$fffffffa,$00000000
 dc.l $33333333,$0000000a,$00000001,$fffffffe,$00000000
 dc.l $7fffffff,$0000000a,$00000004,$fffffff6,$00000000
 dc.l $80000000,$0000000a,$00000005,$00000000,$00000000
 dc.l $ffffffff,$0000000a,$00000009,$fffffff6,$00000000
 dc.l $00000000,$00000014,$00000000,$00000000,$00000000
 dc.l $00000001,$00000014,$00000000,$00000005,$00000000
 dc.l $00000002,$00000014,$00000000,$0000000a,$00000000
 dc.l $00000003,$00000014,$00000000,$0000000f,$00000000
 dc.l $00000005,$00000014,$00000000,$00000019,$00000000
 dc.l $0000fffe,$00000014,$00000000,$0004fff6,$00000000
 dc.l $0000ffff,$00000014,$00000000,$0004fffb,$00000000
 dc.l $00010000,$00000014,$00000000,$00050000,$00000000
 dc.l $000124f8,$00000014,$00000000,$0005b8d8,$00000000
 dc.l $19999999,$00000014,$00000000,$7ffffffd,$00000000
 dc.l $33333333,$00000014,$00000000,$ffffffff,$00000000
 dc.l $7fffffff,$00000014,$00000002,$7ffffffb,$00000000
 dc.l $80000000,$00000014,$00000002,$80000000,$00000000
 dc.l $ffffffff,$00000014,$00000004,$fffffffb,$00000000
 dc.l $00000000,$00000032,$00000000,$00000000,$00000000
 dc.l $00000001,$00000032,$00000000,$00000002,$00000000
 dc.l $00000002,$00000032,$00000000,$00000004,$00000000
 dc.l $00000003,$00000032,$00000000,$00000006,$00000000
 dc.l $00000005,$00000032,$00000000,$0000000a,$00000000
 dc.l $0000fffe,$00000032,$00000000,$0001fffc,$00000000
 dc.l $0000ffff,$00000032,$00000000,$0001fffe,$00000000
 dc.l $00010000,$00000032,$00000000,$00020000,$00000000
 dc.l $000124f8,$00000032,$00000000,$000249f0,$00000000
 dc.l $19999999,$00000032,$00000000,$33333332,$00000000
 dc.l $33333333,$00000032,$00000000,$66666666,$00000000
 dc.l $7fffffff,$00000032,$00000000,$fffffffe,$00000000
 dc.l $80000000,$00000032,$00000001,$00000000,$00000000
 dc.l $ffffffff,$00000032,$00000001,$fffffffe,$00000000
 dc.l $0000007b,$00000000,$ffffffff,$ffffffff,$ffffffff
 dc.l $0000007b,$00000001,$ffffffff,$ffffffff,$ffffffff
 dc.l $0000007b,$00000019,$ffffffff,$ffffffff,$ffffffff
 dc.l $0000007b,$0000003c,$ffffffff,$ffffffff,$ffffffff
 dc.l $0000007b,$00010032,$ffffffff,$ffffffff,$ffffffff
 dc.l $0000007b,$ffffffff,$ffffffff,$ffffffff,$ffffffff
sim_score_import_cases:
 dc.l $00000000,$00000000,$00000000
 dc.l $00000001,$00000000,$00000005
 dc.l $00000002,$00000000,$0000000a
 dc.l $00007fff,$00000000,$00027ffb
 dc.l $00008000,$00000000,$00028000
 dc.l $0000fffe,$00000000,$0004fff6
 dc.l $0000ffff,$ffffffff,$ffffffff
 dc.l $12340001,$00000000,$00000005
 dc.l $1234ffff,$ffffffff,$ffffffff
sim_score_compare_cases:
 dc.l $00000000,$00000000,$00000000,$00000000
 dc.b 0,255
 dc.l $00000000,$00000001,$00000000,$00000002
 dc.b 255,0
 dc.l $00000000,$00000002,$00000000,$00000001
 dc.b 0,0
 dc.l $00000000,$7fffffff,$00000000,$80000000
 dc.b 255,0
 dc.l $00000000,$80000000,$00000000,$7fffffff
 dc.b 0,0
 dc.l $00000000,$ffffffff,$00000001,$00000000
 dc.b 255,0
 dc.l $00000001,$00000000,$00000000,$ffffffff
 dc.b 0,0
 dc.l $00000001,$00000001,$00000001,$00000000
 dc.b 0,0
 dc.l $00000001,$00000000,$00000001,$00000001
 dc.b 255,0
 dc.l $00000001,$00000000,$00000001,$00000000
 dc.b 0,255
 dc.l $00000000,$000249f0,$00000000,$000249f0
 dc.b 0,255
 dc.l $00000000,$000249f0,$00000000,$000249f1
 dc.b 255,0
 dc.l $00000001,$fffffffe,$ffffffff,$ffffffff
 dc.b 255,0
 dc.l $ffffffff,$ffffffff,$00000001,$fffffffe
 dc.b 0,0
 dc.l $ffffffff,$ffffffff,$ffffffff,$ffffffff
 dc.b 0,255
 dc.l $00000001,$00000000,$00000002,$00000000
 dc.b 255,0
sim_score_selftest:
 movem.l d0-a6,-(sp)
 lea sim_score_passed(pc),a3
 clr.l (a3)
 lea sim_score_conversion_cases(pc),a2
 move.w #48-1,d7
.convert:
 move.l (a2),d0
 move.l 4(a2),d1
 move.l #$12345678,d3
 move.l #$76543210,d4
 bsr sim_score_from_ticks
 cmp.l 8(a2),d2
 bne .failed
 cmp.l 12(a2),d0
 bne .failed
 cmp.l 16(a2),d1
 bne .failed
 cmp.l #$12345678,d3
 bne .failed
 cmp.l #$76543210,d4
 bne .failed
 addq.l #1,(a3)
 lea 20(a2),a2
 dbra d7,.convert
 lea sim_score_import_cases(pc),a2
 move.w #9-1,d7
.import:
 move.l (a2),d0
 bsr sim_score_from_native
 cmp.l 4(a2),d2
 bne .failed
 cmp.l 8(a2),d0
 bne .failed
 tst.l d1
 bne .failed
 addq.l #1,(a3)
 lea 12(a2),a2
 dbra d7,.import
 moveq #0,d6
.compare_pass:
 lea sim_score_compare_cases(pc),a2
 move.w #16-1,d7
.compare:
 movea.l a2,a0
 lea 8(a2),a1
 moveq #0,d5
 tst.w d6
 beq .clear_x
 moveq #-1,d5
 add.l d5,d5
 bra .invoke
.clear_x:
 add.l d5,d5
.invoke:
 bsr sim_score_compare
 scs d3
 seq d4
 moveq #0,d5
 addx.w d5,d5
 cmp.w d6,d5
 bne .failed
 cmp.b 16(a2),d3
 bne .failed
 cmp.b 17(a2),d4
 bne .failed
 cmpa.l a2,a0
 bne .failed
 lea 8(a2),a0
 cmpa.l a0,a1
 bne .failed
 addq.l #1,(a3)
 lea 18(a2),a2
 dbra d7,.compare
 addq.w #1,d6
 cmp.w #2,d6
 blo .compare_pass
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #25,(a0)
 illegal
 bra .failed

 ENDC
