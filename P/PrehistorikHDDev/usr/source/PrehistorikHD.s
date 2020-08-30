;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"Prehistorik.Slave"
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
WPDRIVES	= %1111

BLACKSCREEN
DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
CBDOSLOADSEG
PROTECT_WHD_CALLS

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"Prehistorik",0
slv_copy		dc.b	"1990 Titus",0
slv_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Kickstarter 34.005 by Wepl",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
	EVEN

slv_CurrentDir
	dc.b	0
	even
;============================================================================

	;initialize kickstart and environment

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D0,D0
	add.l	D0,D0
	move.l	D0,a0
	cmp.b	#'m',1(a0)
	bne.b	.skip
	cmp.b	#'a',2(a0)
	bne.b	.skip
.notlast
	add.l	d1,d1
	add.l	d1,d1
	move.l	d1,a1
	move.l	(a1),d1
	bne.b	.notlast

	patch	$100.W,_emulate_dbf

	lea	_patchlist(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
.skip	
	rts

_patchlist:
	PL_START
	; remove disk access

	PL_W	$205BE-$1AF54,$4E71

	; remove protection

	PL_L	$56B4,$6000014C
	PL_W	$5958,$33FC
	PL_B	$5958+8,$60

	; fix music

	PL_L	$895A-$3620,$4EB80100

	PL_END

_quit
	PEA	TDREASON_OK
	MOVE.L	_resload(PC),-(A7)
	add.l	#resload_Abort,(a7)
	rts

_emulate_dbf:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$20,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

;============================================================================

	END

