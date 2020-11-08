;*---------------------------------------------------------------------------
; Program:	Zool2.s
; Contents:	Slave for "Zool 2" from Gremlin
; Author:	Codetapper of Action
; History:	28.05.02 - v1.0
;		         - Full load from HD
;		         - 3 versions supported 
;		         - Manual protection removed (screen no longer appears)
;		         - NTSC protection removed
;		         - Loads and saves high scores (unless you cheat)
;		         - Disk requesters removed
;		         - Snoop bugs fixed
;		         - Access faults removed
;		         - Blitter waits added (x12)
;		         - Decruncher relocated to fast memory
;		         - Trainer added (set CUSTOM1=1 to enable cheat, CUSTOM2=1-6 for start level)
;		         - MagicWB, RomIcon, NewIcon and GlowIcon (all created by Frank!) and 2 
;		           Exoticons included (taken from http://exotica.fix.no)
;		         - Quit option (default key is 'F10')
; Requires:	WHDLoad 13+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Info:		The Classic crack is the only version which will work with
;		fast memory due to Mok putting in a Reloc32 routine!
; Cheat Info:	CUSTOM1<>0 to enable cheat mode ($80308)
; 		CUSTOM2=1-6 for starting level (high scores will save)
;
;		Codes are stored in the game as raw keycodes (for USA keymap) from
;		$15074 (in expansion memory at $80000 or $200000) to $150fc in the
;		following order:
;
;		      $0001 creamola__________________________________10 lives
;		      $0002 vision____________________________________20 lives
;		      $0004 kickass______________________Unlimited smart bombs
;		      $0008 napoleon___________________Bonus level every stage
;		      $0010 alcento_________________________99 items collected
;		      $0020 oldenemy____________________________Unlimited time
;		      $0040 toughguy_____________________________Invincibility
;		      $0080 sesame____________________________Start on level 1
;		      $0100 ronson____________________________Start on level 2
;		      $0200 funkytut__________________________Start on level 3
;		      $0400 hissteria_________________________Start on level 4
;		      $0800 7slurp____________________________Start on level 5
;		      $1000 plunger___________________________Start on level 6
;		      $2000 marrobone________Stops the ball on the bonus level
;		      $4000 bumblebee_____Skip stages (press 'RETURN' to skip)
;		      $8000 warpmode___________________________________Unknown
;
;		The game checks for matches at $14f86 and if a code is correct, the
;		routine at $14ffa is run which bit sets $80308 to the value shown in
;		the list and flashes the screen red for one frame.
;
;		To check for cheating, simply check $80308 for <> 0.
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"Zool2.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

;SUPPORT_AMIGA_FUN	equ	0		;Uncomment to support bugged Amiga Fun version
SUPPORT_CRACK		equ	0		;Uncomment to support the Mok/Classic crack (Back to the Roots)
;USE_FAST_MEM		equ	0		;Uncomment to use 512k chip mem/512k other mem (which only works on the Mok/Classic crack)

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		IFD	USE_FAST_MEM
		dc.l	$80000			;ws_BaseMemSize
		ELSE
		dc.l	$100000			;ws_BaseMemSize
		ENDC
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		IFD	USE_FAST_MEM
		dc.l	$80000			;ws_ExpMem
		ELSE
		dc.l	0			;ws_ExpMem
		ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
        dc.w    0     ; kickstart name
        dc.l    $0         ; kicksize
        dc.w    $0         ; kickcrc
		dc.w	slv_config-_base

slv_config:
        dc.b    "C1:B:trainer;"
        dc.b    "C2:L:select start world:1,2,3,4,5,6;"

;============================================================================
    IFD    BARFLY
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
        ENDC
        
DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
    
_name		dc.b	"Zool 2",0
_copy		dc.b	"1993 Gremlin",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version "
        DECL_VERSION
		dc.b	-1,"Thanks to Mad-Matt for the ECS version"
		dc.b	10,"and Chris Vella for the AGA version!"
		dc.b	0
_Highs		dc.b	"Zool2.highs",0
_DiskNumber	dc.b	1
_CheatFlag	dc.b	0
		IFD	SUPPORT_CRACK
_Disk0		dc.b	"Disk.0",0		
		ENDC
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	lea	_Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		lea	_ExpansionMem(pc),a0	;Remember the expansion
		IFD	USE_FAST_MEM		;memory location
		move.l	_expmem(pc),(a0)
		ELSE
		move.l	#$80000,(a0)
		ENDC

		IFD	SUPPORT_CRACK
		lea	_Disk0(pc),a0		;Disk 0 means we have the
		jsr	resload_GetFileSize(a2)	;classic crack
		tst.l	d0
		beq	_NotClassicCrk

		move.l	#$6e000,d0
		move.l	#$6400,d1
		moveq	#0,d2
		lea	$6a000,a0
		move.l	a0,a5
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		cmp.l	#$70000,$124(a5)	;Check for jmp $70000
		beq	_ClassicCrack
_NotClassicCrk	ENDC

		move.l	#$ab000,d0
		move.l	#$1a200,d1
		moveq	#1,d2
		lea	$60000,a0
		move.l	a0,a5
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		move.l	a5,a0
		move.l	#$1a200,d0
		move.l	_resload(pc),a2
		jsr	resload_CRC16(a2)

		cmp.w	#$75fa,d0		;Check Amiga Fun version
		beq	_wrongver		;beq	_AmigaFun

		move.l	#1916,d0		;d0 = First sector
		move.l	#1919,d1		;d1 = Final sector
		lea	$70000,a0
		move.l	a0,a5
		bsr	_Loader

		move.l	a5,a0
		move.l	#$800,d0
		move.l	_resload(pc),a2
		jsr	resload_CRC16(a2)

		cmp.w	#$4a86,d0		;Check two disk original
		bne	_wrongver

		lea	_PL_Boot(pc),a0
		move.l	a5,a1
		bsr	_Patch

		move.l	_ExpansionMem(pc),d2
		jmp	(a5)			;Start game

_PL_Boot	PL_START
		PL_I	$70			;Game has detected $c00000 memory!
		PL_NOP	$80,4		;If expansion memory isn't $80000 crash!
		PL_P	$b4,_Original
		PL_S	$ce,$112-$ce		;Skip memory detection
		PL_R	$25c			;Disk access
		PL_P	$29e,_Loader		;Loader
		PL_END

;======================================================================

_Original	movem.l	d0-d1/a0-a2,-(sp)

		bsr	_CheckCheats
		bsr	_LoadHighScores

		lea	_PL_Common(pc),a0	;Patch stuff in all versions
		move.l	_ExpansionMem(pc),a1
		bsr	_Patch

		lea	_PL_Original(pc),a0	;Patch stuff specific to the
		bsr	_Patch			;original version
		
		movem.l	(sp)+,d0-d1/a0-a2

		move.l	_ExpansionMem(pc),-(sp)	;jmp $80002
		add.l	#2,(sp)
		rts

_PL_Common	PL_START			;Common to all versions
		PL_S	$80,$86-$80		;Remove protection screen :)			
		PL_PS	$608,_Copperlist
		PL_NOP	$60e,2
		PL_PS	$1d12,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
		PL_PS	$1d28,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
		PL_PS	$1d3e,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
		PL_PS	$1d54,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
		PL_PS	$2c3c,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
		PL_PS	$a4f4,_BSet_1_13_a5	;bset #1,($13,a5)
		PL_PS	$a500,_BClr_1_13_a5	;bclr #1,($13,a5)
		PL_PS	$a858,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
		PL_PS	$a8f2,_Blt_1001_58_a5	;move.w #$1001,($58,a5)
		PL_PS	$bad4,_Blt_lsr_6_d0
		PL_P	$bbe0,_Blt_d7_58_a5	;move.w d7,($58,a5) and rts
		PL_PS	$bd70,_Blt_a054_d158	;move.l a0,($54,a5) and move.w d1,($58,a5)
		PL_W	$bd76,$4e71
		PL_P	$e338,_FixCListWait
		PL_PS	$e55c,_Blt_8818_58_a5	;move.w #$8818,($58,a5)
		PL_PS	$e574,_Blt_8818_58_a5	;move.w #$8818,($58,a5)
		PL_PS	$10fca,_Keybd
		PL_NOP	$12a3a,4	;Don't request disk 1
		PL_NOP	$12aec,4	;Don't request disk 2
		PL_PS	$1502a,_SetCheatBit
		PL_PS	$15c36,_SaveHighs	;Save high scores
		PL_R	$15cec			;NTSC protection
		PL_PS	$15e6c,_Copperlist2
		PL_S	$15e72,$15e80-$15e72
		PL_NOP	$15f94,4	;Protection
		PL_NOP	$15fa2,4	;Protection
		PL_NOP	$15fac,4	;Protection
		PL_NOP	$15fba,4	;Protection
		PL_NOP	$15fcc,4	;Protection
		PL_PS	$17532,_SoundFault
		PL_END

