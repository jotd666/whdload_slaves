;*---------------------------------------------------------------------------
; Program:	SuperCars.s
; Contents:	Slave for "Super Cars" from Gremlin
; Author:	Codetapper of Action
; History:	25.01.00 - v1.0
;		         - Full load from HD
;		         - 3 versions supported
;		         - Stackframe fix for 68020+ processors
;		         - Protection removed
;		         - Blitter wait inserted
;		         - Loads and save fastest laps and best performances (unless you cheat)
;		         - Loads and saves settings (name, money, car, level, tracks completed,
;		           engine, body, fuel, tyre damage, weapons, car upgrades and car dealer
;		           status at any point when you press 'S')
;		         - 'P' key added for pause (as specified in the documentation)
;		         - Keyboard acknowledge routine rewritten (on 2 versions)
;		         - Gremlin logo and intro can be bypassed with fire or either mouse button
;		         - RomIcon, NewIcon and GlowIcon (created by me!)
;		         - Quit option (default key is '*' on keypad)
; 		08.06.02 - v1.1
;		         - Modified the delay code on the Gremlin logo so it now works on emulators
;		         - Instructions included
;		         - Added a Normal and MagicWB icon
;		         - Quit key changed to 'F10'
; 		13.06.13 - v1.2
;		         - Stackframe fix added for 68010 users (thanks to Dennis for the bug report)
;		         - Updated installer script
; Requires:	WHDLoad 13+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Info:		
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"SuperCars.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

BASEMEM		equ	$80000

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

_name		dc.b	"Super Cars",0
_copy		dc.b	"1990 Magnetic Fields/Gremlin",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version 1.2 "
		IFD	BARFLY
		IFND	.passchk
		DOSCMD	"WDate >T:date"
.passchk
		ENDC
		INCBIN	"T:date"
		ELSE
		dc.b	"(13.06.2013)"
		ENDC
		dc.b	-1,"Thanks to Ronny, Matthew Thompson and",10
		dc.b	"Jean-François Fabre for the originals!",0
_SaveFileName	dc.b	"SuperCars.save",0
_HighsFileName	dc.b	"SuperCars.highs",0
_BootFileName	dc.b	"SuperCars.boot",0
_DiskNumber	dc.b	1
_CheatFlag	dc.b	0
_SaveFileExists	dc.b	0
		EVEN
_LoadAddress	dc.l	0
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	clr.l	-(a7)			;TAG_DONE
                clr.l	-(a7)			;data to fill
		move.l	#WHDLTAG_ATTNFLAGS_GET,-(a7)
		move.l	a7,a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		move.w	(6,a7),d0		;d0 = AttnFlags
		lea	(12,a7),a7		;Restore sp

		lea	_AttnFlags(pc),a0	;Store AttnFlags
		move.w	d0,(a0)

		lea	$500,sp

		moveq	#0,d0			;d0 = Offset
		move.l	#$9400,d1		;d1 = Size
		moveq	#1,d2			;d2 = Diskno
		lea	$76c00,a0		;a0 = Destination address
		move.l	a0,a5
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		lea	_PL_Boot(pc),a0		;Install patches
		sub.l	a1,a1
		jsr	resload_Patch(a2)

		move.l	a5,a0
		move.l	#$9400,d0
		jsr	resload_CRC16(a2)

		cmp.w	#$b523,d0		;Check two disk original
		beq	_TwoDiskVers

		cmp.w	#$c22c,d0		;Check one disk Hit Squad
		beq	_HitSquadVers

		cmp.w	#$81f7,d0		;Check one disk original
		bne	_wrongver

_OneDiskVers	lea	_LoadAddress(pc),a0
		move.l	#$76c00,(a0)
		lea	_PL_HitMachine(pc),a0
		bra	_PatchMain

_TwoDiskVers	lea	_LoadAddress(pc),a0
		move.l	#$76c00,(a0)
		lea	_PL_2_DiskVer(pc),a0

