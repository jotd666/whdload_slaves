
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	ZoolECS.slave
	OPT	O+ OG+			;enable optimizing
	ENDC

;DEBUG
;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		IFD	DEBUG
		dc.l	$100000		;ws_BaseMemSize
		ELSE
		dc.l	$80000
		ENDC
		
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
		dc.b	0		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem	
	IFD	DEBUG	
	dc.l	0			;ws_ExpMem
	ELSE
	dc.l	$80000
	ENDC
	
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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
_data   dc.b    0
_name	dc.b	'Zool (ECS)'
	IFD	DEBUG
	dc.b	" (debug mode)"
	ENDC
	dc.b	0
_copy	dc.b	'1992 Gremlin',0
_info
    dc.b   'adapted by JOTD',10,10
	dc.b	'Thanks to Codetapper for RawDIC imager',10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	
_config
	dc.b	0
;	dc.b	"BW;"
;    dc.b    "C1:X:Infinite lives:0;"



	dc.b	'$VER: Zool by JOTD - '
	DECL_VERSION
	dc.b	0
	CNOP 0,2

BASE_ADDRESS = $70000

;======================================================================
Start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
		
	move.l	_resload(pc),a2
	lea	Tags(pc),a0
	jsr	resload_Control(a2)		

	lea	BASE_ADDRESS,A0
	move.l	#$0,D0		; offset
	move.l	#$1800,D1		; length
	moveq	#1,D2
	bsr	_loaddisk
	lea	BASE_ADDRESS,A0
	move.l	#$1800,d0
	jsr	resload_CRC16(a2)

	
	cmp.l	#$9A2,d0	; ECS, protected
	beq.b	.ok
	cmp.l	#$788C,d0	; ECS, unprotected
	beq.b	.ok
	cmp.l	#$A2A3,d0	; ECS,SPS 2426
	beq.b	.ok
	cmp.l	#$4EFE,d0	; ECS,AmigaFun, different
	beq.b	.amigafun
;	cmp.l	#$C0A6,d0	; ECS,SPS 893
;	beq.b	.ok
.wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.ok
	bsr	PatchProg1

	jmp	BASE_ADDRESS
	
BASE_ADDRESS_AF = $72000

.amigafun
	lea	BASE_ADDRESS_AF,A0
	move.l	#$400,D0		; offset
	move.l	#$C00,D1		; length
	moveq	#1,D2
	bsr	_loaddisk

	lea	BASE_ADDRESS_AF,A0
	move.l	#$C00,D0
	jsr	resload_CRC16(a2)
	cmp.w	#$A8E5,D0
	bne	.wrong_version	; just another check

	lea	pl_boot_af(pc),a0
	lea	BASE_ADDRESS_AF,A1
	jsr	resload_Patch(a2)
	
	IFD	DEBUG
	move.l	#$80000,A0
	ELSE
	move.l	_expmem(pc),A0
	ENDC


	jmp	BASE_ADDRESS_AF

pl_boot_af
	PL_START
	PL_P	$6F4,DosTrackRead
	PL_P	$500,FungusDecrunch
	PL_P	$1B2,patch_main_af
	PL_END

