; VERIFY-only keyboard route, adapted from the Battlehawks input.device tape.
; Each event uses normal Amiga raw keys. No input automation in release builds.
	INCLUDE	exec/types.i
	INCLUDE	exec/nodes.i
	INCLUDE	exec/lists.i
	INCLUDE	exec/tasks.i
	INCLUDE	exec/ports.i
	INCLUDE	exec/io.i
	INCLUDE	devices/input.i
	INCLUDE	devices/inputevent.i


 IFND TAPE_SIMULATION
TAPE_SIMULATION = 10
 ENDC
 IFNE TAPE_SIMULATION-10
 IFNE TAPE_SIMULATION-20
 IFD SIM_MODE_MENU
 IFNE TAPE_SIMULATION-50
 FAIL "TAPE_SIMULATION must be 10, 20 or 50"
 ENDC
 ELSE
 FAIL "TAPE_SIMULATION must be 10 or 20"
 ENDC
 ENDC
 ENDC

 IFND TAPE_DETAIL
TAPE_DETAIL = 0 ; FULL; other levels are VERIFY coverage only
 ENDC
 IFGT TAPE_DETAIL-4
 FAIL "TAPE_DETAIL must be 0..4"
 ENDC
 IFLT TAPE_DETAIL
 FAIL "TAPE_DETAIL must be 0..4"
 ENDC

RAW_RETURN = $44
RAW_UP = $80
 IFND TAPE_FIRST
TAPE_FIRST = 25
 ENDC
 IFND TAPE_GAP
TAPE_GAP = 25
 ENDC
 IFND TAPE_KEYS
TAPE_KEYS = 200
 ENDC

tape:
 dc.w TAPE_FIRST,RAW_RETURN,5,RAW_RETURN|RAW_UP
 REPT TAPE_KEYS-1
 dc.w TAPE_GAP,RAW_RETURN,5,RAW_RETURN|RAW_UP
 ENDR
 dc.w 0

; Called from the LoadSeg hook (a task, all registers saved by the caller).
tape_start:
	move.l	(4).w,a6
	lea	tape_task(pc),a1
	move.b	#NT_TASK,LN_TYPE(a1)
	move.b	#1,LN_PRI(a1)		;above the game, so events go out on time
	lea	tape_name(pc),a0
	move.l	a0,LN_NAME(a1)
	lea	TC_MEMENTRY(a1),a0
	NEWLIST	a0
	lea	tape_stack(pc),a0
	move.l	a0,TC_SPLOWER(a1)
	lea	tape_stack_end(pc),a0
	move.l	a0,TC_SPUPPER(a1)
	move.l	a0,TC_SPREG(a1)
	lea	tape_task_code(pc),a2
	sub.l	a3,a3
	jmp	_LVOAddTask(a6)

tape_task_code:
	move.l	(4).w,a6
	lea	tape_gfx_name(pc),a1
	moveq	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,a5
 IFD TAPE_PIXELS
 lea tape_gfx_base(pc),a0
 move.l d0,(a0)
 ENDC
	moveq	#-1,d0
	jsr	_LVOAllocSignal(a6)
	lea	tape_port(pc),a2
	move.b	d0,MP_SIGBIT(a2)
	move.b	#NT_MSGPORT,LN_TYPE(a2)
	move.b	#PA_SIGNAL,MP_FLAGS(a2)
	sub.l	a1,a1
	jsr	_LVOFindTask(a6)
	move.l	d0,MP_SIGTASK(a2)
	lea	MP_MSGLIST(a2),a0
	NEWLIST	a0
	lea	tape_io(pc),a1
	move.l	a2,MN_REPLYPORT(a1)
	lea	tape_input_name(pc),a0
	moveq	#0,d0
	moveq	#0,d1
	jsr	_LVOOpenDevice(a6)
 IFD TAPE_OPPONENT
 bsr tape_opponent_route
 ENDC
	lea	tape(pc),a3
.next:	move.w	(a3)+,d2
	beq.w	.done
