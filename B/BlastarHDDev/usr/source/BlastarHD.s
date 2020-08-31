;*---------------------------------------------------------------------------
;  :Program.	BlastarHD.asm
;  :Contents.	Slave for "Blastar" from Core Design
;  :Author.	JOTD
;  :History.	
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	exec/io.i

	IFD BARFLY
	OUTPUT	Blastar.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

USE_FASTMEM

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError	;ws_flags
		IFD	USE_FASTMEM
		dc.l	$81000		;ws_BaseMemSize
		ELSE
		dc.l	$100000
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem	
	IFD	USE_FASTMEM	
	dc.l	$80000			;ws_ExpMem
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
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Blastar"
		IFND	USE_FASTMEM
		dc.b	" (DEBUG)"
		ENDC
		dc.b	0
_copy		dc.b	"1993 Core Design",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Set CUSTOM1=1 to skip introduction",10
		dc.b	"Set CUSTOM2=1 to enable in-game keys",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	$A,$D,0
	even

BASE_ADDRESS = $60000

;======================================================================
start	;	A0 = resident loader
;======================================================================

		clr.l	$4.W

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	a0,a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

		lea	$7FF00,a7

		; load & version check

		lea	BASE_ADDRESS,A0
		move.l	#$32,D0		; offset
		move.l	#$F4,D1		; length
		moveq	#1,D2
		bsr	_loaddisk
		lea	BASE_ADDRESS,A0
		move.l	#$F4,d1
		jsr	resload_CRC16(a2)

		cmp.l	#$7C66,d0
		beq.b	.cont

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.cont
		lea	pl_boot(pc),a0
		lea	BASE_ADDRESS,A1
		jsr	resload_Patch(a2)
		
		jmp	BASE_ADDRESS

pl_boot
	PL_START
	PL_P	$2C,patch_1
	PL_END

patch_1
	; DoIO
	moveq	#1,d2		;first disk
	move.l	#$2C00,d0	;offset
	move.l	#$4E00,d1	;length
	lea	$7A000,a0	;destination
	move.l	(_resload,pc),a2
	jsr	(resload_DiskLoad,a2)

	move.l	_custom1(pc),d0
	beq.b	.sk

	; skip introduction

	lea	$7A000,a1
	lea	pl_nointro(pc),a0
	move.l	(_resload,pc),a2
	jsr	(resload_Patch,a2)
	bra	.p1
.sk
	; patch introduction

	lea	$7A000,a1
	lea	pl_intro(pc),a0
	move.l	(_resload,pc),a2
	jsr	(resload_Patch,a2)
.p1
	lea	$7E000,a1
	lea	pl_1(pc),a0
	move.l	(_resload,pc),a2
	jsr	(resload_Patch,a2)

	jmp	$7A000


run_intro
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	lea	pl_patch_intro(pc),a0
	lea	$1A000,a1
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jsr	$1000.W
	move.w	#$7FFF,($9A,A6)	; original
	add.l	#4,(A7)
	rts

avoid_af_intro
	move.w	(A6),D0	; stolen
	cmp.l	#0,a0
	beq.b	.skip

	cmp.w	(-4,a0),d0
	rts

.skip
	cmp.l	#1,a0	; Z flag not set
	addq	#4,A7	; pops up stack
	rts

pl_patch_intro
	PL_START
	PL_PS	$418,avoid_af_intro
	PL_END

pl_intro
	PL_START
	PL_PS	$7C,run_intro
	PL_END
pl_nointro
	PL_START
	; skip intro
	PL_S	$1E,$24	; skip load
	PL_S	$68,$18	; skip decrunch and call
	PL_END
pl_1:
	PL_START
	PL_P	$BB0,decrunch
	PL_P	$ADE,get_extmem
	PL_P	$362,read_sectors
	PL_P	$B8A,patch_2
	PL_END

patch_2
	move.l	_expmem(pc),a0
	movem.l	d0-d1/a0-a2,-(a7)

	bsr	patch_6a

	move.l	a0,a1

	lea	pl_2(pc),a0
	move.l	_custom2(pc),d0
	beq.b	.sk
	lea	pl_2_igk(pc),a0
