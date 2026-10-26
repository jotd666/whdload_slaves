; Exact record display. Physical exact rows follow the native index mapping.
; Native 20 Hz scores may have odd hundredths: never convert them through 50 Hz.

; D0 logical row word, A4 native data -> D2:D0 unsigned exact hundredths.
; Invalid logical/physical indices return the empty sentinel. Preserve A0/D1.
sim_score_row_time:
 movem.l a0,-(sp)
 and.l #$ffff,d0
 cmp.w #6,d0
 bhi .empty
 add.w d0,d0
 lea -$160a(a4),a0
 move.w (a0,d0.w),d0
 cmp.w #6,d0
 bhi .empty
 lsl.w #3,d0
 lea sim_score_records(pc),a0
 move.l (a0,d0.w),d2
 move.l 4(a0,d0.w),d0
 bra .out
.empty:
 moveq #-1,d2
 moveq #-1,d0
.out:
 movem.l (sp)+,a0
 rts

; $3558..$3570: the following BEQ skips the top record iff it is empty.
; A finite long time can have native mirror $FFFF, so inspect both exact longs.
; Preserve registers and incoming X; only the following branch consumes Z.
sim_score_top_guard:
 movem.l d0-d3/a0,-(sp)
 moveq #0,d3
 addx.w d3,d3
 move.w d3,-(sp)
 moveq #0,d0
 bsr sim_score_row_time
 move.w (sp)+,d3
 lsr.w #1,d3
 cmp.l #-1,d2
 bne .out
 cmp.l #-1,d0
.out:
 movem.l (sp)+,d0-d3/a0
 rts

; D2:D0 hundredths (<=10*UINT32_MAX, or empty), D1 fraction flag, A0 output.
; Empty prints native zero time. Maximum 14 bytes including NUL. D0-D3/A0
; scratch; preserve D4-D7 and all other address registers.
sim_score_format100:
 movem.l d4-d7,-(sp)
 move.w d1,d4
 cmp.l #-1,d2
 bne .finite
 cmp.l #-1,d0
 bne .finite
 moveq #0,d2
 moveq #0,d0
.finite:
 move.l #6000,d1
 bsr sim_average_divide
 move.l d2,d5               ; hundredths within the minute, 0..5999
 cmp.l #100,d0
 bhs .many_minutes
 bsr .pair
 cmp.b #'0',-2(a0)
 bne .seconds
 move.b #' ',-2(a0)
 bra .seconds
.many_minutes:
 moveq #0,d6
.digits:
 moveq #0,d2
 moveq #10,d1
 bsr sim_average_divide
 add.w #'0',d2
 move.w d2,-(sp)
 addq.w #1,d6
 tst.l d0
 bne .digits
.emit:
 move.w (sp)+,d2
 move.b d2,(a0)+
 subq.w #1,d6
 bne .emit
.seconds:
 move.b #':',(a0)+
 move.l d5,d0
 divu #100,d0
 move.l d0,d5
 and.l #$ffff,d0
 bsr .pair
 tst.w d4
 beq .end
 move.b #'.',(a0)+
 move.l d5,d0
 swap d0
 and.l #$ffff,d0
 bsr .pair
.end:
 clr.b (a0)
 movem.l (sp)+,d4-d7
 rts
.pair:
 divu #10,d0
 move.w d0,d2
 add.b #'0',d2
 move.b d2,(a0)+
 swap d0
 add.b #'0',d0
 move.b d0,(a0)+
 rts
