;*---------------------------------------------------------------------------
;  :Program.	FlimbosQuest.asm
;  :Contents.	Slave for "Flimbos Quest" from System 3
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	19.12.98
;		12.12.17 (StingRay), v2.1
;		- code optimised a bit
;		- interrupts fixed
;		- high score load/save added
;		- illegal copperlist entries fixed
;		- Bplcon0 color bit fixes
;		- more blitter waits added
;		- out of bounds blit fixed
;		- timing fixed
;		- more trainer options added
;		- end sequence fixed
;		13.12.17, v2.1a
;		- blitter wait patches can be disabled with CUSTOM3
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	FlimbosQuest.slave
	OPT	O+ OG+			;enable optimizing
	ENDC
	
;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$59		;ws_keyexit = F10
		dc.l	0		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-base		;ws_config
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
DECL_VERSION:MACRO
	dc.b	"2.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC

	ENDM
_config	dc.b	"C3:B:Disable Blitter Wait Patches (7MHz 68000);"
	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Money:1;"
	dc.b	"C1:X:Unlimited Time:2;"
	dc.b	"C1:X:Start with max. Money:3;"
    dc.b    "C2:B:blue/second button jumps;"
	dc.b	"C4:L:Start at Level:1,2,3,4,5,6,7"
	dc.b	0

_name	dc.b	"Flimbo's Quest",0
_copy	dc.b	'1990 System 3',0
_info	dc.b	'Adapted by Mr.Larmer,StingRay & JOTD',10
	dc.b	'Version '
	DECL_VERSION
	dc.b	0


HiName	dc.b	"FlimbosQuest.high",0

	CNOP 0,2
    include     "ReadJoyButtons.s"
    
;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		move.l	a0,a2
		lea	_tag(pc),a0
		jsr	(resload_Control,a2)
		
	lea	$100.w,a0
	move.l	#-2,(a0)
	move.l	a0,$dff080
	move.l	a0,$dff084
	

		lea	$50000,A0
		moveq	#0,D0
		move.l	#$400,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		cmp.l	#$01B20D10,4(A0)
		beq.b	New

		pea	Patch(pc)
		move.l	(A7)+,$88(A0)

		move.w	#$4E75,$AE(A0)		; drive ?

		move.w	#$4EF9,$154(A0)
		pea	Load(pc)
		move.l	(A7)+,$156(A0)

		move.w	#$4EF9,$21E(A0)
		pea	Decrunch(pc)
		move.l	(A7)+,$220(A0)


		jmp	$C(A0)
        ; "new" version matches SPS 121
New
   movem.l   d0-d1/a0-a2,-(a7)
   move.l   a0,a1
   lea  pl_boot_new_50000(pc),a0
   jsr  resload_Patch(a2)
   movem.l  (a7)+,d0-d1/a0-a2
   jmp	($32,A0)

pl_boot_new_50000:
    PL_START
    PL_P    $6C,new_70000
    PL_END
    
new_70000    
   movem.l   d0-d1/a0-a2,-(a7)
   lea  $70000,a1
   lea  pl_boot_new_70000(pc),a0
   jsr  resload_Patch(a2)
   movem.l  (a7)+,d0-d1/a0-a2

    LEA $03c0,A0
    LEA.L $00070016,A1
    MOVE.W #$00ff,D0
.copy
    MOVE.L (A1)+,(A0)+
    DBF D0,.copy
    bsr _flushcache
    jmp	$03c0.w
   
pl_boot_new_70000:
    PL_START
    PL_PA    $AC-$72,PatchNew
    PL_R    $B0-$72		; drive ?
    PL_P    $12C-$72,Load
    PL_P    $204-$72,Decrunch
    PL_END

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
Patch
    
    bsr _detect_controller_type
		move.l	A0,-(A7)
		lea	$70000,A0

		move.w	#$4EB9,$174(A0)
		pea	Keyboard(pc)
		move.l	(A7)+,$176(A0)

		move.w	#$4EB9,$1A0(A0)
		pea	Keyboard2(pc)
		move.l	(A7)+,$1A2(A0)

		move.w	#$6022,$1D0(A0)

		move.w	#$C0,$21E(A0)
		move.w	#$4EF9,$C0.w
		pea	Intro(pc)
		move.l	(A7)+,$C2.w

		move.w	#$6022,$238(A0)
		move.w	#$6004,$2A8(A0)

		move.l	#$4E714EF9,$2EA(A0)
		pea	Game(pc)
		move.l	(A7)+,$2EE(A0)

		move.w	#$4EF9,$4EA(A0)
		pea	Load(pc)
		move.l	(A7)+,$4EC(A0)

		move.w	#$4EF9,$5D4(A0)
		pea	Decrunch(pc)
		move.l	(A7)+,$5D6(A0)

		move.l	(A7)+,A0

		jmp	$70000

