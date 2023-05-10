
	include	"lvo/lowlevel.i"
	include	"lvo/nonvolatile.i"
	include	"lvo/timer.i"
	include	"lvo/cia.i"
	include	"libraries/lowlevel.i"
	include	"libraries/nonvolatile.i"

	IFND	JSRLIB

JSRLIB:MACRO
	jsr	_LVO\1(a6)
	ENDM

JMPLIB:MACRO
        jmp    _LVO\1(a6)
        ENDM

	ENDC

_lowlbase:
	dc.l	0
_nonvbase:
	dc.l	0
_franbase:
	dc.l	0
_lowlname:
	dc.b	"lowlevel.library",0
_franname:
	dc.b	"freeanim.library",0
_nonvname:
	dc.b	"nonvolatile.library",0
_kbdevname:
	dc.b	"keyboard.device",0
_timerdevname:
	dc.b	"timer.device",0
_ciaaname:
	dc.b	"ciaa.resource",0
_ciabname:
	dc.b	"ciab.resource",0
	even


	include	"freeanim.s"

	IFD	USE_DISK_NONVOLATILE_LIB
	IFND	ENABLE_DISK_LIBRARIES
ENABLE_DISK_LIBRARIES
	ENDC
	ELSE
	include	"nonvolatile.s"
	ENDC

KICKCD32 = 1

	IFD	PATCH_DIRECTORY_STUFF
	include	"kickproc.s"
	include	"kickdos.s"

	IFEQ	KICKSIZE-$40000
	IFD	USE_DISK_LOWLEVEL_LIB
	FAIL	"Cannot use lowlevel disk lib with kick 1.x"
	ENDC
	IFD	USE_DISK_NONVOLATILE_LIB
	FAIL	"Cannot use nonvolatile disk lib with kick 1.x"
	ENDC
	include	"whdload/kick13.s"
	ELSE
	include	"whdload/kick31.s"
	ENDC
	ENDC

	IFD	USE_DISK_LOWLEVEL_LIB
	IFND	ENABLE_DISK_LIBRARIES
ENABLE_DISK_LIBRARIES
	ENDC
	ELSE
	include	"lowlevel.s"

InitLowlevelKeyboard:
	lea	_oldint_kb(pc),a0
	move.l	$68.W,(A0)
	lea	_newint_kb(pc),a0
	move.l	a0,$68.W
	rts

TEST_QUALIFIER:MACRO
	cmp.b	#80+\1,d1	; rawkey = bit number + 80, lets use this!
	bne.b	.sk\@
	btst	#7,d0
	beq.b	.press\@
	bclr	#\1,d0
	clr.b	d0	; qualifier is not a key
	bra.b	.sk\@
.press\@
	bset	#\1,d0
	clr.b	d0	; qualifier is not a key
.sk\@
	ENDM

_newint_kb:
	movem.l	D0/A0,-(a7)

	; get current raw keycode & keycode+qualifiers

	clr.w	d0
	move.b	$bfec01,d0
	ror.b	#1,d0
	not.b	d0

	; save keycode as is for lowlevel.QueryKeys

	lea	rawkeycode(pc),a0
	move.b	d0,(a0)

	swap	d0
	move.w		key_and_qualifier(pc),d0	; save qualifiers
	swap	d0

	; handle qualifiers for lowlevel.GetKey

	movem.l	D1,-(a7)
	move.b	d0,d1
	and.b	#$7F,d1

	TEST_QUALIFIER	LLKB_LSHIFT
	TEST_QUALIFIER	LLKB_RSHIFT
	TEST_QUALIFIER	LLKB_CAPSLOCK
	TEST_QUALIFIER	LLKB_CONTROL
	TEST_QUALIFIER	LLKB_LALT
	TEST_QUALIFIER	LLKB_RALT
	TEST_QUALIFIER	LLKB_LAMIGA
	TEST_QUALIFIER	LLKB_RAMIGA

	movem.l	(a7)+,d1

	lea	key_and_qualifier(pc),a0
	move.l	d0,(a0)

	movem.l	(a7)+,D0/A0
	move.l	_oldint_kb(pc),-(A7)
	rts

.ackkb:
	bset	#6,$BFEE01
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	rts

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_oldint_kb:
	dc.l	0

key_and_qualifier:
	dc.l	0
rawkeycode:
	dc.w	0
potinp_value:
	dc.w	$ffff
	ENDC
	
MYRTS:
	rts
