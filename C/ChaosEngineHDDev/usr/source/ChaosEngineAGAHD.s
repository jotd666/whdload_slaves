; *** The Chaos Engine AGA Hard Disk Loader V1.0
; *** Written by Mick/JOTD © 2001-2020

; Mick I think you used some of my JST code to create this one...

		INCDIR	include:
		INCLUDE	"whdload.i"
		INCLUDE	"whdmacros.i"

	IFD BARFLY
	OUTPUT	"ChaosEngineAGA.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC



CHIPMEMSIZE = $1FF000

_base
		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_ReqAGA|WHDLF_Req68020		;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	$0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug
		dc.b	0			;ws_keydebug
_keyexit
		dc.b	$59			;ws_keyexit = F10
		dc.l	0
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config


    include ReadJoyPad.s
    include shared.s

_name
		dc.b	"The Chaos Engine AGA",0
_copy
		dc.b	"1992/93 The Bitmap Brothers",0
_info
		dc.b	"installed by MiCK & JOTD",10,10
		dc.b	"Thanks to Codetapper for RawDIC slave code",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
    
_config
    dc.b    "BW;"
    dc.b    "C1:X:Trainer Infinite Energy:0;"
    dc.b    "C1:X:Trainer 99 Lives:1;"
	dc.b	0
    even
        

_start
	lea	CHIPMEMSIZE-$100,A7

    
	lea	(_resload,pc),A1
	move.l	A0,(A1)			;save for later using
	move.l	A0,A2
	lea	(_tags,pc),A0
	jsr	(resload_Control,A2)

    ;get password
    lea	(password,pc),a0
    moveq.l	#0,d1
    move.l	#13,d0
    jsr	(resload_GetCustom,a2)


	move.l	#WCPUF_Base_WT|WCPUF_IC,D0
	move.l	#WCPUF_Base|WCPUF_IC|WCPUF_DC,D1
	move.l	(_resload,pc),A2
	jsr	(resload_SetCPU,A2)	; to enable caches

	; set disk 1 artificially

	move.l	(gamebase,pc),A0
	add.l	#$12C19,a0
	move.b	#'1',(a0)	; disk 1

	; to load boot sector (DOS tracks at start of disk 1)
	
	move.l	(gamebase,pc),A0
	move.l	#$3,D1
	move.l	#$9e,D2
	moveq	#0,d3
	bsr	robread

	move.l	(gamebase,pc),A0
	lea	$274(A0),A0
	move.l	A0,A1

	bsr	decrunch
	bsr	Reloc
    
	move.l	(gamebase,pc),A1
    add.l #$B1EE,a1
    bsr restore_password

	move.l	(gamebase,pc),A1
	bsr	patch_main

	move.l	(gamebase,pc),A0
	lea	$274(A0),A0
	jmp	(A0)

patch_main
	movem.l	D0-D7/A0-A6,-(A7)
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(A7)+,D0-D7/A0-A6
	rts		


pl_main
	PL_START
	PL_L	$72+$274,$4E714E71	; CACR access
	PL_P	$50AA+$274,robread	; disk load
	PL_PSS	$BFB2+$274,kbint,4	; keyboard
	PL_NOP	$C054+$274,2	; remove a timer check for KB
	PL_P	$1F144,decrunch2
	PL_W	$52F4,$203C
	PL_W	$52FA,$6004
	PL_W	$12BF6,$203C
	PL_W	$12C02,$6004
    
    PL_IFC1X    0
	PL_NOP	$798,6
    PL_ENDIF
    PL_IFC1X    1
	PL_PSS	$ECE,set_lives,2
    PL_ENDIF
    
    PL_PS   $640,_joypad_buttons_loop_aga
    PL_PS   $83e,_pause_test_aga
    PL_PS   $8ce,_pause_test_aga
    PL_PS   $8de,_pause_test_aga
    PL_PS   $8e6,_pause_test_aga

    PL_PS   $00003E9E,_level3_interrupt_hook

    PL_IFBW
    PL_PS    $37c2,_level_loaded
    PL_ENDIF
    
	PL_END

    
    JOY_FUNCS    aga,2063


