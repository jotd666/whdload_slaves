* $Id: lowlevel.s 1.1 1999/02/03 04:08:28 jotd Exp $

; most of this stuff was ripped from the real lowlevel library by JOTD
; except for the joypad test, which has been hacked in order to accept
; either joysticks or joypad.
;
; if the CD of the game includes lowlevel.library file in "LIBS", it is
; recommended to use it instead of this code (maybe more compatible, and
; slave is also smaller). However, the fakepad.s source should be used in
; order to make believe the controller is a joypad (protection in
; some games, which refuse to run without joypad, such as James Pond 2)
;
; Better: if a joystick is connected, then the call always tell
; that this is a CD32 joypad (some games demand CD32 joypad), and the button
; detection routine has been improved in 2006 so there is no problem with joypad
; or joystick. In the case of a joystick connected, the function keys (changeable
; by the slave) emulate the buttons
;
; Mouse is now supported in ReadJoyPort

; Frequent joypad bug: if a joystick is connected at this moment, 2nd button reads are
; interpreted as "Pause" (actually interpreted as "all buttons pressed"),
; which is the problem of many CD³² games which don't make
; use of lowlevel.library (even out of WHDLoad) because they assume a joypad in all cases
;
; the way to detect a wrong button read is to test bit 16: always 0 for joypad read
; always 1 for joystick read (along with the rest of the bits set to 1 too!)
; the joypad/joystick breakthrough was made in january 2006 by JOTD, with a faulty
; joystick and an unstable A1200, which did not help at all :)
;
; thanks Psygore for adding the joypad detection routine in the first place
;
; actually, the info I had in 2014 from EAB / Toni "Winuae" Willen was

; History:
;
; - 2014: JOTD adjust timer for the first time (Bert fix AFAIK), reduced number of buttons
; - 2006: JOTD added automatic controller detection and fixed joypad button test
;          for non-joypad controllers
;         JOTD added mouse support
;         JOTD added SystemControlA() partial implementation
;         JOTD added SetJoyPortAttrsA() partial implementation
; - 2003: Psygore added joypad detection routine adapted from lowlevel.library
; - 2002: JOTD adapted the code for use with KickEmu
; - 2000 or 2001: JOTD initiated lowlevel.library emulation (with OSEmu)
;
;
;
TEST_JOY_BUTTON:MACRO
	bclr	#JPB_BUTTON_\1,D0	; button released
	move.l	(A0)+,D1
	tst.w	D1
	beq.b	.rts_\1
	bset	#JPB_BUTTON_\1,D0	; button pressed
.rts_\1
	ENDM

**************************************************************************
*   LOWLEVEL-LIBRARY                                                    *
**************************************************************************
**************************************************************************
*   INITIALIZATION                                                       *
**************************************************************************

LOWLINIT	move.l	_lowlbase(pc),d0
		beq	.init
		rts

.init		move.l	#162,d0		; reserved function
		move.l	#250,d1
		lea	_lowlname(pc),a0
		bsr	_InitLibrary
		lea	_lowlbase(pc),a0
		move.l	d0,(a0)
		move.l	d0,a0
		
		patch	_LVOReadJoyPort(a0),_ReadJoyPort
		patch	_LVOSetJoyPortAttrsA(a0),SETJOYPORTATTRS
		patch	_LVOAddVBlankInt(a0),ADDVBLANKINT
		patch	_LVOAddKBInt(a0),ADDKBINT
		patch	_LVOAddTimerInt(a0),ADDTIMERINT
		patch	_LVORemTimerInt(a0),REMTIMERINT
		patch	_LVOStartTimerInt(a0),STARTTIMERINT
		patch	_LVOStopTimerInt(a0),STOPTIMERINT
		patch	_LVORemVBlankInt(a0),MYRTS
		patch	_LVORemKBInt(a0),MYRTS
		patch	_LVOQueryKeys(a0),QueryKeys
		patch	_LVOSystemControlA(a0),SYSTEMCONTROLA
		patch	_LVOGetLanguageSelection(a0),GETLANGSEL
		patch	_LVOGetKey(a0),GETKEY
		patch	_LVOElapsedTime(a0),ELAPSEDTIME

		; cache flush (to be able to use function table at once)

		bsr	ForeignCacheFlush

		; init timers and stuff...

		movem.l	D0-A6,-(A7)
		move.l	D0,A5
		CLR.L	242(A5)	; i don't remember why I did that
		move.l	#$ad303,44(A5)	; EClock rate for timer

		lea.l   JOYPAD1KEYS(PC),a0 ;copy joypad keys to
		lea.l   OSM_JOYPAD1KEYS(PC),a1 ;location in lowlevel.lib
		moveq.l #6*2-1,d0
		tst.b   (A0)+
