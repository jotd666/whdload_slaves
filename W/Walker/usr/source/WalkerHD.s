;*---------------------------------------------------------------------------
; Program:	Walker.s
; Contents:	Slave for "Walker" (c) 1993 DMA Design/Psygnosis
; Author:	Codetapper of Action
; History:	16.06.02 - v1.0
; Requires:	WHDLoad 10+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Info:		The unusual stack setup is done to fix an access fault in the
;		RNC depacker. If you set the game address to $80000 and then
;		depack a file to $80000, the routine will read from $7fffe.
;		This will obviously cause problems if the game memory is in
;		fast memory and WHDLoad will catch it as an illegal access.
;		Hence I set USP to $700, SSP to $f00 and the game address to
;		$1000 (all offset from _expmem) to avoid the problem.
;
;		$8671a = $ff if speech is available
;		$8671b = $ff if speech is on or $0 if off
;
; Cheat Info:	$8a4c0 sets the built in WALKER cheat on the title screen
;		in the frontend file.
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

;======================================================================

STACK_SIZE	equ	$1000
;CHIP_ONLY

;======================================================================

		IFD BARFLY
		IFD SPEECH
		OUTPUT	"Walker.slave"
		ELSE
		OUTPUT	"WalkerNoSpeech.slave"
		ENDC
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		IFD	CHIP_ONLY
		dc.l	$200000
		ELSE
		IFD	SPEECH
		dc.l	$c2000			;ws_BaseMemSize
		ELSE
		dc.l	$80000			;ws_BaseMemSize
		ENDC
		ENDC
		
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_Data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem	
		IFD		CHIP_ONLY
		dc.l	0
		ELSE
		dc.l	$80000+STACK_SIZE	;ws_ExpMem
		ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================


DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_name		dc.b	"Walker"
		IFND	SPEECH
		dc.b	" (No Speech)"
		ENDC
		dc.b	0
_copy		dc.b	"1993 DMA Design/Psygnosis",0
_info		dc.b	"Installed by Codetapper & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1,"Keys: F6 - No overheating  F7 - Infinite energy"
		dc.b	10,"      F8 - Shoot anywhere  F9 - Infinite lives "
		dc.b	10,"     Del - Skip level                          "
		dc.b	-1,"Thanks to Chris Vella for the original!",0
_Data		dc.b	"data",0
_MainName	dc.b	"boot",0
_Frontend	dc.b	"frontend.ppc",0
_Highs		dc.b	"Walker.highs",0
_CheatFlag	dc.b	0
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		IFD		CHIP_ONLY
		; fake exp in chip (debug)
		lea		_expmem(pc),a0
		move.l	#$100000,(a0)
		ENDC
_restart	

		move.l	_expmem(pc),d0
		add.l	#STACK_SIZE-$100,d0
		lea	_StackAddress(pc),a0	;Save stack address
		move.l	d0,(a0)
		move.l	d0,sp
		sub.l	#(STACK_SIZE>>1),d0
		move.l	d0,a0
		move.l	a0,usp

		lea	_GameAddress(pc),a0	;Save game loading address. This
		move.l	_expmem(pc),d0		;must not be at the base of a 
		add.l	#STACK_SIZE,d0		;memory block as the depacker has
		move.l	d0,(a0)			;a bug and reads from 2 bytes below it!

		lea	_MainName(pc),a0	;a0 = Name
		lea	$10000,a1		;a1 = Destination
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)

		lea	_PL_Boot(pc),a0		;Patch boot
		move.l	a5,a1
		jsr	resload_Patch(a2)

		move.l	a5,d0			;Set d0 to some spare memory
		add.l	#$1000,d0

		move.l	d0,a0
		move.l	#($4000/4)-1,d7
.Clear		move.l	#0,(a0)+
		dbf	d7,.Clear

		jmp	$1a(a5)			;Start game

