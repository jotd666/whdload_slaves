;*---------------------------------------------------------------------------
; Program:	BuggyBoy.s
; Contents:	Slave for "Buggy Boy" (c) 1988 Elite
; Author:	Codetapper of Action
; History:	??.??.?? - v1.0
;		         - Full load from HD
;		         - Copy protection removed
;		         - Loads and saves high scores
;		         - All files can be compressed to save space (FImp, Propack etc)
;		         - All operating system calls emulated (a mini OSEmu you might say!)
;		         - Atari ST palette access fault removed (lea $ffff824c,a2)
;		         - Keyboard handler added
;		         - Instructions included
;		         - Buttonwait tooltype added for title picture
;		         - RomIcon, NewIcon and GlowIcon (all created by Frank!)
;		         - Quit option (default key is 'F10')
;		??.??.?? - v1.1
;		         - Colour bit fix in bplcon0 (x2)
;		23.11.01 - v1.2
;		         - Also supports the Tenstar pack version
;		         - Added 2 Exotic icons (taken from http://exotica.fix.no)
;		05.11.11 - v1.3         
;		         - Supports another Tenstar pack version (thanks to Paul Vernon)
; Requires:	WHDLoad 17+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"BuggyBoy.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

DOSGAMEADDRESS	equ	$400			;Locate DOS version at $400
BASEMEM		equ	$80000

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_Data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
                dc.w	0			;ws_kickname
                dc.l	0			;ws_kicksize
                dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

;============================================================================

	IFD BARFLY
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.3"
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
	

_name		dc.b	"Buggy Boy",0
_copy		dc.b	"1988 Elite",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1,"Thanks to Wolfgang Unger, Adrian Simpson, Carlo Pirri"
		dc.b	10,"and Paul Vernon for the originals and Frank for the icons!",0
_config		dc.b	"C1:B:Infinite Time;"
		dc.b	"C2:L:Max Frame Rate:Default speed,25fps,17fps,13fps,10fps,8fps,7fps,6fps;"
		dc.b	"C3:B:Enable CD32 joypad controller;"
		dc.b	"BW"
		dc.b	0
_Data		dc.b	"data",0
_BugPFile	dc.b	"bug.p",0
_BugOFile	dc.b	"bug.o",0
_Highs		dc.b	"BuggyBoy.highs",0
_CheatFlag	dc.b	0
		EVEN

;======================================================================
_Start						;a0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	
		bsr		_detect_controller_types
	
		lea	_Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		lea	_BugPFile(pc),a0	;Check for protected version
		bsr	_GetFileSize
		bne	_DOSVersion

		lea	_BugOFile(pc),a0	;Check for unprotected version
		bsr	_GetFileSize
		beq	_DiskVersions

_DOSVersion	lea	DOSGAMEADDRESS-$20,a1	;a1 = Destination (hunk header at $3e0, real code at $400)
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)

		move.l	a5,a0			;Check for original or nicely
		move.l	#46328,d0		;cracked game :)
		jsr	resload_CRC16(a2)

		lea	$20(a5),a5		;a5 = Real start address

		cmp.w	#$1084,d0		;$1084 = Les Fous version
		beq	.Deprotected		;(Bug.o) which is unprotected

		cmp.w	#$134f,d0		;$134f = Retail version
		bne	_wrongver		;(Bug.p) encrypted

		bsr	_DecryptA5		;Decrypt bug.p file