_PL_Original	PL_START
		PL_PS	$12a54,_SetDisk1_d118	;move.l #$18,d1
		PL_PS	$12b06,_SetDisk2_d118	;move.l #$18,d1
		PL_P	$16ea6,_Decruncher
		PL_R	$17b9e			;Disk access
		PL_P	$17bec,_Loader		;Loader
		PL_END

;======================================================================

_CheckCheats	movem.l	d0-d2/a0,-(sp)

		move.w	#0,d2			;d2 = Cheat value
		move.l	_Custom1(pc),d0		;Check CUSTOM1=Cheat mode
		tst.l	d0			;on the cheat mode
		beq	_NoCheat

		move.w	#$c076,d2		;Set default cheats
		bsr	_SetCheatFlag

_NoCheat	move.l	_Custom2(pc),d0		;Check CUSTOM2=Start level
		moveq	#0,d1			;d1 = Initial level mask
		cmp.l	#1,d0
		ble	_NoStartLevel
		cmp.l	#6,d0
		ble	_SetLevel
		move.l	#6,d0			;7 = Maximum start level

_SetLevel	addq	#6,d0
		bset	d0,d2			;Add in start level cheat

_NoStartLevel	move.l	_ExpansionMem(pc),a0	;move.w	d2,$80308
		add.l	#$308,a0
		move.w	d2,(a0)

		movem.l	(sp)+,d0-d2/a0
		rts

