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
	OUTPUT	"KingsQuest4.Slave"
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
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
HRTMON
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
    ENDC
    
IOCACHE = 50000
; segtracker doesn't work yet here, triggers errors in ROM
;SEGTRACKER
;
;SETPATCH

;============================================================================

PATCH_KEYBOARD = 1
PATCH_SOUND = 1



;============================================================================

	include	"sierra_hdinit.s"
   
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
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"King's Quest 4"
    IFD CHIP_ONLY
    dc.b    "(DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"Adapted & fixed by JOTD",10,10
			dc.b	"Thanks to Icy[ool & BTTR for disk images",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
			even

_rename_file:
    rts
    

; < d1 seglist APTR
; use _get_section to compute segments

_specific_patch
    move.l  _resload(pc),a2
    
    movem.l d1,-(a7)
    lea progname(pc),a0
    jsr (resload_GetFileSize,a2)
    cmp.l   #115784,d0      ; BTTR (crack) / V1
    beq.b   .v1
    cmp.l   #116300,d0      ; V2
    beq.b   .v2
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
    
.v1
    lea pl_v1(pc),a0
	;;move.l	#-$6834,d0
    move.l  #-26636,d0
    bra.b   .patch
.v2
    lea pl_v2(pc),a0
	;;move.l	#-$6804,d0
    move.l  #-26588,d0

.patch        
	lea	_variable_offset(pc),a1
	move.l	d0,(a1)
	; in case the game reboots...

	lea	_prot_counter(pc),a1
	clr.l	(a1)
    
    
    movem.l (a7)+,a1

    patch   $100,_patch_prot_bttr
    
    ; patch
    jsr (resload_PatchSeg,a2)
	moveq.l	#0,d0       ; without generic patches it crashes HARD
    rts


pl_v1
    PL_START
    PL_L    $09c88,$4EB80100    ; install protection hook
    PL_END
pl_v2
    PL_START
    PL_L    $09ce4,$4EB80100    ; install protection hook
    PL_END


_patch_prot_bttr:
	movem.l	d1/a1,-(a7)
	lea	_prot_counter(pc),a1
	move.l	_variable_offset(pc),d1
	tst.l	(a1)
	bne.b	.skip
	clr	(a4,d1.l)
	move.l	#1,(a1)
	bra.b	.out
.skip
	move.w	d0,(a4,d1.l)
.out
	movem.l	(a7)+,d1/a1
	rts    
    
    ; alternate protection by JOTD
    ; BTTR crack version is much better because screen doesn't
    ; even appear
    IFEQ    1
_patch_prot:
	lea	_prot_counter(pc),a1
	addq.l	#1,(a1)
	cmp.l	#$1E,(A1)
	bne	.org

	; at this point, the user just pressed RETURN
	; at the protection check
	; "replay" of page 4 word 7 third paragraph

	lea	-$e4a(a3),a1

	move.w	#$013c,$cdc(a1)	; password configuration
	move.l	#'with',$cde(a1)
	move.w	#0,$ce2(a1)
.org
	move.l	d0,-(a7)
	move.l	_variable_offset(pc),d0
	move.l	(a4,d0.L),a1
	move.l	(a7)+,d0
	move.w	(2,a1),(a3)
	rts
    ENDC
    
_prot_counter
	dc.l	0

_variable_offset:
	dc.l	0
progname
    dc.b    "prog",0
    