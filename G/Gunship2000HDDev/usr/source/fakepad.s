;
; fakepad.s, written by JOTD
;
; * CD³² emulation using joystick and function keys
; * language selection patch using WHDLoad language information

	INCLUDE	"hardware/custom.i"
	INCLUDE	"lvo/lowlevel.i"
	INCLUDE	"libraries/lowlevel.i"

SET_JOY_BUTTON:MACRO
	bset	#JPB_BUTTON_\1,D0	; button pressed
	ENDM

	IFND	_custom
_custom = $DFF000
	ENDC


	IFND	QKSTRUCT
_qkstruct:
	dc.w	$50,$0,$51,0,$52,$0,$53,0,$54,0,$55,0
	ENDC

_patch_joypad:
	movem.l	D0-A6,-(a7)
	move.l	$4.W,A6

	lea	.lowname(pc),A1
	JSR	_LVOOldOpenLibrary(A6)
	lea	.lowbase(pc),a0
	move.l	d0,(a0)
	beq	.err

	move.l	.lowbase(pc),A6
	add.l	#_LVOReadJoyPort+2,A6

	; interrupts disabled

	move.l	$4.W,A6
	JSR	_LVODisable(a6)

	; find which type of controller is in port 1

	bsr	.check_controller_1
	move.l	.lowbase(pc),A1
	move.l	#_LVOReadJoyPort,A0
	JSR	_LVOSetFunction(a6)

	lea	.oldreadjoyport(pc),a0
	move.l	d0,(a0)

	;get tags
	move.l	_resload(pc),a2
	lea	(.fp_tags,pc),a0
	jsr	(resload_Control,a2)
	

	lea	.getlangsel(pc),a0
	move.l	a0,d0
	move.l	.lowbase(pc),A1
	move.l	#_LVOGetLanguageSelection,A0
	JSR	_LVOSetFunction(a6)

	; interrupts enabled

	move.l	$4.W,A6
	JSR	_LVOEnable(a6)

	movem.l	(a7)+,d0-a6
	rts

	; error
.err
	pea	.lowname(pc)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

.oldreadjoyport:
	dc.l	0
.lowbase:
	dc.l	0

.fp_tags
		dc.l	WHDLTAG_LANG_GET
.language	dc.l	0
		dc.l	WHDLTAG_CUSTOM4_GET
.forceuk	dc.l	0
		dc.l	0

.getlangsel:
	move.l	.forceuk(pc),d0
	bne.b	.uk
	move.l	.language(pc),d0
	rts
.uk
	moveq.l	#2,d0
	rts

; > D0: patch routine
.check_controller_1:

	movem.l	a6,-(a7)
	move.l	.lowbase(pc),a6
	
	; do it twice or it gives incorrect results

	moveq	#1,d0
	jsr	_LVOReadJoyPort(a6)
	moveq	#1,d0
	jsr	_LVOReadJoyPort(a6)
	and.l	#$40000000,d0
	cmp.l	#$40000000,d0
	beq.b	.joystick
	lea	.readjoyport_dfl(pc),a0
	bra.b	.out
.joystick
	lea	.readjoyport_stk(pc),a0
.out
	move.l	a0,d0
	movem.l	(a7)+,a6
	rts

; reads joypads, joystick in port #1 version
; < D0
; > D0

.readjoyport_stk:
	movem.l	D1-A6,-(A7)

	move.l	d0,d2		; save port number for later use

	cmp.w	#0,D2
	bne	.next	; mouse port read directly by lowlevel lib

; joystick port 0 is not patched (yet)

	movem.l	(a7)+,D1-A6
	move.l	.oldreadjoyport(pc),-(A7)
	rts
.next
	cmp.w	#1,D2
	beq	.joy1_stk

	move.l	#JP_TYPE_NOTAVAIL,D0
	bra	.mainexit

; joystick port 1

.joy1_stk
	; complete rewrite of joystick test
	; since else 2-button joysticks are not recognized

	move.l	#JP_TYPE_GAMECTLR,D0	; force joypad connected

	btst	#7,$bfe001
	bne	.nob1_1

	SET_JOY_BUTTON	RED
	
