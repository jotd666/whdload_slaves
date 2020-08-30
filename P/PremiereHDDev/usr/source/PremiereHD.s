; Premiere slave by JOTD
;


	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	hardware/custom.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	Premiere.slave

	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"3.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


;DEBUG = 1

	IFND	DEBUG
USE_FASTMEM
	ENDC

	IFD	USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $82000
	ELSE
CHIPMEMSIZE = $110000
EXPMEMSIZE = $0000
	ENDC
	
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config:
	dc.b    "C1:X:Trainer infinite lives energy and ammo:0;"			
	dc.b    "C2:X:2nd button jump:0;"			
	dc.b    "C3:X:Start with sfx by default:0;"			
	dc.b    "C4:L:Start level:Western,Not so fast Pardner,Aegypt,Don t stain the train,Horror,"
	dc.b	"Which way to turn ?,Cartoon,A quick touchup,Space,What s big N black,Middle age,Err Hello?;"			
	dc.b	0
_data		dc.b	"data",0

_name		dc.b	"Premiere"
		IFD	DEBUG
		dc.b	" (DEBUG MODE)"
		ENDC
		dc.b	0
_copy		dc.b	"1992 Core Design",0
_info		dc.b	"installed & fixed by JOTD",10,10
		dc.b	"Press SPACE,/ or yellow+forward to skip levels",10,10
		dc.b	"Press reverse+forward to quit current level",10,10
		dc.b	"Press play+reverse+forward to quit to wb",10,10
		dc.b	"Version "
		DECL_VERSION
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
		dc.b	0


; version xx.slave works
loadername:
	dc.b	"loader.bin",0

	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	0

		even
BOOTADDRESS = $7D000

_start
	sub.l	a1,a1
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload
	
	
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)
	
	bsr	set_expmem
	
	bsr	_detect_controller_types

	lea	$700,a7

	;enable cache
	move.l	#WCPUF_Base_NCS|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)
	move.w	#$2700,SR

	; load the file with a shifted offset
	; (so no need to copy there)
	lea	BOOTADDRESS,A1
	lea	loadername(pc),A0
	jsr	resload_LoadFile(a2)

	; *** original CD32 patches

	lea	pl_boot(pc),a0
	lea	BOOTADDRESS,a1
	jsr	resload_Patch(a2)
	jmp	BOOTADDRESS+$1A
	;get tags
	;lea	(_tag,pc),a0
	;jsr	(resload_Control,a2)


pl_boot:
	PL_START
	PL_W	$776,$601E
	PL_PS	$31A,PatchIntro
	;;PL_P	$21DE,RNCDecrunch
	PL_P	$666,ReadFile
	PL_PS	$07E,PatchVects
	PL_W	$084,$605A
	PL_P	$568-$150,PatchGame
	
	
	; original CD32 patches / crack?
	PL_NOP	$228-$150,8
	PL_NOP	$4A0-$150,8
	PL_NOP	$1DA-$150,8

	; fix copperlist
	;;PL_PSS	$44,install_boot_copperlist,4
	PL_W	$452,$200	; bplcon0 COLOR bit
	PL_W	$48E,$200	; bplcon0 COLOR bit
	PL_END
	
;install_boot_copperlist	
	;blitz
;	move.l	#$7D43C,$DFF080
;	rts
	
PatchIntro:
	movem.l	d2-a6,-(a7)
	lea	pl_intro(pc),a0
	lea	$1000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d2-a6
	jmp	$1000.W

ReadFile:
	movem.l	d2-a6,-(a7)
	move.l	a0,a4	; destination
	move.l	a1,a3	; name
	move.l	a1,a0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	move.l	d0,d2	; store size
	
	move.l	a4,a1	; destination
	move.l	a3,a0	; name
	jsr	resload_LoadFile(a2)
	
	move.l	d2,d1	; size
	moveq.l	#0,d0	; no error
	movem.l	(a7)+,d2-a6

	rts
	
PatchVects:
	move.w	#$2100,SR
	move.l	_expmem(pc),$7D436
	rts	
	
