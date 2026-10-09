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
 lea sim_distance_cases(pc),a2
 move.w #(sim_distance_cases_end-sim_distance_cases)/8-1,d6
.distance:
 lea sim_physics_test_fraction(pc),a0
 move.w 2(a2),(a0)
 move.w (a2),d0
 bsr sim_distance_50
 cmp.w 4(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 6(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 addq.l #8,a2
 dbra d6,.distance
 lea sim_approach_cases(pc),a2
 move.w #(sim_approach_cases_end-sim_approach_cases)/12-1,d6
.approach:
 lea sim_physics_test_fraction(pc),a0
 move.w 6(a2),(a0)
 move.w (a2),d0
 move.w 2(a2),d1
 move.w 4(a2),d2
 bsr sim_approach_50
 cmp.w 8(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 10(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 12(a2),a2
 dbra d6,.approach
 lea sim_airborne_cases(pc),a2
 move.w #(sim_airborne_cases_end-sim_airborne_cases)/12-1,d6
.airborne:
 lea sim_physics_test_fraction(pc),a0
 clr.l (a0)
 lea sim_physics_test_position(pc),a1
 clr.l (a1)
 move.w (a2),d0
 moveq #4,d7
.five:
 move.w 2(a2),d1
 bsr sim_airborne_pair_50
 dbra d7,.five
 cmp.w 4(a2),d0
 bne .failed
 tst.l (a0)
 bne .failed
 move.l (a1),d0
 cmp.l 8(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 12(a2),a2
 dbra d6,.airborne
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #13,(a0)
 illegal
 bra .failed
 even
 dc.b "4DPHYTST"
 dc.w 2,(sim_rate_cases_end-sim_rate_cases)/8+(sim_steering_cases_end-sim_steering_cases)/14+(sim_distance_cases_end-sim_distance_cases)/8+(sim_approach_cases_end-sim_approach_cases)/12+(sim_airborne_cases_end-sim_airborne_cases)/12
sim_physics_passed: dc.l 0
sim_physics_test_fraction: dc.w 0,0
sim_physics_test_position: dc.l 0
 include "simulation_physics_cases.i"
