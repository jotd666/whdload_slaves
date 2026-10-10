; A4000 bounded history uses 30,000 local ticks. The unsigned rolling base
; reaches 45,000 over a 25-minute session: total time needs 32-bit arithmetic.
; Finish/penalty storage and time presentation still need their own widening.

; 2412: give all modes in this development build a sufficiently large buffer.
; Native bulk allocation/layout/free remains untouched; this static slave
; storage is valid for the full lifetime of the loaded game.
sim_history_input_buffer:
 movem.l a0,-(sp)
 lea sim_history_input_buffer(pc),a0
 adda.l #sim_history_inputs-sim_history_input_buffer,a0
 move.l a0,-$1770(a4)
 movem.l (sp)+,a0
 rts

; The next native BHI branches only while absolute producer time < limit.
sim_history_producer_limit:
 cmp.w #50,-$15fa(a4)
 beq .new
 move.w -$15fa(a4),d0
 muls #1500,d0
 move.w $a0(a4),d1
 add.w -$2e0(a4),d1
 cmp.w d1,d0
 rts
.new:
 move.w -$2e0(a4),d0
 move.w $a0(a4),d1
 bra sim_history_limit50

; The fast simulation route exits on the same absolute time, using consumer.
sim_history_consumer_limit:
 cmp.w #50,-$15fa(a4)
 beq .new
 move.w -$15fa(a4),d0
 muls #1500,d0
 move.w -$940(a4),d1
 add.w -$2e0(a4),d1
 cmp.w d1,d0
 rts
.new:
 move.w -$2e0(a4),d0
 move.w -$940(a4),d1
 bra sim_history_limit50

; d0.w unsigned rolling base, d1.w unsigned bounded cursor.
; Return d0.l limit, d1.l total and comparison flags used by native branches.
sim_history_limit50:
 and.l #$ffff,d0
 and.l #$ffff,d1
 add.l d0,d1
 move.l #75000,d0
 cmp.l d1,d0
 rts

; E56E: native expression yields the rate, coincidentally 20 only in A2500.
; At 50 it allowed snapshot index 20 beyond the twenty allocated slots.
sim_history_seek_bound:
 cmp.w #50,-$15fa(a4)
 beq .new
 move.w -$15fa(a4),d0
 muls #600,d0
 ext.l d0
 divs #600,d0
 rts
.new:
 moveq #0,d0
 move.w $b30(a4),d0
 divu -$ba(a4),d0
 rts

 even
 IFNE SIM_STARTUP_TESTS
 dc.b "4DCAPACT"
 dc.w 1,16
sim_capacity_passed: dc.l 0
; base, cursor, expected total, comparison class (below/equal/above limit).
sim_capacity_cases:
 dc.w 0,0
 dc.l 0
 dc.w 0
 dc.w 0,9463
 dc.l 9463
 dc.w 0
 dc.w 0,9464
 dc.l 9464
 dc.w 0
 dc.w 0,9465
 dc.l 9465
 dc.w 0
 dc.w 0,29999
 dc.l 29999
 dc.w 0
 dc.w 0,30000
 dc.l 30000
 dc.w 0
 dc.w 1500,28500
 dc.l 30000
 dc.w 0
 dc.w 15000,17767
 dc.l 32767
 dc.w 0
 dc.w 15000,17768
 dc.l 32768
 dc.w 0
 dc.w 36000,29535
 dc.l 65535
 dc.w 0
 dc.w 36000,29536
 dc.l 65536
 dc.w 0
 dc.w 45000,29999
 dc.l 74999
 dc.w 0
 dc.w 45000,30000
 dc.l 75000
 dc.w 1
 dc.w 46500,28501
 dc.l 75001
 dc.w 2
 dc.w $ffff,0
 dc.l 65535
 dc.w 0
 dc.w $ffff,$ffff
 dc.l 131070
 dc.w 2
sim_capacity_selftest:
 movem.l d0-a6,-(sp)
 lea sim_capacity_cases(pc),a0
 moveq #15,d7
.case:
 move.l #$12340000,d0
 move.l #$56780000,d1
 move.w (a0)+,d0
 move.w (a0)+,d1
 bsr sim_history_limit50
 bhi .below
 beq .equal
 bcs .above
 bra .failed
.below:
 moveq #0,d2
 bra.s .check
.equal:
 moveq #1,d2
 bra.s .check
.above:
 moveq #2,d2
.check:
 cmp.l #75000,d0
 bne .failed
 cmp.l (a0)+,d1
 bne .failed
 cmp.w (a0)+,d2
 bne .failed
 lea sim_capacity_passed(pc),a1
 addq.l #1,(a1)
 dbra d7,.case
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea perf_failure(pc),a0
 move.l #17,(a0)
 illegal
 bra.s .failed

 ENDC
