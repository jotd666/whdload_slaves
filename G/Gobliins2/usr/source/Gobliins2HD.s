;*---------------------------------------------------------------------------
;  :Program.	Gobliins2HD.asm
;  :Contents.	Slave for "Gobliins2"
;  :Author.	JOTD, from Wepl sources, updated/fixed by StingRay
;  :Original	v1 
;  :Version.	$Id: Gobliins2HD.asm 1.3 2015/07/14 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

; 14-07-2015: 68000 compatibiliy fixes by StingRay (Mantis issue #3218)
;	      (StingRay), some other minor changes in the source
	INCDIR	SOURCES:Include/
	;INCDIR	sources:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	;INCLUDE	lvo/dos.i
	INCLUDE	exec/ables.i

	IFD BARFLY
	OUTPUT	"Gobliins2.slave"
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

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;DOSASSIGN
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
STACKSIZE = 10000
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s
    

		IFND	_LVORectFill
_LVORectFill	= -306
		ENDC
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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

slv_name		dc.b	"Gobliins 2"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
slv_copy		dc.b	"1992 Coktel Vision",0
slv_info		dc.b	"Install & fix by JOTD & StingRay",10,10
		dc.b	"Thanx to Traxx 4 help with country versions",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"loader",0
_args		dc.b	"hd down lg_"
_lang:
	dc.b	"gb",10
_args_end
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
gfxname
	dc.b	"graphics.library",0

slv_config:
    dc.b    "C3:X:Disable blitter fixes:0;"
	dc.b	0

	EVEN


PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1

	ENDM

;============================================================================
;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	;patch gfx base


	lea	gfxname(pc),a1
	moveq	#0,d0
	move.l	$4.W,a6
	jsr	_LVOOpenLibrary(a6)

	move.l	d0,a6	
	PATCH_XXXLIB_OFFSET	RectFill

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found

	;check language
	
		bsr	_language_detection

	;patch here
		bsr	_patchexe

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

	;quit
_quit		pea	(TDREASON_OK).w
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


_patchexe:
	movem.l	D0-A6,-(A7)
	move.l	D7,A1
    move.l  _resload(pc),a2
    lea pl_main(pc),a0
    jsr (resload_PatchSeg,a2)
	movem.l	(a7)+,d0-a6
	rts

pl_main
    PL_START
    PL_PSS  $BE6E,crackit,2
    PL_P    $1564E,dma_wait_1
    PL_PS   $159f4,dma_wait_2
    PL_PS   $15a1a,dma_wait_2
    PL_PS   $15d46,dma_wait_2
    PL_PSS  $16784,dma_wait_3,2
    PL_PSS  $1a6fa,dma_wait_5,2
    PL_PSS  $1a796,dma_wait_4,2
    
    PL_PS  $16150,fix_cia_read
    PL_END
    
fix_cia_read
    MOVEA.L	-4(A5),A0		;16150: 206dfffc
	MOVE.B	(1,A0),D0			;16154: 3010
    rts
    
dma_wait_1:
    MOVE.W	#$000f,_custom+dmacon		;1564e
    bra.b   soundtracker_loop
dma_wait_3:
    MOVE.W	#$0001,_custom+dmacon		;1564e
    bra.b   soundtracker_loop
dma_wait_2
    MOVE.W	D2,_custom+dmacon		;: 33c200dff096
    bra.b   soundtracker_loop
dma_wait_4
	MOVE.W	0(A5,D0.W),_custom+dmacon
    bra.b   soundtracker_loop
dma_wait_5
    MOVE.W	#$8001,_custom+dmacon		;1564e
    
soundtracker_loop
	move.w  d0,-(a7)
	move.w	#6,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts 
    
; taken from skid row crack
; super simple (but efficient)
; skip the first call to this routine
; but only the first one!
;
; when doing this, the protection screen
; doesn't even appear at all!!

crackit:
    lea first_time(pc),a0
    tst.w   (a0)
    beq.b   .skip

    ; call  jsr
    move.l  (a7),a0 ; return address
    add.l   #$0c38a-$0be74,a0
    jsr (a0)
    
    bra.b   .out
    
.skip
    st.b    (a0)
.out
    MOVEA.L	-12(A5),A0
	RTS

first_time
    dc.w    0
    
new_RectFill
	cmp.w	#200,d3
	bcs.b	.d3_ok

	moveq	#0,d3
.d3_ok
	cmp.w	#320,d2
	bcs.b	.d2_ok
	
	; fix wrong access mode -> fastmem MSW read: 79xx: crash

	moveq	#0,d2	; like when code is run from chipmem only

.d2_ok
	move.l	old_RectFill(pc),-(a7)
	rts



fix_wrong_rectfill_xmax
    ; sometimes A0 points partly on correct data
    ; but at 40(A0) there is an address in expansion
    ; memory, so xmax is wrong and it trashes the game
    ; problem is: it's very difficult to detect it when
    ; reaching RectFill because expmem is sometimes 24 bit
    ; memory and it can mix up with real values, causing
    ; issues too
    ;
    ; my idea: when this is wrong, there are several expmem
    ; addresses following:
    ; A0+40 : 47F4 AC40 47F4 7CF0 47F4 2550
    ; when it's correct it's not like that at all
    ; 00021C6E 0140 0002 2674 0000
    ; just mask A0+40 and A0+44 with $FFF0
    ; and if they're identical, just put 0 in xmax
    ; so nothing happens in RectFill
    movem.l d1,-(a7)
	MOVE	40(A0),D0		;21E02: 30280028
	MOVE	44(A0),D1		;21E02: 30280028
    and.w   #$FFF0,d0
    and.w   #$FFF0,d1
    cmp.w   d0,d1
    movem.l (a7)+,d1
    beq.b   .access_fault
    
    ; normal operation
	MOVE	40(A0),D0		;21E02: 30280028
	SUBQ	#1,D0			;21E06: 5340
    rts
    
.access_fault
    clr.w   D0
    rts
    

; detects language according to DISK2.STK file length

_language_detection:
	lea	_disk2stkname(pc),A0
	jsr	resload_GetFileSize(a2)
	cmp.l	#724356,D0		; french
	beq.b	.fr
	cmp.l	#723311,D0		; uk
	beq.b	.uk
	cmp.l	#724889,D0		; german
	beq.b	.ger
	cmp.l	#723970,D0		; italian
	beq.b	.it
	cmp.l	#$B0CA2,D0		; spanish
	beq.b	.sp

	; unknown version

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.end
	lea	_lang(pc),a0
; stingray, 14-jul-2015: 68000 compatibility fix
	ror.w	#8,d0
	move.b	d0,(a0)+
	ror.w	#8,d0
	move.b	d0,(a0)
	rts

.fr
	move.w	#'fr',D0
	bra.b	.end
.uk
	move.w	#'gb',D0
	bra.b	.end
.ger
	move.w	#'de',D0
	bra.b	.end
.it
	move.w	#'it',D0
	bra.b	.end
.sp
	move.w	#'sp',D0
	bra.b	.end




	; for language detection
_disk2stkname:
	dc.b	"DISK2.STK",0
	even

