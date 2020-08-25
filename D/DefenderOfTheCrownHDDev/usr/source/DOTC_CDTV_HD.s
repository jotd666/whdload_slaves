;*---------------------------------------------------------------------------
;  :Program.	DefenderOfTheCrownCDTVHD.asm
;  :Contents.	Slave for "DefenderOfTheCrownCDTV"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: DefenderOfTheCrownCDTVHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"DefenderOfTheCrownCDTV.slave"
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
CHIPMEMSIZE = $100000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
;HRTMON
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 8000
BOOTDOS
BLACKSCREEN
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s


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
;	cmp.l	#$B0DEB0DE,IO_DEVICE(a1)
;	beq.b	_handle_bookmark
	; ignore (cdtv.device)
.ignore\@
	moveq.l	#0,D0
	rts
.org\@
	move.l	.\1_save\@(pc),-(A7)
	rts
.cont\@
	ENDM

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

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	incbin	"slave_version"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

assign1
	dc.b	"Defender",0

slv_name		dc.b	"Defender Of The Crown CDTV",0
slv_copy		dc.b	"1985-1989 Master Designer Software",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Thanks to Dr Bong for disk image",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"doc",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		bsr	_patch_cdtv
	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_main
	move.l	d7,A1
	addq.l	#4,A1
	sub.l	#$A408,A1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts
pl_main
	PL_START

	; ignore cdtv device tests (no music is playing anyway)

	PL_NOP	$B672,2
	PL_NOP	$155E0,2
	PL_NOP	$15582,2
	PL_NOP	$15590,2
	PL_END

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

_opendev_2:
	movem.l	D0,-(a7)
	GETLONG	A0,D0
	cmp.l	#'cdtv',D0
	beq.b	.cdtv
;	cmp.l	#'book',D0
;	beq.b	.bookmark
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

_closedev_2:
	move.l	IO_DEVICE(a1),D0
	lea	_fake_cdtvbase(pc),a0
	cmp.l	a0,d0
	beq.b	.out
;	cmp.l	#$B0DEB0DE,D0
;	beq.b	.out

.org
	move.l	_closedev_save_2(pc),-(a7)
	rts

.out
	moveq	#0,D0
	rts

_opendev_save_2:
	dc.l	0
_closedev_save_2:
	dc.l	0

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
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
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

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
