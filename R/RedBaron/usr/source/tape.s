; VERIFY-only Red Baron v1 keyboard route and gameplay input anchor.
; ps:15b3a returns raw/translated keys; sim:1ef92 returns raw keys.
; Return must also be held in the native bitmap: menus treat it as a mouse button.
; OS task / WaitTOF / timer.device input is unsuitable after this game takes over.
; All offsets are hunk-0 offsets. Other slave-supported versions are unmodified.
; RBVERIFY +8: poll hook, +12: emit hook, +16/+20/+24: baron/ps/sim code bases,
; +28: polls, +32: key events, +36: generic input hook, +40: input calls,
; +44: gameplay steps after route completion, +48: gameplay-only anchor,
; +52: current caller is flight (1) or UI (0). Pointers initialize only in live slave.
; Gameplay steps are input-loop calls, not a validated display-frame counter.
; Profile at game step 1. CUSTOM5 bit 1 enables Right at steps 20..34; release at 35.
; CUSTOM5 bit 4 emits F2 once after flight step 2, for rear-view scene captures.
; Normal builds contain none of these fixtures.
RAW_RETURN = $440d
RAW_TAB = $4209
RAW_RIGHT = $4e00
RAW_F2 = $5100
RAW_F10 = $5900
RAW_ESC = $451b
	EVEN
tape_start:
	bsr observe_start
	IFD VERIFY_ALLOC_LOG
	bsr alloc_observe_start
	ENDC
	lea tape_marker(pc),a0
	lea tape_menu_key(pc),a1
	move.l a1,8(a0)
	lea tape_emit(pc),a1
	move.l a1,12(a0)
	lea tape_anchor(pc),a1
	move.l a1,36(a0)
	lea tape_game_anchor(pc),a1
	move.l a1,48(a0)
	rts

tape_sim_key:
	move.w time_keys_ready(pc),d0
	beq .route
	move.l time_keys_native_pop(pc),-(sp)
	rts
.route
	; With no scripted fixture selected, accept real commands after menus.
	; W6 owns its pop above; nonzero CUSTOM5 preserves the old fixture route.
	move.l tape_game_steps(pc),d0
	beq .menu_route
	move.l a0,-(sp)
	lea .fixture_base(pc),a0
.fixture_base
	adda.l #perf_custom5-.fixture_base,a0
	move.l (a0),d0
	move.l (sp)+,a0
	bne .menu_route
	move.l tape_marker+24(pc),d0
	addi.l #$309cc,d0
	move.l d0,-(sp)
	rts
.menu_route
	bsr tape_menu_key
	lsr.w #8,d0
	rts

tape_menu_key:
	movem.l d1-d2/a0-a1,-(sp)
	lea tape_hold(pc),a0
	tst.w (a0)
	beq.s .notheld
	subq.w #1,(a0)
	bne.s .notheld
	move.l tape_keybase(pc),a1
	move.w tape_last(pc),d1
	clr.b (a1,d1.w)
.notheld:
	lea tape_polls(pc),a0
	addq.l #1,(a0)
	lea tape_index(pc),a1
	move.w (a1),d1
	move.l tape_routeptr(pc),a0
	adda.w d1,a0
	move.w (a0),d2
	beq.s tape_menu_key_none
	lea tape_wait(pc),a1
	addq.w #1,(a1)
	cmp.w (a1),d2
	bhi.s tape_menu_key_none
	clr.w (a1)
	move.w 2(a0),d0
	lea tape_index(pc),a1
	addq.w #4,(a1)
	lea tape_events(pc),a1
	addq.l #1,(a1)
	move.l tape_keybase(pc),a1
	move.w d0,d1
	lsr.w #8,d1
	move.b #1,(a1,d1.w)
	lea tape_last(pc),a1
	move.w d1,(a1)
	lea tape_hold(pc),a1
	move.w #10,(a1)
tape_emit:
	bra.s tape_return
tape_menu_key_none:
; Optional dense-scene search: emit one native F2 event after flight begins.
; Keep it separate from the squadron route so earlier forward-view fixtures remain available.
	lea .custom5_base(pc),a1
.custom5_base
	adda.l #perf_custom5+3-.custom5_base,a1
	btst #4,(a1)
	beq.s .none
	move.l tape_game_steps(pc),d1
	cmp.l #2,d1
	blo.s .none
	move.l tape_inflight(pc),d1
	tst.l d1
	beq.s .none
	lea tape_rear_sent(pc),a1
	tst.w (a1)
	bne.s .none
	move.w #1,(a1)
	lea tape_events(pc),a1
	addq.l #1,(a1)
	move.w #RAW_F2,d0
	bra.s tape_return
.none:
	moveq #0,d0
tape_return:
	movem.l (sp)+,d1-d2/a0-a1
	tst.w d0
	rts

tape_loadseg:
	lsl.l #2,d0
	move.l d0,a0
	lsl.l #2,d1
	addq.l #4,d1
	lea tape_marker(pc),a1
	cmp.b #'b',1(a0)
	bne.s .ps
	move.l d1,16(a1)
.ps:
	cmp.b #'p',1(a0)
	bne.s .sim
	move.l d1,20(a1)
	move.l d1,d2
	add.l #$2ba5c,d2
	lea tape_keybase(pc),a2
	move.l d2,(a2)
	lea tape(pc),a2
	lea .custom5_base(pc),a1
