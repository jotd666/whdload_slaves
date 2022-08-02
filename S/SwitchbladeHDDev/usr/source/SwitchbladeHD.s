; Resourced by whdslave_resourcer v0.92
; a program written by JOTD in 2016-2019
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	IFD BARFLY
	OUTPUT	"Switchblade.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC
_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 13)
	dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
	dc.l	$80000					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$0					; ws_keydebug
_keyexit
	dc.b	$59					; ws_keyexit
_expmem
	dc.l	$0					; ws_expmem
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;---
_config
;	dc.b	"BW;"
; dc.b    "C1:X:Infinite lives:0;"
	dc.b	0
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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
_name	dc.b	'Switchblade',0
_copy	dc.b	'1989 Core Design/Gremlin',0
_info
    dc.b   'Installed by Codetapper/Action!',10,'Version 1.3 (10.02.2003)',10,'Thanks to Adrian Simpson, Keith Krellwitz',10,'and DJ Mike for sending the originals!',0
_kickname   dc.b    0
;--- version id
    dc.b	0
exename:
	dc.b	"switchblade",0
    even
; IRA V2.10 (Jun  1 2022) (c)1993-1995 Tim Ruehsen
; (c)2009-2015 Frank Wille, (c)2014-2019 Nicolas Bastien
start_address	EQU	$B000
EXT_0001	EQU	$B002
EXT_0002	EQU	$B174
EXT_0003	EQU	$B64C
EXT_0004	EQU	$10000
EXT_0005	EQU	$10020
EXT_0006	EQU	$53000
EXT_0007	EQU	$578F4
EXT_0008	EQU	$58000
EXT_0009	EQU	$5B944
EXT_000a	EQU	$5C914
EXT_000b	EQU	$5E000
EXT_000c	EQU	$60964
EXT_000d	EQU	$63000
EXT_000e	EQU	$65F76
DMACONR		EQU	$DFF002
BLTSIZE		EQU	$DFF058
LAB_0002:
	dc.b	$00	;d8
	DC.B	'sbladeam.raw',0
score_name:
	DC.B	'Switchblade.highs',0
LAB_0004:
	dc.b	$00	;f8
	dc.b	$01	;f9
start:
	LEA	_resload(PC),A1		;0fa: 43fa0682
	MOVE.L	A0,(A1)			;0fe: 2288
	LEA	LAB_0064(PC),A0		;100: 41fa0680
	MOVEA.L	_resload(PC),A2		;104: 247a0678
	JSR	resload_Control(A2)	;108 (offset=34)
	LEA	LAB_0002+1(PC),A0	;10c: 41faffcb
	BSR.W	get_file_size		;110: 61000350
	BNE.S	LAB_0006		;114: 6604
	LEA	exename(PC),A0		;116: 41faff12
LAB_0006:
	LEA	start_address,A1		;11a: 43f90000b000
	JSR	resload_LoadFileDecrunch(A2)	;120 (offset=1c)
	CMPI.L	#$63158666,start_address	;124: 0cb9631586660000b000
	BNE.S	LAB_0007		;12e: 660a
	LEA	start_address,A0		;130: 41f90000b000
	BSR.W	LAB_0045		;136: 61000450
LAB_0007:
	CMPI.L	#$128f3817,start_address	;13a: 0cb9128f38170000b000
	BEQ.W	LAB_0009		;144: 6700008c
	CMPI.L	#$69444521,EXT_0002	;148: 0cb9694445210000b174
	BEQ.W	LAB_000C		;152: 6700010e
	CMPI.L	#$0005e0b6,EXT_0001	;156: 0cb90005e0b60000b002
	BNE.W	LAB_0069		;160: 6600063e
	LEA	EXT_0006,A0		;164: 41f900053000
	LEA	EXT_000b,A1		;16a: 43f90005e000
	BSR.W	fix_blitter_waiits		;170: 61000148
	BSR.W	load_high_scores		;174: 61000280
	BSR.W	LAB_001A		;178: 610001d6
	LEA	LAB_0008(PC),A0		;17c: 41fa0018
	SUBA.L	A1,A1			;180: 93c9
	MOVEA.L	_resload(PC),A2		;182: 247a05fa
	JSR	resload_Patch(A2)	;186 (offset=64)
	LEA	EXT_000e,A7		;18a: 4ff900065f76
	JMP	start_address		;190: 4ef90000b000

