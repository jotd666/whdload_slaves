;*---------------------------------------------------------------------------
;  :Program.	TornadoHD.asm
;  :Contents.	Slave for "Tornado"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: TornadoHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"TornadoECS.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
HDINIT
DOSASSIGN
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;DEBUG
CBDOSLOADSEG
BOOTDOS

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

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

disk1:
	dc.b	"disk1",0
disk2:
	dc.b	"disk2",0
disk3:
	dc.b	"disk3",0
disk4:
	dc.b	"disk4",0

slv_name		dc.b	"Tornado ECS",0
slv_copy		dc.b	"1994 Digital Integration",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"Version "
			DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"disk1/shell",0
_args		dc.b	10
_args_end
	dc.b	0
	dc.b	"$VER: Tornado ECS "
	DECL_VERSION
	dc.b	0
	EVEN
	EVEN

;============================================================================

	;initialize kickstart and environment


; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	
	addq.l	#4,d1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

;	cmp.b	#3+6,(a0)
;	bne.b	.nosmv
;	cmp.b	#'m',2+6(A0)
;	bne.b	.nosmv

	; SMV


;.nosmv
	cmp.b	#'f',1+6(a0)
	bne.b	.out
	cmp.b	#'l',2+6(a0)
	bne.b	.out

	; 'flight': main flight simulation

	move.l	d1,a1
	lea	pl_flight(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
.out
	rts	

pl_flight:
	PL_START
	PL_PS	$2D5C6,fix_snoop1
	PL_END

; fix display on AGA machines

fix_snoop1
	MOVE.W	#$3081,142(A6)		;2D5CA: 1D43008E
	MOVE.W	#$30C1+$C800,144(A6)		;2D5D2: 1D430090
	add.l	#10,(a7)
	rts

	IFEQ	1	
fix_af_smv:
	MOVE	D1,D3			;07C94: 3601
	BMI.B	.negative
	MULU	#$0140,D3		;07C96: C6FC0140
	rts
.negative
	; avoids access fault
	moveq	#0,d3
	rts
	ENDC

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	disk1(pc),a0
		move.l	a0,a1
		bsr	_dos_assign
		lea	disk2(pc),a0
		move.l	a0,a1
		bsr	_dos_assign
		lea	disk3(pc),a0
		move.l	a0,a1
		bsr	_dos_assign
		lea	disk4(pc),a0
		move.l	a0,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist



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
	jsr	(a5)
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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
