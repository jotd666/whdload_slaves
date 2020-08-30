;*---------------------------------------------------------------------------
;  :Program.	TheBluesBrothers.asm
;  :Contents.	Slave for "The Blues Brothers" from Titus
;  :Author.	Mr.Larmer of Wanted Team, StingRay
;  :History.	23.06.01.
;       2019 (JOTD)
;       - added CD32 joypad controls
;       - added option to jump with second button
;		21.11.17 (StingRay)
;		- byte write to volume register fixed
;		- default quitkey changed to Del
;		- main.prg is now loaded directly, loader stuff removed
;		- patch now uses real files
;		- illegal copperlist entry fixed
;		- interrupts fixed
;		22.11.17
;		- protection check removal simplified
;		- 68000  quitkey support
;		23.11.17
;		- trainer options added
;		- WHDLoad v17+ needed now (config)
;		- sample player fixed (took a while!)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44, ASM-Pro 1.16d
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


	IFD	BARFLY
	OUTPUT	TheBluesBrothers.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER

	DOSCMD	"WDate  >T:date"
	ENDC

CHIPMEMSIZE = $80000

;============================================================================

HEADER
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_Disk|WHDLF_ClearMem	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$46			;ws_keyexit = Del
_expmem		dc.l	0
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info


; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:X:Unlimited Lives:0;"
	    dc.b	"C1:X:Unlimited Energy:1;"
        dc.b    "C2:X:blue/second button jumps:0;"
		dc.b	"C3:X:use disk.1 image instead of files:0;"
        dc.b    "C4:L:Start level:The Department Store,The Warehouse,The Jail,The Sewer,The High Rises,The Gig;"
	dc.b	0

; to turn off music completely: $3BF30 <= $60

; character data: base $45F3E (v2)  $45F52 (v1)
; +$01: state/animation frame
; 1: on ground, 8: on ladder, 0x2D, 0x30 swimming
;              $E: carrying crate, $3 walking
; +$08: direction 0/1 left right
; +$14.W: X coord target
; +$16.W: Y coord target

; target (teleport) coords: $45F52 (X) $45F56 (Y)
;
; TODO: 
;       sound off avec manette
;       pb 2eme bouton avec Jake: ok avec le grand, tester avec le petit
; mode 2 joueurs
;============================================================================

DECL_VERSION:MACRO
	dc.b	"1.6"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_data		dc.b	"data",0

_name		dc.b	"The Blues Brothers",0
_copy		dc.b	"1991 Titus",0
_info		dc.b	"adapted by Mr.Larmer & JOTD & StingRay",10,10
		dc.b	"CD32 controls (player 1)",10,10
		dc.b 	"play: pauses game",10
		dc.b	"rev+fwd: quits current game",10
		dc.b	"rev+fwd+play: quits to wb",10
		dc.b	"green: toggles music",10,10
		dc.b	"yellow: toggles filter",10,10
		dc.b	"Greetings to H. Motzkau & X. Bodenand",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

main		dc.b	"Main.prg",0

		dc.b	"$","VER: slave "
		DECL_VERSION
		dc.b	0


		EVEN

IGNORE_JOY_DIRECTIONS = 1

	include	"ReadJoyPad.s"
		
;============================================================================
_start	;	A0 = resident loader
;============================================================================

	lea	resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	bsr	_detect_controller_types
	
	lea	main(pc),a0
	lea	$2000.w,a1
	jsr	resload_LoadFile(a2)
	lea	$2000.w,a0
	jsr	resload_CRC16(a2)
	lea	pl_main_2(pc),a3
	cmp.w	#$8f1f,d0		; SPS 3081
	beq.b	.ok
	lea	pl_main_1(pc),a3
	cmp.w	#$a75d,d0		; SPS 3082
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.ok

; decrunch
	bsr	Decrunch

