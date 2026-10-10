; Executed before the route task starts; these kernels do not alter game state.
sim_physics_selftest:
 movem.l d0-a6,-(sp)
 lea sim_physics_passed(pc),a0
 clr.l (a0)
 ; Projection fractions and signed centroids use independent integer oracles.
 lea sim_centroid_matrix_cases(pc),a3
 move.w #(sim_centroid_matrix_cases_end-sim_centroid_matrix_cases)/48-1,d6
.centroid_matrix:
 movea.l a3,a0
 lea 6(a3),a1
 lea sim_centroid_test_accumulator(pc),a2
 move.l 24(a3),(a2)
 move.l 28(a3),4(a2)
 move.l 32(a3),8(a2)
 bsr sim_centroid_collect
 move.l (a2),d0
 cmp.l 36(a3),d0
 bne .failed
 move.l 4(a2),d0
 cmp.l 40(a3),d0
 bne .failed
 move.l 8(a2),d0
 cmp.l 44(a3),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 48(a3),a3
 dbra d6,.centroid_matrix
 lea sim_centroid_average_cases(pc),a2
 move.w #(sim_centroid_average_cases_end-sim_centroid_average_cases)/16-1,d6
.centroid_average:
 lea sim_physics_test_fraction(pc),a0
 move.w 8(a2),(a0)
 move.l (a2),d0
 move.l 4(a2),d1
 bsr sim_centroid_average
 cmp.l 10(a2),d0
 bne .failed
 cmp.l 4(a2),d1
 bne .failed
 move.w (a0),d0
 cmp.w 14(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 16(a2),a2
 dbra d6,.centroid_average
 ; High-resolution angle lookup: compare to an independent atan2 oracle.
 lea sim_yaw_cases(pc),a2
 move.w #(sim_yaw_cases_end-sim_yaw_cases)/8-1,d6
.yaw:
 move.w (a2),d0
 move.w 2(a2),d1
 bsr sim_yaw_atan_q8
 cmp.w 2(a2),d1
 bne .failed
 sub.l 4(a2),d0
 add.l #$20000,d0
 and.l #$3ffff,d0
 sub.l #$20000,d0
 bpl .yaw_absolute
 neg.l d0
.yaw_absolute:
 cmp.l #2,d0              ; at most 2/256 angle units circular error
 bhi .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 addq.l #8,a2
 dbra d6,.yaw
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
 move.l (a1),d5
 bsr sim_airborne_pair_50
 sub.l (a1),d5
 cmp.l d5,d1
 bne .failed
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
 lea sim_skid_cases(pc),a2
 move.w #(sim_skid_cases_end-sim_skid_cases)/12-1,d6
.skid:
 lea sim_physics_test_fraction(pc),a0
 move.w 6(a2),(a0)
 move.w (a2),d0
 move.w 2(a2),d1
 move.w 4(a2),d2
 bsr sim_skid_loss_50
 cmp.w 8(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 10(a2),d0
 bne .failed
 cmp.w 2(a2),d1
 bne .failed
 cmp.w 4(a2),d2
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 12(a2),a2
 dbra d6,.skid
 lea sim_opponent_brake_cases(pc),a2
 move.w #(sim_opponent_brake_cases_end-sim_opponent_brake_cases)/10-1,d6
.opponent_brake:
 lea sim_physics_test_fraction(pc),a0
 move.w 2(a2),(a0)
 move.w (a2),d0
 bsr sim_opponent_brake_50
 cmp.w 4(a2),d0
 bne .failed
 cmp.w 8(a2),d1
 bne .failed
 move.w (a0),d0
 cmp.w 6(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 10(a2),a2
 dbra d6,.opponent_brake
 lea sim_spin_filter_cases(pc),a2
 move.w #(sim_spin_filter_cases_end-sim_spin_filter_cases)/24-1,d6
.spin_filter:
 lea sim_physics_test_fraction(pc),a0
 move.w 8(a2),(a0)
 move.l 4(a2),4(a0)
 move.w (a2),d0
 moveq #0,d5
 moveq #4,d7
.spin_filter_five:
 move.w 2(a2),d1
 bsr sim_spin_filter_50
 add.l d1,d5
 dbra d7,.spin_filter_five
 cmp.w 12(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 14(a2),d0
 bne .failed
 move.l 4(a0),d0
 cmp.l 16(a2),d0
 bne .failed
 cmp.l 20(a2),d5
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 24(a2),a2
 dbra d6,.spin_filter
 lea sim_spin_alternate_cases(pc),a2
 move.w #(sim_spin_alternate_cases_end-sim_spin_alternate_cases)/24-1,d6
.spin_alternate:
 lea sim_physics_test_fraction(pc),a0
 move.w 8(a2),(a0)
 move.l 4(a2),4(a0)
 move.w (a2),d0
 moveq #0,d5
 moveq #4,d7
.spin_alternate_five:
 move.w 2(a2),d1
 bsr sim_spin_alternate_50
 add.l d1,d5
 dbra d7,.spin_alternate_five
 cmp.w 12(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 14(a2),d0
 bne .failed
 move.l 4(a0),d0
 cmp.l 16(a2),d0
 bne .failed
 cmp.l 20(a2),d5
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 24(a2),a2
 dbra d6,.spin_alternate
 lea sim_slip_relax_cases(pc),a2
 move.w #(sim_slip_relax_cases_end-sim_slip_relax_cases)/8-1,d6
.slip_relax:
 lea sim_physics_test_fraction(pc),a0
 move.w 2(a2),(a0)
 move.w (a2),d0
 moveq #4,d7
.slip_relax_five:
 bsr sim_slip_relax_50
 dbra d7,.slip_relax_five
 cmp.w 4(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 6(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 addq.l #8,a2
 dbra d6,.slip_relax
 lea sim_spin_held_cases(pc),a2
 move.w #(sim_spin_held_cases_end-sim_spin_held_cases)/12-1,d6
.spin_held:
 lea sim_physics_test_fraction(pc),a0
 move.w 2(a2),(a0)
 move.l 4(a2),4(a0)
 move.w (a2),d0
 bsr sim_spin_step_50
 cmp.w 8(a2),d0
 bne .failed
 move.w (a0),d0
 cmp.w 10(a2),d0
 bne .failed
 move.l 4(a0),d0
 cmp.l 4(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 12(a2),a2
 dbra d6,.spin_held
 lea sim_heading_cases(pc),a2
 move.w #(sim_heading_cases_end-sim_heading_cases)/10-1,d6
.heading:
 lea sim_physics_test_fraction(pc),a0
 move.w 4(a2),(a0)
 move.w (a2),d0
 move.w 2(a2),d1
 moveq #4,d7
.heading_five:
 bsr sim_heading_50
 dbra d7,.heading_five
 cmp.w 6(a2),d0
 bne .failed
 cmp.w 2(a2),d1
 bne .failed
 move.w (a0),d0
 cmp.w 8(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 10(a2),a2
 dbra d6,.heading
 IFD SIM_A4000
 bsr sim_delay_hooks_selftest
 tst.w d0
 bne .failed
 bsr sim_spin_hooks_selftest
 tst.w d0
 bne .failed
 bsr sim_spin_resets_selftest
 tst.w d0
 bne .failed
 bsr sim_slip_gate_selftest
 tst.w d0
 bne .failed
 bsr sim_slip_replace_selftest
 tst.w d0
 bne .failed
 bsr sim_heading_hooks_selftest
 tst.w d0
 bne .failed
 bsr sim_contact_distance_selftest
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
SIM_SPIN_HOOK_TESTS = 183
SIM_SLIP_HOOK_TESTS = 84
SIM_HEADING_HOOK_TESTS = (sim_heading_cases_end-sim_heading_cases)/10
SIM_CONTACT_HOOK_TESTS = 48
 ELSE
SIM_DELAY_HOOK_TESTS = 0
SIM_SPIN_HOOK_TESTS = 0
SIM_SLIP_HOOK_TESTS = 0
SIM_HEADING_HOOK_TESTS = 0
SIM_CONTACT_HOOK_TESTS = 0
 ENDC
 dc.b "4DPHYTST"
 dc.w 19,(sim_centroid_matrix_cases_end-sim_centroid_matrix_cases)/48+(sim_centroid_average_cases_end-sim_centroid_average_cases)/16+(sim_yaw_cases_end-sim_yaw_cases)/8+(sim_rate_cases_end-sim_rate_cases)/8+(sim_steering_cases_end-sim_steering_cases)/14+(sim_distance_cases_end-sim_distance_cases)/8+(sim_approach_cases_end-sim_approach_cases)/12+(sim_airborne_cases_end-sim_airborne_cases)/12+(sim_extension_cases_end-sim_extension_cases)/10+(sim_engine_cases_end-sim_engine_cases)/4+(sim_duration_cases_end-sim_duration_cases)/8+(sim_terrain_cases_end-sim_terrain_cases)/10+(sim_skid_cases_end-sim_skid_cases)/12+(sim_spin_filter_cases_end-sim_spin_filter_cases)/24+(sim_spin_held_cases_end-sim_spin_held_cases)/12+(sim_spin_alternate_cases_end-sim_spin_alternate_cases)/24+(sim_opponent_brake_cases_end-sim_opponent_brake_cases)/10+(sim_slip_relax_cases_end-sim_slip_relax_cases)/8+SIM_DELAY_HOOK_TESTS+SIM_SPIN_HOOK_TESTS+SIM_SLIP_HOOK_TESTS+SIM_HEADING_HOOK_TESTS+SIM_CONTACT_HOOK_TESTS+(sim_heading_cases_end-sim_heading_cases)/10
sim_physics_passed: dc.l 0
sim_physics_test_fraction: dc.w 0,0,0,0
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

 IFD SIM_A4000
; Directly exercise the four installed hooks: three modes, nine nominal rates,
; five updates each. Body-first order covers the airborne consumer; the real
; spin fixture covers slip-first order. Repeated reads must not spend carry.
sim_spin_hooks_selftest:
 movem.l d1-a6,-(sp)
 lea sim_delay_test_mode(pc),a4
 adda.l #$15fa,a4
 lea sim_spin_test_frame(pc),a5
 lea sim_delay_test_car(pc),a0
 move.l a0,8(a5)
 lea sim_a4000_private(pc),a6
 moveq #0,d5
.mode:
 lea sim_delay_test_modes(pc),a2
 move.w (a2,d5.w),-$15fa(a4)
 lea sim_spin_hook_cases(pc),a2
 moveq #8,d4
.case:
 move.l 8(a5),a0
 move.w (a2),$3e(a0)
 clr.w 52(a6)
 move.w #$1234,54(a6)
 clr.w $36(a0)
 moveq #0,d7
.tick:
 move.l 8(a5),a0
 move.b d7,$c1(a0)
 bsr sim_a4000_spin_begin
 move.w (a2),d6
 cmp.w #4,d5
 bne .expected
 move.w d7,d0
 add.w d0,d0
 move.w 2(a2,d0.w),d6
.expected:
 ; Original masked-read site preserves X for both incoming states.
 move.w d7,d2
 and.w #1,d2
 lsr.w #1,d2
 move.l 8(a5),a0
 bsr sim_a4000_spin_test
 moveq #0,d2
 addx.w d2,d2
 move.w d7,d3
 and.w #1,d3
 cmp.w d3,d2
 bne .failed
 move.w d6,d3
 and.w #$3ff,d3
 cmp.w d3,d0
 bne .failed
 move.l 8(a5),a0
 bsr sim_a4000_spin_rotate
 move.w d6,d3
 neg.w d3
 cmp.w d3,d0
 bne .failed
 move.l 8(a5),a1
 lea $36(a1),a0
 move.w (a0),d3
 sub.w d6,d3
 bsr sim_a4000_spin_slip
 cmp.w (a0),d3
 bne .failed
 move.l 8(a5),a0
 bsr sim_a4000_spin_test
 move.w d6,d3
 and.w #$3ff,d3
 cmp.w d3,d0
 bne .failed
 move.l 8(a5),a0
 move.w $3e(a0),d0
 cmp.w (a2),d0
 bne .failed
 cmp.w #4,d5
 bne .native_state
 move.w d7,d0
 add.w d0,d0
 move.w 12(a2,d0.w),d3
 cmp.w 52(a6),d3
 bne .failed
 cmp.w 54(a6),d6
 bne .failed
 bra .passed
.native_state:
 tst.w 52(a6)
 bne .failed
 cmp.w #$1234,54(a6)
 bne .failed
.passed:
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 addq.w #1,d7
 cmp.w #5,d7
 blt .tick
 lea 22(a2),a2
 dbra d4,.case
 addq.w #2,d5
 cmp.w #6,d5
 blt .mode
 clr.l 52(a6)
 lea sim_a4000_spin_step_calls(pc),a0
 clr.l (a0)
 moveq #0,d0
 bra .done
.failed:
 moveq #1,d0
.done:
 movem.l (sp)+,d1-a6
 rts
 even
 dcb.b 256,0 ; locals for direct contact-assignment and wheel-pass checks
sim_spin_test_frame: dc.l 0,0,0
; Nominal, five expected displacements, five expected /1280 remainders.
sim_spin_hook_cases:
 dc.w 0,0,0,0,0,0,0,0,0,0,0
 dc.w 1,0,0,1,0,1,512,1024,256,768,0
 dc.w -1,0,0,-1,0,-1,-512,-1024,-256,-768,0
 dc.w 7,2,3,3,3,3,1024,768,512,256,0
 dc.w -7,-2,-3,-3,-3,-3,-1024,-768,-512,-256,0
 dc.w 1023,409,409,409,409,410,256,512,768,1024,0
 dc.w -1023,-409,-409,-409,-409,-410,-256,-512,-768,-1024,0
 dc.w 32767,13106,13107,13107,13107,13107,1024,768,512,256,0
 dc.w -32768,-13107,-13107,-13107,-13107,-13108,-256,-512,-768,-1024,0
 ENDC

 IFD SIM_A4000
; Inactive/airborne cancellation and the actual-step slip gate. These checks
; cover pending fractions and differing nominal/actual zero states directly.
sim_spin_resets_selftest:
 movem.l d1-a6,-(sp)
 lea sim_delay_test_mode(pc),a4
 adda.l #$15fa,a4
 lea sim_spin_test_frame(pc),a5
 lea sim_delay_test_car(pc),a0
 move.l a0,8(a5)
 lea sim_a4000_private(pc),a6
 lea sim_spin_reset_cases(pc),a2
 moveq #23,d6
.reset:
 move.w (a2),-$15fa(a4)
 move.l 8(a5),a0
 move.w 2(a2),$3e(a0)
 move.b 5(a2),$c1(a0)
 move.l #12345,56(a6)
 move.w #3,60(a6)
 tst.w 6(a2)
 bne .inactive
 bsr sim_a4000_spin_begin
 bra .reset_check
.inactive:
 bsr sim_a4000_spin_inactive
.reset_check:
 moveq #3,d0
 cmp.w #50,(a2)
 bne.s .heading_carry
 tst.w 6(a2)
 bne.s .heading_carry
 tst.w 4(a2)
 bne.s .heading_carry
 moveq #0,d0
.heading_carry:
 cmp.w 60(a6),d0
 bne .failed
 moveq #0,d0
 move.w 8(a2),d0
 cmp.l 56(a6),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 10(a2),a2
 dbra d6,.reset
 clr.w 60(a6)
 lea sim_spin_gate_cases(pc),a2
 moveq #23,d6
.gate:
 move.w (a2),-$15fa(a4)
 move.l 8(a5),a0
 move.w 2(a2),$3e(a0)
 move.w 4(a2),54(a6)
 move.w #123,52(a6)
 move.w 6(a2),d2
 lsr.w #1,d2
 move.l #$12345678,d0
 bsr sim_a4000_spin_slip_test
 seq d3
 moveq #0,d2
 addx.w d2,d2
 cmp.w 6(a2),d2
 bne .failed
 cmp.l #$12345678,d0
 bne .failed
 move.w 2(a2),d1
 cmp.w #50,(a2)
 bne .gate_expected
 move.w 4(a2),d1
.gate_expected:
 tst.w d1
 seq d2
 cmp.b d2,d3
 bne .failed
 cmp.w #123,52(a6)
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 addq.l #8,a2
 dbra d6,.gate
 clr.l 52(a6)
 clr.l 56(a6)
 moveq #0,d0
 bra .done
.failed:
 moveq #1,d0
.done:
 movem.l (sp)+,d1-a6
 rts
 even
; mode,nominal,contact,which(0=begin/1=inactive),expected pending carry.
sim_spin_reset_cases:
 dc.w 10,0,0,0,12345
 dc.w 10,0,0,1,12345
 dc.w 10,0,1,0,12345
 dc.w 10,0,1,1,12345
 dc.w 10,1,0,0,12345
 dc.w 10,1,0,1,12345
 dc.w 10,1,1,0,12345
 dc.w 10,1,1,1,12345
 dc.w 20,0,0,0,12345
 dc.w 20,0,0,1,12345
 dc.w 20,0,1,0,12345
 dc.w 20,0,1,1,12345
 dc.w 20,1,0,0,12345
 dc.w 20,1,0,1,12345
 dc.w 20,1,1,0,12345
 dc.w 20,1,1,1,12345
 dc.w 50,0,0,0,0
 dc.w 50,0,0,1,0
 dc.w 50,0,1,0,12345
 dc.w 50,0,1,1,0
 dc.w 50,1,0,0,12345
 dc.w 50,1,0,1,12345
 dc.w 50,1,1,0,12345
 dc.w 50,1,1,1,12345
; mode,nominal,cached actual step,incoming X.
sim_spin_gate_cases:
 dc.w 10,0,0,0
 dc.w 10,0,0,1
 dc.w 10,0,1,0
 dc.w 10,0,1,1
 dc.w 10,1,0,0
 dc.w 10,1,0,1
 dc.w 10,1,1,0
 dc.w 10,1,1,1
 dc.w 20,0,0,0
 dc.w 20,0,0,1
 dc.w 20,0,1,0
 dc.w 20,0,1,1
 dc.w 20,1,0,0
 dc.w 20,1,0,1
 dc.w 20,1,1,0
 dc.w 20,1,1,1
 dc.w 50,0,0,0
 dc.w 50,0,0,1
 dc.w 50,0,1,0
 dc.w 50,0,1,1
 dc.w 50,1,0,0
 dc.w 50,1,0,1
 dc.w 50,1,1,0
 dc.w 50,1,1,1
 ENDC

 IFD SIM_A4000
; Exercise the actual slip reset hook: native TST flags, X, D0, A0 and
; canonical/noncanonical/inactive carry ownership across all three modes.
sim_slip_gate_selftest:
 movem.l d1-a6,-(sp)
 lea sim_delay_test_mode(pc),a4
 adda.l #$15fa,a4
 lea sim_spin_test_frame(pc),a5
 lea sim_delay_test_car(pc),a0
 move.l a0,8(a5)
 lea sim_a4000_private(pc),a6
 lea sim_slip_gate_cases(pc),a2
 moveq #71,d6
.case:
 move.w (a2),-$15fa(a4)
 move.l 8(a5),a0
 move.w 2(a2),$36(a0)
 move.w 4(a2),$3e(a0)
 move.w #$1234,62(a6)
 move.w 6(a2),d2
 lsr.w #1,d2
 move.l #$76543210,d0
 bsr sim_a4000_slip_gate
 smi d3
 seq d4
 scs d5
 svs d1
 moveq #0,d2
 addx.w d2,d2
 cmp.w 6(a2),d2
 bne .failed
 cmp.l #$76543210,d0
 bne .failed
 cmpa.l 8(a5),a0
 bne .failed
 tst.b d5
 bne .failed
 tst.b d1
 bne .failed
 tst.w 2(a2)
 smi d1
 seq d2
 cmp.b d1,d3
 bne .failed
 cmp.b d2,d4
 bne .failed
 move.w 62(a6),d0
 cmp.w 8(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 10(a2),a2
 dbra d6,.case
 clr.w 62(a6)
 moveq #0,d0
 bra.s .done
.failed:
 moveq #1,d0
.done:
 movem.l (sp)+,d1-a6
 rts
 even
; Mode,slip,spin,incomingX,expected fraction.
sim_slip_gate_cases:
 dc.w 10,-1,0,0,4660
 dc.w 10,-1,0,1,4660
 dc.w 10,-1,1,0,4660
 dc.w 10,-1,1,1,4660
 dc.w 10,0,0,0,4660
 dc.w 10,0,0,1,4660
 dc.w 10,0,1,0,4660
 dc.w 10,0,1,1,4660
 dc.w 10,1,0,0,4660
 dc.w 10,1,0,1,4660
 dc.w 10,1,1,0,4660
 dc.w 10,1,1,1,4660
 dc.w 10,1023,0,0,4660
 dc.w 10,1023,0,1,4660
 dc.w 10,1023,1,0,4660
 dc.w 10,1023,1,1,4660
 dc.w 10,1024,0,0,4660
 dc.w 10,1024,0,1,4660
 dc.w 10,1024,1,0,4660
 dc.w 10,1024,1,1,4660
 dc.w 10,32767,0,0,4660
 dc.w 10,32767,0,1,4660
 dc.w 10,32767,1,0,4660
 dc.w 10,32767,1,1,4660
 dc.w 20,-1,0,0,4660
 dc.w 20,-1,0,1,4660
 dc.w 20,-1,1,0,4660
 dc.w 20,-1,1,1,4660
 dc.w 20,0,0,0,4660
 dc.w 20,0,0,1,4660
 dc.w 20,0,1,0,4660
 dc.w 20,0,1,1,4660
 dc.w 20,1,0,0,4660
 dc.w 20,1,0,1,4660
 dc.w 20,1,1,0,4660
 dc.w 20,1,1,1,4660
 dc.w 20,1023,0,0,4660
 dc.w 20,1023,0,1,4660
 dc.w 20,1023,1,0,4660
 dc.w 20,1023,1,1,4660
 dc.w 20,1024,0,0,4660
 dc.w 20,1024,0,1,4660
 dc.w 20,1024,1,0,4660
 dc.w 20,1024,1,1,4660
 dc.w 20,32767,0,0,4660
 dc.w 20,32767,0,1,4660
 dc.w 20,32767,1,0,4660
 dc.w 20,32767,1,1,4660
 dc.w 50,-1,0,0,0
 dc.w 50,-1,0,1,0
 dc.w 50,-1,1,0,0
 dc.w 50,-1,1,1,0
 dc.w 50,0,0,0,0
 dc.w 50,0,0,1,0
 dc.w 50,0,1,0,0
 dc.w 50,0,1,1,0
 dc.w 50,1,0,0,4660
 dc.w 50,1,0,1,4660
 dc.w 50,1,1,0,0
 dc.w 50,1,1,1,0
 dc.w 50,1023,0,0,4660
 dc.w 50,1023,0,1,4660
 dc.w 50,1023,1,0,0
 dc.w 50,1023,1,1,0
 dc.w 50,1024,0,0,0
 dc.w 50,1024,0,1,0
 dc.w 50,1024,1,0,0
 dc.w 50,1024,1,1,0
 dc.w 50,32767,0,0,0
 dc.w 50,32767,0,1,0
 dc.w 50,32767,1,0,0
 dc.w 50,32767,1,1,0
 ENDC

 IFD SIM_A4000
sim_slip_replace_selftest:
 movem.l d1-a6,-(sp)
 lea sim_delay_test_mode(pc),a4
 adda.l #$15fa,a4
 lea sim_spin_test_frame(pc),a5
 move.w #1023,-$80(a5)
 lea sim_a4000_private(pc),a6
 moveq #0,d7
.mode:
 lea sim_delay_test_modes(pc),a2
 move.w (a2,d7.w),-$15fa(a4)
 moveq #0,d6
.x:
 moveq #0,d5
.variant:
 move.w #$1234,62(a6)
 lea sim_delay_test_car(pc),a0
 move.l #$76543210,d0
 tst.w d5
 bne.s .dynamic
 move.w d6,d2
 lsr.w #1,d2
 bsr sim_a4000_slip_impulse_fixed
 move.w #512,d3
 bra.s .check
.dynamic:
 move.w d6,d2
 lsr.w #1,d2
 bsr sim_a4000_slip_impulse_dynamic
 move.w #1023,d3
.check:
 moveq #0,d2
 addx.w d2,d2
 cmp.w d6,d2
 bne .failed
 cmp.l #$76543210,d0
 bne .failed
 lea sim_delay_test_car(pc),a1
 cmpa.l a1,a0
 bne .failed
 cmp.w $36(a0),d3
 bne .failed
 move.w #$1234,d4
 cmp.w #4,d7
 bne.s .carry
 moveq #0,d4
.carry:
 cmp.w 62(a6),d4
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 addq.w #1,d5
 cmp.w #2,d5
 blt .variant
 addq.w #1,d6
 cmp.w #2,d6
 blt .x
 addq.w #2,d7
 cmp.w #6,d7
 blt .mode
 clr.w 62(a6)
 moveq #0,d0
 bra.s .done
.failed:
 moveq #1,d0
.done:
 movem.l (sp)+,d1-a6
 rts
 ENDC

 IFD SIM_A4000
; Same trajectories through the actual 50 Hz hook, verifying A0 and D1 as
; well as the state and carry. Native copied fallback is checked live.
sim_heading_hooks_selftest:
 movem.l d1-a6,-(sp)
 lea sim_delay_test_mode(pc),a4
 adda.l #$15fa,a4
 move.w #50,-$15fa(a4)
 lea sim_spin_test_frame(pc),a5
 lea sim_delay_test_car(pc),a0
 move.l a0,8(a5)
 lea sim_a4000_private(pc),a6
 lea sim_heading_cases(pc),a2
 move.w #(sim_heading_cases_end-sim_heading_cases)/10-1,d6
.case:
 move.l 8(a5),a0
 move.w (a2),$18(a0)
 move.w 2(a2),$20(a0)
 move.w 4(a2),60(a6)
 move.l #$76543210,d1
 moveq #4,d7
.five:
 bsr sim_a4000_heading
 dbra d7,.five
 cmp.l #$76543210,d1
 bne .failed
 cmpa.l 8(a5),a0
 bne .failed
 move.w $18(a0),d0
 cmp.w 6(a2),d0
 bne .failed
 move.w 60(a6),d0
 cmp.w 8(a2),d0
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 10(a2),a2
 dbra d6,.case
 clr.w 60(a6)
 lea sim_a4000_heading_calls(pc),a0
 clr.l (a0)
 moveq #0,d0
 bra.s .done
.failed:
 moveq #1,d0
.done:
 movem.l (sp)+,d1-a6
 rts
 ENDC

 IFD SIM_A4000
; Actual contact hook: all modes/wheels, integrated and skipped pair paths,
; negative rates, word carry/overflow/zero, and non-consuming fraction reads.
sim_contact_distance_selftest:
 movem.l d1-a6,-(sp)
 lea sim_delay_test_mode(pc),a4
 adda.l #$15fa,a4
 lea sim_spin_test_frame(pc),a5
 lea sim_delay_test_car(pc),a0
 move.l a0,8(a5)
 lea sim_a4000_private(pc),a6
 lea sim_physics_test_position(pc),a0
 move.l a0,-$ea(a5)
 move.l a0,-$e6(a5)
 lea sim_contact_distance_cases(pc),a2
 moveq #47,d6
.case:
 move.w (a2),-$15fa(a4)
 moveq #0,d0
 move.w 2(a2),d0
 move.l 8(a5),a0
 move.w 4(a2),$4c(a0,d0.w)
 move.w d0,d2
 add.w d2,d2
 move.w 6(a2),8(a6,d2.w)
 lea sim_a4000_wheel_steps(pc),a1
 move.w 8(a2),(a1,d0.w)
 move.w 10(a2),8(a1,d0.w)
 move.w 12(a2),-6(a5)
 bsr sim_a4000_contact_distance
 ; Capture the flags before comparisons or shifting them into position.
 scs d3
 svs d4
 seq d5
 smi d7
 moveq #0,d1
 addx.w d1,d1
 cmp.w 14(a2),d0
 bne .failed
 swap d0
 tst.w d0
 bne .failed
 and.w #1,d3
 and.w #1,d4
 and.w #1,d5
 and.w #1,d7
 lsl.w #4,d1
 or.w d3,d1
 add.w d4,d4
 or.w d4,d1
 lsl.w #2,d5
 or.w d5,d1
 lsl.w #3,d7
 or.w d7,d1
 cmp.w 16(a2),d1
 bne .failed
 cmpa.l 8(a5),a0
 bne .failed
 move.w 8(a6,d2.w),d0
 cmp.w 6(a2),d0
 bne .failed
 ; Beginning the next pass invalidates only its selected wheel in50 Hz.
 lea sim_physics_test_position(pc),a0
 move.l a0,-$e6(a5)
 move.w 2(a2),d0
 lsr.w #1,d0
 move.b d0,-3(a5)
 moveq #1,d7
 lsr.w #1,d7
 move.l #$12345678,d0
 bsr sim_a4000_wheel_reset
 moveq #0,d7
 addx.w d7,d7
 cmp.w #1,d7
 bne .failed
 cmp.l #$12345678,d0
 bne .failed
 move.w 10(a2),d1
 cmp.w #50,(a2)
 bne.s .valid
 moveq #0,d1
.valid:
 lea sim_a4000_wheel_steps(pc),a0
 move.w 2(a2),d0
 cmp.w 8(a0,d0.w),d1
 bne .failed
 lea sim_physics_passed(pc),a0
 addq.l #1,(a0)
 lea 18(a2),a2
 dbra d6,.case
 lea sim_a4000_private(pc),a0
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.clear:
 clr.l (a0)+
 dbra d0,.clear
 lea sim_a4000_wheel_steps(pc),a0
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 clr.l (a0)+
 lea sim_a4000_contact_step_calls(pc),a0
 clr.l (a0)+
 clr.l (a0)
 IFD SIM_CONTACT_PROBE
 lea sim_contact_probe_count(pc),a0
 clr.l (a0)
 ENDC
 moveq #0,d0
 bra.s .done
.failed:
 moveq #1,d0
.done:
 movem.l (sp)+,d1-a6
 rts
 even
; mode,wheel*2,nominal velocity,fifths,cached step,valid,forward,result,CCR.
sim_contact_distance_cases:
 dc.w 10,0,537,2,216,1,183,720,0
 dc.w 10,0,-537,-2,-216,0,183,65182,8
 dc.w 10,0,32767,4,13106,0,32767,65534,10
 dc.w 10,0,-1,0,-1,1,1,0,21
 dc.w 10,2,537,2,216,1,183,720,0
 dc.w 10,2,-537,-2,-216,0,183,65182,8
 dc.w 10,2,32767,4,13106,0,32767,65534,10
 dc.w 10,2,-1,0,-1,1,1,0,21
 dc.w 10,4,537,2,216,1,183,720,0
 dc.w 10,4,-537,-2,-216,0,183,65182,8
 dc.w 10,4,32767,4,13106,0,32767,65534,10
 dc.w 10,4,-1,0,-1,1,1,0,21
 dc.w 10,6,537,2,216,1,183,720,0
 dc.w 10,6,-537,-2,-216,0,183,65182,8
 dc.w 10,6,32767,4,13106,0,32767,65534,10
 dc.w 10,6,-1,0,-1,1,1,0,21
 dc.w 20,0,537,2,216,1,183,720,0
 dc.w 20,0,-537,-2,-216,0,183,65182,8
 dc.w 20,0,32767,4,13106,0,32767,65534,10
 dc.w 20,0,-1,0,-1,1,1,0,21
 dc.w 20,2,537,2,216,1,183,720,0
 dc.w 20,2,-537,-2,-216,0,183,65182,8
 dc.w 20,2,32767,4,13106,0,32767,65534,10
 dc.w 20,2,-1,0,-1,1,1,0,21
 dc.w 20,4,537,2,216,1,183,720,0
 dc.w 20,4,-537,-2,-216,0,183,65182,8
 dc.w 20,4,32767,4,13106,0,32767,65534,10
 dc.w 20,4,-1,0,-1,1,1,0,21
 dc.w 20,6,537,2,216,1,183,720,0
 dc.w 20,6,-537,-2,-216,0,183,65182,8
 dc.w 20,6,32767,4,13106,0,32767,65534,10
 dc.w 20,6,-1,0,-1,1,1,0,21
 dc.w 50,0,537,2,216,1,183,399,0
 dc.w 50,0,-537,-2,-216,0,183,65505,8
 dc.w 50,0,32767,4,13106,0,32767,45874,10
 dc.w 50,0,-1,0,-1,1,1,0,21
 dc.w 50,2,537,2,216,1,183,399,0
 dc.w 50,2,-537,-2,-216,0,183,65505,8
 dc.w 50,2,32767,4,13106,0,32767,45874,10
 dc.w 50,2,-1,0,-1,1,1,0,21
 dc.w 50,4,537,2,216,1,183,399,0
 dc.w 50,4,-537,-2,-216,0,183,65505,8
 dc.w 50,4,32767,4,13106,0,32767,45874,10
 dc.w 50,4,-1,0,-1,1,1,0,21
 dc.w 50,6,537,2,216,1,183,399,0
 dc.w 50,6,-537,-2,-216,0,183,65505,8
 dc.w 50,6,32767,4,13106,0,32767,45874,10
 dc.w 50,6,-1,0,-1,1,1,0,21
 ENDC

 include "simulation_yaw_cases.i"

sim_centroid_test_accumulator: dcb.l 3,0
 include "simulation_centroid_cases.i"
