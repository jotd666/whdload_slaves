; Resourced by whdslave_resourcer
; a program written by JOTD in 2016
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"ChaosEngine2ECS.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC



	IFD	CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = 0
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
	ENDIF
	
_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 10)
	dc.w	WHDLF_NoError
	dc.l	CHIPMEMSIZE					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$0					; ws_keydebug
_keyexit
	dc.b	$59					; ws_keyexit
_expmem
	dc.l	FASTMEMSIZE					; ws_expmem
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
;---
	dc.w	slv_config-_base
	
slv_config:
        dc.b    "C1:X:disable mouse/2nd player joystick:0;"
		dc.b	0
		
KEYCODE = 12355

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.6"
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
_name	dc.b	'The Chaos Engine 2'
	IFD	CHIP_ONLY
	dc.b	" (1MB chip)"
	ENDC
		dc.b	0
_copy	dc.b	'1996 The Bitmap Brothers',0
_info
    dc.b   'installed by MiCK & JOTD',10,10
	dc.b	'Thanks to Ferox/HF for trainer (Fx/help/del keys)',10,10
	dc.b	'use CUSTOM= to set the 14-char level password on startup',10,10
	dc.b	'Version '
	DECL_VERSION
	dc.b 0

    even
    
    include    shared.s
    include    ReadJoyPad.s
; IRA V2.00 (Nov  2 2010) (c)1993-95 Tim Ruehsen, (c)2009 Frank Wille



CIAA_PRA	EQU	$BFE001
EXT_0003	EQU	$DFF01F


start:
	LEA	_resload(PC),A1		;0a0: 43fa0404
	MOVE.L	A0,(A1)			;0a4: 2288
	;MOVE.L	#$00000102,D0		;0a6: 203c00000102
	;MOVE.L	#$00000303,D1		;0ac: 223c00000303
	;MOVEA.L	_resload(PC),A2		;0b2: 247a03f2
	;JSR	resload_SetCPU(A2)	;b6
    move.l  a0,a2
	IFD	CHIP_ONLY
    lea _expmem(pc),a0
	MOVE.L	#$00080000,(a0)		;0fc: 243c00080000
	ENDIF
    
	;get password
	lea	(password,pc),a0
	moveq.l	#0,d1
	move.l	#15,d0
	jsr	(resload_GetCustom,a2)
	
	LEA	LAB_003A+2(PC),A0	;0ba: 41fa0406
	MOVE.L	#$00000001,(A0)		;0be: 20bc00000001
	MOVEQ	#2,D1			;0c4: 7202
	MOVEQ	#9,D2			;0c6: 7409
	MOVEQ	#0,D3			;0c8: 7600
	LEA		$7C3DC,A0		;0ca: 41f90007c3dc
	BSR.W	rn_loader		;0d0: 61000366
	MOVE.W	#$4ef9,306(A0)		;0d4: 317c4ef90132
	PEA	LAB_0000(PC)		;0da: 487a0046
	MOVE.L	(A7)+,308(A0)		;0de: 215f0134
	MOVE.W	#$4ef9,390(A0)		;0e2: 317c4ef90186
	PEA	rn_loader(PC)		;0e8: 487a034e
	MOVE.L	(A7)+,392(A0)		;0ec: 215f0188
	MOVE.L	#$00000420,D0		;0f0: 203c00000420
	MOVE.L	#$0007fbe0,D1		;0f6: 223c0007fbe0
	MOVE.L	_expmem(pc),D2
	
	MOVE.L	#$0007e318,D3		;102: 263c0007e318
	MOVE.L	D0,D6			;108: 2c00
	ADD.L	D1,D6			;10a: dc81
	SUB.L	#$00003c00,D6		;10c: 9cbc00003c00
	MOVEA.L	D6,A4			;112: 2846
	MOVEA.L	D6,A2			;114: 2446
	BSET	#1,CIAA_PRA		;116: 08f9000100bfe001
	bsr		flushcache
	JMP	36(A0)			;11e: 4ee80024

LAB_0000:
	MOVE.L	#$6000fda4,602(A0)	;122: 217c6000fda4025a
	MOVE.W	#$4ef9,(A0)		;12a: 30bc4ef9
	PEA	patch_main(PC)		;12e: 487a0010
	MOVE.L	(A7)+,2(A0)		;132: 215f0002
	LEA	$7C51E,A1		;136: 43f90007c51e
	bsr		flushcache
	JMP	36(A0)			;13c: 4ee80024