.copykeys	move.b  (A1)+,(A0)+
		addq.l  #3,a0
		dbf     d0,.copykeys
 
		; opens keyboard device

		lea	_kbdevname(pc),A0
		moveq.l	#0,D0
		moveq.l	#0,D1

		lea	-64(A7),A7
		move.l	A7,A1
		move.l	$4.W,A6
		JSRLIB	OpenDevice
		move.l	20(A7),68(A5)	; device base
		lea	64(A7),A7

		; opens timer device

		lea	_timerdevname(pc),A0
		moveq.l	#0,D0
		moveq.l	#0,D1

		lea	-64(A7),A7
		move.l	A7,A1
		move.l	$4.W,A6
		JSRLIB	OpenDevice
		move.l	20(A7),64(A5)	; device base
		lea	64(A7),A7

		lea	(_custom),a5
		move.w	#$CC01,potgo(a5)	; reset ports at startup

		bsr	InitLowlevelKeyboard
		bsr	InitLowlevelVBI

		movem.l	(A7)+,D0-A6
		rts

InitLowlevelVBI
	lea	oldint_vbi(pc),a0
	move.l	$6C.W,(A0)
	lea	newint_vbi(pc),a0
	move.l	a0,$6C.W
	rts

oldint_vbi
	dc.l	0

newint_vbi:
	movem.l	D0/A0,-(a7)
	move.w	$dff000+intreqr,d0
	btst	#5,d0
	beq.b	.notvbi

	lea	vbi_counter(pc),a0
	addq.l	#1,(a0)
.notvbi
	movem.l	(a7)+,D0/A0
	move.l	oldint_vbi(pc),-(A7)
	rts

vbi_counter
	dc.l	0

GETLANGSEL:
	moveq.l	#2,D0	; british english
	rts

; adds a vblank interrupt
; < A0: intRoutine
; < A1: intData

ADDVBLANKINT:
	movem.l	D2-D7/A2-A6,-(A7)
	lea	.int_entry(pc),A3
	move.l	A0,(A3)
	lea	.caller_int(pc),A0

	lea	.int_struct(pc),A3
	move.b	#NT_INTERRUPT,8(A3)	; ln_Type = INTERRUPT
	move.b	#0,9(A3)		; Highest priority
	move.l	.vbname(pc),10(A3)	; The name of the server (for monitor programs)
	move.l	A0,18(A3)		; The new interrupt server code to chain with
	move.l	A1,14(A3)		; The data to pass in A1 at each call
	move.l	#INTB_VERTB,D0		; Vertical Blank interrupt
	move.l	$4.W,A6
	move.l	A3,A1			; pointer on interrupt structure
	JSR	_LVOAddIntServer(A6)	; Adds the handler to the existing chain
	
	movem.l	(A7)+,D2-D7/A2-A6

	moveq.l	#1,D0			; returns !=0 because success
	rts

.caller_int:
	move.l	.int_entry(pc),A5	; as required in lowlevel autodoc
	jmp	(A5)

.int_entry:
	dc.l	0
.int_struct:
	ds.b	22
.vbname:	
	dc.b	"lowlevel vbl",0
	cnop	0,4

; adds a keyboard interrupt
; < A0: intRoutine
; < A1: intData

ADDKBINT:
	movem.l	D2-D7/A2-A6,-(A7)
	lea	.int_entry(pc),A3
	move.l	A0,(A3)
	lea	.caller_int(pc),A0

	lea	.int_struct(pc),A3
	move.b	#NT_INTERRUPT,8(A3)	; ln_Type = INTERRUPT
	move.b	#0,9(A3)		; Highest priority
	move.l	.vbname(pc),10(A3)	; The name of the server (for monitor programs)
	move.l	A0,18(A3)		; The new interrupt server code to chain with
	move.l	A1,14(A3)		; The data to pass in A1 at each call
	move.l	#INTB_PORTS,D0		; Ports interrupt
	move.l	$4.W,A6
	move.l	A3,A1			; pointer on interrupt structure
	JSR	_LVOAddIntServer(A6)	; Adds the handler to the existing chain
	
	movem.l	(A7)+,D2-D7/A2-A6
	moveq.l	#1,D0			; returns !=0 because success
	rts

