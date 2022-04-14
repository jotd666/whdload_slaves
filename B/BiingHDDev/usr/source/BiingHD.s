;*---------------------------------------------------------------------------
;  :Program.	BiingHD.asm
;  :Contents.	Slave for "Biing"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BiingHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Biing.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $300000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DEBUG
INITAGA
HDINIT
;HRTMON
IOCACHE		= 540000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CBDOSLOADSEG
FONTHEIGHT=8
SETPATCH

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick31.s

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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"Biing AGA",0
slv_copy		dc.b	"1995 ReLINE",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Thanks to Hubert Maier for disk images",10,10
			dc.b	"Version "
	DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"B",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	move.l	d1,a1
	addq.l	#4,a1

	cmp.b	#4,(a0)
	bne.b	.norelo
	cmp.b	#'R',1(a0)
	bne.b	.norelo
	move.l	d1,a0
	addq.l	#4,a0

	lea	pl_relo(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	bra	.out
.norelo
	cmp.b	#4,(a0)
	bne.b	.nobint
	cmp.b	#'B',1(a0)
	bne.b	.nobint

	lea	pl_bint(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	bra	.out
.nobint
	cmp.b	#5,(a0)
	bne.b	.nobipro
	cmp.b	#'B',1(a0)
	bne.b	.nobipro

	; original BIPRO file v1.0 & aminet patch v1.2 ?

	move.l	#$4E7A0801,D2
	lea	pl_bipro_v10(pc),a0
	add.l	#$60000,a1
	cmp.l	$4720(a1),d2
	beq.b	.patch

	; patched BIPRO file v1.4

	cmp.l	$5138(a1),d2
	bne.b	wrong_version
	lea	pl_bipro_v14(pc),a0
.patch
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	bra	.out
.nobipro
.out
	rts

wrong_version:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

MOVEQ0D0NOP = $70004E71
pl_relo
	PL_START
	PL_L	$3020,MOVEQ0D0NOP	; VBR
	PL_NOP	$306A,10
	PL_END

pl_bint
	PL_START
	PL_L	$3704,MOVEQ0D0NOP	; VBR
	PL_END

pl_bipro_v10
	PL_START
	PL_L	$4720,MOVEQ0D0NOP	; VBR
	PL_L	$476A,$4E714E71	; CACR
	PL_L	$476E,$4E714E71
	PL_W	$4772,$4E71
	PL_END

pl_bipro_v14
	PL_START
	PL_L	$5138,MOVEQ0D0NOP	; VBR
	PL_NOP	$5182,10	; CACR
	PL_END

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;enable cache
	;	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	;	move.l	#WCPUF_All,d1
	;	jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
;		lea	_assign(pc),a0
;		sub.l	a1,a1
;		bsr	_dos_assign

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
	movem.l	d2/d7/a4,-(a7)
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
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


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
