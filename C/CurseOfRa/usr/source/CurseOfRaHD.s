;*---------------------------------------------------------------------------
;  :Program.	ColonizationHD.asm
;  :Contents.	Slave for "Colonization"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ColonizationHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

	; pass 2 4673578
;============================================================================

;CHIP_ONLY = 1
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE     = $C0000
FASTMEMSIZE     = $0
	ELSE
BLACKSCREEN
CHIPMEMSIZE     = $80000
FASTMEMSIZE     = $40000
	ENDIF
NUMDRIVES       = 1
WPDRIVES        = %1111


;DISKSONBOOT
DOSASSIGN
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU

SETPATCH

STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

assign1
	dc.b	"ra",0


slv_name		dc.b	"Curse Of Ra"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 Rainbow Arts/Cyberstyle",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
        dc.b    "C1:X:Skip introduction:0;"
		dc.b	0

program_floppy:
	dc.b	"ra",0
program_cdtv_intro:
	dc.b	"csi",0
program_cdtv:
	dc.b	"1",0
intro:
	dc.b	"rai",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

_bootdos
		clr.l	$0.W

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
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load intro
		move.l	custom1(pc),d0
		bne.b	.skip
		lea	intro(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l	a5,a5
		bsr	load_exe
	;load exe
.skip
		lea	program_floppy(pc),a0
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		beq.b	.cdtv
		
		lea	program_floppy(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_floppy(pc),a5
		bsr	load_exe
		bra	_quit
.cdtv
		move.l	custom1(pc),d0
		bne.b	.skip2
		lea	program_cdtv_intro(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_cdtv_intro(pc),a5
		bsr	load_exe
.skip2
		lea	program_cdtv(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_cdtv(pc),a5
		bsr	load_exe
		bra	_quit
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_floppy:
	addq.l	#4,d7
	move.l	d7,a1
	lea	pl_floppy(pc),a0
	move.l	(_resload,pc),a2
	jsr	resload_Patch(a2)
	rts
	
patch_cdtv_intro:
	addq.l	#4,d7
	move.l	d7,a1
	lea	pl_cdtv_intro(pc),a0
	move.l	(_resload,pc),a2
	jsr	resload_Patch(a2)
	rts

pl_cdtv_intro
	PL_START
	; fix access faults $DEF00x => $DFF00x
	PL_B	$1d4c+3,$DF
	PL_B	$1d88+3,$DF
	PL_B	$1dde+3,$DF
	PL_END

patch_cdtv:
	addq.l	#4,d7
	move.l	d7,a1
	lea	pl_cdtv(pc),a0
	move.l	(_resload,pc),a2
	jsr	resload_Patch(a2)
	rts

pl_cdtv
	PL_START
	PL_B	$27b6+3,$DF
	PL_B	$2854+3,$DF
	PL_B	$2a24+3,$DF
	PL_B	$2d04+3,$DF
	PL_B	$2dfe+3,$DF
	PL_B	$355a+3,$DF
	PL_B	$3650+3,$DF
	PL_B	$3818+3,$DF
	PL_B	$390e+3,$DF
	PL_B	$3ab8+3,$DF
	PL_B	$3bae+3,$DF
	PL_B	$3d7e+3,$DF
	PL_B	$3e74+3,$DF
	PL_B	$469a+3,$DF
	PL_B	$52c8+3,$DF
	PL_B	$6c2a+3,$DF
	PL_B	$757c+3,$DF
	PL_B	$82f8+3,$DF
	PL_B	$8816+3,$DF
	PL_B	$92ce+3,$DF
	PL_END

pl_floppy
	PL_START
	; fix access faults $DEF00x => $DFF00x
	PL_B	$2762+3,$DF
	PL_B	$2800+3,$DF
	PL_B	$29d0+3,$DF
	PL_B	$2cb0+3,$DF
	PL_B	$2daa+3,$DF
	PL_B	$3506+3,$DF
	PL_B	$35fc+3,$DF
	PL_B	$37c4+3,$DF
	PL_B	$38ba+3,$DF
	PL_B	$3a64+3,$DF
	PL_B	$3b5a+3,$DF
	PL_B	$3d2a+3,$DF
	PL_B	$3e20+3,$DF
	PL_B	$4646+3,$DF
	PL_B	$5252+3,$DF
	PL_B	$6a66+3,$DF
	PL_B	$73b8+3,$DF
	PL_B	$813a+3,$DF
	PL_B	$8658+3,$DF
	PL_B	$9110+3,$DF
	; remove password protection
	PL_B	$adc6,$60
	; avoid cache problem when installing VBL handler
	PL_P	$15d8,flush
	PL_END
	
	
flush:
	bsr	_flushcache
	move.w	#$C000,$DFF09A
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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0

;============================================================================

	END
