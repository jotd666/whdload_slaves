;*---------------------------------------------------------------------------
;  :Program.	Swos.asm
;  :Contents.	Slave for "Sensible Golf" from Sensible Software
;  :Author.	Galahad of Fairlight
;  :History.	11.02.01
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	PhxAs
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	sys:include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	dh1:sensiblegolf/SensibleGolf.slave
	ENDC
	
	;OPT	O+ OG+			;enable optimizing

;CHIP_ONLY

	IFD	CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = 0
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
	ENDC
;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	_data-_base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$59		;ws_keyexit = Del
_expmem
		dc.l	FASTMEMSIZE		;ws_ExpMem
		dc.w	_name-_base	;ws_name
		dc.w	_copy-_base	;ws_copy
		dc.w	_info-_base	;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
_config
	dc.b	0
DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
    
_name	dc.b	'Sensible Golf'
		IFD		CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
		dc.b	0
_copy	dc.b	'1995 Sensible Software / Virgin',0
_info	dc.b	'-------------------------------',10
	dc.b	'Installed & Fixed by',10
	dc.b	'Galahad of FAiRLiGHT / JOTD',10
	dc.b	10
	dc.b	"Version "
	DECL_VERSION
	dc.b	10,'-------------------------------',10,10
	dc.b	'Thanks to John Regent and Karpow/Scoopex',10
	dc.b	'for the different versions',10,10
	dc.b	'Thanks to Frank for the installer and icons',10
	dc.b	0
	dc.b	-1
	CNOP 0,2
_data:
		dc.b	'DATA',0
file1:
		dc.b	'GALAHAD.ROOT',0
optionsfile:
		dc.b	'SG.OPTS',0
bootfile:	dc.b	'SSBOOT',0		
golf:		dc.b	'GOLF',0
golf_rel:		dc.b	'GOLF.REL',0
		even
;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		
		lea	_expmem(pc),a0
		IFD	CHIP_ONLY
		move.l	#$80000,(a0)
		ENDC

		; avoids an access fault when decrunching SPS version: RN unpacker
		; reads 4 bytes before expansion memory...
		;
		; it doesn't happen with the other non SPS version (but RN archive is
		; seen as corrupt by all Windows & XFDdecrunch unpackers!)
		;
		; once unpacked, both versions only differ by build date...
		;
		lea	golf(pc),a0
		move.l	_resload(pc),a2
		jsr		(resload_GetFileSize,a2)
		lea	golf(pc),a0
		cmp.l	#124636,d0
		bne.b	.notsps
		lea		_expmem(pc),a1
		add.l	#$4,(a1)
.notsps

		
		lea	_addr_cbbe4(pc),a0
		move.l	_expmem(pc),d0
		add.l	#$cbbe4-$80000,d0
		move.l	d0,(a0)
		
		lea	_addr_cac46(pc),a0
		move.l	_expmem(pc),d0
		add.l	#$cac46-$80000,d0
		move.l	d0,(a0)
		

		lea	file1(pc),a0
		bsr	_Testfile
		tst.l	d0
		bne	filepresent
		lea	$10000,a0
		moveq	#0,d0
		move.w	#$578,d0			;Size of file to save
		move.w	#$15d,d1
		moveq	#0,d2
looper		move.l	d2,(a0)+
		dbra	d1,looper
		lea	file1(pc),a0
		lea	$10000,a1
		bsr	_SaveFile
filepresent:				
		lea	optionsfile(pc),a0
		bsr	_Testfile
		tst.l	d0
		bne.s	filepresent2
		lea	optionsdata(pc),a1		;File to save under
		moveq	#$a,d0				;Size of options data
		bsr	_SaveFile