LAB_0008:
	PL_START
	PL_NOP	$4a484,4
	PL_NOP	$4a488,2
	PL_R	$4a53c
	PL_P	$531d6,LAB_0027
	PL_PS	$532e6,LABN_0328
	PL_NOP	$5e0ce,4
	PL_NOP	$5e0d2,2
	PL_END

LAB_0009:
	LEA	start_address,A0		;1d2: 41f90000b000
	LEA	EXT_0004,A1		;1d8: 43f900010000
	BSR.W	fungus_decrunch		;1de: 61000296
	LEA	EXT_0008,A0		;1e2: 41f900058000
	LEA	EXT_000d,A1		;1e8: 43f900063000
	BSR.W	fix_blitter_waiits		;1ee: 610000ca
LAB_000A:
	LEA	LAB_0004+1(PC),A0	;1f2: 41faff05
	MOVE.B	#$02,(A0)		;1f6: 10bc0002
	LEA	high_scores_location(PC),A0		;1fa: 41fa059a
	MOVE.L	#$00057cf4,(A0)		;1fe: 20bc00057cf4
	BSR.W	load_high_scores		;204: 610001f0
	BSR.W	LAB_001A		;208: 61000146
	LEA	LAB_000B(PC),A0		;20c: 41fa0018
	SUBA.L	A1,A1			;210: 93c9
	MOVEA.L	_resload(PC),A2		;212: 247a056a
	JSR	resload_Patch(A2)	;216 (offset=64)
	LEA	EXT_000e,A7		;21a: 4ff900065f76
	JMP	EXT_0005		;220: 4ef900010020

LAB_000B:
	PL_START
	PL_NOP	$4f4a4,4
	PL_NOP	$4f4a8,2
	PL_R	$4f55c
	PL_P	$581f6,LAB_0027
	PL_PS	$58306,LABN_0334
	PL_NOP	$630ee,4
	PL_NOP	$630f2,2
	PL_END

LAB_000C:
	LEA	EXT_0003,A0		;262: 41f90000b64c
	LEA	EXT_0004,A1		;268: 43f900010000
	ADDA.L	#$000533e0,A0		;26e: d1fc000533e0
	ADDA.L	#$000533e0,A1		;274: d3fc000533e0
LAB_000D:
	MOVE.L	-(A0),-(A1)		;27a: 2320
	CMPA.L	#$00010000,A1		;27c: b3fc00010000
	BNE.S	LAB_000D		;282: 66f6
	LEA	LAB_000E(PC),A0		;284: 41fa0010
	SUBA.L	A1,A1			;288: 93c9
	MOVEA.L	_resload(PC),A2		;28a: 247a04f2
	JSR	resload_Patch(A2)	;28e (offset=64)
	BRA.W	LAB_000A		;292: 6000ff5e
LAB_000E:
	PL_START
	PL_P	$cc,LAB_0022
	PL_P	$d6,LAB_0023
	PL_P	$e2,LAB_0024
	PL_P	$ee,LAB_0025
	PL_L	$63398,$dff002
	PL_END

fix_blitter_waiits:
	MOVE.L	#$00dff058,D0		;2ba: 203c00dff058
	MOVE.L	#$4e714eb9,D1		;2c0: 223c4e714eb9
LAB_0010:
	CMPA.L	A0,A1			;2c6: b3c8
	BLT.S	LAB_0016		;2c8: 6d5c
	CMPI.W	#$33c7,(A0)		;2ca: 0c5033c7
	BNE.S	LAB_0012		;2ce: 6610
	CMP.L	2(A0),D0		;2d0: b0a80002
	BNE.S	LAB_0012		;2d4: 660a
	MOVE.W	D1,(A0)+		;2d6: 30c1
	PEA	LAB_0022(PC)		;2d8: 487a00d8
LAB_0011:
	MOVE.L	(A7)+,(A0)+		;2dc: 20df
	BRA.S	LAB_0010		;2de: 60e6
LAB_0012:
	CMPI.L	#$33fc0401,(A0)		;2e0: 0c9033fc0401
	BNE.S	LAB_0013		;2e6: 660e
	CMP.L	4(A0),D0		;2e8: b0a80004
	BNE.S	LAB_0013		;2ec: 6608
	MOVE.L	D1,(A0)+		;2ee: 20c1
	PEA	LAB_0023(PC)		;2f0: 487a00c8
	BRA.S	LAB_0011		;2f4: 60e6
