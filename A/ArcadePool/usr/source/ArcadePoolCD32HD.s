;*---------------------------------------------------------------------------
;  :Program.	ArcadePoolCD32HD.asm
;  :Contents.	Slave for "ArcadePoolCD32"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ArcadePoolCD32HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"ArcadePoolCD32.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;DEBUG

	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $40000	; not too much fastmem or there are sprite glitches
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT	; or else impossible to load/save
;DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 8192
BOOTDOS
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'


	include	whdload/kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"3.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0

;assign
;	dc.b	"CD0",0

slv_name		dc.b	"Arcade Pool CD��"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1994 Team 17",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"pool",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0
	EVEN

_bootdos
	clr.l	$0.W

	bsr	_patch_cd32_libs	; for fake cd.device

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		bsr	openwindow	; enables display on screen!

		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		;lea	assign(pc),a0
		;sub.l	a1,a1
		;bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


openwindow:
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	lea	.newscreen_struct(pc),A0
	jsr	_LVOOpenScreen(A6)

	lea	.newwindow_struct(pc),A0
	move.l	D0,$1E(A0)	; nw_Screen

	jsr	_LVOOpenWindow(A6)
	move.l	d0,a0
	sub.l	a1,a1
	moveq.l	#1,d0
	moveq.l	#1,d1
	sub.l	d2,d2
	sub.l	d3,d3
	jsr	_LVOSetPointer(A6)
	rts

.newscreen_struct:
	dc.w	0,0
	dc.w	320,200
	dc.w	2
	dc.b	1,0
	dc.W	0
	dc.W	0
	dc.l	0	; no font
	dc.l	0	; no title
	dc.l	0
	dc.l	0
.newwindow_struct:
	dc.w	0,0
	dc.w	320,200
	dc.w	0
	dc.l	0,0,0,0
	dc.l	0	; no title
	dc.l	0,0
	dc.w	10,10,320,200
	dc.w	0

.intname:
	dc.b	"intuition.library",0
	even

; < d7: seglist (APTR)

patch_main
	move.l	d7,a1
	add.l	#4,a1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	IFEQ	1
	lea	$DFF120,a1
	move.w	#$2F,d0
.loop
	move.w	#0,(a1)+
	dbf	D0,.loop
	ENDC

	rts
pl_main
	PL_START
	PL_R	$2EE0	; floppy stuff
	PL_PS	$3156,patch_int_3
;	PL_W	$4AA6,'CD'
	PL_END

patch_int_3
	move.l	$6C.W,(2,a0)
	bsr	_flushcache
	rts

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
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
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

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


CDDEVICE_ID = $CDDECDDE

	INCLUDE	cddevice.s

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
	cmp.l	#CDDEVICE_ID,IO_DEVICE(a1)
	beq	cddevice_\1

	move.l	.\1_save\@(pc),-(A7)
	rts
.cont\@
	ENDM
	



_patch_cd32_libs:
	movem.l	D0-A6,-(A7)

	;redirect calls: opendevice/closedevice


	move.l	4.W,a0
	add.w	#_LVOOpenDevice+2,a0
	lea	_opendev_save(pc),a1
	move.l	(a0),(a1)
	lea	_opendev(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseDevice+2,a0
	lea	_closedev_save(pc),a1
	move.l	(a0),(a1)
	lea	_closedev(pc),a1
	move.l	a1,(a0)

	PATCH_IO	DoIO
	PATCH_IO	SendIO
	PATCH_IO	CheckIO
	PATCH_IO	WaitIO
	PATCH_IO	AbortIO

	bsr	_flushcache

	movem.l	(A7)+,D0-A6
	rts

_closedev:
	move.l	IO_DEVICE(a1),D0
	cmp.l	#CDDEVICE_ID,D0
	beq.b	.out

.org
	move.l	_closedev_save(pc),-(a7)
	rts

.out
	moveq	#0,D0
	rts

_opendev:
	movem.l	D0,-(a7)
	bsr	.get_long
	cmp.l	#'cd.d',D0
	beq.b	.cddevice
	bra.b	.org

	; cdtv device
.cddevice
	move.l	#CDDEVICE_ID,IO_DEVICE(a1)
.exit
	movem.l	(A7)+,D0
	moveq.l	#0,D0
	rts

.org
	movem.l	(A7)+,D0
	move.l	_opendev_save(pc),-(a7)
	rts

; < A0: address
; > D0: longword
.get_long
	move.l	a0,-(a7)
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	move.l	(a7)+,a0
	rts


; 68000 compliant way to get a long at any address
; < A0: address
; > D0: longword
get_long_a1
	move.l	a1,-(a7)
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	move.l	(a7)+,a1
	rts


_opendev_save:
	dc.l	0
_closedev_save:
	dc.l	0

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0

;============================================================================

	END
