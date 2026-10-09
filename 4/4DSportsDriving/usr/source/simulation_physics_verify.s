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
 lea sim_extension_cases(pc),a2
 move.w #(sim_extension_cases_end-sim_extension_cases)/10-1,d6
.extension:
 lea sim_physics_test_fraction(pc),a0
 move.w 4(a2),(a0)
 move.w (a2),d0
 move.w 2(a2),d1
 bsr sim_extension_50
 cmp.w 6(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 8(a2),d0
 bne .failed
 cmp.w 2(a2),d1
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 10(a2),a2
 dbra d6,.extension
 lea sim_engine_cases(pc),a2
 move.w #(sim_engine_cases_end-sim_engine_cases)/4-1,d6
.engine:
 move.w (a2),d0
 moveq #4,d7
.engine_five:
 bsr sim_engine_decay_50
 dbra d7,.engine_five
 cmp.w 2(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 addq.l #4,a2
 dbra d6,.engine
 lea sim_duration_cases(pc),a2
 move.w #(sim_duration_cases_end-sim_duration_cases)/8-1,d6
.duration:
 move.w (a2),d0
 bsr sim_duration_20_to_50
 cmp.l 4(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 addq.l #8,a2
 dbra d6,.duration
 lea sim_terrain_cases(pc),a2
 move.w #(sim_terrain_cases_end-sim_terrain_cases)/10-1,d6
.terrain:
 lea sim_physics_test_fraction(pc),a0
 move.w 6(a2),(a0)
 moveq #0,d0
 move.w (a2),d0
 moveq #4,d7
.terrain_five:
 move.l d0,d5
 move.w 2(a2),d1
 move.w 4(a2),d2
 bsr sim_terrain_drag_50
 cmp.l d5,d0
 bhi .failed
 cmp.w 2(a2),d5
 bhs .terrain_next
 cmp.l d5,d0
 bne .failed
 tst.w (a0)
 bne .failed
.terrain_next:
 dbra d7,.terrain_five
 moveq #0,d1
 move.w 8(a2),d1
 sub.l d1,d0
 cmp.l #-2,d0
 blt .failed
 cmp.l #2,d0
 bgt .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 10(a2),a2
 dbra d6,.terrain
 IFD SIM_A4000
 bsr sim_delay_hooks_selftest
 tst.w d0
 bne .failed
 ENDC
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #13,(a0)
 illegal
 bra .failed
 even
 IFD SIM_A4000
SIM_DELAY_HOOK_TESTS = 18
 ELSE
SIM_DELAY_HOOK_TESTS = 0
 ENDC
 dc.b "4DPHYTST"
 dc.w 5,(sim_rate_cases_end-sim_rate_cases)/8+(sim_steering_cases_end-sim_steering_cases)/14+(sim_distance_cases_end-sim_distance_cases)/8+(sim_approach_cases_end-sim_approach_cases)/12+(sim_airborne_cases_end-sim_airborne_cases)/12+(sim_extension_cases_end-sim_extension_cases)/10+(sim_engine_cases_end-sim_engine_cases)/4+(sim_duration_cases_end-sim_duration_cases)/8+(sim_terrain_cases_end-sim_terrain_cases)/10+SIM_DELAY_HOOK_TESTS
sim_physics_passed: dc.l 0
sim_physics_test_fraction: dc.w 0,0
sim_physics_test_position: dc.l 0
 include "simulation_physics_cases.i"

 IFD SIM_A4000
; Exercise the ACTUAL assignment hooks: 3 values x 3 modes x both incoming X
; states. Only their documented mode word is exposed through synthetic A4.
; Tests run before the game starts; the outer selftest restores all registers.
sim_delay_hooks_selftest:
 movem.l d1-a6,-(sp)
 lea sim_delay_test_mode(pc),a4
 adda.l #$15fa,a4
 lea sim_delay_test_car(pc),a0
 moveq #0,d5
.mode:
 lea sim_delay_test_modes(pc),a2
 move.w (a2,d5.w),-$15fa(a4)
 moveq #0,d4
.value:
 move.w d4,d3
 add.w d3,d3
 lea sim_delay_test_native(pc),a2
 cmp.w #4,d5
 bne .expected
 lea sim_delay_test_50(pc),a2
.expected:
 move.w (a2,d3.w),d6
 moveq #0,d7
.flags:
 move.l #$12345678,d0
 move.l #$89abcdef,d1
 move.l #$76543210,d2
 move.l #$13572468,a1
 move.w d7,d3
 lsr.b #1,d3
 tst.w d4
 beq .five
 cmp.w #1,d4
 beq .ten
 bsr sim_a4000_delay30
 bra .check
.five:
 bsr sim_a4000_delay5
 bra .check
.ten:
 bsr sim_a4000_delay10
.check:
 ; Original MOVE.B positive immediate sets N/Z/V/C=0, preserves X.
 bmi .failed
 beq .failed
 bvs .failed
 bcs .failed
 moveq #0,d3
 addx.b d3,d3
 cmp.w d7,d3
 bne .failed
 cmp.l #$12345678,d0
 bne .failed
 cmp.l #$89abcdef,d1
 bne .failed
 cmp.l #$76543210,d2
 bne .failed
 cmpa.l #$13572468,a1
 bne .failed
 lea sim_delay_test_car(pc),a2
 cmpa.l a2,a0
 bne .failed
 cmp.b $c6(a0),d6
 bne .failed
 lea sim_physics_passed(pc),a2
 addq.l #1,(a2)
 addq.w #1,d7
 cmp.w #2,d7
 blt .flags
 addq.w #1,d4
 cmp.w #3,d4
 blt .value
 addq.w #2,d5
 cmp.w #6,d5
 blt .mode
 ; Selftest calls are not live-race coverage.
 lea sim_a4000_delay5_calls(pc),a2
 clr.l (a2)+
 clr.l (a2)+
 clr.l (a2)
 moveq #0,d0
 bra .done
.failed:
 moveq #1,d0
.done:
 movem.l (sp)+,d1-a6
 rts
 even
sim_delay_test_modes: dc.w 10,20,50
sim_delay_test_native: dc.w 5,10,30
sim_delay_test_50: dc.w 13,25,75
sim_delay_test_mode: dc.w 0
sim_delay_test_car: dcb.b $d0,0
 ENDC