patch_main:
    bsr _detect_controller_types

	MOVEA.L	A0,A1			;140: 2248 = expmem +$26C
    sub.l   #$26C,A1    ; base=expmem
	movem.l	A0-A2,-(a7)
	lea	pl_main(pc),a0
	MOVEA.L	_resload(PC),A2		;0b2: 247a03f2
	jsr	resload_Patch(a2)
    
    
	movem.l	(a7)+,A0-A2
	
	MOVEA.L	A0,A5			;198: 2a48
	ADDQ.L	#4,A5			;19a: 588d
	LEA	startup_exp270(PC),A1		;19c: 43fa030c
	MOVE.L	A5,(A1)			;1a0: 228d

	MOVEM.L	(A7)+,D0-D7/A0-A6	;1fa: 4cdf7fff
	bra		flushcache      ; jump to $A70

; < A0: destination
restore_password:
	movem.l	d0-d4/a0-a3,-(a7)
	; enter password if set
	lea	password(pc),a1
	tst.b	(a1)
	beq.b	.out
	
	lea	code_letters(pc),a2
	lea	code_values(pc),a3
	move.l	#13,d0	; len

.loop
	move.b	(a1)+,d4	; letter from user code
	moveq.l	#0,d2
.lookup
	move.b	(a2,d2.w),d3	; letter from table
	beq.b	.out
	cmp.b	d3,d4
	beq.b	.match
	addq.l	#1,d2
	bra.b	.lookup
.match
	; index + $15
	move.b	(a3,d2.w),(a0)+	; store decoded in destination
	dbf	d0,.loop
    ; set length
    move.b  #14,16827(A5)       ; number of chars

.out
	movem.l	(a7)+,d0-d4/a0-a3
	rts
    
; JOTD: cleaned up code by adding patchlists & correcting
; all damn offsets that needed 2 levels of shifting...
pl_main
	PL_START

    PL_R    $00018B1A   ; copylock
    PL_B    $0001d466,$60   ; copylock ID check
    PL_P    $0001941a,rn_decrunch
    PL_P    $00019a14,rn_loader
    PL_PSS  $000161fe,fix_access_fault_1,2

    PL_PSS  $15a32,kb_interrupt,2
    PL_PSS  $125ee,vbl_hook,2
    PL_PS   $01e96,LAB_0005
    PL_PS   $00b02,LAB_000A
    PL_PS   $20282,LAB_0003
	PL_IFC1	
	PL_PSS	$158CE,read_joyport1,2
	PL_ENDIF
    
    PL_PSS   $1862,set_password,2
    
	
	; joypad extra controls
	PL_PS	$1cea0,wait_esc_up
	PL_PS	$1ceec,esc_loop
	PL_PS	$20448,test_esc
	PL_PS	$20450,wait_esc_up
	; wrap pause test with tests which blocks if pause is still pressed
	PL_PS	$1ce2c,wait_pause_up
	PL_PS	$1ce34,unpause_loop
	PL_PS	$1ce42,wait_pause_up
	PL_PS	$1ce58,read_keycode

    
	PL_END

set_password:
	CLR.W	16732(A5)		;81862: 426d415c
	CLR.W	16730(A5)		;81866: 426d415a
    movem.l A0,-(a7)
    ; copy password
    move.l  _expmem(pc),a0
    add.l   #$34D82,a0
    bsr restore_password
	movem.l	(a7)+,A0
    rts
    
read_joyport1:
	;move.w	($A,A3),d0
	;and.w	#$303,D0
	; don't use port 1 data at all
	add.l	#$E,(A7)	; skip to $15FE6=>$15FF8
	rts
flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
	
   

LAB_0003:
	MOVE.L	A3,-(A7)		;20a: 2f0b
	LEA	LAB_0032(PC),A3		;20c: 47fa02a4
	MOVE.B	D0,(A3)			;210: 1680
	MOVEA.L	startup_exp270(PC),A3		;212: 267a0296
	ADDA.L	#$00030940,A3		;216: d7fc00030940
	TST.W	16730(A3)		;21c: 4a6b415a
	BNE.S	LAB_0004		;220: 660e
	TST.B	D0			;222: 4a00
	BNE.S	LAB_0004		;224: 660a
	MOVE.B	LAB_0039+1(PC),16731(A3) ;226: 177a0295415b
	SUBQ.W	#1,16730(A3)		;22c: 536b415a
LAB_0004:
	MOVEA.L	(A7)+,A3		;230: 265f
    MOVE.B	#$00,12355(A5)		;a0282: original
	RTS				;232: 4e75

