;*---------------------------------------------------------------------------
;  :Program.	AbandonedPlaces2HD.asm
;  :Contents.	Slave for "AbandonedPlaces2"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: AbandonedPlaces2HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"AbandonedPlaces2.slave"
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
HRTMON
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
CACHE

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

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
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0


slv_name		dc.b	"Abandoned Places 2",0
slv_copy		dc.b	"1993 ICE Ltd",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Thanks to SPS for disk images",10,10
		dc.b	"Thanks to Dr Zarkov & Luca for their help",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"AP2",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patchit(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

patchit:
	move.l	d7,a5
	add.l	A5,A5
	add.l	A5,A5
	addq.l	#4,a5
	move.l	A5,A1
	cmp.w	#$4E73,$B60(a5)
	bne.b	.nopatch_1
	lea	_patchlist_1(pc),A0
	jsr	resload_Patch(a2)

;	lea	_remove_prot(pc),a0
;	move.l	a0,$BC.W		; trap #15
.nopatch_1
	rts
	
_ackkb:
	move.b	#$41,($1E01,a0)
	move.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	move.l	(A7)+,D0
	rts

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

_remove_prot:
	; return from trap

	move.l	A0,-(A7)
;	lea	.return(pc),a0
;	move.l	6(a7),(a0)

	lea	.cont(pc),a0
	move.l	a0,6(a7)
	move.l	(a7)+,A0
	rte
.cont
	; now everything back to normal SR, USP

	move.l	A0,-(A7)
	move.l	4(A7),A0	; return address
	lea	$492(A0),A0
	cmp.l	#$66000006,(A0)
	bne.b	.noprot
	cmp.l	#$6100D3B0,$4(A0)
	bne.b	.noprot

	; remove protection

	IFEQ	1
	move.l	#$3028000A,-8(A0)
	move.l	#$33400014,-4(A0)
	move.l	#$4E714E71,(A0)
	ENDC

	move.l	_resload(pc),a0
	jsr	resload_FlushCache(a0)
.noprot	
	move.l	(A7)+,a0
	tst.l	D2
	RTS

;.return:
;	dc.l	0

_patchlist_1:
	PL_START
	; stackframe error

	PL_W	$b60-$8,$46e8
	PL_W	$b60,$4e75
	PL_W	$bcc-$28,$46E8
	PL_W	$bd4-$28,$4e75

	; keyboard handshake

	PL_PS	$1D1A,_ackkb

	; protection patch

;;	PL_W	$2284,$4E4F

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

;============================================================================

	END
