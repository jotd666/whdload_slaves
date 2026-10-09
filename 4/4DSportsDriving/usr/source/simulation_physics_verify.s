; Executed before the route task starts; these kernels do not alter game state.
sim_physics_selftest:
 movem.l d0-a6,-(sp)
 lea sim_physics_passed(pc),a0
 clr.l (a0)
 lea sim_rate_cases(pc),a2
 move.w #(sim_rate_cases_end-sim_rate_cases)/8-1,d6
.rate:
 lea sim_physics_test_fraction(pc),a0
 move.w 2(a2),(a0)
 move.w (a2),d0
 bsr sim_rate_20_to_50
 cmp.w 4(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 6(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 addq.l #8,a2
 dbra d6,.rate
 lea sim_steering_cases(pc),a2
 move.w #(sim_steering_cases_end-sim_steering_cases)/14-1,d6
.steering:
 lea sim_physics_test_fraction(pc),a0
 move.w 8(a2),(a0)
 move.w (a2),d0
 move.w 2(a2),d1
 move.w 4(a2),d2
 move.w 6(a2),d3
 bsr sim_steering_50
 cmp.w 10(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 12(a2),d0
 bne .failed
 cmp.w 4(a2),d2
 bne .failed
 cmp.w 6(a2),d3
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 14(a2),a2
 dbra d6,.steering
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #13,(a0)
 illegal
 bra .failed
 even
 dc.b "4DPHYTST"
 dc.w 1,(sim_rate_cases_end-sim_rate_cases)/8+(sim_steering_cases_end-sim_steering_cases)/14
sim_physics_passed: dc.l 0
sim_physics_test_fraction: dc.w 0
 include "simulation_physics_cases.i"
