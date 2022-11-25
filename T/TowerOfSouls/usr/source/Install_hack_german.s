; IRA V2.00 (Nov  2 2010) (c)1993-95 Tim Ruehsen, (c)2009 Frank Wille

ExecBase	EQU	$4
EXT_0001	EQU	$3A
CIAA_PRA	EQU	$BFE001
DENISEID	EQU	$DFF07C
INTENA		EQU	$DFF09A
FMODE		EQU	$DFF1FE
EXT_0006	EQU	$6E746178



	incdir	include:
	include	"lvo/exec.i"
	include	"lvo/dos.i"
	include	"dos/dos.i"


	SECTION S_0,CODE

	MOVEA.L	ExecBase,A6	;00000: 2c780004
	SUBA.L	A1,A1			;00004: 93c9
	JSR	(_LVOFindTask,A6)	;00006: 4eaefeda exec.library (off=-294)
	MOVEA.L	D0,A2			;0000a: 2440
	TST.L	172(A2)			;0000c: 4aaa00ac
	BNE.S	LAB_0001		;00010: 6628
	LEA	92(A2),A0		;00012: 41ea005c
	JSR	(_LVOWaitPort,A6)	;00016: 4eaefe80 exec.library (off=-384)
	LEA	92(A2),A0		;0001a: 41ea005c
	JSR	(_LVOGetMsg,A6)	;0001e: 4eaefe8c exec.library (off=-372)
	MOVE.L	D0,-(A7)		;00022: 2f00
	BSR.W	LAB_0001		;00024: 61000014
	JSR	(_LVOForbid,A6)	;00028: 4eaeff7c exec.library (off=-132)
	MOVEA.L	(A7)+,A1		;0002c: 225f
	JSR	(_LVOReplyMsg,A6)	;0002e: 4eaefe86 exec.library (off=-378)
	MOVEQ	#0,D0			;00032: 7000
	RTS				;00034: 4e75
LAB_0000:
	MOVEQ	#0,D0			;00036: 7000
	RTS				;00038: 4e75
LAB_0001:
	MOVEA.L	ExecBase,A6	;00000: 2c780004
	LEA	DosName(PC),A1		;0003a: 43fa0bea
	MOVEQ	#0,D0			;0003e: 7000
	JSR	(_LVOOpenLibrary,A6)	;00040: 4eaefdd8 exec.library (off=-552)
	TST.L	D0			;00044: 4a80
	BEQ.W	LAB_0000		;00046: 6700ffee
	MOVEA.L	D0,A6			;0004a: 2c40
	MOVE.L	D0,DosBase		;0004c: 23c00000174e

    ; remove console shit & AGA check
    
	LEA	LAB_000D,A0		;0008e: 41f9000001aa
	BSR.W	write_message		;00094: 6100191a
LAB_0002:
	LEA	LAB_0040,A0		;00098: 41f900000330
	BSR.W	write_message		;0009e: 61001910
    
    ; hardcode install path
	move.l	#9,D0

	MOVE.L	D0,LAB_0009		;000be: 23c000000148
	BSR.W	LAB_0060		;000c4: 61000350
	BMI.W	LAB_0003		;000c8: 6b00000a
	BNE.W	LAB_0007		;000cc: 6600005e
	BRA.W	LAB_0004		;000d0: 60000010
LAB_0003:
	LEA	LAB_0049,A0		;000d4: 41f900000388
	BSR.W	write_message		;000da: 610018d4
	BRA.W	LAB_0002		;000de: 6000ffb8
LAB_0004:
	MOVE.W	#$0001,LAB_0128		;000e2: 33fc000100001366
	BSR.W	LAB_0075		;000ea: 6100041e
LAB_0005:
	LEA	LAB_000C,A0		;000ee: 41f900000184
	BSR.W	write_message		;000f4: 610018ba

    ; removed "please press return"
    
	BRA.W	LAB_0007		;00114: 60000016
LAB_0006:
	LEA	LAB_000B,A0		;00118: 41f900000154
	BSR.W	write_message		;0011e: 61001890
	MOVE.L	#$000001f4,D1		;00122: 223c000001f4
	BRA.W	LAB_0005		;00128: 6000ffc4
LAB_0007:
	MOVEA.L	A6,A1			;00136: 224e
	MOVEA.L	ExecBase,A6	;00138: 2c780004
	JSR	(_LVOCloseLibrary,A6)	;0013c: 4eaefe62 exec.library (off=-414)
	MOVEQ	#0,D0			;00140: 7000
	RTS				;00142: 4e75

LAB_0009:
	dc.l  0			;00148: 00000000
	dc.l  0			;0014c: 00000000
LAB_000A:
	dc.l  0			;00150: 00000000
LAB_000B:
	NEG.W	-(A5)			;00154: 4465
	MOVEQ	#32,D1			;00156: 7220
	SUBQ.W	#1,-(A5)		;00158: 5365
	dc.w  $656c
	dc.w  $656e
	MOVEQ	#117,D2			;0015e: 7475
	MOVEQ	#109,D1			;00160: 726d
	MOVEA.L	-(A5),A0		;00162: 2065
	MOVEQ	#102,D1			;00164: 7266
	dc.w  $6f72
	DC.W	$6465			;00168
	MOVEQ	#116,D1			;0016a: 7274
	MOVEA.L	-(A5),A0		;0016c: 2065
	dc.w  $696e
	dc.w  $656e
	MOVEA.L	D1,A0			;00172: 2041
	MOVE.W	48(A2,D3.W),-(A0)	;00174: 31323030
	MOVE.L	D1,13360(A7)		;00178: 2f413430
	DC.W	$3030			;0017c
	MOVE.L	A5,D7			;0017e: 2e0d
	DC.W	$0a0d			;00180
	DC.W	$0a00			;00182
LAB_000C:
	DC.W	$4472			;00184
	DC.W	$7563			;00186
	DC.W	$6b65			;00188
	dc.w  $6e20
	SUBQ.W	#1,25888(A1)		;0018c: 53696520
	MOVEQ	#117,D5			;00190: 7a75
	dc.w  $6d20
	NOT.W	29300(A7)		;00194: 466f7274
	DC.W	$6661			;00198
	dc.w  $6872
	dc.w  $656e
	MOVEA.L	D5,A0			;0019e: 2045
	dc.w  $6e74
	dc.w  $6572
	MOVE.L	A5,D7			;001a4: 2e0d
	DC.W	$0a0d			;001a6
	DC.W	$0a00			;001a8
LAB_000D:
	NEG.W	-(A5)			;001aa: 4465
LAB_000E:
	MOVEQ	#32,D1			;001ac: 7220
	SUBQ.W	#1,-(A5)		;001ae: 5365
	dc.w  $656c
	dc.w  $656e
LAB_000F:
	MOVEQ	#117,D2			;001b4: 7475
	MOVEQ	#109,D1			;001b6: 726d
	MOVEA.L	D1,A0			;001b8: 2041
	MOVE.W	48(A2,D3.W),-(A0)	;001ba: 31323030
	MOVE.L	D1,13360(A7)		;001be: 2f413430
	MOVE.W	73(A0,D2.W),D0		;001c2: 30302049
	DC.W	$6e73			;001c6
LAB_0010:
	MOVEQ	#97,D2			;001c8: 7461
	dc.w  $6c6c
LAB_0011:
	dc.w    $6174
	DC.W	$696f			;001ce
	DC.W	$6e73			;001d0
	MOVEQ	#114,D0			;001d2: 7072
	DC.W	$6f67			;001d4
	MOVEQ	#97,D1			;001d6: 7261
	DC.W	$6d6d			;001d8
LAB_0012:
	MOVEP	3338(A2),D6		;001da: 0d0a0d0a
LAB_0013:
	NEG.W	-(A5)			;001de: 4465
LAB_0014:
	MOVEQ	#32,D1			;001e0: 7220
	SUBQ.W	#1,-(A5)		;001e2: 5365
	dc.w  $656c
	dc.w  $656e
	MOVEQ	#117,D2			;001e8: 7475
	MOVEQ	#109,D1			;001ea: 726d
	MOVEA.L	-(A2),A0		;001ec: 2062
	dc.w  $656e
	dc.w  $6f74
	DC.W	$6967			;001f2
	MOVEQ	#32,D2			;001f4: 7420
	MOVE.W	14624(A4),D1		;001f6: 322c3920
	DC.W	$4d42			;001fa
	MOVEA.L	D6,A0			;001fc: 2046
	DC.W	$6573			;001fe
	MOVEQ	#112,D2			;00200: 7470
	DC.W	$6c61			;00202
	MOVEQ	#116,D2			;00204: 7474
	dc.w  $656e
	DC.W	$7370			;00208
	DC.W	$6569			;0020a
LAB_0015:
	dc.w  $6368
LAB_0016:
	dc.w  $6572
	MOVEP	24949(A2),D6		;00210: 0d0a6175
	BNE.S	LAB_001A		;00214: 6620
LAB_0017:
	DC.W	$6569			;00216
	DC.W	$6e65			;00218
	MOVEQ	#32,D1			;0021a: 7220
	ADDQ.W	#8,-(A1)		;0021c: 5061
LAB_0018:
	MOVEQ	#116,D1			;0021e: 7274
	dc.w  $6974
LAB_0019:
	DC.W	$696f			;00222
	dc.w  $6e2e
	MOVEP	3338(A2),D6		;00226: 0d0a0d0a
	DC.W	$4175			;0022a
	BNE.S	LAB_001D		;0022c: 6620
	DC.W	$6465			;0022e
	MOVEQ	#32,D1			;00230: 7220
	ADDQ.W	#8,-(A1)		;00232: 5061
	MOVEQ	#116,D1			;00234: 7274
LAB_001A:
	dc.w  $6974
LAB_001B:
	DC.W	$696f			;00238
	dc.w  $6e20
	DC.W	$4968			;0023c
	MOVEQ	#101,D1			;0023e: 7265
	MOVEQ	#32,D1			;00240: 7220
LAB_001C:
	SUBQ.W	#3,-(A1)		;00242: 5761
	dc.w  $686c
	DC.W	$2077			;00246
	dc.w  $6972
	dc.w  $6420
	DC.W	$6569			;0024c
LAB_001D:
	DC.W	$6e65			;0024e
	MOVEA.L	(A3),A0			;00250: 2053
LAB_001E:
	dc.w  $6368
LAB_001F:
	DC.W	$7562			;00254
LAB_0020:
	DC.W	$6c61			;00256
	DC.W	$6465			;00258
LAB_0021:
	MOVEP	28257(A2),D6		;0025a: 0d0a6e61
LAB_0022:
	DC.W	$6d65			;0025e
	DC.W	$6e73			;00260
	MOVE.L	-(A7),D0		;00262: 2027
	DC.W	$5475			;00264
LAB_0023:
	MOVEQ	#109,D1			;00266: 726d
	MOVE.L	-(A0),-(A3)		;00268: 2720
	dc.w  $6572
LAB_0024:
	DC.W	$7374			;0026c
	dc.w  $656c
	dc.w  $6c74
	MOVE.L	A5,D7			;00272: 2e0d
	DC.W	$0a20			;00274
LAB_0025:
	dc.w  $652e
	BEQ.S	LAB_0029		;00278: 672e
	MOVEA.L	-(A4),A0		;0027a: 2064
	dc.w  $6830
	MOVE.W	-(A0),D5		;0027e: 3a20
	dc.w  $6468
LAB_0026:
	DC.W	$313a			;00282
	MOVEA.L	-(A4),A0		;00284: 2064
	dc.w  $6832
	MOVE.W	-(A0),D5		;00288: 3a20
	dc.w  $6574
	dc.w  $632e
	MOVEP	21353(A2),D6		;0028e: 0d0a5369
	dc.w  $6520
	DC.W	$6b6f			;00294
LAB_0027:
	dc.w  $6e6e
	dc.w  $656e
	MOVEA.L	-(A1),A0		;0029a: 2061
	DC.W	$7563			;0029c
	dc.w  $6820
	dc.w  $696e
	MOVEA.L	-(A5),A0		;002a2: 2065
	dc.w  $696e
LAB_0028:
	DC.W	$656d			;002a6
LAB_0029:
	MOVEA.L	(A5),A0			;002a8: 2055
	dc.w  $6e74
LAB_002A:
	dc.w  $6572
LAB_002B:
	MOVEQ	#101,D3			;002ae: 7665
	MOVEQ	#122,D1			;002b0: 727a
LAB_002C:
	DC.W	$6569			;002b2
LAB_002D:
	dc.w  $6368
	DC.W	$6e69			;002b6
	DC.W	$7320			;002b8
LAB_002E:
	dc.w  $696e
LAB_002F:
	DC.W	$7374			;002bc
	dc.w    $616c
LAB_0030:
	DC.W	$6c69			;002c0
	dc.w  $6572
	dc.w  $656e
	MOVE.L	A5,D6			;002c6: 2c0d
	DC.W	$0a20			;002c8
	MOVEQ	#46,D5			;002ca: 7a2e
	CLR.B	8292(A6)		;002cc: 422e2064
	dc.w  $6830
	MOVEA	-(A7),A5		;002d2: 3a67
	DC.W	$616d			;002d4
	DC.W	$6573			;002d6
	MOVE.L	A5,-(A7)		;002d8: 2f0d
	DC.W	$0a20			;002da
LAB_0031:
	MOVEA.L	25701(A7),A0		;002dc: 206f6465
	MOVEQ	#32,D1			;002e0: 7220
	DC.W	$2077			;002e2
	dc.w  $6f72
LAB_0033:
	dc.w  $6b3a
	DC.W	$6675			;002e8
LAB_0034:
	DC.W	$6e2f			;002ea
	ADDQ.W	#1,(A0)			;002ec: 5250
	DC.W	$472f			;002ee
	MOVE.L	A5,D7			;002f0: 2e0d
	EORI.W	#$6965,D4		;002f2: 0a446965
	DC.W	$7365			;002f6
	DC.W	$7320			;002f8
	SUBQ.W	#2,29797(A6)		;002fa: 556e7465
	MOVEQ	#118,D1			;002fe: 7276
LAB_0035:
	dc.w  $6572
LAB_0036:
	MOVEQ	#101,D5			;00302: 7a65
	DC.W	$6963			;00304
LAB_0037:
	dc.w  $686e
LAB_0038:
	DC.W	$6973			;00308
	MOVEA.L	30175(A5),A0		;0030a: 206d75df
LAB_0039:
	MOVEA.L	25956(A2),A0		;0030e: 206a6564
	DC.W	$6f63			;00312
LAB_003A:
	dc.w  $6820
	DC.W	$7363			;00316
	DC.W	$686f			;00318
	dc.w  $6e20
	MOVEQ	#111,D3			;0031c: 766f
LAB_003B:
	MOVEQ	#104,D1			;0031e: 7268
LAB_003C:
	dc.w    $616e
