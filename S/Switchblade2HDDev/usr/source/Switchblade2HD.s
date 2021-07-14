;*---------------------------------------------------------------------------
;  :Program.	SB2.Asm
;  :Contents.	Slave for "Switchblade 2" from Gremlin Interactive
;  :Author.	Galahad of Fairlight, StingRay
;  :History.	11.12.00 - Initial slave
;  :            30.03.01 - Delay for intro added and exit from intro quicker
;  :            30.03.01 - Changed Quit key to 'Del'
;  :            30.03.01 - Decruncher relocated to Fast Ram
;  :StingRay    31.10.18 - patch more or less redone, blitter waits added,
;  :                       highscore saving fixed (didn't work at all!),
;  :                       memory requirements reduced to 512KB, intro patch
;  :                       redone, all disk accesses removed, FUNGUS
;  :                       decruncher code added in the source, it is not
;  :                       copied anymore from the game, high score file
;  :                       renamed to "Switchblade2.high", cartridge checks
;  :                       disabled; trainers added, quitkey changed to F10
;  :            01.11.18 - more trainer options added, high score saving
;  :                       disabled if trainers are used, pictures in intro
;  :                       are shown for 5 seconds now, 68000 quitkey support
;  :                       in intro added, in-game keys diasabled when
;  :                       entering name in high score screen, all old
;  :                       1.0-1.2 code removed, "Chrome" cheat disabled,
;  :                       help screen implemented (needs 4k extra memory)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One V1.16d
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
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

;======================================================================

HEADER
base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	FLAGS		;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	.dir-base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
		dc.b	0		;ws_keydebug
		dc.b	QUITKEY		;ws_keyexit
		dc.l	4096		;ws_ExpMem
		dc.w	.name-base	;ws_name
		dc.w	.copy-base	;ws_copy
		dc.w	.info-base	;ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Ammo:2;"
	dc.b	"C1:X:Unlimited Money:3;"
	dc.b	"C1:X:Invincibility:4;"
	dc.b	"C1:X:Start with Max. Money:5;"
	dc.b	"C1:X:In-Game Keys (Press HELP during game):6;"
	dc.b	"C2:B:Second button jumps;"
	dc.b	"C3:L:Start at Level:1,2,3,4,5,6,7;"
    dc.b    "C4:B:disable blitter waits (slow machines)"
	dc.b	0

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
	
.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Switchblade2/"
	ENDC
	dc.b	'data',0

.name	dc.b	'--< S W i T C H B L A D E  I I >--',0
.copy	dc.b	'1991 Gremlin Graphics',0
.info	dc.b	'Installed and fixed by',10
	dc.b	'Galahad of Fairlight, Harry,',10
	dc.b	"StingRay/[S]carab^Scoopex and JOTD",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	'Version '
	DECL_VERSION	
	dc.b	0

Introfile:
	dc.b	'INTRO.BIN',0
Bootfile:
	dc.b	'BOOT.BIN',0
Hiscore:
	dc.b	"Switchblade2.high",0
	
	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	10,0
	EVEN

IGNORE_RAW_JOYDAT
	include	ReadJoyPad.s
	
TAGLIST	dc.l	WHDLTAG_CUSTOM3_GET
LEVEL	dc.l	0
	dc.l	TAG_DONE

resload	dc.l	0			; address of resident loader

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	resload(pc),a1
		move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	bsr	_detect_controller_types
	lea third_button_maps_to(pc),a0
    move.l  #JPF_BTN_YEL,(a0)
    
; stingray, V1.3

; load boot
	lea	Bootfile(pc),a0
	lea	$70000,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)

; version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$09b8,d0		; SPS 1725
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)


	lea	$dff000,a6
	jmp	(a5)	


PLBOOT	PL_START
	PL_P	$358,DECRUNCH_FUNGUS
	PL_ORW	$474+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$54c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5d8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$6ac+2,1<<9		; set Bplcon0 color bit
	PL_R	$7dc			; disable loader init
	PL_R	$83e			; disable drive access (motor on)
	PL_R	$86a			; disable drive access (motor off)
	PL_P	$2a0,AckVBI
	PL_PS	$cd0,.CheckQuit

	;PL_PS	$142,.PatchReplay	; not needed
	PL_P	$762,.load
	PL_P	$26c,.PatchGame

	PL_PS	$18e,.wait1		; gremlin logo
	PL_PS	$1ec,.wait2		; title picture
	PL_PS	$250,.wait3		; hiro picture
	PL_END

