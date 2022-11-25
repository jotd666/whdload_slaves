***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        RISKY WOODS WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               June 2016                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 07-Dec-2017	- in-game key handling changed, now using the game
;		  loop instead of the keyboard interrupt for checking keys
;		- more trainer options added
;		- ButtonWait support for intro added
;		- high score saving disabled if trainer options used

; 06-Dec-2017	- high score load/save added
;		- blitter waits only installed on 68010+ machines
;		- keyboard routine fixed
;		- more trainers added

; 28-Nov-2017	- a few more blitter waits added
;		- interrupts fixed
;		- trainer options added
;		- buggy DMA waits fixed

; 29-Jun-2016	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	whdmacros.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"BW;"
	dc.b	"C1:X:Unlimited Energy:0;"
	dc.b	"C1:X:Unlimited Time:1;"
	dc.b	"C1:X:Start with full Weapon Power:2;"
	dc.b	"C1:X:Never lose Weapon Power:3;"
	dc.b	"C1:X:Bad Extras have no Effect:4;"
	dc.b	"C1:X:Start with max. Money:5;"
	dc.b	"C1:X:In-Game Keys (ENHTAFI):6;"
	dc.b	"C2:B:2nd button jumps:0"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"CODE:SOURCES_WRK/WHD_Slaves/RiskyWoods/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Risky Woods",0
.copy	dc.b	"1992 Dinamic",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Joypad additions by JOTD",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
Name	dc.b	"RW",0
HiName	dc.b	"RiskyWoods.high",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
TRAINEROPTIONS	dc.l	0
		dc.l	TAG_END

resload	dc.l	0

IGNORE_JOY_DIRECTIONS = 1
	include		ReadJoyPad.s
	
Patch
	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	bsr	_detect_controller_types
; install keyboard irq
	bsr	SetLev2IRQ


; load game
	lea	Name(pc),a0
	lea	$273e0,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$27c4,d0
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; patch
	lea	PLGAME(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0			; carry: AFB_68010 bit
	bcc.b	.is68000
	lea	PLBLIT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)
.is68000

	move.l	HEADER+ws_ExpMem(pc),$25ea(a5)


; load high scores
	lea	HiName(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HiName(pc),a0
	lea	$16(a5),a1
	jsr	resload_LoadFile(a2)	
.nohigh

; and start game
	jmp	(a5)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

AckLev6	tst.b	$bfdd00
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte



PLBLIT	PL_START
	PL_PS	$41e8,.wblit1
	PL_PSS	$4236,.wblit2,4
	PL_PS	$4222,.wblit3
	PL_PS	$4974,.wblit1
	PL_PS	$4cb0,.wblit4
	PL_PS	$4d6c,.wblit5
	PL_PS	$49ce,.wblit4
	PL_PS	$4c42,.wblit1
	PL_END


.wblit1	bsr.b	WaitBlit
	move.w	#$ffff,$46(a6)
	rts

.wblit2	bsr.b	WaitBlit
	move.l	a1,$54(a6)
	move.w	#$401,$58(a6)
	rts

.wblit3	bsr.b	WaitBlit
	and.l	#$7f80,d0
	rts

.wblit4	bsr.b	WaitBlit
	add.l	#$1f80,a0
	rts

.wblit5	bsr.b	WaitBlit
	add.l	#$1f80,a3
	rts


WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


KEYCODE = $00027ca6


joystick_no_ints
	; menu seems to abuse CIAs and tampers with joypad read
	; block the interrupts to read joypad properly (okay in game)
	move.w	#$4000,$DFF09A
	bsr	_joystick
	move.w	#$C000,$DFF09A
	move.l	joy1(pc),d0
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noexit
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noexit
	btst	#JPB_BTN_PLAY,d0
	beq.b	.noexit
	pea	(TDREASON_OK).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)	
.noexit
	rts
	
read_joypad_menu:
	movem.l	d0/a1,-(a7)
	lea	KEYCODE,a1
	
	bsr	joystick_no_ints
	btst	#JPB_BTN_REVERSE,d0
	bne.b	.f1_pressed
	CMP.B #$50,(a1)
	BNE.B .nof1
.f1_pressed
	bsr	joystick_no_ints
	btst	#JPB_BTN_REVERSE,d0
	bne.b	.f1_pressed
	CMP.B #$50,(a1)
	BEQ.B .f1_pressed
	; toggle flag for music
	NOT.W $000299fe
.nof1
	btst	#JPB_BTN_FORWARD,d0
	bne.b	.f2_pressed
	CMP.B #$51,(a1)
	BNE.B .nof2