_PatchMain	move.l	a5,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		bsr	_LoadHighs		;Load high scores if found
		bsr	_LoadSettings		;Load settings if found

		move.w	#$8210,$dff096
		jmp	(a5)			;Start game

;======================================================================

_HitSquadVers	lea	_LoadAddress(pc),a0
		move.l	#$76de8,(a0)

		lea	$a00,sp

		move.l	#$1000,d0		;d0 = Size
		move.l	#$400,d1		;d1 = Offset
		lea	_BootFileName(pc),a0	;a0 = File name
		lea	$a00,a1			;a1 = Destination address
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_LoadFileOffset(a2)

		lea	_PL_HitSquadBot(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		jmp	$1c(a5)

_PL_HitSquadBot	PL_START
		PL_R	$d6			;Go to track 0
		PL_R	$fe			;Select DF0:
		PL_R	$12e			;Turn off DF0:
		PL_P	$1b6,_Loader
		PL_R	$cbc			;Copy protection
		PL_P	$daa,_debug		;Infinite loop
		PL_END

_PL_HitSquad	PL_START			;Single disk Hit Squad
		PL_W	$18b4,$4e71		;Allow user to skip the
		PL_PS	$18b6,_GremlinDelay	;Gremlin 3 second delay
		PL_W	$18c2,13		;Speed up black delay
		PL_W	$1976,$4e71		;Allow user to skip the long
		PL_PS	$1978,_MagFieldsDelay	;sound sample delay
		PL_PS	$3f06,_BlitWait_d0	;Blitwait (move.w d0,$dff058)
		PL_PS	$5a5e,_KeybdHitSquad	;Detect quit key
		PL_PS	$652e,_SaveHighs	;Player got a lap record
		PL_PS	$6e04,_SaveHighs	;Player got a high score
		PL_PS	$6f3c,_CheckName	;Check name typed in
		PL_PS	$7316,_NameEntryInit
		PL_END

;======================================================================

_PL_Boot	PL_START
		PL_R	$604			;Turn on DF0:
		PL_R	$608			;Turn off DF0:
		PL_L	$60c,$4ef80620
		PL_R	$610
		PL_P	$620,_Loader
		PL_END

_PL_HitMachine	PL_START			;Single disk Hit Machine
		PL_R	$16b4			;Copy protection
		PL_W	$177c,$4e71		;Allow user to skip the
		PL_PS	$177e,_GremlinDelay	;Gremlin 3 second delay
		PL_W	$178a,13		;Speed up black delay
		PL_W	$183e,$4e71		;Allow user to skip the long
		PL_PS	$1840,_MagFieldsDelay	;sound sample delay
		PL_PS	$3dce,_BlitWait_d0	;Blitwait (move.w d0,$dff058)
		PL_PS	$58c4,_KeybdSwap	;Swap keys around
		PL_L	$58ca,$4e714e71
		PL_PS	$58d4,_KeybdDelay	;Detect quit key and delay
		PL_W	$58da,$4e71		;A lame $58c4 patch could also work
		PL_S	$5b46,$5b4e-$5b46	;Skip bclr #6,$bfee01 at wrong time
		PL_PS	$6396,_SaveHighs	;Player got a lap record
		PL_PS	$6d72,_SaveHighs	;Player got a high score
		PL_PS	$6eaa,_CheckName	;Check name typed in
		PL_PS	$7284,_NameEntryInit
		PL_END

_PL_2_DiskVer	PL_START
		PL_R	$193a			;Copy protection
		PL_W	$1a02,$4e71		;Allow user to skip the
		PL_PS	$1a04,_GremlinDelay	;Gremlin 3 second delay
		PL_W	$1a10,13		;Speed up black delay
		PL_W	$1ac4,$4e71		;Allow user to skip the long
		PL_PS	$1ac6,_MagFieldsDelay	;sound sample delay
		PL_W	$1b40,$4e71		;Change disk
		PL_PS	$1b42,_ChangeDisk
		PL_PS	$4088,_BlitWait_d0	;Blitwait (move.w d0,$dff058)
		PL_PS	$5b7e,_KeybdSwap	;Swap keys around
		PL_L	$5b84,$4e714e71
		PL_PS	$5b8e,_KeybdDelay	;Detect quit key and delay
		PL_W	$5b94,$4e71		;A lame $5b7e patch could also work
		PL_S	$5e00,$5e08-$5e00	;Skip bclr #6,$bfee01 at wrong time
		PL_PS	$6650,_SaveHighs	;Player got a lap record
		PL_P	$6ec8,_exit		;Infinite loop flashing screen
		PL_PS	$71e6,_SaveHighs	;Player got a high score
		PL_PS	$731e,_CheckName	;Check name typed in
		PL_PS	$76f8,_NameEntryInit
		PL_END

;======================================================================

_GremlinDelay	movem.l	d0-d2/a0-a2,-(sp)

		move.l	#150-1,d0
.Delay		btst	#6,$bfe001
		beq	.Skip
		btst	#7,$bfe001
		beq	.Skip
		waitvb
		dbf	d0,.Delay
.Skip		movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_MagFieldsDelay	move.l	a0,-(a7)
		lea	(_custom),a0

_WaitForSound	move.w	$dff01e,d0
		andi.w	#$80,d0
		bne	_MagDelayDone

		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	_MagDelayDone
		btst	#POTGOB_DATLY-8,(potinp,a0)		;RMB
		beq	_MagDelayDone
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		bne	_WaitForSound

_MagDelayDone	move.l	(a7)+,a0
		rts

;======================================================================

_ChangeDisk	movem.l	d0/a0,-(sp)		;Switch disks
		lea	_DiskNumber(pc),a0
		move.b	(a0),d0
		eor.b	#3,d0			;01 -> 10 -> 01 :)
		move.b	d0,(a0)
		movem.l	(sp)+,d0/a0
		rts

;======================================================================

_NameEntryInit	cmp.w	#11,d0
		bne	_NotNameEntry

		movem.l	d0/a0,-(sp)
		move.b	_SaveFileExists(pc),d0
		cmp.b	#0,d0
		beq	_DoNotSetToLoad

		move.l	_LoadAddress(pc),a0
		move.l	#'LOAD',$3ec(a0)	;Change load name to 'LOAD'

_DoNotSetToLoad	movem.l	(sp)+,d0/a0

_NotNameEntry	move.l	a0,-(sp)
		move.l	_LoadAddress(pc),a0
		move.w	d0,$e1a(a0)		;Stolen code
		move.l	(sp)+,a0
		rts

;======================================================================

_CheckName	movem.l	d0-d1/a0-a2,-(sp)

		btst	#4,d5			;Check fire pressed
		beq	_CheckRich

		cmp.l	#'LOAD',d0
		bne	_CheckCheat

		move.b	_SaveFileExists(pc),d0
		cmp.b	#0,d0
		beq	_CheckRich

		move.l	_LoadAddress(pc),a0
		move.l	_DriverName(pc),$3ec(a0)
		move.l	_LoadAddress(pc),a0
		move.l	_Money(pc),$30c(a0)
		move.l	_LoadAddress(pc),a0
		move.w	_Car(pc),$2a2(a0)
		move.l	_LoadAddress(pc),a0
		move.w	_Level(pc),$b40(a0)
		move.l	_LoadAddress(pc),a0
		move.w	_Mask(pc),$b42(a0)
		move.l	_LoadAddress(pc),a0
		move.w	_TracksComplete(pc),$b44(a0)
		move.l	_LoadAddress(pc),a0
		move.w	_DealerStatus(pc),$336(a0)
		move.l	_LoadAddress(pc),a0
		move.w	_Unknown(pc),$3f0(a0)

		lea	_DamageStart(pc),a0
		move.l	_LoadAddress(pc),a1
		add.l	#$2d4,a1
		moveq	#($20/4)-1,d0
_SetDamage	move.l	(a0)+,(a1)+
		dbf	d0,_SetDamage

_CheckCheat	cmp.l	#'RICH',d0
		beq	_CheatDetected
		cmp.l	#'ODIE',d0
		beq	_CheatDetected
		cmp.l	#'BIGC',d0
		beq	_CheatDetected

_CheckRich	movem.l	(sp)+,d0-d1/a0-a2
		cmp.l	#'RICH',d0		;Stolen code
		rts

_CheatDetected	lea	_CheatFlag(pc),a0
		move.b	#-1,(a0)
		bra	_CheckRich

;======================================================================

_BlitWait_d0	BLITWAIT			;Wait for the blitter
		move.w	d0,$dff058		;Stolen code
		rts

;======================================================================

_EmptyDBF	movem.l	d0-d1,-(sp)
		moveq	#3-1,d1			;wait because handshake min 75 µs
.int2w1		move.b	(_custom+vhposr),d0
.int2w2		cmp.b	(_custom+vhposr),d0	;one line is 63.5 µs
		beq	.int2w2
		dbf	d1,.int2w1		;(min=127µs max=190.5µs)
		movem.l	(sp)+,d0-d1
		rts

;======================================================================

_KeybdSwap	move.b	$bfec01,d0		;Stolen code
		not.b	d0
		ror.b	#1,d0

		cmp.b	#$19,d0			;Check for P
		bne	_NotP
		move.b	#$40,d0			;Replace with Space

_NotP		rts

;======================================================================

_KeybdHitSquad	not.b	d0			;Stolen code
		ror.b	#1,d0

		cmp.b	#$19,d0			;Check for P
		bne	_NotPHitSquad
		move.b	#$40,d0			;Replace with Space

_NotPHitSquad	bra	_DetectQuit

;======================================================================

_KeybdDelay	bset	#6,$bfee01		;Acknowledge the keypress
		bsr	_EmptyDBF		;properly
		bclr	#6,$bfee01

_DetectQuit	move.l	d0,-(sp)
		cmp.b	_keyexit(pc),d0		
		beq	_exit

		cmp.b	#$21,d0			;Check for S
		bne	_NotS
		bsr	_SaveSettings

_NotS		move.l	(sp)+,d0
		rts

;======================================================================

_Loader		movem.l	d0-d2/a0-a3,-(sp)
		move.l	a0,a3
		moveq	#0,d2
		move.b	_DiskNumber(pc),d2	;d2 = Disk number
		cmp.b	#1,d2
		bne	_NotDisk1
		sub.l	#$3000,d0		;Disk 1 has first 2 tracks missing
_NotDisk1	move.l  _resload(pc),a2
		jsr	resload_DiskLoad(a2)

		move.w	_AttnFlags(pc),d0
		btst	#AFB_68010,d0
		beq	_NoStackFixReqd

		lea	$3f50,a0		;16 bit Hit Machine and 2 disk version
		cmp.l	#$337c0002,(a0)		;$3f50 move.w #2,(6,a1)
		beq	_StackFixReqd		;$3f56 rte

		lea	$4d50,a0		;Hit squad version
		cmp.l	#$337c0002,(a0)		;$4d50 move.w #2,(6,a1)
		bne	_NoStackFixReqd		;$4d56 rte

_StackFixReqd	move.w	#$4ef9,(a0)+
		pea	_StackFrameFix(pc)
		move.l	(sp)+,(a0)+

_NoStackFixReqd	cmp.l	#$76de8,a3		;Check if main Hit Squad file
		bne	_NoHitSquadMain

		lea	_PL_HitSquad(pc),a0
		lea	$76c00,a1
		jsr	resload_Patch(a2)

		bsr	_LoadHighs		;Load high scores if found
		bsr	_LoadSettings		;Load settings if found

_NoHitSquadMain	movem.l	(sp)+,d0-d2/a0-a3
		rts

;======================================================================

_StackFrameFix	move.w	#2,(6,a1)
		move.w	(sp)+,sr
		rts

;======================================================================

_Encrypt	move.l	d0,-(sp)		;Inputs: d0 = length
.enc		eor.b	d0,(a1)+
		subq.l	#1,d0
		bne.s	.enc
		move.l	(sp)+,d0
		sub.l	d0,a1
		rts

;======================================================================

_EncryptHighs	movem.l	d0-d2/a0-a2,-(sp)

		move.l	#$3cc-$33c,d0
		move.l	_LoadAddress(pc),a1
		add.l	#$33c,a1
		bsr	_Encrypt
		movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_LoadHighs	movem.l	d0-d2/a0-a2,-(sp)

		lea	_HighsFileName(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		
		tst.l	d0
		beq	_NoHighsFile

		lea	_HighsFileName(pc),a0
		move.l	_LoadAddress(pc),a1
		add.l	#$33c,a1
		jsr	resload_LoadFile(a2)

		bsr	_EncryptHighs		;Decrypt high scores

_NoHighsFile	movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_SaveHighs	move.b	(a3)+,(a2)+		;Stolen code
		move.b	(a3)+,(a2)+
		move.b	(a3)+,(a2)+

		movem.l	d0-d2/a0-a2,-(sp)	;Save high scores

		move.b	_CheatFlag(pc),d0	;Check if player has cheated
		cmp.b	#0,d0
		bne	_DoNotSaveHighs

		bsr	_EncryptHighs		;Encrypt high scores

		lea	_HighsFileName(pc),a0
		move.l	_LoadAddress(pc),a1
		add.l	#$33c,a1
		move.l	#$3cc-$33c,d0
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)

		bsr	_EncryptHighs		;Decrypt them back again

_DoNotSaveHighs	movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_LoadSettings	movem.l	d0-d2/a0-a2,-(sp)

		lea	_SaveFileName(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		
		tst.l	d0
		beq	_NoSaveFile

		lea	_SaveFileName(pc),a0
		lea	_SaveFileStart(pc),a1
		jsr	resload_LoadFile(a2)

		lea	_SaveFileExists(pc),a0
		move.b	#-1,(a0)

_NoSaveFile	movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_SaveSettings	movem.l	d0-d2/a0-a2,-(sp)

		move.l	_LoadAddress(pc),a1
		lea	_DriverName(pc),a0
		move.l	$3ec(a1),(a0)
		lea	_Money(pc),a0
		move.l	$30c(a1),(a0)
		lea	_Car(pc),a0
		move.w	$2a2(a1),(a0)
		lea	_Level(pc),a0
		move.w	$b40(a1),(a0)
		lea	_Mask(pc),a0
		move.w	$b42(a1),(a0)
		lea	_TracksComplete(pc),a0
		move.w	$b44(a1),(a0)
		lea	_DealerStatus(pc),a0
		move.w	$336(a1),(a0)
		lea	_Unknown(pc),a0
		move.w	$3f0(a1),(a0)

		move.l	_LoadAddress(pc),a0
		add.l	#$2d4,a0
		lea	_DamageStart(pc),a1
		moveq	#($20/4)-1,d0
_StoreDamage	move.l	(a0)+,(a1)+
		dbf	d0,_StoreDamage

		move.b	_CheatFlag(pc),d0
		cmp.b	#0,d0
		bne	_DoNotSaveGame

		lea	_SaveFileName(pc),a0
		lea	_SaveFileStart(pc),a1
		moveq	#_SaveFileEnd-_SaveFileStart,d0
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)

		lea	_SaveFileExists(pc),a0
		move.b	#-1,(a0)

_DoNotSaveGame	movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================
_resload	dc.l	0		;address of resident loader
_AttnFlags	dc.w	0
;======================================================================

_SaveFileStart
_DriverName	dc.l	'IANL'		;$3ec
_Money		dc.l	5000		;$30c
_Car		dc.w	0		;$2a2
_Level		dc.w	0		;$b40
_Mask		dc.w	0		;$b42
_TracksComplete	dc.w	0		;$b44
_DealerStatus	dc.w	0		;$336 (0 = Allowed into shop)
_Unknown	dc.w	0		;$3f0 (All variables cleared at $6026)
_DamageStart	ds.b	$20		;$2d4-$2f4 (set at $72c6)
_DamageEnd
_SaveFileEnd

		EVEN

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