.wait1	bsr.b	.wait
	lea	$70000+$4d2,a0		; original code
	rts

.wait2	bsr.b	.wait
	lea	$70000+$59e,a0		; original code
	rts

.wait3	bsr.b	.wait
	lea	$70000+$632,a0		; original code
	rts


.wait	moveq	#5*10,d0		; show picture for 5 seconds
	move.l	resload(pc),a0
	jmp	resload_Delay(a0)


.CheckQuit
	move.b	d0,$70000
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts

	
.PatchGame
; set starting level
	move.l	LEVEL(pc),d0
	beq.b	.normal
	addq.w	#1,d0
	cmp.w	#7,d0
	bcs.b	.ok
	moveq	#6,d0
.ok	move.w	d0,$400+$e91a+2

.normal

	lea	PLGAME(pc),a0
	lea	$400.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$402.w


; d0.w: track
; d1.w: # of tracks-1
; a0.l: destination

.load	movem.l	d0-a6,-(a7)
	lea	Introfile(pc),a1
	addq.w	#1,d1
	mulu.w	#$1800,d1		; size
	sub.w	#113,d0
	mulu.w	#$1800,d0		; offset
	exg	d0,d1
	exg	a0,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFileOffset(a2)
	movem.l	(a7)+,d0-a6
	rts

AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

PLGAME	PL_START
	PL_R	$1f4da			; disable loader init
	PL_R	$1f53c			; disable drive access (motor on)
	PL_R	$1f568			; disable drive access (motor off)
	PL_P	$1fc52,.load	
	PL_P	$18cb0,DECRUNCH_FUNGUS
	PL_PS	$e9ea,.LoadHighscores
	PL_IFC1
	PL_ELSE
	PL_PSS	$f82c,.SaveHighscores,2
	PL_ENDIF
	PL_SA	$eb5e,$eb76		; skip cartridge check
	PL_SA	$f466,$f47e		; skip cartridge check
	PL_SA	$1c826,$1c83e		; skip cartridge check
	
	PL_PS	$e8c2,.ClearBplcon0		
	PL_ORW	$ecf4+2,1<<9		; set Bplcon0 color bit
	PL_PS	$ee34,.ClearBplcon0
	PL_PS	$fcd2,.ClearBplcon0
	PL_PS	$19e34,.ClearBplcon0
	PL_ORW	$1fee0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1ff74+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1fff0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$edd0+2,1<<9		; set Bplcon0 color bit
	PL_PS	$ee3a,.ClearBplcon0_2
	PL_PS	$f5f4,.ClearBplcon0_2
	PL_ORW	$f760+2,1<<9		; set Bplcon0 color bit
	PL_PS	$f7c4,.ClearBplcon0_2
	PL_PS	$19e3a,.ClearBplcon0_2
	PL_ORW	$173c4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$17ffc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$180d8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$18e7e+2,1<<9		; set Bplcon0 color bit
	
	PL_PSS	$1a0e8,.Fix24Bit,2	; fix access fault

	PL_P	$19de8,AckVBI
	PL_PS	$18e52,.CheckQuit

    PL_IFC4
	PL_PS	$1afa6,.wblit1
	PL_PS	$1b012,.wblit2
	PL_PS	$1bf80,.wblit3
	PL_PS	$1bfd4,.wblit4
	PL_PS	$1b116,.wblit5
	PL_PS	$1b166,.wblit4
	PL_PSS	$19078,.wblit6,2
	PL_PS	$190aa,.wblit4
	PL_PSS	$19364,.wblit6,2
	PL_PS	$19396,.wblit4
    PL_ENDIF

; unlimited lives
	PL_IFC1X	0
	PL_B	$f49c,$4a
	PL_ENDIF

; unlimited energy
	PL_IFC1X	1
	PL_W	$16e50+2,0
	PL_B	$1707c,$4a
	PL_B	$1b382,$4a	; fall
	PL_ENDIF

