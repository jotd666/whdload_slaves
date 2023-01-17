;	:Program.	lotus.asm
;	:Contents.	Slave for "Lotus Esprit Turbo Challenge"
;	:Author.	Wepl,Harry,CFou!
;	:Version.	$Id: LotusEspritTC_Hd.asm 1.2 2006/06/04 17:16:13 wepl Exp wepl $
;	:History.	16.03.99 started
;	:Requires.	-
;	:Copyright.	Public Domain
;	:Language.	68000 Assembler
;	:Translator. Barfly V2.9
;	:To Do.
;---------------------------------------------------------------------------*
	OUTPUT	'LotusEspritTC.slave'
;	OPT	O+ OG+	;enable optimizing
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
;---------------------------------------------------------------------------*
v_high	=2	;version of highscore (in case save of best league will be
	;adapted later so old scores can still be converted)
	;highscore version 1 contained only besttimes
enablesave = 1	;set to 0 if you dont want to have highscoresave included
	;(useful for adapting other images, so you dont have to
	;patch irrelevant stuff at start)	

;_Flash	; Set it to	add BLUE Flash during track Loading
;---------------------------------------------------------------------------*

CHIPMEMSIZE	=	$80000
FASTMEMSIZE	=	$1000

BASEMEM		=	CHIPMEMSIZE
EXPMEM		=	FASTMEMSIZE

_base	SLAVE_HEADER				;ws_Security + ws_ID
		dc.w	13				;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd|WHDLF_ClearMem	;ws_flags
		dc.l	BASEMEM				;ws_BaseMemSize
		dc.l	0				;ws_ExecInstall
		dc.w	_start-_base			;ws_GameLoader
		dc.w	_data-_base			;ws_CurrentDir
		dc.w	0				;ws_DontCache
_keydebug	dc.b	$5f				;ws_keydebug
_keyexit	dc.b	$5d				;ws_keyexit = *
_expmem		dc.l	EXPMEM				;ws_ExpMem
		dc.w	_name-_base			;ws_name
		dc.w	_copy-_base			;ws_copy
		dc.w	_info-_base			;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate	>T:date"
	ENDC

_data	dc.b	0
_name	dc.b	"Lotus Turbo Esprit Challenge",0
_copy	dc.b	"1990 Gremlin/Magnetic Fields ",0
_info	dc.b	"Install done by Wepl, Harry & CFou!",10
	dc.b	"Version 1.1 "
	IFD BARFLY
	INCBIN	"T:date"
	ENDC
	dc.b	0
;====================================================================== 
	even
 
;====================================================================== 
_start	;	A0 = resident loader
;====================================================================== 
_dest=$8000
LgTrack=$1800
	lea	_resload(pc),a1
	move.l	a0,(a1)	;save for later use
	move.l	a0,a4
	move.l	_expmem(pc),a7
	add.l	#FASTMEMSIZE-4,a7

	lea	$dff000,a6
	move.w	#$7fff,$9a(a6)
	move.w	#$7fff,$9c(a6)
	move	#0,sr
	move.l	_expmem(pc),a7
	add.l	#FASTMEMSIZE/2-4,a7

	;get tags
	lea	(_tag,pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Control,a2)

	lea	_dest,a4
	MOVE.L	#$0,D0
	MOVE.L	#$4,D1
	MOVEQ	#1,D2
	move.l	a4,A0
	BSR	_LoadDisk

	CMP.l	#'LETC',(a4)
	beq	_v2

;******************************************
; Version 1 : disk image don't start by 'LETC'
_v1	lea	$1000,a6
	bsr	_InitFalseLoader
	lea	$40000,a6
	bsr	_InitFalseLoader
	bsr	_LoadDirTrackMainLoader

	move.w	#$4e75,$72bb0 ; crack
	bsr	preptouche
	bsr	_InitCIA
	lea	$72000,a2
	bsr	_PatchV1
	bsr	_patchLoadSaveHighscoreV1
	lea	$dff000,a6
	jmp	(a2)

_v2	;	lea	$dff000,a6
	;	move.w	#$7fff,$9a(a6)
	;	move.w	#$7fff,$9c(a6)
	;	lea	$1000,a7
	;	move	#0,sr

	lea	$a00,a6
	bsr	_InitFalseLoaderV2
	bsr	_LoadDirTrackMainLoaderV2
	bsr	preptouche
	bsr	_InitCIA
	lea	$72300,a2
	bsr	_PatchV2
	bsr	_patchLoadSaveHighscoreV2
	lea	$dff000,a6
	jmp	(a2)

_PatchSubGame
	lea	toucheSubGame(pc),a0
	move.l	a0,$68
	cmp.w	#$8040,$40088+2
	bne	.pas
	pea	_modif0(pc)
	move.w	#$4eb9,$40088
	move.l	(a7)+,$40088+2
	move.l	#$01040000,$4123e		; debug black screen ; aga pb
.pas
	cmp.w	#$8040,$40084+2
	bne	.pas1
	pea	_modif0(pc)
	move.w	#$4eb9,$40084
	move.l	(a7)+,$40084+2
	;	move.w	#$8048,$40084+2		; active keyboard interupt
	move.l	#$01040000,$4123e-4		; debug black screen ; aga pb
.pas1
	move.l	d0,-(a7)
	move.l	_custom2(pc),d0
	tst.l	d0
	bne	.no
	lea	$40000,a0
	lea	$41000,a1
.enc
	cmp.l	#$3d5d0058,(a0)
	bne	.next
	move.l	#$4eb80080,(a0)+
.next
	tst.w	(a0)+
	cmp.l	a0,a1
	bne	.enc
	lea	_PatchBlitterSubGame(pc),a0
	move.w	#$4ef9,$80
	move.l	a0,$80+2
.no	move.l	(a7)+,d0
	jmp	$40000

_PatchBlitterSubGame
	move.w	(a5)+,$dff058
	bra	_WaitBLT_gen

_modif0:
	move.w	#$8040,$dff09c
	move.w	#$8008,$dff09a
	rts

opt	dc.l	0

NbLoop		=	$10

_FixFreezeCacheV1
;	bsr	_SMC99
	move.w	$7d18a,d0
;	bclr	#6,$bfee01
	bsr	_InitCIA
	move.l	d0,-(a7)
	bra	.ok
.NotUser
	move.w	#3,$7d870		; no opponents
.ok
	bra	_contFix

_FixFreezeCacheV2
;	bsr	_SMC99
	move.w	$7d244,d0
;	bclr	#6,$bfee01
	move.l	d0,-(a7)
	bra	.ok
.NotUser
	move.w	#3,$7d92a		; no opponents ; PL1 gamescores MODE=1.w
.ok

_contFix
	move.b	#$1,_AdrSkipLevelOpt+1	; active skip level key
	move.w	#NbLoop,d0
.enc	nop
	nop
	dbf	d0,.enc
	move.l	(a7)+,d0
	rts

_InitCIA
	move.b	#$c0,$bfd200
	move.b	#$ff,$bfd300
	move.b	#$03,$bfe201
	move.b	#$00,$bfee01	; freeze it not present
	move.b	#$88,$bfed01
	move.b	#$ff,$bfd100
	rts

_LoadTrackGameV1
	MOVEM.l	D0-D4/A0-A2,-(SP)
	sub.l	#LgTrack*2,d0
	
	MOVE.L	_NumDisk(PC),D2
	MOVE.L	_resload(PC),A2
	
	JSR	resload_DiskLoad(A2)
	
	MOVEM.l	(SP)+,D0-D4/A0-A2
	MOVEQ	#0,D0
	RTS

_NumDisk	dc.l	1