LAB_0013:
	CMPI.L	#$33fc2c14,(A0)		;2f6: 0c9033fc2c14
	BNE.S	LAB_0014		;2fc: 660e
	CMP.L	4(A0),D0		;2fe: b0a80004
	BNE.S	LAB_0014		;302: 6608
	MOVE.L	D1,(A0)+		;304: 20c1
	PEA	LAB_0024(PC)		;306: 487a00bc
	BRA.S	LAB_0011		;30a: 60d0
LAB_0014:
	CMPI.L	#$33fc3214,(A0)		;30c: 0c9033fc3214
	BNE.S	LAB_0015		;312: 660e
	CMP.L	4(A0),D0		;314: b0a80004
	BNE.S	LAB_0015		;318: 6608
	MOVE.L	D1,(A0)+		;31a: 20c1
	PEA	LAB_0025(PC)		;31c: 487a00b0
	BRA.S	LAB_0011		;320: 60ba
LAB_0015:
	ADDQ.L	#2,A0			;322: 5488
	BRA.S	LAB_0010		;324: 60a0
LAB_0016:
	RTS				;326: 4e75

LABN_0328:
	BSR.S	LAB_0019		;328: 6116
	CMPI.B	#$5f,D0			;32a: 0c00005f
	BNE.S	LAB_0017		;32e: 6602
	BRA.S	switch_trainer		;330: 604e
LAB_0017:
	RTS				;332: 4e75

LABN_0334:
	BSR.S	LAB_0019		;334: 610a
	CMPI.B	#$5f,D0			;336: 0c00005f
	BNE.S	LAB_0018		;33a: 6602
	BRA.S	switch_trainer		;33c: 6042
LAB_0018:
	RTS				;33e: 4e75

LAB_0019:
	ROR.B	#1,D0			;340: e218
	EORI.B	#$ff,D0			;342: 0a0000ff
	CMP.B	_keyexit(PC),D0	;346: b03afcd7
	BEQ.W	_quit		;34a: 6700044e
	RTS				;34e: 4e75

LAB_001A:
	MOVE.L	LAB_0065+2(PC),D0	;350: 203a0434
	TST.L	D0			;354: 4a80
	BEQ.S	LAB_001C		;356: 671c
	MOVE.B	LAB_0004+1(PC),D0	;358: 103afd9f
	CMPI.B	#$02,D0			;35c: 0c000002
	BEQ.S	LAB_001B		;360: 670a
	MOVE.W	#$00ff,EXT_0009		;362: 33fc00ff0005b944
	BRA.S	LAB_001C		;36a: 6008
LAB_001B:
	MOVE.W	#$00ff,EXT_000c		;36c: 33fc00ff00060964
LAB_001C:
	MOVE.L	LAB_0066(PC),D0		;374: 203a0418
	TST.L	D0			;378: 4a80
	BEQ.S	LAB_001D		;37a: 6702
	BRA.S	switch_trainer		;37c: 6002
LAB_001D:
	RTS				;37e: 4e75

switch_trainer:
	MOVE.L	D0,-(A7)		;380: 2f00
	MOVE.B	LAB_0004+1(PC),D0	;382: 103afd75
	CMPI.B	#$02,D0			;386: 0c000002
	BEQ.S	LAB_001F		;38a: 670a
	EORI.W	#$cf73,EXT_0007		;38c: 0a79cf73000578f4
	BRA.S	LAB_0020		;394: 6008
LAB_001F:
	EORI.W	#$cf73,EXT_000a		;396: 0a79cf730005c914
LAB_0020:
	BSR.S	LAB_0021		;39e: 6104
	MOVE.L	(A7)+,D0		;3a0: 201f
	RTS				;3a2: 4e75

LAB_0021:
	MOVE.L	A0,-(A7)		;3a4: 2f08
	LEA	LAB_0004(PC),A0		;3a6: 41fafd50
	MOVE.B	#$ff,(A0)		;3aa: 10bc00ff
	MOVEA.L	(A7)+,A0		;3ae: 205f
	RTS				;3b0: 4e75

LAB_0022:
	MOVE.W	D7,BLTSIZE		;3b2: 33c700dff058
	BRA.S	wait_blit		;3b8: 601c
LAB_0023:
	MOVE.W	#$0401,BLTSIZE		;3ba: 33fc040100dff058
	BRA.S	wait_blit		;3c2: 6012
LAB_0024:
	MOVE.W	#$2c14,BLTSIZE		;3c4: 33fc2c1400dff058
	BRA.S	wait_blit		;3cc: 6008
