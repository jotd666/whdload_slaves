; Optional VERIFY-only recorder of native simulation entries, not completions.
; $E5F2: LINK a5,#-4; MOVEQ #0,d0. JMP hook has no extra return address.
; All entry registers except native A5/D0 and the native MOVEQ flags survive.
SIM_PROBE_RECORD_SIZE = 40
SIM_PROBE_RECORD_COUNT = 256
sim_probe_entry:
 link a5,#-4
 movem.l d0-d2/a0-a1,-(sp)
 moveq #0,d2
 addx.b d2,d2              ; save incoming X (MOVEQ preserves it)
 move.w d2,-(sp)
 lea sim_probe_count(pc),a0
 move.l (a0),d0
 and.l #SIM_PROBE_RECORD_COUNT-1,d0
 mulu #SIM_PROBE_RECORD_SIZE,d0
 lea sim_probe_records(pc),a1
 adda.l d0,a1
 move.l $2342(a4),(a1)+       ; 0: raw timer clock
 move.l $233a(a4),(a1)+       ; 4: ungated timer clock
 move.l a4,(a1)+             ; 8: data anchor
 move.w $a0(a4),(a1)+        ; 12: producer cursor
 move.w -$940(a4),(a1)+      ; 14: consumer cursor before update
 move.w -$15fa(a4),(a1)+     ; 16: active mode
 move.w -$be(a4),(a1)+       ; 18: timer divider
 move.w -$217c(a4),(a1)+     ; 20: CIA timer latch
 move.b $45(a4),(a1)+        ; 22: live/start/replay mode
 move.b -$68b(a4),(a1)+      ; 23: driving started
 move.l -$92e(a4),(a1)+      ; 24: player position
 move.l -$92a(a4),(a1)+      ; 28: player position
 move.l -$926(a4),(a1)+      ; 32: player position
 move.w $9c(a4),(a1)+        ; 36: scheduling ticks
 move.w -$948(a4),(a1)+      ; 38: event elapsed
 addq.l #1,(a0)             ; publish the completed record last
 move.w (sp)+,d2
 lsr.b #1,d2               ; restore X before flag-neutral transfer
 movem.l (sp)+,d0-d2/a0-a1
 ; Transfer to the remaining native body without borrowing an entry register.
 ; D0 is dead at entry: the displaced MOVEQ establishes it immediately below.
 move.l a0,-(sp)
 move.l tape_game(pc),a0
 adda.l #$e5f8,a0
 move.l a0,d0
 move.l (sp)+,a0
 move.l d0,-(sp)
 moveq #0,d0
 rts
 even
 dc.b "4DSIMPRB"
 dc.w 1,SIM_PROBE_RECORD_SIZE
sim_probe_count:
 dc.l 0
sim_probe_records:
 dcb.b SIM_PROBE_RECORD_SIZE*SIM_PROBE_RECORD_COUNT,0