;*****************************************
; V1 Image don't start by 'LETC' by CFou! ( main loader replacement)
;*****************************************

_InitFalseLoader
	move.l	#$4e714e75,$00(a6)	;Bra.w	_InitDF0	; $1000
	move.l	#$4e714e75,$04(a6)	;Bra.w	_StopDF0	; $1004
	move.l	#$600000f6,$08(a6)	;Bra.w	_LoadFileID	; $1008 $1100
	move.l	#$4e714e75,$0c(a6)	;Bra.w	_SeekTrack	; $100c
	move.l	#$4e714e75,$10(a6)	;Bra.w	_LoadDirTrackMainLoader	; $1010
					;_LoadDiskPart	; $1110

	pea	_LoadFileID(pc)
	move.w	#$4ef9,$100(a6)
	move.l	(a7)+,$100+2(a6)

	pea	_LoadDiskPart(pc)
	move.w	#$4ef9,$110(a6)
	move.l	(a7)+,$110+2(a6)
	lea	$dff000,a6
	rts

_LoadDirTrackMainLoader	;$1010
	lea	$dff000,a6
	lea	$bfd000,a5
	lea	$13d6,a4
	move.w	#$7fff,$9a(a6)
	move.w	#$7fff,$9c(a6)
	move.l	#$fffffffe,$1116
	move.l	#$1116,$80(a6)
	clr.w	$100(a6)
	clr.w	$88(a6)
	move.w	#$8310,$96(a6)

	move.l	#$3000,d0 ; offset $1800*2 (tracks 0 & 1)
	move.l	#$800,d1	; lg
	lea	$400,a0	; dest
	bsr	_LoadTrackGameV1

	move.l	#$3800,d0 ; offset $1800*2 (tracks 0 & 1)
	move.l	$bf8,d1	; lg
	move.l	$bfc,a0	; dest
	bsr	_LoadTrackGameV1
	rts

_LoadFileID	;$1100
	IFD _Flash
	move.w	#$f00,$dff180
	move.w	#$f,$dff180
	ENDC
;	move.w	#$c028,$dff09a
	bsr	_InitCIA
	lea	$400,a1
	asl.w	#3,d0
	add.w	d0,a1
	move.l	(a1)+,d1
	beq	_exit	; error
	move.l	(a1),d0
_LoadDiskPart	;$1110
	bsr	_LoadTrackGameV1
	rts


;*****************************************
; V2 Image Start by 'LETC' By CFou! ( main loader replacement)
;*****************************************
_InitFalseLoaderV2
	move.l	#$4e714e75,$00(a6) ;	Bra.w	_InitDF0	; $1000
	move.l	#$4e714e75,$04(a6) ;	Bra.w	_StopDF0	; $1004
	move.l	#$60000174,$08(a6) ;	Bra.w	_LoadFileID	; $1008 $1100
	move.l	#$4e714e75,$0c(a6) ;	Bra.w	_SeekTrack	; $100c
	move.l	#$4e714e75,$10(a6) ;	Bra.w	_LoadDirTrackMainLoader	; $1010
		;	_LoadDiskPart	; $1110

	move.l	#$4e714e75,$28(a6)
	move.l	#$4e714e75,$2c(a6)

	pea	_LoadFileID_V2(pc)
	move.w	#$4ef9,$17e(a6)
	move.l	(a7)+,$17e+2(a6)

	pea	_LoadDiskPart(pc)
	move.w	#$4ef9,$1b6(a6)
	move.l	(a7)+,$1b6+2(a6)
	lea	$dff000,a6
	rts

_LoadDirTrackMainLoaderV2
	lea	$dff000,a6
	lea	$bfd000,a5
	lea	$0,a4
	move.w	#$7fff,$9a(a6)
	move.w	#$7fff,$9c(a6)
	move.l	#$fffffffe,$2c0
	move.l	#$2c0,$80(a6)
	clr.w	$100(a6)
	clr.w	$88(a6)
	move.w	#$8310,$96(a6)

	move.l	#$3000,d0 ; offset $1800*2 (tracks 0 & 1)
	move.l	#$57c,d1	; lg
	lea	$2c0,a0	; dest
	bsr	_LoadTrackGameV1

	lea	$dff000,a6
	lea	$bfd000,a5
	lea	0,a4
	MOVE.W	#0,($818,A4)
	move.l	#$ff,d0
	move.l	$7c8,a0
	bsr	_LoadFileID_V2Main
	rts

_LoadFileID_V2 ;$b7e
	lea	$dff000,a6
	lea	$bfd000,a5
	lea	0,a4
	MOVE.W	#1,($818,A4)

_LoadFileID_V2Main
	IFD _Flash
	move.w	#$f00,$dff180
	move.w	#$f,$dff180
	ENDC
	bsr	_InitCIA
	;	move.w	#$8028,$dff09a
	LEA	($2C4,A4),A1
	LEA	($6C8,A4),A2
	MOVEQ	#0,D1
	MOVE.B	(A2,D0.W),D1
	CMP.W	#$FF,D1
	BNE.B	.skip
	ADDQ.W	#1,D1
.skip
	ASL.W	#2,D1
	ASL.W	#2,D0
	MOVE.L	(A1,D0.W),D0
	BEQ.W	_exit
	MOVE.L	(A1,D1.W),D1
	SUB.L	D0,D1
	MOVE.L	D1,($814,A4)
	bra	_LoadDiskPart	;$bb6

;*****************************************************
;******************	sub-routine *********************
;*****************************************************

; Wepl Patch
; $7b828.w	will be incremented by finished blitter-int-system, if
; value=2 not reached there will be a restart
;
; $7d246.w	= -1 blit-int inactive?

; $7d8aa.w	= number of routine (table from $747c8) which will be called
; from vbi, -1 means no routine
; $7d8be.w	= NE if current display task has finished

;
; wait that the car has completely displayed before demo starts
; because blitter bugs
;

_wait_demoV1
	TST.W	($7d806).L	;on fire press, start game
	BNE.W	.1
	tst.w	$7d804
	beq	_wait_demoV1
	jmp	($7b666)	;original
.1	addq.l	#4,a7
	jmp	($168a+$72000)	;start game

_wait_demoV2:
	TST.W	($7D8C0).L	;on fire press, start game
	BNE.W	.1
	tst.w	$7d8be
	beq	_wait_demoV2
	jmp	($7b628)	;original
.1	addq.l	#4,a7
	jmp	($1582+$72300)	;start game

; wait that the gremlin/mf sign has completely displayed
;
_wait_mfV1:
.2	btst	#7,$bfe001
	beq	.1
	tst.w	$7d804
	beq	.2
.1	move.w	#-1,$7d7ec	;original
;	addq.l	#2,(a7)
	rts

_wait_mfV2:
.2	btst	#7,$bfe001
	beq	.1
	tst.w	$7d8be
	beq	.2
.1	move.w	#-1,$7d8a6	;original
;	addq.l	#2,(a7)
	rts

;*****************************************************
;*********** Blitterddelay sub-routine ***************
;*****************************************************

_PatchBlt
	MOVEM.l	A0/A1,-(SP)
	SUBQ.L	#4,A1
.loop
	CMPI.W	#$3D7C,(A0)
	BNE.W	.next2
	CMPI.W	#$58,(4,A0)
	BNE.W	.next
	MOVE.W	2(A0),(4,A0)
.enc
	MOVE.W	#$4EB8,(A0)+
	MOVE.W	A2,(A0)+
;--------------
.next2
	CMPI.W	#$3D5D,(A0)
	BNE.W	.next
	CMPI.W	#$0058,(2,A0)
	BNE.W	.next
	CMPI.W	#$4e73,(4,A0)
	BNE.W	.next
	MOVE.W	#$4EF9,(A0)+
	MOVE.L	A3,(A0)+

