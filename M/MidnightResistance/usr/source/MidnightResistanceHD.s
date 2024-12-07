;*---------------------------------------------------------------------------
;  :Program.	MidnightResistance.asm
;  :Contents.	Slave for "Midnight Resistance" from Ocean
;  :Author.	Mr.Larmer of Wanted Team / Wepl / Hungry Horace
;  :History.	20.12.98
;	*Wepl*
;		09.01.02 - rework
;		17.01.02 - v2 added
;		04.04.08 - strange check in v2 removed which fails on uae
;
;	*Hungry Horace*
;		04.11.09 - brightness tooltype added
;		08.11.09 - load/save scoretable added
;		09.11.09 - generic trainers added on CUSTOM2
;		12.11.09 - 2 button patch for player 1 & related bugfix
;			 - weapon selection trainers CUSTOM3/4/5 added
;		13.11.09 - 68000/NOVBRMOVE quitkey added
;		15.11.09 - CD32 Control Tooltype Added
;		17.11.09 - Green / Blue buttonswap added
;		21.11.09 - Final cleaning up - complete	
;		10.07.13 - Bug Fix on CUSTOM4 trainer, changesd 2nd button code, v17 options
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"whdgames:midnightresistance/MidnightResistance.Slave"
	BOPT  O+		;enable optimizing
	BOPT  OG+            ;enable optimizing
	BOPT  ODd-           ;disable mul optimizing
	BOPT  ODe-           ;disable mul optimizing
	BOPT  w4-            ;disable 64k warnings
	BOPT  wo-            ;disable optimizer warnings
	SUPER
	ENDC

	STRUCTURE	globals,$600
;	LONG	_resload

;======================================================================

base
		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	Start-base		;ws_GameLoader
		dc.w	_data-base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-base		;ws_name
		dc.w	_copy-base		;ws_copy
		dc.w	_info-base		;ws_info
		dc.w	0			; ws_kickname
		dc.l	0			; ws_kicksize
		dc.w	0			; ws_kickcrc
		dc.w	_config-base		
_config:	dc.b    "C1:X:Use Double-Brightness Palette:0;"			; ws_config
		dc.b    "C1:X:Enable CD32 Controls:1;"
		dc.b    "C1:X:Swap Jump/Weapon Second Fire:2;"
		dc.b    "C2:X:Infinite Lives:0;"
		dc.b    "C2:X:Infinite Credits:1;"
		dc.b    "C2:X:Infinite Ammo:2;"
		dc.b    "C2:X:Infinite Money:3;"
		dc.b    "C3:X:Supercharge:0;"
		dc.b    "C3:X:Barrier:1;"
		dc.b    "C4:L:Set Weapon 1:None,Shotgun,Pulse,Auto,Fire,Three-Way;"
		dc.b    "C5:L:Set Weapon 2:None,Homing Missiles,Nitro,Shower;"
		dc.b    0	
		EVEN

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
   dc.b  "1.6"
   IFD BARFLY
      dc.b  " "
      INCBIN   "T:date"
   ENDC
   ENDM

; version xx.slave works

   dc.b  "$","VER: slave "
   DECL_VERSION
   dc.b  $A,$D,0
   EVEN
;============================================================================

_name		dc.b	"Midnight Resistance",0
		dc.b	0
_copy		dc.b	"1990 Ocean/Special FX",0
_info		dc.b	"Adapted by Mr.Larmer/Wanted Team and Wepl",10
		dc.b	"Additions by Hungry Horace",10,10
     		dc.b  "Version "
		DECL_VERSION
		dc.b  0
_data		dc.b	"data",0
_amiga		dc.b	"AMIGA",0
_initdat	dc.b	"INIT.DAT",0
_1		dc.b	"1",0
_2		dc.b	"2",0
_3		dc.b	"3",0
_4		dc.b	"4",0
_5		dc.b	"5",0
_6		dc.b	"6",0
_7		dc.b	"7",0
_8		dc.b	"8",0
_9		dc.b	"9",0
_a		dc.b	"A",0
_savename	dc.b	"MidnightResistance.highs",0
		dc.b	0
