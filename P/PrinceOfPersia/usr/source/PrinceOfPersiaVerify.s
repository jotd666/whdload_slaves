;*---------------------------------------------------------------------------
;  :Contents.	VERIFY-only measurement instruments for Prince of Persia,
;		version 1 (UK) only. Not part of normal builds.
;---------------------------------------------------------------------------*

; runtime address of original (patch list) address \1 in \2
GAME_ADDR:MACRO
	move.l	_reloc_base(pc),\2
	add.l	#\1-$1000,\2
	ENDM

pl_verify_v1
	PL_START
	PL_P	$1942c,verify_poll	; control poll, once per gameplay step
	PL_P	$1b8bc,verify_joy	; joystick reader
	PL_END

; The harness finds this block in memory by its marker and reads it at the end of a run.
verify_block
	dc.b	"POPVERIFY",0
verify_steps
	dc.l	0			; control polls so far (gameplay steps)
verify_tape
	dc.l	0			; current tape entry, 0 = not started
verify_stop
	dc.l	0			; the harness breaks at verify_stopped on this step

;---------------------------------------------------------------------------
; Input tape (plan step A2). CUSTOM4=n plays tape n: the game's joystick reader
; returns the tape's mask for the current step instead of reading port 1, so input
; lands on the same gameplay step on every machine. CUSTOM4=0 reads the real
; joystick. Masks are the reader's own: 1 up, 2 down, 4 left, 8 right, 16 fire;
; TAPE_RESUME is fire for the pause loop only (g:$1958a, "press button"), so it ends a
; pause without reaching the game's controls.

; replaces g:$1942c link a6,#0 / jsr g:$1b8bc
verify_poll
	lea	verify_steps(pc),a0
	addq.l	#1,(a0)
	move.l	(a0),d0
	cmp.l	verify_stop(pc),d0
	bne.b	verify_run
verify_stopped
	nop
verify_run
	link	a6,#0
	bsr.b	verify_joy
	GAME_ADDR	$19436,a0
	jmp	(a0)

; replaces g:$1b8bc link a6,#0 / movem.l d2,-(sp); > d0 mask
verify_joy
	move.l	verify_tape(pc),d0
	bne.b	.play
	move.l	verify_tape_number(pc),d0
	beq.b	.live
	lea	verify_tapes(pc),a0
	add.w	d0,d0
	add.w	(-2,a0,d0.w),a0
	move.l	a0,d0
.play
	move.l	d0,a0
	move.l	verify_steps(pc),d1
.next
	cmp.w	(4,a0),d1		; entries are (first step, mask); last step $ffff
	blo.b	.got
	addq.l	#4,a0
	bra.b	.next
.got
	lea	verify_tape(pc),a1
	move.l	a0,(a1)
	moveq	#0,d0
	move.w	(2,a0),d0
	bclr	#TAPE_RESUME_BIT,d0
	beq.b	.out
	; resume is fire for the pause loop's button check only
	GAME_ADDR	$195a8,a0
	cmp.l	(a7),a0
	bne.b	.out
	or.w	#TAPE_FIRE,d0
.out
	rts
.live
	link	a6,#0
	movem.l	d2,-(sp)
	GAME_ADDR	$1b8c4,a0
	jmp	(a0)

TAPE_UP = 1
TAPE_DOWN = 2
TAPE_LEFT = 4
TAPE_RIGHT = 8
TAPE_FIRE = 16
TAPE_RESUME_BIT = 5
TAPE_RESUME = 1<<TAPE_RESUME_BIT

verify_tapes
	dc.w	tape_spikes-verify_tapes

; Level 1 from the first gameplay step: run right, drop to the lower floor, stop on the
; loose plate and fall with it, run left, climb the ledge, run left into the spike pit.
; Step 1 is the title, paused: fire skips the intro, and the game pauses again at step 2.
tape_spikes
	dc.w	0,0
	dc.w	1,TAPE_FIRE|TAPE_RESUME
	dc.w	2,TAPE_RESUME
	dc.w	3,0
	dc.w	66,TAPE_RIGHT
	dc.w	80,0
	dc.w	88,TAPE_RIGHT
	dc.w	105,0
	dc.w	125,TAPE_LEFT
	dc.w	202,0
	dc.w	205,TAPE_UP
	dc.w	232,0
	dc.w	234,TAPE_LEFT
	dc.w	275,0
	dc.w	$ffff,0
	even
