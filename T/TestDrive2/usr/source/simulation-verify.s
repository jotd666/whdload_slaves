; VERIFY-only checks on private dummy data, using the actual shipping helpers.
verify_simulation_units:
    movem.l d0-a6,-(sp)
    lea verify_unit_results(pc),a0
    clr.l (a0)+
    clr.l (a0)+
    clr.l (a0)
    move.l #32768,d0
    move.l #$10001,d1
    move.l $4.w,a6
    jsr -198(a6)
    tst.l d0
    bne.b .allocated
    lea verify_unit_results(pc),a0
    move.l #1,(a0)
    bra .done
.allocated
    move.l d0,a4
    adda.l #32766,a4
    lea -64(a4),a5
    lea verify_rates(pc),a2
    moveq #11,d6
.vector
    lea sim_speed_frac(pc),a0
    clr.w (a0)
    moveq #0,d4
    moveq #5,d7
.six
    move.l (a2),d0
    bsr sim_scale_long
    add.l d0,d4
    dbf d7,.six
    move.l d4,d0
    move.l (a2)+,d1
    bsr verify_equal
    moveq #0,d0
    move.w (a0),d0
    moveq #0,d1
    bsr verify_equal
    dbf d6,.vector

    ; Changing signed rates: +1,-2,+3,-4,+5,-6 = -3; floor(-3/6)=-1,
    ; with a positive remainder of 3. No creeping rate is lost to truncation.
    moveq #0,d4
    lea verify_changing(pc),a2
    moveq #5,d7
.change
    move.l (a2)+,d0
    bsr sim_scale_long
    add.l d0,d4
    dbf d7,.change
    move.l d4,d0
    moveq #-1,d1
    bsr verify_equal
    moveq #0,d0
    move.w (a0),d0
    moveq #3,d1
    bsr verify_equal

    ; Actual heat producer: six calls preserve the original 3-unit increase.
    lea sim_heat_frac(pc),a0
    clr.w (a0)
    move.w #100,-24718(a4)
    moveq #5,d7
.heat
    moveq #3,d1
    bsr sim_heat_add
    dbf d7,.heat
    moveq #0,d0
    move.w -24718(a4),d0
    moveq #103,d1
    bsr verify_equal

    ; 1500 PAL fields = 30 seconds; clock and average-speed sums agree.
    lea sim_fractions(pc),a0
    clr.l (a0)+
    clr.l (a0)
    move.l #1,-10146(a4)
    moveq #100,d0
    move.w #1499,d7
.clock
    bsr sim_player_time
    dbf d7,.clock
    move.l -10146(a4),d0
    move.l #301,d1
    bsr verify_equal
    move.l -7674(a4),d0
    move.l #30000,d1
    bsr verify_equal

    ; Every original timer advances once in six fields, including police clamp.
    lea sim_phase(pc),a3
    move.w #1,16(a5)
    move.w #1,-12980(a4)
    move.w #10,-7642(a4)
    move.l #500000,2(a5)
    move.l #10001,10(a5)
    bsr sim_ai_prepare
    moveq #5,d7
.timers
    move.w d7,(a3)
    bsr sim_crash_timer
    bsr sim_police_timer
    bsr sim_police_time_motion
    move.l d0,2(a5)
    dbf d7,.timers
    moveq #0,d0
    move.w 16(a5),d0
    moveq #2,d1
    bsr verify_equal
    moveq #0,d0
    move.w -12980(a4),d0
    bsr verify_equal
    moveq #0,d0
    move.w -7642(a4),d0
    moveq #11,d1
    bsr verify_equal
    move.l 2(a5),d0
    move.l #510001,d1
    bsr verify_equal

    moveq #5,d7
    clr.l -13470(a4)
    move.l #100000,-13466(a4)
    move.l #30001,-7652(a4)
    move.w #200,6(a5)
.traffic
    move.l #61441,d0
    bsr sim_traffic_forward
    bsr sim_traffic_oncoming
    bsr sim_police_return_lane
    dbf d7,.traffic
    move.l -13470(a4),d0
    move.l #61441,d1
    bsr verify_equal
    move.l -13466(a4),d0
    move.l #69999,d1
    bsr verify_equal
    moveq #0,d0
    move.w 6(a5),d0
    move.l #159,d1
    bsr verify_equal

    ; Different car records cannot lend each other their fractional increments.
    lea sim_ai_rates(pc),a0
    moveq #13,d7