LAB_0025:
	MOVE.W	#$3214,BLTSIZE		;3ce: 33fc321400dff058
wait_blit:
	BTST	#6,DMACONR		;3d6: 0839000600dff002
	BNE.S	wait_blit		;3de: 66f6
	RTS				;3e0: 4e75

LAB_0027:
	MOVE.B	(A2)+,D3		;3e2: 161a
	CMPI.B	#$2a,D3			;3e4: 0c03002a
	BNE.S	LAB_0028		;3e8: 6604
	MOVE.B	#$20,D3			;3ea: 163c0020
LAB_0028:
	MOVE.B	D3,(A1)+		;3ee: 12c3
	DBF	D2,LAB_0027		;3f0: 51cafff0
	BRA.S	save_high_scores		;3f4: 6030
	
load_high_scores:
	MOVEM.L	D0-D1/A0-A3,-(A7)	;3f6: 48e7c0f0
	MOVEA.L	high_scores_location(PC),A1		;3fa: 227a039a
	MOVEA.L	A1,A3			;3fe: 2649
	LEA	score_name(PC),A0		;400: 41fafce4
	MOVEA.L	_resload(PC),A2		;404: 247a0378
	JSR	resload_GetFileSize(A2)	;408 (offset=24)
	TST.L	D0			;40c: 4a80
	BEQ.S	LAB_002A		;40e: 6710
	LEA	score_name(PC),A0		;410: 41fafcd4
	MOVEA.L	A3,A1			;414: 224b
	MOVE.L	A1,-(A7)		;416: 2f09
	JSR	resload_LoadFile(A2)	;418 (offset=8)
	MOVEA.L	(A7)+,A1		;41c: 225f
	BSR.S	crypt_scores		;41e: 612e
LAB_002A:
	MOVEM.L	(A7)+,D0-D1/A0-A3	;420: 4cdf0f03
	RTS				;424: 4e75

save_high_scores:
	MOVEM.L	D0-D1/A0-A2,-(A7)	;426: 48e7c0e0
	MOVE.B	LAB_0004(PC),D0		;42a: 103afccc
	BNE.S	LAB_002C		;42e: 6618
	LEA	score_name(PC),A0		;430: 41fafcb4
	MOVEA.L	high_scores_location(PC),A1		;434: 227a0360
	MOVEA.L	_resload(PC),A2		;438: 247a0344
	BSR.S	crypt_scores		;43c: 6110
	MOVE.L	A1,-(A7)		;43e: 2f09
	JSR	resload_SaveFile(A2)	;440 (offset=c)
	MOVEA.L	(A7)+,A1		;444: 225f
	BSR.S	crypt_scores		;446: 6106
LAB_002C:
	MOVEM.L	(A7)+,D0-D1/A0-A2	;448: 4cdf0703
	RTS				;44c: 4e75

crypt_scores:
	MOVE.L	#$0000017c,D0		;44e: 203c0000017c
	MOVE.L	D0,-(A7)		;454: 2f00
LAB_002E:
	EOR.B	D0,(A1)+		;456: b119
	SUBQ.L	#1,D0			;458: 5380
	BNE.S	LAB_002E		;45a: 66fa
	MOVE.L	(A7)+,D0		;45c: 201f
	SUBA.L	D0,A1			;45e: 93c0
	RTS				;460: 4e75

get_file_size:
	MOVEM.L	D1/A0-A2,-(A7)		;462: 48e740e0
	MOVEA.L	_resload(PC),A2		;466: 247a0316
	JSR	resload_GetFileSize(A2)	;46a (offset=24)
	TST.L	D0			;46e: 4a80
	MOVEM.L	(A7)+,D1/A0-A2		;470: 4cdf0702
	RTS				;474: 4e75

fungus_decrunch:
	MOVE.L	#$2a46554e,D0		;476: 203c2a46554e
	MOVE.L	#$4755532a,D1		;47c: 223c4755532a
LAB_0031:
	CMP.L	(A0)+,D0		;482: b098
	BEQ.S	LAB_0032		;484: 6704
	CMP.L	(A0)+,D0		;486: b098
	BNE.S	LAB_0031		;488: 66f8
LAB_0032:
	CMP.L	(A0)+,D1		;48a: b298
	BNE.S	LAB_0031		;48c: 66f4
	SUBQ.W	#8,A0			;48e: 5148
	MOVEA.L	-(A0),A2		;490: 2460
	ADDA.L	A1,A2			;492: d5c9
	MOVE.L	-(A0),D0		;494: 2020
	MOVE.L	-(A0),D4		;496: 2820
	MOVE.L	-(A0),D5		;498: 2a20
	MOVE.L	-(A0),D6		;49a: 2c20
	MOVE.L	-(A0),D7		;49c: 2e20
