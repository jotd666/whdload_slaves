;*---------------------------------------------------------------------------
;  :Program.	PiratesHD.asm
;  :Contents.	Slave for "Pirates"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: PiratesHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	IFEQ	1
	INCLUDE	lvo/intuition.i
	INCLUDE	intuition/preferences.i
	ENDC

	IFD BARFLY
	OUTPUT	"PiratesECS.slave"
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
FASTMEMSIZE	= $C0000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 3000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
CBDOSLOADSEG
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_name		dc.b	"Pirates!",0
slv_copy		dc.b	"1990 Microprose",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Use CUSTOM=<savegame name>.pir",10
		dc.b	"to reload a saved game",10,10
		dc.b	"Version 1.4 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Pirates!",0
_args
	blk.b	$22,0
	EVEN
_arglen
	dc.l	0

;============================================================================

	;initialize kickstart and environment


_cb_dosLoadSeg
	tst.l	D0
	beq.b	_patch1		; patch overlay part
;	add.l	d0,d0
;	add.l	d0,d0
;	move.l	d0,a0
;	cmp.b	#'P',1(a0)
;	beq.b	_patch2
	rts

_patch1
	move.l	d1,a0
	add.l	a0,a0
	add.l	a0,a0
	move.l	a0,a1

	bsr	.trypatch_af

	add.l	#$11D4C,a1		; UK original
	bsr	.trypatch
	move.l	a0,a1
	add.l	#$1E9C8-$CC94,a1	; KIXX rerelease
	bsr	.trypatch
	rts


.trypatch
	cmp.l	#$BA406730,(a1)
	bne.b	.noprot
	move.b	#$60,2(a1)
.noprot:
	rts

.trypatch_af
	patch	$100,patch_quit_af

	movem.l	d0-d1/a0-a2,-(a7)
	lea	$F00(a0),a0
	lea	$100(a0),a1
	lea	.pattern(pc),a2
	moveq	#8,d0
.loop
	bsr	hex_search
	cmp.l	#0,a0
	beq.b	.out
	move.l	#$4EB80100,(a0)+
	bra.b	.loop
.out
	movem.l	(a7)+,d0-d1/a0-a2
	rts
	
.pattern
	dc.l	$206DFFF0
	dc.l	$3F280004

patch_quit_af
	move.l	(-$10,a5),a0
	movem.l	D0,-(a7)
	move.l	a0,d0
	cmp.l	#CHIPMEMSIZE,d0
	bcs.b	.ok		; within chipmem: ok
	rol.l	#8,d0
	cmp.b	_expmem(pc),d0
	beq.b	.ok

	; 2-byte shift in the address table when quitting the game

	bra	_quit
.ok
	movem.l	(a7)+,D0
	rts

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

hex_search:
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
	move.l	(_resload),a2		;A2 = resload

	;get tags
		lea	_args(pc),a0

		move.l	#$20,d0
		moveq.l	#0,d1
		jsr	(resload_GetCustom,a2)

	;get length
		lea	_args(pc),a0
		move.l	a0,a1
.loop
		tst.b	(a0)+
		bne.b	.loop
		move.b	#10,-1(a0)
		sub.l	a1,a0
		lea	_arglen(pc),a1
		move.l	a0,(a1)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		move.l	_arglen(pc),d0
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

_quit
		pea	TDREASON_OK
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts


; change preferences

	IFEQ	1
_patchintuition:
	lea	.intuiname(pc),A1
	moveq.l	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,A6

	lea	-232(A7),A7
	
	move.l	A7,A0
	move.l	#232,D0
	jsr	_LVOGetPrefs(a6)

	move.l	A7,A0
	; set WB colors to 0
	clr.w	pf_color0(a0)
	clr.w	pf_color1(a0)
	clr.w	pf_color2(a0)
	clr.w	pf_color3(a0)

	move.l	A7,A0
	move.l	#232,D0
	moveq	#-1,D1
	jsr	_LVOSetPrefs(a6)

	lea	232(A7),A7
	move.l	A6,A1
	move.l	$4.W,A6
	JSR	_LVOCloseLibrary(a6)

	rts
.intuiname:
	dc.b	"intuition.library",0
	even
	ENDC

;============================================================================

	END