kbint:
	move.b	#$19,$E00(A0)
.loop
	btst	#0,$BFE001
	bne	.loop

	ror.b	#1,D0
	not.b	D0
	cmp.b	_keyexit(pc),D0
	bne	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	rts



Reloc
	movem.l	D0-D7/A0-A6,-(A7)
	move.l	(gamebase,pc),A0
	lea	$274(A0),A0
	move.l	A0,A1
	add.l	#$8501C,A1
Reloc_
	move.l	(A1)+,D0
	beq	End
	move.l	$0(A0,D0.L),D1
	add.l	A0,D1
	move.l	D1,$0(A0,D0.L)
	bra	Reloc_
End
	movem.l	(A7)+,D0-D7/A0-A6
	rts
_exit		pea	TDREASON_OK.w
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
;resload_DiskLoad(offset,size,diskno,dest)
;          D0       D1                          D0    D1    D2    A0
;         BOOL    ULONG                        ULONG ULONG UBYTE APTR

; Modified Rob Northen track loading routine
; < A0: buffer
; < D0: disk number
; < D1: sector offset (*$200)
; < D2: sector length (*$200)
; < D3: command (in this game, I ignore command 3 with return code 1,
;       and I know that sometimes D3=1 and you have to read anyway
;       this gave me a tough time when I resumed WHDLoad slave work
;       from an old MiCK slave (fortunately I had my old JST slave source!)
;
; > D0: 0 if ok

robread:
	movem.l	d1-d4/a0-a2,-(A7)
    ; re-detect controllers plugged in at each load
    bsr _detect_controller_types

	move.l	gamebase(pc),A2
	add.l	#$129A5+$274,A2
	move.b	(A2),D0		; '1' or '2'
	sub.l	#'1',d0

	and.l	#$FF,D3
	cmp.w	#3,d0
	beq.b	.exit_error

	cmp.l	#1,d0
	beq.b	.disk2
.disk1
	move.l	#$1E00,d4		; protected RN subtract offset on disk 1 ($F*$200)
	cmp.w	#$A5,d1
	bcc.b	.cont
	; boot
	moveq.l	#0,d4			; DOS tracks on disk 1
	bra.b	.cont
.disk2
	move.l	#$B4*$200,d4		; protected RN subtract offset on disk 2
	moveq	#1,d0
.cont
	move.l	d0,d3		; disk number stored
	
	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.exit		; length=0: out

	move.l	D1,D0
	ext.l	d0
	lsl.l	#7,d0			;diskoffset
	lsl.l	#2,d0

	; adjust because
	; - first 15 tracks are shorter
	; - disk 2 starts at track 16

	sub.l	d4,d0

	move.l	D2,D1			;len to read
	ext.l	d1
	lsl.l	#7,d1
	lsl.l	#2,d1

	move.l	D3,D2
	addq.l	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)
.exit
	moveq.l	#0,D0
	movem.l	(A7)+,d1-d4/a0-a2
	rts
.exit_error
	moveq.l	#1,D0
	bra.b	.exit

decrunch
    movem.l	D0-D7/A0-A6,-(A7)
    move.l	(_resload,pc),A2
    jsr	(resload_Decrunch,A2)
    movem.l	(A7)+,D0-D7/A0-A6
    rts

_resload
		dc.l	0			;address of resident loader
		even

gamebase
		dc.l	$1000	; installed there

_tags
		dc.l	WHDLTAG_CUSTOM1_GET
trainer
		dc.l	0
		dc.l	0

_previous_joystate_1
      dc.l  0
_previous_joystate_0
      dc.l  0      
; Rob Northen decrunch, not the same as the one built-in in WHDLoad

