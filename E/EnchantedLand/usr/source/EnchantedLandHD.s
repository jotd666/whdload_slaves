;*---------------------------------------------------------------------------
;  :Program.	EnchantedLand.asm
;  :Contents.	Slave for "Enchanted Land" from Thalion
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	03.02.2000
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	EnchantedLand.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	19		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem		dc.l	0		;ws_ExpMem
		dc.w	_name-_base	;ws_name
		dc.w	_copy-_base	;ws_copy
		dc.w	_info-_base	;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
		
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
_config
    dc.b    "C1:X:Infinite energy:0;"
	dc.b	0

_name	dc.b	"Enchanted Land",0
_copy	dc.b	'1990 Thalion',0
_info	dc.b	'Installed and fixed by Mr.Larmer & JOTD',10
	dc.b	'Version '
	DECL_VERSION
	dc.b	-1
	dc.b	'Greetings to Ronald van Dijk',10
	dc.b	'Richard Wagenfuhrer',0
	CNOP 0,2

IGNORE_JOY_DIRECTIONS

	include	readjoypad.s
	
;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		bsr	_detect_controller_types
		
		lea	Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		lea	$DFF000,a6
		lea	$2000.w,a7

		lea	$100.w,A0
		moveq	#$4C,D0
		move.l	#$400-$4C,D1
		moveq	#1,D2
		bsr.w	_LoadDisk


		move.l	a0,-(a7)
		sub.l	a1,a1
		lea	pl_boot(pc),a0
		jsr	resload_Patch(a2)
		move.l	(a7)+,a0

		jmp	(A0)

pl_boot
	PL_START
		PL_P	$90,Patch
		PL_P	$C0,jmp_2000
		
		PL_W	$1B0-$4C,$90
		PL_P	$1B2-$4C,Load

		PL_R	$1C4-$4C
		PL_R	$228-$4C

		PL_W	$142,$C0
	PL_END

jmp_2000
	cmp.w	#$33DF,$ECD8
	bne.b	.nosnoop
	patchs	$279A,move_a1_cl
	patch	$ECD8,pop_dma
.nosnoop
	bsr	_flushcache
	jmp	$2000.W

move_a1_cl
	cmp.l	#$CCCCCCCC,(a1)	; uninitialized whdload memory
	bne.b	.noill
	move.l	#-2,(a1)
.noill
	move.l	a1,$dff080
	rts

pop_dma
	move.l	d0,-(a7)
	move.w	4(a7),d0
	move.w	d0,$dff096
	move.l	(a7)+,d0
	addq.l	#2,a7
	jmp	$ecde

_flushcache:
	move.l	a2,-(a7)
	move.w	sr,-(a7)
	move.w	#$2700,SR	; freezing interrupts to avoid whdload reentrant call
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.w	(a7)+,sr
	move.l	(a7)+,a2
	rts


;--------------------------------