LAB_0033:
	ADD.L	D0,D0			;49e: d080
	BNE.S	LAB_0034		;4a0: 6610
	MOVE.L	D4,D0			;4a2: 2004
	MOVE.L	D5,D4			;4a4: 2805
	MOVE.L	D6,D5			;4a6: 2a06
	MOVE.L	D7,D6			;4a8: 2c07
	MOVE.L	-(A0),D7		;4aa: 2e20
	MOVE	#$ffff,CCR		;4ac: 44fcffff
	ADDX.L	D0,D0			;4b0: d180
LAB_0034:
	BCS.S	LAB_003B		;4b2: 6550
	MOVEQ	#3,D1			;4b4: 7203
	MOVEQ	#0,D3			;4b6: 7600
	ADD.L	D0,D0			;4b8: d080
	BNE.S	LAB_0035		;4ba: 6610
	MOVE.L	D4,D0			;4bc: 2004
	MOVE.L	D5,D4			;4be: 2805
	MOVE.L	D6,D5			;4c0: 2a06
	MOVE.L	D7,D6			;4c2: 2c07
	MOVE.L	-(A0),D7		;4c4: 2e20
	MOVE	#$ffff,CCR		;4c6: 44fcffff
	ADDX.L	D0,D0			;4ca: d180
LAB_0035:
	BCS.S	LAB_0037		;4cc: 650c
	MOVEQ	#1,D3			;4ce: 7601
	MOVEQ	#8,D1			;4d0: 7208
	BRA.W	LAB_003F		;4d2: 60000080
LAB_0036:
	MOVEQ	#8,D1			;4d6: 7208
	MOVEQ	#8,D3			;4d8: 7608
LAB_0037:
	BSR.W	LAB_0042		;4da: 6100008c
	ADD.W	D2,D3			;4de: d642
LAB_0038:
	MOVEQ	#7,D1			;4e0: 7207
LAB_0039:
	ADD.L	D0,D0			;4e2: d080
	BNE.S	LAB_003A		;4e4: 6610
	MOVE.L	D4,D0			;4e6: 2004
	MOVE.L	D5,D4			;4e8: 2805
	MOVE.L	D6,D5			;4ea: 2a06
	MOVE.L	D7,D6			;4ec: 2c07
	MOVE.L	-(A0),D7		;4ee: 2e20
	MOVE	#$ffff,CCR		;4f0: 44fcffff
	ADDX.L	D0,D0			;4f4: d180
LAB_003A:
	ADDX.W	D2,D2			;4f6: d542
	DBF	D1,LAB_0039		;4f8: 51c9ffe8
	MOVE.B	D2,-(A2)		;4fc: 1502
	DBF	D3,LAB_0038		;4fe: 51cbffe0
	BRA.S	LAB_0041		;502: 605c
LAB_003B:
	MOVEQ	#0,D2			;504: 7400
	ADD.L	D0,D0			;506: d080
	BNE.S	LAB_003C		;508: 6610
	MOVE.L	D4,D0			;50a: 2004
	MOVE.L	D5,D4			;50c: 2805
	MOVE.L	D6,D5			;50e: 2a06
	MOVE.L	D7,D6			;510: 2c07
	MOVE.L	-(A0),D7		;512: 2e20
	MOVE	#$ffff,CCR		;514: 44fcffff
	ADDX.L	D0,D0			;518: d180
LAB_003C:
	ADDX.W	D2,D2			;51a: d542
	ADD.L	D0,D0			;51c: d080
	BNE.S	LAB_003D		;51e: 6610
	MOVE.L	D4,D0			;520: 2004
	MOVE.L	D5,D4			;522: 2805
	MOVE.L	D6,D5			;524: 2a06
	MOVE.L	D7,D6			;526: 2c07
	MOVE.L	-(A0),D7		;528: 2e20
	MOVE	#$ffff,CCR		;52a: 44fcffff
	ADDX.L	D0,D0			;52e: d180
