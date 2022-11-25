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
	OUTPUT	"LeisureSuitLarry3.Slave"
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
CHIP_ALIGN = $9870

    IFD CHIP_ONLY
CHIPMEMSIZE	= $120000
FASTMEMSIZE	= $0000
HRTMON
BOOTEARLY
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
    ENDC
    
IOCACHE = 50000
;SEGTRACKER
;
;SETPATCH

;============================================================================

PATCH_KEYBOARD = 1
PATCH_MT32 = 1
MAINPROG        ; english version has "sq3" alternate "prog" main name
CRACKIT = 1
;CHANGE_SAVEDIR   ; not needed / would require patching german version too

;============================================================================

	include	"sierra_hdinit.s"
   
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
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
slv_name		dc.b	"Space Quest 3 - The Pirates of Pestulon",0

    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1989 Sierra",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
			dc.b	"Thanks to BTTR for disk images",10,10
			dc.b	"Version "
		DECL_VERSION
		dc.b	0
_rename_file:
    rts
    
    IFD CHIP_ONLY
_bootearly:

    IFD CHIP_ALIGN
    movem.l d0-d1/a0-a1/a6,-(a7)
    ; we have to waste $30000 kb before we can properly align first segment!
    move.l  #$30000,d0
    move.l  #MEMF_CHIP,d1
    move.l  $4.W,a6
    jsr (_LVOAllocMem,a6)
    move.l  #CHIP_ALIGN,d0
    move.l  #MEMF_CHIP,d1
    move.l  $4.W,a6
    jsr (_LVOAllocMem,a6)
    movem.l (a7)+,d0-d1/a0-a1/a6
    ENDC
    rts
    ENDC
    
_specific_patch
    add.l   d1,d1
    add.l   d1,d1  
    
	move.w	#0,d2
	bsr	_get_section
    cmp.l   #$4e55ffda,6(a0)
    beq.b   .german
    cmp.l   #$4e55fa66,6(a0)
    beq.b   .english
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.english    
	move.w	#3,d2    
	bsr	_get_section
	; close stuff: quit
	add.l	#$226,a0
	cmp.l	#$48E760E2,(a0)
	bne.b	.noquk
	move.w	#$4EF9,(a0)+
	pea	_quit(pc)
	move.l	(a7)+,(a0)

	; avoid access fault when course is selected

	move.w	#18,d2
	bsr	_get_section
	move.l	a0,a1
	lea	pl_af_uk(pc),a0
    move.l  _resload(pc),a2
	jsr	resload_Patch(a2)
	moveq.l	#0,d0    
	bra.b	.out
.noquk
	; german, quit
.german
    lea pl_german(pc),a0
    move.l  d1,a1
    addq.l  #4,a1
    move.l  _resload(pc),a2
    jsr resload_Patch(a2)

.noqg
	moveq.l	#1,d0    ; no generic patches
	; assign for saves

	;move.w	#0,d2
	;bsr	_get_section
	;lea	_prog_start(pc),a1
	;move.l	2(a0),(a1)
	;pea	_assign_it(pc)
	;move.l	(a7)+,2(a0)
    
    
.out
	rts

pl_german
     PL_START
     PL_PSS $05978,insert_umlaut,4
     PL_PSS $059ee,cancel_umlaut,4
     PL_P   $1EF58,_quit
     PL_END
pl_af_uk
	PL_START
	PL_PS	$8422-$7E44,avoid_af
	PL_END

; there is some indirection mixup at some point,
; but this is an harmless access fault, since the game
; manages with it...

avoid_af
	addq.l	#2,(a7)
	movem.l	d0,-(a7)
	move.l	(a0),d0
	cmp.l	#'DEST',d0
	movem.l	(a7)+,d0
	beq.b	.avoid

	; normal operation

	MOVE.L	(A0),-1030(A5)		;08422: 2B50FBFA
	MOVEA.L	-1030(A5),A0		;08426: 206DFBFA
	rts
.avoid
	add.l	#$4C-$2A,(a7)	; skip the rest of the crap
	rts

_mainprog:
    dc.b    3,"sq3",0     ; bcpl string
    even