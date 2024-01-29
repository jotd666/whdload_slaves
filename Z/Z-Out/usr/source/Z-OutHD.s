;*---------------------------------------------------------------------------
;  :Program.	Z-Out.asm
;  :Contents.	Slave for "Z-Out" from Rainbow Arts
;  :Author.	JOTD/Harry
;  :History.	rework at 2004-10-31 ... 2004-11-22
;  :Requires.	-
;  :Copyright.	LGPL Lesser Gnu Public license
;  :Language.	68000 Assembler
;  :Translator.	Barfly
;  :Special changes. Instead of J+K now J+I switches invulnerability
;;  :To Do.	access fault fix (acc. to Jeff, but ??where??)
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
;	INCLUDE own/jst.i


	IFD BARFLY
	OUTPUT	"Z-Out.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	DOSCMD	"WDate > T:date"
	ENDC

;EmulateByMMU	=	0	; 1 - on ; 0 -off

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		dc.l	$80000;+$1000		;ws_BaseMemSize
;		dc.l	$100000;+$1000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$5D		;ws_keyexit = num '*'
_expmem		dc.l	0;$1000;+$10000	;ws_ExpMem
		dc.w	_name-_base	;ws_name
		dc.w	_copy-_base	;ws_copy
		dc.w	_info-_base	;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config


_config
        dc.b    "C1:X:Start with autofire on:0;"
		dc.b	0
		
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"3.5"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_name	dc.b	'Z-Out',0
_copy	dc.b	'1991 Advantec/Rainbow Arts',0
_info	dc.b	'Installed & fixed by JOTD/Harry',10,10
	dc.b	"Thanks to DefJam/Angels for 2 player weapon fix",10,10
	dc.b	'Version '
		DECL_VERSION

	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION

		dc.b	0

	CNOP 0,2

_fmem	dc.l	0
;======================================================================
Start	;	A0 = resident loader
;======================================================================

;	ifne	EmulateByMMU
;		lea	_fmem(pc),a1
;		move.l	_expmem(pc),(a1)
;		add.l	#$1000,(a1)
;		nop
;		nop
;	endc

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		bsr	_detect_controller_type	

		move.l	#$110,$4.w
		move.l	4.w,a0			;set ram sizes:
		move.l	#0,$4e(a0)		;no fastmem
		move.l	#$80000,$3e(a0)		;0.5MB chip

		lea	tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		move.l	monitor(pc),d0
		cmp.l	#PAL_MONITOR_ID,d0
		beq.b	.dspok

		; game does not work in NTSC mode

		pea	TDREASON_MUSTPAL
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
.dspok
	IFEQ	1
		lea	$30000,A0		;bootloader, load just for fun
		move.l	#0,D0
		move.l	#$400,D1
		moveq	#1,D2
		bsr.w	_LoadDisk
	ENDC

		lea     $50000,A0		;game takes over
        move.l	#$2c00,d0		;and decrunches 1st part
		move.l	#$5800,d1
		moveq	#1,d2
		bsr.w	_LoadDisk

		lea	Prepare1(pc),a0
		move.l	a0,$5012c

		move.l	a0,-(A7)
		move.l	_resload(PC),a0
		jsr	resload_FlushCache(A0)	;preserves all registers
		move.l	(A7)+,a0

		jmp	$50024

Prepare1	
		move.w	#$4ef9,$40058
		lea	PrepareMain(pc),a0
		move.l	a0,$4005A


		move.l	#$4e714e71,$40004	;mask out SuperState(a6)

		move.l	a0,-(A7)
		move.l	_resload(PC),a0
		jsr	resload_FlushCache(A0)	;preserves all registers
		move.l	(A7)+,a0
		jmp	$40000

DO_ZBASE_PATCH:MACRO
	movem.l	d0-d1/a0-a2,-(a7)
	lea	\1(pc),a0
	move.l	_resload(pc),a2
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	ENDM
	
	include 	dbffix.s
	include		ReadJoyButtons.s
	
PrepareMain
;#!
;.333		bra.s	.333

		pea	PrepIntro(pc)
		move.l	(a7)+,$5da.W
		pea	Fix7855C(pc)		;set trapvectors $e + $f
		move.l	(a7)+,$b8.W
		pea	JMP24To32(pc)
		move.l	(a7)+,$bc.W

		move.l	#$ffff,d7
;		move.w	#$8610,$dff096

		; fix a few DBF D0 and other DBF Dx (sound issues)
		lea	$500.W,A0
		lea	$50000,A1
		bsr	_dbffix

		move.b	controller_joypad_1(pc),d0
		beq.b	.nojoy
		; no need to patch for extra buttons if no joypad connected
		; since 2nd button is already supported for normal joystick
		DO_ZBASE_PATCH	pl_joypad
		
.nojoy
		DO_ZBASE_PATCH	pl_main


		jmp	$500.W

GAME_KB_CODE = $86B7

pl_joypad
	PL_START
	PL_PS	$4476,read_joy_1
	PL_PS	$4482,test_joy_1_button2
	PL_PS	$4492,test_joy_1_button2
	PL_PS	$766C,end_of_pause
	; 86B7 is the kb code
	; 7660: code for pause
	; 1A38: code for ESC	
	PL_END
	
pl_main
	PL_START

	PL_P	$71d2,_LoadOneSec
		
	PL_W	$7210,$601E
	PL_W	$71AE,$6006		; switch drive light off during play

	PL_PS	$5E4,new_game_init		; sets autofire on, detects controller again...
	
	PL_PS	$776,FixAccessFaults

	; trap #F

	PL_W	$55AC,$4E4F
	PL_W	$5644,$4E4F
	PL_W	$58A4,$4E4F
	PL_W	$58AC,$4E4F
	PL_W	$5BCC,$4E4F
	PL_W	$5C58,$4E4F
	PL_W	$5C60,$4E4F
	PL_W	$5CF0,$4E4F
	PL_W	$5CF8,$4E4F

	PL_P	$7750,KbInt2

	; Harry: fix gfx-bug in level 5

	PL_B	$7c34,$20

	; JOTD: fix weapons in 2 player mode (Angels/Defjam fix)

	PL_W	$3E5A,$14
	PL_W	$3E60,$14
	
	
	PL_END

end_of_pause
	; read PLAY again until it is released
	movem.l	d0,-(A7)
	bsr	.waitpauserelease
.loop
	cmp.b	#$19,(a3)	; original code, check P key
	beq.b	.out
	; check if PLAY is pressed again
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	beq.b	.loop
	bsr	.waitpauserelease
.out
	movem.l	(a7)+,d0
	rts
	
.waitpauserelease:
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	bne.b	.waitpauserelease
	rts
	
read_joy_1:
	; perform button readings
	movem.l	d0-a0,-(a7)
	bsr	_read_joystick_port_1
	lea	joystatus(pc),a0
	; check ESC
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	move.b	#$45,GAME_KB_CODE	; ESC in keyboard
.noesc
	; toggle autofire
	btst	#JPB_BTN_GRN,d0
	beq.b	.nogreen
	move.l	d1,-(a7)
	move.l	(a0),d1		; get previous status
	btst	#JPB_BTN_GRN,d1
	bne.b	.green_already_pressed	; avoids toggle
	move.b	#$20,GAME_KB_CODE	; A in keyboard
.green_already_pressed
	move.l	(a7)+,d1
.nogreen
	; pause
	btst	#JPB_BTN_PLAY,d0
	beq.b	.noplay
	move.b	#$19,GAME_KB_CODE	; P in keyboard
.noplay

	; store status in the end
	move.l	d0,(a0)
	movem.l	(a7)+,d0-a0
	rts

test_joy_1_button2
	movem.l	d0,-(a7)
	move.l	joystatus(pc),d0
	not.l	d0		; game logic maps potgo logic: must be 0 to be set
	btst	#JPB_BTN_BLU,d0	
	movem.l	(a7)+,d0
	rts

joystatus:
	dc.l	0
	
new_game_init:
	move.b	d1,(A1)	; some game variable
	movem.l	d0/a0,-(a7)
	move.b	#0,(3,a1)	; autofire: off
	move.l	autofire(pc),d0
	beq.b	.noauto
	move.b	#1,(3,a1)	; autofire: on
.noauto
	; re-run joypad detection so it can be plugged/switched
	; after each game
	bsr	_detect_controller_type
	movem.l	(a7)+,d0/A0
	rts
	
InstallVBLInterrupt:
	pea		empty_vbl(pc)
	move.l	(A7)+,$6C
	move.w	#$C02C,($9A,A6)	; was $C00C
	rts

