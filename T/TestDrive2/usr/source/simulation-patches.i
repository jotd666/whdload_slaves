    ; Enhanced framerate: fixed-period simulation, duel v1 only. Off restores the original game.
    PL_IFC2
    PL_PS  $05a4c,sim_start
    PL_PSS $05a5a,sim_begin,2
    PL_L   $05bea,$70014e71    ; deadline comparison: moveq #1,d0; nop
    PL_L   $05c0c,$70014e71    ; deadline advance: moveq #1,d0; nop
    PL_PS  $0b29e,sim_player_motion ; original speed /64, then /6 with carry
    PL_PS  $0a88a,sim_throttle_curve
    PL_PS  $0a8ca,sim_drag_curve
    PL_PSS $0a8e6,sim_speed_add,2
    PL_PS  $0a7e0,sim_clutch_decay
    PL_PSS $0a7f6,sim_clutch_brake,2
    PL_PSS $0a800,sim_assisted_clutch,2
    PL_PSS $0a828,sim_neutral_drag,2
    PL_PS  $0a836,sim_free_rpm
    PL_PSS $0a852,sim_fuel_drag,2
    PL_PSS $0a866,sim_brake,2
    PL_PSS $0a870,sim_assisted_brake,2
    PL_PSS $0a90e,sim_scrub,2
    PL_PS  $0b0e4,sim_heading_decay
    PL_PS  $0b0ee,sim_yaw_decay
    PL_PSS $0b1a2,sim_yaw_add,2
    PL_PS  $0b2d4,sim_centre_limit
    PL_PS  $0b2fa,sim_return_limit
    PL_PS  $0aee0,sim_heat_cool
    PL_PSS $0aeee,sim_heat_add,2
    PL_PSS $0aec6,sim_controller_hold,4
    PL_PSS $0ae3a,sim_gear_hold,4
    PL_PSS $0ae90,sim_gear_hold,4
    PL_PSS $0af2e,sim_auto_gear,2
    PL_PSS $05bd4,sim_gear_update,2
    PL_PS  $0adf8,sim_dashboard
    PL_P   $0d6ae,sim_ai_begin
    PL_PSS $0dd52,sim_ai_accel,2
    PL_PSS $0dcd4,sim_ai_stop,2
    PL_PS  $0dd16,sim_ai_pursuit
    PL_PS  $0dd2e,sim_ai_brake
    PL_PSS $0de2e,sim_ai_curve,2
    PL_PSS $0de36,sim_ai_motion,2
    PL_PS  $0ddce,sim_ai_lane
    PL_PS  $0e080,sim_ai_lane
    PL_PSS $0def2,sim_police_brake,2
    PL_PSS $0df2e,sim_police_accel,2
    PL_PS  $0df54,sim_police_return_lane
    PL_PSS $0e0f2,sim_traffic_forward,2
    PL_PSS $0e1b0,sim_traffic_oncoming,2
    PL_PSS $0d77a,sim_crash_timer,4
    PL_PSS $0df16,sim_police_timer,4
    PL_PSS $0df36,sim_police_time_motion,6
    PL_PSS $0e016,sim_police_time_read,2
    PL_PS  $0e062,sim_police_limit_branch
    PL_PS  $0e06e,sim_police_limit
    PL_PSS $0d216,sim_gear_timer,4
    PL_PS  $08bee,sim_verge_low
    PL_PS  $08bfa,sim_verge_high
    PL_PS  $08c30,sim_verge_low
    PL_PS  $08c3c,sim_verge_high
    PL_PS  $091b8,sim_effect_phase
    ; Release builds keep the original crash/lives screens, acknowledgement
    ; and restart path. Automatic recovery is an opt-in test instrument only.
    IFD VERIFY
    PL_IFC1X 1
    PL_PS  $05c74,sim_overheat_check
    PL_PS  $05c80,sim_crash_check
    PL_PS  $06510,sim_dashboard_draw
    PL_ENDIF
    ENDC
    PL_PSS $05b8c,sim_player_time,2
    PL_PS  $05bc0,sim_opponent_sum
    PL_NOP $05bc6,4            ; advance opponent time at shared entry below
    PL_PS  $05bca,sim_opponent_time
    PL_NOP $08cd0,32           ; phase accumulation now in simulation
    PL_P   $08d94,sim_draw_event
    PL_W   $0e9f0,$7200        ; gameplay RNG excludes beam-position entropy
    PL_NOP $0e9f2,4
    IFD VERIFY
    PL_ELSE
    PL_IFC5X 0
    PL_PS  $05a4c,sim_start
    PL_PSS $05a5a,verify_original_begin,2
    PL_ENDIF
    ENDC
    PL_ENDIF