;======================================================================

_Copperlist	move.l	#$fffffffe,$858
		move.l	#$800,($80,a5)
		rts

_Copperlist2	move.l	#$fffffffe,$18a0	;Write the end of copperlist
		move.l	#$1854,$dff080		;before activating it!
		rts

_FixCListWait	cmp.l	#$33d0fffe,$880
		bne	.CList880IsOK
		move.l	#$33d1fffe,$880		;Fix!

.CList880IsOK	cmp.l	#$37d0fffe,$8a0
		bne	.CList8a0IsOK
		move.l	#$37d1fffe,$8a0		;Fix!

.CList8a0IsOK	move.w	#$8080,$dff096
		rts

;======================================================================

_SoundFault	and.l	#$7f,d2
		move.l	(a1,d2.l),(4,a4)	;Stolen code
		rts

_BSet_1_13_a5	cmp.l	#$dff000,a5
		beq	.Skip
		bset	#1,($13,a5)		;Read only register pot0dat
.Skip		rts

_BClr_1_13_a5	cmp.l	#$dff000,a5
		beq	.Skip
		bclr	#1,($13,a5)		;Read only register pot0dat
.Skip		rts

;======================================================================

_SetDisk1	move.l	a0,-(sp)
		lea	_DiskNumber(pc),a0
		move.b	#1,(a0)
		move.l	(sp)+,a0
		rts

_SetDisk2	move.l	a0,-(sp)
		lea	_DiskNumber(pc),a0
		move.b	#2,(a0)
		move.l	(sp)+,a0
		rts

;======================================================================

_SetDisk1_d118	bsr	_SetDisk1		;Ensure disk 1 is in
		bra	_Set_d1_to_18		;Stolen code

_SetDisk2_d118	bsr	_SetDisk2		;Ensure disk 2 is in
_Set_d1_to_18	move.l	#$18,d1			;Stolen code
		rts

;======================================================================