LAB_0005:
	ADDI.L	#$00000010,(A7)		;234: 069700000010
	MOVE.L	A3,-(A7)		;23a: 2f0b
	LEA	LAB_0037+3(PC),A3	;23c: 47fa027d
	CMPI.W	#$3cce,D1		;240: 0c413cce
	BEQ.S	LAB_0009		;244: 6722
	ADDQ.L	#1,A3			;246: 528b
	CMPI.W	#$3cd0,D1		;248: 0c413cd0
	BEQ.S	LAB_0009		;24c: 671a
	SUBQ.W	#1,0(A5,D1.W)		;24e: original
	BNE.S	LAB_0008		;252: 6610
LAB_0006:
	TST.B	413(A6)			;254: 4a2e019d
	BEQ.S	LAB_0008		;258: 670a
	SUBQ.B	#1,413(A6)		;25a: 532e019d
LAB_0007:
	MOVE.W	#$0006,0(A5,D1.W)	;25e: 3bbc00061000
LAB_0008:
	MOVEA.L	(A7)+,A3		;264: 265f
	RTS				;266: 4e75

LAB_0009:
	TST.B	(A3)			;268: 4a13
	BNE.S	LAB_0008		;26a: 66f8
	SUBQ.W	#1,0(A5,D1.W)		;26c: 53751000
	BNE.S	LAB_0008		;270: 66f2
	TST.B	2(A3)			;272: 4a2b0002
	BNE.S	LAB_0007		;276: 66e6
	BRA.S	LAB_0006		;278: 60da
LAB_000A:
	MOVE.W	26(A0),D0		;27a: original
	SUB.W	D1,D0			;27e: original
	MOVE.L	A3,-(A7)		;280: 2f0b
	MOVEA.L	A0,A3			;282: 2648
	SUBA.L	startup_exp270(PC),A3		;284: 97fa0224
	CMPA.L	#$0004ccc4,A3		;288: b7fc0004ccc4
	BNE.S	LAB_000B		;28e: 6606
	LEA	LAB_0034+3(PC),A3	;290: 47fa0225
	BRA.S	LAB_000C		;294: 6004
LAB_000B:
	LEA	LAB_0037(PC),A3		;296: 47fa0220
LAB_000C:
	TST.B	(A3)			;29a: 4a13
	BEQ.S	LAB_000D		;29c: 6702
	ADD.W	D1,D0			;29e: d041
LAB_000D:
	MOVEA.L	(A7)+,A3		;2a0: 265f
	RTS				;2a2: 4e75
	
quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

kb_interrupt:
	MOVEM.L	D0/A0,-(A7)		;2a4: 48e78080
	cmp.b	_keyexit(pc),d0
	beq	quit		; quitkey on 68000
	
	LEA	LAB_0034(PC),A0		;2a8: 41fa020a
	CMPI.B	#$60,D0			;2ac: 0c000060
	BEQ.S	LAB_000F		;2b0: 6706
	CMPI.B	#$61,D0			;2b2: 0c000061
	BNE.S	LAB_0010		;2b6: 6606
LAB_000F:
	BSET	#0,(A0)			;2b8: 08d00000
	BRA.S	LAB_0013		;2bc: 601c
LAB_0010:
	CMPI.B	#$e0,D0			;2be: 0c0000e0
	BEQ.S	LAB_0011		;2c2: 6706
	CMPI.B	#$e1,D0			;2c4: 0c0000e1
	BNE.S	LAB_0012		;2c8: 6606
LAB_0011:
	BCLR	#0,(A0)			;2ca: 08900000
	BRA.S	LAB_0013		;2ce: 600a
LAB_0012:
	TST.B	D0			;2d0: 4a00
	BMI.S	LAB_0014		;2d2: 6b10
	LEA	LAB_0032+1(PC),A0	;2d4: 41fa01dd
	MOVE.B	D0,(A0)			;2d8: 1080
LAB_0013:
	LEA	LAB_0034(PC),A0		;2da: 41fa01d8
	TST.B	(A0)			;2de: 4a10
	BEQ.S	LAB_0014		;2e0: 6702
	CLR.L	(A7)			;2e2: 4297
LAB_0014:
	MOVEM.L	(A7)+,D0/A0		;2e4: 4cdf0101
	CLR.B	12354(A5)		;   original code
	TST.B	D0			;2ec: 4a00
	RTS				;2ee: 4e75

