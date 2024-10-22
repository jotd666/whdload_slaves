;*---------------------------------------------------------------------------
;  :Program.	RuffNTumbleHD.asm
;  :Contents.	Slave for "RuffNTumble" from
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	RuffNTumble.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM
    IFD USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000
    ELSE
CHIPMEMSIZE = $100000
EXPMEMSIZE = $0
    ENDC
IGNORE_JOY_DIRECTIONS = 1

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	19		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
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

_config
        dc.b    "BW;"
        dc.b    "C2:B:use 2nd/blue button for jump;"
		dc.b	0
		even
		
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.8"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"Ruff'N'Tumble"
		dc.b	0
_copy		dc.b	"1994 Wonderkind/Renegade",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"CD32 controls by Earok:",10,10
		dc.b	"Menu: bwd enable options",10
		dc.b	"      buttons allow to enter codes",10
		dc.b	"      fwd toggles music",10,10
		dc.b	"Game: bwd+fwd quits game",10
		dc.b	"      bwd replays",10
		dc.b	"      play pauses",10,10
		
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	even
	
BASE_ADDRESS = $10000

;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	a0,a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

		lea	$7FF00,a7

		bsr	_detect_controller_types
		
        IFD USE_FASTMEM
        lea extbase(pc),a0
        move.l  _expmem(pc),(a0)
        ENDC
        
		; load & version check

		lea	BASE_ADDRESS,A0
		move.l	#$3000,D0		; offset
		move.l	#$1600,D1		; length
		moveq	#1,D2
		bsr	_loaddisk
		lea	BASE_ADDRESS,A0
		move.l	#$1600,d0
		jsr	resload_CRC16(a2)

		cmp.l	#$33CE,d0
		beq.b	.cont

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.cont
		lea	pl_boot(pc),a0
		lea	BASE_ADDRESS,A1
		jsr	resload_Patch(a2)
		
		lea	$100,a0
		move.l	#$80000,(a0)+	; expsize
		move.l	extbase(pc),(a0)+	; expbase
		move.l	#$80000,(a0)+	; expsize

		pea	patch_loader_1(pc)
		move.l	(a7)+,$BC.W

		sub.l	a6,a6
		moveq.l	#0,d4
		moveq.l	#0,d5
		jmp	BASE_ADDRESS+$E6