; unlimited ammo
	PL_IFC1X	2
	PL_B	$1127e,$4a
	PL_B	$11542,$4a
	PL_B	$118da,$4a
	PL_B	$11aaa,$4a
	PL_B	$11c60,$4a
	PL_B	$11f04,$4a
	PL_B	$1ba0c,$4a
	PL_ENDIF

; unlimited money
	PL_IFC1X	3
	PL_B	$10558,$4a
	PL_B	$105dc,$4a
	PL_B	$1063e,$4a
	PL_B	$1066e,$4a
	PL_B	$106d6,$4a
	PL_B	$10736,$4a
	PL_B	$10798,$4a
	PL_B	$10810,$4a
	PL_B	$1086c,$4a
	PL_B	$108ce,$4a
	PL_ENDIF


    
; invincibility
	PL_IFC1X	4
	PL_B	$16e34,$60
	PL_NOP	$17054,4
	PL_B	$1b76e-$400,$60	; can fall from any height
	PL_ENDIF


; start with max. money
	PL_IFC1X	5
	PL_PS	$e8f0,.SetMoney
	PL_ENDIF


; in-game keys
	PL_IFC1X	6
	PL_PS	$18e52,.CheckKeys
	PL_PS	$f5e8,.DisableKeys	; disable in-game keys when entering name
	PL_PS	$f7c4,.EnableKeys	; and enable them again after name has been entered
	PL_ENDIF

	PL_IFC2
    PL_PS    $19838-$400,.read_joy0dat
    PL_PS    $19864-$400,.read_joy0dat
    PL_PS    $19890-$400,.read_joy0dat
    PL_PS    $198ba-$400,.read_joy0dat
    PL_PS    $198d8-$400,.read_joy0dat
    PL_PS    $198f6-$400,.read_joy0dat
	PL_PS	$19f4a-$400,.start_climbing_ladder
	PL_PS	$19f8c-$400,.do_jump
	
    ; read joypad from vbl
	PL_PS	$1A184-$400,.vbl_hook
	PL_S	$1A18A-$400,$D4-$8A
	PL_ENDIF

	PL_SA	$19dfc,$19eae		; disable CHROME cheat

	PL_END


.EnableKeys
	lea	.KeysEnabled(pc),a0
	st	(a0)
	bra.w	.ClearBplcon0_2		; original code

.DisableKeys
	lea	.KeysEnabled(pc),a0
	sf	(a0)
	rts

.KeysEnabled	dc.b	1
		dc.b	0	

.CheckQuit
	move.b	d0,$400+$18e16
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts

.CheckKeys
	bsr.b	.CheckQuit

	movem.l	d0-a6,-(a7)

	move.b	.KeysEnabled(pc),d1
	beq.b	.exit

; 1-6: select weapon
	move.b	d0,d1
	cmp.b	#$01,d1
	blt.b	.noweapon
	cmp.b	#$06,d1
	bgt.b	.noweapon
	subq.b	#1,d1
	move.b	d1,$400+$404d.w		; weapon
	move.b	#$24,$400+$3cfa.w	; ammo
.noweapon


	lea	.TAB(pc),a0
.loop	movem.w	(a0)+,d1/d2
	cmp.b	d0,d1
	beq.b	.found

	tst.w	(a0)
	bne.b	.loop
	bra.b	.exit

.found	jsr	.TAB(pc,d2.w)

.exit	movem.l	(a7)+,d0-a6
	rts

.start_climbing_ladder
	move.l	joy1(pc),d0
	btst	#JPB_BTN_UP,d0
	bne.b	.climb		; if it wasn't "up", then jump
	add.l	#$3C,(a7)	; jump
	rts
	
	; alternate behaviour: just do nothing
	;addq.l	#4,a7
	;rts
.climb
	MOVE.W	$26b4.w,d0 	; player_x_absolute_coord,D0	
	rts
	
.do_jump
	move.l	D0,-(a7)
	move.l	joy1(pc),d0
	btst	#JPB_BTN_BLU,d0
	bne.b	.jump		; if it wasn't "up", then do nothing
	btst	#JPB_BTN_YEL,d0
	beq.b	.nojump		; if it wasn't "up", then do nothing
	move.b	#7,$4500.W	; crouch? triggers high jump
	clr.b	$4504.w	; unknown flag that triggers low jump (when???)
	bra.b	.jump		; if it wasn't "up", then do nothing
