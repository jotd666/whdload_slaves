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
	OUTPUT	"MixedUpMotherGoose.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


;CHIP_ONLY


    IFD CHIP_ONLY
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $0000
HRTMON
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $A0000
    ENDC
    
IOCACHE = 50000

;
;SETPATCH

;============================================================================

PATCH_KEYBOARD = 1     ; seems to crash the game!
PATCH_MT32 = 1


; expmem+A0C1A: workout counters

;============================================================================

	include	"sierra_hdinit.s"
   
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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

slv_name		dc.b	"Mixed-up Mother Goose"
    IFD CHIP_ONLY
    dc.b    "(DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
slv_copy		dc.b	"199x Sierra",0
slv_info		dc.b	"Adapted & fixed by JOTD",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
			even

_rename_file:
    rts
    

_specific_patch
    rts
