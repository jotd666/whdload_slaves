		incdir	"include:"
		include	whdload.i
		IFD	BARFLY
		BOPT	O+ OG+			;enable optimizing
		BOPT	ODd- ODe-		;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		SUPER				;disable supervisor warnings

		OUTPUT	FireForceCD32.slave
		ENDC
DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_base		SLAVE_HEADER
		dc.w	17
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoDivZero
		dc.l	$200000
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
		dc.w	slv_config-_base		;ws_config
slv_config
        dc.b    "C1:X:infinite energy:0;"
        dc.b    "C2:X:infinite ammo:0;"
        dc.b    "C3:X:infinite time:0;"
		dc.b	0

dir		dc.b	"data",0
_name		dc.b	"Fire Force [CD32]",0
_copy		dc.b	"1994 ICE",0
_info		dc.b	"installed & fixed by Bored Seal",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

_Start		lea	_resload(pc),a1
		move.l	a0,(a1)
		move.l	a0,a2

		move.l  #CACRF_EnableI,d0
		move.l  d0,d1
		jsr     (resload_SetCACR,a2)

	;load the osemu module
		lea	(_OSEmu,pc),a0
		lea	($400).w,a3
		move.l	a3,a1
		jsr	(resload_LoadFileDecrunch,a2)

	;init the osemu module
		move.l	a2,a0
		lea	(_base,pc),a1
		jsr	(a3)

	;switch to user mode

		lea	dosname(pc),a1
		clr.l	d0
		movea.l	4,a6
		jsr	-$228(a6)
		move.l	d0,a6

		lea	file(pc),a0
		move.l	a0,d1
		jsr	-150(a6)

		add.l	d0,d0
		add.l	d0,d0
		addq.l	#4,d0
		move.l	d0,a1
		move.l	d0,a5

		lea	_pl_game(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		jmp	(a5)

_pl_game	PL_START
		PL_W	$139be-$13948,$4e71	;no useless wait
		PL_W	$13a62-$13948,$6002	;remove CACR access
		PL_R	$216ee-$13948		;fix access faults
		PL_PS	$1afe4-$13948,KBDelay	;fix kb handler
	
		PL_IFC1
		PL_W	$1bcb8-$13948,$6004
		PL_W	$1bf1a-$13948,$600c
		PL_W	$1f644-$13948,$6006
		PL_W	$20864-$13948,$6006
		PL_W	$213c6-$13948,$6006
		PL_W	$227ea-$13948,$6006
		PL_W	$22922-$13948,$6006
		PL_ENDIF
		
		PL_IFC2
		PL_B	$ab0c,$4a		;unlimited ammo
		PL_B	$9950,$4a
		PL_B	$f9b6,$4a
		PL_W	$bb4,$4e71
		PL_ENDIF
	
		PL_IFC3
		PL_B	$11492,$4a		;unlimited time
		PL_ENDIF
		
		PL_END



KBDelay		moveq	#1,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0
BM_2		cmp.b	$dff006,d0
		beq	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
		rts

_resload	dc.l	0


_OSEmu		dc.b	'OSEmu.400',0
file		dc.b	"fforce.prg",0
dosname		dc.b	"dos.library",0