.wait:	exg	a5,a6
	jsr	_LVOWaitTOF(a6)
	exg	a5,a6
	lea	tape_fields(pc),a0
	addq.l	#1,(a0)
	subq.w	#1,d2
	bne.s	.wait
	move.l tape_frames(pc),d0
	bne.s .release
	lea	tape_event(pc),a0
	move.b	#IECLASS_RAWKEY,ie_Class(a0)
	move.w	(a3)+,ie_Code(a0)
	lea tape_keys_sent(pc),a1
	addq.l #1,(a1)
	lea	tape_io(pc),a1
	move.w	#IND_WRITEEVENT,IO_COMMAND(a1)
	move.l	a0,IO_DATA(a1)
	move.l	#ie_SIZEOF,IO_LENGTH(a1)
	jsr	_LVODoIO(a6)
	bra.s	.next
.release:
 lea tape_event(pc),a0
 move.b #IECLASS_RAWKEY,ie_Class(a0)
 move.w #RAW_RETURN|RAW_UP,ie_Code(a0)
 lea tape_io(pc),a1
 move.w #IND_WRITEEVENT,IO_COMMAND(a1)
 move.l a0,IO_DATA(a1)
 move.l #ie_SIZEOF,IO_LENGTH(a1)
 jsr _LVODoIO(a6)
 bsr tape_graphics
 bsr tape_simulation
 IFD SIM_FIXTURE
 ; Graphics-navigation arrow keys can start the current race. Always use
 ; the native restart route before arming a tick-indexed fixture.
 bsr tape_restart_simulation
 ENDC
 lea tape_frames(pc),a0
 clr.l (a0)
 lea tape_configured(pc),a0
 move.l #1,(a0)
 IFD TAPE_ACCEL
 lea tape_event(pc),a0
 move.w #$4c,ie_Code(a0) ; ordinary raw cursor-up press
 lea tape_io(pc),a1
 jsr _LVODoIO(a6)
 ENDC
 IFD SIM_REPLAY_LOAD_ERROR_TEST
 bsr tape_replay_error_ack
 ENDC
 IFD SIM_MODAL_FIXTURE
 bsr tape_live_modal_fixture
 ENDC
 IFD SIM_RESTART_FIXTURE
 bsr tape_live_restart_fixture
 ENDC
 IFD TAPE_SCENARIO
 bsr tape_scenario
 ENDC
 IFD SIM_LIVE_INPUT_TEST
 bsr tape_live_input_test
 ENDC
.done:	moveq	#0,d0
	jsr	_LVOWait(a6)
	bra.s	.done

; Use the game's Ctrl-G command after entering the cockpit.
tape_graphics:
 moveq #0,d3
 lea tape_graphics_keys(pc),a3
 bra.s tape_menu_keys
tape_simulation:
 move.l tape_a4(pc),a0
 cmp.w #TAPE_SIMULATION,-$bc(a0)
 beq.s .done
 lea tape_dialog_ready(pc),a0
 clr.l (a0)
 moveq #1,d3
 lea tape_simulation_keys(pc),a3
 bsr tape_menu_keys
 bsr tape_restart_simulation
.done:
 rts
tape_menu_keys:
.next:
 move.w (a3)+,d2
 beq.w .done
 lea tape_event(pc),a0
 move.w (a3)+,ie_Code(a0)
 move.w (a3)+,ie_Qualifier(a0)
 ; The menu skips checked entries. Leave an already selected level alone;
 ; otherwise navigate to the requested VERIFY detail level.
 cmp.w #RAW_RETURN,ie_Code(a0)
 bne.w .send
 move.l tape_a4(pc),a1
 tst.w d3
 bne.w .simulation_before
 cmp.b #TAPE_DETAIL,-$7708(a1)
 beq.w .next
 IFNE TAPE_DETAIL
 bsr tape_detail_select
 ENDC
 bra.w .send
.simulation_before:
 cmp.w #TAPE_SIMULATION,-$bc(a1)
 beq.w .next
 IFD SIM_MODE_MENU
 bsr tape_mode_select
 ENDC
