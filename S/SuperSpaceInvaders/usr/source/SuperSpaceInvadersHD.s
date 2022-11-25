; slave by JOTD (c) 2020
; note: there a 5 friggin supported versions of this game
; 2 of them are "early" I suppose, and only have one copylock (v1 & v2)
; they also load multipart which doesn't allow one patchlist but needs 2
; 3 of them (SPS ones + v4) are very similar, with one extra copylock
; before game start. But second part loads at once and allows a nice unique
; patchlist. The loading & unpacking system is also a mess, which explains
; the complex slave. The fact that the game has 5 versions doesn't help either.

	INCLUDE	WHDLoad.i
	include	whdmacros.i
	
QUITKEY		= $59		; F10


; rn copylock key
DISK_KEY = $4C196AC5

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
	
HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap		; flags
	dc.l	$80000		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	_start-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	0	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
_keyexit
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config
	dc.b	"C1:B:Unlimited Lives;"
	dc.b	"C3:B:skip introduction;"
	dc.b	0

.name	dc.b	"Super Space Invaders",0
.copy	dc.b	"1991 Taito",0
.info	dc.b	"adapted by JOTD",10,10

	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	CNOP	0,2

PATCH_NOP:MACRO
	move.w	#$4E71,\1
	ENDM
	
_resload	dc.l	0

	;INCLUDE	ReadJoyPad.s

_start
	lea	_resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2
	
	lea	(tag,pc),a0
	jsr	(resload_Control,a2)


	; 3+ versions supported (some versions have the same code but different disk 2)

	bsr	check_version

	lea	TRAP2(pc),A0
	move.l	A0,$88.W

	move.l	#$3C00,D1	; 68000 program offset (V2), program offset (V1), V3/C585

	move.l	version(pc),D0
	cmp.l	#2,D0
	bne	.skip

	move.l	cpuflags(pc),d0
	btst	#AFB_68020,D0
	beq	.skip
	move.l	#$E00,D1
.skip

	lea	$60200,a0
	move.l	d1,d0	; offset
	move.l	#$2000,d1	; size
	moveq.l	#1,d2
	
	bsr	_loaddisk

	lea	pl_boot_common(pc),a0

	; correct stackframe on V1

	move.l	version(pc),D0
	cmp.l	#2,D0
	beq	.goon

.v1:

	move.l	cpuflags(pc),d0
	btst	#AFB_68020,D0
	beq	.goon		; don't patch stackframe if below 68020!!

	; version 1
	lea	pl_boot_v1(pc),a0

.goon:
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	moveq	#0,D0
	jmp	$60200

	
pl_boot_common:
	PL_START
	PL_P	$60CF6,_robread
	PL_P	$60228,Jump70000
	PL_W	$604B6,$4E42 ; trap memory detection
	PL_END
pl_boot_v1:
	PL_START
	PL_PS	$603D2,SaveRegs
	PL_W	$603D2+6,$548F		; add 2 to A7, correct stackframe error
	PL_PS	$6030E,SaveRegs
	PL_W	$6030E+6,$548F		; add 2 to A7, correct stackframe error

	PL_W	$60326,$558F
	PL_PS	$60326+2,RestoreRegs
	PL_W	$60418,$558F
	PL_PS	$60418+2,RestoreRegs	; inverse operation
	PL_NEXT		pl_boot_common
	
SaveRegs:
	lea	stacksave(pc),A0
	move.w	4(A7),(A0)	; save stack part to be destroyed by BSRs
				; in the call

	lea	$61778,A0
	movem.l	D1-D7/A1-A6,(A0)
	rts

; I know this code is bad, but this was ported as quickly as possible
; from old JST install.

; this is entered several times, first when loading, then afterwards

TRAP2:
	movem.l	d0-a6,-(a7)

	; remove expansion memory detection, assume 512K only

	CMPI.L	#$1080B010,$8F56
	BNE	LAB_0008
	
	MOVE.W	#$6028,$8F1E		; V2, 68020+ fixed

	PATCH_NOP	$842C		; no need to press spacebar to swap disk
	patch	$7D04,decrunch
	lea	$7F32.W,A0
	move.l	skip_intro(pc),d0
	beq.b	.nosk2
	move.w	#$4EF9,(a0)
	move.l	#$842E,(2,a0)
.nosk2
	bsr	InitICE
LAB_0008:
	CMPI.L	#$1080B010,$8FD0
	BNE	LAB_0009

	MOVE.W	#$6028,$8F98		; V1, originally 68000 only
	PATCH_NOP	$84A6		; no need to press spacebar to swap disk
	patch	$7D7E,decrunch

	move.l	skip_intro(pc),d0
	lea	$7FAC.W,A0
	beq.b	.nosk1
	move.w	#$4EF9,(a0)
	move.l	#$84A8,(2,a0)
