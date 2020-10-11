;*---------------------------------------------------------------------------
;  :Program.	DeathMaskCD32HD.asm
;  :Contents.	Slave for "DeathMaskCD32"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
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
	INCLUDE	lvo/intuition.i


;CHIP_ONLY

	IFD BARFLY
	OUTPUT	"DeathMaskCD32.slave"

	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	ENDC

	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0
HRTMON
	ELSE
CHIPMEMSIZE	= $1E0000
FASTMEMSIZE	= $40000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
INITAGA
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'

QUIT_JOYPAD_MASK = JPF_BUTTON_FORWARD|JPF_BUTTON_REVERSE|JPF_BUTTON_PLAY

DUMMY_CD_DEVICE = 1
;USE_DISK_LOWLEVEL_LIB
;USE_DISK_NONVOLATILE_LIB

;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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
slv_name		dc.b	"Death Mask CD³²"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
	dc.b	0
slv_copy	dc.b	"1995 Apache",0
slv_info	dc.b	"Adapted by JOTD",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
		dc.b	0
assign
	dc.b	"CD0",0

_exename_pal:
	dc.b	"main",0

_args		dc.b	10
_args_end
	dc.b	0
lowlname:
    dc.b    "lowlevel.library",0    
	EVEN

; +$0542 read joy port 1 routine (firepal)
;============================================================================

	;initialize kickstart and environment

_bootdos
	; configure the button emulation

	bsr	_patch_cd32_libs

	IFND	USE_DISK_LOWLEVEL_LIB
	lea	OSM_JOYPAD1KEYS(pc),a0
	move.w	#$4019,2(a0)	; SPACE = bomb, P = pause
	move.w	#$4545,4(a0)	; both charcoal: ESC so ESC quits the game in pause mode

	move.l	_resload(pc),a2		;A2 = resload
    lea	(tag,pc),a0
    jsr	(resload_Control,a2)

    movem.l (a7)+,a6    
	ENDC


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load program

		lea	_exename_pal(pc),A0

	;load exe
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

patch_exe:
    rts
    
	move.l	d7,a1
	add.l	#4,a1

	
	lea	pl_pal(pc),a0

	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts


pl_pal
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

	add.l	d7,d7
	add.l	d7,d7

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	a3-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a3-a6/d7
.skip
	;call
	move.l	d7,a1

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

is_ntsc
	dc.w	0
  
tag		dc.l	WHDLTAG_CUSTOM3_GET
trainer_start_level	dc.l	0

		dc.l	0   
;============================================================================