.send:
 lea tape_io(pc),a1
 jsr _LVODoIO(a6)
.wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 lea tape_event(pc),a0
 cmp.w #$24,ie_Code(a0)
 bne.w .selection
 move.l tape_dialog_ready(pc),d0
 bne.w .next
 bra.w .timed
.selection:
 cmp.w #RAW_RETURN,ie_Code(a0)
 bne.w .timed
 move.l tape_a4(pc),a0
 tst.w d3
 bne.w .simulation_after
 cmp.b #TAPE_DETAIL,-$7708(a0)
 beq.w .next
 bra.w .timed
.simulation_after:
 cmp.w #TAPE_SIMULATION,-$bc(a0)
 beq.w .next
.timed:
 subq.w #1,d2
 bne.w .wait
 bra.w .next
.done:
 rts
 IFNE TAPE_DETAIL
; Navigate only unchecked graphics entries. The current level is skipped by
; the game's dialog, so one fewer Down is needed when it precedes the target.
tape_detail_select:
 move.w d2,-(sp)
 moveq #TAPE_DETAIL,d4
 cmp.b #TAPE_DETAIL,-$7708(a1)
 bhs.s .count_ready
 subq.w #1,d4
.count_ready:
 tst.w d4
 beq.s .done
.down:
 move.w #$4d,d0
 moveq #10,d2
 bsr.s tape_detail_key
 move.w #$cd,d0
 moveq #30,d2
 bsr.s tape_detail_key
 subq.w #1,d4
 bne.s .down
.done:
 lea tape_event(pc),a0
 move.w #RAW_RETURN,ie_Code(a0)
 clr.w ie_Qualifier(a0)
 move.w (sp)+,d2
 rts
tape_detail_key:
 lea tape_event(pc),a0
 move.w d0,ie_Code(a0)
 clr.w ie_Qualifier(a0)
 lea tape_io(pc),a1
 jsr _LVODoIO(a6)
.wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 subq.w #1,d2
 bne.s .wait
 rts
 ENDC

tape_graphics_keys:
 dc.w 5,$63,IEQUALIFIER_CONTROL
 dc.w 5000,$24,IEQUALIFIER_CONTROL
 dc.w 5,$a4,IEQUALIFIER_CONTROL
 dc.w 200,$e3,0
 dc.w 5000,$44,0
 dc.w 100,$c4,0
 dc.w 20,$45,0 ; Escape closes the dialog
 dc.w 50,$c5,0
 dc.w 0

; One of the five graphics entries is checked and skipped. Four Down presses
; from the first unchecked entry reach the unchecked simulation choice.
; The already-selected simulation choice is also skipped.
tape_simulation_keys:
 dc.w 5,$63,IEQUALIFIER_CONTROL
 dc.w 5000,$24,IEQUALIFIER_CONTROL
 dc.w 5,$a4,IEQUALIFIER_CONTROL
 dc.w 200,$e3,0
 IFND SIM_MODE_MENU
 REPT 4
 dc.w 10,$4d,0
 dc.w 30,$cd,0
 ENDR
 ENDC
 dc.w 5000,$44,0
 dc.w 100,$c4,0
 dc.w 20,$45,0
 dc.w 50,$c5,0
 dc.w 0

 CNOP 0,4
 dc.b "4DTAPE!!"
tape_game: dc.l 0
tape_fields: dc.l 0
tape_frames: dc.l 0
tape_a4: dc.l 0
tape_first_field: dc.l 0
tape_keys_sent: dc.l 0
tape_configured: dc.l 0
tape_dialog_ready: dc.l 0

; Called at game:$74fa, after drawing and before the buffer-index flip.
; Mode $45=0 is live driving; e928=0 excludes the attract/replay route.
tape_frame:
 movem.l d0/a0,-(sp)
 tst.b $45(a4)
 bne.s .original
 tst.b -$16d8(a4)
 bne.s .original
 lea tape_a4(pc),a0
 move.l a4,(a0)
 lea tape_frames(pc),a0
 tst.l (a0)
 bne.s .count
 move.l tape_fields(pc),d0
 lea tape_first_field(pc),a0
 move.l d0,(a0)
 lea tape_frames(pc),a0
