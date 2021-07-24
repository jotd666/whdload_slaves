;*---------------------------------------------------------------------------
;  :Program.	BoppinHD.asm
;  :Contents.	Slave for "Boppin"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BoppinHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"CenterCourts2.slave"
	IFND	CHIP_ONLY
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


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $1F0000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CBDOSLOADSEG
;CACHECHIPDATA
CACHE
SEGTRACKER

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick31.s

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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

;assign
;	dc.b	"Boppin",0

slv_name		dc.b	"Center Court 2"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1996-1997 G. Fritsche",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

diskfont:
    dc.b    "libs/diskfont.library",0
tennis_organizer:
	dc.b	"tennis_organizer",0
tennis_intro
    dc.b    "tennis_intro",0
tennis_menues
    dc.b    "tennis_menues",0
tennis_editor1
    dc.b    "tennis_editor1",0
tennis_editor2
    dc.b    "tennis_editor2",0
tennis_match
    dc.b    "tennis_match",0
    
args		dc.b	10
args_end
	dc.b	0
slv_config
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN


    
PATCH_EXE:MACRO
    lea tennis_\1(pc),a0
    bsr bcpl_strcmp
    tst.l   d0
    bne.b   .no_\1
    move.l  d1,a1
    lea pl_\1(pc),a0
    jsr resload_PatchSeg(a2)
    bra   .out
.no_\1
    ENDM
    
_cb_dosLoadSeg:
    move.l  _resload(pc),a2
    add.l   d0,d0
    add.l   d0,d0
    move.l  d0,a1
    PATCH_EXE   organizer
    PATCH_EXE   intro
    PATCH_EXE   menues
    PATCH_EXE   match
    PATCH_EXE   editor1
    PATCH_EXE   editor2

    move.l  1(a1),d0
;    cmp.l   #'tenn',d0
;    bne.b   .out
;    
.out
    rts
    
_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

        lea     diskfont(pc),a0
        bsr must_exist
        
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase


	;load exe
		lea	tennis_organizer(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l   a5,a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


pl_organizer
	PL_START
	PL_L	$0dc0,$74004E71 ; fake VBR read to D2
	PL_END

pl_intro
	PL_START
	PL_L	$3c98,$74004E71 ; fake VBR read to D2
	PL_END
    
pl_menues
	PL_START
	PL_L	$1b6a2,$74004E71 ; fake VBR read to D2
	PL_END

pl_editor1
	PL_START
	PL_L	$07408,$74004E71 ; fake VBR read to D2
	PL_END

pl_editor2
	PL_START
	PL_L	$5072,$74004E71 ; fake VBR read to D2
	PL_END

pl_match
	PL_START
	PL_L	$1f8b8,$74004E71 ; fake VBR read to D2
	PL_END



; < a0: str1
; < a1: str2 (BCPL)
; > d0: -1: fail, 0: ok

bcpl_strcmp:
	movem.l	d1-d2/a0-a2,-(A7)
	move.b	(A1)+,d2
.contstrcmpasm
	move.b	(A0)+,d0
	beq.s	.termstrcmpasm
    subq.b  #1,d2
	bmi.s	.failstrcmpasm
	move.b	(A1)+,d1
	bsr.s	.letterstrcmpasm
	exg	d0,d1
	bsr.s	.letterstrcmpasm
	cmp.b	d0,d1
	bne.s	.failstrcmpasm
	bra.s	.contstrcmpasm

.termstrcmpasm
	tst.b   d2
	bne.s	.failstrcmpasm
	moveq.l	#0,d0
	bra.s	.endstrcmpasm

.letterstrcmpasm
	cmp.b	#$60,d0
	bls.s	.letter1strcmpasm
	cmp.b	#$7a,d0
	bhi.s	.letter1strcmpasm
	sub.b	#$20,d0
.letter1strcmpasm
	rts

.failstrcmpasm
	moveq.l	#-1,d0
.endstrcmpasm
	movem.l	(A7)+,d1-d2/a0-a2
	rts

; < A0 filename

must_exist
	movem.l	d0-d1/a0-a1/a3/a6,-(a7)
	move.l	a0,d1
    move.l  d1,-(a7)
	lea	_dosname(pc),a1
	move.l	$4.W,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6   ; A6 = dosbase
    move.l  (a7)+,d1
    
	move.l	d1,a3
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	move.l	d0,d1
	beq.b	.error
	jsr	_LVOUnLock(a6)
	movem.l	(a7)+,d0-d1/a0-a1/a3/a6
	rts

.error
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
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