filepresent2:
		lea	optionsfile(pc),a0
		lea	optionsdata(pc),a1
		bsr	_LoadFile

		lea	golf(pc),a0
		move.l	_expmem(pc),a1
		bsr	_LoadFile
		move.l	a1,a0
		moveq	#0,d0
		bsr		rn_unpack_main

		; now load reloc table and apply relocs
		lea	$10000,a1
		lea	golf_rel(pc),a0
		jsr	(resload_LoadFileDecrunch,a2)
		
		lsr.l	#2,d0
		subq.l	#1,d0
		;
		; reloc table has spurious elements, check that
		; addresses are included between $80000 and $FFF00 it seems
		; that's more or less what SSBOOT does
		; OR how to create something more complex than it should be...
		move.l	_expmem(pc),a0
		lea		$10000,a1
.reloc_loop
		move.l	(a1)+,d1
		btst	#0,d1
		beq.b	.skip	; must be odd
		move.l	(-1,a0,d1.l),d2
		cmp.l	#$fff00,d2
		bcc.b	.skip
		sub.l	#$80000,d2
		bcs.b	.skip
		add.l	a0,d2
		move.l	d2,(-1,a0,d1.l)
.skip	
		dbf	d0,.reloc_loop
		
		IFND	CHIP_ONLY
		move.l	_expmem(pc),a0
		move.l	a0,a7
		add.l	#$80000-$200,a7
		ENDC
		
		cmp.w	#'20',$2c(a0)
		beq.s	my_version
		cmp.w	#'18',$2c(a0)
		beq.s	karpow_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

karpow_version:
my_version:
	move.l	a0,a1
	move.l	a1,-(a7)
	lea		pl_main(pc),a0
	jmp		resload_Patch(a2)
	
pl_main
	PL_START
	; original Galahad fixes
	PL_NOP		$5b64,4
	PL_NOP		$5c32,4
	PL_NOP		$32736,4
	PL_NOP		$32764,4
	PL_P		$32bfc,fileloader
	PL_P		$34030,fake
	PL_P		$41526,fake
	PL_PS		$417ae,loadroot
	PL_PS		$41878,loadroot
	PL_PS		$4172c,save
	PL_PS		$424d0,load
	PL_P		$3e934,optionsload
	PL_PS		$41664,filenamemakermaker
	PL_R		$411e4
	PL_R		$41424
	;;PL_R		$3eb86	; was wrong in 1.2, wrong address for RTS
	
	; added JOTD fixes (snoop & fastmem)
	PL_ORW		$bd7a+2,$200	; fix snoop (bplcon0)
	PL_ORW		$1dda,$200	; fix snoop (bplcon0 in copperlist)
	PL_NOP		$5c38,16		; remove write to bplcon3 and bplcon4
	PL_W		$A824+2,$1E		; one less iteration in loop, don't overwrite DFF1C0
	PL_PS		$9ade,kbint
	PL_PSS		$345e0,kbint2,6
	IFND	CHIP_ONLY
	PL_NOP		$5bae,6		; remove stack set
	ENDC
	PL_END
	
;------------------------------------------------------------
kbint2
	BCLR	#6,$bfee01
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq.b	_quit
	rts

;------------------------------------------------------------
kbint
	move.l	d0,-(a7)
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq.b	_quit
	move.l	(a7)+,d0
	rts

;------------------------------------------------------------
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

;------------------------------------------------------------
optionsload:
		movem.l	d0/a0-a1,-(a7)
		move.l	_addr_cac46(pc),a1
		lea	optionsfile(pc),a0
		bsr	_LoadFile
		movem.l	(a7)+,d0/a0-a1
		rts

load:
		movem.l	d0-d7/a0-a6,-(a7)
		move.l	_addr_cbbe4(pc),a1
		move.l	a1,a3
		move.l	a1,a2
		addq.l	#4,a1
get3:		movem.l	a0-a1,-(a7)
loop2:		move.b	(a0)+,d0
		cmp.b	(a1)+,d0
		bne.s	wrong_file
		tst.b	d0
		bne.s	loop2
		movem.l	(a7)+,a0-a1
		bra	quit
