;*---------------------------------------------------------------------------
;  :Program.	FirstSamurai.asm
;  :Contents.	Slave for "First Samurai" from Vivid Image
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	30.03.99
;		22.12.10 Harry/Wepl:
;			 sound fix for channel 4
;			 highscores now saved to a seperate file
;			 keyboard ack fixed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE whdmacros.i

	IFD	BARFLY
	OUTPUT	FirstSamurai.Slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC


;======================================================================

_base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem		dc.l	$80000		;ws_ExpMem
		dc.w	_name-_base	;ws_name
		dc.w	_copy-_base	;ws_copy
		dc.w	_info-_base	;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config
		
_config
        dc.b    "C1:X:trainer infinite lives:0;"
        dc.b    "C1:X:trainer infinite energy:1;"
        dc.b    "C1:X:trainer infinite sword and ammo:2;"
        dc.b    "C1:X:trainer get all magic items at start:3;"
        dc.b    "C1:X:trainer bell always active:4;"
        dc.b    "C2:B:blue/second button jumps;"
        dc.b    "C3:B:skip introduction;"
        dc.b    "C4:B:no speed regulation;"
		dc.b	0

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"The First Samurai",0
_copy		dc.b	"1991 Vivid Image",0
_info		dc.b	"installed by Mr.Larmer, Harry, Wepl, JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
	EVEN
BOOT_ADDRESS = $40000

current_level_select = 4

;======================================================================
Start	;	A0 = resident loader
;======================================================================
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	clr.l	current_level_select	; we'll use $4 to store some data
	
	bsr	_detect_controller_types
    lea third_button_maps_to(pc),a0
    move.l  #JPF_BTN_GRN,(a0)
    
	bsr	calibrate_delay_loop

		;get tags
	move.l	_resload(pc),a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	lea	BOOT_ADDRESS,A0
	moveq	#0,D0
	move.l	#$200,D1
	moveq	#1,d2
	bsr.w	_LoadDisk

	move.l	#$400,D0
	jsr	resload_CRC16(a2)

	cmp.w	#$714D,D0		; ECS version
	beq.b	.skip
	cmp.w	#$DBA8,D0		; AGA version
	bne.b	.not_support
	bra.b	.aga
.skip		
	lea	BOOT_ADDRESS,A0
	move.l	#$400,D0
	move.l	#$1200,D1
	moveq	#1,d2
	bsr.w	_LoadDisk

	move.l	_expmem(pc),0.w			; ext mem

	lea	BOOT_ADDRESS,A1
	lea	pl_boot_ecs(pc),a0
	jsr	resload_Patch(a2)

	moveq	#1,D4
	lea	BOOT_ADDRESS,A0
	jmp	(A0)
	
.not_support
	subq.l	#8,a7
	pea	TDREASON_WRONGVER.w
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
;--------------------------------

.aga
		lea	BOOT_ADDRESS,A0
		move.l	#$400,D0
		move.l	#$1200,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		move.l	_expmem(pc),-4(a0)			; ext mem
		move.l	A0,A1
		lea	pl_boot_aga(pc),a0
		jsr	resload_Patch(a2)

		moveq	#1,D4

		lea	BOOT_ADDRESS,A0
		jmp	(A0)

; super ping_pong: jump 7FFC0 then 500 then 1500

jump_7FFC0:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_jumper_7ffc0_ecs(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	;0007FFE2 JMP $00000500, there's another jump at $7FFD0 not reached (expmem we don't need?)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$7FFC0