check_kb:
	move.b	$BFEC01,D0
	clr.b	$BFEC01
	move.w	D0,-(a7)
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq.b	_quit
	move.w	(a7)+,D0
	rts
_quit
	pea	(TDREASON_OK).w
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	
Keyboard
		btst	#3,$BFED01
		beq.b	.exit
		bsr.b	check_kb
		ori.b	#$40,$BFEE01
		addq.l	#4,(A7)
		rts
.exit
		add.l	#$30,(A7)
		rts
Keyboard3
		btst	#3,$BFED01
		beq.b	.exit
		bsr.b	check_kb
		ori.b	#$40,$BFEE01
		addq.l	#8,(A7)
		rts
.exit
		add.l	#$4A,(A7)
		rts
Keyboard5
		btst	#3,$BFED01
		beq.b	.exit
		bsr.b	check_kb
		ori.b	#$40,$BFEE01
		addq.l	#8,(A7)
		rts
.exit
		add.l	#$24,(A7)
		rts
Keyboard2
		move.l	d1,-(a7)
		moveq	#3-1,d1				;wait because handshake min 75 탎
.int2_w1	move.b	_custom+vhposr,d0
.int2_w2	cmp.b	_custom+vhposr,d0		;one line is 63.5 탎
		beq.b	.int2_w2
		dbf	d1,.int2_w1			;(min=127탎 max=190.5탎)
		move.l	(a7)+,d1

		andi.b	#$BF,$BFEE01
		addq.l	#4,(A7)
		rts
Keyboard4
		move.l	d1,-(a7)
		moveq	#3-1,d1				;wait because handshake min 75 탎
.int2_w1	move.b	_custom+vhposr,d0
.int2_w2	cmp.b	_custom+vhposr,d0		;one line is 63.5 탎
		beq.b	.int2_w2
		dbf	d1,.int2_w1			;(min=127탎 max=190.5탎)
		move.l	(a7)+,d1

		andi.b	#$BF,$BFEE01
		addq.l	#8,(A7)
		rts
Intro
		move.w	#$4EB9,$175C.w
		pea	Keyboard5(pc)
		move.l	(A7)+,$175E.w

		move.w	#$4EB9,$1778.w
		pea	Keyboard4(pc)
		move.l	(A7)+,$177A.w


	lea	PLINTRO(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)


		jmp	$1000.w

PLINTRO	PL_START
	PL_ORW	$11e6+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$11fe+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1272+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$127a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$12ba+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1682+2,1<<9		; set Bplcon0 color bit

	PL_PSS	$1786,ackLev2,2
	PL_PSS	$17e0,ackCOP,2

	PL_IFC3
; CUSTOM3 = 1 -> do nothing

	PL_ELSE
	PL_PS	$2c4c,.wblit
	PL_PS	$2c14,.wblit2
	PL_PSS	$2b12,.wblit3,4
	PL_PSS	$2b8a,.wblit4,4
	PL_PSS	$2e18,.wblit4,4
	PL_PS	$2eb0,.wblit5
	PL_ENDIF
	PL_END


.wblit	bsr	WaitBlit
	move.l	d1,$dff048
	rts

.wblit2	bsr	WaitBlit
	move.w	d0,$dff042
	rts

.wblit3	bsr	WaitBlit
	move.l	#$01000000,$dff040
	rts

.wblit4	bsr	WaitBlit
	move.l	#$09f00000,$dff040
	rts

.wblit5	lea	$dff000,a6
	bra.w	WaitBlit

