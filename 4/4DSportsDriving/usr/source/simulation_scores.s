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
