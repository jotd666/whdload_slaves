;*---------------------------------------------------------------------------
;  :Program.	LostDutchManMineHD.asm
;  :Contents.	Slave for "LostDutchManMine"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: LostDutchManMineHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"LostDutchManMine.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;;DEBUG

	IFD	DEBUG
CHIPMEMSIZE	= $F0000
FASTMEMSIZE	= $00000
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $60000
BLACKSCREEN
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
CACHE
BOOTDOS

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s


;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM
slv_name		dc.b	"Lost DutchMan Mine",0
slv_copy		dc.b	"1989 Magnetic Scrolls",0
slv_info		dc.b	"adapted by JOTD",10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Thanks to Chris Vella & Tony Aksnes for disk image",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"LostDutchManMine",0
_args		dc.b	10
_args_end
	dc.b	0
;ldmname
;	dc.b	"LDM",0
_ramfile:
	dc.b	"RAM:try",0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

; cd LDM
	IFEQ	1
		lea	_ldmname(pc),a0
		move.l	a0,d1
		jsr	_LVOLock(a6)
		move.l	d0,d1
		jsr	_LVOCurrentDir(a6)
	ENDC

; load RAM: handler

		lea	_ramfile(pc),a0
		move.l	a0,d1
		move.l	#MODE_NEWFILE,d2
		jsr	_LVOOpen(a6)
		move.l	d0,d1
		jsr	_LVOClose(a6)

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
		add.l	d7,d7
		add.l	d7,d7

		moveq	#3,d2
		bsr	get_section
		sub.l	#$1494,a1
		lea	pl_main(pc),a0
		jsr	resload_Patch(a2)

	;call
		move.l	d7,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		lsr.l	#2,d7
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_end
		pea	_program(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
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

pl_main
	PL_START
;;	PL_CW	$1716	; lockpick "crack"
	PL_W	$1814,$4A19	; one more tst.b (A1)+ to avoid empty string
	PL_W	$1848,$4E71	; crack
	PL_END
;============================================================================


;============================================================================
