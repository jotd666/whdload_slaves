;*---------------------------------------------------------------------------
;  :Program.	ConquestOfTheLongbowHD.asm
;  :Contents.	Slave for "ConquestOfTheLongbow"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ConquestOfTheLongbowHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"ConquestsLongbow.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFND	DEBUG
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $200000
BLACKSCREEN
	ELSE
CHIPMEMSIZE	= $80000+$C0000
FASTMEMSIZE	= $0000
HRTMON
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 20000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
;BOOTDOS
CBDOSLOADSEG = 1
CACHE
SETPATCH

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


;============================================================================

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"Conquests Of The Longbow"
		IFD	DEBUG
		dc.b	" (DEBUG MODE)"
		ENDC
			dc.b	0
slv_copy		dc.b	"1992 Sierra",0
slv_info		dc.b	"adapted by JOTD",10
			dc.b	"Thanks to BTTR for disk images",10,10
			dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

	even

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	move.l	d0,a0
	add.l	a0,a0
	add.l	a0,a0
	cmp.b	#4,(a0)
	bne.b	.skip_prog

	; prog

	; section 53 - quit

	move.l	#53,d2
	bsr	_get_section	
	add.l	#$6BA-$46C,a0
	cmp.w	#$48E7,(a0)
	bne.b	.nofix
	move.w	#$4EF9,(a0)+
	pea	_quit(pc)
	move.l	(a7)+,(a0)
.nofix

.skip_prog
	rts

; < d1 seglist
; < d2 section #
; > a0 segment
_get_section
	move.l	d1,a0
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	dbf	d2,.loop
.out
	addq.l	#4,a0
	rts

_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)



_wrong_version:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================
