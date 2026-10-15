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
	PL_PSS	$19fac,verify_vbl,2	; VERTB, replaces pl_v1's vbl_hook patch
	PL_PSS	$19fc4,verify_blit,2	; blitter interrupt acknowledge
	PL_P	$1bd46,verify_wait	; frame wait
	PL_END

VERIFY_FRAMES = 2048			; frame log entries

; The harness finds this block in memory by its marker and reads it at the end of a run.
verify_block
	dc.b	"POPVERIFY",0
verify_steps
	dc.l	0			; control polls so far (gameplay steps)
verify_tape
	dc.l	0			; current tape entry, 0 = not started
verify_stop
	dc.l	0			; the harness breaks at verify_stopped on this step
verify_fields
	dc.l	0			; VERTB interrupts
verify_blits
	dc.l	0			; blitter interrupts (one per blit started by g:$53a2/$53d6)
verify_frames
	dc.l	0			; frame log entries written
verify_last
	dc.l	0			; time of the last frame-wait exit (lines)
verify_last_blits
	dc.l	0
verify_log_at
	dc.l	verify_log-verify_block	; offset of the frame log

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

;---------------------------------------------------------------------------
; Frame-time log (plan step A3). Time is in raster lines, fields*313 + VPOS. Each frame
; wait exit appends (step, period, work, blits): lines since the previous exit, lines
; of that spent before entering the wait, and blitter interrupts since the previous exit.
; The display swap is in the VBL that ends the wait, so period/313 is a whole number of
; fields up to the VBL handler's latency.

verify_vbl
	move.l	a0,-(a7)
	lea	verify_fields(pc),a0
	addq.l	#1,(a0)
	move.l	(a7)+,a0
	bra	vbl_hook

verify_blit
	move.w	#$40,_custom+intreq	; original
	move.l	a0,-(a7)
	lea	verify_blits(pc),a0
	addq.l	#1,(a0)
	move.l	(a7)+,a0
	rts

; > d0 now in lines (d1 trashed)
verify_time
	move.w	sr,-(a7)
	move.w	#$2700,sr
.again
	move.w	_custom+intreqr,d1
	move.l	_custom+vposr,d0
	cmp.w	_custom+intreqr,d1
	bne.b	.again
	lsr.l	#8,d0
	and.l	#$1ff,d0
	btst	#5,d1			; VERTB not yet taken: its field has started
	beq.b	.counted
	add.l	#313,d0
.counted
	move.l	d1,-(a7)
	move.l	verify_fields(pc),d1
	mulu	#313,d1
	add.l	d1,d0
	move.l	(a7)+,d1
	move.w	(a7)+,sr
	rts

; replaces g:$1bd46: link a6,#0 / clr.b d0 / wait for the VBL to take the new frame /
; unlk a6 / rts. Leaves d0 (low byte cleared) and a0 as the original does.
verify_wait
	movem.l	d0-d2/a1,-(a7)
	bsr	verify_time
	move.l	d0,d2
	lea	$49d18,a0
.wait
	tst.l	(a0)
	bne.b	.wait
verify_wait_end
	bsr	verify_time
	lea	verify_frames(pc),a1
	move.l	(a1),d1
	cmp.l	#VERIFY_FRAMES,d1
	bhs.b	.full
	addq.l	#1,(a1)
	lsl.l	#3,d1
	lea	verify_log(pc),a1
	add.l	d1,a1
	move.w	verify_steps+2(pc),(a1)+
	move.l	d0,d1
	sub.l	verify_last(pc),d1
	move.w	d1,(a1)+		; period
	sub.l	verify_last(pc),d2
	move.w	d2,(a1)+		; work
	move.l	verify_blits(pc),d1
	sub.l	verify_last_blits(pc),d1
	move.w	d1,(a1)+
.full
	lea	verify_last(pc),a1
	move.l	d0,(a1)+
	move.l	verify_blits(pc),(a1)
	movem.l	(a7)+,d0-d2/a1
	clr.b	d0
	lea	$49d18,a0
	rts

verify_log
	ds.b	VERIFY_FRAMES*8
