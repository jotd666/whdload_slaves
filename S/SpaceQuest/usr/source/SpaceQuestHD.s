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

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"SpaceQuest.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
CBDOSLOADSEG

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s



;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_CurrentDir
	dc.b	0
slv_name		dc.b	"Space Quest",0
slv_copy		dc.b	"1986 Sierra",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Thanks to BTTR/Ungi for disk image",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
	EVEN

;============================================================================


; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a0
	cmp.b	#6,(a0)
	bne.b	.skip

	; sierra found

	move.l	d1,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1

	bsr	_patch_prot

	bsr	_patchintuition

.skip
	rts

_patch_prot
	lea	_pl_prot(pc),a0
	sub.l	#$2e0,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts

_patchintuition:
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	move.l	a6,a0
	add.w	#_LVOCloseScreen+2,a0
	pea	_quit(pc)
	move.l	(a7)+,(a0)
	
	rts

.intname:
	dc.b	"intuition.library",0
	even

_quit
		PEA	TDREASON_OK
		MOVE.L	_resload(PC),-(A7)
		add.l	#resload_Abort,(a7)
		rts


_pl_prot:
	PL_START
	PL_W	$2e2,$fb86
	PL_W	$2e4,$9e9c
	PL_W	$2e6,$9aae
	PL_W	$2e8,$8a9a
	PL_W	$2ea,$8c8b
	PL_W	$2ec,$c5ff
	PL_W	$2ee,$ffff
	PL_W	$2f0,$ffff
	PL_W	$2f2,$ffff
	PL_W	$2f4,$ffff
	PL_W	$2f6,$ffff
	PL_W	$2f8,$ffff
	PL_W	$2fa,$ffff
	PL_W	$2fc,$ffff
	PL_W	$2fe,$ffff
	PL_W	$300,$6000
	PL_W	$302,$04ce
	PL_W	$312,$b159
	PL_W	$316,$047c
	PL_W	$318,$2be4
	PL_W	$31a,$57e0
	PL_W	$31c,$4d1b
	PL_W	$31e,$6555
	PL_W	$320,$e6ac
	PL_W	$322,$3dda
	PL_W	$324,$c4da
	PL_W	$338,$b667
	PL_W	$33a,$be12
	PL_W	$33c,$41a6
	PL_W	$33e,$b172
	PL_W	$340,$bd76
	PL_W	$342,$2b4c
	PL_W	$344,$323a
	PL_W	$346,$43c6
	PL_W	$348,$3132
	PL_W	$34a,$fff7
	PL_W	$34c,$aeeb
	PL_W	$34e,$f7fa
	PL_W	$350,$4be5
	PL_W	$352,$6290
	PL_W	$354,$2d7e
	PL_W	$356,$2b44
	PL_W	$358,$93c3
	PL_W	$35a,$66ee
	PL_W	$35c,$dab6
	PL_W	$35e,$2b50
	PL_W	$360,$70fd
	PL_W	$362,$0d00
	PL_W	$364,$4aa8
	PL_W	$366,$4356
	PL_W	$368,$6756
	PL_W	$36a,$31ec
	PL_W	$36c,$4ef2
	PL_W	$36e,$b376
	PL_W	$370,$d2c0
	PL_W	$372,$0016
	PL_W	$374,$ff32
	PL_W	$376,$6ca6
	PL_W	$378,$dab0
	PL_W	$37a,$d4bf
	PL_W	$37c,$fff8
	PL_W	$37e,$0f54
	PL_W	$380,$fe86
	PL_W	$382,$60ae
	PL_W	$384,$98ce
	PL_W	$386,$2a07
	PL_W	$388,$2415
	PL_W	$38a,$28ae
	PL_W	$38c,$fe88
	PL_W	$38e,$0947
	PL_W	$390,$4ea4
	PL_W	$392,$d7e6
	PL_W	$394,$0622
	PL_W	$396,$2c68
	PL_W	$398,$70fb
	PL_W	$39a,$6bee
	PL_W	$39c,$fe66
	PL_W	$39e,$63d0
	PL_W	$3a0,$0146
	PL_W	$3a2,$5b40
	PL_W	$3a4,$4ebc
	PL_W	$3a6,$d2d8
	PL_W	$3a8,$5cbf
	PL_W	$3aa,$0f54
	PL_W	$3ac,$01d8
	PL_W	$3ae,$3948
	PL_W	$3b0,$241e
	PL_W	$3b2,$d993
	PL_W	$3b4,$ffd6
	PL_W	$3b6,$69c3
	PL_W	$3b8,$ffae
	PL_W	$3ba,$2e10
	PL_W	$3bc,$70ac
	PL_W	$3be,$2208
	PL_W	$3c0,$0666
	PL_W	$3c2,$4eb6
	PL_W	$3c4,$dcc5
	PL_W	$3c6,$2209
	PL_W	$3c8,$7dd2
	PL_W	$3ca,$ff96
	PL_W	$3cc,$225c
	PL_W	$3ce,$0714
	PL_W	$3d0,$0034
	PL_W	$3d2,$4eb4
	PL_W	$3d4,$bf98
	PL_W	$3d6,$20ca
	PL_W	$3d8,$201b
	PL_W	$3da,$5940
	PL_W	$3dc,$4ebc
	PL_W	$3de,$d144
	PL_W	$3e0,$50d2
	PL_W	$3e2,$4ebc
	PL_W	$3e4,$dab6
	PL_W	$3e6,$58ba
	PL_W	$3e8,$00fd
	PL_W	$3ea,$68c2
	PL_W	$3ec,$fe26
	PL_W	$3ee,$0c2d
	PL_W	$3f0,$0014
	PL_W	$3f2,$2c50
	PL_W	$3f4,$312c
	PL_W	$3f6,$002f
	PL_W	$3f8,$3510
	PL_W	$3fa,$001d
	PL_W	$3fc,$2343
	PL_W	$3fe,$2762
	PL_W	$400,$3354
	PL_W	$402,$003e
	PL_W	$404,$376e
	PL_W	$406,$2b3a
	PL_W	$408,$0022
	PL_W	$40a,$45e0
	PL_W	$40c,$42e6
	PL_W	$40e,$27ad
	PL_W	$410,$203d
	PL_W	$412,$554a
	PL_W	$414,$4e88
	PL_W	$416,$d23c
	PL_W	$418,$2029
	PL_W	$41a,$41e8
	PL_W	$41c,$dac4
	PL_W	$41e,$33fa
	PL_W	$420,$36e3
	PL_W	$422,$5e8f
	PL_W	$424,$c632
	PL_W	$426,$2bbb
	PL_W	$428,$6104
	PL_W	$42a,$187c
	PL_W	$42c,$2737
	PL_W	$42e,$3238
	PL_W	$430,$c53c
	PL_W	$432,$b355
	PL_W	$434,$51c2
	PL_W	$436,$d894
	PL_W	$438,$6028
	PL_W	$43a,$0092
	PL_W	$43c,$6438
	PL_W	$43e,$324e
	PL_W	$440,$7a1d
	PL_W	$442,$31fa
	PL_W	$444,$e055
	PL_W	$446,$c51f
	PL_W	$448,$b562
	PL_W	$44a,$c402
	PL_W	$44c,$6424
	PL_W	$44e,$9b38
	PL_W	$450,$51c9
	PL_W	$452,$be0a
	PL_W	$454,$af08
	PL_W	$456,$8fe8
	PL_W	$458,$7849
	PL_W	$45a,$5a8c
	PL_W	$45c,$383a
	PL_W	$45e,$67f7
	PL_W	$460,$2fbc
	PL_W	$462,$cb40
	PL_W	$464,$2336
	PL_W	$466,$321e
	PL_W	$468,$9cee
	PL_W	$46a,$4dd6
	PL_W	$46c,$1d15
	PL_W	$46e,$8007
	PL_W	$470,$2e75
	PL_W	$472,$009c
	PL_W	$474,$5344
	PL_W	$476,$3218
	PL_W	$478,$7a0f
	PL_W	$47a,$7400
	PL_W	$47c,$e349
	PL_W	$47e,$e252
	PL_W	$480,$b545
	PL_W	$482,$e349
	PL_W	$484,$6403
	PL_W	$486,$b740
	PL_W	$488,$51e9
	PL_W	$48a,$fff1
	PL_W	$48c,$51cd
	PL_W	$48e,$ffe8
	PL_W	$490,$4e4d
	PL_W	$492,$4aac
	PL_W	$494,$0007
	PL_W	$496,$670c
	PL_W	$498,$4ef8
	PL_W	$49a,$ff7d
	PL_W	$49c,$226c
	PL_W	$49e,$0006
	PL_W	$4a0,$4e8c
	PL_W	$4a2,$fe87
	PL_W	$4a4,$4cdd
	PL_W	$4a6,$7fff
	PL_W	$4a8,$78e5
	PL_W	$4b8,$6166
	PL_W	$4ba,$6b65
	PL_W	$4bc,$6972
	PL_W	$4c0,$6441
	PL_W	$4c2,$7668
	PL_W	$4c4,$6364
	PL_W	$4c8,$694b
	PL_W	$4ca,$6b2f
	PL_W	$4cc,$7264
	PL_W	$4d0,$7524
	PL_W	$4d2,$6364
	PL_W	$4d4,$0001
	PL_W	$4d8,$f3b7
	PL_W	$4da,$ee94
	PL_W	$4dc,$7352
	PL_W	$4de,$7258
	PL_W	$4e0,$45fc
	PL_W	$4e2,$57e5
	PL_W	$4e4,$48b4
	PL_W	$4e6,$77fc
	PL_W	$4e8,$12e7
	PL_W	$4ea,$122a
	PL_W	$4ec,$4a66
	PL_W	$4ee,$24e8
	PL_W	$4f0,$1231
	PL_W	$4f2,$6342
	PL_W	$4f4,$441c
	PL_W	$4f6,$791e
	PL_W	$4f8,$55ff
	PL_W	$4fa,$47ba
	PL_W	$4fc,$50c4
	PL_W	$4fe,$27d2
	PL_W	$500,$4c91
	PL_W	$502,$7c99
	PL_W	$504,$65f2
	PL_W	$506,$637a
	PL_W	$508,$7058
	PL_W	$50a,$44b1
	PL_W	$50c,$5b99
	PL_W	$50e,$7054
	PL_W	$510,$58c3
	PL_W	$512,$7b01
	PL_W	$514,$e0c4
	PL_W	$516,$23ce
	PL_W	$518,$fdbb
	PL_W	$51a,$1f7f
	PL_W	$51c,$0a41
	PL_W	$51e,$29a5
	PL_W	$520,$516d
	PL_W	$522,$0418
	PL_W	$524,$5f42
	PL_W	$526,$4146
	PL_W	$528,$6ae3
	PL_W	$52a,$3631
	PL_W	$52c,$1ea9
	PL_W	$52e,$2610
	PL_W	$530,$6e80
	PL_W	$532,$ae7f
	PL_W	$534,$68a3
	PL_W	$536,$1db0
	PL_W	$538,$3344
	PL_W	$53a,$6729
	PL_W	$53c,$2465
	PL_W	$53e,$223d
	PL_W	$540,$5a38
	PL_W	$542,$b91a
	PL_W	$544,$0139
	PL_W	$546,$37b0
	PL_W	$548,$b40c
	PL_W	$54a,$fe1a
	PL_W	$54c,$b67b
	PL_W	$54e,$433a
	PL_W	$550,$4d84
	PL_W	$552,$8d98
	PL_W	$554,$6489
	PL_W	$556,$d043
	PL_W	$558,$1310
	PL_W	$55a,$a750
	PL_W	$55c,$ca2e
	PL_W	$55e,$3092
	PL_W	$560,$5ea1
	PL_W	$562,$2d1d
	PL_W	$564,$1288
	PL_W	$566,$f320
	PL_W	$568,$cc28
	PL_W	$56a,$a1fe
	PL_W	$56c,$650a
	PL_W	$56e,$3873
	PL_W	$570,$3304
	PL_W	$572,$6196
	PL_W	$574,$f0a1
	PL_W	$576,$e340
	PL_W	$578,$5a82
	PL_W	$57a,$cf85
	PL_W	$57c,$b8f7
	PL_W	$57e,$0860
	PL_W	$580,$532a
	PL_W	$582,$19fb
	PL_W	$584,$2bc6
	PL_W	$586,$2dc5
	PL_W	$588,$9601
	PL_W	$58a,$431e
	PL_W	$58c,$67ba
	PL_W	$58e,$b761
	PL_W	$590,$13e2
	PL_W	$592,$f15c
	PL_W	$594,$6318
	PL_W	$596,$b042
	PL_W	$598,$7674
	PL_W	$59a,$27f4
	PL_W	$59c,$0386
	PL_W	$59e,$c699
	PL_W	$5a0,$c551
	PL_W	$5a2,$1c42
	PL_W	$5a4,$9dd6
	PL_W	$5a6,$f3e9
	PL_W	$5a8,$0989
	PL_W	$5aa,$40db
	PL_W	$5ac,$5287
	PL_W	$5ae,$73bc
	PL_W	$5b0,$4160
	PL_W	$5b2,$73b3
	PL_W	$5b4,$a6a7
	PL_W	$5b6,$433c
	PL_W	$5b8,$3f68
	PL_W	$5ba,$22ac
	PL_W	$5bc,$5b7b
	PL_W	$5be,$dd1a
	PL_W	$5c0,$67ba
	PL_W	$5c2,$b761
	PL_W	$5c4,$13e4
	PL_W	$5c6,$7440
	PL_W	$5c8,$241a
	PL_W	$5ca,$70fc
	PL_W	$5cc,$f8c7
	PL_W	$5ce,$af1b
	PL_W	$5d0,$02a2
	PL_W	$5d2,$00de
	PL_W	$5d4,$7dd2
	PL_W	$5d6,$9e33
	PL_W	$5d8,$6b67
	PL_W	$5da,$1c18
	PL_W	$5dc,$920c
	PL_W	$5de,$94ca
	PL_W	$5e0,$6e0b
	PL_W	$5e2,$3156
	PL_W	$5e4,$a268
	PL_W	$5e6,$e42d
	PL_W	$5e8,$577c
	PL_W	$5ea,$1140
	PL_W	$5ec,$95ea
	PL_W	$5ee,$602c
	PL_W	$5f0,$4486
	PL_W	$5f2,$2544
	PL_W	$5f4,$e547
	PL_W	$5f6,$99a6
	PL_W	$5f8,$673c
	PL_W	$5fa,$4886
	PL_W	$5fc,$5699
	PL_W	$5fe,$a81e
	PL_W	$600,$5dfc
	PL_W	$602,$cb58
	PL_W	$604,$eb05
	PL_W	$606,$7a4b
	PL_W	$608,$811a
	PL_W	$60a,$a774
	PL_W	$60c,$a88e
	PL_W	$60e,$2802
	PL_W	$610,$7f3c
	PL_W	$612,$1d74
	PL_W	$614,$445e
	PL_W	$616,$2abb
	PL_W	$618,$1b7c
	PL_W	$61a,$5194
	PL_W	$61c,$f944
	PL_W	$61e,$d3de
	PL_W	$620,$842f
	PL_W	$622,$7760
	PL_W	$624,$e585
	PL_W	$626,$15af
	PL_W	$628,$df5d
	PL_W	$62a,$fb4a
	PL_W	$62c,$8081
	PL_W	$62e,$8840
	PL_W	$630,$a244
	PL_W	$632,$ee0c
	PL_W	$634,$9100
	PL_W	$636,$fbac
	PL_W	$638,$0b1e
	PL_W	$63a,$35c0
	PL_W	$63c,$a8ea
	PL_W	$63e,$f3f4
	PL_W	$640,$e52d
	PL_W	$642,$8add
	PL_W	$644,$bc21
	PL_W	$646,$c551
	PL_W	$648,$cd58
	PL_W	$64a,$0eeb
	PL_W	$64c,$447e
	PL_W	$64e,$a3b8
	PL_W	$650,$9809
	PL_W	$652,$6384
	PL_W	$654,$ee65
	PL_W	$656,$d7fa
	PL_W	$658,$775a
	PL_W	$65a,$72c3
	PL_W	$65c,$1131
	PL_W	$65e,$70b5
	PL_W	$660,$9f77
	PL_W	$662,$ae67
	PL_W	$664,$09dc
	PL_W	$666,$a171
	PL_W	$668,$35ae
	PL_W	$66a,$c10c
	PL_W	$66c,$473b
	PL_W	$66e,$db1c
	PL_W	$670,$08b7
	PL_W	$672,$f9e7
	PL_W	$674,$2d8f
	PL_W	$676,$2145
	PL_W	$678,$2225
	PL_W	$67a,$6c4d
	PL_W	$67c,$d89a
	PL_W	$67e,$ee52
	PL_W	$680,$fe34
	PL_W	$682,$3ee7
	PL_W	$684,$433e
	PL_W	$686,$dfd5
	PL_W	$688,$f54d
	PL_W	$68a,$0d97
	PL_W	$68c,$bae1
	PL_W	$68e,$5d22
	PL_W	$690,$c11a
	PL_W	$692,$6903
	PL_W	$694,$bb5c
	PL_W	$696,$4586
	PL_W	$698,$08fa
	PL_W	$69a,$bfee
	PL_W	$69c,$49f8
	PL_W	$69e,$23c2
	PL_W	$6a0,$b148
	PL_W	$6a2,$6339
	PL_W	$6a4,$9573
	PL_W	$6a6,$b878
	PL_W	$6a8,$2aa3
	PL_W	$6aa,$1f45
	PL_W	$6ac,$9a67
	PL_W	$6ae,$674f
	PL_W	$6b0,$3c20
	PL_W	$6b2,$bc17
	PL_W	$6b4,$6296
	PL_W	$6b6,$9969
	PL_W	$6b8,$d6c2
	PL_W	$6ba,$18da
	PL_W	$6bc,$bb16
	PL_W	$6be,$c23a
	PL_W	$6c0,$7d9c
	PL_W	$6c2,$16d4
	PL_W	$6c4,$efd4
	PL_W	$6c6,$5605
	PL_W	$6c8,$6834
	PL_W	$6ca,$2eaf
	PL_W	$6cc,$d70e
	PL_W	$6ce,$f9dd
	PL_W	$6d0,$8ef1
	PL_W	$6d2,$d6d8
	PL_W	$6d4,$396d
	PL_W	$6d6,$00a7
	PL_W	$6d8,$74c3
	PL_W	$6da,$b63a
	PL_W	$6dc,$334b
	PL_W	$6de,$ae2c
	PL_W	$6e0,$b83f
	PL_W	$6e2,$b803
	PL_W	$6e4,$7886
	PL_W	$6e6,$2324
	PL_W	$6e8,$9aa2
	PL_W	$6ea,$1d48
	PL_W	$6ec,$3067
	PL_W	$6ee,$3455
	PL_W	$6f0,$86bc
	PL_W	$6f2,$db3a
	PL_W	$6f4,$1cb2
	PL_W	$6f6,$2b2a
	PL_W	$6f8,$787c
	PL_W	$6fa,$7dce
	PL_W	$6fc,$7378
	PL_W	$6fe,$6cef
	PL_W	$700,$5846
	PL_W	$702,$536f
	PL_W	$704,$0d38
	PL_W	$706,$fb08
	PL_W	$708,$c4a4
	PL_W	$70a,$5800
	PL_W	$70c,$7b0c
	PL_W	$70e,$449e
	PL_W	$710,$1633
	PL_W	$712,$d51f
	PL_W	$714,$336e
	PL_W	$716,$8d2b
	PL_W	$718,$fd2a
	PL_W	$71a,$ae9f
	PL_W	$71c,$2f2e
	PL_W	$71e,$cd63
	PL_W	$720,$f2f4
	PL_W	$722,$8fa8
	PL_W	$724,$cb0b
	PL_W	$726,$17b7
	PL_W	$728,$705f
	PL_W	$72a,$d380
	PL_W	$72c,$84d8
	PL_W	$72e,$fa54
	PL_W	$730,$72ea
	PL_W	$732,$2512
	PL_W	$734,$02c9
	PL_W	$736,$068a
	PL_W	$738,$7027
	PL_W	$73a,$a08c
	PL_W	$73c,$73f9
	PL_W	$73e,$0122
	PL_W	$740,$6a63
	PL_W	$742,$8fb8
	PL_W	$744,$30ac
	PL_W	$746,$16fc
	PL_W	$748,$7030
	PL_W	$74a,$b0dc
	PL_W	$74c,$6f42
	PL_W	$74e,$acc3
	PL_W	$750,$6e08
	PL_W	$752,$0351
	PL_W	$754,$e8f0
	PL_W	$756,$4f2c
	PL_W	$758,$1ba1
	PL_W	$75a,$0b49
	PL_W	$75c,$5909
	PL_W	$75e,$15bd
	PL_W	$760,$6572
	PL_W	$762,$5c24
	PL_W	$764,$cf60
	PL_W	$766,$7118
	PL_W	$768,$ebe4
	PL_W	$76a,$5ffc
	PL_W	$76c,$55f3
	PL_W	$76e,$738f
	PL_W	$770,$cd1a
	PL_W	$772,$d0d9
	PL_W	$774,$9d90
	PL_W	$776,$10a7
	PL_W	$778,$1cbf
	PL_W	$77a,$bd4d
	PL_W	$77c,$17d8
	PL_W	$77e,$bf42
	PL_W	$780,$421a
	PL_W	$782,$c0a5
	PL_W	$784,$0b97
	PL_W	$786,$9ba5
	PL_W	$788,$c65a
	PL_W	$78a,$0108
	PL_W	$78c,$5706
	PL_W	$78e,$a11a
	PL_W	$790,$23f9
	PL_W	$93a,$0001
	PL_W	$93c,$0000
	PL_W	$93e,$0020
	; some stuff missing

	PL_W	$940,$fe86
	PL_W	$942,$201f
	PL_W	$944,$4e75
	PL_W	$946,$48e7
	PL_W	$948,$0106
	PL_W	$94a,$2e3c
	PL_W	$94c,$0003
	PL_W	$94e,$8007
	PL_W	$950,$2c78
	PL_W	$952,$0004
	PL_W	$954,$4eae
	PL_W	$956,$ff94
	PL_W	$958,$4cdf
	PL_W	$95a,$6080
	PL_W	$95c,$7064
	PL_W	$95e,$60b0
	PL_W	$960,$41ec
	PL_W	$962,$005c
	PL_W	$964,$4eae
	PL_W	$966,$fe80
	PL_W	$968,$41ec
	PL_W	$96a,$005c
	PL_W	$96c,$4eae
	PL_W	$96e,$fe8c
	PL_W	$970,$4e75
	PL_W	$972,$42b9
	PL_W	$980,$0000
	PL_W	$982,$001e
	PL_W	$984,$4eae
	PL_W	$986,$fdd8
	PL_W	$988,$23c0

	PL_END

;============================================================================


;============================================================================

	END