_PL_Boot	PL_START
		PL_L	$98,$45ed0496		;Replace jsr $c0 ($4eb800c0 from trainer) with lea ($496,a5),a2
		PL_P	$e4,_Walker		;Patch Walker file
		PL_I	$ea			;Quit on fatal errors
		PL_P	$f4,_Loader		;Loader
		PL_L	$77e,$70004e75
		PL_PS	$cb2,_ChipMemory	;Allocate $7ff00 bytes
		PL_PS	$cce,_GameMemory	;Allocate $80000 bytes
		PL_PS	$cea,_SpeechMemory	;Allocate $61a80 bytes for speech
		PL_I	$d3c			;Memory allocation
		PL_L	$e4c,$70004e75		;Cache control
		PL_S	$e84,$8c-$84		;Disable
		PL_END

int6:
	MOVE.L	A0,-(A7)	;109742: 48e7fffe
	move.l	orig_int6(pc),a0
	cmp.w	#$48E7,(a0)
	beq.b	.orig_installed
	MOVE.L	(A7)+,A0	;10977c: 4cdf7fff
	move.w	#$2000,_custom+intreq	; ack
	RTE				;109780: 4e73
	; during the intro, the original routine is required
	; to trigger level 2 interrupts from level 6 interrupts
	; during the game, it's destroyed, but if it's triggered
	; for example by exotic hardware, it crashes
.orig_installed
	MOVE.L	(A7)+,A0	;10977c: 4cdf7fff
	move.l	orig_int6(pc),-(a7)
	rts
	
;======================================================================

_ChipMemory	move.l	#$100,d0
		bra	_MemoryAlloced

_GameMemory	move.l	_GameAddress(pc),d0
		bra	_MemoryAlloced

_SpeechMemory	IFD	SPEECH
		move.l	#$80000,d0		;Deliberately falls through
		ELSE
		moveq	#-1,d0
		tst.l	d0
		rts
		ENDC

_MemoryAlloced	move.l	d0,a0
		moveq	#0,d0
		tst.l	d0
		rts

;======================================================================

_Walker		
	
		movea.l	($8a,a5),a5		;Stolen code
		movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_Walker(pc),a0	;Patch main game
		move.l	a5,a1			;a1 = Destination
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	_StackAddress(pc),d0		;Stack to fast memory
		move.l	d0,$12(a5)
		move.l	d0,$90(a5)

		movem.l	(sp)+,d0-d1/a0-a2
		jmp	(a5)

_PL_Walker	PL_START
		PL_B	$3e,$60			;CACR test
		PL_P	$74,_jmp_60000		;jmp $60000
		PL_END
		
_pl_walker_60000:
		PL_START
		PL_B	$3c,$60			;CACR test
		PL_PS	$efa-$7a,_LoadHighScores	;Test gmanager.ppd decrunched OK
		PL_P	$f80-$7a,_GManager		;movea.l (8,a0),a2 and jmp (a5) - trained version writes jmp $ca ($4ef800ca)
		PL_NOP	$14ac-$7a,4		;Disk check
		PL_P	$1620-$7a,_Loader		;Loader
		PL_P	$25c6,_RNCDecruncher	;Decrunch with varying decryption key 
		PL_END

;======================================================================

_GManager	movea.l	(8,a0),a2		;Stolen code
		movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_GManager(pc),a0	;Patch main game
		move.l	a5,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	_StackAddress(pc),d0	;SSP to fast memory
		move.l	d0,$a(a5)		;lea $80000,sp

		movem.l	(sp)+,d0-d1/a0-a2
		jmp	(a5)

_PL_GManager	PL_START
		PL_PS	$92,_Logo
		PL_PS	$c2,_PatchFrontend
		PL_NOP	$3fc2,4		;Disk check
		PL_PS	$4126,_Keybd		;move.b $bfec01,d0
		PL_P	$51da,_Loader		;Loader
		PL_P	$61fa,_RNCDecruncher
		PL_END

;======================================================================