.caller_int:
	move.b	rawkeycode(pc),D0
	cmp.b	.lastkey(pc),D0
	beq.b	.ports_end		; same key: impossible, since the key needs
	lea	.lastkey(pc),a5
	move.b	D0,(a5)			; to be released. We don't call the user routine
	move.l	.int_entry(pc),A5	; as required in lowlevel autodoc

.out
	; jumps to user routine

	jmp	(A5)
.ports_end
	; does not call user routine

	rts

.int_entry:
	dc.l	0
.int_struct:
	ds.b	22
.vbname:	
	dc.b	"lowlevel kb",0
.lastkey:
	dc.b	0
	cnop	0,4

; adds a timer interrupt
; < A0: intRoutine
; < A1: intData

ADDTIMERINT:

	MOVEM.L	A0-A1/A4-A6,-(A7)	;08C4: 48E700CE
	MOVEA.L	A6,A5			;08C8: 2A4E
	MOVEA.L	$4.W,A6		;08CA: 2C6E0034
	JSR	_LVOForbid(A6)	;(exec.library)
	TST.L	242(A5)			;08D2: 4AAD00F2
	BEQ.S	LOWL_0061		;08D6: 670C
	JSR	_LVOPermit(A6)	;(exec.library)
	MOVEM.L	(A7)+,A0-A1/A4-A6	;08DC: 4CDF7300
	MOVEQ	#0,D0			;08E0: 7000
	RTS				;08E2: 4E75
LOWL_0061:
	MOVEM.L	(A7)+,A0-A1		;08E4: 4CDF0300
	LEA	224(A5),A4		;08E8: 49ED00E0
	MOVE.L	A0,18(A4)		;08EC: 29480012
	MOVE.L	A1,14(A4)		;08F0: 2949000E
	CLR.B	9(A4)			;08F4: 422C0009
	MOVE.B	#$02,8(A4)		;08F8: 197C00020008
	MOVE.L	10(A5),10(A4)		;08FE: 296D000A000A
	JSR	_LVOPermit(A6)	;(exec.library)
	JSR	_LVODisable(A6)	;(exec.library)
	LEA	_ciaaname(pc),A1	;090C: 43FA01F2
	bsr	LOWL_0071		;0910: 4EB900000A3C
	BPL.S	LOWL_0062		;0916: 6A1C
	MOVEA.L	$4.W,A6		;0918: 2C6D0034
	LEA	_ciabname(pc),A1	;091C: 43FA01F0
	bsr	LOWL_0071		;0920: 4EB900000A3C
	BPL.S	LOWL_0062		;0926: 6A0C
	MOVEQ	#0,D0			;0928: 7000
	MOVE.L	D0,18(A4)		;092A: 29400012
	MOVEA.L	$4.W,A6		;092E: 2C6D0034
	BRA.S	LOWL_0065		;0932: 603C
LOWL_0062:
	MOVE.L	A6,24(A4)		;0934: 294E0018
	MOVE	D0,22(A4)		;0938: 39400016
	BNE.S	LOWL_0063		;093C: 6612
	MOVEQ	#14,D1			;093E: 720E
	ROL.L	#8,D1			;0940: E199
	MOVE.L	#$000100CE,D0		;0942: 203C000100CE
	MOVEA.L	34(A6),A1		; cia base from cia-resource
	BRA.S	LOWL_0064		;094E: 6010
LOWL_0063:
	MOVEQ	#15,D1			;0950: 720F
	ROL.L	#8,D1			;0952: E199
	MOVE.L	#$0002008E,D0		;0954: 203C0002008E
	move.l	34(A6),a1	;cia-base from cia.resource
LOWL_0064:
	AND.B	D0,0(A1,D1)		;0960: C1311000
	SWAP	D0			;0964: 4840
	JSR	-24(A6)		; SetICR
	MOVEA.L	$4.W,A6		;096A: 2C6D0034
	MOVE.L	A4,D0			;096E: 200C