LAB_003D:
	ADDX.W	D2,D2			;530: d542
	CMPI.B	#$02,D2			;532: 0c020002
	BLT.S	LAB_003E		;536: 6d12
	CMPI.B	#$03,D2			;538: 0c020003
	BEQ.S	LAB_0036		;53c: 6798
	MOVEQ	#8,D1			;53e: 7208
	BSR.S	LAB_0042		;540: 6126
	MOVE.W	D2,D3			;542: 3602
	MOVE.W	#$000c,D1		;544: 323c000c
	BRA.S	LAB_003F		;548: 600a
LAB_003E:
	MOVEQ	#2,D3			;54a: 7602
	ADD.W	D2,D3			;54c: d642
	MOVE.W	#$0009,D1		;54e: 323c0009
	ADD.W	D2,D1			;552: d242
LAB_003F:
	BSR.S	LAB_0042		;554: 6112
	LEA	1(A2,D2.W),A3		;556: 47f22001
LAB_0040:
	MOVE.B	-(A3),-(A2)		;55a: 1523
	DBF	D3,LAB_0040		;55c: 51cbfffc
LAB_0041:
	CMPA.L	A2,A1			;560: b3ca
	BLT.W	LAB_0033		;562: 6d00ff3a
	RTS				;566: 4e75

LAB_0042:
	SUBQ.W	#1,D1			;568: 5341
	CLR.W	D2			;56a: 4242
LAB_0043:
	ADD.L	D0,D0			;56c: d080
	BNE.S	LAB_0044		;56e: 6610
	MOVE.L	D4,D0			;570: 2004
	MOVE.L	D5,D4			;572: 2805
	MOVE.L	D6,D5			;574: 2a06
	MOVE.L	D7,D6			;576: 2c07
	MOVE.L	-(A0),D7		;578: 2e20
	MOVE	#$ffff,CCR		;57a: 44fcffff
	ADDX.L	D0,D0			;57e: d180
LAB_0044:
	ADDX.W	D2,D2			;580: d542
	DBF	D1,LAB_0043		;582: 51c9ffe8
	RTS				;586: 4e75

LAB_0045:
	MOVE.L	D0,-(A7)		;588: 2f00
	CMPI.L	#$63158666,(A0)+	;58a: 0c9863158666
	BNE.S	LAB_0049		;590: 6644
	MOVE.L	(A0)+,D0		;592: 2018
	LEA	-8(A0,D0.L),A5		;594: 4bf008f8
	MOVE.L	(A0)+,(A7)		;598: 2e98
	LEA	108(A0),A4		;59a: 49e8006c
	MOVEA.L	A4,A6			;59e: 2c4c
	ADDA.L	(A7),A6			;5a0: ddd7
	MOVEA.L	A6,A3			;5a2: 264e
	MOVEA.L	A6,A1			;5a4: 224e
	LEA	_resload(PC),A2		;5a6: 45fa01d6
	MOVEQ	#119,D0			;5aa: 7077
LAB_0046:
	MOVE.B	-(A1),-(A2)		;5ac: 1521
	DBF	D0,LAB_0046		;5ae: 51c8fffc
	BSR.S	LAB_004E		;5b2: 6152
	BSR.S	LAB_004A		;5b4: 6124
	MOVE.L	(A7),D0			;5b6: 2017
	LEA	-120(A4),A1		;5b8: 43ecff88
LAB_0047:
	MOVE.B	(A4)+,(A1)+		;5bc: 12dc
	DBF	D0,LAB_0047		;5be: 51c8fffc
	SUBI.L	#$00010000,D0		;5c2: 048000010000
	BPL.S	LAB_0047		;5c8: 6af2
	MOVEQ	#119,D0			;5ca: 7077
	LEA	_resload(PC),A2		;5cc: 45fa01b0
LAB_0048:
	MOVE.B	-(A2),-(A3)		;5d0: 1722
	DBF	D0,LAB_0048		;5d2: 51c8fffc
LAB_0049:
	MOVE.L	(A7)+,D0		;5d6: 201f
	RTS				;5d8: 4e75

LAB_004A:
	BSR.S	LAB_0052		;5da: 6156
	BCC.S	LAB_004D		;5dc: 6422
	MOVEQ	#0,D1			;5de: 7200
	BSR.S	LAB_0052		;5e0: 6150
	BCC.S	LAB_004C		;5e2: 6416
	LEA	LAB_0060+2(PC),A1	;5e4: 43fa00f8
	MOVEQ	#4,D3			;5e8: 7604
LAB_004B:
	MOVE.L	-(A1),D0		;5ea: 2021
	BSR.S	LAB_0055		;5ec: 616a
	SWAP	D0			;5ee: 4840
	CMP.W	D0,D1			;5f0: b240
	DBNE	D3,LAB_004B		;5f2: 56cbfff6
	ADD.L	20(A1),D1		;5f6: d2a90014
