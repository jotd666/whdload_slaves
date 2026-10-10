; Wide elapsed-time display ABI for four audited call sites. D0 carries the
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
; Only the four converted callers promise a full unsigned D0 tick argument.
sim_time_format_entry:
 movem.l d0-d3/a0,-(sp)
 moveq #0,d2
 addx.w d2,d2
 move.w d2,-(sp)
 cmp.w #50,-$15fa(a4)
 bne .native
 move.l 22(sp),d1
 lea sim_time_format_entry(pc),a0
 adda.l #tape_game-sim_time_format_entry,a0
 sub.l (a0),d1
 cmp.l #$7720,d1
 beq .wide
 cmp.l #$9308,d1
 beq .wide
 cmp.l #$937e,d1
 beq .wide
 cmp.l #$20f08,d1
 bne .native
.wide:
 move.l 2(sp),d0
 move.l 26(sp),a0
 move.w 32(sp),d1
 bsr sim_time_format50
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

; d0.l unsigned ticks at50Hz, d1.w fractions flag, a0 output (9 bytes).
; Scratch d0-d3/a0. Preserve the native two-character minute field and the
; two-digit seconds/hundredths. All supported elapsed totals are <=75000.
sim_time_format50:
 move.w d1,d3
 divu #3000,d0
 move.l d0,d1
 swap d1
 and.l #$ffff,d1             ; ticks within this minute
 and.l #$ffff,d0
 bsr .pair
 cmp.b #'0',-2(a0)
 bne .colon
 move.b #' ',-2(a0)
.colon:
 move.b #':',(a0)+
 move.l d1,d0
 divu #50,d0
 move.l d0,d1
 swap d1
 and.l #$ffff,d1             ; ticks within this second
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
 dc.w 2,31
sim_time_passed: dc.l 0
sim_time_test_buffer: dcb.b 10,0
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
sim_time_selftest:
 movem.l d0-a6,-(sp)
 lea sim_time_cases(pc),a2
 moveq #25,d7
.case:
 move.l (a2)+,d0
 move.w (a2)+,d1
 lea sim_time_test_buffer(pc),a0
 move.b #$5a,9(a0)
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
 cmp.b #$5a,9(a0)
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
