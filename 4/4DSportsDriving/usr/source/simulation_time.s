; Wide time display ABI for elapsed and completed-result call sites. D0 carries the
; full tick sum across native argument pushes; existing stack args stay intact.
; Other callers retain the native word ABI until their storage is widened.

sim_time_sum_consumer:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2e0(a4),d0
 add.w -$940(a4),d0
 rts
.wide:
 movem.l d1,-(sp)
 moveq #0,d0
 move.w -$2e0(a4),d0
 moveq #0,d1
 move.w -$940(a4),d1
 add.l d1,d0
 movem.l (sp)+,d1
 rts

sim_time_sum_recorded:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2e0(a4),d0
 add.w -$1738(a4),d0
 rts
.wide:
 IFD SIM_TIME_DISPLAY_TEST
 movem.l d2-d3,-(sp)
 move.w -$2e0(a4),d2
 move.w -$1738(a4),d3
 cmp.w #160,-$940(a4)
 blo .ordinary
 move.w #45000,-$2e0(a4)
 move.w #30000,-$1738(a4)
.ordinary:
 ENDC
 movem.l d1,-(sp)
 moveq #0,d0
 move.w -$2e0(a4),d0
 moveq #0,d1
 move.w -$1738(a4),d1
 add.l d1,d0
 movem.l (sp)+,d1
 IFD SIM_TIME_DISPLAY_TEST
 move.w d2,-$2e0(a4)
 move.w d3,-$1738(a4)
 movem.l (sp)+,d2-d3
 ENDC
 rts

sim_time_sum_seek:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2e0(a4),d0
 add.w 12(a5),d0
 rts
.wide:
 movem.l d1,-(sp)
 moveq #0,d0
 move.w -$2e0(a4),d0
 moveq #0,d1
 move.w 12(a5),d1
 add.l d1,d0
 movem.l (sp)+,d1
 rts

sim_time_sum_producer:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2e0(a4),d0
 add.w $a0(a4),d0
 rts
.wide:
 IFD SIM_TIME_DISPLAY_TEST
 movem.l d2-d3,-(sp)
 move.w -$2e0(a4),d2
 move.w $a0(a4),d3
 cmp.w #160,-$940(a4)
 blo .ordinary
 move.w #45000,-$2e0(a4)
 move.w #30000,$a0(a4)
.ordinary:
 ENDC
 movem.l d1,-(sp)
 moveq #0,d0
 move.w -$2e0(a4),d0
 moveq #0,d1
 move.w $a0(a4),d1
 add.l d1,d0
 movem.l (sp)+,d1
 IFD SIM_TIME_DISPLAY_TEST
 move.w d2,-$2e0(a4)
 move.w d3,$a0(a4)
 movem.l (sp)+,d2-d3
 ENDC
 rts

; The replay display cache uses $ffff as invalid. Map the full elapsed tick
; modulo65535 so tick65535 cannot collide with that sentinel. A replay window
; spans at most30000 ticks, so the key stays unique within the current window.
; Native window initialization invalidates the cache when loading another race.
sim_time_cache_key:
 cmp.w #50,-$15fa(a4)
 beq .wide
 move.w -$2e0(a4),d0
 add.w 12(a5),d0
 rts
.wide:
 movem.l d1,-(sp)
 moveq #0,d0
 move.w -$2e0(a4),d0
 moveq #0,d1
 move.w 12(a5),d1
 add.l d1,d0
 movem.l (sp)+,d1
sim_time_cache_reduce:
 cmp.l #65535,d0
 blo .done
 sub.l #65535,d0
.done:
 rts

; JMP entry hook: original return/destination/ticks/show-fractions stack ABI.
; Only the four elapsed-time callers promise a full unsigned D0 tick argument.
; Results and record callers retain their native word stack arguments.
sim_time_format_entry:
 movem.l d0-d3/a0,-(sp)
 moveq #0,d2
 addx.w d2,d2
 move.w d2,-(sp)
 move.l 22(sp),d1
 lea sim_time_format_entry(pc),a0
 adda.l #tape_game-sim_time_format_entry,a0
 sub.l (a0),d1
 ; The record row formatter temporarily forces 20 Hz, in every physics mode.
 cmp.l #$3dbe,d1
 beq .score
 cmp.l #$3dd0,d1
 beq .score
 cmp.w #50,-$15fa(a4)
 bne .native
 cmp.l #$7720,d1
 beq .wide
 cmp.l #$9308,d1
 beq .wide
 cmp.l #$937e,d1
 beq .wide
 cmp.l #$20f08,d1
 beq .wide
 ; These native callers still push low words. Their source is the completed
 ; summary, whose lifetime is independent of live replay restoration.
 cmp.l #$56b8,d1
 beq .player
 cmp.l #$5752,d1
 beq .penalty
 cmp.l #$587a,d1
 beq .opponent
 cmp.l #$58ba,d1
 bne .native
 bra .opponent
