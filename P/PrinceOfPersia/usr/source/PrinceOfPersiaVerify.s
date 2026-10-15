;*---------------------------------------------------------------------------
;  :Contents.	VERIFY-only measurement instruments for Prince of Persia,
;		version 1 (UK) only. Not part of normal builds.
;---------------------------------------------------------------------------*

; runtime address of original (patch list) address \1 in \2
GAME_ADDR:MACRO
	move.l	_reloc_base(pc),\2
	add.l	#\1-$1000,\2
	ENDM

; CUSTOM5 bits (timing and sabotage probes for A4's faithfulness checks)
VOPT_DELAY_WORK = 0			; an extra VBL at each gameplay step's start, before the frame
					; is published: changes the frame times that the game sees
VOPT_DELAY = 1				; an extra VBL before each frame wait, after publishing
VOPT_SABOTAGE = 2			; skip one g:$53d6 blit at step SABOTAGE_STEP
SABOTAGE_STEP = 150

pl_verify_v1
	PL_START
	PL_P	$1942c,verify_poll	; control poll, once per gameplay step
	PL_P	$1b8bc,verify_joy	; joystick reader
	PL_PSS	$19fac,verify_vbl,2	; VERTB, replaces pl_v1's vbl_hook patch
	PL_PSS	$19fc4,verify_blit,2	; blitter interrupt acknowledge
	PL_P	$1bd46,verify_wait	; frame wait
	; RNG entropy: g:$1ba58 adds VHPOSR to the seed (level start, fire); add 0 instead
	PL_W	$1ba5e,$7000		; moveq #0,d0
	PL_NOP	$1ba60,4
	PL_IFC5X	VOPT_SABOTAGE		; patched only for the probe: it costs time on every blit
	PL_P	$53d6,verify_blit_start	; blit start + STOP wait
	PL_ENDIF
	PL_END


VERIFY_FRAMES = 2048			; frame log entries
VERIFY_ENTRY = 8			; bytes per entry

; The harness finds this block in memory by its marker and reads it at the end of a run.
verify_block
	dc.b	"POPVERIFY",0
verify_steps
	dc.l	0			; control polls so far (gameplay steps)
verify_tape
	dc.l	0			; current tape entry, 0 = not started
verify_stop
	dc.l	0			; the harness breaks at verify_stopped on this step
verify_gameplay
	dc.l	0			; -1 while the last control poll was a gameplay step
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
verify_sabotaged
	dc.l	0			; set once the sabotage blit has been skipped

;---------------------------------------------------------------------------
; Input tape (plan step A2). CUSTOM4=n plays tape n: the game's joystick reader
; returns the tape's mask for the current step instead of reading port 1, so input
; lands on the same gameplay step on every machine. CUSTOM4=0 reads the real
; joystick. A step is a control poll from gameplay (g:$13de2, once per frame); the title,
; intro and interludes poll in busy loops, as often as time allows, and don't count.
; Masks are the reader's own: 1 up, 2 down, 4 left, 8 right, 16 fire, for gameplay polls.
; Other polls get fire if the entry has TAPE_SKIP or TAPE_LEVEL, which skips the title and
; the interludes. TAPE_RESUME is fire for the pause loop only (g:$1958a, "press button"),
; so it ends a pause without reaching the controls. TAPE_LEVEL+n requests level n, as the
; level skip does; hold it for one step.

; replaces g:$1942c link a6,#0 / jsr g:$1b8bc (a6 is g:$18df4's frame)
verify_poll
	lea	verify_gameplay(pc),a0
	clr.l	(a0)
	GAME_ADDR	$13e20,a1	; return address of the gameplay call of g:$18df4
	cmp.l	4(a6),a1
	bne.b	verify_run
	st	(a0)
	btst	#VOPT_DELAY_WORK,verify_options+3(pc)
	beq.b	.nodelay
	move.l	verify_fields(pc),d0
.delay
	cmp.l	verify_fields(pc),d0
	beq.b	.delay
.nodelay
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
	beq.w	.live
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
	bclr	#TAPE_LEVEL_BIT,d0
	beq.b	.nolevel
	move.l	d0,$47ab8		; the level the main loop is to play, as the level skip sets it
	moveq	#TAPE_SKIP,d0
.nolevel
	tst.l	verify_gameplay-verify_tape(a1)
	bne.b	.gameplay
	and.w	#TAPE_SKIP|TAPE_RESUME,d0
	bclr	#TAPE_SKIP_BIT,d0
	beq.b	.resume
	or.w	#TAPE_FIRE,d0
	bra.b	.resume
.gameplay
	and.w	#$1f|TAPE_RESUME,d0
.resume
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
TAPE_SKIP_BIT = 6
TAPE_SKIP = 1<<TAPE_SKIP_BIT
TAPE_LEVEL_BIT = 15
TAPE_LEVEL = 1<<TAPE_LEVEL_BIT		; TAPE_LEVEL+n: go to level n, no input

verify_tapes
	dc.w	tape_spikes-verify_tapes
	dc.w	tape_explore-verify_tapes
	dc.w	tape_guard-verify_tapes
	dc.w	tape_palace-verify_tapes
	dc.w	tape_idle-verify_tapes

; Level 1 from the first gameplay step: run right, drop to the lower floor, stop on the
; loose plate and fall with it, run left, climb the ledge, run left into the spike pit.
; The title starts paused: resume and skip it. The game pauses again at step 1.
tape_spikes
	dc.w	0,TAPE_SKIP|TAPE_RESUME
	dc.w	1,TAPE_RESUME
	dc.w	2,0
	dc.w	65,TAPE_RIGHT
	dc.w	79,0
	dc.w	87,TAPE_RIGHT
	dc.w	104,0
	dc.w	124,TAPE_LEFT
	dc.w	201,0
	dc.w	204,TAPE_UP
	dc.w	231,0
	dc.w	233,TAPE_LEFT
	dc.w	274,0
	dc.w	$ffff,0

; Mapping aid: level EXPLORE_LEVEL from step 10, then no input (a zero mask lets the game
; read the keyboard, so the harness can drive the keypad).
	IFND	EXPLORE_LEVEL
EXPLORE_LEVEL = 2
	ENDC
tape_explore
	dc.w	0,TAPE_SKIP|TAPE_RESUME
	dc.w	1,TAPE_RESUME
	dc.w	2,0
	dc.w	10,TAPE_LEVEL+EXPLORE_LEVEL
	dc.w	11,TAPE_RESUME
	dc.w	12,0
	dc.w	$ffff,0

; Level 2's first guard: run left into the next room, stop short of the guard, then
; strike (fire) twice and block (up) once, every 10 steps. The fight runs from step 90
; until the guard kills the kid at about step 218.
tape_guard
	dc.w	0,TAPE_SKIP|TAPE_RESUME
	dc.w	1,TAPE_RESUME
	dc.w	2,0
	dc.w	10,TAPE_LEVEL+2
	dc.w	11,TAPE_RESUME
	dc.w	12,0
	dc.w	45,TAPE_LEFT
	dc.w	84,0
	dc.w	92,TAPE_FIRE
	dc.w	94,0
	dc.w	102,TAPE_FIRE
	dc.w	104,0
	dc.w	112,TAPE_UP
	dc.w	114,0
	dc.w	122,TAPE_FIRE
	dc.w	124,0
	dc.w	132,TAPE_FIRE
	dc.w	134,0
	dc.w	142,TAPE_UP
	dc.w	144,0
	dc.w	152,TAPE_FIRE
	dc.w	154,0
	dc.w	162,TAPE_FIRE
	dc.w	164,0
	dc.w	172,TAPE_UP
	dc.w	174,0
	dc.w	182,TAPE_FIRE
	dc.w	184,0
	dc.w	192,TAPE_FIRE
	dc.w	194,0
	dc.w	202,TAPE_UP
	dc.w	204,0
	dc.w	212,TAPE_FIRE
	dc.w	214,0
	dc.w	222,TAPE_FIRE
	dc.w	224,0
	dc.w	232,TAPE_UP
	dc.w	234,0
	dc.w	$ffff,0

; Level 4, the palace: run right into the arcade with a guard, then back left through two
; rooms and down a level (three room changes by step 200). Timing only: the level start
; takes a timing-dependent path (g:$b882), so its state is not comparable across timings.
tape_palace
	dc.w	0,TAPE_SKIP|TAPE_RESUME
	dc.w	1,TAPE_RESUME
	dc.w	2,0
	dc.w	10,TAPE_LEVEL+4
	dc.w	11,TAPE_RESUME
	dc.w	12,0
	dc.w	45,TAPE_RIGHT
	dc.w	100,TAPE_LEFT
	dc.w	200,0
	dc.w	$ffff,0

; The floor case: level 1's first room, no input.
tape_idle
	dc.w	0,TAPE_SKIP|TAPE_RESUME
	dc.w	1,TAPE_RESUME
	dc.w	2,0
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
	btst	#VOPT_DELAY,verify_options+3(pc)
	beq.b	.nodelay
	move.l	verify_fields(pc),d0
.delay
	cmp.l	verify_fields(pc),d0
	beq.b	.delay
.nodelay
	bsr	verify_time
	move.l	d0,d2
	lea	$49d18,a0
verify_wait_loop
	tst.l	(a0)
	bne.b	verify_wait_loop
verify_wait_end
	move.l	verify_steps(pc),d0
	cmp.l	verify_stop(pc),d0
	bne.b	verify_wait_go
verify_wait_stopped			; the harness's breakpoint for a step's frame-wait exit
	nop
verify_wait_go
	bsr	verify_time
	lea	verify_frames(pc),a1
	move.l	(a1),d1
	cmp.l	#VERIFY_FRAMES,d1
	bhs.b	verify_wait_full
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
verify_wait_full
	lea	verify_last(pc),a1
	move.l	d0,(a1)+
	move.l	verify_blits(pc),(a1)
	movem.l	(a7)+,d0-d2/a1
	clr.b	d0
	lea	$49d18,a0
	rts


;---------------------------------------------------------------------------
; Faithfulness probes (plan step A4). The harness hashes state and the published frame at
; verify_wait_stopped, with emulated time stopped: in-slave hashing took ~60 fields per
; frame, and the game itself behaves differently with frames that long. The probes here
; change timing (VOPT_DELAY_WORK, VOPT_DELAY) or break one blit (VOPT_SABOTAGE).

; replaces g:$53d6 move.w sr,g:$53d4 (start a blit, then STOP until its interrupt)
verify_blit_start
	move.w	sr,-(a7)
	move.l	a0,-(a7)
	lea	verify_steps(pc),a0
	cmp.l	#SABOTAGE_STEP,(a0)
	bne.b	.run
	lea	verify_sabotaged(pc),a0
	tst.l	(a0)
	bne.b	.run
	st	(a0)
	move.l	(a7)+,a0		; the blit never starts
	move.w	(a7)+,sr
	rts
.run
	GAME_ADDR	$53d4,a0
	move.w	4(a7),(a0)		; the SR saved on entry
	move.l	(a7)+,a0
	addq.l	#2,a7
	subq.l	#4,a7			; to g:$53dc with every register as on entry
	move.l	a0,-(a7)
	GAME_ADDR	$53dc,a0
	move.l	a0,4(a7)
	move.l	(a7)+,a0
	rts

; verify_log (VERIFY_FRAMES*VERIFY_ENTRY bytes) is at the end of the slave, past the
; areas that the slave reaches PC-relative.