LAB_003D:
	DC.W	$6465			;00322
	dc.w  $6e20
	DC.W	$7365			;00326
	dc.w  $696e
LAB_003E:
	MOVE.L	A5,D7			;0032a: 2e0d
LAB_003F:
	DC.W	$0a0d			;0032c
	DC.W	$0a00			;0032e
LAB_0040:
	SUBQ.W	#3,8301(A7)		;00330: 576f206d
LAB_0041:
	DC.W	$6f63			;00334
LAB_0042:
	dc.w  $6874
	dc.w  $656e
	MOVEA.L	(A3),A0			;0033a: 2053
LAB_0043:
	DC.W	$6965			;0033c
	MOVEA.L	D4,A0			;0033e: 2044
	dc.w  $6572
	MOVEA.L	(A3),A0			;00342: 2053
	DC.W	$6565			;00344
LAB_0044:
	DC.W	$6c65			;00346
	dc.w  $6e74
	DC.W	$7572			;0034a
	dc.w  $6d20
	dc.w  $696e
	DC.W	$7374			;00350
	dc.w    $616c
	DC.W	$6c69			;00354
	dc.w  $6572
LAB_0045:
	dc.w  $656e
	MOVE.W	A5,-(A7)		;0035a: 3f0d
	EORI.W	#$6661,(A0)		;0035c: 0a506661
	dc.w  $646e
	DC.W	$616d			;00362
	dc.w  $656e
	MOVEA.L	-(A5),A0		;00366: 2065
	dc.w  $696e
	DC.W	$6765			;0036a
	DC.W	$6265			;0036c
LAB_0046:
	dc.w  $6e20
	dc.w  $6f64
	dc.w  $6572
LAB_0047:
	MOVEA.L	26996(A5),A0		;00374: 206d6974
	MOVEA.L	98(A1,D2.W),A0		;00378: 20712062
	DC.W	$6565			;0037c
	dc.w  $6e64
	dc.w  $656e
	MOVE.L	A5,D7			;00382: 2e0d
	DC.W	$0a3e			;00384
	MOVE.L	D0,D0			;00386: 2000
LAB_0049:
	MOVEP	21870(A2),D6		;00388: 0d0a556e
	DC.W	$6775			;0038c
	dc.w  $6c74
LAB_004A:
	DC.W	$6967			;00390
	dc.w  $6572
	MOVEA.L	(A0),A0			;00394: 2050
	DC.W	$6661			;00396
LAB_004B:
	DC.W	$640d			;00398
	DC.W	$0a00			;0039a
	MOVEP	19823(A2),D6		;0039c: 0d0a4d6f
	dc.w  $6368
	MOVEQ	#101,D2			;003a2: 7465
	dc.w  $6e20
LAB_004C:
	SUBQ.W	#1,25888(A1)		;003a6: 53696520
	DC.W	$6b6f			;003aa
LAB_004D:
	dc.w  $6d70
	MOVEQ	#105,D1			;003ae: 7269
	DC.W	$6d69			;003b0
	dc.w  $6572
LAB_004E:
	MOVEQ	#32,D2			;003b4: 7420
	dc.w  $6f64
	dc.w  $6572
	MOVEA.L	-(A5),A0		;003ba: 2065
	MOVEQ	#119,D1			;003bc: 7277
LAB_004F:
	DC.W	$6569			;003be
LAB_0050:
	MOVEQ	#101,D2			;003c0: 7465
	MOVEQ	#116,D1			;003c2: 7274
LAB_0051:
	MOVEA.L	101(A3,D7.W),A0		;003c4: 20737065
LAB_0052:
	DC.W	$6963			;003c8
LAB_0053:
	DC.W	$6865			;003ca
	MOVEQ	#110,D1			;003cc: 726e
	MOVE.W	A5,-(A7)		;003ce: 3f0d
LAB_0054:
	EORI.W	#$6562,D7		;003d0: 0a476562
LAB_0055:
	dc.w  $656e
LAB_0056:
	MOVEA.L	(A3),A0			;003d6: 2053
LAB_0057:
	DC.W	$6965			;003d8
	MOVEA.L	-(A3),A0		;003da: 2063
	MOVE.L	-(A0),D6		;003dc: 2c20
	dc.w  $6520
	dc.w  $6f64
	dc.w  $6572
LAB_0058:
	DC.W	$207a			;003e4
LAB_0059:
	DC.W	$756d			;003e6
	MOVEA.L	D2,A0			;003e8: 2042
	DC.W	$6565			;003ea
	dc.w  $6e64
	dc.w  $656e
LAB_005A:
	MOVEA.L	101(A1,D2.W),A0		;003f0: 20712065
	dc.w  $696e
	MOVE.L	A5,D7			;003f6: 2e0d
	DC.W	$0a3e			;003f8
	MOVE.L	D0,D0			;003fa: 2000
	MOVEP	21870(A2),D6		;003fc: 0d0a556e
LAB_005B:
	DC.W	$6775			;00400
	dc.w  $6c74
LAB_005C:
	DC.W	$6967			;00404
LAB_005D:
	dc.w  $6520
	DC.W	$4569			;00408
LAB_005E:
	DC.W	$6e67			;0040a
	dc.w    $6162
	DC.W	$650d			;0040e
	DC.W	$0a00			;00410
LAB_005F:
	MOVE.W	-(A0),D7		;00412: 3e20
	DC.W	$0000			;00414
LAB_0060:
	MOVEA.L	#install_path,A0		;00416: 207c0006b208
LAB_0061:
	CMPI.B	#$71,(A0)		;0041c: 0c100071
	BEQ.S	LAB_0064		;00420: 6706
	CMPI.B	#$51,(A0)		;00422: 0c100051
LAB_0063:
	BNE.S	LAB_0066		;00426: 660e
LAB_0064:
	CMPI.L	#$00000002,LAB_0009	;00428: 0cb90000000200000148
	BEQ.W	LAB_0073		;00432: 670000ce
LAB_0066:
	MOVEA.L	#install_path,A1		;00436: 227c0006b208
	MOVE.W	#$0100,D7		;0043c: 3e3c0100
LAB_0067:
	MOVE.B	(A1)+,D0		;00440: 1019
LAB_0068:
	CMP.B	#$0a,D0			;00442: b03c000a
LAB_0069:
	BEQ.S	LAB_006A		;00446: 6708
	SUBQ.W	#1,D7			;00448: 5347
	BNE.W	LAB_0067		;0044a: 6600fff4
	BRA.S	LAB_006C		;0044e: 6006
LAB_006A:
	MOVE.B	#$00,-1(A1)		;00450: 137c0000ffff
LAB_006C:
	MOVEA.L	#install_path,A1		;00456: 227c0006b208
	MOVEQ	#0,D7			;0045c: 7e00
LAB_006D:
	MOVE.B	(A1)+,D0		;0045e: 1019
	BEQ.W	LAB_006F		;00460: 67000008
LAB_006E:
	ADDQ.W	#1,D7			;00464: 5247
	BRA.W	LAB_006D		;00466: 6000fff6
LAB_006F:
	MOVE.W	D7,LAB_009C		;0046a: 33c700000906
LAB_0070:
	CMPI.B	#$3a,-2(A1)		;00470: 0c29003afffe
	BEQ.S	LAB_0072		;00476: 6716
LAB_0071:
	CMPI.B	#$2f,-2(A1)		;00478: 0c29002ffffe
	BEQ.S	LAB_0072		;0047e: 670e
	MOVE.L	#LAB_0093,LAB_0099	;00480: 23fc000008be000008e2
	BRA.W	LAB_0074		;0048a: 6000007a
LAB_0072:
	MOVE.L	#LAB_0082,LAB_0099	;0048e: 23fc0000084e000008e2
	MOVE.L	#install_path,D1		;00498: 223c0006b208
	MOVEQ	#-2,D2			;0049e: 74fe
	MOVEA.L	DosBase,A6		;004a0: 2c790000174e
	JSR	(_LVOLock,A6)	;004a6: 4eaeffac dos.library (off=-84)
	MOVE.L	D0,LAB_00BA		;004aa: 23c000000c3a
	MOVE.L	D0,LAB_0168+2		;004b0: 23c00000186c
	BEQ.W	LAB_0074		;004b6: 6700004e
	MOVE.L	LAB_0168+2,D1		;004ba: 22390000186c
	MOVE.L	#fileinfoblock,D2		;004c0: 243c00001768
	MOVEA.L	DosBase,A6		;004c6: 2c790000174e
	JSR	(_LVOExamine,A6)	;004cc: 4eaeff9a dos.library (off=-102)
	MOVE.L	#LAB_0082,LAB_0099	;004d0: 23fc0000084e000008e2
	TST.L	D0			;004da: 4a80
	BEQ.W	LAB_0074		;004dc: 67000028
	MOVE.L	LAB_0166+2,LAB_0167+2	;004e0: 23f9000017e400001868
	MOVE.L	#LAB_0086,LAB_0099	;004ea: 23fc00000866000008e2
	TST.L	LAB_0164+2		;004f4: 4ab90000176c
	BMI.W	LAB_0074		;004fa: 6b00000a
	MOVEQ	#0,D0			;004fe: 7000
	RTS				;00500: 4e75
LAB_0073:
	MOVEQ	#1,D0			;00502: 7001
	RTS				;00504: 4e75
LAB_0074:
	MOVEQ	#-1,D0			;00506: 70ff
	RTS				;00508: 4e75
LAB_0075:
	MOVE.L	LAB_0168+2,D1		;0050a: 22390000186c
	MOVEA.L	DosBase,A6		;00510: 2c790000174e
	JSR	(_LVOCurrentDir,A6)	;00516: 4eaeff82 dos.library (off=-126)
	MOVE.L	D0,LAB_00B8		;0051a: 23c000000c32
	MOVE.L	#tower_dirname,D1		;00520: 223c000009b8
	MOVEQ	#-2,D2			;00526: 74fe
	MOVEA.L	DosBase,A6		;00528: 2c790000174e
	JSR	(_LVOLock,A6)	;0052e: 4eaeffac dos.library (off=-84)
	MOVE.L	D0,LAB_0168+2		;00532: 23c00000186c
	MOVE.L	D0,LAB_00BB		;00538: 23c000000c3e
	BNE.W	LAB_0076		;0053e: 66000026
	MOVE.L	#tower_dirname,D1		;00542: 223c000009b8
	MOVEA.L	DosBase,A6		;00548: 2c790000174e
	JSR	(_LVOCreateDir,A6)	;0054e: 4eaeff88 dos.library (off=-120)
	BEQ.W	LAB_0079		;00552: 67000138
	MOVE.L	D0,LAB_0168+2		;00556: 23c00000186c
	MOVE.L	D0,LAB_00BB		;0055c: 23c000000c3e
	BRA.W	LAB_0076		;00562: 60000002
LAB_0076:
	MOVE.L	LAB_0168+2,D1		;00566: 22390000186c
	MOVEA.L	DosBase,A6		;0056c: 2c790000174e
	JSR	(_LVOCurrentDir,A6)	;00572: 4eaeff82 dos.library (off=-126)
	MOVE.L	D0,LAB_00B9		;00576: 23c000000c36
	MOVEQ	#1,D0			;0057c: 7001
	LEA	LAB_00BC,A1		;0057e: 43f900000c42
	BSR.W	LAB_0130		;00584: 61000dfc
	BNE.W	LAB_0079		;00588: 66000102
	MOVEQ	#2,D0			;0058c: 7002
	LEA	LAB_00C0,A1		;0058e: 43f900000c90
	BSR.W	LAB_0130		;00594: 61000dec
	BNE.W	LAB_0079		;00598: 660000f2
	MOVEQ	#3,D0			;0059c: 7003
	LEA	LAB_00C4,A1		;0059e: 43f900000dd6
	BSR.W	LAB_0130		;005a4: 61000ddc
	BNE.W	LAB_0079		;005a8: 660000e2
	MOVEQ	#4,D0			;005ac: 7004
	LEA	LAB_00C5,A1		;005ae: 43f900000f22
	BSR.W	LAB_0130		;005b4: 61000dcc
	BNE.W	LAB_0079		;005b8: 660000d2
	MOVEQ	#5,D0			;005bc: 7005
	LEA	LAB_00C6,A1		;005be: 43f900001002
	BSR.W	LAB_0130		;005c4: 61000dbc
	BNE.W	LAB_0079		;005c8: 660000c2
	LEA	install_path,A0		;005cc: 41f90006b208
	LEA	LAB_007B,A1		;005d2: 43f9000006ac
	MOVE.W	#$4344,(A1)+		;005d8: 32fc4344
	MOVE.B	#$20,(A1)+		;005dc: 12fc0020
LAB_0077:
	MOVE.B	(A0)+,(A1)+		;005e0: 12d8
	BNE.S	LAB_0077		;005e2: 66fc
	SUBQ.W	#1,A1			;005e4: 5349
	CMPI.B	#$2f,-1(A1)		;005e6: 0c29002fffff
	BEQ.S	LAB_0078		;005ec: 670e
	CMPI.B	#$3a,-1(A1)		;005ee: 0c29003affff
	BEQ.S	LAB_0078		;005f4: 6706
	MOVE.B	#$2f,-1(A1)		;005f6: 137c002fffff
LAB_0078:
	MOVE.B	#$54,(A1)+		;005fc: 12fc0054
	MOVE.B	#$75,(A1)+		;00600: 12fc0075
	MOVE.B	#$72,(A1)+		;00604: 12fc0072
	MOVE.B	#$6d,(A1)+		;00608: 12fc006d
	MOVE.B	#$0a,(A1)+		;0060c: 12fc000a
	MOVE.B	#$53,(A1)+		;00610: 12fc0053
	MOVE.B	#$65,(A1)+		;00614: 12fc0065
	MOVE.B	#$65,(A1)+		;00618: 12fc0065
	MOVE.B	#$6c,(A1)+		;0061c: 12fc006c
	MOVE.B	#$65,(A1)+		;00620: 12fc0065
	MOVE.B	#$6e,(A1)+		;00624: 12fc006e
	MOVE.B	#$74,(A1)+		;00628: 12fc0074
	MOVE.B	#$75,(A1)+		;0062c: 12fc0075
	MOVE.B	#$72,(A1)+		;00630: 12fc0072
	MOVE.B	#$6d,(A1)+		;00634: 12fc006d
	MOVE.B	#$0a,(A1)+		;00638: 12fc000a
	MOVE.B	#$00,(A1)+		;0063c: 12fc0000
	MOVE.L	#LAB_007B,D0		;00640: 203c000006ac
	MOVE.L	A1,D1			;00646: 2209
	SUB.L	D0,D1			;00648: 9280
	MOVE.L	#LAB_007C,D2		;0064a: 243c000007d8
	BSR.W	write_whole_file		;00650: 6100121e
	BNE.W	LAB_0079		;00654: 66000036
	MOVEM.L	D0-D7/A0-A6,-(A7)	;00658: 48e7fffe
	BSR.W	LAB_00A7		;0065c: 6100031a
	MOVEM.L	(A7)+,D0-D7/A0-A6	;00660: 4cdf7fff
	MOVE.L	#LAB_018E,D0		;00664: 203c00069e80
	MOVE.L	LAB_0148,D1		;0066a: 223900001562
	MOVE.L	#iconfilename,D2		;00670: 243c000010e6
	BSR.W	write_whole_file		;00676: 610011f8
	BNE.W	LAB_0079		;0067a: 66000010
	LEA	LAB_00F2,A0		;0067e: 41f9000011b2
	BSR.W	write_message		;00684: 6100132a
	BRA.W	LAB_007A		;00688: 6000001a