PatchNew
    movem.l   d0-d1/a0-a2,-(a7)
    bsr _detect_controller_type
    patch   $C0,Intro
	lea	$70000,A1
    lea pl_patchnew(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)


   movem.l   (a7),d0-d1/a0-a2

		jmp	$70000

game_or_story
    bsr wait_vbl
    bsr    _read_joystick_port_1
    btst    #JPB_BTN_RED,D0
    beq.b   .no_red
    move.b  #$50,$0007016e
.no_red
    btst    #JPB_BTN_BLU,D0
    beq.b   .no_blu
    move.b  #$51,$0007016e
.no_blu
    move.b   _keyexit(pc),d0
    cmp.b   $7016E,d0
    beq _quit       ; quit on 68000 from here!
    CMP.B #$51,$0007016e
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
pl_patchnew
    PL_START
    PL_ORW  $418+2,1<<9	; set Bplcon0 color bit
    PL_PS   $174,Keyboard
    PL_PS   $1A0,Keyboard2

	PL_W   $1D0,$6022
	PL_W   $1FE,$BAF8		; lea $1B100,A0 -> lea $1BAF8,A0
	PL_W   $204,$6014

    PL_W    $234,$C0


	PL_W    $24E,$6022
	PL_W    $2BE,$6004

    PL_NOP    $300,2
    PL_P  $302,Game

    PL_P   $500,Load
    PL_P   $5EA,Decrunch
    
    PL_PSS  $C6,game_or_story,2
    PL_END
 

    
Game
    
		bsr.w	Decrunch

		movem.l	d0-d1,-(a7)


		;move.l	_custom1(pc),d0
		;beq.w	.sktrain
		
		;move.b	#-1,$185D.w
		;clr.l	$53F6.w
		;move.l	#$4E714E71,$57AC.w	; money


