;*---------------------------------------------------------------------------
;  :Program.	StripPot.asm
;  :Contents.	Slave for "StripPot"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
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
	INCLUDE	hardware/custom.i

	IFD BARFLY
	OUTPUT	"StripPot.slave"
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
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
INITAGA

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick31.s

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

_assign_cd
	dc.b	"STRIP_POT",0
_assign_1
	dc.b	"Strip_Pot_Disk_1",0
_assign_2
	dc.b	"Strip_Pot_Disk_2",0

slv_name		dc.b	"StripPot AGA/CD³²",0
slv_copy		dc.b	"1994 Pixel-Blue",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"CUSTOM1=1 enables cursor up = +1 credit",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program_cd:
	dc.b	"sp_cd32",0
_program_floppy:
	dc.b	"c/sp",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

_bootdos
		move.l	(_resload),a2		;A2 = resload

	;enable caches
		move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign_cd(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program_floppy(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.trycd

		bsr	patchexe_floppy		

		bra.b	.ok
.trycd
		lea	_program_cd(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

		bsr	patchexe_cd32
		bsr	patchkb_cd32
.ok
	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

.end		moveq	#0,d0
		rts

patchexe_cd32
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	lea	pl_main_cd32(pc),a0
	jsr	resload_Patch(a2)
	rts

patchexe_floppy
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	lea	pl_main_floppy(pc),a0
	jsr	resload_Patch(a2)
	rts

pl_main_floppy
	PL_START
	PL_PS	$278A,kbint_floppy
	PL_PS	$27E6,get_credit_address_floppy
	PL_END

pl_main_cd32
	PL_START
	PL_PS	$2312,joystick_test
	PL_PS	$29B4,get_credit_address_cd32
	PL_END

get_credit_address_cd32
	add.l	#$2B99A,A1	; original
	movem.l	D0/A0,-(A7)
	move.l	_credit_address(pc),D0
	bne.b	.copied
	move.l	A6,d0
	add.l	#$9E,d0
	lea	_credit_address(pc),a0
	move.l	d0,(a0)
.copied
	movem.l	(A7)+,D0/A0
	rts

kbint_floppy
	move.b	$bfec01,d0
	movem.l	d0,-(a7)
	ror.b	#1,d0
	not.b	d0
	cmp.b	#76,d0
	bne.b	.nocheat

	move.l	_custom1(pc),d0
	beq.b	.nocheat

	move.l	_credit_address(pc),d0
	beq.b	.notyet			; address not computed
	movem.l	a0,-(a7)
	move.l	d0,a0
	add.w	#1,(a0)
	movem.l	(a7)+,a0
.notyet
	bra.b	.noquit
.nocheat
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit

	movem.l	(a7)+,d0
	rts

get_credit_address_floppy
	MOVE	30(A5),D0
	ANDI	#$0010,D0	; stolen

	movem.l	D0/A0,-(A7)
	move.l	_credit_address(pc),D0
	bne.b	.copied
	move.l	A6,d0
	add.l	#$B6,d0
	lea	_credit_address(pc),a0
	move.l	d0,(a0)
.copied
	movem.l	(A7)+,D0/A0
	addq.l	#2,(a7)
	rts

joystick_test:
	; enables keyboard interrupts

	move.w	#$C008,$dff09a

	move.b	_kbvalue(pc),d0
	bclr	#7,d0
	beq.b	.next
	; add 1 credit

	movem.l	D0/A0,-(A7)
	move.l	_custom1(pc),d0
	beq.b	.notyet			; trainer not activated
	move.l	_credit_address(pc),d0
	beq.b	.notyet			; address not computed
	move.l	d0,a0
	add.w	#1,(a0)
.notyet
	movem.l	(A7)+,D0/A0
.next
	btst	#7,$bfe001
	bne.b	.nofire
	bset	#6,D0
.nofire
	add.l	#$4A,(a7)
	rts

patchkb_cd32:
	; replace system keyboard scan by ours

	pea	kbint_cd32(pc)
	move.l	(a7)+,$68.W
	rts

kbint_cd32:
	movem.l	D0-D3/A0/A5,-(A7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.out
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	lea	_kbtable(pc),a0
	bclr	#7,d0
	sne	d2
	move.b	_kbvalue(pc),d3
.loop:
	move.b	(a0)+,d1
	beq.b	.end
	cmp.b	d0,d1
	bne.b	.next
	move.b	(a0)+,d1
	tst.b	d2
	bne.b	.clr
.set
	bset	d1,d3
	bra.b	.end
.clr
	bclr	d1,d3
	bra.b	.end
.next
	addq.l	#1,a0
	bra.b	.loop
.end
	lea	_kbvalue(pc),a0
	move.b	d3,(a0)

	BSET	#$06,$1E01(A5)
	moveq	#2,d0
	bsr	_beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.out
	movem.l	(A7)+,D0-D3/A0/A5
	move.w	#8,$dff09c
	RTE


_kbtable:
	dc.b	$1,5		; HOLD/NUDGE #1: 1
	dc.b	$2,3		; HOLD/NUDGE #2: 2
	dc.b	$3,4		; HOLD/NUDGE #3: 3
	dc.b	$54,6		; START/SELECT: F5
	dc.b	$40,6		; START/SELECT: SPACE
	dc.b	76,7		; credit increase
	dc.w	0

_kbvalue:
	dc.w	0

_credit_address
	dc.l	0

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0


;============================================================================

	END