.count:
 addq.l #1,(a0)
.original:
 movem.l (sp)+,d0/a0
 bchg #0,$3b(a4)
 rts

tape_name:	dc.b	"driving tape",0
tape_gfx_name:	dc.b	"graphics.library",0
tape_input_name:	dc.b	"input.device",0
	EVEN
tape_task:	dcb.b	TC_SIZE,0
tape_port:	dcb.b	MP_SIZE,0
tape_io:	dcb.b	IOSTD_SIZE,0
tape_event:	dcb.b	ie_SIZEOF,0
	EVEN
tape_stack:	dcb.b	1024,0
tape_stack_end:

; Acknowledge Ctrl-G at the native dialog entry, so slow VERIFY twins cannot
; miss the key between rendered frames. The replaced instruction is six bytes.
tape_dialog_enter:
 move.l a0,-(sp)
 lea tape_dialog_ready(pc),a0
 move.l #1,(a0)
 move.l (sp)+,a0
 move.w -$bc(a4),-6(a5)
 rts

 IFD TAPE_SCENARIO
; Scenario coverage uses ordinary input.device events after the normal anchor.
tape_scenario:
.wait_frame:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 move.l tape_frames(pc),d0
 cmp.l #40,d0
 blo.s .wait_frame
 lea tape_scenario_keys(pc),a3
.next:
 move.w (a3)+,d2
 beq.s tape_scenario_done
 lea tape_event(pc),a0
 move.w (a3)+,ie_Code(a0)
 cmp.w #$ffff,ie_Code(a0)
 bne.s .key
 bsr tape_replay_select
 bra.s .next
.key:
 clr.w ie_Qualifier(a0)
 lea tape_io(pc),a1
 jsr _LVODoIO(a6)
.wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 subq.w #1,d2
 bne.s .wait
 bra.s .next
tape_scenario_done:
 rts
tape_scenario_keys:
 dc.w 10,$cc ; release acceleration
 dc.w 10,$45 ; Escape ends driving through the native handler
 dc.w 200,$c5
 dc.w 1,$ffff ; acknowledge selection of rewind
 dc.w 500,$44,100,$c4
 dc.w 3,$ffff ; acknowledge selection of play
 dc.w 10,$44,500,$c4
 dc.w 0

; The native replay selection is a4-$74c1. Release each navigation key as
; soon as the game acknowledges it; timed short presses can be missed.
tape_replay_select:
 move.w d2,d4
 moveq #15,d7
.select:
 move.l tape_a4(pc),a0
 moveq #0,d5
 move.b -$74c1(a0),d5
 cmp.w d4,d5
 beq.s .done
 cmp.w #8,d5
 bhi.s tape_scenario_failed
 lea tape_seek_play(pc),a1
 cmp.w #1,d4
 bne.s .table
 lea tape_seek_rewind(pc),a1
.table:
 moveq #0,d6
 move.b (a1,d5.w),d6
 lea tape_event(pc),a0
 move.w d6,ie_Code(a0)
 clr.w ie_Qualifier(a0)
 lea tape_io(pc),a1
 jsr _LVODoIO(a6)
 move.w #300,d2
.ack:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 move.l tape_a4(pc),a0
 cmp.b -$74c1(a0),d5
 bne.s .release
 dbra d2,.ack
 bra.s tape_scenario_failed
.release:
 or.w #$80,d6
 lea tape_event(pc),a0
 move.w d6,ie_Code(a0)
 lea tape_io(pc),a1
 jsr _LVODoIO(a6)
 moveq #29,d2
.release_wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 dbra d2,.release_wait
 dbra d7,.select
 bra.s tape_scenario_failed
.done:
 rts
