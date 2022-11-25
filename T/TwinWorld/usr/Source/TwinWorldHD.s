; v1.1, 02.11.2017, StingRay
; - RawDIC imager
; - Bplcon0 color bit fixes
; - DMA waits in replayer and sample player fixed 
; - trainers added (CUSTOM1/2/3)

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	WHDmacros.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG


HEADER	SLAVE_HEADER		; ws_Security+ws_ID
	dc.w	17		; ws_Version
	dc.w	FLAGS		; ws_Flags
	dc.l	$80000		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	0		; ws_CurrentDir
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


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Weapons:1;"
	dc.b	"C1:X:In-Game Keys:2;"
	dc.b	"C2:B:blue/second button jumps;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/UniversalWarrior",0
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

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

.name	dc.b	"Twinworld",0
.copy	dc.b	"1989 Ubi Soft",0
.info	dc.b	"installed by Harry & StingRay",10
    dc.b    "joypad adaptations by JOTD",10,10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version "
    DECL_VERSION
    dc.b    0
HighName
	dc.b	'twhigh',0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
TRAINER	dc.l	0

		dc.l	TAG_DONE

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

    bsr _detect_controller_types
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; install keyboard interrupt
	bsr	SetLev2IRQ

; load game
	moveq	#0,d0
	move.l	#$AFC8,d1
	lea	$6520.w,a0
	move.l	a0,a5
	move.l	d1,d5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$5a63,d0			; SPS 1294
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.ok

; install trainers
	move.l	TRAINER(pc),d0
    btst    #0,d0
	beq.b	.noLivesTrainer
	bsr	ToggleLives
.noLivesTrainer

	move.l	TRAINER(pc),d0
    btst    #1,d0
	beq.b	.noWeaponTrainer
	bsr.w	ToggleWeapons
.noWeaponTrainer



