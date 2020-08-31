;*---------------------------------------------------------------------------
;  :Program.	BlackCauldronHD.asm
;  :Contents.	Slave for "BlackCauldron"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BlackCauldronHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;DEBUG
	IFD BARFLY
	OUTPUT	"BlackCauldron.slave"
	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

slv_name		dc.b	"The Black Cauldron"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1987 Sierra",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"BC",0

program:
	dc.b	"Black Cauldron",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l	a5,a5
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)


patch_main
	movem.l	d0-d1/a0-a2,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#91440,D0
	beq.b	sps_2057

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

sps_2057
	moveq	#0,d2
	bsr	get_section
	move.l	A1,A0
	sub.l	#$2E0,a0	; dirty, but matches the offsets, and no need to rework stuff below!!

	move.l	#$600004f2,$2e0(a0)
	move.l	#$3a004265,$2e4(a0)
	move.l	#$6e204865,$2e8(a0)
	move.l	#$726e646f,$2ec(a0)
	move.l	#$6e20484c,$2f0(a0)
	move.l	#$53204475,$2f4(a0)
	move.l	#$706c6963,$2f8(a0)
	move.l	#$6174696f,$2fc(a0)
	move.l	#$6e2048e7,$300(a0)
	move.l	#$fffe4e71,$304(a0)
	move.l	#$4e714e71,$308(a0)
	move.l	#$4e714e71,$30c(a0)
	move.l	#$4e714e71,$310(a0)
	move.l	#$4e714e71,$314(a0)
	move.l	#$4e714bfa,$318(a0)
	move.l	#$4942c78,$31c(a0)
	move.l	#$493c9,$320(a0)
	move.l	#$4eaefeda,$324(a0)
	move.l	#$2b400002,$328(a0)
	move.l	#$28404aac,$32c(a0)
	move.l	#$ac6614,$330(a0)
	move.l	#$41ec005c,$334(a0)
	move.l	#$4eaefe80,$338(a0)
	move.l	#$41ec005c,$33c(a0)
	move.l	#$4eaefe8c,$340(a0)
	move.l	#$2b400006,$344(a0)
	move.l	#$41fa012a,$348(a0)
	move.l	#$4eaeff22,$34c(a0)
	move.l	#$800001f,$350(a0)
	move.l	#$66000106,$354(a0)
	move.l	#$2b40000a,$358(a0)
	move.l	#$2840246c,$35c(a0)
	move.l	#$1070ff,$360(a0)
	move.l	#$25400004,$364(a0)
	move.l	#$43fa0142,$368(a0)
	move.l	#$70004eae,$36c(a0)
	move.l	#$fdd82c40,$370(a0)
	move.l	#$41faff6c,$374(a0)
	move.l	#$2208243c,$378(a0)
	move.l	#$fffffffe,$37c(a0)
	move.l	#$4eaeffac,$380(a0)
	move.l	#$2e0067ec,$384(a0)
	move.l	#$2207240a,$388(a0)
	move.l	#$4eaeff8e,$38c(a0)
	move.l	#$22074eae,$390(a0)
	move.l	#$ffa6224e,$394(a0)
	move.l	#$2c780004,$398(a0)
	move.l	#$4eaefe62,$39c(a0)
	move.l	#$202a0004,$3a0(a0)
	move.l	#$2b400012,$3a4(a0)
	move.l	#$2f0070ff,$3a8(a0)
	move.l	#$4eaefeb6,$3ac(a0)
	move.l	#$1b400022,$3b0(a0)
	move.l	#$266c0028,$3b4(a0)
	move.l	#$276d0002,$3b8(a0)
	move.l	#$101740,$3bc(a0)
	move.l	#$f226c,$3c0(a0)
	move.l	#$18234b,$3c4(a0)
	move.l	#$e337c,$3c8(a0)
	move.l	#$300012,$3cc(a0)
	move.l	#$2b6c0030,$3d0(a0)
	move.l	#$1a41fa,$3d4(a0)
	move.l	#$e0201f,$3d8(a0)
	move.l	#$72004eae,$3dc(a0)
	move.l	#$fe44202d,$3e0(a0)
	move.l	#$122400,$3e4(a0)
	move.l	#$43fa00df,$3e8(a0)
	move.l	#$4eaefe0e,$3ec(a0)
	move.l	#$2b400016,$3f0(a0)
	move.l	#$2c40266c,$3f4(a0)
	move.l	#$20177c,$3f8(a0)
	move.l	#$50008,$3fc(a0)
	move.l	#$276c0028,$400(a0)
	move.l	#$e377c,$404(a0)
	move.l	#$560012,$408(a0)
	move.l	#$45fa0320,$40c(a0)
	move.l	#$274d0022,$410(a0)
	move.l	#$274a0026,$414(a0)
	move.l	#$2c780004,$418(a0)
	move.l	#$41fafec2,$41c(a0)
	move.l	#$7000363c,$420(a0)
	move.l	#$1021383c,$424(a0)
	move.l	#$fc6112,$428(a0)
	move.l	#$343c015d,$42c(a0)
	move.l	#$32184e71,$430(a0)
	move.l	#$4e7151ca,$434(a0)
	move.l	#$fff86000,$438(a0)
	move.l	#$9c5344,$43c(a0)
	move.l	#$32184e71,$440(a0)
	move.l	#$4e714e71,$444(a0)
	move.l	#$4e714e71,$448(a0)
	move.l	#$303cf392,$44c(a0)
	move.l	#$4e714e71,$450(a0)
	move.l	#$4e7151cc,$454(a0)
	move.l	#$ffe84e75,$458(a0)
	move.l	#$4aad0006,$45c(a0)
	move.l	#$670c4eae,$460(a0)
	move.l	#$ff7c226d,$464(a0)
	move.l	#$64eae,$468(a0)
	move.l	#$fe864cdf,$46c(a0)
	move.l	#$7fff4e75,$470(a0)
	move.l	#$0,$474(a0)
	move.l	#$0,$478(a0)
	move.l	#$0,$47c(a0)
	move.l	#$5,$480(a0)
	move.l	#$10001,$484(a0)
	move.l	#$24,$488(a0)
	move.l	#$10001,$48c(a0)
	move.l	#$38,$490(a0)
	move.l	#$10001,$494(a0)
	move.l	#$56,$498(a0)
	move.l	#$10001,$49c(a0)
	move.l	#$22,$4a0(a0)
	move.l	#$10002,$4a4(a0)
	move.l	#$3690,$4a8(a0)
	move.l	#$646f732e,$4ac(a0)
	move.l	#$6b646973,$4bc(a0)
	move.l	#$6b2e6465,$4c0(a0)
	move.l	#$76696365,$4c4(a0)
	move.l	#$646973,$4c8(a0)
	move.l	#$6b2e7265,$4cc(a0)
	move.l	#$736f7572,$4d0(a0)
	move.l	#$63650000,$4d4(a0)
	move.l	#$7c007e01,$4d8(a0)
	move.l	#$610001c8,$4dc(a0)
	move.l	#$610001fc,$4e0(a0)
	move.l	#$20060a00,$4e4(a0)
	move.l	#$16100,$4e8(a0)
	move.l	#$1d02006,$4ec(a0)
	move.l	#$610001ca,$4f0(a0)
	move.l	#$1b7c007f,$4f4(a0)
	move.l	#$23202d,$4f8(a0)
	move.l	#$122207,$4fc(a0)
	move.l	#$142d0023,$500(a0)
	move.l	#$6000003,$504(a0)
	move.l	#$182163c,$508(a0)
	move.l	#$44a01,$50c(a0)
	move.l	#$57c1c203,$510(a0)
	move.l	#$4603c403,$514(a0)
	move.l	#$84011b42,$518(a0)
	move.l	#$23206c,$51c(a0)
	move.l	#$30303c,$520(a0)
	move.l	#$36902400,$524(a0)
	move.l	#$24482c6d,$528(a0)
	move.l	#$16226c,$52c(a0)
	move.l	#$204eae,$530(a0)
	move.l	#$ffee4a80,$534(a0)
	move.l	#$66126100,$538(a0)
	move.l	#$20e206c,$53c(a0)
	move.l	#$284eae,$540(a0)
	move.l	#$fe8c4a80,$544(a0)
	move.l	#$67f066de,$548(a0)
	move.l	#$13fc007f,$54c(a0)
	move.l	#$bfd100,$550(a0)
	move.l	#$43f900df,$554(a0)
	move.l	#$f000337c,$558(a0)
	move.l	#$9500009e,$55c(a0)
	move.l	#$337c0200,$560(a0)
	move.l	#$9e337c,$564(a0)
	move.l	#$82100096,$568(a0)
	move.l	#$2c780004,$56c(a0)
	move.l	#$13ed0023,$570(a0)
	move.l	#$bfd100,$574(a0)
	move.l	#$33fc4000,$578(a0)
	move.l	#$dff024,$57c(a0)
	move.l	#$323c0fa0,$580(a0)
	move.l	#$53416afc,$584(a0)
	move.l	#$43f900df,$588(a0)
	move.l	#$f000337c,$58c(a0)
	move.l	#$1002009c,$590(a0)
	move.l	#$337c8002,$594(a0)
	move.l	#$9a234a,$598(a0)
	move.l	#$20337c,$59c(a0)
	move.l	#$4489007e,$5a0(a0)
	move.l	#$3002e248,$5a4(a0)
	move.l	#$2403fff,$5a8(a0)
	move.l	#$408000,$5ac(a0)
	move.l	#$33400024,$5b0(a0)
	move.l	#$33400024,$5b4(a0)
	move.l	#$61000190,$5b8(a0)
	move.l	#$43f900df,$5bc(a0)
	move.l	#$f000337c,$5c0(a0)
	move.l	#$1002009a,$5c4(a0)
	move.l	#$337c4000,$5c8(a0)
	move.l	#$242c6d,$5cc(a0)
	move.l	#$16226c,$5d0(a0)
	move.l	#$204eae,$5d4(a0)
	move.l	#$ffe82c78,$5d8(a0)
	move.l	#$4204a,$5dc(a0)
	move.l	#$5488243c,$5e0(a0)
	move.l	#$55555555,$5e4(a0)
	move.l	#$20102228,$5e8(a0)
	move.l	#$4c082,$5ec(a0)
	move.l	#$c282e388,$5f0(a0)
	move.l	#$80812200,$5f4(a0)
	move.l	#$48410c01,$5f8(a0)
	move.l	#$16600,$5fc(a0)
	move.l	#$fed84880,$600(a0)
	move.l	#$c0fc0440,$604(a0)
	move.l	#$5188d1c0,$608(a0)
	move.l	#$70007600,$60c(a0)
	move.l	#$303c03e8,$610(a0)
	move.l	#$36003218,$614(a0)
	move.l	#$c414489,$618(a0)
	move.l	#$670cb258,$61c(a0)
	move.l	#$56cbfffc,$620(a0)
	move.l	#$55485243,$624(a0)
	move.l	#$66ec9043,$628(a0)
	move.l	#$2f007000,$62c(a0)
	move.l	#$72017400,$630(a0)
	move.l	#$76016100,$634(a0)
	move.l	#$7841fa,$638(a0)
	move.l	#$fca4303c,$63c(a0)
	move.l	#$f9234a9f,$640(a0)
	move.l	#$323c03d8,$644(a0)
	move.l	#$4e714e71,$648(a0)
	move.l	#$4e710241,$64c(a0)
	move.l	#$ff80d041,$650(a0)
	move.l	#$4441b340,$654(a0)
	move.l	#$e049b300,$658(a0)
	move.l	#$246d001a,$65c(a0)
	move.l	#$34007000,$660(a0)
	move.l	#$301a361a,$664(a0)
	move.l	#$671e41fa,$668(a0)
	move.l	#$168d1c0,$66c(a0)
	move.l	#$d1c043fa,$670(a0)
	move.l	#$fc6c5543,$674(a0)
	move.l	#$30181219,$678(a0)
	move.l	#$b540b300,$67c(a0)
	move.l	#$b15051cb,$680(a0)
	move.l	#$fff460dc,$684(a0)
	move.l	#$61000058,$688(a0)
	move.l	#$226c0018,$68c(a0)
	move.l	#$4eaefe3e,$690(a0)
	move.l	#$102d0022,$694(a0)
	move.l	#$4eaefeb0,$698(a0)
	move.l	#$204c4eae,$69c(a0)
	move.l	#$ff1c6000,$6a0(a0)
	move.l	#$b26130,$6a4(a0)
	move.l	#$23690020,$6a8(a0)
	move.l	#$306022,$6ac(a0)
	move.l	#$383c8002,$6b0(a0)
	move.l	#$6034383c,$6b4(a0)
	move.l	#$8003602e,$6b8(a0)
	move.l	#$74002202,$6bc(a0)
	move.l	#$383c800a,$6c0(a0)
	move.l	#$6024383c,$6c4(a0)
	move.l	#$66032,$6c8(a0)
	move.l	#$383c0007,$6cc(a0)
	move.l	#$602c383c,$6d0(a0)
	move.l	#$80056026,$6d4(a0)
	move.l	#$383c000d,$6d8(a0)
	move.l	#$60207601,$6dc(a0)
	move.l	#$60027600,$6e0(a0)
	move.l	#$383c8009,$6e4(a0)
	move.l	#$6014c0fc,$6e8(a0)
	move.l	#$16c2fc,$6ec(a0)
	move.l	#$bd041,$6f0(a0)
	move.l	#$d042c0fc,$6f4(a0)
	move.l	#$200c6fc,$6f8(a0)
	move.l	#$200226c,$6fc(a0)
	move.l	#$18137c,$700(a0)
	move.l	#$50008,$704(a0)
	move.l	#$3344001c,$708(a0)
	move.l	#$236d001a,$70c(a0)
	move.l	#$28236d,$710(a0)
	move.l	#$1e0034,$714(a0)
	move.l	#$2340002c,$718(a0)
	move.l	#$23430024,$71c(a0)
	move.l	#$4eaefe38,$720(a0)
	move.l	#$1029001f,$724(a0)
	move.l	#$4a8056c1,$728(a0)
	move.l	#$4e75317c,$72c(a0)
	move.l	#$40000024,$730(a0)
	move.l	#$317c0002,$734(a0)
	move.l	#$9c1229,$738(a0)
	move.l	#$227000,$73c(a0)
	move.l	#$3c02269,$740(a0)
	move.l	#$24eee,$744(a0)
	move.l	#$febc122d,$748(a0)
	move.l	#$227000,$74c(a0)
	move.l	#$3c04eee,$750(a0)
	move.l	#$fec24aad,$754(a0)
	move.l	#$66710,$758(a0)
	move.l	#$286d0002,$75c(a0)
	move.l	#$41ec005c,$760(a0)
	move.l	#$226d0006,$764(a0)
	move.l	#$4eaefe92,$768(a0)
	move.l	#$41fafb72,$76c(a0)
	move.l	#$43fa0062,$770(a0)
	move.l	#$41e8ffd0,$774(a0)
	move.l	#$43e9ffd0,$778(a0)
	move.l	#$323c0017,$77c(a0)
	move.l	#$32d851c9,$780(a0)
	move.l	#$fffc323c,$784(a0)
	move.l	#$1234298,$788(a0)
	move.l	#$51c9fffc,$78c(a0)
	move.l	#$4cdf7fff,$790(a0)
	move.l	#$603e23f9,$794(a0)
	move.l	#$a7080000,$7b4(a0)
	move.l	#$1,$7b8(a0)
	move.l	#$cdf80000,$7bc(a0)
	move.l	#$10000,$7c4(a0)
	move.l	#$1ede0003,$7c8(a0)
	move.l	#$21c80000,$7cc(a0)
	move.l	#$1f00,$7d0(a0)
	move.l	#$93c94eae,$7f8(a0)
	move.l	#$feda2840,$7fc(a0)
	move.l	#$4aac00ac,$800(a0)
	move.l	#$670000a8,$804(a0)
	move.l	#$6100016c,$808(a0)
	move.l	#$206c00ac,$80c(a0)
	move.l	#$d1c8d1c8,$810(a0)
	move.l	#$20680010,$814(a0)
	move.l	#$d1c8d1c8,$818(a0)
	move.l	#$48e72030,$81c(a0)
	move.w	#$45f9,$820(a0)
	move.l	#$74017000,$82c(a0)
	move.l	#$101826ca,$830(a0)
	move.l	#$600214d8,$834(a0)
	move.l	#$51c8fffc,$838(a0)
	move.l	#$421a2039,$83c(a0)
	move.l	#$53806f1e,$84c(a0)
	move.l	#$c010020,$850(a0)
	move.l	#$6ff45282,$854(a0)
	move.l	#$26ca600a,$858(a0)
	move.l	#$12185380,$85c(a0)
	move.l	#$c010020,$860(a0)
	move.l	#$6f0414c1,$864(a0)
	move.l	#$60f2421a,$868(a0)
	move.l	#$60dc421a,$86c(a0)
	move.l	#$429b2002,$870(a0)
	move.l	#$4cdf0c04,$874(a0)
	move.w	#$4879,$878(a0)
	move.l	#$4e756100,$8ac(a0)
	move.l	#$c66100,$8b0(a0)
	move.l	#$b023c0,$8b4(a0)
	move.l	#$42a72f00,$8bc(a0)
	move.l	#$2440202a,$8c0(a0)
	move.l	#$246710,$8c4(a0)
	move.l	#$2c790000,$8c8(a0)
	move.l	#$22280000,$8d0(a0)
	move.l	#$4eaeff82,$8d4(a0)
	move.l	#$222a0020,$8d8(a0)
	move.l	#$6728243c,$8dc(a0)
	move.l	#$3ed,$8e0(a0)
	move.l	#$4eaeffe2,$8e4(a0)
	move.w	#$23c0,$8e8(a0)
	move.l	#$e5882040,$8fc(a0)
	move.l	#$29680008,$900(a0)
	move.l	#$a44eb9,$904(a0)
	move.l	#$70006004,$90c(a0)
	move.l	#$202f0004,$910(a0)
	move.w	#$2e79,$914(a0)
	move.l	#$2c790000,$91c(a0)
	move.l	#$42039,$920(a0)
	move.l	#$67022240,$928(a0)
	move.l	#$4eaefe62,$92c(a0)
	move.w	#$4ab9,$930(a0)
	move.l	#$fe86201f,$944(a0)
	move.l	#$4e7548e7,$948(a0)
	move.l	#$1062e3c,$94c(a0)
	move.l	#$38007,$950(a0)
	move.l	#$2c780004,$954(a0)
	move.l	#$4eaeff94,$958(a0)
	move.l	#$4cdf6080,$95c(a0)
	move.l	#$706460b0,$960(a0)
	move.l	#$41ec005c,$964(a0)
	move.l	#$4eaefe80,$968(a0)
	move.l	#$41ec005c,$96c(a0)
	move.l	#$4eaefe8c,$970(a0)
	move.l	#$4e7542b9,$974(a0)
	move.l	#$1e,$984(a0)
	move.l	#$4eaefdd8,$988(a0)
	move.w	#$23c0,$98c(a0)

	bsr	_flushcache

out
	movem.l	(a7)+,d0-d1/a0-a2
	rts


pl_section2_xxx
	PL_START

	PL_END

; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
	rts



; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	bsr	update_task_seglist

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

	;remove exe

	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_saveregs
		blk.l	16,0
_stacksize
		dc.l	0

update_task_seglist
	movem.l	d0/a0/a6,-(a7)
	move.l	$4,A6
	sub.l	a1,a1
	jsr	(_LVOFindTask,a6)
	move.l	d0,a0
	move.l	pr_CLI(a0),d0
	asl.l	#2,d0
	move.l	d0,a0

	; store loaded segments in current task

	move.l	d7,cli_Module(a0)

	movem.l	(a7)+,d0/a0/a6
	rts

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1		dc.l	0
		dc.l	0

;============================================================================

	END
