keyboard_interrupt
	movem.l	D0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here

    cmp.b   _keyexit(pc),d0
    beq   _quit


	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a5
	move.w	#8,$dff09c
	rte


; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts


decrunch:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;00c64: 48e7fffe
	LEA	(-384,A7),A7		;00c68: 4feffe80
	MOVEA.L	A7,A2			;00c6c: 244f
	BSR.W	.lab_00C3		;00c6e: 610003ae
	MOVEQ	#0,D1			;00c72: 7200
	MOVE.L	D0,D2			;00c74: 2400
	ANDI.L	#$ffffff00,D0		;00c76: 0280ffffff00
	CMPI.L	#$50414300,D0		;00c7c: 0c8050414300
	BNE.W	.lab_007D		;00c82: 6600010e
	CMPI.B	#$02,D2			;00c86: 0c020002
	BEQ.W	.lab_007F		;00c8a: 67000114
	CMPI.B	#$01,D2			;00c8e: 0c020001
	BNE.W	.lab_007D		;00c92: 660000fe
	BSR.W	.lab_00C3		;00c96: 61000386
	MOVE.L	D0,(384,A7)		;00c9a: 2f400180
	LEA	(10,A0),A3		;00c9e: 47e8000a
	MOVEA.L	A1,A5			;00ca2: 2a49
	LEA	(0,A5,D0.L),A6		;00ca4: 4df50800
	BSR.W	.lab_00C3		;00ca8: 61000374
	LEA	(0,A3,D0.L),A4		;00cac: 49f30800
	CLR.W	-(A7)			;00cb0: 4267
	CMPA.L	A4,A5			;00cb2: bbcc
	BCC.S	.lab_0074		;00cb4: 644c
	MOVEQ	#0,D0			;00cb6: 7000
	MOVE.B	(-2,A3),D0		;00cb8: 102bfffe
	LEA	(0,A6,D0.L),A0		;00cbc: 41f60800
	CMPA.L	A4,A0			;00cc0: b1cc
	BLS.S	.lab_0074		;00cc2: 633e
	ADDQ.W	#2,A7			;00cc4: 544f
	MOVE.L	A4,D0			;00cc6: 200c
	BTST	#0,D0			;00cc8: 08000000
	BEQ.S	.lab_006F		;00ccc: 6704
	ADDQ.W	#1,A4			;00cce: 524c
	ADDQ.W	#1,A0			;00cd0: 5248
.lab_006F:
	MOVE.L	A0,D0			;00cd2: 2008
	BTST	#0,D0			;00cd4: 08000000
	BEQ.S	.lab_0070		;00cd8: 6702
	ADDQ.W	#1,A0			;00cda: 5248
.lab_0070:
	MOVEQ	#0,D0			;00cdc: 7000
.lab_0071:
	CMPA.L	A0,A6			;00cde: bdc8
	BEQ.S	.lab_0072		;00ce0: 6708
	MOVE.B	-(A0),D1		;00ce2: 1220
	MOVE.W	D1,-(A7)		;00ce4: 3f01
	ADDQ.B	#1,D0			;00ce6: 5200
	BRA.S	.lab_0071		;00ce8: 60f4
.lab_0072:
	MOVE.W	D0,-(A7)		;00cea: 3f00
	ADDA.L	D0,A0			;00cec: d1c0
.lab_0073:
	LEA	(-32,A4),A4		;00cee: 49ecffe0
	MOVEM.L	(A4),D0-D7		;00cf2: 4cd400ff
	MOVEM.L	D0-D7,-(A0)		;00cf6: 48e0ff00
	CMPA.L	A3,A4			;00cfa: b9cb
	BHI.S	.lab_0073		;00cfc: 62f0
	SUBA.L	A4,A3			;00cfe: 97cc
	ADDA.L	A0,A3			;00d00: d7c8
.lab_0074:
	MOVEQ	#0,D7			;00d02: 7e00
	MOVE.B	(1,A3),D6		;00d04: 1c2b0001
	ROL.W	#8,D6			;00d08: e15e
	MOVE.B	(A3),D6			;00d0a: 1c13
	MOVEQ	#2,D0			;00d0c: 7002
	MOVEQ	#2,D1			;00d0e: 7202
	BSR.W	.lab_00BD		;00d10: 610002ca
