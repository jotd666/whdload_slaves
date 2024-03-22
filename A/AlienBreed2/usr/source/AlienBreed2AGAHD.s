;*---------------------------------------------------------------------------
;  :Program.	AlienBreed2AGA.asm
;  :Contents.	Slave for "Alien Breed 2 AGA" from Team 17
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	23.03.2001
;                  01.2004 JOTD
;                          added fastmem support (optional at compile time)
;                          code cleanup
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44, Barfly
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i


	IFD BARFLY
	OUTPUT	"AlienBreed2AGA.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER

	DOSCMD	"WDate  >T:date"
	ENDC

; set EXPCHIP to locate expansion mem at $100000 (easier to debug)
;EXPCHIP = 1
	IFD	EXPCHIP
CHIPMEMSIZE = $1FF000
	ELSE
CHIPMEMSIZE = $100000
	ENDC

;======================================================================

_base
		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_ReqAGA|WHDLF_NoKbd	;ws_flags
		dc.l	CHIPMEMSIZE
		dc.l	0			;ws_ExecInstall
		dc.w	Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
		IFD	EXPCHIP
_fexpmem	dc.l	0			;ws_ExpMem
		ELSE
_expmem
		dc.l	$100000
		ENDC

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

;============================================================================


DECL_VERSION:MACRO
	dc.b	"1.6"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_name		dc.b	"Alien Breed 2 AGA"
	IFD	EXPCHIP
	dc.b	" (DEBUG MODE)"
	ENDC
	dc.b	0
_copy		dc.b	"1993 Team 17",0
_info		dc.b	"adapted by Mr.Larmer & JOTD",10
		dc.b	"mods by ztronzo",10,10
		dc.b	"Greetings to Chris Vella",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

_config
        dc.b    "C1:X:Start with 100000 credits:0;"
        dc.b    "C1:X:Start with 99 lives:1;"
        dc.b    "C1:X:Start with 99 keys:2;"
        dc.b    "C1:X:Use N to skip levels:3;"
        dc.b    "C2:X:Strafe Mode while holding fire:0;"
        dc.b    "C2:X:No collision between human players:1;"
		dc.b	0
	
highsname	dc.b	"AB2.highs",0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

		even
	IFD	EXPCHIP
_expmem
	dc.l	$100000
	ENDC

