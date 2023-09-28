;*---------------------------------------------------------------------------
;  :Program.	BirdsOfPreyHD.asm
;  :Contents.	Slave for "BirdsOfPrey"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BirdsOfPreyHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"BirdsOfPrey.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD		CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000	
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem|WHDLF_NoDivZero
slv_keyexit	= $5D	; num '*'


	INCLUDE	whdload/kick13.s

;============================================================================

slv_config
                dc.b    "C1:B:To skip intro;"
                dc.b    0

_assign
	dc.b	"Birds Of Prey",0

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


slv_name		dc.b	"Birds Of Prey"
	IFD	CHIP_ONLY
	dc.b	"(DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1991 Electronic Arts",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to Tony Aksnes for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN
	
_intro:
	dc.b	"ar",0
_args		dc.b	10
_args_end
	dc.b	0
_program:
	dc.b	"bop.exe",0

	EVEN


_bootdos
	clr.l	$0.W


	move.l	(_resload,pc),a2		;A2 = resload
	lea     (_tag,pc),a0
	move.l  (_resload,pc),a2           ;A2 = resload
	jsr     (resload_Control,a2)

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
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		move.l	_skip_intro(pc),d0
		bne.b	.skipintro
		lea	_intro(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
.skipintro
	;quit
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist


_patch_main:
	lea	_seglist(pc),a0
	move.l	d7,(a0)
	; so we can reuse old code
	move.l	_seglist(pc),A0
	moveq	#2,D0
	bsr	.skipseg

	move.l	A0,A3
	add.l	A3,A3
	add.l	A3,A3

	; segment #3: buggy interrupt/ports stuff
	; not needed / toxic now

	IFEQ	1
	move.l	A3,A0
	lea	8700(a0),a1	; end
	
	; patch keyboard delay
	lea	.kbmul(pc),A2
	moveq.l	#12,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.endkb
	pea	_kbwait(pc)
	move.w	#$4EB9,(A0)+
	move.l	(A7)+,(A0)+
	move.w	#$6056,(A0)+
.endkb

	; patch problem with EZ-mouse interface
	; looked commented in the old version of the slave...
	lea	.rmback(pc),A2
	moveq.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.endrmb
	pea	_rmback(pc)
	move.w	#$4EB9,(A0)+
	move.l	(A7)+,(A0)+
.endrmb
	; segment #43: protection check
	ENDC
	
	move.l	_seglist(pc),A0
	move.l	#45,D0
	bsr	.skipseg

	move.l	A0,A3
	add.l	A3,A3
	add.l	A3,A3

	move.l	A3,A0
	move.l	A3,A1
	add.l	#150500,A1
	lea	.prot(pc),A2
	moveq	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipprot
	subq.l	#2,A0
	cmp.b	#$3E,(A0)
	bne.b	.skipprot
	move.w	#$6024,(A0)
.skipprot
	bsr	_flushcache
	rts

.prot:
	dc.w	$6716
	dc.l	$BE466612

.kbmul:
	dc.w	$70FF,$C1FC,$FFFF
	dc.w	$70FF,$C1FC,$FFFF

.rmback:
	dc.w	$3B7C,$0C01,$0034



; < A0: BPTR pointer on seglist
; < D0: # of segments to skip
; > A0: BPTR pointer on seglist

.skipseg:
	subq.l	#1,D0
.loop
	add.l	A0,A0
	add.l	A0,A0
	move.l	(A0),A0
	dbf	D0,.loop
	rts

_rmback:
	btst	#2,D1	; D1 = potinp >> 8
	;bne.b	.noack	; skip acknowledge if RMB not pressed (else EZ-Mouse freezes)
	;move.w	#$0C01,52(A5)	; reset pot.
;.noack
	rts

_kbwait:
	moveq	#3,D0
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

_seglist
	dc.l	0

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
	movem.l	d0-a6,-(a7)
	jsr	(a5)
	movem.l	(a7)+,d0-a6
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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_tag            dc.l    WHDLTAG_CUSTOM1_GET
_skip_intro       dc.l    0
	dc.l	0