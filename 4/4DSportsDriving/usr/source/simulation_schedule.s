; VERIFY-only integration prototype: field-sampled live inputs, imported in
; the main task through the native history writer. Replay/start routes retain
; native scheduling until their separate lifecycle integration is validated.
SIM_QUEUE_COUNT = 256
SIM_QUEUE_SIZE = 8

; Called by the VBL server with scratch registers saved, after counting field.
sim_schedule_field:
 lea sim_schedule_active(pc),a0
 tst.w (a0)
 beq .done
 move.l sim_schedule_a4(pc),a4
 tst.b $45(a4)
 bne .paused
 tst.b $42(a4)
 bne .paused
 tst.b $a9a(a4)
 bne .paused
 tst.w $a9c(a4)
 bne .paused
 move.w -$948(a4),d0
 cmp.w -$946(a4),d0
 bge .paused             ; native event deadline; CIA retains sound handling
 lea sim_schedule_phase(pc),a0
 move.w sim_schedule_rate(pc),d0
 add.w d0,(a0)
 cmp.w #50,(a0)
 blo .done
 sub.w #50,(a0)
 lea sim_schedule_write(pc),a2
 move.w (a2),d0
 sub.w sim_schedule_read(pc),d0
 cmp.w #SIM_QUEUE_COUNT,d0
 bhs .overflow
 moveq #0,d3              ; analogue steering demand
 moveq #0,d4              ; analogue-present flag
 tst.b -$68a(a4)
 bne .zero
 tst.b -$7710(a4)
 bne .mouse
 jsr -$799e(a4)           ; pure held-key / joystick hardware reader
 move.w d0,d5
 bra .gears
.mouse:
 moveq #1,d4
 move.w $2102(a4),d0      ; native mouse x, as read by $2A6DE
 sub.w #160,d0
 asr.w #1,d0
 ext.w d0                ; native conversion truncates to signed byte
 tst.b d0
 beq .steer_ready
 bmi .negative
 and.w #$ff,d0
 lea -$7514(a4),a0
 move.b (a0,d0.w),d0
 bra .steer_ready
.negative:
 ext.w d0
 neg.w d0
 lea -$7514(a4),a0
 move.b (a0,d0.w),d0
 neg.b d0
.steer_ready:
 move.b d0,d3
 moveq #0,d5
 btst #0,-$3360+1(a4)
 beq .mouse_throttle
 moveq #2,d5
 bra .gears
.mouse_throttle:
 btst #1,-$3360+1(a4)
 beq .gears
 moveq #1,d5
.gears:
 btst #5,d5
 beq .direct_gears
 btst #0,d5
 beq .gear_down
 bset #4,d5
.gear_down:
 btst #1,d5
 beq .direct_gears
 bset #5,d5
.direct_gears:
 tst.w $20c6(a4)
 beq .publish
 tst.b $2356+$20(a4)
 beq .direct_down
 bset #4,d5
.direct_down:
 tst.b $2356+$31(a4)
 beq .publish
 bset #5,d5
 bra .publish
.zero:
 moveq #0,d5
.publish:
 move.w (a2),d0
 and.w #SIM_QUEUE_COUNT-1,d0
 lsl.w #3,d0
 lea sim_schedule_queue(pc),a0
 adda.w d0,a0
 move.l sim_clock_fields(pc),(a0)+
 move.b d5,(a0)+
 move.b d3,(a0)+
 move.b d4,(a0)+
 clr.b (a0)
 addq.w #1,(a2)           ; payload precedes publication
 addq.w #1,$9c(a4)
 lea sim_schedule_ticks(pc),a0
 addq.l #1,(a0)
.done:
 rts
.paused:
 lea sim_schedule_phase(pc),a0
 clr.w (a0)
 rts
.overflow:
 lea sim_schedule_overflow(pc),a0
 move.w #1,(a0)
 rts

