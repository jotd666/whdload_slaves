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
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;CHIP_ONLY
;STACKSIZE=$20000

	IFD BARFLY
	OUTPUT	"Wonderboy.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


	IFND	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $200000
BLACKSCREEN
DEBUG
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
HRTMON
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
BOOTDOS
CACHE
HDINIT
DOSASSIGN
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
;SEGTRACKER
;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

    
;============================================================================

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

slv_name		dc.b	"Wonderboy"
		IFD		CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
			dc.b	0
slv_copy		dc.b	"2022 Acidbottle",0
slv_info		dc.b	"adapted by CFou! & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_args:
	dc.b	10
_args_end:
	dc.b	0
_program:
	dc.b	"wonderboy.exe",0

	EVEN

;============================================================================


	;initialize kickstart and environment


_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

    
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase


    IFD CHIP_ONLY
    move.l  a6,-(a7)
    move.l  4,a6
    move.l  #$20000-$00019430,d0
    move.l  #MEMF_CHIP,d1
    jsr     _LVOAllocMem(a6)
    move.l  (a7)+,a6
    ENDC

	;load exe
		lea	_program(pc),a0
		move.l	a0,a3
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;patch
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
        addq.l  #4,a1
        
        bsr	_patchexe

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1

		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check

		movem.l	d0/d7/a2/a6,-(a7)

		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		; running the unpack segment
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)
        bra.b _quit
.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
    
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
_quit
		pea	TDREASON_OK
        move.l  _resload(pc),a2
		jmp	(resload_Abort,a2)


     
_patchexe

    lea pl_unpack(pc),a0 
    jsr resload_Patch(a2)
    rts
    
pl_unpack:
    PL_START
	PL_P		$0015a,end_decrunch
    PL_END
	
pl_main:
    PL_START
	PL_B		$43770-$20000,$60	; skip VBR read
	PL_P		$4555e-$20000,read_vbr
	PL_B		$4e468-$20000,$60	; skip VBR read
	PL_R		$481b4-$20000		; skip vblank sync at start that locks up!
    PL_END


read_vbr:
	sub.l	a0,a0
	rte
	
end_decrunch:
	; cranker shit
	ADDA.L	A1,A1			;0015a: d3c9
	ADDA.L	A1,A1			;0015c: d3c9
	move.l	a1,-(a7)
	move.l	_resload(pc),a2
	lea		pl_main(pc),a0
	jsr		(resload_Patch,a2)
	moveq	#_args_end-_args,d0
	lea	(_args,pc),a0
	; game is unpacked & patched: run
	rts
	
    
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts

   
    