.Deprotected	bsr	_RelocA5		;Relocate game

		lea	_HighScorePos(pc),a0	;Set high score position
		move.l	a5,d0
		add.l	#$8ea4,d0
		move.l	d0,(a0)

		lea	_JoypadPos(pc),a0	;Set joypad position
		move.l	a5,d0
		add.l	#$2538,d0		;move.w d0,(a0) and move.w (sp)+,d1 and move.w (sp)+,d0
		move.l	d0,(a0)

		lea	_PL_BugOP(pc),a0	;Patch decrypted and relocated 
		move.l	a5,a1			;bug.p file or unencrypted
		move.l	_resload(pc),a2		;bug.o file
		jsr	resload_Patch(a2)

		move.l	_Custom3(pc),d0		;CD32 joypad support
		beq	.NoCD32
		lea	_PL_BugOP_CD32(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

.NoCD32		pea	_SaveHighScores(pc)	;Setup save routine to run
		move.l	(sp)+,$bc		;when trap #15 encountered

		bsr	_SetupKeyboard

		move.l	#$fffffffe,$3cc		;Setup hardware
		move.l	#$3cc,$dff080
		move.l	#0,$dff180

		move.w	#$83d0,$dff096		;Enable DMA
		jsr	(a5)
		bra	_exit

_PL_BugOP	PL_START
		PL_PSS	$8,_AllocMem,4		;Allocate 67102 bytes
		PL_PSS	$24,_AllocMem,4		;Allocate 240000 bytes
		PL_PSS	$40,_AllocMem,4		;Allocate 63702 bytes
		PL_PSS	$5c,_AllocMem,4		;Allocate 57088 bytes
		PL_P	$d4,_LoadHighs		;Load highest scores
		PL_L	$5e0,'IAN'<<8		;Fill high scores with IAN
		PL_L	$1c86,$dff18c		;Atari ST $ffff824c
		PL_L	$1c8a,$4e714e71
		PL_L	$2572,$4e714e71		;Open dos.library
		PL_L	$257c,$4e714e71		;Check dos opened OK
		PL_L	$259e,$4e714e71		;jsr    _LVODelay(a6)
		PL_L	$25a8,$4e714e71		;jsr    _LVODisable(a6)
		PL_PS	$260a,_Delay		;move.l #200,d1
		PL_L	$2610,$4e714e71		;jsr    _LVODelay(a6)
		PL_L	$261c,$4e714e71		;jsr    _LVOCloseLibrary(a6)
		PL_P	$2622,_debug		;No mem, file problem etc
		PL_P	$262e,_LoadFile		;Patch loader
		PL_PSS	$2682,_LockFrameRate,2	;move.l (a1,d0.w),($dff080).l
		PL_W	$29c2,$4e4f		;Trap #15 after player has entered name
		PL_W	$4b9a,$c008		;Enable keyboard (was $4000)
		PL_W	$4baa,$4200		;Fix colour bit bug (was $4000)
		PL_W	$4c72,$4200		;Fix colour bit bug (was $4000)
		PL_W	$4da6,$c028		;Enable keyboard (was $c020)
		PL_PS	$4db0,_CountFrames	;lea $dff000,a0
		PL_PSS	$6650,_SoundFixOrig,4	;Fix lockup when hitting rocks: move.w $1e(a0),d0 then and.w d4,d0
		PL_PSS	$6674,_SoundFixOrig,4	;move.w $1e(a0),d0 then and.w d4,d0
		PL_W	$6696,$c008		;Enable keyboard (was $c000)
		PL_END

_PL_BugOP_Tr	PL_START
		PL_W	$64e,0			;Initial time: move.w #70,$9d22 -> 0
		PL_W	$1626,$6010		;Don't decrement time: subq.w #1,-(a0) etc
		PL_W	$1e4e,$4e71		;No lap complete bonus: add.b d0,(a2)
		PL_END

_PL_BugOP_CD32	PL_START
		PL_P	$2538,_CD32_Read	;move.w d0,(a0) and move.w (sp)+,d1 and move.w (sp)+,d0
		PL_END

;======================================================================

_DiskVersions	move.l	#$4a,d0			;2 Tenstar versions and the Story So Far compilation
		move.l	#$400-$4a,d1
		moveq	#1,d2
		lea	$80,a0
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		lea	_SetupTenstar(pc),a0
		cmp.l	#$14bc00ff,$80+$156-$4a
		beq	.PatchDIBoot

		lea	_SetupTenV2(pc),a0
		cmp.l	#$14bc00ff,$80+$166-$4a
		beq	.PatchDIBoot

		lea	_SetupStory(pc),a0
		cmp.l	#$8280002,$80+$102-$4a
		bne	_wrongver

.PatchDIBoot	jsr	(a0)			;Setup to save variables

		move.l	_BootPatchList(pc),a0
		lea	$80-$4a,a1
		bsr	_Patch

		lea	$dff000,a0
		jmp	$80

_SetupTenstar	lea	_Variables(pc),a0
		pea	_PL_TenstarBoot(pc)	;Boot patch list
		move.l	(sp)+,(a0)+
		pea	_PL_TenstarGame(pc)	;Game patch list
		move.l	(sp)+,(a0)+
		pea	_PL_TenstarTr(pc)	;Trainer patch list
		move.l	(sp)+,(a0)+
		move.l	#$7247e,(a0)+		;Joypad reading position
		move.l	#$7923c,(a0)+		;Set high score position
		rts

_SetupTenV2	lea	_Variables(pc),a0
		pea	_PL_TenV2Boot(pc)	;Boot patch list
		move.l	(sp)+,(a0)+
		pea	_PL_TenV2Game(pc)	;Game patch list
		move.l	(sp)+,(a0)+
		pea	_PL_TenV2Tr(pc)		;Trainer patch list
		move.l	(sp)+,(a0)+
		move.l	#$7247e33,(a0)+		;Joypad reading position
		move.l	#$78d7e,(a0)+		;Set high score position
		rts

_SetupStory	lea	_Variables(pc),a0
		pea	_PL_StoryBoot(pc)	;Boot patch list
		move.l	(sp)+,(a0)+
		pea	_PL_StoryGame(pc)	;Game patch list
		move.l	(sp)+,(a0)+
		pea	_PL_StoryTr(pc)		;Trainer patch list
		move.l	(sp)+,(a0)+
		move.l	#$7247e33,(a0)+		;Joypad reading position
		move.l	#$78dd6,(a0)+		;Set high score position
		rts

;======================================================================

_DiskImageGame	movem.l	d0-d1/a0-a2,-(sp)

		pea	_SaveHighScores(pc)	;Setup save routine to run
		move.l	(sp)+,$bc		;when trap #15 encountered

		bsr	_SetupKeyboard
		bsr	_Patch_Joypad

		move.l	_GamePatchList(pc),a0	;Patch the game
		sub.l	a1,a1
		bsr	_Patch

		move.l	_TrPatchList(pc),a0	;Train the game
		sub.l	a1,a1
		bsr	_Patch

		bsr	_Delay			;Delay the picture for a bit

		movem.l	(sp)+,d0-d1/a0-a2
		jmp	$70020

;======================================================================

_PL_TenstarBoot	PL_START
		PL_S	$74,$9c-$74		;Disk access
		PL_P	$156,_DiskImageGame
		PL_P	$176,_DiskLoaderA5	;Loader
		PL_END

_PL_TenstarGame	PL_START
		PL_P	$7006c,_LoadHighsTens	;Load highest scores
		PL_L	$70544,'IAN'<<8		;Fill high scores with IAN
		PL_L	$71bc4,$dff18c		;Atari ST $ffff824c
		PL_P	$724ec,_DiskLoaderA6	;Loader
		PL_PSS	$72894,_LockFrameRate,2	;move.l (a1,d0.w),($dff080).l
		PL_W	$72bb4,$4e4f		;Trap #15 after player has entered name
		PL_W	$74e54,$c028		;Enable keyboard (was $c020)
		PL_PS	$74e5e,_CountFrames	;lea $dff000,a0
		PL_W	$769b4,$c008		;Enable keyboard (was $4000)
		PL_W	$76a28,$c008		;Enable keyboard (was $c000)
		PL_END

_PL_TenstarTr	PL_START
		PL_W	$705b2,0		;Initial time: move.w #70,$79c48 -> 0
		PL_W	$71574,$6010		;Don't decrement time: subq.w #1,-(a0) etc
		PL_W	$71d84,$4e71		;No lap complete bonus: add.b d0,(a2)
		PL_W	$71d94,$4e71		;No lap complete bonus gates: add.b d0,(a2)
		PL_END

;======================================================================

_PL_TenV2Boot	PL_START
		PL_S	$74,$9c-$74		;Disk access
		PL_P	$166,_DiskImageGame
		PL_P	$198,_DiskLoaderA5	;Loader
		PL_END

_PL_TenV2Game	PL_START
		PL_P	$70054,_LoadHighsTenV2	;Load highest scores
		PL_L	$70530,'IAN'<<8		;Fill high scores with IAN
		PL_L	$71bac,$dff18c		;Atari ST $ffff824c
		PL_P	$724c0,_DiskLoaderTenV2	;Loader
		PL_W	$72a1e,$4e4f		;Trap #15 after player has entered name
		PL_W	$74c88,$c028		;Enable keyboard (was $c020)
		PL_W	$764fe,$c008		;Enable keyboard (was $4000)
		PL_W	$76560,$c008		;Enable keyboard (was $c000)
		PL_END

_PL_TenV2Tr	PL_START
		;PL_W	$705b2,0		;Initial time: move.w #70,$79c48 -> 0
		;PL_W	$71574,$6010		;Don't decrement time: subq.w #1,-(a0) etc
		;PL_W	$71d84,$4e71		;No lap complete bonus: add.b d0,(a2)
		;PL_W	$71d94,$4e71		;No lap complete bonus gates: add.b d0,(a2)
		PL_END

;======================================================================

_PL_StoryBoot	PL_START
		PL_S	$56,$64-$56		;Disk access
		PL_S	$82,$114-$82		;Skip game select screen
		PL_P	$1b2,_DiskImageGame
		PL_P	$272,_DiskLoaderStory	;Loader
		PL_END

_PL_StoryGame	PL_START
		PL_P	$70054,_LoadHighsTenV2	;Load highest scores (same as Tenstar V2)
		PL_L	$70530,'IAN'<<8		;Fill high scores with IAN
		PL_L	$71bb0,$dff18c		;Atari ST $ffff824c
		PL_P	$724d4,_DiskLoaderTenV2	;Loader
		PL_PSS	$72716,_LockFrameRate,2	;move.l (a1,d0.w),($dff080).l
		PL_W	$72a36,$4e4f		;Trap #15 after player has entered name clr.b (a0)
		PL_W	$74cd6,$c028		;Enable keyboard (was $c020)
		PL_PS	$74ce0,_CountFrames	;lea $dff000,a0
		PL_W	$7654c,$c008		;Enable keyboard (was $4000)
		PL_W	$765bc,$c008		;Enable keyboard (was $c000)
		PL_END

_PL_StoryTr	PL_START
		PL_W	$7059e,0		;Initial time: move.w #70,$797e2 -> 0
		PL_W	$71560,$6010		;Don't decrement time: subq.w #1,-(a0) etc
		PL_W	$71d70,$4e71		;No lap complete bonus time: add.b d0,(a2)
		PL_W	$71d80,$4e71		;No lap complete bonus gates: add.b d0,(a2)
		PL_END

;======================================================================

_FrameCounter	dc.w	9999			;Counts VBLs

_CountFrames	lea	_FrameCounter(pc),a0
		add.w	#1,(a0)
		lea	$dff000,a0		;Stolen code
		rts

_LockFrameRate	movem.l	d0-d1/a0,-(sp)
		move.l	_Custom2(pc),d1
		beq	.DefaultRate
		cmp.w	#7,d1
		ble	.FrameRateOK
.DefaultRate	move.w	#4,d1			;50 / (4 + 1) = 10fps

.FrameRateOK	lea	_FrameCounter(pc),a0
.DelayLoop	move.w	(a0),d0			;Check we've reached the
		cmp.w	d1,d0			;correct frame number
		blt	.DelayLoop
		move.w	#0,(a0)			;Reset counter back to 0
		movem.l	(sp)+,d0-d1/a0
		move.l	(a1,d0.w),$dff080
		rts

;======================================================================

_SoundFixOrig	move.l	d1,-(sp)
		move.w	#8-1,d1			;Wait max 8 lines

.WaitOneLine	move.b	vhposr(a0),d0
.WaitLoop	cmp.b	vhposr(a0),d0		;One line is 63.5 탎
		beq	.WaitLoop

		move.w	$1e(a0),d0		;Stolen code to check
		and.w	d4,d0			;for interrupt
		bne	.SoundOK
		dbf	d1,.WaitOneLine

.SoundOK	move.l	(sp)+,d1
		rts

;======================================================================

_DiskLoaderStory
		movem.l	d0-d2/a0-a2,-(sp)
		move.l	a5,a0
		moveq	#0,d0
		move.w	$28,d0
		mulu	#$18a8,d0
		move.l	d7,d1
		addq	#1,d1
		mulu	#$18a8,d1
		moveq	#1,d2
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(sp)+,d0-d2/a0-a2
		rts

_DiskLoaderTenV2
		movem.l	d0-d2/a0-a2,-(sp)	;a5 = Destination, d5 = Length, d4 = Offset
		move.l	a5,a0
		moveq	#0,d0
		move.w	d4,d0
		bra	_DiskLoaderComb

_DiskLoaderA5	movem.l	d0-d2/a0-a2,-(sp)	;a5 = Destination, d5 = Length, $28 = Offset
		move.l	a5,a0
		bra	_DiskLoader

_DiskLoaderA6	movem.l	d0-d2/a0-a2,-(sp)	;a6 = Destination, d5 = Length, $28 = Offset
		move.l	a6,a0

_DiskLoader	moveq	#0,d0
		move.w	$28,d0
_DiskLoaderComb	mulu	#$18a8,d0
		move.l	d5,d1
		moveq	#1,d2
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		move.l	d5,d0
		divu.w	#$18a8,d0
		addq	#1,d0
		add.w	d0,$28
		movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_LoadFile	movem.l	d0-d1/a0-a2,-(sp)	;d1 = Filename, d4 = Destination, d3 = Length

		move.l	d1,a0			;a0 = Filename
		move.l	d4,a1			;a1 = Destination
		move.l	_resload(pc),a2
		bsr	_SkipColon
		jsr	resload_LoadFileDecrunch(a2)

		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_SkipColon	movem.l	d0/a1,-(sp)		;Skip past colon in filename a0
		move.l	a0,a1			;Store original filename

_FindColon	move.b	(a0)+,d0
		cmp.b	#0,d0			;Possibly hacked, exit
		beq	_NoColon

		cmp.b	#':',d0			;Find : to remove path
		bne	_FindColon

_ColonDone	movem.l	(sp)+,d0/a1
		rts

_NoColon	move.l	a1,a0			;Couldn't find colon, so
		bra	_ColonDone		;restore original name

;======================================================================

_DecryptA5	movem.l	d0-d4/a0,-(sp)		;Decrypt game loaded at a5
		move.l	a5,a0			;a0 = Start of data
		move.l	#$2a6b,d0		;d0 = Number of longs - 1 to decrypt
		move.l	#$49946cfd,d1		;d1 = Decryption key
		moveq	#0,d4

_DecryptNext	move.l	(a0)+,d2
		beq.w	_DecryptSkip
		add.l	d1,d2
		moveq	#$1F,d3
_DecryptLoop	roxl.l	#1,d2
		roxr.l	#1,d4
		dbra	d3,_DecryptLoop
		sub.l	d1,d4
		move.l	d4,(-4,a0)
_DecryptSkip	dbra	d0,_DecryptNext
		movem.l	(sp)+,d0-d4/a0
		rts

;======================================================================

_RelocA5	movem.l	d0/d4/d5/a0/a4-a5,-(sp)	;Relocate game loaded at a5
		move.l	a5,a0
		move.l	a5,a4
		move.l	a5,d5
		add.l	#$a9bc,a0		;a0 = Start of reloc table

_RelocNext	move.l	(a0)+,d0
		tst.l	d0
		beq	_RelocDone
		add.l	d5,(a4,d0.l)
		bra	_RelocNext

_RelocDone	movem.l	(sp)+,d0/d4/d5/a0/a4-a5
		rts

;======================================================================

_SetCheat	lea	_CheatFlag(pc),a0
		move.b	#-1,(a0)
		rts

;======================================================================

_LoadHighs	jsr	$5d4+DOSGAMEADDRESS	;Clear out highest scores
		bsr	_LoadHighScores
		jmp	$106+DOSGAMEADDRESS	;Stolen code

_LoadHighsTens	jsr	$70538			;Clear out highest scores
		bsr	_LoadHighScores		;Tenstar version
		jmp	$7009a			;Stolen code

_LoadHighsTenV2	jsr	$70524			;Clear out highest scores
		bsr	_LoadHighScores		;Tenstar version 2
		jmp	$70082			;Stolen code

_LoadHighScores	movem.l	d0-d1/a0-a3,-(sp)
		move.l	_HighScorePos(pc),a1	;a1 = Address
		lea	_Highs(pc),a0
		bsr	_GetFileSize
		beq	.NoHighsFound

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	a1,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		move.l	(sp)+,a1
		bsr	_Encrypt

.NoHighsFound	movem.l	(sp)+,d0-d1/a0-a3
		rts

;======================================================================

_SaveHighScores	clr.b	(a0)			;Stolen code

		movem.l	d0-d1/a0-a2,-(sp)

		move.b	_CheatFlag(pc),d0
		bne	.DoNotSave

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	_HighScorePos(pc),a1	;a1 = Address
		move.l  _resload(pc),a2
		bsr	_Encrypt		;Encrypt scores
		move.l	a1,-(sp)
		jsr	resload_SaveFile(a2)	;Save scores
		move.l	(sp)+,a1
		bsr	_Encrypt		;Decrypt scores

.DoNotSave	movem.l	(sp)+,d0-d1/a0-a2
		rte

;======================================================================

_Encrypt	move.l	#640,d0			;Set d0 = length
		move.l	d0,-(sp)
.enc		eor.b	d0,(a1)+
		subq.l	#1,d0
		bne.s	.enc
		move.l	(sp)+,d0
		sub.l	d0,a1
		rts

;======================================================================

_EmptyDBF	movem.l	d0-d1,-(sp)
		moveq	#3-1,d1			;wait because handshake min 75 탎
.int2w1		move.b	(_custom+vhposr),d0
.int2w2		cmp.b	(_custom+vhposr),d0	;one line is 63.5 탎
		beq	.int2w2
		dbf	d1,.int2w1		;(min=127탎 max=190.5탎)
		movem.l	(sp)+,d0-d1
		rts

;======================================================================

_AllocMem	movem.l	d1-d2/a1,-(sp)
		lea	_FreeMem(pc),a1		;Current free memory
		move.l	(a1),d1
		move.l	d1,d2			;Give this to the program
		add.l	#$10,d0			;Safety
		and.l	#$fffffff0,d0
		add.l	d0,d1
		move.l	d1,(a1)			;Store new free memory

		cmp.l	#BASEMEM,d1
		bhi	_NoMem

		asr.l	#4,d0
		move.l	d2,a0
.clear		clr.l	(a0)+			;Clear the memory
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		dbf	d0,.clear
		move.l	d2,a0
		move.l	d2,d0
		movem.l	(sp)+,d1-d2/a1
		rts

_NoMem		move.l	#'MEM ',$0
		move.l	#'ERR ',$4
		bra	_exit

;======================================================================

_Delay		movem.l	d0-d1/a0-a2,-(sp)

		move.l	_ButtonWait(pc),d0
		bne	.WaitForButton

		moveq	#10,d0			;Wait 1 second
		move.l	_resload(pc),a2
		jsr	resload_Delay(a2)
		bra	.PicDelayDone

.WaitForButton	waitbutton

.PicDelayDone	movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Patch		movem.l	d1/a0-a2,-(sp)

		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d1/a0-a2
		rts

_GetFileSize	movem.l	d1/a0-a2,-(sp)

		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)

		movem.l	(sp)+,d1/a0-a2
		tst.l	d0
		rts