pl_intro
	PL_START
	PL_W	$2B48,$200	; bplcon0 COLOR bit
	PL_L	$736,$DFF17E	; shift by 2 bytes to fix palette clear error
	PL_P	$418,RNCDecrunch
	PL_END
	
; change expansion memory if chip only
set_expmem
	movem.l	a0,-(a7)
	lea	_expmem(pc),a0
	IFND	USE_FASTMEM
	move.l	#$80000,(a0)
	ELSE
	add.l	#$1000,(A0)
	ENDC
	movem.l	(a7)+,a0
	
	rts


kbint:
	move.b	$BFEC01,D0
	move.l	D0,-(sp)
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here

	cmp.b	_keyexit(pc),D0
	beq	quit
.noquit
	move.l	(sp)+,D0
	rts
quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


wait_blit:
	BTST	#6,dmaconr+$DFF000
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts


PatchGame:
	move.l	_expmem(pc),A0
	move.w	_start_level+2(pc),($10E,a0)	; set start level
	movem.l	d0-a6,-(a7)

	
	move.l	_expmem(pc),A1
	move.l	_resload(pc),a2
	lea		pl_main(pc),a0
	jsr	resload_Patch(a2)

	
;;;	move.b	#$7F,$BFD100			; stops drive light
	movem.l	(a7)+,d0-a6

	jmp	(A0)
	; *** offsets
