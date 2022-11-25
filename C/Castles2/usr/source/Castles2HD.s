;*---------------------------------------------------------------------------
;  :Program.	Castles2HD.asm
;  :Contents.	Slave for "Castles2"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: Castles2HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Castles2.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;DEBUG	; non-volatile library problem if DEBUG set

CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $100000

NUMDRIVES	= 1
WPDRIVES	= %0000


;DISKSONBOOT
DOSASSIGN
HDINIT
INITAGA
;HRTMON
IOCACHE		= 15000
STACKSIZE = 80000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA
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

cd0_assign
	dc.b	"CD0",0
castles2_assign
	dc.b	"Castles2",0
jff_assign
	dc.b	"jff",0	; if you don't replace df0 by jff the game won't save
env_assign
	dc.b	"ENV",0	; if you don't assign ENV: the game won't load savegames
ram
	dc.b	"ram:",0

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name		dc.b	"Castles 2 CD³²",0
slv_copy		dc.b	"1992 Interplay",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Castles2",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	_resload(pc),a2		;A2 = resload

	;open doslib
	
	lea	(_dosname,pc),a1
	move.l	(4),a6
	jsr	(_LVOOldOpenLibrary,a6)
	move.l	d0,a6			;A6 = dosbase

	;assigns
	lea	cd0_assign(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	lea	castles2_assign(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	lea	jff_assign(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	lea	env_assign(pc),a0
	lea	ram(pc),a1
	bsr	_dos_assign

	bsr	_patch_cd32_libs

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
	moveq	#4,d2
	bsr	get_section
	move.l	a1,a0
	add.l	#$A1CC-$AD0,a1
	lea	.df0(pc),a2
	moveq	#4,d0
.loop
	bsr	hexsearch
	cmp.l	#0,a0
	beq.b	.out
	move.b	#'j',(a0)+
	move.b	#'f',(a0)+
	move.b	#'f',(a0)+
	bra.b	.loop
.out

	IFEQ	1
	moveq	#0,d2
	bsr	get_section
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	ENDC

	rts
.df0
	dc.b	"df0:"
	even

pl_main
	PL_START
	PL_END

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

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
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
	movem.l	a2-a6/d2-d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a2-a6/d2-d7
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
	; not done here because access fault (corrupt memory?)
;;;	jsr	(_LVOUnLoadSeg,a6)

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


;============================================================================