_Loader		movem.l	d0-d2/a0-a2,-(sp)
		moveq	#0,d2
		move.b	_DiskNumber(pc),d2	;d2 = Disk number
		ext.l	d0
		ext.l	d1
		sub.l	d0,d1
		cmp.b	#2,d2
		beq	_DoNotSkip
		sub.l	#24,d0			;Disk 1 has 2 empty tracks
_DoNotSkip	mulu	#$200,d0
		addq	#1,d1
		mulu	#$200,d1
		move.l  _resload(pc),a2
		jsr	resload_DiskLoad(a2)
_LoadDone	movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_Keybd		move.l	d0,-(sp)
		not.b	d0
		ror.b	#1,d0
		cmp.b	_keyexit(pc),d0
		beq	_exit
		cmp.b	#$5f,d0
		move.l	(sp)+,d0
		rts

;======================================================================

_SetCheatBit	movem.l	d1/a0,-(sp)
		move.l	_ExpansionMem(pc),a0	;move.w	d1,$80308
		add.l	#$308,a0
		move.w	d1,(a0)
		and.w	#$e07f,d1
		tst.w	d1
		beq	_LevelCodeOnly		;User just wants to start
		bsr	_SetCheatFlag		;on a level
_LevelCodeOnly	movem.l	(sp)+,d1/a0
		rts

_SetCheatFlag	move.l	a0,-(sp)
		lea	_CheatFlag(pc),a0
		move.b	#-1,(a0)
		move.l	(sp)+,a0
		rts

;======================================================================

_SaveHighs	bsr	_SaveHighScores
		move.l	_ExpansionMem(pc),-(sp)	;jmp $944b6 (Stolen code)
		add.l	#$144b6,(sp)
		rts

;======================================================================

_LoadHighScores	movem.l	d0-d1/a0-a3,-(sp)

		move.l	_ExpansionMem(pc),a1	;lea	$96cd4,a1
		add.l	#$16cd4,a1
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
		tst.b	d0
		bne	_DoNotSave

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	_ExpansionMem(pc),a1	;lea $9874a,a1
		add.l	#$1874a,a1		;a1 = Address
		move.l  _resload(pc),a2
		bsr	_Encrypt		;Encrypt scores
		move.l	a1,-(sp)
		jsr	resload_SaveFile(a2)	;Save scores
		move.l	(sp)+,a1
		bsr	_Encrypt		;Decrypt scores

_DoNotSave	movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Encrypt	move.l	#112,d0			;Set d0 = length
		move.l	d0,-(sp)
.enc		eor.b	d0,(a1)+
		subq.l	#1,d0
		bne.s	.enc
		move.l	(sp)+,d0
		sub.l	d0,a1
		rts

;======================================================================

_Blt_lsr_6_d0	lsr.w	#6,d0			;Deliberately falls through!

_Blt_d7_58_a5	move.w	d7,($58,a5)
		bra	_BlitWait

_Blt_a054_d158	move.l	a0,($54,a5)
		move.w	d1,($58,a5)
		bra	_BlitWait

_Blt_1001_58_a5	move.w	#$1001,($58,a5)
		bra	_BlitWait

_Blt_8818_58_a5	move.w	#$8818,($58,a5)

_BlitWait	btst	#6,$dff002
		bne	_BlitWait
		rts

;======================================================================

_Decruncher	move.b	(a0)+,d7
		btst	#7,d7
		bne.w	_Dec_10
		btst	#6,d7
		beq.w	_Dec_8
		btst	#5,d7
		bne.w	_Dec_4
		btst	#4,d7
		bne.w	_Dec_2
		andi.w	#15,d7
		addq.w	#2,d7
		move.b	(-2,a1),d6
		move.b	(-1,a1),d5
		sub.b	d6,d5
		move.b	(-1,a1),d6
		add.b	d5,d6
_Dec_1		move.b	d6,(a1)+
		add.b	d5,d6
		dbra	d7,_Dec_1
		bra.w	_Dec_15

_Dec_2		andi.w	#15,d7
		addq.w	#1,d7
		move.b	(-4,a1),d6
		lsl.w	#8,d6
		move.b	(-3,a1),d6
		move.b	(-2,a1),d5
		lsl.w	#8,d5
		move.b	(-1,a1),d5
		sub.w	d6,d5
		move.b	(-2,a1),d6
		lsl.w	#8,d6
		move.b	(-1,a1),d6
		add.w	d5,d6