jump_50000:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	$50000,a1
	lea	pl_50000(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	JMP $00050000
	
pl_50000
	PL_START
	PL_W	$13AA,$4200
	PL_L	$13B4,$01fe0000		; nop to remove FMODE shit we don't need
	PL_END
	
pl_boot
	PL_START
	PL_P	$112,jump_50000
	; Rob read

	PL_P	$170,read_sectors

	; Copy protection

	PL_L	$774,$21FCBED7
	PL_L	$778,$B57D0110
	PL_R	$77C

	; Trap the loader

	PL_W	$16C,$4E4F
	PL_END


patch_loader_1
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_loader(pc),a0

	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	jmp	$804.W


pl_loader
	PL_START
    PL_PS   $A8E,read_fire
    PL_S    $A8E+6,$AB2-$A8E-6  ; skip useless/potentially harmful cia code
	PL_IFC2
	PL_P	$B00,read_2nd_button
	PL_ENDIF
    PL_IFBW
    PL_PS   $D56,wait_button
    PL_ENDIF
	PL_P	$F64,read_sectors
	PL_PS	$948,kbint
	PL_PS	$96E,kback
	PL_W	$974,$6018
	PL_B	$8DF,$1F	; fix BTST.B $DFF01E!!
	PL_PS	$906,inside_vbi
	PL_P	$14F0,decrunch_and_patch

	PL_PS	$C52,main_hook
	PL_NOP	$838,4		; remove fmode write
    
    
	PL_END

; this routine replaces a mess, reading bit 6 and doing nothing with it
; then writing in the port direction register...
read_fire:
    movem.l d0,-(a7)
    move.l current_joypad_input(pc),d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    EORI    #4,CCR      ; invert Z flag
    rts
    
    
wait_button:
    MOVEA.L $00003958.W,A5
.loop
    btst    #7,$BFE001
    bne.b   .loop
    rts
    
main_hook:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_main(pc),a0

	move.l	d0,a1	; expansion
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	
	ADD.L #$0000dfd8,D0	; orig
	rts
	
pl_main
	PL_START
	PL_PS	$D9B2,set_copper_menu
	PL_END
	
set_copper_menu:
	move.l	#$01fe0000,$410C
	move.w	#$5200,$411E
	move.l	d0,$DFF080
	rts

CODE_LOCATION = $0008E49C

TEST_BUTTON:MACRO
	btst #\1,d0	
	beq .no_\1_\3
	btst	#\1,d1
	; was already pressed: do nothing
	bne.b	.\1_\3_out
	clr.b	\2
	bra.b	.\1_\3_out
.no_\1_\3
	btst	#\1,d1
	beq.b	.\1_\3_out
	; was pressed, released
	ST.B	\2  ;Reset		
.\1_\3_out
	ENDM
	
inside_vbi:
	addq.l	#1,$399E.W	; original code
 ;   btst    #0,$399E.W
 ;   beq.b   .ok
 ;   rts
;.ok
	movem.l	D0-D1/A0,-(A7)
	moveq	#1,d0
	bsr	_read_joystick
    lea current_joypad_input(pc),a0
    move.l  d0,(a0)

	lea	button_2_pressed(pc),a0 ; a0 will be used later in the routine
	clr.w	(a0)

	move.b	controller_joypad_1(pc),d1
	beq	.nojoypad
	
	move.l	previous_joypad_input(pc),d1

	; read the cd32 joypad
	; note that this routine could read a standard 2 button joystick
	; but what the use since none of the options above would work?

	;Erik Ruff N Tumble hack
	;Are we in the menu?
	;This is just a stupid check to see if a string exists and has an exact sequence of four characters (this string is overwritten when opening the main game)
	cmp.l #$72207661,$0008E4AC
	bne .InGame
	
    ; clear ESC from previous play else FWD+BWD is permanent
    st.b   $3CC9
    
	;It seems that when pressing a key on the keyboard, the rawkey value is mapped to the equivalent ASCII, and then a byte in a table is cleared and then set again.
	;I probably should only be setting the byte back to $FF after a the button has been lifted rather than all of the time.
	; JOTD: just done that :)
	
	TEST_BUTTON	JPB_BTN_FORWARD,$3CC5,menu
	TEST_BUTTON	JPB_BTN_REVERSE,$3CC7,menu
    
	btst #JPB_BTN_REVERSE,d0
	beq .noreset
	Move.l #$30303030,CODE_LOCATION	;no code

.noreset

	btst #JPB_BTN_BLU,d0
	beq .NoLvl2
	Move.l #$36353831,CODE_LOCATION	;Load the code for level 2.
	; Note that simply changing the value will mean that the string display on the options menu will update automatically, presumably the passcode text is blitted to screen every frame?
	;Further note, I haven't tested but it seems these "practice codes" means that you can't complete the entire game, only the specific world in the code. I figure the majority of people may want it so that use of the practice code simply means you can pick up where you left off and finish the game.
.NoLvl2

	btst #JPB_BTN_GRN,d0
	beq .NoLvl3
	Move.l #$33313738,CODE_LOCATION	;Load the code for level 3
.NoLvl3

	btst #JPB_BTN_YEL,d0
	beq .NoLvl4
	Move.l #$38333932,CODE_LOCATION	;Load the code for level 4
.NoLvl4

	btst #JPB_BTN_PLAY,d0
	beq .NoCheat
	Move.l #$36373137,CODE_LOCATION	;Load the code for infinite lives. Note that when this code is loaded, it cannot be undone,
	; so infinite lives trainer should probably be handled in a different way or not at all.
.NoCheat

	;Further note, there is a "practice code" to see the end of game credits, which is 7339 (presumably $37333339)
	bra.b .raus
	
.InGame
	TEST_BUTTON	JPB_BTN_PLAY,$3CC8,game
	TEST_BUTTON	JPB_BTN_REVERSE,$3CCA,game
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nojoypad
	TEST_BUTTON	JPB_BTN_FORWARD,$3CC9,game
.nojoypad:
.NoReplay	
	btst #JPB_BTN_BLU,d0
	beq .NoJump
	move.w	#1,(a0)
.NoJump
	
	
.raus
	;Ruff N Tumble Erik controls ends
	lea	previous_joypad_input(pc),a0
	move.l	D0,(a0)	; store previous inputs
	movem.l	(a7)+,D0-D1/A0
	rts
	
button_2_pressed:
	dc.w	0
	
previous_joypad_input
	dc.l	0
current_joypad_input
    dc.l    0
    
