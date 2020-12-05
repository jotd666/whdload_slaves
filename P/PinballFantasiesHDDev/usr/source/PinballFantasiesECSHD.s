;*---------------------------------------------------------------------------
;  :Program.	PinballFantasies.asm
;  :Contents.	Slave for "Pinball Fantasies" from Digital Illusion
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	31.12.97
;		08.09.00 adapted for whdload v10 (aminet release)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i

	IFD		BARFLY
	OUTPUT	"PinballFantasiesECS.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC
	
;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w    0     ; kickstart name
		dc.l    $0         ; kicksize
		dc.w    $0         ; kickcrc
		dc.w	slv_config-_base

slv_config:
		dc.b    "C1:B:Skip introduction;"
		dc.b	0

;============================================================================
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"3.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	

_name		dc.b	"Pinball Fantasies",0
_copy		dc.b	"1992 Digital Illusions",0
_info		dc.b	"Install by MrLarmer/Wepl",10
		dc.b	"Additions by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

		EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		lea	$70000,A0
		moveq	#0,D0
		move.l	#$1600,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		move.w	#$4EF9,$701A8
		pea	Patch(pc)
		move.l	(A7)+,$701AA

		clr.b	4.w
		move.l	#$80000,$100.w		; ext mem

		jmp	$700EC
		; 5072: bfec01,D0 kb
Patch
		addq.l	#4,A7

		movem.l	D0-A6,-(A7)

		lea	$1800.w,A0
		move.l	#$1858*3+10,D0
		move.l	#$2800,D1
		moveq	#1,D2
		bsr.w	_LoadDisk

		lea	pl_intro(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		
		movem.l	(A7)+,D0-A6
		jmp	$1800.w
		
pl_intro:
	PL_START
	PL_IFC1
	PL_B	$18C4,$60	; skip introduction
	PL_ENDIF
	
	PL_W	$187A,$6004	; skip screen with ext mem
	PL_W	$18A6,$6004
	PL_NOP	$18EC,2	; else winuae locks up
	PL_P	$28E8,Load
	PL_L	$C,'PD2A'		; disk 1
	PL_P	$1BF0,intro_kb_routine
	PL_PS	$1936,jmp_4000
	PL_END
	
jmp_4000:
	movem.l	D0-A6,-(A7)
	; install 68k keyboard handler
	lea	pl_main(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(A7)+,D0-A6
	JMP	$4000.W
pl_main:
	PL_START
	PL_PS	$5072,read_keyboard
	PL_END
	
read_keyboard:
	move.b	$BFEC01,d0	; original
	movem.w	D0,-(A7)
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	cmp.b	_keyexit(pc),d0
	beq.b		quit_game	
	movem.w	(A7)+,D0
	rts
	
intro_kb_routine:
	movem.l	D0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	cmp.b	_keyexit(pc),d0
	beq.b	quit_game

	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a5
	move.w	#8,$dff09c
	rte
	
quit_game
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
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
	
; 000040C8 21fc 0000 5054 0068      MOVE.L #$00005054,$0068 [00005054]

Load
		movem.l	d0-a6,-(a7)

		moveq	#0,D4

		cmp.w	#2,D0		; save highs
		beq.w	Save

		cmp.w	#3,D0		; load file
		bne.w	next
readroot
		movem.l	D0-A6,-(A7)

		lea	$39C0.w,A0
		move.l	#$1858+4,D0
		move.l	#$100,D1
		moveq	#0,D2
		move.b	$F.w,D2
		sub.b	#$40,D2
		bsr.w	_LoadDisk

		movem.l	(A7)+,D0-A6

		lea	$39B0.w,A0
		lea	$100(A0),A1
loop
		cmp.l	(A0)+,D1
		beq.b	ok
		addq.l	#4,A0

		cmp.l	A0,A1
		beq.b	disk1

		bra.b	loop
disk1
		move.l	#'PD2A',$C.w
		bra.b	readroot
ok
		moveq	#0,D0
		move.w	(A0)+,D0
		mulu	#$1858,D0
		moveq	#0,D1
		move.w	(A0),D1
		add.l	D1,D0
		addq	#2,D0
nextfile
		movem.l	D0/D2-D7/A1-A6,-(A7)

		subq.l	#8,A7
		move.l	A7,A0
		moveq	#8,D1
		moveq	#0,D2
		move.b	$F.w,D2
		sub.b	#$40,D2
		bsr.w	_LoadDisk

		move.l	(A7)+,A0
		move.l	(A7)+,D1

		movem.l	(A7)+,D0/D2-D7/A1-A6

		addq.l	#8,D0
		moveq	#0,D2
		move.b	$F.w,D2
		sub.b	#$40,D2
		bra.b	next2
next
		cmp.w	#4,D0		; read bytes
		bne.w	quit

		moveq	#0,D0
		move.w	D1,D0
		moveq	#0,D1
		move.w	D2,D1
		moveq	#0,D2
		move.b	$F.w,D2
		cmp.b	#'A',D2
		bne.b	notA
		move.b	#'B',D2
		move.b	D2,$F.w
		bra.b	next3
notA
		cmp.b	#'B',D2
		bne.b	notB
		move.b	#'C',D2
		move.b	D2,$F.w
		bra.b	next3
notB
		cmp.b	#'C',D2
		bne.b	notC
		move.b	#'B',D2
		move.b	D2,$F.w
notC
next3
		sub.b	#$40,D2
		move.l	D3,A0
next2
		move.l	A0,D4
		btst	#31,D4
		beq.b	skip

		move.l	$100.w,A0
skip
		bsr.w	_LoadDisk

		cmp.b	#'A',$F.w
		beq.b	sk

		cmp.l	#$30000,A0
		bne.b	sk

		add.l	D1,D0
		addq.l	#2,D0
		bra.w	nextfile
sk
		cmp.l	#'PP20',(A0)
		bne.b	quit

		movem.l	D0-A6,-(A7)

		move.l	A0,A2
		lea	(A2,D1.l),A0
		lea	8(A2),A3
		lea	4(A2),A5

		jsr	$388C.w		; decrunch PP20

		movem.l	(A7)+,D0-A6

		btst	#31,D4
		beq.b	quit
SEL
		add.l	D1,D0
		add.l	#12,D0
		bra.w	nextfile
quit
		movem.l	(A7)+,d0-a6
		moveq	#0,D0
		rts
Save
		lea	_savename(pc),a0	;filename
		moveq	#0,D0
		move.b	$F.w,D0
		sub.b	#$10,D0
		move.b	D0,5(A0)
		move.l	#$80,d0			;len
		move.l	#$4912,d1		;offset
		lea	$200.w,a1		;address
		move.l	_resload(pc),a2
		jsr	resload_SaveFileOffset(a2)

		bra.b	quit

_savename	dc.b	"Disk.2",0
	CNOP 0,2

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
