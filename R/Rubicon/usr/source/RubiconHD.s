; Resourced by whdslave_resourcer
; a program written by JOTD in 2016
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"Rubicon.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC


_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 15)
	dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap
	dc.l	$100000					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$0					; ws_keydebug
_keyexit
	dc.b	$59					; ws_keyexit
_expmem
	dc.l	$1000					; ws_expmem
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;---
_config
	dc.b    "C1:X:Infinite lives & energy:0;"
	dc.b    "C2:X:Jump with second button:0;"
	dc.b	0

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
_data   dc.b    0
_name	dc.b	'Rubicon',0
_copy	dc.b	'1992 21st Century',0
_info
    dc.b   'adapted by Mr.Larmer, Bored Seal & JOTD',10,10
	dc.b	'play pauses/fire unpauses game',10
	dc.b	'reverse/forward to switch weapons from pad',10
	dc.b	'reverse/forward/play to quit to WB',10
	dc.b	'reverse/forward/green to quit current game',10,10
	dc.b	'Version '
	DECL_VERSION
	dc.b	0
_kickname   dc.b    0
;--- version id

    dc.b	0
    even
	include		ReadJoybuttons.s
	
DMACONR		EQU	$DFF002
BLTSIZE		EQU	$DFF058

; A5-related game variables
weapon_type = 483
keycode = 447


start:
	LEA	_resload(PC),A1		;076: 43fa0266
	MOVE.L	A0,(A1)			;07a: 2288
	MOVEA.L	A0,A5			;07c: 2a48
;	LEA	tags(PC),A0		;07e: 41fa0262
;	JSR	resload_Control(A5)	;82 (offset=34)
	
	bsr	_detect_controller_type
	
	LEA	$5e.W,A0
	MOVEA.L	A0,A4			;08a: 2848
	MOVE.L	#$000c8600,D0		;08c: 203c000c8600
	MOVE.L	#$00000d40,D1		;092: 223c00000d40
	MOVEQ	#1,D2			;098: 7401
	BSR.W	_LoadDisk		;09a: 61000230
	move.l	a4,a1
	lea		pl_boot(pc),a0
	JSR		resload_Patch(a5)

	JMP	$8a.W
	
pl_boot
	PL_START
	PL_P	$23e,Load
	PL_PS	$b60,SetColor
	PL_W	$10c,$6050
	PL_AW	$c18,$200
	PL_AW	$c2e-$5E,$200
	PL_AW	$bd6-$5E,$200
	PL_PA	$174,patch_main
	PL_END
	
decrunch
	move.l	_expmem(pc),-(a7)
	rts
	
; after loading picture
patch_main:
	; relocate decruncher code to fast memory
	LEA	$d574,A0
	MOVEA.L	_expmem(PC),A1
.copy:
	MOVE.L	(A0)+,(A1)+
	CMPA.L	#$0000d67c,A0
	BLT.S	.copy

	BSR	fix_blitwaits

	sub.l	a1,a1
	move.l	_resload(pc),a5
	lea		pl_main(pc),a0
	JSR		resload_Patch(a5)

	JMP	$c470
	
pl_main	
	PL_START
	PL_P	$D574,decrunch
	PL_P	$14b9e,Protection
	PL_P	$17606,Load2
	PL_R	$25f7e		; fake exec
	PL_W	$c4c4,$6006
	
	; copperlist color correction
	PL_AW	$1545a,$200
	PL_AW	$15286,$200
	PL_AW	$15312,$200
	PL_AW	$154e6,$200
	PL_AW	$155ee,$200
	PL_AW	$15d7e,$200
	
	PL_PSS	$d00e,WaitBlit_2,2
	PL_PSS	$d0e2,WaitBlit_2,2
	PL_P	$ceb0,WaitBlit_3

	PL_PS	$e8b0,WaitBlit_1
	PL_PS	$d984,WaitBlit_1

	PL_IFC2
	PL_PSS	$d694,read_joy_2_button,4
	PL_ELSE
	PL_PSS	$d694,read_joy_joystick,4
	PL_ENDIF
	PL_PS	$c846,wait_for_pause_release
	PL_PS	$c8bc,wait_for_pause_release
	PL_PS	$c8b0,test_unpause
	PL_PSS	$c860,test_unpause_2,2
	
	PL_IFC1
	PL_B $dc32,$4A
	PL_B $de46,$4A
	PL_B $1b4e,$4A
	PL_B $dad2,$4A
	PL_ENDIF
	
	; remove some damn SMC code that zap some patches
	PL_NOP	$0000CC2E,8
	PL_NOP	$0001A83E,10
	PL_NOP	$0001ACE0,10
	
	PL_END
	
test_unpause
	bsr	set_z_on_play_released_and_out
	CMPI.B	#$40,keycode(A5)		;0c8b0: 0c2d004001bf
	rts

	
test_unpause_2
	bsr	set_z_on_play_released_and_out
	BTST	#7,$BFE001		;0c860: 0839000700bfe001
	rts

	
wait_for_pause_release
	bsr	set_z_on_play_released_and_out
	CMPI.B	#$c0,keycode(A5)		;0c846: 0c2d00c001bf
.out
	rts
	
	
set_z_on_play_released_and_out
	movem.l	d0,-(a7)
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	movem.l	(a7)+,d0
	beq.b	.out
	; wait for pause released
	movem.l	d0,(a7)		; not a typo, we want to pop the stack up
.wait
	bsr	_read_joystick_port_1
	btst	#JPB_BTN_PLAY,d0
	bne.b	.wait
	movem.l	(a7)+,d0
	; set Z flag
	cmp.b	d0,d0
