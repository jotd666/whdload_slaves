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
PATCH_KEYBOARD

	include	"sierra_hdinit.s"

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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	
slv_name		dc.b	"Conquests Of Camelot",0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"Adapted & fixed by JOTD",10,10
		dc.b	"Thanks to UrBi for protection crack",10,10
		dc.b	"Thanks to BTTR/Tony Aksnes for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
	EVEN


; < d1 seglist APTR
; use _get_section to compute segments

_specific_patch
	rts

_mainprog
	dc.b	"prog",0
	even