LAB_0079:
	LEA	LAB_017A,A0		;0068c: 41f900001a2a
	BSR.W	write_message		;00692: 6100131c
	LEA	LAB_011B,A0		;00696: 41f900001306
	BSR.W	write_message		;0069c: 61001312
	BRA.W	LAB_007A		;006a0: 60000002
LAB_007A:
	BSR.W	LAB_009F		;006a4: 6100026a
	MOVEQ	#0,D0			;006a8: 7000
	RTS				;006aa: 4e75
LAB_007B:
	dc.l  0			;006ac: 00000000
	dc.l  0			;006b0: 00000000
	dc.l  0			;006b4: 00000000
	dc.l  0			;006b8: 00000000
	dc.l  0			;006bc: 00000000
	dc.l  0			;006c0: 00000000
	dc.l  0			;006c4: 00000000
	dc.l  0			;006c8: 00000000
	dc.l  0			;006cc: 00000000
	dc.l  0			;006d0: 00000000
	dc.l  0			;006d4: 00000000
	dc.l  0			;006d8: 00000000
	dc.l  0			;006dc: 00000000
	dc.l  0			;006e0: 00000000
	dc.l  0			;006e4: 00000000
	dc.l  0			;006e8: 00000000
	dc.l  0			;006ec: 00000000
	dc.l  0			;006f0: 00000000
	dc.l  0			;006f4: 00000000
	dc.l  0			;006f8: 00000000
	dc.l  0			;006fc: 00000000
	dc.l  0			;00700: 00000000
	dc.l  0			;00704: 00000000
	dc.l  0			;00708: 00000000
	dc.l  0			;0070c: 00000000
	dc.l  0			;00710: 00000000
	dc.l  0			;00714: 00000000
	dc.l  0			;00718: 00000000
	dc.l  0			;0071c: 00000000
	dc.l  0			;00720: 00000000
	dc.l  0			;00724: 00000000
	dc.l  0			;00728: 00000000
	dc.l  0			;0072c: 00000000
	dc.l  0			;00730: 00000000
	dc.l  0			;00734: 00000000
	dc.l  0			;00738: 00000000
	dc.l  0			;0073c: 00000000
	dc.l  0			;00740: 00000000
	dc.l  0			;00744: 00000000
	dc.l  0			;00748: 00000000
	dc.l  0			;0074c: 00000000
	dc.l  0			;00750: 00000000
	dc.l  0			;00754: 00000000
	dc.l  0			;00758: 00000000
	dc.l  0			;0075c: 00000000
	dc.l  0			;00760: 00000000
	dc.l  0			;00764: 00000000
	dc.l  0			;00768: 00000000
	dc.l  0			;0076c: 00000000
	dc.l  0			;00770: 00000000
	dc.l  0			;00774: 00000000
	dc.l  0			;00778: 00000000
	dc.l  0			;0077c: 00000000
	dc.l  0			;00780: 00000000
	dc.l  0			;00784: 00000000
	dc.l  0			;00788: 00000000
	dc.l  0			;0078c: 00000000
	dc.l  0			;00790: 00000000
	dc.l  0			;00794: 00000000
	dc.l  0			;00798: 00000000
	dc.l  0			;0079c: 00000000
	dc.l  0			;007a0: 00000000
	dc.l  0			;007a4: 00000000
	dc.l  0			;007a8: 00000000
	dc.l  0			;007ac: 00000000
	dc.l  0			;007b0: 00000000
	dc.l  0			;007b4: 00000000
	dc.l  0			;007b8: 00000000
	dc.l  0			;007bc: 00000000
	dc.l  0			;007c0: 00000000
	dc.l  0			;007c4: 00000000
	dc.l  0			;007c8: 00000000
	dc.l  0			;007cc: 00000000
	dc.l  0			;007d0: 00000000
	dc.l  0			;007d4: 00000000
LAB_007C:
	NEG.W	-(A5)			;007d8: 4465
	MOVEQ	#32,D1			;007da: 7220
	SUBQ.W	#1,-(A5)		;007dc: 5365
	dc.w  $656c
	dc.w  $656e
	MOVEQ	#117,D2			;007e2: 7475
	MOVEQ	#109,D1			;007e4: 726d
	MOVEA.L	D4,A0			;007e6: 2044
	DC.W	$6973			;007e8
	dc.w  $6b20
	DC.W	$353a			;007ec
	DC.W	$732f			;007ee
	DC.W	$7374			;007f0
	dc.w    $6172
	MOVEQ	#117,D2			;007f4: 7475
	MOVEQ	#45,D0			;007f6: 702d
	DC.W	$7365			;007f8
	DC.W	$7175			;007fa
	dc.w  $656e
	DC.W	$6365			;007fe
	DC.W	$0000			;00800
LAB_007D:
	NEG.W	-(A5)			;00802: 4465
	MOVEQ	#32,D1			;00804: 7220
	SUBQ.W	#1,-(A5)		;00806: 5365
	dc.w  $656c
	dc.w  $656e
LAB_007E:
	MOVEQ	#117,D2			;0080c: 7475
	MOVEQ	#109,D1			;0080e: 726d
	MOVEA.L	D4,A0			;00810: 2044
	DC.W	$6973			;00812
	dc.w  $6b20
	DC.W	$353a			;00816
	SUBQ.W	#1,30060(A7)		;00818: 536f756c
	DC.W	$7300			;0081c
	dc.w  $6320
	DC.W	$7374			;00820
	dc.w  $6568
	MOVEQ	#32,D2			;00824: 7420
	DC.W	$6675			;00826
	MOVEQ	#32,D1			;00828: 7220
	DC.W	$6b6f			;0082a
	dc.w  $6d70
	MOVEQ	#105,D1			;0082e: 7269
	DC.W	$6d69			;00830
	dc.w  $6572
	MOVEQ	#32,D2			;00834: 7420
LAB_007F:
	DC.W	$756e			;00836
	dc.w  $6420
	dc.w  $6520
	DC.W	$6675			;0083c
	MOVEQ	#32,D1			;0083e: 7220
LAB_0080:
	dc.w  $6572
	DC.W	$7765			;00842
	dc.w  $6974
	dc.w  $6572
	MOVEQ	#46,D2			;00848: 742e
LAB_0081:
	MOVEP	0(A2),D6		;0084a: 0d0a0000
LAB_0082:
	ADDQ.W	#8,-(A6)		;0084e: 5066
LAB_0083:
	dc.w    $6164
	dc.l $206e6963
	dc.w  $6874
	DC.W	$2076			;00858
LAB_0084:
	dc.w  $6f72
LAB_0085:
	DC.W	$6861			;0085c
	dc.w  $6e64
	dc.w  $656e
	MOVEP	0(A2),D6		;00862: 0d0a0000
LAB_0086:
	DC.W	$416e			;00866
	DC.W	$6765			;00868
	DC.W	$6765			;0086a
LAB_0087:
	DC.W	$6265			;0086c
	DC.W	$6e65			;0086e
	MOVEQ	#32,D1			;00870: 7220
	ADDQ.W	#8,-(A6)		;00872: 5066
	dc.w    $6164
LAB_0088:
	MOVEA.L	29556(A1),A0		;00876: 20697374
LAB_0089:
	MOVEA.L	-(A5),A0		;0087a: 2065
	dc.w  $696e
	dc.w  $6520
	NEG.W	-(A1)			;00880: 4461
	MOVEQ	#101,D2			;00882: 7465
	dc.w  $692c
	MOVEA.L	25961(A3),A0		;00886: 206b6569
	dc.w  $6e20
LAB_008A:
	ADDQ.W	#8,-(A6)		;0088c: 5066
	dc.w    $6164
	MOVE.L	A5,D7			;00890: 2e0d
	DC.W	$0a00			;00892
	DC.W	$4b65			;00894
	dc.w  $696e
	MOVEA.L	(A0),A0			;00898: 2050
	DC.W	$6661			;0089a
	dc.w  $6420
LAB_008B:
	dc.w    $616e
LAB_008C:
	DC.W	$6765			;008a0
	DC.W	$6765			;008a2
	DC.W	$6265			;008a4
LAB_008D:
	DC.W	$6e0d			;008a6
	DC.W	$0a00			;008a8
	ADDQ.W	#8,-(A6)		;008aa: 5066
LAB_008E:
	dc.w  $6164
	DC.W	$6e61			;008ae
	DC.W	$6d65			;008b0
LAB_008F:
	DC.W	$207a			;008b2
LAB_0090:
	DC.W	$7520			;008b4
LAB_0091:
	DC.W	$6c61			;008b6
	DC.W	$6e67			;008b8
LAB_0092:
	MOVEP	0(A2),D6		;008ba: 0d0a0000
LAB_0093:
	ADDQ.W	#8,-(A6)		;008be: 5066
	dc.w  $6164
	DC.W	$6e61			;008c2
LAB_0094:
	DC.W	$6d65			;008c4
	MOVEA.L	30175(A5),A0		;008c6: 206d75df
LAB_0095:
	MOVEA.L	26996(A5),A0		;008ca: 206d6974
LAB_0096:
	DC.W	$203a			;008ce
LAB_0097:
	MOVEA.L	25701(A7),A0		;008d0: 206f6465
	MOVEQ	#32,D1			;008d4: 7220
	MOVE.L	-(A0),-(A7)		;008d6: 2f20
	dc.w  $656e
LAB_0098:
	DC.W	$6465			;008da
	dc.w  $6e2e
	MOVEP	0(A2),D6		;008de: 0d0a0000
LAB_0099:
	dc.l  0			;008e2: 00000000
	dc.l  0			;008e6: 00000000
LAB_009A:
	MOVEA.L	LAB_0099,A0		;008ea: 2079000008e2
	MOVE.L	A0,-(A7)		;008f0: 2f08
LAB_009B:
	LEA	LAB_017A,A0		;008f2: 41f900001a2a
	BSR.W	write_message		;008f8: 610010b6
	MOVEA.L	(A7)+,A0		;008fc: 205f
	BSR.W	write_message		;008fe: 610010b0
	MOVEQ	#0,D0			;00902: 7000
	RTS				;00904: 4e75
LAB_009C:
	dc.l  0			;00906: 00000000
LAB_009D:
	dc.l  0			;0090a: 00000000
LAB_009E:
	DC.W	$0000			;0090e
LAB_009F:
	MOVE.L	LAB_00B9,D1		;00910: 223900000c36
	BEQ.S	LAB_00A2		;00916: 6710
	MOVEA.L	DosBase,A6		;00918: 2c790000174e
	JSR	(_LVOCurrentDir,A6)	;0091e: 4eaeff82 dos.library (off=-126)
LAB_00A1:
	CLR.L	LAB_00B9		;00922: 42b900000c36
LAB_00A2:
	MOVE.L	LAB_00BB,D1		;00928: 223900000c3e
	BEQ.S	LAB_00A3		;0092e: 6710
	MOVEA.L	DosBase,A6		;00930: 2c790000174e
	JSR	(_LVOUnLock,A6)	;00936: 4eaeffa6 dos.library (off=-90)
	CLR.L	LAB_00BB		;0093a: 42b900000c3e
LAB_00A3:
	MOVE.L	LAB_00B8,D1		;00940: 223900000c32
	BEQ.S	LAB_00A5		;00946: 6710
LAB_00A4:
	MOVEA.L	DosBase,A6		;00948: 2c790000174e
	JSR	(_LVOCurrentDir,A6)	;0094e: 4eaeff82 dos.library (off=-126)
	CLR.L	LAB_00B8		;00952: 42b900000c32
LAB_00A5:
	MOVE.L	LAB_00BA,D1		;00958: 223900000c3a
	CMP.L	#$ffffffff,D1		;0095e: b2bcffffffff
	BEQ.S	LAB_00A6		;00964: 6710
	MOVEA.L	DosBase,A6		;00966: 2c790000174e
	JSR	(_LVOUnLock,A6)	;0096c: 4eaeffa6 dos.library (off=-90)
	CLR.L	LAB_00BA		;00970: 42b900000c3a
LAB_00A6:
	RTS				;00976: 4e75
LAB_00A7:
	MOVE.L	LAB_00B9,D1		;00978: 223900000c36
	BEQ.S	LAB_00A8		;0097e: 6710
	MOVEA.L	DosBase,A6		;00980: 2c790000174e
	JSR	(_LVOCurrentDir,A6)	;00986: 4eaeff82 dos.library (off=-126)
	CLR.L	LAB_00B9		;0098a: 42b900000c36
LAB_00A8:
	MOVE.L	LAB_00BB,D1		;00990: 223900000c3e
	BEQ.S	LAB_00A9		;00996: 6710
	MOVEA.L	DosBase,A6		;00998: 2c790000174e
	JSR	(_LVOUnLock,A6)	;0099e: 4eaeffa6 dos.library (off=-90)
	CLR.L	LAB_00BB		;009a2: 42b900000c3e
LAB_00A9:
	RTS				;009a8: 4e75
	LEA	LAB_00C7,A0		;009aa: 41f900001026
	BSR.W	write_message		;009b0: 61000ffe
	MOVEQ	#0,D0			;009b4: 7000
	RTS				;009b6: 4e75
tower_dirname:
	dc.b	"data",0
    even
