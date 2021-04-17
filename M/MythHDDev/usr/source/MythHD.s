;*---------------------------------------------------------------------------
;  :Program.	Myth.asm
;  :Contents.	Slave for "Myth" from System 3
;  :Author.	Mr.Larmer of Wanted Team, Bored Seal
;  :History.	v1.0, v1.1 (27.07.1998)
;		v1.2 (14.06.2010) Bored Seal - slave remake, new fixes
;		v1.3 (12.08.2016) StingRay
;		- code optimised, source cleaned up and made 100% pc-relative
;		- Bored Seal added in info/credits text :)
;		- version check added
;		- uninitialised copperlist problem fixed
;		- one more blitter wait added
;		- updated to use WHDLoad v17+ features
;		- unlimited lives trainer added
;		- delay for level intro texts added (shown while loading)
;		- keyboard routine rewritten and 68000 quitkey support added
;		- timing fixed
;		- end sequence patched
;		v1.3a (13.08.2016)
;		- wrong blitter wait patch fixed
;		- delay for "System 3 presents" text added
;		- level skip added (key "N"), not for public consumption yet
;		- delay for Myth animation after game over added
;
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Asm-Pro 1.16d
;  :To Do.
;---------------------------------------------------------------------------*


		INCDIR	SOURCES:Include/
		INCLUDE	whdload.i
		include	whdmacros.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

;CHIP_ONLY

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

HEADER		SLAVE_HEADER
		dc.w	17		; ws_version
		dc.w	FLAGS		; ws_flags
        IFD CHIP_ONLY
		dc.l	$100000		; ws_BaseMemSize
        ELSE
		dc.l	$80000		; ws_BaseMemSize
        ENDC
		dc.l	0		; ws_ExecInstall
		dc.w	Patch-HEADER	; ws_GameLoader
		IFD	DEBUG
		dc.w	.dir-HEADER
		ELSE
		dc.w	0		; ws_CurrentDir
		ENDC
		dc.w	0
		dc.b	0
		dc.b	$59		; ws_keyexit
_expmem
        IFD CHIP_ONLY
		dc.l	0		; ws_BaseMemSize
        ELSE
		dc.l	$80000		; ws_BaseMemSize
        ENDC
		dc.w	.name-HEADER
		dc.w	.copy-HEADER
		dc.w	.info-HEADER

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"BW;"
	dc.b	"C1:B:Unlimited Lives;"
	dc.b	"C2:B:Second button jumps;"
	dc.b	0

DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
    
		IFD	DEBUG
.dir		dc.b	"SOURCES:WHD_Slaves/Myth",0
		ENDC
.name		dc.b	"Myth"
    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP mode)"
    ENDC
        dc.b    0
.copy		dc.b	"1992 System 3",0
.info		dc.b	"adapted by Mr.Larmer,Bored Seal,StingRay & JOTD",10
		DECL_VERSION
        dc.b    0

	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	$A,0
		even


IGNORE_JOY_DIRECTIONS    
    include "ReadJoyPad.s"
    
Patch		
        lea	resload(pc),a1
		move.l	a0,(a1)			;save for later use
		move.l	a0,a5

        ;get tags
		lea     (_tag,pc),a0
		jsr     (resload_Control,a5)
	    ;do not get the tags at reboot

        IFD CHIP_ONLY
        lea _expmem(pc),a0
        move.l  #$80000,(a0)
        ENDC
        lea rawkey_address(pc),a1
        move.l  _expmem(pc),d0
        add.l   #$166d0,d0
        move.l  d0,(a1)
        
		lea	$40000,A0
		move.l	#$2C00,D0
		move.l	#$E9A,D1
		moveq	#1,d2
		bsr	LoadDisk

; version check
	move.l	d1,d0
	jsr	resload_CRC16(a5)
	cmp.w	#$2499,d0			; SPS 700
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	jmp	resload_Abort(a5)
.ok	
	
		lea	PLBOOT(pc),a0
		suba.l	a1,a1
		jsr	resload_Patch(a5)

		jmp	$4000a

PLBOOT		PL_START
		PL_P	$4057a,Load
		PL_PA	$40092,.PatchGame
		PL_W	$40016,0		; set color 0 to 0
		PL_PS	$4023a,.get_extmem
        PL_S    $40240,$2C0-$240
		PL_NOP	$4030c,2		; clr.l $1C -> clr.l $1C(A6)
		PL_L	$4030e,$42ae001c
		PL_L	$40000-4,$33fc0000
		PL_END