.lab_0075:
	MOVEA.L	A2,A0			;00d14: 204a
	BSR.W	.lab_00B6		;00d16: 6100023a
	LEA	(128,A2),A0		;00d1a: 41ea0080
	BSR.W	.lab_00B6		;00d1e: 61000232
	LEA	(256,A2),A0		;00d22: 41ea0100
	BSR.W	.lab_00B6		;00d26: 6100022a
	MOVEQ	#-1,D0			;00d2a: 70ff
	MOVEQ	#16,D1			;00d2c: 7210
	BSR.W	.lab_00BD		;00d2e: 610002ac
	MOVE.W	D0,D4			;00d32: 3800
	SUBQ.W	#1,D4			;00d34: 5344
	BRA.S	.lab_0078		;00d36: 6020
.lab_0076:
	LEA	(128,A2),A0		;00d38: 41ea0080
	MOVEQ	#0,D0			;00d3c: 7000
	BSR.W	.lab_00BF		;00d3e: 610002a8
	NEG.L	D0			;00d42: 4480
	LEA	(-1,A5,D0.L),A1		;00d44: 43f508ff
	LEA	(256,A2),A0		;00d48: 41ea0100
	BSR.W	.lab_00BF		;00d4c: 6100029a
	MOVE.B	(A1)+,(A5)+		;00d50: 1ad9
.lab_0077:
	MOVE.B	(A1)+,(A5)+		;00d52: 1ad9
	DBF	D0,.lab_0077		;00d54: 51c8fffc
.lab_0078:
	MOVEA.L	A2,A0			;00d58: 204a
	BSR.W	.lab_00BF		;00d5a: 6100028c
	SUBQ.W	#1,D0			;00d5e: 5340
	BMI.S	.lab_007A		;00d60: 6b1a
.lab_0079:
	MOVE.B	(A3)+,(A5)+		;00d62: 1adb
	DBF	D0,.lab_0079		;00d64: 51c8fffc
	MOVE.B	(1,A3),D0		;00d68: 102b0001
	ROL.W	#8,D0			;00d6c: e158
	MOVE.B	(A3),D0			;00d6e: 1013
	LSL.L	D7,D0			;00d70: efa8
	MOVEQ	#1,D1			;00d72: 7201
	LSL.W	D7,D1			;00d74: ef69
	SUBQ.W	#1,D1			;00d76: 5341
	AND.L	D1,D6			;00d78: cc81
	OR.L	D0,D6			;00d7a: 8c80
.lab_007A:
	DBF	D4,.lab_0076		;00d7c: 51ccffba
	CMPA.L	A6,A5			;00d80: bbce
	BCS.S	.lab_0075		;00d82: 6590
	MOVE.W	(A7)+,D0		;00d84: 301f
	BEQ.S	.lab_007C		;00d86: 6708
.lab_007B:
	MOVE.W	(A7)+,D1		;00d88: 321f
	MOVE.B	D1,(A5)+		;00d8a: 1ac1
	SUBQ.B	#1,D0			;00d8c: 5300
	BNE.S	.lab_007B		;00d8e: 66f8
.lab_007C:
	BRA.S	.lab_007E		;00d90: 6004
.lab_007D:
	MOVE.L	D1,(384,A7)		;00d92: 2f410180
.lab_007E:
	LEA	(384,A7),A7		;00d96: 4fef0180
	MOVEM.L	(A7)+,D0-D7/A0-A6	;00d9a: 4cdf7fff
	RTS				;00d9e: 4e75
.lab_007F:
	BSR.W	.lab_00C3		;00da0: 6100027c
	MOVE.L	D0,(A7)			;00da4: 2e80
	LEA	(10,A0),A3		;00da6: 47e8000a
	MOVEA.L	A1,A5			;00daa: 2a49
	LEA	(0,A5,D0.L),A6		;00dac: 4df50800
	BSR.W	.lab_00C3		;00db0: 6100026c
	LEA	(0,A3,D0.L),A4		;00db4: 49f30800
	CLR.W	-(A7)			;00db8: 4267
	CMPA.L	A4,A5			;00dba: bbcc
	BCC.S	.lab_0085		;00dbc: 644c
	MOVEQ	#0,D0			;00dbe: 7000
	MOVE.B	(-2,A3),D0		;00dc0: 102bfffe
	LEA	(0,A6,D0.L),A0		;00dc4: 41f60800
	CMPA.L	A4,A0			;00dc8: b1cc
	BLS.S	.lab_0085		;00dca: 633e
	ADDQ.W	#2,A7			;00dcc: 544f
	MOVE.L	A4,D0			;00dce: 200c
	BTST	#0,D0			;00dd0: 08000000
	BEQ.S	.lab_0080		;00dd4: 6704
	ADDQ.W	#1,A4			;00dd6: 524c
	ADDQ.W	#1,A0			;00dd8: 5248