.nojump
	addq.l	#4,a7
	move.l	(a7)+,d0
	rts
.jump
	ST	.LADDER_FLAG.W
	move.l	(a7)+,d0
	rts
	
	
.TAB	dc.w	$36,.SkipLevel-.TAB	; N - skip level
	dc.w	$5f,.ShowHelp-.TAB	; HELP - show help screen
	dc.w	$12,.RefreshEnergy-.TAB	; E - refresh energy
	dc.w	$20,.RefreshAmmo-.TAB	; A - refresh ammo
	;dc.w	$21,.Shop-.TAB		: S - enter shop
	dc.w	$37,.SetMoney-.TAB	; M - get max. money
	dc.w	$23,.GetFireBlade-.TAB	; F - get max. fire blades

	dc.w	0			; end of tab

;.Shop	move.b	#1,$400+$72e.w		; disabled, causes problems
;	rts

.RefreshEnergy
	move.b	#$24,$400+$3cf7.w
	rts

.RefreshAmmo
	move.b	#$24,$400+$3cfa.w
	rts

.SkipLevel
	st	$400+$66d.w
	move.l	#-1,$400+$2cb2.w
	rts

.GetFireBlade
	move.b	#99,$400+$2220+3.w
	rts


.SetMoney
	move.b	#99,$400+$2227.w
	rts

.SCREEN		= $60000
.HEIGHT		= 64 			; 8 text lines
.YSTART		= 80

.ShowHelp
	lea	.SCREEN,a0		; screen
	move.l	HEADER+ws_ExpMem(pc),a1
	move.w	#(40*.HEIGHT)/4-1,d7
.copy	move.l	(a0),d0
	clr.l	(a0)+
	move.l	d0,(a1)+
	dbf	d7,.copy

	bsr	WaitRaster

	move.w	#$4000,$dff09a		; disable interrupts
	move.w	#$f,$dff096		; disable audio DMA
	move.w	#1<<7,$dff096		; disable copper DMA

; write help text using the game font
	lea	.TXT(pc),a0
	lea	$60000,a1
	moveq	#0,d1			; x pos
	moveq	#0,d2			; y pos
.next	sub.l	a4,a4			; special chars
	moveq	#0,d0
	move.b	(a0)+,d0
	beq.w	.done
	cmp.b	#10,d0
	bne.b	.noNew
	moveq	#0,d1
	add.w	#40*8,d2
	bra.b	.next

.noNew	cmp.b	#" ",d0
	bne.b	.noSpace
	addq.w	#1,d1
	bra.b	.next

.noSpace
	cmp.b	#".",d0
	bne.b	.noDot
	moveq	#37,d0
.noDot

	cmp.b	#"-",d0
	bne.b	.nominus
	lea	.MINUS(pc),a4
.nominus

	cmp.b	#":",d0
	bne.b	.nocol
	lea	.COLON(pc),a4
.nocol

	cmp.b	#"0",d0
	bne.b	.no0
	moveq	#15,d0
	bra.b	.write
.no0	cmp.b	#"1",d0
	blt.b	.noNum
	cmp.b	#"9",d0
	bgt.b	.noNum
	sub.b	#$15,d0
	bra.b	.write

.noNum	cmp.b	#"A",d0
	blt.b	.write
	cmp.b	#"Z",d0
	bgt.b	.write
	sub.b	#64,d0
		
.write	lea	$400+$5f3c.w,a2		; font
	add.w	d0,a2
	moveq	#40,d6

	move.l	a4,d7
	beq.b	.nospecial
	move.l	a4,a2
	moveq	#1,d6			; modulo
.nospecial

	lea	(a1,d1.w),a3		; screen
	add.w	d2,a3
	moveq	#7-1,d7
.copyChar
	move.b	(a2),(a3)
	add.w	d6,a2
	add.w	#40,a3
	dbf	d7,.copyChar
	addq.w	#1,d1			; next x pos	
	bra.w	.next

.done



