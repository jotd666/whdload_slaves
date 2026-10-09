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

; Unsigned forward displacement from $C326: speed*1408 / (20*768).
; At 50 Hz use denominator 38400, with an unsigned remainder at (a0).
; d0.w unsigned speed -> d0.l whole displacement. Scratch d1.
; Max numerator 65535*1408+38399=92311679: DIVU quotient always fits.
sim_distance_50:
 mulu #1408,d0
 moveq #0,d1
 move.w (a0),d1
 add.l d1,d0
 divu #38400,d0
 swap d0
 move.w d0,(a0)
 swap d0
 and.l #$ffff,d0
 rts

; Approach target at a nominal A2500 rate (gear actuator uses 6 units/step).
; d0.w current, d1.w target, d2.w positive rate, a0 -> signed fraction.
; Return d0.l signed new current, stop exactly at target and clear carry there.
; Long comparisons avoid signed-word overflow across the full coordinate range.
sim_approach_50:
 movem.l d2-d4,-(sp)
 ext.l d0
 move.l d0,d3
 ext.l d1
 move.l d1,d4
 cmp.l d3,d4
 beq .target
 blt .decrease
 move.w d2,d0
 bsr sim_rate_20_to_50
 add.l d3,d0
 cmp.l d4,d0
 blt .done
 bra .target
.decrease:
 move.w d2,d0
 neg.w d0
 bsr sim_rate_20_to_50
 add.l d3,d0
 cmp.l d4,d0
 bgt .done
.target:
 move.l d4,d0
 clr.w (a0)
.done:
 movem.l (sp)+,d2-d4
 rts

; Airborne wheel pair from $CB48: v += a; y -= v at nominal 20 Hz.
; Native Normal repeats the ordered pair. Its constant-a fractional extension
; for h=2/5 is dv=2a/5, dy=-(2*v/5 + 7*a/25). Here v includes the private
; velocity fraction. Five steps equal two native pairs exactly without collision/velocity wrap.
; d0.w old velocity, d1.w acceleration; a0 -> signed velocity/position
; remainders in fifths/twenty-fifths; a1 -> long position. Return d0.w new v.
; Position remainder measures downward displacement; subtract its quotient.
; Scratch d1. Contact/impulse resets and replay storage belong to integration.
sim_airborne_pair_50:
 movem.l d2-d5,-(sp)
 move.w d0,d2
 move.w d1,d4
 muls #10,d0
 move.w (a0),d3
 ext.l d3
 add.l d3,d3
 add.l d3,d0
 muls #7,d1
 add.l d1,d0
 move.w 2(a0),d1
 ext.l d1
 add.l d1,d0
 divs #25,d0
 swap d0
 move.w d0,2(a0)
 swap d0
 ext.l d0
 sub.l d0,(a1)
 move.w d4,d0
 bsr sim_rate_20_to_50
 add.w d2,d0
 ext.l d0
 movem.l (sp)+,d2-d5
 rts