.get_extmem
    move.l  _expmem(pc),d1
    rts
    
.PatchGame	
        bsr _detect_controller_types

        lea	PLGAME(pc),a0
		move.l  _expmem(pc),a1
		move.l	resload(pc),a5
		jsr	resload_Patch(a5)

		jmp	$800.w

PLGAME		PL_START

;Mr. Larmer's work - v1.0 and v1.1
		PL_R	$B146			; skip check how many disk drives connected
		PL_R	$B4C0			; remove disk access
		PL_P	$b4f8,ChangeDisk	; disk loader
		PL_P	$B5B8,Load

		PL_W	$0086,$605E		; skip set zero page vectors
		PL_B	$051a,$2f		; move.w A1,-(A7) -> move.l A1,-(A7)

		PL_PSS	$051c,Copylock,2		; crack the copylock

		PL_NOP	$3f7c,2		; clr.l $1C -> clr.l $1C(A6)
		PL_L	$3f7e,$42AE001C
		PL_PS	$E6A4,AccessFault
		PL_PS	$E6C0,AccessFault2

		PL_NOP	$98c4,2		; correct waitdma loop in music player
		PL_PS	$9eb8,PatchPlayer
		PL_PS	$a090,PatchPlayer

;Bored Seal's work - v1.2
		PL_IFBW				; stingray
		PL_PS	$0766,LogoWait		;waitbutton for flaming Myth logo
		PL_ENDIF
        IFD CHIP_ONLY
		PL_P	$c818,Decrunch		;decruncher in fast RAM
        ENDC
		PL_PS	$467e,BlitFix1		;blitter waits
		PL_PS	$ad84,BlitFix1
		PL_PS	$47dc,BlitFix2
		PL_PSS	$c0fe,Delay,2	;insert beam delays - game doesn't freezes anymore
		PL_PSS	$c14e,Delay,2

; StingRay's work -  v1.3
		PL_SA	$6be2,$6bea		; don't enable DMA yet
		PL_PSS	$6bf4,.enableDMA,2
		PL_PS	$5c96,.wblit2

		PL_IFC1
		PL_W	$13308,1
		PL_ENDIF

		;PL_W	$8081a+2,11

		PL_PS	$0d54,.delay		; show loading text for 6 seconds
		PL_PS	$3df4,.delay2		; same for end part text
		PL_PS	$05f8,.delay3

		PL_PS	$00e6,.setkbd
		PL_R	$420c		; end level 2 interrupt code

		PL_P	$6294,.waitraster; fix timing
		PL_P	$3f1c,.patchend

		PL_PS	$0ae4,.delay4		; delay for myth logo after game over
        
; JOTD work - v1.4
        PL_PS   $43ea,.vbl_hook
    
        PL_PS   $390a,.fire_read
        PL_IFC2
        PL_PS   $3900,.joydat_read
        PL_ENDIF
		PL_END
        
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d2
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    bset    #7,d3
.pressed_\1
    move.b  d3,(a1)
.nochange_\1
    ENDM
    
.fire_read
    move.l  prev_buttons_state(pc),d2
    btst    #JPB_BTN_RED,d2
    bne.b   .pressed
    st.b    d2
    rts
.pressed
    move.b  #$40,d2 ; no LMB, ever
    rts
    
.joydat_read:
    move.w  _custom+joy1dat,d0
    move.l  D1,-(a7)
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
    move.l  prev_buttons_state(pc),d1
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
    move.l  (a7)+,d1
    rts
.skip_vbl
    add.l   #$10,(a7)
    rts    
.vbl_hook
    btst    #5,d0
    beq.b   .skip_vbl
    movem.l d0-d3/a0-a1,-(a7)
    lea prev_buttons_state(pc),a0
    move.l rawkey_address(pc),a1
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_read_joystick
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d2 to get what has changed quickly
    move.l  d0,d2
    eor.l   d1,d2
    beq   .nochange   ; cheap-o test just in case no input has changed
    ; d2 bears changed bits (buttons pressed/released)
    TEST_BUTTON REVERSE,$4F
    TEST_BUTTON FORWARD,$4E
