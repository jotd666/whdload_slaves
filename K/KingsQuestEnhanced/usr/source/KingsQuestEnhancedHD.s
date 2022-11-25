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
	OUTPUT	"KingsQuestEnhanced.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


STACKSIZE = 6000

;CHIP_ONLY
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $120000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

    
IOCACHE = 50000
SEGTRACKER
;
;SETPATCH

;============================================================================

PATCH_KEYBOARD = 1
PATCH_MT32 = 1


;============================================================================

	include	"sierra_hdinit.s"
   
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"Kings Quest I: Quest For The Crown (Enhanced)"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
        even
        
_rename_file:
    rts

    
_specific_patch
    move.l  d1,a1
    lea     pl_main(pc),a0
    move.l  _resload(pc),a2
    jsr resload_PatchSeg(a2)

    lea	(_dosname,pc),a1
    move.l	(4),a6
    jsr	(_LVOOldOpenLibrary,a6)
    move.l  d0,a0
    ; no more delete (to avoid OS swaps on savegames)
    ; done in generic patches, but we can't enable them
	add.w	#_LVODeleteFile,a0
	move.w	#$4EF9,(a0)+
	lea	_deletefile(pc),a1
	move.l	a1,(a0)

	moveq.l	#1,d0    ; no generic patches
	rts

pl_main
	PL_START
	PL_PS	$3092,copy_savedir
	PL_PS	$1ED78,delay_loop
    PL_P    $1e98c,_quit    ; intercept quit sequence else game locks up
	PL_END

    
delay_loop:
	movem.l	D0,-(a7)
	move.l	#$1000,D0
	bsr	beamdelay
	movem.l	(A7)+,d0
	addq.l	#$8,(a7)
	rts


; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
	



copy_savedir
	movem.l	a0/a1,-(a7)
	move.l	(12,A7),a1	; dest
    lea .syssave(pc),a0
.copy
    move.b  (a0)+,(a1)+
    bne.b   .copy
	movem.l	(a7)+,a1/a0

	bsr	_flushcache

	rts
.syssave
    dc.b    "SYS:save",0
    even
