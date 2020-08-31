;*---------------------------------------------------------------------------
;  :Program.	XP8HD.asm
;  :Contents.	Slave for "XP8"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: XP8HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
FORCEPAL

;============================================================================

KICKSIZE	= $80000			;40.068
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
	IFD	AGAVER
		dc.w	WHDLF_ReqAGA|WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
	ELSE
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
	ENDC
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	CNOP 0,4
	IFD	AGAVER
_assign_1
	dc.b	6,"xp8di1",0
	CNOP 0,4
_assign_2
	dc.b	6,"xp8di2",0
	CNOP 0,4
_assign_3
	dc.b	6,"xp8di3",0
	CNOP 0,4
_assign_4
	dc.b	6,"xp8di4",0
	ELSE
_assign_1
	dc.b	6,"xp8df1",0
	CNOP 0,4
_assign_2
	dc.b	6,"xp8df2",0
	CNOP 0,4
_assign_3
	dc.b	6,"xp8df3",0
	ENDC
_name		
		dc.b	"XP8 "
	IFD	AGAVER
		dc.b	"AGA"
	ELSE
		dc.b	"ECS"
	ENDC
		dc.b	0
_copy		dc.b	"1996 Weathermine Software",0
_info		dc.b	"adapted by JOTD",10,10
	IFND	AGAVER
		dc.b	"Thanks to C. Lennard for diskimages",10,10
	ENDC
		dc.b	"Version 1.2 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0
	EVEN

_program:
	IFD	AGAVER
	dc.b	"XP8.b212",0
	ELSE
	dc.b	"XP8.exe",0
	ENDC
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload

	;enable cache
	;	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	;	move.l	#WCPUF_All,d1
	;	jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		IFD	AGAVER
		lea	_assign_4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		ENDC

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found

	;patch here
		bsr	_patch_exe
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
		pea	_program(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;============================================================================

	INCLUDE	kick31.s

;============================================================================

	END