;    btst    #JPB_BTN_FORWARD,d0
;    beq.b   .no_skip
;    btst    #JPB_BTN_YEL,d0
;    beq.b   .no_skip
;    bsr skip_level
;.no_skip
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .no_esc
    TEST_BUTTON YEL,$45     ; quit    
    cmp.b   #$45,d3
    bne.b   .no_esc
    btst    #JPB_BTN_FORWARD,d0

    bne _exit
.no_esc
    move.b  buttonjumps+3(pc),d3
    beq.b   .blu
    TEST_BUTTON GRN,$40     ; select weapon
    bra.b   .skblu
.blu
    TEST_BUTTON BLU,$40     ; select weapon
.skblu
    TEST_BUTTON PLAY,$19     ; pause
.nochange    
    movem.l (a7)+,d0-d3/a0-a1
    rts

    
.delay4	movem.l	d0-a6,-(a7)
	bsr.w	.dodelay
	movem.l	(a7)+,d0-a6
    move.l  _expmem(pc),a1
	lea	$1d18(a1),a1
	rts

.patchend
    move.l  _expmem(pc),a2
	move.l	$13374,a0
	move.l	$13370,a1
    add.l   a2,a0
    add.l   a2,a1
    
	lea	.kbdcust(pc),a2
	clr.l	(a2)

	or.w	#1<<3,$2c44a+2		; enable level 2 interrupt

	move.w	#$4eb9,$2c9ee
	pea	.wblit2(pc)
	move.l	(a7)+,$2c9ee+2


	jmp	(a0)

.wblit2	lea	$dff000,a0
	bra.w	BlitWait

.waitraster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#250<<8,d0
	bne.b	.wait

.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#250<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
	rts

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	bra.w	SetLev2IRQ

.kbdcust
	move.b	RawKey(pc),d0

    IFD    DEBUG
	cmp.b	#$36,d0			; N - skip level
	bne.b	.noN
	;move.w	$80000+$16726,$80000+$16718
	;add.w	#$120,$80000+$16718
    bsr skip_level
.noN
    ENDC
    
    move.l  _expmem(pc),-(a7)
    add.l   #$4200,(a7)
    rts


.delay2	bsr.b	.dodelay
	move.l	#$204,d0
	rts

.delay3	
    pea .next3(pc)
    move.l  _expmem(pc),-(a7)
    add.l   #$1305E,(a7)
    rts
.next3
	movem.l	d0-a6,-(a7)
	bsr	.dodelay
	bsr	.dodelay
	movem.l	(a7)+,d0-a6
	rts

.delay		
    pea .next(pc)
    move.l  _expmem(pc),-(a7)
    add.l   #$15cc,(a7)
    rts
.next

.dodelay	moveq	#6*10,d0
		move.l	resload(pc),a0
		jmp	resload_Delay(a0)

.wblit		lea	$dff000,a6
		bra.w	BlitWait

.enableDMA	move.w	#$87d0,$dff096
		move.w	#0,$dff088
		rts
skip_level
    move.l  a0,-(a7)
    move.l  _expmem(pc),a0
    add.l   #$16718,a0
	move.w	#32767,(a0)
    move.l  (a7)+,a0
    rts
    
BlitFix1	move.w	d7,$dff058
BlitWait	;BLITWAIT
		tst.b	$dff002
.wblit		btst	#6,$dff002
		bne.b	.wblit
		rts

BlitFix2	move.w	d1,$dff058
		bra.b	BlitWait

LogoWait
    pea .next(pc)
    move.l  _expmem(pc),-(a7)
    add.l   #$b188,(a7)
    rts
.next
		;waitbutton
.wait
    move.l  prev_buttons_state(pc),d0
	beq.b	.wait
.out
		rts

Delay		move.l	d0,-(sp)
		moveq	#8,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0	; VPOS
BM_2		cmp.b	$dff006,d0
		beq.b	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
		move.l	(sp)+,d0
		rts

;Mr. Larmer's routines

AccessFault	and.l	#$FFFFFF,D0
		and.l	#$FFFFFF,D7
		sub.l	A1,A1
		rts

AccessFault2	and.l	#$FFFFFF,D6
		and.l	#$FFFFFF,D7
		sub.l	A1,A1
		rts

Copylock	move.l	#$96C1AAFE,D0
		move.l	D0,$60.w
        move.l  a0,-(a7)
        move.l  _expmem(pc),a0
        add.l   #$1334E,a0
        move.l  d0,(a0)
        move.l  (a7)+,a0
		rts