LAB_00AD:
	DC.W	$0000			;00a14
	BSET	D1,0(A3,D0.W)		;00a16: 03f30000
	dc.l  0			;00a1a: 00000000
	ORI.B	#$00,D1			;00a1e: 00010000
	dc.l  0			;00a22: 00000000
	dc.l  0			;00a26: 00000000
	ORI.W	#$0000,1001(A3)		;00a2a: 006b000003e9
	ORI.B	#$6b,D0			;00a30: 0000006b
	MOVEA.L	ExecBase,A6	;00a34: 2c780004
	SUBA.L	A1,A1			;00a38: 93c9
	JSR	(_LVOFindTask,A6)	;00a3a: 4eaefeda exec.library (off=-294)
	MOVEA.L	D0,A2			;00a3e: 2440
	TST.L	172(A2)			;00a40: 4aaa00ac
	BNE.S	LAB_00AF		;00a44: 6630
	LEA	92(A2),A0		;00a46: 41ea005c
	JSR	(_LVOWaitPort,A6)	;00a4a: 4eaefe80 exec.library (off=-384)
	LEA	92(A2),A0		;00a4e: 41ea005c
	JSR	(_LVOGetMsg,A6)	;00a52: 4eaefe8c exec.library (off=-372)
	MOVE.L	D0,-(A7)		;00a56: 2f00
	BSR.W	LAB_00AF		;00a58: 6100001c
	JSR	(_LVOForbid,A6)	;00a5c: 4eaeff7c exec.library (off=-132)
	MOVEA.L	(A7)+,A1		;00a60: 225f
	JSR	(_LVOReplyMsg,A6)	;00a62: 4eaefe86 exec.library (off=-378)
	MOVEQ	#0,D0			;00a66: 7000
	RTS				;00a68: 4e75
DosName:
	DC.W	$646f			;00a6a
	DC.W	$732e			;00a6c
	DC.W	$6c69			;00a6e
	dc.w    $6272
	dc.w    $6172
	DC.W	$7900			;00a74
LAB_00AF:
	MOVEA.L	ExecBase,A6	;00a34: 2c780004
	LEA	DosName(PC),A1		;00a76: 43fafff2
	MOVEQ	#0,D0			;00a7a: 7000
	JSR	(_LVOOpenLibrary,A6)	;00a7c: 4eaefdd8 exec.library (off=-552)
	TST.L	D0			;00a80: 4a80
	BEQ.W	LAB_00B0		;00a82: 67000024
	MOVEA.L	D0,A6    ;00a86: 2c40
	LEA	LAB_00B2(PC),A0		;00a88: 41fa002a
	MOVE.L	A0,D1			;00a8c: 2208
	MOVEQ	#-2,D2			;00a8e: 74fe
	JSR	(_LVOLock,A6)	;00a90: 4eaeffac dos.library (off=-84)
	MOVE.L	D0,D1			;00a94: 2200
	JSR	(_LVOCurrentDir,A6)	;00a96: 4eaeff82 dos.library (off=-126)
	LEA	LAB_00B1(PC),A0		;00a9a: 41fa0010
	MOVE.L	A0,D1			;00a9e: 2208
	MOVEQ	#0,D2			;00aa0: 7400
	MOVEQ	#0,D3			;00aa2: 7600
	JSR	(_LVOExecute,A6)	;00aa4: 4eaeff22 dos.library (off=-222)
LAB_00B0:
	MOVEQ	#0,D0			;00aa8: 7000
	RTS				;00aaa: 4e75
LAB_00B1:
	MOVEQ	#114,D0			;00aac: 7072
	DC.W	$6f67			;00aae
	MOVEQ	#97,D1			;00ab0: 7261
	DC.W	$6d00			;00ab2
LAB_00B2:
	dc.l  0			;00ab4: 00000000
	dc.l  0			;00ab8: 00000000
	dc.l  0			;00abc: 00000000
	dc.l  0			;00ac0: 00000000
	dc.l  0			;00ac4: 00000000
	dc.l  0			;00ac8: 00000000
	dc.l  0			;00acc: 00000000
	dc.l  0			;00ad0: 00000000
	dc.l  0			;00ad4: 00000000
	dc.l  0			;00ad8: 00000000
	dc.l  0			;00adc: 00000000
	dc.l  0			;00ae0: 00000000
LAB_00B3:
	dc.l  0			;00ae4: 00000000
	dc.l  0			;00ae8: 00000000
	dc.l  0			;00aec: 00000000
	dc.l  0			;00af0: 00000000
	dc.l  0			;00af4: 00000000
	dc.l  0			;00af8: 00000000
	dc.l  0			;00afc: 00000000
	dc.l  0			;00b00: 00000000
	dc.l  0			;00b04: 00000000
	dc.l  0			;00b08: 00000000
	dc.l  0			;00b0c: 00000000
	dc.l  0			;00b10: 00000000
	dc.l  0			;00b14: 00000000
	dc.l  0			;00b18: 00000000
	dc.l  0			;00b1c: 00000000
	dc.l  0			;00b20: 00000000
	dc.l  0			;00b24: 00000000
	dc.l  0			;00b28: 00000000
	dc.l  0			;00b2c: 00000000
	dc.l  0			;00b30: 00000000
	dc.l  0			;00b34: 00000000
	dc.l  0			;00b38: 00000000
	dc.l  0			;00b3c: 00000000
	dc.l  0			;00b40: 00000000
	dc.l  0			;00b44: 00000000
	dc.l  0			;00b48: 00000000
	dc.l  0			;00b4c: 00000000
	dc.l  0			;00b50: 00000000
	dc.l  0			;00b54: 00000000
	dc.l  0			;00b58: 00000000
	dc.l  0			;00b5c: 00000000
	dc.l  0			;00b60: 00000000
	dc.l  0			;00b64: 00000000
	dc.l  0			;00b68: 00000000
	dc.l  0			;00b6c: 00000000
	dc.l  0			;00b70: 00000000
	dc.l  0			;00b74: 00000000
	dc.l  0			;00b78: 00000000
	dc.l  0			;00b7c: 00000000
	dc.l  0			;00b80: 00000000
	dc.l  0			;00b84: 00000000
	dc.l  0			;00b88: 00000000
	dc.l  0			;00b8c: 00000000
	dc.l  0			;00b90: 00000000
	dc.l  0			;00b94: 00000000
	dc.l  0			;00b98: 00000000
	dc.l  0			;00b9c: 00000000
	dc.l  0			;00ba0: 00000000
	dc.l  0			;00ba4: 00000000
	dc.l  0			;00ba8: 00000000
	dc.l  0			;00bac: 00000000
	dc.l  0			;00bb0: 00000000
	dc.l  0			;00bb4: 00000000
	dc.l  0			;00bb8: 00000000
	dc.l  0			;00bbc: 00000000
	dc.l  0			;00bc0: 00000000
	dc.l  0			;00bc4: 00000000
	dc.l  0			;00bc8: 00000000
	dc.l  0			;00bcc: 00000000
	dc.l  0			;00bd0: 00000000
	dc.l  0			;00bd4: 00000000
	dc.l  0			;00bd8: 00000000
	dc.l  0			;00bdc: 00000000
	DC.W	$0000			;00be0
	BSET	D1,0(A2,D0.W)		;00be2: 03f20000
	dc.l  0			;00be6: 00000000
	dc.l  0			;00bea: 00000000
	DC.W	$0000			;00bee
LAB_00B5:
	DC.W	$636f			;00bf0
	dc.w    $6e3a
	MOVE.W	12848(A7),D0		;00bf4: 302f3230
	DC.W	$2f36			;00bf8
	DC.W	$3430			;00bfa
	DC.W	$2f32			;00bfc
	DC.W	$3136			;00bfe
	MOVE.L	D4,25970(A7)		;00c00: 2f446572
	MOVEA.L	(A3),A0			;00c04: 2053
	DC.W	$6565			;00c06
	DC.W	$6c65			;00c08
	dc.w  $6e74
	DC.W	$7572			;00c0c
	DC.W	$6d2d			;00c0e
	DC.W	$496e			;00c10
	DC.W	$7374			;00c12
	dc.w  $616c
	DC.W	$6c61			;00c16
	MOVEQ	#105,D2			;00c18: 7469
	dc.w  $6f6e
	DC.W	$7370			;00c1c
	MOVEQ	#111,D1			;00c1e: 726f
	dc.w    $6772
	DC.W	$616d			;00c22
	DC.W	$6d00			;00c24

LAB_00B8:
	dc.l  0			;00c32: 00000000
LAB_00B9:
	dc.l  0			;00c36: 00000000
LAB_00BA:
	dc.l  0			;00c3a: 00000000
LAB_00BB:
	dc.l  0			;00c3e: 00000000
LAB_00BC:
	ORI.B	#$06,D4			;00c42: 00040006
	ORI.B	#$05,D7			;00c46: 00070005
	ORI.B	#$15,(A4)		;00c4a: 00140015
	ORI.B	#$11,(A6)		;00c4e: 00160011
	ORI.B	#$b2,(A2)		;00c52: 001200b2
	DC.W	$00b8			;00c56
	DC.W	$00ba			;00c58
	DC.W	$000b			;00c5a
	ORI.B	#$b3,(A3)		;00c5c: 001300b3
	ORI.L	#$000e0030,49(A7,D0.W)	;00c60: 00b7000e00300031
	ORI.B	#$33,52(A2,D0.W)	;00c68: 003200330034
	ORI.B	#$36,55(A5,D0.W)	;00c6e: 003500360037
	ORI.B	#$39,EXT_0001.W		;00c74: 00380039003a
	DC.W	$003b			;00c7a
	ORI.B	#$3d,CCR		;00c7c: 003c003d
LAB_00BD:
	DC.W	$003e			;00c80
LAB_00BE:
	DC.W	$003f			;00c82
	ORI.W	#$0041,D0		;00c84: 00400041
LAB_00BF:
	ORI.L	#$0092ff0e,-1(A7)	;00c88: 00af0092ff0effff
LAB_00C0:
	ORI.B	#$01,D0			;00c90: 00000001
LAB_00C1:
	ORI.B	#$03,D2			;00c94: 00020003
	ORI.B	#$05,D4			;00c98: 00040005
	ORI.B	#$07,D6			;00c9c: 00060007
LAB_00C2:
	DC.W	$0008			;00ca0
LAB_00C3:
	DC.W	$0009			;00ca2
	DC.W	$000a			;00ca4
	DC.W	$000b			;00ca6
	DC.W	$000c			;00ca8
	DC.W	$000d			;00caa
	DC.W	$000e			;00cac
	DC.W	$000f			;00cae
	ORI.B	#$11,(A0)		;00cb0: 00100011
	ORI.B	#$13,(A2)		;00cb4: 00120013
	ORI.B	#$15,(A4)		;00cb8: 00140015
	ORI.B	#$17,(A6)		;00cbc: 00160017
	ORI.B	#$19,(A0)+		;00cc0: 00180019
	ORI.B	#$1b,(A2)+		;00cc4: 001a001b
	ORI.B	#$2d,(A4)+		;00cc8: 001c002d
	ORI.B	#$2f,48(A6)		;00ccc: 002e002f0030
	ORI.B	#$32,51(A1,D0.W)	;00cd2: 003100320033
	ORI.B	#$35,54(A4,D0.W)	;00cd8: 003400350036
	ORI.B	#$38,57(A7,D0.W)	;00cde: 003700380039
	DC.W	$003a			;00ce4
	DC.W	$003b			;00ce6
	ORI.B	#$3d,CCR		;00ce8: 003c003d
	DC.W	$003e			;00cec
	DC.W	$003f			;00cee
	ORI.W	#$0041,D0		;00cf0: 00400041
	ORI.W	#$0043,D2		;00cf4: 00420043
	ORI.W	#$0045,D4		;00cf8: 00440045
	ORI.W	#$0047,D6		;00cfc: 00460047
	DC.W	$0048			;00d00
	DC.W	$0049			;00d02
	ORI.W	#$00a0,(A0)		;00d04: 005000a0
	ORI.L	#$00a200a3,-(A1)	;00d08: 00a100a200a3
	ORI.L	#$00a500a6,-(A4)	;00d0e: 00a400a500a6
	ORI.L	#$00a800a9,-(A7)	;00d14: 00a700a800a9
	ORI.L	#$00ab00ac,173(A2)	;00d1a: 00aa00ab00ac00ad
	ORI.L	#$00af00b0,177(A6)	;00d22: 00ae00af00b000b1
	ORI.L	#$00b300b4,-75(A2,D0.W)	;00d2a: 00b200b300b400b5
	ORI.L	#$00b700d7,97(A6,D0.W)	;00d32: 00b600b700d70061
	DC.W	$00e2			;00d3a
	DC.W	$00dc			;00d3c
	ORI.L	#$00de00df,D6		;00d3e: 008600de00df
	DC.W	$00e0			;00d44
	DC.W	$00e1			;00d46
	DC.W	$00c9			;00d48
	DC.W	$00ca			;00d4a
	DC.W	$00cb			;00d4c
	DC.W	$00cc			;00d4e
	DC.W	$00dd			;00d50
	DC.W	$00e5			;00d52
	DC.W	$00e6			;00d54
	DC.W	$00ec			;00d56
	DC.W	$00ed			;00d58
	DC.W	$00ee			;00d5a
	DC.W	$00ef			;00d5c
	DC.W	$00f0			;00d5e
	ORI.L	#$005100f9,(A6)+	;00d60: 009e005100f9
	DC.W	$00fa			;00d66
	DC.W	$00fb			;00d68
	DC.W	$00fc			;00d6a
	DC.W	$00e7			;00d6c
	DC.W	$00e8			;00d6e
	DC.W	$00e9			;00d70
	DC.W	$00ea			;00d72
	DC.W	$00eb			;00d74
	DC.W	$00f1			;00d76
	DC.W	$00f2			;00d78
	DC.W	$00da			;00d7a
	DC.W	$00db			;00d7c
	DC.W	$007a			;00d7e
	DC.W	$007b			;00d80
	DC.W	$007e			;00d82
	ORI.W	#$0063,-(A2)		;00d84: 00620063
	ORI.W	#$00f3,-(A4)		;00d88: 006400f3
	DC.W	$00f4			;00d8c
	DC.W	$00f5			;00d8e
	DC.W	$00f6			;00d90
	DC.W	$00f7			;00d92
	ORI.L	#$00fe009c,(A7)+	;00d94: 009f00fe009c
	ORI.L	#$00d400d5,(A5)+	;00d9a: 009d00d400d5
	DC.W	$00d6			;00da0
	DC.W	$00d8			;00da2
	DC.W	$00d9			;00da4
	ORI.W	#$006d,110(A4)		;00da6: 006c006d006e
	ORI.W	#$0070,113(A7)		;00dac: 006f00700071
	ORI.W	#$007d,115(A2,D0.W)	;00db2: 0072007d0073
	ORI.W	#$0075,118(A4,D0.W)	;00db8: 007400750076
	ORI.W	#$0078,121(A7,D0.W)	;00dbe: 007700780079
	ORI.W	#$0066,-(A5)		;00dc4: 00650066
	ORI.W	#$0068,-(A7)		;00dc8: 00670068
	ORI.W	#$006a,107(A1)		;00dcc: 0069006a006b
	ORI.W	#$ffff,SR		;00dd2: 007cffff
LAB_00C4:
	ORI.B	#$01,D0			;00dd6: 00000001
	ORI.B	#$03,D2			;00dda: 00020003
	ORI.B	#$05,D4			;00dde: 00040005
	ORI.B	#$07,D6			;00de2: 00060007
	DC.W	$0008			;00de6
	DC.W	$0009			;00de8
	DC.W	$000a			;00dea
	DC.W	$000b			;00dec
	DC.W	$000c			;00dee
	DC.W	$000d			;00df0
	DC.W	$000e			;00df2
	DC.W	$000f			;00df4
	ORI.B	#$11,(A0)		;00df6: 00100011
	ORI.B	#$13,(A2)		;00dfa: 00120013
	ORI.B	#$15,(A4)		;00dfe: 00140015
	ORI.B	#$17,(A6)		;00e02: 00160017
	ORI.B	#$19,(A0)+		;00e06: 00180019
	ORI.B	#$1b,(A2)+		;00e0a: 001a001b
	ORI.B	#$1d,(A4)+		;00e0e: 001c001d
	ORI.B	#$1f,(A6)+		;00e12: 001e001f
	ORI.B	#$21,-(A0)		;00e16: 00200021
	ORI.B	#$23,-(A2)		;00e1a: 00220023
	ORI.B	#$25,-(A4)		;00e1e: 00240025
	ORI.B	#$27,-(A6)		;00e22: 00260027
	ORI.B	#$29,42(A0)		;00e26: 00280029002a
	ORI.B	#$2c,45(A3)		;00e2c: 002b002c002d
	ORI.B	#$2f,54(A6)		;00e32: 002e002f0036
	ORI.B	#$38,57(A7,D0.W)	;00e38: 003700380039
	DC.W	$003a			;00e3e
	DC.W	$003b			;00e40
	ORI.B	#$a0,CCR		;00e42: 003c00a0
	ORI.L	#$00a200a3,-(A1)	;00e46: 00a100a200a3
	ORI.L	#$00a500a6,-(A4)	;00e4c: 00a400a500a6
	ORI.L	#$00a800a9,-(A7)	;00e52: 00a700a800a9
	ORI.L	#$00ab00ac,173(A2)	;00e58: 00aa00ab00ac00ad
	ORI.L	#$00af00b0,177(A6)	;00e60: 00ae00af00b000b1
	ORI.L	#$00b300b4,-75(A2,D0.W)	;00e68: 00b200b300b400b5
	DC.W	$00b6			;00e70
	DC.W	$00b7			;00e72
	DC.W	$ff29			;00e74
	DC.W	$ff9f			;00e76
	DC.W	$ff1e			;00e78
	DC.W	$ff24			;00e7a
	DC.W	$ff7a			;00e7c
	DC.W	$ff22			;00e7e
	DC.W	$ff21			;00e80
	DC.W	$ff20			;00e82
	DC.W	$ff1f			;00e84
	DC.W	$ff37			;00e86
	DC.W	$ff36			;00e88
	DC.W	$ff35			;00e8a
	DC.W	$ff34			;00e8c
	DC.W	$ff23			;00e8e
	DC.W	$ff1b			;00e90
	DC.W	$ff1a			;00e92
	DC.W	$ff14			;00e94
	DC.W	$ff13			;00e96
	DC.W	$ff12			;00e98
	DC.W	$ff11			;00e9a
	DC.W	$ff10			;00e9c
	DC.W	$ff62			;00e9e
	DC.W	$ffaf			;00ea0
	DC.W	$ff07			;00ea2
	DC.W	$ff06			;00ea4
	DC.W	$ff05			;00ea6
	DC.W	$ff04			;00ea8
	DC.W	$ff19			;00eaa
	DC.W	$ff18			;00eac
	DC.W	$ff17			;00eae
	DC.W	$ff16			;00eb0
	DC.W	$ff15			;00eb2
	DC.W	$ff0f			;00eb4
	DC.W	$ff0e			;00eb6
	DC.W	$ff26			;00eb8
	DC.W	$ff25			;00eba
	DC.W	$ff86			;00ebc
	DC.W	$ff85			;00ebe
	DC.W	$ff82			;00ec0
	DC.W	$ff9e			;00ec2
	DC.W	$ff9d			;00ec4
	DC.W	$ff9c			;00ec6
	DC.W	$ff0d			;00ec8
	DC.W	$ff0c			;00eca
	DC.W	$ff0b			;00ecc
	DC.W	$ff0a			;00ece
	DC.W	$ff09			;00ed0
	DC.W	$ff61			;00ed2
	DC.W	$ff02			;00ed4
	DC.W	$ff64			;00ed6
	DC.W	$ff63			;00ed8
	DC.W	$ff2c			;00eda
	DC.W	$ff2b			;00edc
	DC.W	$ff2a			;00ede
	DC.W	$ff28			;00ee0
	DC.W	$ff27			;00ee2
	DC.W	$ff94			;00ee4
	DC.W	$ff93			;00ee6
	DC.W	$ff92			;00ee8
	DC.W	$ff91			;00eea
	DC.W	$ff90			;00eec
	DC.W	$ff8f			;00eee
	DC.W	$ff8e			;00ef0
	DC.W	$ff83			;00ef2
	DC.W	$ff8d			;00ef4
	DC.W	$ff8c			;00ef6
	DC.W	$ff8b			;00ef8
	DC.W	$ff8a			;00efa
	DC.W	$ff89			;00efc
	DC.W	$ff88			;00efe
	DC.W	$ff87			;00f00
	DC.W	$ff9b			;00f02
	DC.W	$ff9a			;00f04
	DC.W	$ff99			;00f06
	DC.W	$ff98			;00f08
	DC.W	$ff97			;00f0a
	DC.W	$ff96			;00f0c
	DC.W	$ff95			;00f0e
	DC.W	$ff84			;00f10
	DC.W	$007f			;00f12
	ORI.L	#$00810082,D0		;00f14: 008000810082
	ORI.L	#$00840085,D3		;00f1a: 008300840085
	DC.W	$ffff			;00f20
LAB_00C5:
	ORI.B	#$02,D1			;00f22: 00010002
	ORI.B	#$04,D3			;00f26: 00030004
	ORI.B	#$06,D5			;00f2a: 00050006
	ORI.B	#$08,D7			;00f2e: 00070008
	DC.W	$0009			;00f32
	DC.W	$000a			;00f34
	DC.W	$000b			;00f36
	ORI.L	#$00a100a2,-(A0)	;00f38: 00a000a100a2
	ORI.L	#$00a400a5,-(A3)	;00f3e: 00a300a400a5
	ORI.L	#$00a700a8,-(A6)	;00f44: 00a600a700a8
	ORI.L	#$00aa00ab,172(A1)	;00f4a: 00a900aa00ab00ac
	ORI.L	#$00ae00af,176(A5)	;00f52: 00ad00ae00af00b0
	DC.W	$00b1			;00f5a
	DC.W	$ff29			;00f5c
	DC.W	$ff9f			;00f5e
	DC.W	$ff1e			;00f60
	DC.W	$ff24			;00f62
	DC.W	$ff7a			;00f64
	DC.W	$ff22			;00f66
	DC.W	$ff21			;00f68
	DC.W	$ff20			;00f6a
	DC.W	$ff1f			;00f6c
	DC.W	$ff37			;00f6e
	DC.W	$ff36			;00f70
	DC.W	$ff35			;00f72
	DC.W	$ff34			;00f74
	DC.W	$ff23			;00f76
	DC.W	$ff1b			;00f78
	DC.W	$ff1a			;00f7a
	DC.W	$ff14			;00f7c
	DC.W	$ff13			;00f7e
	DC.W	$ff12			;00f80
	DC.W	$ff11			;00f82
	DC.W	$ff10			;00f84
	DC.W	$ff62			;00f86
	DC.W	$ffaf			;00f88
	DC.W	$ff07			;00f8a
	DC.W	$ff06			;00f8c
	DC.W	$ff05			;00f8e
	DC.W	$ff04			;00f90
	DC.W	$ff19			;00f92
	DC.W	$ff18			;00f94
	DC.W	$ff17			;00f96
	DC.W	$ff16			;00f98
	DC.W	$ff15			;00f9a
	DC.W	$ff0f			;00f9c
	DC.W	$ff0e			;00f9e
	DC.W	$ff26			;00fa0
	DC.W	$ff25			;00fa2
	DC.W	$ff86			;00fa4
	DC.W	$ff85			;00fa6
	DC.W	$ff82			;00fa8
	DC.W	$ff9e			;00faa
	DC.W	$ff9d			;00fac
	DC.W	$ff9c			;00fae
	DC.W	$ff0d			;00fb0
	DC.W	$ff0c			;00fb2
	DC.W	$ff0b			;00fb4
	DC.W	$ff0a			;00fb6
	DC.W	$ff09			;00fb8
	DC.W	$ff61			;00fba
	DC.W	$ff02			;00fbc
	DC.W	$ff64			;00fbe
	DC.W	$ff63			;00fc0
	DC.W	$ff2c			;00fc2
	DC.W	$ff2b			;00fc4
	DC.W	$ff2a			;00fc6
	DC.W	$ff28			;00fc8
	DC.W	$ff27			;00fca
	DC.W	$ff94			;00fcc
	DC.W	$ff93			;00fce
	DC.W	$ff92			;00fd0
	DC.W	$ff91			;00fd2
	DC.W	$ff90			;00fd4
	DC.W	$ff8f			;00fd6
	DC.W	$ff8e			;00fd8
	DC.W	$ff83			;00fda
	DC.W	$ff8d			;00fdc
	DC.W	$ff8c			;00fde
	DC.W	$ff8b			;00fe0
	DC.W	$ff8a			;00fe2
	DC.W	$ff89			;00fe4
	DC.W	$ff88			;00fe6
	DC.W	$ff87			;00fe8
	DC.W	$ff9b			;00fea
	DC.W	$ff9a			;00fec
	DC.W	$ff99			;00fee
	DC.W	$ff98			;00ff0
	DC.W	$ff97			;00ff2
	DC.W	$ff96			;00ff4
	DC.W	$ff95			;00ff6
	DC.W	$ff84			;00ff8
	DC.W	$00e3			;00ffa
	ORI.B	#$21,-(A0)		;00ffc: 00200021
	DC.W	$ffff			;01000
LAB_00C6:
	DC.W	$00e0			;01002
	DC.W	$00e1			;01004
	DC.W	$00e2			;01006
	ORI.B	#$02,D1			;01008: 00010002
	ORI.B	#$04,D3			;0100c: 00030004
	ORI.B	#$06,D5			;01010: 00050006
	ORI.B	#$08,D7			;01014: 00070008
	ORI.L	#$00b40060,16(A6,D0.W)	;01018: 00b600b400600010
	ORI.L	#$0091ffff,(A0)		;01020: 00900091ffff
LAB_00C7:
	SUBQ.W	#1,EXT_0006		;01026: 53796e746178
	DC.W	$6665			;0102c
	dc.w  $686c
	dc.w  $6572
	MOVEP	0(A2),D6		;01032: 0d0a0000
LAB_00C8:
	MOVEP	19557(A2),D6		;01036: 0d0a4c65
	DC.W	$6765			;0103a
	dc.w  $6e20
	SUBQ.W	#1,25888(A1)		;0103e: 53696520
	DC.W	$6469			;01042
	dc.w  $6520
	NEG.W	-(A5)			;01046: 4465
	MOVEQ	#32,D1			;01048: 7220
	SUBQ.W	#1,-(A5)		;0104a: 5365
	dc.w    $656c
	dc.w    $656e
	MOVEQ	#117,D2			;01050: 7475
	MOVEQ	#109,D1			;01052: 726d
	MOVEA.L	D4,A0			;01054: 2044
	DC.W	$6973			;01056
	dc.w    $6b20
LAB_00C9:
	MOVEQ	#32,D4			;0105a: 7820
	dc.w  $696e
LAB_00CA:
	MOVEA.L	-(A5),A0		;0105e: 2065
	dc.w  $696e
	MOVEA.L	A4,A0			;01062: 204c
	DC.W	$6175			;01064
LAB_00CB:
	DC.W	$6677			;01066
	dc.w  $6572
	dc.w  $6b20
	DC.W	$756e			;0106c
	dc.w  $6420
	dc.w  $6472
	DC.W	$7563			;01072
	DC.W	$6b65			;01074
	dc.w  $6e20
LAB_00CC:
	SUBQ.W	#1,25888(A1)		;01078: 53696520
	DC.W	$456e			;0107c
	MOVEQ	#101,D2			;0107e: 7465
	MOVEQ	#46,D1			;01080: 722e
	MOVEP	0(A2),D6		;01082: 0d0a0000
	DC.W	$4b6f			;01086
	MOVEQ	#105,D0			;01088: 7069
	dc.w  $6572
LAB_00CD:
	dc.w    $6520
	NEG.W	-(A1)			;0108e: 4461
LAB_00CE:
	MOVEQ	#101,D2			;01090: 7465
	DC.W	$6965			;01092
	dc.w    $6e20
	MOVEQ	#111,D3			;01096: 766f
LAB_00CF:
	dc.w    $6e20
	DC.W	$6465			;0109a
LAB_00D0:
	MOVEQ	#32,D1			;0109c: 7220
	NEG.W	29547(A1)		;0109e: 4469736b
	dc.w  $6574
LAB_00D1:
	MOVEQ	#101,D2			;010a4: 7465
	MOVEP	0(A2),D6		;010a6: 0d0a0000
data_file_name:
	dc.b    "Der Seelenturm Disk "
disknumber:
	dc.b    "x:data",0
xxx_data_name:
	dc.b    "xxx",0
    even
LAB_00D8:
	dc.w $5365
LAB_00D9:
	dc.w    $656c
	dc.w    $656e
LAB_00DA:
	MOVEQ	#117,D2			;010d0: 7475
	MOVEQ	#109,D1			;010d2: 726d
	DC.W	$0000			;010d4
LAB_00DB:
	SUBQ.W	#1,-(A5)		;010d6: 5365
	dc.w    $656c
	dc.w    $656e
LAB_00DC:
	MOVEQ	#117,D2			;010dc: 7475
LAB_00DD:
	MOVEQ	#109,D1			;010de: 726d
	MOVEA.L	28262(A1),A7		;010e0: 2e696e66
LAB_00DE:
	DC.W	$6f00			;010e4
iconfilename:
	DC.W	$5475			;010e6
	MOVEQ	#109,D1			;010e8: 726d
	MOVEA.L	28262(A1),A7		;010ea: 2e696e66
	DC.W	$6f00			;010ee
	dc.w    $696e
	DC.W	$666f			;010f2
	DC.W	$0000			;010f4
	DC.W	$4c65			;010f6
	DC.W	$7365			;010f8
	MOVE.L	D0,D0			;010fa: 2000
	MOVEA.L	D2,A0			;010fc: 2042
LAB_00E0:
	DC.W	$7974			;010fe
	DC.W	$6573			;01100
	MOVE.L	11808(A6),D7		;01102: 2e2e2e20
	DC.W	$0000			;01106
	SUBQ.W	#1,25448(A1)		;01108: 53696368
	dc.w    $6572
	dc.w    $6520
	DC.W	$0000			;01110
	DC.W	$5370			;01112
	DC.W	$6569			;01114
	dc.w    $6368