.lab_0080:
	MOVE.L	A0,D0			;00dda: 2008
	BTST	#0,D0			;00ddc: 08000000
	BEQ.S	.lab_0081		;00de0: 6702
	ADDQ.W	#1,A0			;00de2: 5248
.lab_0081:
	MOVEQ	#0,D0			;00de4: 7000
.lab_0082:
	CMPA.L	A0,A6			;00de6: bdc8
	BEQ.S	.lab_0083		;00de8: 6708
	MOVE.B	-(A0),D1		;00dea: 1220
	MOVE.W	D1,-(A7)		;00dec: 3f01
	ADDQ.B	#1,D0			;00dee: 5200
	BRA.S	.lab_0082		;00df0: 60f4
.lab_0083:
	MOVE.W	D0,-(A7)		;00df2: 3f00
	ADDA.L	D0,A0			;00df4: d1c0
.lab_0084:
	LEA	(-32,A4),A4		;00df6: 49ecffe0
	MOVEM.L	(A4),D0-D7		;00dfa: 4cd400ff
	MOVEM.L	D0-D7,-(A0)		;00dfe: 48e0ff00
	CMPA.L	A3,A4			;00e02: b9cb
	BHI.S	.lab_0084		;00e04: 62f0
	SUBA.L	A4,A3			;00e06: 97cc
	ADDA.L	A0,A3			;00e08: d7c8
.lab_0085:
	MOVEQ	#-128,D7		;00e0a: 7e80
	ADD.B	D7,D7			;00e0c: de07
	MOVE.B	(A3)+,D7		;00e0e: 1e1b
	ADDX.B	D7,D7			;00e10: df07
	ADD.B	D7,D7			;00e12: de07
	BRA.W	.lab_00A3		;00e14: 600000ba
.lab_0086:
	MOVE.B	(A3)+,D7		;00e18: 1e1b
	ADDX.B	D7,D7			;00e1a: df07
	BRA.S	.lab_0090		;00e1c: 6030
.lab_0087:
	MOVE.B	(A3)+,D7		;00e1e: 1e1b
	ADDX.B	D7,D7			;00e20: df07
	BRA.S	.lab_0093		;00e22: 6044
.lab_0088:
	MOVE.B	(A3)+,D7		;00e24: 1e1b
	ADDX.B	D7,D7			;00e26: df07
	BRA.S	.lab_0094		;00e28: 6044
.lab_0089:
	MOVE.B	(A3)+,D7		;00e2a: 1e1b
	ADDX.B	D7,D7			;00e2c: df07
	BRA.S	.lab_0095		;00e2e: 6046
.lab_008A:
	MOVE.B	(A3)+,D7		;00e30: 1e1b
	ADDX.B	D7,D7			;00e32: df07
	BRA.S	.lab_0097		;00e34: 604c
.lab_008B:
	MOVE.B	(A3)+,D7		;00e36: 1e1b
	ADDX.B	D7,D7			;00e38: df07
	BRA.S	.lab_0098		;00e3a: 604c
.lab_008C:
	MOVE.B	(A3)+,D7		;00e3c: 1e1b
	ADDX.B	D7,D7			;00e3e: df07
	BRA.S	.lab_0099		;00e40: 604c
.lab_008D:
	MOVE.B	(A3)+,D7		;00e42: 1e1b
	ADDX.B	D7,D7			;00e44: df07
	BRA.S	.lab_009B		;00e46: 6052
.lab_008E:
	MOVEQ	#3,D5			;00e48: 7a03
.lab_008F:
	ADD.B	D7,D7			;00e4a: de07
	BEQ.S	.lab_0086		;00e4c: 67ca
