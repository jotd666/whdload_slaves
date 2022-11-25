;*---------------------------------------------------------------------------
;  :Program.	TheHumansCD32HD.asm
;  :Contents.	Slave for "TheHumansCD32"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: TheHumansCD32HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"TheHumansCD32.slave"
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
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= 0
	ELSE
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $40000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
;INITAGA
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


DUMMY_CD_DEVICE = 1
USE_DISK_LOWLEVEL_LIB
USE_DISK_NONVOLATILE_LIB

;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


_assign1
	dc.b	"CD0",0

slv_name	dc.b	"The Humans CD³²"
		IFD	DEBUG
		dc.b	" (DEBUG)"
		ENDC
		dc.b	0
slv_copy	dc.b	"1992 GameTek",0
slv_info	dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Set CUSTOM1=1 to skip introduction",10,10	
		dc.b	"Version "
		incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

	dc.b	"$","VER: slave "
		incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
		dc.b	$A,$D,0
	ENDC

	EVEN

_intro:
	dc.b	"anim",0
_program:
	dc.b	"game",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload

	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	_patch_cd32_libs

	;load exe
		move.l	_custom1(pc),d0
		bne.b	.skipintro

		; skip intro after reboot

		move.l	skip_intro(pc),d0
		bne.b	.skipintro

		lea	_intro(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_intro(pc),a5
		bsr	_load_exe
.skipintro
	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_game(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

patch_intro
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_intro(pc),a0
	move.l	(_resload,pc),a2
	jsr	resload_Patch(a2)
	rts

; < d7: seglist

patch_game
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_game(pc),a0
	move.l	(_resload,pc),a2
	jsr	resload_Patch(a2)
	rts

reboot
	lea	skip_intro(pc),a0
	move.l	#1,(a0)

	lea	.doit(pc),a5
	move.l	$4.W,a6
	jsr	_LVOSupervisor(a6)
.doit
	move.w	#$2700,SR
	bra	kick_reboot

pl_intro
	PL_START
	PL_L	$1F6,$70004E73	; VBR access
	PL_P	$1B0,reboot
	PL_END


pl_game
	PL_START
	PL_L	$1224,$70004E73	; VBR access

	PL_PS	$5BC6,blit_fix
	PL_PS	$5BD6,blit_fix
	PL_PS	$5BE6,blit_fix
	PL_PS	$5BF6,blit_fix
	PL_PS	$5C06,blit_fix
	PL_PS	$5C16,blit_fix
	PL_PS	$5C26,blit_fix
	PL_END

blit_fix
	MOVEM.L A1-A4,72(A6)	; stolen
	TST.B	dmaconr(a6)
	BTST	#6,dmaconr(a6)
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr(a6)
	BNE.S	.wait
	TST.B	dmaconr(a6)
.end
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

	add.l	d7,d7
	add.l	d7,d7

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	a4-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a4-a6/d7
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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0
skip_intro
	dc.l	0

;============================================================================
