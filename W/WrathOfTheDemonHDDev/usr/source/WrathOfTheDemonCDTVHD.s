;*---------------------------------------------------------------------------
;  :Program.	WrathOfTheDemonCDTV.asm
;  :Contents.	Slave for "WrathOfTheDemonCDTV"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
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
	OUTPUT	"WrathOfTheDemonCDTV.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_assign
	dc.b	"Wrath",0

slv_name		dc.b	"Wrath Of The Demon CDTV",0
slv_copy		dc.b	"1989 ReadySoft",0
slv_info		dc.b	"Install/fix by JOTD",10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0

slv_CurrentDir		dc.b	"data",0

_program:
	dc.b	"Wrath.exe",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

; to get a longword without caring for alignment (68000)

GETLONG:MACRO
		move.b	(\1),\2
		lsl.l	#8,\2
		move.b	(1,\1),\2
		lsl.l	#8,\2
		move.b	(2,\1),\2
		lsl.l	#8,\2
		move.b	(3,\1),\2
		ENDM

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	_patch_cdtv

	;load exe
		lea	_program(pc),a0
		lea	patch_wrath(pc),a5
		moveq	#1,d0
		lea	_args(pc),a1
		bsr	_load_exe
	;call
_exit
	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

patch_wrath
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_wrath(pc),a0
	jsr	resload_Patch(a2)
	rts

pl_wrath
	PL_START
	PL_PS	$3C0,load_exec_flush
	PL_PS	$24C2,kb_delay
	PL_END

load_exec_flush
	move.l	$4,a6
	bra	_flushcache

kb_delay:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	rts

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
	
PATCH_IO:MACRO
	move.l	$4.W,a0
	add.w	#_LVO\1+2,a0
	lea	.\1_save\@(pc),a1
	move.l	(a0),(a1)
	lea	.\1\@(pc),a1
	move.l	a1,(a0)
	bra.b	.cont\@
.\1_save\@:
	dc.l	0
.\1\@:
	lea	_fake_cdtvbase(pc),A0
	cmp.l	IO_DEVICE(a1),A0
	beq.b	.ignore\@
	cmp.l	#$B0DEB0DE,IO_DEVICE(a1)
	beq.b	_handle_bookmark
	; ignore (cdtv.device)
.ignore\@
	moveq.l	#0,D0
	rts
.org\@
	move.l	.\1_save\@(pc),-(A7)
	rts
.cont\@
	ENDM

_handle_bookmark:
	movem.l	A1/A2,-(a7)
	move.l	_resload(pc),a2

	move.w	$1C(a1),d0	; command
	cmp.w	#13,d0		; create
	beq.b	.out		; creation always OK

	cmp.w	#CMD_READ,d0
	beq.b	.read_bookmark
	cmp.w	#CMD_WRITE,d0
	beq.b	.write_bookmark
	
	illegal
.out
	movem.l	(A7)+,A1/A2
	moveq.l	#0,D0
	clr.b	$1F(a1)
	rts

.read_bookmark:
	lea	.bookmark_name(pc),a0
	move.l	IO_LENGTH(a1),d0
	moveq.l	#0,D1
	move.l	IO_DATA(a1),a1
	jsr	resload_LoadFileOffset(a2)
	bra.b	.out	

.write_bookmark:
	lea	.bookmark_name(pc),a0
	move.l	IO_LENGTH(a1),d0
	moveq.l	#0,D1
	move.l	IO_DATA(a1),a1
	jsr	resload_SaveFileOffset(a2)
	bra.b	.out	
	
.bookmark_name:
	dc.b	"gamesave",0
	even

_patch_cdtv:
	move.l	4.W,a0
	add.w	#_LVOOpenDevice+2,a0
	lea	_opendev_save_2(pc),a1
	move.l	(a0),(a1)
	lea	_opendev_2(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseDevice+2,a0
	lea	_closedev_save_2(pc),a1
	move.l	(a0),(a1)
	lea	_closedev_2(pc),a1
	move.l	a1,(a0)

	PATCH_IO	DoIO
	PATCH_IO	SendIO
	PATCH_IO	CheckIO
	PATCH_IO	WaitIO
	PATCH_IO	AbortIO

	rts

_opendev_save_2:
	dc.l	0
_closedev_save_2:
	dc.l	0

;============================================================================


_closedev_2:
	move.l	IO_DEVICE(a1),D0
	lea	_fake_cdtvbase(pc),a0
	cmp.l	a0,d0
	beq.b	.out
	cmp.l	#$B0DEB0DE,D0
	beq.b	.out

.org
	move.l	_closedev_save_2(pc),-(a7)
	rts

.out
	moveq	#0,D0
	rts

_opendev_2:
	movem.l	D0,-(a7)
	GETLONG	A0,D0
	cmp.l	#'cdtv',D0
	beq.b	.cdtv
	cmp.l	#'book',D0
	beq.b	.bookmark
	bra.b	.org

	; cdtv device
.cdtv
	pea	_fake_cdtvbase(pc)
	move.l	(A7)+,IO_DEVICE(a1)
.exit
	movem.l	(A7)+,D0
	moveq.l	#0,D0
	rts

.org
	movem.l	(A7)+,D0
	move.l	_opendev_save_2(pc),-(a7)
	rts

.bookmark:
	move.l	#$B0DEB0DE,IO_DEVICE(a1)
	bra.b	.exit

; all functions do nothing

	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
_fake_cdtvbase:
	illegal


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
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d0-a6,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	movem.l	(a7)+,d0-a6
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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
