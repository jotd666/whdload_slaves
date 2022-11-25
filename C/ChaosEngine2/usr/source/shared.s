read_keycode:
	CLR.W	D0			;1e444: 4240
	MOVE.B	KEYCODE(A5),D0		;1e446: 102d303b
	bne.b	.key
	; D0 is 0: read the joystick
	move.b	#1,d0
	bsr	_read_joystick
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause
	move.b	#$50,D0
	bra.b	.key
.nopause
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	move.b	#$1B,D0
	bra.b	.key
.noesc
	btst	#JPB_BTN_BLU,d0
	beq.b	.nolshift
 	move.b	#$15,D0   
.nolshift
    ; player 2
	move.b	#0,d0
	bsr	_read_joystick
	btst	#JPB_BTN_BLU,d0
	beq.b	.norshift
 	move.b	#$16,D0   
.norshift
	moveq.l	#0,d0
.key
	rts
esc_loop:
	move.l	d0,-(a7)
	MOVEQ	#1,D0			;1e4d6: 7000
	; wait for rev+fwd not pressed
	bsr	_read_joystick_vbl
	btst	#JPB_BTN_GRN,d0
	beq.b	.noyel
	move.b	#$52,KEYCODE(A5)	; 'R'
.noyel
	btst	#JPB_BTN_YEL,d0
	beq.b	.nogrn
	move.b	#$51,KEYCODE(A5)	; 'Q'
.nogrn
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	move.b	#$1B,KEYCODE(A5)	; ESC
.noesc
	move.l	(a7)+,d0
	
	; original
	CMPI.B	#$51,KEYCODE(A5)		;1e4d8: 0c2d0051303b	; "Q"
	rts

unpause_loop:
	move.l	d0,-(a7)
	MOVEQ	#1,D0			;1e4d6: 7000
	; wait for rev+fwd not pressed
	bsr	_read_joystick_vbl
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause
	move.b	#$50,KEYCODE(A5)	; ESC
.nopause
	move.l	(a7)+,d0

	CMPI.B	#$50,KEYCODE(A5)		;21c54: 0c2d001b303b
	rts
	
test_esc:
	move.l	d0,-(a7)
	MOVEQ	#1,D0
	; wait for rev+fwd not pressed
	bsr	_read_joystick_vbl
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	move.b	#$1B,KEYCODE(A5)	; ESC
.noesc
	move.l	(a7)+,d0

	CMPI.B	#$1b,KEYCODE(A5)		;21c54: 0c2d001b303b
	rts
	
wait_esc_up:
	move.l	d0,-(a7)
.loop
	; wait for rev+fwd not pressed
	bsr	_read_joystick_vbl
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.out
	btst	#JPB_BTN_FORWARD,d0
	bne.b	.loop
.out
	move.l	(a7)+,d0

	MOVE.B	#$00,KEYCODE(A5)		;1e418: 1b7c0000303b
	RTS
	
wait_pause_up:
	move.l	d0,-(a7)
.loop
	; wait for rev+fwd not pressed
	bsr	_read_joystick_vbl
	btst	#JPB_BTN_PLAY,d0
	bne.b	.loop
	move.l	(a7)+,d0

	MOVE.B	#$00,KEYCODE(A5)		;1e418: 1b7c0000303b
	RTS
	
pre_esc_loop:
	; wait for rev+fwd not pressed
	bsr	_read_joystick_vbl
	btst	#JPB_BTN_REVERSE,d0
	bne.b	pre_esc_loop
	btst	#JPB_BTN_FORWARD,d0
	bne.b	pre_esc_loop
	
	MOVEA	#$0006,A0		;1e4d2: 307c0006
	MOVEQ	#0,D0			;1e4d6: 7000
	rts

_read_joystick_vbl
    bsr wait_vbl
	MOVEQ	#1,D0
    bra _read_joystick
    
wait_vbl:
    movem.l a0,-(a7)
	; wait for VBL
	lea	$DFF000,a0
	move.w	#$7FFF,intreq(a0)