decrunch2
	MOVEM.L	D0-D7/A0-A6,-(A7)	;2BC: 48E7FFFE
	LEA	-384(A7),A7		;2C0: 4FEFFE80
	MOVEA.L	A7,A2			;2C4: 244F
	BSR	.lab_0035		;2C6: 6100016C
	MOVEQ	#0,D1			;2CA: 7200
	CMPI.L	#$524E4301,D0		;2CC: 0C80524E4301
	BNE	.lab_002C		;2D2: 660000F8
	BSR	.lab_0035		;2D6: 6100015C
	MOVE.L	D0,384(A7)		;2DA: 2F400180
	LEA	10(A0),A3		;2DE: 47E8000A
	MOVEA.L	A1,A5			;2E2: 2A49
	LEA	0(A5,D0.L),A6		;2E4: 4DF50800
	BSR	.lab_0035		;2E8: 6100014A
	LEA	0(A3,D0.L),A4		;2EC: 49F30800
	CLR	-(A7)			;2F0: 4267
	CMPA.L	A4,A5			;2F2: BBCC
	BCC.S	.lab_0023		;2F4: 644C
	MOVEQ	#0,D0			;2F6: 7000
	MOVE.B	-2(A3),D0		;2F8: 102BFFFE
	LEA	0(A6,D0.L),A0		;2FC: 41F60800
	CMPA.L	A4,A0			;300: B1CC
	BLS.S	.lab_0023		;302: 633E
	ADDQ	#2,A7			;304: 544F
	MOVE.L	A4,D0			;306: 200C
	BTST	#0,D0			;308: 08000000
	BEQ.S	.lab_001E		;30C: 6704
	ADDQ	#1,A4			;30E: 524C
	ADDQ	#1,A0			;310: 5248
.lab_001E:
	MOVE.L	A0,D0			;312: 2008
	BTST	#0,D0			;314: 08000000
	BEQ.S	.lab_001F		;318: 6702
	ADDQ	#1,A0			;31A: 5248
.lab_001F:
	MOVEQ	#0,D0			;31C: 7000
.lab_0020:
	CMPA.L	A0,A6			;31E: BDC8
	BEQ.S	.lab_0021		;320: 6708
	MOVE.B	-(A0),D1		;322: 1220
	MOVE	D1,-(A7)		;324: 3F01
	ADDQ.B	#1,D0			;326: 5200
	BRA.S	.lab_0020		;328: 60F4
.lab_0021:
	MOVE	D0,-(A7)		;32A: 3F00
	ADDA.L	D0,A0			;32C: D1C0
.lab_0022:
	LEA	-32(A4),A4		;32E: 49ECFFE0
	MOVEM.L	(A4),D0-D7		;332: 4CD400FF
	MOVEM.L	D0-D7,-(A0)		;336: 48E0FF00
	CMPA.L	A3,A4			;33A: B9CB
	BHI.S	.lab_0022		;33C: 62F0
	SUBA.L	A4,A3			;33E: 97CC
	ADDA.L	A0,A3			;340: D7C8
.lab_0023:
	MOVEQ	#0,D7			;342: 7E00
	MOVE.B	1(A3),D6		;344: 1C2B0001
	ROL	#8,D6			;348: E15E
	MOVE.B	(A3),D6			;34A: 1C13
	MOVEQ	#2,D0			;34C: 7002
	MOVEQ	#2,D1			;34E: 7202
	BSR	.lab_0032		;350: 610000BE
.lab_0024:
	MOVEA.L	A2,A0			;354: 204A
	BSR	.lab_0037		;356: 610000E8
	LEA	128(A2),A0		;35A: 41EA0080
	BSR	.lab_0037		;35E: 610000E0
	LEA	256(A2),A0		;362: 41EA0100
	BSR	.lab_0037		;366: 610000D8
	MOVEQ	#-1,D0			;36A: 70FF
	MOVEQ	#16,D1			;36C: 7210
	BSR	.lab_0032		;36E: 610000A0
	MOVE	D0,D4			;372: 3800
	SUBQ	#1,D4			;374: 5344
	BRA.S	.lab_0027		;376: 601C
.lab_0025:
	LEA	128(A2),A0		;378: 41EA0080
	MOVEQ	#0,D0			;37C: 7000
	BSR.S	.lab_002E		;37E: 615A
	NEG.L	D0			;380: 4480
	LEA	-1(A5,D0.L),A1		;382: 43F508FF
	LEA	256(A2),A0		;386: 41EA0100
	BSR.S	.lab_002E		;38A: 614E
	MOVE.B	(A1)+,(A5)+		;38C: 1AD9
