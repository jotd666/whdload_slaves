;*---------------------------------------------------------------------------
;  :Program.	PreyHD.asm
;  :Contents.	Slave for "Guardian"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: GuardianHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9

;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"PreyCD32.slave"
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
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0
    ELSE
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $80000
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
INITAGA
;HRTMON
IOCACHE		= 300
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'


INIT_LOWLEVEL
INIT_NONVOLATILE


;============================================================================

	INCLUDE	whdload/kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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

_assign1
	dc.b	"ENV",0
_ram
	dc.b	"RAM:",0
_assign2
	dc.b	"Prey",0

slv_name		dc.b	"Prey CD³²"
        IFD CHIP_ONLY
        dc.b    " (DEBUG/CHIP mode)"
        ENDC
        dc.b    0
slv_copy		dc.b	"1994 Almathera",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Version "
		DECL_VERSION
	dc.b	0
slv_config:
	dc.b	0

slv_CurrentDir:
	dc.b	"data",0


_program:
	dc.b	"moreno/prey",0
_args		dc.b	10
_args_end
	dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

_bootdos

		bsr		_patch_cd32_libs

		lea	(_lowlevelname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOpenLibrary,a6)
		lea		_lowlevelbase(pc),a0
		move.l	d0,(a0)
		bne.b	.ok
		illegal
.ok
		
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		
		
	;assigns
		lea	_assign1(pc),a0
		lea		_ram(pc),a1
		bsr	_dos_assign
  
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
  

        IFD CHIP_ONLY
		; chip-only mode: exe starts at $20000
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$20000-$0001B120,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

        

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


    
; < d7: seglist

patch_main
	move.l	d7,a1
	add.l	#4,a1

	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts


pl_main
	PL_START

	PL_END



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
	movem.l	d0-a6,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d0-a6
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
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

tag		dc.l	WHDLTAG_CUSTOM1_GET
	dc.l	0

CDDEVICE_ID = $CDDECDDE

	INCLUDE	cddevice.s

PATCH_IO:MACRO
	move.l	$4.W,a0
	add.w	#_LVO\1+2,a0
	lea	.\1_save\@(pc),a1
	move.l	(a0),(a1)
	lea	.\1\@(pc),a1
	move.l	a1,(a0)
	bra.b	.cont\@
.\1_save\@:
	dc.l	0
.\1\@:
	cmp.l	#CDDEVICE_ID,IO_DEVICE(a1)
	beq	cddevice_\1

	move.l	.\1_save\@(pc),-(A7)
	rts
.cont\@
	ENDM
	



_patch_cd32_libs:
	movem.l	D0-A6,-(A7)

	;redirect calls: opendevice/closedevice


	move.l	4.W,a0
	add.w	#_LVOOpenDevice+2,a0
	lea	_opendev_save(pc),a1
	move.l	(a0),(a1)
	lea	_opendev(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseDevice+2,a0
	lea	_closedev_save(pc),a1
	move.l	(a0),(a1)
	lea	_closedev(pc),a1
	move.l	a1,(a0)

	PATCH_IO	DoIO
	PATCH_IO	SendIO
	PATCH_IO	CheckIO
	PATCH_IO	WaitIO
	PATCH_IO	AbortIO

	bsr	_flushcache

	movem.l	(A7)+,D0-A6
	rts

_closedev:
	move.l	IO_DEVICE(a1),D0
	cmp.l	#CDDEVICE_ID,D0
	beq.b	.out

.org
	move.l	_closedev_save(pc),-(a7)
	rts

.out
	moveq	#0,D0
	rts

_opendev:
	movem.l	D0,-(a7)
	bsr	.get_long
	cmp.l	#'cd.d',D0
	beq.b	.cddevice
	bra.b	.org

	; cdtv device
.cddevice
	move.l	#CDDEVICE_ID,IO_DEVICE(a1)
.exit
	movem.l	(A7)+,D0
	moveq.l	#0,D0
	rts

.org
	movem.l	(A7)+,D0
	move.l	_opendev_save(pc),-(a7)
	rts

; < A0: address
; > D0: longword
.get_long
	move.l	a0,-(a7)
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	move.l	(a7)+,a0
	rts


; 68000 compliant way to get a long at any address
; < A0: address
; > D0: longword
get_long_a1
	move.l	a1,-(a7)
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	move.l	(a7)+,a1
	rts


_opendev_save:
	dc.l	0
_closedev_save:
	dc.l	0

_lowlevelbase
	dc.l	0
_lowlevelname
	dc.b	"lowlevel.library",0

;============================================================================

	END