LAB_00E1:
	dc.w    $6572
	dc.w    $6520
	DC.W	$6675			;0111c
LAB_00E2:
	MOVEQ	#32,D1			;0111e: 7220
	DC.W	$7370			;01120
LAB_00E3:
	ROXL.W	D2,D4			;01122: e574
	dc.w    $6572
	MOVE.L	A5,D0			;01126: 200d
	DC.W	$0a00			;01128
LAB_00E4:
	MOVEP	19311(A2),D6		;0112a: 0d0a4b6f
	MOVEQ	#105,D0			;0112e: 7069
LAB_00E5:
	dc.w    $6572
	dc.w    $6520
	NEG.W	-(A1)			;01134: 4461
	MOVEQ	#101,D2			;01136: 7465
	DC.W	$6965			;01138
LAB_00E6:
	dc.w    $6e20
LAB_00E7:
	MOVEQ	#111,D3			;0113c: 766f
LAB_00E8:
	dc.w    $6e20
	DC.W	$6465			;01140
	MOVEQ	#32,D1			;01142: 7220
LAB_00E9:
	NEG.W	29547(A1)		;01144: 4469736b
	dc.w    $6574
LAB_00EA:
	MOVEQ	#101,D2			;0114a: 7465
	MOVEP	0(A2),D6		;0114c: 0d0a0000
	DC.W	$4572			;01150
	DC.W	$7374			;01152
LAB_00EB:
	dc.w    $656c
	DC.W	$6c65			;01156
	MOVEA.L	(A6),A0			;01158: 2056
	dc.w  $6572
LAB_00EC:
	MOVEQ	#101,D5			;0115c: 7a65
	DC.W	$6963			;0115e
LAB_00ED:
	dc.w  $686e
	DC.W	$6973			;01162
	MOVE.L	-(A7),D0		;01164: 2027
	DC.W	$5475			;01166
	MOVEQ	#109,D1			;01168: 726d
	MOVE.L	A5,-(A3)		;0116a: 270d
	DC.W	$0a00			;0116c
	ADDQ.W	#3,-(A5)		;0116e: 5665
	MOVEQ	#122,D1			;01170: 727a
	DC.W	$6569			;01172
	dc.w  $6368
	DC.W	$6e69			;01176
	DC.W	$7320			;01178
	MOVE.L	(A4),30066(A3)		;0117a: 27547572
	DC.W	$6d27			;0117e
LAB_00EE:
	MOVEA.L	-(A7),A0		;01180: 2067
	dc.w  $6566
	DC.W	$756e			;01184
	DC.W	$6465			;01186
	DC.W	$6e0d			;01188
	DC.W	$0a00			;0118a
LAB_00EF:
	SUBQ.W	#2,-(A2)		;0118c: 5562
	dc.w  $6572
	DC.W	$7370			;01190
	MOVEQ	#105,D1			;01192: 7269
	DC.W	$6e67			;01194
	dc.w  $6520
LAB_00F0:
	MOVEP	0(A2),D6		;01198: 0d0a0000
	SUBQ.W	#1,-(A3)		;0119c: 5363
	dc.w  $616e
	DC.W	$6e65			;011a0
	MOVEA.L	(A6),A0			;011a2: 2056
LAB_00F1:
	dc.w  $6572
	MOVEQ	#101,D5			;011a6: 7a65
	DC.W	$6963			;011a8
	dc.w  $686e
	DC.W	$6973			;011ac
	MOVEP	0(A2),D6		;011ae: 0d0a0000
LAB_00F2:
	MOVEP	20270(A2),D6		;011b2: 0d0a4f2e
	DC.W	$4b2e			;011b6
LAB_00F3:
	MOVEA.L	A1,A0			;011b8: 2049
	DC.W	$6e73			;011ba
	MOVEQ	#97,D2			;011bc: 7461
LAB_00F4:
	dc.w  $6c6c
	dc.w  $6174
LAB_00F5:
	DC.W	$696f			;011c2
	dc.w  $6e20
	dc.w  $6162
	DC.W	$6765			;011c8
	DC.W	$7363			;011ca
	dc.w  $686c
LAB_00F6:
	DC.W	$6f73			;011ce
LAB_00F7:
	DC.W	$7365			;011d0
	dc.w  $6e2e
	MOVEP	3338(A2),D6		;011d4: 0d0a0d0a
	DC.W	$5a75			;011d8
	dc.w  $6d20
	DC.W	$5374			;011dc
LAB_00F8:
	dc.w  $6172
	MOVEQ	#101,D2			;011e0: 7465
	dc.w  $6e20
	DC.W	$6465			;011e4
LAB_00F9:
	DC.W	$7320			;011e6
	DC.W	$496e			;011e8
LAB_00FA:
	DC.W	$7374			;011ea
	dc.w  $616c
	DC.W	$6c69			;011ee
	dc.w  $6572
	MOVEQ	#101,D2			;011f2: 7465
	dc.w  $6e20
	DC.W	$5370			;011f6
	DC.W	$6965			;011f8
	DC.W	$6c73			;011fa
LAB_00FB:
	MOVEA.L	-(A1),A0		;011fc: 2061
	DC.W	$7566			;011fe
	MOVEA.L	(A2),A0			;01200: 2052
LAB_00FC:
	DC.W	$6563			;01202
LAB_00FD:
	dc.w  $686e
	DC.W	$656d			;01206
	MOVEP	28009(A2),D6		;01208: 0d0a6d69
	MOVEQ	#32,D2			;0120c: 7420
LAB_00FE:
	DC.W	$6e75			;0120e
	MOVEQ	#32,D1			;01210: 7220
	MOVE.W	-(A0),D1		;01212: 3220
	DC.W	$4d42			;01214
LAB_00FF:
	MOVEA.L	(A2),A0			;01216: 2052
LAB_0100:
	DC.W	$616d			;01218
LAB_0101:
	MOVE.L	31278(A0),D0		;0121a: 20287a2e
	CLR.B	8275(A6)		;0121e: 422e2053
	MOVEQ	#97,D2			;01222: 7461
	dc.w  $6e64
	dc.w  $6172
	dc.w  $6420
LAB_0102:
	DC.W	$4131			;0122a
LAB_0103:
	MOVE.W	41(A0,D3.W),D1		;0122c: 32303029
	MOVE.L	-(A0),D6		;01230: 2c20
	DC.W	$6265			;01232
	DC.W	$6c61			;01234
LAB_0104:
	DC.W	$7373			;01236
	dc.w  $656e
LAB_0105:
	MOVEP	21353(A2),D6		;0123a: 0d0a5369
	dc.w  $6520
	DC.W	$6269			;01240
	MOVEQ	#116,D2			;01242: 7474
	dc.w  $6520
	NEG.W	29547(A1)		;01246: 4469736b
LAB_0106:
	dc.w  $6574
	MOVEQ	#101,D2			;0124c: 7465
	MOVE.L	105(A5,D2.W),D0		;0124e: 20352069
LAB_0107:
	dc.w  $6e20
	DC.W	$6569			;01254
	DC.W	$6e65			;01256
	dc.w  $6d20
LAB_0108:
	DC.W	$4c61			;0125a
	DC.W	$7566			;0125c
	DC.W	$7765			;0125e
LAB_0109:
	MOVEQ	#107,D1			;01260: 726b
	DC.W	$2075			;01262
LAB_010A:
	dc.w  $6e64
LAB_010B:
	MOVEP	29556(A2),D6		;01266: 0d0a7374
	dc.w  $6172
	MOVEQ	#101,D2			;0126c: 7465
	dc.w  $6e20
	DC.W	$6461			;01270
	DC.W	$7320			;01272
LAB_010C:
	DC.W	$5379			;01274
	DC.W	$7374			;01276
	DC.W	$656d			;01278
LAB_010D:
	MOVEA.L	25973(A6),A0		;0127a: 206e6575
	MOVE.L	A5,D7			;0127e: 2e0d
	DC.W	$0a0d			;01280
	DC.W	$0a48			;01282
	dc.w  $6162
	dc.w  $656e
	MOVEA.L	(A3),A0			;01288: 2053
LAB_010E:
	DC.W	$6965			;0128a
	MOVEA.L	25960(A5),A0		;0128c: 206d6568
LAB_010F:
	MOVEQ	#32,D1			;01290: 7220
	dc.w  $616c
	DC.W	$7320			;01294
	MOVE.W	-(A0),D1		;01296: 3220
	DC.W	$4d42			;01298
LAB_0110:
	MOVE.L	-(A0),D6		;0129a: 2c20
	dc.w  $6b6c
	DC.W	$6963			;0129e
	DC.W	$6b65			;012a0
	dc.w  $6e20
	SUBQ.W	#1,25888(A1)		;012a4: 53696520
LAB_0111:
	DC.W	$6569			;012a8
	dc.w  $6e66
	DC.W	$6163			;012ac
	dc.w  $6820
	DC.W	$6175			;012b0
	DC.W	$660d			;012b2
	EORI.W	#$6173,-(A4)		;012b4: 0a646173
	MOVE.L	-(A7),D0		;012b8: 2027
	SUBQ.W	#1,-(A5)		;012ba: 5365
	dc.w  $656c
	dc.w  $656e
LAB_0112:
	MOVEQ	#117,D2			;012c0: 7475
	MOVEQ	#109,D1			;012c2: 726d
LAB_0113:
	MOVE.L	21369(A5),-(A3)		;012c4: 272d5379
	dc.w  $6d62
LAB_0114:
	dc.w  $6f6c
	MOVEA.L	28192(A1),A0		;012cc: 20696e20
LAB_0115:
	DC.W	$6465			;012d0
	dc.w  $6d20
	dc.w  $656e
	MOVEQ	#115,D2			;012d6: 7473
	MOVEQ	#114,D0			;012d8: 7072
	DC.W	$6563			;012da
	DC.W	$6865			;012dc
LAB_0116:
	dc.w  $6e64
	dc.w  $656e
	MOVEP	20338(A2),D6		;012e2: 0d0a4f72
	dc.w  $646e
LAB_0117:
	dc.w  $6572
	MOVEA.L	-(A1),A0		;012ea: 2061
	DC.W	$7566			;012ec
	MOVEA.L	A1,A0			;012ee: 2049
	dc.w  $6872
	dc.w  $6572
LAB_0118:
	MOVEA.L	D6,A0			;012f4: 2046
LAB_0119:
	DC.W	$6573			;012f6
	MOVEQ	#112,D2			;012f8: 7470
	DC.W	$6c61			;012fa
	MOVEQ	#116,D2			;012fc: 7474
	dc.w  $652e
LAB_011A:
	MOVEP	3338(A2),D6		;01300: 0d0a0d0a
	DC.W	$0000			;01304
LAB_011B:
	NOT.W	-(A5)			;01306: 4665
	dc.w  $686c
LAB_011C:
	dc.w  $6572
	DC.W	$2077			;0130c
	LSL.W	D2,D0			;0130e: e568
	MOVEQ	#101,D1			;01310: 7265
LAB_011D:
	dc.w  $6e64
	MOVEA.L	-(A4),A0		;01314: 2064
	dc.w  $6572
	MOVEA.L	A1,A0			;01318: 2049
	DC.W	$6e73			;0131a
	MOVEQ	#97,D2			;0131c: 7461
	dc.w  $6c6c
	dc.w    $6174
	DC.W	$696f			;01322
	dc.w  $6e2e
	MOVEA.L	(A6),A0			;01326: 2056
	dc.w  $6572
LAB_011E:
	DC.W	$7375			;0132a
LAB_011F:
	dc.w  $6368
LAB_0120:
	dc.w  $656e
	MOVEA.L	(A3),A0			;01330: 2053
	DC.W	$6965			;01332
	MOVEA.L	-(A5),A0		;01334: 2065
	DC.W	$7320			;01336
LAB_0121:
	DC.W	$6e6f			;01338
	dc.w  $6368
	DC.W	$6d61			;0133c
	dc.w  $6c2e
	MOVEP	0(A2),D6		;01340: 0d0a0000
LAB_0122:
	NEG.W	-(A5)			;01344: 4465
	DC.W	$6b6f			;01346
	dc.w  $6d70
	MOVEQ	#105,D1			;0134a: 7269
	DC.W	$6d69			;0134c
	dc.w  $6572
LAB_0123:
	dc.w  $652e
LAB_0124:
	MOVE.L	8192(A6),D7		;01352: 2e2e2000
hex_table:
	DC.W	$3031			;01356
	DC.W	$3233			;01358
	DC.W	$3435			;0135a
LAB_0126:
	dc.l    $36373839
    dc.w    $6162
	dc.w  $6364
LAB_0127:
	dc.w  $6566
LAB_0128:
	DC.W	$0000			;01366
LAB_0129:
	BTST	#6,CIAA_PRA		;01368: 0839000600bfe001
	BNE.W	LAB_0129		;01370: 6600fff6
	RTS				;01374: 4e75
LAB_012B:
	dc.l  0			;01376: 00000000
LAB_012D:
	dc.l  0			;0137a: 00000000
LAB_012E:
	dc.l  0			;0137e: 00000000
LAB_0130:
	MOVE.L	A1,LAB_012E		;01382: 23c90000137e
LAB_0131:
	MOVE.W	D0,LAB_012B		;01388: 33c000001376
	ADDI.B	#$30,D0			;0138e: 06000030
LAB_0133:
	MOVE.B	D0,LAB_00C9		;01392: 13c00000105a
LAB_0134:
	MOVE.B	D0,disknumber		;01398: 13c0000010be
LAB_0135:
	LEA	LAB_00C8,A0		;0139e: 41f900001036
LAB_0136:
	BSR.W	write_message		;013a4: 6100060a
	LEA	LAB_005F,A0		;013a8: 41f900000412
	BSR.W	write_message		;013ae: 61000600

LAB_0137:
	MOVE.L	#LAB_0191,D2		;013b8: 243c0006b428
LAB_0138:
	MOVE.L	#$00000100,D3		;013be: 263c00000100
LAB_0139:
	MOVEA.L	DosBase,A6		;013c4: 2c790000174e
LAB_013B:
	CLR.L	LAB_014C		;013d4: 42b9000015ba
	MOVE.L	#data_file_name,D1		;013da: 223c000010aa
	BSR.W	open_data_file		;013e0: 61000184
	BNE.W	LAB_0147		;013e4: 6600016e
	MOVE.L	#$00000406,D3		;013e8: 263c00000406
	MOVE.L	#SECSTRT_2,D2		;013ee: 243c000635dc
	BSR.W	LAB_014F		;013f4: 610001d4
	TST.L	D0			;013f8: 4a80
	BMI.W	LAB_0147		;013fa: 6b000158
	LEA	LAB_00E4,A0		;013fe: 41f90000112a
	BSR.W	write_message		;01404: 610005aa