.nob1_1:
	; 2nd button test (may not work depending on the games)

	btst	#6,potinp+$DFF000
	bne	.nob2_1

	SET_JOY_BUTTON	BLUE
	move.w	#$CC01,(potgo+_custom)	; reset ports
.nob2_1:

	movem.l	D0,-(A7)

	move.l	.old_buttonmask(pc),D0
	bsr	.button_test

	lea	.old_buttonmask(pc),A0
	move.l	D0,(A0)			; relocatable memory write

	or.l	(A7),D0
	move.l	D0,(A7)
	movem.l	(A7)+,D0	

	; now test joystick moves

	lea	(joy1dat+_custom),A6
	bsr	.joy_test

	bra	.mainexit

; reads joypads, joypad/mouse in port #1 version
; < D0
; > D0

.readjoyport_dfl:
	movem.l	D1-A6,-(A7)

	move.l	d0,d2		; save port number for later use

	pea	.port_keys(pc)
	move.l	.oldreadjoyport(pc),-(A7)
	rts
.port_keys

	cmp.w	#0,D2
	beq	.mainexit	; mouse port: no extra button support
	cmp.w	#1,D2
	beq	.joy1_pad

	move.l	#JP_TYPE_NOTAVAIL,D0
	bra	.mainexit

; joystick port 0 is not patched (yet)

; joystick port 1

.joy1_pad
	movem.l	D0,-(A7)

	move.l	.old_buttonmask(pc),D0
	bsr	.button_test

	lea	.old_buttonmask(pc),A0
	move.l	D0,(A0)			; relocatable memory write

	or.l	(A7),D0
	move.l	D0,(A7)
	movem.l	(A7)+,D0	

.mainexit
	movem.l	(A7)+,D1-A6
	rts

.old_buttonmask:
	dc.l	0

; other joypad buttons by keyboard emulation

.button_test:
	movem.l	D1/A0-A1,-(A7)
	bsr	.btproc
	movem.l	(A7)+,D1/A0-A1
	rts


.btproc
	; reads keyboard current pressed key (maybe it won't work)

	lea	_qkstruct(pc),A0
	move.l	.lowbase(pc),A6
	moveq.l	#6,D1
	JSR	_LVOQueryKeys(a6)

	moveq.l	#0,D0

	lea	_qkstruct(pc),A0

	; F1: Blue
		
	tst.w	2(A0)
	beq	.noblue
	SET_JOY_BUTTON	BLUE
.noblue
	; F2: Green

	addq.l	#4,A0
	tst.w	2(A0)
	beq	.nogreen
	SET_JOY_BUTTON	GREEN
.nogreen:
	; F3: Yellow

	addq.l	#4,A0
	tst.w	2(A0)
	beq	.noyellow
	SET_JOY_BUTTON	YELLOW
.noyellow:
	; F4: Play/pause

	addq.l	#4,A0
	tst.w	2(A0)
	beq	.noplay
	SET_JOY_BUTTON	PLAY
.noplay:
	; F5: Reverse (left ear)

	addq.l	#4,A0
	tst.w	2(A0)
	beq	.nolear
	SET_JOY_BUTTON	REVERSE
.nolear:
	; F6: right ear
	addq.l	#4,A0
	tst.w	2(A0)
	beq	.norear
	SET_JOY_BUTTON	FORWARD

.norear:
	rts



; tests joystick moves
; < A6: custom reg. of the selected joystick
; > D0: joystick bits set

.joy_test:
	movem.l	D4-D6,-(A7)

	move.w	(A6),D4
	move.w	D4,D5
	btst	#1,D4
	beq.b	.left_off
	bset	#JPB_JOY_RIGHT,D0
	bra.b	.vert_test
.left_off:
	btst	#9,D4
	beq.b	.vert_test
	bset	#JPB_JOY_LEFT,D0
.vert_test
	lsr.w	#1,D4
	eor.w	D5,D4
	btst	#0,D4
	beq.b	.back_off
	bset	#JPB_JOY_DOWN,D0
	bra.b	.exit
.back_off
	btst	#8,D4
	beq.b	.exit
	bset	#JPB_JOY_UP,D0
.exit

	movem.l	(A7)+,D4-D6
	rts

.lowname:
	dc.b	"lowlevel.library",0
	even