pl_main
	PL_START
	PL_P	$1476C,ReadFile
	PL_L	$13FEC,$60000098  ; original CD32 (maybe RN copy protection)
	PL_PS	$103E8,kbint
	PL_P	$13DCA,RNCDecrunch  ; fast decrunch

	; *** original game fixes from CD32 release (floppy stuff)

	PL_R	$148A8
	PL_R	$147E8
	PL_R	$147F0
	PL_R	$14880
	PL_R	$1466E

	PL_IFC1
	; *** trainer
	PL_NOP	3550,6
	PL_B	3556,$60
	PL_ENDIF
	
	PL_IFC3
	; sfx default
	PL_B	$113d7,1
	PL_ENDIF
	
	PL_PSS	$9c24,check_for_pause,2
	PL_PSS	$9c94,check_for_pause_release,6
	
	PL_PSS	$137C,read_controls_menu,2
	PL_PSS	$269e,read_controls_game,4
	
	; activates levelskip with spacebar (trainer)
	; original levelskip was active with / on keypad :)
	
	PL_PSS	$c02,test_levelskip,2
	
	; makes it so 2nd button jumps, not "up"
	PL_IFC2
	PL_PSS	$53d8,joyup_next_to_ladder,6
	PL_PS	$26C4,game_joytest
	PL_PSS	$53e4,jump_with_button_only,2
	PL_P	$48AC,enter_door_test
	PL_PS	$B33C,read_controls_train_level
	PL_ENDIF
	
	PL_IFC1
	; remove sub energy in A LOT of places
	PL_NOP	$4690,6
	PL_NOP	$4826,6
	PL_NOP	$741e,6
	PL_NOP	$d5dc,6
	PL_NOP	$dc08,6
	PL_NOP	$dd36,6
	PL_NOP	$de64,6
	PL_NOP	$e246,6
	PL_NOP	$e646,6
	PL_NOP	$e712,6
	PL_NOP	$ecf2,6
	PL_NOP	$f00e,6
	PL_NOP	$f108,6
	PL_NOP	$f244,6
	PL_NOP	$f3fe,6	
	PL_NOP	$0dde,6		; infinite lives
	; ammo
	PL_NOP	$799e,6
	PL_NOP	$800a,6
	PL_NOP	$85de,6
	PL_NOP	$8ab0,6
	PL_NOP	$8f7a,6
	PL_NOP	$95b6,6
	PL_W	$0188,10	; 10 ammo at start
	PL_ENDIF
	
	; blitter waits
	PL_PSS	$1d2e,wait_blit,2
	PL_PSS	$1d60,wait_blit,2
	PL_PSS	$1d82,wait_blit,2
	PL_PSS	$1da4,wait_blit,2
	PL_PSS	$1dc6,wait_blit,2
	PL_PSS	$1e64,wait_blit,2
	PL_PSS	$1eaa,wait_blit,2
	PL_PSS	$1ed4,wait_blit,2
	PL_PSS	$1efe,wait_blit,2
	PL_PSS	$1f28,wait_blit,2
	PL_PSS	$2988,wait_blit,2
	PL_PSS	$29f0,wait_blit,2
	PL_PSS	$2a0a,wait_blit,2
	PL_PSS	$2a26,wait_blit,2
	PL_PSS	$2a40,wait_blit,2
	PL_PSS	$2a5c,wait_blit,2
	PL_PSS	$2a76,wait_blit,2
	PL_PSS	$2a92,wait_blit,2
	PL_PSS	$2aac,wait_blit,2
	PL_PSS	$2ac8,wait_blit,2
	PL_PSS	$2ae2,wait_blit,2
	PL_PSS	$2b86,wait_blit,2
	PL_PSS	$2bde,wait_blit,2
	PL_PSS	$2bf8,wait_blit,2
	PL_PSS	$2c14,wait_blit,2
	PL_PSS	$2c2e,wait_blit,2
	PL_PSS	$2c4a,wait_blit,2
	PL_PSS	$2c64,wait_blit,2
	PL_PSS	$2c80,wait_blit,2
	PL_PSS	$2c9a,wait_blit,2
	PL_PSS	$2cb6,wait_blit,2
	PL_PSS	$2cd0,wait_blit,2
	PL_PSS	$2d40,wait_blit,2
	PL_PSS	$2db2,wait_blit,2
	PL_PSS	$2dcc,wait_blit,2
	PL_PSS	$2de6,wait_blit,2
	PL_PSS	$2e02,wait_blit,2
	PL_PSS	$2e1c,wait_blit,2
	PL_PSS	$2e36,wait_blit,2
	PL_PSS	$2e52,wait_blit,2
	PL_PSS	$2e6c,wait_blit,2
	PL_PSS	$2e86,wait_blit,2
	PL_PSS	$2ea2,wait_blit,2
	PL_PSS	$2ebc,wait_blit,2
	PL_PSS	$2ed6,wait_blit,2
	PL_PSS	$2ef2,wait_blit,2
	PL_PSS	$2f08,wait_blit,2
	PL_PSS	$2f1e,wait_blit,2
	PL_PSS	$318e,wait_blit,2
	PL_PSS	$31e6,wait_blit,2
	PL_PSS	$321a,wait_blit,2
	PL_PSS	$324e,wait_blit,2
	PL_PSS	$3274,wait_blit,2
	PL_PSS	$3334,wait_blit,2
	PL_PSS	$338c,wait_blit,2
	PL_PSS	$33c0,wait_blit,2
	PL_PSS	$33f4,wait_blit,2
	PL_PSS	$3428,wait_blit,2
	PL_PSS	$352c,wait_blit,2
	PL_PSS	$3560,wait_blit,2
	PL_PSS	$3594,wait_blit,2
	PL_PSS	$35c8,wait_blit,2
	PL_PSS	$35fc,wait_blit,2
	PL_PSS	$37d2,wait_blit,2
	PL_PSS	$3806,wait_blit,2
	PL_PSS	$3822,wait_blit,2
	PL_PSS	$383e,wait_blit,2
	PL_PSS	$385a,wait_blit,2
	PL_PSS	$390a,wait_blit,2
	PL_PSS	$393e,wait_blit,2
	PL_PSS	$395a,wait_blit,2
	PL_PSS	$3976,wait_blit,2
	PL_PSS	$3992,wait_blit,2
	PL_PSS	$3a50,wait_blit,2
	PL_PSS	$3a6c,wait_blit,2
	PL_PSS	$3a88,wait_blit,2
	PL_PSS	$3aa4,wait_blit,2
	PL_PSS	$3ac0,wait_blit,2
	PL_PSS	$9e6e,wait_blit,2
	PL_PSS	$a000,wait_blit,2
	
	; snoop bugs
	
	PL_PSS	$1346,fix_copperlist_1,2
	PL_PS	$1375A,fix_copperlist_2
	PL_PS	$C90,fix_copperlist_3
	PL_END