.sk
	move.l	(_resload,pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2

	jmp	(a0)

; patch all occurrences of
; 	clr	($6A,A1)	; <- sometimes A1=0 -> crashes kb int
;	lea	($50,a0),a0

patch_6a
	movem.l	d0-d1/a0-a2,-(a7)
	patch	$100,avoid_kbint_write

	add.l	#$10000,a0
	lea	($3000,a0),a1
	lea	.clr_6a(pc),a2
	moveq	#4,d0
.loop
	bsr	hex_search
	cmp.l	#0,a0
	beq.b	.out
	move.l	#$4EB80100,(a0)+
	bra.b	.loop
.out
	movem.l	(a7)+,d0-d1/a0-a2
	rts
.clr_6a
	dc.l	$4269006A


pl_2_igk
	PL_START
	; trainer keys enabled all the time

	PL_L	$95F8,$4E714E71
	PL_NEXT	pl_2

pl_2:
	PL_START

	; keyboard

	PL_PS	$9508,kb_routine
	PL_PS	$1F0,set_interrupts

	; load

	PL_P	$2D5D2,read_sectors

	; removes a patch for traps $64->$7C

	PL_W	$1AC,$6010

	; patch to avoid the game to crash (protection??)

	PL_W	$191D0,$6004
	PL_W	$3DC42,$6004

	; copylock

	PL_PS	$2B6B4,copylock_emu
	PL_END

avoid_kbint_write
	cmp.l	#0,a1
	beq.b	.skip
	clr.w	($6A,A1)	; A1 = 0: clears LSW of interrupt vector
.skip
	rts

set_interrupts
	; install our keyboard interrupt

	pea	kb_interrupt(pc)
	move.l	(a7)+,$68.W

	; set INTENA value, adding keyboard interrupt

	move.w	#$C038,($9A,A6)
	rts

kb_routine
	move.b	kb_value(pc),d0
	cmp.b	#$CD,d0
	beq.b	.nokb

	MOVE.B	D0,12463(A5)		; stolen

	move.l	A0,-(a7)
	lea	kb_value(pc),a0
	move.b	#$CD,(a0)			; "acknowledge" kb
	move.l	(a7)+,A0
.nokb
	add.l	#$52,(a7)	; skip the rest
	rts

kb_value
	dc.w	$CDCD

kb_interrupt
	movem.l	d0/a5,-(a7)
	move.w	$DFF01E,d0
	btst	#3,d0
	beq.b	.nokb

	move.b	$bfec01,d0
	not.b	d0
	ror.b	#1,d0
	lea	kb_value(pc),a5
	move.b	d0,(a5)

	cmp.b	_keyexit(pc),D0
	bne	.noquit

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	bset	#6,$bfee01
	moveq	#2,d0
	bsr	_beamdelay	; handshake: 75 us minimum
	bclr	#6,$bfee01	

	bclr	#3,$bfed01
.nokb
	movem.l	(a7)+,d0/a5
	move.w	#8,$DFF09C
	rte


read_sectors
	movem.l	d1-d2/a0-a2,-(A7)

	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.readnothing		; length=0: out

	exg.l	d0,d2
	addq.l	#1,d2	; disk number

	exg.l	d0,d1

	ext.l	d0
	lsl.l	#7,d0
	lsl.l	#2,d0
	ext.l	d1
	lsl.l	#7,d1			;diskoffset
	lsl.l	#2,d1
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
.readnothing
	movem.l	(a7)+,d1-d2/a0-a2
	moveq	#0,d0
	rts

get_extmem
	lea	_expmem(pc),a0
	IFD	USE_FASTMEM
	add.l	#$10,(a0)	; workaround decrunch bug for pre-16.4 WHDload
	ELSE
	move.l	#$80000,(a0)
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
	
copylock_emu:

	move.l	#$5EE0F501,$F4.W
	move.l	#$3984EC01,d0	; fake copylock
	rts

real_copylock
	jsr	$800.W
	pea	TDREASON_DEBUG
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
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

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_loaddisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
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
