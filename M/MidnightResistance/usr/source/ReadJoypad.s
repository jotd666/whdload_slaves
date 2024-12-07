;==========================================================================
; read current state of joystick & joypad
;
; original code by asman with timing fix by wepl
; "getting joypad keys (cd32)"
; http://eab.abime.net/showthread.php?t=29768
;
; adapted to single read of both joysticks thanks to Girv
;
; > d0.l = port number (0,1)
;
; < d0.l = state bits set as follows
;        JPB_JOY_R	= $00
;        JPB_JOY_L 	= $01
;        JPB_JOY_D	= $02
;        JPB_JOY_U	= $03
;        JPB_BTN_PLAY	= $11
;        JPB_BTN_REVERSE	= $12
;        JPB_BTN_FORWARD	= $13
;        JPB_BTN_GRN	= $14
;        JPB_BTN_YEL	= $15
;        JPB_BTN_RED	= $16
;        JPB_BTN_BLU	= $17
; < d1.l = raw joy[01]dat value read from input port
;

	IFND	EXEC_TYPES_I
	INCLUDE	exec/types.i
	ENDC

	BITDEF	JP,JOY_R,0
	BITDEF	JP,JOY_L,1
	BITDEF	JP,JOY_U,2
	BITDEF	JP,JOY_D,3
	BITDEF	JP,BTN_PLAY,$11
	BITDEF	JP,BTN_REVERSE,$12
	BITDEF	JP,BTN_FORWARD,$13
	BITDEF	JP,BTN_GRN,$14
	BITDEF	JP,BTN_YEL,$15
	BITDEF	JP,BTN_RED,$16
	BITDEF	JP,BTN_BLU,$17

_joystick:

	moveq	#0,d0
	bsr	_read_joystick

		movem.l	a0,-(a7)	; put input 0 output in joy0
		lea	joy0(pc),a0
		move.l	d0,(a0)		
		movem.l	(a7)+,a0

	moveq	#1,d0
	bsr	_read_joystick

		movem.l	a0,-(a7)	; put input 1 output in joy1
		lea	joy1(pc),a0
		move.l	d0,(a0)		
	
		lea	potgo(pc),a0
		move.w	#$ffff,a0

		movem.l	(a7)+,a0

	rts	

_read_joystick:
		movem.l	d2-d7/a0-a1,-(a7)
		lea	_custom,a0
		lea	_ciaa,a1

		moveq	#CIAB_GAMEPORT0,d3	; red button ( port 0 )
		moveq	#10,d4			; blue button ( port 0 )
		move.w	#$f600,d5		; for potgo port 0
		moveq	#joy0dat,d6		; port 0

		tst.l	d0
		beq	.direction

		moveq	#CIAB_GAMEPORT1,d3	; red button ( port 1 )
		moveq	#14,d4			; blue button ( port 1 )
		move.w	#$6f00,d5		; for potgo port 1
		moveq	#joy1dat,d6		; port 1

.direction	moveq	#0,d7

		move.w	0(a0,d6.w),d0		;get joystick direction
		move.w	d0,d6

		move.w	d0,d1
		lsr.w	#1,d1
		eor.w	d0,d1

		btst	#8,d1	;check joystick up
		sne	d7
		add.w	d7,d7

		btst	#0,d1	;check joystick down
		sne	d7
		add.w	d7,d7

		btst	#9,d0	;check joystick left
		sne	d7
		add.w	d7,d7

		btst	#1,d0	;check joystick right
		sne	d7
		add.w	d7,d7

		swap	d7

	;two buttons

		btst	d4,potinp(a0)	;check button blue (normal fire2)
		seq	d7
		add.w	d7,d7

		btst	d3,ciapra(a1)	;check button red (normal fire1)
		seq	d7
		add.w	d7,d7

		and.w	#$0300,d7	;calculate right out for
		asr.l	#2,d7		;above two buttons
		swap	d7		;like from lowlevel
		asr.w	#6,d7

	; read buttons from CD32 pad

		bset	d3,ciaddra(a1)	;set bit to out at ciapra
		bclr	d3,ciapra(a1)	;clr bit to in at ciapra

		move.w	d5,potgo(a0)

		moveq	#0,d0
		moveq	#8-1,d1
		bra.b	.gamecont4

.gamecont3	tst.b	ciapra(a1)
		tst.b	ciapra(a1)
.gamecont4	tst.b	ciapra(a1)	; wepl timing fix
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)

		move.w	potinp(a0),d2

		bset	d3,ciapra(a1)
		bclr	d3,ciapra(a1)
	
		btst	d4,d2
		bne.b	.gamecont5

		bset	d1,d0

.gamecont5	dbf	d1,.gamecont3

		bclr	d3,ciaddra(a1)		;set bit to in at ciapra
;		move.w	#$ffff,potgo(a0)

		swap	d0		; d0 = state
		or.l	d7,d0

		moveq	#0,d1		; d1 = raw joydat
		move.w	d6,d1

		movem.l	(a7)+,d2-d7/a0-a1
		rts

;==========================================================================

;==========================================================================

joy0		dc.l	0		
joy1		dc.l	0
