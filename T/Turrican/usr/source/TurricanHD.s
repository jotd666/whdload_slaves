;*---------------------------------------------------------------------------
;  :Program.	turrican.asm
;  :Contents.	Slave for "Turrican"
;		supports:
;			v1 PAL "Rainbow Arts"
;			v2 NTSC "Innerprise"
;			v3 "AmigaFun" rerelease
;			v4 "CDTV"
;  :Author.	Wepl
;  :Version.	$Id: turrican.asm 1.17 2016/02/09 22:06:51 wepl Exp wepl $
;  :History.	31.03.97 initial
;		22.04.97 new 60000 and bb -> changes
;		28.04.97 copper preserved (install-waitpic)
;		05.05.97 rework files instead image, lots more
;		13.05.97 file "30" forgotten, delay on intro voice added
;		24.05.97 highscore saving fixed
;		25.05.97 cache enabled
;			 to version 4 evaluated (kinit removed)
;		27.05.97 blitter patches
;		24.06.97 keyboard routine fixed
;		22.07.97 copylock level 1,2,4,5 removed
;		24.07.97 voice wait improved
;			 blitter waits reworked and completed
;		29.07.97 random generator replaced because Access Fault's
;		31.07.97 support for second version started
;		01.08.97 extro fixed
;		09.08.97 keyboard stuff in install changed
;			 support for innerprise version completed
;			 blitwaits on endboss added
;		15.08.97 sp changed for install because crash with v2
;		17.08.97 basememsize for install increased from 7f000 -> 82000
;		20.08.97 level4 protection adapted for innerprise version
;		30.08.97 keyboard external
;		15.09.97 support for "AmigaFun" rerelease
;		27.06.98 cleanup for source code release
;		07.06.01 global rework
;		14.01.16 install slave removed
;			 highscore load for cdtv added
;		16.01.16 highscore save for cdtv added
;			 keyboard fixed on cdtv
;		17.01.16 AmigaFun worked on
;			 sync for speech and picture added
;			 decruncher fixed
;			 works upto level 1
;		21.01.16 AmigaFun worked on
;		24.01.16 AmigaFun worked on
;			 security for random increased
;		30.01.16 AmigaFun worked on
;			 decruncher optimized
;			 LEV2-5 fixed
;		31.01.16 AmigaFun finished
;		02.02.16 speech fixed for slow machines
;			 keyboard enabled during speech, improved quit/debug on 68000
;		03.02.16 v1 adapted
;		08.02.16 v2 adapted, finished
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:tr/turrican/Turrican.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

SAVEDATA = 0	;save decompressed data files

RND_LEN		= $2000		;length
RND_STRTOFF	= $50		;LEV2 $3c88
RND_STOPOFF	= $22

	STRUCTURE expmem,0
	STRUCT	exp_rnd,RND_LEN
	STRUCT	exp_stack,$c00
	LABEL	exp_stackend
	STRUCT	exp_unpack2,$400
	LABEL	exp_SIZEOF

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	18			;ws_Version
		dc.w	WHDLF_NoError		;ws_Flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_dir-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	exp_SIZEOF		;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	slv_config-_base			;ws_config


slv_config:
        dc.b    "BW;"
       dc.b    "C1:X:trainer infinite lives:0;"
       dc.b    "C1:X:trainer infinite time and specials:1;"
       dc.b    "C2:X:second button for jump:0;"
	   dc.b    "C4:L:Start level:1,2,3,4;"			
	   dc.b    "C5:L:Start sublevel:A,B,C;"			
	   dc.b	0

;============================================================================


	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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


_name		dc.b	"Turrican",0
_copy		dc.b	"1990 Rainbow Arts/Innerprise",0
_info		dc.b	"Installed by Wepl",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_dir		dc.b	"data",0
_main		dc.b	"main",0
_60000		dc.b	"60000",0
_highsname	dc.b	"highs",0
	EVEN
    include ReadJoyPad.s

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a3				;A3 = resload
		move.l	(_expmem,pc),a7
		add.l	#exp_stackend,a7

        bsr _detect_controller_types
		pea	_int68(pc)
		move.l	(a7)+,$68
        
        ;get tags
		lea     (_tag,pc),a0
		jsr     (resload_Control,a3)

	;enable caches
		move.l	#CACRF_EnableI,d0
		move.l	d0,d1
		jsr	(resload_SetCACR,a3)
		
	;random area
		bsr	_rnd_init
		
	;check for CDTV Version
		lea	(_main,pc),a0
		jsr	(resload_GetFileSize,a3)
		tst.l	d0
		bne	_cdtv

	;check for AmigaFun Version
		lea	_60000(pc),a0
		jsr	(resload_GetFileSize,a3)
		tst.l	d0
		bne	_v1_v2

;======================================================================
; AmigaFun

	;bootblock stuff
		move.l	#$400,d0			;offset
		move.l	#$18000,d1			;size
		moveq	#1,d2				;disk
		lea	$5fe00,a0			;data
		lea	(a0),a2
		jsr	(resload_DiskLoad,a3)

        
		lea	_pl_5fe00(pc),a0
		move.l	a2,a1
		jsr	(resload_Patch,a3)

		jmp	($228,a2)

_pl_5fe00	PL_START
	;	PL_S	$228,6				;skip rainbow arts intro unpack
		PL_PS	$236,_ra
	;	PL_S	$236,6				;skip rainbow arts intro run
		PL_PS	$270,_waitspeech
		PL_ORW	$2c0,INTF_PORTS
		PL_P	$304,_100_v3
		PL_ORW	$382,INTF_PORTS
		PL_P	$510,_intack1
		PL_PS	$6ae,_dec3_main
		PL_PS	$6d0,_dec3_mus0
		PL_PS	$6e8,_dec3_intr
		PL_P	$6fa,_load_v3			;with cache
		PL_P	$77a,_load_v3			;plain
		PL_PSS	$9ac,_picshow,$9c6-$9ac-6	;obsolete delay
		PL_P	$c390,_unpack
	;	PL_P	$c3ea,unpack1
	;	PL_P	$c506,unpack2
	;	PL_P	$c782,unpack3
	;the following moves to $50000 (init2, speech)
		PL_P	$10618,_intack10
		PL_END

;load_exec_3x:
; loadadr	decadr	lenunp	lenpak
; fffa		100	1b680	1504e
; 21180		1bb00	11964	10708
; 37af8		30000	13200	e8a9

_waitspeech	cmp.w	#$130,$50186			;speech counter
		bhs	.waitspeech_q
		btst	#6,$bfe001
		beq	.waitspeech_q
		btst	#7,$bfe001
		bne	_waitspeech
.waitspeech_q	move.w	#INTF_COPER|INTF_VERTB,(intena,a6)
		rts

_dec3_main	lea	$fffa+$4a0,a0	;MAIN
		move.l	(a0)+,a1
		move.l	$c0,a2		;free buffer $400
	IFNE SAVEDATA
		move.l	a1,-(a7)
		move.l	(a0),-(a7)
		bsr	_unpack
		movem.l	(a7)+,d0/a1
		lea	.name(pc),a0
		move.l	(_resload,pc),a2
		jmp	(resload_SaveFile,a2)
.name		dc.b	"D1 18C00-24386 @  100",0
	ELSE
		bra	_unpack
	ENDC

