;*---------------------------------------------------------------------------
;  :Program.	TotalFootballHD.asm
;  :Contents.	Slave for "Total Football" from
;  :Author.	JOTD
;  :History.	28.01.05
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
	OUTPUT	TotalFootball.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM
CHIPMEMSIZE = $100000
EXPMEMSIZE = $0

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	data-_base		;ws_CurrentDir
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

data:
	dc.b	"data",0
	even

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

_name		dc.b	"Total Football"
		dc.b	0
_copy		dc.b	"1996 Domark/Akklaim",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Set CUSTOM1=1 for one player controls",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

BASEADDRESS=$19268

;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	a0,a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

		lea	CHIPMEMSIZE-$100,a7

		; load & version check

		lea	start_address(pc),a0
		lea	BASEADDRESS,A1
		move.l	A1,(a0)
		lea	chipname(pc),A0
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)

		; check the file CRC

		lea	BASEADDRESS,A0
		jsr	resload_CRC16(a2)
		cmp.w	#$2A49,D0
		beq.b	.ok
		cmp.w	#$87D9,D0	; no Akklaim logo version (NOPs inserted at $1AE2C)
		beq.b	.ok

		bra	wrong_version
.ok
		; read routine

		; configure memory

		lea	$100.W,A0
		MOVE	#$FF,758(A0)	; attnflags?
		MOVE.L	#CHIPMEMSIZE,760(A0)	; top chip
		MOVE.L	#$0,764(A0)		; top fast

		lea	pl_main(pc),a0
		move.l	_custom1(pc),d0
		beq	.patch
		lea	pl_one_player(pc),a0
.patch
		sub.l	a1,a1
		jsr	resload_Patch(a2)
		
		jmp	BASEADDRESS

pl_one_player
	PL_START

	PL_PS	$1F3D8,read_joy1
	PL_PS	$1F4A4,read_joy1
	PL_PS	$1F570,read_joy1

	PL_PS	$1AF88,read_fire1
	PL_PS	$1F410,read_fire1
	PL_PS	$1F4DC,read_fire1
	PL_PS	$1F5A8,read_fire1

	PL_NEXT	pl_main

pl_main
	PL_START

	PL_P	$1B642,read_file

	; quit key

	PL_PS	$1957E,kb_int

	; Akklaim logo removal

;	PL_L	$1AE2C,$4E714E71
;	PL_L	$1AE30,$4E714E71
;	PL_L	$1AE34,$4E714E71
	PL_END


read_fire1
	addq.l	#2,(a7)
	btst	#7,$bfe001
	rts

	IFEQ	1
read_fire0_or_1
	movem.l	d0,-(a7)
	move.l	8(a7),d0	; check return address
	cmp.l	#$1FD02,d0
	movem.l	(a7)+,d0
	beq.b	.from_game

	; menu: use joystick from port 2 all the time

	btst	#7,$bfe001
	rts

.from_game
	btst	#6,$bfe001
	rts

read_joy0_or_1
	movem.l	d0,-(a7)
	move.l	8(a7),d0	; check return address
	cmp.l	#$1FD02,d0
	movem.l	(a7)+,d0
	beq.b	.from_game

	; menu: use joystick from port 2
	ENDC

read_joy1
	move.w	$dff00c,d1
	rts

.from_game
	move.w	$dff00a,d1
	rts

kb_int:
	move.b	$BFEC01,D0
	move.l	D0,-(a7)
	ror.b	#1,D0
	not.b	D0
	cmp.b	_keyexit(pc),D0
	bne.b	.skip

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.skip
	move.l	(a7)+,d0
	rts

read_file
	movem.l	d0-a6,-(a7)
	move.l	A2,A1
	move.l	_resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,d0-a6
	JMP	$1BBC8

wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

get_extmem
	lea	_expmem(pc),a0
	IFND	USE_FASTMEM
	move.l	#CHIPMEMSIZE,(a0)
	ENDC
	move.l	(A0),A0
	move.l	A0,$7EBAA
	rts

decrunch
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	bsr	_flushcache
	rts
	
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;--------------------------------

_resload	dc.l	0		;address of resident loader

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts



trainer:
	dc.l  0

start_address:
	dc.l	0

chipname:
	dc.b	"CHIPRAM.EXE",0
