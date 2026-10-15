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
VOPT_REALTIME = 3			; no gameplay time pin: sounds end in real time
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
	PL_IFC5X	VOPT_REALTIME
	PL_ELSE
	PL_P	$0820c,verify_snd_start	; play_sound_from_buffer
	PL_P	$080e2,verify_snd_stop	; stop_sounds
	PL_P	$08106,verify_snd_playing	; check_sound_playing
	PL_PS	$1a002,verify_audio	; level-4 handler's call of the audio interrupt code
	PL_PS	$19f8a,verify_ciaa_tb	; level-2 handler's CIA-A timer B callback (the MIDI player)
	PL_PS	$19fb4,verify_vbl_game	; level-3 handler's VERTB call of g:$1a0c2 (MIDI voices)
	PL_ENDIF
	PL_END


VERIFY_FRAMES = 2048			; frame log entries
VERIFY_ENTRY = 10			; bytes per entry

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
	dc.l	0			; BLIT acknowledgements (C1 polling removes per-blit interrupts)
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
verify_vclock
	dc.l	0			; virtual time in lines: g:$7aba fields per frame wait
verify_snd_flags
	dc.l	0			; bit 0 a sound is on, bit 1 a frame wait has ended since
verify_snd_t0
	dc.l	0			; real time (lines) when it started
verify_snd_dur
	dc.l	0			; its real length (lines), -1 until it ends
verify_snd_base
	dc.l	0			; verify_vclock at the first frame-wait exit after the start
verify_snd_ret
	dc.l	0			; play_sound_from_buffer's return address

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
; wait exit appends (step, period, work, blits, target): lines since the previous exit, lines
; of that spent before entering the wait, blitter interrupts since the previous exit, and the
; game's own frame time in fields (g:$7aba: 4, or 5 while the kid's sword is drawn).
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
	mulu	#VERIFY_ENTRY,d1
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
	GAME_ADDR	$7aba,a0
	move.w	2(a0),(a1)+		; target
verify_wait_full
	lea	verify_last(pc),a1
	move.l	d0,(a1)+
	move.l	verify_blits(pc),(a1)
	bsr	verify_tick
	movem.l	(a7)+,d0-d2/a1
	clr.b	d0
	lea	$49d18,a0
	rts


