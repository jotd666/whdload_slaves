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
 cmp.w #10,-$bc(a0)
 beq.s .done
 lea tape_dialog_ready(pc),a0
 clr.l (a0)
 moveq #1,d3
 lea tape_simulation_keys(pc),a3
 bra.s tape_menu_keys
.done:
 rts
tape_menu_keys:
.next:
 move.w (a3)+,d2
 beq.s .done
 lea tape_event(pc),a0
 move.w (a3)+,ie_Code(a0)
 move.w (a3)+,ie_Qualifier(a0)
 ; The menu skips checked entries. When FULL is already checked (notably on
 ; 68020), Return would select the next level and reduce detail.
 cmp.w #RAW_RETURN,ie_Code(a0)
 bne.s .send
 move.l tape_a4(pc),a1
 tst.w d3
 bne.s .normal_before
 tst.b -$7708(a1)
 beq.s .next
 bra.s .send
.normal_before:
 cmp.w #10,-$bc(a1)
 beq.s .next
.send:
 lea tape_io(pc),a1
 jsr _LVODoIO(a6)
.wait:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 lea tape_event(pc),a0
 cmp.w #$24,ie_Code(a0)
 bne.s .selection
 move.l tape_dialog_ready(pc),d0
 bne.s .next
 bra.s .timed
.selection:
 cmp.w #RAW_RETURN,ie_Code(a0)
 bne.s .timed
 move.l tape_a4(pc),a0
 tst.w d3
 bne.s .normal_after
 tst.b -$7708(a0)
 beq.s .next
 bra.s .timed
.normal_after:
 cmp.w #10,-$bc(a0)
 beq.s .next
.timed:
 subq.w #1,d2
 bne.s .wait
 bra.s .next
.done:
 rts
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

; FULL is checked, so the dialog starts on entry 1. Four cursor-down presses
; reach Normal (entry 5). This sequence is only needed for the 68020 default.
tape_simulation_keys:
 dc.w 5,$63,IEQUALIFIER_CONTROL
 dc.w 5000,$24,IEQUALIFIER_CONTROL
 dc.w 5,$a4,IEQUALIFIER_CONTROL
 dc.w 200,$e3,0
 REPT 4
 dc.w 10,$4d,0
 dc.w 30,$cd,0
 ENDR
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