empty_vbl:
	move.w	#$0070,$DFF000+intreq	; just acknowledge and exit
	RTE
	
PrepIntro
	DO_ZBASE_PATCH	pl_intro
	
	jmp	$b000


pl_intro
	PL_START
	PL_P	$fbd8,_LoadOneSec

	PL_P	$1c094,_LoadOneSec

	;the hiscore-track (=01) acts also as protection
	;its content is loaded to $d2f6-$d396
	;the original game-resetscores are from $d396-$d436

	PL_B	$f40a,$60		;success check

	PL_B	$f5d0,$60		;omit step to cyl 0

	PL_W	$f5b2,$4e71		;spin up time

	PL_R	$f5e0		;omit headsteps

	PL_W	$f4c0,$4e71		;allowed read time

	PL_L	$f4d0,$42844e75	;return from decode

	PL_R	$f59e		;motor on
	PL_R	$f5b6		;motor off

	PL_P	$f474,hiload

	PL_P	$f694,hiwrite

	PL_L	$f634,$7e704e75	;write hiscoretrack, now no op.

;	PL_B	$d38f,$59		;omit - changed values 
;	PL_L	$d390,$00050005	;from hiscoretrack
;	PL_W	$d394,$0005

	PL_P	$234E,InstallVBLInterrupt

	; *** keyboard fix & quit key for the menu part

	PL_PS	$fe82,KbIntMenu
	PL_W	$FE88,$600C

	; *** ack interrupt and remove disk spinup wait
	;     by omitting the replaced instructions

	PL_P	$fee0,AckInterrupt
	PL_W	$fee6,$4e71

	; *** fix VBL interrupts acknowledge

	PL_P	$6b5ea,PatchEndVBL

						;correct centering of ...
	PL_L	$BD80,$23E94		;advantec logo
	PL_L	$c41a,$fffffffc	;small alnum letters (see hiscore)

	PL_B	$1a9b,$17	;change immunity from j+k to j+i
					;(worked only on A2000/A4000 Keyboard)

	PL_END

;still buggy! -- What bugs? (harry)

FixAccessFaults
		lea	$784ee,a4		;orig. code

	movem.l	d0-d3/a0-a3,-(a7)
;#!
;.1	bra	.1


;	movem.l	d0-a6,-(a7)
	lea	$78000,A0
	lea	$7F000,A1
;	lea	.string(pc),A2
	moveq.l	#8,D0
	bra.s	.loopin

.loop	addq.l	#1,a0
	cmp.l	a1,a0
	bhs.s	.loopnotfound

.loopin	move.l	d0,d1
	move.l	a0,a2
	lea	.string(pc),A3

.looptrue
	move.b	(a3)+,d2
	cmp.b	(a2)+,d2
	bne.s	.loop
	subq.l	#1,d1
	beq.s	.loopend
;	addq.l	#1,a0
	
	bra.s	.looptrue

.loopnotfound
	move.l	#0,a0
.loopend
;	bsr	HexSearch
	cmp.l	#0,A0
	beq.b	.skip

	move.w	#$4E4E,(A0)			;insert a trap #e
.skip
	movem.l	(a7)+,d0-d3/a0-a3
	move.l	a0,-(A7)
	move.l	_resload(PC),a0
	jsr	resload_FlushCache(A0)	;preserves all registers
	move.l	(A7)+,a0

		rts
.string:
	dc.l	$28102C08,$242C0004


Fix7855C
	move.l	A0,D4
	bmi.b	.avoid
	move.l	(A0),D4
	rte
.avoid
	; an access fault would have occured on (A0)
	; we put 0 in D4 and it works OK

	moveq.l	#0,D4
	rte

JMP24To32:
	move.l	D0,-(sp)
	move.l	A1,D0
	and.l	#$FFFFFF,D0	; 24Bit Patch
	move.l	D0,A1
	move.l	(sp)+,D0

	move.l	A1,2(SP)

	rte

PatchEndVBL
	; *** Correct bug in $7855C (crash at section 3 of level 2)

	move.w	#$7FFF,intreq+$DFF000
	movem.l	(A7)+,D0/A5
	rte