.nosk1
	bsr	InitICE
LAB_0009:

	cmp.l	#$08E80000,$66D2.W
	bne	.no_version1
	; called when game is loaded
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_game_v1(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

.no_version1
	cmp.l	#$08E80000,$6658.W
	bne	.no_version2
	; called when game is loaded

	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_game_v2(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

.no_version2

	cmp.l	#$08E80000,$67C6.W
	bne	.nokbint3
	; version 3, but version 1 also has this "signature"!!
	
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	version(pc),d0
	move.l	version(pc),d0
	cmp.l	#1,d0
	beq.b	.zap
	lea	pl_game_C585(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
.zap
	movem.l	(a7)+,d0-d1/a0-a2

.nokbint3
	; version 5/c2480 ?
	cmp.l	#$E80000,$9882
	bne	.noversion2480


	lea	$7FAC-$7A,A0
	bsr	InitICE	

	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_game_C2480(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
.noversion2480
	
	bsr	_flushcache
	movem.l	(a7)+,d0-a6

	; starts the intro

	JSR	(A0)			;13C: 4E90
	RTE				;13E: 4E73

	;PL_W	$8F98,$6028		; V1, originally 68000 only
	;PL_NOP	$84A6,2		; no need to press spacebar to swap disk
	;PL_P	$7D7E,decrunch

	;PL_IFC3
	;PL_W	$7FAC,$4EF9
	;PL_L	$7FAE,$84A8
	;PL_ENDIF

pl_game_v1
	PL_START



	PL_PSS	$74EC,SetDisk1_V1,2
	PL_PS	$66D2,KbInt
	PL_IFC1
	PL_NOP		$13948,8
	PL_ENDIF
	PL_END

pl_game_v2
	PL_START
	PL_PSS	$7472,SetDisk1_V2,2
	PL_PS	$6658,KbInt
	PL_IFC1
	PL_NOP		$138CE,8
	PL_ENDIF
	PL_END

pl_game_C585
	PL_START
	PL_W	$98FA,$6028
	PL_L	$68DE,$317CCC01

	; V3/C585, skip press spacebar
	PL_NOP	$84A6,2
	; skip copylock jump to $8E1A	
	; skip copylock jump to end
	PL_W	$84B8,$4EF9
	PL_L	$84BA,$8E1A		; skip copylock

	PL_P	$7D7E,decrunch
	PL_IFC3
	PL_W	$7FAC,$4EF9
	PL_L	$7FAE,$84A8
	PL_ENDIF	
	
	PL_PS	$67C6,KbInt
	PL_PS	$4B0,game_patch

	PL_END
	
pl_game_C2480
	PL_START
	PL_W	$9880,$6028

	; V3/C585, skip press spacebar
	PL_NOP	$0000842C,2
	; skip copylock jump to end
	PL_W	$84B8-$7A,$4EF9
	PL_L	$84BA-$7A,$8E1A-$7A		; skip copylock
	
	PL_P	$7D7E-$7A,decrunch

	PL_IFC3
	PL_W	$7FAC-$7A,$4EF9
	PL_L	$7FAE-$7A,$84A8-$7A
	PL_ENDIF	
	
	PL_PS	$0000674C,KbInt
	PL_PS	$4B0,game_patch_c2480
	PL_END

	
	
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
	
game_patch_c2480
;	CMP.L	#$303C0004,$6F56
;	BNE.S	.noclock_c2480
	; second copylock
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_c2480_main(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
;.noclock_c2480	
	move.l	$174A.W,a0	; original
	bsr	_flushcache
	rts
	
game_patch:
	CMPI.L	#$1F10303C,$8E6A
	BNE.S	.no
	; ?????
	move.w	#$6028,$8E38		; V3 & V4/C585, second memory detection
.no
	CMPI.L	#$303C0004,$6FD6
	BNE.S	.noclock_v3
	; second copylock
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_c585_main(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	bra.b	.out
.noclock_v3
	CMPI.L	#$303C0004,$6FD0
	BNE.S	.noclock_v4
	; second copylock
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_v4_main(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	
.noclock_v4

.out
	move.l	$17C4.W,a0
	bsr	_flushcache
	rts

fix_second_copylock_c585:
	move.l	#DISK_KEY,d0	; copylock id
	jmp	$792E.w
fix_second_copylock_c2480:
	move.l	#DISK_KEY,d0	; copylock id
	jmp	($792E-$80).w
		
pl_c585_main
	PL_START
	PL_P	$6FD6,fix_second_copylock_c585
	;PL_PSS	$74EC,SetDisk1_V1,2
	PL_IFC1
	PL_NOP		$0001424E,8
	PL_ENDIF

	PL_END
	
pl_c2480_main
	PL_START
	PL_P	$6F56,fix_second_copylock_c2480
	PL_IFC1
	PL_NOP		$0001418A,8
	PL_ENDIF

	PL_END
	
pl_v4_main
	PL_START
	PL_P	$6FD6,fix_second_copylock_v4
	;PL_PSS	$74EC,SetDisk1_V1,2
	PL_IFC1
	PL_NOP		$00014204,8
	PL_ENDIF

	PL_END

fix_second_copylock_v4:
	move.l	#DISK_KEY,d0	; copylock id
	jmp	$00007928.w

	
Jump24A:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_24a(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	jmp	$24A.W

pl_24a:
	PL_START
	PL_PS	$634,CheckDisk2
	;PL_P	$AC2,decrunch		; needs decruncher init
	PL_END

SetDisk1_V1
	lea	$16D61,a0		; stolen code
	bra	SetDisk1
SetDisk1_V2
	lea	$16CE7,a0		; stolen code
	bra	SetDisk1
	; not the same code at all for v3
SetDisk1_C585
;;	lea	$xxxxx,a0		; stolen code
;;	bra	SetDisk1

SetDisk1
	movem.l	a0,-(a7)
	lea	diskunit(pc),a0
	clr.l	(a0)
	movem.l	(a7)+,a0
	rts
	
RestoreRegs:
	move.w	stacksave(pc),4(A7)	; restore stack part

	movem.l	(A0),D1-D7/A1-A6
	lea	$61778,A0
	rts

	;bsr	_detect_controller_types

; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

check_version:
	lea	version(pc),a3
	moveq.l	#1,D2
	move.l	#$200,D0
	move.l	#$700,D1
	lea	$60200,A0
	bsr	_loaddisk
	move.l	$608A0,D0
	cmp.l	#$00D5,D0
	bne	.nov2
	move.l	#2,(a3)
	rts
.nov2
	cmp.l	#$00D6,D0
	bne	.nov1
	move.l	#1,(a3)
	rts

.nov1
	cmp.l	#$00DB,D0
	bne	.nov3
	move.l	#3,(a3)
	rts
.nov3		; also v4
	cmp.l	#$00DA,D0
	bne	.no2480
	move.l	#5,(a3)
	rts
.no2480
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

CheckDisk2:
	movem.l	D0-D7/A0-A6,-(a7)
	lea	siprgname(pc),a1
	bsr	strcmp
	tst.l	D0
	bne	.nodisk2
			
	lea	diskunit(pc),a0
	move.l	#1,(a0)
.nodisk2
	movem.l	(A7)+,D0-D7/A0-A6

	jsr	$7A2.W
	tst.l	D0
	rts

Jump70000:
	patch	$70012,Jump24A
	bsr	_flushcache
	jmp	$70000

; < a0: str1
; < a1: str2
; > d0: -1: fail, 0: ok

strcmp:
	movem.l	d1/a0-a2,-(A7)
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
	movem.l	(A7)+,d1/a0-a2
	rts


; Rob Northen track loading routine
; < A0: buffer
; < D0: disk number (hardcoded)
; < D1: sector offset (*$200)
; < D2: sector length (*$200)
; < D3: command (ignored)
; > D0: 0 if ok (which is all the time :))

_robread:
	movem.l	d1-d3/a0-a2,-(A7)
	move.l	diskunit(pc),D0

	and.b	#$FF,D3
	bne.b	.exit

	move.l	d0,d3		; disk number stored
	
	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.exit		; length=0: out

	move.l	D1,D0
	ext.l	d0
	lsl.l	#7,d0			;diskoffset
	lsl.l	#2,d0

	move.l	D2,D1			;len to read
	ext.l	d1
	lsl.l	#7,d1
	lsl.l	#2,d1

	move.l	D3,D2
	addq.l	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)
.exit
	movem.l	(A7)+,d1-d3/a0-a2
	bsr	_flushcache
	moveq.l	#0,D0
	rts
	
KbInt:
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
	bset	#0,$E00(A0)
	rts
	

decrunch:
	bra.b	ICEDecrunch+$20
	
; I had to include the binary because BASM crashes
; (but phxass assembled it OK)
InitICE:
	bra.b	ICEDecrunch+$24

ICEDecrunch:
	incbin	"icedecrunch.bin"

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_loaddisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts


tag		dc.l	WHDLTAG_ATTNFLAGS_GET
cpuflags	dc.l	0
	dc.l	WHDLTAG_CUSTOM3_GET
skip_intro
	dc.l	0
	dc.l	0
version
	dc.l	0
stacksave:
	dc.l	0
diskunit:
	dc.l	0	
siprgname:
	dc.b	"SI.PRG",0