LOWL_0065:
	JSR	_LVOEnable(A6)	;(exec.library)
	MOVEM.L	(A7)+,A4-A6		;0974: 4CDF7000
	RTS				;0978: 4E75

LOWL_0071:
	JSRLIB	OpenResource
	MOVEA.L	D0,A6			;0A40: 2C40
	MOVEA.L	A4,A1			;0A42: 224C
	MOVE	#$0000,D0		;0A44: 303C0000
	MOVE	D0,-(A7)		;0A48: 3F00
	JSRLIB	AddICRVector ; (cia.resource)
	TST.L	D0			;0A4E: 4A80
	BEQ.S	LOWL_0072		;0A50: 6714
	MOVEA.L	A4,A1			;0A52: 224C
	MOVE	#$0001,D0		;0A54: 303C0001
	MOVE	D0,(A7)			;0A58: 3E80
	JSRLIB	AddICRVector ; (cia.resource)
	TST.L	D0			;0A5E: 4A80
	BEQ.S	LOWL_0072		;0A60: 6704
	MOVE	#$FFFF,(A7)		;0A62: 3EBCFFFF
LOWL_0072:
	MOVE	(A7)+,D0		;0A66: 301F
	RTS				;0A68: 4E75

REMTIMERINT:
	MOVE.L	A6,-(A7)		;0A18: 2F0E
	MOVE.L	A1,-(A7)		;0A1A: 2F09
	BEQ.S	.rti_0070		;0A1C: 6718
	MOVE	22(A1),D0		;0A1E: 30290016
	MOVEA.L	24(A1),A6		;0A22: 2C690018
	JSR	_LVORemICRVector(A6); (cia.resource)
	MOVEM.L	(A7)+,A1		;0A2A: 4CDF0200
	CLR.L	18(A1)			;0A2E: 42A90012
	MOVEA.L	(a7)+,a6		;0A32: 2C5F
	RTS				;0A34: 4E75
.rti_0070:
	MOVEM.L	(A7)+,A1/A6		;0A36: 4CDF4200
	RTS				;0A3A: 4E75

STARTTIMERINT:
	MOVEM.L	D1-D3,-(A7)		;09A4: 48E77000
	TST.W	22(A1)			;timer a or b?
	BNE.S	.lab_006A		;09AC: 6618
	MOVEQ	#14,D2			;09AE: 740E
	ROL.L	#8,D2			;09B0: E19A
	MOVE.L	#$000100C6,D3		;09B8: 263C000100C6
	MOVEA.L	24(A1),a0
	move.l	34(A0),a0	;get cia-baseaddress from resource instead
	MOVEA.L	#$00000400,A1		;09B2: 227C00000400
	BRA.S	.lab_006B		;09C4: 6016
.lab_006A:
	MOVEQ	#15,D2			;09C6: 740F
	ROL.L	#8,D2			;09C8: E19A
	MOVE.L	#$00010086,D3		;09D0: 263C00010086
	MOVEA.L	24(A1),a0	;#$00BFD000,A0		;09D6: 207C00BFD000
	move.l	34(A0),a0
	MOVEA.L	#$00000600,A1		;09CA: 227C00000600
.lab_006B:
	AND.B	D3,0(A0,D2)		;09DC: C7302000
	TST	D1			;09E0: 4A41
	BNE.S	.lab_006C		;09E2: 6606
	ORI.B	#$08,0(A0,D2)		;09E4: 003000082000
.lab_006C:
	MOVE.L	44(A6),D1		;09EA: 222E002C
	LSR.L	#1,D0			;09EE: E288
	LSR.L	#4,D1			;09F0: E889
	MULU	D1,D0			;09F2: C0C1
	DIVU	#$7A12,D0		;09F4: 80FC7A12
	BNE.S	.lab_006D		;09F8: 6602
	ADDQ.B	#1,D0			;09FA: 5200
.lab_006D:
	ADDA.L	A0,A1			;09FC: D3C8
	MOVE.B	D0,(A1)			;09FE: 1280
	LSR	#8,D0			;0A00: E048
	MOVE.B	D0,256(A1)		;0A02: 13400100
	TST	2(A7)			;0A06: 4A6F0002
	BEQ.S	.lab_006E		;0A0A: 6706
	SWAP	D3			;0A0C: 4843
	OR.B	D3,0(A0,D2)		;0A0E: 87302000