; load high scores

	lea	HiName(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HiName(pc),a0
	lea	$3708.w,a1
	jsr	resload_LoadFile(a2)
.nohigh

	lea	PLGAME(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)

	lea	$100.w,a0
	move.l	a0,$dff080

	movem.l	(a7)+,d0-d1
	
		jmp	$380.w

read_fire
    movem.l D0,-(a7)
    move.l  _current_buttons_state(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,D0
    movem.l (a7)+,D0
    rts
    
;read_controls
;    bsr _update_buttons_status
read_joystick
    movem.l A0/d2,-(a7)
    bsr _update_buttons_status
    MOVE.W $00dff00c,D2
    move.b  d2,D1
    lsr.w   #8,d2
    move.b  d2,d0
    movem.l (a7)+,A0/d2
    rts
        
read_joypad
    movem.l A0/d2-d3,-(a7)
    bsr _update_buttons_status
    move.l  _current_buttons_state(pc),d3
    MOVE.W $00dff00c,D2
    cmp.l   #$1AC8,($14,A7)
    bne.b   .noneed     ; not called from main game (shop: $5D52)
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,D2
	btst	#9,D2
	beq.b	.noneed
	bset	#8,D2	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d3
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,D2
	btst	#9,D2
	bne.b	.no_blue
	bset	#8,D2	; xor 8 and 9 yields 1 cos bit9=1 
        ; dispatch D2 into D0 and D1
.no_blue
    move.b  d2,D1
    lsr.w   #8,d2
    move.b  d2,d0
    movem.l (a7)+,A0/d2-d3
    rts

pause_test
    movem.l d0-d1,-(a7)
    move.l  _current_buttons_state(pc),d0
    btst    #JPB_BTN_PLAY,d0
    beq.b   .nopause
    move.l  _previous_buttons_state(pc),d1
    btst    #JPB_BTN_PLAY,d1
    bne.b   .nopause
    ; play just pressed, Z is set
    movem.l (a7)+,d0-d1
    RTS
.nopause
    movem.l (a7)+,d0-d1

    CMPI.B	#$40,$d1f
    rts
    
esc_test
    movem.l a0/d0-d1,-(a7)
    move.l  _current_buttons_state(pc),d0
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noesc
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noesc
    btst    #JPB_BTN_YEL,d0
    bne _quit
    move.l  _previous_buttons_state(pc),d1
    btst    #JPB_BTN_FORWARD,d1
    beq.b   .esc
    btst    #JPB_BTN_REVERSE,d1
    bne.b   .noesc
    
.esc
    lea _current_buttons_state(pc),a0
    clr.l   (a0)    ; read is done after this test...
    ; play just pressed, Z is set
    movem.l (a7)+,a0/d0-d1
    RTS
    
.noesc
    movem.l (a7)+,a0/d0-d1
    CMPI.B	#$45,$d1f
    rts
    
PLGAME	PL_START
    PL_PS   $D38,Keyboard3
    PL_PS   $D7A,Keyboard4

    PL_L    $1924,$4EB800C0
    PL_P    $C0,AccessFault

    PL_B    $1FAA,$60		; skip check TOD protection
    PL_B    $4D00,$60		; skip check TOD protection

    PL_PSS   $173C,read_fire,2
    PL_IFC2
    PL_PSS  $1728,read_joypad,6
    PL_ELSE
    PL_PSS  $1728,read_joystick,6
    PL_ENDIF
    
    PL_PS   $DBE,pause_test
	PL_PS   $da4,esc_test
    	
; this one needs to stay even with CUSTOM3=1! For now anyway. :)
	PL_W    $4DD0,$6002		; skip lea $58(A6),A7

    PL_PS   $4DF2,WaitBlit7

    PL_IFC3
    ; do nothing!
    PL_ELSE
    PL_PS   $14C8,WaitBlit1
    PL_PS   $1702,WaitBlit2
    PL_PS   $20B0,WaitBlit3
    PL_PS   $2176,WaitBlit3
    PL_PS   $21EE,WaitBlit4
    PL_PS   $2222,WaitBlit4
    PL_PS   $4BF0,WaitBlit5
    PL_PS   $4C10,WaitBlit5
    PL_PS   $4D5A,WaitBlit6

    PL_ENDIF

    PL_P    $4EB8,Load2

    PL_PA   $5A4A,EndIntro

	PL_R    $6ADC

	PL_P    $6BBC,Load3

    PL_P    $6CEC,Decrunch



	PL_PSS	$d88,ackLev2,2
	PL_PSS	$48f2,ackCOP,2
	PL_PSS	$df4,ackCOP,2
	PL_PSS	$5da2,ackCOP,2
	PL_PSS	$6a12,ackCOP,2
	

	PL_PS	$62c6,.savehigh

	PL_ORW	$39f4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3a54+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3c98+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$43f4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$bee+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4e4e+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$4e90+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$524a+2,1<<9		; set Bplcon0 color bit

	PL_PS	$4dec,.wblit
	PL_PS	$4d1a,.wblit2
	PL_PS	$148e,.wblit3
	PL_PS	$4ba8,.wblit4

	PL_PSS	$4822,.fixtiming,2
	PL_L	$47a6+2,$100000/$34	; adapt loop counter value

	PL_PS	$5a48,.fixend

; unlimited lives
	PL_IFC1X	0
	PL_B	$7a0,$4a
	PL_ENDIF

; unlimited money
	PL_IFC1X	1
	PL_S	$57ac,4
	PL_ENDIF

; unlimited time
	PL_IFC1X	2
	PL_S	$355a,$3562-$355a	; unlimited time
	PL_ENDIF

; start with max. money
	PL_IFC1X	3
	PL_S	$47e,4
	PL_L	$ebc,$99999
	PL_ENDIF

	PL_IFC2
	PL_PSS	$43a,.setlev,2
	PL_PSS	$46a,.setlev,2
	PL_PSS	$5a5e,.setlev,2
	PL_ENDIF
	PL_END

.setlev	move.l	STARTLEVEL(pc),d0
	move.b	d0,$ec2.w
	jsr	$4eb8.w
	jmp	$63e8.w
	


.fixtiming
	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	btst	#7,$bfe001
	rts

.wblit	bsr	WaitBlit
	move.w	d4,(a2)
	move.w	d0,(a3)
	move.l	a0,(a4)
	rts

.wblit2	lea	$dff000,a6
	bra.w	WaitBlit

.wblit3	move.w	$12e2.w,d3
	ror.w	#4,d3
	bra.w	WaitBlit

.wblit4	lea	$dff000,a4
	bra.w	WaitBlit


.savehigh
	move.l	STARTLEVEL(pc),d0
	bne.b	.nosave
	move.l	_custom1(pc),d0
	bne.b	.nosave
	tst.b	$185d.w
	bne.b	.nosave

	lea	HiName(pc),a0
	lea	$3708.w,a1
	move.l	#$3774-$3708,d0
	move.l	_resload(pc),a2
	jsr	resload_SaveFile(a2)
	


.nosave	move.l	#$a0000,d0
	rts


.fixend	lea	PLEND(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$39000

PLEND	PL_START	
	PL_ORW	$39022+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$39504,ackCOP,2
	PL_PSS	$3ac80,ackCOP,2
	PL_ORW	$3a9cc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3aa20+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3ab04+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$104+2,1<<9		; set Bplcon0 color bit

	PL_IFC3
; CUSTOM3 = 1 -> do nothing

	PL_ELSE
	
	PL_PSS	$39de8,.wblit,2
	PL_PSS	$3a30e,.wblit2,2
	PL_PSS	$39ffa,.wblit3,4
	PL_PS	$39d3e,.wblit4
	PL_PS	$39cfe,.wblit4
	PL_PS	$3a2f8,.wblit5
	PL_PSS	$3a34a,.wblit6,2
	PL_PS	$3a3aa,.wblit7
	PL_PS	$3ac8a,.wblit5
	PL_PS	$3acf6,.wblit5
	PL_PSS	$3adde,.wblit8,2
	PL_PS	$3b1b2,.wblit5
	PL_PSS	$3b1fa,.wblit8,2
	PL_PSS	$3a370,.wblit6,2
	PL_ENDIF

	PL_END

.wblit	bsr	WaitBlit
	move.l	a3,$50(a1)
	move.l	a0,$4c(a1)
	rts

.wblit2	bsr	WaitBlit
	move.l	#$0fca0000,$40(a6)
	rts

.wblit3	bsr	WaitBlit
	move.l	#$09f00000,$dff040
	rts

.wblit4	lea	$dff000,a1
	bra.w	WaitBlit

.wblit5	lea	$dff000,a6
	bra.w	WaitBlit

.wblit6	bsr	WaitBlit
	move.l	a0,$4c(a6)
	move.l	a1,$50(a6)
	rts

.wblit7	lea	$dff000,a5
	bra.w	WaitBlit

.wblit8	bsr	WaitBlit
	move.l	a0,$48(a6)
	move.l	a1,$4c(a6)
	rts



ackLev2
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rts	

ackCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0

		dc.l	WHDLTAG_CUSTOM4_GET
STARTLEVEL	dc.l	0

		dc.l	WHDLTAG_CUSTOM3_GET
NOBLITWAITS	dc.l	0
		dc.l	TAG_DONE

AccessFault
		btst	#5,D1
		beq.b	.skip
		and.w	#$3C,D1
		rts
.skip
		and.w	#$5C,D1
		rts
WaitBlit1
		move.w	#$A14,$58(A0)
WaitBlit
		;BLITWAIT
		tst.b	$dff002
.wblit		btst	#6,$dff002
		bne.b	.wblit
		rts
WaitBlit2
		move.w	$18(A4),$58(A0)
		bra.b	WaitBlit
WaitBlit3
		move.w	#$1A43,$58(A6)
		bra.b	WaitBlit
WaitBlit4
		move.w	#$543,$58(A6)
		bra.b	WaitBlit
WaitBlit5
		move.w	#$381,$58(A4)
		bra.b	WaitBlit
WaitBlit6
		move.w	#$396,$58(A6)
		bra.b	WaitBlit
WaitBlit7
		move.l	A1,(A5)
		move.l	A1,(A6)

	cmp.l	#$7f840,a1
	blt.b	.ok
	move.w	#13<<6+2,d5	; blit one line less

.ok		move.w	D5,4(A6)		; move.w D5,(A7)
.skip		rts
EndIntro
		move.l	#$100,$39190		; move.l #$100,$DFF080
		move.l	#$009C8010,$100.w
		move.l	#$01000000,$104.w
		move.l	#$FFFFFFFE,$108.w
		jmp	$39000

;--------------------------------

; Byte Killer optimized decrunch procedure

Decrunch
		move.l	A1,A2
		move.l	(A0)+,D0
		move.l	(A0)+,D1
		move.l	(A0)+,D5
		add.l	D0,A0
		add.l	D1,A2
		move.l	-(A0),D0

		eor.l	D0,D5
lbC000012
		lsr.l	#1,D0
		beq.s	lbC000040
lbC000016
		bcs.s	lbC000078
		moveq	#7,D1
		moveq	#1,D3
		lsr.l	#1,D0
		beq.s	lbC000044
lbC000020
		bcs.s	lbC00009A
		moveq	#2,D1
		clr.w	D4
lbC000026
		bsr.s	lbC00005E
		move.w	D2,D3
		add.w	D4,D3
lbC00002C
		moveq	#7,D1
lbC00002E
		lsr.l	#1,D0
		beq.s	lbC000048
lbC000032
		addx.b	D2,D2
		dbra	D1,lbC00002E
		move.b	D2,-(A2)
		dbra	D3,lbC00002C
		bra.s	lbC0000A4

lbC000040
		bsr.s	lbC000052
		bra.s	lbC000016

lbC000044
		bsr.s	lbC000052
		bra.s	lbC000020

lbC000048
		bsr.s	lbC000052
		bra.s	lbC000032

lbC00004C
		moveq	#7,D1
		moveq	#8,D4
		bra.s	lbC000026

lbC000052
		move.l	-(A0),D0
		eor.l	D0,D5
		roxr.l	#1,D0
		bset	#$1F,D0
		rts

lbC00005E
		clr.w	D2
lbC000060
		lsr.l	#1,D0
		beq.s	lbC00006C
lbC000064
		addx.w	D2,D2
		dbra	D1,lbC000060
		rts

lbC00006C
		move.l	-(A0),D0
		eor.l	D0,D5
		roxr.l	#1,D0
		bset	#$1F,D0
		bra.s	lbC000064

lbC000078
		moveq	#1,D1
		bsr.s	lbC00005E
		cmpi.b	#2,D2
		blt.s	lbC000092
		cmpi.b	#3,D2
		beq.s	lbC00004C
		moveq	#7,D1
		bsr.s	lbC00005E
		move.w	D2,D3
		moveq	#11,D1
		bra.s	lbC00009A

lbC000092
		moveq	#8,D1
		add.w	D2,D1
		addq.w	#2,D2
		move.w	D2,D3
lbC00009A
		bsr.s	lbC00005E
lbC00009C
		move.b	-1(A2,D2.W),-(A2)
		dbra	D3,lbC00009C
lbC0000A4
		cmpa.l	A2,A1
		blt.w	lbC000012
		move.l	D5,D0
		rts

;--------------------------------

Load
		movem.l	d0-a6,-(a7)

		cmp.l	#$700,A1
		bne.b	.sk1

		move.l	#$1600,D0
.sk1
		cmp.l	#$1000,A1
		bne.b	.sk2

		move.l	#$8DA00,D0
.sk2
		cmp.l	#$300,A1
		bne.b	.sk3

		move.l	#$97400,D0
.sk3
		cmp.l	#$F00,A1
		bne.b	.sk4

		move.l	#$C1E00,D0
.sk4
		move.l	A2,D1
		sub.l	A1,D1
		move.l	A1,A0
		moveq	#1,D2

		bsr.b	_LoadDisk

		movem.l	(a7)+,d0-a6
		rts
Load2
		clr.w	$6B88.w

		movem.l	d0-a6,-(a7)

		lea	$2BC1A,A0
		move.l	#$2C00,D0
		move.l	#$10BCC,D1
		moveq	#1,D2

		bsr.b	_LoadDisk

		lea	$2C194,A1
		bsr.w	Decrunch

		movem.l	(a7)+,d0-a6
		rts
Load3
		movem.l	d0-a6,-(a7)

		move.l	A4,A0
		move.l	A5,D1
		sub.l	A4,D1
;		lea	Table(pc),A1
;		move.l	(A1,D0.w),D0
		move.l	Table(pc,D0.w),D0

		moveq	#1,D2

		bsr.b	_LoadDisk

		movem.l	(a7)+,d0-a6
		rts
Table
	dc.l	$2C00,$14A00,$27E00,$3DE00,$4FC00,$60400,$72200,$84000

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================

	END
