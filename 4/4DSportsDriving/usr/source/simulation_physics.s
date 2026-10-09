; A4000 arithmetic kernels. Development-only until all physics/replay gates pass.
; No native mode hooks yet. Per-vehicle fractions must join the replay extension.
;
; Signed rate conversion: d0.w is a nominal A2500 increment; (a0).w is a
; signed numerator remainder (-4..4). Return d0.w at 50 Hz, update remainder.
; Truncation toward zero is symmetric; retaining the signed remainder makes
; five constant 50 Hz steps sum to two A2500 increments, even at +/-1 units.
; Scratch d1. Full signed-word inputs fit the signed DIVS quotient.
sim_rate_20_to_50:
 muls #2,d0
 move.w (a0),d1
 ext.l d1
 add.l d1,d0
 divs #5,d0
 swap d0
 move.w d0,(a0)
 swap d0
 ext.l d0
 rts

; Steering kernel, derived from $1033A..$10492:
; d0.w current angle; d1.w signed A2500 table command; d2.w positive native
; centering increment (twice table column 1); d3.w nonzero if moving;
; a0 -> private steering fraction. Returns angle d0.w and updated fraction.
; Countersteering multiplier 4, absolute +/-240 and neutral deadzone 8 stay
; native. The per-step +/-80 increment is rate-scaled. Clamp centering AFTER
; rate conversion so reaching the target cannot overshoot or decay forever.
; All registers except d0/d1 and CCR are preserved.
sim_steering_50:
 movem.l d2-d5,-(sp)
 move.w d0,d4
 moveq #0,d5             ; centering flag
 tst.w d1
 beq .neutral
 bmi .left
 cmp.w #-1,d4
 bge .rate
 asl.w #2,d1
 bra .rate
.left:
 cmp.w #1,d4
 ble .rate
 asl.w #2,d1
 bra .rate
.neutral:
 tst.w d3
 beq .deadzone
 tst.w d4
 beq .at_target
 moveq #1,d5
 move.w d2,d1
 tst.w d4
 bmi .rate
 neg.w d1
.rate:
 cmp.w #80,d1
 ble .low
 moveq #80,d1
.low:
 cmp.w #-80,d1
 bge .convert
 moveq #-80,d1
.convert:
 move.w d1,d0
 bsr sim_rate_20_to_50
 add.w d0,d4
 tst.w d5
 beq .limit
 ; Centering: a sign crossing or the native +/-8 neutral zone reaches zero.
 tst.w d0
 beq .deadzone
 bmi .center_from_right
 tst.w d4
 bpl .at_target
 bra .deadzone
.center_from_right:
 tst.w d4
 bmi .at_target
.deadzone:
 cmp.w #8,d4
 bge .limit
 cmp.w #-8,d4
 ble .limit
.at_target:
 clr.w (a0)
 moveq #0,d4
.limit:
 cmp.w #240,d4
 ble .limit_low
 move.w #240,d4
 clr.w (a0)             ; no accumulated demand against the steering stop
.limit_low:
 cmp.w #-240,d4
 bge .unchanged
 move.w #-240,d4
 clr.w (a0)
.unchanged:
 move.w d4,d0
 movem.l (sp)+,d2-d5
 rts