.lab_006E:
	MOVEM.L	(A7)+,D1-D3		;0A12: 4CDF000E
	RTS				;0A16: 4E75


STOPTIMERINT:
	TST.W	22(A1)			;097A: 4A690016
	BNE.S	.lab_0067		;097E: 6610
	MOVEQ	#14,D1			;0980: 720E
	ROL.L	#8,D1			;0982: E199
	MOVE	#$00CE,D0		;0984: 303C00CE
	move.l	24(A1),a1		; cia base address
	move.l	34(A1),a1
	BRA.S	.lab_0068		;098E: 600E
.lab_0067:
	MOVEQ	#15,D1			;0990: 720F
	ROL.L	#8,D1			;0992: E199
	MOVE	#$008E,D0		;0994: 303C008E
	move.l	24(A1),a1
	move.l	34(A1),a1
.lab_0068:
	AND.B	D0,0(A1,D1)		;099E: C1311000
	RTS				;09A2: 4E75



; forces a port to a controller type and allows to reset it
; < A1: taglist
; < D0: port number

SETJOYPORTATTRS:
	cmp.l	#2,d0
	bcc.b	.err

	add.l	d0,d0
	add.l	d0,d0
	lea	port_0_attribute(pc),a0
	add.l	d0,a0

.loop	
	move.l	(a1)+,d0
	beq.b	.end
	cmp.l	#SJA_Type,d0
	bne.b	.no_type

	move.l	(a1)+,(a0)	; set/force port type
	bra.b	.loop

.no_type	
	cmp.l	#SJA_Reinitialize,d0
	bne.b	.no_reinit

	; unsupported, will do nothing

	bra.b	.loop

.no_reinit
	bra.b	.loop

.end	
	moveq.l	#-1,D0	; all went OK
	rts
.err
	moveq	#0,d0
	rts

port_0_attribute
	dc.l	SJA_TYPE_AUTOSENSE
port_1_attribute
	dc.l	SJA_TYPE_AUTOSENSE


; reads joypads/mouses/...

_ReadJoyPort:
	movem.l	d1-d7/a3-a5,-(sp)

	lea	(_ciaa),a4
	lea	(_custom),a5

	cmp.w	#0,D0
	beq	.port0
	cmp.w	#1,D0
	beq	.port1
	move.l	#JP_TYPE_NOTAVAIL,D0	; neither port 0 or 1 !
	bra	.rjexit

.port0
	move.w	(joy0dat,a5),d7		; joystick 1 moves
	bsr	.detect_controller

	moveq	#CIAB_GAMEPORT0,d3	; 1rst button (left mouse)
	moveq	#10,d4			; 2nd button (right mouse)
	move.w	#$F600,d5
	bsr.b	.port_test
.rjexit
	movem.l	(sp)+,d1-d7/a3-a5
	rts

.port1
	move.w	(joy1dat,a5),d7		; joystick 1 moves
	bsr	.detect_controller

	moveq	#CIAB_GAMEPORT1,d3	; 1rst button (red)
	moveq	#14,d4			; 2nd button (blue)
	move.w	#$6F00,d5

	bsr	.port_test

	bra	.rjexit

	; first, perform a 1-button joystick compatible test for red button
	; then a complete test of the joypad buttons, counterchecked in the end
	; in order to detect a 2 button joystick (not testing would result in
	; all buttons pressed, which is wrong)

.port_test
	moveq	#0,d6

.joystick_mode
	btst	d3,(a4)
	bne.b	.no_red_button
	bset	#JPB_BUTTON_RED,d0	; fire/lmb
.no_red_button

	; this is the joypad specific part

.joypad_mode
	bset	d3,(ciaddra,a4)
	bclr	d3,(a4)
	move.w	d5,(potgo,a5)		; a5=$DFF034
	moveq	#17-1,d1	; was done 24 times, not needed

	bra.b	.lbC000746	; removed: shaving timer issue too close
						; 2017: reinstated (identical as Wepl timing fix)

.button_loop
	tst.b	(a4)
	tst.b	(a4)