up_test
	btst	#4,($F6,a6)
	rts

read_2nd_button
	eori.b 	#$F,$3CFA	; stolen

	movem.l	d0,-(a7)
	move.w	button_2_pressed(pc),d0
	beq.b	.no
	bset	#4,$3CFA
.no
	movem.l	(a7)+,d0
	rts

kback:
	move.b	#$40,$bfee01
	movem.l	d0,-(a7)
	move.l	#2,d0
	bsr	_beamdelay
	movem.l	(a7)+,d0
	move.b	#$0,$bfee01
	rts

decrunch_and_patch:
	MOVEM.L	D0-D7/A2-A4,-(A7)	;14F0: 48E7FF38
;;	LEA	-384(A7),A7		;14F4: 4FEFFE80
;;	MOVEA.L	A7,A2			;14F8: 244F
	lea	rob_local_mem(pc),a2
	ADDQ	#4,A0			;14FA: 5848
	BSR	.lab_000D		;14FC: 610000F2
	LEA	10(A0),A3		;1500: 47E8000A
	MOVEA.L	A1,A4			;1504: 2849
	LEA	0(A4,D0.L),A5		;1506: 4BF40800
	MOVEQ	#0,D7			;150A: 7E00
	MOVE.B	1(A3),D6		;150C: 1C2B0001
	ROL	#8,D6			;1510: E15E
	MOVE.B	(A3),D6			;1512: 1C13
	MOVEQ	#2,D0			;1514: 7002
	MOVEQ	#2,D1			;1516: 7202
	BSR	.lab_000A		;1518: 610000B2
.lab_0000:
	MOVEA.L	A2,A0			;151C: 204A
	BSR	.lab_000F		;151E: 610000DC
	LEA	128(A2),A0		;1522: 41EA0080
	BSR	.lab_000F		;1526: 610000D4
	LEA	256(A2),A0		;152A: 41EA0100
	BSR	.lab_000F		;152E: 610000CC
	MOVEQ	#-1,D0			;1532: 70FF
	MOVEQ	#16,D1			;1534: 7210
	BSR	.lab_000A		;1536: 61000094
	MOVE	D0,D4			;153A: 3800
	SUBQ	#1,D4			;153C: 5344
	BRA.S	.lab_0003		;153E: 601C
.lab_0001:
	LEA	128(A2),A0		;1540: 41EA0080
	MOVEQ	#0,D0			;1544: 7000
	BSR.S	.lab_0006		;1546: 614E
	NEG.L	D0			;1548: 4480
	LEA	-1(A4,D0.L),A1		;154A: 43F408FF
	LEA	256(A2),A0		;154E: 41EA0100
	BSR.S	.lab_0006		;1552: 6142
	MOVE.B	(A1)+,(A4)+		;1554: 18D9
.lab_0002:
	MOVE.B	(A1)+,(A4)+		;1556: 18D9
	DBF	D0,.lab_0002		;1558: 51C8FFFC
.lab_0003:
	MOVEA.L	A2,A0			;155C: 204A
	BSR.S	.lab_0006		;155E: 6136
	SUBQ	#1,D0			;1560: 5340
	BMI.S	.lab_0005		;1562: 6B1A
.lab_0004:
	MOVE.B	(A3)+,(A4)+		;1564: 18DB
	DBF	D0,.lab_0004		;1566: 51C8FFFC
	MOVE.B	1(A3),D0		;156A: 102B0001
	ROL	#8,D0			;156E: E158
	MOVE.B	(A3),D0			;1570: 1013
	LSL.L	D7,D0			;1572: EFA8
	MOVEQ	#1,D1			;1574: 7201
	LSL	D7,D1			;1576: EF69
	SUBQ	#1,D1			;1578: 5341
	AND.L	D1,D6			;157A: CC81
	OR.L	D0,D6			;157C: 8C80
.lab_0005:
	DBF	D4,.lab_0001		;157E: 51CCFFC0
	CMPA.L	A5,A4			;1582: B9CD
	BCS.S	.lab_0000		;1584: 6596
	MOVE.L	A5,$1684.W
;;	LEA	384(A7),A7		;158C: 4FEF0180

	bsr	end_rob_decrunch

	MOVEM.L	(A7)+,D0-D7/A2-A4	;1590: 4CDF1CFF
	RTS				;1594: 4E75
