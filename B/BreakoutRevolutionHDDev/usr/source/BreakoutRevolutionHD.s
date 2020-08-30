;*---------------------------------------------------------------------------
;  :Program.	PinballFantasiesHD.asm
;  :Contents.	Slave for "PinballFantasies"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: PinballFantasiesHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"BreakoutRevolution.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG	: with it nonvolatile.lib fails
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE
INITAGA
FONTHEIGHT = 8

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_ReqAGA|WHDLF_Req68020|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"Breakout Revolution AGA",0
slv_copy		dc.b	"1996 Oliver Michel",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

_program:
	dc.b	"BreakoutRevolution",0
_args		dc.b	10
_args_end
	dc.b	0
_assign:
	dc.b	"BOR",0
_assign3:
	dc.b	"ENV",0
_ram:
	dc.b	"RAM:",0
	


	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W



	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
	lea	(_dosname,pc),a1
	move.l	(4),a6
	jsr	(_LVOOldOpenLibrary,a6)
	move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	_assign3(pc),a0
		lea	_ram(pc),a1
		bsr	_dos_assign
	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
;	move.l	d7,a1
;	lea	pl_main(pc),a0
;	jsr	resload_PatchSeg(a2)
	
	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_end
	jsr	(_LVOIoErr,a6)
	pea	_program(pc)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

pl_main
	PL_START
	
	PL_END
	
