;*---------------------------------------------------------------------------
;  :Program.	TheBluesBrothers.asm
;  :Contents.	Slave for "The Blues Brothers" from Titus
;  :Author.	Mr.Larmer of Wanted Team, StingRay
;  :History.	23.06.01.
;       2019 (JOTD)
;       - added CD32 joypad controls
;       - added option to jump with second button
;		21.11.17 (StingRay)
;		- byte write to volume register fixed
;		- default quitkey changed to Del
;		- main.prg is now loaded directly, loader stuff removed
;		- patch now uses real files
;		- illegal copperlist entry fixed
;		- interrupts fixed
;		22.11.17
;		- protection check removal simplified
;		- 68000  quitkey support
;		23.11.17
;		- trainer options added
;		- WHDLoad v17+ needed now (config)
;		- sample player fixed (took a while!)
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

CHIPMEMSIZE = $80000

;============================================================================

HEADER
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem	;ws_flags
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


.config	dc.b	"C1:X:Unlimited Lives:0;"
	    dc.b	"C1:X:Unlimited Energy:1;"
        dc.b    "C2:X:blue/second button jumps:0;"
		dc.b	"C3:X:use disk.1 image instead of files:0;"
        dc.b    "C4:L:Start level:The Department Store,The Warehouse,The Jail,The Sewer,The High Rises,The Gig;"
	dc.b	0

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
_copy		dc.b	"2021 ??",0
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
	MOVEA.L	#$00dff186,A1		;0108: 227c00dff186
.1:
	MOVE.L	(A0),D0			;010e: 2010
	EOR.L	D6,D0			;0110: bd80
	SWAP	D0			;0112: 4840
	MOVE.L	D0,(A0)+		;0114: 20c0
	ROL.L	#1,D6			;0116: e39e
	SUBQ.L	#1,D7			;0118: 5387
	CMP.L	D5,D7			;011a: be85
	BNE.S	.1		;011c: 66f0

; patch
	;;movem.l	d0-d2/a0-a2,-(a7)
	

	
	lea		pl_main(pc),a0
	lea		LOAD_ADDRESS,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	LOAD_ADDRESS




pl_main:
	PL_START

	PL_END

	
.checkquit
	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0



	cmp.b	_base+ws_keyexit(pc),d0
	beq.w	QUIT
	move.b	$bfec01,d0
	rts	


.load	move.l	a6,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,d0-a6
	moveq	#0,d0
	unlk	a6
	rts


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

resload:
	dc.l	0