.wait
	move.w	intreqr(a0),d0
	btst	#5,d0
	beq.b	.wait
    movem.l (a7)+,a0    ; no need to restore D0 here
	rts

rn_decrunch:
	movem.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	(resload_Decrunch,a2)
	movem.l	(a7)+,a2
	rts
    
rn_decrunchxxx:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;4c6: 48e7fffe
	LEA	-512(A7),A7		;4ca: 4feffe00
	MOVEA.L	A7,A2			;4ce: 244f
	BSR.W	LAB_0053		;4d0: 61000198
	MOVEQ	#0,D1			;4d4: 7200
	CMPI.L	#$524e4301,D0		;4d6: 0c80524e4301
	BNE.W	LAB_004A		;4dc: 66000124
	BSR.W	LAB_0053		;4e0: 61000188
	MOVE.L	D0,512(A7)		;4e4: 2f400200
	LEA	10(A0),A3		;4e8: 47e8000a
	MOVEA.L	A1,A5			;4ec: 2a49
	LEA	0(A5,D0.L),A6		;4ee: 4df50800
	BSR.W	LAB_0053		;4f2: 61000176
	LEA	0(A3,D0.L),A4		;4f6: 49f30800
	MOVEA.L	A3,A1			;4fa: 224b
	BSR.W	LAB_005C		;4fc: 61000200
	LEA	-6(A3),A0		;500: 41ebfffa
	BSR.W	LAB_0053		;504: 61000164
	MOVEQ	#-1,D1			;508: 72ff
	CMP.W	D2,D0			;50a: b042
	BNE.W	LAB_004A		;50c: 660000f4
	SWAP	D0			;510: 4840
	MOVE.W	D0,-(A7)		;512: 3f00
	CLR.W	-(A7)			;514: 4267
	CMPA.L	A4,A5			;516: bbcc
	BCC.S	LAB_0041		;518: 644c
	MOVEQ	#0,D0			;51a: 7000
	MOVE.B	-2(A3),D0		;51c: 102bfffe
	LEA	0(A6,D0.L),A0		;520: 41f60800
	CMPA.L	A4,A0			;524: b1cc
	BLS.S	LAB_0041		;526: 633e
	ADDQ.W	#2,A7			;528: 544f
	MOVE.L	A4,D0			;52a: 200c
	BTST	#0,D0			;52c: 08000000
	BEQ.S	LAB_003C		;530: 6704
	ADDQ.W	#1,A4			;532: 524c
	ADDQ.W	#1,A0			;534: 5248
LAB_003C:
	MOVE.L	A0,D0			;536: 2008
	BTST	#0,D0			;538: 08000000
	BEQ.S	LAB_003D		;53c: 6702
	ADDQ.W	#1,A0			;53e: 5248
LAB_003D:
	MOVEQ	#0,D0			;540: 7000
LAB_003E:
	CMPA.L	A0,A6			;542: bdc8
	BEQ.S	LAB_003F		;544: 6708
	MOVE.B	-(A0),D1		;546: 1220
	MOVE.W	D1,-(A7)		;548: 3f01
	ADDQ.B	#1,D0			;54a: 5200
	BRA.S	LAB_003E		;54c: 60f4
LAB_003F:
	MOVE.W	D0,-(A7)		;54e: 3f00
	ADDA.L	D0,A0			;550: d1c0
LAB_0040:
	LEA	-32(A4),A4		;552: 49ecffe0
	MOVEM.L	(A4),D0-D7		;556: 4cd400ff
	MOVEM.L	D0-D7,-(A0)		;55a: 48e0ff00
	CMPA.L	A3,A4			;55e: b9cb
	BHI.S	LAB_0040		;560: 62f0
	SUBA.L	A4,A3			;562: 97cc
	ADDA.L	A0,A3			;564: d7c8
LAB_0041:
	MOVEQ	#0,D7			;566: 7e00
	MOVE.B	1(A3),D6		;568: 1c2b0001
	ROL.W	#8,D6			;56c: e15e
	MOVE.B	(A3),D6			;56e: 1c13
	MOVEQ	#2,D0			;570: 7002
	MOVEQ	#2,D1			;572: 7202
	BSR.W	LAB_0050		;574: 610000d0