.clear_ai
    clr.l (a0)+
    dbf d7,.clear_ai
    move.l a5,a2
    moveq #5,d7
.cars
    move.l a2,a5
    bsr sim_ai_remainder
    moveq #1,d0
    bsr sim_scale_long
    add.l d0,2(a5)
    lea 48(a2),a5
    bsr sim_ai_remainder
    moveq #5,d0
    bsr sim_scale_long
    add.l d0,2(a5)
    dbf d7,.cars
    move.l 2(a2),d0
    move.l #510002,d1
    bsr verify_equal
    move.l 50(a2),d0
    moveq #5,d1
    bsr verify_equal

    ; Clamp hook preserves d1->d2 and changes its countdown once per six fields.
    move.w #10,-7642(a4)
    moveq #5,d7
.clamp
    move.w d7,(a3)
    moveq #21,d1
    bsr sim_police_limit
    dbf d7,.clamp
    moveq #0,d0
    move.w d2,d0
    bsr verify_equal
    moveq #0,d0
    move.w -7642(a4),d0
    moveq #9,d1
    bsr verify_equal

    ; Return-adjustment hook: mimic PatchSeg's site+6 return, including the
    ; overwritten trailing NOP. Non-boundary fields must land 56 bytes later.
    moveq #5,d7
.auto_gear
    move.w d7,(a3)
    moveq #0,d0
    bsr sim_auto_gear
    moveq #1,d0
    bra.w .land
    REPT 24
    nop
    ENDR
    moveq #2,d0             ; site+54 must fail, not silently execute a NOP
.land
    moveq #0,d1
    tst.w d7
    bne.b .check_auto
    moveq #1,d1
.check_auto
    bsr verify_equal
    dbf d7,.auto_gear

    ; Six fractional decays preserve each original retention to one word unit.
    ; These use the real assembly helpers, including their Q16 carries.
    lea sim_heading_decay_frac(pc),a0
    clr.l (a0)
    move.w #1024,-13390(a4)
    moveq #5,d7
.heading_decay
    bsr sim_heading_decay
    dbf d7,.heading_decay
    move.w -13390(a4),d0
    ext.l d0
    move.l #896,d1
    bsr verify_near
    lea sim_yaw_decay_frac(pc),a0
    clr.l (a0)
    move.w #-1024,-9862(a4)
    moveq #5,d7
.yaw_decay
    bsr sim_yaw_decay
    dbf d7,.yaw_decay
    move.w -9862(a4),d0
    ext.l d0
    move.l #-768,d1
    bsr verify_near
    lea sim_clutch_decay_frac(pc),a0
    clr.l (a0)
    move.w #4096,-13188(a4)
    moveq #5,d7
.clutch_decay
    bsr sim_clutch_decay
    dbf d7,.clutch_decay
    move.w -13188(a4),d0
    ext.l d0
    move.l #3840,d1
    bsr verify_near
    ; The coupled clutch decay + free rise is an affine map, not two rates.
    lea sim_clutch_decay_frac(pc),a0
    clr.l (a0)
    lea sim_clutch_rise_frac(pc),a0
    clr.l (a0)
    move.w #4096,-13188(a4)
    move.w #1,-13038(a4)
    moveq #5,d7
.clutch_map
    bsr sim_clutch_decay
    bsr sim_free_rpm
    dbf d7,.clutch_map
    moveq #0,d0
    move.w -13188(a4),d0
    move.l #4540,d1
    bsr verify_near

    ; Six constant-acceleration integrations reproduce the original Euler
    ; displacement, including the braking bias, rather than merely its speed.
    lea sim_distance_frac(pc),a0
    clr.w (a0)
    lea sim_tick_force(pc),a0
    move.l #60,(a0)
    move.l #6000,-13282(a4)
    clr.l -17238(a4)
    moveq #5,d7
