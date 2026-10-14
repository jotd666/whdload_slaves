; Actual DOS reads/writes, plus injected Open/Write/Read failures.
; Requires a disposable GAME drawer containing the negative read fixtures.
sim_replay_io_fixture:
 movem.l d0-a6,-(sp)
 lea sim_replay_io_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_replay_io_fixture,a0
 move.w (a0),-(sp)
 move.w #1,(a0)
 movea.l $bda(a4),a6
 lea sim_replay_io_fixture(pc),a5
 adda.l #sim_replay_io_marker-sim_replay_io_fixture,a5
 lea sim_replay_io_fixture(pc),a4
 adda.l #sim_replay_test_file-sim_replay_io_fixture,a4
 lea sim_replay_io_fixture(pc),a3
 adda.l #sim_replay_io_buffer-sim_replay_io_fixture,a3
 lea sim_replay_io_fixture(pc),a2
 adda.l #sim_replay_io_readback-sim_replay_io_fixture,a2
 lea sim_replay_io_tag_name(pc),a0
 movea.l a4,a1
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_file_write
 tst.l d0
 bne .failed
 addq.l #1,12(a5)
 ; Invalid replacement must fail before Open and leave the old file intact.
 eor.b #1,9(a4)
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_file_write
 cmp.w #1,d0
 bne .failed
 eor.b #1,9(a4)
 addq.l #1,12(a5)
 movea.l a3,a1
 bsr sim_replay_file_read
 tst.l d0
 bne .failed
 cmp.w #50,d1
 bne .failed
 cmp.l #SIM_REPLAY_BYTES,d2
 bne .failed
 movea.l a3,a0
 movea.l a4,a1
 move.w #SIM_REPLAY_BYTES/4-1,d0
.compare:
 move.l (a0)+,d1
 cmp.l (a1)+,d1
 bne .failed
 dbra d0,.compare
 addq.l #1,12(a5)
 ; KickEmu aborts on nonexistent save directories instead of returning an
 ; Open error. Inject that failure, plus short Write and failed readback.
 movem.l a6,-(sp)
 lea sim_replay_io_fail_base(pc),a6
 moveq #0,d7
.failures:
 lea sim_replay_io_fail_mode(pc),a0
 move.w d7,(a0)
 lea sim_replay_io_tag_name(pc),a0
 movea.l a4,a1
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_file_write
 move.l d7,d1
 addq.l #2,d1
 cmp.l d1,d0
 bne .failed
 addq.l #1,12(a5)
 addq.w #1,d7
 cmp.w #3,d7
 blo .failures
 movem.l (sp)+,a6
 ; Native original and negative files, with exact result contract checks.
 lea sim_replay_io_cases(pc),a4
 moveq #4,d7
.reads:
 movea.l a4,a0
 adda.w (a4),a0
 movea.l a3,a1
 bsr sim_replay_file_read
 cmp.w 2(a4),d0
 bne .failed
 cmp.w 4(a4),d1
 bne .failed
 cmp.l 6(a4),d2
 bne .failed
 addq.l #1,12(a5)
 adda.w #10,a4
 dbra d7,.reads
 ; Round-trip the actual shipped A2500 replay without modifying its format.
 lea sim_replay_io_default(pc),a0
 movea.l a3,a1
 bsr sim_replay_file_read
 tst.l d0
 bne .failed
 lea sim_replay_io_native_name(pc),a0
 move.l d2,d0
 bsr sim_replay_file_write
 tst.l d0
 bne .failed
 addq.l #1,12(a5)
 lea sim_replay_io_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_replay_io_fixture,a0
 move.w (sp)+,(a0)
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea sim_replay_io_fixture(pc),a0
 adda.l #perf_failure-sim_replay_io_fixture,a0
 move.l #31,(a0)
 illegal
 bra .failed
sim_replay_io_cases:
 dc.w sim_replay_io_default-*,0,20
 dc.l 4805
 dc.w sim_replay_io_missing-*,1,0
 dc.l 0
 dc.w sim_replay_io_short-*,2,0
 dc.l 0
 dc.w sim_replay_io_oversize-*,2,0
 dc.l 0
 dc.w sim_replay_io_corrupt-*,2,0
 dc.l 0
sim_replay_io_tag_name: dc.b "A4000-io-test.rpl",0
sim_replay_io_native_name: dc.b "A2500-io-test.rpl",0
sim_replay_io_default: dc.b "DEFAULT.rpl",0
sim_replay_io_missing: dc.b "absent-replay-test.rpl",0
sim_replay_io_short: dc.b "replay-short.test",0
sim_replay_io_oversize: dc.b "replay-oversize.test",0
sim_replay_io_corrupt: dc.b "replay-corrupt.test",0
 even

; DOS LVO slots -48 Write,-42 Read,-36 Close,-30 Open.
sim_replay_io_fail_vectors:
 bra.w sim_replay_io_fail_write
 nop
 bra.w sim_replay_io_fail_read
 nop
 bra.w sim_replay_io_fail_close
 nop
 bra.w sim_replay_io_fail_open
 nop
 dcb.b 24,0
sim_replay_io_fail_base: dc.l 0
sim_replay_io_fail_mode: dc.w 0
sim_replay_io_fail_open:
 moveq #0,d0
 move.w sim_replay_io_fail_mode(pc),d0
 beq .out
 moveq #1,d0
.out:
 rts
sim_replay_io_fail_write:
 move.w sim_replay_io_fail_mode(pc),d0
 cmp.w #1,d0
 bne .full
 moveq #0,d0
 rts
.full:
 move.l d3,d0
 rts
sim_replay_io_fail_read:
 moveq #-1,d0
 rts
sim_replay_io_fail_close:
 moveq #-1,d0             ; undefined Close result must not replace I/O result
 rts