; patch
	;;movem.l	d0-d2/a0-a2,-(a7)
	
	pea	handle_current_level(pc)
	move.l	(a7)+,$BC.W

	lea	$30000,a1
	lea	player_1_structure(pc),a0
	move.l	($2370,a1),(a0)	; get address, depending on version
	lea	player_2_structure(pc),a0
	move.l	($237A,a1),(a0)
	
	lea	key_table(pc),a0
	move.l	a1,a2
	add.l	#$DD2C,a2
	move.l	(a2),(a0)	; get address of key table, depending on version
	
	
	move.l	a3,a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

	move.l	#$30000,d0
	move.l	d0,$8.w
	move.l	d0,12.w
	move.l	d0,$14.w
	move.l	d0,$1c.w		; was $1FF? WTF!!!

	move.w	#$83c0,$dff096

	jmp	$30000

AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte



pl_main_common_12
	PL_START
	PL_S	$df42,$df56-$df42	; skip drive access
	; trap to get current level address (regardless of the version)
	PL_W	$250,$4E4F

	PL_R	$E446			; disable drive access (motor on)
	PL_R	$E45E			; disable drive access (motor off)

	PL_IFC3
	PL_P	$E476,LoadDiskImage
	PL_ELSE
	PL_P	$e210,.load
	PL_ENDIF
	
	PL_R	$e802			; disable protection track check


	PL_PS	$b212,.fixcop

	PL_PSS	$bfc8,.ackVBI_R,2
	PL_PSS	$bfec,.ackBLT,2

	PL_PS	$dcd4,.checkquit

	PL_PS	$6736,.fix_af_level_5_1
	PL_PS	$6760,.fix_af_level_5_1
	PL_PS	$6744,.fix_af_level_5_2
	
	PL_IFC1X	0
	PL_B	$4cfa,$4a		; unlimited lives
	; enable original trainer with level select on start screen
	PL_NOP	$4D18,2
	; allow 1-6 keys to select start level, but also allow to
	; do it with joypad
	PL_PSS	$3808,select_start_level,2
	PL_ENDIF

	PL_IFC1X	1
	PL_B	$8822,$4a		; unlimited energy
	PL_ENDIF
	PL_IFC2
	PL_PS	$DE6E,read_joy_directions_jump_button_player_1
	PL_PS	$DE8A,read_joy_directions_jump_button_player_2
	PL_ELSE
	; no need to change port 0 controls, port 1 has the pause and all
	PL_PS	$DE6E,read_joy_directions_jump_up	
	PL_ENDIF
	PL_END

	; on level 5, A4 is junk and an access fault
	; is triggered when reading from it. Running the game
	; with MMU off in WinUAE makes the game work, so I just
	; write 0 in the original target, that should do
.fix_af_level_5_1:
	cmp.l	#$80000,a4
	bcc.b	.avoid_af
	MOVE.B	0(A4,D0.L),1(A3)
	rts
.avoid_af
	clr.b	1(a3)
	rts
.fix_af_level_5_2:
	MOVE.B	2(A3),D0		;36744: 102B0002
	cmp.l	#$80000,a4
	bcc.b	.avoid_af_2
	CMP.B	(A4),D0			;36748: B014
	rts
.avoid_af_2
	cmp.b	$4,d0
	rts
	
	
.checkquit
	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0

	cmp.b	#$36,d0
	bne.b	.noN
	st	$30000+$11d7b
.noN

	cmp.b	_base+ws_keyexit(pc),d0
	beq.w	QUIT
	move.b	$bfec01,d0
	rts	


.ackVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

.ackVBI_R
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts

.ackBLT	move.w	#1<<6,$dff09c
	move.w	#1<<6,$dff09c
	rts


.fixcop	move.w	#1<<9,$30000+$b6d6+2	; fix trashed Bplcon0 in copperlist
	add.w	#10,a0		; optimised :) original code
	rts


.load	move.l	a6,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,d0-a6
	moveq	#0,d0
	unlk	a6
	rts


ackAUD	move.w	#1<<7,$9c(a0)
	move.w	#1<<7,$9c(a0)
	rts