.Fire	bsr	WaitRaster

	lea	$dff000,a6
	move.w	#($2c+.YSTART)<<8|81,$8e(a6)
	move.w	#($2c+.YSTART+.HEIGHT)<<8|$c1,$90(a6)
	move.w	#$38,$92(a6)
	move.w	#$d0,$94(a6)
	move.l	#.SCREEN,$e0(a6)
	move.w	#$1200,$100(a6)
	move.w	#0,$108(a6)
	move.w	#0,$10a(a6)
	move.w	#0,$102(a6)
	move.w	#0,$104(a6)
	move.w	#0,$180(a6)
	move.w	#$fff,$182(a6)


	btst	#7,$bfe001
	bne.b	.Fire

	move.l	HEADER+ws_ExpMem(pc),a0
	lea	.SCREEN,a1		; screen
	move.w	#(40*.HEIGHT)/4-1,d7
.restore
	move.l	(a0)+,(a1)+
	dbf	d7,.restore

	move.w	#1<<15|1<<7,$dff096			; enable copper DMA
	move.w	#$1<<15|1<<3|1<<2|1<<1|1<<0,$dff096	; enable audio DMA
	move.w	#$c000,$dff09a
	rts

.TXT	dc.b	"              IN-GAME KEYS",10
	dc.b	10
	dc.b	"A: REFRESH AMMO        E: REFRESH ENERGY",10
	dc.b	"F: MAX. FIRE BLADES    M: MAX. MONEY",10
	dc.b	"N: SKIP LEVEL        1-6: SELECT WEAPON",10
	dc.b	"          HELP: THIS SCREEN",10
	dc.b	10
	dc.b	"     PRESS FIRE TO RETURN TO GAME",0

; chars not available in font, "drawn" by me :)

.MINUS	dc.b	%00000000
	dc.b	%00000000
	dc.b	%00000000
	dc.b	%01111110
	dc.b	%00000000
	dc.b	%00000000
	dc.b	%00000000

.COLON	dc.b	%00000000
	dc.b	%00011000
	dc.b	%00011000
	dc.b	%00000000
	dc.b	%00011000
	dc.b	%00011000
	dc.b	%00000000

	CNOP	0,2


.Fix24Bit
	and.l	#$00ffffff,d0
	move.l	d0,a1
	and.l	#8-1,d1
	rts

.wblit1	add.l	a2,d0
	add.l	a2,d0
	add.l	a2,d0
	bra.b	.WaitBlit

.wblit2	bsr.b	.WaitBlit
	move.l	d0,$dff050
	rts

.wblit3	add.w	d0,d2
	add.l	d2,a0
	moveq	#0,d4
	bra.b	.WaitBlit

.wblit4	bsr.b	.WaitBlit
	move.l	d4,$dff050
	rts

.wblit5	add.l	(a6),d4
	move.l	6(a6),d3
	bra.b	.WaitBlit


.wblit6	bsr.b	.WaitBlit
	move.w	#-1,$dff044
	rts

.WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


.ClearBplcon0
	move.w	#1<<9,$400+$1fdf6
	rts

.ClearBplcon0_2
	move.w	#1<<9,$400+$1ff76
.noHigh	rts

.LoadHighscores
	lea	Hiscore(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.noHigh
	lea	Hiscore(pc),a0
	lea	$400+$1d13a,a1
	jmp	resload_LoadFile(a2)



.SaveHighscores
	move.w	#15,$dff096		; original code
	move.l	LEVEL(pc),d0
	bne.b	.nosave

	lea	Hiscore(pc),a0
	lea	$400+$1d13a,a1
	move.l	#$1d31a-$1d13a,d0
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)



; a0.l: file name
; a1.l: destination

.load	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d0-a6
.nosave	rts

.rawkey = $19216

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
	
.vbl_hook
	move.l	#$1966,d0
	lea	$dff120,a0
	; original game (less cycles :))
	MOVE.L	d0,(a0)+
	MOVE.L	d0,(a0)+
	MOVE.L	d0,(a0)+
	MOVE.L	d0,(a0)+
	MOVE.L	d0,(a0)+
	MOVE.L	d0,(a0)+
	MOVE.L	d0,(a0)+
	MOVE.L	d0,(a0)
    lea read_once_out_of_2(pc),a0
    eor.b   #1,(a0)
    beq.b   .nochange
    
    lea joy1(pc),a0
    lea	.rawkey,a1
    move.l  (a0),d1     ; get previous state
    moveq.l #1,d0
	bsr	_read_joystick
    cmp.l   d0,d1
    beq.b   .nochange   ; cheap-o test just in case no input has changed
    move.l  d0,(a0)     ; save previous state for next time

    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d1 to get what has changed quickly
    eor.l   d0,d1
    ; d1 bears changed bits (buttons pressed/released)
    TEST_BUTTON PLAY,$19     ; pause
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nochange
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nochange
	btst	#JPB_BTN_YEL,d0
	bne		QUIT