tape_scenario_failed:
 lea tape_scenario_failed(pc),a0
 adda.l #perf_failure-tape_scenario_failed,a0
 move.l #7,(a0)
 illegal
 bra.s tape_scenario_failed
tape_seek_rewind:
 dc.b $4f,0,$4d,$4d,$4d,$4d,$4d,$4e,$4e
tape_seek_play:
 dc.b $4c,$4c,$4f,0,$4e,$4e,$4e,$4e,$4e
 EVEN
 ENDC

; Selecting a simulation mode during a race changes the next race only.
; Acknowledge the notice, open replay/Menu, and choose Re-start Driving.
tape_restart_simulation:
 IFD TAPE_OPPONENT
 bsr tape_restart_acknowledged
 bra .verify
 ENDC
 lea tape_restart_keys(pc),a3
.next:
 move.w (a3)+,d2
 beq.s .verify
 move.w (a3)+,d0
 bsr.s tape_setup_key
 bra.s .next
.verify:
 move.w #5000,d2
.wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 move.l tape_a4(pc),a0
 tst.b $45(a0)
 bne.s .retry
 cmp.w #TAPE_SIMULATION,-$15fa(a0)
 bne.s .retry
 cmp.b #TAPE_SIMULATION,-$173a(a0)
 beq.s tape_simulation_ready
.retry:
 dbra d2,.wait
 lea tape_simulation_ready(pc),a0
 adda.l #perf_failure-tape_simulation_ready,a0
 move.l #8,(a0)
 illegal
 bra.s .retry
tape_simulation_ready:
 rts

tape_setup_key:
 lea tape_event(pc),a0
 move.w d0,ie_Code(a0)
 clr.w ie_Qualifier(a0)
 lea tape_io(pc),a1
 jsr _LVODoIO(a6)
.wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 subq.w #1,d2
 bne.s .wait
 rts

tape_restart_keys:
 dc.w 20,$44,100,$c4 ; acknowledge simulation notice
 dc.w 20,$45,200,$c5 ; end race, show replay panel
 dc.w 20,$44,100,$c4 ; activate Menu
 dc.w 20,$4d,50,$cd  ; Re-start Driving (disabled Evaluation is skipped)
 dc.w 20,$44,500,$c4
 dc.w 0

 IFD TAPE_PIXELS
; Pixel validation only: finish the native final DMA before taking a snapshot.
; The production drawer can return while its last plane is still being written.
tape_draw_complete:
 jsr -$7f62(a4) ; original primitive drawer call at game:$20c3a
 movem.l d0-d1/a0-a1/a6,-(sp)
 move.l tape_gfx_base(pc),a6
 jsr _LVOWaitBlit(a6)
tape_pixels_ready:
 movem.l (sp)+,d0-d1/a0-a1/a6
 clr.w -2(a5) ; displaced original instruction at game:$20c3e
 rts
tape_gfx_base:
 dc.l 0
 ENDC

 IFD TAPE_OPPONENT
 IFLE TAPE_OPPONENT
 FAIL "TAPE_OPPONENT must be 1..6"
 ENDC
 IFGT TAPE_OPPONENT-6
 FAIL "TAPE_OPPONENT must be 1..6"
 ENDC
; Read-only menu observations. Selection, opponent identity, car loading and
; race initialization still run through the original game and input.device.
tape_opponent_main_observe:
 move.l a0,-(sp)
 lea tape_opponent_ui(pc),a0
 move.b -2(a5),1(a0)
 move.b -$174a(a4),2(a0)
 move.b #1,(a0)
 move.l (sp)+,a0
 move.b -2(a5),d0
 cmp.b -3(a5),d0
 rts
tape_opponent_menu_observe:
 move.l a0,-(sp)
 lea tape_opponent_ui(pc),a0
 move.b -10(a5),1(a0)
 move.b -$174a(a4),2(a0)
 move.b #2,(a0)
 move.l (sp)+,a0
 move.b -$174a(a4),d0
 cmp.b -12(a5),d0
 rts

