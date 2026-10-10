; A4000 body tilt: retain sub-angle change, removing the reconstruction bias
; of old wheels after restoring their INITIAL suspension extension. Scratch
; belongs only to this C270 update; all four slots are overwritten at C520.
sim_tilt_collect:
 cmp.w #50,-$15fa(a4)
 bne .done
 movem.l d0-a6,-(sp)
 moveq #0,d4
 addx.w d4,d4
 move.w d4,-(sp)          ; preserve original projection X across extra work
 IFD SIM_TILT_COLLECT_VERIFY
 lea sim_tilt_collect_marker(pc),a0
 move.w d4,20(a0)
 ENDC
 moveq #0,d0
 move.b -3(a5),d0
 move.w d0,d1
 mulu #6,d0
 lea sim_tilt_wheels(pc),a3
 adda.l d0,a3
 move.l -$46(a5),(a3)
 move.w -$42(a5),4(a3)
 add.w d1,d1
 move.l 8(a5),a0
 move.w $54(a0,d1.w),d2
 add.w #384,d2
 lea -12(sp),sp
 clr.w (sp)
 move.w d2,2(sp)
 clr.w 4(sp)
 lea 6(sp),a0
 move.l a0,d0
 move.l sp,a0
 lea $bae(a4),a1
 jsr -$7bd8(a4)
 move.w 6(sp),d0
 add.w d0,(a3)
 move.w 8(sp),d0
 add.w d0,2(a3)
 move.w 10(sp),d0
 add.w d0,4(a3)
 lea 12(sp),sp
 move.w (sp)+,d4
 lsr.w #1,d4
 IFD SIM_TILT_COLLECT_VERIFY
 ; Read X with CPU instructions rather than a debugger SR snapshot.
 moveq #0,d3
 addx.w d3,d3
 lea sim_tilt_collect_marker(pc),a0
 addq.l #1,12(a0)
 cmp.w 20(a0),d3
 beq .x_same
 addq.l #1,16(a0)
.x_same:
 tst.w d3
 beq .x_zero
 addq.l #1,26(a0)
 bra .x_counted
.x_zero:
 addq.l #1,22(a0)
.x_counted:
 lsr.w #1,d3
 ENDC
 movem.l (sp)+,d0-a6
.done:
 rts

; Normalize the old reconstructed body center exactly as the native integer
; four-wheel centroid. Translation does not belong in the orientation basis.
sim_tilt_center:
 lea sim_tilt_wheels(pc),a0
 moveq #2,d3
.axis:
 move.w (a0),d0
 ext.l d0
 move.w 6(a0),d1
 ext.l d1
 add.l d1,d0
 move.w 12(a0),d1
 ext.l d1
 add.l d1,d0
 move.w 18(a0),d1
 ext.l d1
 add.l d1,d0
 asr.l #2,d0
 sub.w d0,(a0)
 sub.w d0,6(a0)
 sub.w d0,12(a0)
 sub.w d0,18(a0)
 addq.l #2,a0
 dbra d3,.axis
 rts

; Apply the SAME native heading/pitch matrix and per-vector floor operation.
sim_tilt_rotate:
 lea sim_tilt_wheels(pc),a3
 moveq #3,d7
 lea -6(sp),sp
.wheel:
 move.l sp,d0
 move.l a3,a0
 lea -$28(a5),a1
 jsr -$7bd8(a4)
 move.l (sp),(a3)+
 move.w 4(sp),(a3)+
 dbra d7,.wheel
 lea 6(sp),sp
 rts

; Same rear-minus-front axis and signs as D514..D55A.
; A0 four centered XYZ word triplets -> D0=x=-Z, D1=y=Y.
sim_tilt_pitch_vector:
 move.w 16(a0),d0
 add.w 22(a0),d0
 sub.w 4(a0),d0
 sub.w 10(a0),d0
 neg.w d0
 move.w 14(a0),d1
 add.w 20(a0),d1
 sub.w 2(a0),d1
 sub.w 8(a0),d1
 rts
; Same transverse axis and signs as D5F2..D634.
sim_tilt_roll_vector:
 move.w 6(a0),d0
 add.w 12(a0),d0
 sub.w (a0),d0
 sub.w 18(a0),d0
 move.w 8(a0),d1
 add.w 14(a0),d1
 sub.w 2(a0),d1
 sub.w 20(a0),d1
 rts

sim_tilt_private:
 lea sim_a4000_private+144(pc),a2
 lea -$85e(a4),a0
 cmpa.l 8(a5),a0
 bne .player
 addq.l #4,a2
.player:
 rts

; Full replacement of D514..D584. Original blocks have internal relative
; branches only and A4-relative calls; copied fallbacks keep native10/20 exact.
sim_tilt_pitch:
 cmp.w #50,-$15fa(a4)
 bne sim_native_pitch
 movem.l d0-a6,-(sp)
 bsr sim_tilt_center
 bsr sim_tilt_rotate
 bsr sim_tilt_private
 lea -$102(a5),a0
 bsr sim_tilt_pitch_vector
 move.w d0,d6
 move.w d1,d7
 lea sim_tilt_wheels(pc),a0
 bsr sim_tilt_pitch_vector
 bsr sim_tilt_angle
 move.w d0,$baa(a4)
 movem.l (sp)+,d0-a6
 rts

