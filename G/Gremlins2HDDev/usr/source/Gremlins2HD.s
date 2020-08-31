;*---------------------------------------------------------------------------
;  :Program.	Gremlins2.asm
;  :Contents.	Slave for "Gremlins 2" from Elite
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	12.12.97
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i

	IFD	BARFLY
	OUTPUT	Gremlins2.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
	
;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	15		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = F9
_keyexit	dc.b	$5D		;ws_keyexit = num '*'

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
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Gremlins 2: The new batch"
		dc.b	0
_copy		dc.b	"1990 Elite",0
_info		dc.b	"adapted by Mr Larmer/Wanted Team",10
		dc.b	"keyboard fix & rework by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

;;	dc.b	'$VER: Gremlins 2 HD by Mr.Larmer/Wanted Team - V1.0 (12.12.97)',0
	even

DO_ZBASE_PATCH:MACRO
	movem.l	d0-d1/a0-a2,-(a7)
	lea	\1(pc),a0
	move.l	_resload(pc),a2
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	ENDM
;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		lea	$1000.w,A0
		moveq	#0,D0
		move.l	#$400,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		DO_ZBASE_PATCH	pl_boot
		jmp	$100C.w

pl_boot
	PL_START
	PL_W	$1028,$6004		; skip set priv. viol. vect.

	PL_R	$107A		; drive on ?
	PL_R	$11EA
	PL_R	$11F8

	PL_P	$1120,diskload

	PL_P	$1224,main	; P or PS?
	PL_END

main
	DO_ZBASE_PATCH	pl_main
	jmp	$400.w

pl_main
	PL_START
	PL_W	$84E,$6006		; skip int vect disabled
	PL_R	$14D2		; drive on ?
	PL_R	$14E6
	PL_R	$14FA
	PL_R	$150E
	PL_R	$1522

	PL_P	$15D4,diskload

	; JOTD: added these to fix keyboard handshake & lockup

	PL_P	$10D0,end_kb_int
	PL_S	$1002,6
	PL_S	$104C,$54-$4C
	PL_PS	$1024,kb_delay
	PL_END

diskload
		movem.l	d0-a6,-(a7)

		moveq	#0,D0
		move.w	$28.w,D0
		mulu	#$18A8,D0
		sub.l	#$18A8-$1600,D0
		moveq	#0,D1
		move.w	D7,D1
		mulu	#$18A8,D1
		move.l	A5,A0
		moveq	#1,D2

		bsr.w	_LoadDisk

		movem.l	(A7)+,d0-a6
		moveq	#0,D0
		rts

end_kb_int
	movem.l	(a7)+,d0-d2/a0
	move.w	#8,$dff09C
	rte

kb_delay:
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	bclr	#6,$bfee01
	movem.l	(A7)+,D0
	add.l	#30,(a7)	; skip shitty kb delay code
	rts

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

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
		
;--------------------------------

_exit		pea	TDREASON_OK.w
		bra.b	_end
_debug		pea	TDREASON_DEBUG.w
_end		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

;======================================================================

	END