; patch game
	lea	PLGAME(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

; and run it
	jmp	(a5)

PLGAME	PL_START

; v1.0 patches by Harry
	PL_P	$9e4c,Loader
	PL_P	$9f3c,SaveHighscore
	PL_R	$9948			; disable drive access (motor on)
	PL_R	$994c			; disable drive access (motor off)
	PL_R	$9950			; disable loader init (drive ready)
	PL_R	$9954			; disable step to track 0
	PL_NOP	$312,2		; disable delay before loading
	PL_NOP	$33e,2		; disable delay after loading

; v1.1 patches by StingRay
	PL_ORW	$968+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$ad2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$cc8+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$7600,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1180,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$11b2,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$11c0,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$d54,.setkbd,4
	PL_R	$d78			; don't install exception handler
    
; v1.2 additions by JOTD
    PL_PS   $08186-$6520,test_fire
    PL_IFC2
    PL_PS   $00008114-$6520,read_joypad
    PL_ELSE
    PL_PS   $00008114-$6520,read_joystick
    PL_ENDIF
    PL_PSS  $81AA-$6520,change_spell,4
    PL_P    $75e0-$6520,unpause
    
    PL_PSS  $B8CC-$6520,FixDMAWait,2    ; fix DMA wait in menu music
    PL_PSS  $DC92-$6520,FixDMAWait,2    ; fix DMA wait in menu music
    
	PL_END


.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	RawKey(pc),d0
	move.b	d0,$6520+$1028.w

	move.l	TRAINER(pc),d1
    btst    #2,d1    
	beq.b	.nokeys
	lea	$6520.w,a5

	cmp.b	#$11,d0			; W - toggle unlimited weapons
	bne.b	.noW
	bsr.b	ToggleWeapons
.noW

	cmp.b	#$28,d0			; L - toggle unlimited lives
	bne.b	.noL
	bsr.b	ToggleLives
.noL

	cmp.b	#$01,d0			; 1 - 99 red bubbles
	bne.b	.nored
	move.b	#$99,$6520+$9196
.nored

	cmp.b	#$02,d0			; 2 - 99 green bubbles
	bne.b	.nogreen
	move.b	#$99,$6520+$9197
.nogreen

	cmp.b	#$03,d0			; 3 - 99 blue bubbles
	bne.b	.noblue
	move.b	#$99,$6520+$9198
.noblue


.nokeys
	rts


    
ToggleLives
	eor.w	#1,$424a+2(a5)
	eor.w	#1,$42c0+2(a5)
	eor.w	#1,$42d0+2(a5)
	rts

    
ToggleWeapons
	move.w	#$cf70,d0		; sbcd d1,d0 <-> nop
	eor.w	d0,$727e(a5)		; blue bubbles
	eor.w	d0,$728c(a5)		; red bubbles
	eor.w	d0,$729a(a5)		; green bubbles
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


Loader	movem.l	d1-a6,-(a7)
	cmp.b	#80,d0
	blo.b	.ok
	subq.w	#1,d0
.ok	subq.w	#1,d0
	cmp.l	#17,d0
	bne.b	.nohigh
	move.l	d0,d4
	move.l	d1,d5
	move.l	d2,d6
	move.l	a0,a4
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	LoadHighscore
	move.l	d4,d0
	move.l	d5,d1
	move.l	d6,d2
	move.l	a4,a0

.nohigh	mulu	#$1790,d0
	and.l	#$FFFF,d2
	add.l	d2,d0
	moveq	#1,d2
	move.l	resload(pc),a3
	jsr	resload_DiskLoad(a3)
	movem.l	(a7)+,d1-a6
	moveq	#0,d0
	rts

LoadHighscore
	lea	HighName(pc),a0
	move.l	a4,a1
	move.l	#110,d0
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(sp)+,d1-d7/a0-a6
	moveq	#0,d0
	rts

SaveHighscore
	movem.l	d1-d7/a0-a6,-(sp)
	cmp.w	#18,d0
	bne.b	QUIT

	move.l	TRAINER(pc),d0
	bne.b	.nosave

	move.l	a0,a1
	lea	HighName(pc),a0
	move.l	#110,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
.nosave
	movem.l	(sp)+,d1-d7/a0-a6
	moveq	#0,d0
	rts

resload	dc.l	0


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
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
	beq.b	.end

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

.exit	bra.w	QUIT

change_spell:
    movem.l d1,-(a7)
	CMP.B	#$40,D0			;081aa: b03c0040
	beq.S	.change		;081ae: 6604
    move.l  previous_joy(pc),d1
    btst    #JPB_BTN_YEL,d1
    bne.b   .nospace
    move.l  joy1(pc),d1
    btst    #JPB_BTN_YEL,d1
    beq.b   .nospace
.change
	BSET	#6,D7			;081b0: 08c70006
.nospace
    movem.l (a7)+,d1
    rts
    
test_fire:
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    
    RTS
    
KEYCODE = $7548

read_joypad
    bsr controls
    MOVE.W $00dff00c,D0

    movem.l d1,-(a7)
	move.l	joy1(pc),d1
	
	
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,D0
	btst	#9,D0
	beq.b	.noneed
	bset	#8,D0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,D0
	btst	#9,D0
	bne.b	.no_blue
	bset	#8,D0	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:
    movem.l (a7)+,d1

    rts
    
read_joystick
    bsr controls
    MOVE.W $00dff00c,D0
    rts

controls:
    movem.l d0/a0,-(a7)
    lea previous_joy(pc),a0
    move.l  joy1(pc),(a0)
    bsr _joystick
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    beq.b   .nopause
    move.b  #$19,KEYCODE
.nopause
    btst    #JPB_BTN_GRN,d0
    beq.b   .nomerchant
    move.b  #$25,KEYCODE
.nomerchant
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    move.b  #$45,KEYCODE        ; lose just 1 life when stuck
    btst    #JPB_BTN_GRN,d0
    beq.b   .noquit
    move.b  #$46,KEYCODE        ; give up
    btst    #JPB_BTN_YEL,d0
    bne QUIT        ; quit to wb
.noquit
    movem.l (a7)+,d0/a0
    rts
previous_joy
    dc.l    0


unpause
    clr.b   KEYCODE
.unp    
	BSR.S	get_keycode		;075e0: 612c
	CMP.B	#$19,D0			;075e2: b03c0019
	BEQ.S	.unp		;075e6: 67f8
.LAB_005C:
	BSR.S	get_keycode		;075e8: 6124
	CMP.B	#$19,D0			;075ea: b03c0019
	BNE.S	.LAB_005C		;075ee: 66f8
.LAB_005D:
	BSR.S	get_keycode		;075f0: 611c
	CMP.B	#$19,D0			;075f2: b03c0019
	BEQ.S	.LAB_005D		;075f6: 67f8
	RTS				;075f8: 4e75

get_keycode
    ; if play is pressed then set d0 to $19 else read keyboard
    bsr wait_vbl
    bsr _joystick
    movem.l d1,-(a7)
    move.l  joy1(pc),d1
    btst    #JPB_BTN_PLAY,d1
    movem.l (a7)+,d1
    beq.b   .noplay
    move.b  #$19,d0
    bra.b   .p_pressed
.noplay
    move.b  KEYCODE,d0
.p_pressed:
    rts
    
wait_vbl:
    movem.l d0/a0,-(a7)
	; wait for VBL
	lea	$DFF000,a0
	move.w	#$7FFF,intreq(a0)
.wait
	move.w	intreqr(a0),d0
	btst	#5,d0
	beq.b	.wait
    movem.l (a7)+,d0/a0
	rts    
    include     ReadJoypad.s

Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine
