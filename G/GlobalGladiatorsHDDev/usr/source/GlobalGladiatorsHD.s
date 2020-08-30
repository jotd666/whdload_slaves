		INCDIR	"Include:"
		INCLUDE	whdload.i
	IFD BARFLY
	OUTPUT	GlobalGladiators.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC



	IFD	BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$80000
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base
_name		dc.b	"Global Gladiators",0
_copy		dc.b	"1993 Virgin",0
_info		dc.b	"installed & fixed by Bored Seal & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	even
;-----------------
_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
		move.l	a0,a2

		move.l	#$400,d0
		move.l	#$1200,d1
		moveq	#1,d2			;disk number
		lea	$50000,a0
		move.l	a0,a5
		bsr	Load

;		move.l	#$80000,-4(a5)	;set chip expansion memory
		move.l	_expmem(pc),-4(a5)	;set expansion memory

		lea	pl_boot(pc),a0
		move.l	a5,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		jmp	(a5)

Patch		jsr	$122c.W

		movem.l	a0-a3/d0-d1,-(sp)
		lea	pl_game(pc),a0
		suba.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(sp)+,a0-a3/d0-d1
		
		jmp	$1500.W

pl_boot		PL_START
		PL_W	$30,$601e	;remove disk access
		PL_P	$17e,Loader	;loader for Virgin games
		PL_W	$dc0,$4e71	;patch game
		PL_PS	$dc2,Patch
		PL_END

pl_game		PL_START
		PL_PS	$772e,AccessFault	;24bit access fix
		PL_P	$2d42,Copylock		;skip RNC copylock
		PL_W	$a6b4,$6002		;fix memory routine
		PL_AW	$1be6,$200		;bplcon0 access fixes
		PL_AW	$1ca4,$200
		PL_AW	$30e1a,$200
		PL_AW	$31922,$200
		PL_P	$9BB0,mask_int_6
		PL_PA	$1CEC,mask_int_6
		PL_PA	$1CF4,mask_int_6
		PL_NOP	$6F5E,2
		PL_PS	$6F60,kb_routine
		PL_END

kb_routine:
	not.b	d0
	move.b	d0,($11C,A5)	; stolen
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	rts
		
; avoids crashes on CD32
mask_int_6
	move.w	#$2000,$DFF09C
	btst.b	#0,$BFDD00		; acknowledge CIA-B Timer A interrupt
	RTE
Copylock	move.l	#$e7f4fd52,d5
		move.l	d5,$f4
		jmp	$360e.W

AccessFault	lea	-8(a0),a0
		move.l	(a0),d0
		and.l	#$00ffffff,d0
		rts

Loader		MOVEM.L	D0-D7/A0-A6,-(SP)
		MOVEQ	#0,D0
		MOVE.W	D1,D0
		MULU.W	#$200,D0
		MOVEQ	#0,D1
		MOVE.W	D2,D1
		MULU.W	#$200,D1
		MOVEQ	#0,D2
		MOVE.B	D4,D2
		CMP.B	#3,D2
		BNE.B	LoadData
		MOVEQ	#2,D2
LoadData	BSR.W	Load
		BTST	#4,D3
		BEQ.B	GoBack
		MOVEA.L	A0,A1
		BTST	#5,D3		;this proceeds file with "RLE" header
		BEQ.B	ProcessRLE
		MOVEA.L	A2,A1
ProcessRLE	JSR	$1052.W		; decrunch?
GoBack		MOVEM.L	(SP)+,D0-D7/A0-A6
		MOVEQ	#0,D0
		RTS

Load		MOVEM.L	D0/D1/A0-A2,-(SP)
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		MOVEM.L	(SP)+,D0/D1/A0-A2
		RTS

_resload	dc.l	0