_version	dc.b	0
_blue		dc.b	0
_green		dc.b	0
		EVEN

_cheats		dc.l	0
_spritecolour	dc.l	0
_buttonhold	dc.l	0
_keystore	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_custom3	dc.l	0
		dc.l	WHDLTAG_CUSTOM4_GET
_custom4	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	TAG_END
_resload	dc.l	0

	
;======================================================================
Start	;	A0 = resident loader
;======================================================================


		move.l	a0,$600.w

		lea	_resload(pc),a2
		move.l	a0,(a2)
	
	;	move.l	a0,(_resload)
		move.l	a0,a2			;A2 = resload
	
		lea	(_tags,pc),a0
		jsr	(resload_Control,a2)
	;	bra	.x
		lea	_amiga(pc),a0
		lea	$8000,a1
		jsr	(resload_LoadFileDecrunch,a2)
		lea	$8000,a0
		jsr	(resload_CRC16,a2)
		
		lea	_version(pc),a3
		lea	_keystore(pc),a4

		move.b	#1,(a3)			; is it version 1
		move.l	#$11712,(a4)

		lea	_pl1(pc),a0		; v1 patchlist
		cmp.w	#$b635,d0		; verify
		beq	.ok

		move.b	#2,(a3)			; is it version 2
		move.l	#$1176e,(a4)		
		lea	_pl2(pc),a0		; v2 patchlist
		cmp.w	#$abe6,d0		; verify
		beq	.ok
		
.x		pea	TDREASON_WRONGVER	; unsupported version
		jmp	(resload_Abort,a2)

.ok		lea	$8000,a1		;
		jsr	(resload_Patch,a2)	; apply main patches
		
		lea	_loader(pc),a0		;loader
		move.l	a0,$44

		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon+_custom)

		lea	_spritecolour(pc),a0	; link sprite colour to a0
		move.l	#$05000444,(a0)		; original sprite colour

		move.l	_custom1(pc),d1		; CUSTOM1 tooltype (bit 1)
		btst	#0,d1			; test custom1 bit 0 (brightness)
		beq 	.go			; skip, no patchlist changes
		
		move.l	#$0A000888,(a0)		; bright sprite colour				
		lea	_version(pc),a3		; link version to a3
		lea	_pl1_col(pc),a0		; colour patch version 1
		cmp.b	#1,(a3)			; is it version 1
		beq	.patchcolour		; do colour patch
		lea	_pl2_col(pc),a0		; otherwise, must be ver 2

.patchcolour	lea	$8000,a1		
		jsr	(resload_Patch,a2)	; patch palette if required
		
.go		bsr	_LoadScore		; Load Highscore table
		bsr	_ButtonSwitch		; Apply Button Switcher
		bsr	_Trainers		; Apply trainers

		jmp	$8000			; start game


; *** main patch list for ver 1 (Wepl)

_pl1		PL_START
		PL_W	$9248+2,$200		; bplcon0 color bit
		PL_PS	$9366,_f1		; bplcon0 color bit
		PL_W	$93bc+2,$87|CIAF_DSKSEL3|CIAF_DSKSEL2|CIAF_DSKSEL1|CIAF_DSKSEL0
		PL_PS	$93ea,_p5
		PL_PS	$9400,_f2
		PL_PS	$94e0,_f3
		PL_W	$a234+2,$200		; bplcon0 color bit
		PL_PS	$9A2E,_SaveScore	; save score routuine
		PL_NOP	$9A34,6			; save score relocated code
		PL_NEXT _pl3

; *** main patch list for ver 2 (Wepl)