.score:
 move.w 8(a5),d0            ; still the caller's native row frame
 bsr sim_score_row_time
 move.l 26(sp),a0
 move.w 32(sp),d1
 bsr sim_score_format100
 bra .restore
.opponent:
 lea sim_results_summary(pc),a0
 move.l 8(a0),d0
 bra .format
.player:
 lea sim_results_summary(pc),a0
 move.l 4(a0),d0
 sub.l (a0),d0             ; driving time without penalties, as native caller
 bra .format
.penalty:
 lea sim_results_summary(pc),a0
 move.l (a0),d0
 bra .format
.wide:
 move.l 2(sp),d0
.format:
 move.l 26(sp),a0
 move.w 32(sp),d1
 bsr sim_time_format50
.restore:
 move.w (sp)+,d2
 lsr.w #1,d2
 movem.l (sp)+,d0-d3/a0
 rts
.native:
 move.w (sp)+,d2
 lsr.w #1,d2
 movem.l (sp)+,d0-d3/a0
 link a5,#-24
 move.w -$15fa(a4),d0
 ; Execute the rest of the original formatter without borrowing a register.
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_time_format_entry(pc),a0
 adda.l #tape_game-sim_time_format_entry,a0
 move.l (a0),a0
 adda.l #$1a476,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts

; D0 unsigned 32-bit ticks at 50 Hz, D1 fractions flag, A0 destination.
; Up to 14 bytes including NUL for the complete unsigned range. The elapsed
; callers remain <=75000 ticks (9 bytes); result callers use the large native
; temporary string at -$5B(a5). Scratch D0-D3/A0.
sim_time_format50:
 move.w d1,d3
 move.w #3000,d2
 bsr .divide
 bsr .minutes
 move.b #':',(a0)+
 move.l d1,d0
 divu #50,d0
 move.l d0,d1
 swap d1
 and.l #$ffff,d1
 and.l #$ffff,d0
 bsr .pair
 tst.w d3
 beq .end
 move.b #'.',(a0)+
 move.l d1,d0
 add.l d0,d0
 bsr .pair
.end:
 clr.b (a0)
 rts

; Unsigned long / unsigned word without the 68000 DIVU quotient overflow.
; D0 quotient, D1 remainder, D2 scratch. Both partial quotients fit a word.
.divide:
 move.l d0,-(sp)
 clr.w d0
 swap d0
 divu d2,d0
 move.w d0,-(sp)
 move.w 4(sp),d0
 divu d2,d0
 move.l d0,d1
 swap d1
 and.l #$ffff,d1
 and.l #$ffff,d0
 move.w (sp)+,d2
 swap d2
 clr.w d2
 or.l d2,d0
 addq.l #4,sp
 rts
.minutes:
 cmp.l #100,d0
 bhs .many
 bsr .pair
 cmp.b #'0',-2(a0)
 bne .minutes_done
 move.b #' ',-2(a0)
.minutes_done:
 rts
.many:
 movem.l d1/d3,-(sp)
 moveq #0,d3
.digits:
 moveq #10,d2
 bsr .divide
 add.w #'0',d1
 move.w d1,-(sp)
 addq.w #1,d3
 tst.l d0
 bne .digits
.emit:
 move.w (sp)+,d2
 move.b d2,(a0)+
 subq.w #1,d3
 bne .emit
 movem.l (sp)+,d1/d3
 rts
.pair:
 divu #10,d0
 move.w d0,d2
 add.b #'0',d2
 move.b d2,(a0)+
 swap d0
 add.b #'0',d0
 move.b d0,(a0)+
 rts

 even
 dc.b "4DTIMET!"
 dc.w 3,37