;======================================================================
Start	;	A0 = resident loader
;======================================================================
		lea	CHIPMEMSIZE-$100,a7	; supervisor stack

		clr.l	$4.W			; else shoot bug at first life! typical Team 17 error (same on superfrog space level)

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	_resload(pc),a2

		move.w	#$8220,$DFF096

		lea	$8000,a0
		move.l	#$1600,d0
		move.l	#$1600,d1
		moveq	#1,d2
		bsr.w	_LoadDisk

		lea	$8000,a0
		move.l	#$1600,d0
		jsr	resload_CRC16(a2)

		cmp.l	#$6E78,d0
		beq.b	.ok

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.ok
		lea	$8000,a0
		move.l	_expmem(pc),$1F2(a0)
		clr.l	$1EE(a0)	; 2nd expansion
		move.l	#$400,$1F6(a0)	; base memory ???

	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	move.l	a0,a1
	lea	_pl_1(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	jmp	4(a0)

_pl_1
	PL_START
	PL_P	$2DE,ATNDecrunch
	PL_P	$D2,Patch
	PL_P	$538,Load

	PL_W	$290,$4E71	; Mr Larmer
	PL_W	$29E,$4E71
	PL_END

ATNDecrunch:
	movem.l	D1/A0-A2,-(A7)
	MOVE.L	_resload(PC),A2
	JSR	(resload_Decrunch,a2)
	movem.l	(A7)+,D1/A0-A2
	rts

;--------------------------------

Patch
	movem.l	d0-d1/a0-a2,-(a7)
	lea	_pl_4(pc),a0
	lea	$FF000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$FF000


_pl_4:
	PL_START
	PL_P	$88,Patch2
	PL_P	$34E,Load
	PL_END

;--------------------------------

Patch2
	movem.l	d0-d1/a0-a2,-(a7)

	move.l	_expmem(pc),a1

	move.l	_resload(pc),a2

	lea	_pl_3(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	move.l	$FF08E,a2	; stolen code
	jmp	(a1)

_pl_3:
	PL_START
	PL_B	$384A,$60		; skip check highs
	PL_P	$D94C,Load
;;	PL_P	$DDD4,Load		; added by JFF
	PL_P	$E9D2,Highs

	PL_L	$3876,$70004E75	; skip check save highs disk
	PL_L	$DDCC,$70004E75	; check how many drives connected

	PL_W	$3742,$602A	; remove some checks (fire/floppy)
	PL_W	$37E6,$6008

	PL_IFC1X	0
	PL_L	$1AA2,100000	; money
	PL_ENDIF
	PL_IFC1X	1
	PL_W	$1AA8,99	; lives
	PL_ENDIF
	PL_IFC1X	2
	PL_W	$1AAA,99	; keys
	PL_ENDIF
	PL_IFC1X	3
	PL_NOP	$7702,4	; enables "N" to skip levels
	PL_ENDIF
	PL_PS	$1A640,Keyboard	; possible to quit with NOVBRMOVE set
	PL_PS	$233C4,fix_af_1	; issue #0002183 access fault

	; new modding options, added by ztronzo
	PL_IFC2X	0
	PL_PSS	$13520,.strafe_start,26 ; enable strafe mode for each player while shooting
	PL_ENDIF
	PL_IFC2X	1
	PL_W	$1157C,$6000	; allows human players to walk through each other
	PL_ENDIF
	
	PL_END

.strafe_start
	cmpa.L #$00DFF00C,A2
	bne.b	.strafe_check_player1
	beq.b	.strafe_check_player2
	;bt.b .no_strafe

.strafe_check_player1
	BTST.B #$07,$00bfe001
	beq.b	.strafe_player1
	bra.b .no_strafe
	
.strafe_check_player2
	BTST.B #$06,$00bfe001	
	beq.b	.strafe_player2
	bra.b .no_strafe
		
.strafe_player1
	cmpa.L #$00DFF00C,A2
	bne.b	.strafe_done

.strafe_player2
	cmpa.L #$00DFF00C,A2
	beq.b	.strafe_done
	
.no_strafe 	; restoring original instructions without strafe START
	TST.W D0
	BPL.B .no_strafe_cmp2
	NEG.W D0
.no_strafe_cmp1	CMP.W #$0004,D0
	BHI.B .no_strafe_sub
	bra.B .no_strafe_add
.no_strafe_cmp2	CMP.W #$0004,D0
	BMI.B .no_strafe_sub
	bra.B .no_strafe_add
.no_strafe_sub	SUB.W #$01,$0068(A0)
	bra.B .strafe_done
.no_strafe_add	ADD.W #$01,$0068(A0) 	; restoring original instructions without strafe END
	
.strafe_done
	rts

; JFF: did not see it by myself but saw a register log...
; Access fault with rebounder weapon

fix_af_1
	and.l	#$FFFF,d1
	cmp.l	#$1350,d1
	bcs.b	.ok
	move.l	#$1350,d1	; limit value to avoid access fault later...
.ok
	rts
Keyboard:
	move.b	$BFEC01,D0
	move.l	D0,-(sp)
	not.b	D0
	ror.b	#1,D0

	cmp.b	_keyexit(pc),D0		; F10 quits in the menu
	bne	.noquit

	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
	
.noquit
	move.l	(sp)+,D0
	rts	

;--------------------------------

Highs
		movem.l	d0-d2/a0-a2,-(a7)

		move.l	a0,a1

		btst	#0,d3
		bne.b	.save

		lea	highsname(pc),a0
		move.l	a1,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		tst.l	d0
		beq.b	.not_exist

		lea	highsname(pc),a0	;filename
		move.l	(sp)+,a1		;address
		jsr	resload_LoadFile(a2)
.exit
		movem.l	(a7)+,d0-d2/a0-a2
		moveq	#0,d0
		rts
.not_exist
		addq.l	#4,a7
		move.l	_expmem(pc),a1
		add.l	#$3F06,A1		; original highs
.save
		move.l	#$A0,d0			;len
		lea	highsname(pc),a0	;filename
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)

		bra.b	.exit

;--------------------------------

Load
		movem.l	d0-d2/a0,-(a7)

		moveq	#0,d0
		move.w	d1,d0
		mulu	#$200,d0
		moveq	#0,d1
		move.w	d2,d1
		beq.b	.out
		mulu	#$200,d1
		moveq	#0,d2
		move.b	d4,d2
		and.b	#$F,d2	; rn key is $123111 for disk #1, $123222 for disk #2...

		bsr.b	_LoadDisk
.out
		movem.l	(a7)+,d0-d2/a0
		moveq	#0,d0
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

_flushcache
		movem.l	a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)
		movem.l	(a7)+,a2
		rts
;======================================================================

	END