LAB_004C:
	MOVE.B	-(A5),-(A6)		;5fa: 1d25
	DBF	D1,LAB_004C		;5fc: 51c9fffc
LAB_004D:
	CMPA.L	A4,A6			;600: bdcc
	BGT.S	LAB_0058		;602: 6e62
	RTS				;604: 4e75

LAB_004E:
	MOVEQ	#3,D0			;606: 7003
LAB_004F:
	MOVE.B	-(A5),D7		;608: 1e25
	ROR.L	#8,D7			;60a: e09f
	DBF	D0,LAB_004F		;60c: 51c8fffa
	RTS				;610: 4e75

LAB_0050:
	MOVE.W	A5,D7			;612: 3e0d
	BTST	#0,D7			;614: 08070000
	BNE.S	LAB_0051		;618: 6606
	MOVE.L	-(A5),D7		;61a: 2e25
	ADDX.L	D7,D7			;61c: df87
	BRA.S	LAB_0057		;61e: 603e
LAB_0051:
	MOVE.L	-5(A5),D7		;620: 2e2dfffb
	LSL.L	#8,D7			;624: e18f
	MOVE.B	-(A5),D7		;626: 1e25
	SUBQ.L	#3,A5			;628: 578d
	ADD.L	D7,D7			;62a: de87
	BSET	#0,D7			;62c: 08c70000
	BRA.S	LAB_0057		;630: 602c
LAB_0052:
	ADD.L	D7,D7			;632: de87
	BEQ.S	LAB_0053		;634: 6702
	RTS				;636: 4e75

LAB_0053:
	MOVE.W	A5,D7			;638: 3e0d
	BTST	#0,D7			;63a: 08070000
	BNE.S	LAB_0054		;63e: 6606
	MOVE.L	-(A5),D7		;640: 2e25
	ADDX.L	D7,D7			;642: df87
	RTS				;644: 4e75

LAB_0054:
	MOVE.L	-5(A5),D7		;646: 2e2dfffb
	LSL.L	#8,D7			;64a: e18f
	MOVE.B	-(A5),D7		;64c: 1e25
	SUBQ.L	#3,A5			;64e: 578d
	ADD.L	D7,D7			;650: de87
	BSET	#0,D7			;652: 08c70000
	RTS				;656: 4e75

LAB_0055:
	MOVEQ	#0,D1			;658: 7200
LAB_0056:
	ADD.L	D7,D7			;65a: de87
	BEQ.S	LAB_0050		;65c: 67b4
LAB_0057:
	ADDX.W	D1,D1			;65e: d341
	DBF	D0,LAB_0056		;660: 51c8fff8
	RTS				;664: 4e75

LAB_0058:
	LEA	LAB_0061(PC),A1		;666: 43fa008a
	MOVEQ	#3,D2			;66a: 7403
LAB_0059:
	BSR.S	LAB_0052		;66c: 61c4
	DBCC	D2,LAB_0059		;66e: 54cafffc
	MOVEQ	#0,D4			;672: 7800
	MOVEQ	#0,D1			;674: 7200
	MOVE.B	1(A1,D2.W),D0		;676: 10312001
	EXT.W	D0			;67a: 4880
	BMI.S	LAB_005A		;67c: 6b02
	BSR.S	LAB_0055		;67e: 61d8
LAB_005A:
	MOVE.B	6(A1,D2.W),D4		;680: 18312006
	ADD.W	D1,D4			;684: d841
	BEQ.S	LAB_005C		;686: 671e
	LEA	LAB_0062(PC),A1		;688: 43fa0072
	MOVEQ	#1,D2			;68c: 7401
LAB_005B:
	BSR.S	LAB_0052		;68e: 61a2
	DBCC	D2,LAB_005B		;690: 54cafffc
	MOVEQ	#0,D1			;694: 7200
	MOVE.B	1(A1,D2.W),D0		;696: 10312001
	EXT.W	D0			;69a: 4880
	BSR.S	LAB_0055		;69c: 61ba
	ADD.W	D2,D2			;69e: d442
	ADD.W	6(A1,D2.W),D1		;6a0: d2712006
	BRA.S	LAB_005E		;6a4: 6012