patch_main_af
	patch	$100.W,EmulateDbf

	; disk, mem & kb functions

	IFD	DEBUG
	move.l	#$80000,$2156.W
	ELSE
	move.l	_expmem(pc),$2156.W
	ENDC

	; hiscore read

	lea	$4016.W,A1
	bsr	LoadHiscore

	sub.l	a1,a1
	lea	pl_main_af(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	; flush and go

	jmp	$1002.W
	
pl_main_af
	PL_START
	PL_P	$58FE,DosTrackRead
	PL_PS	$60F6,kbint_af
	PL_PS	$60FC,AckKb
	PL_NOP	$6108,4
	PL_P	$622E,FungusDecrunch
	PL_PS	$8CEE,SwapDisks
	PL_IFBW
	PL_ELSE
	; remove buttonwait if not requested
	PL_NOP	$7084,4
	PL_ENDIF
	
	; USP read, can change stack location
	;;PL_W	$60C2,$204F
	
	PL_P	$EEAA,SaveHiscore	
	
	; disk swap

	PL_NOP	$8CF4,6

	; dbf delays (music does not work properly)

	PL_L	$475E,$4EB80100
	PL_L	$4772,$4EB80100
	PL_L	$8B5A,$4EB80100
	PL_END
	
;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_loaddisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

PatchProg1:
	movem.l	D0-A6,-(a7)

	; ** Patch strategic locations
	
	lea	BASE_ADDRESS,A0
	cmp.l	#$33FC7FFF,$1BC(A0)
	bne	.nopatch

	; ** corrects some differences with another version (protected, different)
	lea	$1BC(A0),A1
	move.l	#$23FC6000,(A1)+
	move.l	#$040A0000,(A1)+
	move.l	#$6FA64E71,(A1)+
	move.l	#$4E714E71,(A1)+

.nopatch
	lea	BASE_ADDRESS,A1
	lea	pl_prog_1(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)


	movem.l	(a7)+,D0-A6
	rts
pl_prog_1:
	PL_START
	; ** NIBREAD #1

	PL_P	$662,NibRead
	PL_P	$52a,FUN_0000		;Fungus decruncher

	; ** Cancel some disk-related code

	PL_W	$B38,$6028
	PL_R	$6EC			;Disk access
	PL_R	$730			;Turn on DF0:
	PL_R	$75C			;Turn off DF0:

	PL_NOP	$754,2
	PL_NOP	$81A,2

	PL_W	$126,10			;Delay on Chupa Chups picture

	; ** Lay in the new patch
	PL_P	$1CC,PatchLoader1

	; ** Set the kbint

;	lea	$BBE(A0),A1
;	GETUSRADDR	kbint
;	move.w	#$4EB9,(A1)+
;	move.l	D0,(A1)
	PL_END

SwapDisks:

	movem.l	D0/A0,-(A7)
	lea	currdisk(PC),A0
	move.w	(A0),D0
	cmp.w	#1,d0
	beq	.setto2
	moveq.l	#1,D0
	bra	.setvar
.setto2
	moveq.l	#2,D0
.setvar
	move.w	D0,(A0)
	movem.l	(A7)+,D0/A0
	rts

PatchLoader1:
	movem.l	D0-A6,-(a7)

	; *** remove cpu dependent loops (music)

	patch	$100,EmulateDbf
	lea	$1000.W,A0
	lea	$A000,A1
	move.l	#$51C8FFFE,D0
	move.l	#$4EB80100,D1
	bsr	hex_replace_long

	; ** fix SNOOP faults

	lea	$B000,A0
	lea	$25000,A1
	lea	.dmachange(pc),A2
	move.l	#8,D0
.loopdma
	bsr	hex_search
	cmp.l	#0,A0
	beq.b	.enddma
	pea	FixForceDma(pc)
	move.l	#$4E714EB9,(a0)+
	move.l	(a7)+,(a0)+
	bra.b	.loopdma
.enddma

	
	; *** Version Test

	cmp.l	#$6600FFF2,$705E.W
	bne	.version_wp

	lea	pl_protected(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)

	; hiscore

	lea	$4000.W,A1
	bsr	LoadHiscore

	bra	.exit

	; ***************************
	; *** Unprotected version ***
	; ***************************

.version_wp
	lea	pl_unprotected(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)

	; ** load the scores

	lea	$4016.W,A1
	bsr	LoadHiscore

.exit

	movem.l	(a7)+,D0-A6

	jmp	$1002.W


.dmachange
	dc.l	$08F90006,$00DFF002
pl_unprotected:
	PL_START
	; ** Nibload patch (not necessary but speeds up loading)
	PL_P	$5730,NibRead
	; ** Lower level
	PL_P	$5910,ReadTrack
	; ** Set the track
	PL_P	$5866,SetTrack
	; ** Set the diskchange patch
	PL_PS	$8CEE,SwapDisks

;	move.w	#$600C,$8B6A	; remove a disk ready test

	; ** Decrunch faster
	PL_P	$623C,FungusDecrunch

	; ** Remove Disk-Inserted check
	
	PL_R	$58DC
	PL_R	$57F8		; for disk check
	PL_R	$579A		; for disk check v1.4
	PL_R	$5834		; v1.4
	PL_NOP	$582C,2		; for disk check
	PL_NOP	$590C,2		; for disk check

	PL_W	$8B10,$6074		; disk change (v1.4)

	; ** Enable 2nd button = space

	PL_PS	$ACA4,emuspace

	; ** Enable quit by F10

	PL_PS	$60F6,kbint3
	PL_W	$60FC,$6014

	; ** Patch the memory extension detection

	PL_P	$6EE8,GetExt_2
	; ** Install hiscore save
	PL_P	$EEAA,SaveHiscore_V2
	PL_END
	
pl_protected:
	PL_START
	; *************************
	; *** Protected version ***
	; *************************

	; ** Remove Disk-Inserted check

	PL_R	$58C6		;Step a track
	PL_R	$57E2		; for disk check
	PL_R	$581E		; for drive light
	PL_R	$5784		; for drive light

	PL_W	$8B38,$600C

	PL_NOP	$5816,2		; for disk check
	PL_NOP	$58F6,2		; for disk check
	
	PL_W	$8ADE,$6074		; drive change

	; ** Nibload patch (not necessary but speeds up loading)
	PL_P	$571A,NibRead

	PL_I	$6fa4			;Infinite loop erasing memory
	; ** Lower level disk routine	
	PL_P	$58FA,ReadTrack

	; ** Set the track
	PL_P	$5850,SetTrack

	; ** Crack the protected version

	PL_NOP	$705E,4
	PL_W	$737A,$60A6

	; ** Set the diskchange patch

	PL_PS	$8CBC,SwapDisks
	PL_W	$8CC2,$6004

	; ** Decrunch faster

	PL_P	$6218,FungusDecrunch
	; ** Enable quit by F10 + fix kb

	PL_PS	$60E0,kbint2
;	move.l	#$4E714E71,$60F2.W
	PL_W	$60E6,$6014

	; ** Patch the memory extension detection

	PL_P	$6ED2,GetExt_1
	; ** Install hiscore save

	PL_P	$EE78,SaveHiscore_V1
	PL_END
	
emuspace:
	move.b	spcpress(pc),D0
	bne	.skip
	move.b	#$00,$60BA.W		; no key
.skip
	move.w	#$CC01,$DFF034
	move.w	$DFF016,D0
	btst	#14,D0
	bne	.exit
	move.b	#$40,$60BA.W		; space pressed
.exit
	move.w	#$CC01,$DFF034

	move.w	$DFF01E,D0		; original proggy
	rts

FixForceDma:
	rts

SaveHiscore_V1:
	lea	$4000.W,A1
	bra	SaveHiscore

SaveHiscore_V2:
	lea	$4016.W,A1

; < A1: source
SaveHiscore:
	move.w	#$F,$DFF096	; stolen code
	
	movem.l	D0-A6,-(a7)
	lea	scores_name(pc),A0
	move.l	#$110-$16,D0		; length: 4
	move.l	_resload(pc),a2
	jsr	(resload_SaveFile,a2)
	movem.l	(a7)+,D0-A6
	rts

; < A1: start

LoadHiscore:
	movem.l	D0-A6,-(a7)
	lea	scores_name(pc),A0
	move.l	_resload(pc),a2
	movem.l	A1,-(a7)
	jsr	(resload_GetFileSize,a2)
	movem.l	(a7)+,a1
	tst.l	d0
	beq.b	.nohighs
	lea	scores_name(pc),A0
	move.l	_resload(pc),a2
	move.l	#$110-$16,D0		; length: 4
	jsr	(resload_LoadFile,a2)
.nohighs
	movem.l	(a7)+,D0-A6
	rts

GetExt_1:
	IFD	DEBUG
	move.l	#$80000,$2140.W
	ELSE
	move.l	_expmem(pc),$2140.W
	ENDC
	jmp	$6F2E.W

GetExt_2:
	IFD	DEBUG
	move.l	#$80000,$2156.W
	ELSE
	move.l	_expmem(pc),$2156.W
	ENDC
	jmp	$6F54.W

SetTrack:
	move.l	A0,-(A7)
	lea	currtrack(PC),A0
	move.w	D0,(A0)
	move.l	(A7)+,A0
	rts

ReadTrack:
	movem.l	D0-A6,-(a7)
	moveq.l	#0,D0
	moveq.l	#0,D1

	move.w	#$1800,D1
	move.w	currtrack(PC),D0
	lea	$3820(A4),A0
	bsr	NibRead
	
	movem.l	(a7)+,D0-A6
	rts
	
; amigafun, DOS track
DosTrackRead:
	movem.l	D1-D6/A0-A6,-(sp)

	move.l	D6,D1	; length
	beq	.exit
	move.l	D5,D0	; offset
	moveq.l	#0,d2
	move.w	currdisk(pc),D2
	
	bsr	_loaddisk

.exit
	movem.l	(sp)+,D1-D6/A0-A6
	moveq	#0,D0
	rts

; Routine patchant la lecture

; D1: Longueur en octets
; D0: Track #
; A0: Buffer

NibRead:
	movem.l	D0-A6,-(a7)
	and.l	#$FFFF,D1	; length
	sub.l	#$2,D0		; Substract the track offset

	tst.l	D1
	beq	ReadNothing

	mulu.w	#$C,D0
	lsl.l	#8,D0
	add.l	D0,D0	; D0*=512*12 offset
	moveq.l	#0,d2
	move.w	currdisk(PC),D2	; disk #
	
	bsr	_loaddisk

ReadNothing:
	movem.l	(a7)+,D0-A6
	rts

kbint:
	bsr	AckKb

	move.b	D0,$70B82
	cmp.b	_keyexit(pc),D0
	bne	.noquit

	bra		quit
.noquit
	rts

kbint2:
	bsr	AckKb

	move.b	D0,$60A4.W
	cmp.b	_keyexit(pc),D0
	bne	.noquit

	bra		quit

.noquit
	rts

AckKb
	BSET	#$06,$0E00(A0)
	movem.l	D0,-(a7)
	moveq.l	#2,d0
	bsr	beam_delay
	movem.l	(a7)+,d0
	BCLR	#$06,$0E00(A0)
	rts

kbint3:
	bsr	AckKb
	
	move.b	D0,$60BA.W
	cmp.b	_keyexit(pc),D0
	bne.b	.noquit

	MOVE.B	#$01,$0500(A0)
	bra		quit

.noquit
	move.l	A0,-(sp)
	lea	spcpress(pc),A0
	clr.b	(A0)
	cmp.b	#$40,D0
	bne.b	.nospc

	st.b	(A0)
.nospc
	move.l	(sp)+,A0
	rts
	
quit:
		move.l	_resload(pc),a2
		move.l	#TDREASON_OK,-(A7)
		jmp	resload_Abort(a2)

kbint_af:
	move.b	D0,($60BA).W
	cmp.b	_keyexit(pc),D0
	bne	.noquit
	bra	quit
.noquit
	rts
	
KbInt:
	lsr.w	#1,D0
	eor.w	#$7F,D0
CheckQuit:
	
	cmp.b	_keyexit(pc),D0
	bne	.noquit		; F10: exit
	bra	quit
.noquit
	RTS

EmulateDbf:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0

beam_delay:	
; < D0: numbers of vertical positions to wait
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

	
Tags		dc.l	WHDLTAG_BUTTONWAIT_GET
buttonwait:		dc.l	0
	dc.l	WHDLTAG_CUSTOM1_GET
infinite_lives	dc.l	0
	dc.l	WHDLTAG_CUSTOM2_GET
maxed_out	dc.l	0
	
		dc.l	0


_resload
	dc.l	0

currdisk:
	dc.w	1
currtrack:
	dc.w	0
spcpress:
	dc.w	0


scores_name:
	dc.b	"highs",0
	cnop	0,4

;< A0: start
;< A1: end
;< D0: longword to search for
;< D1: longword to replace by

hex_replace_long:
	movem.l	A0-A1/D0-D1,-(A7)
.srch
	cmp.l	(A0),D0
	beq.b	.found
.next
	addq.l	#2,A0
	cmp.l	A1,A0
	bcc.b	.exit
	bra.b	.srch
.found
	move.l	D1,(A0)+
	bra	.next
.exit
	movem.l	(A7)+,A0-A1/D0-D1
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
	
FungusDecrunch:
	movem.l	d0-a6,-(a7)
	bsr	FUN_0000
	movem.l	(a7)+,d0-a6
	RTS

FUN_0000:
	move.l	#'*FUN',d0		;Fungus decruncher
		move.l	#'GUS*',d1
_Dec_1		cmp.l	(a0)+,d0
		beq.b	_Dec_2
		cmp.l	(a0)+,d0
		bne.b	_Dec_1
_Dec_2		cmp.l	(a0)+,d1
		bne.b	_Dec_1
		subq.w	#8,a0
		movea.l	-(a0),a2
		adda.l	a1,a2
		move.l	-(a0),d0
		move.l	-(a0),d4
		move.l	-(a0),d5
		move.l	-(a0),d6
		move.l	-(a0),d7
_Dec_3		add.l	d0,d0
		bne.b	_Dec_4
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_4		bcs.w	_Dec_11
		moveq	#3,d1
		moveq	#0,d3
		add.l	d0,d0
		bne.b	_Dec_5
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_5		bcs.b	_Dec_7
		moveq	#1,d3
		moveq	#8,d1
		bra.w	_Dec_15

_Dec_6		moveq	#8,d1
		moveq	#8,d3
_Dec_7		bsr.w	_Dec_18
		add.w	d2,d3
_Dec_8		moveq	#7,d1
_Dec_9		add.l	d0,d0
		bne.b	_Dec_10
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_10		addx.w	d2,d2
		dbra	d1,_Dec_9
		move.b	d2,-(a2)
		dbra	d3,_Dec_8
		bra.w	_Dec_17

_Dec_11		moveq	#0,d2
		add.l	d0,d0
		bne.b	_Dec_12
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_12		addx.w	d2,d2
		add.l	d0,d0
		bne.b	_Dec_13
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_13		addx.w	d2,d2
		cmp.b	#2,d2
		blt.b	_Dec_14
		cmp.b	#3,d2
		beq.b	_Dec_6
		moveq	#8,d1
		bsr.w	_Dec_18
		move.w	d2,d3
		move.w	#12,d1
		bra.w	_Dec_15

_Dec_14		moveq	#2,d3
		add.w	d2,d3
		move.w	#9,d1
		add.w	d2,d1
_Dec_15		bsr.w	_Dec_18
		lea	(1,a2,d2.w),a3
_Dec_16		move.b	-(a3),-(a2)
		dbra	d3,_Dec_16
_Dec_17		cmpa.l	a2,a1
		blt.w	_Dec_3
		rts

_Dec_18		subq.w	#1,d1
		clr.w	d2
_Dec_19		add.l	d0,d0
		bne.b	_Dec_20
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
_Dec_20		addx.w	d2,d2
		dbra	d1,_Dec_19
		rts