LAB_0042:
	MOVEA.L	A2,A0			;578: 204a
	BSR.W	LAB_0055		;57a: 610000fa
	LEA	128(A2),A0		;57e: 41ea0080
	BSR.W	LAB_0055		;582: 610000f2
	LEA	256(A2),A0		;586: 41ea0100
	BSR.W	LAB_0055		;58a: 610000ea
	MOVEQ	#-1,D0			;58e: 70ff
	MOVEQ	#16,D1			;590: 7210
	BSR.W	LAB_0050		;592: 610000b2
	MOVE.W	D0,D4			;596: 3800
	SUBQ.W	#1,D4			;598: 5344
	BRA.S	LAB_0045		;59a: 601c
LAB_0043:
	LEA	128(A2),A0		;59c: 41ea0080
	MOVEQ	#0,D0			;5a0: 7000
	BSR.S	LAB_004C		;5a2: 616c
	NEG.L	D0			;5a4: 4480
	LEA	-1(A5,D0.L),A1		;5a6: 43f508ff
	LEA	256(A2),A0		;5aa: 41ea0100
	BSR.S	LAB_004C		;5ae: 6160
	MOVE.B	(A1)+,(A5)+		;5b0: 1ad9
LAB_0044:
	MOVE.B	(A1)+,(A5)+		;5b2: 1ad9
	DBF	D0,LAB_0044		;5b4: 51c8fffc
LAB_0045:
	MOVEA.L	A2,A0			;5b8: 204a
	BSR.S	LAB_004C		;5ba: 6154
	SUBQ.W	#1,D0			;5bc: 5340
	BMI.S	LAB_0047		;5be: 6b1a
LAB_0046:
	MOVE.B	(A3)+,(A5)+		;5c0: 1adb
	DBF	D0,LAB_0046		;5c2: 51c8fffc
	MOVE.B	1(A3),D0		;5c6: 102b0001
	ROL.W	#8,D0			;5ca: e158
	MOVE.B	(A3),D0			;5cc: 1013
	LSL.L	D7,D0			;5ce: efa8
	MOVEQ	#1,D1			;5d0: 7201
	LSL.W	D7,D1			;5d2: ef69
	SUBQ.W	#1,D1			;5d4: 5341
	AND.L	D1,D6			;5d6: cc81
	OR.L	D0,D6			;5d8: 8c80
LAB_0047:
	DBF	D4,LAB_0043		;5da: 51ccffc0
	CMPA.L	A6,A5			;5de: bbce
	BCS.S	LAB_0042		;5e0: 6596
	MOVE.W	(A7)+,D0		;5e2: 301f
	BEQ.S	LAB_0049		;5e4: 670a
	MOVEA.L	A5,A0			;5e6: 204d
LAB_0048:
	MOVE.W	(A7)+,D1		;5e8: 321f
	MOVE.B	D1,(A0)+		;5ea: 10c1
	SUBQ.B	#1,D0			;5ec: 5300
	BNE.S	LAB_0048		;5ee: 66f8
LAB_0049:
	MOVE.L	514(A7),D0		;5f0: 202f0202
	SUBA.L	D0,A5			;5f4: 9bc0
	MOVEA.L	A5,A1			;5f6: 224d
	BSR.W	LAB_005C		;5f8: 61000104
	MOVEQ	#-2,D1			;5fc: 72fe
	CMP.W	(A7)+,D2		;5fe: b45f
	BEQ.S	LAB_004B		;600: 6704
LAB_004A:
	MOVE.L	D1,512(A7)		;602: 2f410200
LAB_004B:
	LEA	512(A7),A7		;606: 4fef0200
	MOVEM.L	(A7)+,D0-D7/A0-A6	;60a: 4cdf7fff
	RTS				;60e: 4e75

