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
	OUTPUT	"IM2025AGA.slave"
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
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES=%1111

;DISKSONBOOT
DOSASSIGN
INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 8000
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
	
slv_name		dc.b	"Impossible Mission 2025 (AGA)"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1993 Microprose",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
		dc.b	0

assign1
			dc.b	"a_impossible_mission",0
assign2
			dc.b	"b_impossible_mission",0
			
_program:
	dc.b	"loader",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

_bootdos
	clr.l	$0.W

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

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
	move.w	$3EE(a1),d0
	cmp.w	#$2C79,d0
	bne.b	wrong_version
	; add lives if needed
	
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	
	rts
	
	
pl_boot:
	PL_START
	PL_PS	$3EE,patch_main
	PL_END
	
patch_main:
	movem.l	D0-D1/A0-A2,-(A7)
	lea	pl_main(pc),a0
	move.l	d0,a1
	add.l	a1,a1
	add.l	a1,a1
	move.l	a1,a2
	add.l	#$27274,a2
	cmp.w	#$4E7A,(a2)
	bne.b	wrong_version
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(A7)+,D0-D1/A0-A2
	move.l	$4.W,a6	; stolen code
	rts

pl_main:
	PL_START
	PL_B	$227A8-$21FA4,$60		; any code passes protection check
	PL_S	$21FF2-$21FA4,6		; skips protection screen (patch above is useless)
	PL_L	$49218-$21FA4,$91C84E71	; removes VBR read, replaces by 0
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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts



