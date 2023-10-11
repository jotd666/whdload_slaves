	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"BDefender.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
    
NUMDRIVES	= 1
WPDRIVES	= %0000

;CHIP_ONLY
	IFD	CHIP_ONLY
DEBUG
	ELSE
BLACKSCREEN
	ENDC

CACHE
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS

;============================================================================
	IFD	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0	
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
	ENDC
	
    
slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick31.s



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_name
	dc.b	"Blitz Defender",0
slv_copy		dc.b	"199x yyyy",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version 1.0 "

		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN
_rampath:
	dc.b	"RAM:",0
_assign:
	dc.b	"ENV",0
_program:
	dc.b	"defender.prg",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN
	

;============================================================================

	;initialize kickstart and environment

_bootdos	move.l	(_resload,pc),a2		;A2 = resload


		; align exe memory on round value
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$20000-$1d50C-$7B0,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC
		
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		
		
	;assigns
		lea	_assign(pc),a0
		lea		_rampath(pc),a1
		bsr	_dos_assign


	;load exe
		lea	_program(pc),a0
		move.l	a0,a3
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;patch
		lea	pl_main(pc),a0
		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)


		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		add.l	d7,d7
		add.l	d7,d7
		move.l	d7,a1

		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts



pl_main:
    PL_START 
	PL_NOP	$0004c,4		; no close workbench
	PL_R	$0b29a			; no waitTOF (takes forever)
    PL_L  $0b2fe,$74004E71	; VBR at 0
    PL_L  $0de68,$74004E71	; VBR at 0
    PL_END

