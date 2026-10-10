; Original integer atan reads the live game's table and jump stubs. Resolve
; its data anchor from LoadSeg's hunk chain rather than the startup caller A4.
sim_tilt_selftest:
 movem.l d1-a6,-(sp)
 lea sim_tilt_selftest(pc),a0
 adda.l #sim_game-sim_tilt_selftest,a0
 movea.l (a0),a4
 movea.l -4(a4),a4
 adda.l a4,a4
 adda.l a4,a4
 adda.l #$8002,a4
 lea sim_tilt_gate_cases(pc),a3
.gate:
 lea sim_tilt_test_fraction(pc),a2
 move.w 8(a3),(a2)
 move.l (a3),d0
 move.l 4(a3),d5
 lea sim_tilt_selftest(pc),a0
 adda.l #sim_tilt_stabilize-sim_tilt_selftest,a0
 jsr (a0)
 scs d4
 cmp.l (a3),d0
 bne .failed
 cmp.l 4(a3),d5
 bne .failed
 move.w (a2),d0
 cmp.w 8(a3),d0
 bne .failed
 cmp.l 12(a3),d1
 bne .failed
 move.l 12(a3),d2
 cmp.l #816,d2
 scs d3
 cmp.b d3,d4
 bne .failed
 lea sim_tilt_selftest(pc),a0
 adda.l #sim_physics_passed-sim_tilt_selftest,a0
 addq.l #1,(a0)
 lea 16(a3),a3
 lea sim_tilt_gate_cases_end(pc),a0
 cmpa.l a0,a3
 blo .gate
 lea sim_tilt_cases(pc),a3
.loop:
 lea sim_tilt_test_fraction(pc),a2
 move.w 8(a3),(a2)
 move.w (a3),d0
 move.w 2(a3),d1
 move.w 4(a3),d6
 move.w 6(a3),d7
 lea sim_tilt_selftest(pc),a0
 adda.l #sim_tilt_angle-sim_tilt_selftest,a0
 jsr (a0)
 move.w (a2),d1
 cmp.w #-128,d1
 blt .failed
 cmp.w #127,d1
 bgt .failed
 ext.l d0
 lsl.l #8,d0
 ext.l d1
 add.l d1,d0
 sub.l 12(a3),d0
 add.l #$20000,d0
 and.l #$3ffff,d0
 sub.l #$20000,d0
 bpl .absolute
 neg.l d0
.absolute:
 moveq #0,d1
 move.w 10(a3),d1
 cmp.l d1,d0
 bhi .failed
 lea sim_tilt_selftest(pc),a0
 adda.l #sim_physics_passed-sim_tilt_selftest,a0
 addq.l #1,(a0)
 lea 16(a3),a3
 lea sim_tilt_cases_end(pc),a0
 cmpa.l a0,a3
 blo .loop
 moveq #0,d0
 bra .out
.failed:
 moveq #1,d0
.out:
 movem.l (sp)+,d1-a6
 rts
sim_tilt_test_fraction: dc.w 0
 include "simulation_tilt_cases.i"

 include "simulation_tilt_gate_cases.i"
