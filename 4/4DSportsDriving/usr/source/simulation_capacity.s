; A4000 bounded history uses 30,000 local ticks. The unsigned rolling base
; reaches 45,000 over a 25-minute session: total time needs 32-bit arithmetic.
; Finish/penalty storage and time presentation still need their own widening.

; 2412: all modes share the full-capacity runtime input buffer.
; Native bulk allocation/layout/free remains untouched; the runtime workspace
; is valid for the full lifetime of the loaded game.
sim_history_input_buffer:
 movem.l a0,-(sp)
 lea sim_history_input_buffer(pc),a0
 adda.l #sim_history_inputs-sim_history_input_buffer,a0
 movea.l (a0),a0
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
