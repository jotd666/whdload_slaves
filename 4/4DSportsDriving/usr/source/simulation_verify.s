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
 IFD SIM_FIXTURE
 bsr sim_fixture_before
 ENDC
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

 IFD SIM_FIXTURE
; Deterministic consumer-side input fixture, VERIFY only. This is deliberately
; not a production input scheduler. Samples the first 3.2 game seconds at 10 Hz.
; Snapshots are raw native replay state; compare and classify differences before
; selecting a semantic manifest. No fields are masked here.
SIM_FIXTURE_SAMPLES = 32
SIM_FIXTURE_STATE_SIZE = $460
SIM_FIXTURE_RECORD_SIZE = SIM_FIXTURE_STATE_SIZE+4
sim_fixture_before:
 move.l tape_configured(pc),d0
 beq .done
 tst.b $45(a4)
 bne .done
 lea sim_fixture_active(pc),a0
 tst.w (a0)
 bne .active
 tst.w -$940(a4)
 bne .done
 tst.b -$68b(a4)
 bne .done
 move.w #1,(a0)
.active:
 ; Throttle for eight seconds, then brake for two, then throttle again.
 moveq #1,d1
 move.w -$15fa(a4),d0
 mulu #8,d0
 cmp.w -$940(a4),d0
 bhi .input
 move.w -$15fa(a4),d0
 mulu #10,d0
 cmp.w -$940(a4),d0
 bls .input
 moveq #2,d1
.input:
 moveq #0,d0
 move.w -$940(a4),d0
 move.l -$1770(a4),a1
 move.b d1,(a1,d0.l)
 ; Capture BEFORE the native update: sample 0 is the untouched initial state.
 move.w -$15fa(a4),d1
 divu #10,d1
 divu d1,d0
 swap d0
 tst.w d0
 bne .done
 lea sim_fixture_count(pc),a0
 cmp.w #SIM_FIXTURE_SAMPLES,(a0)
 bhs .done
 moveq #0,d0
 move.w (a0),d0
 mulu #SIM_FIXTURE_RECORD_SIZE,d0
 lea sim_fixture_records(pc),a1
 adda.l d0,a1
 move.w -$940(a4),(a1)+
 move.w -$15fa(a4),(a1)+
 lea -$a80(a4),a0
 move.w #SIM_FIXTURE_STATE_SIZE/4-1,d0
.copy:
 move.l (a0)+,(a1)+
 dbf d0,.copy
 lea sim_fixture_count(pc),a0
 addq.w #1,(a0)
.done:
 rts
 even
 dc.b "4DSIMFIX"
 dc.w 1,SIM_FIXTURE_RECORD_SIZE
sim_fixture_active: dc.w 0
sim_fixture_count: dc.w 0
sim_fixture_records:
 dcb.b SIM_FIXTURE_SAMPLES*SIM_FIXTURE_RECORD_SIZE,0
 ENDC