.lab_0026:
	MOVE.B	(A1)+,(A5)+		;38E: 1AD9
	DBF	D0,.lab_0026		;390: 51C8FFFC
.lab_0027:
	MOVEA.L	A2,A0			;394: 204A
	BSR.S	.lab_002E		;396: 6142
	SUBQ	#1,D0			;398: 5340
	BMI.S	.lab_0029		;39A: 6B1A
.lab_0028:
	MOVE.B	(A3)+,(A5)+		;39C: 1ADB
	DBF	D0,.lab_0028		;39E: 51C8FFFC
	MOVE.B	1(A3),D0		;3A2: 102B0001
	ROL	#8,D0			;3A6: E158
	MOVE.B	(A3),D0			;3A8: 1013
	LSL.L	D7,D0			;3AA: EFA8
	MOVEQ	#1,D1			;3AC: 7201
	LSL	D7,D1			;3AE: EF69
	SUBQ	#1,D1			;3B0: 5341
	AND.L	D1,D6			;3B2: CC81
	OR.L	D0,D6			;3B4: 8C80
.lab_0029:
	DBF	D4,.lab_0025		;3B6: 51CCFFC0
	CMPA.L	A6,A5			;3BA: BBCE
	BCS.S	.lab_0024		;3BC: 6596
	MOVE	(A7)+,D0		;3BE: 301F
	BEQ.S	.lab_002B		;3C0: 6708
.lab_002A:
	MOVE	(A7)+,D1		;3C2: 321F
	MOVE.B	D1,(A5)+		;3C4: 1AC1
	SUBQ.B	#1,D0			;3C6: 5300
	BNE.S	.lab_002A		;3C8: 66F8
.lab_002B:
	BRA.S	.lab_002D		;3CA: 6004
.lab_002C:
	MOVE.L	D1,384(A7)		;3CC: 2F410180
.lab_002D:
	LEA	384(A7),A7		;3D0: 4FEF0180
	MOVEM.L	(A7)+,D0-D7/A0-A6	;3D4: 4CDF7FFF
	RTS				;3D8: 4E75
.lab_002E:
	MOVE	(A0)+,D0		;3DA: 3018
	AND	D6,D0			;3DC: C046
	SUB	(A0)+,D0		;3DE: 9058
	BNE.S	.lab_002E		;3E0: 66F8
	MOVE.B	60(A0),D1		;3E2: 1228003C
	SUB.B	D1,D7			;3E6: 9E01
	BGE.S	.lab_002F		;3E8: 6C02
	BSR.S	.lab_0034		;3EA: 6130
.lab_002F:
	LSR.L	D1,D6			;3EC: E2AE
	MOVE.B	61(A0),D0		;3EE: 1028003D
	CMPI.B	#$02,D0			;3F2: 0C000002
	BLT.S	.lab_0031		;3F6: 6D16
	SUBQ.B	#1,D0			;3F8: 5300
	MOVE.B	D0,D1			;3FA: 1200
	MOVE.B	D0,D2			;3FC: 1400
	MOVE	62(A0),D0		;3FE: 3028003E
	AND	D6,D0			;402: C046
	SUB.B	D1,D7			;404: 9E01
	BGE.S	.lab_0030		;406: 6C02
	BSR.S	.lab_0034		;408: 6112
.lab_0030:
	LSR.L	D1,D6			;40A: E2AE
	BSET	D2,D0			;40C: 05C0
.lab_0031:
	RTS				;40E: 4E75
.lab_0032:
	AND	D6,D0			;410: C046
	SUB.B	D1,D7			;412: 9E01
	BGE.S	.lab_0033		;414: 6C02
	BSR.S	.lab_0034		;416: 6104
.lab_0033:
	LSR.L	D1,D6			;418: E2AE
	RTS				;41A: 4E75
.lab_0034:
	ADD.B	D1,D7			;41C: DE01
	LSR.L	D7,D6			;41E: EEAE
	SWAP	D6			;420: 4846
	ADDQ	#4,A3			;422: 584B
	MOVE.B	-(A3),D6		;424: 1C23
	ROL	#8,D6			;426: E15E
	MOVE.B	-(A3),D6		;428: 1C23
	SWAP	D6			;42A: 4846
	SUB.B	D7,D1			;42C: 9207
	MOVEQ	#16,D7			;42E: 7E10
	SUB.B	D1,D7			;430: 9E01
	RTS				;432: 4E75
.lab_0035:
	MOVEQ	#3,D1			;434: 7203
.lab_0036:
	LSL.L	#8,D0			;436: E188
	MOVE.B	(A0)+,D0		;438: 1018
	DBF	D1,.lab_0036		;43A: 51C9FFFA
	RTS				;43E: 4E75
.lab_0037:
	MOVEQ	#31,D0			;440: 701F
	MOVEQ	#5,D1			;442: 7205
	BSR.S	.lab_0032		;444: 61CA
	SUBQ	#1,D0			;446: 5340
	BMI.S	.lab_003D		;448: 6B7C
	MOVE	D0,D2			;44A: 3400
	MOVE	D0,D3			;44C: 3600
	LEA	-16(A7),A7		;44E: 4FEFFFF0
	MOVEA.L	A7,A1			;452: 224F
.lab_0038:
	MOVEQ	#15,D0			;454: 700F
	MOVEQ	#4,D1			;456: 7204
	BSR.S	.lab_0032		;458: 61B6
	MOVE.B	D0,(A1)+		;45A: 12C0
	DBF	D2,.lab_0038		;45C: 51CAFFF6
	MOVEQ	#1,D0			;460: 7001
	ROR.L	#1,D0			;462: E298
	MOVEQ	#1,D1			;464: 7201
	MOVEQ	#0,D2			;466: 7400
	MOVEM.L	D5-D7,-(A7)		;468: 48E70700
.lab_0039:
	MOVE	D3,D4			;46C: 3803
	LEA	12(A7),A1		;46E: 43EF000C
.lab_003A:
	CMP.B	(A1)+,D1		;472: B219
	BNE.S	.lab_003C		;474: 663A
	MOVEQ	#1,D5			;476: 7A01
	LSL	D1,D5			;478: E36D
	SUBQ	#1,D5			;47A: 5345
	MOVE	D5,(A0)+		;47C: 30C5
	MOVE.L	D2,D5			;47E: 2A02
	SWAP	D5			;480: 4845
	MOVE	D1,D7			;482: 3E01
	SUBQ	#1,D7			;484: 5347
.lab_003B:
	ROXL	#1,D5			;486: E355
	ROXR	#1,D6			;488: E256
	DBF	D7,.lab_003B		;48A: 51CFFFFA
	MOVEQ	#16,D5			;48E: 7A10
	SUB.B	D1,D5			;490: 9A01
	LSR	D5,D6			;492: EA6E
	MOVE	D6,(A0)+		;494: 30C6
	MOVE.B	D1,60(A0)		;496: 1141003C
	MOVE.B	D3,D5			;49A: 1A03
	SUB.B	D4,D5			;49C: 9A04
	MOVE.B	D5,61(A0)		;49E: 1145003D
	MOVEQ	#1,D6			;4A2: 7C01
	SUBQ.B	#1,D5			;4A4: 5305
	LSL	D5,D6			;4A6: EB6E
	SUBQ	#1,D6			;4A8: 5346
	MOVE	D6,62(A0)		;4AA: 3146003E
	ADD.L	D0,D2			;4AE: D480
.lab_003C:
	DBF	D4,.lab_003A		;4B0: 51CCFFC0
	LSR.L	#1,D0			;4B4: E288
	ADDQ.B	#1,D1			;4B6: 5201
	CMPI.B	#$11,D1			;4B8: 0C010011
	BNE.S	.lab_0039		;4BC: 66AE
	MOVEM.L	(A7)+,D5-D7		;4BE: 4CDF00E0
	LEA	16(A7),A7		;4C2: 4FEF0010
.lab_003D:
	RTS				;4C6: 4E75

