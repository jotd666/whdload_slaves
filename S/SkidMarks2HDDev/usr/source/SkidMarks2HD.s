;*---------------------------------------------------------------------------
;  :Program.	SkidMarks2HD.asm
;  :Contents.	Slave for "SkidMarks2"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SkidMarks2HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;DEBUG

	IFD BARFLY
	OUTPUT	"SkidMarks2.slave"
	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD	DEBUG
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $800000	; 8 megs
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
INITAGA
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'


DUMMY_CD_DEVICE = 1
	; lowlevel not used by the game
USE_DISK_LOWLEVEL_LIB
;USE_DISK_NONVOLATILE_LIB

;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.2"
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

_assign1
	dc.b	"CD0",0
_assign2
	dc.b	"SkidMarks2",0

slv_name		dc.b	"SkidMarks 2 floppy / CD³²"
			IFD	DEBUG
			dc.b	"(DEBUG MODE)"
			ENDC
			dc.b	0
slv_copy		dc.b	"1995 Acid Software",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program_cd32:
	dc.b	"skid2cd",0
_program_floppy:
	dc.b	"skidmarks2",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	_resload(pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	patch_main_cd32(pc),a5
		lea	_program_cd32(pc),a0
		move.l	_resload(pc),a2
		movem.l	a0,-(a7)
		jsr	resload_GetFileSize(a2)
		movem.l	(a7)+,a0
		cmp.l	#236816,d0
		beq.b	.cd32
		
		IFEQ	1
		lea	_program_floppy(pc),a0
		move.l	_resload(pc),a2
		movem.l	a0,-(a7)
		jsr	resload_GetFileSize(a2)
		movem.l	(a7)+,a0
		
		cmp.l	#243108,d0
		beq.b	.floppy
		ENDC
		
		pea	TDREASON_WRONGVER
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

.floppy
		lea	patch_main_floppy(pc),a5
		bra	.load
.cd32
		bsr	_patch_cd32_libs
.load
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		bsr	_load_exe
	;quit
_quit
		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

patch_main_cd32
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_main_cd32(pc),a0
	jsr	resload_Patch(a2)
	rts

pl_main_cd32
	PL_START
	PL_P	$28d70,quit
	PL_P	$29d6c,quit
	PL_P	$2e5e4,quit
	PL_L	$29C0C,$74004E71	; remove VBR access
	PL_END


; < d7: seglist

patch_main_floppy
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_main_floppy(pc),a0
	jsr	resload_Patch(a2)
	rts

pl_main_floppy
	PL_START
	PL_L	$2B58C,$74004E71	; remove VBR access
	PL_END

quit:
	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

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

	add.l	d7,d7
	add.l	d7,d7

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	a4-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a4-a6/d7
.skip
	;call
	move.l	d7,a1

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

;============================================================================
