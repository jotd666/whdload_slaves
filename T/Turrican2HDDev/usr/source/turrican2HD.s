;*---------------------------------------------------------------------------
;  :Program.	Turrican2.asm
;  :Contents.	Slave for "Turrican 2"
;  :Author.	Wepl, Kyzer, JOTD
;  :Version.	$Id: turrican2.asm 1.9 2009/07/15 21:41:33 wepl Exp wepl $
;  :History.	09.07.96 initial
;		14.12.96 rework for public installation release
;		23.12.96 installation improved / using new whdload functions
;		31.08.97 update for key managment and sources
;		29.11.98 install stuff removed, decruncher fixed
;		20.02.99 minor speed up for decruncher
;		01.06.00 (passed to Kyzer)
;			 - added intro logo skip, level select
;			 - merged '60000' file into diskimage
;		08.10.06 merged Kyzer's changes
;		11.10.06 level selector reworked and adapted for second game version
;		13.10.06 custom1 added, caches deactivated, pp20 relocated
;		02.06.09 tfmx fixed, Don Adan, issue #2031
;		13.06.09 2nd joystick button fixed, CHRKUM, issue #1196
;		09.07.09 again 2nd joystick button fixed, issue #2113
;		16.06.20 added full joypad controls & jump button, issue #0000412
;                added a comprehensive trainer, issue #0000850
;                merged floppy & CDTV versions (only once slave)
;                level selection at startup
;                added DMACON waits for title music, issue #0002993
;       17.06.20 fixed source indentation to try to keep Wepl unannoyed :)
;                merged floppy & CDTV versions (once source code file, 2 slaves)
;                skip introduction only makes sense for floppy version
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


    IFD BARFLY
    IFD CDTV_VERSION
	OUTPUT	wart:tr/turrican2/Turrican2CDTV.Slave
    ELSE
	OUTPUT	wart:tr/turrican2/Turrican2.Slave
    ENDC
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable warnings
	SUPER
    ENDC
    
; DiskFormat:
; Track 0	std  (512 byte/sec,11 sec/track = 5632 byte/track)
; Track 1	own  (highs)
; Track 2-159	long (6800 byte/track)

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem	       ;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	81920			;ws_ExpMem (only used by CDTV)
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config
       dc.b    "C1:X:trainer infinite lives:0;"
       dc.b    "C1:X:trainer infinite smartbombs:1;"
       dc.b    "C1:X:trainer infinite super smartbombs:2;"
       dc.b    "C1:X:trainer infinite time:3;"
       dc.b    "C2:X:second button for jump:0;"
       dc.b    "C2:X:yellow button for super smartbomb:1;"
       IFND    CDTV_VERSION
       dc.b    "C3:B:skip introduction;"
       ENDC
       dc.b    "C4:L:start level:1,2,3,4,5;"
		dc.b	0
;============================================================================
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

_name		dc.b	"Turrican 2",0
_copy		dc.b	"1991 Factor 5, Rainbow Arts",0
_info		dc.b	"Installed by Wepl, Kyzer & JOTD",10
		dc.b	"Version "
        DECL_VERSION
        dc.b    0
_60000		dc.b	"60000",0
_highsname	dc.b	"highs",0
_data		dc.b	"data",0
_pics		dc.b	'PICS',0
_main		dc.b	'MAIN',0
	EVEN
    include ReadJoyPad.s
    
    
;======================================================================
_start	;	A0 = resident loader
;======================================================================
		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a3			;A3 = resload

        bsr _detect_controller_types
        
		lea	_tags(pc),a0
		jsr	(resload_Control,a3)
        move.l  _button_jumps(pc),d0
        beq.b   .skip
        lea smart_bomb_bit(pc),a0
        move.l  #JPB_BTN_GRN,(a0)
.skip
        IFND    CDTV_VERSION
        
		lea	_60000(pc),a0
		lea	$60000,a1
		move.l	a1,a2
		jsr	(resload_LoadFileDecrunch,a3)

		lea	_pl1(pc),a0
		move.l	a2,a1
		jsr	(resload_Patch,a3)

		moveq	#0,d0			;expmem
		jmp	(a2)


_pl1		PL_START
		PL_PS	$42,.intro
		PL_PS	$5a,.wait
		PL_P	$c0,_start_floppy
		PL_P	$394,_loadbygeo
		PL_P	$5ac,_decrunchpp20
		PL_END

; intro logo crashes if its interrupts keep running. the diskloader turns
; them off after loading the first file, but out loader is too quick ;)

.intro		btst	#7,$bfe001		; don't run intro if fire held down
		beq	.skip
		move.l	_skip_intro(pc),d0
		bne	.skip
		jmp	$3010a			; run the intro
.skip		move.w	#208,$30ae2		; set skip intro
	IFEQ 1	; not required because WHDLF_ClearMem
		lea	$383c8,a0		; clear the picture
		move.w	#$225f,d0
.clr		clr.l	(a0)+
		dbf	d0,.clr
	ENDC
		rts

.wait		cmp.w	#208,$30ae2		; wait for intro to end
		blt	.wait
		move.w	#$7fff,$dff09a		; disable ints
		addq.l	#2,(a7)
		rts

_start_floppy
		lea	$c0,a6
		move.l	_resload(pc),a2

		move.l	#$2000,d0
		move.l	a6,a0
		jsr	(resload_CRC16,a2)

		lea	_plm1(pc),a0
		cmp.w	#$3cae,d0
		beq	.patch
		lea	_plm2(pc),a0
		cmp.w	#$8004,d0
		beq	.patch
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)

