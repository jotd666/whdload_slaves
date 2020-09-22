;*---------------------------------------------------------------------------
; Program:	AllTerrainRacing.s
; Contents:	Slave for "All Terrain Racing" (c) 1995 Team 17
; Author:	Codetapper of Action
; History:	02.12.00 - v1.0
;		         - Full load from HD
;		         - Loads and saves high scores and league races (unless you cheat)
;		         - Fastest times for each of the courses set to 99.99 seconds so that you
;		           can have a realistic chance of beating the built in times
;		         - RomIcon, NewIcon and OS3.5 Colour Icon (created by me!)
;		         - Trainer (press Del for loads of cash and Help to win a one player race).
;		           If you cheat, nothing will be saved until you reload the game.
;		         - Quit option (default key is F10)
;		17.12.00 - v1.1
;		         - First disk image is now less than half the size, so to preload requires
;		           500k less memory :)
;		         - Color bit fix for scandoubler (requested by Pavel Narozny)
;		14.11.13 - v1.2
;		         - Fixed uninitialised copperlist which caused weird faults on WinUAE due to
;		           FMODE being set to -1
;		         - Source code included
; Requires:	WHDLoad 10+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"AllTerrainRacing.slave"
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
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$80000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

_name		dc.b	"All Terrain Racing",0
_copy		dc.b	"1995 Team 17",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version 1.2 "
		IFND	.passchk
		DOSCMD	"WDate >T:date"
.passchk
		ENDC
		INCBIN	"T:date"
		dc.b	-1,"Press Del for loads of money and Help to",10
		dc.b	"win the current race. You will not be able to",10
		dc.b	"save anything if you cheat."
		dc.b	-1,"Thanks to Denis Lechevalier for sending the original!"
		dc.b	0
_DiskNumber	dc.b	1
_SaveName	dc.b	"AllTerrainRacing.save",0
_CheatFlag	dc.b	0
		EVEN

;======================================================================
_Start						;A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	move.l	#$400,d0		;offset
		move.l	#$2800,d1		;size
		moveq	#1,d2			;diskno
		lea	$78000,a0		;destination address
		move.l	a0,a5
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		lea	_PL_Boot(pc),a0		;Patch boot
		sub.l	a1,a1			;a1 = Destination
		jsr	resload_Patch(a2)

		bsr	_CheckSaveGame

		move.l	#$100,$dff080		;Install default copperlist
		move.l	#$100,$dff084

		move.l	_expmem(pc),d0
		jmp	$30(a5)			;Start game

_PL_Boot	PL_START
		PL_L	$100,-2			;Copperlist
		PL_P	$78096,_Game		;Patch game
		PL_P	$787a2,_Loader		;Patch Rob Northen loader
		PL_END

;======================================================================

_Game		movem.l	d0-d1/a0-a2,-(sp)

		bsr	_FixBlitter		;Fix buggy blitter waits

		lea	_PL_Game(pc),a0		;Patch second part
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.w	#9999,$93dc		;Insert times
		move.l	#'IAN ',$93e0
		move.w	#9999,$93e8		;Insert times
		move.l	#'IAN ',$93ec
		move.w	#9999,$93f4		;Insert times
		move.l	#'IAN ',$93f8

		or.w	#$0200,$62c2		;Set colour bit in bplcon0
						;To fix disk image: At $4de0
						;change $5000 to $5200

		movem.l	(sp)+,d0-d1/a0-a2
		jmp	$1000

_PL_Game	PL_START
		PL_P	$104,_Blt_d7_58_a6	;Blitter patch
		PL_PS	$17f0,_Keybd		;Quit key
		PL_L	$1f46,$4eb80104		;move.w d7,$58(a6)
		PL_L	$1f62,$4eb80104		;move.w d7,$58(a6)
		PL_L	$3af6,$4eb80104		;move.w d7,$58(a6)
		PL_L	$3b12,$4eb80104		;move.w d7,$58(a6)
		PL_P	$58f0,_Loader		;Patch Rob Northen loader
		PL_L	$64fa,-2		;Uninitialised copperlist
		PL_P	$8d96,_Crack		;Remove protection
		PL_PS	$11a2a,_SetDisk2	;Set disk 2
		PL_END

;======================================================================

_Crack		move.l	#'jami',$6bc00
		move.l	#'e123',$6bc04
		jmp	$8dba

;======================================================================

_SetDisk2	lea	_DiskNumber(pc),a1
		move.b	#2,(a1)
		lea	$400f0,a1
		rts

;======================================================================

_Blt_d7_58_a6	move.w	d7,$58(a6)		;Stolen code
		BLITWAIT			;Wait for blitter to finish
		rts

;======================================================================

_FixBlitter	movem.l	a0-a1,-(sp)

		lea	$6a00,a0
		lea	$11500,a1