;======================================================================
; CD32 Support
;======================================================================

		include ReadJoypad.s

_Patch_Joypad	movem.l	d0/a0,-(sp)

		move.l	_Custom3(pc),d0		;CD32 joypad support
		beq	.NoCD32

		move.l	_JoypadPos(pc),d0
		beq	.NoCD32
		move.l	d0,a0
		move.w	#$4ef9,(a0)+
		pea	_CD32_Read(pc)
		move.l	(sp)+,(a0)+

.NoCD32		movem.l	(sp)+,d0/a0
		rts

_CD32_Read	movem.l	d0-d2,-(sp)
		bsr	_joystick
		move.l	(sp),d0			;Get old joystick value
		move.l	joy1(pc),d1
		bsr	_CD32_Quit
		bsr	_CD32_Fire
		bsr	_CD32_Controls
		move.w	d0,(a0)			;Stolen code to store joystick value
		movem.l	(sp)+,d0-d2		;Restore stack
		move.w	(sp)+,d1		;Stolen code
		move.w	(sp)+,d0		;Stolen code
		rts

_CD32_Quit	btst	#JPB_BTN_REVERSE,d1
		beq	.notquit
		btst	#JPB_BTN_FORWARD,d1
		beq	.notquit
		btst	#JPB_BTN_PLAY,d1
		bne	_exit
.notquit	rts

_CD32_Fire	btst	#JPB_BTN_RED,d1
		beq	.notfire
		bset	#7,d0			;Fake pressing fire
.notfire	rts

_CD32_Controls	move.l	#JPB_BTN_FORWARD,d2
		btst.l	d2,d1
		beq	.notforward
		bset	#2,d0			;Fake pressing up
.notforward	move.l	#JPB_BTN_REVERSE,d2
		btst.l	d2,d1
		beq	.notreverse
		bset	#0,d0			;Fake pressing down
.notreverse	rts

;======================================================================

		INCLUDE	"whdload/keyboard.s"

;======================================================================
_resload	dc.l	0			;Resident loader
_FreeMem	dc.l	$10000

_Variables					;Do not change the order
_BootPatchList	dc.l	'CODE'			;of these 5 addresses!
_GamePatchList	dc.l	'TAPP'
_TrPatchList	dc.l	'ER!!'
_JoypadPos	dc.l	0
_HighScorePos	dc.l	0

_Tags		dc.l	WHDLTAG_CUSTOM1_GET
_Custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_Custom2	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET	;Custom3=1 if CD32 controller
_Custom3	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l	0
		dc.l	TAG_DONE
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