.custom5_base
	adda.l #perf_custom5+3-.custom5_base,a1
	btst #2,(a1)
	beq.s tape_newroute
	lea tape_dense(pc),a2
	bra.s tape_newroute
.sim:
	cmp.b #'s',1(a0)
	bne.s .out
	cmp.b #'i',2(a0)
	bne.s .out
	move.l d1,24(a1)
	move.l d1,d2
	add.l #$1ec20,d2
	lea tape_flight_target(pc),a2
	move.l d2,(a2)
	move.l d1,d2
	add.l #$30f8c,d2
	lea tape_keybase(pc),a2
	move.l d2,(a2)
	lea tape_sim(pc),a2
	bra.s tape_newroute
.out:
	rts
tape_newroute:
	lea tape_routeptr(pc),a0
	move.l a2,(a0)
	lea tape_index(pc),a0
	clr.w (a0)
	lea tape_wait(pc),a0
	clr.w (a0)
	lea tape_hold(pc),a0
	clr.w (a0)
	rts

; sim v1 keyboard flight-control call: replaces bsr sim:1ec20; move.l d0,d7.
tape_flight:
	movem.l d0/a0-a1,-(sp)
	lea tape_flight_calls(pc),a0
	addq.l #1,(a0)
; The input helper is shared by menus. Only sim:21d30 is the flight caller.
	lea tape_inflight(pc),a0
	clr.l (a0)
	move.l 4(a5),d0
	sub.l tape_marker+24(pc),d0
	cmp.l #$21d30,d0
	bne.s tape_anchor
	move.l #1,(a0)
	bsr time_prelude_step
	move.l tape_routeptr(pc),a0
	move.w tape_index(pc),d0
	tst.w (a0,d0.w)
	bne.s tape_anchor
	move.w tape_hold(pc),d0
	bne.s tape_anchor
	lea tape_game_steps(pc),a0
	addq.l #1,(a0)
	move.w time_keys_ready(pc),d0
	bne.s tape_game_record
	move.l (a0),d0
	move.l tape_keybase(pc),a1
	clr.b $4e(a1)
	lea .custom5_base(pc),a0
.custom5_base
	adda.l #perf_custom5+3-.custom5_base,a0
	btst #1,(a0)
	beq.s tape_game_record
	cmp.l #20,d0
	blo.s tape_game_record
	cmp.l #35,d0
	bhs.s tape_game_record
	move.b #1,$4e(a1)
tape_game_record:
	bsr observe_step
	IFD VERIFY_ALLOC_LOG
	bsr alloc_observe_stop
	ENDC
tape_game_anchor:
	nop
	lea .activate_base(pc),a0
.activate_base
	adda.l #perf_activate_deferred-.activate_base,a0
	jsr (a0)
tape_anchor:
	movem.l (sp)+,d0/a0-a1
	move.l a0,-(sp)
	move.l tape_flight_target(pc),a0
	jsr (a0)
	move.l (sp)+,a0
	move.l d0,d7
	rts
	CNOP 0,4
tape_marker: dc.b "RBVERIFY"
	dc.l 0,0,0,0,0
tape_polls: dc.l 0
tape_events: dc.l 0
tape_anchor_address: dc.l 0
tape_flight_calls: dc.l 0
tape_game_steps: dc.l 0
tape_game_anchor_address: dc.l 0
tape_inflight: dc.l 0
tape_hold: dc.w 0
tape_last: dc.w 0
tape_index: dc.w 0
tape_wait: dc.w 0
tape:
	INCLUDE "tape-route.i"

tape_keybase: dc.l 0
tape_routeptr: dc.l 0
tape_sim:
 ; Pre-flight mission-tape dialog: Tab selects No; Return confirms.
 dc.w 100,RAW_TAB,100,RAW_RETURN
 ; Allow 50 input polls in flight, then open Preferences.
 dc.w 50,RAW_F10
 ; Default focus is Sound; five Tabs reach World.
 REPT 5
 dc.w 100,RAW_TAB
 ENDR
 ; Activate the slider, move fully right, then confirm its position.
 dc.w 100,RAW_RETURN
 REPT 20
 dc.w 100,RAW_RIGHT
 ENDR
 dc.w 100,RAW_RETURN,100,RAW_TAB,100,RAW_RETURN
 ; Aircraft slider: likewise saturate to maximum.
 REPT 20
 dc.w 100,RAW_RIGHT
 ENDR
 dc.w 100,RAW_RETURN,100,RAW_TAB,100,RAW_RETURN
 ; Ground detail is now ON IN COMBAT. Skip Sound/Fill/Joy/Time to ACCEPT.
 ; Time Scale stays at the archive's original setting.
 REPT 5
 dc.w 100,RAW_TAB
 ENDR
 dc.w 100,RAW_RETURN
 IFD VERIFY_PANEL_CHECK
 ; Optional QA: reopen the accepted panel, leave time to inspect, then Escape.
 dc.w 50,RAW_F10,5000,RAW_ESC
 ENDC
 dc.w 0

tape_rear_sent: dc.w 0
	EVEN
tape_flight_target: dc.l 0

	INCLUDE "observe.s"
