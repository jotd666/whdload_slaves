 IFND SIM_REPLAY_FILE_TICK
SIM_REPLAY_FILE_TICK = 155
 ENDC
; Consumer-side acceptance only. Real race -> serialized packet -> isolated
; output buffers. It never installs decoded state into the running game.
sim_replay_file_fixture:
 cmp.w #50,-$15fa(a4)
 bne .return
 tst.b $45(a4)
 bne .return
 tst.b -$16d8(a4)
 bne .return
 cmp.w #SIM_REPLAY_FILE_TICK,-$940(a4)
 bne .return
 movem.l d0-a6,-(sp)
 lea sim_replay_file_fixture(pc),a6
 adda.l #sim_replay_test_marker-sim_replay_file_fixture,a6
 tst.l 12(a6)
 bne .out
 lea sim_replay_file_fixture(pc),a5
 adda.l #sim_replay_test_file-sim_replay_file_fixture,a5
 movea.l a5,a0
 bsr sim_replay_pack
 tst.l d0
 bne .failed
 addq.l #1,12(a6)
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_validate
 cmp.w #50,d0
 bne .failed
 addq.l #1,12(a6)
 ; Decode into a contiguous body arena plus a separate epoch cell.
 lea sim_replay_file_fixture(pc),a3
 adda.l #sim_replay_test_out-sim_replay_file_fixture,a3
 lea 16(a6),a1
 move.l a3,(a1)
 lea SIM_REPLAY_PREFIX(a3),a2
 move.l a2,4(a1)
 adda.l #SIM_REPLAY_INPUTS,a2
 move.l a2,8(a1)
 adda.l #SIM_REPLAY_NATIVE,a2
 move.l a2,12(a1)
 adda.l #SIM_REPLAY_COMPANIONS,a2
 move.l a2,16(a1)
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_unpack
 tst.l d0
 bne .failed
 lea SIM_REPLAY_HEADER(a5),a0
 movea.l a3,a1
 move.w #(SIM_REPLAY_CRC_OFFSET-SIM_REPLAY_HEADER)/4-1,d0
.compare:
 move.l (a0)+,d1
 cmp.l (a1)+,d1
 bne .failed
 dbra d0,.compare
 move.l 32(a5),d1
 cmp.l (a1),d1
 bne .failed
 addq.l #1,12(a6)
 ; Rejection must leave every output byte unchanged.
 movea.l a3,a1
 move.w #(SIM_REPLAY_CRC_OFFSET-SIM_REPLAY_HEADER+4)/4-1,d0
.poison:
 move.l #$a55a6996,(a1)+
 dbra d0,.poison
 movea.l a5,a0
 eor.b #1,100(a0)        ; payload corruption, still valid structural header
 lea 16(a6),a1
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_unpack
 cmp.w #1,d0
 bne .failed
 eor.b #1,100(a5)
 movea.l a3,a1
 move.w #(SIM_REPLAY_CRC_OFFSET-SIM_REPLAY_HEADER+4)/4-1,d0
.unchanged:
 cmp.l #$a55a6996,(a1)+
 bne .failed
 dbra d0,.unchanged
 addq.l #1,12(a6)
 ; Exact-size and format/physics-version gates, then checkpoint identity.
 lea sim_replay_test_lengths(pc),a2
 moveq #3,d7
.lengths:
 movea.l a5,a0
 move.l (a2)+,d0
 bsr sim_replay_validate
 tst.l d0
 bne .failed
 addq.l #1,12(a6)
 dbra d7,.lengths
 lea sim_replay_test_offsets(pc),a2
 moveq #8,d7
.fields:
 moveq #0,d1
 move.w (a2)+,d1
 movea.l a5,a1
 adda.l d1,a1
 eor.b #1,(a1)
 bsr sim_replay_test_checksum
 movea.l a5,a0
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_validate
 tst.l d0
 bne .failed
 eor.b #1,(a1)
 bsr sim_replay_test_checksum
 addq.l #1,12(a6)
 dbra d7,.fields
 ; Native mode/count/size boundaries use the isolated output arena.
 lea sim_replay_test_native_cases(pc),a2
 moveq #9,d7
.native:
 movea.l a3,a0
 move.b (a2)+,22(a0)
 moveq #0,d6
 move.b (a2)+,d6
 move.w (a2)+,24(a0)
 move.l (a2)+,d0
 bsr sim_replay_validate
 cmp.l d6,d0
 bne .failed
 addq.l #1,12(a6)
 dbra d7,.native
 ; Return the valid golden packet and recheck it after destructive tests.
 movea.l a5,a0
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_validate
 cmp.w #50,d0
 bne .failed
 addq.l #1,12(a6)
 IFD SIM_REPLAY_IO_TEST
 bsr sim_replay_io_fixture
 ENDC
 bra .out
.failed:
 lea sim_replay_file_fixture(pc),a0
 adda.l #perf_failure-sim_replay_file_fixture,a0
 move.l #30,(a0)
 illegal
 bra .failed
.out:
 movem.l (sp)+,d0-a6
.return:
 rts
; Recompute the checksum so structural rejection cannot pass by CRC alone.
sim_replay_test_checksum:
 movem.l d0/a0-a1,-(sp)
 movea.l a5,a0
 move.l #SIM_REPLAY_CRC_OFFSET,d0
 bsr sim_replay_crc
 movea.l a5,a1
 adda.l #SIM_REPLAY_CRC_OFFSET,a1
 move.l d0,(a1)
 movem.l (sp)+,d0/a0-a1
 rts
sim_replay_test_lengths:
 dc.l 0,SIM_REPLAY_PREFIX-1,SIM_REPLAY_BYTES-1,SIM_REPLAY_BYTES+1
sim_replay_test_offsets:
 dc.w 9,11,13,15,23,SIM_REPLAY_HEADER+22,35
 dc.w SIM_REPLAY_NATIVE_OFFSET+$141,SIM_REPLAY_COMPANION_OFFSET+1
sim_replay_test_native_cases:
 dc.b 10,10
 dc.w 0
 dc.l SIM_REPLAY_PREFIX
 dc.b 10,10
 dc.w 6000
 dc.l SIM_REPLAY_PREFIX+6000
 dc.b 20,20
 dc.w 12000
 dc.l SIM_REPLAY_PREFIX+12000
 dc.b 20,20
 dc.w 2977
 dc.l 4805
 dc.b 10,0
 dc.w 6001
 dc.l SIM_REPLAY_PREFIX+6001
 dc.b 20,0
 dc.w 12001
 dc.l SIM_REPLAY_PREFIX+12001
 dc.b 50,0
 dc.w 100
 dc.l SIM_REPLAY_PREFIX+100
 dc.b 0,0
 dc.w 100
 dc.l SIM_REPLAY_PREFIX+100
 dc.b 20,0
 dc.w 100
 dc.l SIM_REPLAY_PREFIX+99
 dc.b 20,0
 dc.w 100
 dc.l SIM_REPLAY_PREFIX+101
