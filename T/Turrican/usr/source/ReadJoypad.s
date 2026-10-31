;==========================================================================
; read current state of joystick & joypad
;
; original code by asman with timing fix by wepl
; "getting joypad keys (cd32)"
; http://eab.abime.net/showthread.php?t=29768
;
; adapted to single read of both joysticks thanks to Girv
;
; added detection of joystick/joypad by JOTD, thanks to EAB thread:
; http://eab.abime.net/showthread.php?p=1175551#post1175551
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
	INCLUDE	hardware/cia.i
	INCLUDE	hardware/custom.i

	BITDEF	JP,BTN_RIGHT,0
	BITDEF	JP,BTN_LEFT,1
	BITDEF	JP,BTN_DOWN,2
	BITDEF	JP,BTN_UP,3
	BITDEF	JP,BTN_PLAY,$11
	BITDEF	JP,BTN_REVERSE,$12
	BITDEF	JP,BTN_FORWARD,$13
	BITDEF	JP,BTN_GRN,$14
	BITDEF	JP,BTN_YEL,$15
	BITDEF	JP,BTN_RED,$16
	BITDEF	JP,BTN_BLU,$17


	XDEF	_detect_controller_types
	XDEF	_read_joystick

; optional call to differentiate 2-button joystick from CD32 joypad
; default is "all joypads", but when using 2-button joystick second button,
; the problem is that all bits are set (which explains that pressing 2nd button usually
; triggers pause and/or both shoulder buttons => quit game)
;
; drawback:
; once detected, changing controller type needs game restart/check again
;
; advantage:
; less CPU time consumed while trying to read ghost buttons
;
_detect_controller_types:
    movem.l d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	move.l	#$80000000,d0
	jsr		resload_ReadJoyPort(a2)
	lea		controller_joypad_0(pc),a0
	and.l	#RJP_TYPE_GAMECTRL,d0
	sne		(a0)		
	
	move.l	#$80000001,d0
	jsr		resload_ReadJoyPort(a2)
	lea		controller_joypad_1(pc),a0
	and.l	#RJP_TYPE_GAMECTRL,d0
	sne		(a0)		
    movem.l (a7)+,d0-d1/a0-a2
	rts

_joystick:
	move.l	a0,-(a7)	; put input 0 output in joy0
	moveq	#0,d0
	bsr	_read_joystick

	lea	joy0(pc),a0
	move.l	d0,(a0)		

	moveq	#1,d0
	bsr	_read_joystick

	lea	joy1(pc),a0
	move.l	d0,(a0)		

	move.l	(a7)+,a0

	rts	

_read_joystick:
    movem.l d1-d2/a0-a2,-(a7)
	move.l	_resload(pc),a2
	moveq	#0,d2
	move.b	d0,d2
	jsr		resload_ReadJoyPort(a2)
	btst	#JPB_BTN_PLAY,d0
	beq.b	.1
	* maybe third button pressed,
	* change third button if needed
	lea		controller_joypad_0(pc),a0
	tst.b	(a0,d2.w)
	bne.b	.1		; joypad, ignore
	move.l	third_button_maps_to(pc),d1
	cmp.l	#JPF_BTN_PLAY,d1
	beq.b	.1
	; remapped third button: change
	bclr	#JPB_BTN_PLAY,d0
	or.l	d1,d0
.1:
	movem.l (a7)+,d1-d2/a0-a2
    
	rts
	

       
;==========================================================================

;==========================================================================

joy0		dc.l	0		
joy1		dc.l	0

controller_joypad_0:
	dc.b	$FF	; set: joystick 0 is a joypad, else joystick
controller_joypad_1:
	dc.b	$FF
third_button_maps_to:
	dc.l	JPF_BTN_PLAY