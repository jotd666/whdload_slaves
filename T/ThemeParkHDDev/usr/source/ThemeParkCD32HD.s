;*---------------------------------------------------------------------------
;  :Program.	ThemeParkAGAHD.asm
;  :Contents.	Slave for "ThemeParkAGA"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ThemeParkAGAHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"ThemeParkCD32.slave"
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
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
    ELSE
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $A0000
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG
INITAGA
HDINIT
;HRTMON
IOCACHE		= 160000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
SEGTRACKER

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA|WHDLF_Req68020
slv_keyexit	= $5D	; num '*'


;============================================================================
DUMMY_CD_DEVICE
	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b    "3.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


slv_name		dc.b	"Theme Park CD32",0
slv_copy		dc.b	"1993 Bullfrog",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"main",0

_args		dc.b	10
_args_end
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,0
slv_config
		dc.b	0

	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

		lea	_tag(pc),a0
		jsr	resload_Control(a2)

    IFD CHIP_ONLY
    move.l  4,A6
    move.l  #0,D1
    move.l  #$50000-$42AE8,d0
    jsr (_LVOAllocMem,a6)
    ENDC
    
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

        bsr get_version

        bsr _patch_cd32_libs
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_maincd32_patch(pc),a5
		bsr	_load_exe

_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)



get_version:
	movem.l	d1/a1,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)


	cmp.l	#763692,d0      ; "main" is the main proggy
	beq.b	.cd32


	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.out
    movem.l	(a7)+,d1/a1
    rts
.cd32
    bra.b   .out
    
_maincd32_patch
	move.l	d7,a1
	lea	_patchlist_cd32(pc),a0
	jsr	resload_PatchSeg(a2)

	rts

_patchlist_cd32:
	PL_START
	PL_P	$568f4,_set_intena
    PL_PS   $56478,_keyboard_hook
	PL_END

_keyboard_hook
	MOVE.W	D0,D1			;56478: 3200
	NOT.B	D1			;5647a: 4601
	ROR.B	#1,D1			;5647c: e219
    cmp.b   _keyexit(pc),d1
    beq _quit
    rts
    
_set_intena:
	bsr	_flushcache
	move.w	#$8020,$DFF09A
	; enable video & sprite DMA (else: black screen!)
	move.w	#$8120,$dff096
	rts

_emulate_dbf:
	move.l	D0,-(A7)
	move.l	D7,D0
	divu.w	#$9,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	move.l	(A7)+,D0
	rts

avoid_af_1
    cmp.l   #CHIPMEMSIZE,a1
    bcs.b   .ok
    cmp.l   _expmem(pc),a1
    bcc.b   .ok
    move.w  #$0F0,$DFF180   ; TEMP signal access fault avoid
    rts
.ok
	NOT.W	D4			;53bf4: 4644
	AND.W	D4,(0,A1,D1.W)		;53bf6: c9711000
    rts
    

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found



	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	jsr	(a5)
.skip
	;call
	add.l	d7,d7
	add.l	d7,d7
	move.l	d7,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
    lsr.l   #2,d7
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
    dc.l    WHDLTAG_LANG_GET
_language
        dc.l    0
		dc.l	0

;============================================================================

	END