sim_time_passed: dc.l 0
sim_time_test_buffer: dcb.b 16,0
sim_time_cases:
 dc.l 0
 dc.w 0
 dc.b " 0:00",0
 even
 dc.l 0
 dc.w 1
 dc.b " 0:00.00",0
 even
 dc.l 1
 dc.w 0
 dc.b " 0:00",0
 even
 dc.l 1
 dc.w 1
 dc.b " 0:00.02",0
 even
 dc.l 49
 dc.w 0
 dc.b " 0:00",0
 even
 dc.l 49
 dc.w 1
 dc.b " 0:00.98",0
 even
 dc.l 50
 dc.w 0
 dc.b " 0:01",0
 even
 dc.l 50
 dc.w 1
 dc.b " 0:01.00",0
 even
 dc.l 2999
 dc.w 0
 dc.b " 0:59",0
 even
 dc.l 2999
 dc.w 1
 dc.b " 0:59.98",0
 even
 dc.l 3000
 dc.w 0
 dc.b " 1:00",0
 even
 dc.l 3000
 dc.w 1
 dc.b " 1:00.00",0
 even
 dc.l 32767
 dc.w 0
 dc.b "10:55",0
 even
 dc.l 32767
 dc.w 1
 dc.b "10:55.34",0
 even
 dc.l 32768
 dc.w 0
 dc.b "10:55",0
 even
 dc.l 32768
 dc.w 1
 dc.b "10:55.36",0
 even
 dc.l 65535
 dc.w 0
 dc.b "21:50",0
 even
 dc.l 65535
 dc.w 1
 dc.b "21:50.70",0
 even
 dc.l 65536
 dc.w 0
 dc.b "21:50",0
 even
 dc.l 65536
 dc.w 1
 dc.b "21:50.72",0
 even
 dc.l 74999
 dc.w 0
 dc.b "24:59",0
 even
 dc.l 74999
 dc.w 1
 dc.b "24:59.98",0
 even
 dc.l 75000
 dc.w 0
 dc.b "25:00",0
 even
 dc.l 75000
 dc.w 1
 dc.b "25:00.00",0
 even
 dc.l 131070
 dc.w 0
 dc.b "43:41",0
 even
 dc.l 131070
 dc.w 1
 dc.b "43:41.40",0
 even
 dc.l $000493e0
 dc.w 0
 dc.b "100:00",0
 even
 dc.l $000493e0
 dc.w 1
 dc.b "100:00.00",0
 even
 dc.l $004aff6a
 dc.w 1
 dc.b "1638:21.00",0
 even
 dc.l $005c2462
 dc.w 1
 dc.b "2012:52.52",0
 even
 dc.l $0bb80000
 dc.w 1
 dc.b "65536:00.00",0
 even
 dc.l $ffffffff
 dc.w 1
 dc.b "1431655:45.90",0
 even
sim_time_selftest:
 movem.l d0-a6,-(sp)
 lea sim_time_cases(pc),a2
 moveq #31,d7
.case:
 move.l (a2)+,d0
 move.w (a2)+,d1
 lea sim_time_test_buffer(pc),a0
 move.b #$5a,15(a0)
 bsr sim_time_format50
 lea sim_time_test_buffer(pc),a0
.compare:
 move.b (a2)+,d0
 cmp.b (a0)+,d0
 bne .failed
 tst.b d0
 bne .compare
 move.l a2,d0
 btst #0,d0
 beq .aligned
 addq.l #1,a2
.aligned:
 lea sim_time_test_buffer(pc),a0
 cmp.b #$5a,15(a0)
 bne .failed
 lea sim_time_passed(pc),a0
 addq.l #1,(a0)
 dbra d7,.case
 lea sim_time_cache_cases(pc),a2
 moveq #4,d7
.cache:
 move.l (a2)+,d0
 bsr sim_time_cache_reduce
 cmp.l (a2)+,d0
 bne .failed
 lea sim_time_passed(pc),a0
 addq.l #1,(a0)
 dbra d7,.cache
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #19,(a0)
 illegal
 bra.s .failed

sim_time_cache_cases:
 dc.l 0,0,65534,65534,65535,0,65536,1,75000,9465