_pl2		PL_START
		PL_W	$9250+2,$200		; bplcon0 color bit
		PL_PS	$936e,_f1		; bplcon0 color bit
		PL_W	$93c4+2,$87|CIAF_DSKSEL3|CIAF_DSKSEL2|CIAF_DSKSEL1|CIAF_DSKSEL0
		PL_PS	$93f2,_p5
		PL_PS	$9408,_f2
		PL_S	$94e2,$530-$4e2		; strange check, fails on uae
		PL_S	$a0a4,$f8-$a4		; strange check, fails on uae
		PL_PS	$953c,_f3
		PL_W	$a2f6+2,$200		; bplcon0 color bit
		PL_PS	$9A8A,_SaveScore	; save score routuine
		PL_NOP	$9A90,6			; save score relocated code	
		PL_NEXT _pl3

; *** main patch list shared (HH)

_pl3		PL_START
		PL_PS	$0262,_Weapons		; Weapon Selector
		PL_NOP	$1F00,8			; PLAYER 1 relocated code

		PL_PS	$1EFA,_Player1		; Extra buttons check player 1	
		PL_PS	$1EFA,_Player1		; Extra buttons check player 1	

		PL_NOP	$1F28,12		; PLAYER 2 relocated code
		PL_PS	$1F28,_Player2		; Extra buttons check player 2	
		PL_NOP	$9146,8			; Keyboard check relocated code
		PL_PS	$9146,_Keyboard		; 68000 /NOVBRMOVE quit
		PL_PS	$9196,_CD32_Read	; CD32 Pad Input
		PL_END


; *** first patchlist (v1) for high-brightness mode (HH)

_pl1_col	PL_START
	; main game palette
		PL_L	$9502,$00000A62
		PL_L	$9506,$08640A86
		PL_L	$950A,$00440264
		PL_L	$950E,$06840CA0
		PL_L	$9512,$0820004A		
		PL_L	$9516,$026C028E
		PL_L	$951A,$02460444
		PL_L	$951E,$06660CCC		
	; weapons room main palette
		PL_L	$9522,$00000A62	
		PL_L	$9526,$08640A86
		PL_L	$952A,$00440264
		PL_L	$952E,$06840CA0
		PL_L	$9532,$0820004A		
		PL_L	$9536,$026C028E
		PL_L	$953A,$02460444
		PL_L	$953E,$06660CCC		
		PL_NEXT	_pl3_col

; *** first patchlist (v2) for high-brightness mode (HH)

_pl2_col	PL_START
	; main game palette
		PL_L	$955E,$00000A62	
		PL_L	$9562,$08640A86
		PL_L	$9566,$00440264
		PL_L	$956A,$06840CA0
		PL_L	$956E,$0820004A		
		PL_L	$9572,$026C028E
		PL_L	$9576,$02460444
		PL_L	$957A,$06660CCC		
	; weapons room main palette
		PL_L	$957E,$00000A62	
		PL_L	$9582,$08640A86
		PL_L	$9586,$00440264
		PL_L	$958A,$06840CA0
		PL_L	$958E,$0820004A		
		PL_L	$9592,$026C028E
		PL_L	$9596,$02460444
		PL_L	$959A,$06660CCC	
		PL_NEXT	_pl3_col

; *** second patchlist (shared) for high-brightness mode (HH)

_pl3_col	PL_START
		PL_L	$1CB0,$0246004A ; shop 1 palette
		PL_L	$1CB4,$026C028E ; shop 1 palette
		PL_L	$1CC4,$06400862 ; shop 2 palette
		PL_L	$1CC8,$0A840CA6 ; shop 2 palette
		PL_L	$1CD8,$06200842 ; shop 3 palette
		PL_L	$1CDC,$0A640C86 ; shop 3 palette
		PL_L	$1CEC,$02440466 ; shop 4 palette
		PL_L	$1CF0,$068806A0 ; shop 4 palette
		PL_L	$1D00,$02400462 ; shop 5 palette
		PL_L	$1D04,$068408A6 ; shop 5 palette
		PL_L	$1D14,$04660688 ; shop 6 palette
		PL_L	$1D18,$08AA0ACC ; shop 6 palette
		PL_L	$1D28,$04200642 ; shop 7 palette
		PL_L	$1D2C,$08640A86 ; shop 7 palette
		PL_L	$1D3C,$06400862 ; shop 8 palette
		PL_L	$1D40,$0A840CA6 ; shop 8 palette
		PL_L	$1D50,$0246004A ; shop 9 palette
		PL_L	$1D54,$026C028E ; shop 9 palette
		PL_END