.lbC000746
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	move.w	(potinp,a5),d2		; a5=$DFF016
	bset	d3,(a4)
	bclr	d3,(a4)
	btst	d4,d2
	bne.b	.lbC00077C
	bset	d1,d6
.lbC00077C
	dbra	d1,.button_loop

	; all buttons have been read, reset data direction register

	bclr	d3,(ciaddra,a4)

	; acknowledge port input

;;	move.w	#$CC01,(potgo,a5)	; a5=$DFF034
;;	move.w	#$FFFF,(potgo,a5)	; a5=$DFF034
	move.w	#$FF00,(potgo,a5)	; a5=$DFF034	; correct value according to robinsonb5@eab
	
	; JOTD: added this in 2006 after 8 years of not knowing why
	; standard 2nd button joystick fails the multi-button test

	btst	#16,d6		; if this bit is set, then there was a read problem
	beq.b	.read_ok	; meaning this is not a joypad but a joystick

	; button 2 of the joystick

	bset	#JPB_BUTTON_BLUE,d0	; fire2/rmb only
	bra.b	.out

.read_ok
	and.l	#JP_BUTTON_MASK,d6
	or.l	d6,d0

.out
	move.l	D0,-(A7)
	movem.l	D1/D2,-(A7)
	move.l	.old_buttonmask(pc),D0
	bsr	.button_test
	movem.l	(A7)+,D1/D2
	lea	.old_buttonmask(pc),a4
	move.l	D0,(a4)
	or.l	(A7),D0
	move.l	D0,(A7)
	move.l	(A7)+,D0

.rptexit
	rts

.detect_controller
	add.l	d0,d0	
	add.l	d0,d0	
	lea	port_0_attribute(pc),a0
	move.l	(a0,d0.w),d0	; get attribute
	cmp.l	#SJA_TYPE_AUTOSENSE,d0
	beq.b	.autosense

	lsl.l	#8,d0
	lsl.l	#8,d0
	lsl.l	#8,d0
	lsl.l	#4,d0
	cmp.l	#JP_TYPE_MOUSE,d0
	beq.b	.mouse
	bra.b	.joy

.autosense
	move.l	d7,d3
	and.w	#$F0F0,d3
	cmp.w	#$9040,d3
	beq.b	.joy			; detection is not perfect but seems to work
.mouse
	move.l	#JP_TYPE_MOUSE,D0	; type of controller is mouse
	move.w	d7,d0			; X-Y mouse positions
	rts
.joy
	; type of controller is joypad, always
	; else some games complain
	; BUT some 2-button joystick are OK to play most games
	; (provided other buttons are mapped on keyboard by slave or
	; originaly). And joypad button read routine fails on a non-joypad
	; sometimes: pressing second button sets ALL buttons.
	
	move.l	#JP_TYPE_GAMECTLR,D0
	bsr	.joy_test		; joystick moves
	rts

