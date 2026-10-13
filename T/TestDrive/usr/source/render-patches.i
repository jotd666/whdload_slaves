; Installed only for C2, after simulation hooks. VERIFY C1 bit 4 disables
; this entire list for a same-build comparison without changing simulation.
    ; RENDER_RANGE h4 0113e 8 C2R render_lateral_main
    PL_PSS $0113e,render_lateral_main,2
    ; RENDER_RANGE h4 011c8 26 C2R render_lateral_mirror
    PL_PSS $011c8,render_lateral_mirror,20
    ; RENDER_RANGE h4 07e4e 6 C2R render_sine_width
    PL_PS $07e4e,render_sine_width
    ; RENDER_RANGE h4 07e62 6 C2R render_sine_width
    PL_PS $07e62,render_sine_width
    ; RENDER_RANGE h4 07e86 6 C2R render_lateral_rear_step
    PL_P $07e86,render_lateral_rear_step
    ; RENDER_RANGE h4 07e98 6 C2R render_lateral_forward_step
    PL_P $07e98,render_lateral_forward_step
    ; RENDER_RANGE h4 01a38 8 C2R render_row
    PL_PSS $01a38,render_row,2
    ; RENDER_RANGE h4 03b42 10 C2R render_queue
    PL_PSS $03b42,render_queue,4
    ; RENDER_RANGE h4 01b54 6 C2R render_finish
    PL_P $01b54,render_finish
    ; RENDER_RANGE h4 014c8 6 C2R render_slope_add
    PL_P $014c8,render_slope_add
    ; RENDER_RANGE h4 01490 6 C2R render_height_fraction
    PL_P $01490,render_height_fraction
    ; RENDER_RANGE h4 01ea0 8 C2R render_backdrop
    PL_PSS $01ea0,render_backdrop,2
    ; RENDER_RANGE h4 01a1c 8 C2R render_walk_start
    PL_PSS $01a1c,render_walk_start,2
    ; RENDER_RANGE h4 0117e 6 C2R render_main_fraction
    PL_PS $0117e,render_main_fraction
    ; RENDER_RANGE h4 01496 6 C2R render_slope_begin
    PL_P $01496,render_slope_begin
    ; RENDER_RANGE h4 07eaa 6 C2R render_curve_seed
    PL_P $07eaa,render_curve_seed
