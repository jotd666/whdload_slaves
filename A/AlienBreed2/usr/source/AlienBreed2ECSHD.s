;*---------------------------------------------------------------------------
;  :Program.	AlienBreed2ECS.asm
;  :Contents.	Slave for "Alien Breed 2 ECS" from Team 17
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	23.03.2001
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


	IFD	BARFLY
	OUTPUT	"AlienBreed2ECS.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER

	ENDC

; set CHIP_ONLY to locate expansion mem at $80000 (easier to debug)
;CHIP_ONLY = 1
	IFD	CHIP_ONLY
CHIPMEMSIZE = $100000
	ELSE
CHIPMEMSIZE = $80000
	ENDC

;======================================================================

_base
		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_Disk|WHDLF_NoKbd	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
		IFD	CHIP_ONLY
		dc.l	0			;ws_ExpMem
		ELSE
_expmem
		dc.l	$80000
		ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

		IFD	CHIP_ONLY
_expmem
		dc.l	$80000
		ENDC
_config
        dc.b    "C1:X:Trainer Infinite Energy & Lives:0;"
		dc.b	0

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

_name		dc.b	"Alien Breed 2 ECS"
		IFD	CHIP_ONLY
			dc.b	" (DEBUG/CHIP MODE)"
		ENDC
		dc.b	0
_copy		dc.b	"1993 Team 17",0
_info		dc.b	"adapted by Mr.Larmer",10
		dc.b	"extra fixes by JOTD",10,10
		dc.b	"Greetings to Helmut Motzkau",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
highsname	dc.b	"AB2.highs",0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

	EVEN

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		move.l	a0,a2
		
		clr.l	$4.W		; fix shoot bug

		move.w	#0,SR
		move.w	#$8220,$DFF096

		lea	$8000,a0
		move.l	#$57804,d0	; offset
		move.l	#$1600,d1	; size
		moveq	#1,d2
		bsr.w	_LoadDisk

		lea	$8000,a0
		move.l	#$1600,d0
		jsr	resload_CRC16(a2)
		cmp.l	#$7690,d0
		beq.b	.v1
		cmp.l	#$7944,d0
		beq.b	.v2
		bra.b	.wrong_version
.v2
		moveq	#2,d0
		bra.b	.cont
.v1
		moveq	#1,d0
.cont
		lea	version(pc),a0
		move.l	d0,(a0)

		lea	$8000,a0
		move.l	#$1600,d0	; offset
		move.l	#$1600,d1	; size
		moveq	#1,d2
		bsr.w	_LoadDisk

		lea	$8000,a0
		move.l	#$1600,d0
		jsr	resload_CRC16(a2)
		cmp.l	#$D3FC,d0
		beq.b	.ok

.wrong_version
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.ok

		lea	$8000,a1
		movem.l	a0-a1,-(a7)
		move.l	_expmem(pc),d0
		move.l	d0,$1F2(a1)

		lea	pl_boot(pc),a0
		jsr	resload_Patch(A2)
		movem.l	(a7)+,a0-a1

		jmp	(4,a1)


pl_boot
		PL_START
		PL_P	$D2,patch1

		PL_NOP	$29A,2		; fix get stack data
		PL_NOP	$2A8,2

		PL_P	$542,load
		PL_END

version
	dc.l	0

hiscore_offset:
	dc.l	0

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

;--------------------------------

patch1
	patch	$7E8E6,load
	movem.l	d0/a0-a1,-(a7)
	lea	patch2_v1(pc),a1
	move.l	version(pc),d0
	cmp.l	#2,d0
	bne.b	.sk
	lea	patch2_v2(pc),a1
.sk
	lea	$7F704,a0
	move.w	#$4EF9,(a0)+
	move.l	a1,(a0)

	movem.l	(a7)+,d0/a0-a1
	bsr	_flushcache
	jmp	$46620

;--------------------------------

patch2_v1
		movem.l	d0-d1/a0-a2,-(a7)
		lea	hiscore_offset(pc),a0
		move.l	#$3F88,(a0)
		lea	pl_2_v1(pc),a0
		move.l	_expmem(pc),a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2

		move.l	$7F736,a2
		jmp	(a1)			; a1=$80FA0

patch2_v2
		movem.l	d0-d1/a0-a2,-(a7)
		lea	hiscore_offset(pc),a0
		move.l	#$3F92,(a0)
		lea	pl_2_v2(pc),a0
		move.l	_expmem(pc),a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2

		move.l	$7F736,a2
		jmp	(a1)			; a1=$80FA0

pl_2_v1
	PL_START
	PL_IFC1
	PL_B	$251BC,$4A	;lives
	PL_B	$25374,$4A	;energy
	PL_B	$25378,$4A	;energy
	PL_ENDIF
	PL_B	$38CC,$60		; skip check highs
	PL_L	$38F8,$70004E75		; skip check save highs disk
	PL_P	$DC42,load
	PL_L	$E0CA,$70004E75
	PL_P	$ECC8,highs
	PL_PS	$23630,fix_af_1
	PL_NOP	$77D8,4	; skip levels with "N"
    
    PL_PSS  $1A8F4,keyboard,4    ; quit key on 68000
	PL_P	$1e4c0,wait_blit	; replace blitter wait
	PL_END


pl_2_v2
	PL_START
	PL_IFC1
	PL_B	$251B6,$4A	;lives
	PL_B	$2536E,$4A	;energy
	PL_B	$25372,$4A	;energy	
	PL_ENDIF
	PL_B	$38D8,$60		; skip check highs
	PL_L	$3902,$70004E75		; skip check save highs disk
	PL_P	$DC3C,load
	PL_L	$E0C4,$70004E75
	PL_P	$ECC2,highs
	PL_PS	$2362A,fix_af_1
	PL_NOP	$77E2,4	; skip levels with "N"

    PL_PSS   $1A8EE,keyboard,4    ; quit key on 68000
	PL_P	$1e4ba,wait_blit	; replace blitter wait

	PL_END

; original routine doesn't test BFE001 first so timing issues
; can occur on some machines (issue #5999)
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
	
keyboard:
    MOVE.B $00bfec01,D0
    ror.b   #1,d0
    not.b   d0
    movem.l d0,-(a7)
    cmp.b   _keyexit(pc),d0
    bne.b   .noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts    
.noquit
    movem.l (a7)+,d0
    rts

;--------------------------------

; JFF: did not see it by myself but saw a register log...
; Access fault with rebounder weapon

fix_af_1
	and.l	#$FFFF,d1
	cmp.l	#$1350,d1
	bcs.b	.ok
	move.l	#$1350,d1	; limit value to avoid access fault later...
.ok
	rts
;--------------------------------

highs
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
		add.l	hiscore_offset(pc),a1		; original highs
.save
		move.l	#$A0,d0			;len
		lea	highsname(pc),a0	;filename
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)

		bra.b	.exit

;--------------------------------

load
		movem.l	d0-d2/a0,-(a7)

		moveq	#0,d0
		move.w	d1,d0
		mulu	#$200,d0
		moveq	#0,d1
		move.w	d2,d1
		mulu	#$200,d1
		moveq	#0,d2
		move.b	d4,d2
		and.b	#$F,d2

		bsr.b	_LoadDisk

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

;======================================================================

	END
