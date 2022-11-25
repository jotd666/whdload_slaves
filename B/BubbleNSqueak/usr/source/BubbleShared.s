IGNORE_JOY_DIRECTIONS
	include	ReadJoyPad.s
	

PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1

	ENDM
	
two_button_test_potgo:
	movem.w	d0,-(a7)
	move.w	(potinp,a6),d0
	; that wasn't done in the original game
	; causing 2 button mode to make button 2 sticky
	; on non-CD32 pad 2-joystick buttons
	move.w	#$FF00,(potgo,A6)
	btst	#$E,d0
	movem.w	(a7)+,d0
	rts
	

_wrongver
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
	rts
	
_emu_copylock:
;	movem.l	A0-A2/D0-D1,-(a7)
;	move.l	_resload(pc),a2
;	moveq	#4,D0
;	lea	$F4,A0
;	jsr	resload_ProtectRead(a2)
;	movem.l	(a7)+,A0-A2/D0-D1

	move.l	#$D8BA5C60,$F4.W
	rts

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

read_joypad_buttons_floppy_dummy
	moveq.l	#0,d3
	rts
	
read_joypad_buttons_floppy
	movem.l	d0/d1,-(a7)
	moveq.l	#0,d3
	moveq.l	#1,d0
	bsr	_read_joystick
	btst	#JPB_BTN_RED,d0
	beq.b	.nofire1
	bset	#5,d3
.nofire1
	btst	#JPB_BTN_BLU,d0
	beq.b	.nojump
	bset	#6,d3
.nojump
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nolookdown
	bset	#2,d3
.nolookdown
	btst	#JPB_BTN_PLAY,d0
	beq.b	.noplay
	bset	#0,d3
.noplay
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nolookup
	bset	#1,d3
.nolookup
	btst	#JPB_BTN_GRN,d0
	beq.b	.nogreen
	bset	#4,d3
.nogreen
	btst	#JPB_BTN_YEL,d0
	beq.b	.noyellow
	bset	#4,d3
.noyellow
	movem.l	(a7)+,d0/d1
	rts
	IFEQ	1
.test_mouse
	bra	.out
	; joystick connected: test mouse buttons for look up & down
	moveq.l	#0,d0
	bsr	_read_joystick

	btst	#JPB_BTN_RED,d0
	beq.b	.nolookup2
	; test if both mouse buttons pressed at the same time for pause
;	btst	#JPB_BTN_BLU,d0
;	beq.b	.nopause
;	bset	#0,d3
;	bra.b	.out
.nopause
	; look up
	bset	#1,d3
	bra.b	.out
.nolookup2
	btst	#JPB_BTN_BLU,d0
	beq.b	.nolookdown2
	bset	#2,d3
.nolookdown2
.out
	movem.l	(a7)+,d0/d1
	rts
	ENDC