; complex because doesn't depend on data address
; reads directly from the code
handle_current_level
	movem.l	a0-a1/d0,-(a7)
	; return address (depends on the number of saved registers above)
	move.l	14(A7),a0
	move.l	(a0),a0
	lea	current_level_address(pc),a1
	move.l	a0,(a1)
	move.b	start_level+3(pc),(a0)
	movem.l	(a7)+,a0-a1/d0
	add.l	#$4,2(a7)
	rte
	
; only called in the menu
select_start_level
	movem.l	a0/d0-d1,-(a7)
	move.l	current_level_address(pc),a0
	move.l	previous_button_states(pc),d1
	move.l	button_states(pc),d0
	not.l	d1
	and.l	d1,d0

	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nofwd
	move.w	#$F0,$DFF180
	addq.b	#1,(a0)
	cmp.b	#6,(a0)
	bne.b	.noz
	clr.b	(a0)
.noz
.nofwd
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.norev
	tst.b	(a0)
	bne.b	.z
	move.b	#6,(a0)
	move.w	#$F00,$DFF180
.z
	sub.b	#1,(a0)
.norev
	movem.l	(a7)+,a0/d0-d1
	rts
	
; SPS 3082
pl_main_1
	PL_START
	PL_PSS	$ED5C,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$ED74,FixDMAWait,2	; fix DMA wait in replayer

	PL_P	$f0a4,FixAudXVol	; fix byte write to volume register
	PL_B	$f3b5,0			; fake result of protection check

	PL_PSS	$f134,FixSamplePlayer,2	; make sure samples are played properly
	PL_PS	$f18c,ackAUD


	PL_NEXT	pl_main_common_12


; SPS 3081
pl_main_2
	PL_START
	PL_PSS	$ED48,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$ED60,FixDMAWait,2	; fix DMA wait in replayer

	PL_P	$f090,FixAudXVol	; fix byte write to volume register
	PL_B	$f3a1,0			; fake result of protection check

	PL_PSS	$f120,FixSamplePlayer,2	; make sure samples are played properly
	PL_PS	$f178,ackAUD


	PL_NEXT	pl_main_common_12

FixSamplePlayer
	move.w	#$8001,$dff096		; original code

FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait	
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

EMUKEY:MACRO
	btst	#\2,d0
	beq.b	.no\2
	; just pressed
	move.b	#1,(\1,A5)
	bra.b	.norel\2
.no\2
	btst	#\2,d1
	beq.b	.norel\2
	; just released
	move.b	#1,(\1+$80,A5)
.norel\2
	ENDM
	
read_joy_directions_jump_button_player_1:
	movem.l	d1-d2/a1,-(a7)
	bsr	read_joy_directions
	move.l	button_states(pc),d0
	moveq.l	#0,d1
	move.l	player_1_structure(pc),a1
	move.w	$DFF00C,D1
	bsr	handle_up
	movem.l	(a7)+,d1-d2/a1	
	rts
read_joy_directions_jump_button_player_2:
	movem.l	d1-d2/a1,-(a7)
	moveq.l	#0,d0
	bsr	_read_joystick
	moveq.l	#0,d1
	move.l	player_2_structure(pc),a1
	move.w	$DFF00A,D1
	bsr	handle_up
	movem.l	(a7)+,d1-d2/a1	
	rts
	

; < D0: button press state for port x
; < D1: JOYxDAT
; < A1: player x structure

handle_up:
	; testing various character frames to see if he's on ladder, baloon
	; and cancel "up" only if walking or carrying a crate
	; there are more frames like this as the 2nd character has some different
	; frame indexes
	move.b	(1,a1),d2
	cmp.b	#$32,d2
	bcs.b	.elwood
	sub.b	#$32,d2
.elwood
	cmp.b	#$8,d2		;  ladder: use normal UP
	beq.b	.no_blue
	cmp.b	#$9,d2		;  ladder ?
	beq.b	.no_blue
	cmp.b	#$10,d2		; on ground, carrying crate
	bcc.b	.no_blue	; !=8 and 9 and >=10: swimming, balloon, whatever: use normal UP
.go
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
	rts
	
read_joy_directions_jump_up:
	bsr	read_joy_directions
	move.w	$DFF00C,D0
	rts
	