.check		cmp.l	#$8390006,-8(a0)
		bne	.no
		cmp.l	#$dff002,-4(a0)
		bne	.no
		cmp.w	#$66f8,(a0)
		bne	.no
		move.w	#$66f6,(a0)
.no		add.l	#2,a0
		cmp.l	a0,a1
		bne	.check

		movem.l	(sp)+,a0-a1
		rts

;======================================================================

_Loader		movem.l	d1-d7/a0-a6,-(sp)
		move.l  _resload(pc),a2		;a0 = dest address
		mulu	#$200,d1		;offset (sectors)
		mulu	#$200,d2		;length (sectors)
		cmp.l	#0,d2			;Game loads a blank file at
		beq	_LoadDone		;one point

		move.b	_DiskNumber(pc),d7	;d7 = disk
		cmp.b	#2,d7
		bne	_OnDisk1

		cmp.l	#$d3e00,d1
		bge	_SaveDiskOp

_OnDisk1	cmp.b	#1,d3
		beq	_debug
		cmp.b	#2,d3
		beq	_debug

		exg.l	d1,d0			;d0 = offset (bytes)
		exg.l	d2,d1			;d1 = length (bytes)

		moveq	#0,d2
		move.b	_DiskNumber(pc),d2	;d2 = disk

		cmp.l	#$dbc00,d0
		bne	_DoLoad
		cmp.b	#1,d2
		beq	_LoadLast2Secs

_DoLoad		jsr	resload_DiskLoad(a2)	;a0 = destination
_LoadDone	movem.l	(sp)+,d1-d7/a0-a6
		moveq	#0,d0
		rts

_SaveDiskOp	sub.l	#$d3e00,d1
		move.l	a0,a1			;a1 = address
		exg.l	d2,d0			;d0 = size, d1 = offset
		lea	_SaveName(pc),a0	;a0 = name
		cmp.b	#1,d3
		beq	_SaveToSaveFile
		
		jsr	resload_LoadFileOffset(a2)
		bra	_LoadDone

_SaveToSaveFile	move.b	_CheatFlag(pc),d5
		tst.b	d5
		bne	_LoadDone

		jsr	resload_SaveFileOffset(a2)
		bra	_LoadDone

_LoadLast2Secs	moveq	#0,d0
		move.l	a0,a2
		subq	#1,d1
_ClearBytes	move.b	d0,(a0)+
		dbf	d1,_ClearBytes
		
		move.l	a2,a0
		lea	_DataFirst(pc),a1
		moveq	#_DataSecond-_DataFirst-1,d0
_CopyFirst	move.b	(a1)+,(a0)+
		dbf	d0,_CopyFirst

		move.l	a2,a0
		add.l	#$3e8,a0
		lea	_DataSecond(pc),a1
		moveq	#_DataEnd-_DataSecond-1,d0
_CopySecond	move.b	(a1)+,(a0)+
		dbf	d0,_CopySecond
		bra	_LoadDone

_DataFirst	dc.l	'game',$00160006,$5dd40000
_DataSecond	dc.l	'qwak',$03450000
_DataEnd

;======================================================================

_CheckSaveGame	lea	_SaveName(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)

		tst.l	d0
		bne	.SaveGameFound

		move.l	#$d3e00,d0		;d0 = Offset
		move.l	#$8200,d1		;d1 = Size
		moveq	#2,d2			;d2 = Disk number
		lea	$1000,a0		;a0 = Destination address
		jsr	resload_DiskLoad(a2)

		lea	$1000,a0		;Insert some default (slow)
		move.l	#(42*3)-1,d7		;times
.ClearTimes	move.l	#9999,(a0)+
		move.l	#'IAN ',(a0)+
		dbf	d7,.ClearTimes

		moveq	#7,d7
.ClearScores	move.l	d7,d0
		addq.w	#1,d0
		mulu.w	#2000,d0
		move.l	d0,(a0)+
		move.l	#'IAN ',(a0)+
		dbra	d7,.ClearScores

		move.l	#$8200,d0		;Create the savegame file
		lea	_SaveName(pc),a0
		lea	$1000,a1
		jsr	resload_SaveFile(a2)

.SaveGameFound	rts

;======================================================================

_Keybd		cmp.b	_keyexit(pc),d0
		beq	_exit

		cmp.b	#$46,d0
		bne	_NotDel

		move.l	#99950,$d94e		;Loadsamoney!
		bra	_SetCheat

_NotDel		cmp.b	#$5f,d0
		bne	_NoCheat

		move.w	#0,($86DC).l		;Win race
		move.b	#7,($D938).l

_SetCheat	move.l	a0,-(sp)
		lea	_CheatFlag(pc),a0
		move.b	#-1,(a0)
		move.l	(sp)+,a0

_NoCheat	bset	#6,($e00,a0)		;Stolen code
		rts

;======================================================================
_resload	dc.l	0			;Resident loader
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
