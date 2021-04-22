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
	OUTPUT	"HoyleVolumeIII.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;CHIP_ONLY
;============================================================================

;CHIPMEMSIZE	= $180000
;FASTMEMSIZE	= $0000
    IFD CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE	= $0
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $90000    ; $80000 works but sound is crap
BLACKSCREEN
    ENDC
;HRTMON
;MEMFREE	= $100
;NEEDFPU
SETPATCH
IOCACHE = 50000
;============================================================================


;============================================================================

PATCH_SOUND
PATCH_KEYBOARD
PATCH_MT32

	include	"sierra_hdinit.s"
	IFD BARFLY
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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
slv_name		dc.b	"Hoyle Volume III"
    IFD CHIP_ONLY
    dc.b       "(DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"Adapted & fixed by JOTD",10,10
			dc.b	"Version "
			DECL_VERSION
            dc.b    0
		EVEN

; < A0: filename
; > A0: new name
_rename_file:
    cmp.b   #'1',(a0)
    bne.b   .nopat
    cmp.b   #'.',(1,a0)
    bne.b   .nopat
    cmp.b   #'p',(2,a0)
    bne.b   .nopat
    cmp.b   #'t',(4,a0)
    bne.b   .nopat
    lea .1palname(pc),a0
    
.nopat
    rts
.1palname
    dc.b    "101.pat",0
    even
    
; < a1 seglist BPTR
; use resload_PatchSeg on it

_specific_patch
    move.l  _resload(pc),a2
    lea pl_main(pc),a0
    jsr (resload_PatchSeg,a2)
	moveq.l	#0,d0       ; 0 means apply generic patches too
	rts

pl_main
    PL_START
    PL_PS   $f6c0,avoid_af
    PL_PS   $f7d0,avoid_af
    PL_PS   $f62c,avoid_af
    PL_END
    
avoid_af:
    cmp.l   #0,a0
    beq.b   .avoid
	CMPI.W	#$1234,-10(A0)		;0f62c: 0c681234fff6 
    rts
.avoid:
    eor #4,CCR  ; flip Z
    rts
    
_mainprog
	dc.b	4,"prog",0
	even

