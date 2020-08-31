	INCDIR	"Include:"
	INCLUDE	whdload.i

_base		SLAVE_HEADER
		dc.w	10
		dc.w	WHDLF_NoError|WHDLF_EmulTrap
		dc.l	$80000
		dc.l	0
		dc.w	_Start-_base
		dc.w	0
		dc.w	0
_keydebug	dc.b	0
_keyexit	dc.b	$59
		dc.l	0
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"Cabaret Asteroids",0
_copy		dc.b	"1991 Vertical",0
_info		dc.b	"installed & fixed by Bored Seal & JOTD",10
		DECL_VERSION
		dc.b	0
		even

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using

		lea	game,a0
		lea	$5000,a1
		bsr	LoadFile

		move.w	#$f180,$502a		;i want color stripes!
		pea	DCR_Done
		move.l	(sp)+,$511c

		illegal
		jmp	$5000

DCR_Done	move.w	#$4ef9,$3d04e
		pea	LoadHS
		move.l	(sp)+,$3d050

		move.w	#$4ef9,$3d45c
		pea	SaveHS
		move.l	(sp)+,$3d45e

		move.w	#$4ef9,$34ce2
		pea	BlitFix
		move.l	(sp)+,$34ce4

		move.w	#$4eb9,$36d88		;quit
		pea	Exit
		move.l	(sp)+,$36d8a

		move.l	#$2f104e75,$36de6	;keyboard fix by Jeff

		jmp	$34000

LoadFile	movem.l	a0-a2/d0-d2,-(sp)
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFileDecrunch,a2)
		movem.l	(sp)+,a0-a2/d0-d2
		rts

LoadHS		lea	hisc,a0
		lea	$1c000,a1
		bsr	LoadFile
		jmp	$3d092

SaveHS		lea	hisc,a0
		lea	$37e80,a1
		move.l	#$1600,d0
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
		jmp	$3d494

Exit		cmp.b	_keyexit,d0
		beq	_exit
		move.b	d0,d1
		bclr	#7,d0
		rts

BlitFix		move.w	#$9c01,$58(a0)
BlitWait	btst	#6,$dff002
		bne	BlitWait
		rts

_exit		pea	TDREASON_OK
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_resload	dc.l	0			;address of resident loader
game		dc.b	"game",0
hisc		dc.b	"hisc",0