.lab_0090:
	ADDX.W	D6,D6			;00e4e: dd46
	DBF	D5,.lab_008F		;00e50: 51cdfff8
	ADDQ.W	#2,D6			;00e54: 5446
.lab_0091:
	MOVE.B	(A3)+,(A5)+		;00e56: 1adb
	MOVE.B	(A3)+,(A5)+		;00e58: 1adb
	MOVE.B	(A3)+,(A5)+		;00e5a: 1adb
	MOVE.B	(A3)+,(A5)+		;00e5c: 1adb
	DBF	D6,.lab_0091		;00e5e: 51cefff6
	BRA.S	.lab_00A3		;00e62: 606c
.lab_0092:
	ADD.B	D7,D7			;00e64: de07
	BEQ.S	.lab_0087		;00e66: 67b6
.lab_0093:
	ADDX.W	D5,D5			;00e68: db45
	ADD.B	D7,D7			;00e6a: de07
	BEQ.S	.lab_0088		;00e6c: 67b6
.lab_0094:
	BCC.S	.lab_0096		;00e6e: 640e
	SUBQ.W	#1,D5			;00e70: 5345
	ADD.B	D7,D7			;00e72: de07
	BEQ.S	.lab_0089		;00e74: 67b4
.lab_0095:
	ADDX.W	D5,D5			;00e76: db45
	CMPI.B	#$09,D5			;00e78: 0c050009
	BEQ.S	.lab_008E		;00e7c: 67ca
.lab_0096:
	ADD.B	D7,D7			;00e7e: de07
	BEQ.S	.lab_008A		;00e80: 67ae
.lab_0097:
	BCC.S	.lab_009D		;00e82: 641a
	ADD.B	D7,D7			;00e84: de07
	BEQ.S	.lab_008B		;00e86: 67ae
.lab_0098:
	ADDX.W	D6,D6			;00e88: dd46
	ADD.B	D7,D7			;00e8a: de07
	BEQ.S	.lab_008C		;00e8c: 67ae
.lab_0099:
	BCS.S	.lab_00A9		;00e8e: 656e
	TST.W	D6			;00e90: 4a46
	BNE.S	.lab_009C		;00e92: 6608
	ADDQ.W	#1,D6			;00e94: 5246
.lab_009A:
	ADD.B	D7,D7			;00e96: de07
	BEQ.S	.lab_008D		;00e98: 67a8
.lab_009B:
	ADDX.W	D6,D6			;00e9a: dd46
.lab_009C:
	ROL.W	#8,D6			;00e9c: e15e
.lab_009D:
	MOVE.B	(A3)+,D6		;00e9e: 1c1b
	MOVEA.L	A5,A0			;00ea0: 204d
	SUBA.W	D6,A0			;00ea2: 90c6
	SUBQ.W	#1,A0			;00ea4: 5348
	LSR.W	#1,D5			;00ea6: e24d
	BCC.S	.lab_009E		;00ea8: 6402
	MOVE.B	(A0)+,(A5)+		;00eaa: 1ad8
.lab_009E:
	SUBQ.W	#1,D5			;00eac: 5345
	TST.W	D6			;00eae: 4a46
	BNE.S	.lab_00A0		;00eb0: 660c
	MOVE.B	(A0),D6			;00eb2: 1c10
.lab_009F:
	MOVE.B	D6,(A5)+		;00eb4: 1ac6
	MOVE.B	D6,(A5)+		;00eb6: 1ac6
	DBF	D5,.lab_009F		;00eb8: 51cdfffa
	BRA.S	.lab_00A3		;00ebc: 6012
.lab_00A0:
	MOVE.B	(A0)+,(A5)+		;00ebe: 1ad8
	MOVE.B	(A0)+,(A5)+		;00ec0: 1ad8
	DBF	D5,.lab_00A0		;00ec2: 51cdfffa
	BRA.S	.lab_00A3		;00ec6: 6008
.lab_00A1:
	MOVE.B	(A3)+,D7		;00ec8: 1e1b
	ADDX.B	D7,D7			;00eca: df07
	BCS.S	.lab_00A5		;00ecc: 650e
.lab_00A2:
	MOVE.B	(A3)+,(A5)+		;00ece: 1adb
