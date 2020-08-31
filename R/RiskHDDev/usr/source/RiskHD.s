;*---------------------------------------------------------------------------
;  :Program.	Risk.asm
;  :Contents.	Slave for "Risk"
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
;	INCLUDE	lvo/intuition.i
;	INCLUDE	intuition/preferences.i

	IFD BARFLY
	OUTPUT	"Risk.slave"
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
IOCACHE		= 3000
;MEMFREE	= $200
;NEEDFPU
SETPATCH

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	CNOP 0,4
_assign
	dc.b	3,"pix",0

_name		dc.b	"Risk",0
_copy		dc.b	"1989 Virgin",0
_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Risk",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootdos
	bsr	_patchkb
	move.l	(_resload),a2		;A2 = resload

	bsr	_set60font


	;enable cache
	;	move.l	#WCPUF_Base_NC|WCPUF_Exp_NC|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
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
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

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
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

.end		moveq	#0,d0
		rts

_patch_exe:
	move.l	A5,-(a7)
	move.l	d7,A5
	add.l	A5,A5
	add.l	A5,A5

	move.l	a5,a0
	move.l	a0,a1
	add.l	#$10000,a1
	lea	.title(pc),a2
	move.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip0

	move.w	#$4EF9,(A0)+
	pea	_title(pc)
	move.l	(A7)+,(A0)+

.skip0

	move.l	a5,a0
	move.l	a0,a1
	add.l	#$10000,a1
	lea	.quit(pc),a2
	move.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip1

	move.w	#$4EF9,(A0)+
	pea	_quit(pc)
	move.l	(A7)+,(A0)+


.skip1
	move.l	A5,a0
	move.l	a0,a1
	add.l	#$10000,a1
	lea	.af_1(pc),a2
	move.l	#8,D0
.loop
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip2
	move.l	#$4E714EB9,(A0)+
	pea	_avoid_af_1(pc)
	move.l	(A7)+,(A0)+
	bra.b	.loop
.skip2

	bsr	_flushcache

	move.l	(A7)+,A5
	rts

.af_1:
	dc.l	$41EC0654,$D1C02E10

.quit:
	dC.l	$203C8000,$000041FA
	dc.w	$10

.title:
	dc.l	$4EAEFF04,$201F4E75
	dc.w	$2209

_title:
	btst	#6,$bfe001
	bne.b	_title

	jsr	(-$fc,a6)
	move.l	(a7)+,d0
	rts

_avoid_af_1
	lea	($654,a4),a0
	add.l	D0,A0
	cmp.l	#$100000,d0
	bcc	.avoid
	move.l	(a0),d7
	bra.b	.end
.avoid
	moveq.l	#-1,d7
.end
	rts

_quit:
	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_set60font:
	rts
	IFEQ	1
	lea	.intuiname(pc),A1
	moveq.l	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,A6
	sub.l	#2,A7
	move.l	A7,A0
	moveq.l	#2,D0
	jsr	_LVOGetPrefs(a6)
	move.l	A7,A0
	move.b	#TOPAZ_SIXTY,pf_FontHeight(a0)
	move.l	A7,A0
	moveq.l	#2,D0
	jsr	_LVOSetPrefs(a6)
	lea	2(A7),A7
	rts

.intuiname:
	dc.b	"intuition.library",0
	even
	ENDC

_patchkb
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
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

	INCLUDE	kick13.s

;============================================================================

	END