; *** original main fixes (Wepl)

_f1		move.w	#$200,($fe,a6)
		move.w	#$7fff,($98,a6)
		addq.l	#4,(a7)
		rts

_f2		move.w	(4,a6),d0
		add.l	#2,(a7)
		rts

_f3		move.w	#$444,(a0)+
		moveq	#3,d0
.lp		clr.l	(a0)+
		move.l	_spritecolour(pc),(a0)+	; h/w sprite colours
		dbf	d0,.lp
		add.l	#$f2-$e0-6,(a7)
		rts

_p5		move.b	(4,a6),d0
		move.b	d0,($700,a4)
		rts

; *** loader routines (Wepl)
; a0=name a1=dest|NULL

_loader		movem.l	d2-d3/a2-a4,-(a7)

	;search vars
		moveq	#0,d2			;d2 = dest address
		moveq	#0,d3			;d3 = patch routine
		lea	(__patch-6,pc),a4
.loop		addq.l	#6,a4
		move.w	(a4)+,d0
		beq	.endvars
		move.l	a0,a2			;load name
		lea	(__patch,pc,d0.w),a3
.cmp		move.b	(a2)+,d0
		cmp.b	(a3)+,d0
		bne	.loop
		tst.b	d0
		bne	.cmp
		move.w	(a4)+,d3
		ext.l	d3
		beq	.1
		lea	(__patch,pc),a2
		add.l	a2,d3			;d3 = patch routine
.1		move.l	(a4)+,d2		;d2 = dest address
.endvars

	;set dest
		move.l	a1,d0
		bne	.destok
		move.l	d2,a1
		tst.l	d2
		bne	.destok
		illegal
.destok
		
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFileDecrunch,a2)

	;patch
		tst.l	d3
		beq	.patchok
		move.l	d3,a0
		jsr	(a0)
.patchok

		movem.l	(a7)+,d2-d3/a2-a4		;_MOVEMREGS
		rts

PT	MACRO
	dc.w	\1-__patch
	dc.w	\2-__patch
	dc.l	\3
	ENDM

		;name, patches, loadaddress
__patch		PT	_initdat,__patch,$2ff80
		PT	_1,__patch,$595d2
		PT	_2,__patch,$595d2
		PT	_3,__patch,$595d2
		PT	_4,__patch,$595d2
		PT	_5,__patch,$595d2
		PT	_6,__patch,$595d2
		PT	_7,__patch,$595d2
		PT	_8,__patch,$59732
		PT	_9,__patch,$59732
		PT	_a,__patch,$5d0b2
		dc.w	0


; *** Read Joypads routine
;
;

_CD32_Read	movem.l	d0-d2/a0-a1,-(a7)	; inside VBI
		move.l	_custom1(pc),d2		; get custom 1
		btst	#1,d2			; bit 1 = CD32 mode
		beq	.end			; not used

		bsr	_Joypad			; read CD32 inputs on ports
		bsr	_pausebutton		; additional pause-code

.end		movem.l	(a7)+,d0-d2/a0-a1
		lea	($dff0e0).l,a6		; original code 	
		rts



; *** Extra Buttons routine (HH)