; Main menu selection2 opens opponents. Opponent selection1 is Next,
; selection4 is Done. Observe acknowledgement after each ordinary key press.
tape_opponent_route:
 lea tape_opponent_ui(pc),a2
.intro:
 cmp.b #1,(a2)
 beq .main
 bsr .enter
 bra .intro
.main:
 moveq #2,d4
 bsr .select
 bsr .enter
 move.w #299,d7
.wait_opponent:
 cmp.b #2,(a2)
 beq .opponent
 bsr .field
 dbra d7,.wait_opponent
 addq.l #1,4(a2)
 bsr .enter
 move.w #299,d7
 bra .wait_opponent
.opponent:
 cmp.b #TAPE_OPPONENT,2(a2)
 beq .finish
 moveq #1,d4
 bsr .select
 move.b 2(a2),d5
 bsr .enter
 move.w #299,d7
.wait_identity:
 cmp.b 2(a2),d5
 bne .opponent
 bsr .field
 dbra d7,.wait_identity
 addq.l #1,4(a2)
 bsr .enter
 move.w #299,d7
 bra .wait_identity
.finish:
 moveq #4,d4
 bsr .select
 bsr .enter
 move.w #299,d7
.wait_main:
 cmp.b #1,(a2)
 beq .done
 bsr .field
 dbra d7,.wait_main
 addq.l #1,4(a2)
 bsr .enter
 move.w #299,d7
 bra .wait_main
.done:
 move.b #1,3(a2)
 rts
.select:
 cmp.b 1(a2),d4
 beq .selected
 move.b 1(a2),d5
 move.w #$4f,d6 ; Left: native menu navigation, unlike Ctrl-G Down
 move.w d6,d0
 moveq #1,d2
 bsr .key
 move.w #299,d7
.wait_selection:
 cmp.b 1(a2),d5
 bne .release_selection
 bsr .field
 dbra d7,.wait_selection
 addq.l #1,4(a2)
.release_selection:
 move.w d6,d0
 or.w #RAW_UP,d0
 moveq #30,d2
 bsr .key
 bra .select
.selected:
 rts
.enter:
 move.w #RAW_RETURN,d0
.press:
 move.w d0,d3
 moveq #5,d2
 bsr .key
 move.w d3,d0
 or.w #RAW_UP,d0
 moveq #25,d2
.key:
 lea tape_event(pc),a0
 move.b #IECLASS_RAWKEY,ie_Class(a0)
 move.w d0,ie_Code(a0)
 clr.w ie_Qualifier(a0)
 lea tape_keys_sent(pc),a1
 addq.l #1,(a1)
 lea tape_io(pc),a1
 move.w #IND_WRITEEVENT,IO_COMMAND(a1)
 move.l a0,IO_DATA(a1)
 move.l #ie_SIZEOF,IO_LENGTH(a1)
 jsr _LVODoIO(a6)
.wait:
 bsr .field
 subq.w #1,d2
 bne .wait
 rts
.field:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 move.l a0,-(sp)
 lea tape_fields(pc),a0
 addq.l #1,(a0)
 move.l (sp)+,a0
 rts
 even
 dc.b "4DOPPUI!"
 dc.w 2,TAPE_OPPONENT
tape_opponent_ui: dc.b 0,0,0,0 ; menu,selection,identity,route complete
 dc.l 0 ; retry count
 even
 ENDC

 IFD TAPE_OPPONENT
; Observe only the native Replay Menu invocation of the generic popup. The
; saved return address belongs to its original caller, independent of our hook.
tape_restart_observe:
 move.l a0,-(sp)
 move.l tape_game(pc),a0
 adda.l #$9ce4,a0
 cmpa.l 4(a5),a0
 bne.s .original
 lea tape_restart_ui(pc),a0
 move.b -$c1(a5),1(a0)
 move.b #1,(a0)
.original:
 move.l (sp)+,a0
 move.b -$c1(a5),d0
 cmp.b -$c2(a5),d0
 rts
