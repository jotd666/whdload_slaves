; Resourced by whdslave_resourcer v0.91
; a program written by JOTD in 2016-2019
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	IFD BARFLY
	OUTPUT	"SkeletonKrewAGA.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC
_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 10)
	dc.w	WHDLF_NoError|WHDLF_NoKbd
	dc.l	$200000					; ws_basememsize
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
    dc.b    "C1:B:Infinite lives;"
	dc.b    "C3:L:Start level:Monstrocity,Lift Shaft,Clear All Aliens,"
	dc.b	"Clear All Aliens 2,Clear All Aliens 3,Clear All Aliens 4,"
	dc.b	"Jungle,Mars,Venus,Kadaver,End sequence;"			
	dc.b	"C4:L:Control method P1:Joy1,Joy2,Joy3,2 button joypad;"
	dc.b	"C5:L:Control method P2:Joy1,Joy2,Joy3,2 button joypad;"
	dc.b	0
_start_level
	dc.b	0	; monstrocity
	dc.b	3	; lift shaft
	dc.b    4,6,8,10 ; clear all aliens
	dc.b	13	; jungle
	dc.b	$19	; mars
	dc.b	$13	; venus
	dc.b	$1B	; kadaver
	dc.b	$1D	; end sequence
_start_level_end
	dc.b	$1D	; just in case..
_nb_levels:
	dc.b	_start_level_end-_start_level
	even
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"3.0"
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
_name	dc.b	'Skeleton Krew',0
_copy	dc.b	'1995 Core Design',0
_info
    dc.b   'installed by MiCK & JOTD',10
	dc.b	'Version '
	DECL_VERSION
	dc.b	0
	dc.b	'Greetings to Bored Seal & JHZ',0

; end of game: 00101D5E 66f6                     BNE.B #$f6 == $00101d56 (T)
; infinite loop

                      ;$00000000
;--- version id
    dc.b	0
    even

CIAA_SDR	EQU	$BFEC01
INTREQ		EQU	$DFF09C

start:
	LEA	_resload(PC),A1
	MOVE.L	A0,(A1)
	MOVE.L	#$00000102,D0
	MOVE.L	#$00000303,D1
	MOVEA.L	_resload(PC),A2
	JSR	resload_SetCPU(A2)
	
	lea	_tags(pc),a0
	jsr	(resload_Control,a2)
	
	LEA	disk_number(PC),A0		;0a6: 41fa0196
	MOVE.W	#$0001,(A0)		;0aa: 30bc0001
	MOVEQ	#104,D1			;0ae: 7268
	MOVEQ	#24,D2			;0b0: 7418
	LEA	$7a000,A0
	BSR.W	load_disk		;0b8: 61000130
	MOVEA.L	A0,A1			;0bc: 2248
	LEA	562(A0),A0		;0be: 41e80232
	BSR.W	decrunch		;0c2: 61000112

	patch	$100,patch_main
	
	lea	pl_boot(pc),a0
	lea	$7A000,a1
	jsr	(resload_Patch,a2)
	
	JMP	$7A000		;112: 4ef90007a000

pl_boot
	PL_START
	PL_W	$232,$100
	PL_P	$9b6,keyboard_interrupt
	PL_P	$1950,toggle_disk_and_load
	PL_P	$41c2,rnc_decrunch
	PL_END
	
read_2nd_button:
	MOVE.B $00dff016,$12f5 	; original
	move.W	#$FF00,$DFF034	; required for standard 2-button joysticks
	RTS
	
patch_main
	movem.l	d0-d1/a0-a2,-(a7)
	; tweaks start level
	move.l	_start_level_index(pc),d0
	cmp.b	_nb_levels(pc),d0
	bcc.b	.skip
	lea	_start_level(pc),a0
	move.b	(a0,d0.l),$21AD2+3