fix_copperlist_1:
	move.w	#$200,$7876	; color bit
	MOVE.L	#$0000781c,128(A6)	;81346: 2d7c0000781c0080
	rts
	
fix_copperlist_2:
	lea	$7960,a0
	move.w	#$200,($16,a0)	; color bit
	rts
	
fix_copperlist_3:
	lea	$75D0,a0
	move.w	#$200,($A66-$5D0,a0)	; color bit
	move.w	#$200,($6A6-$5D0,a0)	; color bit
	rts
;
; stance states:
; $00: standing
; $02: jumping
; ... various states on ladder (turning left/right)
; $0C: arms crossed
; $12: climbing up ladder
; $24: climbing down ladder
; $36: entering door
; $38: exiting door (entering the other side)

game_joytest:
	; check button first
	movem.l	d0/a0,-(a7)
	move.l	_expmem(pc),a0
	add.l	#$113C0,a0
	cmp.l	#$12,(a0)	; climbing up ladder already?
	beq.b	.ignore_button
	cmp.l	#$24,(a0)	; climbing down ladder already?
	beq.b	.ignore_button
	; other cases: test button
	move.l	joystick_state(pc),d0
	btst	#JPB_BTN_BLU,d0
.ignore_button
	movem.l	(a7)+,d0/a0
	bne.b	.out		; pressed: set flag like UP
	; original code
	EOR.W	D0,D1			;826c4: b141
	BTST	#8,D1			;826c6: 08010008
.out
	RTS

enter_door_test:
	movem.l	d0,-(a7)
	move.l	joystick_state(pc),d0
	btst	#JPB_BTN_UP,d0
	movem.l	(a7)+,d0
	beq.b	.noup
	; if this was reached it means that up was pressed
	; set player stance to $36 like original game
	movem.l	a0,-(a7)
	move.l	_expmem(pc),a0
	add.l	#$10000,a0
	; stolen code
	MOVE.L	#$36,$13c0(a0)
	MOVE.W	#$000a,$1472(a0)
	MOVE.W	#$0001,$14ca(a0)
	movem.l	(a7)+,a0
.noup:
	rts
	
test_levelskip
	; check button first
	movem.l	d0,-(a7)
	; test buttons
	move.l	joystick_state(pc),d0
	btst	#JPB_BTN_YEL,d0
	beq.b	.no_skip
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.no_skip
	; skip level
	add.l	#$c36-$c08,4(a7)
.no_skip
	movem.l	(a7)+,d0
	rts
	
read_controls_menu
	movem.l	d0/a0/a1,-(a7)
	lea	previous_joy_state(pc),a1
	move.l	_expmem(pc),a0
	add.l	#$13514,a0
	moveq.l	#1,d0
	bsr	_read_joystick
	and.l	#JPF_BTN_BLU|JPF_BTN_YEL|JPF_BTN_GRN|JPF_BTN_PLAY,d0
	cmp.l	(a1),d0
	beq.b	.out	; same output as before
	move.l	d0,(a1)	; store old output
	beq.b	.out
	move.b	#$20,(a0)
.out
	
	cmp.b	#$20,(a0)		; original test for space in menu
	movem.l	(a7)+,d0/a0/a1
	rts
	
check_for_pause

	movem.l	d0/a0,-(a7)

	move.l	_expmem(pc),a0
	add.l	#$13514,a0
	move.l	joystick_state(pc),d0
	btst.l	#JPB_BTN_PLAY,d0
	beq.b	.out
	move.b	#$50,(a0)
.out
	cmp.b	#$1B,(a0)		; ESC ASCII code
	beq.b	.esc
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
.esc
	clr.b	(a0)	; cancel ESC
	; flag for death & one life to quit game
	move.l	_expmem(pc),a0
	add.l	#$11506,a0
	move.w	#1,(a0)
	move.l	_expmem(pc),a0
	add.l	#$114fa,a0
	clr.w	(a0)	; no life
	move.l	_expmem(pc),a0
	add.l	#$114f8,a0
	clr.w	(a0)	; no energy
	move.l	_expmem(pc),a0
	add.l	#$13514,a0
	