_Logo		movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_Logo(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2
		jmp	$7000

_PL_Logo	PL_START
		PL_PS	$718a,_IntroDelay	;Skip awful delay on intro!
		PL_L	$7490,$4e714e71		;Disk check
		PL_W	$799c,$4e71		;Don't load frontend.ppc to $2683e
		PL_PS	$79fc,_CopyA0ToA1	;move.b (a0)+,(a1)+ and dbra d0,$79fc
		PL_PS	$7a10,_LoadFrontend
		PL_S	$7a16,$3a-$16
		PL_PS	$7a48,_PatchFrontFrst	;adda.l #$61fa,a3
		PL_END

;======================================================================

_CopyA0ToA1	move.b	(a0)+,(a1)+		;Causes a bug on 68060's
		dbra	d0,_CopyA0ToA1		;if you don't flush the
		bra	_FlushCache		;cache

;======================================================================

_LoadFrontend	lea	_Frontend(pc),a0	;Load frontend.ppc to $7000
		lea	$7000,a1
		bsr	_Loader
		rts

;======================================================================

_PatchFrontFrst	adda.w	#$61fa,a3

_PatchFrontend	
		movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_Frontend(pc),a0
		move.l	_GameAddress(pc),a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2
		rts

_PL_Frontend	PL_START
		PL_P	$8140,_SaveHighs	;End of this routine is $8332
		PL_PSS	$744e,_JoyDownPatch,2
		PL_PSS	$746e,_JoyDownPatch,2
		PL_PSS	$8588,_JoyUpPatch,2
		PL_PSS	$85ac,_JoySidePatch,2
		PL_P	$86ea,_install_int6
		PL_END

_install_int6:
	move.l	a1,-(a7)
	lea		orig_int6(pc),a1
	move.l	a0,(a1)
	lea		int6(pc),a0
	move.l	a0,$78.W
	move.l	(a7)+,a1
	rts

orig_int6:
	dc.l	0
;======================================================================

_IntroDelay	btst	#6,$bfe001		;Intro forces a 60 second
		beq	.Skip			;delay while music plays!
		btst	#7,$bfe001
		bne	.NormalDelay
.Skip		move.w	#60,(6,a5)		;Intro complete! :)
.NormalDelay	cmpi.w	#60,(6,a5)		;Stolen code
		rts

;======================================================================

_JoyUpPatch	btst	#7,$bfe001		;Start Easy mode (joystick
		bne	.NotJoystickUp		;up and fire)
		movem.l	d1-d2,-(sp)
		bsr	_ReadJoystick
		btst	#8,d1
		movem.l	(sp)+,d1-d2
		rts

.NotJoystickUp	movea.l	_GameAddress(pc),a0
		lea	($684c,a0),a0
		tst.b	($50,a0)
		rts

;======================================================================

_JoySidePatch	btst	#7,$bfe001		;Start Arcade mode (joystick
		bne	.NotJoystickSid		;left/right and fire)
		movem.l	d1-d2,-(sp)
		move.w	$dff00c,d1
		and.w	#$202,d1
		tst.w	d1
		movem.l	(sp)+,d1-d2
		rts

.NotJoystickSid	movea.l	_GameAddress(pc),a0
		lea	($684c,a0),a0
		tst.b	($52,a0)
		rts

;======================================================================

_JoyDownPatch	btst	#7,$bfe001		;Toggle speech on/off
		bne	.NotJoystickDwn		;(joystick down and fire)
		movem.l	d1-d2,-(sp)
		bsr	_ReadJoystick
		btst	#0,d1
		movem.l	(sp)+,d1-d2
		rts

.NotJoystickDwn	movea.l	_GameAddress(pc),a0
		lea	($684c,a0),a0
		tst.b	($54,a0)
		rts

;======================================================================

_ReadJoystick	move.w	$dff00c,d1
		move.w	d1,d2
		lsr.w	#1,d1
		eor.w	d2,d1
		rts

;======================================================================

_jmp_60000
		lea		_pl_walker_60000(pc),A0
		lea		$60000,a1
		move.l	_resload(pc),a2
		jsr		resload_Patch(a2)
		
		move.l	#$75ce90e2,d7		;Rob Northen copylock key
		;move.l	#$80000,$64fb2		;Jeff does this (but seems pointless)
		jmp	$60cf6

;======================================================================