.skip
	; default control options (avoids entering the options)
	move.l	_control_method_player_1(pc),d0
	and.w	#$3,d0
	move.w	d0,$1F862
	move.l	_control_method_player_2(pc),d0
	and.w	#$3,d0
	move.w	d0,$1F868
	
	move.l	_resload(pc),a2
	lea	pl_main(pc),a0
	sub.l	a1,a1
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	JMP	$500.W
pl_main
	PL_START
	PL_IFC1
	PL_NOP	$A314,4  ; 5368 0008                SUB.W #$01,(A0,$0008) == $00001050 [0004]
	PL_B	$A318,$60
	PL_ENDIF
	; fixes second button read for non CD32 joypads
	PL_PSS	$1300,read_2nd_button,2
	; protection?
	PL_L	$130e0,$26bc42ed
	PL_L	$130e4,$69c44e75
	
	PL_PS	$1804,keyboard_interrupt
	PL_P	$129F8,ack_interrupts
	PL_P	$12a60,ack_interrupts
	PL_P	$13dd6,ack_interrupts
	PL_P	$13e84,ack_interrupts
	PL_P	$254d0,toggle_disk_and_load
	PL_P	$28d44,rnc_decrunch
	
	; try to fix access fault
	PL_PS	$923A,fix_af
	
	; end sequence
	PL_P	$16942,end_sequence

	PL_END
	
