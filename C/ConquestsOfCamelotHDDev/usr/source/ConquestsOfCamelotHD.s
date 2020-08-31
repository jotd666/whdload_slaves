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

	IFD BARFLY
	OUTPUT	"ConquestsOfCamelot.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;CHIPMEMSIZE	= $100000
;FASTMEMSIZE	= $0000
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $C0000
IOCACHE = 50000

;HRTMON
;SETPATCH

;============================================================================



;============================================================================

; fix glitches in sound replay
PATCH_SOUND

	include	"sierra_hdinit.asm"

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
	
slv_name		dc.b	"Conquests Of Camelot",0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"Adapted & fixed by JOTD",10,10
		dc.b	"Thanks to BTTR/Tony Aksnes for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
	EVEN


; < d1 seglist APTR
; use _get_section to compute segments

_specific_patch
	; section 36:protection

	move.w	#36,d2
	bsr	_get_section
	add.l	#$B70,a0
	move.w	#$4EB9,(a0)+
	pea	_crack(pc)
	move.l	(a7)+,(a0)

	moveq.l	#0,d0
	rts
	

_crack
	cmp.l	#'Pres',(8,a3)
	bne.b	.orig

	; crack it: tell it what it wants to hear at the flower check

	move.w	(2,a3),(a3)

	; one check instead of three

	move.w	#2,4(a3)
.orig
	move.w	(a3),d0
	addq.w	#2,a2
	move.w	d0,(a2)
	rts

_mainprog
	dc.b	4,"prog",0
	even