LAB_013C:
	MOVEA.L	LAB_012E,A1		;01408: 22790000137e
	MOVE.W	(A1)+,D0		;0140e: 3019
	CMP.W	#$ffff,D0		;01410: b07cffff
	BEQ.W	LAB_0146		;01414: 67000136
	MOVE.W	D0,LAB_012B+2		;01418: 33c000001378
	MOVE.L	A1,LAB_012E		;0141e: 23c90000137e
	TST.W	D0			;01424: 4a40
	BPL.S	LAB_013D		;01426: 6a02
	NEG.W	D0			;01428: 4440
LAB_013D:
	LEA	SECSTRT_2,A0		;0142a: 41f9000635dc
LAB_013E:
	CMP.B	0(A0),D0		;01430: b0280000
	BNE.S	LAB_013F		;01434: 660c
	MOVE.L	0(A0),D3		;01436: 26280000
	ANDI.L	#$00ffffff,D3		;0143a: 028300ffffff
	BRA.S	LAB_0140		;01440: 6006
LAB_013F:
	ADDQ.L	#4,A0			;01442: 5888
	BRA.W	LAB_013E		;01444: 6000ffea
LAB_0140:
	MOVE.L	D3,LAB_012D		;01448: 23c30000137a
	MOVE.L	#SECSTRT_1,D2		;0144e: 243c00001b5c
	BSR.W	LAB_014F		;01454: 61000174
	TST.L	D0			;01458: 4a80
	BMI.W	LAB_0147		;0145a: 6b0000f8
	TST.W	LAB_012B+2		;0145e: 4a7900001378
	BMI.W	LAB_0145		;01464: 6b0000e2
	LEA	xxx_data_name,A0		;01468: 41f9000010c6
	LEA	hex_table,A1		;0146e: 43f900001356
	MOVE.W	LAB_012B,D0		;01474: 303900001376
	MOVE.B	0(A1,D0.W),(A0)		;0147a: 10b10000
	MOVE.W	LAB_012B+2,D0		;0147e: 303900001378
	ANDI.W	#$00f0,D0		;01484: 024000f0
	LSR.W	#4,D0			;01488: e848
	MOVE.B	0(A1,D0.W),1(A0)	;0148a: 117100000001
	MOVE.W	LAB_012B+2,D0		;01490: 303900001378
	ANDI.W	#$000f,D0		;01496: 0240000f
	MOVE.B	0(A1,D0.W),2(A0)	;0149a: 117100000002
	CMPI.W	#$0090,LAB_012B+2	;014a0: 0c79009000001378
	BEQ.W	LAB_0141		;014a8: 67000038
	CMPI.W	#$0091,LAB_012B+2	;014ac: 0c79009100001378
	BEQ.W	LAB_0143		;014b4: 67000068
	CMPI.W	#$0092,LAB_012B+2	;014b8: 0c79009200001378
	BEQ.W	LAB_0142		;014c0: 6700003e
	MOVE.L	#SECSTRT_1,D0		;014c4: 203c00001b5c
	MOVE.L	LAB_012D,D1		;014ca: 22390000137a
	MOVE.L	#xxx_data_name,D2		;014d0: 243c000010c6
	BSR.W	write_whole_file		;014d6: 61000398
	BNE.W	LAB_0147		;014da: 66000078
	BRA.W	LAB_0145		;014de: 60000068
LAB_0141:
	MOVE.L	#SECSTRT_1,D0		;014e2: 203c00001b5c
	MOVE.L	LAB_012D,D1		;014e8: 22390000137a
	MOVE.L	#LAB_00D8,D2		;014ee: 243c000010ca
	BSR.W	write_whole_file		;014f4: 6100037a
	BNE.W	LAB_0147		;014f8: 6600005a
	BRA.W	LAB_0145		;014fc: 6000004a
LAB_0142:
	MOVE.L	#SECSTRT_1,D0		;01500: 203c00001b5c
	MOVE.L	LAB_012D,D1		;01506: 22390000137a
	MOVE.L	#LAB_00DB,D2		;0150c: 243c000010d6
	BSR.W	write_whole_file		;01512: 6100035c
	BNE.W	LAB_0147		;01516: 6600003c
	BRA.W	LAB_0145		;0151a: 6000002c
LAB_0143:
	MOVEA.L	#SECSTRT_1,A0		;0151e: 207c00001b5c
	MOVE.L	LAB_012D,D1		;01524: 22390000137a
	MOVE.L	D1,LAB_0148		;0152a: 23c100001562
	MOVEA.L	#LAB_018E,A1		;01530: 227c00069e80
	MOVE.L	LAB_0148,D7		;01536: 2e3900001562
LAB_0144:
	MOVE.B	(A0)+,(A1)+		;0153c: 12d8
	SUBQ.L	#1,D7			;0153e: 5387
	BNE.W	LAB_0144		;01540: 6600fffa
	BRA.W	LAB_0145		;01544: 60000002
LAB_0145:
	BRA.W	LAB_013C		;01548: 6000febe
LAB_0146:
	BSR.W	LAB_0158		;0154c: 6100014c
	MOVEQ	#0,D0			;01550: 7000
	RTS				;01552: 4e75
LAB_0147:
	LEA	LAB_017A,A0		;01554: 41f900001a2a
	BSR.W	write_message		;0155a: 61000454
	MOVEQ	#-1,D0			;0155e: 70ff
	RTS				;01560: 4e75
LAB_0148:
	dc.l  0			;01562: 00000000
open_data_file:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;01566: 48e7fffe
	MOVE.L	#MODE_OLDFILE,D2		;0156a: 243c000003ed
	MOVEA.L	DosBase,A6		;01570: 2c790000174e
	JSR	(_LVOOpen,A6)	;01576: 4eaeffe2 dos.library (off=-30)
	CMP.L	#$00000000,D0		;0157a: b0bc00000000
	BEQ.W	LAB_014A		;01580: 67000014
	MOVE.L	D0,LAB_014B		;01584: 23c0000015b6
	MOVEM.L	(A7)+,D0-D7/A0-A6	;0158a: 4cdf7fff
	MOVE.L	#$00000000,D0		;0158e: 203c00000000
	RTS				;01594: 4e75
LAB_014A:
	LEA	LAB_017A,A0		;01596: 41f900001a2a
	BSR.W	write_message		;0159c: 61000412
	MOVEA.L	#LAB_0176,A0		;015a0: 207c00001a02
	BSR.W	write_message		;015a6: 61000408
	MOVEM.L	(A7)+,D0-D7/A0-A6	;015aa: 4cdf7fff
	MOVE.L	#$ffffffff,D0		;015ae: 203cffffffff
	RTS				;015b4: 4e75
LAB_014B:
	dc.l  0			;015b6: 00000000
LAB_014C:
	dc.l  0			;015ba: 00000000
	dc.l  0			;015be: 00000000
LAB_014D:
	dc.l  0			;015c2: 00000000
LAB_014E:
	dc.l  0			;015c6: 00000000
LAB_014F:
	MOVEM.L	D3/A0,-(A7)		;015ca: 48e71080
	MOVE.L	D2,LAB_014D		;015ce: 23c2000015c2
	MOVE.L	LAB_014C,D1		;015d4: 2239000015ba
	MOVEQ	#0,D5			;015da: 7a00
	MOVE.L	D3,D4			;015dc: 2803
LAB_0150:
	TST.L	D4			;015de: 4a84
	BEQ.S	LAB_0152		;015e0: 6716
	MOVE.L	D1,D0			;015e2: 2001
	DIVU	#$01e8,D0		;015e4: 80fc01e8
	SWAP	D0			;015e8: 4840
	CMP.W	#$01e6,D0		;015ea: b07c01e6
	BEQ.S	LAB_0151		;015ee: 6702
	SUBQ.L	#2,D4			;015f0: 5584
LAB_0151:
	ADDQ.L	#2,D5			;015f2: 5485
	ADDQ.L	#2,D1			;015f4: 5481
	BRA.S	LAB_0150		;015f6: 60e6
LAB_0152:
	MOVE.L	D5,LAB_014E		;015f8: 23c5000015c6
	MOVE.L	LAB_014E,D3		;015fe: 2639000015c6
	MOVE.L	LAB_014D,D2		;01604: 2439000015c2
	BSR.W	LAB_0157		;0160a: 6100005a
	CMP.L	LAB_014E,D0		;0160e: b0b9000015c6
	BNE.W	LAB_0156		;01614: 66000048
	MOVEA.L	LAB_014D,A0		;01618: 2079000015c2
	MOVEA.L	LAB_014D,A1		;0161e: 2279000015c2
	MOVE.L	LAB_014C,D1		;01624: 2239000015ba
	MOVEQ	#0,D5			;0162a: 7a00
	MOVE.L	D3,D4			;0162c: 2803
LAB_0153:
	TST.L	D4			;0162e: 4a84
	BEQ.S	LAB_0155		;01630: 6718
	MOVE.W	(A0)+,D6		;01632: 3c18
	MOVE.L	D1,D0			;01634: 2001
	DIVU	#$01e8,D0		;01636: 80fc01e8
	SWAP	D0			;0163a: 4840
	CMP.W	#$01e6,D0		;0163c: b07c01e6
	BEQ.S	LAB_0154		;01640: 6702
	MOVE.W	D6,(A1)+		;01642: 32c6
LAB_0154:
	ADDQ.L	#2,D1			;01644: 5481
	SUBQ.L	#2,D4			;01646: 5584
	BRA.S	LAB_0153		;01648: 60e4
LAB_0155:
	MOVE.L	LAB_014E,D0		;0164a: 2039000015c6
	ADD.L	D0,LAB_014C		;01650: d1b9000015ba
	MOVEM.L	(A7)+,D3/A0		;01656: 4cdf0108
	MOVEQ	#0,D0			;0165a: 7000
	RTS				;0165c: 4e75
LAB_0156:
	MOVEM.L	(A7)+,D3/A0		;0165e: 4cdf0108
	MOVEQ	#-1,D0			;01662: 70ff
	RTS				;01664: 4e75
LAB_0157:
	MOVEM.L	D1-D7/A0-A6,-(A7)	;01666: 48e77ffe
	MOVE.L	LAB_014B,D1		;0166a: 2239000015b6
	MOVEA.L	DosBase,A6		;01670: 2c790000174e
	JSR	(_LVORead,A6)	;01676: 4eaeffd6 dos.library (off=-42)
	MOVEM.L	(A7)+,D1-D7/A0-A6	;0167a: 4cdf7ffe
	RTS				;0167e: 4e75
LAB_0158:
	MOVEM.L	D1-D7/A0-A6,-(A7)	;0169a: 48e77ffe
	MOVE.L	LAB_014B,D1		;0169e: 2239000015b6
	MOVEA.L	DosBase,A6		;016a4: 2c790000174e
	JSR	(_LVOClose,A6)	;016aa: 4eaeffdc dos.library (off=-36)
	MOVE.L	LAB_015E+2,D7		;016ae: 2e3900001746
	MOVEM.L	(A7)+,D1-D7/A0-A6	;016b4: 4cdf7ffe
	RTS				;016b8: 4e75
	MOVE.L	D0,LAB_015C		;016ba: 23c000001720
	MOVEM.L	D0/A0,-(A7)		;016c0: 48e78080
LAB_0159:
	TST.W	D0			;016c4: 4a40
	BEQ.S	LAB_015B		;016c6: 6716
	CMPI.B	#$41,(A0)		;016c8: 0c100041
	BMI.S	LAB_015A		;016cc: 6b0a
	CMPI.B	#$5b,(A0)		;016ce: 0c10005b
	BPL.S	LAB_015A		;016d2: 6a04
	SUBI.B	#$e0,(A0)		;016d4: 041000e0
LAB_015A:
	SUBQ.W	#1,D0			;016d8: 5340
	ADDQ.W	#1,A0			;016da: 5248
	BRA.S	LAB_0159		;016dc: 60e6
LAB_015B:
	MOVEM.L	(A7)+,D0/A0		;016de: 4cdf0101
	MOVEM.L	D0-D7/A0-A6,-(A7)	;016e2: 48e7fffe
	MOVEQ	#0,D0			;016e6: 7000
	MOVEA.L	#DosName,A1		;016e8: 227c00000c26
	MOVEA.L	ExecBase,A6		;016ee: 2c7900000004
	JSR	(_LVOOldOpenLibrary,A6)	;016f4: 4eaefe68 exec.library (off=-408)
	MOVE.L	D0,DosBase		;016f8: 23c00000174e
    ; no need for graphics library
	MOVEM.L	(A7)+,D0-D7/A0-A6	;0171a: 4cdf7fff
	RTS				;0171e: 4e75
LAB_015C:
	dc.l  0			;01720: 00000000
LAB_015D:
	dc.l  0			;01724: 00000000
	dc.l  0			;01728: 00000000
	dc.l  0			;0172c: 00000000
	dc.l  0			;01730: 00000000
	dc.l  0			;01734: 00000000
	dc.l  0			;01738: 00000000
	dc.l  0			;0173c: 00000000
	dc.l  0			;01740: 00000000
LAB_015E:
	dc.l  0			;01744: 00000000
LAB_015F:
	dc.l  0			;01748: 00000000
LAB_0160:
	dc.l  0			;0174c: 00000000
LAB_0161:
	dc.l  0			;01750: 00000000
	DC.W	$0000			;01754
    cnop    0,4
fileinfoblock
    dc.w    0
LAB_0164:
	dc.l  0			;0176a: 00000000
	dc.l  0			;0176e: 00000000
	dc.l  0			;01772: 00000000
	dc.l  0			;01776: 00000000
	dc.l  0			;0177a: 00000000
	dc.l  0			;0177e: 00000000
	dc.l  0			;01782: 00000000
	dc.l  0			;01786: 00000000
	dc.l  0			;0178a: 00000000
	dc.l  0			;0178e: 00000000
	dc.l  0			;01792: 00000000
	dc.l  0			;01796: 00000000
	dc.l  0			;0179a: 00000000
	dc.l  0			;0179e: 00000000
	dc.l  0			;017a2: 00000000
	dc.l  0			;017a6: 00000000
	dc.l  0			;017aa: 00000000
	dc.l  0			;017ae: 00000000
	dc.l  0			;017b2: 00000000
	dc.l  0			;017b6: 00000000
	dc.l  0			;017ba: 00000000
	dc.l  0			;017be: 00000000
	dc.l  0			;017c2: 00000000
	dc.l  0			;017c6: 00000000
LAB_0165:
	dc.l  0			;017ca: 00000000
	dc.l  0			;017ce: 00000000
	dc.l  0			;017d2: 00000000
	dc.l  0			;017d6: 00000000
	dc.l  0			;017da: 00000000
	dc.l  0			;017de: 00000000
