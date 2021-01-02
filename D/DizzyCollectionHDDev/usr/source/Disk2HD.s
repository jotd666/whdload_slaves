	INCDIR	"Include:"
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

_base		SLAVE_HEADER
		dc.w	17
		dc.w	WHDLF_NoError|WHDLF_EmulTrap
		dc.l	$80000
		dc.l	0
		dc.w	_Start-_base
		dc.w	dir-_base
		dc.w	0
_keydebug	dc.b	0
_keyexit	dc.b	$59
		dc.l	0
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

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
	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0

_config
        dc.b    "C1:B:infinite lives (FW Dizzy);"
        dc.b    "C2:B:second button jumps;"
		dc.b	0
        
dir		dc.b	"data",0
_name		dc.b	"Dizzy Collection [disk 2]",0
_copy		dc.b	"1991 Code Masters",0
_info		dc.b	"adapted by Bored Seal & JOTD",10
		dc.b	"Version "
        DECL_VERSION
        dc.b    0
		even


IGNORE_JOY_DIRECTIONS = 1
		include ReadJoypad.s
        
_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
        lea     (_tags,pc),a0
        jsr     (resload_Control,a2)

		move.l	#$528,d1
		move.l	#$160,d2
		lea	$38000,a0
		bsr	LoadRNCTracks

		lea	$3ffe0,a3		;input parameters - a0,a3,d0
		move.l	#$29190,d0
		bsr	Decrunch

        movem.l d0-d1/a0-a2,-(a7)
        sub.l   a1,a1
        lea pl_boot1(pc),a0
        move.l  _resload(pc),a2
        jsr (resload_Patch,a2)
        movem.l (a7)+,d0-d1/a0-a2

		jmp	$40004

pl_boot1
    PL_START
    PL_R	$4014a
    PL_B	$40a78,$60

    PL_P	$40d32,LoadRNCTracks

    PL_P	$41d88,Decrunch2

    PL_PA	$40d2e,PatchFWDizzy

    PL_P	$41d74,PatchTreasure
    
    PL_END
    
PatchTreasure
    bsr _detect_controller_types
    moveq	#0,d7
    movem.l d0-d1/a0-a2,-(a7)
    lea pl_treasure(pc),a0
    sub.l   a1,a1
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
	jmp	$400.W

pl_treasure
    PL_START
    PL_PS	$b72,_Keybd		;Detect quit key
    PL_L	$4060,$bfe201		;move.b ($bfe2ff).l,d0->$bfe201
    PL_L	$406a,$bfe201		;move.b d0,($bfe2ff).l,d0->$bfe201
    PL_IFC2
    PL_S    $406e,$82-$6e       ; skip fire read completely
    PL_PS	$4082,_CD32_Read	;move.w ($dff00c),d0
    PL_P	$4e02,_CD32_WaitUnpause	;cmpi.b #1,d0 and bne.w $4e2c (rts)
    PL_ELSE
    PL_L	$4070,$bfe001		;$bfe0ff->$bfe001
    PL_ENDIF
    PL_END


_CD32_Read	movem.l	d0-d7/a0-a6,-(sp)
		bsr	_joystick
		move.l	joy1(pc),d0
		bsr	_CD32_Quit
		bsr	_CD32_Fire
		bsr	_CD32_Jump
		bsr	_CD32_Pause
		movem.l	(sp)+,d0-d7/a0-a6
		move.w	($dff00c).l,d0
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
        bclr	#8,d0
        btst	#9,d0
        beq.b	.noneed
        bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed        
		rts

_CD32_Quit	btst	#JPB_BTN_REVERSE,d0
		beq	.notquit
		btst	#JPB_BTN_FORWARD,d0
		beq	.notquit
		btst	#JPB_BTN_YEL,d0
		bne	_quit
.notquit	rts

_CD32_Fire	btst	#JPB_BTN_RED,d0
		beq	.notfire
		move.b	#$80,($786).w		;Fake pressing fire
.notfire	rts

_CD32_Jump	move.l	#JPB_BTN_BLU,d2
		btst.l	d2,d0
		beq	.notblue
		ori.b	#1,($786).w		;Fake pressing up
.notblue	rts

_CD32_Pause	lea	_held_button(pc),a0
		move.l	#JPB_BTN_PLAY,d2
		btst.l	d2,d0
		beq	.notpause
		btst.l	d2,(a0)
		bne	.held
		bset.l	d2,(a0)
		eor.b	#1,($789).w		;Toggle pause on/off
		rts
.notpause	bclr	d2,(a0)
.held		rts

_CD32_WaitUnpause
		cmpi.b	#1,d0
		bne	.notpause
		bsr	_CD32_Read		;To detect unpause key
		jmp	$4e0a.w			;(trashes d0 but no problem)
.notpause	rts

;======================================================================
_held_button	dc.l	0			;For CD32 pause
;======================================================================


_quit
        pea	TDREASON_OK
        move.l	_resload(pc),-(a7)
        addq.l	#resload_Abort,(a7)
        rts

   
