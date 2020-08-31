;*---------------------------------------------------------------------------
;  :Program.	Globdule.asm
;  :Contents.	Slave for "Globdule" from Psygnosis
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	07.01.99
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i

	IFD BARFLY
	OUTPUT	Globdule.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


;======================================================================



USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.1-B"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Globdule"
		dc.b	0
_copy		dc.b	"1993 Psygnosis",0
_info		dc.b	"adapted & fixed by Mr Larmer & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0
	CNOP	0,4

;	dc.b	'$VER: Globdule HD by Mr.Larmer/Wanted Team - V1.0 (07.01.99)',0
;	CNOP 0,2

;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		lea	$100.w,A0
		moveq	#0,D0
		move.l	#$400,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		move.l	#$400,D0
		move.l	_resload(pc),a2
		jsr	resload_CRC16(a2)

		cmp.w	#$7F78,D0
		bne.w	.not_support

		; PAL/NTSC versions share the same boot

		lea	$100.w,A0
		move.l	#$400,D0
		move.l	#$1200,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		bsr	get_expmem
		move.l	d0,$B54.W	; extmem

		move.l	_resload(pc),a2
		lea	pl_boot_pal(pc),a0
		sub.l	a1,a1
		jsr	resload_Patch(a2)

		lea	Tags(pc),a0
		jsr	resload_Control(a2)

		moveq	#0,d0
		move.l	_chiprevbits(pc),d1
		and.w	#15,d1
		cmp.w	#15,d1
		bne.b	.skip

		moveq	#-1,d0
.skip
		jmp	$100.w
.not_support
		subq.l	#8,a7
		pea	TDREASON_WRONGVER.w
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

get_expmem
	IFD	USE_FASTMEM	
	move.l	_expmem(pc),d0
	ELSE
	move.l	#CHIPMEMSIZE,d0
	ENDC
	rts

pl_boot_pal
		PL_START
		PL_W	$10E,$6012		; skip set cache
		PL_W	$12C,$4E71		; skip clear zero page
		PL_W	$140,$6006		; skip wrong access to CIA

		PL_W	$226,$4E71
		PL_PS	$228,patch_pal

		PL_P	$252,Load

		PL_R	$6C4		; skip check ext mem
		PL_R	$720		; skip drive ?
		PL_L	$76A,$70004E75	; skip drive ?
		PL_END

Tags
		dc.l	WHDLTAG_CHIPREVBITS_GET
_chiprevbits
		dc.l	0
		dc.l	0

;--------------------------------

