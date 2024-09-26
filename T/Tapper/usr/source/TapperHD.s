;*---------------------------------------------------------------------------
;  :Program.	TapperHD.s
;  :Contents.	Slave for "Tapper" from Old Bob
;  :Author.	JOTD
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44, ASM-Pro 1.16d
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


	IFD	BARFLY
	OUTPUT	Tapper.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER

	DOSCMD	"WDate  >T:date"
	ENDC

CHIPMEMSIZE = $100000

;============================================================================

HEADER
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_NoKbd|WHDLF_ClearMem	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$46			;ws_keyexit = Del
_expmem		dc.l	0
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info


; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config		dc.b	0

;============================================================================

DECL_VERSION:MACRO
	dc.b	"1.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_data		dc.b	"data",0

_name		dc.b	"Tapper",0
_copy		dc.b	"2023 Old Bob",0
_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

main		dc.b	"game.bin",0

		dc.b	"$","VER: slave "
		DECL_VERSION
		dc.b	0


		EVEN


LOAD_ADDRESS = $30000
	
;============================================================================
_start	;	A0 = resident loader
;============================================================================

	lea	resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2

	
	lea	main(pc),a0
	lea	LOAD_ADDRESS,a1
	jsr	resload_LoadFile(a2)

; decrunch
	lea		LOAD_ADDRESS,A0		;00f0: 207c00030000
	MOVE.L	#$ffffffff,D5		;00f6: 2a3cffffffff
	MOVE.L	#$92492492,D6		;00fc: 2c3c92492492
	MOVE.L	#$00023645,D7		;0102: 2e3c00023645
.1:
	MOVE.L	(A0),D0			;010e: 2010
	EOR.L	D6,D0			;0110: bd80
	SWAP	D0			;0112: 4840
	MOVE.L	D0,(A0)+		;0114: 20c0
	ROL.L	#1,D6			;0116: e39e
	SUBQ.L	#1,D7			;0118: 5387
	CMP.L	D5,D7			;011a: be85
	BNE.S	.1		;011c: 66f0

	
	lea		pl_main(pc),a0
	lea		LOAD_ADDRESS,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	
	pea		keyboard_interrupt(pc)
	move.l	(a7)+,$68.w
	
	move.w	#$C008,_custom+intena
	
	MOVE.L	#$00007fff,D1
	jmp	LOAD_ADDRESS+$C



keyboard_interrupt
	movem.l	D0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here

    cmp.b   _keyexit(pc),d0
    beq.b   _quit


	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a5
	move.w	#8,$dff09c
	rte


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
kb_ack:
kb_delay:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
	rts

pl_main:
	PL_START

	PL_END



_quit	pea	(TDREASON_OK).w
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

resload:
	dc.l	0

