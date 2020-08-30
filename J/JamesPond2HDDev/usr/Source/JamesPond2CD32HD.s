;*---------------------------------------------------------------------------
;  :Program.	RobocodHD.asm
;  :Contents.	Slave for "Robocod"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: RobocodHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"JamesPond2CD32.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $180000

; not too much fastmem, or else, ebook music is completely buggy
; and it's useless anyway since game uses only chipmem, so the fastmem
; will be used by the system to speed up OS operations

FASTMEMSIZE	= $20000
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;DEBUG
INITAGA
HDINIT
BOOTDOS
;HRTMON
CACHE
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH

FORCEPAL
;DUMMY_CD_DEVICE = 1
USE_DISK_LOWLEVEL_LIB
USE_DISK_NONVOLATILE_LIB

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick31cd32.s
	INCLUDE	fakepad.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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
_assign1
	dc.b	"CD0",0
_assign2
	dc.b	"ENV",0
_assign3
	dc.b	"Robocod_CD",0

slv_name		dc.b	"James Pond 2 - Robocod CD³²",0
slv_copy		dc.b	"1992 Millenium",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Use F1-F6 to emulate joypad buttons",10
		dc.b	"Use CUSTOM4=1 to force english language",10,10
		dc.b	"Version "
	DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
		dc.b    "C4:B:Force english language;"			
		dc.b	0

_rampath:
	dc.b	"RAM:",0
_menu:
	dc.b	"Roboselect",0
_main:
	dc.b	"Roboloader",0
_book:
	dc.b	"c/ebook",0
_envvar:
	dc.b	"RoboSelection",0
_args		dc.b	10
_args_end
	dc.b	0
ENVBUF_LEN= 20
_envbuf:
	ds.b	ENVBUF_LEN,0
	EVEN


_bootdos
	move.l	(_resload,pc),a2		;A2 = resload


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		bsr	_dos_assign
		lea	_assign3(pc),a0
		bsr	_dos_assign
		lea	_assign2(pc),a0
		lea	_rampath(pc),a1
		bsr	_dos_assign

		bsr	_patch_joypad

_loop
	;load & execute menu
		lea	_menu(pc),a0
		lea	_args(pc),a1
		sub.l	a5,a5
		moveq	#_args_end-_args,d0
		bsr	_load_exe
	;check env variable
		lea	_envvar(pc),a0
		move.l	a0,d1
		lea	_envbuf(pc),a0
		move.l	a0,d2
		move.l	#ENVBUF_LEN,d3
		moveq	#0,d4
		jsr	_LVOGetVar(a6)
		tst.l	d0
		bmi.b	_quit
	;found
		lea	_envbuf(pc),a0
		cmp.b	#'F',(a0)
		beq.b	.book

		cmp.b	#'R',(a0)
		beq.b	.game

		bra.b	_quit

.game
		lea	_main(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
		bra.b	_loop

.book
		lea	_book(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
		bra.b	_loop

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist



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
	cmp.l	#0,a5
	beq.b	.skip
	jsr	(a5)
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


	END