_Dec_3		move.w	d6,d4
		move.b	d4,(1,a1)
		lsr.w	#8,d4
		move.b	d4,(a1)
		addq.l	#2,a1
		add.w	d5,d6
		dbra	d7,_Dec_3
		bra.w	_Dec_15

_Dec_4		btst	#4,d7
		bne.w	_Dec_6
		andi.w	#15,d7
		addq.w	#2,d7
		move.b	(-1,a1),d6
_Dec_5		move.b	d6,(a1)+
		dbra	d7,_Dec_5
		bra.w	_Dec_15

_Dec_6		andi.w	#15,d7
		addq.w	#1,d7
		move.b	(-2,a1),d6
		lsl.w	#8,d6
		move.b	(-1,a1),d6
_Dec_7		move.w	d6,d4
		move.b	d4,(1,a1)
		lsr.w	#8,d4
		move.b	d4,(a1)
		addq.l	#2,a1
		dbra	d7,_Dec_7
		bra.w	_Dec_15

_Dec_8		andi.w	#$3F,d7
		beq.w	_Dec_16
		subq.w	#1,d7
_Dec_9		move.b	(a0)+,(a1)+
		dbra	d7,_Dec_9
		bra.w	_Dec_15

_Dec_10		btst	#6,d7
		beq.w	_Dec_14
		btst	#5,d7
		beq.w	_Dec_13
		andi.w	#$1F,d7
		lsl.w	#8,d7
		move.w	d7,d5
		move.b	(a0)+,d5
		addq.w	#3,d5
		moveq	#0,d7
		move.b	(a0)+,d7
		addq.w	#5,d7
_Dec_11		subq.w	#1,d7
		neg.w	d5
		lea	(a1),a2
		lea	(a2,d5.w),a2
_Dec_12		move.b	(a2)+,(a1)+
		dbra	d7,_Dec_12
		bra.w	_Dec_15

_Dec_13		move.b	d7,d6
		andi.w	#$1C,d7
		andi.w	#3,d6
		lsl.w	#8,d6
		move.w	d6,d5
		move.b	(a0)+,d5
		addq.w	#3,d5
		lsr.w	#2,d7
		addq.b	#4,d7
		andi.w	#$FF,d7
		bra.w	_Dec_11

_Dec_14		andi.w	#$3F,d7
		move.w	d7,d5
		addq.w	#3,d5
		moveq	#3,d7
		bra.w	_Dec_11

_Dec_15		bra.w	_Decruncher

_Dec_16		rts

;======================================================================

		IFD	SUPPORT_AMIGA_FUN
_AmigaFun	lea	_PL_Common(pc),a0	;Patch stuff in all versions
		move.l	a5,a1
		bsr	_Patch

		lea	_PL_AmigaFun(pc),a0	;Patch stuff specific to the
		bsr	_Patch			;Amiga Fun version

		move.l	_ExpansionMem(pc),a1
		add.l	#2,a1
		jmp	(a5)

_PL_AmigaFun	PL_START
		PL_P	$a0,_GameAF
		PL_P	$be,_DecrunchMASM
		PL_END

_GameAF		move.b	#$5a,(a0)
		;lea	($100).w,sp		;Causes problems
		lea	$60000,a0
		move.w	#$7fff,d0
_ClearAFMem	clr.l	(a0)+
		dbra	d0,_ClearAFMem

		movem.l	d0-d1/a0-a1,-(sp)

		bsr	_CheckCheats
		bsr	_LoadHighScores

		lea	_PL_GameAmigaFn(pc),a0
		move.l	_ExpansionMem(pc),a1
		bsr	_Patch

		movem.l	(sp)+,d0-d1/a0-a1
		jmp	(a1)

_PL_GameAmigaFn	PL_START
		PL_P	$16ea6,_DecrunchMASM	;Bugged data or decruncher? (Levels 2-4 cause problems)
		PL_PS	$17c5a,_StoreDiskNumAF
		PL_W	$17c60,$4e71
		PL_P	$17ca2,_LoaderAF	;Loader
		PL_END