.nochange 	
	rts

.LADDER_FLAG = $444A	; when climbing ladder
	
.read_joy0dat:
	move.l	(4,a7),d0	; caller of the read controls routine
	cmp.l	#$10700,d0
	beq.b	.from_shop	; shop: no buttons
	
	movem.l	d1/a0,-(a7)
	move.l	joy1(pc),d1
	move.l	$DFF00A,D0
	; here just make BLU exactly like UP
	; we'll sort out the difference later in the game
	tst.b	$44C2.W		; on ladder? ignore button
	;tst.b	.LADDER_FLAG.W		; on ladder? ignore button
	bne.b	.no_blue
	btst	#JPB_BTN_YEL,d1		; high jump
	bne.b	.blue
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
.blue:
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	movem.l	(a7)+,d1/a0
	RTS	


.from_shop
	move.l	$DFF00A,D0
	rts
	
	
QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	
***********************************
** FUNGUS DECRUNCHER		***
***********************************

; this is an optimised version of the ByteKiller decruncher
; disassembled, adapted and optimised by stingray

FNG_NEXTLONG	MACRO
		add.l	d0,d0
		bne.b	*+18
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
		ENDM	


DECRUNCH_FUNGUS
	move.l	#"*FUN",d0
	move.l	#"GUS*",d1
.getend	cmp.l	(a0)+,d0
	beq.b	.ok1
	cmp.l	(a0)+,d0
	bne.b	.getend
.ok1	cmp.l	(a0)+,d1
	bne.b	.getend

	subq.w	#8,a0
	move.l	-(a0),a2	; decrunched length
	add.l	a1,a2		; a2: end of decrunched data
	move.l	-(a0),d0	; get first long
	move.l	-(a0),d4	; plus the 4 following longs
	move.l	-(a0),d5
	move.l	-(a0),d6
	move.l	-(a0),d7

.loop	FNG_NEXTLONG
	bcs.b	.getcmd

	moveq	#3,d1		; next 3 bits: length of packed data
	moveq	#0,d3
	FNG_NEXTLONG
	bcs.b	.enter
	moveq	#1,d3
	moveq	#8,d1
	bra.w	.copyunpacked

.copypacked
	moveq	#8,d1
	moveq	#8,d3
.enter	bsr.w	.getbits
	add.w	d2,d3
.packedloop
	moveq	#8-1,d1
.getbyte
	FNG_NEXTLONG
	addx.w	d2,d2
	dbf	d1,.getbyte
	move.b	d2,-(a2)
	dbf	d3,.packedloop
	bra.b	.next

.getcmd	moveq	#0,d2
	FNG_NEXTLONG
	addx.w	d2,d2
	FNG_NEXTLONG
	addx.w	d2,d2
	cmp.b	#2,d2		; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2		; %11: packed data follows
	beq.b	.copypacked

; %10
	moveq	#8,d1		; next byte
	bsr.b	.getbits
	move.w	d2,d3
	moveq	#12,d1
	bra.b	.copyunpacked

.notpacked
	moveq	#2,d3
	add.w	d2,d3
	moveq	#9,d1
	add.w	d2,d1
.copyunpacked
	bsr.b	.getbits
	lea	1(a2,d2.w),a3
.copy	move.b	-(a3),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.w	.loop
	rts

; d0.l: stream
; d1.w: number of bits to get from stream 
; -----
; d2.w: new bits

.getbits
	subq.w	#1,d1
	clr.w	d2
.bitloop
	FNG_NEXTLONG
	addx.w	d2,d2
	dbf	d1,.bitloop
	rts

WaitRaster
.wait	btst	#0,$dff005
	beq.b	.wait
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts

prev_buttons_state
		dc.l	0
read_once_out_of_2
    dc.b    0