LAB_004C:
	MOVE.W	(A0)+,D0		;610: 3018
	AND.W	D6,D0			;612: c046
	SUB.W	(A0)+,D0		;614: 9058
	BNE.S	LAB_004C		;616: 66f8
	MOVE.B	60(A0),D1		;618: 1228003c
	SUB.B	D1,D7			;61c: 9e01
	BGE.S	LAB_004D		;61e: 6c02
	BSR.S	LAB_0052		;620: 6130
LAB_004D:
	LSR.L	D1,D6			;622: e2ae
	MOVE.B	61(A0),D0		;624: 1028003d
	CMPI.B	#$02,D0			;628: 0c000002
	BLT.S	LAB_004F		;62c: 6d16
	SUBQ.B	#1,D0			;62e: 5300
	MOVE.B	D0,D1			;630: 1200
	MOVE.B	D0,D2			;632: 1400
	MOVE.W	62(A0),D0		;634: 3028003e
	AND.W	D6,D0			;638: c046
	SUB.B	D1,D7			;63a: 9e01
	BGE.S	LAB_004E		;63c: 6c02
	BSR.S	LAB_0052		;63e: 6112
LAB_004E:
	LSR.L	D1,D6			;640: e2ae
	BSET	D2,D0			;642: 05c0
LAB_004F:
	RTS				;644: 4e75

LAB_0050:
	AND.W	D6,D0			;646: c046
	SUB.B	D1,D7			;648: 9e01
	BGE.S	LAB_0051		;64a: 6c02
	BSR.S	LAB_0052		;64c: 6104
LAB_0051:
	LSR.L	D1,D6			;64e: e2ae
	RTS				;650: 4e75

LAB_0052:
	ADD.B	D1,D7			;652: de01
	LSR.L	D7,D6			;654: eeae
	SWAP	D6			;656: 4846
	ADDQ.W	#4,A3			;658: 584b
	MOVE.B	-(A3),D6		;65a: 1c23
	ROL.W	#8,D6			;65c: e15e
	MOVE.B	-(A3),D6		;65e: 1c23
	SWAP	D6			;660: 4846
	SUB.B	D7,D1			;662: 9207
	MOVEQ	#16,D7			;664: 7e10
	SUB.B	D1,D7			;666: 9e01
	RTS				;668: 4e75

LAB_0053:
	MOVEQ	#3,D1			;66a: 7203
LAB_0054:
	LSL.L	#8,D0			;66c: e188
	MOVE.B	(A0)+,D0		;66e: 1018
	DBF	D1,LAB_0054		;670: 51c9fffa
	RTS				;674: 4e75

LAB_0055:
	MOVEQ	#31,D0			;676: 701f
	MOVEQ	#5,D1			;678: 7205
	BSR.S	LAB_0050		;67a: 61ca
	SUBQ.W	#1,D0			;67c: 5340
	BMI.S	LAB_005B		;67e: 6b7c
	MOVE.W	D0,D2			;680: 3400
	MOVE.W	D0,D3			;682: 3600
	LEA	-16(A7),A7		;684: 4feffff0
	MOVEA.L	A7,A1			;688: 224f
LAB_0056:
	MOVEQ	#15,D0			;68a: 700f
	MOVEQ	#4,D1			;68c: 7204
	BSR.S	LAB_0050		;68e: 61b6
	MOVE.B	D0,(A1)+		;690: 12c0
	DBF	D2,LAB_0056		;692: 51cafff6
	MOVEQ	#1,D0			;696: 7001
	ROR.L	#1,D0			;698: e298
	MOVEQ	#1,D1			;69a: 7201
	MOVEQ	#0,D2			;69c: 7400
	MOVEM.L	D5-D7,-(A7)		;69e: 48e70700
LAB_0057:
	MOVE.W	D3,D4			;6a2: 3803
	LEA	12(A7),A1		;6a4: 43ef000c