vbl_hook:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;2f0: 48e7fffe
	MOVEQ	#0,D0			;2f4: 7000
	LEA	LAB_0032+1(PC),A0	;2f6: 41fa01bb
	MOVE.B	(A0),D0			;2fa: 1010
	CLR.B	(A0)			;2fc: 4210
	MOVEA.L	startup_exp270(PC),A6		;2fe: 2c7a01aa
	MOVEA.L	A6,A2			;302: 244e
	ADDA.L	#$00030940,A2		;304: d5fc00030940
	MOVEA.L	A6,A3			;30a: 264e
	LEA	LAB_0034+1(PC),A4	;30c: 49fa01a7
	BTST	#0,-1(A4)		;310: 082c0000ffff
	BEQ.S	LAB_0016		;316: 670a
	ADDA.L	#$0004cefc,A3		;318: d7fc0004cefc
	MOVEQ	#1,D7			;31e: 7e01
	BRA.S	LAB_0017		;320: 6008
LAB_0016:
	ADDA.L	#$0004ccc4,A3		;322: d7fc0004ccc4
	MOVEQ	#0,D7			;328: 7e00
LAB_0017:
	TST.B	9(A4)			;32a: 4a2c0009
	BEQ.S	LAB_0018		;32e: 6702
	BSR.S	LAB_001A		;330: 6124
LAB_0018:
	MOVEQ	#83,D0			;332: 7053
	TST.B	(A4)			;334: 4a14
	BEQ.S	LAB_0019		;336: 6702
	MOVEQ	#74,D0			;338: 704a
LAB_0019:
	MOVEA.L	A6,A0			;33a: 204e
	ADDA.L	#$0001f2aa,A0		;33c: d1fc0001f2aa
	MOVE.B	D0,(A0)			;342: 1080
	MOVE.B	D0,2884(A6)		;344: 1d400b44
	MOVEM.L	(A7)+,D0-D7/A0-A6	;348: 4cdf7fff
	BTST	#4,EXT_0003		;34c: 0839000400dff01f
	RTS				;354: 4e75

LAB_001A:
	MOVEQ	#1,D1			;356: 7201
	MOVEQ	#-1,D2			;358: 74ff
	CMPI.B	#$50,D0			;35a: 0c000050
	BNE.S	LAB_001B		;35e: 6606
	EOR.B	D1,0(A4,D7.W)		;360: b3347000
	RTS				;364: 4e75

LAB_001B:
	CMPI.B	#$51,D0			;366: 0c000051
	BNE.S	LAB_001C		;36a: 6606
	EOR.B	D1,2(A4,D7.W)		;36c: b3347002
	RTS				;370: 4e75

LAB_001C:
	CMPI.B	#$52,D0			;372: 0c000052
	BNE.S	LAB_001D		;376: 6606
	EOR.B	D1,4(A4,D7.W)		;378: b3347004
	RTS				;37c: 4e75

LAB_001D:
	CMPI.B	#$53,D0			;37e: 0c000053
	BNE.S	LAB_001E		;382: 6606
	EOR.B	D1,6(A4,D7.W)		;384: b3347006
	RTS				;388: 4e75

LAB_001E:
	CMPI.B	#$55,D0			;38a: 0c000055
	BNE.S	LAB_001F		;38e: 6608
	MOVE.B	#$09,401(A3)		;390: 177c00090191
	RTS				;396: 4e75

LAB_001F:
	CMPI.B	#$56,D0			;398: 0c000056
	BNE.S	LAB_0020		;39c: 6608
	MOVE.W	366(A3),26(A3)		;39e: 376b016e001a
	RTS				;3a4: 4e75

LAB_0020:
	CMPI.B	#$57,D0			;3a6: 0c000057
	BNE.S	LAB_0021		;3aa: 6610
	MOVE.W	D7,D0			;3ac: 3007
	ADD.W	D0,D0			;3ae: d040
	ADDI.W	#$3cce,D0		;3b0: 06403cce
	MOVE.W	#$0006,0(A2,D0.W)	;3b4: 35bc00060000
	RTS				;3ba: 4e75

LAB_0021:
	CMPI.B	#$58,D0			;3bc: 0c000058
	BNE.S	LAB_0022		;3c0: 6608
	MOVE.B	#$09,413(A3)		;3c2: 177c0009019d
	RTS				;3c8: 4e75

LAB_0022:
	CMPI.B	#$46,D0			;3ca: 0c000046
	BNE.S	LAB_0023		;3ce: 6616
	TST.W	-3(A4)			;3d0: 4a6cfffd
	BNE.S	LAB_0023		;3d4: 6610
	CMPI.W	#$0013,16730(A2)	;3d6: 0c6a0013415a
	BEQ.S	LAB_0023		;3dc: 6708
	MOVE.W	#$0012,16730(A2)	;3de: 357c0012415a
	BRA.S	LAB_0024		;3e4: 6006
LAB_0023:
	CMPI.B	#$5f,D0			;3e6: 0c00005f
	BNE.S	LAB_0027		;3ea: 6632