.lab_0006:
	MOVE	(A0)+,D0		;1596: 3018
	AND	D6,D0			;1598: C046
	SUB	(A0)+,D0		;159A: 9058
	BNE.S	.lab_0006		;159C: 66F8
	MOVE.B	60(A0),D1		;159E: 1228003C
	SUB.B	D1,D7			;15A2: 9E01
	BGE.S	.lab_0007		;15A4: 6C02
	BSR.S	.lab_000C		;15A6: 6130
.lab_0007:
	LSR.L	D1,D6			;15A8: E2AE
	MOVE.B	61(A0),D0		;15AA: 1028003D
	CMP.B	#$02,D0			;15AE: B03C0002
	BLT.S	.lab_0009		;15B2: 6D16
	SUBQ.B	#1,D0			;15B4: 5300
	MOVE.B	D0,D1			;15B6: 1200
	MOVE.B	D0,D2			;15B8: 1400
	MOVE	62(A0),D0		;15BA: 3028003E
	AND	D6,D0			;15BE: C046
	SUB.B	D1,D7			;15C0: 9E01
	BGE.S	.lab_0008		;15C2: 6C02
	BSR.S	.lab_000C		;15C4: 6112
.lab_0008:
	LSR.L	D1,D6			;15C6: E2AE
	BSET	D2,D0			;15C8: 05C0
.lab_0009:
	RTS				;15CA: 4E75
.lab_000A:
	AND	D6,D0			;15CC: C046
	SUB.B	D1,D7			;15CE: 9E01
	BGE.S	.lab_000B		;15D0: 6C02
	BSR.S	.lab_000C		;15D2: 6104
.lab_000B:
	LSR.L	D1,D6			;15D4: E2AE
	RTS				;15D6: 4E75
.lab_000C:
	ADD.B	D1,D7			;15D8: DE01
	LSR.L	D7,D6			;15DA: EEAE
	SWAP	D6			;15DC: 4846
	ADDQ	#4,A3			;15DE: 584B
	MOVE.B	-(A3),D6		;15E0: 1C23
	ROL	#8,D6			;15E2: E15E
	MOVE.B	-(A3),D6		;15E4: 1C23
	SWAP	D6			;15E6: 4846
	SUB.B	D7,D1			;15E8: 9207
	MOVEQ	#16,D7			;15EA: 7E10
	SUB.B	D1,D7			;15EC: 9E01
	RTS				;15EE: 4E75
.lab_000D:
	MOVEQ	#3,D1			;15F0: 7203
.lab_000E:
	LSL.L	#8,D0			;15F2: E188
	MOVE.B	(A0)+,D0		;15F4: 1018
	DBF	D1,.lab_000E		;15F6: 51C9FFFA
	RTS				;15FA: 4E75
.lab_000F:
	MOVEQ	#31,D0			;15FC: 701F
	MOVEQ	#5,D1			;15FE: 7205
	BSR.S	.lab_000A		;1600: 61CA
	SUBQ	#1,D0			;1602: 5340
	BMI.S	.lab_0015		;1604: 6B7C
	MOVE	D0,D2			;1606: 3400
	MOVE	D0,D3			;1608: 3600
	LEA	-16(A7),A7		;160A: 4FEFFFF0
	MOVEA.L	A7,A1			;160E: 224F
.lab_0010:
	MOVEQ	#15,D0			;1610: 700F
	MOVEQ	#4,D1			;1612: 7204
	BSR.S	.lab_000A		;1614: 61B6
	MOVE.B	D0,(A1)+		;1616: 12C0
	DBF	D2,.lab_0010		;1618: 51CAFFF6
	MOVEQ	#1,D0			;161C: 7001
	ROR.L	#1,D0			;161E: E298
	MOVEQ	#1,D1			;1620: 7201
	MOVEQ	#0,D2			;1622: 7400
	MOVEM.L	D5-D7,-(A7)		;1624: 48E70700
.lab_0011:
	MOVE	D3,D4			;1628: 3803
	LEA	12(A7),A1		;162A: 43EF000C
.lab_0012:
	CMP.B	(A1)+,D1		;162E: B219
	BNE.S	.lab_0014		;1630: 663A
	MOVEQ	#1,D5			;1632: 7A01
	LSL	D1,D5			;1634: E36D
	SUBQ	#1,D5			;1636: 5345
	MOVE	D5,(A0)+		;1638: 30C5
	MOVE.L	D2,D5			;163A: 2A02
	SWAP	D5			;163C: 4845
	MOVE	D1,D7			;163E: 3E01
	SUBQ	#1,D7			;1640: 5347
