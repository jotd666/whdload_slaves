; A4000 fragment motion. Native10/20 displaced paths remain exact.
; State layout per slot (8 bytes): rv,ry,rx,rz,rangle,reserved[3].
; rv/rx/rz/rangle are 0..4; ry is 0..24. Clear at birth/reset.
;
; D0 signed numerator, D1 positive divisor -> D0 signed long floor quotient,
; D1 remainder 0..divisor-1. DIVS quotient must fit signed16 bits.
; All other registers preserved. Correct native truncation for negative inputs.
sim_aux_div_floor:
 move.l d2,-(sp)
 divs d1,d0
 move.l d0,d2
 ext.l d0
 swap d2
 tst.w d2
 bpl .remainder
 subq.l #1,d0
 add.w d1,d2
.remainder:
 moveq #0,d1
 move.w d2,d1
 move.l (sp)+,d2
 rts

; D0.w nominal20Hz signed component, A0 -> fractional byte.
; D0.l output delta; update byte. Preserve all other registers.
; Also used for the shared angular increment: component16 -> 6/7 steps.
sim_aux_component_50:
 movem.l d1-d2,-(sp)
 muls #2,d0
 moveq #0,d2
 move.b (a0),d2
 add.l d2,d0
 moveq #5,d1
 bsr sim_aux_div_floor
 move.b d1,(a0)
 movem.l (sp)+,d1-d2
 rts

; D0.w native vertical velocity, A0 -> slot state.
; D0.l Y delta, D1.l next signed16-bit velocity; update rv/ry only.
; Other registers preserved. The position correction retains the A2500
; kick-then-drift trajectory at five50Hz/two20Hz common boundaries.
sim_aux_vertical_50:
 movem.l d2-d4,-(sp)
 move.w d0,d4
 muls #10,d0
 moveq #0,d2
 move.b (a0),d2
 add.w d2,d2
 add.l d2,d0
 moveq #0,d2
 move.b 1(a0),d2
 add.l d2,d0
 sub.l #133,d0
 moveq #25,d1
 bsr sim_aux_div_floor
 move.b d1,1(a0)
 move.l d0,d3
 moveq #0,d0
 move.b (a0),d0
 sub.w #38,d0
 ext.l d0
 moveq #5,d1
 bsr sim_aux_div_floor
 move.b d1,(a0)
 add.w d4,d0             ; retain native velocity word storage/wrapping
 move.l d0,d1
 ext.l d1
 move.l d3,d0
 movem.l (sp)+,d2-d4
 rts

; Copy the branch-free native movement/angle blocks before patch installation.
sim_aux_prepare:
 lea sim_aux_prepare(pc),a0
 adda.l #sim_game-sim_aux_prepare,a0
 movea.l (a0),a0
 adda.l #$11b80,a0
 lea sim_aux_native_move(pc),a1
 moveq #100/2-1,d0
.move:
 move.w (a0)+,(a1)+
 dbra d0,.move
 lea sim_aux_prepare(pc),a0
 adda.l #sim_game-sim_aux_prepare,a0
 movea.l (a0),a0
 adda.l #$11c50,a0
 lea sim_aux_native_rotate(pc),a1
 moveq #32/2-1,d0
.rotate:
 move.w (a0)+,(a1)+
 dbra d0,.rotate
 rts

; The native local -2(A5) identifies the slot. Preserve every register.
; Called at birth/retirement; displaced native arithmetic defines flags/X.
sim_aux_clear_slot:
 cmp.w #50,-$15fa(a4)
 bne .done
 movem.l d0/a0,-(sp)
 moveq #0,d0
 move.w -2(a5),d0
 lsl.l #3,d0
 lea sim_aux_state(pc),a0
 adda.l d0,a0
 clr.l (a0)+
 clr.l (a0)
 movem.l (sp)+,d0/a0
.done:
 rts
sim_aux_birth:
 bsr sim_aux_clear_slot
 move.w -2(a5),d0
 ext.l d0
 asl.l #2,d0
 rts
sim_aux_retire:
 bsr sim_aux_clear_slot
 move.w -2(a5),d0
 ext.l d0
 add.l d0,d0
 lea -$6f2(a4),a0
 clr.w (a0,d0.l)
 rts

; 11B80..11BE4 only: native matrix-argument cleanup at11BEA stays outside
; the hook, as does Normal's second vertical substep and ground predicate.
sim_aux_move:
 cmp.w #50,-$15fa(a4)
 bne sim_aux_native_move
 movem.l d1-d3/a2,-(sp)
 moveq #0,d2
 move.w -2(a5),d2
 add.l d2,d2
 move.l d2,d3             ; word-array displacement
 add.l d2,d2             ; long-array displacement
 move.l d2,d0
 add.l d0,d0
 lea sim_aux_state(pc),a2
 adda.l d0,a2
 lea 2(a2),a0
 move.w -$14(a5),d0
 bsr sim_aux_component_50
 lea -$a80(a4),a1
 add.l d0,(a1,d2.l)
 lea 3(a2),a0
 move.w -$10(a5),d0
 bsr sim_aux_component_50
 lea -$9c0(a4),a1
 add.l d0,(a1,d2.l)
 movea.l a2,a0
 lea -$6c2(a4),a1
 move.w (a1,d3.l),d0
 bsr sim_aux_vertical_50
 move.w d1,(a1,d3.l)
 lea -$a20(a4),a0
 adda.l d2,a0
 add.l d0,(a0)
 movem.l (sp)+,d1-d3/a2
 rts
sim_aux_native_move: dcb.b 100,0
 rts

; Same per-slot fractional increment for both rotating angles. Heading is
; fixed by creation and must not be changed by the rotation carry.
sim_aux_rotate:
 cmp.w #50,-$15fa(a4)
 bne sim_aux_native_rotate
 movem.l d0-d2,-(sp)
 moveq #0,d2
 move.w -2(a5),d2
 lsl.l #3,d2
 lea sim_aux_state+4(pc),a0
 adda.l d2,a0
 moveq #16,d0
 bsr sim_aux_component_50
 move.w -2(a5),d2
 add.w d2,d2
 lea -$782(a4),a1
 add.w d0,(a1,d2.w)
 lea -$752(a4),a1
 lea (a1,d2.w),a0
 add.w d0,(a0)
 movem.l (sp)+,d0-d2
 rts
sim_aux_native_rotate: dcb.b 32,0
 rts

 even
 dc.b "4DAUXPHY"
 dc.w 1,SIM_AUX_BYTES
sim_aux_state: dcb.b SIM_AUX_BYTES,0
 dc.l $41555847