_Loader		movem.l	a0-a2,-(sp)		;a0 = Filename, a1 = Address, a2 = Buffer
		move.l	_resload(pc),a2
		bsr	_SkipPath
		jsr	resload_LoadFile(a2)
		lea	_LastFileLen(pc),a0
		move.l	d0,(a0)
		move.l	d0,d1
		movem.l	(sp)+,a0-a2
		moveq	#0,d0
		rts

;======================================================================

_SkipPath	movem.l	d0/a1,-(sp)		;Skip past colon in filename a0
		move.l	a0,a1			;a1 = Working filename

.ReadNextChar	move.b	(a1)+,d0
		beq	.Done			;Found end of string

		cmp.b	#':',d0			;Check for colon
		beq	.SetNewFilename
		cmp.b	#'/',d0			;Check for directory
		bne	.ReadNextChar

.SetNewFilename	move.l	a1,a0			;Set new filename
		bra	.ReadNextChar

.Done		movem.l	(sp)+,d0/a1
		rts

;======================================================================

_Keybd		move.b	$bfec01,d0		;Stolen code

		movem.l	d0/a0,-(sp)
		ror.b	#1,d0
		not.b	d0
		cmp.b	_keyexit(pc),d0
		beq	_exit

		move.l	_GameAddress(pc),a0	;Check we are in the game. If
		add.l	#$9e46,a0		;not, do not patch these!
		cmp.l	#$41fa4eae,(a0)
		bne	_NoKey

_CheckF6	cmp.b	#$55,d0			;Gun is always cool: subq.w #4,($50,a5) -> bra $89e46 ($596d0050 -> $600a)
		bne	_CheckF7
		move.l	_GameAddress(pc),a0
		add.l	#$9e3a,a0
		eor.w	#$596d^$600a,(a0)
		bsr	_SetCheat

_CheckF7	cmp.b	#$56,d0			;Infinite energy: add.l d0,($58,a5) -> nop nop
		bne	_CheckF8
		move.l	_GameAddress(pc),a0
		add.l	#$b000,a0
		eor.l	#$d1ad0058^$4e714e71,$fce(a0)
		eor.l	#$d1ad0058^$4e714e71,$fea(a0)
		bsr	_SetCheat

_CheckF8	cmp.b	#$57,d0			;Shoot anywhere: move.w d4,($70,a5) -> nop nop ($3b440070 -> $4e714e71)
		bne	_CheckF9
		move.l	_GameAddress(pc),a0
		add.l	#$9000,a0
		eor.l	#$3b440070^$4e714e71,$bbe(a0)
		eor.l	#$3b440070^$4e714e71,$c7a(a0)
		bsr	_SetCheat

_CheckF9	cmp.b	#$58,d0			;Infinite lives: subq.w #1,(2,a0) -> nop nop ($53680002 -> $4e714e71)
		bne	_CheckDel
		move.l	_GameAddress(pc),a0
		eor.l	#$53680002^$4e714e71,$7538(a0)
		bsr	_SetCheat

_CheckDel	cmp.b	#$46,d0			;Skip level
		bne	_NoKey
		move.l	_GameAddress(pc),a0
		add.l	#$ed20,a0
		move.w	#$ffff,($66,a0)
		bsr	_SetCheat

_NoKey		movem.l	(sp)+,d0/a0
		rts

;======================================================================

_SetCheat	move.l	a0,-(sp)
		lea	_CheatFlag(pc),a0
		move.b	#-1,(a0)
		move.l	(sp)+,a0
		; flushes cache too (no rts)
;======================================================================

_FlushCache	move.l	a2,-(sp)		
		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)
		move.l	(sp)+,a2
		rts

;======================================================================

_SaveHighs	clr.b	(0,a3)			;Stolen code
		clr.b	(1,a3)
		clr.b	(2,a3)

		move.l	_GameAddress(pc),a5	;Run the original code to
		add.l	#$814c,a5		;enter the players name
		jsr	(a5)			;(a5 is destroyed anyway)

		bra	_SaveHighScores		;Save the scores

;======================================================================