LAB_0024:
	CMPI.W	#$0013,16730(A2)	;3ec: 0c6a0013415a
	BEQ.S	LAB_0026		;3f2: 6728
	MOVE.W	#$0003,12462(A2)	;3f4: 357c000330ae
	MOVEA.L	startup_exp270(PC),A0		;3fa: 207a00ae
	ADDA.L	#$0004ce3c,A0		;3fe: d1fc0004ce3c
	LEA	568(A0),A1		;404: 43e80238
	BTST	#0,-1(A4)		;408: 082c0000ffff
	BEQ.S	LAB_0025		;40e: 6702
	EXG	A0,A1			;410: c149
LAB_0025:
	MOVE.W	(A1),D0			;412: 3011
	CMP.W	(A0),D0			;414: b050
	BCS.S	LAB_0026		;416: 6504
	ADDQ.W	#1,D0			;418: 5240
	MOVE.W	D0,(A0)			;41a: 3080
LAB_0026:
	RTS				;41c: 4e75

LAB_0027:
	RTS				;41e: 4e75

fix_access_fault_1:
	MOVEA.L	0(A1,D1.W),A1		;420: 22711000
	MOVE.L	D0,-(A7)		;424: 2f00
	MOVE.L	A1,D0			;426: 2009
	AND.L	#$000fffff,D0		;428: c0bc000fffff
	MOVEA.L	D0,A1			;42e: 2240
	MOVE.L	(A7)+,D0		;430: 201f
	ADDA.L	24(A5),A1		;432: d3ed0018
	RTS				;436: 4e75

rn_loader:
	TST.W	D3			;438: 4a43
	BNE.S	LAB_002B		;43a: 662e
	TST.W	D2			;43c: 4a42
	BEQ.S	LAB_002A		;43e: 6726
	BSR.S	LAB_002C		;440: 612c
	MOVEM.L	D0-D7/A0-A6,-(A7)	;442: 48e7fffe
	MOVEQ	#0,D0			;446: 7000
	MOVE.W	D1,D0			;448: 3001
	MOVEQ	#0,D1			;44a: 7200
	MOVE.W	D2,D1			;44c: 3202
	MULU	#$0200,D0		;44e: c0fc0200
	MULU	#$0200,D1		;452: c2fc0200
	MOVE.L	LAB_003A+2(PC),D2	;456: 243a006a
	MOVEA.L	_resload(PC),A2		;45a: 247a004a
	JSR	resload_DiskLoad(A2)	;45e
	MOVEM.L	(A7)+,D0-D7/A0-A6	;462: 4cdf7fff
LAB_002A:
	MOVEQ	#0,D0			;466: 7000
	RTS				;468: 4e75

LAB_002B:
	MOVEQ	#1,D0			;46a: 7001
	RTS				;46c: 4e75

LAB_002C:
	CMPI.L	#$00000001,D7		;46e: 0c8700000001
	BEQ.S	LAB_002D		;474: 6712
	CMPI.L	#$00000002,D7		;476: 0c8700000002
	BEQ.S	LAB_002D		;47c: 670a
	CMPI.L	#$00000003,D7		;47e: 0c8700000003
	BEQ.S	LAB_002D		;484: 6702
	RTS				;486: 4e75

LAB_002D:
	MOVE.L	A0,-(A7)		;488: 2f08
	LEA	LAB_003A+2(PC),A0	;48a: 41fa0036
	MOVE.L	D7,(A0)			;48e: 2087
	MOVEA.L	(A7)+,A0		;490: 205f
	RTS				;492: 4e75

	PEA	-1.W			;494: 4878ffff
	BRA.S	LAB_002E		;498: 6004
	PEA	5.W			;49a: 48780005
LAB_002E:
	MOVE.L	_resload(PC),-(A7)	;49e: 2f3a0006
	ADDQ.L	#4,(A7)			;4a2: 5897
	RTS				;4a4: 4e75

_resload:
	dc.l	0			;4a6: 00000000
startup_exp270:
	dc.l	0			;4aa: 00000000
LAB_0031:
	dc.l	0			;4ae: 00000000
LAB_0032:
	BTST	D0,D0			;4b2: 0100
LAB_0034:
	dc.l	0			;4b4: 00000000
LAB_0037:
	dc.l	0			;4b8: 00000000
LAB_0039:
	DC.B	$0	;4bc
	DC.B	$1	;4bd
	BCHG	D0,(A6)+		;4be: 015e
LAB_003A:
	ANDI.B	#$00,D4			;4c0: 02040000
	DC.B	$0	;4c4
	DC.B	$0	;4c5