wrong_file:
		movem.l	(a7)+,a0-a1
		lea	$20(a1),a1
		bra.s	get3
quit:
		subq.w	#1,(a2)
		lea	$554(a3),a3
		move.l	a1,a2
		lea	$20(a2),a2
getta:		move.b	(a2)+,(a1)+
		cmp.l	a1,a3
		bne.s	getta
		lea	filenamemaker(pc),a3
getta2:		move.b	(a0)+,(a3)+
		bne.s	getta2
		clr.b	(a3)
		lea	filenamemaker(pc),a0
		bsr	_DeleteFile
		bsr	save_root
		movem.l	(a7)+,d0-d7/a0-a6
		moveq	#0,d0
		tst.l	d0
		rts

save_root:
		movem.l	d0/a0-a2,-(a7)			;Saves Galahad.ROOT
		lea	file1(pc),a0
		move.l	_addr_cbbe4(pc),a1
		move.l	#$578,d0
		bsr	_SaveFile
		movem.l	(a7)+,d0/a0-a2
		rts

filenamemakermaker:
		movem.l	d0-d7/a0-a6,-(a7)
		lea	filenamemaker(pc),a2
make:		move.b	(a0)+,(a2)+
		bne.s	make
		clr.b	(a2)
		lea	filenamemaker(pc),a0
		bsr	_LoadFile
		movem.l	(a7)+,d0-d7/a0-a6
		moveq	#0,d0
		tst.l	d0
		rts
;-------------------------------------------------
save:
		movem.l	d0-d7/a0-a6,-(a7)
		movem.l	d0-d2/a0-a5,-(a7)		
		move.l	_addr_cbbe4(pc),a2

		moveq	#0,d0
		move.l	a2,a3
		move.l	a2,a5
		addq.l	#4,a2
		move.l	a0,a4
looper2
		move.l	a2,a3
		move.l	a0,a4
		tst.l	(a2)
		beq.s	skip1
get:		move.b	(a4)+,d2
		cmp.b	(a3)+,d2
		bne.s	skip2
		tst.b	d2
		bne.s	get
		bra.s	done

skip2:		lea	$20(a2),a2
		addq.w	#1,d0
		cmp.w	#$2c,d0
		beq.s	skip3
		bra.s	looper2

skip1		addq.w	#1,(a5)
skip3:		move.l	a2,a5
		moveq	#0,d0
next:		addq.b	#1,d0
		move.b	(a0)+,(a2)+
		bne.s	next
		clr.b	(a2)
		subq.b	#1,d0
		move.b	d0,-1(a5)
done:		movem.l	(A7)+,d0-d2/a0-a5
		moveq	#0,d0
		exg	d1,d0
		lea	filenamemaker(pc),a3
copy:		move.b	(a0)+,(a3)+
		bne.s	copy
		clr.b	(a3)+
		lea	filenamemaker(pc),a0
		bsr	_SaveFile
		lea	file1(pc),a0
		move.l	_addr_cbbe4(pc),a1

		move.l	#$578,d0
		bsr	_SaveFile
		lea	optionsfile(pc),a0
		move.l	_addr_cac46(pc),a1
		moveq	#$a,d0
		bsr	_SaveFile
		movem.l	(a7)+,d0-d7/a0-a6
		moveq	#0,d0
		tst.l	d0
		rts





loadroot:
		movem.l	a0-a2,-(a7)
		lea	file1(pc),a0
		bsr	_LoadFile
		movem.l	(a7)+,a0-a2
		moveq	#0,d0
		tst.l	d0
		rts
fileloader:
		movem.l	d0-d7/a0-a6,-(a7)
		tst.l	d0
		bne.s	fake_load
		addq.l	#4,a0			;Skip	df0:
		bsr	_LoadFile
		move.l	a1,a0
		bsr	_Decrunch
skip_fake:
		movem.l	(a7)+,d0-d7/a0-a6
		move.l	size(pc),d1