.lab_0013:
	ROXL	#1,D5			;1642: E355
	ROXR	#1,D6			;1644: E256
	DBF	D7,.lab_0013		;1646: 51CFFFFA
	MOVEQ	#16,D5			;164A: 7A10
	SUB.B	D1,D5			;164C: 9A01
	LSR	D5,D6			;164E: EA6E
	MOVE	D6,(A0)+		;1650: 30C6
	MOVE.B	D1,60(A0)		;1652: 1141003C
	MOVE.B	D3,D5			;1656: 1A03
	SUB.B	D4,D5			;1658: 9A04
	MOVE.B	D5,61(A0)		;165A: 1145003D
	MOVEQ	#1,D6			;165E: 7C01
	SUBQ.B	#1,D5			;1660: 5305
	LSL	D5,D6			;1662: EB6E
	SUBQ	#1,D6			;1664: 5346
	MOVE	D6,62(A0)		;1666: 3146003E
	ADD.L	D0,D2			;166A: D480
.lab_0014:
	DBF	D4,.lab_0012		;166C: 51CCFFC0
	LSR.L	#1,D0			;1670: E288
	ADDQ.B	#1,D1			;1672: 5201
	CMP.B	#$11,D1			;1674: B23C0011
	BNE.S	.lab_0011		;1678: 66AE
	MOVEM.L	(A7)+,D5-D7		;167A: 4CDF00E0
	LEA	16(A7),A7		;167E: 4FEF0010
.lab_0015:
	RTS				;1682: 4E75
.lab_0017:
	MOVE.B	(A0)+,D0		;1688: 1018
	EXT	D0			;168A: 4880
	BMI.S	.lab_0019		;168C: 6B08
.lab_0018:
	MOVE.B	(A0)+,(A1)+		;168E: 12D8
	DBF	D0,.lab_0018		;1690: 51C8FFFC
	BRA.S	.lab_0017		;1694: 60F2
.lab_0019:
	LEA	0(A1,D0),A2		;1696: 45F10000
	CLR	D0			;169A: 4240
	MOVE.B	(A0)+,D0		;169C: 1018
	BEQ.S	.lab_001B		;169E: 670A
	SUBQ	#1,D0			;16A0: 5340
.lab_001A:
	MOVE.B	(A2)+,(A1)+		;16A2: 12DA
	DBF	D0,.lab_001A		;16A4: 51C8FFFC
	BRA.S	.lab_0017		;16A8: 60DE
.lab_001B:
	RTS				;16AA: 4E75

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

kbint:
	move.b	D0,$3CF9.W
	cmp.b	_keyexit(pc),D0
	beq	quit		; F10: exit
	cmp.b	#$5F,D0		; HELP: levelskip
	bne	.nolskip

	movem.l	D0/A0,-(sp)
	
	move.l	extbase(pc),A0
	move.l	level(pc),D0
	beq	.intro			; not playing

	cmp.b	#1,D0
	bne	.n1
	add.l	#$573B0,A0
	bra	.lskip
.n1
	cmp.b	#2,D0
	bne	.n2
	add.l	#$5C7FA,A0
	bra	.lskip	

.n2
	cmp.b	#3,D0
	bne	.n3
	add.l	#$55704,A0
	bra	.lskip	

.n3
	cmp.b	#4,D0
	bne	.n4
	add.l	#$532C2,A0
	bra	.lskip	
.n4
	bra	.intro
.lskip
	tst.w	(A0)
	bne	.intro			; safety

	move.w	#$14,(A0)		; skips level
.intro
	movem.l	(sp)+,D0/A0

.nolskip
	rts

; RD en $14F0

CHECK_PATCHED:MACRO
	move.l	extbase(pc),A2
	add.l	#\1,A2
	cmp.w	#$43F1,(A2)+
	bne	.l\2_patched
	ENDM

PATCH_BTST_1:MACRO
	move.l	extbase(pc),A2
	add.l	#\1,A2
	move.w	#$4EB9,(a2)+
	pea	PatchBtst1(pc)
	move.l	(a7)+,(a2)+
	ENDM

PATCH_ZERO:MACRO
	move.l	extbase(pc),A2
	add.l	#\1,A2
	move.l	#$4E714EB9,(a2)+
	pea	PatchZero(pc)
	move.l	(a7)+,(a2)+
	ENDM