_Keybd		not.b	d0			;Stolen code
		ror.b	#1,d0
		move.w	d0,d1

		cmp.b	_keyexit(pc),d0
		beq	_quit
		rts
    
PatchFWDizzy
    ;bsr _detect_controller_types
    
    movem.l d0-d1/a0-a2,-(a7)
    lea controller_joypad_1(pc),a0
    ; force 2 button joystick, faster to read
    ; we don't use other buttons anyway
    clr.b   (a0)
    lea pl_fwdizzy(pc),a0
    sub.l   a1,a1
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
	jmp	$13000

pl_fwdizzy
    PL_START
    PL_P	$1340a,LoadRNCTracks

    PL_PSS  $1ca48,BlitFix401,2
    PL_PSS  $1ca64,BlitFix401,2
    PL_PSS  $1ca80,BlitFix401,2
    PL_PSS  $1ca9c,BlitFix401,2
    PL_PSS  $1caf8,BlitFix401,2
    PL_PSS  $1cb14,BlitFix401,2
    PL_PSS  $1cb30,BlitFix401,2
    PL_PSS  $1cb4c,BlitFix401,2

    PL_PS   $200de,kbint_hook

    PL_PS   $4550,BeamDelay

	PL_IFC1
	PL_W	$15216,$6008
    PL_ENDIF
    
    PL_IFC2
    PL_PS   $201aa,read_joy1dat_d0
    PL_PSS  $1d6c2,vbl_hook,2

    PL_ENDIF
    
    PL_END
    
kbint_hook
	MOVE.B	D0,$20092
    cmp.b   _keyexit(pc),d0
    beq _quit
    rts
    
vbl_hook
   	ADDI.B	#$01,$1d707
    bra    _joystick
    
