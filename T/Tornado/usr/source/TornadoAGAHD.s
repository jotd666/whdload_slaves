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
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"TornadoAGA.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1FE000
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
CBDOSLOADSEG
BOOTDOS

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_name		dc.b	"Tornado AGA",0
slv_copy		dc.b	"1994 Digital Integration",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"shell",0
_args		dc.b	10
_args_end
	dc.b	0
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

	cmp.b	#3,(a0)
	bne.b	.nosmv
	cmp.b	#'m',2(A0)
	bne.b	.nosmv

	; SMV

	move.l	d1,a0
	move.w	#$4EB9,$7C94(a0)
	pea	fix_af_smv(pc)
	move.l	(a7)+,$7C96(a0)

.nosmv
	cmp.b	#'f',1(a0)
	bne.b	.out
	cmp.b	#'l',2(a0)
	bne.b	.out

	; 'flight': main flight simulation

	bsr	.getbounds
	lea	.unrolled_loop(pc),a2
	move.l	#42,d0
.unroll
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.out
	move.l	#20,d0
	lea	.unrolled_loop_fast(pc),a3
.cp
	move.w	(a3)+,(a0)+
	dbf	d0,.cp

	bra.b	.unroll
.out
	rts	


.getbounds
	move.l	d1,a0
	move.l	a0,a1
	add.l	#$59000,a1
	rts

.unrolled_loop:
	dc.w	$2368,$0118,$0118
	dc.w	$2368,$00F0,$00F0
	dc.w	$2368,$00C8,$00C8
	dc.w	$2368,$00A0,$00A0
	dc.w	$2368,$0078,$0078
	dc.w	$2368,$0050,$0050
	dc.w	$2368,$0028,$0028

.unrolled_loop_fast:
	dc.w	$2368,$0028,$0028
	dc.w	$2368,$0050,$0050
	dc.w	$2368,$0078,$0078
	dc.w	$2368,$00A0,$00A0
	dc.w	$2368,$00C8,$00C8
	dc.w	$2368,$00F0,$00F0
	dc.w	$2368,$0118,$0118


fix_af_smv:
	MOVE	D1,D3			;07C94: 3601
	BMI.B	.negative
	MULU	#$0140,D3		;07C96: C6FC0140
	rts
.negative
	; avoids access fault
	moveq	#0,d3
	rts

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

_hexsearch:
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


_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

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

