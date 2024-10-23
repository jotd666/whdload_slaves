;*---------------------------------------------------------------------------
;  :Program.	Commando.asm
;  :Contents.	Slave for "Commando" from Elite
;  :Author.	Keith Krellwitz / Abaddon
;  :History.	09.19.2010 - V1.0 - Initial Release 
;		   Trainer Custom1=1 - Invincibiltiy
;		   Added 2nd fire button to select weapon
;		   Fixed 3x access fault
;		   Added 3x button waits
;		   Added delay on game over - press fire to continue
;		   Added 16x blitter waits
;
;		version 1.2 (03-04-2012) done by Keith Krellwitz (Abaddon):
;		 - Complete re-write (removed jst macros and implemented PATCHLIST)
;		 - 4 more blitter waits added
;		 - Custom4=1 Enable 2nd trainer - new invincibility and level skip
;		   press 'Help'
;		 - Fixed another access fault
;		 - Fixed 14x snoop bugs (long read from dff000)
;		 - Custom2=1 Disable blitter patches
;		 - Custom3=1 Enable CD32 support
;		 	Red 			- Fire
;		 	Play 			- Pause (press fire to unpause) 
;		 	Yellow			- Skip levels when cheat active 
;		 	Play+Forward+Reverse 	- Quit
;		 	Forward+Reverse+Green 	- Abort Game
;		 	Reverse+Green+Yellow	- Skip level (Custom4=1)
;		  
;		    On Title screen
;		     	Forward			- Maps to F2
;		     	Reverse			- Maps ro F1
;		   
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly
;
;B	-	ESC
;20	-	Space
;F	- 	R Alt
;E	- 	R Amiga
;964e - key store .b
;---------------------------------------------------------------------------*


        INCDIR  Include:
        INCLUDE whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
        OUTPUT  Commando.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimizer warnings
	SUPER
	ENDC

;======================================================================

base
		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	19			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem ;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-base		;ws_GameLoader
                dc.w    0		       	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	$58			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l    0			;ws_ExpMem
		dc.w    _name-base		;ws_name
		dc.w    _copy-base		;ws_copy
		dc.w    _info-base		;ws_info
        dc.w	0			;ws_kickname
        dc.l	0			;ws_kicksize
        dc.w	0			;ws_kickcrc
        dc.w	_config-base		;ws_config

;======================================================================


DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0


_name		dc.b	"Commando",0
_copy		dc.b	"1989 Elite",0
_info		dc.b	"Installed by Keith Krellwitz (Abaddon)",10
            dc.b    "Latest fixes & improvements by JOTD",10,10
                dc.b    "Version "
                DECL_VERSION
		dc.b	0
		EVEN

_config
    dc.b    "BW;"
    dc.b    "C1:X:Infinite Lives:0;"
    dc.b    "C1:X:Infinite Grenades:1;"
    dc.b    "C1:X:Invincibility:2;"
    dc.b    "C1:X:Level Skip:3;"
    dc.b    "C2:B:Blue/second button launches grenades;"
    dc.b    "C3:B:Disable Blitter Patches;"
    dc.b    0
    even

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea		_resload(pc),a1
		move.l		a0,(a1)				;save for later use
		move.l		a0,a2
		lea     	(_Tags,pc),a0
		jsr     	(resload_Control,a2)


		move.w		#$7fff,$dff096
		move.w		#$7fff,$dff09a
		move.w		#$7fff,$dff09c

		lea     	$5c40.w,a0
		moveq		#$1,d2
		move.l		#$8e800,d0
		move.l		#$400,d1
		move.l		(_resload,pc),a2
		jsr		(resload_DiskLoad,a2)

		lea		_PL_LOADER(pc),a0
		sub.l		a1,a1
		move.l		_resload(pc),a2
		jsr		resload_Patch(a2)

		jmp		$5c4c.w


_PatchIntro
		movem.l		a0-a2,-(sp)
		lea		_PL_INTRO(pc),a0
		bsr        	_Patch
		movem.l		(sp)+,a0-a2

		jmp		$6801c


_PatchMain
    
    movem.l		D0-D7/A0-A6,-(sp)
    lea		_PL_MAIN(pc),a0
    bsr        	_Patch


    movem.l		(sp)+,D0-D7/A0-A6

    bsr		_LoadHighScoreTable

    jmp		$1000.w