.f2_pressed
	bsr	joystick_no_ints
	btst	#JPB_BTN_FORWARD,d0
	bne.b	.f2_pressed
	CMP.B #$51,(a1)
	BEQ.B .f2_pressed
	; toggle flag for music
	NOT.W $0002828a
.nof2
	movem.l	(a7)+,d0/a1
	rts

	
pl_menu
	PL_START
	PL_PS	$3719A,read_joypad_menu
	PL_S	$000371A0,$D2-$A0
	PL_END


PLGAME
	PL_START
	PL_PSS	$32A92-$273E0,.read_joypad,2
	PL_PSS	$32A70-$273E0,.wait_pause_release,2
	PL_PSS	$32A9C-$273E0,.wait_pause_release,2
	PL_PSS	$32AAC-$273E0,.clear_key_test_esc,2
	PL_PS	$29E2E-$273E0,.menu_loaded

	PL_SA	$2648,$2670		; skip relocating
	PL_R	$19c2			; disable disk drive check
	PL_P	$1f62,.checkextmem
	PL_P	$1a46,.load
	;PL_R	$293e			; disable protection code
	PL_R	$2900			; don't load and run protection code
	PL_SA	$1e36,$1e60		; skip drive access (drive off)

	PL_PS	$c0a8,.ackVBI
	PL_PS	$bee6,.ackCOP
	

	PL_PSA	$10e8,FixDMAWait,$110a
	PL_P	$1138,FixDMAWait
	PL_PSA	$148c,FixDMAWait,$14ae
	PL_P	$1544,FixDMAWait


	PL_PS	$2d42,.savehigh
	PL_PSS	$2e7a,.setkbd,2
	PL_R	$8aa			; end keyboard interrupt code


; unlimited energy
	PL_IFC1X	0
	PL_PS	$3456,.energy
	PL_ENDIF

; unlimited time
	PL_IFC1X	1
	PL_B	$322e,$4a
	PL_ENDIF


; start with full weapon power
	PL_IFC1X	2
	PL_W	$2706+2,3
	PL_ENDIF

; never lose weapon power
	PL_IFC1X	3
	PL_B	$34fa,$4a
	PL_ENDIF

; bad extras have no effect
	PL_IFC1X	4
	PL_B	$9254,$60
	PL_B	$928a,$60
	PL_R	$912c
	PL_ENDIF

; start with max. money
	PL_IFC1X	5
	PL_S	$270e,6
	PL_W	$368e,$999
	PL_ENDIF

; in-game keys, same offset as read_joypad
	PL_IFC1X	6
	PL_PSS	$b67e,.checkkeys,2
	PL_ELSE
	PL_PSS	$b67e,.read_joypad,2	
	PL_ENDIF
	
	PL_IFBW
	PL_PS	$28fa,.waitbutton
	PL_ENDIF

	PL_IFC2
	PL_PS	$D42-$3E0,.read_joy1dat_d1_button_jumps
	PL_ENDIF
	PL_END

	
.waitbutton
	jsr	$121e4
	move.l	#30*10,d0		; show intro for 30 seconds
	move.l	resload(pc),a0
	jmp	resload_Delay(a0)

.menu_loaded:
	movem.l	d0-d1/a0-a2,-(a7)
	sub.l	a1,a1
	move.l	resload(pc),a2
	lea	pl_menu(pc),a0
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	JMP $00028004
	

.read_joypad
	bsr	_joystick
	movem.l	d0/a1,-(a7)
	lea	KEYCODE,a1
	move.l	joy1(pc),d0
	btst	#JPB_BTN_PLAY,d0
	beq.b	.noplay
	move.b	#$19,(a1)
.noplay
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	btst	#JPB_BTN_PLAY,d0
	beq	.noexit
	pea	(TDREASON_OK).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)	
.noexit
	move.b	#$45,(a1)
.noesc
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nofwd
	btst	#JPB_BTN_YEL,d0
	beq.b	.nolskip
	move.b	#$36,(a1)
.nolskip
	btst	#JPB_BTN_GRN,d0
	beq.b	.norenergy
	move.b	#$12,(a1)
.norenergy
.nofwd

	CMP.B #$19,(a1)	; original
	movem.l	(a7)+,d0/a1
	RTS

.clear_key_test_esc
	movem.l	d0,-(a7)
	move.b	KEYCODE,d0
	clr.b	KEYCODE
	CMP.B #$45,d0
	movem.l	(a7)+,d0
	rts
	
