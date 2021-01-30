;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	IFD BARFLY
	OUTPUT	"LeisureSuitLarry2.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;CHIPMEMSIZE	= $100000
;FASTMEMSIZE	= $0000
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
IOCACHE = 50000

;HRTMON
;SETPATCH
MAINPROG
;============================================================================


	include	"sierra_hdinit.s"
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"Leisure Suit Larry 2",0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"Adapted & fixed by JOTD",10,10
			dc.b	"At protection screen:",10,10
			dc.b	"Enter 1111 to pass protection",10
			dc.b	"Enter 2222 to pass protection & intro",10,10
			dc.b	"Thanks to BTTR for disk images",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
			EVEN


_mainprog:
	dc.b	4,"lsl2",0
	even

; < d1 seglist APTR
; use _get_section to compute segments

_specific_patch
	; section 14:protection
    add.l   d1,d1
    add.l   d1,d1
	move.w	#14,d2
	bsr	_get_section
	add.l	#$E7E-$2FC,a0

	move.w	#$4EB9,(a0)+
	pea	_crack(pc)
	move.l	(a7)+,(a0)
	
	moveq.l	#0,d0
	rts

_crack
	MOVEM.L	8(A5),A0-A2		;4E: 4CED07000008
	MOVEM.L	D0-D1,-(A7)		;54: 48E7C000
	MOVE.L	.flag(pc),D0		;58: 203900000000
	BNE	.lb_0008		;5E: 6644
	MOVE	#$03FF,D0		;60: 303C03FF
.lb_0002:
	LEA	.lb_0009(PC),A0		;64: 41FA004A
.lb_0003:
	MOVE.B	(A0),D1			;68: 1210
	CMP.B	(A1)+,D1		;6A: B219
	BEQ.S	.lb_0004		;6C: 6706
	DBF	D0,.lb_0003		;6E: 51C8FFF8
	BRA	.lb_0008		;72: 6030
.lb_0004:
	ADDQ.L	#1,A0			;74: 5288
.lb_0005:
	MOVE.B	(A0)+,D1		;76: 1218
	BEQ.S	.lb_0006		;78: 6706
	CMP.B	(A1)+,D1		;7A: B219
	BNE.S	.lb_0002		;7C: 66E6
	BRA.S	.lb_0005		;7E: 60F6
.lb_0006:
    add.l   #15*9,a1    ; skip all standard telephone codes
	ADDQ.L	#5,A1			;84: 5A89
    ; this overwrites Al Lowe's birthday code (0724)
    ; that starts the game immediately, without intro
    ; now replaced by 2222
    move.b  #$32,d0
	MOVE.B	d0,(A1)+		;86: 12FC0031
	MOVE.B	d0,(A1)+		;8A: 12FC0031
	MOVE.B	d0,(A1)+		;8E: 12FC0031
	MOVE.B	d0,(A1)+		;92: 12FC0031
    ; this overwrites another undocumented code (7915)
    ; that starts the game, but with intro
    ; now replaced by 1111
    move.b  #$31,d0
	ADDQ.L	#5,A1			;84: 5A89
	MOVE.B	d0,(A1)+		;86: 12FC0031
	MOVE.B	d0,(A1)+		;8A: 12FC0031
	MOVE.B	d0,(A1)+		;8E: 12FC0031
	MOVE.B	d0,(A1)+		;92: 12FC0031

	lea	.flag(pc),a1
	move.l	#-1,(a1)

;;	MOVE.L	#$FFFFFFFF,EXT_0000	;9A: 23FCFFFFFFFF00000000
.lb_0008:
	MOVEM.L	(A7)+,D0-D1		;A4: 4CDF0003
	MOVEM.L	8(A5),A0-A2		;A8: 4CED07000008
	RTS				;AE: 4E75
.lb_0009:
	DC.W	$5374			;B0
	DC.W	$6172			;B2
	DC.W	$7469
	DC.W	$6E67			;B6
	DC.W	$2052
	DC.W	$6F6F			;BA
	DC.W	$6D00			;BC
	DC.W	$0416			;BE
	DC.W	$6308			;C0
	DC.W	$2B7C			;C2

.flag
	dc.l	0
