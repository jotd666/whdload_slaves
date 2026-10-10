; Keep expanded checkpoint data after code to preserve relative branch reach.
 even
 dc.b "4DHISTRY"
 dc.w 5,SIM_HISTORY_SLOTS,SIM_HISTORY_BYTES,0
sim_history_saves: dc.l 0
sim_history_restores: dc.l 0
sim_history_rotations: dc.l 0
sim_history_records: dcb.b SIM_HISTORY_SLOTS*SIM_HISTORY_BYTES,0
 dc.b "4DHISTST"
 dc.w 5,40
sim_history_passed: dc.l 0
sim_history_test_private: dcb.b SIM_PRIVATE_BYTES,0
sim_history_test_rng: dcb.b 6,0

