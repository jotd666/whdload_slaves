
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"RoadRash.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;DEBUG
;FILERIP
;BW

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
	IFND DEBUG
		dc.w	17			;ws_Version
	ELSE
		dc.w	18			;ws_Version
	ENDC
		dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_EmulDivZero;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	Start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug = F9
_keyexit	dc.b	$5F;ws_keyexit = help
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"Road Rash",0
_copy		dc.b	"1992 Electronic Arts",0
_info		dc.b	"Adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_data		dc.b	"data",0
_config
	dc.b	"C1:L:password:none,level 1 Diablo 1000 big money,Millions of dollars and level 4,"
	dc.b	"PANDA 600,BANZAI 750,KAMIKAZE 750,SHURIKEN 1000,FERRUCI 850,PANDA 750,DIABLO 1000;"
	
	dc.b	0
	EVEN
	include	ReadJoyPad.s
	
;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	$7FF00,a7
		MOVE	#$2700,SR
		
		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		move.l	a0,a2			;A2 = resload
		
		lea	_tags(pc),a0
		jsr	(resload_Control,a2)
		
		;get password
		lea	(_user_password,pc),a0
		moveq.l	#0,d1
		move.l	#24,d0
		jsr	(resload_GetCustom,a2)
		
		lea	_boot(pc),a0
		lea	$400.W,a1
		move.l	a1,a3
		jsr	(resload_LoadFileDecrunch,a2)

		lea	_pl_boot(pc),a0
		sub.l	a1,a1
		jsr	(resload_Patch,a2)
		
		move.l	expansion_memory(pc),A0	; expansion start
		move.l	A0,D0	; and size

		jmp	(a3)
		

_pl_boot	PL_START
	PL_P	$496A,PatchLoader2

	; *** patches the 1st disk routine

	PL_P	$4DCA,ReadSomeFile

	; *** patches some exec shit
;;	PATCHUSRJMP	$12BA4,MoveD0_1

	; *** patches a prog

	PL_PS	$4800,PatchIntro1

	; *** patches another prog

	PL_PS	$4844,PatchIntro2
	PL_END

