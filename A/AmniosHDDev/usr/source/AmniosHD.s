;*---------------------------------------------------------------------------
;  :Program.	Amnios.asm
;  :Contents.	Slave for "Amnios" from Psygnosis
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	04.11.99
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	Amnios.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000

;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info


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

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

_name	dc.b	"Amnios",0
_copy	dc.b	"1991 Psygnosis",0
_info	dc.b	"Installed and fixed by Mr.Larmer & JOTD",10
	dc.b	"Version "
	DECL_VERSION
	dc.b	-1
	dc.b	"Greetings to Bored Seal",0
	CNOP 0,2

;;	dc.b	"Version 1.0 (08.11.1999)",-1

DO_ZBASE_PATCH:MACRO
	movem.l	d0-d1/a0-a2,-(a7)
	lea	\1(pc),a0
	move.l	_resload(pc),a2
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	ENDM

;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use


		lea	CHIPMEMSIZE-$100,a7

		lea	$20000,A0
		move.l	#$400,D0
		move.l	#$1200,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		pea	Patch(pc)
		move.l	(a7)+,$80.w

		movem.l	d0-d1/a0-a2,-(a7)
		move.l	a0,a1
		lea	pl_boot(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2

		bsr	get_expmem
		move.l	d0,d3		; ext mem
		move.l	d3,d4
		add.l	#EXPMEMSIZE,d4

		jmp	$48(a0)

pl_boot
	PL_START
	PL_W	$118,$6002		; skip run second copperlist
						; because not exist

	PL_W	$172,$4E40		; jmp (a2) -> trap #0

	PL_P	$1F6,Load
	PL_END

;--------------------------------

Patch
		addq.l	#8,a7

		pea	Patch2(pc)
		move.l	(a7)+,$80.w
		move.w	#$4E40,$54(a2)		; jmp (a3) -> trap #0
		bsr	_flushcache

		jmp	(a2)			; A2=$73000

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

;--------------------------------

Patch2
	addq.l	#8,a7


	DO_ZBASE_PATCH	pl_2
	jmp	(a3)			; A3=$4000

pl_2
	PL_START
	PL_PS	$4314,PatchDir

	PL_P	$43B0,Run

	PL_L	$90,0
	PL_W	$406E,$4E71	; skip country check for both versions
	PL_R	$4450		; skip protection

	PL_P	$65A0,Load2
	PL_END

;--------------------------------

PatchDir
	DO_ZBASE_PATCH	pl_dir	
	jmp	$6926.w

pl_dir
	PL_START
	PL_P	$6926,Load3
	PL_END

;--------------------------------

Run
	patch	$100,Patch3
	DO_ZBASE_PATCH	pl_run
	jmp	$1D126

pl_run
	PL_START
	PL_W	$1D14A,$100
	PL_END

;--------------------------------

Patch3
	lea	$5F0.w,a7

	DO_ZBASE_PATCH	pl_patch3

	jmp	$604.w

pl_patch3
		PL_START
		PL_PS	$746,Keyboard

		PL_P	$DAB0,Load3
		PL_END

;--------------------------------

Keyboard
		move.l	d1,-(a7)

		moveq	#3-1,d1				;wait because handshake min 75 탎
.int2_w1	move.b	_custom+vhposr,d0
.int2_w2	cmp.b	_custom+vhposr,d0		;one line is 63.5 탎
		beq.b	.int2_w2
		dbf	d1,.int2_w1			;(min=127탎 max=190.5탎)

		move.l	(a7)+,d1
		rts

;--------------------------------

Load3
		movem.l	d0-a6,-(a7)

		cmp.w	#1,D1
		beq.b	.savehighs

		lea	DirPtr(pc),A1

		cmp.w	#5,D1
		bne.b	.skip

		move.l	#$3000,D0
		move.l	#$1000,D1

		move.l	A0,(A1)

		bra.b	.read
.skip
		move.l	(A1),A2
		lea	$C00(A2),A3
		moveq	#0,D0
		moveq	#0,D1
		moveq	#0,D2
.loop
		movem.l	A0/A2,-(A7)
.loop2
		move.b	(A0)+,D0
		move.b	(A2)+,D1
		cmp.b	D0,D1
		bne.b	.next
		tst.b	D0
		bne.b	.loop2
		bra.b	.ok
.next
		movem.l	(A7)+,A0/A2
		addq.b	#1,D2
		lea	$10(A2),A2
		bra.b	.loop
.ok
		movem.l	(A7)+,A0/A2
		move.l	$C(A2),D1		; length
		lea	(A3),A4
.loop3
		cmp.b	(A4)+,D2
		bne.b	.loop3
		subq.l	#1,A4
		sub.l	A3,A4
		move.l	A4,D0
		mulu	#$400,D0

		move.l	$24(A7),A0
.read
		moveq	#2,D2

		bsr.w	_LoadDisk
.exit
		movem.l	(A7)+,d0-a6
		moveq	#0,D0
		rts

.savehighs
		move.l	#$120,d0		;len
		move.l	#$B7800,d1		;offset
		lea	$5E9C2,a1		;address
		lea	_savename(pc),a0	;filename
		move.l	_resload(pc),a2
		jsr	resload_SaveFileOffset(a2)
		bra.b	.exit

_savename	dc.b	"Disk.2",0
		even
DirPtr		dc.l	0

;--------------------------------

Load
		movem.l	d0-a6,-(a7)

		moveq	#0,d0
		move.w	(a0)+,d0
		mulu	#$1800,d0
		moveq	#0,d1
		move.w	(a0)+,d1
		mulu	#$1800,d1

		move.l	a1,a0
		moveq	#1,d2

		bsr.b	_LoadDisk

		clr.w	$92(a5)

		movem.l	(a7)+,d0-a6
		rts


get_expmem
	IFD	USE_FASTMEM	
	move.l	_expmem(pc),d0
	ELSE
	move.l	#CHIPMEMSIZE,d0
	ENDC
	rts

;--------------------------------

Load2
		movem.l	d0-a6,-(a7)

		addq.l	#4,a0
		moveq	#0,d0
		move.w	(a0)+,d0
		mulu	#$1800,d0
		moveq	#0,d1
		move.w	(a0)+,d1
		mulu	#$1800,d1

		move.l	a1,a0
		moveq	#1,d2

		bsr.b	_LoadDisk

		movem.l	(a7)+,d0-a6
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

;======================================================================

	END