jump_500_ecs
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_jumper_500_ecs(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$500.W
	
jump_1500_ecs:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_jumper_1500_ecs(pc),a0
	lea	$1500,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	JMP $1500.W

; $8A41: climbing 1, else 0
; $ADB1: head facing left 1 else 0
; $AE41: legs facing left 1 else 0
; $AEBD: smthing else facing left
; code 00005D16 test sword C81C.W
; has sword: 0000C817 (also: 0000B10D 0000B111 0000B115 0000B119)
; but computed from sword energy (set to 0 when has sword: sword comes back)

read_joystick_button_jump:
	movem.l	d2/a0,-(a7)

	move.l	joy1(pc),d0
	; D2: opposite direction bit
	move.l	#JPB_BTN_LEFT,d2
	tst.b	$AE41
	beq.b	.facing_right
	move.l	#JPB_BTN_RIGHT,d2	
.facing_right

	;move.l	buttons_state(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
	tst.b	$00008A41
	bne.b	.no_blue	; 1: climbing: button never replaces "up"

	;btst	D2,D0
	; here, climbing, but opposite direction select: able to jump with diagonal
	;bne.b	.noneed

	; not climbing: fire+opposite direction cancels up button
	btst	#JPB_BTN_RED,d0
	beq.b	.cancel_up
	btst	D2,d0
	bne.b	.no_blue
.cancel_up
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d1
	btst	#9,d1
	beq.b	.noneed
	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	move.l	d1,d0
	movem.l	(a7)+,d2/a0
	RTS

pressed_key_as_ascii = $CB6B
pressed_key_as_ascii_2 = $CB6C
	
read_joypad_test_pause
	bsr	_joystick
	movem.l	d0,-(a7)
	move.l	joy1(pc),d0

	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noquit
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	btst	#JPB_BTN_PLAY,d0
	bne	_quit
	bsr	quit_current_game
.noquit
	btst	#JPB_BTN_GRN,d0
	beq.b	.nogreen
	; trigger bell
	;;move.w	#$229,$C812
	move.l	#$6210,$C820
	move.b	#$20,pressed_key_as_ascii_2
.nogreen

	btst	#JPB_BTN_PLAY,d0
	movem.l	(a7)+,d0
	bne.b	.pause
	
	CMPI.B	#$50,pressed_key_as_ascii
	rts

.pause
	cmp.b	d0,d0	; set Z flag
	rts
	
award_lives_on_level_skip:
	SUBQ.W	#1,$c848
	bpl.b	.okay
	move.W	#3,$c848	; start with 3 lives when skipping
.okay
	rts	
	
main_loop_hook
	; original
	clr.w	$b524
	; now regulate speed. This variable flip flops 0/1 each 50th second
	; (from game VBLANK interrupt). Game loop seems to be normally running at
	; 25 fps, except in some places where it runs at 50 fps and it's really
	; too fast to be playable. Syncing on this variable makes it right everywhere
	; probably a bug passed undetected, as everything was so easy to put in sync...
.wait
	tst.w	$8ff0
	bne.b	.wait
	rts
	
read_joy_from_menu:
	bsr	_joystick
	movem.l	d0,-(a7)
	move.l	joy1(pc),d0
	bsr	check_quit
	btst	#JPB_BTN_YEL,d0
	beq.b	.noyellow
	move.b	#$01,pressed_key_as_ascii_2
.noyellow

	movem.l	(a7)+,d0

	BTST	#7,$bfe001	; orig
	rts

read_joy_from_level_select_menu:
	bsr	_joystick
	movem.l	a0/d0/d1,-(a7)
	lea	previous_joy(pc),a0
	move.l	(a0),d1
	move.l	joy1(pc),d0
	move.l	d0,(a0)
	
	bsr	check_quit
	btst	#JPB_BTN_GRN,d0
	beq.b	.nogreen
	move.b	#'S',pressed_key_as_ascii_2
.nogreen
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nofwd
	btst	#JPB_BTN_FORWARD,d1
	bne.b	.nofwd
	move.w	#$F0,$DFF180
	add.b	#1,current_level_select
	cmp.b	#10,current_level_select
	bne.b	.nofwd
	clr.b	current_level_select
.nofwd
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nobwd
	btst	#JPB_BTN_REVERSE,d1
	bne.b	.nobwd
	move.w	#$F00,$DFF180
	sub.b	#1,current_level_select
	cmp.b	#$FF,current_level_select
	bne.b	.nobwd
	move.b	#9,current_level_select
.nobwd
	btst	#JPB_BTN_BLU,d0
	beq.b	.noblue
	; current level
	move.b	#1,pressed_key_as_ascii_2
	move.b	current_level_select,d0
	add.b	d0,pressed_key_as_ascii_2
.noblue
	movem.l	(a7)+,a0/d0/d1
	MOVE.B	pressed_key_as_ascii_2,D0	; original
	rts

check_quit
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noquit
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	btst	#JPB_BTN_PLAY,d0
	bne	_quit
.noquit
	rts
read_hiscore_key_1:
	bsr	_joystick
	movem.l	d0,-(a7)
	move.l	joy1(pc),d0
	bsr	check_quit
	btst	#JPB_BTN_BLU,d0
	beq.b	.nofire
	; return
	move.B	#$FF,pressed_key_as_ascii
	
.nofire
	movem.l	(a7)+,d0
	CMPI.B	#$ff,pressed_key_as_ascii		;045ee: 0c3900ff0000cb6b
	rts
	
read_hiscore_key_2:
	bsr	_joystick
	movem.l	d0,-(a7)
	move.l	joy1(pc),d0
	bsr	check_quit
	btst	#JPB_BTN_BLU,d0
	beq.b	.nofire
	; return
	move.B	#$0D,pressed_key_as_ascii
	
.nofire
	movem.l	(a7)+,d0
	CMPI.B	#$ff,pressed_key_as_ascii		;045ee: 0c3900ff0000cb6b
	rts
; access to game base code (JOTD)
; level-specific code is patched in the load routine
; dirty but seems difficult to do otherwise

pl_jumper_1500_ecs
	PL_START
	PL_IFC2
	PL_PS	$094b8-$1500,read_joystick_button_jump
	PL_ENDIF
	
	PL_PSS	$185e-$1500,read_joy_from_menu,2
	PL_PSS	$264a-$1500,read_joypad_test_pause,2
	PL_PS	$4230-$1500,read_joy_from_level_select_menu
	PL_PSS	$45B0-$1500,read_hiscore_key_1,2
	PL_PSS	$45ee-$1500,read_hiscore_key_2,2
	;fix sound channel 4 max volume (#issue 2260)
	PL_W	$1d798-$1500,$30
	
	;PL_B	$0572e-$1500,$60	; crack password check/protection
	PL_R	$5606-$1500		; even better: protection never shows
	PL_PS	$1646-$1500,Copylock

	; all levels are reachable even if not validated yet
	PL_NOP	$04264-$1500,2
	; give 3 lives if the level wasn't reached (-1 lives)
	PL_PS	$1D4C-$1500,award_lives_on_level_skip

	PL_IFC4
	PL_ELSE
	PL_PS	$1E80-$1500,main_loop_hook
	PL_ENDIF
	
	PL_IFC1X	1
	; energy
	PL_NOP	$70FA-$1500,8
	PL_NOP	$d398-$1500,8
	PL_NOP	$4cce-$1500,8
	PL_NOP	$60C4-$1500,8
	PL_NOP	$7b6a-$1500,8
	PL_ENDIF
	PL_IFC1X	0
	PL_B	$6800-$1500,$4A	; lives
	PL_ENDIF
	PL_IFC1X	2
	PL_B	$7C4C-$1500,$4A	; ammo
	PL_CW	$6BE6-$1500		; sword
	PL_W 	$1D00-$1500,$3E8	; maxed sword at start
	PL_W 	$1DE4-$1500,$3E8	; maxed sword at start
	PL_ENDIF
	PL_IFC1X	4
	; bell always active
	PL_S	$07b8e-$1500,$07ba2-$07b8e
	PL_ENDIF

	PL_END
	
pl_jumper_7ffc0_ecs
	PL_START
	PL_P	$7FFE2,jump_500_ecs
	PL_END
	
pl_jumper_500_ecs
	PL_START
	PL_P	$12EC,jump_1500_ecs
	PL_END
	
pl_boot_ecs
	PL_START
	PL_W	$2C,$601E ; drive off
	PL_P	$17E,Load
	PL_W	$F6E,$601A	; skip set bus vector
	PL_NOP	$FD4,2		; useful?
	PL_P	$FD6,Patch1
	PL_R	$1036    ; check mem
	PL_P	$8C,jump_7FFC0
	PL_END
	
pl_boot_aga
	PL_START
	PL_W	$30,$601E ; drive off
	PL_P	$182,Loadaga
	PL_PSS	$FF0,Patch1aga,2
	PL_END


Patch1
	jsr	$1316.w		; decrunch?

	movem.l	d0-d1/a0-a2,-(A7)
	lea	pl_patch_1_ecs(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	

	; change last text to just "press fire"

	moveq	#' ',d1

	moveq	#12,d0
	lea	$3B21.w,A0
.clear
	move.b	d1,(A0)+
	dbf	D0,.clear

	moveq	#23,d0
	lea	$3B30.w,A0
.clear2
	move.b	d1,(A0)+
	dbf	D0,.clear2

	moveq	#14,d0
	lea	$3B4A.w,A0
.clear3
	move.b	d1,(A0)+
	dbf	D0,.clear3

	moveq	#17,d0
	lea	$3B5C.w,A0
.clear4
	move.b	d1,(A0)+
	dbf	D0,.clear4

	lea	Text(pc),A0
	lea	$3B37.w,A1
	moveq	#9,D0
.copy
	move.b	(A0)+,(A1)+
	dbf	D0,.copy

	movem.l	(A7)+,d0-d1/a0-a2
	jmp	$1500.w

pl_patch_1_ecs
	PL_START
	PL_PS	$1658,Patch3
	PL_L	$60,$2CC6C50D		; copylock ID
	PL_L	$1C26,$60000958		; skip copylock
	PL_P	$2660,Patch2ecs
	PL_W	$26EC,$0068	; interrupt vectors on
	PL_W	$26EE,$600A
	PL_W	$2706,$6016
	
	; not sure that all patches are needed, just bruteforcing
	; all tests to CIAAPRA bit 7 to return true, which skips
	; the introduction
	
	PL_IFC3
	PL_PSS	$19fc,yes_fire,2
	PL_PSS	$25ee,yes_fire,2
	PL_PSS	$28ac,yes_fire,2
	PL_PSS	$2a70,yes_fire,2
	PL_PSS	$4688,yes_fire,2
	PL_PSS	$471c,yes_fire,2
	PL_PSS	$4b8a,yes_fire,2
	PL_ENDIF
	
	PL_END

; set Z flag (so button is pressed)
yes_fire:
	cmp.b	d0,d0
	rts
	
; 00008A41: 1: climbing
;  00008A47:

;--------------------------------

Patch3
		patchs	$909E,PlayerPatch
		jmp	$8B00

;--------------------------------

PlayerPatch
		move.l	D0,-(A7)
		moveq	#0,D0
		move.b	3(A6),D0
		move.w	D0,8(A5)
		move.l	(A7)+,D0
		rts

;--------------------------------

Patch1aga
		jsr	$132A.w

		pea	Patch3aga(pc)
		move.l	(A7)+,$1676.w

		move.w	#$4EF9,$1D1C.w
		pea	Patch2aga(pc)
		move.l	(A7)+,$1D1E.w

		move.w	#$0068,$1DA8.w		; skip set interrupt vectors
		move.w	#$600A,$1DAA.w
		move.w	#$6016,$1DC2.w

		movem.l	d0-d1/a0-a1,-(A7)

		moveq	#' ',d1

		moveq	#12,d0
		lea	$31DF.w,A0
.clear
		move.b	d1,(A0)+
		dbf	D0,.clear

		moveq	#23,d0
		lea	$31EE.w,A0
.clear2
		move.b	d1,(A0)+
		dbf	D0,.clear2

		moveq	#14,d0
		lea	$3208.w,A0
.clear3
		move.b	d1,(A0)+
		dbf	D0,.clear3

		moveq	#17,d0
		lea	$321A.w,A0
.clear4
		move.b	d1,(A0)+
		dbf	D0,.clear4

		lea	Text(pc),A0
		lea	$31F5.w,A1
		moveq	#9,D0
.copy
		move.b	(A0)+,(A1)+
		dbf	D0,.copy

		movem.l	(A7)+,d0-d1/a0-a1

		jmp	$1500.w

;--------------------------------

Patch3aga
		patch	$85A4,PlayerPatch

		jmp	$8000

;--------------------------------

Patch2ecs
		move.l	$432C.w,A0

		movem.l	d0-d1/a0-a2,-(A7)
		
		patch	$C0,WaitBlit1
		patch	$C6,WaitBlit2
		
		move.l	_resload(pc),a2
		move.l	a0,a1
		lea	pl_main_ecs(pc),a0
		jsr	(resload_Patch,a2)
	
		movem.l	(a7)+,d0-d1/a0-a2

		jmp	$504.w
		
pl_main_ecs
	PL_START
	; blitter waits
	PL_L	$2A0C2-$22900,$4EB800C0
	PL_L	$2A0CE-$22900,$4EB800C0
	PL_L	$2A0DA-$22900,$4EB800C0
	PL_L	$2A0E6-$22900,$4EB800C0
	PL_L	$2A120-$22900,$4EB800C0
	PL_L	$2A134-$22900,$4EB800C0
	PL_L	$2A148-$22900,$4EB800C0
	PL_L	$2A15C-$22900,$4EB800C0
	PL_L	$2A210-$22900,$4EB800C0
	PL_L	$2A21C-$22900,$4EB800C0
	PL_L	$2A228-$22900,$4EB800C0
	PL_L	$2A234-$22900,$4EB800C0
	PL_L	$2A25A-$22900,$4EB800C0
	PL_L	$2A26E-$22900,$4EB800C0
	PL_L	$2A282-$22900,$4EB800C0
	PL_L	$2A296-$22900,$4EB800C0


	PL_L    $2CA06-$22900,$4EB800C6
	PL_L    $2CA18-$22900,$4EB800C6
	PL_L    $2CA2A-$22900,$4EB800C6
	PL_L    $2CA3C-$22900,$4EB800C6
	PL_L    $2CA52-$22900,$4EB800C6
	PL_L    $2CA6C-$22900,$4EB800C6
	PL_L    $2CA86-$22900,$4EB800C6
	PL_L    $2CA9C-$22900,$4EB800C6
	PL_L    $2CBE4-$22900,$4EB800C6
	PL_L    $2CBFC-$22900,$4EB800C6
	PL_L    $2CC14-$22900,$4EB800C6
	PL_L    $2CC2C-$22900,$4EB800C6
	PL_L    $2CCA6-$22900,$4EB800C6
	PL_L    $2CCB8-$22900,$4EB800C6
	PL_L    $2CCCA-$22900,$4EB800C6
	PL_L    $2CCDC-$22900,$4EB800C6
	PL_L    $2D950-$22900,$4EB800C6
	PL_L    $2D962-$22900,$4EB800C6
	PL_L    $2D974-$22900,$4EB800C6
	PL_L    $2D986-$22900,$4EB800C6
	PL_L    $2DD72-$22900,$4EB800C6
	PL_L    $2DD82-$22900,$4EB800C6
	PL_L    $2DD92-$22900,$4EB800C6
	PL_L    $2DDA2-$22900,$4EB800C6
	PL_L    $2DE22-$22900,$4EB800C6
	PL_L    $2DE32-$22900,$4EB800C6
	PL_L    $2DE42-$22900,$4EB800C6
	PL_L    $2DE52-$22900,$4EB800C6

	PL_B	$2A2F6-$22900,$13	; correct copperlist
	PL_B	$2A2FB-$22900,$71
	PL_B	$2E832-$22900,$13
	PL_B	$2E837-$22900,$71

	PL_PS	$2DF78-$22900,Keyboard
	PL_PS	$2DFaa-$22900,_keyboarddelay
	PL_END
	
	
	;;PL_B	$572E-$1500,$60	; skip manual protection
	
	PL_END


_keyboarddelay	
		moveq	#3-1,d1
.wait1		move.b	(vhposr+_custom),d0
.wait2		cmp.b	(vhposr+_custom),d0
		beq	.wait2
		dbf	d1,.wait1
		addq.l	#2,(a7)
		rts

;--------------------------------

Patch2aga
		move.l	$39EA.w,A0

		move.b	#$60,$424E(A0)		; skip manual protection

		lea	$7000(a0),a0

		move.w	#$4EB9,$489C(A0)
		pea	KeyboardAga(pc)
		move.l	(A7)+,$489E(A0)

		lea	-$7000(a0),a0

		jmp	$504.w

;--------------------------------

Copylock
		move.l	$2CA68,A0
		cmp.l	#$70007200,(A0)		; copy lock
		bne.b	.not_level_5
		cmp.l	#$7600487A,4(A0)
		bne.b	.not_level_5
		cmp.l	#$000A23DF,8(A0)
		bne.b	.not_level_5
		cmp.l	#$00000010,12(A0)
		bne.b	.not_level_5

		move.w	#$4E75,(A0)

		move.l	#$2CC6C50D,D0			; copylock ID
		eor.l	#$2C19350D,D0
		move.l	D0,$96BA
		bsr	_flushcache
.not_level_5
		rts

;--------------------------------

WaitBlit1
		move.w	D7,$58(A0)
waitblit
		BLITWAIT
		rts
WaitBlit2
		move.w	A4,$58(A0)
		bra.b	waitblit
		
quit_current_game:
	clr.w	$C81A	; zero energy
	move.w	#-1,$C848	; neg lives
	rts
;--------------------------------

Keyboard
		ror.b	#1,D0
		eori.b	#$FF,D0

	; the manual states: Q when paused, but it doesn't work
	cmp.b	#$45,d0
	bne.b	.noesc
	bsr	quit_current_game
	

.noesc
;		cmp.b	#$46,D0			; Del
;		bne.b	check_quit_key

;		move.w	#40,$5E9E.w		; ammo
;		move.w	#$3F8,$C81A		; energy
;		move.w	#$3F8,$C81C		; sword
;		move.w	#5,$C848		; lives
check_quit_key
		cmp.b	_keyexit(pc),d0
		beq.b	_quit
	rts
_quit
	pea	TDREASON_OK.w
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
KeyboardAga
		ror.b	#1,D0
		eori.b	#$FF,D0

		cmp.b	#$46,D0			; Del
		bne.b	.2

		move.w	#40,$5EB6.w		; ammo
		move.w	#$3F8,$C9F0		; sword
		move.w	#$3F8,$C9EE		; energy
		move.w	#5,$CA1C		; lives
.2
		bra.b	check_quit_key

;--------------------------------

Load
		movem.l	d0-a6,-(a7)

		btst	#0,D3
		bne	_savehighs

		cmp.l	#$300,a0
		bne	.loaddisk2
		lea	_savename(pc),a0	;filename
		move.l	_resload(pc),a3
		jsr	(resload_GetFileSize,a3)
		tst.l	d0
		beq	.loaddisk2
		movem.l	(a7),d0-a2
		move.l	#$200,d0
		move.l	d0,d1
		move.l	a0,a1
		lea	_savename(pc),a0	;filename
		jsr	(resload_LoadFileOffset,a3)
		bra	.skip
.loaddisk2	movem.l	(a7),d0-a6

		cmp.l	#$7dc3c,a0
		bne	.loaddisk
		lea	_savename(pc),a0	;filename
		move.l	_resload(pc),a3
		jsr	(resload_GetFileSize,a3)
		tst.l	d0
		beq	.loaddisk
		movem.l	(a7),d0-a2
		move.l	a0,a1
		lea	_savename(pc),a0	;filename
		jsr	(resload_LoadFile,a3)
		bra	.skip
.loaddisk	movem.l	(a7),d0-a6

		moveq	#0,D0
		move.w	D1,D0
		mulu	#512,D0

		moveq	#0,D1
		move.w	D2,D1
		mulu	#512,D1

		moveq	#0,D2
		move.b	D4,D2

		bsr	_LoadDisk


		btst	#4,D3			; if must be decrunched
		beq.b	.skip

		btst	#5,D3
		beq.b	.skip2

		move.l	A2,A0
.skip2
		jsr	$11A0.w			; decrunch (run length custom encoder?)

; level code patch. A0 is typically 2CA24
	cmp.l	#$04790032,$2F3E2-$2CA24(a0)
	bne.b	.nolev14
	move.l	a0,a1
	lea	pl_levels_14(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	bra.b	.skip
.nolev14
	cmp.l	#$0479007d,$2E5F0-$2CA24(A0)
	bne.b	.levels6_8
	; level 5
	move.l	a0,a1
	lea	pl_level_5(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	bra.b	.skip
.levels6_8
	cmp.l	#$04790019,$2F524-$2CA24(A0)
	bne.b	.levels_910
	; levels 6 to 8
	move.l	a0,a1
	lea	pl_levels_68(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	bra.b	.skip
.levels_910
	cmp.l	#$04790021,$2EF9C-$2CA24(A0)
	bne.b	.skip
	; levels 9 & 10
	move.l	a0,a1
	lea	pl_levels_910(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)

	
.skip

exit
		bsr	_flushcache
		movem.l	(A7)+,d0-a6

		moveq	#0,D0
		rts

set_max_specials_910:
	move.w	#10,d0
	MOVE.W	D0,$2faaa
	MOVE.W	D0,$2faa2
	rts
	
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

pl_level_5:
	PL_START

	PL_IFC1X	1
	PL_CW	$2E5F2-$2CA24	; energy
	PL_B	$2E92E-$2CA24,$4A
	PL_CW	$2EB98-$2CA24	; energy
	PL_B	$2F450-$2CA24,$4A
	PL_ENDIF
	PL_IFC1X	0
	PL_B	$30010-$2CA24,$4A	; lives
	PL_ENDIF
	PL_END


pl_levels_910:
	PL_START
	PL_IFC1X	3
	PL_P	$2E16E-$2CA24,set_max_specials_910
	PL_ENDIF
	PL_IFC1X	1
	PL_CW	$2EF9E-$2CA24		; energy
	PL_CW	$2F64E-$2CA24		; energy
	PL_B	$2F9C4-$2CA24,$4A		; energy
	PL_CW	$2FE96-$2CA24		; energy
	PL_CW	$30024-$2CA24		; energy
	PL_CW	$301F6-$2CA24		; energy
	PL_CW	$314fC-$2CA24		; energy
	PL_B	$31792-$2CA24,$4A		; energy
	PL_CW	$31B26-$2CA24		; energy
	PL_ENDIF
	PL_END
	
pl_levels_68:
	PL_START
	PL_IFC1X	3
	PL_B	$2e26D-$2CA24,10
	PL_ENDIF
	PL_IFC1X	1
	PL_B	$2ED30-$2CA24,$4A		; energy
	PL_CW	$2F526-$2CA24		; energy
	PL_B	$2FEE6-$2CA24,$4A		; energy
	PL_B	$3022A-$2CA24,$4A		; energy
	PL_CW	$303A6-$2CA24		; energy
	PL_CW	$3087A-$2CA24		; energy
	PL_B	$30E64-$2CA24,$4A		; energy
	PL_CW	$30F6C-$2CA24		; energy
	PL_CW	$3178E-$2CA24		; energy
	PL_CW	$31A86-$2CA24		; energy
	PL_CW	$31D24-$2CA24		; energy
	PL_CW	$321FA-$2CA24		; energy
	PL_CW	$3260C-$2CA24		; energy	
	PL_ENDIF
	PL_END
	
pl_levels_14:
	PL_START
	PL_IFC1X	3
	; maxed special items
	PL_B	$2e34F-$2CA24,10
	PL_ENDIF
	
	PL_IFC1X	1
	PL_NOP	$2F3E2-$2CA24,8	; bats
	PL_NOP	$2f55e-$2CA24,8
	PL_NOP	$2f834-$2CA24,8
	PL_NOP	$2fd7a-$2CA24,8
	PL_NOP	$30020-$2CA24,8
	PL_NOP	$304ea-$2CA24,8
	PL_NOP	$30792-$2CA24,8
	PL_NOP	$3133a-$2CA24,8
	PL_NOP	$314bc-$2CA24,8
	PL_NOP	$31940-$2CA24,8
	PL_NOP	$31c76-$2CA24,8
	PL_NOP	$31e30-$2CA24,8
	PL_NOP	$320E2-$2CA24,8	; big head
	PL_NOP	$322de-$2CA24,8
	PL_NOP	$323d6-$2CA24,8
	PL_NOP	$32952-$2CA24,8
	PL_NOP	$32a4c-$2CA24,8
	PL_NOP	$32ef2-$2CA24,8
	PL_ENDIF
	PL_END
;--------------------------------

_savehighs
		move.l	#$400,d0		;len
		lea	(A0),a1			;address
		lea	_savename(pc),a0	;filename
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)

		bra	exit

;--------------------------------

Loadaga
		movem.l	d0-a6,-(a7)

		btst	#0,D3
		bne.b	_savehighs

		moveq	#0,D0
		move.w	D1,D0
		mulu	#512,D0

		moveq	#0,D1
		move.w	D2,D1
		mulu	#512,D1

		moveq	#0,D2
		move.b	D4,D2

		bsr.b	_LoadDisk

		btst	#4,D3			; if must be decrunch
		beq.b	.skip

		btst	#5,D3
		beq.b	.skip2

		move.l	A2,A0
.skip2
		jsr	$11BA.w			; decrunch
.skip
		movem.l	(A7)+,d0-a6

		moveq	#0,D0
		rts

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

_savename	dc.b	'FirstSamurai.Highs',0
Text		dc.b	'Press fire'
		even

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_trainer	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_second_button_jumps	dc.l	0
		dc.l	0
		
; speed regulation part

vbl_counter:
	dc.l	0
previous_joy:
	dc.l	0
	
slowdown:
	movem.l	D0,-(a7)
	move.l	vbl_counter(pc),d0
	sub.l	#$D38,d0		; value measured with "exact cycle"
	bmi.b	.skip
	lsr.l	#8,d0
	beq.b	.skip
	bsr	beamdelay
.skip
	movem.l	(a7)+,d0
	rts
	
	
; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
	; 17CB7, 8DAA: A1200 cycle exact??, D37: A500 cycle exact
calibrate_delay_loop
	lea	_custom,a2
	move.w	#$4000,(intena,a2)
.vbl
	btst	#5,(intreqr+1,a2)
	beq.b	.vbl
	
	move.w	#$3FFF,(intreq,a2)
	move.l	#0,d0
.loop
	add.l	#1,d0
	btst	#5,(intreqr+1,a2)
	beq.b	.loop
	
	move.w	#$C000,(intena,a2)
	lea	vbl_counter(pc),a2
	move.l	d0,(a2)
	rts	
	
		include	"ReadJoyPad.s"
		
;======================================================================

	END
