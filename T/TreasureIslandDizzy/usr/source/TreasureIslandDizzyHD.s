;*---------------------------------------------------------------------------
; Program:	TreasureIslandDizzy.s
; Contents:	Slave for "Treasure Island Dizzy" (c) 1989 Codemasters
; Author:	Codetapper of Action
; History:	17.02.01 - v1.0
;		         - Full load from HD
;		         - 2 versions supported
;		         - RNC copylock bypassed
;		         - Decruncher relocated to fast memory
;		         - Fixed CIA register accesses ($bfe0ff->$bfe001 and 2x$bfe2ff->$bfe201)
;		         - RomIcon, NewIcon and GlowIcon (created by me!)
;		         - Quit option (default key is 'F10')
;		01.04.02 - v1.1
;		         - Supports another version
;		         - Instructions included
;		         - NewIcon replaced with extended newicon (120x96)
;		20.12.11 - v1.2
;		         - Also supports the disk with "Version 2" written on it (thanks Irek!)
;		         - Set CUSTOM3=1 to enable CD32 joypad controller:
;		                 Red                  - Fire
;		                 Blue                 - Jump
;		                 Play                 - Pause 
;		                 Play+Forward+Reverse - Quit
;		20.12.11 - v1.3
;		         - Set CUSTOM2=1 to enable CD32 joypad controller
;                - support for non-CD32 2 button joysticks
;                - when jump with button is set, up does nothing
; Requires:	WHDLoad 17+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Cheat Info:	During play, type any of the following:
;		
;		        "ICANFLY"_____________________Lets you fly.
;		        "EGGSONLEGS"_________________Invincibility.
;		        "EGGONASPRING"___________________High jump.
;		
;		Hold down 'S', 'P', 'A', 'C', and 'SPACE KEY'.  Now press 'C' to
;		disappear (space makes you reappear).  When you have disappeared, 'M'
;		key moves the map around.
;		
;		Here are some objects, and where to use them:
;		
;		        CHEST                     - Below the cliff
;		        SNORKEL                   - In the water
;		        GRAVEDIGGER SPADE         - In the grave on island 2
;		        MAGIC STONE               - Totem pole (island 2)
;		        DETONATOR AND DYNAMITE    - Mine (island 1)
;		        AXE & BIBLE               - Bridge (island 1)
;		        POGO STICK                - Pogo place on ship
;		        GOLD COINS                - The shop
;		        FIRE PROOF SUIT           - Smuggler's cave (island 2)
;		        BRANDY                    - Shop
;		        GOLD EGG                  - Shop
;		        BRASS KEY                 - Smuggler's cave
;		        CROWBAR                   - Rock in water
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"TreasureIslandDizzy.slave"
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
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_data-_base			;ws_CurrentDir
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
_data:
        dc.b    "data",0
_name		dc.b	"Treasure Island Dizzy",0
_copy		dc.b	"1989 Codemasters",0
_info		dc.b	"Installed by Codetapper/Action!",10
            dc.b    "Joypad fixes by JOTD",10,10
		dc.b	"Version "
        DECL_VERSION
        
		dc.b	-1,"Thanks to Mad-Matt, Chris Vella, Irek Kloska"
		dc.b	10,"and Marcus Naylor for sending the originals!",0
_config
    dc.b	"C2:B:Enable CD32 joypad controller;"
	dc.b	0
_MainFile	dc.b	"TI"
_MainFileV2	dc.b	"DIZZY.DAT",0
_MainFileV3	dc.b	"treasure",0
_MainFileV4	dc.b	"TID",0
		EVEN

;======================================================================
_Start						;a0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart
		lea	_MainFileV4(pc),a0	;Allow for multiple names
		bsr	_GetFileSize
		bne	_LoadMainFile

		lea	_MainFileV3(pc),a0
		bsr	_GetFileSize
		bne	_LoadMainFile

		lea	_MainFileV2(pc),a0
		bsr	_GetFileSize
		bne	_LoadMainFile

		lea	_MainFile(pc),a0

_LoadMainFile	lea	$400,a1			;Load game
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)

		cmp.l	#$4ef90000,$400		;Check for decrunched
		beq	_CrackedGame		;or cracked version

		cmp.l	#$5453791e,$bfa		;Check for copylocked
		bne	.NotCopylock		;version
		bsr	_DecryptRNC

.NotCopylock	lea	$400,a0			;Search address
		move.l	#$72863c21,d1		;Start of data

		cmp.l	(a0),d1			;Original crunched file
		beq	_DecrunchGame		;in the right location

