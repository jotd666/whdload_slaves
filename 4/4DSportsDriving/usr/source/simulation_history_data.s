; Runtime checkpoint pointer and optional diagnostic data.
 even
 dc.b "4DHISTRY"
 dc.w 9,SIM_HISTORY_SLOTS,SIM_HISTORY_BYTES,0
sim_history_saves: dc.l 0
sim_history_restores: dc.l 0
sim_history_rotations: dc.l 0
sim_history_records: dc.l 0 ; runtime workspace pointer
