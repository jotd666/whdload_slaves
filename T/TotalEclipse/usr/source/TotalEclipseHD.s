;*---------------------------------------------------------------------------
; Program:	TotalEclipse.s
; Contents:	Slave for "Total Eclipse" (c) 1989 Incentive Software/Domark
; Author:	Codetapper/Action
; History:	23.04.2002 - v1.0
;		           - Supports 3 versions
;		           - Full load from HD
;		           - Loads and saves games to HD
;		           - Copy protection removed on 2 versions (MFM track/Rob Northen copylock)
;		           - Empty DBF loops fixed (x2)
;		           - Stack relocated to fast memory
;		           - Quick key instructions included
;		           - 4 Colour Icon, MagicWB Icon, RomIcon, NewIcon, OS3.5 Colour Icon (created by 
;		             me!) and 2 Exoticons (taken from http://exotica.fix.no)
;		           - Quit option (default key is 'F10')
; Requires:	WHDLoad 15+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Version 1:	Taken from the "Virtual Worlds" compilation. The game indicates 
;		that this is V1.1 Published by MicroProse Software Ltd 
;		under licence and (c) 1989 Incentive Software. 
;		Copy protection is the file "nofastmem" which runs before the
;		game starts and alters the _LVOOpenLibrary(a6) call to check
;		for "KEV.library" and replace it with "dos.library" so the
;		game works. The main game is called "2" and the disk is
;		labelled "3D Worlds". Supplied by Carlo Pirri!
; Version 2:	Unprotected version called V1.0 in the readme. Found on most
;		ADF sites on the net!
; Version 3:	The loading file "0.tec" contains a completely encrypted Rob 
;		Northen series 1 copylock. The second file "1.tec" is the
;		same as Version 1 of the game. The label is "TOTAL ECLIPSE".
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		INCLUDE	lvo/dos.i

		IFD BARFLY
		OUTPUT	"TotalEclipse.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DEBUG
;DISKSONBOOT
;DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_Data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM+$1000		;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

		CNOP 0,4
_name		dc.b	"Total Eclipse",0
_copy		dc.b	"1989 Incentive Software/Domark",0
_info		dc.b	"Installed by Codetapper/Action",10
		dc.b	"Version 1.0 "
		IFD	BARFLY
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
		INCBIN	"T:date"
		ELSE
		dc.b	"(23.04.2002)"
		ENDC
		dc.b	-1,"Thanks to Carlo Pirri and Mike West"
		dc.b	10,"for sending the originals!"
		dc.b	0
_Data		dc.b	"data",0
_MainFile	dc.b	"2",0
_MainFile_V3	dc.b	"0.tec",0
_NotFoundMsg	dc.b	"The intro file '0.tec' or '2' could not be found!",0
_FailedLoadMsg	dc.b	"Failed to load the intro file!",10,"Check it is a standard Amiga executable",10,"and hasn't been compressed!",0
_args		dc.b	10
_args_end
		EVEN

;============================================================================
_start						;a0 = resident loader
;============================================================================
						
		bra	_boot			;initialize kickstart and environment

_bootdos	move.l	_resload(pc),a2		;a2 = resload

		lea	_dosname(pc),a1		;Open doslib
		move.l	(4),a6
		jsr	_LVOOldOpenLibrary(a6)
		move.l	d0,a6			;A6 = dosbase

		lea	_MainFile(pc),a0	;Virtual Worlds intro name
		bsr	_GetFileSize
		tst.l	d0
		bne	_LoadIntro

		lea	_MainFile_V3(pc),a0	;Copylocked intro name
		bsr	_GetFileSize
		tst.l	d0
		beq	_filenotfound

_LoadIntro	move.l	a0,d1			;Load exe
		jsr	_LVOLoadSeg(a6)
		move.l	d0,d7			;D7 = segment
		beq	_failedtoload

		move.l	d7,a0
		add.l	a0,a0
		add.l	a0,a0
		add.l	#4,a0

		cmp.l	#$4afc23c0,$ee(a0)	;Check for encrypted game (jmp CONTROL)
		beq	_Intro_V3

		cmp.l	#'KEV.',$30(a0)		;KEV.library protected version
		beq	_IntroOK		;from Virtual Worlds compilation (Carlo Pirri)

		cmp.l	#'dos.',$30(a0)		;dos.library unprotected version
		bne	_wrongver		;from Virtual Worlds compilation (KEV->dos)

_IntroOK	lea	_PL_Intro(pc),a0	;Patch game
		move.l	d7,a1
		jsr	resload_PatchSeg(a2)

_CommonIntro	IFD DEBUG
		clr.l	-(a7)			;set debug
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
		ENDC

		lea	_PL_LowMem(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	d7,a1			;call
		add.l	a1,a1
		add.l	a1,a1
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6
		bra	_exit

_PL_LowMem	PL_START
		PL_P	$100,_EmptyD1Loop	;Fix empty DBF loops
		PL_P	$106,_EmptyD7Loop
		PL_P	$10c,_Game
		PL_END

_PL_Intro	PL_START
		PL_L	$30,'dos.'		;KEV.library->dos.library
		PL_L	$400,$4eb8010c		;lea ($1c,a6),a0 to jump to game
		PL_END

;============================================================================

_Intro_V3	move.l	d7,-(sp)		;Save segment address
		move.l	a0,a5			;a5 = Start of the data

		move.l	#$575f,d0		;d0 = Length of encrypted data
		move.l	#$9fde1d0a,d5		;D0 = $0000575F , D1 = $00000001
		move.l	#$9fde1d20,d6		;D5 = $9FDE1D0A , D6 = $9FDE1D20
		move.l	#$74ea8d5c,d7		;D7 = $74EA8D5C , A0 = $00000CEC
		lea	$cec-$20(a5),a0		;A1 = $0000001C , A2 = $00000CF0
		bsr	_Decrypt		
						
		lea	$cf0-$20+$c(a5),a2	;Table of reloc32 values
		lea	$e54-$20(a5),a3		;Current position of game code
		move.l	a5,d0			;Destination address
_RelocNext	move.l	(a2)+,d2
		beq	_RelocDone		;Registers used for relocate file
		add.l	d0,(a3,d2.l)		;
		bra	_RelocNext		;A2 = $00000CF0 , A3 = $00000E54

_RelocDone	lea	$e54-$20(a5),a0
		move.l	a5,a1
		move.l	#$575f-1,d0
_Relocate	move.l	(a0)+,(a1)+
		dbf	d0,_Relocate

		lea	_PL_Intro(pc),a0	;Patch game (PatchSeg fails so
		move.l	a5,a1			;we will do it this way)
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	(sp)+,d7		;Restore segment address
		bra	_CommonIntro

;============================================================================

_Game		movem.l	d0-d1/a0-a2/a6,-(sp)	;Patch main game

		move.l	#$4eaefdd8,d0		;jsr _LVOOpenLibrary(a6)
		cmp.l	$4b2(a6),d0		;Check for known versions
		beq	_Version2

		cmp.l	$438(a6),d0
		bne	_wrongver

_Version1	lea	_PL_GameV1(pc),a0
		move.l	a6,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	_expmem(pc),d0		;Stack to fast memory
		add.l	#EXPMEM,d0
		add.l	#$ffc,d0
		add.l	#$8000,a6
		move.l	d0,$7d4(a6)
		move.l	d0,$9ea(a6)
		bra	_StartGame

_Version2	lea	_PL_GameV2(pc),a0
		move.l	a6,a1
		jsr	resload_Patch(a2)

		move.l	_expmem(pc),d0		;Stack to fast memory
		add.l	#EXPMEM,d0
		add.l	#$ffc,d0
		add.l	#$8000,a6
		move.l	d0,$84e(a6)
		move.l	d0,$a4e(a6)

_StartGame	movem.l	(sp)+,d0-d1/a0-a2/a6
		lea	$1c(a6),a0		;Stolen code
		rts

_PL_GameV1	PL_START
		PL_L	$2716,$4eb80106		;Empty d7 loop (8191)
		PL_L	$2eb8,$4eb80100		;Empty d1 loop (4000)
		PL_PS	$34f2,_LongD0Loop	;1500000 empty d0 loop
		PL_S	$34f8,$fe-$f8
		PL_R	$350a			;Disk access
		PL_P	$3536,_LongD0Loop	;1500000 empty d0 loop
		PL_END

_PL_GameV2	PL_START
		PL_L	$2794,$4eb80106		;Empty d7 loop (8191)
		PL_L	$2f32,$4eb80100		;Empty d1 loop (4000)
		PL_PS	$356c,_LongD0Loop	;1500000 empty d0 loop
		PL_S	$3572,$78-$72
		PL_R	$3584			;Disk access
		PL_P	$35b0,_LongD0Loop	;1500000 empty d0 loop
		PL_END

;============================================================================

_LongD0Loop	move.l	#25-1,d0		;Wait half a second
.Wait		waitvb
		dbf	d0,.Wait
		rts

;============================================================================

_EmptyD1Loop	movem.l	d0-d1,-(sp)
		and.l	#$ffff,d1
		divu	#80,d1
.wait1		move.b	(_custom+vhposr),d0
.wait2		cmp.b	(_custom+vhposr),d0
		beq	.wait2
		dbf	d1,.wait1
		movem.l	(sp)+,d0-d1
		rts

_EmptyD7Loop	move.l	d1,-(sp)
		move.l	d7,d1
		bsr	_EmptyD1Loop
		move.l	(sp)+,d1
		rts

;============================================================================

_GetFileSize	movem.l	d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		movem.l	(sp)+,d1/a0-a2
		rts

;======================================================================

_Decrypt	movem.l	d0/d5-d7/a0,-(sp)	;Rob Northen Decryption (3 Key)
.DecryptLoop	lsl.l	#1,d7
		btst	d5,d7
		beq.s	.Skip1
		btst	d6,d7
		beq.s	.Skip3
		bra.s	.Skip2
.Skip1		btst	d6,d7
		beq.s	.Skip2
.Skip3		addq.l	#1,d7			;Modify key for correct btst otherwise fuckup!
.Skip2		add.l	d7,(a0)			;Modify key to encrypted data = correct data
		add.l	(a0)+,d7		;Modify key with next encrypted longword
		subq.l	#1,d0			;Subtract from counter until null
		bne.s	.DecryptLoop
		movem.l	(sp)+,d0/d5-d7/a0
		rts	

;======================================================================

_filenotfound	pea	_NotFoundMsg(pc)
		pea	TDREASON_FAILMSG
		bra	_end
_failedtoload	pea	_FailedLoadMsg(pc)
		pea	TDREASON_FAILMSG
		bra	_end
_exit		pea	TDREASON_OK
		bra	_end
;_debug		pea	TDREASON_DEBUG
;		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;============================================================================

		INCLUDE	"whdload/kick13.s"

;============================================================================

		END