LAB_0166:
	dc.l  0			;017e2: 00000000
	dc.l  0			;017e6: 00000000
	dc.l  0			;017ea: 00000000
	dc.l  0			;017ee: 00000000
	dc.l  0			;017f2: 00000000
	dc.l  0			;017f6: 00000000
	dc.l  0			;017fa: 00000000
	dc.l  0			;017fe: 00000000
	dc.l  0			;01802: 00000000
	dc.l  0			;01806: 00000000
	dc.l  0			;0180a: 00000000
	dc.l  0			;0180e: 00000000
	dc.l  0			;01812: 00000000
	dc.l  0			;01816: 00000000
	dc.l  0			;0181a: 00000000
	dc.l  0			;0181e: 00000000
	dc.l  0			;01822: 00000000
	dc.l  0			;01826: 00000000
	dc.l  0			;0182a: 00000000
	dc.l  0			;0182e: 00000000
	dc.l  0			;01832: 00000000
	dc.l  0			;01836: 00000000
	dc.l  0			;0183a: 00000000
	dc.l  0			;0183e: 00000000
	dc.l  0			;01842: 00000000
	dc.l  0			;01846: 00000000
	dc.l  0			;0184a: 00000000
	dc.l  0			;0184e: 00000000
	dc.l  0			;01852: 00000000
	dc.l  0			;01856: 00000000
	dc.l  0			;0185a: 00000000
	dc.l  0			;0185e: 00000000
	dc.l  0			;01862: 00000000
LAB_0167:
	dc.l  0			;01866: 00000000
LAB_0168:
	dc.l  0			;0186a: 00000000
	DC.W	$0000			;0186e
write_whole_file:
	MOVE.L	D0,LAB_017B		;01870: 23c000001a38
	MOVE.L	D1,LAB_017C		;01876: 23c100001a3c
	MOVE.L	D2,LAB_0161+2		;0187c: 23c200001752
	MOVE.L	LAB_0161+2,D1		;01882: 223900001752
	MOVE.L	#MODE_NEWFILE,D2		;01888: 243c000003ee
	MOVEA.L	DosBase,A6		;0188e: 2c790000174e
	JSR	(_LVOOpen,A6)	;01894: 4eaeffe2 dos.library (off=-30)
	CMP.L	#$00000000,D0		;01898: b0bc00000000
	BEQ.W	LAB_016A		;0189e: 67000030
	MOVE.L	LAB_017B,D2		;018a2: 243900001a38
	MOVE.L	LAB_017C,D3		;018a8: 263900001a3c
	MOVE.L	D0,D1			;018ae: 2200
	MOVE.L	D1,-(A7)		;018b0: 2f01
	MOVEA.L	DosBase,A6		;018b2: 2c790000174e
	JSR	(_LVOWrite,A6)	;018b8: 4eaeffd0 dos.library (off=-48)
	MOVEA.L	DosBase,A6		;018bc: 2c790000174e
	MOVE.L	(A7)+,D1		;018c2: 221f
	JSR	(_LVOClose,A6)	;018c4: 4eaeffdc dos.library (off=-36)
	MOVE.L	#$00000000,D0		;018c8: 203c00000000
	RTS				;018ce: 4e75
LAB_016A:
	MOVEA.L	#LAB_0177,A0		;018d0: 207c00001a1a
	BSR.W	write_message		;018d6: 610000d8
	MOVE.L	#$ffffffff,D0		;018da: 203cffffffff
	RTS				;018e0: 4e75
	MOVEM.L	D0-D7/A0-A6,-(A7)	;018e2: 48e7fffe
	LEA	LAB_017F,A0		;018e6: 41f900001a68
	LEA	LAB_017D,A1		;018ec: 43f900001a44
	MOVE.W	#$0000,D1		;018f2: 323c0000
	MOVE.W	#$0000,D2		;018f6: 343c0000
LAB_016B:
	MOVE.B	#$30,D6			;018fa: 1c3c0030
LAB_016C:
	CMP.L	(A1),D0			;018fe: b091
	BCS.W	LAB_016D		;01900: 6500000e
	ADDQ.B	#1,D6			;01904: 5206
	MOVE.W	#$ffff,D2		;01906: 343cffff
	SUB.L	(A1),D0			;0190a: 9091
	BRA.W	LAB_016C		;0190c: 6000fff0
LAB_016D:
	TST.W	D2			;01910: 4a42
	BEQ.W	LAB_016E		;01912: 67000004
	MOVE.B	D6,(A0)+		;01916: 10c6
LAB_016E:
	ADDQ.L	#4,A1			;01918: 5889
	ADDI.W	#$0001,D1		;0191a: 06410001
	CMP.W	#$0009,D1		;0191e: b27c0009
	BNE.W	LAB_016B		;01922: 6600ffd6
	TST.W	D2			;01926: 4a42
	BNE.W	LAB_016F		;01928: 66000006
	MOVE.B	#$30,(A0)+		;0192c: 10fc0030
LAB_016F:
	MOVE.B	#$00,(A0)+		;01930: 10fc0000
	LEA	LAB_017F,A0		;01934: 41f900001a68
	BSR.W	write_message		;0193a: 61000074
	MOVEM.L	(A7)+,D0-D7/A0-A6	;0193e: 4cdf7fff
	RTS				;01942: 4e75
	DC.W	$3031			;01944
	DC.W	$3233			;01946
	DC.W	$3435			;01948
	MOVE.W	57(A7,D3.L),D3		;0194a: 36373839
	dc.w    $6162
	dc.w    $6364
	dc.w    $6566
	MOVE.B	D0,D0			;01954: 1000
	DC.W	$0000			;01956
	BTST	D0,D0			;01958: 0100
	ORI.B	#$10,D0			;0195a: 00000010
	ORI.B	#$01,D0			;0195e: 00000001
	dc.l  0			;01962: 00000000
	MOVE.B	D0,D0			;01966: 1000
	DC.W	$0000			;01968
	BTST	D0,D0			;0196a: 0100
	ORI.B	#$10,D0			;0196c: 00000010
	ORI.B	#$01,D0			;01970: 00000001
	MOVEM.L	D0-D7/A0-A6,-(A7)	;01974: 48e7fffe
	MOVE.L	A0,-(A7)		;01978: 2f08
	MOVEA.L	DosBase,A6		;0197a: 2c790000174e
	JSR	(_LVOOutput,A6)	;01980: 4eaeffc4 dos.library (off=-60)
	MOVE.L	D0,LAB_015F+2		;01984: 23c00000174a
	MOVEA.L	(A7)+,A0		;0198a: 205f
	MOVE.L	A0,D2			;0198c: 2408
	MOVE.L	#$00000000,D3		;0198e: 263c00000000
LAB_0170:
	ADDQ.L	#1,D3			;01994: 5283
	TST.B	(A0)+			;01996: 4a18
	BNE.S	LAB_0170		;01998: 66fa
	MOVEA.L	DosBase,A6		;0199a: 2c790000174e
	MOVEA.L	LAB_015F+2,A1		;019a0: 22790000174a
	JSR	(_LVOWrite,A6)	;019a6: 4eaeffd0 dos.library (off=-48)
	MOVEM.L	(A7)+,D0-D7/A0-A6	;019aa: 4cdf7fff
	RTS				;019ae: 4e75
write_message:
    RTS
    
	MOVE.L	USP,A1			;019d8: 4e69
	dc.w  $6368
	MOVEQ	#32,D2			;019dc: 7420
	DC.W	$6765			;019de
	DC.W	$6e6f			;019e0
	DC.W	$6765			;019e2
	dc.w  $6e64
	MOVEA.L	(A3),A0			;019e6: 2053
	MOVEQ	#101,D0			;019e8: 7065
	DC.W	$6963			;019ea
	DC.W	$6865			;019ec
	MOVEQ	#13,D1			;019ee: 720d
	DC.W	$0a00			;019f0
	DC.W	$4c61			;019f2
	DC.W	$6465			;019f4
	MOVE.L	D0,D0			;019f6: 2000
	SUBQ.W	#1,25448(A1)		;019f8: 53696368
	dc.w  $6572
	dc.w  $6520
	DC.W	$0000			;01a00
LAB_0176:
	NEG.W	-(A1)			;01a02: 4461
	MOVEQ	#101,D2			;01a04: 7465
	dc.w  $6920
	DC.W	$6e69			;01a08
	dc.w  $6368
	MOVEQ	#32,D2			;01a0c: 7420
	DC.W	$6765			;01a0e
	DC.W	$6675			;01a10
	dc.w  $6e64
	dc.w  $656e
	MOVEP	0(A2),D6		;01a16: 0d0a0000
LAB_0177:
	DC.W	$4572			;01a1a
	DC.W	$7374			;01a1c
	dc.w  $656c
LAB_0178:
	dc.w  $6c66
	dc.w  $6568
	DC.W	$6c65			;01a24
	MOVEQ	#13,D1			;01a26: 720d
LAB_0179:
	DC.W	$0a00			;01a28
LAB_017A:
	MOVEP	0(A2),D6		;01a2a: 0d0a0000
	BTST	D6,D0			;01a2e: 0d00
	dc.l  0			;01a30: 00000000
	dc.l  0			;01a34: 00000000
LAB_017B:
	dc.l  0			;01a38: 00000000
LAB_017C:
	dc.l  0			;01a3c: 00000000
	dc.l  0			;01a40: 00000000
LAB_017D:
	DC.W	$05f5			;01a44
	ASL.B	#8,D0			;01a46: e100
LAB_017E:
	ORI.L	#$9680000f,(A0)+	;01a48: 00989680000f
	CLR.W	D0			;01a4e: 4240
	DC.W	$0001			;01a50
	OR.L	-(A0),D3		;01a52: 86a0
	DC.W	$0000			;01a54
	MOVE.L	(A0),-(A3)		;01a56: 2710
	DC.W	$0000			;01a58
	BSET	D1,0(A0)		;01a5a: 03e80000
	ORI.W	#$0000,-(A4)		;01a5e: 00640000
	DC.W	$000a			;01a62
	ORI.B	#$01,D0			;01a64: 00000001
LAB_017F:
	dc.l  0			;01a68: 00000000
	dc.l  0			;01a6c: 00000000
LAB_0180:
	DC.W	$0000			;01a70
	MOVEQ	#0,D1			;01a72: 7200
LAB_0181:
	TST.L	LAB_015C		;01a74: 4ab900001720
	BEQ.S	LAB_0187		;01a7a: 6728
	SUBQ.L	#1,LAB_015C		;01a7c: 53b900001720
	MOVE.B	(A0)+,D2		;01a82: 1418
LAB_0183:
	CMP.B	#$20,D2			;01a84: b43c0020
LAB_0184:
	BEQ.W	LAB_0187		;01a88: 6700001a
LAB_0185:
	CMP.B	#$0a,D2			;01a8c: b43c000a
	BEQ.W	LAB_0187		;01a90: 67000012
	MOVE.B	D2,(A1)+		;01a94: 12c2
	ADDQ.W	#1,D1			;01a96: 5241
	BRA.W	LAB_0181		;01a98: 6000ffda
LAB_0186:
	MOVE.L	#$ffffffff,D0		;01a9c: 203cffffffff
	RTS				;01aa2: 4e75
LAB_0187:
	TST.W	D1			;01aa4: 4a41
	BEQ.W	LAB_0186		;01aa6: 6700fff4
	MOVE.B	#$00,(A1)+		;01aaa: 12fc0000
	MOVE.L	#$00000000,D0		;01aae: 203c00000000
	RTS				;01ab4: 4e75
	TST.L	LAB_015C		;01ab6: 4ab900001720
	BEQ.S	LAB_0188		;01abc: 6726
	SUBQ.L	#1,LAB_015C		;01abe: 53b900001720
	MOVE.B	(A0)+,D7		;01ac4: 1e18
	CMP.B	#$0a,D7			;01ac6: be3c000a
	BEQ.W	LAB_0188		;01aca: 67000018
	ANDI.L	#$000000ff,D7		;01ace: 0287000000ff
	ADDQ.L	#1,A0			;01ad4: 5288
	SUBQ.L	#1,LAB_015C		;01ad6: 53b900001720
	MOVE.L	#$00000000,D0		;01adc: 203c00000000
	RTS				;01ae2: 4e75
LAB_0188:
	MOVE.L	#$ffffffff,D0		;01ae4: 203cffffffff
	RTS				;01aea: 4e75
	MOVE.L	#$00000000,D7		;01aec: 2e3c00000000
	MOVE.W	#$0000,D1		;01af2: 323c0000
LAB_0189:
	TST.L	LAB_015C		;01af6: 4ab900001720
	BEQ.S	LAB_018A		;01afc: 674c
	SUBQ.L	#1,LAB_015C		;01afe: 53b900001720
	MOVE.B	(A0)+,D5		;01b04: 1a18
	CMP.B	#$20,D5			;01b06: ba3c0020
	BEQ.W	LAB_018B		;01b0a: 67000046
	CMP.B	#$0a,D5			;01b0e: ba3c000a
	BEQ.W	LAB_018B		;01b12: 6700003e
	SUBI.B	#$30,D5			;01b16: 04050030
	CMP.B	#$0a,D5			;01b1a: ba3c000a
	BCC.W	LAB_018A		;01b1e: 6400002a
	ANDI.L	#$000000ff,D5		;01b22: 0285000000ff
	MOVE.L	D7,D6			;01b28: 2c07
	ADD.L	D6,D7			;01b2a: de86
	ADD.L	D6,D7			;01b2c: de86
	ADD.L	D6,D7			;01b2e: de86
	ADD.L	D6,D7			;01b30: de86
	ADD.L	D6,D7			;01b32: de86
	ADD.L	D6,D7			;01b34: de86
	ADD.L	D6,D7			;01b36: de86
	ADD.L	D6,D7			;01b38: de86
	ADD.L	D6,D7			;01b3a: de86
	ADD.L	D5,D7			;01b3c: de85
	ADDI.W	#$0001,D1		;01b3e: 06410001
	CMP.W	#$000a,D1		;01b42: b27c000a
	BCS.W	LAB_0189		;01b46: 6500ffae
LAB_018A:
	MOVE.L	#$ffffffff,D0		;01b4a: 203cffffffff
	RTS				;01b50: 4e75
LAB_018B:
	MOVE.L	#$00000000,D0		;01b52: 203c00000000
	RTS				;01b58: 4e75
	DC.W	$0000			;01b5a
DosBase
    dc.l    0
    
install_path:
	dc.b	"JOTD_TOS:",0
	even
    
	SECTION S_1,BSS

SECSTRT_1:
	DS.L	100000			;01b5c


	SECTION S_2,BSS

SECSTRT_2:
	DS.L	6697			;635dc
LAB_018E:
	DS.L	1250			;69e80

LAB_0190:
	DS.L	64			;6b328
LAB_0191:
	DS.L	64			;6b428
	END