Patch
		lea	pl_main(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		jmp	$600.w

pl_main
	PL_START
	PL_R	$608		; drive on ???
	PL_P	$654,SaveHighs
	PL_L	$9C,$64A		; enable load code
	PL_NOP	$8D6,2		; skip protection longtrack
	PL_P	$E58,Relocate	; multi-pass relocate function
	PL_P	$1420,Load2
	PL_P	$F64,code_relocate
	PL_PSS	$6E0,decrunch,2
	PL_END
	
decrunch:
    MOVE.L A3,-(A7)
    JSR $10FE.W
    MOVEA.L (A7)+,A3
	

	bsr		_flushcache
	rts
	
code_relocate
.reloc
    MOVEA.L (A0)+,A3
    dc.l	$d3b1b800
    DBF	 D0,.reloc
	cmp.l	#$DFF1DC,$103F8
	bne.b	.skip6		

	; remove invalid PAL beamcon write	
	move.l	#$4E714E71,$103F4
	move.l	#$4E714E71,$103F8
	
.skip6
	cmp.l	#$DFF080,$1070A+6
	bne.b	.skip7
	
	; this is the game section
	
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	$1070C,a0		; copper start
	move.w	#$200,(2,a0)	; fix bplcon missing color 0
	move.w	#$200,($9A,a0)	; fix bplcon missing color 0
	lea	pl_game(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		(resload_Patch,a2)
	
	; disable sprite DMA
	move.w	#$0020,dmacon+$DFF000
	movem.l	(a7)+,d0-d1/a0-a2
.skip7



	bsr	_flushcache
	RTS

pl_game
	PL_START
	; fix blitter source out of range error
	PL_PSS	$11208,fix_blit_1,2
	; enable in-game cheat keys
	PL_NOP	$25832,2
	; joypad controls
	PL_PS	$25808,in_game_joypad
	PL_PSS	$257CC,handle_pause_release,2
	PL_PSS	$000257D6,handle_pause_press,2
	; more blitwaits
	IFEQ	1
	PL_PS	$112B8,blitwait_1
	PL_PS	$112c6,blitwait_1
	PL_P	$11618,blitwait_2
	PL_P	$12234,blitwait_2
	PL_P	$12484,blitwait_2
	PL_P	$12492,blitwait_2
	PL_P	$18416,blitwait_2
	PL_P	$1c00a,blitwait_2
	ENDC
	; smc fixes
	PL_PS	$17658,fix_smc_1
	PL_PS	$1B1DE,fix_smc_2
	PL_PS	$1F746,fix_smc_3
	PL_PS	$21cb6,fix_smc_4
	PL_PS	$2221e,fix_smc_5
	; trainer: infinite energy
	PL_IFC1
	PL_NOP	$00021600,14
	PL_ENDIF
	; install program part
	PL_P	$25076,reloc_game_over
	PL_END
reloc_game_over
.loop
	MOVEA.L (A0)+,A3
	dc.l   $d3b1b800 ;               ADD.L D1,(A1, A3.L*1, $00) == $0002a792 [d768ed6f]
	dbf	d0,.loop

	cmp.b	#$c,$2A78E
	bne.b	.no_gameover
; game over waits for space bar	
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_game_over(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
.no_gameover
	rts
	
	
pl_game_over:
	PL_START
	PL_PSS	$0002A78E,game_over_wait_for_spacebar,2
	PL_END

fix_smc_1
	; original code, followed by cache flush
	MOVE.W	D2,$176cc
	bra	_flushcache
fix_smc_2
	MOVE.L	A1,$1b1e6
	bra	_flushcache
fix_smc_3
	MOVEA.L	#$00026efa,A0		;1f746: 207c00026efa
	bra	_flushcache
	
fix_smc_4
	MOVE.W	D4,$21d5e
	bra	_flushcache
fix_smc_5:
	ANDI.W	#$7fff,D7		;2221e: 02477fff
	MOVEQ	#0,D6			;22222: 7c00
	bra	_flushcache

blitwait_2
.loop
	BTST	#6,$DFF002
	BNE.S	.loop		;11298: 66f6
	MOVE.W	#$c000,$dff09a
	rts
	
handle_pause_release:
	bsr	in_game_joypad
	CMP.B #$99,$0001db41
	rts
handle_pause_press:
	bsr	in_game_joypad
	CMP.B #$19,$0001db41
	rts
	
blitwait_1:
	MOVE.L	D2,(A0)			;112b8: 2082
	MOVE.L	A6,(A1)			;112ba: 228e
	MOVE.W	D1,(A2)			;112bc: 3481
.loop
	BTST	#6,$DFF002
	BNE.S	.loop		;11298: 66f6
	rts
	

in_game_joypad:
	movem.l	d1/a0/a2,-(a7)
	lea	$0001db41,a2		; game keyboard code
	bsr	handle_joypad
	movem.l	(a7)+,d1/a0/a2
	RTS
handle_joypad
	lea	previous_button_state(pc),a0
	move.l	(a0),d1
	moveq.l	#1,d0
	bsr	_read_joystick
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; blue pressed, was it the first time
	btst	#JPB_BTN_BLU,d1
	bne.b	.bluedone	; already pressed
	move.b	#$40,(a2)	; space pressed
	bra.b	.bluedone
.no_blue
	; blue not pressed, was it the first time
	btst	#JPB_BTN_BLU,d1
	beq.b	.bluedone
	move.b	#$C0,(a2)	; space released
.bluedone
	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_play
	; play pressed, was it the first time
	btst	#JPB_BTN_PLAY,d1
	bne.b	.playdone	; already pressed
	move.b	#$19,(a2)	; P pressed
	bra.b	.playdone
.no_play
	; play not pressed, was it the first time
	btst	#JPB_BTN_PLAY,d1
	beq.b	.playdone
	move.b	#$99,(a2)	; pause released
.playdone

	btst	#JPB_BTN_REVERSE,d0
	beq.b	.no_esc
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.no_esc
	; blue pressed, was it the first time
	btst	#JPB_BTN_REVERSE,d1
	bne.b	.escdone	; already pressed
	move.b	#$45,(a2)	; ESC pressed
	bra.b	.escdone
.no_esc
	; blue not pressed, was it the first time
	btst	#JPB_BTN_REVERSE,d1
	beq.b	.escdone
	move.b	#$C5,(a2)	; ESC released
.escdone
	
	move.l	d0,(a0)	; store previous button state
	
	MOVE.B (a2),D0
	rts
	



menu_spacebar_test:
	movem.l	d1/a0/a2,-(a7)
	lea	$00011622,a2		; game keyboard code
	bsr	handle_joypad
	movem.l	(a7)+,d1/a0/a2
	rts

previous_button_state
	dc.l	0

;--------------------------------

fix_blit_1:
	; D2 is the source address, can be wrong
	; fix address so it doesn't go up too much
	; (this can be also wrong, but the actual error seems
	; to have extra high bits so this masking is probably ok)
	and.l	#$7FFFF,d2
	move.l	d2,(a0)
	move.l	(a4)+,a6
	move.l	a6,(a1)
	move.w	d1,(a2)
	rts




Relocate
		pea	Reloc(pc)
		movem.l	d0-a6,-(a7)
		lea	$1042.w,a6
		jmp	$E60.w
Reloc
		cmp.w	#$2F39,$25D64
		bne.b	.skip
		cmp.l	#$1077A,$25D66
		bne.b	.skip

		move.l	attnflags(pc),d0
		btst	#AFB_68010,d0
		beq.b	.skip

		; JOTD: don't do it on 68000 because it would crash badly

		patch	$25D64,StackFrameFormat
.skip
		cmp.w	#$11FC,$11A60
		bne.b	.skip2
		cmp.l	#$8260,$11A62
		bne.b	.skip2
		move.w	#$6004,$11A60		; skip Atari ST code
.skip2
		cmp.w	#$0C98,$24F7C
		bne.b	.skip3
		cmp.l	#$3F3,$24F7E
		bne.b	.skip3

		move.w	#$4EF9,$24F6A
		pea	Relocate2(pc)
		move.l	(a7)+,$24F6C
.skip3
		cmp.l	#$423900BF,$10AD4
		bne.b	.skip4
		patchs	$10AD4,kb_routine
.skip4

		cmp.l	#$23C900DF,$10AD4
		bne.b	.skip5	
		
		patchs	$104A8,set_copperlist
		move.l	#$4E714E71,$104A8+6
		; menu (character walks the screen, wait for spacebar)		
	    ; while we're at it, patch spacebar => second button
		patchs	$15824,menu_spacebar_test
		; enable sprite DMA
		move.w	#$C020,dmacon+$DFF000

.skip5

		cmp.l	#$0c3900c0,$00011A74 
		bne.b	.skip11
		
		movem.l	d0-d1/a0-a2,-(a7)
		lea	pl_high_scores(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	(resload_Patch,a2)
		movem.l	(a7)+,d0-d1/a0-a2
		

.skip11
		bsr	_flushcache
		rts
pl_high_scores
	PL_START
	PL_PSS	$11A74,hiscores_wait_for_spacebar,2
	PL_PS	$10BDE,hiscores_keyboard
	PL_END
	
hiscores_keyboard
	jsr	$1041C	; original
	btst	#7,$BFE001
	bne.b	.nofire
	move.l	#$44,D0	; simulate RETURN to end hiscore entry
.nofire
	rts
	
hiscores_wait_for_spacebar
	movem.l	A0,-(a7)
	lea	$0001048d,a0
	bsr	wait_spacebar_or_fire
	movem.l	(A7)+,A0
	rts
game_over_wait_for_spacebar
	movem.l	A0,-(a7)
	lea	$0002a1a0,a0
	bsr	wait_spacebar_or_fire
	movem.l	(A7)+,A0
	rts
	
wait_spacebar_or_fire:
	; no need to bother for blue button, just test for FIRE
	btst	#7,$BFE001
	bne.b	.nofire
	move.B #$c0,(a0)
.nofire
	CMP.B #$c0,(a0)
	rts
	
set_copperlist:
	move.l	#-2,$11D48		; terminate copperlist properly
	move.w	#$200,$11C3E	; activate COLOR on bplcon
	cmp.w	#$FFFF,$11D26
	bne.b	.zap
	; fix incorrect bitplane addresses (set to 0 instead of $FFFFFFFE)
	move.w	#0,$11D26
	move.w	#0,$11D26+4
	
.zap
	MOVE.L #$00011c3c,$00dff080	
	rts
	
kb_routine
	movem.l	d0,-(a7)
	not.b	d0
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit

	; quitkey for 68000 / NOVBRMOVE

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.noquit
	movem.l	(a7)+,d0

	bsr	kb_delay	
	addq.l	#4,(A7)
	rts

kb_delay:
	bset	#6,$BFEE01  ; CIA.CRA
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
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

;--------------------------------

Relocate2
		pea	Reloc2(pc)
		movem.l	d0-a6,-(a7)
		lea	$25154,a6
		jmp	$24F72
Reloc2
		cmp.w	#$31FC,$59A70
		bne.b	.skip
		cmp.l	#$07008240,$59A72
		bne.b	.skip

		move.w	#$6004,$59A70		; skip Atari ST code
.skip
		rts

;--------------------------------

StackFrameFormat
		move.w	#$80,-(a7)
		move.l	$1077A,-(a7)
		jmp	$25D6A

;--------------------------------

SaveHighs
		movem.l	d0-a6,-(a7)

		move.l	#$1E4,d0		;len
		move.l	#$EE800,d1		;offset
		lea	(a0),a1			;address
		lea	_savename(pc),a0	;filename
		move.l	_resload(pc),a2
		jsr	resload_SaveFileOffset(a2)

		movem.l	(a7)+,d0-a6
		rte
_savename
		dc.b	'Disk.1',0
		even

;--------------------------------

Load
		movem.l	d0-a6,-(a7)

		mulu	#$1800,d0

		moveq	#0,d1
		move.w	d7,d1
		mulu	#$1800,d1

		moveq	#1,D2

		bsr.b	_LoadDisk

		movem.l	(A7)+,d0-a6
		rts

;--------------------------------

Load2
		movem.l	d1-a6,-(a7)

		moveq	#1,D2

		bsr.b	_LoadDisk

		move.l	d1,d0

		movem.l	(a7)+,d1-a6
		add.l	#$20,(a7)
		rts

;--------------------------------

_resload	dc.l	0		;address of resident loader

Tags
	dc.l	WHDLTAG_ATTNFLAGS_GET
attnflags
	dc.l	0
	dc.l	0
;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================
; keyboard read
;0002582C 0c38 0002 0211           CMP.B #$02,$0211 [00]   ; cheatmode?
;00025832 663c                     BNE.B #$3c == $00025870 (T)
;00025834 4a39 0002 3fc4           TST.B $00023fc4 [00]
;0002583A 6b52                     BMI.B #$52 == $0002588e (T)
;0002583C 0c00 0051                CMP.B #$51,D0
;00025840 6618                     BNE.B #$18 == $0002585a (T)
;00025842 4279 0001 3146           CLR.W $00013146
;00025848 50f9 0002 4b78           ST .B $00024b78 [00] == $00024b78 (T)
;0002584E 50f9 0002 58f8           ST .B $000258f8 [00] == $000258f8 (T)
;00025854 50f9 0001 c698           ST .B $0001c698 [00] == $0001c698 (T)
;0002585A 0c00 0052                CMP.B #$52,D0
;0002585E 6610                     BNE.B #$10 == $00025870 (T)
;00025860 6100 f37a                BSR.W #$f37a == $00024bdc
;00025864 4239 0002 58f6           CLR.B $000258f6
;0002586A 4239 0001 db41           CLR.B $0001db41
;00025870 4a39 0002 3fc4           TST.B $00023fc4 [00]
;00025876 6b16                     BMI.B #$16 == $0002588e (T)
;00025878 0c00 0040                CMP.B #$40,D0
;0002587C 6610                     BNE.B #$10 == $0002588e (T)
;0002587E 6100 f990                BSR.W #$f990 == $00025210
;00025882 4239 0002 58f6           CLR.B $000258f6
;00025888 4239 0001 db41           CLR.B $0001db41
;0002588E 0c00 0019                CMP.B #$19,D0
;00025892 6606                     BNE.B #$06 == $0002589a (T)
;00025894 50f9 0002 58fa           ST .B $000258fa [00] == $000258fa (T)
;0002589A 0c00 0053                CMP.B #$53,D0