LAB_0058:
	CMP.B	(A1)+,D1		;6a8: b219
	BNE.S	LAB_005A		;6aa: 663a
	MOVEQ	#1,D5			;6ac: 7a01
	LSL.W	D1,D5			;6ae: e36d
	SUBQ.W	#1,D5			;6b0: 5345
	MOVE.W	D5,(A0)+		;6b2: 30c5
	MOVE.L	D2,D5			;6b4: 2a02
	SWAP	D5			;6b6: 4845
	MOVE.W	D1,D7			;6b8: 3e01
	SUBQ.W	#1,D7			;6ba: 5347
LAB_0059:
	ROXL.W	#1,D5			;6bc: e355
	ROXR.W	#1,D6			;6be: e256
	DBF	D7,LAB_0059		;6c0: 51cffffa
	MOVEQ	#16,D5			;6c4: 7a10
	SUB.B	D1,D5			;6c6: 9a01
	LSR.W	D5,D6			;6c8: ea6e
	MOVE.W	D6,(A0)+		;6ca: 30c6
	MOVE.B	D1,60(A0)		;6cc: 1141003c
	MOVE.B	D3,D5			;6d0: 1a03
	SUB.B	D4,D5			;6d2: 9a04
	MOVE.B	D5,61(A0)		;6d4: 1145003d
	MOVEQ	#1,D6			;6d8: 7c01
	SUBQ.B	#1,D5			;6da: 5305
	LSL.W	D5,D6			;6dc: eb6e
	SUBQ.W	#1,D6			;6de: 5346
	MOVE.W	D6,62(A0)		;6e0: 3146003e
	ADD.L	D0,D2			;6e4: d480
LAB_005A:
	DBF	D4,LAB_0058		;6e6: 51ccffc0
	LSR.L	#1,D0			;6ea: e288
	ADDQ.B	#1,D1			;6ec: 5201
	CMPI.B	#$11,D1			;6ee: 0c010011
	BNE.S	LAB_0057		;6f2: 66ae
	MOVEM.L	(A7)+,D5-D7		;6f4: 4cdf00e0
	LEA	16(A7),A7		;6f8: 4fef0010
LAB_005B:
	RTS				;6fc: 4e75

LAB_005C:
	MOVEA.L	A2,A0			;6fe: 204a
	MOVEQ	#0,D3			;700: 7600
LAB_005D:
	MOVE.L	D3,D1			;702: 2203
	MOVEQ	#7,D2			;704: 7407
LAB_005E:
	LSR.W	#1,D1			;706: e249
	BCC.S	LAB_005F		;708: 6404
	EORI.W	#$a001,D1		;70a: 0a41a001
LAB_005F:
	DBF	D2,LAB_005E		;70e: 51cafff6
	MOVE.W	D1,(A0)+		;712: 30c1
	ADDQ.B	#1,D3			;714: 5203
	BNE.S	LAB_005D		;716: 66ea
	MOVEQ	#0,D2			;718: 7400
LAB_0060:
	MOVE.B	(A1)+,D1		;71a: 1219
	EOR.B	D1,D2			;71c: b302
	MOVE.W	D2,D1			;71e: 3202
	ANDI.W	#$00ff,D2		;720: 024200ff
	ADD.W	D2,D2			;724: d442
	MOVE.W	0(A2,D2.W),D2		;726: 34322000
	LSR.W	#8,D1			;72a: e049
	EOR.B	D1,D2			;72c: b302
	SUBQ.L	#1,D0			;72e: 5380
	BNE.S	LAB_0060		;730: 66e8
	RTS				;732: 4e75


    
password:
	ds.b	16,0
code_letters:
	dc.b	"BCDFGHJKLMNPQRSTVWXYZ0123456789#",0
code_values:
    ;		B   C   D   F   G   H   J   K   L   M   N   P   Q   R   S   T   V   W   X   Y   Z
    dc.b	$15,$16,$17,$19,$1A,$1B,$1D,$1E,$1F,$20,$21,$23,$24,$25,$26,$27,$29,$2A,$2B,$2C,$2D
	;       0   1   2   3   4   5   6   7   8   9   #
	dc.b	$2F,$30,$31,$32,$33,$34,$35,$36,$37,$38,$3A
    even