_Player1	movem.l	a0-a1/d3-d6,-(a7)	; reserve registers
		bsr	_PlayerShares		; shared joystick setup code
		move.l	_keystore(pc),a0	; a0 = keycode location 
		move	#0,d6	 		; use bit 0 for held-button
	 	
		btst	#1,d5			; CD32 tooltype
		bne	.cd32			; use CD32 controls
		bsr	.twobutton		; otherwise 2 button
.resume		bsr	.keyboard		; check original keyboard control
		movem.l	(a7)+,a0-a1/d3-d6	; restore regs
		rts				; EXIT PLAYER 1 PATCH
; ===

.twobutton	movem.l	d2,-(a7)		; preserve reg	
		move.w	$dff016,d2
		btst	#14,d2
		bsr	_secondbutton		; second button shared code
		movem.l	(a7)+,d2		; restore reg						
		rts

.cd32		movem.l	d2,-(a7)		; preserve reg	
		move.l	joy1(pc),d2		; get CD32 button used
		bsr	_cd32buttons		; CD32 buttons
		movem.l	(a7)+,d2		; restore reg						
		bra	.resume

.keyboard	cmpi.b	#$60,(a0)		; original code
		bne	.exit		
		bset 	#5,d0			; fire with left shift
.exit		rts

	
_Player2	movem.l	a0-a1/d3-d6,-(a7)	; reserve regs

		bsr	_PlayerShares		; shared joystick setup code
		move	#2,d6			; use bit 2 for held-button
			 		 	
		btst	#1,d5			; CD32 tooltype
		bne	.cd32			; CD32 controls
		bsr	.twobutton		; otherwise 2 button
.resume		bsr	.keyboard		; check original keyboard control
		movem.l	(a7)+,a0-a1/d3-d6	; restore regs
		rts				; EXIT PLAYER 2 PATCH

; ===

.twobutton	movem.l	d2,-(a7)		; preserve reg	
		move.w	$dff016,d2
		btst	#10,d2
		bsr	_secondbutton		; second button shared code
		movem.l	(a7)+,d2		; restore reg						
		rts
			
.cd32		movem.l	d2,-(a7)		; preserve reg	
		move.l	joy0(pc),d2		; get CD32 button used
		bsr	_cd32buttons		; CD32 buttons
		movem.l	(a7)+,d2		; restore reg		
		bra	.resume
		
.keyboard	and.b	($BFE001).L,D1		; original code
		lsr.b	#2,D1			; original code
		eor.b	d1,d0			; original code		

		btst	#5,$EF9		; bugfix
		beq	.exit		; if previous shift button held, set control bit
		bset	#5,d0		; second fire with right shift	
.exit		rts				

; *** Player 1 / 2 shared code
;

_PlayerShares	move.l	_custom1(pc),d5		; d5 = custom1	 	
	 	move.b	_blue(pc),d3		; d3 = blue function
	 	move.b	_green(pc),d4	 	; d4 = green function
		lea	_buttonhold(pc),a1
		rts		

; *** Standard 2 button mode

_secondbutton	bne.b	.exit			; test second button
		bset 	d3,d0			; set control bit
.exit		rts

; *** Full CD32 Controls (HH)
;

_cd32buttons	bsr	_firebutton		; red button (fire)
		bsr	_specialbutton		; blue button (second weapon)
		bsr	_jumpbutton		; green button (jump)
		bsr	_soundbutton		; yellow button (sound toggle)
		rts	
				
_jumpbutton	btst	#JPB_BTN_GRN,d2		; test green button 
		beq	.finish			; not pressed
		bset 	d4,d0			; set control bit
.finish		rts

_firebutton	btst	#JPB_BTN_RED,d2		; test red button 
		beq	.finish			; not pressed
		bset 	#4,d0			; set control bit 4 (first fire)
.finish		rts

_specialbutton	;bclr	#5,d0
		btst	#JPB_BTN_BLU,d2		; test blue button 
		beq	.finish			; not pressed
		bset 	d3,d0			; set control bit
.finish		rts