PatchIntro1:
	; fixes execbase access (maybe for protection...)
	movem.l	d0-d1/a1-a2,-(a7)
	lea	pl_intro_1(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a1-a2

	move.l	$4C98.W,A0
	rts
	
pl_intro_1:
	PL_START
	PL_R	$12BAE
	PL_END
	
PatchIntro2:
	movem.l	d0-d1/a1-a2,-(a7)
	lea	pl_intro_2(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a1-a2
	
	move.l	$4C98.W,A0
	rts
	
pl_intro_2:
	PL_START
	PL_P	$8E58,ReadSomeFile
	PL_P	$8CDA,MoveD0_2
	PL_END


	
;MoveD0_1:
;	move.w	#$FC77,D0
;	rts

MoveD0_2:
	move.w	#$395,D0
	rts
	
last_key_pressed_offset = $2e969
keytable_offset = $2E868

PatchLoader2:
	; detect controllers now, leaving time for the user
	; to plug proper pads
	move.l	expansion_memory(pc),a1

	movem.l	d0-d1/a0-a2,-(a7)
	add.l	#$580,a1
	move.w	#24,D1
	bsr	_detect_controller_types
	lea	_user_password(pc),a0
	tst.b	(a0)
	beq.b	.no_user_password
	subq	#1,d1
.copy_user
	move.b	(a0)+,(a1)+
	dbf	d1,.copy_user
	bsr	.custom_pass
	bra.b	.nopass
.no_user_password	
	move.l	_password(pc),d0
	beq.b	.nopass
	lea	password_data(pc),a0
	subq.l	#1,d0
	mulu.w	d1,D0
	subq.l	#1,d1

	add.l	d0,a0
	cmp.l	password_data_end(pc),a0
	bcc.b	.nopass	; out of range
.copy
	move.b	(a0)+,(a1)+
	dbf	d1,.copy
	bsr	.custom_pass
.nopass
	; change messages if joypad is plugged in
	move.l	expansion_memory(pc),a1
	lea	pl_main(pc),a0
	move.b	controller_joypad_1(pc),d0
	beq.b	.nopad
	lea	pl_messages_main(pc),a0	
.nopad
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	(a1)
	
.custom_pass
	move.l	expansion_memory(pc),a1
	lea	pl_password(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	rts
	
	; skip copy default password so we can install passwords
pl_password
	PL_START
	PL_S	$22E,$36-$2E
	PL_END
	
	; change function keys by pad buttons
pl_messages_main
	PL_START
	PL_STR	$2B3F,<rev for >
	PL_STR	$2B81,<fwd to turn >
	PL_STR	$2BC7,<blue>
	PL_STR	$2C30,<green to select >
	PL_STR	$2C74,<yellow to>
	PL_STR	$2CB9,<rev+fwd during>
	PL_STR	$2F45,<blue>
	PL_STR	$2FCB,<fwd to check >
	PL_STR	$303A,<blue>
	PL_STR	$2537,<Press blue to >
	; *** install joypad handler for menu
	; pretty useless for joystick only
	; on the other hand, with joypad, we can get rid
	; of keyboard!
	PL_PSS	$52,menu_control_loop,4

	PL_NEXT	pl_main
	
pl_main
	PL_START

	
	; *** pause
	PL_PSS	$72B4,test_for_pause,2
	
	; *** removes password protection
	PL_L	$331A4,$600000A8   ; no check for correct answer
	PL_NOP	$3319C,2	   		; no need to press return

	; *** sets the kbint patch

	PL_PS	$2E9D8,kbint

	; *** patches the 2nd disk routine

	PL_P	$2DF82,ReadSomeFile

	; *** remove the 'insert disk 2'
	PL_NOP	$2F116,2
	PL_END
	

FUNCTION_KEYPRESS:MACRO
	btst	#JPB_BTN_\1,d0
	beq.b	.no\1
	st.b	(\2,a0)
	bra.b	.out\1
.no\1
	clr.b	(\2,a0)
.out\1
	ENDM
	
test_for_pause
	movem.l	d0-d1/a0,-(a7)
	move.l	expansion_memory(pc),a0
	add.l	#last_key_pressed_offset,a0
	
	moveq.l	#1,d0
	bsr	_read_joystick
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause
	move.B	#$40,(a0)		;072b4: 0c3900400002e969
.wr
	bsr	_read_joystick
	btst	#JPB_BTN_PLAY,d0
	bne.b	.wr
	
.nopause
	movem.l	(a7)+,d0-d2/a0

	CMPI.B	#$40,(a0)		;072b4: 0c3900400002e969
	rts
	
menu_control_loop:
	BTST	#3,D1			;00052: 08010003
	BEQ.S	.out		;00056: 6704
	ORI.B	#$08,D0			;00058: 00000008
.out
	movem.l	d0-d3/a0-a2,-(a7)
	move.l	expansion_memory(pc),a2
	add.l	#last_key_pressed_offset,a2
	move.l	previous_button_state(pc),d3
	lea	backflag(pc),a0
	tst.b	(a0)
	beq.b	.noback
	subq.b	#1,(a0)
	bne.b	.noback

	move.b	#$4F,(a2)
	move.l	d3,d0
	bra	.noprevletter
.noback
	lea	keytable_offset,a0
	add.l	expansion_memory(pc),a0
	moveq.l	#1,d0
	bsr	_read_joystick
	FUNCTION_KEYPRESS	REVERSE,$50
	FUNCTION_KEYPRESS	FORWARD,$51
	FUNCTION_KEYPRESS	BLU,$52
	FUNCTION_KEYPRESS	GRN,$53
	FUNCTION_KEYPRESS	YEL,$54
	
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nof10
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nof10
	st.b	($59,a0)
	bra.b	.f10p
.nof10
	clr.b	($59,a0)
.f10p

	; cursor keys emulated by joystick
	btst	#JPB_BTN_UP,d0
	beq.b	.noup
	move.b	#$4C,(a2)
.noup
	btst	#JPB_BTN_DOWN,d0
	beq.b	.nodown
	move.b	#$4D,(a2)
.nodown
	btst	#JPB_BTN_LEFT,d0
	beq.b	.noleft
	move.b	#$4F,(a2)
.noleft
	btst	#JPB_BTN_RIGHT,d0
	beq.b	.noright
	move.b	#$4E,(a2)
.noright
	lea	current_pos(pc),a0
	lea	raw_table(pc),a1
	moveq	#0,d1
	
	btst	#JPB_BTN_FORWARD,d3
	bne.b	.nonextletter		; was pressed
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nonextletter

	addq.b	#1,(a0)
	move.b	(a0),d1
	tst.b	(a1,d1.w)
	bpl.b	.nofwrap
	clr.b	(a0)
	moveq	#0,d1
.nofwrap
	move.b	(a1,d1.W),(a2)
	bsr	.nexttimeback
.nonextletter
	btst	#JPB_BTN_REVERSE,d3
	bne.b	.noprevletter		; was pressed
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noprevletter

	; back one character
	tst.b	(a0)
	bne.b	.nofirst	; first count
.gotolast
	move.b	(a0),d1
	addq.b	#1,(a0)
	tst.b	(a1,d1.W)
	bpl.b	.gotolast
	subq.b	#1,(a0)
.nofirst
	subq.b	#1,(a0)
	move.b	(a0),d1
	move.b	(a1,d1.W),(a2)
	bsr	.nexttimeback
.noprevletter

	lea	previous_button_state(pc),a0
	move.l	d0,(a0)

	movem.l	(a7)+,d0-d3/a0-a2
	rts
.nexttimeback
	lea	backflag(pc),a0
	move.b	#2,(a0)
	rts

	
kbint:
	move.b	$BFEC01,D0
	move.l	D0,-(sp)
	ror.b	#1,D0
	not.b	D0
	
	cmp.b	_keyexit(pc),D0
	bne	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	move.l	(sp)+,D0
	rts	

password_data:
	dc.b	"00000  REDC0QNGM5  172SU"
    dc.b    "00000  01O00MTPN8  4NPBI"   ;To give millions of $ and level 4
    dc.b	"00000  00J00102VS  21JUD"   ;PANDA 600
    dc.b	"00000  00J01113BT  22KDP"   ;BANZAI 750
 ;       "00000 00R00 013VS 32RV4"   BANZAI 750
    dc.b	"00000  00S20117H5  33UV1"   ;KAMIKAZE 750
    dc.b	"00000  01421109G5  448VN"   ;SHURIKEN 1000
    dc.b	"00000  01420019G5  457VO"   ;FERRUCI 850
    dc.b	"00000  01S91OOEGJ  567HM"   ;PANDA 750
    dc.b	"00000  01S9010EGJ  576IK"   ;DIABLO 1000
password_data_end



; < A0: filename
; < A1: destination address
; > D0: 0 (ok)
; > D1: filesize (not returning that leads to strange bugs...)

ReadSomeFile:
	movem.l	a0-a2,-(sp)

	cmp.b	#':',3(A0)	; does the name mention xxx: ??
	bne	.skipdf0
	lea	$4(A0),A0	; skips 'DF0:'
	tst.b	(A0)
	beq	.exit

.skipdf0
	cmp.b	#'/',4(A0)	; does the name mention data/ ??
	bne	.skipdata
	lea	$5(A0),A0	; skips 'data/'

	movem.l	a1,-(a7)
	lea	locpla_name(pc),A1
	bsr	strcmp
	movem.l	(a7)+,a1
	tst.l	D0
	bne	.skipdata

	; *** trick to wait a bit during the fading
	; *** else the colors are fucked up

	move.l	#20000,D0
	bsr		beamdelay

.skipdata
	
	tst.b	(A0)		; end of file
	beq	.exit

	move.l	_resload(pc),a2
	movem.l	a0,-(a7)
	jsr	(resload_LoadFile,a2)
	movem.l	(a7)+,a0
	jsr	(resload_GetFileSize,a2)
	move.l	d0,d1
.exit
	moveq	#0,D0		; no problemo
	movem.l	(sp)+,a0-a2
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
	
; < a0: str1
; < a1: str2
; > d0: -1: fail, 0: ok

strcmp:
	movem.l	d1/a0-a1,-(A7)
.contstrcmpasm
	move.b	(A0)+,d0
	beq.s	.termstrcmpasm
	move.b	(A1)+,d1
	beq.s	.failstrcmpasm
	bsr.s	.letterstrcmpasm
	exg	d0,d1
	bsr.s	.letterstrcmpasm
	cmp.b	d0,d1
	bne.s	.failstrcmpasm
	bra.s	.contstrcmpasm

.termstrcmpasm
	tst.b	(A1)+
	bne.s	.failstrcmpasm
	moveq.l	#0,d0
	bra.s	.endstrcmpasm

.letterstrcmpasm
	cmp.b	#$60,d0
	bls.s	.letter1strcmpasm
	cmp.b	#$7a,d0
	bhi.s	.letter1strcmpasm
	sub.b	#$20,d0
.letter1strcmpasm
	rts

.failstrcmpasm
	moveq.l	#-1,d0
.endstrcmpasm
	movem.l	(A7)+,d1/a0-a1
	rts

current_pos:
	dc.b	0
backflag:
	dc.b	0
raw_table:
 	dc.b	$40	; space 
 	dc.b	$0A ; 0
 	dc.b	$01 ; 1
 	dc.b	$02 ; 2
 	dc.b	$03 ; 3
 	dc.b	$04 ; 4
 	dc.b	$05 ; 5
 	dc.b	$06 ; 6
 	dc.b	$07 ; 7
 	dc.b	$08 ; 8
 	dc.b	$09 ; 9
 	dc.b	$20	; A
 	dc.b	$35 ; B
 	dc.b	$33 ; C
 	dc.b	$22	; D
 	dc.b	$12	; E
 	dc.b	$23	; F
 	dc.b	$24	; G
 	dc.b	$25	; H
 	dc.b	$17	; I
 	dc.b	$26 ; J
 	dc.b	$27 ; K
 	dc.b	$28 ; L
 	dc.b	$37 ; M
 	dc.b	$36 ; N
 	dc.b	$18	; O
 	dc.b	$19	; P
 	dc.b	$10	; Q
 	dc.b	$13	; R
 	dc.b	$21	; S
 	dc.b	$14	; T
 	dc.b	$16	; U
 	dc.b	$34 ; V
 	dc.b	$11	; W
  	dc.b	$32 ; X
	dc.b	$15	; Y
 	dc.b	$31 ; Z
 	;dc.b	$39 ; .
 	;dc.b	$2A	; '
	dc.b	$FF
	

;======================================================================
_user_password:
	ds.b	26
_boot:
	dc.b	"lomain.ami",0
locpla_name:
	dc.b	"locpla.set",0
	cnop	0,4
_resload	dc.l	0		;address of resident loader
_tags
		dc.l	WHDLTAG_CUSTOM1_GET
_password		dc.l	0
	dc.l	0
	
previous_button_state
	dc.l	0
expansion_memory:
	dc.l	$80000
	
	IFD DEBUG
		dc.l	WHDLTAG_CUST_DISABLE,vposw
		dc.l	WHDLTAG_CUST_DISABLE,vhposw
	;	dc.l	WHDLTAG_CUST_DISABLE,copjmp1
	;	dc.l	WHDLTAG_CUST_DISABLE,copjmp2
	ENDC
		dc.l	0
