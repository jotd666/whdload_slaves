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
	OUTPUT	"Ugh.slave"
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


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s

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
	ENDM

slv_name		dc.b	"Ugh"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1992 PlayByte - Ego Software",0
slv_info		dc.b	"adapted by Asman & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

intro:
	dc.b	"loader",0
program:
	dc.b	"t",0
highs:
	dc.b	"ugh.high",0
args		dc.b	10
args_end
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

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
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
		lea	intro(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l	a5,a5
		bsr	load_exe
	;quit
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

load_highs:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;1d2: 48e7fffe
	LEA	highs(PC),A0	;1d6: 41fafed1
	MOVEA.L	_resload(PC),A2	;1da: 247a0d92
	JSR	resload_GetFileSize(A2)			;1de: 4eaa0024
	TST.L	D0			;1e2: 4a80
	BEQ.W	LAB_000B		;1e4: 67000012
	LEA	highs(PC),A0	;1e8: 41fafebf
	MOVEA.L	hiscore_buffer(PC),A1		;1ec: 227a0054
	JSR	resload_LoadFile(A2)			;1f0: 4eaa0008
	BSR.W	hiscore_encrypt		;1f4: 61000032
LAB_000B:
	MOVEM.L	(A7)+,D0-D7/A0-A6	;1f8: 4cdf7fff
	RTS				;1fc: 4e75

save_highs:
	MOVE.B	#$0d,8(A2)		;1fe: 157c000d0008 original code
	MOVEM.L	D0-D7/A0-A6,-(A7)	;204: 48e7fffe
	BSR.W	hiscore_encrypt		;208: 6100001e
	MOVEQ	#106,D0			;20c: 706a
	MOVEA.L	hiscore_buffer(PC),A1		;20e: 227a0032
	LEA	highs(PC),A0	;212: 41fafe95
	MOVEA.L	_resload(PC),A2	;216: 247a0d56
	JSR	resload_SaveFile(A2)			;21a: 4eaa000c
	BSR.W	hiscore_encrypt		;21e: 61000008
	MOVEM.L	(A7)+,D0-D7/A0-A6	;222: 4cdf7fff
	RTS				;226: 4e75

hiscore_encrypt:
	MOVEM.L	D0/A0,-(A7)		;228: 48e78080
	MOVEA.L	hiscore_buffer(PC),A0		;22c: 207a0014
	MOVEQ	#25,D0			;230: 7019
LAB_000E:
	EORI.L	#$9bedafec,(A0)+	;232: 0a989bedafec
	DBF	D0,LAB_000E		;238: 51c8fff8
	MOVEM.L	(A7)+,D0/A0		;23c: 4cdf0101
	RTS				;240: 4e75

hiscore_buffer:
	dc.l	0			;242: 00000000
	
; < d7: seglist (APTR)

patch_main
	moveq.l	#8,d2
	bsr	get_section
	ADDA.L	#$1fe,A1		;11e: d1fc000001fe
	LEA	hiscore_buffer(PC),A2		;124: 45fa011c
	MOVE.L	A1,(A2)			;128: 2488

	moveq.l	#0,d2
	bsr	get_section

	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	
	BSR.W	load_highs		;188: 61000048
	rts
	
pl_main
	PL_START
	PL_L	$18,$93c94e71	; remove VBR access	(sub.l  A1,A1 + NOP)
	; keyboard
	PL_PSS	$51B2,kbdelay,8


	PL_NOP	$5224,16
	PL_PS	$2506,save_highs
	PL_END
	
CIAB_PRA	EQU	$BFD000
CIAA_SDR	EQU	$BFEC01
CIAA_CRA	EQU	$BFEE01
VHPOSR		EQU	$DFF006

kbdelay:
	MOVEM.L	D1-D2,-(A7)		;194: 48e76000
	MOVE.B	CIAA_SDR,D0		;198: 103900bfec01
	MOVE.B	#$00,CIAA_SDR		;19e: 13fc000000bfec01
	ORI.B	#$40,CIAA_CRA		;1a6: 0039004000bfee01
	MOVEQ	#2,D1			;1ae: 7202
LAB_0008:
	MOVE.B	VHPOSR,D2		;1b0: 143900dff006
LAB_0009:
	CMP.B	VHPOSR,D2		;1b6: b43900dff006
	BEQ.W	LAB_0009		;1bc: 6700fff8
	DBF	D1,LAB_0008		;1c0: 51c9ffee
	ANDI.B	#$bf,CIAA_CRA		;1c4: 023900bf00bfee01
	move.b	d0,d1
	ror.b	#1,d1
	not.b	d1
	cmp.b	_keyexit(pc),d1
	bne.b	.out
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.out
	MOVEM.L	(A7)+,D1-D2		;1cc: 4cdf0006
	RTS
	
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
	add.l	d7,d7
	add.l	d7,d7
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