.noesc
	cmp.b	#$50,(a0)		; original test for pause
	movem.l	(a7)+,d0/a0
	rts
	
check_for_pause_release
	movem.l	d0/a0,-(a7)
	; wait for button release
.loop
	moveq.l	#1,d0
	bsr	_read_joystick
	; pause? or quit to WB?
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	btst	#JPB_BTN_FORWARD,d0
	bne	quit
.noquit
	btst.l	#JPB_BTN_PLAY,d0
	bne.b	.loop
	
	move.l	#$100,d0
	bsr	beamdelay
	
	move.l	_expmem(pc),a0
	add.l	#$13514,a0
	moveq.l	#1,d0
	bsr	_read_joystick
	btst.l	#JPB_BTN_PLAY,d0
	beq.b	.out
	; wait button release
.loop2
	moveq.l	#1,d0
	bsr	_read_joystick
	btst.l	#JPB_BTN_PLAY,d0
	bne.b	.loop2

	move.b	#$50,(a0)
.out
	movem.l	(a7)+,d0/a0
	rts



jump_with_button_only:
	movem.l	d0/a0,-(a7)
	move.l	joystick_state(pc),d0
	btst	#JPB_BTN_BLU,d0
	beq.b	.nojump
	move.l	_expmem(pc),a0
	add.l	#$1140E,a0
	MOVE.W	#$fff9,(a0)		; original program
	movem.l	(a7)+,d0/a0
	rts
.nojump
	movem.l	(a7)+,d0/a0
	addq.l	#4,a7	; return directly, do nothing
	rts

joyup_next_to_ladder:
	movem.l	d0,-(a7)
	move.l	joystick_state(pc),d0
	btst	#JPB_BTN_UP,d0
	movem.l	(a7)+,d0
	beq.b	.joyup
	; if this was reached it means that blue button was pressed
	; set player stance to $12 like original game
	movem.l	a0,-(a7)
	move.l	_expmem(pc),a0
	add.l	#$113c0,a0
	MOVE.L	#$12,(a0)
	movem.l	(a7)+,a0
	add.l	#$416-$3DE,(a7)	; emulates bra to skip jump
	rts
.joyup
	rts		; returns to jump part
	
read_controls_game:
	moveq.l	#1,d0
	bsr	_read_joystick
	lea	joystick_state(pc),a6
	move.l	d0,(a6)
	lea	_custom,a6		; original
	MOVE.W	12(A6),D0
	rts
	
read_controls_train_level:
	; original
	MOVE.W	12(A6),D0		;8b33c: 302e000c
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	movem.l	d1,-(a7)
	move.l	joystick_state(pc),d1
	btst	#JPB_BTN_BLU,d1
	movem.l	(a7)+,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:
	MOVE.W	D0,D1			;8b340: 3200
	RTS

	
RNCDecrunch
	movem.l	d0-d1/a0-a3,-(a7)
	IFD	DECRUNCH_BUG
	move.l	_expmem(pc),a3
	add.l	#$60000,a3
	cmp.l	a3,a0
	bne.b	.okay
	; decrunching a $20000-size buffer in $E0000
	; needs slightly more than $20000 bytes
	; so I'll decrunch it in $30000 where there's room
	; (nothing in $50000 so far)
	lea	$30000,a1
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)
	; then will move it back
	move.l	#$7FFF,d0
	lea	$30000,a1
.copy
	move.l	(a1),(a3)+
	clr.l		(a1)+	; clear temp memory
	dbf		d0,.copy
	bra.b	.out
.okay
	ENDC
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)
.out
	movem.l	(a7)+,d0-d1/a0-a3
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


_resload
	dc.l	0

_tag		
	dc.l	WHDLTAG_CUSTOM4_GET
_start_level	dc.l	0
	dc.l	0
joystick_state
	dc.l	0
previous_joy_state
	dc.l	0
	
	
	include ReadJoyPad.s
	