PATCH_24BIT:MACRO
	move.l	extbase(pc),A2
	add.l	#\1,A2
	move.w	#$4EB9,(a2)+
	pea	patch_24_bit_level_1_\2(pc)
	move.l	(a7)+,(a2)+
	ENDM

PATCH_24BIT_2:MACRO
	move.l	extbase(pc),A2
	add.l	#\1,A2
	move.l	#$4E714EB9,(A2)+
	pea	Patch24BitMonster(pc)
	move.l	(a7)+,(A2)+
	ENDM

TRAPA_24BIT:MACRO
	move.l	extbase(pc),A2
	add.l	#\1,A2
	move.w	#$4E4E,(A2)
	ENDM


PATCH_2ND_BUTTON:MACRO
	move.l	extbase(pc),A2
	add.l	#\1,A2
	move.w	#$4EB9,(A2)+
	pea	up_test(pc)
	move.l	(a7)+,(a2)
	ENDM

SET_LEVEL:MACRO
	lea	level(pc),A2
	move.l	#\1,(A2)
	ENDM

SET_COPPER:MACRO
	movem.l	a0-a1,-(a7)
	move.l	extbase(pc),a1
	add.l	#\1,a1
	move.w	#$4EB9,(a1)+
	lea	set_copper_game(pc),a0
	move.l	a0,(a1)+
	move.l	#$4E714E71,(a1)
	movem.l	(a7)+,a0-a1
	ENDM
	
PatchZero:
	move.l	$1E(A0),A1
	cmp.l	#0,A1
	beq.b	.zero
.exit
	and.w	#$7C00,(A1)
	rts
.zero
	addq.l	#2,A1
	bra.b	.exit

PatchBtst1:
	move.l	D0,-(A7)
	move.l	A2,D0
	swap	D0
	ror.w	#8,D0
	tst.b	D0
	bne.b	.notok
	
	move.l	(A7)+,D0
	btst	#2,9(A2)	; normal test
	rts

.notok:
	move.l	(A7)+,D0
	cmp.l	D0,D0		; set Z bit
	rts
	
set_copper_game:
	move.w	#$5200,$36CE
	move.w	#$5200,$385A
	move.w	#$0200,$3796
	move.l	#$3684,$DFF080		; original
	rts
	
end_rob_decrunch:
	; ** check for level 1 bugs



	CHECK_PATCHED	$58CB0,1
	
	
	SET_COPPER	$5826C

	
	move.l	two_button_control(pc),d0
	beq.b	.not1
	PATCH_2ND_BUTTON	$5AC12	; jump test
;;;	PATCH_2ND_BUTTON	$5AD12	; during jump cling to ladder (not patched)
	PATCH_2ND_BUTTON	$5A962  ; during jump (control height)
.not1

	PATCH_24BIT	$5CE8A,1
	PATCH_24BIT	$58CB0,2
	PATCH_24BIT	$58CBA,3

	PATCH_24BIT_2	$5DCE8

	PATCH_BTST_1	$5C3FE

	SET_LEVEL	1

	bsr	Remove24BitCalls
	bra	.exit
.l1_patched

	; ** check for level 2 bugs


	CHECK_PATCHED	$5E0FA,2
	
	SET_COPPER	$5D6B6

	move.l	two_button_control(pc),d0
	beq.b	.not2
	PATCH_2ND_BUTTON	$6005C	; jump test
	PATCH_2ND_BUTTON	$5FDAC  ; during jump (control height)
.not2

	PATCH_24BIT	$622D4,1
	PATCH_24BIT	$5E0FA,2
	PATCH_24BIT	$5E104,3

	PATCH_24BIT_2	$63132

	PATCH_BTST_1	$61848

	SET_LEVEL	2

	bsr	Remove24BitCalls
	bra	.exit
.l2_patched

	; ** check for level 3 bugs

	CHECK_PATCHED	$57004,3

	SET_COPPER	$565C0

	move.l	two_button_control(pc),d0
	beq.b	.not3
	PATCH_2ND_BUTTON	$58F66	; jump test
	PATCH_2ND_BUTTON	$58CB6  ; during jump (control height)
.not3


	PATCH_24BIT	$5B1DE,1
	PATCH_24BIT	$57004,2
	PATCH_24BIT	$5700E,3

	PATCH_24BIT_2	$5C03C

	PATCH_BTST_1	$5A752

	SET_LEVEL	3

	bsr	Remove24BitCalls
	bra	.exit