.patch
		move.l	a6,a1
		jsr	(resload_Patch,a2)
		moveq	#0,d0			;expmem
		moveq	#-1,d1			;headpos
        
		jmp	(a6)


    
_plm		PL_START
		PL_PS	$5da,_title2

		PL_P	$922,_loadbygeo
		PL_P	$b20,_loadhighs
		PL_P	$b9e,_savehighs
		PL_P	$d0c,_decrunch		;self modifying code
		PL_DATA	$1f4d4,6
			move.b	($43,a5),d1	;TFMX Pro, Don Adan
			nop
		PL_END

_plm1		PL_START
        PL_IFC1X    0
        PL_W    $07502-$C0,$4a2c    ; infinite lives
        PL_ENDIF
        PL_IFC1X    1
        PL_W    $07476-$C0,$4a2c    ; infinite smart bombs
        PL_ENDIF
        PL_IFC1X    2
        PL_S    $02d32-$C0,$84-$6C    ; infinite super smart bombs
        PL_ENDIF
        PL_IFC1X    3
        PL_W    $0755c-$C0,$4a2c    ; infinite time
        PL_ENDIF
        
        PL_IFC2X    0
        PL_PSS  $032f2-$C0,read_joystick_button_jumps,2
        PL_ELSE
        PL_PSS  $032f2-$C0,read_joystick_up_jumps,2    
        PL_ENDIF

        PL_IFC2X    1
        PL_PSS  $0276c-$C0,super_smart_bomb_test,4
        PL_S    $0277a-$C0,$8C-$82  ; skip space test
        PL_ENDIF

        PL_PSS  $3316-$C0,read_fire,2
        PL_PSS  $3328-$C0,read_fire,2
        
        PL_PS   $05b1c-$C0,pause_test
        PL_PSS  $05b26-$C0,wait_play_release,2
        PL_PSS  $05b44-$C0,unpause,2

        PL_PS	$11f4,_title1
        PL_PS	$3284,_buttons
        PL_PS	$50f4,loadlev		;just as a world is loaded

        PL_PS   $69D8-$C0,vbl_hook
        PL_ORW    $141e-$C0,$20
    ;	PL_I	$1480			;smc
        PL_NEXT	_plm

_plm2		PL_START

        PL_IFC1X    0
        PL_W    $07506-$C0,$4a2c    ; infinite lives
        PL_ENDIF
        PL_IFC1X    1
        PL_W    $07474-$C0,$4a2c    ; infinite smart bombs
        PL_ENDIF
        PL_IFC1X    2
        PL_S    $02d3a-$C0,$84-$6C    ; infinite super smart bombs
        PL_ENDIF
        PL_IFC1X    3
        PL_W    $07560-$C0,$4a2c    ; infinite time
        PL_ENDIF
        
        PL_IFC2X    0
        PL_PSS  $032fa-$C0,read_joystick_button_jumps,2
        PL_ELSE
        PL_PSS  $032fa-$C0,read_joystick_up_jumps,2    
        PL_ENDIF
        PL_PSS  $0331e-$C0,read_fire,2
        PL_PSS  $03330-$C0,read_fire,2

        PL_PS   $05b20-$C0,pause_test
        PL_PSS  $05b2a-$C0,wait_play_release,2
        PL_PSS  $05b48-$C0,unpause,2
        
        PL_IFC2X    1
        PL_PSS  $02774-$C0,super_smart_bomb_test,4
        PL_S    $02782-$C0,$8C-$82  ; skip space test
        PL_ENDIF

        PL_PS   $69dc-$C0,vbl_hook
        PL_ORW    $01426-$C0,$20
   
	;	PL_I	$11ec
	;	PL_I	$11fc
		PL_PS	$11fc,_title1
		PL_PS	$328c,_buttons
		PL_PS	$50fc,loadlev		;just as a world is loaded
		PL_NEXT	_plm
        
        ELSE
start_cdtv
        ; load MAIN file to $C0
        lea	_main(pc),a0
        lea	$c0.w,a1
        jsr	(resload_LoadFileDecrunch,a3)

        lea	_pl_cdtv(pc),a0
        lea	$c0.w,a1
        jsr	(resload_Patch,a3)

            ;init clist
        move.l	#$c0+$6724,_custom+cop1lc	;init clist
        move.l	#-2,0				;lc1 sets lc2 to 0...
        tst.w	_custom+copjmp1

        bsr	_loadhighs

        ; load PICS file to filecache
        lea	_pics(pc),a0
        move.l	_expmem(pc),a1
        jsr	(resload_LoadFileDecrunch,a3)

        ; initialise the 'filecache' with the PICS file
        ; (contains files IP00 to IP07)
        move.l	_expmem(pc),a0
        move.l	a0,a1
.1
        move.l	(a1),d0		; get size of file (0 for end)
        beq.s	.done
        add.l	a0,d0
        move.l	d0,(a1)		; convert size into pointer to next entry
        movea.l	d0,a1		; go to next entry
        bra.s	.1
.done	move.l	a0,d0
        moveq	#0,d1
        jmp	$c0.w		; start game (d0=filecache / d1=0)

_loader	bsr	_kinit

        bclr.l	#31,d1		; clear it...
        move.l	d1,a1
        beq	.addrok		; if bit 31 is set ...
        move.l	(a1),a1		; ...and fetch an indirect address
.addrok
        lea	_filename(pc),a0    ; store filename
        move.l	d0,(a0)
        clr.w	(4,a0)
        move.l	_monitor(pc),d1
        cmp.l	#NTSC_MONITOR_ID,d1
        bne	.norm
        cmp.l	#"INTR",d0
        beq	.ntsc
        cmp.l	#"L3-1",d0
        bne	.norm
