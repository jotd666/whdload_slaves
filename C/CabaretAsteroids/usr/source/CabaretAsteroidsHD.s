; Resourced by whdslave_resourcer
; a program written by JOTD in 2016
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"CabaretAsteroids.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC


_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	16					; ws_version (was 10)
	dc.w	WHDLF_NoError|WHDLF_EmulTrap
	dc.l	$80000					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$0					; ws_keydebug
_keyexit
	dc.b	$59					; ws_keyexit
_expmem
	dc.l	$0					; ws_expmem
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
;---

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


_name	dc.b	'Cabaret Asteroids',0
_copy	dc.b	'1991 Vertical',0
_info
    dc.b   'installed & fixed by Bored Seal & JOTD',10
	DECL_VERSION
	dc.b	0
_kickname   dc.b    0
;--- version id

    dc.b	0
    even

; IRA V2.00 (Nov  2 2010) (c)1993-95 Tim Ruehsen, (c)2009 Frank Wille



DMACONR		EQU	$DFF002

; 36E3A: keyboard ascii code to test
;000342C2 0c39 0031 0003 6e3a      CMP.B #$31,$00036e3a
;000342E8 0c39 0032 0003 6e3a      CMP.B #$32,$00036e3a
;0003433E 0c39 0061 0003 6e3a      CMP.B #$61,$00036e3a
;00034354 0c39 0072 0003 6e3a      CMP.B #$72,$00036e3a
;00034392 0c39 0020 0003 6e3a      CMP.B #$20,$00036e3a
;0003439C 0c39 007a 0003 6e3a      CMP.B #$7a,$00036e3a

;00036CC8 0c39 007a 0003 6e3a      CMP.B #$7a,$00036e3a
;00036CDA 0c39 0078 0003 6e3a      CMP.B #$78,$00036e3a
;00036CEC 0c39 002f 0003 6e3a      CMP.B #$2f,$00036e3a
;00036CFA 0c39 002e 0003 6e3a      CMP.B #$2e,$00036e3a
;00036D08 0c39 0020 0003 6e3a      CMP.B #$20,$00036e3a
;00036D3A 0c39 0061 0003 6e3a      CMP.B #$61,$00036e3a
;00036DB6 13f0 0000 0003 6e3a      MOVE.B (A0, D0.W*1, $00) == $00039022,$00036e3a
;0003724E 0c39 0020 0003 6e3a      CMP.B #$20,$00036e3a





start:
	LEA	_resload(PC),A1		;07e: 43fa00d6
	MOVE.L	A0,(A1)			;082: 2288
	move.l	A0,A2
	LEA	game(PC),A0		;084: 41fa00d4
	LEA	$1F000,A1
	BSR.S	LoadFile		;08e: 6158
	lea	pl_main(pc),a0
	sub.l	a1,a1
	jsr	(resload_Patch,a2)
	JMP	$34000
	
pl_main:
	PL_START
	; replaces keys
	PL_PSS	$342C2,test_1_player,2
	PL_PSS	$342E8,test_2_player,2
;	PL_PSS	$34392,test_space,2
;	PL_PSS	$36D08,test_space,2
;	PL_PSS	$3724E,test_space,2
	
	PL_P	$3d04e,LoadHS
	PL_P	$3d45c,SaveHS
	PL_P	$34ce2,BlitFix
	PL_PS	$36d88,KbInt
	PL_L	$36de6,$2f104e75
	PL_END

; trashes fire 1!
;test_space:
;	CMP.B #$20,$00036e3a
;	beq.b	.out
;	movem.w	d0,-(a7)
;	btst	#6,$DFF016+1	;check button blue (normal fire2)
;	seq		d0
;	move.w	#$6F00,$DFF034
;	tst.b	d0
;	movem.w	(a7)+,d0
;.out
;	rts
		
test_1_player:
	CMP.B #'1',$00036e3a
	beq.b	.out
	btst	#7,$BFE001
.out
	rts
test_2_player:
	CMP.B #'2',$00036e3a
	beq.b	.out
	btst	#6,$BFE001
.out
	rts
	
LoadFile:
	MOVEM.L	D0-D2/A0-A2,-(A7)	;0e8: 48e7e0e0
	MOVEA.L	_resload(PC),A2		;0ec: 247a0068
	JSR	resload_LoadFileDecrunch(A2)	;f0
	MOVEM.L	(A7)+,D0-D2/A0-A2	;0f4: 4cdf0707
	RTS				;0f8: 4e75

LoadHS		
	MOVEA.L	_resload(PC),A2		;0ec: 247a0068
	lea	hisc(pc),a0
	lea	$1c000,a1
	bsr	LoadFile
	jmp	$3d092

SaveHS		lea	hisc(pc),a0
		lea	$37e80,a1
		move.l	#$1600,d0
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
		jmp	$3d494

KbInt:
	CMP.B	_keyexit(PC),D0	;12a: b03afef3
	BEQ.S	exit		;12e: 671a
	MOVE.B	D0,D1			;130: 1200
	BCLR	#7,D0			;132: 08800007
	RTS				;136: 4e75

BlitFix		move.w	#$9c01,$58(a0)
.BlitWait	btst	#6,DMACONR
		bne	.BlitWait
		rts

exit:
	PEA	-1.W			;14a: 4878ffff
	MOVE.L	_resload(PC),-(A7)	;14e: 2f3a0006
	ADDQ.L	#4,(A7)			;152: 5897
	RTS				;154: 4e75

_resload:
	dc.l	0			;156: 00000000
game:
	dc.b	"game.RNC",0
hisc:
	dc.b 	"hisc",0
	