; $70E0: move.w $A0(a4),d0; cmp.w -$940(a4),d0.
sim_schedule_poll:
 movem.l d0-d7/a0-a6,-(sp)
 moveq #0,d0
 addx.b d0,d0
 move.w d0,-(sp)
 move.l tape_configured(pc),d0
 beq .return
 tst.b $45(a4)
 bne .deactivate
 lea sim_schedule_active(pc),a0
 tst.w (a0)
 bne .drain
 lea sim_schedule_a4(pc),a0
 move.l a4,(a0)
 lea sim_schedule_rate(pc),a0
 move.w -$15fa(a4),(a0)
 lea sim_schedule_phase(pc),a0
 clr.w (a0)
 lea sim_schedule_read(pc),a0
 clr.w (a0)
 lea sim_schedule_write(pc),a0
 clr.w (a0)
 lea sim_schedule_active(pc),a0
 move.w #1,(a0)           ; publish initialized state last
.drain:
 tst.b $42(a4)
 bne .return
 tst.b $a9a(a4)
 bne .return
 move.w sim_schedule_overflow(pc),d0
 beq .capacity_ok
 lea perf_failure(pc),a0
 move.l #12,(a0)
 illegal                  ; explicit VERIFY failure, never overwrite history
.capacity_ok:
 move.w $a0(a4),d0
 cmp.w -$940(a4),d0
 bne .return              ; consume older native history first
 move.w sim_schedule_read(pc),d0
 cmp.w sim_schedule_write(pc),d0
 beq .return
 and.w #SIM_QUEUE_COUNT-1,d0
 lsl.w #3,d0
 lea sim_schedule_queue(pc),a0
 adda.w d0,a0
 lea sim_schedule_current(pc),a1
 move.l (a0)+,(a1)+
 move.l (a0),(a1)
 move.w $a0(a4),d6
 lea sim_schedule_enqueuing(pc),a0
 move.w #1,(a0)
 move.w #1,-(sp)          ; native synthetic-input route bypasses live sampling
 move.l tape_game(pc),a0
 adda.l #$7a66,a0
 jsr (a0)
 addq.l #2,sp
 lea sim_schedule_enqueuing(pc),a0
 clr.w (a0)
 cmp.w $a0(a4),d6
 beq .return             ; native history-full prompt: retain the input
 move.b sim_schedule_current+6(pc),d0
 beq .consumed
 ; At most one pending native step: the 64-slot steering ring cannot wrap.
 move.w $a0(a4),d0
 subq.w #1,d0
 and.w #63,d0
 lea $ab0(a4),a0
 move.b sim_schedule_current+5(pc),(a0,d0.w)
 lea $af0(a4),a0
 move.b #1,(a0,d0.w)
.consumed:
 lea sim_schedule_read(pc),a0
 addq.w #1,(a0)
 bra .return
.deactivate:
 lea sim_schedule_active(pc),a0
 clr.w (a0)
.return:
 move.w (sp)+,d0
 lsr.b #1,d0
 movem.l (sp)+,d0-d7/a0-a6
 move.w $a0(a4),d0
 cmp.w -$940(a4),d0
 rts

; $7A04: displaced decrement and BNE $7A5E. Keep the CIA sound service,
; pause/end checks and callback cleanup; skip only its simulation production.
sim_schedule_timer:
 move.l a0,-(sp)
 lea sim_schedule_active(pc),a0
 tst.w (a0)
 move.l (sp)+,a0
 bne .skip
 subq.b #1,$43(a4)
 beq .done
.skip:
 add.l #$54,(sp)          ; return $7A0A -> $7A5E
.done:
 rts

; $7C0A: original session-limit arithmetic, with captured input substitution.
sim_schedule_input:
 move.l a0,-(sp)
 lea sim_schedule_enqueuing(pc),a0
 tst.w (a0)
 beq .original
 move.b sim_schedule_current+4(pc),-1(a5)
.original:
 move.l (sp)+,a0
 move.w -$15fa(a4),d0
 muls #1500,d0
 rts

 even
 dc.b "4DSCHED!"
 dc.w 1,SIM_QUEUE_COUNT
sim_schedule_active: dc.w 0
sim_schedule_phase: dc.w 0
sim_schedule_rate: dc.w 0
sim_schedule_read: dc.w 0
sim_schedule_write: dc.w 0
sim_schedule_overflow: dc.w 0
sim_schedule_enqueuing: dc.w 0
sim_schedule_a4: dc.l 0
sim_schedule_ticks: dc.l 0
sim_schedule_current: dcb.b SIM_QUEUE_SIZE,0
sim_schedule_queue: dcb.b SIM_QUEUE_COUNT*SIM_QUEUE_SIZE,0