.out
	rts
	
read_joy_2_button
	bsr	read_joy
; replace joystick UP by 2nd button
	movem.l	d1/a0,-(a7)
	move.l	buttons_state(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
;	move.l	_GameAddress(pc),a0
;	cmp.b	#7,$4813(a0)		; project-F ? don't do anything
;	beq.b	.no_blue
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
	movem.l	(a7)+,d1/a0
	RTS	

read_joy:
	MOVEM.L	D0-D1/A0-A1,-(A7)		;1e6: 48e700c0
	lea previous_buttons_state(pc),a1
	lea	buttons_state(pc),a0
	move.l	(a0),(a1)
	bsr	_read_joystick_port_1
	move.l	d0,(a0)
	; here work with raw button state not delta
	; else combination doesn't work
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.norev
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	btst	#JPB_BTN_PLAY,d0
	bne.b	.quit
	btst	#JPB_BTN_GRN,d0
	beq.b	.noesc
	; esc
	move.B	#$45,keycode(A5)
.noesc
	
	; we can change weapons from here, using shoulder buttons
	move.l	previous_buttons_state(pc),d1
	not.l	d1
	; keep the bits that just changed in d0
	and.l	d1,d0
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nofwd
	cmp.b	#6,weapon_type(A5)
	bne.b	.nowrapfwd
	move.b	#$FF,weapon_type(A5)
.nowrapfwd
	add.b	#1,weapon_type(A5)
	jsr	$0c6f6
.nofwd

	tst.b	weapon_type(A5)
	bne.b	.nowraprev
	move.b	#7,weapon_type(A5)
.nowraprev
	sub.b	#1,weapon_type(A5)
	jsr	$0c6f6
.norev
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause
	; spacebar: pause
	move.B	#$40,keycode(A5)
.nopause

	MOVEM.L	(A7)+,D0-D1/A0-A1		;216: 4cdf0300
	; original code
    AND.B #$10,(A5,$01bd)
	rts
.quit:
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
read_joy_joystick:
	bsr	read_joy
 	; original code
    MOVE.W (A6,$000c),D0
	rts
	
fix_blitwaits:
	MOVEM.L	A0-A1,-(A7)		;1e6: 48e700c0
	LEA	$E950,A0		;1ea: 41f90000e950
	LEA	$EA70,A1		;1f0: 43f90000ea70
LAB_0005:
	ADDQ.L	#2,A0			;1f6: 5488
	CMPI.W	#$33c6,(A0)		;1f8: 0c5033c6
	BNE.S	LAB_0006		;1fc: 6614
	CMPI.L	#$00dff058,2(A0)	;1fe: 0ca800dff0580002
	BNE.S	LAB_0006		;206: 660a
	MOVE.W	#$4eb9,(A0)+		;208: 30fc4eb9
	PEA	WaitBlit_4(PC)		;20c: 487a002a
	MOVE.L	(A7)+,(A0)+		;210: 20df
LAB_0006:
	CMPA.L	A0,A1			;212: b3c8
	BNE.S	LAB_0005		;214: 66e0
	MOVEM.L	(A7)+,A0-A1		;216: 4cdf0300
	RTS				;21a: 4e75

WaitBlit_1:
	MOVE.W	D0,BLTSIZE		;21c: 33c000dff058
	BRA.S	_waitblit		;222: 601a
WaitBlit_2:
	MOVE.W	#$0c01,BLTSIZE		;224: 33fc0c0100dff058
	BRA.S	_waitblit		;22c: 6010
WaitBlit_3:
	MOVE.W	#$7f95,BLTSIZE		;22e: 33fc7f9500dff058
	BRA.S	_waitblit		;236: 6006
WaitBlit_4:
	MOVE.W	D6,BLTSIZE		;238: 33c600dff058
_waitblit:
	BTST	#6,DMACONR		;23e: 0839000600dff002
	BNE.S	_waitblit		;246: 66f6
	RTS				;248: 4e75

Protection:
	ST	472(A5)			;24a: 50ed01d8
	MOVE.B	#$01,$16A28		;24e: 13fc000100016a28
	RTS				;256: 4e75

Load
		sf	$18(A5)

		moveq	#0,D0
		move.w	D2,D0
		mulu	#512,D0

		moveq	#1,D2

		bsr.w	_LoadDisk

		lea	Var(pc),A0
		cmp.w	#3,(A0)
		blt.b	skip
		cmp.w	#4,(A0)
		bgt.b	skip

		move.w	#150,D0
.wait		cmp.b	#$FF,$DFF006
		bne.b	.wait
.wait1		cmp.b	#$FF,$DFF006
		beq.b	.wait1
		dbf	d0,.wait
skip
		addq.w	#1,(A0)

		st	$18(A5)

		movem.l	(A7)+,d0-a6
		rts

Var		dc.w	0

Load2
		movem.l	d0-a6,-(a7)

		move.l	D0,A0
		moveq	#0,D0
		move.w	D2,D0
		mulu	#512,D0

		moveq	#1,D2
		tst.b	$1E0(A5)
		bne.b	.skip
		moveq	#2,D2
.skip
		bsr.w	_LoadDisk

		movem.l	(A7)+,d0-a6
		rts

SetColor
		moveq	#0,D0
		moveq	#0,D1
		move.b	(A0)+,D0
		lsl.w	#4,D0
		rts

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts
_resload:
	dc.l	0

buttons_state
	dc.l	0
previous_buttons_state
	dc.l	0
	