PatchPlayer	move.l	D0,-(A7)
		moveq	#0,D0
		move.b	2(A5),D0
		move.w	D0,8(A1)
		move.l	(A7)+,D0
		rts

ChangeDisk	move.l	A0,-(sp)
		lea	DiskNr(pc),A0
		moveq	#0,D0
		move.b	$20(A5),D0
		move.b	D0,(A0)
		addq.b	#1,(A0)
		move.l	(sp)+,A0
		rts

Load		movem.l	d0-a6,-(sp)

		move.w	D1,D0
		mulu	#512,D0
		move.w	D2,D1
		mulu.w	#512,D1
		move.b	DiskNr(pc),D2

		bsr.w	LoadDisk

		movem.l	(sp)+,d0-a6
		moveq	#0,D0
		rts
        
       IFD  CHIP_ONLY
Decrunch	MOVE.L	A1,A0
		ADDA.L	D0,A0
		MOVEA.L	-(A0),A2
		MOVE.L	A2,($8C8FA).L
		ADDA.L	A1,A2
		MOVE.L	-(A0),D5
		MOVE.L	-(A0),D0
		EOR.L	D0,D5
lab02		LSR.L	#1,D0
		BNE.B	lab01
		BSR.W	lab52
lab01		BCS.B	lab2
		MOVEQ	#8,D1
		MOVEQ	#1,D3
		LSR.L	#1,D0
		BNE.B	lab03
		BSR.W	lab52
lab03		BCS.B	lab31
		MOVEQ	#3,D1
		CLR.W	D4
lab08		BSR.W	lab6
		MOVE.W	D2,D3
		ADD.W	D4,D3
lab07		MOVEQ	#7,D1
lab06		LSR.L	#1,D0
		BNE.B	lab05
		BSR.W	lab52
lab05		ROXL.L	#1,D2
		DBRA	D1,lab06
		MOVE.B	D2,-(A2)
		DBRA	D3,lab07
		BRA.W	lab51

lab1		MOVEQ	#8,D1
		MOVEQ	#8,D4
		BRA.W	lab08

lab2		MOVEQ	#2,D1
		BSR.W	lab6
		CMPI.B	#2,D2
		BLT.B	lab3
		CMPI.B	#3,D2
		BEQ.B	lab1
		MOVEQ	#8,D1
		BSR.W	lab6
		MOVE.W	D2,D3
		MOVE.W	#12,D1
		BRA.W	lab31

lab3		MOVE.W	#9,D1
		ADD.W	D2,D1
		ADDQ.W	#2,D2
		MOVE.W	D2,D3
lab31		BSR.W	lab6
lab33		SUBQ.W	#1,A2
		MOVE.B	(A2,D2.W),(A2)
		DBRA	D3,lab33
lab51		CMPA.L	A2,A1
		BLT.W	lab02
		TST.L	D5
		MOVE.L	($8C8FA).L,D0
		RTS

lab52		MOVE.L	-(A0),D0
		EOR.L	D0,D5
		MOVE.W	#$10,CCR
		ROXR.L	#1,D0
		RTS

lab6		SUBQ.W	#1,D1
		CLR.W	D2
lab62		LSR.L	#1,D0
		BNE.B	lab61
		MOVE.L	-(A0),D0
		EOR.L	D0,D5
		MOVE.W	#$10,CCR
		ROXR.L	#1,D0
lab61		ROXL.L	#1,D2
		DBRA	D1,lab62
		RTS
        ENDC
        
;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

resload		dc.l	0		;address of resident loader
DiskNr		dc.b	1

	CNOP	0,2
	

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



	IFD	DEBUG
	cmp.b	HEADER+ws_keydebug(pc),d0	
	bne.b	.nodebug
	movem.l	(a7)+,d0-d1/a0-a2
	move.w	(a7),6(a7)			; sr
	move.l	2(a7),(a7)			; pc
	clr.w	4(a7)				; ext.l sr
	bra.b	.debug
	ENDC

.nodebug
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	_exit
	

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

	IFD	DEBUG
.debug	pea	(TDREASON_DEBUG).w
	bra.b	_quit
	ENDC


_exit	pea	(TDREASON_OK).w
_quit	move.l	resload(pc),a0
	jmp	resload_Abort(a0)


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

prev_buttons_state:
    dc.l    0
rawkey_address:
    dc.l    0
    
_tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
buttonjumps	dc.l	0
		dc.l	0