patch_pal
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	lea	pl_main(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	move.w	$22(a5),d0
	jmp	$1304.w

pl_main
	PL_START
	PL_PS	$1336,patch1
	PL_END

;--------------------------------

patch1_ok
	illegal
;;		move.w	#$6034,$8299C		; skip manual protection

		move.l	$1512.w,a0
		jmp	(a6)

patch1
	movem.l	d0-d1/a0-a2,-(a7)

	bsr	get_expmem
	move.l	_resload(pc),a2
	move.l	d0,a0

	cmp.w	#$4EB9,$1130(a0)
	beq.b	.ntsc
.pal
	lea	pl_pal(pc),a0
	bra.b	.do
.ntsc
	lea	pl_ntsc(pc),a0
.do
	bsr	get_expmem	
	move.l	d0,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	move.l	$1512.w,a0
	jmp	(a6)

pl_pal
	PL_START
	PL_W	$299C,$6034		; skip manual protection
;	PL_R	$1130			; skip country check
	PL_END


pl_ntsc
	PL_START
	PL_W	$29EA,$6034		; skip manual protection
	PL_R	$1130			; skip country check
	PL_END

;--------------------------------

Load
	movem.l	d0-a6,-(a7)

	jsr	$5BC.w			; init regs

	move.l	a1,$14(a5)		; dest
.again
	move.l	$10(a5),a0
	moveq	#0,d0
	move.l	#$1600,d1
	lea	DiskNr(pc),a1
	moveq	#0,d2
	move.w	(a1),d2
	bsr.w	_LoadDisk		; load dir

	movea.l	$10(a5),a0
	lea	$1000(a0),a0
	lea	$D00.w,a1
	move.w	#$17F,d0
.loop
	move.l	(a0)+,(a1)+
	dbra	D0,.loop

;		movea.l	$10(a5),a0
;		clr.w	$14C0(a0)
;		jsr	$A84.w			; calculate checksum
;		cmp.w	$11C0.w,d0
;		bne.b	bug

	move.l	$20(a7),a0		; file name
	jsr	$852.w			; find filename
	tst.l	d0
	bmi.b	.changedisk

	move.l	d1,d0
	swap	d0
	move.w	d0,$18(a5)
		and.l	#$FFF,d0
		add.l	#11,d0
		mulu	#512,d0
		move.l	d1,d2
		lsr.w	#8,d1
		and.l	#$FF,d1
		mulu	#512,d1
		and.l	#$FF,d2
		add.l	d2,d2
		add.l	d2,d1
		move.l	$24(a7),a0
		lea	DiskNr(pc),a1
		moveq	#0,d2
		move.w	(a1),d2
		bsr.w	_LoadDisk

		tst.w	$18(a5)
		bpl.b	.skip
		bsr.b	Decrunch
.skip
		movem.l	(a7)+,d0-a6
		moveq	#0,D0
		rte
.changedisk
		lea	DiskNr(pc),a1
		moveq	#1,d2
		cmp.w	(a1),d2
		bne.b	.skip2
		move.w	#2,(a1)
		bra.w	.again
.skip2
		move.w	#1,(a1)
		bra.w	.again

DiskNr		dc.w	1

;--------------------------------

Decrunch
	movea.l	$14(A5),A0
	movea.l	$10(A5),A1
	movem.l	D0/D2-D7/A0-A6,-(SP)
	movea.l	A1,A2
	move.l	$140(A0),D0
	move.l	$144(A0),D1
	addq.l	#1,D0
	addq.l	#1,D1
	andi.l	#$FFFFFFFE,D0
	andi.l	#$FFFFFFFE,D1
	lea	3(A0,D0.L),A3
	lea	1(A0,D1.L),A4
lbC0009C6:
	move.b	-(A4),-(A3)
	cmpa.l	A0,A4
	bge.b	lbC0009C6
	addq.l	#1,A3
	movea.l	A0,A1
	movea.l	A3,A0
	movea.l	A2,A5
	lea	$40(A0),A3
	moveq	#7,D7
	movea.l	A0,A6
	bsr.b	lbC000A0E
	move.l	$140(A0),D0
	move.l	D0,D1
	moveq	#7,D7
	lea	$148(A0),A6
lbC0009EA:
	movea.l	A5,A2
lbC0009EC:
	move.w	(A2)+,D3
	bpl.b	lbC000A02
	addq.w	#1,D7
	andi.w	#7,D7
	bne.b	lbC0009FA
	move.b	(A6)+,D4
lbC0009FA:
	btst	D7,D4
	beq.b	lbC0009EC
	suba.w	D3,A2
	bra.b	lbC0009EC

lbC000A02:
	move.b	D3,(A1)+
	subq.l	#1,D0
	bne.b	lbC0009EA
	movem.l	(SP)+,D0/D2-D7/A0-A6
	rts

lbC000A0E:
	addq.w	#1,D7
	andi.w	#7,D7
	bne.b	lbC000A18
	move.b	(A6)+,D4
lbC000A18:
	btst	D7,D4
	bne.b	lbC000A22
	clr.b	(A2)+
	move.b	(A3)+,(A2)+
	rts

lbC000A22:
	move.l	A2,-(SP)
	addq.l	#2,A2
	bsr.b	lbC000A0E
	movea.l	(SP)+,A4
	move.l	A2,D3
	sub.l	A4,D3
	neg.w	D3
	addq.w	#2,D3
	move.w	D3,(A4)
	bra.b	lbC000A0E

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

;======================================================================

	END