fake:		moveq	#0,d0
		tst.l	d0
		rts				
fake_load:
		movem.l	(a7)+,d0-d7/a0-a6
		moveq	#0,d0
		moveq	#0,d1
		tst.l	d0
		rts
		
filenamemaker:
		dcb.b	14,0
optionsdata:
		dc.b	$00,$01,$00,$01,$00,$00,$00,$02,$00,$00,$43
		even

;------------------------------------------------------------------

_resload	dc.l	0		;address of resident loader
_addr_cbbe4	dc.l	0
_addr_cac46	dc.l	0
size:
		dc.l	0
;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

		cnop	0,4

_DeleteFile:
		movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DeleteFile(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
_LoadFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		lea	size(pc),a0
		move.l	d0,(a0)
		movem.l	(a7)+,d0-d1/a0-a2
		rts
		
SHIFT_OFFSET = -$10


_Decrunch
	movem.l	d1-d7/a0-a6,-(sp)
	
	; game loads data at $77400 but decrunched length
	; makes the end at exactly $80000, which makes the
	; decruncher trigger an access fault just after $80000 if
	; chipmem is just 512k (no impact for 1MB)
	; (decruncher bug reads 3 or 4 bytes too much after the limit)
	; so we move the data and move it back afterwards
	cmp.l	#$80000,a0
	bcc	.no_access_fault		; fastmem

	; let's move the unpacked data just before
	move.l	a0,a2
	move.l	4(a2),d0	; unpacked length
	move.l	d0,d2		; save in d2
	add.l	d0,a2
	cmp.l	#$80000,a2
	bne	.no_access_fault
	
	; ends right before $80000: rn decrunch is going to read too much
	move.l	a0,a2
	move.l	8(a2),d0	; packed length

	
	lea	(SHIFT_OFFSET,a2),a3	; there's some room there
	lsr.w	#2,d0
	add.l	#10,d0
.copy
	move.l	(a2)+,(a3)+
	dbf		d0,.copy
	lea	(SHIFT_OFFSET,a0),a0	; source
	; same dest
	move.l	a0,a1
	bsr		rn_unpack
	; now move memory back
	lea		(-SHIFT_OFFSET,a0),a1			; source (start)
	add.l	d2,a0
	add.l	d2,a1
.copy2
	move.b	-(a0),-(a1)
	subq.l	#1,d2
	bne.b	.copy2
	bra.b	.out
.no_access_fault
	
	bsr		rn_unpack

.out
	movem.l	(sp)+,d1-d7/a0-a6
	rts
		
_Testfile:
		movem.l d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		movem.l	(a7)+,d1/a0-a2
		rts

_SaveFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts
;==========================================

rn_unpack
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_Decrunch(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

rn_unpack_main
	MOVEM.L	D0-D7/A0-A6,-(A7)	;636: 48e7fffe
	LEA	-384(A7),A7		;63a: 4feffe80
	MOVEA.L	A7,A2			;63e: 244f
	BSR.W	LAB_0062		;640: 6100016c
	MOVEQ	#0,D1			;644: 7200
	CMPI.L	#$524e4301,D0		;646: 0c80524e4301
	BNE.W	LAB_0059		;64c: 660000f8
	BSR.W	LAB_0062		;650: 6100015c
	MOVE.L	D0,384(A7)		;654: 2f400180
	LEA	10(A0),A3		;658: 47e8000a
	MOVEA.L	A1,A5			;65c: 2a49
	LEA	0(A5,D0.L),A6		;65e: 4df50800
	BSR.W	LAB_0062		;662: 6100014a
	LEA	0(A3,D0.L),A4		;666: 49f30800
	CLR.W	-(A7)			;66a: 4267
	CMPA.L	A4,A5			;66c: bbcc
	BCC.S	LAB_0050		;66e: 644c
	MOVEQ	#0,D0			;670: 7000
	MOVE.B	-2(A3),D0		;672: 102bfffe
	LEA	0(A6,D0.L),A0		;676: 41f60800
	CMPA.L	A4,A0			;67a: b1cc
	BLS.S	LAB_0050		;67c: 633e
	ADDQ.W	#2,A7			;67e: 544f
	MOVE.L	A4,D0			;680: 200c
	BTST	#0,D0			;682: 08000000
	BEQ.S	LAB_004B		;686: 6704
	ADDQ.W	#1,A4			;688: 524c
	ADDQ.W	#1,A0			;68a: 5248
LAB_004B:
	MOVE.L	A0,D0			;68c: 2008
	BTST	#0,D0			;68e: 08000000
	BEQ.S	LAB_004C		;692: 6702
	ADDQ.W	#1,A0			;694: 5248
LAB_004C:
	MOVEQ	#0,D0			;696: 7000
LAB_004D:
	CMPA.L	A0,A6			;698: bdc8
	BEQ.S	LAB_004E		;69a: 6708
	MOVE.B	-(A0),D1		;69c: 1220
	MOVE.W	D1,-(A7)		;69e: 3f01
	ADDQ.B	#1,D0			;6a0: 5200
	BRA.S	LAB_004D		;6a2: 60f4
LAB_004E:
	MOVE.W	D0,-(A7)		;6a4: 3f00
	ADDA.L	D0,A0			;6a6: d1c0
LAB_004F:
	LEA	-32(A4),A4		;6a8: 49ecffe0
	MOVEM.L	(A4),D0-D7		;6ac: 4cd400ff
	MOVEM.L	D0-D7,-(A0)		;6b0: 48e0ff00
	CMPA.L	A3,A4			;6b4: b9cb
	BHI.S	LAB_004F		;6b6: 62f0
	SUBA.L	A4,A3			;6b8: 97cc
	ADDA.L	A0,A3			;6ba: d7c8
LAB_0050:
	MOVEQ	#0,D7			;6bc: 7e00
	MOVE.B	1(A3),D6		;6be: 1c2b0001
	ROL.W	#8,D6			;6c2: e15e
	MOVE.B	(A3),D6			;6c4: 1c13
	MOVEQ	#2,D0			;6c6: 7002
	MOVEQ	#2,D1			;6c8: 7202
	BSR.W	LAB_005F		;6ca: 610000be
LAB_0051:
	MOVEA.L	A2,A0			;6ce: 204a
	BSR.W	LAB_0064		;6d0: 610000e8
	LEA	128(A2),A0		;6d4: 41ea0080
	BSR.W	LAB_0064		;6d8: 610000e0
	LEA	256(A2),A0		;6dc: 41ea0100
	BSR.W	LAB_0064		;6e0: 610000d8
	MOVEQ	#-1,D0			;6e4: 70ff
	MOVEQ	#16,D1			;6e6: 7210
	BSR.W	LAB_005F		;6e8: 610000a0
	MOVE.W	D0,D4			;6ec: 3800
	SUBQ.W	#1,D4			;6ee: 5344
	BRA.S	LAB_0054		;6f0: 601c
LAB_0052:
	LEA	128(A2),A0		;6f2: 41ea0080
	MOVEQ	#0,D0			;6f6: 7000
	BSR.S	LAB_005B		;6f8: 615a
	NEG.L	D0			;6fa: 4480
	LEA	-1(A5,D0.L),A1		;6fc: 43f508ff
	LEA	256(A2),A0		;700: 41ea0100
	BSR.S	LAB_005B		;704: 614e
	MOVE.B	(A1)+,(A5)+		;706: 1ad9
LAB_0053:
	MOVE.B	(A1)+,(A5)+		;708: 1ad9
	DBF	D0,LAB_0053		;70a: 51c8fffc
LAB_0054:
	MOVEA.L	A2,A0			;70e: 204a
	BSR.S	LAB_005B		;710: 6142
	SUBQ.W	#1,D0			;712: 5340
	BMI.S	LAB_0056		;714: 6b1a
LAB_0055:
	MOVE.B	(A3)+,(A5)+		;716: 1adb
	DBF	D0,LAB_0055		;718: 51c8fffc
	MOVE.B	1(A3),D0		;71c: 102b0001
	ROL.W	#8,D0			;720: e158
	MOVE.B	(A3),D0			;722: 1013
	LSL.L	D7,D0			;724: efa8
	MOVEQ	#1,D1			;726: 7201
	LSL.W	D7,D1			;728: ef69
	SUBQ.W	#1,D1			;72a: 5341
	AND.L	D1,D6			;72c: cc81
	OR.L	D0,D6			;72e: 8c80
LAB_0056:
	DBF	D4,LAB_0052		;730: 51ccffc0
	CMPA.L	A6,A5			;734: bbce
	BCS.S	LAB_0051		;736: 6596
	MOVE.W	(A7)+,D0		;738: 301f
	BEQ.S	LAB_0058		;73a: 6708
LAB_0057:
	MOVE.W	(A7)+,D1		;73c: 321f
	MOVE.B	D1,(A5)+		;73e: 1ac1
	SUBQ.B	#1,D0			;740: 5300
	BNE.S	LAB_0057		;742: 66f8
LAB_0058:
	BRA.S	LAB_005A		;744: 6004
LAB_0059:
	MOVE.L	D1,384(A7)		;746: 2f410180
LAB_005A:
	LEA	384(A7),A7		;74a: 4fef0180
	MOVEM.L	(A7)+,D0-D7/A0-A6	;74e: 4cdf7fff
	RTS				;752: 4e75
LAB_005B:
	MOVE.W	(A0)+,D0		;754: 3018
	AND.W	D6,D0			;756: c046
	SUB.W	(A0)+,D0		;758: 9058
	BNE.S	LAB_005B		;75a: 66f8
	MOVE.B	60(A0),D1		;75c: 1228003c
	SUB.B	D1,D7			;760: 9e01
	BGE.S	LAB_005C		;762: 6c02
	BSR.S	LAB_0061		;764: 6130
LAB_005C:
	LSR.L	D1,D6			;766: e2ae
	MOVE.B	61(A0),D0		;768: 1028003d
	CMPI.B	#$02,D0			;76c: 0c000002
	BLT.S	LAB_005E		;770: 6d16
	SUBQ.B	#1,D0			;772: 5300
	MOVE.B	D0,D1			;774: 1200
	MOVE.B	D0,D2			;776: 1400
	MOVE.W	62(A0),D0		;778: 3028003e
	AND.W	D6,D0			;77c: c046
	SUB.B	D1,D7			;77e: 9e01
	BGE.S	LAB_005D		;780: 6c02
	BSR.S	LAB_0061		;782: 6112
LAB_005D:
	LSR.L	D1,D6			;784: e2ae
	BSET	D2,D0			;786: 05c0
LAB_005E:
	RTS				;788: 4e75
LAB_005F:
	AND.W	D6,D0			;78a: c046
	SUB.B	D1,D7			;78c: 9e01
	BGE.S	LAB_0060		;78e: 6c02
	BSR.S	LAB_0061		;790: 6104
LAB_0060:
	LSR.L	D1,D6			;792: e2ae
	RTS				;794: 4e75
LAB_0061:
	ADD.B	D1,D7			;796: de01
	LSR.L	D7,D6			;798: eeae
	SWAP	D6			;79a: 4846
	ADDQ.W	#4,A3			;79c: 584b
	MOVE.B	-(A3),D6		;79e: 1c23
	ROL.W	#8,D6			;7a0: e15e
	MOVE.B	-(A3),D6		;7a2: 1c23
	SWAP	D6			;7a4: 4846
	SUB.B	D7,D1			;7a6: 9207
	MOVEQ	#16,D7			;7a8: 7e10
	SUB.B	D1,D7			;7aa: 9e01
	RTS				;7ac: 4e75
LAB_0062:
	MOVEQ	#3,D1			;7ae: 7203
LAB_0063:
	LSL.L	#8,D0			;7b0: e188
	MOVE.B	(A0)+,D0		;7b2: 1018
	DBF	D1,LAB_0063		;7b4: 51c9fffa
	RTS				;7b8: 4e75
LAB_0064:
	MOVEQ	#31,D0			;7ba: 701f
	MOVEQ	#5,D1			;7bc: 7205
	BSR.S	LAB_005F		;7be: 61ca
	SUBQ.W	#1,D0			;7c0: 5340
	BMI.S	LAB_006A		;7c2: 6b7c
	MOVE.W	D0,D2			;7c4: 3400
	MOVE.W	D0,D3			;7c6: 3600
	LEA	-16(A7),A7		;7c8: 4feffff0
	MOVEA.L	A7,A1			;7cc: 224f
LAB_0065:
	MOVEQ	#15,D0			;7ce: 700f
	MOVEQ	#4,D1			;7d0: 7204
	BSR.S	LAB_005F		;7d2: 61b6
	MOVE.B	D0,(A1)+		;7d4: 12c0
	DBF	D2,LAB_0065		;7d6: 51cafff6
	MOVEQ	#1,D0			;7da: 7001
	ROR.L	#1,D0			;7dc: e298
	MOVEQ	#1,D1			;7de: 7201
	MOVEQ	#0,D2			;7e0: 7400
	MOVEM.L	D5-D7,-(A7)		;7e2: 48e70700
LAB_0066:
	MOVE.W	D3,D4			;7e6: 3803
	LEA	12(A7),A1		;7e8: 43ef000c
LAB_0067:
	CMP.B	(A1)+,D1		;7ec: b219
	BNE.S	LAB_0069		;7ee: 663a
	MOVEQ	#1,D5			;7f0: 7a01
	LSL.W	D1,D5			;7f2: e36d
	SUBQ.W	#1,D5			;7f4: 5345
	MOVE.W	D5,(A0)+		;7f6: 30c5
	MOVE.L	D2,D5			;7f8: 2a02
	SWAP	D5			;7fa: 4845
	MOVE.W	D1,D7			;7fc: 3e01
	SUBQ.W	#1,D7			;7fe: 5347
LAB_0068:
	ROXL.W	#1,D5			;800: e355
	ROXR.W	#1,D6			;802: e256
	DBF	D7,LAB_0068		;804: 51cffffa
	MOVEQ	#16,D5			;808: 7a10
	SUB.B	D1,D5			;80a: 9a01
	LSR.W	D5,D6			;80c: ea6e
	MOVE.W	D6,(A0)+		;80e: 30c6
	MOVE.B	D1,60(A0)		;810: 1141003c
	MOVE.B	D3,D5			;814: 1a03
	SUB.B	D4,D5			;816: 9a04
	MOVE.B	D5,61(A0)		;818: 1145003d
	MOVEQ	#1,D6			;81c: 7c01
	SUBQ.B	#1,D5			;81e: 5305
	LSL.W	D5,D6			;820: eb6e
	SUBQ.W	#1,D6			;822: 5346
	MOVE.W	D6,62(A0)		;824: 3146003e
	ADD.L	D0,D2			;828: d480
LAB_0069:
	DBF	D4,LAB_0067		;82a: 51ccffc0
	LSR.L	#1,D0			;82e: e288
	ADDQ.B	#1,D1			;830: 5201
	CMPI.B	#$11,D1			;832: 0c010011
	BNE.S	LAB_0066		;836: 66ae
	MOVEM.L	(A7)+,D5-D7		;838: 4cdf00e0
	LEA	16(A7),A7		;83c: 4fef0010
LAB_006A:
	RTS				;840: 4e75
	