; replace joystick UP by 2nd button
; returns JOY1DAT in D0, modified by button 2 press
; (up cancelled if button 2 not pressed)
; < nothing (uses buttons_state 32bit var)
; > D0: modified JOY1DAT
read_joy1dat_d0:
	movem.l	d1/a0,-(a7)
	move.l	joy1(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
	tst.b  $24a02
	bne.b	.no_blue    ; in menu: leave up as is
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
 
BeamDelay	move.l  d0,-(sp)
		moveq	#2,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0	; VPOS
BM_2		cmp.b	$dff006,d0
		beq	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
End		move.l	(sp)+,d0
		rts

BlitFix401	move.w	#$401,$dff058
    btst	#6,$dff002
BlitWait	btst	#6,$dff002
		bne	BlitWait
		rts

LoadRNCTracks	movem.l a0-a2/d0-d3,-(sp)
		mulu.w	#$200,d1
		mulu.w	#$200,d2
		move.l	d1,d0
		move.l	d2,d1
		moveq	#1,d2
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		movem.l (sp)+,a0-a2/d0-d3
		clr.l	d0
		rts

;powerpacker20 routine
Decrunch	MOVE.L	D0,D1
		MOVEA.L	A0,A1
		MOVEA.L	A0,A2
		MOVE.L	(4,A1),D7
		LEA	(8,A1),A1
		MOVE.W	D1,D2
		LSR.L	#4,D1
		SUBQ.W	#1,D1
		BMI.B	lab16
lab1		MOVE.L	(A1)+,(A2)+
		MOVE.L	(A1)+,(A2)+
		MOVE.L	(A1)+,(A2)+
		MOVE.L	(A1)+,(A2)+
		DBRA	D1,lab1
lab16		ANDI.W	#15,D2
		SUBQ.W	#1,D2
		BMI.B	lab17
until3		MOVE.B	(A1)+,(A2)+
		DBRA	D2,until3
lab17		SUBQ.L	#8,D0
		ADDA.L	D0,A0
		LEA	(value1,PC),A5
		MOVE.L	D7,(A5)
		MOVEQ	#1,D4
		MOVEQ	#1,D5
		MOVEQ	#3,D6
		MOVEQ	#7,D7
		MOVEA.L	A3,A2
		MOVE.L	-(A0),D1
		TST.B	D1
		BEQ.B	lab15
		BSR.B	lab9
		SUB.L	D4,D1
		LSR.L	D1,D5
lab15		LSR.L	#8,D1
		ADDA.L	D1,A3
lab18		BSR.B	lab9
		BCS.B	lab6
		MOVEQ	#0,D2
lab14		MOVE.W	D4,D0
		BSR.B	lab10
		ADD.W	D1,D2
		CMP.W	D6,D1
		BEQ.B	lab14
lab13		MOVEQ	#7,D0
		BSR.B	lab10
		MOVE.B	D1,-(A3)
		DBRA	D2,lab13
		CMPA.L	A3,A2
		BCS.B	lab6
		RTS

lab9		LSR.L	D4,D5
		BEQ.B	lab12
		RTS

lab12		MOVE.L	-(A0),D5
		ROXR.L	D4,D5
		RTS

lab8		SUB.W	D4,D0
lab10		MOVEQ	#0,D1
until1		LSR.L	D4,D5
		BEQ.B	lab5
lab11		ROXL.L	D4,D1
		DBRA	D0,until1
		RTS

lab5		MOVE.L	-(A0),D5
		ROXR.L	D4,D5
		BRA.B	lab11

lab6		MOVE.W	D4,D0
		BSR.B	lab10
		MOVEQ	#0,D0
		MOVE.B	(A5,D1.W),D0
		MOVE.W	D1,D2
		CMP.W	D6,D2
		BNE.B	lab3
		BSR.B	lab9
		BCS.B	lab7
		MOVEQ	#7,D0
lab7		BSR.B	lab8
		MOVE.W	D1,D3
lab2		MOVEQ	#2,D0
		BSR.B	lab10
		ADD.W	D1,D2
		CMP.W	D7,D1
		BEQ.B	lab2
		BRA.B	lab4

lab3		BSR.B	lab8
		MOVE.W	D1,D3
lab4		ADD.W	D4,D2
until2		MOVE.B	(A3,D3.W),-(A3)
		DBRA	D2,until2
		CMPA.L	A3,A2
		BCS.B	lab18
		RTS

value1		dc.l	0

;decrucher routine for dizzy2

Decrunch2	MOVEA.L	-(A0),A2
		ADDA.L	A1,A2
		MOVE.L	-(A0),D0
xlab99		MOVEQ	#3,D1
		BSR.B	xlab19
		TST.B	D2
		BEQ.B	xlab22
		CMPI.W	#7,D2
		BNE.B	xlab24
		LSR.L	#1,D0
		BNE.B	xlab26
		BSR.W	xlab5
xlab26		BCC.B	xlab2
		MOVEQ	#10,D1
		BSR.B	xlab19
		TST.W	D2
		BNE.B	xlab24
		MOVEQ	#$12,D1
		BSR.B	xlab19
		BRA.B	xlab24

xlab19		SUBQ.W	#1,D1
		MOVEQ	#0,D2
xunt1		LSR.L	#1,D0
		BEQ.W	xlab6
		ROXL.L	#1,D2
		DBRA	D1,xunt1
		RTS

xlab2		MOVEQ	#4,D1
		BSR.B	xlab19
		ADDQ.W	#7,D2
xlab24		SUBQ.W	#1,D2
xlab21		MOVEQ	#7,D1
xlab20		LSR.L	#1,D0
		BEQ.B	xlab3
		ROXL.L	#1,D3
		DBRA	D1,xlab20
		MOVE.B	D3,-(A2)
		DBRA	D2,xlab21
		BRA.B	xlab22

xlab3		MOVE.L	-(A0),D0
		MOVE.W	#$10,CCR
		ROXR.L	#1,D0
		ROXL.L	#1,D3
		DBRA	D1,xlab20
		MOVE.B	D3,-(A2)
		DBRA	D2,xlab21
xlab22		CMPA.L	A2,A1
		BGE.B	xlab4
		MOVEQ	#2,D1
		BSR.B	xlab19
		MOVEQ	#2,D3
		MOVEQ	#8,D1
		TST.W	D2
		BEQ.B	xlab8
		MOVEQ	#4,D3
		CMPI.W	#2,D2
		BEQ.B	xlab67
		MOVEQ	#3,D3
		CMPI.W	#1,D2
		BEQ.B	xlab10
		MOVEQ	#2,D1
		BSR.B	xlab19
		CMPI.W	#3,D2
		BEQ.B	xlab18
		CMPI.W	#2,D2
		BEQ.B	xlab16
		ADDQ.W	#5,D2
		MOVE.W	D2,D3
		BRA.B	xlab67

xlab16		MOVEQ	#2,D1
		BSR.W	xlab19
		ADDQ.W	#7,D2
		MOVE.W	D2,D3
		BRA.B	xlab67

xlab18		MOVEQ	#8,D1
		BSR.W	xlab19
		MOVE.W	D2,D3
		BRA.B	xlab67

xlab10		MOVEQ	#8,D1
		LSR.L	#1,D0
		BNE.B	xlab12
		BSR.B	xlab5
xlab12		BCS.B	xlab8
		MOVEQ	#14,D1
		BRA.B	xlab8

xlab67		MOVEQ	#$10,D1
		LSR.L	#1,D0
		BNE.B	xlab11
		BSR.B	xlab5
xlab11		BCC.B	xlab8
		MOVEQ	#8,D1
		LSR.L	#1,D0
		BNE.B	xlab9
		BSR.B	xlab5
xlab9		BCS.B	xlab8
		MOVEQ	#12,D1
xlab8		BSR.W	xlab19
		SUBQ.W	#1,D3
xunt2		MOVE.B	(-1,A2,D2.L),-(A2)
		DBRA	D3,xunt2
		BRA.W	xlab99

xlab4		MOVEQ	#0,D0
		RTS

xlab5		MOVE.L	-(A0),D0
		MOVE.W	#$10,CCR
		ROXR.L	#1,D0
		RTS

xlab6		MOVE.L	-(A0),D0
		MOVE.W	#$10,CCR
		ROXR.L	#1,D0
		ROXL.L	#1,D2
		DBRA	D1,xunt1
		RTS

_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0,0
