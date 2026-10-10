; A4000 fragment arithmetic, not yet installed in the native fragment loop.
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

 even
 dc.b "4DAUXPHY"
 dc.w 1,SIM_AUX_BYTES
sim_aux_state: dcb.b SIM_AUX_BYTES,0
 dc.l $41555847
