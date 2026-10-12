; All h4 gameplay changes are conditional. Ranges include displaced tails.
    PL_IFC2
    ; SIM_RANGE h4 00b68 8 C2 render_latch
    PL_PSS $00b68,render_latch,2
    ; SIM_RANGE h4 00042 8 C2 sim_period
    PL_PSS $00042,sim_period,2
    ; SIM_RANGE h4 000e6 6 C2 sim_reset
    PL_PS $000e6,sim_reset
    ; SIM_RANGE h4 0012a 6 C2 sim_begin
    PL_PS $0012a,sim_begin
    ; SIM_RANGE h4 00152 8 C2 sim_count
    PL_PSS $00152,sim_count,2
    ; SIM_RANGE h4 00198 8 C2 sim_shifter
    PL_PSS $00198,sim_shifter,2
    ; SIM_RANGE h4 00476 16 C2 nop
    PL_NOP $00476,16          ; clutch no longer waits for drawn lever buffers
    ; SIM_RANGE h4 03f34 12 C2 sim_rpm_decay
    PL_PSS $03f34,sim_rpm_decay,6
    ; SIM_RANGE h4 03f46 8 C2 sim_brake
    PL_PSS $03f46,sim_brake,2
    ; SIM_RANGE h4 03f5e 8 C2 sim_neutral_drag
    PL_PSS $03f5e,sim_neutral_drag,2
    ; SIM_RANGE h4 03f6c 6 C2 sim_free_rpm
    PL_PS $03f6c,sim_free_rpm
    ; SIM_RANGE h4 03f80 8 C2 sim_brake
    PL_PSS $03f80,sim_brake,2
    ; SIM_RANGE h4 03fde 8 C2 sim_speed_add
    PL_PSS $03fde,sim_speed_add,2
    ; SIM_RANGE h4 03ff2 6 C2 sim_player_motion
    PL_PS $03ff2,sim_player_motion
    ; SIM_RANGE h4 08172 8 C2 sim_scrub
    PL_PSS $08172,sim_scrub,2
    ; SIM_RANGE h4 01240 4 C2 current_x
    PL_L $01240,$946ca898     ; wall collision consumes current simulation x
    ; SIM_RANGE h4 0127a 4 C2 current_x
    PL_L $0127a,$946ca898
    ; SIM_RANGE h4 01cfa 12 C2 nop
    PL_NOP $01cfa,12          ; widths now come from simulation road descriptors
    ; SIM_RANGE h4 0180e 4 C2 nop
    PL_NOP $0180e,4           ; police lane return is no longer per draw
    ; SIM_RANGE h4 0181e 4 C2 nop
    PL_NOP $0181e,4
    ; SIM_RANGE h4 0182e 4 C2 nop
    PL_NOP $0182e,4           ; other traffic lane return is no longer per draw
    ; SIM_RANGE h4 0183e 4 C2 nop
    PL_NOP $0183e,4
    ; SIM_RANGE h4 0184c 4 C2 nop
    PL_NOP $0184c,4           ; keep visual projection; remove collision-origin write
    ; SIM_RANGE h4 018ec 4 C2 nop
    PL_NOP $018ec,4
    ; SIM_RANGE h4 01506 8 C2 sim_traffic_forward
    PL_PSS $01506,sim_traffic_forward,2
    ; SIM_RANGE h4 01624 8 C2 sim_police_accel
    PL_PSS $01624,sim_police_accel,2
    ; SIM_RANGE h4 01648 8 C2 sim_police_seen
    PL_PSS $01648,sim_police_seen,2
    ; SIM_RANGE h4 01662 10 C2 sim_police_clock
    PL_PSS $01662,sim_police_clock,4
    ; SIM_RANGE h4 0168c 8 C2 sim_police_brake
    PL_PSS $0168c,sim_police_brake,2
    ; SIM_RANGE h4 016a4 6 C2 sim_police_stop
    PL_PS $016a4,sim_police_stop
    ; SIM_RANGE h4 016d2 6 C2 sim_police_follow
    PL_PS $016d2,sim_police_follow
    ; SIM_RANGE h4 016ea 8 C2 sim_traffic_oncoming
    PL_PSS $016ea,sim_traffic_oncoming,2
    ; SIM_RANGE h4 08008 6 C2 sim_lane_centre
    PL_PS $08008,sim_lane_centre
    ; SIM_RANGE h4 0808e 12 C2 sim_steer_limits
    PL_PSS $0808e,sim_steer_limits,6
    ; SIM_RANGE h4 080d0 8 C2 sim_edge_rate
    PL_PSS $080d0,sim_edge_rate,2
    ; SIM_RANGE h4 0431e 10 C2 sim_gear_hold
    PL_PSS $0431e,sim_gear_hold,4
    ; SIM_RANGE h4 043c2 10 C2 sim_rev_counter
    PL_PSS $043c2,sim_rev_counter,4
    ; SIM_RANGE h4 043e4 6 C2 sim_station_gear
    PL_PS $043e4,sim_station_gear
    ; SIM_RANGE h4 043fa 8 C2 sim_auto_gear
    PL_PSS $043fa,sim_auto_gear,2
    ; SIM_RANGE h4 03f9a 6 C2 sim_torque_curve
    PL_PS $03f9a,sim_torque_curve
    ; SIM_RANGE h4 03fc2 6 C2 sim_drag_curve
    PL_PS $03fc2,sim_drag_curve
    ; SIM_RANGE h4 01eee 8 C2 sim_visual_1023
    PL_PSS $01eee,sim_visual_1023,2
    ; SIM_RANGE h4 01f00 8 C2 sim_visual_255
    PL_PSS $01f00,sim_visual_255,2
    ; SIM_RANGE h4 01f10 8 C2 sim_visual_127
    PL_PSS $01f10,sim_visual_127,2
    ; SIM_RANGE h4 01f76 8 C2 sim_visual_3
    PL_PSS $01f76,sim_visual_3,2
    ; SIM_RANGE h4 01e64 24 C2 nop
    PL_NOP $01e64,24          ; background phases advance in simulation
    ; SIM_RANGE h4 01edc 8 C2 sim_windscreen_draw
    PL_PSS $01edc,sim_windscreen_draw,2
    ; SIM_RANGE h4 01f4c 12 C2 sim_windscreen_draw_next
    PL_PSS $01f4c,sim_windscreen_draw_next,6
    ; SIM_RANGE h4 03d46 4 C2 nop
    PL_NOP $03d46,4           ; police lamp phase no longer counts draws
    ; SIM_RANGE h4 01e20 8 C2 sim_draw_verge
    PL_PSS $01e20,sim_draw_verge,2
    ; SIM_RANGE h4 07fb2 8 C2 sim_steer_grip
    PL_PSS $07fb2,sim_steer_grip,2
    ; SIM_RANGE h4 07f94 6 C2 sim_visual_edge_capture
    PL_PS $07f94,sim_visual_edge_capture
    ; SIM_RANGE h4 07fd6 6 C2 sim_bank_pose
    PL_PS $07fd6,sim_bank_pose
    PL_ENDIF