.wait_pause_release
	bsr	_joystick
	movem.l	d0/a1,-(a7)
	lea	KEYCODE,a1
	move.l	joy1(pc),d0
	btst	#JPB_BTN_PLAY,d0
	bne.b	.play
	move.b	#$99,(a1)
.play
	CMP.B #$99,(a1)	; original
	movem.l	(a7)+,d0/a1
	RTS

.energy
	move.w	$273e0+$368a,d0
	bpl.b	.ok
	moveq	#0,d0
	clr.w	$273e0+$368a
.ok	rts

.checkkeys
	; call joypad read from there
	bsr	.read_joypad
	moveq	#0,d0
	move.b	KEYCODE,d0		; raw key

	cmp.b	#$12,d0			; E - refresh energy
	bne.b	.noE
	;move.w	#1,$273e0+$368a
	move.w	#43,$273e0+$3686
	jmp	$273e0+$342c
.noE

	cmp.b	#$36,d0			; N - skip level
	bne.b	.noN
	move.w	#1,$273e0+$ba74
	move.l	$273e0+$c360,a0
	move.w	#950,(a0)

.noN
	
	cmp.b	#$25,d0			; H - refresh time
	bne.b	.noH
	move.l	#"4:00",$273e0+$3642
	jsr	$273e0+$b760
	bra.b	.end
.noH

	cmp.b	#$14,d0			; T - toggle unlimited time
	bne.b	.noT
	eor.b	#$18,$273e0+$322e
.noT

	cmp.b	#$20,d0			; A - add money
	bne.b	.noA
	cmp.w	#$999,$273e0+$368e
	beq.b	.noA
	move.w	#1,$273e0+$3692
	jsr	$273e0+$35d8
	bra.b	.end
.noA

	cmp.b	#$23,d0			; F - get fire ball (10 seconds)
	bne.b	.noF
	jsr	$273e0+$9212
	bra.b	.end
.noF

	cmp.b	#$17,d0			; I - invincibility (10 seconds)
	bne.b	.noI
	jsr	$273e0+$9226
	;bra.b	.end
.noI



.end	cmp.b	#$19,$273e0+$8c6	; original code
	rts

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	Key(pc),d0
	jmp	$273e0+$88a


.savehigh
	move.l	TRAINEROPTIONS(pc),d0
	bne.b	.nosave
	jsr	$37000
	lea	HiName(pc),a0
	lea	$273e0+$16,a1
	move.l	#$e8-$16,d0
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)


.ackVBI	move.w	#1<<5,$9c(a6)
	move.w	#1<<5,$9c(a6)
.nosave	rts

.ackCOP	move.w	#1<<4,$9c(a6)
	move.w	#1<<4,$9c(a6)
	rts

.checkextmem
	moveq	#0,d0			; no ext. mem available
	rts
	;moveq	#1,d0			; ext. mem available
	;move.l	HEADER+ws_ExpMem(pc),$273e0+$25ea
	;rts

.read_joy1dat_d1_button_jumps:
; replace joystick UP by 2nd button
	movem.l	d0/a0,-(a7)
	move.l	joy1(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
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
	movem.l	(a7)+,d0/a0
	LSL.W #$08,D0		; original
	RTS	
;00027D42 e148                     LSL.W #$08,D0
;00027D44 322e 000c                MOVE.W (A6,$000c) == $00dff00c,D1

; a4.l: destination
; d3.l: file number

.load	cmp.l	#"RWD2",$273e0+$178e
	bne.b	.nodisk2
	addq.w	#6,d3		; adapt file number
.nodisk2

	move.l	a4,a5
	move.w	d3,d0
	lea	Name(pc),a0
	bsr.b	.convName	; build file name
	move.l	a4,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	moveq	#0,d0		; no errors
	rts


.convName
	movem.l	d0/d1/a0,-(a7)
	moveq	#2-1,d3		; max. 2 digits
	lea	.TAB(pc),a1
.loop	moveq	#-"0",d1
.loop2	sub.w	(a1),d0
	dbcs	d1,.loop2
	neg.b	d1
	move.b	d1,(a0)+
.nope	add.w	(a1)+,d0
	dbf	d3,.loop
	movem.l	(a7)+,d0/d1/a0
	rts

.TAB	dc.w	10
	dc.w	1



WaitRaster
.wait	btst	#0,$dff005
	beq.b	.wait
.wait2	btst	#0,$dff005
	bne.b	.wait
	rts


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts


***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1


	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.w	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	lea	Key(pc),a2
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

	move.l	KbdCust(pc),d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom	
	


	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

.exit	pea	(TDREASON_OK).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine



