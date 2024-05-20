
		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"MortalKombat.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

_name		dc.b	"Mortal Kombat",0
_copy		dc.b	"1993 Acclaim",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version 0.9 "
		INCBIN	"T:date"
		dc.b	-1,"Thanks to Jean-François Fabre for the original JST install",10
		dc.b	"and to Chris Vella and Carlo Pirri for the originals!",0
_Highs		dc.b	"MortalKombat.highs",0
_CheatFlag	dc.b	0
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	lea	_LoadFileStart(pc),a0	;Source
		lea	$10000,a1		;Destination
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_Decrunch(a2)

		lea	_PL_Boot(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		jmp	$2a(a5)			;Start game

_PL_Boot	PL_START
		PL_W	$bc,$2200		;Colour bit fix (was $2020)
		PL_P	$294,_Patch		;Patch main
		PL_B	$596,3
		PL_B	$570,$54
		PL_L	$59c,$80000		;Expansion memory
		PL_L	$5a0,0
		PL_P	$bc6,_Loader
		PL_P	$fdc,_Decrunch
		PL_END

;======================================================================

_Patch		movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_Main(pc),a0		;Patch main game
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		bsr	_LoadHighScores		;Load high scores

		move.w	#$4ef9,$100
		pea	_SaveHighScores(pc)
		move.l	(sp)+,$102

		clr.l	-(a7)			;Set switch between O/S and
		pea	_cbswitch		;game, otherwise game freezes
		pea	WHDLTAG_CBSWITCH_SET	;after the high scores are
		move.l	a7,a0			;saved
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		add.w	#12,a7

		movem.l	(sp)+,d0-d1/a0-a2

		move.w	#0,d0			;Attn flags
		move.w	d0,d1
		jmp	(a1)

_PL_Main	PL_START			;Self modifying code at $80050, beware!
		PL_S	$11a,$120-$11a		;move.b #0,$bfd200
		PL_W	$136,$cc01		;move.w #$cc00,($34,a6)
		PL_PS	$848,_SetCheat		;User has typed CATHULU
		PL_PS	$bec,_2ButtonModeFix
		PL_PS	$bf8,_2ButtonModeFix
		PL_PS	$1050,_keybd		;Detect quit key
		PL_PS	$6c20,_2ButtonModeFix
		PL_P	$6ed8,_Loader		;RNC loader
		PL_P	$72ec,_Decrunch		;RNC decruncher
		PL_L	$74fe,$203caa79		;Copylock
		PL_L	$7502,$4baf4e75
		PL_PS	$ede8,_2ButtonModeFix
		PL_PS	$f01e,_2ButtonModeFix
		PL_L	$f634,$4ef80100		;Save high scores
		PL_PS	$1fbd6,_SnoopBug
		PL_END

;======================================================================

_cbswitch	move.l	#$af8,(cop2lc+_custom)	;Required for high scores :)
		;move.w	#-1,(bltafwm+_custom)
		;move.w	#0,(bltalwm+_custom)
		jmp	(a0)

;======================================================================

;_SelfModifyCode	adda.l	(a5)+,a4	;No longer needed
;_ModifyIt	cmp.l	#$8f630,a4
;		beq	_NextPatch
;		add.l	d0,(a4)
;_NextPatch	move.b	(a5)+,d1
;		beq.b	_PatchesDone
;		andi.w	#$FF,d1
;		adda.w	d1,a4
;		cmpi.w	#1,d1
;		bne.b	_ModifyIt
;		adda.w	#$FD,a4
;		bra.b	_NextPatch
;_PatchesDone	rts

;======================================================================

_SetCheat	move.l	a0,-(sp)		;Set cheat flag
		lea	_CheatFlag(pc),a0
		move.b	#-1,(a0)
		move.l	(sp)+,a0

		bchg	#0,(1,a1)		;Stolen code
		rts

;======================================================================

_SnoopBug	cmp.l	#$dff000,a6
		bne	_DoMove
		move.w	#-1,(6,a5)
		rts

_DoMove		move.w	($6c,a6),(6,a5)
		rts

;======================================================================

_Loader		movem.l	d1-d2/a0-a2,-(sp)	;d0 = drive, d1 = offset, d2 = blocks, a0 = buffer
		cmp.l	#0,d1			;Skip dummy loads
		beq	_LoadDone
		exg.l	d0,d1
		exg.l	d1,d2
		sub.l	#24,d0
		mulu	#$200,d0		;d0 = Offset (bytes)
		mulu	#$200,d1		;d1 = Length (bytes)
		addq	#1,d2			;d2 = Disk number
		move.l  _resload(pc),a2
		jsr	resload_DiskLoad(a2)
_LoadDone	moveq	#0,d0
		movem.l	(sp)+,d1-d2/a0-a2
		rts

;======================================================================

_keybd		cmp.b	_keyexit(pc),d0
		beq	_exit

		bset	#6,($e00,a0)		;Stolen code
		rts

;======================================================================

_2ButtonModeFix	move.w	$dff016,d0
		move.w	#$cc01,$dff034
		rts

;======================================================================

_LoadHighScores	movem.l	d0-d1/a0-a3,-(sp)
		lea	$8ada2,a1
		move.l	a1,a3
		lea	_Highs(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		tst.l	d0
		beq	_NoHighsFound

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	a3,a1			;a1 = Address
		move.l	a1,-(sp)
		jsr	resload_LoadFile(a2)
		move.l	(sp)+,a1
		bsr	_Encrypt

_NoHighsFound	movem.l	(sp)+,d0-d1/a0-a3
		rts

;======================================================================

_SaveHighScores	movem.l	d0-d1/a0-a2,-(sp)

		moveq	#0,d0
		move.b	_CheatFlag(pc),d0	;Check if user is a cheat
		bne	_DoNotSave

		lea	_Highs(pc),a0		;a0 = Filename
		lea	$8a972,a1		;a1 = Address (different from load address)
		move.l  _resload(pc),a2
		bsr	_Encrypt		;Encrypt scores
		move.l	a1,-(sp)
		jsr	resload_SaveFile(a2)	;Save scores
		move.l	(sp)+,a1
		bsr	_Encrypt		;Decrypt scores

_DoNotSave	movem.l	(sp)+,d0-d1/a0-a2
		moveq	#-1,d0
		rts

;======================================================================

_Encrypt	move.l	#72,d0			;Set d0 = length
		move.l	d0,-(sp)
.enc		eor.b	d0,(a1)+
		subq.l	#1,d0
		bne.s	.enc
		move.l	(sp)+,d0
		sub.l	d0,a1
		rts

;======================================================================

_Decrunch	movem.l	d0-d7/a0-a6,-(sp)	;Cannot use built in 
		lea	(-$180,sp),sp		;WHDLoad function or you
		movea.l	sp,a2			;will get a corrupt game!
		bsr.w	_ReadLong
		moveq	#0,d1
		cmpi.l	#$524E4301,d0
		bne.w	_Rob_15
		bsr.w	_ReadLong
		move.l	d0,($180,sp)
		lea	(10,a0),a3
		movea.l	a1,a5
		lea	(a5,d0.l),a6
		bsr.w	_ReadLong
		lea	(a3,d0.l),a4
		clr.w	-(sp)
		cmpa.l	a4,a5
		bcc.b	_Rob_6
		moveq	#0,d0
		move.b	(-2,a3),d0
		lea	(a6,d0.l),a0
		cmpa.l	a4,a0
		bls.b	_Rob_6
		addq.w	#2,sp
		move.l	a4,d0
		btst	#0,d0
		beq.b	_Rob_1
		addq.w	#1,a4
		addq.w	#1,a0
_Rob_1		move.l	a0,d0
		btst	#0,d0
		beq.b	_Rob_2
		addq.w	#1,a0
_Rob_2		moveq	#0,d0
_Rob_3		cmpa.l	a0,a6
		beq.b	_Rob_4
		move.b	-(a0),d1
		move.w	d1,-(sp)
		addq.b	#1,d0
		bra.b	_Rob_3

_Rob_4		move.w	d0,-(sp)
		adda.l	d0,a0
_Rob_5		lea	(-$20,a4),a4
		movem.l	(a4),d0-d7
		movem.l	d0-d7,-(a0)
		cmpa.l	a3,a4
		bhi.b	_Rob_5
		suba.l	a4,a3
		adda.l	a0,a3
_Rob_6		moveq	#0,d7
		move.b	(1,a3),d6
		rol.w	#8,d6
		move.b	(a3),d6
		moveq	#2,d0
		moveq	#2,d1
		bsr.w	_Rob_21
_Rob_7		movea.l	a2,a0
		bsr.w	_Rob_24
		lea	($80,a2),a0
		bsr.w	_Rob_24
		lea	($100,a2),a0
		bsr.w	_Rob_24
		moveq	#-1,d0
		moveq	#$10,d1
		bsr.w	_Rob_21
		move.w	d0,d4
		subq.w	#1,d4
		bra.b	_Rob_10

_Rob_8		lea	($80,a2),a0
		moveq	#0,d0
		bsr.w	_Rob_17
		neg.l	d0
		lea	(-1,a5,d0.l),a1
		lea	($100,a2),a0
		bsr.w	_Rob_17
		move.b	(a1)+,(a5)+
_Rob_9		move.b	(a1)+,(a5)+
		dbra	d0,_Rob_9
_Rob_10		movea.l	a2,a0
		bsr.w	_Rob_17
		subq.w	#1,d0
		bmi.b	_Rob_12
_Rob_11		move.b	(a3)+,(a5)+
		dbra	d0,_Rob_11
		move.b	(1,a3),d0
		rol.w	#8,d0
		move.b	(a3),d0
		lsl.l	d7,d0
		moveq	#1,d1
		lsl.w	d7,d1
		subq.w	#1,d1
		and.l	d1,d6
		or.l	d0,d6
_Rob_12		dbra	d4,_Rob_8
		cmpa.l	a6,a5
		bcs.b	_Rob_7
		move.w	(sp)+,d0
		beq.b	_Rob_14
_Rob_13		move.w	(sp)+,d1
		move.b	d1,(a5)+
		subq.b	#1,d0
		bne.b	_Rob_13
_Rob_14		bra.b	_Rob_16

_Rob_15		move.l	d1,($180,sp)
_Rob_16		lea	($180,sp),sp
		movem.l	(sp)+,d0-d7/a0-a6
		rts

_Rob_17		move.w	(a0)+,d0
		and.w	d6,d0
		sub.w	(a0)+,d0
		bne.b	_Rob_17
		move.b	($3C,a0),d1
		sub.b	d1,d7
		bge.b	_Rob_18
		bsr.b	_Rob_23
_Rob_18		lsr.l	d1,d6
		move.b	($3D,a0),d0
		cmpi.b	#2,d0
		blt.b	_Rob_20
		subq.b	#1,d0
		move.b	d0,d1
		move.b	d0,d2
		move.w	($3E,a0),d0
		and.w	d6,d0
		sub.b	d1,d7
		bge.b	_Rob_19
		bsr.b	_Rob_23
_Rob_19		lsr.l	d1,d6
		bset	d2,d0
_Rob_20		rts

_Rob_21		and.w	d6,d0
		sub.b	d1,d7
		bge.b	_Rob_22
		bsr.b	_Rob_23
_Rob_22		lsr.l	d1,d6
		rts

_Rob_23		add.b	d1,d7
		lsr.l	d7,d6
		swap	d6
		addq.w	#4,a3
		move.b	-(a3),d6
		rol.w	#8,d6
		move.b	-(a3),d6
		swap	d6
		sub.b	d7,d1
		moveq	#$10,d7
		sub.b	d1,d7
		rts

_ReadLong	moveq	#3,d1
_ReadByte	lsl.l	#8,d0
		move.b	(a0)+,d0
		dbra	d1,_ReadByte
		rts

_Rob_24		moveq	#$1F,d0
		moveq	#5,d1
		bsr.b	_Rob_21
		subq.w	#1,d0
		bmi.b	_Rob_30
		move.w	d0,d2
		move.w	d0,d3
		lea	(-$10,sp),sp
		movea.l	sp,a1
_Rob_25		moveq	#15,d0
		moveq	#4,d1
		bsr.b	_Rob_21
		move.b	d0,(a1)+
		dbra	d2,_Rob_25
		moveq	#1,d0
		ror.l	#1,d0
		moveq	#1,d1
		moveq	#0,d2
		movem.l	d5-d7,-(sp)
_Rob_26		move.w	d3,d4
		lea	(12,sp),a1
_Rob_27		cmp.b	(a1)+,d1
		bne.b	_Rob_29
		moveq	#1,d5
		lsl.w	d1,d5
		subq.w	#1,d5
		move.w	d5,(a0)+
		move.l	d2,d5
		swap	d5
		move.w	d1,d7
		subq.w	#1,d7
_Rob_28		roxl.w	#1,d5
		roxr.w	#1,d6
		dbra	d7,_Rob_28
		moveq	#$10,d5
		sub.b	d1,d5
		lsr.w	d5,d6
		move.w	d6,(a0)+
		move.b	d1,($3C,a0)
		move.b	d3,d5
		sub.b	d4,d5
		move.b	d5,($3D,a0)
		moveq	#1,d6
		subq.b	#1,d5
		lsl.w	d5,d6
		subq.w	#1,d6
		move.w	d6,($3E,a0)
		add.l	d0,d2
_Rob_29		dbra	d4,_Rob_27
		lsr.l	#1,d0
		addq.b	#1,d1
		cmpi.b	#$11,d1
		bne.b	_Rob_26
		movem.l	(sp)+,d5-d7
		lea	($10,sp),sp
_Rob_30		rts

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

_LoadFileStart	dc.l	$524E4301,$1200,$FC1,$62C30CF0,$1A411
		dc.l	$112ABB73,$87353333,$43648425,$64880204,$EE186100
		dc.l	$3706708,$43FA0568,$12BC0046,$41865CD6,$887402F5
		dc.l	$C8665250,$B0A9FFFC,$670222C0,$57CAFFF0,$4DF900DF
		dc.l	$F0C205FC,$27003D7C,$7FFF009A,$2D3E9649,$291E4F10
		dc.l	$BB078000,$41060000,$3BE1FFAE,$B3FC0005,$EE00630E
		dc.l	$4A190612,$620607,$4AC748E7,$C0303C,$47F20D9
		dc.l	$51C854AE,$4CDF0300,$45FA0008,$95C94EF0,$A8DEB304
		dc.l	$4D2DD40F,$9F4298B3,$5491F718,$58235211,$36E21C8
		dc.l	$6C862E,$73CACF20,$2D4800,$80426E00,$88202001
		dc.l	$5DB46484,$10216B4,$4A00508,$A092E2C,$81008EA3
		dc.l	$8C380092,$D0009404,$B2F4C100,$909C8400,$9C1004C0
		dc.l	$9A5D1AB0,$5CC14222,$CC034434,$83907D4E,$2BC001EC
		dc.l	$C400004,$66D4111F,$2147CBD,$5019050F,$E1F69519
		dc.l	$A67E03C1,$49046420,$18043C51,$CFFFF82D,$29169242
		dc.l	$1B2A8A5E,$E1B09D51,$2670AAD,$270166F0,$6000FF28
		dc.l	$1B91EFD0,$BC971D6A,$41F80400,$4336B153,$4C700072
		dc.l	$18740C76,$283C9B,$8C915EF8,$C04C450A,$3C661E37
		dc.l	$EF1F0641,$C0C41,$7806DE8,$BEF87C8,$922EF513
		dc.l	$A22E002F,$12F07CA,$B746570,$14C4051C,$C8589751
		dc.l	$8201F28,$42A4D111,$FD788582,$F6F29880,$FC2A128E
		dc.l	$842A60CB,$44A60C58,$6D064AA8,$C7E10C44,$9A0648D0
		dc.l	$923300F0,$7B50092,$4B7C3F07,$B4348451,$A300020
		dc.l	$29B79522,$246C1C,$EA89A6AB,$282001F,$FFFF0682
		dc.l	$6A2FFFE2,$8AE08A32,$50280C84,$2CFB5193,$630AB376
		dc.l	$9502144,$2044ABC7,$F23821EA,$96A3E1F,$4A4057CF
		dc.l	$FFAC670C,$EC5002C0,$D6C8841A,$39E88B94,$1C4CD00F
		dc.l	$6089490D,$540D760E,$2B853A02,$DE287843,$1F322C01
		dc.l	$284ED17E,$2362BCB,$AC019C34,$41B39BA2,$63092308
		dc.l	$E1E5DA0C,$795A4C39,$CA671049,$39050963,$1A80A3F3
		dc.l	$F8E0B2BE,$8C3239B6,$46021141,$3E049,$599D014E
		dc.l	$7577CCDA,$60FE01E2,$4BBFE001,$9CB4082D,$A7A6B881
		dc.l	$660408C0,$6BBCC,$1082E05,$B716389B,$2E7B106
		dc.l	$63EA031E,$52933D6E,$180C751,$67F2426E,$1C9D300
		dc.l	$CE3639E6,$4642407E,$735270F1,$80721F3C,$C051C9FF
		dc.l	$FC720220,$9398088F,$CC224A80,$61B0000,$BD516114
		dc.l	$63C400F8,$801F2FF1,$AC07D004,$201F56D3,$48E760C0
		dc.l	$2C50CC4E,$AEFF3A7E,$2806AC4D,$999101F6,$43FA0E4A
		dc.l	$389A0C20,$E8684A1,$8EF39EA4,$9D002C7C,$138067A
		dc.l	$27121848,$816B0A9A,$4112D864,$83600C14,$184441C2
		dc.l	$9D9B5345,$6AE0D2FC,$1F4043E9,$FFDA81CC,$FFD43E06
		dc.l	$5247CE4F,$A93C7DA,$BB002891,$8FC012D6,$2F088052
		dc.l	$50205F33,$FC83DF9A,$76CDDF9C,$4E73303A,$16EB07A
		dc.l	$16A67FA,$76F0AE01,$91BA0074,$616628BE,$85243C66
		dc.l	$ABAF283C,$33000300,$7E063602,$10C0107A,$5DF30FC
		dc.l	$FFFE0182,$30C3EA6E,$843203E2,$49024107,$7730C1D6
		dc.l	$440C4724,$FE6E0496,$44684B52,$40E62DAA,$6E1CDA1B
		dc.l	$CC4844E8,$4C4842E8,$5A0C4260,$6660434,$3C0606ED
		dc.l	$286FAE67,$F11E3019,$30C5B0CB,$6ED319E0,$6F6CE2F0
		dc.l	$C0E4C983,$E69F9362,$9ABDF01,$2705B25E,$2D0999A3
		dc.l	$F4FE4735,$B1527143,$F347EB14,$89951018,$67340417
		dc.l	$323065A6,$96F04CA,$3076104,$60E8459F,$CE94004A
		dc.l	$406B16D4,$C0700612,$9245EA45,$DA245C60,$E1F4FEE8
		dc.l	$5289615D,$3B935645,$52494659,$444953,$4B4F4B00
		dc.l	$9EBD524F,$525B0031,$204D4547,$41425954,$45204F46
		dc.l	$2052414D,$2304551,$55494400,$540B1F43,$B622494E
		dc.l	$535420D7,$31204120,$4B1C544F,$35224630,$90C35458
		dc.l	$5D58E188,$7205E998,$48E74269,$6DB8CC68,$F6100FF
		dc.l	$764CDF00,$36CACEC,$58738AB1,$EB0166BF,$9735524E
		dc.l	$43E99509,$64060B29,$554A150E,$DE340398,$90A12A06
		dc.l	$66542433,$33542684,$83DE0F1,$DB464D8F,$CE5C494C
		dc.l	$424DBCED,$48449C1D,$1401F9,$102DD2DC,$7C21C3F6
		dc.l	$801013D,$C7434D41,$508AFE0C,$FAADFFAF,$2917FF42
		dc.l	$4F4459DB,$C1FF77B,$79C0F3BE,$C703FFE0,$30FEDA31
		dc.l	$3FA00F8,$6D1E01F2,$762C0400,$10406821,$417600F
		dc.l	$145F975,$53FD6CD,$FFFCBC43,$FF8000FE,$C05AF016
		dc.l	$AD078311,$2FAFB95,$59081B59,$1303C012,$383BAF07
		dc.l	$FFC0F8D1,$E2807FE0,$B41C0FC2,$A0ED7CFD,$B0800
		dc.l	$20996FC6,$ED408010,$AEC0100D,$BC07C099,$10FFFD9
		dc.l	$4AF0001F,$79CC04D,$1F082AE0,$9DF40A10,$80F93D
		dc.l	$F63A10E3,$703B9E0F,$C0C2351F,$FEFCFA89,$9B079633
		dc.l	$3F0910D6,$6800302B,$20019BA7,$5100416,$840B823
		dc.l	$1FC0B448,$3CE582B,$C0010370,$327FB6B4,$8119D446
		dc.l	$520EFF2,$402C840F,$B331AF3F,$61A67FFC,$7441985
		dc.l	$E9A698FF,$25CBD824,$CDDCBD41,$8746CB66,$220576B
		dc.l	$F9867917,$7FC54CF6,$F236C1E4,$85A06303,$802C1BF1
		dc.l	$5F044AB1,$69B224EA,$27C4B10,$1EDB0BBB,$BFA18001
		dc.l	$DFDD103F,$FC14ABFE,$D4DFA18,$320540A3,$AC20B102
		dc.l	$440024A,$F7801B03,$38F39FF0,$71C4E2D,$F8B06280
		dc.l	$15E09603,$4592304,$473719C,$67E91003,$10B9228B
		dc.l	$BE214B07,$3664433E,$FFF0221F,$1FD9B708,$FD520A08
		dc.l	$4A664,$894A820,$8D1A0F69,$4D3F6445,$FF90CD0D
		dc.l	$F2013F10,$520464E6,$E510C002,$D142100A,$D94090D7
		dc.l	$1E84551E,$7FFE8681,$14F27BC8,$C721F86F,$A21A0821
		dc.l	$2D2620A8,$A0840D2A,$3C0EE897,$F4E63C82,$A0F802A
		dc.l	$E8F35182,$420EF358,$B4CC5902,$40395301,$168E9857
		dc.l	$7878CCD4,$FC45000C,$F401E3A8,$79845221,$FE75BA01
		dc.l	$28B6152,$D0618A0F,$F01EA9DC,$70C21C77,$47E61602
		dc.l	$3C32955,$FA31EC5B,$2E048880,$20161301,$40145FA
		dc.l	$4E4CC0C3,$5C1C0FE0,$B3981FC7,$300F030F,$88897698
		dc.l	$B9FD8B01,$10F480D7,$E107801D,$5E76C041,$A48E9BC3
		dc.l	$131EEFAA,$8790D0B,$2052C521,$631B2004,$102143E4
		dc.l	$9BCD500F,$65C938,$866A0381,$A9893FF8,$1F3C7A11
		dc.l	$362A69D7,$4C0C40F4,$C0657057,$191E07CD,$96E91D3F
		dc.l	$F058B321,$E27841D3,$144764CD,$AF6FB4EA,$80FD07DA
		dc.l	$84A009,$3C78BAA9,$E0136A0,$9DBF007F,$A057F042
		dc.l	$FF6D0511,$2BB9131,$EB0480AF,$69D4464D,$7870D4D5
		dc.l	$1C1AF086,$BAD8A4FC,$43D4E06B,$A84FDBC,$3D22ADA6
		dc.l	$7A2AD0C,$B6021061,$AFF09199,$3803B0D5,$E059C2C0
		dc.l	$A6B4FB45,$C9511F26,$DB440499,$F310FC21,$C70420F8
		dc.l	$B99145,$EFFEFF13,$42BFE007,$FC70073C,$EB9F40D
		dc.l	$CB51DB10,$80288D1,$5C6929F7,$31AF0361,$86FEF0F2
		dc.l	$61B62AF0,$8179A801,$732D0501,$C481901C,$20936540
		dc.l	$B9C10A1,$851A0F99,$BBC02707,$FFE00FFC,$93B7003C
		dc.l	$3E1DCA,$337373DE,$8BC50910,$C446AC1E,$F3C0DC09
		dc.l	$C00F8D78,$F4426FD,$21E5F347,$2120DD76,$28C5046D
		dc.l	$843CD0B3,$802221B3,$40BBD0E0,$F0734E,$42FD856E
		dc.l	$2401069,$739BE4B0,$B6038010,$1838E1A,$78E73947
		dc.l	$841F6E3E,$725CBE0,$67D4ECB,$84FCB723,$80A30C5E
		dc.l	$8D0217DE,$1E91F0AF,$C8FE915E,$A271B8E1,$8ABC3278
		dc.l	$FC158B04,$4CE520FD,$D5C56136,$20F7A50E,$1B922307
		dc.l	$8003FCB4,$3D160EFF,$3FEE8,$33026BCD,$104D516
		dc.l	$BD944ED2,$186EE40,$900A03C0,$B4B9FB73,$5BF619CA
		dc.l	$3252D2D0,$676204,$CD750608,$82CDEB74,$828E7A8
		dc.l	$38E02550,$AC004CA4,$3F0C2AF,$66B980E0,$671E0322
		dc.l	$8735FE03,$360C08AA,$A36F8C40,$2103A2F9,$67940F00
		dc.l	$1E4303E0,$4FE50F11,$75630E80,$3CABA3FC,$223D669A
		dc.l	$920F343,$80F7418F,$F0018020,$FE1D0E0E,$1B051C
		dc.l	$3F5913E0,$3F80B952,$A326A3E7,$D8E4D40D,$423B40FE
		dc.l	$38A0696F,$DD01AAD1,$96C910C9,$9581BC78,$19421532
		dc.l	$B0A5F05C,$2780727A,$7FE63889,$A55B1F,$28B42EDB
		dc.l	$1D38B5E2,$D4D0A540,$1C1250B4,$89510208,$81220A2
		dc.l	$148096FD,$8035033A,$52FF87FF,$FF183BEB,$941F8D71
		dc.l	$10ABF3FC,$EAE4CE71,$9308F400,$E99931FE,$F3337F37
		dc.l	$1FE3624,$38307870,$1C7C1878,$5F9E5E73,$383C1844
		dc.l	$100EC640,$44C2EF8E,$783C0404,$2C68C1D,$8BD9B49F
		dc.l	$6470CCD8,$2C6030C8,$24CC384C,$3C6CE0F0,$3CCC307C
		dc.l	$CCC0EEE6,$3CAF1E48,$C7CCF04C,$4C46C6CC,$C0FD24C
		dc.l	$300C0C48,$38600844,$CC6C4C64,$6CC0C060,$BE900CF8
		dc.l	$C0FEE664,$CC644CC0,$30CCCCC6,$6CD81810,$328B27D4
		dc.l	$5BA90898,$C79584C,$F8604CD8,$D840FCD8,$C9F0C0D6
		dc.l	$F664F85A,$2460A7CD,$D6387830,$303C8332,$E430E6EC
		dc.l	$563DFC0C,$CC10C418,$FC7A37F0,$DCA2763D,$6E08D8C0
		dc.l	$C6DE4C1C,$C8F86BD6,$FEB02960,$2031506B,$73093931
		dc.l	$60F059DA,$1330FDCC,$FFC0FFCC,$1130D865,$83C6CED5
		dc.l	$92D0E30C,$78EE6C30,$85B34BBA,$FF7825FC,$F8A7EDED
		dc.l	$F1E0CCF8,$78F8FCC0,$78BD6C70,$C67CC6C6,$78C074CC
		dc.l	$E9653073,$E130FCA1,$5E0569CE,$8C7FFC4E,$56FFDE3A
		dc.l	$24500,$33D45A7,$5F3D41FF,$E03D42FF,$E23D43FF
		dc.l	$E42D44FF,$EE2D48FF,$E62D49FF,$EAE4589C,$1DF33801
		dc.l	$52403D40,$FFF27000,$360267C4,$101ED641,$B67C0780
		dc.l	$6E8C48C1,$82D7A274,$E20C6EA9,$52F26702,$D2412434
		dc.l	$F448BB7D,$8DB16430,$2ECC2572,$C9240B2,$6ED2356F
		dc.l	$4322EA5,$52F8615E,$66282615,$E290E70A,$F8671EE2
		dc.l	$B6CEF8E1,$88D080D1,$AE0C1542,$F884F6F2,$D1C5DDF4
		dc.l	$60BE2FA4,$8302EE20,$1F672072,$7F24F4,$3D9DE249
		dc.l	$C23BBCD2,$DADB0BFF,$FC2F4100,$264E5E4A,$804CDF3F
		dc.l	$FE4E757A,$2B8E6F4,$4C7C701D,$839CBB6,$5B4DF671
		dc.l	$67282A46,$3EA204D,$224D700B,$D0FC040A,$4258D259
		dc.l	$A2AF0038,$F79690AF,$4D611A30,$39906712,$316E7099
		dc.l	$71017F4B,$1E0B9F5,$51CDFFB4,$60644305,$67ED0033
		dc.l	$7C402424,$90801000,$96DDFB02,$19E9515,$8C234800
		dc.l	$20E50C9C,$44E14F9,$57E33FC,$998B243E,$D788F91F
		dc.l	$BBDB8CFA,$CC09C47E,$829DFEB,$99EB1F66,$A723D64
		dc.l	$66F270FF,$60027000,$89EB02C9,$C5BCAE6,$DA6E3DB3
		dc.l	$598837FA,$BDE8FC24,$E66FD650,$7AB667E1,$1A6068F
		dc.l	$C19EB3E1,$41177E9E,$BAAA8E0C,$55489197,$9C8A41ED
		dc.l	$45FF2018,$22180280,$55129A02,$816C9AD0,$80808122
		dc.l	$2E926B08,$C1B38026,$4840B0,$56E1F566,$5CE0488C
		dc.l	$AFB6654,$F76D2212,$444CF9D2,$91A2B001,$6C1635E4
		dc.l	$560F5CB6,$40663C22,$4A617A45,$EABA8852,$DAB9E9D8
		dc.l	$90301D72,$7407E5,$50E31151,$CA50C6D2,$41DBC1FA
		dc.l	$6C060CB2,$FCD4A6FF,$727567AD,$DA1B6F1B,$DC44195A
		dc.l	$F369A20B,$B8DA1DAF,$CC017267,$64A6D40,$D767F4AA
		dc.l	$C5800B6A,$3275CDFF,$2418B580,$88C6FA0E,$DA22412A
		dc.l	$41E93280,$414CDF01,$6999FF8,$E0707F45,$E8D44326
		dc.l	$3C288BAD,$5B0FA638,$241AC283,$C483D281,$8282B384
		dc.l	$22C42801,$FC70EC07,$34B3F00,$F3DF9BCE,$DED04041
		dc.l	$FB00504A,$506A0261,$163017E2,$48E2D0C0,$BA906E87
		dc.l	$472FF44,$40616A30,$9F602872,$55D80E04,$1BC5102F
		dc.l	$170A816,$FF615222,$1F2283EA,$25B8DB05,$E425061
		dc.l	$1013C0D1,$9DB65B51,$FB6D2866,$3F011039,$BFD87F4A
		dc.l	$75DE5601,$3805701,$63E627AE,$10DE0828,$31D36704
		dc.l	$8800002,$326D144A,$672A8D,$2861CC4A,$16BCDF0
		dc.l	$1469E00,$6357C319,$739CFC78,$70036148,$301F5300
		dc.l	$66D233FC,$4B6373B,$214A6EFF,$E46A1E13,$C187591F
		dc.l	$13568001,$81EC2101,$C17CEC1A,$D8F4976E,$54088175
		dc.l	$ABD47064,$D080611E,$ED47BFDE,$6994F653,$8066F087
		dc.l	$F137BC1C,$B8256718,$13FC36B6,$E1C0CCC0,$B3D40D19
		dc.l	$D5133BFB,$2AE830FF,$FE4FEFFE,$80244FA7,$1372000C
		dc.l	$8057A4D9,$4609BEFE,$F35E622F,$40018047,$E8000A2A
		dc.l	$494DF508,$2E300150,$49F37FF3,$4267BBB4,$9B59782B
		dc.l	$132F41F6,$6E57B1CC,$633E71B0,$C6CCD6B,$6E04524C
		dc.l	$52482008,$61CC0285,$BFBDC867,$DABA97E0,$3F015200
		dc.l	$60F43F00,$D1C049EC,$FFE04C45,$38FF48E0,$FF00B9CB
		dc.l	$62F097CC,$D7C87E00,$1C2BBD8B,$E15E1C13,$700272F3
		dc.l	$F500C420,$B2BA00EE,$41EA0094,$EE618D7,$1D429DE
		dc.l	$70FF7210,$5CABA638,$534460,$2007DD70,$443F6044
		dc.l	$804370B9,$FFE21A52,$1AD91AB8,$CBB0CD44,$53406B1A
		dc.l	$1ADB0F19,$10E77E58,$1013EFA8,$7201EF69,$5341CC81
		dc.l	$8C80E3AC,$5B12BABB,$CE659030,$1F321F1A,$C11359F5
		dc.l	$CEF86004,$2F414FEF,$15F17B1,$D37F4A9D,$3018C046
		dc.l	$9058EE47,$1228003C,$9E016C70,$7C30E2AE,$103D0C00
		dc.l	$250F1647,$C5120014,$30C3C5,$3ED48B12,$1A5705D2
		dc.l	$C65EB004,$C639751C,$DE01EEAE,$4846584B,$1C23238C
		dc.l	$BA92077E,$109E3097,$7203E188,$10185B70,$368B555B
		dc.l	$1F720561,$CA557A7C,$34003600,$3B0F75D9,$4F700F72
		dc.l	$461B612,$C0B955F6,$7001E298,$6F9874D8,$3E702D07
		dc.l	$380343,$EF000CB2,$19663A7A,$1E36D53,$4530C52A
		dc.l	$248453E,$15347E3,$55E256ED,$72FA7A10,$9A01EA6E
		dc.l	$30C6C9AE,$FF0D3C1A,$39A0411,$45A2E975,$5705EB6E
		dc.l	$53463146,$687ED46E,$B7C0E288,$52010C01,$1166AE
		dc.l	$C5C8E04C,$170010D4,$F6FB0F00
		END
