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
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"LeisureSuitLarry.slave"
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

KICKSIZE	= $40000		;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE


_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	11			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_EmulTrap	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_name		dc.b	"Leisure Suit Larry",0
_copy		dc.b	"1987 Sierra",0
_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Thanks to BTTR/Ungi/Seppo for disk images",10,10
		dc.b	"Version 1.0 "
		INCBIN	"T:date"
		dc.b	0

	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	bsr	_patch_boot

	;initialize kickstart and environment
	bra	_boot


;============================================================================
	
; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a0
	cmp.b	#3,(a0)
	bne.b	.skip

	; sierra found

	move.l	d1,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1

	bsr	_patch_prot

	bsr	_patchkb
	bsr	_patchintuition

.skip
	rts

_patch_prot
	lea	_pl_prot(pc),a0
	sub.l	#$2E0,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts

_patchkb
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
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
	PL_W	$2e0,$48e7
	PL_W	$2e2,$fffe
	PL_W	$2e4,$2c78
	PL_W	$2e6,$0004
	PL_W	$2e8,$43fa
	PL_W	$2ea,$040b
	PL_W	$2ec,$4eae
	PL_W	$2ee,$fe68
	PL_W	$2f0,$2c40
	PL_W	$2f2,$45fa
	PL_W	$2f4,$03f6
	PL_W	$2f6,$41fa
	PL_W	$2f8,$03ea
	PL_W	$2fa,$208a
	PL_W	$2fc,$4eae
	PL_W	$2fe,$ffb8
	PL_W	$300,$2c40
	PL_W	$302,$41fa
	PL_W	$304,$0278
	PL_W	$306,$43fa
	PL_W	$308,$0282
	PL_W	$30a,$45fa
	PL_W	$30c,$02c2
	PL_W	$30e,$48f8
	PL_W	$310,$0700
	PL_W	$312,$0080
	PL_W	$314,$41f9
	PL_W	$316,$00df
	PL_W	$318,$f000
	PL_W	$31a,$317c
	PL_W	$31c,$00a0
	PL_W	$31e,$0096
	PL_W	$320,$317c
	PL_W	$322,$0020
	PL_W	$324,$009a
	PL_W	$326,$317c
	PL_W	$328,$4200
	PL_W	$32a,$0100
	PL_W	$32c,$4268
	PL_W	$32e,$0102
	PL_W	$330,$42a8
	PL_W	$332,$0108
	PL_W	$334,$217c
	PL_W	$336,$0028
	PL_W	$338,$00d8
	PL_W	$33a,$0092
	PL_W	$33c,$217c
	PL_W	$33e,$1c71
	PL_W	$340,$3cd1
	PL_W	$342,$008e
	PL_W	$344,$317c
	PL_W	$346,$8300
	PL_W	$348,$0096
	PL_W	$34a,$217c
	PL_W	$34c,$0000
	PL_W	$34e,$0000
	PL_W	$350,$0144
	PL_W	$352,$43f9
	PL_W	$354,$0006
	PL_W	$356,$0000
	PL_W	$358,$303c
	PL_W	$35a,$8fff
	PL_W	$35c,$4259
	PL_W	$35e,$51c8
	PL_W	$360,$fffc
	PL_W	$362,$43fa
	PL_W	$364,$0330
	PL_W	$366,$303c
	PL_W	$368,$000f
	PL_W	$36a,$4247
	PL_W	$36c,$47fa
	PL_W	$36e,$026a
	PL_W	$370,$45f9
	PL_W	$372,$0006
	PL_W	$374,$47bc
	PL_W	$376,$1e19
	PL_W	$378,$d6c7
	PL_W	$37a,$1e19
	PL_W	$37c,$d4c7
	PL_W	$37e,$323c
	PL_W	$380,$000d
	PL_W	$382,$161b
	PL_W	$384,$4883
	PL_W	$386,$181b
	PL_W	$388,$0804
	PL_W	$38a,$0000
	PL_W	$38c,$6718
	PL_W	$38e,$1493
	PL_W	$390,$156b
	PL_W	$392,$0001
	PL_W	$394,$0001
	PL_W	$396,$45ea
	PL_W	$398,$002e
	PL_W	$39a,$5341
	PL_W	$39c,$51cb
	PL_W	$39e,$fff0
	PL_W	$3a0,$47eb
	PL_W	$3a2,$0002
	PL_W	$3a4,$600c
	PL_W	$3a6,$1483
	PL_W	$3a8,$1544
	PL_W	$3aa,$0001
	PL_W	$3ac,$45ea
	PL_W	$3ae,$002e
	PL_W	$3b0,$5341
	PL_W	$3b2,$4a41
	PL_W	$3b4,$6acc
	PL_W	$3b6,$51c8
	PL_W	$3b8,$ffb4
	PL_W	$3ba,$45f9
	PL_W	$3bc,$0006
	PL_W	$3be,$46d6
	PL_W	$3c0,$303c
	PL_W	$3c2,$0022
	PL_W	$3c4,$50ea
	PL_W	$3c6,$002e
	PL_W	$3c8,$50ea
	PL_W	$3ca,$005c
	PL_W	$3cc,$50ea
	PL_W	$3ce,$008a
	PL_W	$3d0,$50ea
	PL_W	$3d2,$0398
	PL_W	$3d4,$50ea
	PL_W	$3d6,$03c6
	PL_W	$3d8,$50ea
	PL_W	$3da,$03f4
	PL_W	$3dc,$50ea
	PL_W	$3de,$0422
	PL_W	$3e0,$50da
	PL_W	$3e2,$51c8
	PL_W	$3e4,$ffe0
	PL_W	$3e6,$43fa
	PL_W	$3e8,$031e
	PL_W	$3ea,$45f9
	PL_W	$3ec,$0006
	PL_W	$3ee,$4000
	PL_W	$3f0,$4280
	PL_W	$3f2,$1019
	PL_W	$3f4,$673c
	PL_W	$3f6,$c0fc
	PL_W	$3f8,$002e
	PL_W	$3fa,$4241
	PL_W	$3fc,$1219
	PL_W	$3fe,$d041
	PL_W	$400,$45f2
	PL_W	$402,$0000
	PL_W	$404,$266e
	PL_W	$406,$0022
	PL_W	$408,$4240
	PL_W	$40a,$1019
	PL_W	$40c,$67dc
	PL_W	$40e,$902e
	PL_W	$410,$0020
	PL_W	$412,$49f3
	PL_W	$414,$0000
	PL_W	$416,$2a4a
	PL_W	$418,$45ea
	PL_W	$41a,$0001
	PL_W	$41c,$323c
	PL_W	$41e,$0007
	PL_W	$420,$1a94
	PL_W	$422,$d8ee
	PL_W	$424,$0026
	PL_W	$426,$dbfc
	PL_W	$428,$0000
	PL_W	$42a,$002e
	PL_W	$42c,$51c9
	PL_W	$42e,$fff2
	PL_W	$430,$60d6
	PL_W	$432,$43f9
	PL_W	$434,$0006
	PL_W	$436,$8000
	PL_W	$438,$45f9
	PL_W	$43a,$0006
	PL_W	$43c,$c02e
	PL_W	$43e,$343c
	PL_W	$440,$0012
	PL_W	$442,$323c
	PL_W	$444,$0158
	PL_W	$446,$32fc
	PL_W	$448,$fffe
	PL_W	$44a,$34fc
	PL_W	$44c,$7fff
	PL_W	$44e,$51c9
	PL_W	$450,$fff6
	PL_W	$452,$43e9
	PL_W	$454,$002e
	PL_W	$456,$45ea
	PL_W	$458,$002e
	PL_W	$45a,$51ca
	PL_W	$45c,$ffe6
	PL_W	$45e,$43f9
	PL_W	$460,$0007
	PL_W	$462,$0000
	PL_W	$464,$303c
	PL_W	$466,$0f00
	PL_W	$468,$323c
	PL_W	$46a,$0010
	PL_W	$46c,$4e40
	PL_W	$46e,$323c
	PL_W	$470,$ff00
	PL_W	$472,$4e40
	PL_W	$474,$323c
	PL_W	$476,$0001
	PL_W	$478,$4e40
	PL_W	$47a,$323c
	PL_W	$47c,$fff0
	PL_W	$47e,$4e40
	PL_W	$480,$323c
	PL_W	$482,$0100
	PL_W	$484,$4e40
	PL_W	$486,$323c
	PL_W	$488,$ffff
	PL_W	$48a,$4e40
	PL_W	$48c,$4240
	PL_W	$48e,$3140
	PL_W	$490,$0190
	PL_W	$492,$4e42
	PL_W	$494,$3141
	PL_W	$496,$0198
	PL_W	$498,$807c
	PL_W	$49a,$0999
	PL_W	$49c,$3140
	PL_W	$49e,$0194
	PL_W	$4a0,$3140
	PL_W	$4a2,$0180
	PL_W	$4a4,$4e42
	PL_W	$4a6,$3141
	PL_W	$4a8,$019c
	PL_W	$4aa,$3141
	PL_W	$4ac,$0188
	PL_W	$4ae,$317c
	PL_W	$4b0,$0fff
	PL_W	$4b2,$0184
	PL_W	$4b4,$317c
	PL_W	$4b6,$0999
	PL_W	$4b8,$018c
	PL_W	$4ba,$4243
	PL_W	$4bc,$4244
	PL_W	$4be,$4245
	PL_W	$4c0,$4247
	PL_W	$4c2,$45fa
	PL_W	$4c4,$01f0
	PL_W	$4c6,$47fa
	PL_W	$4c8,$0212
	PL_W	$4ca,$3028
	PL_W	$4cc,$001e
	PL_W	$4ce,$c07c
	PL_W	$4d0,$0020
	PL_W	$4d2,$67f6
	PL_W	$4d4,$217c
	PL_W	$4d6,$0006
	PL_W	$4d8,$3ffc
	PL_W	$4da,$00e0
	PL_W	$4dc,$217c
	PL_W	$4de,$0006
	PL_W	$4e0,$0000
	PL_W	$4e2,$00e8
	PL_W	$4e4,$1039
	PL_W	$4e6,$00bf
	PL_W	$4e8,$e901
	PL_W	$4ea,$c03c
	PL_W	$4ec,$0007
	PL_W	$4ee,$d833
	PL_W	$4f0,$0000
	PL_W	$4f2,$c87c
	PL_W	$4f4,$000f
	PL_W	$4f6,$3204
	PL_W	$4f8,$c2fc
	PL_W	$4fa,$002e
	PL_W	$4fc,$d2bc
	PL_W	$4fe,$0006
	PL_W	$500,$8000
	PL_W	$502,$2141
	PL_W	$504,$00e4
	PL_W	$506,$d2bc
	PL_W	$508,$0000
	PL_W	$50a,$4000
	PL_W	$50c,$2141
	PL_W	$50e,$00ec
	PL_W	$510,$5400
	PL_W	$512,$c03c
	PL_W	$514,$0007
	PL_W	$516,$d633
	PL_W	$518,$0000
	PL_W	$51a,$c67c
	PL_W	$51c,$000f
	PL_W	$51e,$3403
	PL_W	$520,$e94a
	PL_W	$522,$3142
	PL_W	$524,$0102
	PL_W	$526,$3c07
	PL_W	$528,$303c
	PL_W	$52a,$00af
	PL_W	$52c,$5347
	PL_W	$52e,$6a04
	PL_W	$530,$de7c
	PL_W	$532,$0026
	PL_W	$534,$3c07
	PL_W	$536,$4bf9
	PL_W	$538,$0007
	PL_W	$53a,$0000
	PL_W	$53c,$3f05
	PL_W	$53e,$303c
	PL_W	$540,$0040
	PL_W	$542,$4e41
	PL_W	$544,$3a1f
	PL_W	$546,$5545
	PL_W	$548,$6a04
	PL_W	$54a,$da7c
	PL_W	$54c,$00b4
	PL_W	$54e,$317c
	PL_W	$550,$0020
	PL_W	$552,$009c
	PL_W	$554,$0839
	PL_W	$556,$0006
	PL_W	$558,$00bf
	PL_W	$55a,$e001
	PL_W	$55c,$6600
	PL_W	$55e,$ff6c
	PL_W	$560,$317c
	PL_W	$562,$8020
	PL_W	$564,$009a
	PL_W	$566,$317c
	PL_W	$568,$0100
	PL_W	$56a,$0096
	PL_W	$56c,$317c
	PL_W	$56e,$8080
	PL_W	$570,$0096
	PL_W	$572,$4cdf
	PL_W	$574,$7fff
	PL_W	$576,$6000
	PL_W	$578,$025c
	PL_W	$57a,$0000
	PL_W	$57c,$343c
	PL_W	$57e,$000e
	PL_W	$580,$32c0
	PL_W	$582,$d041
	PL_W	$584,$51ca
	PL_W	$586,$fffa
	PL_W	$588,$4e73
	PL_W	$58a,$323c
	PL_W	$58c,$009b
	PL_W	$58e,$b028
	PL_W	$590,$0006
	PL_W	$592,$6afa
	PL_W	$594,$1f32
	PL_W	$596,$6000
	PL_W	$598,$8517
	PL_W	$59a,$115f
	PL_W	$59c,$0103
	PL_W	$59e,$5346
	PL_W	$5a0,$6a04
	PL_W	$5a2,$dc7c
	PL_W	$5a4,$0026
	PL_W	$5a6,$3175
	PL_W	$5a8,$5000
	PL_W	$5aa,$0182
	PL_W	$5ac,$3175
	PL_W	$5ae,$5000
	PL_W	$5b0,$0186
	PL_W	$5b2,$3175
	PL_W	$5b4,$5000
	PL_W	$5b6,$0192
	PL_W	$5b8,$3175
	PL_W	$5ba,$5000
	PL_W	$5bc,$0196
	PL_W	$5be,$5240
	PL_W	$5c0,$5545
	PL_W	$5c2,$6a04
	PL_W	$5c4,$da7c
	PL_W	$5c6,$00b4
	PL_W	$5c8,$51c9
	PL_W	$5ca,$ffc4
	PL_W	$5cc,$4e73
	PL_W	$5ce,$3200
	PL_W	$5d0,$e249
	PL_W	$5d2,$c27c
	PL_W	$5d4,$0777
	PL_W	$5d6,$4e73
	PL_W	$5d8,$0301
	PL_W	$5da,$fffe
	PL_W	$5dc,$0901
	PL_W	$5de,$07c0
	PL_W	$5e0,$0401
	PL_W	$5e2,$f83e
	PL_W	$5e4,$0301
	PL_W	$5e6,$fffe
	PL_W	$5e8,$0401
	PL_W	$5ea,$f83e
	PL_W	$5ec,$1ffe
	PL_W	$5ee,$7ffe
	PL_W	$5f0,$fffe
	PL_W	$5f2,$fffe
	PL_W	$5f4,$f800
	PL_W	$5f6,$0301
	PL_W	$5f8,$fffe
	PL_W	$5fa,$f800
	PL_W	$5fc,$fffe
	PL_W	$5fe,$fffe
	PL_W	$600,$7ffe
	PL_W	$602,$1ffe
	PL_W	$604,$1ffe
	PL_W	$606,$7ffe
	PL_W	$608,$fffe
	PL_W	$60a,$fffe
	PL_W	$60c,$f800
	PL_W	$60e,$fff0
	PL_W	$610,$fffc
	PL_W	$612,$7ffe
	PL_W	$614,$1ffe
	PL_W	$616,$003e
	PL_W	$618,$fffe
	PL_W	$61a,$fffe
	PL_W	$61c,$fffc
	PL_W	$61e,$fff0
	PL_W	$620,$1ff0
	PL_W	$622,$7ffc
	PL_W	$624,$fffe
	PL_W	$626,$fffe
	PL_W	$628,$f83e
	PL_W	$62a,$0301
	PL_W	$62c,$fffe
	PL_W	$62e,$0401
	PL_W	$630,$f83e
	PL_W	$632,$fff0
	PL_W	$634,$fffc
	PL_W	$636,$fffe
	PL_W	$638,$fffe
	PL_W	$63a,$f83e
	PL_W	$63c,$fffe
	PL_W	$63e,$fffe
	PL_W	$640,$fffc
	PL_W	$642,$fff0
	PL_W	$644,$f9e0
	PL_W	$646,$f9f0
	PL_W	$648,$f8f8
	PL_W	$64a,$f87c
	PL_W	$64c,$f83e
	PL_W	$64e,$1ffe
	PL_W	$650,$7ffe
	PL_W	$652,$fffe
	PL_W	$654,$fffe
	PL_W	$656,$f800
	PL_W	$658,$0301
	PL_W	$65a,$fffe
	PL_W	$65c,$0401
	PL_W	$65e,$f800
	PL_W	$660,$1ff0
	PL_W	$662,$7ffc
	PL_W	$664,$7ffe
	PL_W	$666,$7ffe
	PL_W	$668,$0501
	PL_W	$66a,$f83e
	PL_W	$66c,$fffe
	PL_W	$66e,$fffe
	PL_W	$670,$7ffc
	PL_W	$672,$1ff0
	PL_W	$674,$783e
	PL_W	$676,$fc3e
	PL_W	$678,$fe3e
	PL_W	$67a,$ff3e
	PL_W	$67c,$ffbe
	PL_W	$67e,$fffe
	PL_W	$680,$fffe
	PL_W	$682,$fffe
	PL_W	$684,$fffe
	PL_W	$686,$fbfe
	PL_W	$688,$f9fe
	PL_W	$68a,$f8fe
	PL_W	$68c,$f87e
	PL_W	$68e,$f83c
	PL_W	$690,$0d01
	PL_W	$692,$fe00
	PL_W	$694,$0000
	PL_W	$696,$0802
	PL_W	$698,$1404
	PL_W	$69a,$2c08
	PL_W	$69c,$000a
	PL_W	$69e,$480c
	PL_W	$6a0,$5a0e
	PL_W	$6a2,$7612
	PL_W	$6a4,$5a14
	PL_W	$6a6,$8816
	PL_W	$6a8,$9c18
	PL_W	$6aa,$001a
	PL_W	$6ac,$b81c
	PL_W	$6ae,$141d
	PL_W	$6b0,$5a1f
	PL_W	$6b2,$2c21
	PL_W	$6b4,$0809
	PL_W	$6b6,$0a0b
	PL_W	$6b8,$0c0d
	PL_W	$6ba,$0e0e
	PL_W	$6bc,$0f0f
	PL_W	$6be,$0f0f
	PL_W	$6c0,$0e0e
	PL_W	$6c2,$0d0c
	PL_W	$6c4,$0b0a
	PL_W	$6c6,$0908
	PL_W	$6c8,$0706
	PL_W	$6ca,$0504
	PL_W	$6cc,$0302
	PL_W	$6ce,$0201
	PL_W	$6d0,$0101
	PL_W	$6d2,$0102
	PL_W	$6d4,$0203
	PL_W	$6d6,$0405
	PL_W	$6d8,$0607
	PL_W	$6da,$0001
	PL_W	$6dc,$0201
	PL_W	$6de,$00ff
	PL_W	$6e0,$feff
	PL_W	$6e2,$0000
	PL_W	$6e4,$0000
	PL_W	$6e6,$0004
	PL_W	$6e8,$0000
	PL_W	$6ea,$746f
	PL_W	$6ec,$7061
	PL_W	$6ee,$7a2e
	PL_W	$6f0,$666f
	PL_W	$6f2,$6e74
	PL_W	$6f4,$0067
	PL_W	$6f6,$7261
	PL_W	$6f8,$7068
	PL_W	$6fa,$6963
	PL_W	$6fc,$732e
	PL_W	$6fe,$6c69
	PL_W	$700,$6272
	PL_W	$702,$6172
	PL_W	$704,$7900
	PL_W	$706,$6410
	PL_W	$708,$5052
	PL_W	$70a,$4553
	PL_W	$70c,$454e
	PL_W	$70e,$5400
	PL_W	$710,$7809
	PL_W	$712,$4c45
	PL_W	$714,$4953
	PL_W	$716,$5552
	PL_W	$718,$4520
	PL_W	$71a,$5355
	PL_W	$71c,$4954
	PL_W	$71e,$204c
	PL_W	$720,$4152
	PL_W	$722,$5259
	PL_W	$724,$2049
	PL_W	$726,$4e00
	PL_W	$728,$8705
	PL_W	$72a,$5448
	PL_W	$72c,$4520
	PL_W	$72e,$4c41
	PL_W	$730,$4e44
	PL_W	$732,$204f
	PL_W	$734,$4620
	PL_W	$736,$5448
	PL_W	$738,$4520
	PL_W	$73a,$4c4f
	PL_W	$73c,$554e
	PL_W	$73e,$4745
	PL_W	$740,$204c
	PL_W	$742,$495a
	PL_W	$744,$4152
	PL_W	$746,$4453
	PL_W	$748,$00a5
	PL_W	$74a,$0043
	PL_W	$74c,$7261
	PL_W	$74e,$636b
	PL_W	$750,$6564
	PL_W	$752,$2031
	PL_W	$754,$302d
	PL_W	$756,$5365
	PL_W	$758,$702d
	PL_W	$75a,$3837
	PL_W	$75c,$2062
	PL_W	$75e,$7920
	PL_W	$760,$5468
	PL_W	$762,$6520
	PL_W	$764,$5374
	PL_W	$766,$6172
	PL_W	$768,$2046
	PL_W	$76a,$726f
	PL_W	$76c,$6e74
	PL_W	$76e,$6965
	PL_W	$770,$7273
	PL_W	$772,$00b4
	PL_W	$774,$0053
	PL_W	$776,$7065
	PL_W	$778,$6369
	PL_W	$77a,$616c
	PL_W	$77c,$2054
	PL_W	$77e,$6861
	PL_W	$780,$6e78
	PL_W	$782,$2074
	PL_W	$784,$6f20
	PL_W	$786,$526f
	PL_W	$788,$7474
	PL_W	$78a,$656e
	PL_W	$78c,$2066
	PL_W	$78e,$6f72
	PL_W	$790,$2074
	PL_W	$792,$6865
	PL_W	$794,$204f
	PL_W	$796,$7269
	PL_W	$798,$6769
	PL_W	$79a,$6e61
	PL_W	$79c,$6c00
	PL_W	$79e,$0000
	PL_W	$7a0,$0000
	PL_W	$7a2,$03f2
	PL_W	$7a4,$0000
	PL_W	$7a6,$03ea
	PL_W	$7a8,$0000
	PL_W	$7aa,$0000
	PL_W	$7ac,$0000
	PL_W	$7ae,$03f2
	PL_W	$7b2,$03eb
	PL_W	$7ba,$03f2
	PL_W	$7c0,$4cdf
	PL_W	$7c2,$7fff
	PL_W	$7c4,$6000
	PL_W	$7c6,$000e
	PL_W	$7fa,$4eae
	PL_W	$7fc,$feda
	PL_W	$7fe,$2840
	PL_W	$800,$4aac
	PL_W	$802,$00ac
	PL_W	$804,$6700
	PL_W	$806,$00a8
	PL_W	$808,$6100
	PL_W	$80a,$016c
	PL_W	$80c,$206c
	PL_W	$80e,$00ac
	PL_W	$810,$d1c8
	PL_W	$812,$d1c8
	PL_W	$814,$2068
	PL_W	$816,$0010
	PL_W	$818,$d1c8
	PL_W	$81a,$d1c8
	PL_W	$81c,$48e7
	PL_W	$81e,$2030
	PL_W	$820,$45f9
	PL_W	$82e,$7000
	PL_W	$830,$1018
	PL_W	$832,$26ca
	PL_W	$834,$6002
	PL_W	$836,$14d8
	PL_W	$838,$51c8
	PL_W	$83a,$fffc
	PL_W	$83c,$421a
	PL_W	$83e,$2039
	PL_W	$84c,$5380
	PL_W	$84e,$6f1e
	PL_W	$850,$0c01
	PL_W	$852,$0020
	PL_W	$854,$6ff4
	PL_W	$856,$5282
	PL_W	$858,$26ca
	PL_W	$85a,$600a
	PL_W	$85c,$1218
	PL_W	$85e,$5380
	PL_W	$860,$0c01
	PL_W	$862,$0020
	PL_W	$864,$6f04
	PL_W	$866,$14c1
	PL_W	$868,$60f2
	PL_W	$86a,$421a
	PL_W	$86c,$60dc
	PL_W	$86e,$421a
	PL_W	$870,$429b
	PL_W	$872,$2002
	PL_W	$874,$4cdf
	PL_W	$876,$0c04
	PL_W	$878,$4879
	PL_W	$8ae,$6100
	PL_W	$8b0,$00c6
	PL_W	$8b2,$6100
	PL_W	$8b4,$00b0
	PL_W	$8b6,$23c0
	PL_W	$8be,$2f00
	PL_W	$8c0,$2440
	PL_W	$8c2,$202a
	PL_W	$8c4,$0024
	PL_W	$8c6,$6710
	PL_W	$8c8,$2c79
	PL_W	$8d0,$2228
	PL_W	$8d2,$0000
	PL_W	$8d4,$4eae
	PL_W	$8d6,$ff82
	PL_W	$8d8,$222a
	PL_W	$8da,$0020
	PL_W	$8dc,$6728
	PL_W	$8de,$243c
	PL_W	$8e0,$0000
	PL_W	$8e2,$03ed
	PL_W	$8e4,$4eae
	PL_W	$8e6,$ffe2
	PL_W	$8e8,$23c0
	PL_W	$8fc,$e588
	PL_W	$8fe,$2040
	PL_W	$900,$2968
	PL_W	$902,$0008
	PL_W	$904,$00a4
	PL_W	$906,$4eb9
	PL_W	$90e,$6004
	PL_W	$910,$202f
	PL_W	$912,$0004
	PL_W	$914,$2e79
	PL_W	$91c,$2c79
	PL_W	$91e,$0000
	PL_W	$920,$0004
	PL_W	$922,$2039
	PL_W	$92a,$2240
	PL_W	$92c,$4eae
	PL_W	$92e,$fe62
	PL_W	$930,$4ab9
	PL_W	$944,$fe86
	PL_W	$946,$201f
	PL_W	$948,$4e75
	PL_W	$94a,$48e7
	PL_W	$94c,$0106
	PL_W	$94e,$2e3c
	PL_W	$950,$0003
	PL_W	$952,$8007
	PL_W	$954,$2c78
	PL_W	$956,$0004
	PL_W	$958,$4eae
	PL_W	$95a,$ff94
	PL_W	$95c,$4cdf
	PL_W	$95e,$6080
	PL_W	$960,$7064
	PL_W	$962,$60b0
	PL_W	$964,$41ec
	PL_W	$966,$005c
	PL_W	$968,$4eae
	PL_W	$96a,$fe80
	PL_W	$96c,$41ec
	PL_W	$96e,$005c
	PL_W	$970,$4eae
	PL_W	$972,$fe8c
	PL_W	$974,$4e75
	PL_W	$976,$42b9
	PL_W	$984,$0000
	PL_W	$986,$001e
	PL_W	$988,$4eae
	PL_W	$98a,$fdd8
	PL_W	$98c,$23c0
	PL_END



_patch_boot
	movem.l	d0-a6,-(a7)
	move.l	a0,a2		; resload
	moveq.l	#4,d0		; offset
	moveq.l	#$10,d1		; size
	moveq.l	#1,d2
	move.l	_expmem(pc),a0
	jsr	resload_DiskLoad(a2)
	move.l	_expmem(pc),a0
	cmp.l	#'Viru',$C(a0)	; byte bandit virus found
	beq.b	.reinstall
	cmp.w	#'DO',(a0)
	beq.b	.reinstall
	bra.b	.ok

.reinstall
	; original disk is not bootable: we have to fix that

	moveq.l	#0,d1		; offset
	move.l	#$400,d0	; size
	lea	.disk1name(pc),a0
	lea	.sierraboot(pc),a1
	jsr	resload_SaveFileOffset(a2)

.ok
	movem.l	(a7)+,d0-a6
	moveq.l	#0,D0
	rts

.disk1name:
	dc.b	"disk.1",0
	even
.sierraboot:
	incbin	"sierraboot.bin"


	INCLUDE	kick13.s