_soundbutton	btst	#JPB_BTN_YEL,d2		; test yellow button 
		beq	.noyellow		; not pressed

		btst	d6,(a1)			; check if button is already held
		bne	.finish			; if so, abandon
		bset	d6,(a1)			; set button as pressed

			movem.l	a0-a6/d0-d6,-(a7)	
			move.b	#$21,d0			; fake "s" press
			jsr	$10c66			; switch sound
			movem.l	(a7)+,a0-a6/d0-d6	
			rts				; exit
				
.noyellow	bclr	d6,(a1)			; clear button hold
.finish		rts

_pausebutton	lea	_buttonhold(pc),a1	; check if button is held

		move.l	joy0(pc),d2		; get joystick 0
		move.b	#1,d1			; button held bit for play port0
		bsr	_pauseshare		; check

		move.l	joy1(pc),d2		; button held bit for play port0
		move.b	#3,d1			; button held bit
		bsr	_pauseshare		; check

		rts
		
		
_pauseshare	btst	#JPB_BTN_PLAY,d2	; test play button 
		beq	.clear			; not pressed
		
		btst	d1,(a1)			; check if button is already held
		bne	.finish			; if so, abandon
		bset	d1,(a1)			; set button as pressed

		not.b	($E8F).w		; toggle pause
		rts				; exit
					
.clear		bclr	d1,(a1)			; clear button hold
.finish		rts



; *** CUSTOM1 tooltype for switching jump/second fire (HH)
;

_ButtonSwitch	movem.l	d0-d7/a0-a6,-(a7)		; preserve reg

		lea	_blue(pc),a1	
		lea	_green(pc),a2
		move.b	#5,(a1)			; blue set as second fire
		move.b	#0,(a2)			; green set as jump

		move.l	_custom1(pc),d0		; get CUSTOM1
		btst	#2,d0			; test bit 2 (switch controls)
		beq	.exit			; not used
		
		move.b	#0,(a1)			; blue set as jump
		move.b	#5,(a2)			; green set as second fire			
	
.exit		movem.l	(a7)+,d0-d7/a0-a6
		rts

; *** load / save highscores (HH)
;

_SaveScore	move.b	(a0)+,(a1)+			; original code relocated
		addi.b	#$37,(-1,a1)			; puts name intro highscore table
		dbra	d6,_SaveScore			; letter at a time
		
		movem.l	d0-d7/a0-a6,-(a7)		; preserve reg
		lea	_cheats(pc),a0			; check for trainers
		tst.l	(a0)				; check 
		bne	.close				; exit if any trainers are used

		move.l	_resload(PC),A2
		move.l	#$6F,D0				;data length
		moveq.l	#0,D1				;offset of zero
		lea	_savename(pc),A0		;filename

		lea	_version(pc),a4
		cmp.b	#2,(a4)				; check version
		beq	.ver2save

.ver1save	lea	$1190C,A1			; position of ver 1 scores
		bra	.save
.ver2save	lea	$11968,A1			; position of ver 2 scores
.save		jsr	(resload_SaveFileOffset,a2)
.close		movem.l	(a7)+,d0-d7/a0-a6		; register restore
		rts


_LoadScore	movem.l	d0-d7/a0-a6,-(a7)		; store registers
		
		lea	(_savename,pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_GetFileSize,a2)	; get highscore filesize
		tst.l	d0				; check exists
		beq	.skip				; skip loadscore

		move.l	_resload(PC),A2
		move.l	#$6F,D0				; data length
		moveq.l	#0,D1				; offset of zero
		lea	_savename(pc),A0		; filename
				
		lea	_version(pc),a3			; link version
		cmp.b	#2,(a3)				; check for  2
		beq	.ver2

.ver1		lea	$1190C,a1			; ver1 highscore position
		bra 	.jump

.ver2		lea	$11968,a1			; ver2 highscore position
.jump		jsr	(resload_LoadFileOffset,a2)	; Load scores