.ntsc	move.w	#"_N",(4,a0)
.norm

        move.l	_resload(pc),a2
        jsr	(resload_LoadFileDecrunch,a2)


        lea	_filename(pc),a0
        cmp.l	#"INTR",(a0)+
        bne	.end
        lea	$20700+$5a4e,a1		;INTR pal version
        tst.w	(a0)
        beq	.patch
        lea	$20700+$5a46,a1		;INTR_N ntsc version
.patch
    
        patch	0(a1),_keyin

.end	rts

_pl_cdtv		PL_START
    PL_IFC1X    0
    PL_W    $06e4a-$C0,$4a2c    ; infinite lives
    PL_ENDIF
    PL_IFC1X    1
    PL_W    $06dbe-$C0,$4a2c    ; infinite smart bombs
    PL_ENDIF
    PL_IFC1X    2
    PL_S    $0266c-$C0,$84-$6C    ; infinite super smart bombs
    PL_ENDIF
    PL_IFC1X    3
    PL_W    $06ea4-$C0,$4a2c    ; infinite time
    PL_ENDIF
    
    PL_IFC2X    0
    PL_PSS  $02c2c-$C0,read_joystick_button_jumps,2
    PL_ELSE
    PL_PSS  $02c2c-$C0,read_joystick_up_jumps,2    
    PL_ENDIF

    PL_IFC2X    1
    PL_PSS  $020a6-$C0,super_smart_bomb_test,4
    PL_S    $020b4-$C0,$8C-$82  ; skip space test
    PL_ENDIF


    PL_PSS  $02c50-$C0,read_fire,2
    PL_PSS  $02c62-$C0,read_fire,2

    PL_PS   $05444-$C0,pause_test
    PL_PSS  $0544e-$C0,wait_play_release,2
    PL_PSS  $0546c-$C0,unpause,2

	; this is fun. the CDTV version has all hiscore load/save as just
	; 'rts'. i patch this rts to do 'load', and the save vector that
	; calls this rts to do 'save'.
    ;PL_S	 $b44,$680-$b44
    ;PL_P	 $680,_loadhighs
    
    PL_S	$32e,$690-$32e
    PL_P	$690,_savehighs

    PL_P	$5f4,_loader
    PL_P	$670,_decrunch		; self modifying code
    PL_PS	$2bbe,_buttons
    PL_PS	$4a2e,loadlev		;just as a world is loaded
    PL_S	$4bbc,2			;fix 'game over' after 'time out'
	IFD SETTIME
		PL_PS	$4c38,.settime
		PL_PS	$5152,.settime
	ENDC
    
    PL_PS   $0065a-$C0,intro_load

    PL_PS   $06300-$C0,vbl_hook
    ;PL_ORW    $141e-$C0,$20

    PL_END
    ENDC
    
vbl_hook
	MOVE.W	_custom+intreqr,D0
    btst    #5,d0
    beq.b   .novbl
    bsr     _joystick
.novbl
    rts
    
intro_load
    movem.l a0,-(a7)
    lea _filename(pc),a0
    move.l  d0,(a0)
    movem.l (a7)+,a0
	MOVEQ	#1,D2			;: 7401
	JSR	$692.W
    movem.l d0-d1/a0-a2,-(a7)
    move.l _filename(pc),d0

    cmp.l   #'MUS0',d0
    bne.b   .nomusic
    lea $20700,a1
    lea _pl_tfmx(pc),a0
    move.l  (_resload,pc),a2
    jsr resload_Patch(a2)
.nomusic
    movem.l (a7)+,d0-d1/a0-a2
    rts
    
RAWKEY = $249
OTHERFLAG = $DA

super_smart_bomb_test
    movem.l d1,-(a7)
    move.l  joy1(pc),d1
    btst    #JPB_BTN_YEL,d1
    movem.l (a7)+,d1
    rts

pause_test:
    CMPI.B	#$19,RAWKEY
    beq.b   .paused
    movem.l d1,-(a7)
    move.l  joy1(pc),d1
    not.l   d1
    btst    #JPB_BTN_PLAY,d1
    movem.l (a7)+,d1
    
.paused
    rts

wait_play_release:
.wait
    movem.l d1,-(a7)
    move.l  joy1(pc),d1
    btst    #JPB_BTN_PLAY,d1
    movem.l (a7)+,d1
    bne.b   .wait
	CLR.B	RAWKEY.W		;05b26: 42380249
	CLR.B	OTHERFLAG.W		;05b2a: 423800da
    rts

    
unpause:
     ; read once more until play is released
    
	MOVE.B	RAWKEY,D0		;0546c: 10380249

    movem.l    d1,-(A7)
    move.l  joy1(pc),d1
    btst    #JPB_BTN_PLAY,d1
    beq.b   .wait
    move.b  #$19,d0     ; simulate P pressed
.wait
    move.l  joy1(pc),d1
    btst    #JPB_BTN_PLAY,d1
    bne.b   .wait
    movem.l (a7)+,d1

	OR.B	OTHERFLAG.W,D0		;05470: 803800da
    RTS
    
; D1 is set with joy settings 
meta_controls
    ;bsr _joystick
    move.l  joy1(pc),d1
    btst    #JPB_BTN_REVERSE,d1
    beq.b   .noquit
    btst    #JPB_BTN_FORWARD,d1
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d1
    bne     _exit
    move.b  #$45,RAWKEY
.noquit

    rts