.next
	add.l	#2,a0
	CMPA.L	A0,A1
	BCC.W	.loop
.fin	MOVE.W	#$4EF9,(A2)+
	LEA	(_WaitBliterDelay,PC),A0
	MOVE.L	A0,(A2)+
	MOVEM.l	(SP)+,A0/A1
	RTS

_BltA5	move.w	(a5)+,$58(a6)
	bsr	_WaitBLT_gen
	rte

_WaitBliterDelay
	MOVE.L	A0,-(SP)
	MOVEA.l	(4,SP),A0
	MOVE.W	(A0)+,($58,A6)
	cmp.l	#$dff000,a6
	bne	_finBlt
	MOVE.L	A0,(4,SP)
	MOVEA.l	(SP)+,A0

_WaitBLT_gen
	TST.B	(2,A6)
.l2	TST.B	($BFE001).L
	TST.B	($BFE001).L
	BTST	#6,(2,A6)
	BNE.B	.l2
	TST.B	(2,A6)
_finBlt	RTS


;*****************************************************
;****************** SMC sub-routine by CFou! *********
;*****************************************************
_AdrBLT		=$80
_AdrSMC1	=_AdrBLT+6	;$086-$106
_AdrSMC2	=_AdrSMC1+2	:$088-$108
_AdrSMC3	=_AdrSMC2+6	:$08e-$10e
_AdrSMC4	=_AdrSMC3+2	:$090-$110
_AdrSMC5	=_AdrSMC4+2	:$092-$112
_AdrSMC6	=_AdrSMC5+2	:$094-$114
_AdrSMC7	=_AdrSMC6+2	:$096-$116
_AdrSMC8	=_AdrSMC7+2	:$09c-$11c ;6 before
_AdrSMC9	=_AdrSMC8+6	:$0a2-$122
;_AdrSMC10	=_AdrSMC9+6
_AdrSkipLevelOpt=_AdrSMC9+6
;_AdrSMC10	=_AdrSMC9+6+2

_PatchV1

;	bsr	_SMC99

	pea	_wait_preraceV1(pc)
	move.w	#$4eb9,$739d6-$72000(a2)
	move.l	(a7)+,$739d6-$72000+2(a2)

;---------- skip level patch
	move.b	#$0,_AdrSkipLevelOpt
	move.b	#$0,_AdrSkipLevelOpt+1
	move.l	_custom1(pc),d0
	and.l	#1,d0
	cmp.l	#1,d0
	bne	.pasSkipLevel
	pea	_SkipLevelPrepV1(pc)
	move.w	#$4eb9,$73a32-$72000(a2)
	move.l	(a7)+,$73a32-$72000+2(a2)

	pea	_SkipLevelPosV1(pc)
	move.w	#$4eb9,$75bea-$72000(a2)
	move.l	(a7)+,$75bea-$72000+2(a2)
.pasSkipLevel
;---------- skip level patch END

;---------- skip original cheat
	move.l	_custom1(pc),d0
	and.l	#2,d0
	cmp.l	#2,d0
	bne	.pasCheat
	move.w	#$6022,$73f66-$72000(a2) ; active all time cheat
.pasCheat
;---------- skip original cheat END

;---------- skip original subgame
	move.l	_custom1(pc),d0
	and.l	#4,d0
	cmp.l	#4,d0
	bne	.pasSG
	move.w	#$602e,$737c4-$72000(a2)
.pasSG	pea	_PatchSubGame(pc)
	move.w	#$4ef9,$7382a-$72000(a2)
	move.l	(a7)+,$7382a-$72000+2(a2)
;---------- skip original subgame END

	pea	_wait_mfV1(pc)
	move.w	#$4eb9,$e06(a2)
	move.l	(a7)+,$e06+2(a2)
	move.w	#$4e71,$e06+6(a2)

	pea	_wait_demoV1(pc)
	move.w	#$4eb9,$1578(a2)
	move.l	(a7)+,$1578+2(a2)

	move.w	#$186,$14ae(a2)		;time to play
	move.w	#$190,$14ae+8(a2)	;time to play
;-----------------------------

	move.l	d0,-(a7)
	move.l	_custom2(pc),d0
	tst.l	d0
	beq	.ok
	move.l	(a7)+,d0
	rts
.ok
	move.l	(a7)+,d0

	pea	_FixFreezeCacheV1(pc)
	move.w	#$4eb9,$7848c-$72000(a2)
	move.l	(a7)+,$7848c-$72000+2(a2)

;------------SMC patched
;----- SMC1
	add.l	#$64ee,a2
	pea	_SMC1_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$64ee,a2

	pea	_SMC1_(pc)
	move.w	#$4eb9,$776de-$72000(a2)
	move.l	(a7)+,$776de-$72000+2(a2)
	move.l	#$4e714e71,$776ea-$72000(a2)

;----- SMC2
	add.l	#$6c22,a2
	pea	_SMC2_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6c22,a2

	pea	_SMC2_(pc)
	move.w	#$4ef9,$78c46-$72000(a2)
	move.l	(a7)+,$78c46-$72000+2(a2)

;----- SMC3
	add.l	#$6e94,a2
	pea	_SMC3_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6e94,a2

	pea	_SMC3_V1(pc)
	move.w	#$4eb9,$78ed6-$72000(a2)
	move.l	(a7)+,$78ed6-$72000+2(a2)
	move.w	#$4e71,$78ed6-$72000+6(a2)

