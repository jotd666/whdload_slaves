;*---------------------------------------------------------------------------
; Program:	Intro.s
; Contents:	Slave for "Superfrog Intro" (c) 1993 Team 17
; Author:	Codetapper of Action
; History:	03.05.01 - v1.0
;		         - Full load from HD
;		         - Loads and saves high scores automatically (unless you cheat!)
;		         - Load/Save high score menu options have been disabled (disk version)
;		         - Compatible with JST disk images (rename them to Disk.x)
;		         - Intro installed separately
;		         - All O/S code removed in CD³² version (no need for OSEmu!)
;		         - ATN! decruncher relocated to fast memory (x3)
;		         - Snoop bugs fixed (move.l #$ffffffff,$dff084)
;		         - Access faults in Project F fixed (x8)
;		         - Instructions included
;		         - Colour bit fixes (x2)
;		         - Trainer (press F9 to toggle infinite lives and time - this only works
;		           for registered users)
;		         - RomIcons, NewIcons and OS3.5 Colour Icons (created by me!)
;		         - Quit option (default key is 'F10')
;		08.05.04 - v1.1
;		         - Level codes can now be entered by typing 4 zeros, then the world, then
;		           the level number. eg. 000032 = World 3, level 2
;		                                 000064 = World 6, level 4
;		                                 000071 = Project F
;		         - Help key added to skip levels
;		         - Project F no-enemies bug fixed (huge thanks to Jeff!)
;		         - Added box icons (thanks to Captain^HIT!)
;		28.08.05 - v1.2
;		         - Supports the CD version released by Islona (thanks Xavier!)
;		         - CD32 version will no longer quit the entire game when you press Escape
; Requires:	WHDLoad 10+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"SuperfrogIntro.slave"
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
		dc.w	WHDLF_EmulTrap|WHDLF_NoError|WHDLF_NoKbd	;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	_DoNotCache-_base	;ws_DontCache
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

_name		dc.b	"Superfrog Intro",0
_copy		dc.b	"1993 Team 17",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version 1.2 "
		INCBIN	"T:date"
		dc.b	-1,"Thanks to Chris Vella for the disk version, and to"
		dc.b	10,"Carlo Pirri and Xavier Bodenand for the CD versions!"
		dc.b	0
_DoNotCache	dc.b	"(Disk.1|Disk.2)",0
		EVEN

;======================================================================
_Start						;a0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	lea	$8,a0
		lea	$ffffc,a1
_Clear		clr.l	(a0)+
		cmp.l	a0,a1
		bcc	_Clear

		lea	_IntroLoader(pc),a0
		lea	$10000,a1
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_Decrunch(a2)

		lea	_PL_IntroBoot(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		move.w	#$8300,$dff096		;Turn on DMA

		jmp	4(a5)

_PL_IntroBoot	PL_START
		PL_W	$2a,$200		;Colour bit fix
		PL_W	$6c,$4e71		;Trap #0
		PL_P	$d2,_IntroPart2		;Patch second part of intro
		PL_L	$1f2,$80000		;Expansion memory
		PL_L	$1f6,0			;Extra memory
		PL_P	$542,_LoaderDisk3	;Patch Rob Northen loader
		PL_P	$2e8,_DecrunchATN	;Decrunch ATN!
		PL_END

;======================================================================

_IntroPart2	movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_IntroPart2(pc),a0
		lea	$519d0,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2

		lea	$80000,a1		;Expansion memory
		sub.l	a2,a2			;Further expansion memory
		lea	$80000,sp
		jmp	$519d0

_PL_IntroPart2	PL_START
		PL_P	$2b4d0,_LoaderDisk3	;Patch Rob Northen loader
		PL_P	$2c2d6,_MainIntro	;Patch main intro
		PL_P	$2c2f4,_DecrunchATN	;Decrunch ATN!
		PL_END

;======================================================================

_MainIntro	movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_MainIntro(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2

		sub.l	a2,a2			;Stolen code
		jmp	(a1)

_PL_MainIntro	PL_START
		PL_P	$c462,_LoaderDisk3	;Patch Rob Northen loader
		PL_L	$b0c6,$3fc		;move.l #$ffffffff,$dff084
		PL_P	$c38e,_exit		;Quit when it wants disk 1
		PL_L	$c876,$70004e75		;Disk swap?
		PL_P	$cf5c,_DecrunchATN	;Decrunch ATN!
		PL_END

;======================================================================

_LoaderDisk3	movem.l	d1-d2/a0-a2,-(sp)
		moveq	#2,d0
		bra	_LoadData

;======================================================================

_Loader		movem.l	d1-d2/a0-a2,-(sp)
_LoadData	move.l  _resload(pc),a2		;a0 = dest address
		mulu	#$200,d1		;offset (sectors)
		mulu	#$200,d2		;length (sectors)
		exg.l	d1,d0			;d0 = offset (bytes)
		exg.l	d2,d1			;d1 = length (bytes)
		addq	#1,d2			;d2 = disk
		jsr	resload_DiskLoad(a2)	;a0 = destination
		movem.l	(sp)+,d1-d2/a0-a2
		moveq	#0,d0
		rts

;======================================================================

_DecrunchATN	movem.l	d2-d5/a2-a4,-(sp)
		movea.l	a0,a3
		movea.l	a1,a4
		movea.l	a1,a5
		cmpi.l	#'ATN!',(a0)+
		bne.b	_ATN_6
		adda.l	(a0)+,a4
		adda.l	(a0)+,a3
		movea.l	a3,a2
		move.l	(a2)+,-(a0)
		move.l	(a2)+,-(a0)
		move.l	(a2)+,-(a0)
		move.l	(a2)+,d2
		move.w	(a2)+,d3
		bmi.b	_ATN_1
		subq.l	#1,a3
_ATN_1		lea	(-$1C,sp),sp
		movea.l	sp,a1
		moveq	#6,d0
_ATN_2		move.l	(a2)+,(a1)+
		dbra	d0,_ATN_2
		movea.l	sp,a1
		moveq	#0,d4
_ATN_3		tst.l	d2
		beq.b	_ATN_5
_ATN_4		move.b	-(a3),-(a4)
		subq.l	#1,d2
		bne.b	_ATN_4
_ATN_5		cmpa.l	a4,a5
		bcs.b	_ATN_8
		lea	($1C,sp),sp
		moveq	#-1,d0
		cmpa.l	a3,a0
		beq.b	_ATN_7
_ATN_6		moveq	#0,d0
_ATN_7		movem.l	(sp)+,d2-d5/a2-a4
		tst.l	d0
		rts

_ATN_8		add.b	d3,d3
		bne.b	_ATN_9
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_9		bcc.b	_ATN_21
		add.b	d3,d3
		bne.b	_ATN_10
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_10		bcc.b	_ATN_20
		add.b	d3,d3
		bne.b	_ATN_11
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_11		bcc.b	_ATN_19
		add.b	d3,d3
		bne.b	_ATN_12
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_12		bcc.b	_ATN_18
		add.b	d3,d3
		bne.b	_ATN_13
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_13		bcc.b	_ATN_14
		move.b	-(a3),d4
		moveq	#3,d0
		bra.b	_ATN_22

_ATN_14		add.b	d3,d3
		bne.b	_ATN_15
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_15		addx.b	d4,d4
		add.b	d3,d3
		bne.b	_ATN_16
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_16		addx.b	d4,d4
		add.b	d3,d3
		bne.b	_ATN_17
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_17		addx.b	d4,d4
		addq.b	#6,d4
		moveq	#3,d0
		bra.b	_ATN_22

_ATN_18		moveq	#5,d4
		moveq	#3,d0
		bra.b	_ATN_22

_ATN_19		moveq	#4,d4
		moveq	#2,d0
		bra.b	_ATN_22

_ATN_20		moveq	#3,d4
		moveq	#1,d0
		bra.b	_ATN_22

_ATN_21		moveq	#2,d4
		moveq	#0,d0
_ATN_22		moveq	#0,d5
		move.w	d0,d1
		add.b	d3,d3
		bne.b	_ATN_23
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_23		bcc.b	_ATN_26
		add.b	d3,d3
		bne.b	_ATN_24
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_24		bcc.b	_ATN_25
		move.b	(_ATN_36,pc,d0.w),d5
		addq.b	#8,d0
		bra.b	_ATN_26

_ATN_25		moveq	#2,d5
		addq.b	#4,d0
_ATN_26		move.b	(_ATN_37,pc,d0.w),d0
_ATN_27		add.b	d3,d3
		bne.b	_ATN_28
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_28		addx.w	d2,d2
		subq.b	#1,d0
		bne.b	_ATN_27
		add.w	d5,d2
		moveq	#0,d5
		movea.l	d5,a2
		move.w	d1,d0
		add.b	d3,d3
		bne.b	_ATN_29
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_29		bcc.b	_ATN_32
		add.w	d1,d1
		add.b	d3,d3
		bne.b	_ATN_30
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_30		bcc.b	_ATN_31
		movea.w	(8,a1,d1.w),a2
		addq.b	#8,d0
		bra.b	_ATN_32

_ATN_31		movea.w	(a1,d1.w),a2
		addq.b	#4,d0
_ATN_32		move.b	($10,a1,d0.w),d0
_ATN_33		add.b	d3,d3
		bne.b	_ATN_34
		move.b	-(a3),d3
		addx.b	d3,d3
_ATN_34		addx.l	d5,d5
		subq.b	#1,d0
		bne.b	_ATN_33
		addq.w	#1,a2
		adda.l	d5,a2
		adda.l	a4,a2
_ATN_35		move.b	-(a2),-(a4)
		subq.b	#1,d4
		bne.b	_ATN_35
		bra.w	_ATN_3

_ATN_36		dc.b	6
		dc.b	10
		dc.b	10
		dc.b	$12
_ATN_37		dc.b	1
		dc.b	1
		dc.b	1
		dc.b	1
		dc.b	2
		dc.b	3
		dc.b	3
		dc.b	4
		dc.b	4
		dc.b	5
		dc.b	7
		dc.b	14

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_IntroLoader	dc.l	$524E4301,$C4A,$9AB,$94809A05,$12011
		dc.l	$192AB366,$37333433,$45744762,$A8CC1E03,$5ED06100
		dc.l	$20243FA,$1F022BC,$400,$33FC40F6,$2FDFF09A
		dc.l	$23FC7FFF,$94C941F9,$408B03F4,$20FC0126,$23008093
		dc.l	$2FBCFF1D,$62FE6E70,$50568042,$799C8BF1,$8081D02A
		dc.l	$5996411A,$D3A02050,$D10E4C07,$D045FA02,$4E2488ED
		dc.l	$753623CA,$804E409A,$D382C7C8,$FA02E48,$ED847422
		dc.l	$88428032,$3C001834,$355E6036,$3CF29228,$12387A06
		dc.l	$519D043,$4BA70768,$A8E83704,$9E0C8D51,$7F34DC58
		dc.l	$384207A,$12E22B0,$4C26241E,$4E6D5242,$400D89DE
		dc.l	$C8824463,$A233B189,$4C92EF08,$5CCCF401,$E491A920
		dc.l	$80E8C00,$D2314000,$6484002,$2A7B1C3D,$70C3900
		dc.l	$44B75A06,$66F623C8,$9FE160EE,$1205810,$1224F46
		dc.l	$90480142,$24262412,$484A8944,$282A2291,$50522C48
		dc.l	$242E5812,$895A3044,$22326091,$48623436,$2412686A
		dc.l	$8944383A,$22917072,$3C48243E,$7812857A,$92B425
		dc.l	$8E948100,$90C4C1B8,$B5E68894,$D00108,$AAE6F02
		dc.l	$FF0180,$4440182,$FFF00E0,$8F10E2AF,$7650F0DD
		dc.l	$BB444630,$3A4C4F41,$D52A002C,$79EB0204,$203C9094
		dc.l	$2268BE,$31754EAE,$FF3AA8CF,$2E72B910,$5347672C
		dc.l	$75B901EA,$33002F07,$53ED2E1F,$280FFF8,$5C6A4A80
		dc.l	$67D841FA,$FFA22080,$6006588F,$F1BEFE7E,$F5FE32C5
		dc.l	$E2223AFF,$66B29981,$D05A19BA,$34DD4E75,$301F221F
		dc.l	$241F2EC5,$770A2F02,$2F013F00,$4E737887,$7C87FF07
		dc.l	$A950300,$AFB233C1,$8386D95B,$F0FD562D,$3F70E8E9
		dc.l	$48E73C38,$26482849,$2A490C98,$41544E21,$663ED9D8
		dc.l	$D7D8244B,$211A6F9E,$29D9241A,$361A6B02,$538B4FEF
		dc.l	$FFE4224F,$700622DA,$51C8FFFC,$784CD782,$67061923
		dc.l	$538266FA,$BBCC6514,$F9EE001C,$70FFB1CB,$67027000
		dc.l	$4CDF1C3C,$4A3D3929,$B7D60366,$41623D7,$3646454
		dc.l	$CAAD4472,$AB34DC5B,$6182370,$3603A3F,$A3D9047C
		dc.l	$125C040F,$65167805,$A2751078,$4A6E0260,$A780370
		dc.l	$1600478,$A4B97A00,$320055EE,$16EDD108,$1A3B006A
		dc.l	$5000D272,$7A025800,$1062F23C,$F836D542,$530066F2
		dc.l	$D445FCEE,$24453001,$7A3F1AD2,$410C6F34,$71100872
		dc.l	$BA060013,$6231F68C,$DB85FB1C,$DFB6524A,$D5C5D5CC
		dc.l	$19225304,$66FAF979,$EA060A0A,$12017323,$2030304
		dc.l	$405070E,$48E7FFFE,$28492649,$20180C28,$4903F366
		dc.l	$E0ADF167,$8D080EB,$C9D1C060,$F42E182C,$7E78F9F
		dc.l	$C7504822,$4F2A4F64,$CCCD6922,$C022CBD7,$C0538666
		dc.l	$F036261A,$CE220004,$81FA2BE7,$D2814EBB,$6D9466EC
		dc.l	$C5489624,$122E2A89,$44363222,$914C5822,$48241E1A
		dc.l	$12891612,$4C766090,$B8899170,$14E7570,$4BA315
		dc.l	$2C6D75D6,$2CD85981,$538066F8,$4A816706,$429EA2C5
		dc.l	$7018A663,$76D06312,$FAA5675F,$7B18E789,$26371808
		dc.l	$72E62418,$D7B62800,$B4CEF660,$E4CF6050,$4D518625
		dc.l	$59DFC787,$CD600270,$FF4CDF7F,$FF32A77F,$FC4E56FF
		dc.l	$DE3A0002,$45FA8A3D,$45D2E33D,$41FFE03D,$42FFE23D
		dc.l	$43FFE42D,$44FFEE2D,$48FFE62D,$49FFEAE4,$58024053
		dc.l	$C04AD040,$3D40FFF2,$B5B93602,$676C701E,$D641B67C
		dc.l	$7806E0E,$528C48C1,$82FC000C,$C4E3701,$52086702
		dc.l	$D241F448,$1B2FF61C,$E564302E,$CD5C720C,$9240B26E
		dc.l	$8D746F04,$322E986C,$4DCAF861,$5E6628E2,$9054CDF8
		dc.l	$671E4555,$E25F00F8,$E18833E7,$AE4254EA,$F6C21BF2
		dc.l	$D1F460BE,$2F978E83,$3F02EE20,$1F672072,$939EF4
		dc.l	$CD4DE249,$C2D22FA0,$4BB7FC2F,$4100264E,$5E4A80A5
		dc.l	$DB3FFEE2,$CF7A02F4,$BC9B26F,$F8701D08,$39FB7400
		dc.l	$BFE00167,$282A6623,$EA204D22,$4D700BD0,$FC040A42
		dc.l	$58D2592B,$5B003813,$9AB634D,$611A2371,$906712
		dc.l	$F1267002,$BC3277E0,$F3E651CD,$FFB46064,$B28EDFF0
		dc.l	$337C26,$B224068B,$80100096,$5D419E96,$CC955022
		dc.l	$23480020,$27599C6A,$2D147E33,$FC998B3F,$F2249346
		dc.l	$C2FFE092,$D03E0009,$C4F5A67E,$82950CD,$1F660A7A
		dc.l	$976466F2,$70FFB862,$91002E79,$9CCD5E6E,$E924E12D
		dc.l	$1005FAFC,$24B3BFE6,$A121C1F4,$B667A648,$8F06D113
		dc.l	$9E7C9C7E,$E39C9ED5,$8B8E0C55,$48916689,$8A41ED1D
		dc.l	$627CC218,$2805502,$816636D0,$80808122,$2E5D9208
		dc.l	$C1B7D5B3,$80260048,$40B01657,$F5665CE0,$48FB6654
		dc.l	$66B0F76D,$2212A218,$F9D2B001,$6C1629D0,$50B75CB6
		dc.l	$40663C22,$4A617A45,$EA7AB252,$BBEDA1B,$C7301D72
		dc.l	$7407E5,$50E31151,$CA861AD2,$41DBC193,$7CFA9B64
		dc.l	$C91BFEC,$B0FF7271,$CB700872,$701B1943,$A179790B
		dc.l	$B8514484,$2B437267,$64A6DD9,$4267F413,$AF6080B8
		dc.l	$796DF7FF,$2418B580,$51C968EC,$B09D224C,$D5417499
		dc.l	$80414CDF,$10699BF,$F8E0707F,$45E84C8F,$263C282D
		dc.l	$A2DB1EBC,$62241AC2,$83C483D2,$818282B3,$8422C428
		dc.l	$1FA15EC,$71FBFF2,$3F00FEBD,$E92CDED0,$4041FB00
		dc.l	$504A506A,$2611630,$17E248E2,$D0D5AE90,$472FF44
		dc.l	$40616A30,$9F602872,$55DB8104,$DB614731,$102F0170
		dc.l	$AD16FF61,$52221F78,$C7EA21C1,$B95D0E42,$50611013
		dc.l	$C0B253D1,$5CA3F876,$4C0C3F01,$10391FB7,$7F92DDDE
		dc.l	$56010380,$570158F8,$D50B10DE,$81A25B7,$DB670408
		dc.l	$80000232,$301A4A00,$672A69CD,$61CC4A01,$6B8CC801
		dc.l	$3C4794,$7308C05E,$2C700361,$48301FBC,$AD2E56D
		dc.l	$FC04EFEC,$4A6EFFE4,$6A1EA438,$13C10C7D,$CC505680
		dc.l	$1818FF0,$1C103B7,$983FAF37,$8810007,$61D47064
		dc.l	$D080611E,$8E624BF,$DE4DDEF6,$B822A1,$DFEA1C0D
		dc.l	$B3671813,$FC50074E,$9ECCD47C,$D890CCD5,$820B73F8
		dc.l	$8F03A7F4,$FC14A4E2,$F8A45FF,$80973BF1,$834A1C0F
		dc.l	$1C06183F,$FD7747E4,$7FC0771E,$35801E1F,$1F199F00
		dc.l	$1F9F9853,$41FA0303,$78921B1B,$199B8312,$447F0019
		dc.l	$86183180,$18190D5E,$7D44C20F,$F061FB1,$801F9999
		dc.l	$8F19A047,$46253F00,$FF3EECB1,$FE5D28F2,$C3E11298
		dc.l	$E7807F13,$F6A63F01,$F017FD6,$69BF91AE,$3F0403E2
		dc.l	$3718809F,$11F02930,$1F10F9E3,$B930849A,$23F3DD88
		dc.l	$7C58C022,$F6C588FC,$240EF2DF,$88143183,$32B83008
		dc.l	$7823C201,$E3E0C908,$8709F3B0,$CC201C22,$1586503
		dc.l	$11F820B0,$1A82DF2C,$1B57F061,$8300BA14,$9F0EF800
		dc.l	$F108A0C1,$932039F,$B0811563,$5978464F,$F99BE843
		dc.l	$6F8842C,$3CC1E703,$F819E249,$740FC018,$DC82D01C
		dc.l	$58084E0E,$39BEC374,$C5431090,$F901260F,$F1C213E4
		dc.l	$59FB59C3,$A24F88DF,$E009BF58,$F9E209F4,$8F6C0F8
		dc.l	$D0430461,$F8F0D48A,$E05B597,$F1BD21C1,$A5F89209
		dc.l	$1A6181BE,$D0133298,$F0301983,$117400C3,$2505767A
		dc.l	$AD136018,$3199981,$8C80995E,$569998C1,$98F5642E
		dc.l	$61801818,$F144BCF0,$F96780C1,$A0016806,$F0A1DE65
		dc.l	$C0006319,$9047C074,$F3B26F57,$D3809283,$70F06AF9
		dc.l	$98A10D61,$32F00318,$F8C4A031,$9810F0F1,$9870F831
		dc.l	$99481330,$F15B6628,$6EEA990,$F0F88118,$9412D0C7
		dc.l	$51FFBE4E,$2BF25F46,$AE41BF0,$C7B20DF0,$49E007F
		dc.l	$C029EC82,$3824F21F,$820D896F,$40FC06E0,$BFA20113
		dc.l	$D02916E0,$40180F0,$4904243F,$45C100F2,$4B0CF7BD
		dc.l	$B61B0797,$2CE0C003,$8E8303E3,$33E36881,$74C3E3E1
		dc.l	$E3E701C1,$E0C1E3E0,$D71322F1,$E0C38345,$5D034121
		dc.l	$373007F0,$6043F4F0,$5D3BE9BE,$9406B880,$4F37F0F0
		dc.l	$27D09F24,$DB95F1E3,$F01FF183,$AA0A7A82,$B1F34BF0
		dc.l	$A227D56F,$C513E0B1,$F19F4083,$21E22BC3,$3303049
		dc.l	$30E8353,$49023097,$808103,$F8100201,$18E200C3
		dc.l	$31833306,$33F732C3,$33C29322,$F4030061,$E1F32303
		dc.l	$1E15643,$E1E0F4,$92F331F1,$6ACFE17A,$6EB0181
		dc.l	$F300E331,$E3804663,$3181E306,$31F0E061,$E330C00C
		dc.l	$80FFFA01,$FFF0B0A8,$23F00000,$9F1F0F1F,$CF1FA0AF
		dc.l	$DF21C830,$6644FFC0,$40CDBF,$168A6C0,$280D93A
		dc.l	$DB950500,$6070808,$709090A,$80A0B0C,$D6B7BF8D
		dc.l	$365B01FA,$59FE9520,$497AE23B,0
		END
