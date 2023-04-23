*---------------------------------------------------------------------------
;  :Program.    DesertStrike.asm
;  :Contents.	Slave for "Desert Strike - Return to the Gulf" from Electronic Arts
;  :Author.     Jean-Francois Fabre / Keith Krellwitz/Abaddon
;  :History.    --------
;		previous versions done by JOTD (1996-2007, no history available)
;		 - Rewrote memory allocation so the loader now only needs 512K chip/512K 24bit RAM
;		 - Removed routines that lit the floppy led (I hate that floppy led :) )
;		 - Second button changes weapons (VERY useful during intensive fights)
;		 - Fast decrunch using relocated routines in fastmem
;		 - Manual included;
;		version 2.2 (07.07.07) done by JOTD:
;		 - no need for NOVBRMOVE anymore
;		 - reworked install & icons
;		 - source code included
;		version 2.3 (01.21.2013) done by Keith Krellwitz/Abaddon:
;		 - Custom4=1 - Enable CD32 joypad support
;		 	Red 			- Fire
;			Yellow 			- Bring Up Map Screen/Exit Map screen
;		 	Play 			- Pause 
;		 	Play+Forward+Reverse 	- Quit
;		 	Green+Forward+Reverse 	- Abort Game
;		version 2.3.1 (01.21.2013) done by Keith Krellwitz/Abaddon:
;		 - Custom5=1 - Skip Intro - Jumps to the Main Menu
;		version 3.0 (02.26.2016) done by Keith Krellwitz/Abaddon & JOTD:
;		 - Removed all JST specific code and converted to use patchlists
;		 - Added Level Select 
;		 - Added Trainer - Infinite Power, Fuel, Hellfire, Hydra, and Cannon
;		 - Blitter Waits Added
;		 - Removed 6x Disk Access
;		 - Fixed issue with copperlist being set before the its loaded 
;		  (after main menu, press fire to skip intro, mission briefing, etc.)
;		 - Reworked the CD32 controls as requested
;			Red 	- Always fires the Cannon
;			Blue	- Always fires Hydra
;			Green	- Always Fires Hellfire
;		   (The weapon select no longer functions)
;		 - Added Button Wait to force NTSC
;		 - Added support for a second version
;		 - Removed division by 0 after first intro
;        - JOTD: added automatic joypad detection
;        - JOTD: finalized installation package (Abaddon didn't release the latest version)

;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly
;
; Code adresses @ bc66
; Codes start @ bc92
;
;
; *** Desert Strike Hard Disk Loader
; *** Written by JOTD

;                                           fastsize   fastbuff
;                                               |          |
; on A500: $200: E  T  C  !  00 00 02 08 00 17 E3 18 00 C0 04 E8
; 2MB      $210: 00 05 00 07 FB E0 00 00 04 20 00 03 00 00 00 00
;                            |            |
;                          topchip     lowchip

; on A500: $200: E  T  C  !  00 00 02 08 00 07 E3 18 00 C0 04 E8
; 1MB      $210: 00 05 00 07 FB E0 00 00 04 20 00 03 00 00 00 00

; on 1200: $200: E  T  C  !  00 00 02 08 00 F7 FF E0 68 00 02 00
; 68060    $210: 00 05 00 1F EF E0 00 00 10 20 07 03 00 00 00 00

;level at 2572 255A
;2116 return pressed on password screen
;password calc 244e
; Lives at 98362
; 97b4c - btst 5 infinite hellfire
; Level 2 Code: VQAOEKN
; Level 3 Code: ALATHZQ
;---------------------------------------------------------------------------*


		INCDIR  Include:
		INCLUDE whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT  DesertStrike.slave
		BOPT	O+				;enable optimizing
		BOPT	OG+				;enable optimizing
		BOPT	ODd-	               		;disable mul optimizing
		BOPT	ODe-	        		;disable mul optimizing
		BOPT	w4-				;disable 64k warnings
		BOPT	wo-				;disable optimizer warnings
		SUPER
		DOSCMD	"WDate  >T:date"
		ENDC

;CHIP_ONLY

	IFD	CHIP_ONLY
CHIPMEMSIZE = $100000
EXPMEMSIZE = $0
	ELSE
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000
	ENDC
;======================================================================

base
                SLAVE_HEADER            	;ws_Security + ws_ID
                dc.w    18              	;ws_Version
                dc.w    WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_NoDivZero    ;ws_flags
                dc.l    CHIPMEMSIZE    	     	;ws_BaseMemSize can't use fast memory would have to be 24 bit memory
                dc.l    0               	;ws_ExecInstall
                dc.w    _start-base      	;ws_GameLoader
                dc.w    0                       ;ws_CurrentDir
                dc.w    0               	;ws_DontCache
_keydebug       dc.b    $58             	;ws_keydebug = F9
_keyexit        dc.b    $5d             	;ws_keyexit = * keypad
_expmem         dc.l    EXPMEMSIZE         	;ws_ExpMem
                dc.w    _name-base      	;ws_name
                dc.w    _copy-base      	;ws_copy
                dc.w    _info-base      	;ws_info
                dc.w	0                       ;ws_kickname
                dc.l	0                       ;ws_kicksize
                dc.w	0                       ;ws_kickcrc
                dc.w	_config-base		;ws_config

;======================================================================

DECL_VERSION:MACRO
	dc.b	"4.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_name           dc.b    "Desert Strike - Return to the Gulf"
		IFD	CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
				dc.b	0
_copy           dc.b    "1993 Electronic Arts",0
_info           dc.b    "by JOTD & Abaddon since 1996",10,10
				dc.b	"CD32 controls: Blue=change weapon",10
				dc.b	"Yellow/Play=status",10,10
				dc.b	"Alt CD32 controls: Red=cannon, Blue=hydra",10
				dc.b	"Green=hellfire, Yellow/Play=status",10,10
		dc.b    "Version "
                DECL_VERSION
                dc.b    0
	dc.b	0
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	10,0	

_config
		dc.b    "BW;"
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C1:X:Trainer Infinite Energy:1;"
        dc.b    "C1:X:Trainer Infinite Weapons:2;"
		dc.b    "C2:L:Select Starting Level:Air Superiority,Scud Buster,Embassy City,Nuclear Storm,The End;"
        dc.b    "C3:B:Disable Blitter Patches;"
        dc.b    "C4:B:Enable alternate CD32 Joypad controls;"
        dc.b    "C5:B:Skip Intro;"
        dc.b    0
        even

;======================================================================
_start   ;       A0 = resident loader
;======================================================================

		lea		_resload(pc),a1
		move.l		a0,(a1)	
		move.l		a0,a2
		lea     	(_Tags,pc),a0
		jsr     	(resload_Control,a2)

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
		
		bsr	_detect_controller_types

		move.l	_alt_cd32_controls(pc),d0
		beq.b	.no_alt
		lea		third_button_maps_to(pc),a0
		move.l	#JPF_BTN_GRN,(a0)
.no_alt
		
		IFD	CHIP_ONLY
		lea		_expmem(pc),a0
		move.l	#$80000,(a0)
		ENDC

		lea	_ammo_type(pc),a1
		move.l		_expmem(pc),a0
		add.l		#$17524,a0		; Weapon Select
		move.l	a0,(a1)
		lea		heli_struct_address(pc),a1
		move.l	_expmem(pc),a0
		add.l	#$76FF6,a0
		move.l	a0,(a1)
		
		move.l		#$10400,d3		; load datatable
		movea.l		d3,a0
		move.l		#$400,d0
		move.l		#$200,d1
		moveq		#1,d2
		move.l		(_resload,pc),a2
		jsr		(resload_DiskLoad,a2)	

		moveq		#0,d7
		movea.l		d3,a0
		move.l		4(a0,d7.w),d0
		addi.l		#$3ff,d0
		andi.l		#$fffffe00,d0
		move.l		d0,d5
		subi.l		#$200,d5
		
		movea.l		d3,a0
		move.l		d5,d1			; length
		move.l		0(a0,d7.w),d0		; Offset
		moveq		#1,d2
		lea		$58000,a0

		move.l		(_resload,pc),a2
		jsr		(resload_DiskLoad,a2)	

		movea.l		d3,a1
		clr.l		(a1)+

		movea.l		d3,a2
		lea		$200.w,a6
		move.l		#$45544321,0(a6)
		lea		8(a6),a4
		move.l		a4,4(a6)
.1
		move.l		(a2)+,(a4)+
		beq.s		.2
		move.l		(a2)+,(a4)+
		move		(a2)+,(a4)+
		bra.s		.1
.2
		move		#$2700,sr

		movem.l		d0-d7/a0-a6,-(sp)
		lea		_PL_BOOT(pc),a0		
		bsr		_Patch
		
		movem.l		(sp)+,d0-d7/a0-a6
		
		bsr		_MemoryConfig
		
		jmp		$5800e

_Patch800
		movem.l		d0-d7/a0-a6,-(sp)
		lea		_IntroAddr(pc),a1
		move.l		$86A.W,(a1)

		lea		_PL_800(pc),a0		
		bsr		_Patch

		move.l	_expmem(pc),a1
		lea		_PL_800_BLITTER(pc),a0		
		move.l		_resload(pc),a2
		jsr		resload_Patch(a2)
		movem.l		(sp)+,d0-d7/a0-a6
				
		lea		$2714.w,a7
		move		#$2700,sr
		move.w		#$1ff,dmacon+$dff000

		
		jmp		$840.W

		
_JsrIntro
		bsr		_FlushCache
		move.l		_Custom5(pc),d0			; Skip Intro
		bne		.skip
		move.l		_IntroAddr(pc),-(sp)	; expmem+2
.skip		
		rts

_JsrIntro2
		movem.l		d0-d7/a0-a6,-(sp)

		move.l		$210E.W,A0
		add.l		#$1C566,A0
		cmp.l		#$48E77FFC,(A0)
		bne		.exit

		lea		_expmem(pc),a1
		move.l		$210E,(a1)

		lea		_PL_MAIN(pc),a0
		move.l		$210E.W,a1
		move.l		_resload(pc),a2
		jsr		resload_Patch(a2)
.exit
		movem.l		(sp)+,d0-d7/a0-a6
		; *** flush and run
		bsr		_FlushCache
		move.l		$210e.w,a0
		add.l		#$e,A0				; Add $e to skip the division by 0
		rts

; code jumps in $200 in menu, team brief
_JsrLoader3
		movem.l		d0-d7/a0-a6,-(sp)
		
		cmp.l		#$48E77FFC,$3AF4.W
		bne		.patch2
		
		lea		_PL_JSR3_1(pc),a0
		bsr		_Patch
		

		bra		.go
.patch2
		cmp.l		#$13C00000,$F92.W
		bne		.patch3
		
		bsr		_PatchStartLevel
	
		; JOTD: found out that there are 2 versions really slightly different
		; and that SPS112 support was broken when I fixed the sound issues in 2021
		; making the game crash on startup menu
		
		lea		_PL_JSR3_2_SPS112(pc),a0
		cmp.l	#$4E714E71,$2384.W
		beq.b	.patch22
		lea		_PL_JSR3_2_ALT(pc),a0
.patch22
		bsr		_Patch
		bra		.go
.patch3
		cmp.l		#$48E7FFFE,$1A170
		bne		.patch4
		; team brief
		lea		_PL_JSR3_3(pc),a0
		bsr		_Patch
		bra		.go

.patch4		; *** CD32 Joypad - Abort Game Menu - Abaddon
		cmp.l		#$303900df,$78a
		bne		.go
		lea		_PL_JSR3_4(pc),a0
		bsr		_Patch
.go
		movem.l		(sp)+,d0-d7/a0-a6
		bsr		_FlushCache

		; bugfix (A0 was fixed at $200)

		move.l		_expmem(pc),A0
		add.l		#$1bcea,a0
		move.l		(a0),a0

		rts
		
anim_hook_v2:
	movem.l	d0/a0-a2,-(a7)
	move.l	_expmem(pc),a0
	add.l	#$182F2,a0		; location of the password string
	lea	.offset(pc),a1
	
	moveq	#1,d0
	bsr	_read_joystick
	btst	#JPB_BTN_LEFT,d0
	beq.b	.noleft
	; user pressed left: back one level
	move.w	(a1),d0
	beq.b	.end
	subq.w	#1,d0
	bra.b	.setpass	
.end
	move.w	#4,d0
	bra.b	.setpass
.noleft
	btst	#JPB_BTN_RIGHT,d0
	beq.b	.zap
	move.w	(a1),d0
	cmp.w	#4,d0
	bcc.b	.start
	addq.w	#1,d0
	bra.b	.setpass	
.start
	move.w	#0,d0
.setpass	
	move.w	d0,(a1)
	lea	password_table(pc),a1
	add.w	d0,d0
	move.w	(a1,d0.w),d0
	
	add.w	d0,a1
.copy
	move.b	(a1)+,(a0)+
	bne.b	.copy
	
.loop
	moveq	#1,d0
	bsr	_read_joystick
	tst.l	d0
	bne.b	.loop
	
.zap
	movem.l	(a7)+,d0/a0-a2
	
	; original
	TST.W $0002a194
	BNE.W anim_hook_v2
	RTS
.offset:
	dc.l	0

password_table:
	dc.w	.level1-password_table
	dc.w	.level2-password_table
	dc.w	.level3-password_table
	dc.w	.level4-password_table
	dc.w	.end-password_table

	
.level1:
	dc.b	"AAAAAAA",0
.level2:
	dc.b	"BQJRAEF",0
.level3:
	dc.b	"KLJLTOE",0
.level4:
	dc.b	"WEIVVJT",0
.end:
	dc.b	"ONKKQKF",0
	
 
_JsrLoader4
		movem.l		d0-d7/a0-a6,-(sp)

		cmp.l		#$33c700df,$36d5c
		bne		.patch2
		lea		_PL_JSR4_1_BLITTER(pc),a0		
		bsr		_Patch
.patch2

		movem.l		(sp)+,d0-d7/a0-a6
		bsr		_FlushCache
		movea.l 	$3286.W,a0
		rts

_Patch:
		sub.l		a1,a1
		move.l		_resload(pc),a2
		jmp		resload_Patch(a2)


	IFND	CHIP_ONLY
FIX_24_BIT = 1
	ENDC
	
;======================================================================
;Patchlists
;======================================================================

_PL_BOOT	PL_START
		PL_P		$58BFE,_ReadSectors
		PL_P		$581A2,_Patch800
		PL_P		$5916A,_Decrunch
		PL_R		$58962				; remove insert disk 1
		PL_R		$5880a				; remove disk access
		
		IFD		FIX_24_BIT
		; fix issues with 32-bit code when relocating
		PL_B		$59568+2,$7F		; better MSB clipping
		PL_B		$59574+2,$7F		; better MSB clipping
		PL_B		$595d4+2,$7F		; better MSB clipping
		ENDC
		
		PL_END

_PL_800
		PL_START
		PL_NOP		$0830,6		; remove CACR access
		PL_P		$12d4,_ReadSectors
		PL_P		$1840,_Decrunch
		PL_PS		$868,_JsrIntro
		PL_PS		$205c,_JsrIntro2
		PL_R		$ee0				; remove disk access
		PL_R		$e7a				; remove disk access
		;PL_PA		$86a,_IntroAddr
		
		; fix issues with 32-bit code when relocating
		IFD		FIX_24_BIT		
		PL_B		$1e14+2,$7F		; better MSB clipping
		PL_B		$1e80+2,$7F		; better MSB clipping
		PL_B		$1e20+2,$7F		; better MSB clipping
		ENDC
		
		PL_END

_PL_800_BLITTER
		PL_START
		PL_IFC3
		PL_ELSE
		PL_PS		$12d0,_WaitBlit1
		PL_PSS		$13a6,_WaitBlitter,6
		PL_ENDIF
		PL_END
		
_PL_MAIN	PL_START
		PL_P		$1C566,_ReadSectors
		PL_PS		$1BC38,_JsrLoader3
		PL_P		$1C2CA,_SetDisk
		PL_R		$1b2a4				; remove trap handler
		PL_PSS		$99a2,_Check2ndButton,2		; 2nd button check
		PL_PS		$976,_CheckQuit_1		; keyboard interrupt
		PL_P		$1cad2,_Decrunch		; decrunch in fastmem
		PL_R		$1c10c				; drive light
		PL_R		$1c172				; remove disk access
		PL_PS		$1bc9a,_FixCopper		; Copper list is blank when set and activated before it is loaded

		PL_PSS		$1a87e,dbf_fix,2
		PL_PSS		$1a894,dbf_fix,2
		
		PL_PSS		$24c,install_other_interrupts,$60-$4c+4

		PL_IFC1X	0 					; Trainer
		PL_W		$7cba,$6046			; Infinite Lives $98362
		PL_ENDIF
		PL_IFC1X	1
		PL_NOP		$dde,6				; Infinite Fuel 98356
		PL_ENDIF
		;PL_NOP		$ac70,400			; Infinite Power f6e36 - sub @ 8AC7E
		PL_IFC1X	2
		PL_B		$d5f4,$60			; Infinite ammo (Hellfire Missiles f7088)
		PL_ENDIF
		
		PL_IFC1
		; enabled if a trainer option is set (why?)
		PL_PS		$6cc,_PatchTrainer
		PL_ENDIF
		PL_PS		$9888,_CD32_Read1		; *** CD32 Joypad - Main Screen - Abaddon

		PL_IFC4 					; If not null enable CD32 joypad-style controls
		PL_PSS		$9890,_cd32_one_weapon_per_button,2		; Converted to use 3 fire buttons - one for each weapon
		PL_B		$9898,$67
		PL_PSS		$98A0,cd32_weapon_switch_off,2
		PL_ELSE
		;;PL_PSS		$A9C,_Read2ndButton,2		; 2nd button detect in VBLANK interrupt
		;;PL_PSS		$9890,_cd32_fire_current_weapon_test,2		; Converted to use 3 fire buttons - one for each weapon
		; change weapon with 2nd button or FORWARD
		PL_PSS		$98a0,cd32_weapon_switch,2
		PL_B		$98a8,$67
		PL_ENDIF
		
		PL_PSS		$d80e,_ammo_test,2
		PL_PS		$e7e8,_CD32_ZeroOutKeys		; *** CD32 Joypad - Map Screen - Abaddon
		PL_PS		$105ba,_CD32_Read1
		PL_PSS		$105c4,_CD32_FireMap2,4
		PL_B		$105ce,$67
		PL_PS		$102e0,_CD32_FireMap
		PL_IFC5
		PL_NOP		$676,6				; Skip Intro
		PL_ENDIF
		
		IFD		FIX_24_BIT
		; fix issues with 32-bit code when relocating
		PL_B		$14e46+2,$7F		; better MSB clipping
		PL_B		$14e52+2,$7F		; better MSB clipping
		PL_B		$14eb0+2,$7F		; better MSB clipping
		ENDC
		
		; blitter
		PL_IFC3
		PL_ELSE		
		PL_PSS	$5c14,blit1,2
		PL_PSS	$5298,blit2,2
		PL_P	$537a,blit3
		PL_ENDIF
		PL_END

blit1		
	CMPI.W	#$ffff,D3		;85c14: 0c43ffff
	BEQ.b	.out		;85c18: 6700e1d2
	rts
.out
	addq.l	#4,a7
	bra		_WaitBlitter

blit2
	CMPI.B	#$04,D4			;8: 0c040004
	BCS.b	.out		;8529c: 6500eb4e
	rts
.out
	addq.l	#4,a7
	bra		_WaitBlitter

blit3
	MOVE.L	#$ffffffff,(A1)	;8537a: 237cffffffff0000
	bra		_WaitBlitter

	
_PL_JSR3_1	PL_START
		PL_P		$3af4,_ReadSectors
		PL_P		$4060,_Decrunch			; decrunch
		PL_NOP		$33c0,4				; led off
		PL_R		$369a				; led off
		PL_R		$3700				; remove disk access
		PL_PS		$31e0,_JsrLoader4
		PL_END

; SPS112 has a lot of NOPs inserted in 2384, alternate version doesn't
_PL_JSR3_2_SPS112
		PL_START
		PL_PSS		$37CC,dbf_fix_d7,2	; audio dma cpu dependent loop wait
		PL_PSS		$3818,dbf_fix_d6,2	; audio dma cpu dependent loop wait
		PL_NEXT		_PL_JSR3_2_common
_PL_JSR3_2_ALT
		PL_START
		PL_PSS		$37C2,dbf_fix_d7,2	; audio dma cpu dependent loop wait
		PL_PSS		$380e,dbf_fix_d6,2	; audio dma cpu dependent loop wait
		PL_NEXT		_PL_JSR3_2_common
		
; common code (below $2384)
_PL_JSR3_2_common
		PL_START
		PL_PS		$f92,_CheckQuit_2		; keyboard menu
		;PL_IFC4						; *** CD32 Joypad - Main Menu - Abaddon
		PL_PS		$1326,_CD32_Read3
		PL_PS		$1330,_CD32_FireMenu
		PL_PSS		$1196,_CD32_FireJoy0,2
		PL_PSS		$1092,vblank_menu_hook,6
		PL_B		$119e,$67			; Change to bne check
		;PL_ENDIF
		
		PL_IFC3
		
		PL_ELSE
		PL_PS		$1dac,_WaitBlit1
		PL_PSS		$194e,_WaitBlitter,6

		PL_ENDIF
		
		PL_END


_PL_JSR3_3	PL_START
		PL_P		$1a40c,_ReadSectors
		PL_P		$1a170,_SetDisk			; Set Disk
		PL_R		$19fb2				; led off
		PL_R		$1a018				; remove disk access
		PL_IFC4						; Check if CD32 joypad enable
		PL_PSS		$cdc,_CD32_Read4,2	; team brief - in vblank
		PL_B		$ce4,$66			; Replace with cd32 joy 0 check red button
		PL_PSS		$ce8,_CD32_Fire,2
		PL_B		$cf0,$67			; Replace with cd32 joy 0 check red button
		PL_ENDIF
		PL_END

		
_PL_JSR3_4	PL_START
		PL_IFC4						; Check if CD32 joypad enable
		PL_PS		$78a,_CD32_Read3
		PL_PS		$794,_CD32_FireMenu
		PL_B		$ce4,$66			; Replace with cd32 joy 0 check red button
		PL_PSS		$5fa,_CD32_FireJoy0,2
		PL_B		$602,$67			; Replace with cd32 joy 0 check red button
		PL_ENDIF
		PL_END

_PL_JSR4_1_BLITTER
		PL_START
		PL_IFC3
		PL_ELSE
		PL_PS		$36d5c,_WaitBlit1
		PL_PSS		$36b7a,_WaitBlitter,6
		PL_ENDIF
		PL_END

;======================================================================
;Blitter Patches
;======================================================================


	
_WaitBlit1
		move.w		d7,$dff058
_WaitBlitter
		BLITWAIT	
		rts
;======================================================================
; added JOTD fixes
;======================================================================
	
_ammo_test
	; not working with hellfire, launched on button release
	move.l	d0,-(a7)
	cmp.l	heli_struct_address(pc),a3
	bne.b	.fired		; enemies are also using this routine!
	move.l	a0,-(a7)
	move.l		_ammo_type(pc),a0
	cmp.b		#WEAPON_HELLFIRE,(a0)
	movem.l	(a7)+,a0
	beq.b	.fired
	
	; we're going to check raw joypad, see if any fire is pressed

	move.l	joy1(pc),d0
	; possible fire buttons
	btst	#JPB_BTN_RED,d0
	bne.b	.fired
	btst	#JPB_BTN_BLU,d0
	bne.b	.fired
	btst	#JPB_BTN_GRN,d0
	bne.b	.fired
	; no buttons are actually fired
	; means that fire was pressed to enable strafing
	; using the rev/fwd
	move.l	(a7)+,d0
	bra.b	.no_ammo_no_noise
	
.fired
	move.l	(a7)+,d0
	; test ammo before firing
	TST.W	18(A3)			;8d80e: 4a6b0012
	bgt.b	.set

.no_ammo
	; no ammo
	add.l	#$1E-$10,(a7)
.set
	rts
.no_ammo_no_noise
	addq.l	#4,A7
	MOVE.L	(A7)+,D0		;8d860: 201f
	MOVE	#$0004,CCR		;8d862: 44fc0004
	RTS				;8d866: 4e75

	
dbf_fix:
	move.w	#4,d0	; $12C DBF, usually soundtracker
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	addq.l	#2,(a7)
	rts
	
dbf_fix_d7:
	move.w	#6,d7	; $12C DBF, usually soundtracker
.bd_loop1
	move.w  d7,-(a7)
    move.b	$dff006,d7	; VPOS
.bd_loop2
	cmp.b	$dff006,d7
	beq.s	.bd_loop2
	move.w	(a7)+,d7
	dbf	d7,.bd_loop1
	rts
	
dbf_fix_d6:
	move.w	#6,d6	; $12C DBF, usually soundtracker
.bd_loop1
	move.w  d6,-(a7)
    move.b	$dff006,d6	; VPOS
.bd_loop2
	cmp.b	$dff006,d6
	beq.s	.bd_loop2
	move.w	(a7)+,d6
	dbf	d6,.bd_loop1
	
	rts

; original game just did an RTE
install_other_interrupts:
	movem.l	a1,-(a7)
	lea	default_handler(pc),a1
	move.l	a1,$64.W
	move.l	a1,$74.W
	move.l	a1,$78.W
	movem.l	(a7)+,a1
	RTS
	
default_handler:
	move.w	#$0F0,$DFF180
	move.w	#$7FFF,$DFF09C
	RTE
	
;======================================================================
; Trainer Code
;======================================================================
_PatchStartLevel
		movem.l		d0,-(sp)
		move.l		_start_level(pc),d0

		cmp.l		#$33fc0000,$2564.W
		bne		.version2
		cmp.l		#$0000257e,$2568.W
		bne		.version2
		move.w		d0,$257e.W
		move.w		d0,$2566.W
		bra		.skip
.version2
		move.w		d0,$2574.W
		move.w		d0,$255c.W
		; hook to the sync loop used in menu animation / password enter
		; so we can read the joystick here and change passwords
		patch		$E14,anim_hook_v2

.skip		movem.l		(sp)+,d0
		rts

_PatchTrainer
		movem.l		d0/a0,-(sp)
		move.l		_Custom1(pc),d0
		beq		.skip
		move.b		#$5,d3
.skip		move.l		_expmem(pc),a0
		add.l		#$17b4c,a0		; $97b4c
		move.b 		d3,(a0)
		movem.l		(sp)+,d0/a0
		rts

		
;======================================================================
; Flush Caches
;======================================================================

_FlushCache
		move.l		a0,-(sp)
		move.l		_resload(PC),a0
		jsr		resload_FlushCache(a0)
		move.l		(sp)+,a0
		rts
		
;======================================================================
; Disk Loader
;======================================================================

_ReadSectors
		movem.l		d0-d3/a0-a2,-(sp)
		move.w		_currdisk(pc),d3
		and.w		#3,d3
		move.w		d1,d0
		mulu.w		#512,d0                 ; offset
		moveq		#$0,d1
		move.w		d2,d1
		mulu.w		#512,d1                 ; size
		tst.w		d1			; If size is 0 exit
		beq.b		.exit
		move.l		d3,d2
		addi.l		#$1,d2
		move.l		(_resload,pc),a2
		jsr		(resload_DiskLoad,a2)
.exit		movem.l		(sp)+,d0-d3/a0-a2
		rts

_SetDisk
		movem.l		a0,-(sp)
		lea		_currdisk(pc),a0
		and.w		#15,D0
		move.w		d0,(a0)
		movem.l		(sp)+,a0
		rts

;======================================================================
; Memory Configuration
;======================================================================

_MemoryConfig
		lea		$200.w,a1
		move.l		#'ETC!',(a1)+
		move.l		#$208,(a1)+
		move.l		#$80000,(a1)+		; size
		move.l		_expmem(pc),(a1)+	; location
		move.w		#$5,(a1)+
		move.l		#$7fbe0,(a1)+
		move.l		#$420,(a1)+
		move.w		#$300,(a1)+
		clr.l		(a1)+
		rts
	
;======================================================================
; Second Fire Button Support
;======================================================================

_Check2ndButton
		movem.l		d0/a0/a1,-(sp)
		move.l		_expmem(pc),a0
		add.l		#$186d6,a0
		lea		_Fire2Pressed(pc),a1
		tst.l		(a1)
		beq		.nob2
		bset.b		#7,(a0)		; simulate space pressed
.nob2
		btst.b		#7,(a0)		; original code
		movem.l		(sp)+,d0/a0/a1
		rts

;======================================================================
;Check for quit key
;======================================================================

_CheckQuit_2
		move.b		d0,($fd6).w
		cmp.b		_keyexit(pc),d0
		beq		_quit
		rts

_CheckQuit_1
		lea		$bfe001,a0
		move.l		d0,-(sp)
		move.b		$c00(a0),d0
		ror.b		#1,d0
		not.b		d0
		cmp.b		_keyexit(pc),d0
		beq		_quit
		move.l		(sp)+,d0
		rts

;======================================================================
; Decrunch
;======================================================================

_Decrunch
		movem.l		a2,-(sp)
		move.l		_resload(pc),a2
		jsr		(resload_Decrunch,a2)

		move.l		_resload(PC),a2
		jsr		resload_FlushCache(a2)

		movem.l		(sp)+,a2
		rts

;======================================================================
;CD32 Support - Added by Abaddon
;======================================================================

		include ReadJoypad.s

vblank_menu_hook:
	movem.l	d0-d7/A0-A6,-(sp)
	bsr		_joystick
	jsr		$10c4.w
	move.w	#$20,_custom+intreq
	movem.l		(sp)+,d0-d7/A0-A6
	rts
	
_CD32_Read1	movem.l		d0-d7/A0-A6,-(sp)		; Game screen joypad read
		bsr		_joystick
		bsr		_CD32_Quit
		bsr		_CD32_Keys
		bsr		_CD32_Abort
		movem.l		(sp)+,d0-d7/A0-A6
		move.w		($dff00c),d0
		rts

_CD32_Read2	movem.l		d0-d7/A0-A6,-(sp)		; Map screen joypad read
		bsr		_joystick
		bsr		_CD32_Quit
		bsr		_CD32_Keys
		movem.l		(sp)+,d0-d7/A0-A6
		move.w		($dff00c),d0
		rts

_CD32_Read3	movem.l		d0-d7/A0-A6,-(sp)		; Main menu screen joypad read
		bsr		_CD32_Quit
		movem.l		(sp)+,d0-d7/A0-A6
		move.w		($dff00c),d0
		rts

_CD32_Read4	movem.l		d0-d7/A0-A6,-(sp)		; team brief menu screen joypad read
		bsr		_joystick
		bsr		_CD32_Quit
		bsr		_CD32_FireJoy0
		movem.l		(sp)+,d0-d7/A0-A6
		rts

_CD32_FireMenu
		move.b		($bfe001),d2
		movem.l		d0-d1,-(sp)
		move.l		joy1(pc),d1
		move.l		#JPB_BTN_RED,d0
		btst.l		d0,d1
		beq		.exit
		move.b		#$7e,d2
.exit		movem.l		(sp)+,d0-d1
		rts


_CD32_FireJoy0							;
		movem.l		d0,-(sp)
		move.l		joy0(pc),d0
		btst		#JPB_BTN_RED,d0
		movem.l		(sp)+,d0
		rts

_CD32_Fire:
		movem.l		d1,-(sp)
		move.l		joy1(pc),d1
		btst		#JPB_BTN_RED,d1
		movem.l		(sp)+,d1
		rts

; < D1: joystick state (decoded from _joystick)
; <> D0: game decoded controls
_handle_strafe
	move.l	a0,-(a7)
	move.l		_ammo_type(pc),a0
	cmp.b		#WEAPON_HELLFIRE,(a0)
	movem.l	(a7)+,a0
	beq.b	.no_rev
	
	btst	#JPB_BTN_FORWARD,d1
	beq.b	.no_fwd
	; left+fire
	bset	#3,d0
	bset	#6,d0
.no_fwd
	btst	#JPB_BTN_REVERSE,d1
	beq.b	.no_rev
	; right+fire
	bset	#2,d0
	bset	#6,d0
.no_rev
	rts
	
_CD32_FireMap2
		move.b		($bfe001),d2
		movem.l		d0,-(sp)
		move.l		joy1(pc),d0
		btst		#JPB_BTN_RED,d0
		movem.l		(sp)+,d0
		rts

_CD32_FireMap
		move.b		($bfe001),d1
		movem.l		d0,-(sp)
		move.l		joy1(pc),d0
		btst		#JPB_BTN_RED,d0
		beq		.exit
		move.b		#$7e,d1
.exit		movem.l		(sp)+,d0
		rts

cd32_weapon_switch_off
	movem.l		d0,-(sp)
	sub.l	d0,d0
	movem.l		(sp)+,d0
	rts
	
cd32_weapon_switch
		movem.l		d0,-(sp)
		move.l		joy1(pc),d0
		; test for blue
		btst	#JPB_BTN_BLU,d0
		movem.l		(sp)+,d0
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
		bra		_quit
.exit
		movem.l         (sp)+,d0
		rts

_CD32_Abort
		movem.l         d1/a0,-(sp)
		move.l		joy1(pc),d1
		btst		#JPB_BTN_REVERSE,d1
		beq		.exit
		btst		#JPB_BTN_FORWARD,d1
		beq		.exit
		btst		#JPB_BTN_GRN,d1
		beq		.exit
		move.l		_expmem(pc),a0
		add.l		#$17514,a0
		move.w		#$c0,(a0)
.exit		movem.l         (sp)+,d1/a0
		rts


_CD32_Keys
		movem.l         d0-d3/a0-a1,-(sp)
		move.l		joy1(pc),d1
		lea		_held_button(pc),a1
		move.l	(a1),d3
		; play & yellow act the same
		btst		#JPB_BTN_PLAY,d1
		bne.b		.pressed
		btst		#JPB_BTN_YEL,d1
		beq.b		.NotPressed
.pressed
		btst		#JPB_BTN_PLAY,d3
		bne.b		.exit
		bset		#JPB_BTN_PLAY,d3
		move.l	d3,(a1)
		move.b		#$59,d0		; F10 key emulation
		move.l		_expmem(pc),a0
		add.l		#$9b4,a0
		jsr		(a0)
		bra		.exit
.NotPressed	bclr		#JPB_BTN_PLAY,d3
			move.l	d3,(a1)
.exit
.done	movem.l         (sp)+,d0-d3/a0-a1
		rts


_CD32_ZeroOutKeys					; Need to clear otherwise in order for the
		movem.l		a0,-(sp)		; Map button to work correctly
		move.l		_expmem(pc),a0
		add.l		#$14b58,a0
		jsr		(a0)
		move.l		_expmem(pc),a0
		add.l		#$17514,a0
		move.w		#0,(a0)
		movem.l		(sp)+,a0
		rts

WEAPON_CANNON = 0
WEAPON_HYDRA = 1
WEAPON_HELLFIRE = 2

_cd32_fire_current_weapon_test
		movem.l         d1/a0,-(sp)
		move.l		joy1(pc),d1
		bsr			_handle_strafe	; affects d0
		not.l	d1
		btst		#JPB_BTN_RED,d1	; test fire
		movem.l         (sp)+,d1/a0
		rts


_cd32_one_weapon_per_button						; Updated the fire buttons
		movem.l         d1/a0,-(sp)
		move.l		joy1(pc),d1
		bsr			_handle_strafe	; affects d0

		move.l		_ammo_type(pc),a0
		btst		#JPB_BTN_RED,d1		; Red Button always fires the cannon - regardless of the 
		beq		.checkhydra		; weapon select
		move.b		#WEAPON_CANNON,(a0)
		btst		#JPB_BTN_RED,d1
		bra		.exit
.checkhydra
		btst		#JPB_BTN_BLU,d1		; Blue Button always fires the hydra - regardless of the 
		beq		.checkhellfire		; weapon select
		move.b		#WEAPON_HYDRA,(a0)
		btst		#JPB_BTN_BLU,d1
		bra		.exit
.checkhellfire
		btst		#JPB_BTN_GRN,d1		; Green Button always fires the hellfire - regardless of the 
		beq		.exit			; weapon select
		move.b		#WEAPON_HELLFIRE,(a0)
		btst		#JPB_BTN_GRN,d1

.exit	
		movem.l         (sp)+,d1/a0
		rts
		
		
_held_button	dc.l	0

;======================================================================
; Copperlist Fix - This loads the correct copper list into memory 
; @ $4dbb2
;======================================================================

_FixCopper
		movem.l         d0/a0-a1,-(sp)
		movea.l		d0,a0
		cmp.w	#$120,(a0)
		beq.b	.skip
		lea		_CopperList(pc),a1
		moveq		#6,d0
.loop		move.l		(a1)+,(a0)+
		dbf		d0,.loop
.skip
		movem.l         (sp)+,d0/a0-a1
		move.l		d0,($dff080)
		rts

_CopperList
		dc.l		$a01fffe
		dc.l		$1800000
		dc.l		$1000200
		dc.l		$f401fffe
		dc.l		$1800000
		dc.l		$9c8010
		dc.l		$fffffffe 
		
;======================================================================


_IntroAddr	dc.l	0
_Fire2Pressed	dc.l	0
_currdisk	dc.w	0

_resload	dc.l	0
_Tags           dc.l    WHDLTAG_CUSTOM1_GET
_Custom1	dc.l    0
         	dc.l    WHDLTAG_CUSTOM2_GET
_start_level	dc.l    0
         	dc.l    WHDLTAG_CUSTOM3_GET
_Custom3	dc.l    0
         	dc.l    WHDLTAG_CUSTOM4_GET
_alt_cd32_controls	dc.l    0
         	dc.l    WHDLTAG_CUSTOM5_GET
_Custom5	dc.l    0
 		dc.l    WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l    0
                dc.l    TAG_DONE

;======================================================================


_quit     pea     TDREASON_OK
          bra     _end
_debug    pea     TDREASON_DEBUG
          bra     _end
_wrongver pea     TDREASON_WRONGVER
_end      move.l  (_resload,pc),-(a7)
          add.l   #resload_Abort,(a7)
          rts
_ammo_type
	dc.l	0
heli_struct_address
	dc.l	0
	
;======================================================================

        END