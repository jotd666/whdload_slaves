;*---------------------------------------------------------------------------
;  :Program.	BloodnetHD.asm
;  :Contents.	Slave for "Bloodnet"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BloodnetHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"BloodnetECS.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000
NO68020
;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 7000
;MEMFREE	= $200
;NEEDFPU
BOOTDOS

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.2"
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
ASSIGNDECL:MACRO
_assign\1:
	dc.b	"Bloodnet"
	dc.b	\1+'0',0
	ENDM

	ASSIGNDECL	1
	ASSIGNDECL	2
	ASSIGNDECL	3
	ASSIGNDECL	4
	ASSIGNDECL	5
	ASSIGNDECL	6
	ASSIGNDECL	7
	ASSIGNDECL	8

_assign_sg
	dc.b	"BloodnetSG",0

slv_name		dc.b	"Bloodnet ECS",0
slv_copy		dc.b	"1994 GameTEK/Microprose",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Thanks to Tony Aksnes for disk images",10,10
			dc.b	"Version "
	DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Bloodnet500",0
_args		dc.b	10
_args_end
	dc.b	0
	even

;============================================================================

	;initialize kickstart and environment

DOASSIGN:MACRO
	lea	_assign\1(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	ENDM


_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;patch dos

		;;bsr	_patch_dos

	;assigns
		lea	_assign_sg(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		DOASSIGN	1
		DOASSIGN	2
		DOASSIGN	3
		DOASSIGN	4
		DOASSIGN	5
		DOASSIGN	6
		DOASSIGN	7
		DOASSIGN	8

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

	include	"BloodnetShared.s"