_Patch
    sub.l		a1,a1
    move.l		_resload(pc),a2
    jmp		resload_Patch(a2)


;======================================================================
;Patchlists
;======================================================================
 
_PL_LOADER
 		PL_START
 		PL_P	 	$5cfa,_LoadTracks
		PL_P 		$5cf4,_PatchIntro
		PL_R		$5ee6
		PL_END

_PL_INTRO
 		PL_START
 		PL_P	 	$684d8,_LoadTracks
		PL_P 		$681d4,_PatchMain
		PL_P 		$68172,_MemoryFix
		PL_R		$686c4
		PL_END

_PL_MAIN
 		PL_START
 		PL_P	 	$6a74,_LoadTracks2
		PL_P 		$9692,_FixKeyboard
		PL_P 		$9382,_MemoryFix2
		PL_R		$6c60
		PL_W		$97d6,$e201
		PL_NOP		$ad5c,6			;Remove long read from dff000
		PL_NOP		$acb4,6			;Remove long read from dff000
		PL_NOP		$9c10,6			;Remove long read from dff000
		PL_NOP		$9bf2,6			;Remove long read from dff000
		PL_NOP		$9bd4,6			;Remove long read from dff000
		PL_NOP		$98d0,6			;Remove long read from dff000
		PL_NOP		$1890,6			;Remove long read from dff000
		PL_NOP		$187a,6			;Remove long read from dff000
		PL_NOP		$1864,6			;Remove long read from dff000
		PL_NOP		$183a,6			;Remove long read from dff000
		PL_NOP		$12de,6			;Remove long read from dff000
		PL_NOP		$12c6,6			;Remove long read from dff000
		PL_NOP		$12ae,6			;Remove long read from dff000
		PL_NOP		$127e,6			;Remove long read from dff000
		PL_P		$3e8e,_AccessFault

        PL_IFC1X    0
 		PL_NOP		$a980,4      		;infinite lives
 		PL_NOP		$a988,4
 		PL_NOP		$a9a0,4
        PL_ENDIF
        PL_IFC1X    1
 		PL_B		$3f52,$4a            	;infinite grenades
        PL_ENDIF
        PL_IFC1X    2
 		PL_R		$273e			;Invincible
        PL_ENDIF
        PL_IFC1X    3
 		PL_PSS		$a8ca,_SkipLevelCheck,2
        PL_ENDIF

        PL_IFC3
 		PL_PSS	 	$9bc8,_WaitBlit1,2
 		PL_PSS	 	$9be6,_WaitBlit1,2
 		PL_PSS	 	$9c04,_WaitBlit1,2
 		PL_PSS	 	$9c22,_WaitBlit1,2
 		PL_PSS	 	$1858,_WaitBlit2,2
 		PL_PSS	 	$186e,_WaitBlit2,2
 		PL_PSS	 	$1884,_WaitBlit2,2
 		PL_PSS	 	$189a,_WaitBlit2,2
 		PL_PS		$12a4,_WaitBlit3
 		PL_PS		$12bc,_WaitBlit3
 		PL_PS		$12d4,_WaitBlit3
 		PL_P		$12ea,_WaitBlit4
        PL_ENDIF
        
        ; save hiscore unless trainer is on
 
        PL_IFC1
        PL_ELSE
		PL_PSS		$8364,_SaveHighScoreTable,4
        PL_ENDIF        

        ; CD32 controls
        
		PL_PS		$9798,_CD32_Read
		PL_PS		$97de,_CD32_Fire
		PL_PSS		$87ec,_CD32_Title,2
 		PL_PSS		$a8ca,_CD32_Skip,2
        PL_IFC2
        PL_PSS  $3F3A,_CD32_Blue,4
        PL_ENDIF
		        
		PL_END




;======================================================================
;Level Skip
;======================================================================

_SkipLevelCheck
		move.l		($a0b0),a2
		lea		$a8fa,a0
		move.l  	_level_skip(pc),d0
		bne     	.skip
		rts
.skip
		movem.l		a0,-(sp)
		lea		_level_skip(pc),a0
		move.l		#0,(a0)
		movem.l		(sp)+,a0
		jmp		$2084

;======================================================================
;Memory Fixes
;======================================================================

_MemoryFix
		moveq		#$0,d4
		jmp		$681ba