_LoadHighScores	movem.l	d0-d1/a0-a3,-(sp)

		lea	_HighsAddress(pc),a1
		move.l	a5,d0
		add.l	#$31c,d0
		move.l	d0,(a1)			;Store high score address
		move.l	d0,a1
		move.l	a1,a3
		lea	_Highs(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		tst.l	d0
		beq	_NoHighsFound

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	a3,a1			;a1 = Address
		move.l	a1,-(sp)
		jsr	resload_LoadFile(a2)
		move.l	(sp)+,a1
		bsr	_Encrypt

_NoHighsFound	movem.l	(sp)+,d0-d1/a0-a3
		rts

;======================================================================

_SaveHighScores	movem.l	d0-d1/a0-a2,-(sp)

		move.b	_CheatFlag(pc),d0	;Check if user is a cheat
		bne	_DoNotSave

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	_HighsAddress(pc),a1	;a1 = Address
		move.l  _resload(pc),a2
		bsr	_Encrypt		;Encrypt scores
		move.l	a1,-(sp)
		jsr	resload_SaveFile(a2)	;Save scores
		move.l	(sp)+,a1
		bsr	_Encrypt		;Decrypt scores

_DoNotSave	movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Encrypt	move.l	#240,d0			;Set d0 = length
		move.l	d0,-(sp)
.enc		eor.b	d0,(a1)+
		subq.l	#1,d0
		bne.s	.enc
		move.l	(sp)+,d0
		sub.l	d0,a1
		rts

;======================================================================

_RNCDecruncher	movem.l	d0-d7/a0-a6,-(sp)
		lea	(-$180,sp),sp
		movea.l	sp,a2
		move.w	d0,d5
		bsr.w	.24
		moveq	#0,d1
		cmp.l	#$524E4301,d0
		bne.w	.15
		bsr.w	.24
		move.l	d0,($180,sp)
		lea	(10,a0),a3
		movea.l	a1,a5
		lea	(a5,d0.l),a6
		bsr.w	.24
		lea	(a3,d0.l),a4
		clr.w	-(sp)
		cmpa.l	a4,a5
		bcc.b	.6
		moveq	#0,d0
		move.b	(-2,a3),d0
		lea	(a6,d0.l),a0
		cmpa.l	a4,a0
		bls.b	.6
		addq.w	#2,sp
		move.l	a4,d0
		btst	#0,d0
		beq.b	.1
		addq.w	#1,a4
		addq.w	#1,a0
.1		move.l	a0,d0
		btst	#0,d0
		beq.b	.2
		addq.w	#1,a0
.2		moveq	#0,d0
.3		cmpa.l	a0,a6
		beq.b	.4
		move.b	-(a0),d1
		move.w	d1,-(sp)
		addq.b	#1,d0
		bra.b	.3

.4		move.w	d0,-(sp)
		adda.l	d0,a0
		move.w	d5,-(sp)
.5		lea	(-$20,a4),a4
		movem.l	(a4),d0-d7		;Buggy and causes access fault!
		movem.l	d0-d7,-(a0)
		cmpa.l	a3,a4
		bhi.b	.5
		suba.l	a4,a3
		adda.l	a0,a3
		move.w	(sp)+,d5
.6		moveq	#0,d7
		move.b	(1,a3),d6
		rol.w	#8,d6
		move.b	(a3),d6
		moveq	#2,d0
		moveq	#2,d1
		bsr.w	.21
.7		movea.l	a2,a0
		bsr.w	.26
		lea	($80,a2),a0
		bsr.w	.26
		lea	($100,a2),a0
		bsr.w	.26
		moveq	#-1,d0
		moveq	#$10,d1
		bsr.w	.21
		move.w	d0,d4
		subq.w	#1,d4
		bra.b	.10

.8		lea	($80,a2),a0
		moveq	#0,d0
		bsr.w	.17
		neg.l	d0
		lea	(-1,a5,d0.l),a1
		lea	($100,a2),a0
		bsr.w	.17
		move.b	(a1)+,(a5)+
.9		move.b	(a1)+,(a5)+
		dbra	d0,.9
.10		movea.l	a2,a0
		bsr.w	.17
		subq.w	#1,d0
		bmi.b	.12
.11		move.b	(a3)+,(a5)+
		eor.b	d5,(-1,a5)
		dbra	d0,.11
		ror.w	#1,d5
		move.b	(1,a3),d0
		rol.w	#8,d0
		move.b	(a3),d0
		lsl.l	d7,d0
		moveq	#1,d1
		lsl.w	d7,d1
		subq.w	#1,d1
		and.l	d1,d6
		or.l	d0,d6
.12		dbra	d4,.8
		cmpa.l	a6,a5
		bcs.b	.7
		move.w	(sp)+,d0
		beq.b	.14
.13		move.w	(sp)+,d1
		move.b	d1,(a5)+
		subq.b	#1,d0
		bne.b	.13
.14		bra.b	.16

.15		;move.l	d1,($180,sp)		;Original code
		move.l	_LastFileLen(pc),($180,sp)
.16		bsr	_FlushCache
		lea	($180,sp),sp
		movem.l	(sp)+,d0-d7/a0-a6
		rts

.17		move.w	(a0)+,d0
		and.w	d6,d0
		sub.w	(a0)+,d0
		bne.b	.17
		move.b	($3C,a0),d1
		sub.b	d1,d7
		bge.b	.18
		bsr.b	.23
.18		lsr.l	d1,d6
		move.b	($3D,a0),d0
		cmp.b	#2,d0
		blt.b	.20
		subq.b	#1,d0
		move.b	d0,d1
		move.b	d0,d2
		move.w	($3E,a0),d0
		and.w	d6,d0
		sub.b	d1,d7
		bge.b	.19
		bsr.b	.23
.19		lsr.l	d1,d6
		bset	d2,d0
.20		rts

.21		and.w	d6,d0
		sub.b	d1,d7
		bge.b	.22
		bsr.b	.23
.22		lsr.l	d1,d6
		rts

.23		add.b	d1,d7
		lsr.l	d7,d6
		swap	d6
		addq.w	#4,a3
		move.b	-(a3),d6
		rol.w	#8,d6
		move.b	-(a3),d6
		swap	d6
		sub.b	d7,d1
		moveq	#$10,d7
		sub.b	d1,d7
		rts

.24		moveq	#3,d1
.25		lsl.l	#8,d0
		move.b	(a0)+,d0
		dbra	d1,.25
		rts

.26		moveq	#$1F,d0
		moveq	#5,d1
		bsr.b	.21
		subq.w	#1,d0
		bmi.b	.33
		move.w	d0,d2
		move.w	d0,d3
		lea	(-$10,sp),sp
		movea.l	sp,a1
.27		moveq	#15,d0
		moveq	#4,d1
		bsr.b	.21
		move.b	d0,(a1)+
		dbra	d2,.27
		moveq	#1,d0
		ror.l	#1,d0
		moveq	#1,d1
		moveq	#0,d2
		movem.l	d5-d7,-(sp)
.28		move.w	d3,d4
		lea	(12,sp),a1
.29		cmp.b	(a1)+,d1
		bne.b	.31
		moveq	#1,d5
		lsl.w	d1,d5
		subq.w	#1,d5
		move.w	d5,(a0)+
		move.l	d2,d5
		swap	d5
		move.w	d1,d7
		subq.w	#1,d7
.30		roxl.w	#1,d5
		roxr.w	#1,d6
		dbra	d7,.30
		moveq	#$10,d5
		sub.b	d1,d5
		lsr.w	d5,d6
		move.w	d6,(a0)+
		move.b	d1,($3C,a0)
		move.b	d3,d5
		sub.b	d4,d5
		move.b	d5,($3D,a0)
		moveq	#1,d6
		subq.b	#1,d5
		lsl.w	d5,d6
		subq.w	#1,d6
		move.w	d6,($3E,a0)
		add.l	d0,d2
.31		dbra	d4,.29
		lsr.l	#1,d0
		addq.b	#1,d1
		cmp.b	#$11,d1
		bne.b	.28
		movem.l	(sp)+,d5-d7
		lea	($10,sp),sp
.33		rts

;======================================================================
_resload	dc.l	0			;Resident loader
_StackAddress	dc.l	$80f00
_GameAddress	dc.l	$81000
_HighsAddress	dc.l	0
_LastFileLen	dc.l	0
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	_resload(pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
