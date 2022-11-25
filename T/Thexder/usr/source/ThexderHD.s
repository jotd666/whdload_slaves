;*---------------------------------------------------------------------------
;  :Program.	ThexderHD.asm
;  :Contents.	Slave for "Thexder"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ThexderHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"Thexder.slave"
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
FASTMEMSIZE	= $0
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN

;INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


_assign
	dc.b	"Thexder",0

slv_name		dc.b	"Thexder"
		IFD	DEBUG
		dc.b	"(DEBUG MODE)"
		ENDC
		dc.b   0
slv_copy		dc.b	"1988 Sierra",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config
        dc.b    "C1:X:infinite energy:0;"
        dc.b    "C2:X:alternate palette:0;"
        dc.b    "C3:X:sfx mode by default:0;"
		dc.b	0

_program:
	dc.b	"Thex",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

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

; < d7: seglist (APTR)

patch_game
	move.l	d7,a1
	addq.l	#4,a1
	IFD	DEBUG
	move.l	a1,$FC.W
	ENDC
	patch	$100,emulate_dbf
	lea	pl_game(pc),a0
	jsr	resload_Patch(a2)

	rts

SET_PALETTE_COLOR:MACRO
	move	#\2,\1*6(a5)
	move	#\3,\1*6+2(a5)
	move	#\4,\1*6+4(a5)
	ENDM

change_game_palette
	LEA	-30720(A4),A5		;2322: 4BEC8800
	move.l	_custom2(pc),d0
	beq.b	.skip
	SET_PALETTE_COLOR	1,13,0,0
	SET_PALETTE_COLOR	2,9,7,15
	SET_PALETTE_COLOR	3,14,13,15
.skip
	addq.l	#8,(A7)
	rts

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
	rts

clear_pointer
	move.l	D0,-4(a5)
	beq.b	.out
	movem.l	d0-d2/a0-a1,-(a7)
	move.l	d0,a0
	lea	$0.W,a1
	moveq	#1,d0
	moveq	#1,d1
	moveq	#0,d2
	moveq	#0,d3
	jsr	_LVOSetPointer(a6)
	movem.l	(a7)+,d0-d2/a0-a1
.out
	tst.l	-4(a5)
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

main_loop
	movem.l	a1,-(a7)
	move	$DFF016,d1	; trashing D1 because used just after
	btst	#14,d1
	bne.b	.nobut2

	lea	-17030(A4),a1
	move.w	#$F00,$dff180
	MOVE	#1,20(A1)		; activate shield
	move	#$ff00,$DFF034
.nobut2
	movem.l	(a7)+,a1
; stolen code
	ADD	D0,D0			;2A20: D040
	MOVE	0(A0,D0),D1		;2A22: 32300000
	rts
	
pl_game
	PL_START
	PL_IFC1
	; infinite energy
	PL_R	$41E0
	PL_R	$41E6
	PL_ENDIF
	
	PL_PS	$2A20,main_loop
	
	PL_IFC3
	PL_B	$1EC,$66	; sfx instead of music by default
	PL_ENDIF

	; no mouse pointer

	IFEQ	1
	PL_PS	$68C,clear_pointer
	PL_W	$692,$4E71
	ENDC

	; protection

	PL_R	$624

	; empty dbf loops

	PL_L	$25D2,$4EB80100
	PL_L	$2606,$4EB80100
	PL_L	$2638,$4EB80100
	PL_L	$266C,$4EB80100

	; palette change

	PL_PS	$2322,change_game_palette

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
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	;;bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

_tag
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;============================================================================

	END