.l3_patched
	; level 4
	
	CHECK_PATCHED	$54BC2,4
	
	SET_COPPER	$5417E
	
	move.l	two_button_control(pc),d0
	beq.b	.not4
	PATCH_2ND_BUTTON	$56B24	; jump test
	PATCH_2ND_BUTTON	$56874  ; during jump (control height)
.not4

	PATCH_24BIT	$58D6C,1
	PATCH_24BIT	$54BC2,2
	PATCH_24BIT	$54BCC,3

	PATCH_24BIT_2	$59BF8

	PATCH_BTST_1	$582E0

	PATCH_ZERO	$5981C

	SET_LEVEL	4

	bsr	Remove24BitCalls
	bra	.exit

.l4_patched
.exit
	bsr	_flushcache

	rts

fix_32bit_address:
	and.l	#$FFFFFF,d0

	rts
	
Patch24BitMonster:
	move.w	$28(A0),D0
	move.l	D0,-(sp)
	move.l	$24(A0),D0
	bsr.b		fix_32bit_address
	move.l	D0,A2
	move.l	(sp)+,D0
	rts

Remove24BitCalls:
	movem.l	d0-a6,-(a7)
	move.l	extbase(pc),A0
	add.l	#$50000,A0
	move.l	A0,A1
	add.l	#$10000,A1

	move.l	#$28502C14,D0	; pattern searched

.search
	cmp.l	(A0),D0
	bne	.nopatch
	move.w	#$4E4E,(A0)
.nopatch
	addq.l	#2,A0		; next please

	cmp.l	A0,A1
	bcc	.search

	pea	trap_24_bit(pc)
	move.l	(a7)+,$B8.W

	movem.l	(a7)+,d0-a6
	rts

trap_24_bit:
	move.l	D0,-(sp)
	move.l	(A0),D0
	bsr.b		fix_32bit_address
	move.l	D0,A4
	move.l	(sp)+,D0
	rte

patch_24_bit_level_1_1:
patch_24_bit_level_2_1:
	move.l	D0,-(sp)
	move.l	$24(A0),D0
	bsr.b		fix_32bit_address
	move.l	D0,A1
	move.l	(sp)+,D0
	move.w	D0,D1
	rts


patch_24_bit_level_2_2:
patch_24_bit_level_1_2:
	lea	(A1,D0.W),A1	; original

	move.l	D0,-(sp)
	move.l	A1,D0
	bsr.b		fix_32bit_address
	move.l	D0,A1
	move.l	(sp)+,D0

	tst.l	(A1)		; original
	rts

patch_24_bit_level_1_3:
patch_24_bit_level_2_3:
	move.b	(A1),D4
	move.l	(A1),A1
	move.w	D4,D0

	move.l	D0,-(sp)
	move.l	A1,D0
	bsr		fix_32bit_address
	move.l	D0,A1
	move.l	(sp)+,D0

	rts


uae_break:
	* sends a WinUAE command to enter WinUAE debugger
	move.l	d0,-(a7)
	pea     0.w
	pea     0.w
	pea     .1003-.1002
	pea     .1002(pc)
	pea     -1.w
	pea     82.w
	jsr     $f0ff60
	lea     24(sp),sp
	move.l	(a7)+,d0
    rts
		
.1002:
		dc.b	"AKS_ENTERDEBUGGER 1",0
.1003:
        even
	
read_sectors
	movem.l	d1-d2/a0-a2,-(A7)
	bsr	_detect_controller_types

	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.readnothing		; length=0: out

	exg.l	d0,d2
	addq.l	#1,d2	; disk number

	exg.l	d0,d1

	ext.l	d0
	lsl.l	#7,d0
	lsl.l	#2,d0
	ext.l	d1
	lsl.l	#7,d1			;diskoffset
	lsl.l	#2,d1
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
.readnothing
	movem.l	(a7)+,d1-d2/a0-a2
	moveq	#0,d0
	rts

decrunch
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	bsr	_flushcache
	rts
	
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts


_tag		dc.l	WHDLTAG_CUSTOM2_GET
two_button_control	dc.l	0
		dc.l	0


;--------------------------------

_resload	dc.l	0		;address of resident loader

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_loaddisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts


;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

hex_search:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts

extbase:
	dc.l	$80000
level
	dc.l	0

rob_local_mem
	ds.b	384

	include	ReadJoyPad.s