;======================================================================

_StoreDiskNumAF	move.l	a0,-(sp)
		lea	_DiskNumber(pc),a0
		move.b	d0,(a0)
		move.l	(sp)+,a0
		
		move.w	d0,(-2,a4)
		clr.w	(-4,a4)
		rts

_LoaderAF	movem.l	d1-d2/a0-a2,-(sp)
		move.l	d5,d0			;d0 = Offset
		move.l	d6,d1			;d1 = Length
		moveq	#0,d2
		move.b	_DiskNumber(pc),d2	;d2 = Disk number
		move.l  _resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(sp)+,d1-d2/a0-a2
		moveq	#0,d0			;d0 = 0 for success
		rts

;======================================================================

_DecrunchMASM	movem.l	d1-d5/a2-a5,-(sp)
		lea	(_MASM_37,pc),a4
		lea	(_MASM_36,pc),a5
		move.l	#$FF00,d5
		moveq	#0,d4
		moveq	#-$80,d3
_MASM_1		add.b	d3,d3
		bne.b	_MASM_2
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_2		bcc.b	_MASM_18
		add.b	d3,d3
		bne.b	_MASM_3
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_3		bcc.b	_MASM_17
		add.b	d3,d3
		bne.b	_MASM_4
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_4		bcc.b	_MASM_16
		add.b	d3,d3
		bne.b	_MASM_5
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_5		bcc.b	_MASM_15
		add.b	d3,d3
		bne.b	_MASM_6
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_6		bcc.b	_MASM_14
		add.b	d3,d3
		bne.b	_MASM_7
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_7		bcc.b	_MASM_13
		movea.l	a4,a2
_MASM_8		addq.l	#4,a2
		add.b	d3,d3
		bne.b	_MASM_9
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_9		bcs.b	_MASM_8
		move.w	(a2)+,d4
_MASM_10	add.b	d3,d3
		bne.b	_MASM_11
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_11	addx.w	d4,d4
		bcc.b	_MASM_10
		add.w	(a2),d4
_MASM_12	move.b	(a0)+,(a1)+
		dbra	d4,_MASM_12
_MASM_13	move.b	(a0)+,(a1)+
_MASM_14	move.b	(a0)+,(a1)+
_MASM_15	move.b	(a0)+,(a1)+
_MASM_16	move.b	(a0)+,(a1)+
_MASM_17	move.b	(a0)+,(a1)+
_MASM_18	add.b	d3,d3
		bne.b	_MASM_19
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_19	bcs.b	_MASM_21
		moveq	#1,d2
		add.b	d3,d3
		bne.b	_MASM_20
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_20	bcs.b	_MASM_26
		move.l	d5,d1
		moveq	#0,d2
		bra.b	_MASM_30

_MASM_21	movea.l	a5,a2
_MASM_22	addq.l	#4,a2
		add.b	d3,d3
		bne.b	_MASM_23
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_23	bcs.b	_MASM_22
		move.w	(a2)+,d2
_MASM_24	add.b	d3,d3
		bne.b	_MASM_25
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_25	addx.w	d2,d2
		bcc.b	_MASM_24
		add.w	(a2),d2
_MASM_26	moveq	#0,d4
		add.b	d3,d3
		bne.b	_MASM_27
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_27	addx.w	d4,d4
		add.b	d3,d3
		bne.b	_MASM_28
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_28	addx.w	d4,d4
		add.b	d3,d3
		bne.b	_MASM_29
		move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_29	addx.w	d4,d4
		add.w	d4,d4
		add.w	d4,d4
		move.l	(_MASM_35,pc,d4.w),d1
_MASM_30	move.w	d1,d4
_MASM_31	add.b	d3,d3
		bne.b	_MASM_33
		cmp.w	d5,d4
		bcs.b	_MASM_32
		lsl.w	#8,d4
		move.b	(a0)+,d4
_MASM_32	move.b	(a0)+,d3
		addx.b	d3,d3
_MASM_33	addx.w	d4,d4
		bcs.b	_MASM_31
		swap	d1
		add.w	d1,d4
		movea.l	a1,a3
		suba.l	d4,a3
