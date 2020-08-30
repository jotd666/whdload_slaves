;*---------------------------------------------------------------------------
;  :Program.	Silkworm.asm
;  :Contents.	Slave for "Silkworm" from The Sales Curve And Jaleco
;  :Author.	Keith Krellwitz (Abaddon) & JOTD
;  :History.	JST Versions (1998-2000) by Abaddon/JOTD
;		   - Two versions supported (Thanks to Stepan Chladek for the 2nd version)
;		   - Saving of the high scores to HD on game exit (JST) or at once (WHDLoad)
;		   - User can RNC crunch files
;		   - System friendly imager
;		   - Added BUTTONWAIT tooltype support (for those people who want
;		     to see the screen with the helmet)
;		   - Possible to quit by pressing F10 (JST) or QUITKEY (WHDLoad)
;		   - Jeff: Iconify/Snapshot added (JST only)
;		     of level 1 (at least for one version).
;		   - Jeff: ripped/reworked a nice OS3.5 icon
;		    (I took the title at full scale, no resize, I personaly think it's great :))
;
;		Version 1.1 (2001) by JOTD
;		   - WHDLoad conversion
;  		   - Access fault removed, which caused the game to crash in the middle
;		Version 1.2 (12.05.03) by JOTD
;		   - empty dbf loops fixed
;		   - keyboard fixed
;		   - hiscores fixed
;		Version 1.3 (08.17.2011) by Abaddon
;		   - Complete re-write of the slave using Patchlists
;		   - Removed dependency on the incbin for the loader
;		   - Added support for third version (Supplied by Irek´72)
;		   - Load & Save scores now working correctly.
;		   - Fixed high score display when game completed.  The 100,000
;		     for completing the game was added after the display high
;		     was set.
;		   - Removed 2 empty dbf loop patches as they were in the disk routines
;		   - Custom1=1 - Enable Programmers Cheat
;		   - Custom2=1 - Invincibility
;		   - Custom3=1 - Enable jeep arcade-like controls (blue button jumps)
;		 	Red 				- Fire
;		 	Play 				- Pause 
;		 	Play+Forward+Reverse 		- Quit (Port 2 only)
;		 	Yellow+Forward+Reverse		- Abort Game (Port 2 only)
;
;		     Title Screen
;		 	Play 				- Enter Options Screen 
;
;		     Options Screen
;			Reverse (Port 2)		- F1
;			Forward (Port 2)		- F2
;			Reverse (Port 1)		- F6
;			Forward (Port 1)		- F7
;
;		Version 1.4 (26/02/2018) by JOTD:
;		    - jeep player controls defaults to joystick in port 1 instead of keyboard (unless CUSTOM4 is set)
;		    - adapted to WHDLoad v17 (dynamic options on splash screen, rewritten patchlists with conditionals)
;		    - fixed "bug" which prevented to crunch files with Propack or such (resload_LoadFile => resload_LoadFileDecrunch)
;		    - if invincibility cheat mode is enabled, high scores aren't saved anymore

 
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly
;---------------------------------------------------------------------------*


        INCDIR  Include:
        INCLUDE whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
        OUTPUT  Silkworm.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimizer warnings
	SUPER
	ENDC

BUTTON_WAIT	MACRO

		movem.l	d0/a0,-(a7)
		lea	(_custom),a0
.down\@		bsr	.wait\@
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
;		btst	#POTGOB_DATLY-8,(potinp,a0)		;RMB
;		beq	.up\@
		move.l	joy1_buttons(pc),d0
		btst	#JPB_BTN_RED,d0				;CD32 Fire
		bne	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		bne	.down\@
.up\@		bsr	.wait\@					;entprellen
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
;		btst	#POTGOB_DATLY-8,(potinp,a0)		;RMB
;		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		beq	.up\@
		bsr	.wait\@					;entprellen
		bra	.done\@
.wait\@		waitvb	a0
		rts
.done\@		movem.l	(a7)+,d0/a0
		ENDM
		
;======================================================================

base
		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_NoKbd ;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-base		;ws_GameLoader
                dc.w    _dir-base	       	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	$58			;ws_keydebug = F9
_keyexit	dc.b	$5d			;ws_keyexit = *
_expmem		dc.l    0			;ws_ExpMem
		dc.w    _name-base		;ws_name
		dc.w    _copy-base		;ws_copy
		dc.w    _info-base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-base		;ws_config
_config
		dc.b	"BW;"
		dc.b	"C1:B:Enable coders in-game cheat keys;"
		dc.b	"C2:B:Invincibility;"
		dc.b	"C3:B:2nd/blue makes jeep jump (arcade controls);"
		dc.b	"C4:B:Leave keyboard controls for jeep;"
		dc.b	0
		even
;======================================================================
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
	
DECL_VERSION:MACRO
		dc.b	"1.5"
			IFD BARFLY
		dc.b	" "
			INCBIN	"T:date"
			ENDC
			ENDM


_name		dc.b	"Silkworm",0
_copy		dc.b	"1988 The Sales Curve And Jaleco",0
_info		dc.b	"Installed by Keith Krellwitz (Abaddon) & JOTD",10
		dc.b	"Version "
                DECL_VERSION
                dc.b    -1,"Three Versions Supported"
		dc.b	0
		EVEN

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
_dir            dc.b    "data",0
_trainer	dc.b    $5f
                EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================


		lea     	_resload(pc),a1
		move.l  	a0,(a1)				;save for later use

		lea     	_Tags(pc),a0
		move.l  	_resload(pc),a2
		jsr    		resload_Control(a2)

		move.w  	#$7fff,$dff09a
		move.w  	#$7fff,$dff09c
		move.w  	#$7fff,$dff096
		
		lea		$7FFF0,sp
		bsr	_detect_controller_types
		
		lea		$2da,a1					; Copy copper list to chipmem
		lea		_copperlist(pc),a0
		moveq		#60,d0
		bsr		_CopyMem

		lea		($dff000),a0				; Setup copper
		lea		$2da,a1
		move.l		a1,($80,a0)
		clr.w		($88,a0)
		lea		($180,a0),a1
		moveq		#15,d0
.1		move.w		#$20,(a1)+
		dbf		d0,.1
		
		lea		$20000,a1				; Load Intro picture (Helmet)
		lea		_filename(pc),a0
		move.l          (_resload,pc),a2
		jsr     	(resload_LoadFileDecrunch,a2)
		
		movem.l		($27d00),d0-d7				; Display picture
		movem.l		d0-d7,($dff180)
		move.w		#$8380,$dff096
		move.l  	_ButtonWait(pc),d0          		; Wait for button press if BUTTONWAIT  tooltype set
		beq     	.nodelay
		waitbutton
.nodelay
		move.w		#$7fff,$dff096

		lea		$3FFE0,a1				; Load Program
		lea		_filename(pc),a0
		move.w		#$3031,(a0)		; 01.slk
		move.l          (_resload,pc),a2
		jsr     	(resload_LoadFileDecrunch,a2)
		cmpi.l		#$007c0700,$68488			; Version 1 - IPF 388
		beq		_PatchMain_V1
		cmpi.l		#$08e80006,$6b054			; Version 2 - IPF 2413
		beq		_PatchMain_V2
		cmpi.l		#$08e80006,$6b052			; Version 3 - Non IPF version 3
		beq		_PatchMain_V3
		bra		_wrongver

;======================================================================
;Version 1 - IPF 388
;======================================================================

_PatchMain_V1
		bsr		_LoadScores_V1
		lea		control_type_offset(pc),a0
		move.l	#$7D3E,(a0)
		
		lea		_PL_MAIN_V1(pc),a0			; Main Patch List
		bsr		_Patch

		jmp		$68488


_PatchPGMCheat
		movem.l		D0-D7/A0-A6,-(sp)
		move.l  	_Custom1(pc),d0
		beq     	.nopgmtrainer
		;lea		_PL_PGM_CHEAT_V1(pc),a0			; Cheat Patch List
		;bsr		_Patch
		jsr		$68794
.nopgmtrainer
		movem.l		(sp)+,D0-D7/A0-A6
		jsr		$715c0
		rts
		
		
;======================================================================
;Version 2 - IPF 2413
;======================================================================

_PatchMain_V2
		bsr		_LoadScores_V2
		lea		_PL_MAIN_V2(pc),a0			; Main Patch List
		bsr		_Patch
		jmp		$68408

;======================================================================
;Version 3 - Non IPF version 3
;======================================================================

_PatchMain_V3
		bsr		_LoadScores_V2
		lea		_PL_MAIN_V3(pc),a0			; Main Patch List
		bsr		_Patch
		jmp		$68408


;======================================================================
;Empty DBF patches
;======================================================================

emudbf_d0
		swap		D0
		clr.w		D0
		swap		D0
		divu.w		#$28,D0
		swap		D0
		clr.w		D0
		swap		D0
		bsr		_BeamDelay
		rts

;======================================================================
;Patchlists
;======================================================================

_PL_MAIN_V1
		PL_START
		PL_W		$6aef2,0		; Set correct protection check value
		PL_W		$6ef7c,$6630		; Skip protection check
		PL_PS		$6b194,_PatchQuit
		PL_W		$6b94c,$6012
		PL_W		$6acba,$6016		; bypass disk access
		PL_R		$6b9b6
		PL_NOP		$6E7B6,8		; JFF: fix access fault - changed to nop
		PL_L		$719AC,$4EB80010	; dbf	d0 - JFF
		PL_P		$10,emudbf_d0		; dbf	d0 - JFF
		PL_P		$6b9f6,_Offset		; Correct the disk offset to load correct file
		PL_P		$6ba58,_LoadFiles_V1
		PL_PS		$684a0,_PatchPGMCheat
		PL_IFC4
		PL_ELSE
		PL_W		$684E2,0			; default: second player (jeep) : joystick 1
		PL_ENDIF
		PL_IFC2
		PL_R		$6f556			:invincibility
		PL_ELSE
		PL_P		$16,_SaveScores_V1	; Patch Saving of scores to HD
		PL_L		$68b6a,$4EB80016	; Patch Saving of scores to HD
		PL_ENDIF
		;PL_IFC3
 		PL_PS		$6afa0,_CD32_Read
 		PL_PS		$6afcc,_CD32_Fire
 		PL_B		$6afd2,$67
 		PL_PS		$6960c,_CD32_Pause_V1
 		PL_PS		$688e4,_CD32_Abort_V1
 		PL_PS		$68bde,_CD32_Abort_V1
 		PL_PS		$68dce,_CD32_Abort_V1
 		PL_PS		$6b0c4,_CD32_Abort_V1
 		PL_PSS		$68e18,_CD32_Options,2
 		PL_PS		$68db8,_CD32_OptionScreen
		;PL_ENDIF
		PL_IFC3
		PL_PSS	$6F392,jeep_jump_test,6
		PL_ENDIF
		PL_END

_PL_MAIN_V2	PL_START
		PL_IFC1
		PL_NOP		$6852c,2		;Enable programmers cheat
		PL_ENDIF
		PL_PS		$6b054,_PatchQuit
		PL_P		$6b8b6,_Offset		; Correct the disk offset to load correct file
		PL_W		$6b80c,$6012
		PL_NOP		$6E676,8		; JFF: fix access fault - changed to nop
		PL_L		$7186C,$4EB80010	; dbf	d0 - JFF
		PL_P		$10,emudbf_d0		; dbf	d0 - JFF
		PL_P		$6ab7a,_ProtectionCheck
		PL_R		$6b876
		PL_P		$6b918,_LoadFiles_V2
		PL_IFC2
		PL_R		$6f416			:invincibility
		PL_ELSE
		; don't save highscores if cheat enabled
		PL_P		$16,_SaveScores_V2	; Patch Saving of scores to HD
		PL_L		$68a22,$4EB80016
		PL_ENDIF
		;PL_IFC3
 		PL_PS		$6ae60,_CD32_Read
 		PL_PS		$6ae8c,_CD32_Fire
 		PL_B		$6ae92,$67
		PL_PS		$694c4,_CD32_Pause_V2
		PL_PS		$687ea,_CD32_Abort_V2
		PL_PS		$68a96,_CD32_Abort_V2
		PL_PS		$68c86,_CD32_Abort_V2
		PL_PS		$6af84,_CD32_Abort_V2
 		PL_PSS		$68cd0,_CD32_Options,2
 		PL_PS		$68c70,_CD32_OptionScreen
		;PL_ENDIF
		PL_IFC3
		PL_PSS	$6F252,jeep_jump_test,6
		PL_ENDIF

		PL_IFC4
		PL_ELSE
		PL_W		$68462,0
		PL_ENDIF
		PL_END

_PL_MAIN_V3	PL_START
		PL_IFC1
		PL_NOP		$6852c,2		;Enable programmers cheat
		PL_ENDIF
		PL_IFC2
		PL_R		$6f40c			:invincibility
		PL_ELSE
		PL_P		$16,_SaveScores_V2	; Patch Saving of scores to HD
		PL_L		$68a22,$4EB80016	; Patch Saving of scores to HD
		PL_ENDIF
		PL_IFC3
		PL_PS		$6ae5e,_CD32_Read
		PL_PS		$6ae8a,_CD32_Fire
		PL_B		$6ae90,$67
		PL_PS		$694c4,_CD32_Pause_V2
		PL_PS		$687ea,_CD32_Abort_V2
		PL_PS		$68a96,_CD32_Abort_V2
		PL_PS		$68c86,_CD32_Abort_V2
		PL_PS		$6af82,_CD32_Abort_V2
 		PL_PSS		$68cd0,_CD32_Options,2
 		PL_PS		$68c70,_CD32_OptionScreen
		PL_ENDIF
		PL_PS		$6b052,_PatchQuit
		PL_P		$6b8b4,_Offset		; Correct the disk offset to load correct file
		PL_W		$6b80a,$6012
		PL_NOP		$6E66c,8		; JFF: fix access fault - changed to nop
		PL_L		$71862,$4EB80010	; dbf	d0 - JFF
		PL_P		$10,emudbf_d0		; dbf	d0 - JFF
		PL_P		$6ab7a,_ProtectionCheck
		PL_R		$6b874
		PL_P		$6b916,_LoadFiles_V2
		PL_IFC3
		PL_PSS	$6F248,jeep_jump_test,6
		PL_ENDIF

		PL_IFC4
		PL_ELSE
		PL_W		$68462,0	
		PL_ENDIF

		PL_END

 
;======================================================================
;Protection (Version 2 & 3)
;======================================================================

_ProtectionCheck
		move.b		#$0,$6ab6e
		jmp		$6ab92

;======================================================================
;Beam Delay
;======================================================================

_BeamDelay
		move.w  	d1,-(a7)
.1        	move.b		$dff006,d1	; VPOS
.2		cmp.b		$dff006,d1
		beq.s		.2
		dbf		d0,.1
		move.w		(a7)+,d1
		rts
		
;======================================================================
;Patch Quit 
;======================================================================

_PatchQuit
		movem.l		d0,-(a7)
		not.b		d0
		ror.b		#$1,d0
		cmp.b   	_keyexit(pc),d0                     
		beq     	_exit
		movem.l		(a7)+,d0
		bset		#$6,$e01(a0)
		rts

;======================================================================
;Load/Save Routines
;======================================================================

_LoadFiles_V1
		movem.l		D0-D7/A0-A6,-(sp)
		lea		$18e4,a1
		bra		_Load
		
_LoadFiles_V2
		movem.l		D0-D7/A0-A6,-(sp)
		lea		$18de,a1
		bra		_Load

_Load
		lea		_filename(pc),a0
		bsr		_ConvertByteToASCII
		move.w		d3,(a0)
		move.l		#$0,d0
		move.l		#-1,d1
		move.l          (_resload,pc),a2
		jsr     	(resload_LoadFileDecrunch,a2)
		movem.l		(sp)+,D0-D7/A0-A6
		rts

        
;======================================================================
;Load/Save High Score Routines
;======================================================================

_SaveScores_V1
		jsr		$68f26
		movem.l		D0-D7/A0-A6,-(sp)
		lea		$692f4,a5
		lea		$2b2,a3				; Heli top score
		lea		$324,a4				; Jeep top score
		bsr		_SaveScores
		movem.l		(sp)+,D0-D7/A0-A6
		rts

_LoadScores_V1
		lea		$692f4,a4			; Hex value of scores
		lea		$684e8,a3			; Hex value for default top score
		bra		_LoadScores

_SaveScores_V2
		jsr		$68dde
		movem.l		D0-D7/A0-A6,-(sp)
		lea		$691ac,a5
		lea		$2ac,a3				; Heli top score
		lea		$31e,a4				; Jeep top score
		bsr		_SaveScores
		movem.l		(sp)+,D0-D7/A0-A6
		rts

_LoadScores_V2
		lea		$691ac,a4			; Hex value of scores
		lea		$68468,a3			; Hex value for default top score
		bra		_LoadScores
	
_SaveScores
		lea		_scorebuffer(pc),a1
		move.l		#$1ae,d0			; size
		lea		$67e29,a0
		bsr		_CopyMem
		lea		_scorebuffer(pc),a1
		adda.l		#$1ae,a1
		movea.l		a5,a0
		move.l		#20,d0				; size
		bsr		_CopyMem
		lea		_scorebuffer(pc),a1
		lea		_high(pc),a0
		move.l		#$1c2,d0
		move.l          (_resload,pc),a2
		jsr     	(resload_SaveFile,a2)
		move.w		(a5),(a3)			; Set Heli Top Score
		move.w		($a,a5),(a4)			; Set Tank Top Score
		rts

_LoadScores
		lea     	_high(pc),a0
		move.l  	(_resload,pc),a2
		jsr     	(resload_GetFileSize,a2)
		tst.l	  	d0
		beq	  	.noload
		lea		_scorebuffer(pc),a1
		lea		_high(pc),a0
		move.l          (_resload,pc),a2
		jsr     	(resload_LoadFileDecrunch,a2)
		lea		_scorebuffer(pc),a0
		lea		$67e29,a1
		move.l		#$1ae,d0			; size
		bsr		_CopyMem
		lea		_scorebuffer(pc),a0
		adda.l		#$1ae,a0
		movea.l		a4,a1
		move.l		#20,d0				; size
		bsr		_CopyMem
		move.w		(a4),(a3)			; Set Heli Top Score
		adda.l		#6,a3
		move.w		($a,a4),(a3)			; Set Tank Top Score
.noload		rts


;======================================================================
;Common Routines
;======================================================================

_Offset							; Returns the correct disk offset that corresponds
		move.l		d0,d1			; to the first 2 digits of the data files
		rts

_Patch
		sub.l		a1,a1
		move.l		_resload(pc),a2
		jsr		resload_Patch(a2)
		rts


_ConvertByteToASCII                             	;converts a byte in D0 to ascii and
		move.b  	d1,d4                   ;stores the word result in d3
		lsr             #4,d1                   ;1a in D0 would be $3141 in d3
		bsr             .convert                ;useful for savenames and loadnames
		move.b  	d1,d3
		mulu            #$100,d3
		move.b  	d4,d1
		bsr             .convert
		move.b  	d1,d3
		rts
.convert
		and.b   	#$f,d1
		addi.b  	#$30,d1
		cmpi.b  	#$3a,d1
		bcs             .done
		addi.b  	#$7,d1
.done
	        rts


_CopyMem
		subi.l		#$1,d0
.1		move.b		(a0)+,(a1)+
		dbf		d0,.1
		rts

;======================================================================
;CD32 Support
;======================================================================
IGNORE_JOY_DIRECTIONS
		include ReadJoypad.s

_CD32_Read	movem.l		d0,-(A7)
		bsr		_read_joysticks_buttons
		bsr		_CD32_Quit
		movem.l		(a7)+,d0
		move.w		($dff00a),d0	; second joystick
		rts							

_CD32_Quit	
		move.l		joy1_buttons(pc),d0
		btst		#JPB_BTN_REVERSE,d0
		beq		.exit
		btst		#JPB_BTN_FORWARD,d0
		beq		.exit
		btst		#JPB_BTN_PLAY,d0
		bne		_exit
.exit		rts

_CD32_Fire
		movem.l		d0,-(sp)
		move.l		joy1_buttons(pc),d0
		cmpi.b		#$6,d2
		bne		.joy1
		move.l		joy0_buttons(pc),d0
.joy1
		btst		#JPB_BTN_RED,d0
		movem.l		(sp)+,d0
		rts

_CD32_Pause_V1	movem.l         a5,-(sp)
		lea		(-$7ea0,a6),a5
		bsr		_CD32_Pause
		movem.l         (sp)+,a5
		rts
_CD32_Pause_V2	movem.l         a5,-(sp)
		lea		(-$7ea6,a6),a5
		bsr		_CD32_Pause
		movem.l         (sp)+,a5
		rts
		
_CD32_Pause
		movem.l         d1-d3/A0,-(sp)
		moveq		#$19,d3
		move.l		#JPB_BTN_PLAY,d1
		move.l		joy1_buttons(pc),d2
		lea		_held_button_p1(pc),a0
		bsr		_CD32_CommonButton
		move.l		joy0_buttons(pc),d2
		lea		_held_button_p2(pc),a0
		bsr		_CD32_CommonButton
.done		movem.l         (sp)+,d1-d3/A0
		cmpi.w		#$19,(a5)
		rts

_CD32_CommonButton
		btst.l		d1,d2
		beq		.NotPressed
		btst.l		d1,(a0)
		bne		.done
		bset.l		d1,(a0)
		move.w		d3,(a5)
		bra		.done
.NotPressed
		bclr		d1,(a0)

.done		rts


_CD32_Abort_V1	movem.l         a5,-(sp)
		lea		(-$7ea0,a6),a5			;Address of stored rawkey
		bsr		_CD32_Abort
		movem.l         (sp)+,a5
		rts

_CD32_Abort_V2	movem.l         a5,-(sp)
		lea		(-$7ea6,a6),a5			;Address of stored rawkey
		bsr		_CD32_Abort
		movem.l         (sp)+,a5
		rts

_CD32_Abort
		movem.l         d1/A0,-(sp)
		move.l		joy1_buttons(pc),d1
		btst		#JPB_BTN_REVERSE,d1
		beq		.CheckKey
		btst		#JPB_BTN_FORWARD,d1
		beq		.CheckKey
		btst		#JPB_BTN_YEL,d1
		beq		.CheckKey
		move.w		#$45,(a5)
		bra		.exit
.CheckKey	cmpi.w		#$45,(a5)
.exit		movem.l         (sp)+,d1/A0
		rts


_CD32_OptionScreen
		cmp.b		#$50,d0
		blt		.cd32
		cmp.b		#$59,d0
		ble		.done
.cd32
		movem.l         d1-d4/a0-a1,-(sp)
		lea		_held_button_p1(pc),a1
		move.l		joy1_buttons(pc),d1
		move.l		#JPB_BTN_PLAY,d2
		moveq		#$50,d3
		bsr		_CD32_Common_Held
		tst.b		d0
		bne		.done
		move.b		#$60,d0
		movem.l         (sp)+,d1-d4/a0-a1
.done		
		rts
		
_CD32_Options	bclr		#7,d0
		movem.l         d1-d4/a0-a1,-(sp)
		move.l		d0,d4
.cd32		lea		_held_button_p1(pc),a1
		move.l		joy1_buttons(pc),d1
		move.l		#JPB_BTN_REVERSE,d2
		moveq		#$50,d3
		bsr		_CD32_Common_Held
		tst.b		d0
		bne		.done
		move.l		#JPB_BTN_FORWARD,d2
		moveq		#$51,d3
		bsr		_CD32_Common_Held
		tst.b		d0
		bne		.done
		lea		_held_button_p2(pc),a1
		move.l		joy0_buttons(pc),d1
		move.l		#JPB_BTN_REVERSE,d2
		moveq		#$55,d3
		bsr		_CD32_Common_Held
		tst.b		d0
		bne		.done
		move.l		#JPB_BTN_FORWARD,d2
		moveq		#$56,d3
		bsr		_CD32_Common_Held
		tst.b		d0
		bne		.done
		move.l		d4,d0
.done
		movem.l         (sp)+,d1-d4/a0-a1
		cmp.b		#$50,d0
		rts
		
_CD32_Common_Held						;Used for Pause button
		btst.l		d2,d1
		beq		.NotPressed
		btst.l		d2,(a1)
		bne		.clrkey
		bset.l		d2,(a1)
		move.b		d3,d0
		bra		.exit
.NotPressed	bclr		d2,(a1)
.clrkey		moveq		#0,d0
.exit		rts

jeep_jump_test
	movem.l	d1/a6,-(a7)
	sub.l	control_type_offset(pc),a6
	move.l	joy0_buttons(pc),d1
	tst.w	(a6)
	beq.b	.jeep_port_0
	move.l	joy1_buttons(pc),d1		; read from port 1
.jeep_port_0
	btst	#JPB_BTN_BLU,d1	; blue triggers jump
	movem.l	(a7)+,d1/a6
	beq.b	.nojump
	bset	#0,d0
	rts
.nojump
	add.l	#$A6-$98,(a7)
	rts
	
	
;======================================================================


_filename
		dc.b    "00.slk",0
		even
_high
		dc.b    "Silkworm.high",0
		even

_held_button_p1	dc.l	0
		even
		
_held_button_p2	dc.l	0
		even

_scorebuffer
		dc.b	'ZERO'
		ds.b	$1C2,0


_resload	dc.l	0
_Tags           dc.l    WHDLTAG_CUSTOM1_GET
_Custom1	dc.l    0
		dc.l    WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l    0
                dc.l    TAG_DONE

control_type_offset
	dc.l	$7D44
	
;======================================================================

_exit     
		pea     	TDREASON_OK
		bra		_end
_debug		pea		TDREASON_DEBUG
		bra		_end
_wrongver	pea		TDREASON_WRONGVER
_end		move.l		(_resload,pc),-(a7)
		add.l		#resload_Abort,(a7)
		rts

_copperlist	dc.l	$1004200
		dc.l	$1020000
		dc.l	$920038
		dc.l	$9400D0
		dc.l	$8E2C81
		dc.l	$90F4C1
		dc.l	$E00002
		dc.l	$E20000
		dc.l	$E40002
		dc.l	$E61F40
		dc.l	$E80002
		dc.l	$EA3E80
		dc.l	$EC0002
		dc.l	$EE5DC0
		dc.l	$FFFFFFFE

;======================================================================

	END