read_joy_directions:
	movem.l	d1-d3/a0-a1/a5,-(a7)
	lea	button_states(pc),a0
	lea	previous_button_states(pc),a1
	move.l	(a0),(a1)		; save previous state
	moveq.l	#1,d0
	bsr	_read_joystick
	move.l	d0,(a0)
	
	; quit slave
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nq
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nq
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nq
	bra		QUIT
.nq	
	;;move.l	button_states(pc),d0
	move.l	key_table(pc),a5
	
	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_pause

	; custom pause, as it's as easy as plugging unpause
.waitrel
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	bne.b	.waitrel
.waitpress
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	beq.b	.waitpress
.waitrel2
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_pause
	
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nq2
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nq2
	bra		QUIT
.nq2
	
	bra.b	.waitrel2
	
.no_pause
	move.l	previous_button_states(pc),d1
	move.l	button_states(pc),d0

	
	btst	#JPB_BTN_YEL,d0	; yellow on?
	beq.b	.noyel
	btst	#JPB_BTN_YEL,d1	; was it pressed previously?
	bne.b	.noyel
	; first time pressed: filter on/off
	eor.b	#1,($35B-$2B4,a5)
.noyel

	btst	#JPB_BTN_GRN,d0	; green pressed
	beq.b	.grn_out
	; gree pressed was it pressed previously?
	btst	#JPB_BTN_GRN,d1
	bne.b	.grn_out
	; this is strange, as this seems to match the "F2 released" event
	; but it doesn't seem so trivial. Toggling values 0 <=> 1 disables/enables music
	eor.b	#1,($AE,A5)
.grn_out

	; F5: $2B (as released): quits
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noquit
	move.b	#1,($AB,A5)
.noquit

	
	movem.l	(a7)+,d1-d3/a0-a1/a5
	RTS
	
_read_joystick_port_1
	moveq.l	#1,d0
	bsr	_read_joystick
	rts
	
;.no_bluex
;	blitz
;	bra.b	.no_blue
music_off:
	dc.w	0
	
;--------------------------------
button_states
	dc.l	0
previous_button_states
	dc.l	0

resload	dc.l	0		;address of resident loader

;--------------------------------

LoadDiskImage
		movem.l	d0-d2/a0-a2,-(a7)

		swap	d0
		clr.w	d0
		swap	d0

		swap	d1
		clr.w	d1
		swap	d1

		subq.w	#1,d0
		mulu.w	#$200,d0

		mulu.w	#$2800,d1
		add.l	d1,d0

		move.l	#$200,d1
		moveq	#1,d2
		move.l	a2,a0

		bsr.b	_LoadDisk

		movem.l	(a7)+,d0-d2/a0-a2
		rts

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d2/a0-a2,-(a7)
		move.l	resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d2/a0-a2
		rts
player_1_structure:
	dc.l	0
player_2_structure:
	dc.l	0
key_table:
	dc.l	0
_tag		
		dc.l	WHDLTAG_CUSTOM4_GET
start_level	dc.l	0
		dc.l	0
current_level_address
		dc.l	0

Decrunch
	lea	$2000.w,a0
	move.l	(a0)+,d4		; size of decrunched data

	move.l	#83848,d4		; there is some crap at the end
					; of the file so we adapt the size
	move.b	5(a0),d0
	lsl.w	#8,d0
	move.b	4(a0),d0

	lea	$30000,a2		; destination

	clr.w	d3
	lea	$2000.w,a1
	addq.w	#6,a1

	add.l	#$400,a1
.empty
	move.w	(a1)+,d1
	moveq	#17,d0
.loop0	subq.w	#1,d0
	beq.b	.empty
	rol.w	#1,d1
	bhs.b	.go
	addq.w	#2,d3
.go	lea	$2000.w,a0
	add.w	#10,a0
	add.w	d3,a0


	move.b	1(a0),d3
	lsl.w	#8,d3
	move.b	(a0),d3

	tst.w	d3
	bpl.b	.loop0
	move.b	(a0),(a2)+
	clr.w	d3
	subq.l	#1,d4
	bne.b	.loop0
	rts