.integrate_up
    add.l #60,-13282(a4)
    move.l -13282(a4),d0
    bsr sim_player_motion
    add.l d0,-17238(a4)
    dbf d7,.integrate_up
    move.l -17238(a4),d0
    moveq #99,d1             ; original (6000+360)/64
    bsr verify_equal
    lea sim_distance_frac(pc),a0
    clr.w (a0)
    lea sim_tick_force(pc),a0
    move.l #-60,(a0)
    clr.l -17238(a4)
    moveq #5,d7
.integrate_down
    sub.l #60,-13282(a4)
    move.l -13282(a4),d0
    bsr sim_player_motion
    add.l d0,-17238(a4)
    dbf d7,.integrate_down
    move.l -17238(a4),d0
    moveq #93,d1             ; original (6360-360)/64
    bsr verify_equal

    ; Gear commands retain the original six-field player-physics hold.
    move.l #12345,-17216(a4)
    bsr sim_gear_hold
    move.l sim_player_hold_until(pc),d0
    move.l #12351,d1
    bsr verify_equal
    moveq #0,d0
    move.w -13446(a4),d0
    moveq #0,d1
    bsr verify_equal
    moveq #0,d0
    move.w -12672(a4),d0
    moveq #7,d1
    bsr verify_equal

    ; Demo prediction is NOT integration: one call retains full speed/motion,
    ; while its lane output is a physical rate that still divides by six.
    lea -10478(a4),a5
    move.l #500000,2(a5)
    move.l #10001,10(a5)
    bsr sim_ai_motion
    move.l #510001,d1
    bsr verify_equal
    move.w #32768,22(a5)
    move.w #12000,d0
    bsr sim_ai_accel
    move.l #6000,d1
    bsr verify_equal
    move.l #10000,10(a5)
    bsr sim_ai_curve
    move.l 10(a5),d0
    move.l #8976,d1
    bsr verify_equal
    move.w #100,6(a5)
    moveq #5,d7
.demo_lane
    move.w 6(a5),d0
    moveq #7,d2
    bsr sim_ai_lane
    dbf d7,.demo_lane
    moveq #0,d0
    move.w 6(a5),d0
    move.l #107,d1
    bsr verify_equal

    ; Both shipping periods: sim_n calls sum exactly to each signed rate and
    ; leave no remainder (68000: one call; 68020+: three). Runs last, before
    ; _patchexe selects the actual period; earlier checks use the defaults.
    moveq #0,d5               ; AttnFlags: 68000 table
.period
    move.l d5,d0
    bsr sim_configure
    lea verify_rates(pc),a2
    moveq #11,d6
.period_rate
    lea sim_speed_frac(pc),a0
    clr.w (a0)
    moveq #0,d4
    move.w sim_n(pc),d7
    subq.w #1,d7
.period_call
    move.l (a2),d0
    bsr sim_scale_long
    add.l d0,d4
    dbf d7,.period_call
    move.l d4,d0
    move.l (a2)+,d1
    bsr verify_equal
    moveq #0,d0
    move.w (a0),d0
    moveq #0,d1
    bsr verify_equal
    dbf d6,.period_rate
    addq.w #2,d5              ; AFF_68020
    cmp.w #4,d5
    bne.b .period

    bsr verify_render_units
    bsr verify_render_seed
    bsr verify_render_tangent

    move.l a4,a1
    suba.l #32766,a1
    move.l #32768,d0
    move.l $4.w,a6
    jsr -210(a6)
.done
    movem.l (sp)+,d0-a6
    rts
verify_equal:
    move.l a0,-(sp)
    lea verify_unit_results(pc),a0
    addq.l #1,4(a0)
    cmp.l d1,d0
    beq.b .equal
    addq.l #1,(a0)
    tst.l 8(a0)
    bne.b .equal
    move.l 4(a0),8(a0)       ; first failing case, for read-only diagnosis
.equal
    movem.l (sp)+,a0
    rts
verify_near:
    sub.l d1,d0
    bpl.b .positive
    neg.l d0
.positive
    cmp.l #1,d0
    sls d0
    and.l #1,d0
    moveq #1,d1
    bra verify_equal
verify_rates:
    dc.l 0,1,-1,5,-5,6,-6,32767,-32768,123456789,$7fffffff,$80000000
verify_changing:
    dc.l 1,-2,3,-4,5,-6
    dc.b "TD2RATECHECK",0
    even
verify_unit_results:
    dc.l 0,0,0