read_joystick_up_jumps:
    movem.l D1,-(a7)
    bsr meta_controls
    movem.l (a7)+,D1
    CLR.W	joytest(A6)			;032f2: 426e0036
	MOVE.W	joy1dat(A6),D0		;032f6: 302e000c
    RTS
    
read_joystick_button_jumps:
    CLR.W	joytest(A6)			;032f2: 426e0036
	MOVE.W	joy1dat(A6),D0		;032f6: 302e000c
    movem.l D1,-(a7)
    bsr meta_controls
    
    tst.l   $F2.W
    bne.b   .no_blue        ; in water: don't use second button
    cmp.b   #2,$5CDF.W      ; ship level: don't use second button
	beq.b	.no_blue
    

	;move.l	_GameAddress(pc),a0
	;cmp.b	#7,$4813(a0)		; project-F ? don't do anything
    ;;cmp.b   #1,$5CD6    ; in water: don't do anything
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:    
    movem.l (a7)+,D1
    RTS

read_fire
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts    
 
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


_title1	lea	$20700,a0
    ; just before title starts
    movem.l d0-d1/a0-a2,-(a7)
    move.l  a0,a1
    lea _pl_title1(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
	jmp	(a0)

_pl_title1
    PL_START
	PL_P	$5864,_keyin		; patch 'get key' of the music menu

    PL_NEXT _pl_tfmx
    
_pl_tfmx:
    PL_START
	PL_P	$2111e,_snd
    ; this doesn't fix the wrong replay (winuae worst settings) but seems
    ; to make it slightly better
    PL_PSS  $3F5EC-$20700,_dma_wait_1,2
    PL_PSS  $3F674-$20700,_dma_wait_2,2
    PL_PSS  $3FCE6-$20700,_dma_wait_3,2
    PL_PS  $3F5B0-$20700,_dma_wait_4
    PL_END
    
_dma_wait_4
    MOVE.W D0,$00dff096
    bra soundtracker_loop
_dma_wait_3:
    MOVE.W ($0016,A6),$00dff096
    bra soundtracker_loop
_dma_wait_2:
    MOVE.W ($003a,A6),$00dff096
    bra soundtracker_loop
_dma_wait_1:
    MOVE.W ($0054,A6),$00dff096
soundtracker_loop
	move.w  d0,-(a7)
	move.w	#8,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts
    
_snd	move.w	#$400,$dff09c
	tst.w	$dff002
	rte

_title2	cmp.l	#"MUS0",d0
	bne	.go
	patch	$20700+$5864,_keyin		; patch 'get key' of the music menu
.go	
    move.l	$2070c,d1   ; original
	rts

_keyin	lea	start_level_by_key(pc),a0
	lea	state(pc),a1
	tst.w	(a1)
	bpl	.key
	clr.w	(a1)		; reset status for next run of music menu
	bra	.neg

.key	move.b	$249.w,d0
	beq.s	.key
	clr.b	$249.w
	cmp.b	#$45,d0		; escape pressed? return -1
	beq	.esc
	cmp.b	#$42,d0
	beq	.tab
	cmp.b	#1,d0
	blo	.key
	cmp.b	#6,d0
	bhi	.key
	ext.w	d0
	tst.w	(a1)		; do nothing if in music select
	bne	.ret
	move.w	d0,d1
	subq.w	#2,d1
	move.w	d1,(a0)
	addq.w	#1,(a1)		; set music select
.ret    rts

.esc	clr.w	(a0)		; no level skip
	clr.w	(a1)		; world select
.neg	moveq	#-1,d0
	rts

.tab	tst.w	(a1)
	beq	.key		; ignore if in world select
	tst.w	(a0)
	bmi	.key		; ignore intro music (level -1)
	moveq	#-1,d0
	move.w	d0,(a1)
	rts

loadlev
    move.w  start_level_by_key(pc),d0
    bne.b   .once
    move.w	_start_level+2(pc),d0
    cmp.w   #6,d0
    bcs.b   .go
    clr.w   d0  ; safety else it crashes
    bra.b   .go
.once
    lea	start_level_by_key(pc),a0
	move.w	(a0),d0
	clr.w	(a0)		;reset
.go
	move.l	(a7)+,a0
	move.w	(a0)+,a1
	clr.w	(a1)		;sub level
	move.w	d0,-(a1)	;world
	jmp	(a0)

		
	;d0 = size in bytes
	;d1 = start track
	;d2 = offset track in bytes
	;a0 = address
_loadbygeo	bsr	_kinit

		move.l	d2,-(a7)
		subq.w	#2,d1			;image starts at track 2
		mulu	#6800,d1
		add.l	d2,d1		;offset
		exg.l	d0,d1
		moveq	#1,d2		;disk
		move.l	a3,-(a7)
		move.l	(_resload,pc),a3
		jsr	(resload_DiskLoad,a3)
		move.l	(a7)+,a3
		move.l	(a7)+,d2
		moveq	#0,d0
        
  
		rts

_kinit		movem.l	a0-a1,-(a7)
		lea	(_keyboard,pc),a1
		cmp.l	$68,a1
		beq	.q
	;allow interrupts from the keyboard
		move.b	#CIAICRF_SETCLR|CIAICRF_SP,(ciaicr+_ciaa)
	;clear all ciaa-interrupts
		tst.b	(ciaicr+_ciaa)
	;set input mode
		and.b	#~(CIACRAF_SPMODE),(ciacra+_ciaa)
	;clear ports interrupt
		move.w	#INTF_PORTS,(intreq+_custom)
	;allow ports interrupt
		move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,(intena+_custom)
		lea	(_realint68,pc),a0
		move.l	$68,(a0)
		move.l	a1,$68
.q		movem.l	(a7)+,a0-a1
		rts

_keyboard	move.l	d0,-(a7)
		move.b	$bfec01,d0
		ror.b	#1,d0
		not.b	d0

		cmp.b	(_keydebug,pc),d0
		bne	.1
		move.l	(a7)+,d0
		move.w	(a7),(6,a7)		;sr
		move.l	(2,a7),(a7)		;pc
		clr.w	(4,a7)			;ext.l sr
		bra	_debug			;coredump & quit
.1
		cmp.b	(_keyexit,pc),d0
		beq	_exit			;exit

		move.l	(a7)+,d0
		move.l	(_realint68,pc),-(a7)	;enter orginal rou.
		rts
_exit		pea	TDREASON_OK.w
		bra	_end
_debug		pea	TDREASON_DEBUG.w
_end		move.l	(_resload,pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
;--------------------------------

_loadhighs	movem.l	d0-d1/a0-a2,-(a7)
		move.l	(_resload,pc),a2
		lea	_highsname(pc),a0
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		beq	.end
		bsr	_crypt
		lea	_highsname(pc),a0
		lea	$25e,a1
		jsr	(resload_LoadFile,a2)
		bsr	_crypt
.end		movem.l	(a7)+,d0-d1/a0-a2
		rts

_savehighs	movem.l	d0-d1/a0-a1,-(a7)
    move.l  _cheat(pc),d0
    bne.b   .skip
    bsr	_crypt
    move.l	#$61*4,d0
    lea	_highsname(pc),a0
    lea	$25e,a1
    move.l	(_resload,pc),a2
    jsr	(resload_SaveFile,a2)
    bsr	_crypt
.skip
    movem.l	(a7)+,d0-d1/a0-a1
    rts

_crypt		lea	$25e,a0
		move.w	#$61*4-1,d0
.lp		eor.b	d0,(a0)+
		dbf	d0,.lp
		rts
	


;======================================================================

lbC000596	addq.w	#8,d3
	moveq	#7,d1
lbC00059A	dbra	d3,lbC0005A2
	move.l	-(a1),d2
	moveq	#$1F,d3
lbC0005A2	lsr.l	#1,d2
	roxl.w	#1,d0
	dbra	d1,lbC00059A
	bra.b	lbC00061A

_decrunchpp20	 cmpi.l	 #$50503230,(a0)
	addq.l	#4,a0
	subq.b	#1,(a0)
	subq.b	#1,(1,a0)
	subq.b	#1,(2,a0)
	subq.b	#1,(3,a0)
	movea.l	a2,a4
	move.l	-(a1),d0
	moveq	#0,d1
	move.b	d0,d1
	lsr.l	#8,d0
	adda.l	d0,a4
	move.l	-(a1),d2
	moveq	#$20,d3
	tst.w	d1
	beq.b	lbC0005DC
	subq.w	#1,d1
	bsr.w	lbC00066A
lbC0005DC	dbra	d3,lbC0005E4
	move.l	-(a1),d2
	moveq	#$1F,d3
lbC0005E4	lsr.l	#1,d2
	bcs.b	lbC000624
	moveq	#0,d4
lbC0005EA	moveq	#1,d1
	bsr.w	lbC00066A
	add.w	d0,d4
	subq.w	#3,d0
	beq.b	lbC0005EA
lbC0005F6	subq.w	#8,d3
	bmi.b	lbC000596
	lsr.l	#1,d2
	roxl.w	#1,d0
	lsr.l	#1,d2
	roxl.w	#1,d0
	lsr.l	#1,d2
	roxl.w	#1,d0
	lsr.l	#1,d2
	roxl.w	#1,d0
	lsr.l	#1,d2
	roxl.w	#1,d0
	lsr.l	#1,d2
	roxl.w	#1,d0
	lsr.l	#1,d2
	roxl.w	#1,d0
	lsr.l	#1,d2
	roxl.w	#1,d0
lbC00061A	move.b	d0,-(a4)
	dbra	d4,lbC0005F6
	cmpa.l	a4,a2
	bcc.b	lbC000668
lbC000624	moveq	#1,d1
	bsr.b	lbC00066A
	moveq	#0,d1
	move.b	(a0,d0.w),d1
	move.w	d0,d4
	addq.w	#1,d4
	subq.w	#3,d0
	bmi.b	lbC000656
	dbra	d3,lbC00063E
	move.l	-(a1),d2
	moveq	#$1F,d3
lbC00063E	lsr.l	#1,d2
	bcs.b	lbC000644
	moveq	#6,d1
lbC000644	bsr.b	lbC00066A
	lea	(1,a4,d0.w),a3
lbC00064A	moveq	#2,d1
	bsr.b	lbC00066A
	add.w	d0,d4
	subq.w	#7,d0
	beq.b	lbC00064A
	bra.b	lbC00065C

lbC000656	bsr.b	lbC00066A
	lea	(1,a4,d0.w),a3
lbC00065C	move.b	-(a3),-(a4)
	dbra	d4,lbC00065C
	cmpa.l	a4,a2
	bcs.w	lbC0005DC
lbC000668	rts

lbC00066A	moveq	#0,d0
lbC00066C	dbra	d3,lbC000674
	move.l	-(a1),d2
	moveq	#$1F,d3
lbC000674	lsr.l	#1,d2
	roxl.w	#1,d0
	dbra	d1,lbC00066C
	rts

;======================================================================
; a0=source a1=dest a2=temp($400)

_decrunch

	MOVE.L	(A0)+,-(SP)	;unpacked length
	MOVE.L	(A0)+,-(SP)
	MOVE.W	#$400,D0
	MOVEA.L	A1,A3
	ADDA.L	(4,SP),A3
lbC00000E	MOVE.B	(A3)+,(A2)+
	SUBQ.W	#1,D0
	BNE.B	lbC00000E

	MOVEM.L	A2/A3,-(SP)
	MOVE.L	A1,-(SP)
	MOVE.L	A2,-(SP)
	BSR.B	lbC000060
	MOVEA.L	(SP)+,A3
	MOVEA.L	A1,A0
	MOVEA.L	(8,SP),A2
	MOVEA.L	A2,A1
	SUBA.L	(12,SP),A1
	BSR.W	lbC00017C
	MOVEA.L	A2,A0
	MOVEA.L	A5,A3
	MOVEA.L	(SP)+,A1
	MOVEA.L	A1,A2
	ADDA.L	(12,SP),A2
	MOVEM.L	A1/A2,(8,SP)
	BSR.W	lbC0003EA
	MOVEM.L	(SP)+,A2/A3
	MOVE.W	#$400,D0
lbC00004E	MOVE.B	-(A2),-(A3)
	SUBQ.W	#1,D0
	BNE.B	lbC00004E
	MOVEM.L	(SP)+,A0/A1
	LEA	($DFF000).L,A6
	RTS

lbC000060
	LEA	(_fuck1,PC),A3
	MOVE.W	#$FF,(A3)+
	MOVEQ	#-2,D0
	MOVE.W	D0,(A3)+
	MOVE.W	D0,(A3)+
	MOVE.W	D0,(A3)+
	MOVE.L	(A0)+,D3
	SUBQ.L	#1,D3
	MOVE.L	D3,D5
	SWAP	D5
	MOVE.W	(A0)+,D4
	MOVEQ	#0,D6
	MOVE.B	(A0)+,D6
	MOVEM.L	D3-D6,-(SP)
	MOVEQ	#2,D5
	MOVE.L	#$100,D6
	MOVEQ	#0,D7
	MOVEQ	#0,D0
	MOVE.B	(A0)+,D0
	MOVEA.L	A2,A6
	MOVE.L	D0,D1
	ADD.L	D1,D1
	LEA	(_fuck1,PC),A5
lbC0000A6	MOVEQ	#0,D2
	MOVEQ	#0,D4
	MOVE.B	(A0)+,D2
	MOVE.B	(A0)+,D4
	ADD.W	D4,(A5)
	ADD.W	D4,(A5)
	ADD.W	D2,D4
	MOVE.W	D2,(A6)
	ADDA.L	D1,A6
	MOVE.W	D4,(A6)
	ADDA.L	D1,A6
	MOVE.W	D6,(A6)
	ADD.W	D2,D2
	SUB.W	D2,(A6)
	LSR.W	#1,D2
	ADDA.L	D1,A6
	MOVE.W	D7,(A6)
	SUB.W	D4,(A6)
	SUBA.L	D1,A6
	SUBA.L	D1,A6
	SUBA.L	D1,A6
	ADDQ.L	#2,A6
	MOVE.L	D5,D3
	SUB.L	D4,D3
	ADD.L	D3,D7
	SUB.L	D2,D4
	ADD.L	D4,D6
	ADD.L	D4,D6
	MOVE.L	D2,D5
	ADD.L	D5,D5
	SUBQ.W	#1,D0
	BNE.B	lbC0000A6
	addq.l	#2,a5
	ADD.W	D1,(A5)+
	ADD.W	D1,(A5)
	ADD.W	D1,(A5)
	ADD.W	D1,(A5)+
	ADD.W	D1,(A5)
	ADD.W	D1,(A5)
	LSL.L	#2,D1
	LEA	(A2,D1.L),A6
	MOVEA.L	A6,A5
	MOVE.W	(_fuck1,pc),D0
lbC00010A
	MOVE.B	(A0)+,(A5)+
	DBRA	D0,lbC00010A
	MOVEM.L	(SP)+,D3-D6
	lea	(-2,a2,d6.l),a5
	ADDA.L	D6,A5
	MOVEQ	#0,D1
lbC00011E
	CMP.W	D6,D1
	BCS.B	lbC00012E
	SUB.W	D6,D1
	ROL.W	D6,D0
	MOVE.W	D0,D2
	AND.W	D4,D2
	MOVEA.L	A5,A3
	BRA.B	lbC00013E

lbC00012E
	MOVEQ	#0,D2
	MOVEA.L	A2,A3
	DBRA	D1,lbC00013A
	MOVE.W	(A0)+,D0
	MOVEQ	#15,D1
lbC00013A
	ADD.W	D0,D0
	ADDX.W	D2,D2
lbC00013E
	CMP.W	(A3)+,D2
	DBCC	D1,lbC00013A
	BCC.B	lbC00014C
	MOVE.W	(A0)+,D0
	MOVEQ	#15,D1
	BRA.B	lbC00013A

lbC00014C
	adda.w	(_fuck2,pc),a3
	CMP.W	(A3),D2
	suba.w	(_fuck2,pc),a3
	BCS.B	lbC000164
	adda.w	(_fuck3,pc),a3
	add.W	(A3),D2
	suba.w	(_fuck3,pc),a3
	MOVE.B	(A6,D2.W),(A1)+
	DBRA	D3,lbC00011E
	DBRA	D5,lbC00011E
	RTS

lbC000164
	ADD.W	D2,D2
	adda.w	(_fuck4,pc),a3
	add.W	(A3),D2
	suba.w	(_fuck4,pc),a3
	MOVE.B	(A6,D2.W),(A1)+
	MOVE.B	(1,A6,D2.W),(A1)+
	SUBQ.W	#2,D3
	BCC.B	lbC00011E
	DBRA	D5,lbC00011E
	RTS

lbC00017C	MOVEA.L	A3,A5
	MOVEA.L	A5,A6
	MOVE.W	#$FF,D7
lbC000184	CLR.W	(A6)+
	DBRA	D7,lbC000184
	LEA	(lbL0003D4,PC),A6
	LEA	(-$6C).W,A3
	MOVEQ	#9,D7
lbC000194	MOVEQ	#0,D6
	MOVE.B	-(A0),D6
	ADD.W	D6,D6
	MOVE.W	(A6)+,D5
	ADD.W	A3,D5
	MOVE.W	D5,(A5,D6.W)
	DBRA	D7,lbC000194
	LEA	($10E).W,A3
	MOVEQ	#15,D7
lbC0001AC	MOVEQ	#0,D6
	MOVE.B	-(A0),D6
	ADD.W	D6,D6
	MOVE.W	A3,(A5,D6.W)
	ADDQ.W	#6,A3
	DBRA	D7,lbC0001AC
	MOVEQ	#0,D6
	MOVE.B	-(A0),D6
	ADD.W	D6,D6
	LEA	($196).W,A3
	MOVE.W	A3,(A5,D6.W)
	LEA	(lbC0001FE,PC),A4
	LEA	(lbC0001D2,PC),A3
lbC0001D2	CMPA.L	A1,A2
	BLS.W	lbC0003E8
	MOVE.B	-(A0),D0
	MOVEQ	#0,D7
	MOVE.B	D0,D7
	ADD.W	D7,D7
	MOVE.W	(A5,D7.W),D7
	JMP	(lbC0001E8,PC,D7.W)

lbC0001E8	MOVE.B	D0,-(A2)
	JMP	(A3)

	MOVEQ	#0,D1
	MOVE.B	-(A0),D1
	BEQ.B	lbC0001E8
	LEA	(A2,D1.W),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC0001FE	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	JMP	(A3)

	MOVE.B	-(A0),D1
	MOVE.B	D1,D2
	AND.W	#$FC,D1
	BEQ.B	lbC0001E8
	LSR.W	#2,D1
	AND.W	#3,D2
	LEA	(A2,D1.W),A6
	ADD.W	D2,D2
	NEG.W	D2
	JMP	(A4,D2.W)

	MOVEQ	#0,D2
	MOVE.B	-(A0),D2
	BEQ.B	lbC0001E8
	MOVE.W	D2,D1
	LSR.W	#2,D2
	LSL.W	#8,D1
	MOVE.B	-(A0),D1
	AND.W	#$3FF,D1
	LEA	(1,A2,D1.W),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC00023C	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC00023C
	JMP	(A3)

	MOVEQ	#0,D1
	MOVE.B	-(A0),D1
	BEQ.B	lbC0001E8
	LSL.W	#8,D1
	MOVE.B	-(A0),D1
	CMP.W	#$C000,D1
	BCC.B	lbC000262
	LEA	(A2,D1.L),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	JMP	(A3)

lbC000262	MOVE.W	#$401,D3
lbC000266	AND.W	#$3FFF,D1
	MOVE.B	D1,D2
	AND.W	#7,D2
	LSR.W	#3,D1
	ADD.W	D3,D1
	LEA	(A2,D1.W),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC00027E
	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC00027E
	JMP	(A3)

	MOVEQ	#0,D1
	MOVE.B	-(A0),D1
	BEQ.W	lbC0001E8
	LSL.W	#8,D1
	MOVE.B	-(A0),D1
	MOVE.W	#$2C01,D3
	CMP.W	#$C000,D1
	BCC.B	lbC000266
	MOVEQ	#0,D2
	MOVE.B	-(A0),D2
	SUBQ.W	#1,D2
	SUB.W	#$100,D1
	LEA	(A2,D1.L),A6
lbC0002AA	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC0002AA
	JMP	(A3)

	MOVE.W	#$C01,D3
	BRA.B	lbC0002CE

	MOVE.W	#$9401,D3
	BRA.B	lbC0002CE

	MOVE.W	#$7401,D3
	BRA.B	lbC0002CE

	MOVE.W	#$5401,D3
	BRA.B	lbC0002CE

	MOVE.W	#$3401,D3
lbC0002CE	MOVEQ	#0,D2
	MOVE.B	-(A0),D2
	BEQ.W	lbC0001E8
	MOVE.L	D2,D1
	LSR.W	#5,D2
	LSL.W	#8,D1
	MOVE.B	-(A0),D1
	AND.W	#$1FFF,D1
	ADD.W	D3,D1
	LEA	(A2,D1.L),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC0002EE	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC0002EE
	JMP	(A3)

	MOVE.W	#$3F,D3
	BRA.B	lbC00035A

	MOVE.W	#$7E,D3
	BRA.B	lbC00035A

	MOVE.W	#$BD,D3
	BRA.B	lbC00035A

	MOVE.W	#$FC,D3
	BRA.B	lbC00035A

	MOVE.W	#$13B,D3
	BRA.B	lbC00035A

	MOVE.W	#$17A,D3
	BRA.B	lbC00035A

	MOVE.W	#$1B9,D3
	BRA.B	lbC00035A

	MOVE.W	#$1F8,D3
	BRA.B	lbC00035A

	MOVE.W	#$237,D3
	BRA.B	lbC00035A

	MOVE.W	#$276,D3
	BRA.B	lbC00035A

	MOVE.W	#$2B5,D3
	BRA.B	lbC00035A

	MOVE.W	#$2F4,D3
	BRA.B	lbC00035A

	MOVE.W	#$333,D3
	BRA.B	lbC00035A

	MOVE.W	#$372,D3
	BRA.B	lbC00035A

	MOVE.W	#$3B1,D3
	BRA.B	lbC00035A

	MOVE.W	#$3F0,D3
	BRA.B	lbC00035A

	MOVE.W	#$42F,D3
lbC00035A	MOVE.B	-(A0),D1
	MOVE.B	D1,D2
	AND.W	#$FC,D1
	BEQ.W	lbC0001E8
	LSR.W	#2,D1
	AND.W	#3,D2
	ADD.W	D3,D1
	LEA	(A2,D1.W),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC000376	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC000376
	JMP	(A3)

	MOVE.B	-(A0),D1
	BEQ.W	lbC0001E8
	MOVE.B	D1,D2
	AND.W	#$3F,D1
	ROL.B	#2,D2
	AND.W	#3,D2
	ADD.W	D2,D2
	LEA	(lbL0003CC,PC),A6
	MOVE.W	(A6,D2.W),D3
	EXT.L	D3
	MOVE.B	-(A0),D4
	ROR.L	#8,D4
	MOVE.B	-(A0),D4
	ROR.L	#8,D4
	MOVE.B	-(A0),D4
	ROR.L	#8,D4
	MOVE.B	-(A0),D4
	ROR.L	#8,D4
lbC0003AC	MOVE.B	D4,-(A2)
	ROR.L	#8,D4
	MOVE.B	D4,-(A2)
	ROR.L	#8,D4
	MOVE.B	D4,-(A2)
	ROR.L	#8,D4
	MOVE.B	D4,-(A2)
	ROR.L	#8,D4
	MOVEQ	#0,D5
	MOVE.B	-(A0),D5
	ADD.L	D3,D5
	SUB.L	D5,D4
	DBRA	D1,lbC0003AC
	ADDQ.L	#1,A0
	JMP	(A3)

lbL0003CC
	dc.l	$FF800000
	dc.l	$1000200
lbL0003D4
	dc.l	$70008A
	dc.l	$A600C8
	dc.l	$136010A
	dc.l	$14E0148
	dc.l	$142013C

lbC0003E8	RTS

lbC0003EA	MOVEA.L	A3,A6
	MOVEQ	#0,D0
lbC0003EE	CLR.B	(A3)+
	SUBQ.B	#1,D0
	BNE.B	lbC0003EE
	MOVE.B	(A0)+,D0
	MOVE.B	#4,(A6,D0.W)
	MOVE.B	(A0)+,D0
	MOVE.B	#14,(A6,D0.W)
	MOVE.B	(A0)+,D0
	MOVE.B	#$1A,(A6,D0.W)
	MOVEQ	#0,D7
lbC00040E	CMPA.L	A2,A1
	BCC.B	lbC0003E8
	MOVE.B	(A0)+,D0
	MOVE.B	(A6,D0.W),D7
	JMP	(lbC00041C,PC,D7.W)

lbC00041C	MOVE.B	D0,(A1)+
	BRA.B	lbC00040E

	MOVEQ	#0,D2
	MOVE.B	(A0)+,D2
	BEQ.B	lbC00041C
	MOVEQ	#0,D1
	BRA.B	lbC00043E

	MOVE.B	(A0)+,D1
	BEQ.B	lbC00041C
	MOVE.B	D1,(A1)+
	MOVE.B	D1,(A1)+
	MOVE.B	D1,(A1)+
	BRA.B	lbC00040E

	MOVE.B	(A0)+,D1
	BEQ.B	lbC00041C
	MOVEQ	#0,D2
	MOVE.B	(A0)+,D2
lbC00043E	SUBQ.B	#3,D2
	BCS.B	lbC00044E
	MOVE.B	D1,(A1)+
	MOVE.B	D1,(A1)+
lbC000446	MOVE.B	D1,(A1)+
	DBRA	D2,lbC000446
	BRA.B	lbC00040E

lbC00044E	ADDQ.B	#1,D2
	BNE.B	lbC00045A
	MOVE.B	(A0)+,D2
	LSL.W	#8,D2
	MOVE.B	(A0)+,D2
	LSL.L	#8,D2
lbC00045A	MOVE.B	(A0)+,D2
	LSL.L	#8,D2
	MOVE.B	(A0)+,D2
	SUBQ.L	#1,D2
	MOVE.L	D2,D3
	SWAP	D3
lbC000466	MOVE.B	D1,(A1)+
	DBRA	D2,lbC000466
	DBRA	D3,lbC000466
	BRA.B	lbC00040E

	CNOP	0,4
_fuck1	dc.w	0
_fuck2	dc.w	0
_fuck3	dc.w	0
_fuck4	dc.w	0

;======================================================================

smart_bomb_bit:
    dc.l    JPB_BTN_BLU

start_level_by_key	dc.w	0	; should we load a different world? (0=no, 1-5=yes)
state		dc.w	0	; 0=world-select 1=music-select -1=level-jump
_tags		dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_cheat	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_skip_intro		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_button_jumps		dc.l	0
		dc.l	WHDLTAG_CUSTOM4_GET
_start_level
		dc.l	WHDLTAG_DBGADR_SET
		dc.l	$c0
		dc.l	0
_resload	dc.l	0		;address of resident loader
_realint68	dc.l	0
_filename	ds.b	7

;======================================================================

	END