_MemoryFix2
		moveq		#$0,d0
		jmp		$9390

_AccessFault	move.l		(a2)+,d0
		cmpa.l		#$7a000,a0
		blt		.continue
		rts
.continue
		or.l		d0,($6000,a0)
		jmp		$3e94
		
		

;======================================================================
;Track Loaders
;======================================================================

_LoadTracks
		movem.l		D0-D7/A0-A6,-(sp)
        ; detect joypad type from time to time
        bsr _detect_controller_types
        
		move.w  	(a0),d0
_Load
		subi.l  	#$1,d0
		mulu    	#$1800,d0
		move.l  	a6,a0
		move.l  	d3,d1
		moveq   	#$1,d2
		move.l		(_resload,pc),a2
		jsr		(resload_DiskLoad,a2)
		movem.l		(sp)+,D0-D7/A0-A6
		rts

_LoadTracks2
		movem.l		D0-D7/A0-A6,-(sp)
		move.l  	(a2),d0
		bra     	_Load

;======================================================================
;Load/Save High Scores
;======================================================================

_SaveHighScoreTable
		movem.l		D0-D7/A0-A6,-(sp)
		lea		$841e,a1
		lea		_high(pc),a0
		move.l		#$80,d0
		move.l  	(_resload,pc),a2
		jsr     	(resload_SaveFile,a2)
		movem.l		(sp)+,D0-D7/A0-A6
		move.l		#$86e0,($86d4)
		rts

_LoadHighScoreTable
		lea     	(_high,pc),a0
		move.l  	(_resload,pc),a2
		jsr     	(resload_GetFileSize,a2)
		tst.l		d0
		beq		.noload
		lea     	(_high,pc),a0
		move.l		#$841e,a1
		move.l  	(_resload,pc),a2
		jsr     	(resload_LoadFile,a2)
.noload
		rts


;======================================================================
;Keyboard
;======================================================================

_FixKeyboard
		move.b		$bfed01,d0
		btst		#$3,d0
		beq		.notpressed
		clr.l		d0
		move.b		$bfec01,d0
		ori.b		#$40,$bfee01

		clr.b		$bfec01
		move.w  	d0,-(a7)
		move.w  	#3,D0
		beq.b  		.finished         ; don't wait
.loop1
		move.w  	d0,-(a7)
		move.b  	$dff006,d0      ; VPOS
.loop2
		cmp.b   	$dff006,d0
		beq.s   	.loop2
		move.w  	(a7)+,d0
		dbf     	d0,.loop1
.finished
		move.w  	(a7)+,d0
		ror.b		#$1,d0
		not.b		d0
		cmp.b		_keyexit(pc),d0
		beq		_exit

		cmp.b		#$5f,d0
		bne		.noskip
		movem.l		a0,-(sp)
		lea		_level_skip(pc),a0
		move.l		#1,(a0)
		movem.l		(sp)+,a0
.noskip
		andi.b		#$bf,$bfee01
		move.l		#$ffffff80,d1
		and.b		d0,d1
		andi.w		#$7f,d0
		lea		$9710,a0
		move.b		(a0,d0.w),d0
		or.b		d0,d1
		lea		$964e,a0
		jsr		$959a
.notpressed
		move.w		#$8,$dff09c
		jmp		$970a

;======================================================================
;Blitter Patches
;======================================================================

_WaitBlit1
		move.l		a0,($54,a5)
		move.w		d1,($58,a5)
		bra		_WaitBlitter
_WaitBlit2
		move.l		a1,($54,a5)
		move.w		d7,($58,a5)
		bra		_WaitBlitter
_WaitBlit3
		move.w		d4,(a3)+
		adda.w		d7,a0
		adda.w		d5,a2
		bra		_WaitBlitter
_WaitBlit4
		move.l		a0,(a3)+
		move.w		d4,(a3)+
		bra		_WaitBlitter

_WaitBlitter
		BLITWAIT	
		rts


;======================================================================
;CD32 Support
;======================================================================
		include ReadJoypad.s

_CD32_Read	movem.l		d0-d7/A0-A6,-(A7)
		bsr		_joystick
		bsr		_CD32_Quit
		movem.l		(a7)+,d0-d7/A0-A6
		move.w		($c,a5),d1
		move.w		d1,d2
		rts							
		
