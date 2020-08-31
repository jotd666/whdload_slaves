;*---------------------------------------------------------------------------
;  :Program.	KidGlovesHD.asm
;  :Contents.	Slave for "KidGloves" from
;  :Author.	Abaddon & JOTD
;  :History.	01.07.06 - reworked by JOTD
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
	OUTPUT	KidGloves.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $0

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_ClearMem|WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	$58		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10

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

_name		dc.b	"Kid Gloves"
		dc.b	0
_copy		dc.b	"1990 Millenium",0
_info		dc.b	"adapted & fixed by Abaddon/JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)					;save for later use

	lea	$400.W,a7

	lea	loader(pc),a0
	lea	$14c08,a1
	move.l  (_resload,pc),a2
	jsr     (resload_LoadFile,a2)

;;	move.w	#0,$dff100

	move.w	#$8210,$dff096
	MOVE	#$2700,SR

	lea	pl_main(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)

	sub.l	a0,a0
	sub.l	a1,a1
	sub.l	a2,a2
	sub.l	a3,a3
	sub.l	a4,a4
	sub.l	a5,a5
	sub.l	a6,a6
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d7

	jmp		$14c08

fix:
	andi.l	#$5ffff,d2
	move.l	d2,a2
	tst.w	(a2)
	bne		.ok
	jmp		$17ec6
.ok
	jmp		$17ed2
.fuck
	jmp		$17eec


pl_main
	PL_START
	PL_W	$1dc4a,0
	PL_P	$1d91c,loadf
	PL_P	$1d8f6,loadcrap	
	PL_P	$17ec0,fix

	PL_PS	$1C960,get_kb_dat
	PL_PS	$1C974,kb_delay
	PL_END

get_kb_dat
	move.b	($C00,a0),d0
	not.b	d0

	move.l	d0,-(a7)
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	bne.b	.noq

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
.noq
	move.l	(a7)+,d0
	rts

kb_delay
	move.l	d0,-(a7)
	move.l	#2,d0
	bsr	beamdelay
	move.l	(a7)+,d0

	; skip the BRA that fucks up keyboard reading
	addq.l	#4,(a7)
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

loadf:
	movem.l	d0-a6,-(a7)
	lea 	loader(pc),a0
	move.b	#$31,$7(a0)
	lea	$41ac4,a1
	move.l  (_resload,pc),a2
	jsr     (resload_LoadFile,a2)
	movem.l	(a7)+,d0-a6
	move.b	#$ff,$1d5cb
	rts

loadcrap:
	movem.l	d0/a0,-(a7)
	move.w	#$4ff,d0
	lea	$41ac4,a0
reloc3:
	move.l	#$eaeaeaea,(a0)+
	dbf	d0,reloc3
	movem.l	(a7)+,d0/a0
	rts

;--------------------------------
loader:
	dc.b	"kgloves0.bin",0
	even
_resload	dc.l	0		;address of resident loader

;======================================================================

	END