_dec3_mus0	lea	$21180+$4a0,a0	;MUS0 $1bb00
		move.l	(a0)+,a1
		move.l	$c0,a2		;free buffer $400
	IFNE SAVEDATA
		move.l	a1,-(a7)
		move.l	(a0),-(a7)
		bsr	_unpack
		movem.l	(a7)+,d0/a1
		lea	.name(pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
		bra	.go
.name		dc.b	"D1 26800-32AE4 @1bb00",0
.go
	ELSE
		bsr	_unpack
	ENDC
		lea	_pl3m(pc),a0
		lea	$1bb00,a1
		move.l	(_resload,pc),a2
		jmp	(resload_Patch,a2)

_dec3_intr	lea	$37af8+$4a0,a0	;INTR $30000
		move.l	(a0)+,a1
		move.l	$c0,a2		;free buffer $400
	IFNE SAVEDATA
		move.l	a1,-(a7)
		move.l	(a0),-(a7)
		bsr	_unpack
		movem.l	(a7)+,d0/a1
		lea	.name(pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
		bra	.go
.name		dc.b	"D1 32E00-3E5C8 @30000",0
.go
	ELSE
		bsr	_unpack
	ENDC
		lea	_pl13i(pc),a0
		lea	$30000,a1
		move.l	(_resload,pc),a2
		jmp	(resload_Patch,a2)

	;rainbow arts logo
_ra		lea	$30000,a1
		pea	(2,a1)
		lea	_plra(pc),a0
		move.l	(_resload,pc),a2
		jmp	(resload_Patch,a2)

_plra		PL_START
		PL_S	$128,6				;empty loop delay counter
		PL_PS	$150,.dmaoff
		PL_PS	$248,_ra_chkkb
		PL_PS	$2bc,.vbicnt
		PL_END

.dmaoff		waitvb	a6
		move.w	#$7fff,(dmacon,a6)
		rts

.vbicnt		lea	_vbicnt(pc),a0
		subq.l	#1,(a0)
		bne	.rte
		st	$30d9a				;quit_flag (keyboard)
.rte		move.w	#$10,($9c,a6)
		tst.w	(intreqr,a6)
		rts

_int68		movem.l	d0-a6,-(a7)
		lea	$bfe001,a1
		btst	#3,($d00,a1)
		beq	.int68_q
		move.b	($c00,a1),d0
		bset	#6,($e00,a1)
		bsr	_ra_chkkb
		bclr	#6,($e00,a1)
.int68_q	move	#8,_custom+intreq
		tst	_custom+intreqr
		movem.l	(a7)+,d0-a6
		rte

_ra_chkkb	bsr	_waitkb
		move.b	d0,d1
		not.b	d1
		ror.b	#1,d1
		cmp.b	_keyexit(pc),d1
		beq	_exit
		cmp.b	_keydebug(pc),d1
		bne	_rts
		addq.l	#4,a7			;rts
		movem.l	(a7)+,d0-a6
		cmp	#$68,(6,a7)		;68010+?
		bne	.00
		move	(a7),(6,a7)		;sr
		move.l	(2,a7),(a7)		;pc
		clr	(4,a7)
		bra	_debug
.00		move.l	(2,a7),-(a7)		;pc
		move	(4,a7),(8,a7)		;sr
		clr	(6,a7)
		move.l	(a7),(2,a7)
		addq.l	#2,a7
		bra	_debug

_vbicnt		dc.l	$1c0

_picshow	movem.l	d0-d1/a0-a1,-(a7)
		moveq	#100,d0
		move.l	_resload(pc),a0
		jsr	(resload_Delay,a0)
		movem.l	(a7)+,d0-d1/a0-a1
		rts

_100_v3		
        lea	_pl_100_v3(pc),a5
_100_v13	lea	$603ae,a2			;original
_100_v123	lea	$100.W,a4


		movem.l	d0-d1/a0-a2,-(a7)

		move.l	a4,a0
		move.l	a4,a1
		add.l	#112256,a1			;main size
		lea	$1dc,a2
		bsr	_fix_rnd

        
		move.l	a5,a0
		move.l	a4,a1
		move.l	_resload(pc),a3
		jsr	(resload_Patch,a3)
		
		movem.l	(a7)+,d0-d1/a0-a2
		jmp	(a4)

   
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d1
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    bset    #7,d3   ; released
.pressed_\1
    move.b  d3,(a1) ; store keycode
.nochange_\1
    ENDM
    
_vbl_hook
        MOVE.W	_custom+intreqr,D0
        btst    #5,d0
        beq.b   .novbl
        movem.l  d0/d1/d3/a0/a1,-(a7)
        moveq.l #0,d3
        
        lea joy1(pc),a0
        move.l  (a0),d1     ; get previous state
        moveq	#1,d0
        bsr	_read_joystick
        cmp.l   d0,d1
        beq.b   .nochange   ; cheap-o test just in case no input has changed
        move.l  d0,(a0)     ; save previous state for next time
        eor.l   d0,d1   ; D1: only changes have set bits

        lea .rawkey(pc),a1
        TEST_BUTTON PLAY,$19
        TEST_BUTTON YEL,$64

        btst    #JPB_BTN_REVERSE,d0
        beq.b   .noquit
        TEST_BUTTON FORWARD,$45     ; rev+fwd: ESC

        btst    #JPB_BTN_FORWARD,d0
        beq.b   .noquit

        btst    #JPB_BTN_YEL,d0
        bne     _exit
.noquit
.nochange    
        tst.b   d3
        movem.l  (a7)+,d0/d1/d3/a0/a1
        bne.b   .keyboard
.novbl
        ; return to original
        rts
        
.keyboard:
        move.w  #$20,_custom+intreq
        ; set stack so jumping to keyboard interrupt returns to code on RTE
        move.l  (a7)+,d0
        addq.l  #4,a7       ; pop stack
        MOVEM.L	D0-D2/A0,-(A7)		;070da: 4cdf0107
        move.l  _keyboard_plug(pc),-(a7)
        move.b   .rawkey(pc),d0
        rts

.rawkey
        dc.w    0
        
read_joystick_up_jumps:
        CLR.W	joytest(A6)			;032f2: 426e0036
        MOVE.W	joy1dat(A6),D0		;032f6: 302e000c
        RTS
    
read_joystick_button_jumps:
        CLR.W	joytest(A6)			;032f2: 426e0036
        MOVE.W	joy1dat(A6),D0		;032f6: 302e000c
        movem.l D1/a0,-(a7)
        
        move.l  _start_level_address(pc),a0
        cmp.l   #$00020000,(a0)      ; fly level 3.1: don't use second button
        beq.b	.no_blue
        cmp.l   #$00020002,(a0)      ; fly level 3.3: don't use second button
        beq.b	.no_blue
        
        bclr	#8,d0
        btst	#9,d0
        beq.b	.noneed
        bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
        move.l  joy1(pc),d1
        btst	#JPB_BTN_BLU,d1
        beq.b	.no_blue
        ; set UP because blue pressed
        bclr	#8,d0
        btst	#9,d0
        bne.b	.no_blue
        bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:    
        movem.l (a7)+,D1/a0
        RTS

_read_fire
        move.l d0,-(a7)
        move.l  joy1(pc),d0
        not.l   d0
        btst    #JPB_BTN_RED,d0
        movem.l (a7)+,d0
        rts 

_read_fire_2_green
        move.l d0,-(a7)
        move.l  joy1(pc),d0
        not.l   d0
        btst    #JPB_BTN_GRN,d0
        movem.l (a7)+,d0
        rts 
        
_read_fire_2_blue
        move.l d0,-(a7)
        move.l  joy1(pc),d0
        not.l   d0
        btst    #JPB_BTN_BLU,d0
        movem.l (a7)+,d0
        rts 
        
    IFEQ    1
_buttons
        moveq	#$0000,d2		;input
        bchg	#0,$bf			;toggle
        bne	.set
        movem.l d0/d1,-(a7)
        move.l  joy1(pc),d0
        not.l   d0
        move.l  smart_bomb_bit(pc),d1
        btst    d1,d0
        movem.l (a7)+,d0/d1
        seq	d2
        cmp.b	$dd,d2
        beq	.same
        ext.w	d2
        move.w	d2,$dc
.same
.set
        add.l	#$32b6-$3284-6,(a7)
        rts   
     ENDC
     
_set_start_level:
        move.l  _start_level(pc),d0
        movem.l d0-d1/a0,-(a7)
        move.l _start_level_address(pc),a0
        move.w  d0,(a0)+        
        move.l  _start_sublevel(pc),d1
        cmp.w   #3,d1
        bcc.b   .nosub
        tst.w   d0
        beq.b   .full
        cmp.w   #2,d0
        beq.b   .full
        cmp.w   #3,d0
        beq.b   .full
        cmp.w   #2,d1
        bcc.b   .nosub        
.full        
        move.w  d1,(a0)   ; start section
.nosub
        movem.l (a7)+,d0-d1/a0
        rts
        
_pl_100_v123	PL_START
        
		PL_P	$8d0,_loadhighs
        PL_IFC1
        PL_ELSE
		PL_P	$95a,_savehighs
        PL_ENDIF
		PL_S	$bb8,6			;set sp
		PL_S	$be4,6			;set sp
		PL_PS	$c4c,_b31
		PL_W	$c86,$6006		;blitwait
	;	PL_S	$c8e,8			;clear level/sublevel
	;	PL_S	$d26,$135a-$d26		;enter next (extro with 4-1)
		PL_W	$1084,$6006		;blitwait
		PL_PS	$126a,_b21
		PL_R	$1282			;blitwait
		PL_PS	$141c,_b9
		PL_W	$147e,$6006		;blitwait

        PL_PSS  $D8e-$100,_set_start_level,2
	;	PL_W	$1838,4			;start level 0..4
	;	PL_W	$183a,2			;start sublevel
						;LEV1 0..2
						;LEV2 0..1
						;LEV3 0..2
						;LEV4 0..2
						;LEV5 0..1
		PL_PS	$1ab4,_b9
		PL_PS	$1adc,_b12
		PL_PS	$1b14,_b10
		PL_PS	$1ba4,_b11
		PL_P	$1dde,_b29
		PL_P	$1eec,_b29
		PL_P	$2128,_b29
		PL_P	$2242,_b29
		PL_PS	$232a,_b9
		PL_R	$236e			;blitwait
		PL_PS	$23a2,_b18
		PL_P	$248e,_bx3
	;	PL_W	$248e,$6006		;blitwait
	;	PL_PS	$249e,_b13
	;	PL_W	$24b4,$6006		;blitwait
		PL_R	$25c8			;blitwait
		PL_P	$268c,_bx2
	;	PL_R	$2748			;blitwait
		PL_PS	$2904,_b9
		PL_PS	$2956,_bb1
		PL_PS	$3418,_b9
		PL_P	$343c,_bx1
	;	PL_PS	$3454,_b14
	;	PL_W	$349c,$6006		;blitwait
		PL_END

_pl_100_v13	PL_START
		PL_PS	$5520,_b10
		PL_PS	$557e,_b10
		PL_PS	$5680,_b10
		PL_PS	$571e,_b10
		PL_PS	$590c,_b10
		PL_PS	$5a5e,_b10
		PL_PS	$5d40,_b9
		PL_PS	$5d6c,_b12
		PL_PS	$5da4,_b10
		PL_PS	$5ef8,_b10
		PL_PS	$5f66,_b11
		PL_P	$6198,_b29
		PL_P	$62a2,_b29
		PL_PS	$6308,_b9
		PL_PS	$67b8,_b10
		PL_P	$6cc6,_intack1
		PL_PS	$6f8c,_chkkb
		PL_P	$6fcc,_fixkb
		PL_P	$6fde,_intack3  ; keyboard handshake
		PL_PS	$74c6,_b9

        PL_IFC1X    0
        PL_W    $079ac+2-$100,0     ; sub 0 lives
        PL_ENDIF
        PL_IFC1X    1
        PL_W    $07870+2-$100,0     ; sub 0 bombs, also time
        PL_ENDIF

        PL_PS   $06d66-$100,_vbl_hook

        PL_IFC2X    0
        PL_PSS  $44CC-$100,read_joystick_button_jumps,2
        PL_PSS  $04524-$100,_read_fire_2_green,6
        PL_PSS  $0453a-$100,_read_fire_2_green,6
        PL_ELSE
        PL_PSS  $04524-$100,_read_fire_2_blue,6
        PL_PSS  $0453a-$100,_read_fire_2_blue,6
        PL_PSS  $44CC-$100,read_joystick_up_jumps,2    
        PL_ENDIF

        PL_PSS  $44F0-$100,_read_fire,2
        PL_PSS  $4502-$100,_read_fire,2
        
		PL_NEXT	_pl_100_v123

_pl_100_v3	PL_START
		PL_PS	$3d0,.level
		PL_PS	$58e,_dec3_intr
		PL_PS	$5a8,_dec3_mus0
		PL_P	$61c,_load_v3		;with cache
		PL_P	$696,_load_v3		;plain

        
		PL_NEXT	_pl_100_v13

.level		add	#$4a8,a0	;source
		move.l	(a0)+,a1	;destination
		move.l	$c0,a2		;free buffer $400
	IFNE SAVEDATA
		move.l	a1,-(a7)
		move.l	(a0),-(a7)
		bsr	_unpack
		move.l	a0,d7
		move.l	a1,d6
		moveq	#100,d0
		lea	.name(pc),a0
		lea	.namef(pc),a1
		move.l	(4,a7),-(a7)	;adress
		movem.l	$b0,d1-d2	;start/length
		add.l	d1,d2
		movem.l	d1-d2,-(a7)
		move.l	a7,a2
		move.l	(_resload,pc),a3
		jsr	(resload_VSNPrintF,a3)
		add	#12,a7
		movem.l	(a7)+,d0/a1
		lea	.name(pc),a0
		jsr	(resload_SaveFile,a3)
		move.l	d7,a0
		move.l	d6,a1
		bra	.namep
.name		dc.b	"D1 00000-00000 @00000",0
.namef		dc.b	"D1 %5lx-%5lx @%5lx",0
	EVEN
.namep
	ELSE
		bsr	_unpack
	ENDC
	;after unpacking
	; a0 = start
	; a1 = end
		bsr	_patch_lev_intr
		movem.l	(4,a7),d0-a6
		move.l	(a7)+,a0
		add.w	#15*4,a7
		jmp	(a0)

_patch_lev_intr	move.l	a0,a3
		lea	$1dc,a2		;rnd pointer variable
		bsr	_fix_rnd
		move.l	a3,a1		;unpacked destination
		lea	_pl31(pc),a0
		cmp.l	#$00021c80,(a1)
		beq	.patch
		lea	_pl32(pc),a0
		cmp.l	#$00020080,(a1)
		beq	.patch
		lea	_pl33(pc),a0
		cmp.l	#$00023ee0,(a1)
		beq	.patch
		cmp.l	#$000219a0,(a1)
		bne	.nolev4
		lea	_pl134(pc),a0
		cmp.w	#$f4c2,($126,a1)
		bne	.patch
		lea	_pl24(pc),a0
		bra	.patch
.nolev4		lea	_pl35(pc),a0
		cmp.l	#$00022000,(a1)
		beq	.patch
		cmp.l	#$6000000a,(a1)
		bne	.go
		lea	_pl13i(pc),a0
		cmp.w	#$f58,(10,a1)
		bne	.patch
		lea	_pl2i(pc),a0
.patch		clr.l	-(a7)
		move.l	a1,-(a7)
		pea	WHDLTAG_DBGADR_SET
		move.l	_resload(pc),a2
		jsr	(resload_Patch,a2)
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
.go		rts

_pl31		PL_START			;1b980, LEV1
		PL_NOP	$1902,2		;copylock, no exit after Level 1-3
		PL_PS	$1962,_b9
		PL_PS	$19e2,_b1
		PL_PS	$19fe,_b2
		PL_PS	$1aae,_b3
		PL_PS	$1b0c,_b4
		PL_PS	$1b32,_b2
		PL_PS	$1b48,_b1
		PL_PS	$1b70,_b5
		PL_PS	$1b88,_b1
		PL_PS	$1bb8,_b6
		PL_PS	$1bea,_b7
		PL_PS	$1c00,_b7
		PL_PS	$1c16,_b7
		PL_PS	$1c38,_b8
		PL_PS	$1c58,_b7
		PL_PS	$1c6e,_b7
		PL_PS	$1c84,_b7
		PL_PS	$1d00,_b9
		PL_PS	$1d5c,_b15
		PL_P	$5e6a,_b33
		PL_END

_pl32		PL_START			;1b980, LEV2
		PL_R	$f08			;fix deadlock on level 2
		PL_PS	$13ec,_b16
		PL_PS	$14f0,_b9
		PL_PS	$1550,_b15
		PL_PS	$157e,_b15
		PL_PS	$1596,_b15
		PL_PS	$15aa,_b15
		PL_PS	$40da,_b9
		PL_PS	$4104,_b17
		PL_END

_pl33		PL_START			;1b980, LEV3
		PL_W	$2548,$6006		;blitwait
		PL_PS	$349c,_b9
		PL_END

_pl1234		PL_START			;1b980, LEV4
		PL_PS	$1a12,_b20
		PL_PS	$1a7c,_b19
		PL_PS	$1af0,_b19
		PL_PS	$1b40,_b9
		PL_PS	$1b98,_b15
		PL_END

_pl134		PL_START
		PL_B	$3a58,$60		;beq -> bra  v1 (rainbow arts)
		PL_PS	$43bc,_b9
		PL_PS	$43d6,_b22
		PL_B	$4722,$60		;beq -> bra  v1 (rainbow arts)
		PL_PS	$47b0,_b23
		PL_R	$4828			;blitwait
		PL_R	$48b2			;blitwait
		PL_NEXT	_pl1234

_pl24		PL_START
		PL_PS	$43a0,_b9
		PL_PS	$43ba,_b22
		PL_PS	$4760,_b23
		PL_R	$47d8			;blitwait
		PL_R	$4862			;blitwait
		PL_NEXT	_pl1234

_pl35		PL_START			;1b980, LEV5
		PL_PS	$f02,_b9
		PL_PS	$fb4,_b9
		PL_PS	$100c,_b15
		PL_PS	$343c,_b9
		PL_P	$3464,_b24
		PL_B	$37e2,$60		;beq -> bra
		PL_B	$3a54,$60		;beq -> bra ('FUCK YOU')
		PL_B	$471e,$60		;beq -> bra ('FUCK YOU')
		PL_END

_pl13i		PL_START
		PL_P	$113a,_intack10
		PL_PS	$12d8,_b32
		PL_PS	$15a8,_b9
		PL_PS	$15c8,_b25
		PL_PS	$15f2,_b26
		PL_PS	$1600,_b26
		PL_PS	$160e,_b26
		PL_PS	$1634,_b27
		PL_PS	$1666,_b11
		PL_PS	$16c4,_b28
		PL_NEXT	_pl123i

_pl2i		PL_START
		PL_P	$1138,_intack10
		PL_PS	$12d6,_b32
		PL_PS	$15a6,_b9
		PL_PS	$15c6,_b25
		PL_PS	$15f0,_b26
		PL_PS	$15fe,_b26
		PL_PS	$160c,_b26
		PL_PS	$1632,_b27
		PL_PS	$1664,_b11
		PL_PS	$16c2,_b28
		PL_NEXT	_pl123i

_pl123i		PL_START			;30000, INTR
		PL_CW	$14			;wait line 0 instead 256
		PL_ORW	$2e,INTF_PORTS
		PL_PS	$29c,_chkfixkb
		PL_S	$600,4
		PL_PS	$604,_waitdma2
		PL_PS	$792,.waitchar
		PL_END

	;fix empty loop in cursor blinking
.waitchar	moveq	#3,d0
.w		waitvb
		dbf	d0,.w
		rts

_waitdma2	waitvb	a6
		move.w	#$83e0,(dmacon,a6)
		rts

_pl3m		PL_START			;1bb00, MUS0
		PL_P	$111c,.intack6
		PL_END

.intack6	tst.w	(_custom+intreqr)
		movem.l	(a7)+,d0/a6
		rte

;--------------------------------
; d0 = starttrack
; d1 = size in bytes
; d2 = dest. address

_load_v3	mulu	#$1600,d0		;offset
		movem.l	d0-d1,$b0		;for level file dump
		move.l	d2,a0			;data
		moveq	#1,d2			;disk
		bset	#31,d2			;save files
		move.l	(_resload,pc),a2
		jmp	(resload_DiskLoad,a2)

;--------------------------------
; a0 = packed data
; a1 = destination
; a2 = free buffer
; returns:
; a0 = unpacked data
; a1 = end of unpacked data

_unpack move.l	(a0)+,-(sp)	;unpacked?
	move.l	(a0)+,-(sp)	;packed?
	move.w	#$400/4-1,d0
	movea.l	a1,a3
	adda.l	(4,sp),a3	;end unpacked
.cp400	move.l	(a3)+,(a2)+	;save
	dbf	d0,.cp400
	movem.l	a2/a3,-(sp)
	move.l	a1,-(sp)
	move.l	a2,-(sp)
	bsr.b	unpack1
	movea.l	(sp)+,a3
	movea.l	a1,a0
	movea.l	(8,sp),a2
	movea.l	a2,a1
	suba.l	(12,sp),a1
	bsr.w	unpack2
	movea.l	a2,a0
	movea.l	a5,a3
	movea.l	(sp)+,a1
	movea.l	a1,a2
	adda.l	(12,sp),a2
	movem.l	a1/a2,(8,sp)
	bsr.w	unpack3
	movem.l	(sp)+,a2/a3
	move.w	#$400/4-1,d0
.rs400	move.l	-(a2),-(a3)
	dbf	d0,.rs400
	movem.l	(sp)+,a0/a1
	rts

u1d1	dc.w	$ff
u1d2	dc.w	-2
u1d3	dc.w	-2
u1d4	dc.w	-2

; a0 = src
; a1 = dest
; a2 = src2
; d0-d7/a3-a6 = trash

unpack1 move.l	(a0)+,d3
	subq.l	#1,d3
	move.l	d3,d5
	swap	d5
	move.w	(a0)+,d4
	moveq	#0,d6
	move.b	(a0)+,d6
	movem.l	d3-d6,-(sp)
	lea	u1d1+8(pc),a4
	move.l	#$fffefffe,-(a4)
	move.l	#$00fffffe,-(a4)
	moveq	#2,d5
	move.l	#$100,d6
	moveq	#0,d7
	moveq	#0,d0
	move.b	(a0)+,d0
	movea.l	a2,a6
	move.l	d0,d1
	add.l	d1,d1
.lppre	moveq	#0,d2
	moveq	#0,d4
	move.b	(a0)+,d2
	move.b	(a0)+,d4
	add.w	d4,(a4)
	add.w	d4,(a4)
	add.w	d2,d4
	move.w	d2,(a6)
	adda.l	d1,a6
	move.w	d4,(a6)
	adda.l	d1,a6
	move.w	d6,(a6)
	add.w	d2,d2
	sub.w	d2,(a6)
	lsr.w	#1,d2
	adda.l	d1,a6
	move.w	d7,(a6)
	sub.w	d4,(a6)
	suba.l	d1,a6
	suba.l	d1,a6
	suba.l	d1,a6
	addq.l	#2,a6
	move.l	d5,d3
	sub.l	d4,d3
	add.w	d3,d7
	sub.l	d2,d4
	add.l	d4,d6
	add.l	d4,d6
	move.l	d2,d5
	add.l	d5,d5
	subq.w	#1,d0
	bne.b	.lppre
	add.w	d1,(2,a4)
	lea	(4,a4),a5
	add.w	d1,(a5)
	add.w	d1,(a5)
	add.w	d1,(a5)
	add.w	d1,(6,a4)
	add.w	d1,(6,a4)
	lsl.l	#2,d1
	lea	(a2,d1.l),a6
	movea.l	a6,a5
	move.w	(a4),d0
.cp	move.b	(a0)+,(a5)+
	dbra	d0,.cp
	movem.l	(sp)+,d3-d6

	movea.l	a2,a5
	adda.l	d6,a5
	adda.l	d6,a5
	subq.l	#2,a5
	moveq	#0,d1
.lp	cmp.w	d6,d1
	bcs.b	.1
	sub.w	d6,d1
	rol.w	d6,d0
	move.w	d0,d2
	and.w	d4,d2
	movea.l	a5,a3
	bra.b	.2

.1	moveq	#0,d2
	movea.l	a2,a3
	dbra	d1,.lp2
	move.w	(a0)+,d0
	moveq	#15,d1
.lp2	add.w	d0,d0
	addx.w	d2,d2
.2	cmp.w	(a3)+,d2
	dbcc	d1,.lp2
	bcc.b	.3
	move.w	(a0)+,d0
	moveq	#15,d1
	bra.b	.lp2

.3	move.w	(2,a4),d7
	cmp.w	(a3,d7.w),d2
	bcs.b	.4
	move.w	(4,a4),d7
	add.w	(a3,d7.w),d2
	move.b	(a6,d2.w),(a1)+
	dbra	d3,.lp
	dbra	d5,.lp
	rts

.4	add.w	d2,d2
	move.w	(6,a4),d7
	add.w	(a3,d7.w),d2
	move.b	(a6,d2.w),(a1)+
	move.b	(1,a6,d2.w),(a1)+
	subq.w	#2,d3
	bcc.b	.lp
	dbra	d5,.lp
	rts

; a0 = src end
; a1 = dest start
; a2 = dest end
; a3 = buffer, used by a5, jump table, provided buffer no longer used

unpack2	move.l	(_expmem,pc),a5
	add.w	#exp_unpack2,a5

	movea.l	a5,a6			;build the jump table
	move.w	#$FF,d7
	lea	(.c_cpd0,pc),a4
.tab1	move.l	a4,(a6)+
	dbra	d7,.tab1

	lea	(.jmps,pc),a6
	lea	(unpack2,pc),a3
	moveq	#9,d7
.tab2	moveq	#0,d6
	move.b	-(a0),d6
	lsl.w	#2,d6
	move.w	(a6)+,d5
	ext.l	d5
	add.l	a3,d5
	move.l	d5,(a5,d6.w)
	dbra	d7,.tab2

	lea	(.c_cpy,pc),a3
	moveq	#15,d7
.tab3	moveq	#0,d6
	move.b	-(a0),d6
	lsl.w	#2,d6
	move.l	a3,(a5,d6.w)
	addq.l	#6,a3
	dbra	d7,.tab3

	moveq	#0,d6
	move.b	-(a0),d6
	lsl.w	#2,d6
	lea	(.c_cpz,pc),a3
	move.l	a3,(a5,d6.w)

	lea	(.c_cpn3,pc),a4
	move	#$c000,d6
	moveq	#3,d7
	bra	.loop

.c_cpo7	moveq	#0,d1		;copy offset 7 bytes
	move.b	-(a0),d1
	beq.b	.c_cpd0
	lea	(a2,d1.w),a6
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
.c_cpn3	move.b	-(a6),-(a2)	;copy next 3 bytes
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
	bra.b	.loop

.c_cpon	move.b	-(a0),d1	;copy offset n bytes
	move.b	d1,d2
	andi.w	#$FC,d1
	beq.b	.c_cpd0
	lsr.w	#2,d1
	and.w	d7,d2
	lea	(a2,d1.w),a6
	add.w	d2,d2
	neg.w	d2
	jmp	(a4,d2.w)

.c_cpln	moveq	#0,d2		;copy long offset n bytes
	move.b	-(a0),d2
	beq.b	.c_cpd0
	move.w	d2,d1
	lsr.w	#2,d2
	lsl.w	#8,d1
	move.b	-(a0),d1
	andi.w	#$3FF,d1
	lea	(1,a2,d1.w),a6
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
.cp1	move.b	-(a6),-(a2)
	dbra	d2,.cp1

.loop	cmpa.l	a1,a2		;main loop
	bls.w	.rts
	move.b	-(a0),d0
	moveq	#0,d1
	move.b	d0,d1
	add.w	d1,d1
	add.w	d1,d1
	movea.l	(a5,d1.w),a3
	jmp	(a3)
.rts	rts

.c_cpd0	move.b	d0,-(a2)	;copy byte direct
	bra.b	.loop

.c_cpl4	moveq	#0,d1		;copy offset 4 bytes
	move.b	-(a0),d1
	beq.b	.c_cpd0
	lsl.w	#8,d1
	move.b	-(a0),d1
	cmp.w	d6,d1
	bcc.b	.cpvl
	lea	(a2,d1.l),a6
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
	bra.w	.loop

.cpvl	move.w	#$401,d3
.cpvld3	andi.w	#$3FFF,d1	;copy very long offset+d3 n bytes
	move.b	d1,d2
	andi.w	#7,d2
	lsr.w	#3,d1
	add.w	d3,d1
	lea	(a2,d1.w),a6
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
.cp2	move.b	-(a6),-(a2)
	dbra	d2,.cp2
	bra.w	.loop

.c_cpn	moveq	#0,d1		;copy n
	move.b	-(a0),d1
	beq.w	.c_cpd0
	lsl.w	#8,d1
	move.b	-(a0),d1
	move.w	#$2C01,d3
	cmp.w	d6,d1
	bcc.b	.cpvld3
	moveq	#0,d2
	move.b	-(a0),d2
	subq.w	#1,d2
	subi.w	#$100,d1
	lea	(a2,d1.l),a6
.cp3	move.b	-(a6),-(a2)
	dbra	d2,.cp3
	bra.w	.loop

.c_cpx1	move.w	#$C01,d3
	bra.b	.cpx

.c_cpx2	move.w	#$9401,d3
	bra.b	.cpx

.c_cpx3	move.w	#$7401,d3
	bra.b	.cpx

.c_cpx4	move.w	#$5401,d3
	bra.b	.cpx

.c_cpx5	move.w	#$3401,d3
.cpx	moveq	#0,d2
	move.b	-(a0),d2
	beq.w	.c_cpd0
	move.l	d2,d1
	lsr.w	#5,d2
	lsl.w	#8,d1
	move.b	-(a0),d1
	andi.w	#$1FFF,d1
	add.w	d3,d1
	lea	(a2,d1.l),a6
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
.cp4	move.b	-(a6),-(a2)
	dbra	d2,.cp4
	bra.w	.loop

.c_cpy	move.w	#$3F,d3
	bra.b	.cpy

	move.w	#$7E,d3
	bra.b	.cpy

	move.w	#$BD,d3
	bra.b	.cpy

	move.w	#$FC,d3
	bra.b	.cpy

	move.w	#$13B,d3
	bra.b	.cpy

	move.w	#$17A,d3
	bra.b	.cpy

	move.w	#$1B9,d3
	bra.b	.cpy

	move.w	#$1F8,d3
	bra.b	.cpy

	move.w	#$237,d3
	bra.b	.cpy

	move.w	#$276,d3
	bra.b	.cpy

	move.w	#$2B5,d3
	bra.b	.cpy

	move.w	#$2F4,d3
	bra.b	.cpy

	move.w	#$333,d3
	bra.b	.cpy

	move.w	#$372,d3
	bra.b	.cpy

	move.w	#$3B1,d3
	bra.b	.cpy

	move.w	#$3F0,d3
	bra.b	.cpy

	move.w	#$42F,d3
.cpy	move.b	-(a0),d1
	move.b	d1,d2
	andi.w	#$FC,d1
	beq.w	.c_cpd0
	lsr.w	#2,d1
	and.w	d7,d2
	add.w	d3,d1
	lea	(a2,d1.w),a6
	move.b	-(a6),-(a2)
	move.b	-(a6),-(a2)
.cp5	move.b	-(a6),-(a2)
	dbra	d2,.cp5
	bra.w	.loop

.c_cpz	move.b	-(a0),d1
	beq.w	.c_cpd0
	move.b	d1,d2
	andi.w	#$3F,d1
	rol.b	#2,d2
	and.w	d7,d2
	add.w	d2,d2
	lea	(.data,pc),a6
	move.w	(a6,d2.w),d3
	ext.l	d3
	move.b	-(a0),d4
	ror.l	#8,d4
	move.b	-(a0),d4
	ror.l	#8,d4
	move.b	-(a0),d4
	ror.l	#8,d4
	move.b	-(a0),d4
	ror.l	#8,d4
.cp6	move.b	d4,-(a2)
	ror.l	#8,d4
	move.b	d4,-(a2)
	ror.l	#8,d4
	move.b	d4,-(a2)
	ror.l	#8,d4
	move.b	d4,-(a2)
	ror.l	#8,d4
	moveq	#0,d5
	move.b	-(a0),d5
	add.l	d3,d5
	sub.l	d5,d4
	dbra	d1,.cp6
	addq.l	#1,a0
	bra.w	.loop

.data	dc.w	$FF80
	dc.w	0
	dc.w	$100
	dc.w	$200
.jmps	dc.w	.c_cpo7-unpack2
	dc.w	.c_cpon-unpack2
	dc.w	.c_cpln-unpack2
	dc.w	.c_cpl4-unpack2
	dc.w	.c_cpx1-unpack2
	dc.w	.c_cpn-unpack2
	dc.w	.c_cpx5-unpack2
	dc.w	.c_cpx4-unpack2
	dc.w	.c_cpx3-unpack2
	dc.w	.c_cpx2-unpack2

_rts	rts

unpack3	movea.l	a3,a6
	moveq	#0,d0
	moveq	#0,d7
.set	move.b	#2,(a3)+		;skip 2
	subq.b	#1,d0
	bne.b	.set
	move.b	(a0)+,d0
	move.b	#6,(a6,d0.w)		;skip 6
	move.b	(a0)+,d0
	move.b	#$10,(a6,d0.w)		;skip 16
	move.b	(a0)+,d0
	move.b	#$1C,(a6,d0.w)		;skip 28

	lea	.jmp-2(pc),a5
.lp	cmp.l	a2,a1
	bcc	_rts
	move.b	(a0)+,d0
	move.b	(a6,d0.w),d7
	jmp	(a5,d7.l)

.jmp	move.b	d0,(a1)+
	bra.b	.lp

	moveq	#0,d2
	move.b	(a0)+,d2
	beq.b	.jmp
	moveq	#0,d1
	bra.b	.1

	move.b	(a0)+,d1
	beq.b	.jmp
	move.b	d1,(a1)+
	move.b	d1,(a1)+
	move.b	d1,(a1)+
	bra.b	.lp

	move.b	(a0)+,d1
	beq.b	.jmp
	moveq	#0,d2
	move.b	(a0)+,d2
.1	subq.b	#3,d2
	bcs.b	.2
	move.b	d1,(a1)+
	move.b	d1,(a1)+
.cp	move.b	d1,(a1)+
	dbra	d2,.cp
	bra.b	.lp

.2	addq.b	#1,d2
	bne.b	.3
	move.b	(a0)+,d2
	lsl.w	#8,d2
	move.b	(a0)+,d2
	lsl.l	#8,d2
.3	move.b	(a0)+,d2
	lsl.l	#8,d2
	move.b	(a0)+,d2
	subq.l	#1,d2
	move.l	d2,d3
	swap	d3
.cp2	move.b	d1,(a1)+
	dbra	d2,.cp2
	dbra	d3,.cp2
	bra.b	.lp

_intack1	move	d0,_custom+intreq
		tst	_custom+intreqr
		move.l	(a7)+,d0
		rte

_intack3	move	#8,_custom+intreq
		tst	_custom+intreqr
		rte

_intack10	move.w	#INTF_COPER,_custom+intreq
		tst.w	_custom+intreqr
		rte

;======================================================================
; original "Rainbow Arts" and "Innerprise"
; SPS 1838 and SPS 92
; 216 = keycode
; = level
; = sublevel

_v1_v2
	;bootblock stuff
		lea	_60000(pc),a0
		lea	$60000,a1
		move.l	a1,a2
		jsr	(resload_LoadFileDecrunch,a3)
		move.l	d0,d7			;d7 = size IMPORTANT !!

	;check version
		move.l	a2,a0          
		jsr	(resload_CRC16,a3)
		lea	_pl_60000_sps92(pc),a0
		cmp.w	#$5346,d0
		beq.b	.patch
		lea	_pl_60000_sps1838(pc),a0
		cmp.w	#$59fe,d0
		bne	_badver
        lea _keyboard_plug(pc),a1
        move.l  #$070b8,(a1)        ; set proper keyboard plug address
.patch		move.l	a2,a1
		jsr	(resload_Patch,a3)

		jmp	($28,a2)

_pl_60000_sps92	PL_START
	;	PL_S	$3a,10			;skip rainbow arts intro unpack/run
		PL_PS	$3e,_ra
		PL_PS	$70,_waitspeech
		PL_ORW	$c0,INTF_PORTS
        PL_IFBW
		PL_PS	$d8,_picshow12_bw
        PL_ELSE
		PL_PS	$d8,_picshow12
        PL_ENDIF
		PL_P	$104,_100_sps92
		PL_PS	$17a,_waitdma
		PL_ORW	$182,INTF_PORTS
		PL_P	$310,_intack1
		PL_P	$4fa,_load		;with cache
		PL_P	$57a,_load		;plain
		PL_P	$78c,_pp20
	;the following moves to $50000 (init2, speech)
		PL_P	$10418,_intack10
		PL_END

_pl_60000_sps1838	PL_START
		PL_PS	$54,_waitspeech
		PL_ORW	$a4,INTF_PORTS
        PL_IFBW
		PL_PS	$bc,_picshow12_bw
        PL_ELSE
		PL_PS	$bc,_picshow12
        PL_ENDIF
		PL_P	$e8,_100_sps1838
		PL_PS	$15e,_waitdma
		PL_ORW	$166,INTF_PORTS
		PL_P	$2f4,_intack1
		PL_P	$4de,_load		;with cache
		PL_P	$55e,_load		;plain
		PL_P	$770,_pp20
	;the following moves to $50000 (init2, speech)
		PL_P	$c198,_intack10
		PL_END

_waitdma	waitvb	a6
		move.w	#$8380,(dmacon,a6)
		rts

_picshow12_bw
.loop
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.out
	bra.b	.loop
.out
_picshow12
        clr.w	(a0)+
		dbf	d0,_picshow12
		bra	_picshow

_100_sps92		lea	_pl_100_sps92(pc),a5
		bra	_100_v13

_100_sps1838		lea	_pl_100_sps1838(pc),a5
		lea	$60392,a2		;original
		bra	_100_v123

_pl_100_sps92	PL_START
		PL_P	$61c,_load		;with cache
		PL_P	$696,_load		;plain
		PL_P	$af4,_pp20
        

        
		PL_NEXT	_pl_100_v13

_pl_100_sps1838	PL_START

        PL_IFC1X    0
        PL_W    $079ce+2-$100,0     ; sub 0 lives
        PL_ENDIF
        PL_IFC1X    1
        PL_W    $07892+2-$100,0     ; sub 0 bombs
        PL_ENDIF

        PL_PS   $06d88-$100,_vbl_hook

        PL_IFC2X    0
        PL_PSS  $44CC-$100,read_joystick_button_jumps,2
        PL_PSS  $04524-$100,_read_fire_2_green,6
        PL_PSS  $0453a-$100,_read_fire_2_green,6
        PL_ELSE
        PL_PSS  $04524-$100,_read_fire_2_blue,6
        PL_PSS  $0453a-$100,_read_fire_2_blue,6
        PL_PSS  $44CC-$100,read_joystick_up_jumps,2    
        PL_ENDIF

        PL_PSS  $44F0-$100,_read_fire,2
        PL_PSS  $4502-$100,_read_fire,2
        
		PL_P	$61c,_load		;with cache
		PL_P	$696,_load		;plain
		PL_P	$af4,_pp20
		PL_PS	$5542,_b10
		PL_PS	$55a0,_b10
		PL_PS	$56a2,_b10
		PL_PS	$5740,_b10
		PL_PS	$592e,_b10
		PL_PS	$5a80,_b10
		PL_PS	$5d62,_b9
		PL_PS	$5d8e,_b12
		PL_PS	$5dc6,_b10
		PL_PS	$5f1a,_b10
		PL_PS	$5f88,_b11
		PL_P	$61ba,_b29
		PL_P	$62c4,_b29
		PL_PS	$632a,_b9
		PL_PS	$67da,_b10
		PL_P	$6ce8,_intack1
		PL_PS	$6fae,_chkkb
		PL_P	$6fee,_fixkb
		PL_P	$7000,_intack3
		PL_PS	$74e8,_b9
		PL_NEXT	_pl_100_v123

;--------------------------------
; in:
; a0 = src start
; a1 = src end
; a2 = dest start
; out:
; a2 = dest start

_pp20		bsr	.dec
	;after unpacking
	; a2 = start
	; a5 = end
		move.l	a2,a0
		move.l	a5,a1
		bsr	_patch_lev_intr
		moveq	#0,d0
		rts

.dec	cmpi.l	#$50503230,(a0)
	bne.b	lbC00080E
	addq.l	#4,a0
	movea.l	a2,a4
	move.l	-(a1),d0
	moveq	#0,d1
	move.b	d0,d1
	lsr.l	#8,d0
	adda.l	d0,a4
	move.l	a4,a5			;a5 = dest end
	move.l	-(a1),d2
	moveq	#$20,d3
	tst.w	d1
	beq.b	lbC0007AC
	bsr.b	lbC000824
lbC0007AC	bsr.b	lbC000810
	bne.b	lbC0007CA
	moveq	#0,d4
lbC0007B2	moveq	#1,d1
	bsr.b	lbC000826
	add.w	d0,d4
	cmpi.w	#3,d0
	beq.b	lbC0007B2
lbC0007BE	bsr.b	lbC000822
	move.b	d0,-(a4)
	dbra	d4,lbC0007BE
	cmpa.l	a4,a2
	bcc.b	lbC00080E
lbC0007CA	moveq	#1,d1
	bsr.b	lbC000826
	moveq	#0,d5
	move.w	d0,d1
	move.b	(a0,d0.w),d5
	move.w	d0,d4
	addq.w	#1,d4
	cmpi.w	#3,d0
	bne.b	lbC0007FA
	move.w	d5,d1
	bsr.b	lbC000810
	bne.b	lbC0007E8
	moveq	#7,d1
lbC0007E8	bsr.b	lbC000824
	move.w	d0,d6
lbC0007EC	moveq	#2,d1
	bsr.b	lbC000826
	add.w	d0,d4
	cmpi.w	#7,d0
	beq.b	lbC0007EC
	bra.b	lbC000800

lbC0007FA	move.w	d5,d1
	bsr.b	lbC000824
	move.w	d0,d6
lbC000800	lea	(1,a4,d6.w),a3
lbC000804	move.b	-(a3),-(a4)
	dbra	d4,lbC000804
	cmpa.l	a4,a2
	bcs.b	lbC0007AC
lbC00080E	rts

lbC000810	lsr.l	#1,d2
	roxl.w	#1,d0
	subq.w	#1,d3
	bne.b	lbC00081C
	move.l	-(a1),d2
	moveq	#$20,d3
lbC00081C	btst	#0,d0
	rts

lbC000822	moveq	#8,d1
lbC000824	subq.w	#1,d1
lbC000826	moveq	#0,d0
lbC000828	lsr.l	#1,d2
	roxl.l	#1,d0
	subq.w	#1,d3
	bne.b	lbC000834
	move.l	-(a1),d2
	moveq	#$20,d3
lbC000834	dbra	d1,lbC000828
	rts

;--------------------------------
; fix bad random generator:
; and a lot variations of this
;	2078 01dc		move.l	($1dc).w,a0
;	3010			move.w	(a0),dx
;	54b8 01dc		addq.l	#2,($1dc).w
;	b1fc 00ff ffde		cmpa.l	#$ffffde,a0
;	6d08			blt.b	...
;	21fc 00fc 00d2 01dc	move.l	#$fc00d2,($1dc).w

_rnd_init	move.l	(_expmem,pc),a0
		move.w	#RND_LEN/2-1,d0
		move.w	#$3fb2,d1
.fill		add.w	(vhposr+_custom),d1
		ror.w	#1,d1
		move.w	d1,(a0)+
		dbf	d0,.fill
		rts

; a0 = start
; a1 = end
; a2 = rnd pointer variable

_fix_rnd	move.l	(_expmem,pc),d1
		add.l	#RND_STRTOFF,d1
		move.l	d1,(a2)
		move.w	#$21fc,d0
.loop		cmp.w	(a0)+,d0
		bne	.next
		cmp.l	#$fc00d2,(a0)
		bne	.next
		move.l	d1,(a0)
		move.l	d1,(-8,a0)
		add.l	#RND_LEN-RND_STRTOFF-RND_STOPOFF,(-8,a0)
.next		cmp.l	a0,a1
		bhs	.loop
		rts

;--------------------------------
; d0 = starttrack
; d1 = size in bytes
; d2 = dest. address
; $1978 = 6520 bytes per track

_load		movem.l	d0-d1/a0-a2,-(a7)
		bsr	_LongToStr
		move.l	d2,a1
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFileDecrunch,a2)
		cmp.l	#$1c,(a7)
		bne	.q
	;MUS0, not packed
		lea	_pl3m(pc),a0
		move.l	d2,a1
		jsr	(resload_Patch,a2)
.q		movem.l	(a7)+,d0-d1/a0-a2
		rts

;--------------------------------

_loadhighs	lea	$2d6,a0
_loadhighs_adr	movem.l	d0-d1/a0-a2,-(a7)
		move.l	(_resload,pc),a2		;A2 = resload
		lea	_highsname(pc),a0
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		beq	.end
		lea	_highsname(pc),a0
		move.l	(8,a7),a1
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	(8,a7),a0
		bsr	_crypt
.end		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================
; 1d6 = keycode
; 5b7a = level
; 5b7c = sublevel

_cdtv		lea	_main(pc),a0
		lea	$c0,a1
		move.l	a1,a4			;a4 = main
		jsr	(resload_LoadFileDecrunch,a3)
	
        ; set variables
        lea _keyboard_plug(pc),a1
        move.l  #$06f5a,(a1)
        lea _start_level_address(pc),a1
        move.l  #$5b7a,(a1)
       
		move.l	a4,a0
		lea	(a0,d0.l),a1
		lea	$19c,a2
		bsr	_fix_rnd

		lea	$296,a0
		bsr	_loadhighs_adr
		
		lea	.pl(pc),a0
		move.l	a4,a1
		jsr	(resload_Patch,a3)
		
		waitvb
		jmp	(a4)

.pl		PL_START
		PL_P	$5ca,.load
		PL_P	$8f6,.savehighs
		PL_S	$9c4,12			;set sp
		PL_S	$a66,6			;set sp
		PL_ORW	$ac2,INTF_PORTS
		PL_P	$ac6,.dmaon
		PL_PS	$b48,_b9
		PL_PS	$165c,_b9
		PL_PS	$1698,_b14
		PL_W	$16e0,$6006		;blitwait
		PL_PS	$3786,_b10
		PL_PS	$37e4,_b10
		PL_PS	$38e6,_b10
		PL_PS	$3984,_b10
		PL_PS	$3cc4,_b10
		PL_PS	$3fa6,_b9
		PL_PS	$3fd2,_b12
		PL_W	$3ff6,$6006		;blitwait
		PL_PS	$4012,_b10
		PL_PS	$4166,_b10
		PL_PS	$41d4,_b11
		PL_PS	$458a,_b9
		PL_PS	$4a3a,_b10
		PL_W	$4f06,$6006		;blitwait
	;	PL_S	$4f0e,8			;clear level/sublevel
	;	PL_S	$4fa6,$55dc-$4fa6	;enter next (extro with 4-1)
		PL_W	$5306,$6006		;blitwait
		PL_PS	$54ec,_b21
		PL_R	$5504			;blitwait
		PL_PS	$569e,_b9
		PL_W	$5700,$6006		;blitwait
	;	PL_W	$5aba,4			;start level
	;	PL_W	$5abc,1			;start sublevel
		PL_PS	$5d3c,_b9
		PL_PS	$5d64,_b12
		PL_PS	$5d9c,_b10
		PL_PS	$5e2c,_b11
		PL_R	$6616			;blitwait
		PL_PS	$664a,_b18
		PL_W	$6736,$6006		;blitwait
		PL_PS	$6746,_b13
		PL_W	$675c,$6006		;blitwait
		PL_R	$6870			;blitwait
		PL_R	$6a0c			;blitwait
		PL_PS	$6e90,_chkkb
		PL_P	$6ed0,_fixkb
		PL_PS	$73d6,_b9
        
        PL_IFC1X    0
        PL_W    $0787c+2-$c0,0     ; sub 0 lives
        PL_ENDIF
        PL_IFC1X    1
        PL_W    $07740+2-$c0,0     ; sub 0 bombs, also time
        PL_ENDIF
        
        PL_PS   $06c28-$c0,_vbl_hook

        PL_IFC2X    0
        PL_PSS  $026d0-$c0,read_joystick_button_jumps,2
        PL_PSS  $02728-$c0,_read_fire_2_green,6
        PL_PSS  $0273e-$c0,_read_fire_2_green,6
        PL_ELSE
        PL_PSS  $02728-$c0,_read_fire_2_blue,6
        PL_PSS  $0273e-$c0,_read_fire_2_blue,6
        PL_PSS  $026d0-$c0,read_joystick_up_jumps,2    
        PL_ENDIF

        PL_PSS  $02706-$c0,_read_fire,2
        PL_PSS  $026f4-$c0,_read_fire,2
        
        PL_PSS  $04fce-$c0,_set_start_level,2
        
		PL_END

.dmaon		move.l	#$7080+$c0,($80,a6)
		move.w	#$87e0,($96,a6)
		rts

.load		clr.l	-(a7)
		move.l	d0,-(a7)
		move.l	a7,a0			;filename
		move.l	d1,a1			;destination
		move.l	a1,-(a7)
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	d0,d2			;filesize

		lea	_pl41(pc),a0
		cmp.l	#"LEV1",(4,a7)
		beq	.patch
		lea	_pl42(pc),a0
		cmp.l	#"LEV2",(4,a7)
		beq	.patch
		lea	_pl43(pc),a0
		cmp.l	#"LEV3",(4,a7)
		beq	.patch
		lea	_pl44(pc),a0
		cmp.l	#"LEV4",(4,a7)
		beq	.patch
		lea	_pl45(pc),a0
		cmp.l	#"LEV5",(4,a7)
		beq	.patch
		lea	_pl4i(pc),a0
		cmp.l	#"INTR",(4,a7)
		bne	.end

.patch		move.l	(a7),a1
		jsr	(resload_Patch,a2)
		move.l	(a7),a0
		lea	(a0,d2.l),a1
		lea	$19c,a2
		bsr	_fix_rnd
		
.end		add.w	#12,a7
		rts

.savehighs	lea	$296,a0
		bra	_savehighs_adr

_pl41		PL_START			;1b980
		PL_PS	$1940,_b9
		PL_PS	$19c0,_b1
		PL_PS	$19dc,_b2
		PL_PS	$1a8c,_b3
		PL_PS	$1aea,_b4
		PL_PS	$1b10,_b2
		PL_PS	$1b26,_b1
		PL_PS	$1b4e,_b5
		PL_PS	$1b66,_b1
		PL_PS	$1b96,_b6
		PL_PS	$1bc8,_b7
		PL_PS	$1bde,_b7
		PL_PS	$1bf4,_b7
		PL_PS	$1c16,_b8
		PL_PS	$1c36,_b7
		PL_PS	$1c4c,_b7
		PL_PS	$1c62,_b7
		PL_PS	$1cde,_b9
		PL_PS	$1d3a,_b15
		PL_END

_pl42		PL_START			;1b980
		PL_PS	$13d0,_b16
		PL_PS	$14d4,_b9
		PL_PS	$1534,_b15
		PL_PS	$1562,_b15
		PL_PS	$157a,_b15
		PL_PS	$158e,_b15
		PL_PS	$1d4c,_b9
		PL_PS	$1d76,_b17
		PL_END

_pl43		PL_START			;1b980
		PL_PS	$4fd4,_b9
		PL_END

_pl44		PL_START			;1b980
		PL_PS	$1a12,_b20
		PL_PS	$1a7c,_b19
		PL_PS	$1af0,_b19
		PL_PS	$1b40,_b9
		PL_PS	$1b98,_b15
		PL_PS	$43a0,_b9
		PL_PS	$43ba,_b22
		PL_PS	$4760,_b23
		PL_R	$47d8			;blitwait
		PL_R	$4862			;blitwait
		PL_END

_pl45		PL_START			;1b980
		PL_PS	$f02,_b9
		PL_PS	$fb4,_b9
		PL_PS	$100c,_b15
		PL_PS	$343c,_b9
		PL_P	$3464,_b24
		PL_END

_pl4i		PL_START			;30000
	;	PL_CW	$14
		PL_ORW	$2e,INTF_PORTS
		PL_PS	$2a2,_chkfixkb
		PL_S	$606,4
		PL_PS	$60a,_waitdma2
		PL_PS	$1814,_b9
		PL_PS	$1834,_b25
		PL_PS	$185e,_b26
		PL_PS	$186c,_b26
		PL_PS	$187a,_b26
		PL_PS	$18a0,_b27
		PL_PS	$18d2,_b11
		PL_PS	$1930,_b28
		PL_END

_b1		bsr	_wb
		movem.l	a3-a4,($50,a6)
		rts
_b2		bsr	_wb
		move.w	#2,($66,a6)
		rts
_b3		sub.w	d0,a3
		bsr	_wb
		clr.l	($64,a6)
		rts
_b4		lea	($100,a4),a4
		bsr	_wb
		clr.l	($64,a6)
		add.l	#2,(a7)
		rts
_b5		lea	($180,a4),a4
		bsr	_wb
		clr.l	($64,a6)
		add.l	#2,(a7)
		rts
_b6		bsr	_wb
		move.w	#$fca,($40,a6)
		rts
_b7		addq.w	#4,a3
		bsr	_wb
		move.l	a4,($54,a6)
		rts
_b8		add.w	(a0,d0.w),a5
		bsr	_wb
		move.l	a4,($54,a6)
		add.l	#2,(a7)
		rts
_b9		bsr	_wb
		move.w	#$9f0,($40,a6)
		rts
_b10		bsr	_wb
		move.l	#$fffefffe,($62,a6)
		add.l	#2,(a7)
		rts
_b11		swap	d0
		bsr	_wb
		move.w	d0,($42,a6)
		rts
_b12		move.l	(a2)+,d2
		bsr	_wb
		move.l	d2,($54,a6)
		rts
_b13		add.w	d6,a1
		bsr	_wb
		move.l	a2,($50,a6)
		rts
_b14		add.l	d3,d2
		bsr	_wb
		move.l	d1,($50,a6)
		rts
_b15		bsr	_wb
		move.l	(a1,d0.w),($50,a6)
		rts
_b16		moveq	#2,d1
		bsr	_wb
		move.w	d1,($60,a6)
		rts
_b17		add.w	#$7f2,a2
		bsr	_wb
		move.l	a2,($54,a6)
		add.l	#2,(a7)
		rts
_b18		move.l	(4,a0),a2
		bsr	_wb
		clr.l	($44,a6)
		add.l	#2,(a7)
		rts
_b19		lea	($80,a2),a3
		bsr	_wb
		move.l	a3,($50,a6)
		add.l	#2,(a7)
		rts
_b20		bsr	_wb
		move.w	#$be2,($40,a6)
		rts
_b21		bsr	_wb
		move.w	(2,a0),($66,a6)
		rts
_b22		bsr	_wb
		move.l	(10,a0,d0.w),($50,a6)
		rts
_b23		moveq	#-4,d5
		bsr	_wb
		clr.l	($44,a6)
		rts
_b24		bsr	_wb
		move.l	a1,($54,a6)
		move.w	(4,a0),($58,a6)
		add.w	#$900,a1
		dbf	d0,_b24
		rts
_b25		move.w	(2,a5),d0
		bsr	_wb
		move.w	d0,($64,a6)
		addq.l	#2,(a7)
		rts
_b26		bsr	_wb
		movem.l	a0-a1,($50,a6)
		rts
_b27		bsr	_wb
		move.l	#$ffff0000,($44,a6)
		addq.l	#2,(a7)
		rts
_b28		bsr	_wb
		movem.l	a0-a1,($50,a6)
		move.l	a1,($48,a6)
		move.w	d0,($58,a6)
		lea	($2198,a1),a1
		bsr	_wb
		movem.l	a0-a1,($50,a6)
		move.l	a1,($48,a6)
		move.w	d0,($58,a6)
		lea	($2198,a1),a1
		add.l	#$1958-$1930-6,(a7)
_wb		BLITWAIT a6
		rts
_b29		bsr	_wb
		move.l	#$fffefffe,($62,a6)
		rts
_bx1		movem.w	(a2)+,d2/d4
		jsr	(a5)
		bne	.1
		addq	#1,$35f0
		add	d1,d1
		add	d1,d1
		move.l	(a4,d1.w),d1
		cmp.l	#$80000,d1		;maybe corrupt level data?
		bhs	.1
		move.l	(a3,d2.w),d2
		add.l	d3,d2
		bsr	_wb
		move.l	d1,(bltapt,a6)
		move.l	d2,(bltdpt,a6)
		move	#$2002,(bltsize,a6)
		add.l	#$c000,d2
		bsr	_wb
		move.l	d1,(bltapt,a6)
		move.l	d2,(bltdpt,a6)
		move	#$2002,(bltsize,a6)
		add.l	#$c000,d2
		bsr	_wb
		move.l	d1,(bltapt,a6)
		move.l	d2,(bltdpt,a6)
		move	#$2002,(bltsize,a6)
.1		dbra	d0,_bx1
		move.l	a2,(2,a0)
		rts
_bb1		move.l	(a0,d3.w),d6
		cmp.l	#$80000,d6		;maybe corrupt level data?
		bhs	.1
		move.l	d6,(bltapt,a6)
		rts
.1		add.l	#4,(a7)			;skip bltsize write
		rts
_bx2		bsr	_wb
		move.l	a2,(bltapt,a6)
		move.l	a1,(bltbpt,a6)
		move.l	d1,(bltcpt,a6)
		move.l	d0,(bltdpt,a6)
		move.w	d7,(bltsize,a6)
		bsr	_wb
		move.l	d3,(bltcpt,a6)
		move.l	d2,(bltdpt,a6)
		move.w	d5,(bltsize,a6)
		moveq	#$30,d4
		add.l	d4,d0
		add.l	d4,d2
		add.l	d4,d1
		add.l	d4,d3
		adda.w	d6,a1
		bsr	_wb
		move.l	a2,(bltapt,a6)
		move.l	a1,(bltbpt,a6)
		move.l	d1,(bltcpt,a6)
		move.l	d0,(bltdpt,a6)
		move.w	d7,(bltsize,a6)
		bsr	_wb
		move.l	d3,(bltcpt,a6)
		move.l	d2,(bltdpt,a6)
		move.w	d5,(bltsize,a6)
		add.l	d4,d0
		add.l	d4,d2
		add.l	d4,d1
		add.l	d4,d3
		adda.w	d6,a1
		bsr	_wb
		move.l	a2,(bltapt,a6)
		move.l	a2,(bltbpt,a6)
		move.l	d1,(bltcpt,a6)
		move.l	d0,(bltdpt,a6)
		move.w	d7,(bltsize,a6)
		bsr	_wb
		move.l	d3,(bltcpt,a6)
		move.l	d2,(bltdpt,a6)
		move.w	d5,(bltsize,a6)
		add.l	d4,d0
		add.l	d4,d2
		add.l	d4,d1
		add.l	d4,d3
		adda.w	d6,a1
		bsr	_wb
		move.l	a2,(bltapt,a6)
		move.l	a2,(bltbpt,a6)
		move.l	d1,(bltcpt,a6)
		move.l	d0,(bltdpt,a6)
		move.w	d7,(bltsize,a6)
		bsr	_wb
		move.l	d3,(bltcpt,a6)
		move.l	d2,(bltdpt,a6)
		move.w	d5,(bltsize,a6)
		rts
_b31		bsr	_wb
		move.w	#$1f0,($40,a6)
		rts
_bx3		moveq	#$30,d4
		moveq	#2,d5
.lp		add.l	d4,d0
		add.l	d4,d1
		add.w	d6,a1
		bsr	_wb
		movem.l	d1/a1/a2,($48,a6)
		move.l	d0,($54,a6)
		move	d7,($58,a6)
		dbra	d5,.lp
		rts
_b32		bsr	_wb
		clr	($42,a6)
		move	#$9f0,($40,a6)
		add.l	#4,(a7)
		rts
_b33		bsr	_wb
		move.l	d3,($54,a6)
		move.w	d1,($58,a6)
		rts

_chkkb		move.b	$bfec01,d0		;original
_chkkbcode	move.b	d0,d1
		not.b	d1
		ror.b	#1,d1
		cmp.b	_keyexit(pc),d1
		beq	_exit
		cmp.b	_keydebug(pc),d1
		beq	_debug
		rts

_chkfixkb	bsr	_chkkbcode
_waitkb		moveq	#3-1,d1
		move.l	d0,-(a7)
.wait1		move.b	(_custom+vhposr),d0
.wait2		cmp.b	(_custom+vhposr),d0
		beq	.wait2
		dbf	d1,.wait1
		move.l	(a7)+,d0
		rts

_fixkb		bsr	_waitkb
		bclr	#6,$bfee01		;original
		movem.l	(a7)+,d0-d2/a0		;original
		move	#8,(_custom+intreq)	;original
		tst	(_custom+intreqr)
		rte				;original

;======================================================================

_savehighs	lea	$2d6,a0
_savehighs_adr	movem.l	d0-d1/a0-a3,-(a7)
		bsr	_crypt
		move.l	#$61*4,d0
		lea	_highsname(pc),a0
		move.l	(8,a7),a1
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
		move.l	(8,a7),a0
		bsr	_crypt
		movem.l	(a7)+,d0-d1/a0-a3
		rts

;----------------------------------------

_crypt		move.w	#$61*4-1,d0
.lp		eor.b	d0,(a0)+
		dbf	d0,.lp
		rts

;----------------------------------------
; IN:	D0 = LONG value
; OUT:	A0 = CPTR string

_LongToStr	lea	(.str,pc),a0
		ror.l	#4,d0
		move.b	.list(PC,d0.w),(a0)+
		clr.w	d0
		rol.l	#4,d0
		move.b	.list(PC,d0.w),(a0)
		subq.w	#1,a0
		rts
		
.list		dc.b	"0123456789abcdef"
.str		ds.b	4
	
;--------------------------------

_badver		pea	TDREASON_WRONGVER
		bra	_end
_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload,pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

_tag		dc.l	WHDLTAG_CUSTOM4_GET
_start_level	dc.l	0
            dc.l	WHDLTAG_CUSTOM5_GET
_start_sublevel	dc.l	0


		dc.l	0

_start_level_address
    dc.l    $1938       ; SPS versions
_keyboard_plug:
    dc.l    $07096      ; SPS98, also amigafun
;--------------------------------

_resload	dc.l	0			;address of resident loader

;======================================================================

	END

