;*---------------------------------------------------------------------------
;  :Program.	CoolSpot.asm
;  :Contents.	Slave for "Cool Spot" from Virgin
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	26.02.98
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i

	IFD BARFLY
	OUTPUT	CoolSpot.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;======================================================================
basemem	=$80000


	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM
	
_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	15		;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError	;ws_flags
		dc.l	basemem
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem	
	dc.l	$80000
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

_name		dc.b	"Cool Spot"
		dc.b	0
_copy		dc.b	"1990 Virgin",0
_info		dc.b	"adapted by Mr.Larmer/Wanted Team & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	$A,$D,0
	even



;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		Lea	$40000,A0
		MOVE.l	#2*512,D0
		MOVE.l	#9*512,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		move.l	_expmem(pc),-4(A0)			; ext mem

		move.w	#$601E,$30(A0)			; skip drive on

		move.w	#$4EF9,$17E(A0)
		pea	Load(pc)
		move.l	(A7)+,$180(A0)

		move.l	#$4E714EF9,$E16(A0)
		pea	Patch1(pc)
		move.l	(A7)+,$E1A(A0)

		moveq	#1,D4
		
		bsr	_flushcache

		jmp	(A0)

;--------------------------------

Patch1
		jsr	$1282.w

		move.w	#$600C,$1CA8.w		; skip set int. vectors
		move.w	#$6016,$1CC6.w

		move.l	#$600008C8,$2E04.w	; skip copylock

		move.w	#$7A00,$36DA.w		; set copylock ID = 0
		move.w	#$6002,$36DC.w

		move.w	#$6002,$B98C		; access fault (bset #$1F,D0)

		move.w	#$4EF9,$AE7C
		pea	mask_int_6(pc)
		move.l	(A7)+,$AE7E

		move.l	#$4E714EB9,$7A34
		pea	kb_routine(pc)
		move.l	(A7)+,$7A38
		
;		move.w	#-1,$390B8	; cheat on (keys)
		bsr	_flushcache

		jmp	$1500.w

; avoids crashes on CD32
mask_int_6
	move.w	#$2000,$DFF09C
	btst.b	#0,$BFDD00		; acknowledge CIA-B Timer A interrupt
	RTE

kb_routine:
	not.b	d0
	move.b	d0,($11A,A5)	; stolen
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	rts

;--------------------------------

Load
		movem.l	d0-a6,-(a7)

		moveq	#0,D0
		move.w	D1,D0
		mulu	#512,D0

		moveq	#0,D1
		move.w	D2,D1
		mulu	#512,D1

		moveq	#0,D2
		move.b	D4,D2

		cmp.b	#4,D2
		bne.b	.skip1

		moveq	#3,D2
.skip1
		bsr.w	_LoadDisk

		btst	#4,D3			; if must be decrunch
		beq.b	.skip

		move.l	A0,A1

		btst	#5,D3
		beq.b	.skip2

		move.l	A2,A1
.skip2
		jsr	$10A8.w			; decrunch
.skip
		movem.l	(A7)+,d0-a6

		moveq	#0,D0
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

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

;======================================================================

	END