end_sequence:
	lea	$100000,a1
	lea	($232,a1),a0
	bsr	decrunch
	lea	pl_end(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	lea	$100000,a1
	JMP (a1)

pl_end
	PL_START
	PL_P	$1824,load_disk
	PL_P	$5096,rnc_decrunch
	PL_END
	
;0000923A 4211                     CLR.B (A1) [39]
;0000923C 4212                     CLR.B (A2) [00]
;0000923E 4213                     CLR.B (A3) [00]
;00009240 4214                     CLR.B (A4) [01]
;00009242 4e75                     RTS
;00009244 2f0b                     MOVE.L A3,-(A7) [00019740]
;00009246 4bf8 0c38                LEA.L $0c38,A5
;0000924A 47ea 0068                LEA.L (A2,$0068) == $00053354,A3

	
fix_af
	; rarely happens: access fault on A1
	; emulating by masking highest byte
	; (24 bit address looks okay)
	move.l	D0,-(a7)
	move.l	a1,d0
	and.l	#$FFFFFF,d0
	move.l	d0,a1
	move.l	(a7)+,d0
	CLR.B (A1)
	CLR.B (A2)
	CLR.B (A3)
	RTS
	
ack_interrupts:
	MOVE.W	#$2000,INTREQ		;1aa: 33fc200000dff09c
	MOVE.W	#$2000,INTREQ		;1b2: 33fc200000dff09c
	NOP				;1ba: 4e71
	NOP				;1bc: 4e71
	RTE				;1be: 4e73

keyboard_interrupt:
	MOVE.B	CIAA_SDR,D0		;1c0: 103900bfec01
	MOVE.L	D0,-(A7)		;1c6: 2f00
	NOT.B	D0			;1c8: 4600
	ROR.B	#1,D0			;1ca: e218
	CMP.B	_keyexit(PC),D0	;1cc: b03afe51
	BEQ.S	_quit		;1d0: 6756
	MOVE.L	(A7)+,D0		;1d2: 201f
	RTS				;1d4: 4e75

decrunch:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;1d6: 48e7fffe
	MOVEA.L	_resload(PC),A2		;1da: 247a005e
	JSR	resload_Decrunch(A2)	;1de (offset=18)
	MOVEM.L	(A7)+,D0-D7/A0-A6	;1e2: 4cdf7fff
	RTS				;1e6: 4e75

toggle_disk_and_load:
	BSR.S	toggle_disk		;1e8: 612a
load_disk:
	MOVEM.L	D0-D2/A0-A2,-(A7)	;1ea: 48e7e0e0
	MOVEQ	#0,D0			;1ee: 7000
	MOVE.W	D1,D0			;1f0: 3001
	MOVEQ	#0,D1			;1f2: 7200
	MOVE.W	D2,D1			;1f4: 3202
	MULU	#$0200,D0		;1f6: c0fc0200
	MULU	#$0200,D1		;1fa: c2fc0200
	MOVEQ	#0,D2			;1fe: 7400
	MOVE.W	disk_number(PC),D2		;200: 343a003c
	MOVEA.L	_resload(PC),A2		;204: 247a0034
	JSR	resload_DiskLoad(A2)	;208 (offset=28)
	MOVEM.L	(A7)+,D0-D2/A0-A2	;20c: 4cdf0707
	MOVEQ	#0,D0			;210: 7000
	RTS				;212: 4e75

toggle_disk:
	TST.B	D0			;214: 4a00
	BNE.S	LAB_0008		;216: 6604
	MOVE.W	#$0001,D0		;218: 303c0001
LAB_0008:
	MOVE.L	A0,-(A7)		;21c: 2f08
	LEA	disk_number(PC),A0		;21e: 41fa001e
	MOVE.W	D0,(A0)			;222: 3080
	MOVEA.L	(A7)+,A0		;224: 205f
	RTS				;226: 4e75

_quit:
	PEA	TDREASON_OK			;228: 4878ffff
	MOVE.L	_resload(PC),-(A7)	;232: 2f3a0006
	ADDQ.L	#4,(A7)			;236: 5897
	RTS				;238: 4e75

_resload:
	dc.l	0			;23a: 00000000
disk_number:
	DC.B	$0	;23e
	DC.B	$0	;23f
rnc_decrunch:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;240: 48e7fffe
	LEA	-384(A7),A7		;244: 4feffe80
	MOVEA.L	A7,A2			;248: 244f
	BSR.W	LAB_0025		;24a: 6100016c
	MOVEQ	#0,D1			;24e: 7200
	CMPI.L	#$524e4301,D0		;250: 0c80524e4301
	BNE.W	LAB_001C		;256: 660000f8
	BSR.W	LAB_0025		;25a: 6100015c
	MOVE.L	D0,384(A7)		;25e: 2f400180
	LEA	10(A0),A3		;262: 47e8000a
	MOVEA.L	A1,A5			;266: 2a49
	LEA	0(A5,D0.L),A6		;268: 4df50800
	BSR.W	LAB_0025		;26c: 6100014a
	LEA	0(A3,D0.L),A4		;270: 49f30800
	CLR.W	-(A7)			;274: 4267
	CMPA.L	A4,A5			;276: bbcc
	BCC.S	LAB_0013		;278: 644c
	MOVEQ	#0,D0			;27a: 7000
	MOVE.B	-2(A3),D0		;27c: 102bfffe
	LEA	0(A6,D0.L),A0		;280: 41f60800
	CMPA.L	A4,A0			;284: b1cc
	BLS.S	LAB_0013		;286: 633e
	ADDQ.W	#2,A7			;288: 544f
	MOVE.L	A4,D0			;28a: 200c
	BTST	#0,D0			;28c: 08000000
	BEQ.S	LAB_000E		;290: 6704
	ADDQ.W	#1,A4			;292: 524c
	ADDQ.W	#1,A0			;294: 5248
LAB_000E:
	MOVE.L	A0,D0			;296: 2008
	BTST	#0,D0			;298: 08000000
	BEQ.S	LAB_000F		;29c: 6702
	ADDQ.W	#1,A0			;29e: 5248
LAB_000F:
	MOVEQ	#0,D0			;2a0: 7000
LAB_0010:
	CMPA.L	A0,A6			;2a2: bdc8
	BEQ.S	LAB_0011		;2a4: 6708
	MOVE.B	-(A0),D1		;2a6: 1220
	MOVE.W	D1,-(A7)		;2a8: 3f01
	ADDQ.B	#1,D0			;2aa: 5200
	BRA.S	LAB_0010		;2ac: 60f4
LAB_0011:
	MOVE.W	D0,-(A7)		;2ae: 3f00
	ADDA.L	D0,A0			;2b0: d1c0
LAB_0012:
	LEA	-32(A4),A4		;2b2: 49ecffe0
	MOVEM.L	(A4),D0-D7		;2b6: 4cd400ff
	MOVEM.L	D0-D7,-(A0)		;2ba: 48e0ff00
	CMPA.L	A3,A4			;2be: b9cb
	BHI.S	LAB_0012		;2c0: 62f0
	SUBA.L	A4,A3			;2c2: 97cc
	ADDA.L	A0,A3			;2c4: d7c8
LAB_0013:
	MOVEQ	#0,D7			;2c6: 7e00
	MOVE.B	1(A3),D6		;2c8: 1c2b0001
	ROL.W	#8,D6			;2cc: e15e
	MOVE.B	(A3),D6			;2ce: 1c13
	MOVEQ	#2,D0			;2d0: 7002
	MOVEQ	#2,D1			;2d2: 7202
	BSR.W	LAB_0022		;2d4: 610000be
LAB_0014:
	MOVEA.L	A2,A0			;2d8: 204a
	BSR.W	LAB_0027		;2da: 610000e8
	LEA	128(A2),A0		;2de: 41ea0080
	BSR.W	LAB_0027		;2e2: 610000e0
	LEA	256(A2),A0		;2e6: 41ea0100
	BSR.W	LAB_0027		;2ea: 610000d8
	MOVEQ	#-1,D0			;2ee: 70ff
	MOVEQ	#16,D1			;2f0: 7210
	BSR.W	LAB_0022		;2f2: 610000a0
	MOVE.W	D0,D4			;2f6: 3800
	SUBQ.W	#1,D4			;2f8: 5344
	BRA.S	LAB_0017		;2fa: 601c
LAB_0015:
	LEA	128(A2),A0		;2fc: 41ea0080
	MOVEQ	#0,D0			;300: 7000
	BSR.S	LAB_001E		;302: 615a
	NEG.L	D0			;304: 4480
	LEA	-1(A5,D0.L),A1		;306: 43f508ff
	LEA	256(A2),A0		;30a: 41ea0100
	BSR.S	LAB_001E		;30e: 614e
	MOVE.B	(A1)+,(A5)+		;310: 1ad9
LAB_0016:
	MOVE.B	(A1)+,(A5)+		;312: 1ad9
	DBF	D0,LAB_0016		;314: 51c8fffc
LAB_0017:
	MOVEA.L	A2,A0			;318: 204a
	BSR.S	LAB_001E		;31a: 6142
	SUBQ.W	#1,D0			;31c: 5340
	BMI.S	LAB_0019		;31e: 6b1a
LAB_0018:
	MOVE.B	(A3)+,(A5)+		;320: 1adb
	DBF	D0,LAB_0018		;322: 51c8fffc
	MOVE.B	1(A3),D0		;326: 102b0001
	ROL.W	#8,D0			;32a: e158
	MOVE.B	(A3),D0			;32c: 1013
	LSL.L	D7,D0			;32e: efa8
	MOVEQ	#1,D1			;330: 7201
	LSL.W	D7,D1			;332: ef69
	SUBQ.W	#1,D1			;334: 5341
	AND.L	D1,D6			;336: cc81
	OR.L	D0,D6			;338: 8c80
LAB_0019:
	DBF	D4,LAB_0015		;33a: 51ccffc0
	CMPA.L	A6,A5			;33e: bbce
	BCS.S	LAB_0014		;340: 6596
	MOVE.W	(A7)+,D0		;342: 301f
	BEQ.S	LAB_001B		;344: 6708
LAB_001A:
	MOVE.W	(A7)+,D1		;346: 321f
	MOVE.B	D1,(A5)+		;348: 1ac1
	SUBQ.B	#1,D0			;34a: 5300
	BNE.S	LAB_001A		;34c: 66f8
LAB_001B:
	BRA.S	LAB_001D		;34e: 6004
LAB_001C:
	MOVE.L	D1,384(A7)		;350: 2f410180
LAB_001D:
	LEA	384(A7),A7		;354: 4fef0180
	MOVEM.L	(A7)+,D0-D7/A0-A6	;358: 4cdf7fff
	RTS				;35c: 4e75

LAB_001E:
	MOVE.W	(A0)+,D0		;35e: 3018
	AND.W	D6,D0			;360: c046
	SUB.W	(A0)+,D0		;362: 9058
	BNE.S	LAB_001E		;364: 66f8
	MOVE.B	60(A0),D1		;366: 1228003c
	SUB.B	D1,D7			;36a: 9e01
	BGE.S	LAB_001F		;36c: 6c02
	BSR.S	LAB_0024		;36e: 6130
LAB_001F:
	LSR.L	D1,D6			;370: e2ae
	MOVE.B	61(A0),D0		;372: 1028003d
	CMPI.B	#$02,D0			;376: 0c000002
	BLT.S	LAB_0021		;37a: 6d16
	SUBQ.B	#1,D0			;37c: 5300
	MOVE.B	D0,D1			;37e: 1200
	MOVE.B	D0,D2			;380: 1400
	MOVE.W	62(A0),D0		;382: 3028003e
	AND.W	D6,D0			;386: c046
	SUB.B	D1,D7			;388: 9e01
	BGE.S	LAB_0020		;38a: 6c02
	BSR.S	LAB_0024		;38c: 6112
LAB_0020:
	LSR.L	D1,D6			;38e: e2ae
	BSET	D2,D0			;390: 05c0
LAB_0021:
	RTS				;392: 4e75

LAB_0022:
	AND.W	D6,D0			;394: c046
	SUB.B	D1,D7			;396: 9e01
	BGE.S	LAB_0023		;398: 6c02
	BSR.S	LAB_0024		;39a: 6104
LAB_0023:
	LSR.L	D1,D6			;39c: e2ae
	RTS				;39e: 4e75

LAB_0024:
	ADD.B	D1,D7			;3a0: de01
	LSR.L	D7,D6			;3a2: eeae
	SWAP	D6			;3a4: 4846
	ADDQ.W	#4,A3			;3a6: 584b
	MOVE.B	-(A3),D6		;3a8: 1c23
	ROL.W	#8,D6			;3aa: e15e
	MOVE.B	-(A3),D6		;3ac: 1c23
	SWAP	D6			;3ae: 4846
	SUB.B	D7,D1			;3b0: 9207
	MOVEQ	#16,D7			;3b2: 7e10
	SUB.B	D1,D7			;3b4: 9e01
	RTS				;3b6: 4e75

LAB_0025:
	MOVEQ	#3,D1			;3b8: 7203
LAB_0026:
	LSL.L	#8,D0			;3ba: e188
	MOVE.B	(A0)+,D0		;3bc: 1018
	DBF	D1,LAB_0026		;3be: 51c9fffa
	RTS				;3c2: 4e75

LAB_0027:
	MOVEQ	#31,D0			;3c4: 701f
	MOVEQ	#5,D1			;3c6: 7205
	BSR.S	LAB_0022		;3c8: 61ca
	SUBQ.W	#1,D0			;3ca: 5340
	BMI.S	LAB_002D		;3cc: 6b7c
	MOVE.W	D0,D2			;3ce: 3400
	MOVE.W	D0,D3			;3d0: 3600
	LEA	-16(A7),A7		;3d2: 4feffff0
	MOVEA.L	A7,A1			;3d6: 224f
LAB_0028:
	MOVEQ	#15,D0			;3d8: 700f
	MOVEQ	#4,D1			;3da: 7204
	BSR.S	LAB_0022		;3dc: 61b6
	MOVE.B	D0,(A1)+		;3de: 12c0
	DBF	D2,LAB_0028		;3e0: 51cafff6
	MOVEQ	#1,D0			;3e4: 7001
	ROR.L	#1,D0			;3e6: e298
	MOVEQ	#1,D1			;3e8: 7201
	MOVEQ	#0,D2			;3ea: 7400
	MOVEM.L	D5-D7,-(A7)		;3ec: 48e70700
LAB_0029:
	MOVE.W	D3,D4			;3f0: 3803
	LEA	12(A7),A1		;3f2: 43ef000c
LAB_002A:
	CMP.B	(A1)+,D1		;3f6: b219
	BNE.S	LAB_002C		;3f8: 663a
	MOVEQ	#1,D5			;3fa: 7a01
	LSL.W	D1,D5			;3fc: e36d
	SUBQ.W	#1,D5			;3fe: 5345
	MOVE.W	D5,(A0)+		;400: 30c5
	MOVE.L	D2,D5			;402: 2a02
	SWAP	D5			;404: 4845
	MOVE.W	D1,D7			;406: 3e01
	SUBQ.W	#1,D7			;408: 5347
LAB_002B:
	ROXL.W	#1,D5			;40a: e355
	ROXR.W	#1,D6			;40c: e256
	DBF	D7,LAB_002B		;40e: 51cffffa
	MOVEQ	#16,D5			;412: 7a10
	SUB.B	D1,D5			;414: 9a01
	LSR.W	D5,D6			;416: ea6e
	MOVE.W	D6,(A0)+		;418: 30c6
	MOVE.B	D1,60(A0)		;41a: 1141003c
	MOVE.B	D3,D5			;41e: 1a03
	SUB.B	D4,D5			;420: 9a04
	MOVE.B	D5,61(A0)		;422: 1145003d
	MOVEQ	#1,D6			;426: 7c01
	SUBQ.B	#1,D5			;428: 5305
	LSL.W	D5,D6			;42a: eb6e
	SUBQ.W	#1,D6			;42c: 5346
	MOVE.W	D6,62(A0)		;42e: 3146003e
	ADD.L	D0,D2			;432: d480
LAB_002C:
	DBF	D4,LAB_002A		;434: 51ccffc0
	LSR.L	#1,D0			;438: e288
	ADDQ.B	#1,D1			;43a: 5201
	CMPI.B	#$11,D1			;43c: 0c010011
	BNE.S	LAB_0029		;440: 66ae
	MOVEM.L	(A7)+,D5-D7		;442: 4cdf00e0
	LEA	16(A7),A7		;446: 4fef0010
LAB_002D:
	RTS				;44a: 4e75



_tags		
		dc.l	WHDLTAG_CUSTOM4_GET
_control_method_player_1
		dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_control_method_player_2
		dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_start_level_index
		dc.l	0
		dc.l	0