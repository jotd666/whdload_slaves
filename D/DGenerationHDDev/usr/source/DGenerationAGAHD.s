;*---------------------------------------------------------------------------
;  :Program.	DGenerationHD.asm
;  :Contents.	Slave for "DGeneration"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: DGenerationHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"DGenerationAGA.slave"
	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================
;DEBUG

	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 8000
BOOTDOS
CACHE
slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_ReqAGA|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include 	kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"2.3"
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
	
slv_name		dc.b	"D/Generation (AGA)"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1993 Mindscape",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
		dc.b    "C1:L:Start with lives:5,25,45;"			
		dc.b    "C2:B:Infinite power weapons;"			
		dc.b    "C3:B:Don't steal power weapons at level 89;"			
		dc.b	0

_program:
	dc.b	"DGen",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

_bootdos
	clr.l	$0.W

	move.l	_resload(pc),a2		;A2 = resload
	lea	_whdtags(pc),a0
	jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

_patch_exe:
	moveq.l	#0,d2
	bsr	get_section
	move.w	$e62(a1),d0
	cmp.w	#$197C,d0
	bne.b	wrong_version
	; add lives if needed
	
	lea	pl_train(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	
	rts
	
game_init:
	movem.l	d0,-(a7)
	move.l	_nb_lives(pc),d0
	beq.b	.sk
	mulu	#20,d0
	add.w	d0,$e64(a1)
.sk
	add	#5,D0
	MOVE.B	D0,(1296,A4)
	
	move.l	_power_weapons(pc),d0
	beq.b	.skpw
	
	moveq.l	#9,d0
	move.b	d0,(1305,A4)
	move.b	d0,(1306,A4)
	move.b	d0,(1307,A4)
	move.b	d0,(1308,A4)
.skpw
	movem.l	(a7)+,d0
	rts
	
pl_train:
	PL_START
	PL_PS	$00e62,game_init
	
	PL_IFC2
	PL_NOP	$1424a,2	; check if player has bombs
	PL_NOP	$1427c,2	; does not substract bombs
	
	PL_NOP	$1414a,4	; check lasers
	PL_NOP	$141d2,2	; sub lasers
	PL_NOP	$14196,2	; sub lasers
	
	PL_NOP	$1421a,2	; check freezers
	PL_NOP	$14236,2	; sub freezers
	
	PL_NOP	$1424a,2	; check bombs
	PL_NOP	$1427c,2	; sub bombs
	
	PL_NOP	$050d8,2	; check grenades
	PL_NOP	$05bee,2	; sub grenades

	PL_NOP	$141e2,2	; check shields
	PL_NOP	$141f6,2	; sub shields
	
	PL_ENDIF
	PL_IFC3
	PL_B	$07cb6,$60	; don't remove special weapons at level 89
	PL_ENDIF
	PL_END
	
wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
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
	movem.l	d0-a6,-(a7)
	jsr	(a5)
	movem.l	(a7)+,d0-a6
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
	lsr.l	#2,d7
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

_whdtags
		dc.l	WHDLTAG_CUSTOM1_GET
_nb_lives:
		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_power_weapons:
		dc.l	0
		dc.l	0