_FindData	cmp.l	(a0),d1
		beq	_RelocateTo400
		addq	#2,a0
		cmp.l	#$10000,a0
		bne	_FindData
		bra	_wrongver

_RelocateTo400	lea	$400,a1			;Relocate game to $400
		move.l	#($256b0>>2),d0
.Relocate	move.l	(a0)+,(a1)+
		dbf	d0,.Relocate

_DecrunchGame	bsr	_DecrunchDizzy		;Decrunch game

_CrackedGame	
        lea	_PL_Game(pc),a0		;Patch game
		bsr	_Patch

        moveq	#0,d0			;Disable caches
		move.l	#CACRF_EnableI|CACRF_EnableD,d1
		jsr	resload_SetCACR(a2)

		suba.l	a0,a0			
		suba.l	a1,a1
		suba.l	a2,a2
		suba.l	a3,a3
		suba.l	a4,a4
		suba.l	a5,a5
		suba.l	a6,a6
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
        
        bsr _detect_controller_types
		jmp	($400).w		;Start game

_PL_Game	PL_START
		PL_PS	$b72,_Keybd		;Detect quit key
		PL_L	$4060,$bfe201		;move.b ($bfe2ff).l,d0->$bfe201
		PL_L	$406a,$bfe201		;move.b d0,($bfe2ff).l,d0->$bfe201
        PL_IFC2
        PL_S    $406e,$82-$6e       ; skip fire read completely
		PL_PS	$4082,_CD32_Read	;move.w ($dff00c),d0
		PL_P	$4e02,_CD32_WaitUnpause	;cmpi.b #1,d0 and bne.w $4e2c (rts)
        PL_ELSE
   		PL_L	$4070,$bfe001		;$bfe0ff->$bfe001
        PL_ENDIF
		PL_END

;======================================================================

_DecryptRNC	move.l	#$a3ef1306,d0
		moveq	#0,d1
		move.l	#$f06535df,d2
		move.l	#$a46b0000,d3
		move.l	#$8972ff7a,d4
		move.l	#$00000801,d5

		lea	$d40,a0
		move.l	#$2583c,d6
.Decrypt	rol.l	d0,d1
		add.l	d1,d2
		ror.l	d2,d3
		add.l	d3,d4
		ror.l	d4,d5
		add.l	d5,d0
		add.l	d0,(a0)+
		subq.l	#4,d6
		bne.b	.Decrypt
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

_Keybd		not.b	d0			;Stolen code
		ror.b	#1,d0
		move.w	d0,d1

		cmp.b	_keyexit(pc),d0
		beq	_exit
		rts

;======================================================================

_DecrunchDizzy	lea	($25ab0).l,a0
		lea	($400).w,a1
		movea.l	-(a0),a2
		adda.l	a1,a2
		move.l	-(a0),d0
_Dizzy_2	moveq	#3,d1
		bsr.b	_Dizzy_4
		tst.b	d2
		beq.b	_Dizzy_11
		cmpi.w	#7,d2
		bne.b	_Dizzy_7
		lsr.l	#1,d0
		bne.b	_Dizzy_3
		bsr.w	_Dizzy_22
_Dizzy_3	bcc.b	_Dizzy_6
		moveq	#10,d1
		bsr.b	_Dizzy_4
		tst.w	d2
		bne.b	_Dizzy_7
		moveq	#$12,d1
		bsr.b	_Dizzy_4
		bra.b	_Dizzy_7

_Dizzy_4	subq.w	#1,d1
		moveq	#0,d2
_Dizzy_5	lsr.l	#1,d0
		beq.w	_Dizzy_23
		roxl.l	#1,d2
		dbra	d1,_Dizzy_5
		rts

_Dizzy_6	moveq	#4,d1
		bsr.b	_Dizzy_4
		addq.w	#7,d2
_Dizzy_7	subq.w	#1,d2
_Dizzy_8	moveq	#7,d1
_Dizzy_9	lsr.l	#1,d0
		beq.b	_Dizzy_10
		roxl.l	#1,d3
		dbra	d1,_Dizzy_9
		move.b	d3,-(a2)
		dbra	d2,_Dizzy_8
		bra.b	_Dizzy_11

_Dizzy_10	move.l	-(a0),d0
		move.w	#$10,ccr
		roxr.l	#1,d0
		roxl.l	#1,d3
		dbra	d1,_Dizzy_9
		move.b	d3,-(a2)
		dbra	d2,_Dizzy_8