;----- SMC4
	add.l	#$8f68,a2
	pea	_SMC4_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$8f68,a2

	add.l	#$7afe4-$72000,a2
	pea	_SMC4_(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$7afe4-$72000,a2

;----- SMC5
	add.l	#$6e9e,a2
	pea	_SMC5_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6e9e,a2

	add.l	#$79230-$72000,a2
	pea	_SMC5_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	move.w	#$4e71,6(a2)
	sub.l	#$79230-$72000,a2

;----- SMC6
	add.l	#$688e,a2
	pea	_SMC6_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$688e,a2

	add.l	#$788d4-$72000,a2
	pea	_SMC6_(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	move.w	#$4e71,6(a2)
	sub.l	#$788d4-$72000,a2

;----- SMC7
	add.l	#$68ce,a2
	pea	_SMC7_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$68ce,a2

	add.l	#$78914-$72000,a2
	pea	_SMC7_(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$78914-$72000,a2

;----- SMC8
	add.l	#$6afc,a2
	pea	_SMC8_Code_V1(pc)
	move.w	#$4ef9,(a2)	; before $4eb9
	move.l	(a7)+,2(a2)
	sub.l	#$6afc,a2

	;_SMC8	; not needed

;----- SMC9
	add.l	#$79f7e-$72000,a2
	pea	_SMC9_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$79f7e-$72000,a2

	add.l	#$7a01c-$72000,a2
	pea	_SMC9_(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$7a01c-$72000,a2

;----- SMC10
	add.l	#$626a,a2
	pea	_SMC10_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$626a,a2

;----- SMC11
	add.l	#$659c,a2
	pea	_SMC11_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$659c,a2

;----- SMC12
	add.l	#$6504,a2
	pea	_SMC12_Code_V1(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6504,a2

	movem.l	a0-a3,-(a7)
	lea	$72000,a0
	lea	$80000,a1
	lea	_AdrBLT,a2
	lea	_BltA5(pc),a3
	bsr	_PatchBlt
	movem.l	(a7)+,a0-a3
	rts


_PatchV2

;	bsr	_SMC99

	pea	_wait_preraceV2(pc)
	move.w	#$4eb9,$73bce-$72300(a2)
	move.l	(a7)+,$73bce-$72300+2(a2)

;---------- skip level patch
	move.b	#$0,_AdrSkipLevelOpt
	move.b	#$0,_AdrSkipLevelOpt+1
	move.l	_custom1(pc),d0
	and.l	#1,d0
	cmp.l	#1,d0
	bne	.pasSkipLevel
	pea	_SkipLevelPrepV2(pc)
	move.w	#$4eb9,$73c2a-$72300(a2)
	move.l	(a7)+,$73c2a-$72300+2(a2)

	pea	_SkipLevelPosV2(pc)
	move.w	#$4eb9,$75bf4-$72300(a2)
	move.l	(a7)+,$75bf4-$72300+2(a2)
.pasSkipLevel
;---------- skip level patch END


;---------- skip original cheat
	move.l	_custom1(pc),d0
	and.l	#2,d0
	cmp.l	#2,d0
	bne	.pasCheat
	move.w	#$6022,$74148-$72300(a2) ; active all time cheat
.pasCheat
;---------- skip original cheat END

;---------- skip original subgame
	move.l	_custom1(pc),d0
	and.l	#4,d0
	cmp.l	#4,d0
	bne	.pasSG

	move.w	#$602e,$739bc-$72300(a2)

.pasSG
	pea	_PatchSubGame(pc)
	move.w	#$4ef9,$73a22-$72300(a2)
	move.l	(a7)+,$73a22-$72300+2(a2)
;---------- skip original subgame END

	pea	_wait_mfV2(pc)
	move.w	#$4eb9,$db4(a2)
	move.l	(a7)+,$db4+2(a2)
	move.w	#$4e71,$db4+6(a2)

	pea	_wait_demoV2(pc)
	move.w	#$4eb9,$1470(a2)
	move.l	(a7)+,$1470+2(a2)

	move.w	#$186,$13a6(a2)	;time to play
	move.w	#$190,$13a6+8(a2)	;time to play

	move.l	d0,-(a7)
	move.l	_custom2(pc),d0
	tst.l	d0
	beq	.ok
	move.l	(a7)+,d0
	rts
.ok
	move.l	(a7)+,d0

	pea	_FixFreezeCacheV2(pc)
	move.w	#$4eb9,$78400-$72300(a2)
	move.l	(a7)+,$78400-$72300+2(a2)

;------------SMC patched
;----- SMC1
	add.l	#$6162,a2
	pea	_SMC1_Code_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6162,a2

	pea	_SMC1_(pc)
	move.w	#$4eb9,$77652-$72300(a2)
	move.l	(a7)+,$77652-$72300+2(a2)
	move.l	#$4e714e71,$7765e

;----- SMC2
	add.l	#$6896,a2
	pea	_SMC2_Code_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6896,a2

	pea	_SMC2_(pc)
	move.w	#$4ef9,$78bba-$72300(a2)
	move.l	(a7)+,$78bba-$72300+2(a2)

;----- SMC3
	add.l	#$6b08,a2
	pea	_SMC3_Code_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6b08,a2

	pea	_SMC3_V2(pc)
	move.w	#$4eb9,$78e4a-$72300(a2)
	move.l	(a7)+,$78e4a-$72300+2(a2)
	move.w	#$4e71,$78e4a-$72300+6(a2)

;----- SMC4
	add.l	#$8bdc,a2
	pea	_SMC4_Code_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$8bdc,a2

	add.l	#$7af58-$72300,a2
	pea	_SMC4_(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$7af58-$72300,a2

;----- SMC5
	add.l	#$6b12,a2
	pea	_SMC5_Code_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6b12,a2

	add.l	#$791a4-$72300,a2
	pea	_SMC5_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	move.w	#$4e71,6(a2)
	sub.l	#$791a4-$72300,a2
;----- SMC6
	add.l	#$6502,a2
	pea	_SMC6_Code_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6502,a2

	add.l	#$78848-$72300,a2
	pea	_SMC6_(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	move.w	#$4e71,6(a2)
	sub.l	#$78848-$72300,a2

;----- SMC7
	add.l	#$6542,a2
	pea	_SMC7_Code_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$6542,a2

	add.l	#$78888-$72300,a2
	pea	_SMC7_(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$78888-$72300,a2

;----- SMC8
	add.l	#$6770,a2
	pea	_SMC8_Code_V2(pc)
	move.w	#$4ef9,(a2)	; before $4eb9
	move.l	(a7)+,2(a2)
	sub.l	#$6770,a2

	; SMC8 ; not needed
;----- SMC9
	add.l	#$7bf2,a2
	pea	_SMC9_Code_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$7bf2,a2

	add.l	#$79f90-$72300,a2
	pea	_SMC9_(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$79f90-$72300,a2

;----- SMC10
	add.l	#$5ede,a2
	pea	_SMC10_Code_V2(pc)
	move.w	#$4eb9,(a2)
	move.l	(a7)+,2(a2)
	sub.l	#$5ede,a2

;----------- Blitter delay inserted
	movem.l	a0-a3,-(a7)
	lea	$72300,a0
	lea	$80000,a1
	lea	_AdrBLT,a2
	lea	_BltA5(pc),a3
	bsr	_PatchBlt
	movem.l	(a7)+,a0-a3
	rts


_SMC1_Code_V1
;	move.w	d0,$776ec	; :::	; SMC1_
	move.w	d0,_AdrSMC1	; ->$108
	rts
_SMC2_Code_V1
;	move.w	d0,$78c4a
	move.l	d0,-(a7)
	ext.l	d0
	add.l	#$78c4a,d0
;	move.w	#$4ef9,_AdrSMC2	; SMC2_
	move.l	d0,_AdrSMC2+2	; ->$10e
	move.l	(a7)+,d0
	rts
_SMC3_Code_V1
;	move.w	d6,$78ed8	; SMC3
	move.w	d6,_AdrSMC3	; ->$110
	rts
_SMC4_Code_V1
;	move.w	d1,$7afe8	; SMC4
	move.w	d1,_AdrSMC4	; ->$112
	rts
_SMC5_Code_V1
;	move.w	d6,$79232	; SMC5
	move.w	d6,_AdrSMC5	; ->$114
	rts
_SMC6_Code_V1
;	move.w	d5,$788d6	; SMC6
	move.w	d5,_AdrSMC6	; ->$116
	rts
_SMC7_Code_V1
;	move.b	d3,$78915
	move.l	d3,-(a7)
	and.l	#$ff,d3
	move.w	d3,_AdrSMC7	; SMC7
	move.l	(a7)+,d3
	rts
_SMC8_Code_V1
;	move.w	d0,$78b06
	move.l	d0,-(a7)
	and.l	#$ffff,d0
	add.l	#$78b06,d0
;	move.w	#$4ef9,_AdrSMC8	; SMC8
	move.l	d0,_AdrSMC8+2	; ->$122
	move.l	(a7)+,d0
	add.w	d7,d1
	move.l	_AdrSMC8+2,-(a7)
	rts
;	jmp	_AdrSMC8
;	rts
_SMC9_Code_V1
;	move.w	d0,$7a020
	move.w	d0,_AdrSMC9	; SMC9
	rts
_SMC10_Code_V1
	move.w	d1,$782c0
	rts
_SMC11_Code_V1
	move.l	d0,$7b956
	rts
_SMC12_Code_V1
	move.w	d1,$7b9e8
	rts

;------------------------
_SMC1_Code_V2
;	move.w	d0,$77660	; SMC1
	move.w	d0,_AdrSMC1	; ->$108
	rts
_SMC2_Code_V2
;	move.w	d0,$78bbe	
	move.l	d0,-(a7)
	ext.l	d0
	add.l	#$78bbe,d0
;	move.w	#$4ef9,_AdrSMC2	; SMC2
	move.l	d0,_AdrSMC2+2	; ->$10e
	move.l	(a7)+,d0
	rts
_SMC3_Code_V2
;	move.w	d6,$78e4c	; SMC3
	move.w	d6,_AdrSMC3	; ->$110
	rts
_SMC4_Code_V2
;	move.w	d1,$7af5c	; SMC4
	move.w	d1,_AdrSMC4	; ->$112
	rts
_SMC5_Code_V2
;	move.w	d6,$791a6	; SMC5
	move.w	d6,_AdrSMC5	; ->$114
	rts
_SMC6_Code_V2
;	move.w	d5,$7884a	; SMC6
	move.w	d5,_AdrSMC6	; ->$116
	rts
_SMC7_Code_V2
;	move.b	d3,$78889
	move.l	d3,-(a7)
	and.l	#$ff,d3
	move.w	d3,_AdrSMC7	; SMC7
	move.l	(a7)+,d3
	rts
_SMC8_Code_V2
;	move.w	d0,$78a7a
	move.l	d0,-(a7)
	and.l	#$ffff,d0
	add.l	#$78a7a,d0
;	move.w	#$4ef9,_AdrSMC8	; SMC8
	move.l	d0,_AdrSMC8+2	; ->$122
	move.l	(a7)+,d0
	add.w	d7,d1
	move.l	_AdrSMC8+2,-(a7)
	rts
;	jmp	_AdrSMC8
;	rts
_SMC9_Code_V2
;	move.w	d0,$79f94	
	move.w	d0,_AdrSMC9	; SMC9
	rts

_SMC10_Code_V2	; not need
	move.w	d1,$78234
	rts
;**************************

_SMC1_	lea	$dff000,a6
	move.w	_AdrSMC1,d0
	ext.l	d0
	rts
_SMC2_	move.l	#$14,d1
	move.l	_AdrSMC2+2,-(a7)
	rts
	;jmp	_AdrSMC2
_SMC3_V2
	move.w	_AdrSMC3,$7d20a
	rts
_SMC3_V1
	move.w	_AdrSMC3,$7d150
	rts
_SMC4_	subq.w	#2,d7
	move.w	_AdrSMC4,d0
;	ext.l	d0
	move.w	d0,d1
	rts
_SMC5_V2
	move.w	_AdrSMC5,$7d20a
	rts
_SMC5_V1
	move.w	_AdrSMC5,$7d150
	rts
_SMC6_
	add.w	_AdrSMC6,d2
	and.w	#$400,d2
	rts
_SMC7_
	move.w	_AdrSMC7,d6
	and.w	#1,d6
	rts
;SMC8_	;not need
_SMC9_
	add.l	d0,d3
	cmp.w	_AdrSMC9,d7
	rts


;*****************************************************
; Keyboard Patche by CFou!
;*****************************************************


preptouche:
	movem.l	a0-a1,-(a7)
	lea	toucheV1(pc),a0
	lea	$72c48,a1	; v1
	cmp.w	#$1039,(a1)
	bne	.past1
	lea	$72c30,a1	; v1
	move.w	#$4ef9,(a1)+
	move.l	a0,(a1)
.past1:
	lea	toucheV2(pc),a0
	lea	$72ef4,a1	; v2 LETC
	cmp.w	#$1039,(a1)
	bne	.past2
	lea	$72300+$c62,a1
	move.l	#$4e714eb9,(a1)+
	move.l	a0,(a1)
.past2:

	lea	$72ef4,a1	; v3 LETC CD32
	cmp.l	#$4e714e71,(a1)
	bne	.past3
	lea	$72300+$c62,a1
	move.l	#$4e714eb9,(a1)+
	move.l	a0,(a1)
.past3:

	movem.l	(a7)+,a0-a1
	rts

toucheV1:
	movem.l	d0-d1/a6,-(a7)
	LEA	$DFF000,A6
	;	lea	$BFE001,a4
	move.b	$BFED01,d0
;	BTST	#0,d0
;	Bne	.skip0
	BTST	#3,d0
	BEQ	.fintouche
	MOVE.B	$BFEC01,D0
	CLR.B	$BFEC01
	;	BCLR	#6,$BFEE01
	;	OR.B	#$40,$BFE01
	;	bsr	toucheV1bb
	NOT.B	D0
	ROR.B	#1,D0
	bsr	toucheV1b

	MOVE.B	D0,$7D7AE
	CMPI.W	#1,$7D874
	BNE.B	.skip0
	MOVE.B	$7B9E6,D1
	CMP.B	#$31,D0
	BEQ.B	.t1
	CMP.B	#$32,D0
	BEQ.B	.t2
	CMP.B	#$28,D0
	BEQ.B	.t3
	CMP.B	#$38,D0
	BEQ.B	.t4
	CMP.B	#$40,D0
	BEQ.B	.t5
	CMP.B	#$B1,D0
	BEQ.B	.t6
	CMP.B	#$B2,D0
	BEQ.B	.t7
	CMP.B	#$A8,D0
	BEQ.B	.t8
	CMP.B	#$B8,D0
	BEQ.B	.t9
	CMP.B	#$C0,D0
	BEQ.B	.tA
.endKey
	MOVE.B	D1,$7B9E6

;;	move.b	#1,$BFE501

;	bra	.skip0
	MOVEQ	#2,D1
.w2:
	MOVE.B	$DFF006,D0
.w1:
	CMP.B	$DFF006,D0
	BEQ	.w1
	DBRA	D1,.w2
.skip0
;	AND.B	#$BF,$BFEE01
	BSET	#6,$BFEE01
.skip1

.fintouche:
	MOVE.W	#8,$9C(a6)
	MOVEM.l	(SP)+,d0-d1/a6
	RTE

.t1	BSET	#0,D1
	BRA.B	.endKey

.t2	BSET	#1,D1
	BRA.B	.endKey

.t3	BSET	#3,D1
	BRA.B	.endKey

.t4	BSET	#2,D1
	BRA.B	.endKey

.t5	BSET	#4,D1
	BRA.B	.endKey

.t6	BCLR	#0,D1
	BRA.B	.endKey

.t7	BCLR	#1,D1
	BRA.B	.endKey

.t8	BCLR	#3,D1
	BRA.B	.endKey

.t9	BCLR	#2,D1
	BRA.B	.endKey

.tA	BCLR	#4,D1
	BRA.B	.endKey

toucheV1bb:
	move.b	$bfec01,d0
	move.l	d0,-(a7)
	NOT.B	D0
	ROR.B	#1,D0
	bsr	toucheV1b
	move.l	(a7)+,d0
	rts
toucheV1b:

	cmp.b	#$57,d0
	bne	.pas_f8
	move.w	#$f,$dff180
	move.w	#$f,$dff180
	move.w	#$f,$dff180
.pas_f8

	cmp.b	#$58,d0
	bne	.pas_f9

	tst.b	_AdrSkipLevelOpt+1
	beq	.pas_f9
	move.w	#$f0,$dff180
	move.w	#$f0,$dff180
	move.w	#$f0,$dff180

	move.l	d0,-(A7)
	move.l	_custom1(pc),d0
	and.l	#1,d0
	cmp.l	#1,d0
	bne	.pas
	move.w	#1,$7d7b2	; quit
	move.b	#$ff,_AdrSkipLevelOpt
.pas
	move.l	(A7)+,d0
.pas_f9	cmp.b	_keyexit(pc),d0
	beq	_exit
	rts

toucheV2
	clr.b	($c00,a0)
	moveq	#3-1,d1	;wait because handshake min 75 탎
	move.w	d0,-(A7)
.int2_w1
	move.b	(6,a6),d0
.int2_w2
	cmp.b	(6,a6),d0	;one line is 63.5 탎
	beq	.int2_w2
	dbf	d1,.int2_w1	;(min=127탎 max=190.5탎)
	move.w	(A7)+,d0
	BCLR	#6,($E00,A0)

	cmp.b	#$57,d0
	bne	.pas_f8
	move.w	#$f,$dff180
	move.w	#$f,$dff180
	move.w	#$f,$dff180
.pas_f8
	cmp.b	#$58,d0
	bne	.pas_f9

	tst.b	_AdrSkipLevelOpt+1
	beq	.pas_f9
	move.w	#$f0,$dff180
	move.w	#$f0,$dff180
	move.w	#$f0,$dff180

	move.l	d0,-(A7)
	move.l	_custom1(pc),d0
	and.l	#1,d0
	cmp.l	#1,d0
	bne	.pas
	move.w	#1,$7d86c	; quit
	move.b	#$ff,_AdrSkipLevelOpt
.pas
	move.l	(A7)+,d0
.pas_f9:
	cmp.b	_keyexit(PC),d0
	beq	_exit
	rts

toucheSubGame:
	MOVEM.l	D0/D1/A1,-(SP)
	LEA	$BFE001,A1
	BTST	#3,$D00(A1)
	BEQ	.fintouche
	MOVE.B	$C00(A1),D0
	CLR.B	$C00(A1)
	OR.B	#$40,$E00(A1)
	NOT.B	D0
	ROR.B	#1,D0

	cmp.b	_keyexit(PC),d0
	beq	_exit

	cmp.b	#$58,d0
	bne	.pas_f9
	move.w	#$f0,$dff180
	move.w	#$f0,$dff180
	move.w	#$f0,$dff180
	move.w	#$0,$dff180
.pas_f9:

	cmp.b	#$57,d0
	bne	.pas_f8
	move.w	#$f,$dff180
	move.w	#$f,$dff180
	move.w	#$f,$dff180
	move.w	#$0,$dff180
.pas_f8:

	MOVEQ	#2,D1
.w2:
	MOVE.B	$DFF006,D0
.w1:
	CMP.B	$DFF006,D0
	BEQ	.w1
	DBRA	D1,.w2
	LEA	$BFE001,A1
	AND.B	#$BF,$E00(A1)
.fintouche:
	MOVE.W	#8,$DFF09C
	MOVEM.l	(SP)+,D0/D1/A1
	RTE
	
touchebin:
	dc.l	0


; ******** end touche proc

;*****************************************************
;-------------- skip Level
;*****************************************************

;-------------- v1
_SkipLevelPrepV1
	move.w	#$387f,$9a(a6)
	move.b	#$00,_AdrSkipLevelOpt+1
	cmp.b	#$ff,_AdrSkipLevelOpt
	bne	.pas
	move.w	#0,$7d7b2	; remove quit because it's skip level
.pas	rts

_SkipLevelPosV1
	cmp.b	#$ff,_AdrSkipLevelOpt
	bne	.pas
	move.b	#$0,_AdrSkipLevelOpt
	clr.l	d5
	move.l	#$0000000a,$7d23e+2 ; your are first ;) now
.pas	move.w	d5,$7d23e
	rts

;-------------- v2
_SkipLevelPrepV2
	move.w	#$387f,$9a(a6)
	move.b	#$00,_AdrSkipLevelOpt+1
	cmp.b	#$ff,_AdrSkipLevelOpt
	bne	.pas
	move.w	#0,$7d86c	; remove quit because it's skip level
.pas	rts

_SkipLevelPosV2
	cmp.b	#$ff,_AdrSkipLevelOpt
	bne	.pas
	move.b	#$0,_AdrSkipLevelOpt
	clr.l	d5
	move.l	#$0000000a,$7d2f8+2 ; your are first ;) now
.pas	move.w	d5,$7d2f8
	rts

;*****************************************************
;------------- Button wait inserted before race by Wepl
;*****************************************************

;wait for buttonpress on preracescreen
_wait_preraceV1
	move.l	d0,-(A7)
	move.l	_buttonwait(PC),d0
	beq.s	.e
.w	btst	#6,$bfe001
	beq.s	.e
	btst	#7,$bfe001
	bne.s	.w
.e	move.l	(A7)+,d0
	tst.w	$7d7b2
	rts

_wait_preraceV2
	move.l	d0,-(A7)
	move.l	_buttonwait(PC),d0
	beq.s	.e
.w	btst	#6,$bfe001
	beq.s	.e
	btst	#7,$bfe001
	bne.s	.w
.e	move.l	(A7)+,d0
	tst.w	$7d86c
	rts


;*****************************************************
;------------- High Score by Wepl adapted for others version by CFou!
;*****************************************************

_patchLoadSaveHighscoreV1
	movem.l	d0-a6,-(a7)
	move.l	_custom1(pc),d0
	tst.l	d0
	bne	.end
	IFNE	enablesave
	bsr	_PatchLoadSaveHSGeneric
	move.w	#$4ef9,$75d12
	pea	savehigh(PC)
	move.l	(A7)+,$75d12+2

	move.w	#$4eb9,$74d74
	pea	seasonscorechange(PC)
	move.l	(A7)+,$74d74+2

	move.w	#$4eb9,$74cd4
	pea	saveseason(PC)
	move.l	(A7)+,$74cd4+2

	move.b	#$62,$74d58	;bhs -> bhi so later scores equal
		;to a former score are entered higher
	ENDC
.end
	movem.l	(a7)+,d0-a6
	rts

_patchLoadSaveHighscoreV2
	movem.l	d0-a6,-(a7)
	move.l	_custom1(pc),d0
	tst.l	d0
	bne	.end
	IFNE	enablesave

	lea	_AdrListHSV1(pc),a0
	lea	_AdrListHSV2(pc),a1
.next
	move.w	(a1)+,d0
	cmp.w	#0,d0
	beq	.endlist
	move.w	d0,(a0)+
	bra	.next
.endlist

	bsr	_PatchLoadSaveHSGeneric
	move.w	#$4ef9,$75d1c
	pea	savehigh(PC)
	move.l	(A7)+,$75d1e
	move.w	#$4eb9,$74e70
	pea	seasonscorechange(PC)
	move.l	(A7)+,$74e72
	move.w	#$4eb9,$74dd0
	pea	saveseason(PC)
	move.l	(A7)+,$74dd2
	move.b	#$62,$74e54	;bhs -> bhi so later scores equal
		;to a former score are entered higher


	ENDC
.end
	movem.l	(a7)+,d0-a6
	rts

_PatchLoadSaveHSGeneric
	IFNE	enablesave

.copyhigh
	bsr.w	copyhigh	;copy gamescores, since highscore
		; v1 was shorter

.loadhigh	;load high into extramem, if failed copy org. high therein
	;highscorefile contains 4 byte checksum, 2 byte version,
	;$20 word timestable, $14*$20 byte besttime-names
	;(there are total $20 courses), v2	additionally 3*$b*$23
	;byte racescores
	move.l	(_resload,pc),a2
	lea	_highsname(pc),a0
	jsr	(resload_GetFileSize,a2)
	tst.l	d0
	beq.w	.endloadhigh	;no score -> to game
	lea	_highsname(pc),a0
	move.l	_expmem(PC),a1
	jsr	(resload_LoadFile,a2)

	move.l	_expmem(PC),a0
	addq.l	#4,a0
	move.w	(A0)+,d0
	cmp.w	#1,d0
	beq.s	.lhv1
	cmp.w	#2,d0
	beq.s	.lhv2
	bra.w	.copyagain

.lhv2	move.l	#($40+$20*$14+$181*3+3)/4-1,d1	;len highscore v2
	bra.s	.lhva

.lhv1	move.l	#$40/4+$20*$14/4-1,d1	;len highscore v1
.lhva	moveq.l	#0,d0
.sumhigh	add.l	(a0)+,d0
	dbf	d1,.sumhigh
	move.l	_expmem(PC),a0
	cmp.l	(A0),d0
	bne.s	.copyagain
.copyloaded
	;copy all scoretables back to game, if highscore v1 the
	;original tables will be copied back (doesnt matter)
	move.l	_expmem(PC),a0
	addq.l	#4,a0
	move.w	#v_high,(A0)+	;set highscoreformat to new

;	lea.l	$7dc0e,a1	;copy loaded besttimes into game
	move.l	_BestTimes(pc),a1
	moveq.l	#$20-1,d0
.cpl1	move.w	(A0)+,(A1)+
	dbf	d0,.cpl1
;	lea.l	$7d97a,a1	;copy loaded besttimenames
	move.l	_BestTimesName(pc),a1
	move.l	#$14*$20/4-1,d0
.cpl2	move.l	(A0)+,(A1)+
	dbf	d0,.cpl2
;	lea.l	$7c9bb,a1	;copy loaded easy-scores
	move.l	_EasyScores(pc),a1
	move.l	#$181-1,d0
.cpl3	move.b	(A0)+,(A1)+
	dbf	d0,.cpl3
;	lea.l	$7cb55,a1	;copy loaded medium-scores
	move.l	_MediumScores(pc),a1
	move.l	#$181-1,d0
.cpl4	move.b	(A0)+,(A1)+
	dbf	d0,.cpl4
;	lea.l	$7cced,a1	;copy loaded hard-scores
	move.l	_HardScores(pc),a1
	move.l	#$181-1,d0
.cpl5	move.b	(A0)+,(A1)+
	dbf	d0,.cpl5
	bra.s	.endloadhigh

.copyagain	bsr.s	copyhigh	;if invalid scores were loaded,
		;copy gamescores again
.endloadhigh
	ENDC
.end
	rts

;**********************************************

	IFNE	enablesave
copyhigh	move.l	_expmem(PC),a0
	addq.l	#4,a0
	move.w	#v_high,(A0)+
;	lea.l	$7dc0e,a1	;copy initial besttimes
	move.l	_BestTimes(pc),a1
	moveq.l	#$20-1,d0
.cph1	move.w	(A1)+,(A0)+
	dbf	d0,.cph1
;	lea.l	$7d97a,a1	;copy initial besttimenames
	move.l	_BestTimesName(pc),a1
	move.l	#$14*$20/4-1,d0
.cph2	move.l	(A1)+,(A0)+
	dbf	d0,.cph2
;	lea.l	$7c9bb,a1	;copy initial easy-scores
	move.l	_EasyScores(pc),a1
	move.l	#$181-1,d0
.cph3	move.b	(A1)+,(A0)+
	dbf	d0,.cph3
;	lea.l	$7cb55,a1	;copy initial medium-scores
	move.l	_MediumScores(pc),a1
	move.l	#$181-1,d0
.cph4	move.b	(A1)+,(A0)+
	dbf	d0,.cph4
;	lea.l	$7cced,a1	;copy initial hard-scores
	move.l	_HardScores(pc),a1
	move.l	#$181-1,d0
.cph5	move.b	(A1)+,(A0)+
	dbf	d0,.cph5

	clr.b	(A0)+	;clear mem in case its end is not
	clr.b	(A0)+	;longword-aligned
	clr.b	(A0)+
	rts

seasonscorechange
	move.l	a0,-(A7)
	lea.l	seasonchangestate(PC),a0 ;my indicator
	st	(A0)
	move.l	(A7)+,a0
	sub.w	#$23,a0	;original 2 instructions
	subq.w	#1,d6
	rts
saveseason
	MOVEM.l	d0-a3,-(A7)
	move.l	_Cheat(pc),a0
;	tst.w	$7e09e	;skip cheat fields of fire
	move.l	_Cheat(pc),a0
	tst.w	(a0)	; cheat ?
	bne.s	.nohigh
	lea.l	seasonchangestate(PC),a0 ;reset my indicator
	sf	(A0)

;	LEA	$7C79D,A1	;enter seasonscore for plyr 1
;	LEA	$7C7C4,A2
	move.l	_SeasonScorePL1(pc),a1
	lea	$27(a1),a2
	bsr.s	genseasontable
	TST.W	$7D92C	;2 players active?
	BEQ.B	.no2ndplyr
;	LEA	$7C7FC,A1	;enter seasonscore for plyr 2
;	LEA	$7C823,A2
	move.l	_SeasonScorePL2(pc),a1
	lea	$27(a1),a2
	bsr.s	genseasontable
.no2ndplyr
	move.b	seasonchangestate(PC),d0 ;test my indicator
	beq.s	.nohigh
	move.l	_expmem(PC),a0
	addq.l	#6,a0
	move.l	#($40+$20*$14+$181*3+3)/4-1,d1
	moveq.l	#0,d0
.sumhigh	add.l	(a0)+,d0
	dbf	d1,.sumhigh
	move.l	_expmem(PC),a0
	move.l	d0,(A0)

	move.l	#(6+$40+$20*$14+$181*3+1),d0	;size
	lea	_highsname(pc),a0
	move.l	_expmem(PC),a1	;destination
	move.l	(_resload,PC),a2
	jsr	(resload_SaveFile,a2)

.nohigh
	MOVEM.l	(A7)+,d0-a3
;	lea.l	$7c7fc,a0	;original instruction
	move.l	_SeasonScorePL2(pc),a0
	rts

genseasontable
	;	move.w	$7d92a,d0	;level in game - PL1 game ?
	move.l	_1PLGAME(pc),a0
	move.w	(a0),d0

	and.w	#$3,d0
	lsl.w	#2,d0
	move.l	_expmem(PC),a0
	add.l	.leveloffset(pc,d0.w),a0
;	jmp	$74e14
	bra _JumpCalcSeasonTable

	;my offsets of leveltables in my highscore
.leveloffset	dc.l	6+$40+$20*$14,6+$40+$20*$14+$181
	dc.l	6+$40+$20*$14+$181*2,6+$40+$20*$14+$181*2
		;last entry is dummy

savehigh
	MOVEM.l	D0-A4,-(A7)
;	TST.W	$7E09E	;SKIP CHEAT FIELDS OF FIRE...
	move.l	_Cheat(pc),a0
	tst.w	(a0)
	BNE.W	.NOHIGH
	MOVE.L	_expmem(PC),A0
	LEA	$46(A0),A2	;BESTTIMENAMES
	LEA	6(A0),A3	;BESTTIMES
	MOVEQ.l	#$13,D4	;NAMEOFFSET OF PLAYER 1
;	MOVE.W	$7D2F8,D5	;PLACE OF PLAYER 1
	move.l	_PL1Pos(pc),a4
	move.w	(a4),d5

;	TST.W	$7D92C	;ONEPLAYERGAME
	move.l	_2PLGAME(pc),a4
	tst.w	(a4)
	BEQ.S	.SKIP2PLYR

;	CMP.W	$7D3AE,D5	;COMPARE PLACES OF PLAYERS
	move.l	_PL2Pos(pc),a4
	cmp.w	(a4),d5
	BLS.S	.SKIP2PLYR
	MOVEQ.l	#$12,D4	;NAMEOFFSET OF PLAYER 2
;	MOVE.W	$7D3AE,D5	;PLACE OF PLAYER 2
	move.w	(a4),d5
.SKIP2PLYR
;	CMP.W	#$A,D5
;	BHS.S	.NOHIGH	;no highscores if not qualified

;	JSR	$76406	;GET TOTAL COURSEOFFSET IN D1
	move.l	_AdrCalculCOURSEOFFSET(pc),a4
	jsr	(a4)

;	LEA.L	$7D20C,A0	;TIMESTABLE, ONLY PLAYERENTRYS ARE VALID
	move.l	_TimesTable(pc),a0
	MOVE.W	D5,D0
	LSL.W	#1,D0
	MOVE.W	(A0,D0.W),D0	;GET BEST TIME OF BEST PLAYER
	BEQ.S	.NOHIGH	;IF ZERO PLAYER DIDNT REACH FINISH
	MOVE.W	D1,D2	;THATS THE COURSEOFFSET
	LSL.W	#1,D2
	CMP.W	(A3,D2.W),D0
	BHI.S	.NOHIGH	;BRANCH ONLY IF TIME WAS SLOWER
;	LEA.L	$7BDE8,A1
	move.l	_BestTimesNameBis(pc),a1
	SWAP	D1
	CLR.W	D1
	SWAP	D1
	MULU	#$14,D1
	MULU	#$14,D4
	MOVE.W	D0,(A3,D2.W)	;REPLACE BEST TIME...
	MOVE.L	(A1,D4.W),(A2,D1.W)	;...AND BEST NAME
	MOVE.L	4(A1,D4.W),4(A2,D1.W)
	MOVE.L	8(A1,D4.W),8(A2,D1.W)
	MOVE.L	$C(A1,D4.W),$C(A2,D1.W)
	MOVE.L	$10(A1,D4.W),$10(A2,D1.W)

	move.l	_expmem(PC),a0
	addq.l	#6,a0
	move.l	#($40+$20*$14+$181*3+3)/4-1,d1
	moveq.l	#0,d0
.sumhigh	add.l	(a0)+,d0
	dbf	d1,.sumhigh
	move.l	_expmem(PC),a0
	move.l	d0,(A0)

	move.l	#(6+$40+$20*$14+$181*3+1),d0	;size
	lea	_highsname(pc),a0
	move.l	_expmem(PC),a1	;destination
	move.l	(_resload,PC),a2
	jsr	(resload_SaveFile,a2)

.NOHIGH	moveM.l	(A7)+,D0-A4

	MOVE.B	#0,(A2)	;THE 2 ORIGINAL INSTRUCTIONS
	RTS
	ENDC	

_AdrListHSV1:
_BestTimes
	dc.l	$7db54 ;$7dc0e	;copy loaded besttimes into game
_BestTimesName
	dc.l	$7d8c0 ;$7d97a	;copy loaded besttimenames
_EasyScores
	dc.l	$7c901 ;$7c9bb	;copy loaded easy-scores
_MediumScores
	dc.l	$7ca9b ;$7cb55	;copy loaded medium-scores
_HardScores
	dc.l	$7cc33 ;$7cced	;copy loaded hard-scores
_Cheat
	dc.l	$7dfe4 ;$7e09e
_SeasonScorePL1
	dc.l	$7c7db ;$7C79D	;enter seasonscore for plyr 1
_SeasonScorePL2
	dc.l	$7c83a ;$7C7FC	;enter seasonscore for plyr 2
_1PLGAME
	dc.l	$7d870 ;$7d92a	;level in game - PL1 game ?
_2PLGAME
	dc.l	$7d872 ;$7d92a+2	;level in game - PL1 game ?
_JumpCalcSeasonTable
	dc.w	$4ef9
	dc.l	$74d18	;$74e14	;	jmp	$74e14
_PL1Pos
	dc.l	$7d23e	;$7D2F8	;PLACE OF PLAYER 1
_PL2Pos
	dc.l	$7d2f4	;$7D3AE	;PLACE OF PLAYER 2
_AdrCalculCOURSEOFFSET
	dc.l	$76492	;$76406	;GET TOTAL COURSEOFFSET IN D1
_TimesTable
	dc.l	$7d152	;$7D20C	;TIMESTABLE, ONLY PLAYERENTRYS ARE VALID
_BestTimesNameBis
	dc.l	$7be26	;$7BDE8	;copy loaded besttimenames
	dc.l	0

_AdrListHSV2:
;_BestTimes
	dc.l	$7dc0e	;copy loaded besttimes into game
;_BestTimesName
	dc.l	$7d97a	;copy loaded besttimenames
;_EasyScores
	dc.l	$7c9bb	;copy loaded easy-scores
;_MediumScores
	dc.l	$7cb55	;copy loaded medium-scores
;_HardScores
	dc.l	$7cced	;copy loaded hard-scores
_CheatV2
	dc.l	$7e09e
;_SeasonScorePL1
	dc.l	$7C79D	;enter seasonscore for plyr 1
;_SeasonScorePL2
	dc.l	$7C7FC	;enter seasonscore for plyr 2
;_1PLGAME
	dc.l	$7d92a	;level in game - PL1 game ?
;_2PLGAME
	dc.l	$7d92a+2	;level in game - PL1 game ?
;_JumpCalcSeasonTable
	dc.w	$4ef9
	dc.l	$74e14	;	jmp	$74e14
;_PL1Pos
	dc.l	$7D2F8	;PLACE OF PLAYER 1
;_PL2Pos
	dc.l	$7D3AE	;PLACE OF PLAYER 2
;_AdrCalculCOURSEOFFSET
	dc.l	$76406	;GET TOTAL COURSEOFFSET IN D1
;_TimesTable
	dc.l	$7D20C	;TIMESTABLE, ONLY PLAYERENTRYS ARE VALID
;_BestTimesNameBis
	dc.l	$7BDE8	;copy loaded besttimenames
	dc.l	0



_highsname
	dc.b	"highs",0
seasonchangestate
	dc.b	0
	even
;*****************************************************
;*****************************************************


;--------------------------------
 
_resload	dc.l	0	;address of resident loader 
_tag
	dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
	dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
	dc.l	WHDLTAG_BUTTONWAIT_GET
_buttonwait	dc.l	0
	dc.l	0	; End

	
 
;-------------------------------- 
; IN:	d0=offset d1=size d2=disk a0=dest 
; OUT:	d0=success 
 
_LoadDisk	movem.l	d0-d1/a0-a2,-(a7) 
	move.l	_resload(pc),a2 
	jsr	resload_DiskLoad(a2) 
	movem.l	(a7)+,d0-d1/a0-a2 
	rts 

;-------------------------------- 
_exit	pea	TDREASON_OK.w
	bra.b	_end
_debug	pea	TDREASON_DEBUG.w
_abort
_end	move.l	_resload(pc),-(a7) 
	addq.l	#resload_Abort,(a7) 
	rts


;====================================================================== 
	end
	
_SMC99
	movem.l	d0-a6,-(a7)
	lea	opt(pc),a0
	move.l	(a0),d0
	cmp.l	#$ff,d0
	beq	.pas
	move.l	#$ff,(a0)
	lea	$72300,a0
	lea	$7764e,a0
	move.l	#$7b80e-$7764e,d0
	move.l	_resload(pc),a2
	jsr	(resload_ProtectSMC,a2)	
.pas
	movem.l	(a7)+,d0-a6
	rts
_SMC99b
	
	movem.l	d0-a6,-(a7)
	lea	opt(pc),a0
	move.l	(a0),d0
	cmp.l	#$ff,d0
	beq	.pas
	move.l	#$ff,(a0)
	move.l	_resload(pc),a2
	lea	$78e4a-2,a0
	moveq	#10,d0
	jsr	(resload_ProtectWrite,a2)
.pas	movem.l	(a7)+,d0-a6
	rts

	