tape_restart_result:
 move.l a0,-(sp)
 lea tape_restart_ui(pc),a0
 move.b -12(a5),2(a0)
 move.b #1,3(a0)
 move.l (sp)+,a0
 move.b -12(a5),d0
 ext.w d0
 rts

; Opponent redraw can outlast the old fixed key windows. Wait for real menu
; acknowledgement; never write a selector, restart state or replay cursor.
tape_restart_acknowledged:
 lea tape_restart_ui(pc),a2
 clr.l (a2)
 move.w #$44,d0
 moveq #20,d2
 bsr tape_setup_key
 move.w #$c4,d0
 moveq #100,d2
 bsr tape_setup_key
 move.w #$45,d0
 moveq #20,d2
 bsr tape_setup_key
 move.w #$c5,d0
 move.w #200,d2
 bsr tape_setup_key
 moveq #9,d6
.open:
 move.w #$44,d0
 moveq #20,d2
 bsr tape_setup_key
 move.w #$c4,d0
 move.w #200,d2
 bsr tape_setup_key
 tst.b (a2)
 bne.s .navigate
 dbra d6,.open
 bra .failed
.navigate:
 cmp.b #2,1(a2)
 beq.s .accept
 move.w #$4d,d0
 moveq #1,d2
 bsr tape_setup_key
 move.w #999,d7
.wait_selection:
 cmp.b #2,1(a2)
 beq.s .release
 bsr .field
 dbra d7,.wait_selection
 bra .failed
.release:
 move.w #$cd,d0
 moveq #30,d2
 bsr tape_setup_key
.accept:
 moveq #9,d6
.retry_accept:
 ; Native $194C6 waits for key release before the popup returns its choice.
 move.w #$44,d0
 moveq #20,d2
 bsr tape_setup_key
 move.w #$c4,d0
 moveq #100,d2
 bsr tape_setup_key
 tst.b 3(a2)
 bne.s .accepted
 dbra d6,.retry_accept
 bra .failed
.accepted:
 move.w #$c4,d0
 move.w #500,d2
 bsr tape_setup_key
 cmp.b #2,2(a2)
 bne.s .failed
 rts
.field:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 rts
.failed:
 lea tape_restart_ui(pc),a0
 adda.l #perf_failure-tape_restart_ui,a0
 move.l #8,(a0)
 illegal
 bra.s .failed
 even
 dc.b "4DRSTUI!"
 dc.w 1,4
tape_restart_ui: dc.b 0,0,0,0 ; ready,selection,result,returned
 ENDC

 IFD SIM_RESTART_FIXTURE
 IFND SIM_SCHEDULE
 FAIL "SIM_RESTART_FIXTURE requires SIM_SCHEDULE"
 ENDC
; Let a real live scheduler accumulate/consume inputs, then restart entirely
; through the existing keyboard route. No mode, selector or history writes.
tape_live_restart_fixture:
.wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 move.l tape_a4(pc),a0
 cmp.w #80,-$940(a0)
 blo.s .wait
 lea tape_restart_keys(pc),a3
.next:
 move.w (a3)+,d2
 beq.s .done
 move.w (a3)+,d0
 bsr tape_setup_key
 bra.s .next
.done:
 rts
 ENDC

 IFD SIM_MODAL_FIXTURE
 IFND SIM_SCHEDULE
 FAIL "SIM_MODAL_FIXTURE requires SIM_SCHEDULE"
 ENDC
; Open Ctrl-G during a real race, hold it for 100 fields, then leave by Escape.
; Reuse the established input.device Ctrl-G route and its key qualifiers.
tape_live_modal_fixture:
.wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 move.l tape_a4(pc),a0
 cmp.w #80,-$940(a0)
 blo.s .wait
 lea tape_dialog_ready(pc),a0
 clr.l (a0)
 moveq #0,d3
 lea tape_modal_keys(pc),a3
 bsr tape_menu_keys
 rts
 even
