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
	OUTPUT	"FaeryTaleAdventure.slave"
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
FASTMEMSIZE	= $40000
NUMDRIVES	= 2
WPDRIVES	= %0010	; df0 is write protected, df1 isn't

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
CBDOSLOADSEG
;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

;============================================================================
	IFD	BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"Faery Tale Adventure",0
slv_copy		dc.b	"1986 Microillusions",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir
		dc.b	0
	EVEN

;============================================================================

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	clr.l	0.W

	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a0
	cmp.b	#5,(a0)
	bne.b	.nomain
	cmp.b	#'f',1(a0)
	bne.b	.nomain

	add.l	d1,d1
	add.l	d1,d1
	move.l	d1,a1
	addq.l	#4,a1
	lea	_pl_main(pc),a0

	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
.nomain
	rts

_pl_main
	PL_START

	; password protection

	PL_L	$1242,$4E714E71

	; music fix

	PL_B	$CC56,$39	; audvol
	PL_PS	$CC62,clr_audvol
	PL_PS	$CC6C,clr_audvol_2	; audvol
	PL_PS	$CF2C,clr_audvol
	PL_L	$D126,$42914E71
	PL_PS	$D12A,clr_4_a1
	PL_L	$D15C,$42914E71
	PL_PS	$D160,clr_4_a1

	; quit whdload on game quit

	PL_P	$D878,quit	; close device
	PL_P	$D888,quit	; close library

	PL_END

clr_4_a1:
	clr.l	4(a1)
	;clr.b	4(a1)
	;clr.b	5(a1)
	;clr.b	6(a1)
	;clr.b	7(a1)

	rts

clr_audvol_2
	move.w	#0,168(a4)
	move.l	16(a1),32(a3)	; stolen
	add.l	#4,(A7)
	rts

clr_audvol
	move.w	#0,168(a4)
	rts

quit
		PEA	TDREASON_OK
		MOVE.L	_resload(PC),-(A7)
		add.l	#resload_Abort,(a7)
		rts

;============================================================================

	END

