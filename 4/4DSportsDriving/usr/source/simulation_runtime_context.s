; Runtime game context.
; sim_game is filled before patch installation; sim_ready permits live polling.
 even
 dc.b "4DSIMRUN"
 dc.w 1,8
sim_game: dc.l 0
sim_ready: dc.l 1
; Error code for runtime safety checks.
perf_failure: dc.l 0
