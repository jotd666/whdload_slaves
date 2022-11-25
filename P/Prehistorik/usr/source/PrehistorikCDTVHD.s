;*---------------------------------------------------------------------------
;  :Program.	BubbleNSqueakHD.asm
;  :Contents.	Slave for "BubbleNSqueak"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BubbleNSqueakHD.asm 1.3 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"PrehistorikCDTV.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;DEBUG
	IFD	DEBUG
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
DOSASSIGN
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 6000
BOOTDOS
CACHE

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	kick13.s
	
;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	
_assign1
	dc.b	"Bubble1",0
_assign2
	dc.b	"bubble2",0
slv_config
 	dc.b	0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Prehistorik CDTV"
			IFD	DEBUG
			dc.b	" (DEBUG MODE)"
			ENDC
			dc.b	0
slv_copy		dc.b	"1991 Titus",0
slv_info		dc.b	"Install/fix by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_program:
	dc.b	"main",0

_args		dc.b	10
_args_end
	dc.b	0
	EVEN

	include 	"cdtv_device.s"
	
;============================================================================

	;initialize kickstart and environment


_bootdos
	bsr	_patch_cdtv

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
;		lea	_assign1(pc),a0
;		sub.l	a1,a1
;		bsr	_dos_assign
;		lea	_assign2(pc),a0
;		sub.l	a1,a1
;		bsr	_dos_assign

	move.l	(_resload,pc),a2		;A2 = resload
		lea	_program(pc),a0
		jsr	resload_GetFileSize(a2)
		cmp.l	#137356,d0
		beq.b	_cdtvver
		
		bra.b	_wrongver  ; only ECS version supported by this slave
_cdtvver
	;load exe
	lea	_program(pc),a0
	lea	_args(pc),a1
	moveq	#_args_end-_args,d0
	lea	_patch_exe(pc),a5
	bsr	_load_exe
	;quit
_quit	
	pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)

	
; < d7: seglist (BPTR)

_patch_exe:

	rts

_wrongver
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
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
	movem.l	d2/a4,-(a7)
	jsr	(a5)
	movem.l	(a7)+,d2/a4
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