.lab_00A3:
	ADD.B	D7,D7			;00ed0: de07
	BCS.S	.lab_00A4		;00ed2: 6506
	MOVE.B	(A3)+,(A5)+		;00ed4: 1adb
	ADD.B	D7,D7			;00ed6: de07
	BCC.S	.lab_00A2		;00ed8: 64f4
.lab_00A4:
	BEQ.S	.lab_00A1		;00eda: 67ec
.lab_00A5:
	MOVEQ	#2,D5			;00edc: 7a02
	MOVEQ	#0,D6			;00ede: 7c00
	ADD.B	D7,D7			;00ee0: de07
	BEQ.S	.lab_00AC		;00ee2: 672c
.lab_00A6:
	BCC.W	.lab_0092		;00ee4: 6400ff7e
	ADD.B	D7,D7			;00ee8: de07
	BEQ.S	.lab_00AD		;00eea: 672a
.lab_00A7:
	BCC.S	.lab_009D		;00eec: 64b0
	ADDQ.W	#1,D5			;00eee: 5245
	ADD.B	D7,D7			;00ef0: de07
	BEQ.S	.lab_00AE		;00ef2: 6728
.lab_00A8:
	BCC.S	.lab_0096		;00ef4: 6488
	MOVE.B	(A3)+,D5		;00ef6: 1a1b
	BEQ.S	.lab_00B1		;00ef8: 6734
	ADDQ.W	#8,D5			;00efa: 5045
	BRA.S	.lab_0096		;00efc: 6080
.lab_00A9:
	ADD.B	D7,D7			;00efe: de07
	BEQ.S	.lab_00AF		;00f00: 6720
.lab_00AA:
	ADDX.W	D6,D6			;00f02: dd46
	ORI.W	#$0004,D6		;00f04: 00460004
	ADD.B	D7,D7			;00f08: de07
	BEQ.S	.lab_00B0		;00f0a: 671c
.lab_00AB:
	BCS.S	.lab_009C		;00f0c: 658e
	BRA.S	.lab_009A		;00f0e: 6086
.lab_00AC:
	MOVE.B	(A3)+,D7		;00f10: 1e1b
	ADDX.B	D7,D7			;00f12: df07
	BRA.S	.lab_00A6		;00f14: 60ce
.lab_00AD:
	MOVE.B	(A3)+,D7		;00f16: 1e1b
	ADDX.B	D7,D7			;00f18: df07
	BRA.S	.lab_00A7		;00f1a: 60d0
.lab_00AE:
	MOVE.B	(A3)+,D7		;00f1c: 1e1b
	ADDX.B	D7,D7			;00f1e: df07
	BRA.S	.lab_00A8		;00f20: 60d2
.lab_00AF:
	MOVE.B	(A3)+,D7		;00f22: 1e1b
	ADDX.B	D7,D7			;00f24: df07
	BRA.S	.lab_00AA		;00f26: 60da
.lab_00B0:
	MOVE.B	(A3)+,D7		;00f28: 1e1b
	ADDX.B	D7,D7			;00f2a: df07
	BRA.S	.lab_00AB		;00f2c: 60de
.lab_00B1:
	ADD.B	D7,D7			;00f2e: de07
	BNE.S	.lab_00B2		;00f30: 6604
	MOVE.B	(A3)+,D7		;00f32: 1e1b
	ADDX.B	D7,D7			;00f34: df07
.lab_00B2:
	BCS.S	.lab_00A3		;00f36: 6598
	MOVE.W	(A7)+,D0		;00f38: 301f
	BEQ.S	.lab_00B4		;00f3a: 6708
.lab_00B3:
	MOVE.W	(A7)+,D1		;00f3c: 321f
	MOVE.B	D1,(A5)+		;00f3e: 1ac1
	SUBQ.B	#1,D0			;00f40: 5300
	BNE.S	.lab_00B3		;00f42: 66f8
.lab_00B4:
	BRA.S	.lab_00B5		;00f44: 6002
	MOVE.L	D1,(A7)			;00f46: 2e81
.lab_00B5:
	LEA	(384,A7),A7		;00f48: 4fef0180
	MOVEM.L	(A7)+,D0-D7/A0-A6	;00f4c: 4cdf7fff
	RTS				;00f50: 4e75