_CD32_Fire	
		move.b		#$fc,d1
		movem.l         d0/d2/a0,-(sp)
		move.l		joy1(pc),d2
		move.l		#JPB_BTN_RED,d0
		btst		d0,d2
		beq		.NotPressed
		move.b		#$7c,d1
.NotPressed	movem.l         (sp)+,d0/d2/a0
		not.b		d1
		rts
		
_CD32_Quit	
		movem.l         d0,-(sp)
		move.l		joy1(pc),d0
		btst		#JPB_BTN_REVERSE,d0
		beq		.exit
		btst		#JPB_BTN_FORWARD,d0
		beq		.exit
		btst		#JPB_BTN_PLAY,d0
		beq		.exit
		movem.l         (sp)+,d0
		bra		_exit
.exit		
		movem.l         (sp)+,d0
		rts
		
_CD32_Title
		movem.l         d1-d2/a0,-(sp)
		bsr		_CD32_TitleButtons
		movem.l         (sp)+,d1-d2/a0
		cmp.b		#1,d0
		rts


_CD32_TitleButtons
		move.l		joy1(pc),d2
		lea		_held_button(pc),a0
		move.l		#JPB_BTN_REVERSE,d1
		btst.l		d1,d2
		beq		.NotPressed
		btst		d1,(a0)
		bne		.CheckNext
		bset		d1,(a0)
		move.b		#1,d0
		rts
.NotPressed	bclr		d1,(a0)
.CheckNext
		move.l		#JPB_BTN_FORWARD,d1
		btst.l		d1,d2
		beq		.NotPressed2
		btst		d1,(a0)
		bne		.CheckKey
		bset		d1,(a0)
		move.b		#2,d0
		rts
.NotPressed2	bclr		d1,(a0)
.CheckKey	move.b		($9651),d0
		rts


_CD32_Skip	
		movem.l         d0-d1,-(sp)

		move.l		joy1(pc),d0
		btst		#JPB_BTN_YEL,d0
		beq		_noskip
		btst		#JPB_BTN_FORWARD,d0
		beq		_noskip
		movem.l         (sp)+,d0-d1
		movem.l		a0,-(sp)
		lea		_level_skip(pc),a0
		move.l		#0,(a0)
		movem.l		(sp)+,a0
		jmp		$2084
_noskip
		movem.l         (sp)+,d0-d1
		
		bsr		_CD32_Pause
		bsr		_CD32_Abort
		
		move.l		($a0b0),a2
		lea		$a8fa,a0
		rts

_CD32_Pause	
		movem.l         d0-d2/a0,-(sp)
		move.l		joy1(pc),d2
		lea		_held_button(pc),a0
		move.l		#JPB_BTN_PLAY,d1
		btst		d1,d2
		beq		.NotPressed
		btst		d1,(a0)
		bne		.done
		bset		d1,(a0)
		move.b		#$ff,($9653)
		bra		.done
.NotPressed	bclr		d1,(a0)
.done		movem.l         (sp)+,d0-d2/a0
		rts

_CD32_Abort	
		movem.l         d0,-(sp)
		move.l		joy1(pc),d0
		btst		#JPB_BTN_GRN,d0
		beq		.exit
		btst		#JPB_BTN_FORWARD,d0
		beq		.exit
		btst		#JPB_BTN_REVERSE,d0
		beq		.exit
		move.b		#$b,($9651)
.exit
		movem.l         (sp)+,d0
		rts

_CD32_Blue
    move.l		joy1(pc),d0
    btst		#JPB_BTN_BLU,d0
    bne.b		.launch
    addq.l  #4,a7   ; pop stack: don't launch
.launch
        rts
        

;======================================================================

_high
	dc.b	"Commando.high",0
	even

_held_button	dc.l	0

_level_skip	dc.l	0
		

_resload	dc.l	0
_Tags          
		dc.l    WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l    0,WHDLTAG_CUSTOM1_GET
_Custom1  dc.l    0

                dc.l    TAG_DONE
                
;======================================================================


_exit     pea     TDREASON_OK
          bra     _end
_debug    pea     TDREASON_DEBUG
          bra     _end
_wrongver pea     TDREASON_WRONGVER
_end      move.l  (_resload,pc),-(a7)
          add.l   #resload_Abort,(a7)
          rts

;======================================================================

	END