; other joypad buttons by keyboard emulation
; even a real joypad does not work properly on a real amiga!
; (I don't really know why!)

.button_test0
	lea     JOYPAD0KEYS(pc),A0
	moveq.l #6,D1

	movem.l D0,-(A7)
	bsr     QueryKeys
	movem.l (A7)+,D0

	lea     JOYPAD0KEYS(pc),A0
	bra.s   .allbutton_test

.button_test:
	lea	.query_array(pc),A0
	moveq.l	#6,D1

	movem.l	D0,-(A7)
	bsr	QueryKeys
	movem.l	(A7)+,D0

	lea	.query_array(pc),A0
.allbutton_test:
	TEST_JOY_BUTTON	BLUE	; F5: fire 2/blue/rmb
	TEST_JOY_BUTTON	GREEN	; F6: Green
	TEST_JOY_BUTTON	YELLOW	; F7: Yellow
	TEST_JOY_BUTTON	PLAY	; F8: Play/pause
	TEST_JOY_BUTTON	REVERSE	; F9: left ear
	TEST_JOY_BUTTON	FORWARD	; F10:right ear
	rts

; tests joystick moves
; < d7: custom reg (word) of the selected joystick
; > d0: joystick bits set

.joy_test:
	movem.l	D4-D6,-(A7)

	move.w	D7,D4
	move.w	D4,D5
	btst	#1,D4
	beq.b	.left_off
	bset	#JPB_JOY_RIGHT,D0
	bra.b	.vert_test
.left_off:
	btst	#9,D4
	beq.b	.vert_test
	bset	#JPB_JOY_LEFT,D0
.vert_test
	lsr.w	#1,D4
	eor.w	D5,D4
	btst	#0,D4
	beq.b	.back_off
	bset	#JPB_JOY_DOWN,D0
	bra.b	.exit
.back_off
	btst	#8,D4
	beq.b	.exit
	bset	#JPB_JOY_UP,D0
.exit

	movem.l	(A7)+,D4-D6
	rts

.old_buttonmask:
	dc.l	0
.old_buttonmask0:
	dc.l	0

.query_array:
JOYPAD1KEYS:
	dc.w	$54,0	; F5
	dc.w	$55,0
	dc.w	$56,0
	dc.w	$57,0
	dc.w	$58,0
	dc.w	$59,0
JOYPAD0KEYS:
	dc.w    $5,0
	dc.w    $6,0
	dc.w    $7,0
	dc.w    $8,0
	dc.w    $9,0
	dc.w    $A,0

; A0: queryArray
; D1: array size

QueryKeys:
	MOVEM.L	D2/A2/A5-A6,-(A7)	;1584: 48E72026
	MOVEA.L	A6,A5			;1588: 2A4E
	MOVE.B	D1,D2			;158A: 1401
	MOVEA.L	A0,A2			;158C: 2448
	MOVEA.L	$4.W,A6
	SUBA.L	A1,A1			;1592: 93C9
	JSRLIB	FindTask	;(exec.library)

;;;	MOVEA.L	84(A5),A0		;1598: keyboard.device base
;;;	MOVE.L	D0,16(A0)		;159C: 21400010
;;;	MOVE.B	#$04,15(A0)		;15A0: 117C0004000F
;;;	MOVE.B	#$00,14(A0)		;15A6: 117C0000000E

	LEA	-64(A7),A7		;15AC: 4FEFFFC0

;;;	MOVE.L	A0,14(A7)		;15B0: 2F48000E

	MOVEA.L	A7,A1			;15B4: 224F
	MOVE.L	68(A5),20(A1)		;15B6: 236D00440014
	MOVE	#$000A,28(A1)		;15BC: 337C000A001C
	LEA	48(A7),A0		;15C2: 41EF0030
	MOVE.L	A0,40(A1)		;15C6: 23480028
	MOVE.L	#$00000010,36(A1)	;15CA: 237C000000100024
	JSR	_LVODoIO(A6)	;(exec.library)
	TST.B	D0			;15D6: 4A00
	BNE.S	.qk_00E2		;15D8: 661E
.qk_00DE:
	MOVE	(A2)+,D1		;15DA: 321A
	MOVE	D1,D0			;15DC: 3001
	AND	#$0007,D0		;15DE: C07C0007
	LSR	#3,D1			;15E2: E649
	BTST	D0,48(A7,D1)		;15E4: 01371030
	BEQ.S	.qk_00DF		;15E8: 6706
	MOVE	#$FFFF,(A2)+		;15EA: 34FCFFFF
	BRA.S	.qk_00E0		;15EE: 6004
.qk_00DF:
	MOVE	#$0000,(A2)+		;15F0: 34FC0000
.qk_00E0:
	SUBQ.B	#1,D2			;15F4: 5302
.qk_00E1:
	BNE.S	.qk_00DE		;15F6: 66E2
.qk_00E2:
;;;	MOVEA.L	14(A7),A0		;15F8: 206F000E
	LEA	64(A7),A7		;15FC: 4FEF0040
;;;	MOVE.B	#$02,14(A0)		;1600: 117C0002000E
	MOVEM.L	(A7)+,D2/A2/A5-A6	;1606: 4CDF6404
	RTS				;160A: 4E75

; gets rawkey+qualifier
GETKEY:
	move.l	key_and_qualifier(pc),D0
	tst.b	D0
	beq.b	.nok
	rts
.nok
	st.b	D0
	rts

ELAPSEDTIME:
	MOVEM.L	D2-D3/A6,-(A7)		;0A6A: 48E73002
	MOVE.L	4(A0),-(A7)		; old values
	MOVE.L	(A0),-(A7)
	MOVEA.L	64(A6),A6	; timer base
	JSRLIB	ReadEClock
	MOVEM.L	(A0)+,D1-D2		;0A7C: 4CD80006
	SUB.L	4(A7),D2		;0A80: 94AF0004
	MOVE.L	(A7)+,D3		;0A84: 261F
	ADDQ	#4,A7			;0A86: 584F
	SUBX.L	D3,D1			;0A88: 9383
	BPL.S	LAB_0074		;0A8A: 6A04
	NEG.L	D2			;0A8C: 4482
	NEGX.L	D1			;0A8E: 4081
LAB_0074:
	SWAP	D1			;0A90: 4841
	TST	D1			;0A92: 4A41
	BNE.S	LAB_0076		;0A94: 6614
	SWAP	D2			;0A96: 4842
	MOVE	D2,D1			;0A98: 3202
	CLR	D2			;0A9A: 4242

	MC68020		; lowlevel should need 68020+AGA so noproblemo with this
	DIVU.L	D0,D1:D2		;0A9C: 4C402401
	MC68000

	BVS.S	LAB_0076		;0AA0: 6908
	MOVE.L	D2,D0			;0AA2: 2002
LAB_0075:
	MOVEM.L	(A7)+,D2-D3/A6		;0AA4: 4CDF400C
	RTS				;0AA8: 4E75
LAB_0076:
	MOVEQ	#-1,D0			;0AAA: 70FF
	BRA.S	LAB_0075		;0AAC: 60F6

SYSTEMCONTROLA
	movem.l	d1-d7/a2-a6,-(a7)
.loop
	move.l	(a1)+,d0
	beq.b	.end
	move.l	(a1)+,d1
	cmp.l	#SCON_StopInput,d0
	beq.b	.stop_input
	bra	.loop
	
.end
	movem.l	(a7)+,d1-d7/a2-a6
	moveq	#0,d0
	rts

.stop_input
	tst.l	d1
	beq.b	.loop

	; stop input device & gameport device
	
	move.l	$4,A6

	LEA	-48(A7),A7		;0B42: 4FEFFFD0
	LEA	.gameportname(PC),A0		;0B5C: 41FA0092
	MOVEA.L	A7,A1			;0B60: 224F
	MOVEQ	#0,D0			;0B62: 7000
	MOVE.L	D0,D1			;0B64: 2200
	JSR	_LVOOpenDevice(A6)	;(exec.library)
;;	BNE.S	LAB_007C		;0B6A: 6612
	MOVE	#CMD_CLEAR,28(A7)		;0B6C: 3F7C0005001C
	MOVEA.L	A7,A1			;0B72: 224F
	JSR	_LVODoIO(A6)	;(exec.library)
	MOVEA.L	A7,A1			;0B78: 224F
	JSR	_LVOCloseDevice(A6)	;(exec.library)

;	LEA	48(A7),A7		;0BE4: 4FEF0030
;	LEA	-48(A7),A7		;0BB6: 4FEFFFD0

;;	MOVE.L	A0,14(A7)		;0BBA: 2F48000E
	LEA	.inputname(PC),A0		;0BBE: 41FA0040
	MOVEA.L	A7,A1			;0BC2: 224F
	MOVEQ	#0,D0			;0BC4: 7000
	MOVE.L	D0,D1			;0BC6: 2200
	JSR	_LVOOpenDevice(A6)	;(exec.library)
;;	BNE.S	LAB_007F		;0BCC: 6612
	MOVE	#CMD_STOP,28(A7)		;0BCE: 3F7C0006001C

	MOVEA.L	A7,A1			;0BD4: 224F
	JSR	_LVODoIO(A6)	;(exec.library)
	MOVEA.L	A7,A1			;0BDA: 224F
	JSR	_LVOCloseDevice(A6)	;(exec.library)
	LEA	48(A7),A7		;0BE4: 4FEF0030

	bra.b	.loop

.inputname
	dc.b	"input.device",0
.gameportname
	dc.b	"gameport.device",0
	even

OSM_JOYPAD1KEYS	dc.w	$5455,$5657,$5859	;keys F5-F10 for pad1, offs.48
OSM_JOYPAD0KEYS	dc.w	$0506,$0708,$090a	;keys 5-0 for pad0, offset 54