.lab_00B6:
	MOVEQ	#31,D0			;00f52: 701f
	MOVEQ	#5,D1			;00f54: 7205
	BSR.W	.lab_00BD		;00f56: 61000084
	SUBQ.W	#1,D0			;00f5a: 5340
	BMI.S	.lab_00BC		;00f5c: 6b7c
	MOVE.W	D0,D2			;00f5e: 3400
	MOVE.W	D0,D3			;00f60: 3600
	LEA	(-16,A7),A7		;00f62: 4feffff0
	MOVEA.L	A7,A1			;00f66: 224f
.lab_00B7:
	MOVEQ	#15,D0			;00f68: 700f
	MOVEQ	#4,D1			;00f6a: 7204
	BSR.S	.lab_00BD		;00f6c: 616e
	MOVE.B	D0,(A1)+		;00f6e: 12c0
	DBF	D2,.lab_00B7		;00f70: 51cafff6
	MOVEQ	#1,D0			;00f74: 7001
	ROR.L	#1,D0			;00f76: e298
	MOVEQ	#1,D1			;00f78: 7201
	MOVEQ	#0,D2			;00f7a: 7400
	MOVEM.L	D5-D7,-(A7)		;00f7c: 48e70700
.lab_00B8:
	MOVE.W	D3,D4			;00f80: 3803
	LEA	(12,A7),A1		;00f82: 43ef000c
.lab_00B9:
	CMP.B	(A1)+,D1		;00f86: b219
	BNE.S	.lab_00BB		;00f88: 663a
	MOVEQ	#1,D5			;00f8a: 7a01
	LSL.W	D1,D5			;00f8c: e36d
	SUBQ.W	#1,D5			;00f8e: 5345
	MOVE.W	D5,(A0)+		;00f90: 30c5
	MOVE.L	D2,D5			;00f92: 2a02
	SWAP	D5			;00f94: 4845
	MOVE.W	D1,D7			;00f96: 3e01
	SUBQ.W	#1,D7			;00f98: 5347
.lab_00BA:
	ROXL.W	#1,D5			;00f9a: e355
	ROXR.W	#1,D6			;00f9c: e256
	DBF	D7,.lab_00BA		;00f9e: 51cffffa
	MOVEQ	#16,D5			;00fa2: 7a10
	SUB.B	D1,D5			;00fa4: 9a01
	LSR.W	D5,D6			;00fa6: ea6e
	MOVE.W	D6,(A0)+		;00fa8: 30c6
	MOVE.B	D1,(60,A0)		;00faa: 1141003c
	MOVE.B	D3,D5			;00fae: 1a03
	SUB.B	D4,D5			;00fb0: 9a04
	MOVE.B	D5,(61,A0)		;00fb2: 1145003d
	MOVEQ	#1,D6			;00fb6: 7c01
	SUBQ.B	#1,D5			;00fb8: 5305
	LSL.W	D5,D6			;00fba: eb6e
	SUBQ.W	#1,D6			;00fbc: 5346
	MOVE.W	D6,(62,A0)		;00fbe: 3146003e
	ADD.L	D0,D2			;00fc2: d480
.lab_00BB:
	DBF	D4,.lab_00B9		;00fc4: 51ccffc0
	LSR.L	#1,D0			;00fc8: e288
	ADDQ.B	#1,D1			;00fca: 5201
	CMPI.B	#$11,D1			;00fcc: 0c010011
	BNE.S	.lab_00B8		;00fd0: 66ae
	MOVEM.L	(A7)+,D5-D7		;00fd2: 4cdf00e0
	LEA	(16,A7),A7		;00fd6: 4fef0010
.lab_00BC:
	RTS				;00fda: 4e75
.lab_00BD:
	AND.W	D6,D0			;00fdc: c046
	SUB.B	D1,D7			;00fde: 9e01
	BGE.S	.lab_00BE		;00fe0: 6c02
	BSR.S	.lab_00C5		;00fe2: 6146
.lab_00BE:
	LSR.L	D1,D6			;00fe4: e2ae
	RTS				;00fe6: 4e75
.lab_00BF:
	MOVE.W	(A0)+,D0		;00fe8: 3018
	AND.W	D6,D0			;00fea: c046
	SUB.W	(A0)+,D0		;00fec: 9058
	BNE.S	.lab_00BF		;00fee: 66f8
	MOVE.B	(60,A0),D1		;00ff0: 1228003c
	SUB.B	D1,D7			;00ff4: 9e01
	BGE.S	.lab_00C0		;00ff6: 6c02
	BSR.S	.lab_00C5		;00ff8: 6130
