;*---------------------------------------------------------------------------
;  :Program.	RailroadTycoon.asm
;  :Contents.	Slave for "RailroadTycoon"
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
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"RailroadTycoon.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS



slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM
	
_disk1
	dc.b	"RAILA",0
_disk2
	dc.b	"RDISKB",0
_jff:
	dc.b	"JFF",0
_saves:
	dc.b	"saves",0

slv_name		dc.b	"Railroad Tycoon",0
slv_copy		dc.b	"1990 Microprose",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
;	CNOP	0,4
;	dc.b	4
_program:
	dc.b	"game",0
_args		dc.b	10
_args_end
	dc.b	0
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_disk1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_disk2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	_jff(pc),a0
		lea	_saves(pc),a1
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end

	;patch	

		bsr	_patch_exe

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		moveq	#0,D1
		move.l	#4000,D2
		move.l	#4008,D3
		moveq	#1,D4
		moveq	#0,D5
		moveq	#0,D6
		moveq	#0,D7
		sub.l	A2,A2
		sub.l	A3,A3
		sub.l	A4,A4
		sub.l	A5,A5
		sub.l	A6,A6
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end
		pea	_program(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_patch_exe:
	move.l	d7,d0
.loop
	move.l	d0,a0
	add.l	a0,a0
	add.l	a0,a0

	cmp.l	#$4EBA005E,$11b6(a0)
	bne.b	.nosave_uk
	move.w	#$6028,$11b6(a0)	; skip insert disk check
	bra		.next

.nosave_uk
	cmp.l	#$4EBA005E,$120A(a0)
	bne.b	.nosave_fr
	move.w	#$6028,$120A(a0)	; skip insert disk check
	bra.b	.next

.nosave_fr
	cmp.l	#$4E55FFE4,4(a0)
	bne.b	.noprot
	cmp.l	#$48E73F10,8(a0)
	bne.b	.noprot

	; remove protection

	cmp.l	#$BA476626,$388(a0)
	bne.b	.next
	move.l	#$3A074E71,$388(a0)
	bra.b	.next
.noprot
	cmp.l	#$4446300A,$190(a0)	; DF0\n
	bne.b	.nouk

	move.l	#$4A46460A,$190(A0)
	move.l	#'JFF:',$196(A0)
	move.b	#0,$1C8(A0)
	move.l	#'JFF:',$1CE(A0)
	bra.b	.next
.nouk:	
	cmp.l	#$4446300A,$22E(a0)	; DF0\n
	bne.b	.next
	move.l	#$4A46460A,$22E(A0)
	move.l	#'JFF:',$234(A0)
	move.b	#0,$266(A0)
	move.l	#'JFF:',$26C(A0)
	
.next
	move.l	(a0),d0
	bne		.loop
.out
	bsr	_flushcache
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


;============================================================================

	END
