;*---------------------------------------------------------------------------
;  :Program.	NickFaldoGolf.asm
;  :Contents.	Slave for "Nick Faldo Golf" from Arc Developments
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	13.03.2001
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


	IFD BARFLY
	OUTPUT	"NickFaldosGolf.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000

;======================================================================


	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_Disk	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

DECL_VERSION:MACRO
	incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

_name		dc.b	"Nick Faldo's Championship Golf",0
_copy		dc.b	"1992 Grandslam",0
_info		dc.b	"adapted by Mr.Larmer & fixed by JOTD",10,10
		dc.b	"Greetings to Chris Vella",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	CHIPMEMSIZE-$100,A7	; for hrtmon

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	lea	$8000,a0
	moveq	#$0,d0
	move.l	#$400,d1
	moveq	#1,d2
	bsr.w	_LoadDisk

	movem.l	a0,-(a7)
	move.l	a0,a1
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2

	pea	patch_main(pc)
	move.l	(a7)+,$84.w

	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0

	jmp	$14(a0)

pl_boot
	PL_START
	PL_PS	$A6,Copylock
	PL_PS	$BC,get_expmem
	PL_W	$196,$4E41	; TRAP #1
	PL_P	$1C2,Load
	PL_END

;--------------------------------

Copylock
		move.l	#$9643111F,d0

		move.l	d0,$80.w
		not.l	$80
		add.l	d0,$B4.w

		move.l	d0,d7
		rol.l	#1,d0
		move.l	d0,-(a7)
		moveq	#0,d1
		rol.l	#1,d0
		move.l	d0,d2
		rol.l	#1,d0
		move.l	d0,d3
		rol.l	#2,d0
		move.l	d0,d4
		rol.l	#1,d0
		move.l	d0,d5
		rol.l	#1,d0
		move.l	d0,d6
		move.l	(a7)+,d0
		rts

;--------------------------------

get_expmem
	IFD	USE_FASTMEM
	move.l	_expmem(pc),d0
	ELSE
	move.l	#$80000,d0
	ENDC
	move.l	d0,a0
	rts

;--------------------------------

patch_main
	addq.l	#8,a7

	movem.l	d0-d1/a0-a2,-(a7)

	pea	fix_smc_1(pc)
	move.l	(a7)+,$BC.W	; trap #$F

	patch	$100,emulate_dbf

	bsr	get_expmem
	move.l	d0,a1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	jmp	(a0)


fix_smc_1
	movem.l	d0/a0,-(a7)
	move.l	10(a7),a0	; return address
	moveq	#0,d0
	move.w	(a0),d0		; address offset to add
	ext.l	d0
	add.l	d0,10(a7)
	movem.l	(a7)+,d0/a0
	rte

; < D0: value of D0 in line
; .x: DBF D0,x
emulate_dbf
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
	rts

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

pl_main
	PL_START
	; Mr Larmer

	PL_P	$1F9B0,LoadDos	; load/save games

	; JOTD

	; empty dbf loops

	PL_L	$1707C,$4EB80100
	PL_L	$206A6,$4EB80100
	PL_L	$206BC,$4EB80100
	PL_L	$20E08,$4EB80100
	PL_L	$20E1E,$4EB80100

	; SMC on BRA

	PL_W	$196EE,$4E4F	; replaces BRA opcode by TRAP #F	
	PL_END

;--------------------------------

; RN protected loader

Load
		movem.l	d0-d3/a0-a1,-(a7)

		move.l	d0,-(a7)
		move.l	#$3000,d0
		moveq	#$20,d1
		moveq	#1,d2
		bsr.b	_LoadDisk

		move.l	(a7)+,d0
		lsl.l	#1,d0
		move.l	a0,a1
		add.l	d0,a1
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		move.b	(a1)+,d0
		move.b	(a1)+,d1
		move.b	(a1)+,d2
		move.b	(a1)+,d3

		mulu	#$C,d0
		add.w	d1,d0
		mulu	#$200,d0

		mulu	#$C,d2
		add.w	d3,d2
		mulu	#$200,d2
		move.l	d2,d1
		sub.l	d0,d1

		moveq	#1,d2
		bsr.b	_LoadDisk

		movem.l	(a7)+,d0-d3/a0-a1
		moveq	#0,d0
		rts

;--------------------------------
; Rob Northen track loading routine
; < A0: buffer
; < D0: disk number
; < D1: sector offset (*$200)
; < D2: sector length (*$200)
; < D3: command (ignored)
; > D0: 0 if ok (which is all the time :))

LoadDos
		movem.l	d0-d3/a0-a1,-(a7)

		btst	#0,d3
		bne.b	.write

		btst	#1,d3
		bne.b	.format

		tst.w	d2
		beq.b	.exit	; no data to load

		moveq	#0,d0
		move.w	d1,d0
		mulu	#$200,d0

		moveq	#0,d1
		move.w	d2,d1
		mulu	#$200,d1

		moveq	#2,d2
		bsr.b	_LoadDisk
.exit
		movem.l	(a7)+,d0-d3/a0-a1
		moveq	#0,d0
		rts

.write
.format
		bra.b	.exit

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================

	END
