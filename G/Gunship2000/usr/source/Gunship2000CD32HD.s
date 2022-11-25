;*---------------------------------------------------------------------------
;  :Program.	Gunship2000HD.asm
;  :Contents.	Slave for "Gunship2000"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: Gunship2000HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Gunship2000CD32.slave"
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
FASTMEMSIZE	= $00000
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
DEBUG
HDINIT
INITAGA
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
CACHE

FORCEPAL
BOOTDOS
QKSTRUCT

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick31.s
	INCLUDE	fakepad.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

; keys

_qkstruct:
	dc.w	$50,$0,$51,0,$52,$0,$53,0,$54,0,$55,0

_assign1
	dc.b	"CD0",0
_assign2
	dc.b	"Gunship_2000",0
_assign3
	dc.b	"ENV",0


DECL_VERSION:MACRO
	incbin	"slave_version"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

slv_name		dc.b	"Gunship 2000 CD³²",0
slv_copy		dc.b	"1992 Microprose",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
_rampath:
	dc.b	"RAM:",0
_program:
	dc.b	"Gunship 2000",0
_args		dc.b	10
_args_end
	dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

	EVEN

;DUMMY_CD_DEVICE = 1
USE_DISK_LOWLEVEL_LIB
USE_DISK_NONVOLATILE_LIB

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	_assign3(pc),a0
		lea	_rampath(pc),a1
		bsr	_dos_assign

		bsr	_patch_joypad

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_gs2000(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

_patch_gs2000
	RTS

	move.l	d7,a1
	add.l	A1,A1
	add.l	A1,A1
	addq	#4,A1
	illegal
	lea	_pl_gs2000(pc),a0
	jsr	resload_Patch(a2)
	illegal
	rts

_pl_gs2000:
	PL_START
	PL_L	$154,$4E714E71
	PL_B	$168,$60
	PL_END

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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts



	END
