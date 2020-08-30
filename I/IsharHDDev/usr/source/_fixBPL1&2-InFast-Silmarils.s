
slv_Flags       = WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA|WHDLF_ClearMem

slv_config	DC.B	"C1:X:Vitality trainer:0;"
		DC.B	"C1:X:Phisical trainer:1;"
		DC.B	"C1:X:Mental trainer:2;"
		DC.B	"C1:X:Unlimited coins:3;"
		dc.b	0
		even

;********************************************************
;********************************************************
;********************************************************
;******************* fix GFX bug with fast memory
; as main AGA silmarils game
; code try to take intuituion bitplan adress to preserve memory
; 
; move.l	_intuitionBase,a0
; move.l	$38(a0),a1
; move.l	$c0(a1),a0	=>BPL1ADR of intuition screen
; but it's do'nt work on Kick31 => fast adress is return for BPl1ADR and Game use it for  first BitPlans
;********************************************************
_ChipSCRLg	=$3e80*3		;  but 1 more for security
_ChipSCRAbs	=CHIPMEMSIZE-$10000

_NoEnoughMem	dc.b "No enough chip memory in KickEmul",0
	even
_ADR_RESERVE_chip	dc.l	0
;********************************************************

_TakeChipBPL1AdrFix
	move.l	_ADR_RESERVE_chip(pc),d1
	RTS
;********************************************************

_TakeChipBPL1AdrFixPrep
	movem.l	d0-a6,-(a7)
        LSL.L   #2,D0
        MOVE.L  D0,A0
	IFD _FlashHunk
.t1
	move.w	#$f0,$dff180
	btst	#6,$bfe001
	bne	.t1
	ENDC

	;CMP.L	#$222800C0,$31C(A0)	; move.l	$c0(a0),d1 ; take Intuition BPL1ADR	; ishar 1
	;CMP.L	#$222800C0,$426(A0)	; move.l	$c0(a0),d1 ; take Intuition BPL1ADR	; ISHAR 2
	CMP.L	#$222800C0,$456(A0)	; move.l	$c0(a0),d1 ; take Intuition BPL1ADR	; ishar 3/Robinson Requieù
	bne .nofound
;	move.l	#$4EB80106,$31C(a0)	; Ishar 1/transactica
;	move.l	#$4EB80106,$426(a0)	; Ishar 2
	move.l	#$4EB80106,$456(a0)	; Isahr 3/Robinson
	pea _TakeChipBPL1AdrFix(pc)
	move.w #$4EF9,$106
	move.l	(a7)+,$106+2

;	move.l 4,a6
;	MOVE.L #$3E80*2,D0	; reserve  first BitPLan for game
;	MOVE.L #$10002,D1	; CLEAR & CHIP
;	JSR -198(A6)		; AllocMem		; gfx bug game use it without allocation!!!


	move.l 4,a6
	move.l	#_ChipSCRAbs,a1
	MOVE.L #_ChipSCRLg,D0	; reserve  first 2 BitPLans for game (1 more by security
	JSR -204(A6)		; AllocAbs
	CMP.L	#_ChipSCRAbs+_ChipSCRLg,A0
	beq .ok

; error quit
        move.l  (_resload,pc),a2           ;A2 = resload
	PEA	_NoEnoughMem(pc)
        pea     TDREASON_FAILMSG
        jmp     (resload_Abort,a2)
.ok
	LEA _ADR_RESERVE_chip(PC),A1
	MOVE.L #_ChipSCRAbs,(A1)

.nofound
	movem.l	(a7)+,d0-a6
	rts
;********************************************************
;********************************************************
;********************************************************