AckInterrupt
	btst.b	#0,$BFDD00
	move.w	#$7FF0,intreq+$DFF000
	bset	#3,$BFD100	; Disable Floppy 0
	bset	#7,$BFD100	; Disable Motor
	movem.l	(A7)+,D0-D3/A0-A1
	RTE

KbInt:
	lea	$BFEC01,A1
	movem.l	D0/A0,-(sp)
	move.b	(A1),D0
	not.b	D0
	ror.b	#1,D0
	cmp.b	_keyexit(pc),D0
	beq	_quit

	cmp.b	#$26,d0
	bne.s	.nocheat
	lea	trused(pc),a0
	st	(a0)

.nocheat
	movem.l	(sp)+,D0/A0
	rts

_quit
	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


KbIntMenu:
	move.b	$BFEC01,(A0)
	move.l	D0,-(A7)
	move.b	(A0),D0
	ror.b	#1,D0
	not.b	D0
	cmp.b	_keyexit(pc),D0
	beq	_quit
	move.l	a0,-(a7)
	cmp.b	#$26,d0
	bne.s	.nocheat
	lea	trused(pc),a0
	st	(a0)

.nocheat
	move.l	(a7)+,a0
	move.l	(A7)+,D0
	bset	#6,$BFEE01
	rts

KbInt2
	move.b	$BFEC01,D0

	; ** decode keycode

	ror.B	#1,D0
	not.b	D0
	move.b	D0,$86B7

	cmp.b	_keyexit(pc),D0
	beq	_quit

	cmp.b	#$26,d0
	bne.s	.nocheat
	move.l	a0,-(a7)
	lea	trused(pc),a0
	st	(a0)
	move.l	(a7)+,a0

	; acknowledge keyboard
.nocheat
	bset	#6,$BFEE01
	move.l	#$2,D0
.4	MOVE.L	D0,-(A7)
	MOVE.B	$DFF006,D0
.3	CMP.B	$DFF006,D0
	BEQ.S	.3
	MOVE.L	(A7)+,D0
	DBF	D0,.4

	bclr	#6,$BFEE01

	move.w	(A7)+,D0

	move.w	#8,$DFF000+intreq
	RTE


_LoadDisk	move.l	a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		move.l	(a7)+,a2
		rts


;in bootblock: several sectors are loaded
_LoadSec	movem.l	d0-d7/a0-a6,-(a7)
		mulu	#$200,d0		;#of starting sector
		mulu	#$200,d1		;size in sectors
		moveq.l	#$1,d2			;always 1st disk
		bsr.b	_LoadDisk
		movem.l	(a7)+,d0-d7/a0-a6
		rts

;in game: always only one sector is loaded
_LoadOneSec	movem.l d0-d7/a0-a6,-(a7)	;load one sector from hd->ram
		mulu	#$200,d0		;#of starting sector
		move.l	#$200,d1		;size is one sector
		moveq.l	#$1,d2			;always 1st disk
		bsr.b	_LoadDisk

		movem.l	(a7)+,d0-d7/a0-a6
		rts

hiload
	MOVEM.L	D0-A6,-(A7)
;#!
;	bra.s	.skip

	lea	(hiname,PC),a0		;filename
	move.l	(_resload,PC),a3
	jsr	(resload_GetFileSize,a3)
	tst.l	d0
	beq.s	.skip
	MOVE.L	#$d2f6,A1		;ADDY
	MOVE.L	#$d396-$d2f6,D0		;LEN
	lea	(hiname,PC),a0		;filename
	jsr	(resload_LoadFile,a3)

.skip	MOVEM.L	(A7)+,D0-A6
	moveq	#$70,d7
	RTS


hiwrite
	MOVEM.L	D0-A6,-(A7)
	move.b	trused(PC),d0
	bne.s	.end

	MOVE.L	#$d396-$d2f6,D0
	MOVE.L	#$d2f6,A1
	LEA.L	hiname(PC),A0
	move.l	_resload(pc),a2
	jsr	(resload_SaveFile,a2)
.end
	MOVEM.L	(A7)+,D0-A6
	RTS

hiname	DC.B	'zouthigh',0
	even


;--------------------------------
	
_resload	dc.l	0		;address of resident loader
trused	dc.b	0			;trainer has been used?
	even
tags
		dc.l	WHDLTAG_MONITOR_GET
monitor	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
autofire
		dc.l	0
		dc.l	0

	END