.skip		movem.l	(a7)+,d0-d7/a0-a6		; register restore
		rts


; *** Weapon Select on CUSTOM3/4/5 (HH)
; 

_Weapons	movem.l	d0-d3,-(a7)		; store registers
		move.l	_custom3(pc),d0		; CUSTOM3 tooltype 

		btst	#1,d0	
		beq	.nobarrier	
		move.w	#$2800,$C8(A5)		; barrier - needs time removed also

.nobarrier	btst	#0,d0	
		beq	.nosupercharge
		move.w	#$1194,$88(A5)		; supercharge on


.nosupercharge	move.l	_custom4(pc),d0		; CUSTOM4 tooltype 
		tst	d0
		beq	.noweapon
	
		subi	#1,d0		
		cmp.b	#5,d0	
		bge	.noweapon
		
		move.w	#$500,$C0(A5) 		; weapon 1 ammo
		clr.b	$1(A5)			; unknown
		move.b	d0,$9(a5)		; weapon 1 type


.noweapon	move.l	_custom5(pc),d0		; CUSTOM5 tooltype 
		cmp.b	#4,d0
		bge	.end

		move.b	#$50,$C2(A5)		; weapon 2 ammo
		move.b	d0,$A(A5)		; weapon 2 type
		clr.b	$8C(A5)			; unknown

.end		movem.l	(a7)+,d0-d3		; restore registers
		move.b	#2,$2(A5) 		; original code
		rts


		
; *** Simple CUSTOM2 Trainers (HH)		
;
;   seemed easier to maintain by code and not patchlist
;   these memory locations are the same between versions
;

_Trainers	movem.l	d0-d7/a0-a6,-(a7)		; store registers

		lea	_cheats(pc),a0			; cheats flag
		clr.l	(a0)

		move.l	_custom5(pc),d1
		add.l	d1,(a0)			; CUSTOM5 tooltype 
		move.l	_custom4(pc),d1
		add.l	d1,(a0)			; CUSTOM4 tooltype 
		move.l	_custom3(pc),d1
		add.l	d1,(a0)			; CUSTOM3 tooltype 
		move.l	_custom2(pc),d1
		add.l	d1,(a0)			; CUSTOM2 tooltype (used below)		

		tst.l	(a0)				
		beq	.cheatend			; skip if no cheats used

		move.l	#$4e714e71,d0			; NOP

		btst	#0,d1				; bit 0 = lives
		beq	.nolives
		move.l	d0,$84ee			; infinite lives

.nolives	btst	#1,d1				; bit 1 = credits
		beq	.nocredits
		move.l	d0,$822a			; infinite credits
		move.w	d0,$822e			; infinite credits 

.nocredits	btst	#2,d1				; bit 2 = ammo
		beq	.noammo
		move.w	d0,$a438			; infinite ammo
		move.w	d0,$a444			; infinite ammo
		move.l	d0,$a428			; infinite 2nd ammo

.noammo		btst	#3,d1				; bit 3 = money
		beq	.cheatend
		move.l	d0,$89ca			; infinite money

.cheatend	move.l	(_resload,pc),a2		; 
 		jsr 	(resload_FlushCache,a2)		; flush cache (recommended by StingRay)
		movem.l	(a7)+,d0-d7/a0-a6		; register restore
		rts


; *** 68000/NOVBRMOVE friendly quit (HH)

_Keyboard:	andi.w	#$7f,d0			; original game code
		cmp.b	_keyexit(pc),d0		; check exit key
		bne	.noquit			; not pressed

		pea	TDREASON_OK		; safe WHD exit 
		move.l	_resload(pc),-(a7)	; safe WHD exit 
		addq.l	#resload_Abort,(a7)	; safe WHD exit 

.noquit		cmpi.b	#$61,d0			; original game code
		rts
;============================================================================

_Joypad:	include	readjoypad.s


		END