.lab_00C0:
	LSR.L	D1,D6			;00ffa: e2ae
	MOVE.B	(61,A0),D0		;00ffc: 1028003d
	CMPI.B	#$02,D0			;01000: 0c000002
	BLT.S	.lab_00C2		;01004: 6d16
	SUBQ.B	#1,D0			;01006: 5300
	MOVE.B	D0,D1			;01008: 1200
	MOVE.B	D0,D2			;0100a: 1400
	MOVE.W	(62,A0),D0		;0100c: 3028003e
	AND.W	D6,D0			;01010: c046
	SUB.B	D1,D7			;01012: 9e01
	BGE.S	.lab_00C1		;01014: 6c02
	BSR.S	.lab_00C5		;01016: 6112
.lab_00C1:
	LSR.L	D1,D6			;01018: e2ae
	BSET	D2,D0			;0101a: 05c0
.lab_00C2:
	RTS				;0101c: 4e75
.lab_00C3:
	MOVEQ	#3,D1			;0101e: 7203
.lab_00C4:
	LSL.L	#8,D0			;01020: e188
	MOVE.B	(A0)+,D0		;01022: 1018
	DBF	D1,.lab_00C4		;01024: 51c9fffa
	RTS				;01028: 4e75
.lab_00C5:
	ADD.B	D1,D7			;0102a: de01
	LSR.L	D7,D6			;0102c: eeae
	SWAP	D6			;0102e: 4846
	ADDQ.W	#4,A3			;01030: 584b
	MOVE.B	-(A3),D6		;01032: 1c23
	ROL.W	#8,D6			;01034: e15e
	MOVE.B	-(A3),D6		;01036: 1c23
	SWAP	D6			;01038: 4846
	SUB.B	D7,D1			;0103a: 9207
	MOVEQ	#16,D7			;0103c: 7e10
	SUB.B	D1,D7			;0103e: 9e01
	RTS				;01040: 4e75

;	A0,filename		;01066: 23c8000018be
;	A1,destination		;0106c: 23c9000018c2
;	D1,size		(0 => all file)
;	D2,whence	(0 => start)

    
read_file
    move.l  _resload(pc),a2
    movem.l d0-d1/a0-a1,-(a7)
    jsr resload_GetFileSize(a2)
    move.l  d0,d3
    bne.b   .ok
    illegal
.ok
    movem.l (a7)+,d0-d1/a0-a1
    ; D3 file size
    sub.l   d2,d3   ; subtract start offset if any
    tst.l   d1
    bne.b   .sizeset
    move.l  d3,d1   ; rest of the file
.sizeset
    move.l   d1,d0  ; size
    move.l  d2,d1   ; offset
    move.l  d0,d3   ; save size
    jsr resload_LoadFileOffset(a2)
    move.l  d3,d0   ; return size read
    rts

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
	movem.l	d0-a6,-(a7)

    move.l  _expmem(pc),a1   ; base address
    movem.l a0-a1,-(a7)
    move.l  _resload(pc),a2
    jsr resload_LoadFile(a2)
    movem.l (a7)+,a0-a1
    
    movem.l a0-a1,-(a7)
    move.l  a1,a0       ; address
    clr.l   -(a7)                   ;TAG_DONE
    pea     -1                      ;true
    pea     WHDLTAG_LOADSEG
    move.l  #$400,-(a7)       ;chip area
    pea     WHDLTAG_CHIPPTR
    pea     8                       ;8 byte alignment
    pea     WHDLTAG_ALIGN
    move.l  a7,a1                   ;tags
    move.l  (_resload,pc),a2

    
    jsr     (resload_Relocate,a2)
    add.w   #7*4,a7
    movem.l (a7)+,a0-a1

    ;lea $1FFF8,a1   ; base address
    move.l  a1,d7
    addq.l  #4,d7
    lsr.l   #2,d7                   ;make BPTR

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	jsr	(a5)
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1


	movem.l	d0/d7/a2/a6,-(a7)
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6


	movem.l	(a7)+,d0-a6
	rts
    
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
_resload
    dc.l    0