LAB_005C:
	MOVEQ	#0,D1			;6a6: 7200
	MOVEQ	#5,D0			;6a8: 7005
	MOVEQ	#0,D2			;6aa: 7400
	BSR.S	LAB_0052		;6ac: 6184
	BCC.S	LAB_005D		;6ae: 6404
	MOVEQ	#8,D0			;6b0: 7008
	MOVEQ	#64,D2			;6b2: 7440
LAB_005D:
	BSR.S	LAB_0055		;6b4: 61a2
	ADD.W	D2,D1			;6b6: d242
LAB_005E:
	LEA	2(A6,D4.W),A1		;6b8: 43f64002
	ADDA.W	D1,A1			;6bc: d2c1
	MOVE.B	-(A1),-(A6)		;6be: 1d21
LAB_005F:
	MOVE.B	-(A1),-(A6)		;6c0: 1d21
	DBF	D4,LAB_005F		;6c2: 51ccfffc
	BRA.W	LAB_004A		;6c6: 6000ff12
	DC.B	$7f	;6ca
	DC.B	$ff	;6cb
	DC.B	$0	;6cc
	DC.B	$e	;6cd
	DC.B	$0	;6ce
	DC.B	$ff	;6cf
	ORI.B	#$07,D7			;6d0: 00070007
	ORI.B	#$03,D2			;6d4: 00020003
	ORI.B	#$03,D1			;6d8: 00010003
LAB_0060:
	ORI.B	#$00,D1			;6dc: 00010000
	MOVEP.W	0(A5),D0		;6e0: 010d0000
	DC.B	$0	;6e4
	DC.B	$e	;6e5
	ORI.B	#$07,D0			;6e6: 00000007
	ORI.B	#$04,D0			;6ea: 00000004
	ORI.B	#$01,D0			;6ee: 00000001
LAB_0061:
	BTST	D4,D1			;6f2: 0901
	DC.B	$0	;6f4
	DC.B	$ff	;6f5
	DC.B	$ff	;6f6
	DC.B	$8	;6f7
	DC.B	$4	;6f8
	DC.B	$2	;6f9
	BTST	D0,D0			;6fa: 0100
LAB_0062:
	BTST	D5,D4			;6fc: 0b04
	BTST	D3,D0			;6fe: 0700
	BTST	D0,-(A0)		;700: 0120
	ORI.B	#$20,D0			;702: 00000020
	dc.l	0			;706: 00000000
	dc.l	0			;70a: 00000000
	dc.l	0			;70e: 00000000
	dc.l	0			;712: 00000000
	dc.l	0			;716: 00000000
	dc.l	0			;71a: 00000000
	dc.l	0			;71e: 00000000
	dc.l	0			;722: 00000000
	dc.l	0			;726: 00000000
	dc.l	0			;72a: 00000000
	dc.l	0			;72e: 00000000
	dc.l	0			;732: 00000000
	dc.l	0			;736: 00000000
	dc.l	0			;73a: 00000000
	dc.l	0			;73e: 00000000
	dc.l	0			;742: 00000000
	dc.l	0			;746: 00000000
	dc.l	0			;74a: 00000000
	dc.l	0			;74e: 00000000
	dc.l	0			;752: 00000000
	dc.l	0			;756: 00000000
	dc.l	0			;75a: 00000000
	dc.l	0			;75e: 00000000
	dc.l	0			;762: 00000000
	dc.l	0			;766: 00000000
	dc.l	0			;76a: 00000000
	dc.l	0			;76e: 00000000
	dc.l	0			;772: 00000000
	dc.l	0			;776: 00000000
	dc.l	0			;77a: 00000000
_resload:
	dc.l	0			;77e: 00000000
LAB_0064:
	OR.B	D0,D4			;782: 8800
LAB_0065:
	ORI.B	#$00,D7			;784: 00070000
	DC.B	$0	;788
	DC.B	$0	;789
	DC.B	$88	;78a
	DC.B	$0	;78b
	DC.B	$0	;78c
	DC.B	$8	;78d
LAB_0066:
	dc.l	0			;78e: 00000000
	dc.l	0			;792: 00000000
	dc.w	5
high_scores_location:
	dc.l	$00052cd4
_quit:
	PEA	TDREASON_OK			;7a0: 48780009
	BRA.S	LAB_006A		;79e: 6004
LAB_0069:
	PEA	TDREASON_WRONGVER			;7a0: 48780009
LAB_006A:
	MOVE.L	_resload(PC),-(A7)	;7a4: 2f3affd8
	ADDQ.L	#4,(A7)			;7a8: 5897
	RTS				;7aa: 4e75