_MASM_34	move.b	(a3)+,(a1)+
		dbra	d2,_MASM_34
		move.b	(a3)+,(a1)+
		cmp.l	a1,d0
		bhi.w	_MASM_1
		movem.l	(sp)+,d1-d5/a2-a5
		rts

		dc.w	$20
_MASM_35	dc.l	$F000
		dc.l	$20FC00
		dc.l	$A0FF00
		dc.l	$2A0FF80
		dc.l	$6A0FFC0
		dc.l	$EA0FFE0
		dc.l	$1EA0FFF0
_MASM_36	dc.l	$3EA0FFF8
		dc.l	$80000002
		dc.l	$40000004
		dc.l	$20000008
		dc.l	$10000010
		dc.l	$8000020
		dc.l	$4000040
		dc.l	$2000080
		dc.l	$1000100
		dc.l	$800200
_MASM_37	dc.l	$400400
		dc.l	$80000000
		dc.l	$40000002
		dc.l	$20000006
		dc.l	$1000000E
		dc.l	$800001E
		dc.l	$400003E
		dc.l	$200007E
		dc.l	$10000FE
		dc.l	$8001FE
		dc.l	$4003FE
		dc.l	$2007FE
		dc.l	$100FFE
		dc.l	$81FFE
		dc.l	$43FFE
		dc.l	$27FFE
		dc.l	$1FFFE
		dc.l	0
		ENDC

;======================================================================

		IFD	SUPPORT_CRACK
_ClassicCrack	pea	_ClassicDec(pc)		;jmp $70000
		move.l	(sp)+,$124(a5)
		jmp	(a5)

_ClassicDec	move.l	_ExpansionMem(pc),$7c	;Wire in expansion memory

		lea	_DiskNumber(pc),a0
		move.b	#0,(a0)

		lea	_PL_ClassicDec(pc),a0
		lea	$70000,a1
		bsr	_Patch
		
		jmp	$70000

_PL_ClassicDec	PL_START
		PL_P	$6e,_GameCrack		;Swap disks and flash screen, jmp (a0)
		PL_P	$200,_LoaderMok
		PL_P	$500,_DecrunchMok	;IMP! decruncher with destination in a4 not a1
		PL_R	$1000			;Detect expansion memory
		PL_END

_GameCrack	movem.l	d0-d1/a0-a1,-(sp)

		bsr	_SetDisk1		;Switch to disk 1 (we are on disk 0)
		bsr	_CheckCheats
		bsr	_LoadHighScores

		lea	_PL_Common(pc),a0	;Patch stuff in all versions
		move.l	_ExpansionMem(pc),a1
		bsr	_Patch

		lea	_PL_GameClassic(pc),a0	;Patch stuff specific to the
		bsr	_Patch			;Classic crack

		movem.l	(sp)+,d0-d1/a0-a1
		jmp	(a0)

_PL_GameClassic	PL_START
		PL_PS	$12a54,_SetDisk1_d118	;move.l #$18,d1
		PL_PS	$12b06,_SetDisk2_d118	;move.l #$18,d1
		PL_P	$16ea6,_Decruncher	;Decruncher
		PL_P	$17c86,_LoaderMok
		PL_END
		ENDC

;======================================================================

_LoaderMok	movem.l	d1/a0-a2,-(sp)

		move.l	d5,d0			;d0 = Offset
		move.l	d6,d1			;d1 = Length
		move.l	d4,d2			;d2 = Disk
		move.b	_DiskNumber(pc),d2	;d2 = Disk
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		movem.l	(sp)+,d1/a0-a2
		moveq	#0,d0			;d0 = 0 if everything was OK
		rts

;======================================================================

_DecrunchMok	move.l	a4,a1			;a1 = Destination

		movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_Decrunch(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Patch		movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

_FlushCache	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================
_resload	dc.l	0			;Resident loader
_ExpansionMem	dc.l	0			
_Tags		dc.l	WHDLTAG_CUSTOM1_GET
_Custom1	dc.l	0			;Cheat mode
		dc.l	WHDLTAG_CUSTOM2_GET
_Custom2	dc.l	0			;Starting level
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
