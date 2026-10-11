; E2 bounded persistent-gauge pixel guard. VERIFY-only until the draw hook/twin.
; a0 = native 320x200x5 planar screen, a1 = private packed fast-RAM pixels,
; a2 = {left byte offset, top row, row bytes, rows}, four unsigned words.
; d0 = 0 compare or 1 capture. Return d0=1 success/equal, 0 invalid/different.
; Preserve all other registers. At most 1920 packed bytes (8*48*5).
; Caller owns the allocation and separately keys the native draw inputs/state.
; A successful compare alone does NOT authorize skipping a native callback.
instrument_pixels:
 movem.l d1-d7/a0-a4,-(sp)
 cmpi.l #1,d0
 bhi .bad
 move.l d0,d7
 moveq #0,d1
 move.w (a2),d1
 btst #0,d1
 bne .bad
 cmpi.w #38,d1
 bhi .bad
 moveq #0,d2
 move.w 2(a2),d2
 cmpi.w #199,d2
 bhi .bad
 moveq #0,d3
 move.w 4(a2),d3
 beq .bad
 btst #0,d3
 bne .bad
 cmpi.w #8,d3
 bhi .bad
 move.w d1,d0
 add.w d3,d0
 cmpi.w #40,d0
 bhi .bad
 moveq #0,d4
 move.w 6(a2),d4
 beq .bad
 cmpi.w #48,d4
 bhi .bad
 move.w d2,d0
 add.w d4,d0
 cmpi.w #200,d0
 bhi .bad
 ; Screen and packed pointers must be non-null/even for word accesses.
 move.l a0,d0
 beq .bad
 btst #0,d0
 bne .bad
 move.l a1,d0
 beq .bad
 btst #0,d0
 bne .bad
 lea $dff000,a3
 btst #6,2(a3)
.wait
 btst #6,2(a3)
 bne .wait
 mulu.w #40,d2
 add.l d1,d2
 adda.l d2,a0
 lsr.w #1,d3
 subq.w #1,d3
 subq.w #1,d4
 moveq #4,d5
.plane
 move.l a0,a3
 move.w d4,d6
.row
 move.l a3,a4
 move.w d3,d2
 tst.l d7
 bne .capture
.compare
 move.w (a4)+,d1
 cmp.w (a1)+,d1
 bne .bad
 dbf d2,.compare
 bra .next_row
.capture
 move.w (a4)+,(a1)+
 dbf d2,.capture
.next_row
 adda.w #40,a3
 dbf d6,.row
 adda.l #8000,a0
 dbf d5,.plane
 moveq #1,d0
 bra .done
.bad
 moveq #0,d0
.done
 movem.l (sp)+,d1-d7/a0-a4
 rts

; a0 = native x/y/width/height words, a1 = signed byte x/y padding,
; a2 = private eight-byte descriptor destination. No writes on rejection.
; Return d0=1 accepted, 0 native fallback; all other registers preserved.
instrument_region:
 movem.l d1-d7,-(sp)
 moveq #0,d1
 move.b (a1),d1
 bmi .bad
 moveq #0,d2
 move.b 1(a1),d2
 bmi .bad
 move.w (a0),d3
 ext.l d3
 move.w 2(a0),d4
 ext.l d4
 move.w 4(a0),d5
 ble .bad
 ext.l d5
 move.w 6(a0),d6
 ble .bad
 ext.l d6
 add.l d3,d5
 add.l d4,d6
 sub.l d1,d3
 bmi .bad
 sub.l d2,d4
 bmi .bad
 add.l d1,d1
 add.l d2,d2
 add.l d1,d5
 add.l d2,d6
 cmpi.l #320,d5
 bhs .bad
 cmpi.l #200,d6
 bhs .bad
 ; Inclusive upper native limits, rounded outwards to 16-pixel words.
 lsr.l #4,d3
 add.w d3,d3
 lsr.l #4,d5
 addq.w #1,d5
 add.w d5,d5
 sub.w d3,d5
 cmpi.w #8,d5
 bhi .bad
 sub.w d4,d6
 addq.w #1,d6
 cmpi.w #48,d6
 bhi .bad
 move.w d3,(a2)
 move.w d4,2(a2)
 move.w d5,4(a2)
 move.w d6,6(a2)
 moveq #1,d0
 bra .done
.bad
 moveq #0,d0
.done
 movem.l (sp)+,d1-d7
 rts