;---------------------------------------------------------------------------
; Time pin (plan step B7). After pinning the RNG, the gameplay time dependency found
; on the benchmark routes is check_sound_playing
; (g:$08106, SDLPoP's name): play_next_sound starts a queued sound only once the last one
; has ended, level 1 holds the kid until its opening music ends (need_level1_music), and
; the level start and end wait for sounds. Sounds play in real time, so with slower frames
; they end after fewer frames. The pin answers check_sound_playing from virtual time
; instead: every frame wait counts g:$7aba fields, as if each frame took exactly the
; game's own frame time. A sound started in frame s0 is playing in frame s while its real
; length exceeds the virtual time of the frames that completed in between. The real
; length is measured at the interrupt where the sound ends: the audio interrupt for samples,
; the CIA-A timer B callback for MIDI songs (g:$0865a clears g:$46e7a when the last track
; ends), or the VBL, whose envelopes end the last MIDI notes. Until then the sound is
; playing in virtual time too: gameplay cannot outrun its target field countdown.
; Outside gameplay, retain the real driver answer. Interludes can busy-wait for a sound
; without publishing another frame, so a frame-clock answer there would deadlock. The
; control-poll hook identifies these loops, including the level-2 interlude at step 15.
; This is a PAL verification clock; sound-duration boundary cases and other machines
; still need the D1 matrix. It does not make real-time driver memory deterministic.
; stop_sounds called by the game (not from an interrupt) ends a sound at once. The
; driver itself still plays in real time; its state is excluded from the A4 hashes.

; at each frame-wait exit: advance virtual time; a sound started in the frame gets its base
verify_tick
	GAME_ADDR	$7aba,a0
	move.l	(a0),d1
	mulu	#313,d1
	lea	verify_vclock(pc),a0
	add.l	d1,(a0)
	lea	verify_snd_flags(pc),a0
	bset	#1,3(a0)
	bne.b	.based
	move.l	verify_vclock(pc),verify_snd_base-verify_snd_flags(a0)
.based
	rts

; > Z set if the driver is silent: no MIDI song and all four channels idle (as g:$08106)
verify_snd_idle
	tst.l	$46e7a
	bne.b	.out
	tst.w	$49dde
	bne.b	.out
	tst.w	$49df0
	bne.b	.out
	tst.w	$49e02
	bne.b	.out
	tst.w	$49e14
.out
	rts

; a sound on and not yet ended has just ended in real time: note its length
verify_snd_ended
	movem.l	d0-d1/a0,-(a7)
	lea	verify_snd_flags(pc),a0
	btst	#0,3(a0)
	beq.b	.out
	tst.l	verify_snd_dur-verify_snd_flags(a0)
	bpl.b	.out
	bsr	verify_time
	sub.l	verify_snd_t0(pc),d0
	lea	verify_snd_dur(pc),a0
	move.l	d0,(a0)
.out
	movem.l	(a7)+,d0-d1/a0
	rts

; replaces g:$0820c link a6,#-$20 / movem.l d2-d3/a2,-(sp) (play_sound_from_buffer)
verify_snd_start
	movem.l	d0-d1,-(a7)
	lea	verify_snd_flags(pc),a0
	clr.l	(a0)			; off while the driver stops the last sound
	bsr	verify_time
	lea	verify_snd_t0(pc),a0
	move.l	d0,(a0)
	movem.l	(a7)+,d0-d1
	lea	verify_snd_ret(pc),a0
	move.l	(a7),(a0)
	lea	verify_snd_started(pc),a0
	move.l	a0,(a7)
	link	a6,#-$20
	movem.l	d2-d3/a2,-(sp)
	GAME_ADDR	$08214,a0
	jmp	(a0)
verify_snd_started
	movem.l	d0/a0,-(a7)
	lea	verify_snd_flags(pc),a0
	move.l	#1,(a0)			; on, no frame wait ended yet
	move.l	#-1,verify_snd_dur-verify_snd_flags(a0)
	bsr	verify_snd_idle
	bne.b	.on
	clr.l	verify_snd_dur-verify_snd_flags(a0)	; nothing played: length 0
.on
	movem.l	(a7)+,d0/a0
	move.l	verify_snd_ret(pc),-(a7)
	rts

; replaces g:$080e2 link a6,#0 / pea 1.w (stop_sounds)
verify_snd_stop
	move.w	sr,d0
	and.w	#$700,d0
	bne.b	.interrupt
	lea	verify_snd_flags(pc),a0
	clr.l	(a0)			; the game stopped it
	bra.b	.go
.interrupt
	bsr	verify_snd_ended	; the driver ended it: its natural end
.go
	link	a6,#0
	pea	1.w
	GAME_ADDR	$080ea,a0
	jmp	(a0)

; replaces g:$08106 (check_sound_playing); > d0 1 if a sound is playing in virtual time
verify_snd_playing
	; Non-gameplay polls do not advance the tape and may not call verify_wait.
	move.l	verify_gameplay(pc),d0
	bne.b	.pinned
	moveq	#0,d0
	bsr	verify_snd_idle
	beq.b	.real_idle
	moveq	#1,d0
.real_idle
	rts
.pinned
	lea	verify_snd_flags(pc),a0
	moveq	#0,d0
	btst	#0,3(a0)
	beq.b	.out
	moveq	#1,d0
	move.l	verify_snd_dur(pc),d1
	bmi.b	.out			; still playing in real time
	btst	#1,3(a0)
	beq.b	.same			; started in this frame: no virtual time has passed
	move.l	verify_vclock(pc),a0
	sub.l	verify_snd_base(pc),a0
	cmp.l	a0,d1
	bgt.b	.out
	moveq	#0,d0
	rts
.same
	tst.l	d1
	bgt.b	.out
	moveq	#0,d0
.out
	rts

; replace the level-4 handler's jsr g:$1b1fe, the level-2 handler's jsr g:$1a6ac and the
; level-3 handler's jsr g:$1a0c2(pc) / nop (all saved d0-d1/a0-a1)
verify_vbl_game
	GAME_ADDR	$1a0c2,a0
	bra.b	verify_int
verify_ciaa_tb
	GAME_ADDR	$1a6ac,a0
	bra.b	verify_int
verify_audio
	GAME_ADDR	$1b1fe,a0
verify_int
	jsr	(a0)
	bsr	verify_snd_idle
	bne.b	.out
	bra	verify_snd_ended
.out
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