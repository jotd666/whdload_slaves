;*---------------------------------------------------------------------------
;  :Program.	BoppinHD.asm
;  :Contents.	Slave for "Boppin"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BoppinHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"AsvancedSkiSimulator.slave"
	IFND	CHIP_ONLY
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


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
;CACHECHIPDATA
CACHE
SEGTRACKER

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0



slv_name		dc.b	"Advanced Ski Simulator"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 Codemasters",0
slv_info		dc.b	"adapted by Mr Larmer & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"game",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	;dc.b    "C1:X:Trainer Infinite lives:0;"
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
;		lea	assign(pc),a0
;		sub.l	a1,a1
;		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_main
	bsr	get_version
    move.l  d7,a1
	cmp.l	#1,d0
	beq.b	.v1
	lea	pl_v2(pc),a0
	jsr	resload_PatchSeg(a2)
.skip
	rts
.v1
    add.l   a1,a1
    add.l   a1,a1
    addq.l  #4,a1
    ; decrypt Rob Northen copylock
	move.l	a1,-(a7)
lbC000846:
	move.l	#$A3EF1306,d0
	moveq	#0,d1
	move.l	#$14D5CE00,d2
	move.l	#$40005A02,d3
	move.l	#$A5A804DE,d4
	moveq	#$56,d5
	move.l	(a7),a6
	lea	$846(a6),A6
	adda.w	#$156-$28,A6
	move.l	#$6824,D6
	add.l	A6,D6
lbC000858:
	roxl.l	#1,D0
	roxl.l	#1,D1
	roxl.l	#1,D2
	roxl.l	#1,D3
	roxl.l	#1,D4
	roxl.l	#1,D5
	eor.l	D0,(A6)+
	cmpa.l	D6,A6
	bne.s	lbC000858
lbC00086A:
	move.l	(a7),a6
	lea	$86A-$28(a6),A6
	move.l	A6,D6
	subi.l	#$842,D6
	adda.w	#$132,A6
	movem.l	D0-D2/A0-A2,-(SP)
	cmpi.w	#$3E9,2(A6)
	bne.s	lbC0008D2
	move.l	4(A6),D0
	lsl.l	#2,D0
	lea	8(A6),A1
	lea	0(A1,D0.L),A2
	cmpi.l	#$3EC,(A2)+
	bne.s	lbC0008D2
lbC00089E:
	move.l	(A2)+,D1
	beq.s	lbC0008D2
	move.l	(A2)+,D0
	bsr.s	lbC0008BC
	move.l	A0,D2
	tst.l	-4(A2)
	bne.s	lbC0008B0
	move.l	D6,D2
lbC0008B0:
	move.l	(A2)+,D0
	add.l	D2,0(A1,D0.L)
	subq.l	#1,D1
	bne.s	lbC0008B0
	bra.s	lbC00089E

lbC0008BC:
	movea.l	D6,A0
	subq.l	#4,A0
	tst.l	D0
	beq.s	lbC0008CE
lbC0008C4:
	movea.l	(A0),A0
	adda.l	A0,A0
	adda.l	A0,A0
	subq.l	#1,D0
	bne.s	lbC0008C4
lbC0008CE:
	addq.l	#4,A0
	rts

lbC0008D2:
	movem.l	(SP)+,D0-D2/A0-A2

	move.l	(a7)+,a0
	lea	$9A4-$28(a0),A0
	movea.l	A0,A1
	suba.w	#$97C,A1
	movea.w	#$53D4,A2
	movea.w	#$1DC4,A3
	movea.l	A1,A4

	move.l	a2,d0
.copy
	move.l	(a0)+,(a1)+
	subq.l	#4,d0
	bne.b	.copy
	move.l	a3,d0
.clear
	clr.l	(a1)+
	subq.l	#4,d0
	bne.b	.clear

    sub.l	a0,a0
    moveq	#0,d0

    ; get seglist as BCPL so PatchSeg can be called
    lea	(-4,a4),a1
    move.l  a1,d0
    lsr.l   #2,d0
    move.l  d0,a1

    
	lea pl_v1(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_PatchSeg,a2)

    rts
    

; sub $10 to make up for segment offsets that we don't have
; in our flat disassembly of the loaded segments
pl_v1
	PL_START
    PL_PS    $2327c-$1ba90-$10,DMA1
    PL_PS    $23910-$1ba90-$10,DMA2
    PL_PS    $2391a-$1ba90-$10,DMA2
	PL_END
    
pl_v2
	PL_START
    PL_S    0,$1C   ; skip stupid protection
    PL_PS    $5a18,DMA1
    PL_PS    $60ac,DMA2
    PL_PS    $60b6,DMA2
	PL_END


get_version:
	movem.l	d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#51236,D0
	beq.b	.v1

	cmp.l	#48808,d0
	beq.b	.v2

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.v1
	moveq	#1,d0
	bra.b	.out
.v2
	moveq	#2,d0
	bra	.out
.out
	movem.l	(a7)+,d1/a1
	rts

DMA1
	move.w	d5,$DFF096
	bra.b	WaitDMA
DMA2
	bsr.b	WaitDMA
	move.w	d1,$DFF096
WaitDMA
		movem.l	d0-d1,-(a7)
		moveq	#4,d1			;8.5 * 63.5µs = 0.54 ms
.1
		move.b	$dff006,d0
.2
		cmp.b	$dff006,d0
		beq.b	.2
		dbf	d1,.1
		movem.l	(a7)+,d0-d1
		rts

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
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


	jsr	(a5)
	bsr	_flushcache
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

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0

;============================================================================

	END