sim_tilt_roll:
 cmp.w #50,-$15fa(a4)
 bne sim_native_roll
 movem.l d0-a6,-(sp)
 tst.w $baa(a4)
 beq .unrotated
 bsr sim_tilt_rotate
.unrotated:
 bsr sim_tilt_private
 addq.l #2,a2
 lea -$102(a5),a0
 bsr sim_tilt_roll_vector
 move.w d0,d6
 move.w d1,d7
 lea sim_tilt_wheels(pc),a0
 bsr sim_tilt_roll_vector
 bsr sim_tilt_angle
 move.w d0,$ba8(a4)
 movem.l (sp)+,d0-a6
 rts

; Baseline D0/D1, final D6/D7, signed centered Q8 carry at A2.
; Preserve the native integer baseline angle, then add the high precision
; geometric change and old fractional carry. Round once; do not discard +/-1.
; Degenerate final/baseline axes cannot transport a fraction reliably.
sim_tilt_angle:
 move.w d0,d2
 or.w d1,d2
 beq .degenerate
 move.w d6,d2
 or.w d7,d2
 beq .degenerate
 move.w d1,-(sp)
 move.w d0,-(sp)
 bsr sim_yaw_atan_q8
 move.l d0,d4
 jsr -$7bae(a4)
 addq.l #4,sp
 ext.l d0
 lsl.l #8,d0
 move.l d0,d5
 move.w d6,d0
 move.w d7,d1
 bsr sim_yaw_atan_q8
 sub.l d4,d0
 and.l #$3ffff,d0
 cmp.l #$20000,d0
 blo .delta
 sub.l #$40000,d0
.delta:
 bsr sim_tilt_stabilize
 blo .stabilized
 add.l d5,d0
 move.w (a2),d1
 ext.l d1
 add.l d1,d0
 add.l #128,d0
 move.w d0,d1
 and.w #255,d1
 sub.w #128,d1
 move.w d1,(a2)
 lsr.l #8,d0
 and.w #$3ff,d0
 cmp.w #512,d0
 blo .angle
 bhi .negative
 tst.w d6
 bpl .angle
.negative:
 sub.w #1024,d0
.angle:
 sub.w #256,d0
 rts
.stabilized:
 clr.w (a2)
 moveq #0,d0
 rts
.degenerate:
 clr.w (a2)
 move.w d6,d0
 or.w d7,d0
 beq .zero
 move.w d7,-(sp)
 move.w d6,-(sp)
 jsr -$7bae(a4)
 addq.l #4,sp
 sub.w #256,d0
 move.w d0,d1
 bpl .absolute
 neg.w d1
.absolute:
 cmp.w #2,d1
 bge .fallback_done
 moveq #0,d0
.fallback_done:
 rts
.zero:
 moveq #0,d0
 rts
 even
sim_tilt_wheels: dcb.w 12,0

; Evaluate the native near-level gate at its A2500 reference interval. D0 is
; the actual Q8 angle change, D5 the native atan baseline before subtracting
; the quarter-turn, A2 the old carry. Preserve D0/D5/A2. D1 returns absolute
; maximum actual/reference tilt magnitude in Q9; C means both are below cutoff.
; Native table index3 is the first value2. Its rounded-ratio lower boundary
; is640/65536, atan=1.59149884 angle units: ceil(Q8)=408. Doubling avoids
; asymmetric rounding of (5/2)*delta. The extrapolated reference can cross
; zero while the actual state remains steep: require BOTH to be near level.
sim_tilt_stabilize:
 move.l d0,d1
 asl.l #2,d1
 add.l d0,d1
 move.l d5,d2
 sub.l #65536,d2
 move.w (a2),d3
 ext.l d3
 add.l d3,d2
 add.l d2,d2
 add.l d2,d1
 add.l #$40000,d1
 and.l #$7ffff,d1
 sub.l #$40000,d1
 bpl .absolute
 neg.l d1
.absolute:
 ; A reference prediction may cross level before the actual50Hz state.
 ; Require BOTH the reference and actual result to lie in the native band.
 move.l d0,d3
 add.l d3,d3
 add.l d3,d2
 add.l #$40000,d2
 and.l #$7ffff,d2
 sub.l #$40000,d2
 bpl .actual_absolute
 neg.l d2
.actual_absolute:
 cmp.l d2,d1
 bhs .gate_range
 move.l d2,d1
.gate_range:
 cmp.l #816,d1
 rts

 IFD SIM_TILT_COLLECT_VERIFY
 IFND VERIFY
 FAIL "Collector flag observation requires VERIFY"
 ENDC
 even
sim_tilt_collect_marker:
 dc.b "4DTILTX!"
 dc.w 1,0
 dc.l 0,0                 ; calls,mismatches
 dc.w 0                   ; current incoming X, main-task scratch only
 dc.l 0,0                 ; outgoing zero/one observations
 ENDC