_Dizzy_11	cmpa.l	a2,a1
		bge.b	_Dizzy_21
		moveq	#2,d1
		bsr.b	_Dizzy_4
		moveq	#2,d3
		moveq	#8,d1
		tst.w	d2
		beq.b	_Dizzy_19
		moveq	#4,d3
		cmpi.w	#2,d2
		beq.b	_Dizzy_16
		moveq	#3,d3
		cmpi.w	#1,d2
		beq.b	_Dizzy_14
		moveq	#2,d1
		bsr.b	_Dizzy_4
		cmpi.w	#3,d2
		beq.b	_Dizzy_13
		cmpi.w	#2,d2
		beq.b	_Dizzy_12
		addq.w	#5,d2
		move.w	d2,d3
		bra.b	_Dizzy_16

_Dizzy_12	moveq	#2,d1
		bsr.b	_Dizzy_4
		addq.w	#7,d2
		move.w	d2,d3
		bra.b	_Dizzy_16

_Dizzy_13	moveq	#8,d1
		bsr.w	_Dizzy_4
		move.w	d2,d3
		bra.b	_Dizzy_16

_Dizzy_14	moveq	#8,d1
		lsr.l	#1,d0
		bne.b	_Dizzy_15
		bsr.b	_Dizzy_22
_Dizzy_15	bcs.b	_Dizzy_19
		moveq	#14,d1
		bra.b	_Dizzy_19

_Dizzy_16	moveq	#$10,d1
		lsr.l	#1,d0
		bne.b	_Dizzy_17
		bsr.b	_Dizzy_22
_Dizzy_17	bcc.b	_Dizzy_19
		moveq	#8,d1
		lsr.l	#1,d0
		bne.b	_Dizzy_18
		bsr.b	_Dizzy_22
_Dizzy_18	bcs.b	_Dizzy_19
		moveq	#12,d1
_Dizzy_19	bsr.w	_Dizzy_4
		subq.w	#1,d3
_Dizzy_20	move.b	(-1,a2,d2.l),-(a2)
		dbra	d3,_Dizzy_20
		bra.w	_Dizzy_2

_Dizzy_21	moveq	#0,d0
		rts

_Dizzy_22	move.l	-(a0),d0
		move.w	#$10,ccr
		roxr.l	#1,d0
		rts

_Dizzy_23	move.l	-(a0),d0
		move.w	#$10,ccr
		roxr.l	#1,d0
		roxl.l	#1,d2
		dbra	d1,_Dizzy_5
		rts

;======================================================================

_GetFileSize	movem.l	d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		movem.l	(sp)+,d1/a0-a2
		tst.l	d0
		rts

_Patch		sub.l	a1,a1
		move.l	_resload(pc),a2
		jmp	resload_Patch(a2)

;======================================================================
; CD32 Support
;======================================================================

IGNORE_JOY_DIRECTIONS = 1
		include ReadJoypad.s

_CD32_Read	movem.l	d0-d7/a0-a6,-(sp)
		bsr	_joystick
		move.l	joy1(pc),d0
		bsr	_CD32_Quit
		bsr	_CD32_Fire
		bsr	_CD32_Jump
		bsr	_CD32_Pause
		movem.l	(sp)+,d0-d7/a0-a6
		move.w	($dff00c).l,d0
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
        bclr	#8,d0
        btst	#9,d0
        beq.b	.noneed
        bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed        
		rts

_CD32_Quit	btst	#JPB_BTN_REVERSE,d0
		beq	.notquit
		btst	#JPB_BTN_FORWARD,d0
		beq	.notquit
		btst	#JPB_BTN_PLAY,d0
		bne	_exit
.notquit	rts

_CD32_Fire	btst	#JPB_BTN_RED,d0
		beq	.notfire
		move.b	#$80,($786).w		;Fake pressing fire
.notfire	rts

_CD32_Jump	move.l	#JPB_BTN_BLU,d2
		btst.l	d2,d0
		beq	.notblue
		ori.b	#1,($786).w		;Fake pressing up
.notblue	rts

_CD32_Pause	lea	_held_button(pc),a0
		move.l	#JPB_BTN_PLAY,d2
		btst.l	d2,d0
		beq	.notpause
		btst.l	d2,(a0)
		bne	.held
		bset.l	d2,(a0)
		eor.b	#1,($789).w		;Toggle pause on/off
		rts
.notpause	bclr	d2,(a0)
.held		rts

_CD32_WaitUnpause
		cmpi.b	#1,d0
		bne	.notpause
		bsr	_CD32_Read		;To detect unpause key
		jmp	$4e0a.w			;(trashes d0 but no problem)
.notpause	rts

;======================================================================
_resload	dc.l	0			;Resident loader

_held_button	dc.l	0			;For CD32 pause
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