tape_modal_keys:
 dc.w 5,$63,IEQUALIFIER_CONTROL
 dc.w 5000,$24,IEQUALIFIER_CONTROL ; hold until native dialog acknowledgement
 dc.w 5,$a4,IEQUALIFIER_CONTROL
 dc.w 100,$e3,0            ; release Control, leave the dialog open
 dc.w 20,$45,0,30,$c5,0    ; Escape and release
 dc.w 0
 ENDC

 IFD SIM_MODE_MENU
; Each menu skips its checked graphics/mode rows. Start at the first unchecked
; entry and count only selectable rows preceding the compile-time target.
tape_mode_select:
 move.w d2,-(sp)
 moveq #5,d4
 IFEQ TAPE_SIMULATION-20
 moveq #6,d4
 ENDC
 IFEQ TAPE_SIMULATION-50
 moveq #7,d4
 ENDC
 moveq #5,d5
 cmp.w #10,-$bc(a1)
 beq .current
 moveq #6,d5
 cmp.w #20,-$bc(a1)
 beq .current
 moveq #7,d5
.current:
 cmp.w d4,d5
 bhs .graphics
 subq.w #1,d4
.graphics:
 subq.w #1,d4
.down:
 move.w #$4d,d0
 moveq #10,d2
 bsr tape_setup_key
 move.w #$cd,d0
 moveq #30,d2
 bsr tape_setup_key
 subq.w #1,d4
 bne .down
 lea tape_event(pc),a0
 move.w #RAW_RETURN,ie_Code(a0)
 clr.w ie_Qualifier(a0)
 move.w (sp)+,d2
 rts
 ENDC

 IFD SIM_LIVE_INPUT_TEST
 IFND SIM_MANUAL
 FAIL "SIM_LIVE_INPUT_TEST requires the manual input path"
 ENDC
; One-shot acceptance driver. These are ordinary input.device key events;
; no native input-history bytes or physical state are written by this test.
tape_live_input_test:
 moveq #0,d0
 bsr tape_live_input_sample
 move.w #$4c,d0
 move.w #100,d2
 bsr tape_setup_key
 moveq #1,d0
 bsr tape_live_input_sample
 move.w #$cc,d0
 move.w #100,d2
 bsr tape_setup_key
 moveq #2,d0
 bsr tape_live_input_sample
 lea tape_live_input_phase(pc),a0
 move.w #3,(a0)
 rts
; Each record: fields.L, produced.W, consumed.W, speed.W, rate.W, X.L, Z.L.
tape_live_input_sample:
 movem.l d0-d2/a0-a2,-(sp)
 lea tape_live_input_phase(pc),a0
 move.w d0,(a0)
 mulu #20,d0
 lea tape_live_input_records(pc),a2
 adda.l d0,a2
 lea tape_live_input_sample(pc),a0
 adda.l #sim_clock_fields-tape_live_input_sample,a0
 move.l (a0),(a2)+
 movea.l tape_a4(pc),a1
 move.w $a0(a1),(a2)+
 move.w -$940(a1),(a2)+
 move.w -$902(a1),(a2)+
 move.w -$15fa(a1),(a2)+
 move.l -$92e(a1),(a2)+
 move.l -$926(a1),(a2)+
 movem.l (sp)+,d0-d2/a0-a2
 rts
 even
 dc.b "4DLIVET!"
 dc.w 1,20
tape_live_input_phase: dc.w 0
 dc.w 0
tape_live_input_records: dcb.b 60,0
 ENDC

 IFD SIM_REPLAY_LOAD_ERROR_TEST
; Wait for the native loader error, leave it visible, then acknowledge through
; the ordinary input.device path. Main-task file code never manufactures keys.
tape_replay_error_ack:
.wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 lea tape_replay_error_ack(pc),a0
 adda.l #sim_replay_menu_status-tape_replay_error_ack,a0
 tst.l (a0)
 beq .wait
 move.w #100,d2
.hold:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 subq.w #1,d2
 bne .hold
 move.w #$44,d0
 moveq #10,d2
 bsr tape_setup_key
 move.w #$c4,d0
 moveq #10,d2
 bsr tape_setup_key
 rts
 ENDC
