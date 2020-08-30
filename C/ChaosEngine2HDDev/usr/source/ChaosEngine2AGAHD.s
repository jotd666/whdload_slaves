; Resourced by whdslave_resourcer
; a program written by JOTD in 2016
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"ChaosEngine2AGA.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

	; valid passwords 30MHV7WB6HHLJL, ZF2FLN5JV1RT0L
	; ILLEGAL instruction at $24832
	
CHIPMEMSIZE = $200000

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
	dc.l	$0					; ws_expmem
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
_name	dc.b	'The Chaos Engine 2 AGA',0
_copy	dc.b	'1996 The Bitmap Brothers',0
_info
    dc.b   'installed by MiCK & JOTD',10,10
	dc.b	'Thanks to Ferox/HF for trainer (Fx/help/del keys)',10,10
	dc.b	"CD32 controls:",10,10
	dc.b	'Play: Pause',10
	dc.b	'Reverse+Forward: ESC/menu',10
	dc.b	'Yellow: Retry / Green: Quit',10,10
	dc.b	'use CUSTOM= to set the 14-char level password on startup',10,10
	dc.b	'Version '
	DECL_VERSION
	dc.b 0
_kickname   dc.b    0
;--- version id

    dc.b	0


    even

; IRA V2.00 (Nov  2 2010) (c)1993-95 Tim Ruehsen, (c)2009 Frank Wille

CIAA_PRA	EQU	$BFE001
KEYCODE = 12347

    include shared.s


start:
	LEA	_resload(PC),A1
	MOVE.L	A0,(A1)

	
	MOVE.L	#$00000102,D0
	MOVE.L	#$00000303,D1
	MOVEA.L	_resload(PC),A2
	JSR	resload_SetCPU(A2)	;b6
	
	;get password
	lea	(password,pc),a0
	moveq.l	#0,d1
	move.l	#15,d0
	jsr	(resload_GetCustom,a2)
	
	LEA	disk_number(PC),A0
	MOVE.L	#$00000001,(A0)
	MOVEQ	#2,D1
	MOVEQ	#9,D2
	MOVEQ	#0,D3
	LEA	$1FAB46,A0
	BSR.W	rn_loader
	move.l	a0,a3
	move.l	#$200*9,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$9ADA,d0
	beq.b	.okver

	; protect against using the AGA version with ECS disks
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.okver
	
	lea	pl_preboot(pc),a0
	move.l	a3,a1
	
	jsr	(resload_Patch,a2)
	
	LEA	$FFD6,A7
	MOVE.L	A7,D0
	MOVE.L	#$001f56f0,D1
	BSET	#1,CIAA_PRA
	
	sub.l	a0,a0
	sub.l	a1,a1
	sub.l	a2,a2
	moveq.l	#0,d5	; there's an access fault at $228A2 byte read from D5D5D5D5!!
	moveq.l	#0,d6
	moveq.l	#0,d7
	
	MOVEQ	#0,D2
	JMP	42(A3)

pl_preboot
	PL_START
	PL_P	312,patch_boot
	PL_P	396,rn_loader
	PL_END
	
flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
	
patch_boot:
	movem.l	A0-A2,-(A7)
	move.l	a0,a1
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	
	movem.l	(A7)+,A0-A2
	LEA	$1FAC8E,A1
	JMP	36(A0)

pl_boot
	PL_START
	PL_L	602,$6000fda4
	PL_P	0,patch_main
	PL_END

pl_main
	PL_START
	; remove write to intena during VBL, not useful as already set somewhere else
	; and causes issues when running under CD32Load
	PL_NOP	$131C2-$A6C,6
	; the rest...
	PL_R	$19346-$A6C
	PL_B	$1ea52-$A6C,$60
	PL_P	$19c46-$A6C,rn_decrunch
	PL_P	$1a240-$A6C,rn_loader
	PL_PSS	$15a6c-$A6C,LAB_0028,2
	PL_PS	$161c6-$A6C,kb_interrupt
	PL_PSS	$12caa-$A6C,LAB_0015,2
	PL_PS	$26a4-$A6C,LAB_0005
	PL_PS	$1314-$A6C,LAB_000A
	PL_PSS	$228A2-$A6C,avoid_af,4
	;;PL_PS	$E2E6-$A6C,store_menu_pos
	PL_PS	$23dc4-$A6C,avoid_af_2	; retest 23DC4 sans offset ou avec?
	PL_PSS	$E45A-$A6C,restore_password,2

	PL_IFC1	
    ; disable joyport read for mouse port
	PL_PSS	$15FD2-$A6C,read_joyport1,2
	PL_ENDIF
	
	; joypad extra controls
	PL_PS	$1e48c-$A6C,wait_esc_up
	PL_PS	$1e4d8-$A6C,esc_loop
	PL_PS	$21c54-$A6C,test_esc
	PL_PS	$21C5C-$A6C,wait_esc_up
	; wrap pause test with tests which blocks if pause is still pressed
	PL_PS	$1e418-$A6C,wait_pause_up
	PL_PS	$1e420-$A6C,unpause_loop
	PL_PS	$1e42e-$A6C,wait_pause_up
	PL_PS	$1e444-$A6C,read_keycode
	; below: we have to make inconditional branches here. Why? I don't know...
    ; yeah, because when checking for joypad buttons in loops, we didn't wait
    ; between readings, which caused spurious RED reads. Fixed now
	;PL_B	$1e51a-$A6C,$60		; force ESC loop to be forever (else it stops after 1 second or such & quits)
	;PL_B	$1e42c-$A6C,$60		; force pause loop to be forever (else it stops after 1 second or such)
	PL_END
	

	
; trying to fix issue #0002266
avoid_af_2:
	cmp.l	#CHIPMEMSIZE,a2
	bcc.b	.avoid
	move.l       (a2),a0                        ;$34830134
.out
	move.l       (-4,a6),a2                     ;$00089f7a
	rts
.avoid
	sub.l	a0,a0
	bra.b	.out
	
store_menu_pos:
	movem.l	a0,-(a7)
	lea	menu_pos(pc),a0
	move.w	8(a7),(a0)	; 0, 1, or 2
	movem.l	(a7)+,a0
	jmp	$17704
	
menu_pos:
	dc.w	0

restore_password:
	movem.l	d0-d4/a0-a3,-(a7)
	; enter password if set
	lea	password(pc),a1
	tst.b	(a1)
	beq.b	.zero
	
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
	move.w	#14,$E328		; password length: full
.out
	movem.l	(a7)+,d0-d4/a0-a3
	rts
.zero:
	; clear zone, no password passed
	move.b	#$3E,(a0)+
	dbf	d0,.zero
	bra.b	.out
	
read_joyport1:
	;move.w	($A,A3),d0
	;and.w	#$303,D0
	; don't use port 1 data at all
	add.l	#$E,(A7)	; skip to $15FE6=>$15FF8
	rts
	
avoid_af:
	cmp.l	#CHIPMEMSIZE,a2
	bcc		.out		; avoid access fault encountered once
	tst.b	(a2)
	bne.b	.l2284e
.out
	movem.l	(-$18,a6),D3-D7/A2
	rts
	
.l2284e:
	sub.l	#$A8-$4E,(a7)	; jump to $2284E
	rts
	
patch_main:
	bsr	_detect_controller_types

; < A0: program start
	; store 2 values
	movem.l	a0/a1/a5,-(a7)
	MOVEA.L	A0,A5
	move.l	a0,a6
	ADDQ.L	#4,A5
	LEA	LAB_0030(PC),A1
	MOVE.L	A5,(A1)
	MOVEA.L	A5,A0
	ADDA.L	#$00020fd4,A0
	LEA	LAB_0031(PC),A1
	MOVE.L	(A0),(A1)
	PEA	LAB_0002(PC)
	move.l	(a7)+,(a0)+

	movem.l	(a7)+,a0/a1/a5
	
	movem.l	a0-a2,-(a7)
	move.l	_resload(pc),a2
	move.l	a0,a1
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2
	
	
	MOVEM.L	(A7)+,D0-D7/A0-A6
	RTS

LAB_0002:
	PEA	LAB_0003(PC)
	MOVE.L	LAB_0031(PC),-(A7)
	RTS

LAB_0003:
	MOVE.L	A3,-(A7)
	LEA	LAB_0032(PC),A3
	MOVE.B	D0,(A3)
	MOVEA.L	LAB_0030(PC),A3
	ADDA.L	#$0003117c,A3
	TST.W	16720(A3)
	BNE.S	LAB_0004
	TST.B	D0
	BNE.S	LAB_0004
	MOVE.B	LAB_0039+1(PC),16721(A3) 
	SUBQ.W	#1,16720(A3)
LAB_0004:
	MOVEA.L	(A7)+,A3
	RTS

LAB_0005:
	ADDI.L	#$00000010,(A7)
	MOVE.L	A3,-(A7)
	LEA	LAB_0037+3(PC),A3
	CMPI.W	#$3cc6,D1
	BEQ.S	LAB_0009
	ADDQ.L	#1,A3
	CMPI.W	#$3cc8,D1
	BEQ.S	LAB_0009
	SUBQ.W	#1,0(A5,D1.W)
	BNE.S	LAB_0008
LAB_0006:
	TST.B	413(A6)
	BEQ.S	LAB_0008
	SUBQ.B	#1,413(A6)
LAB_0007:
	MOVE.W	#$0006,0(A5,D1.W)
LAB_0008:
	MOVEA.L	(A7)+,A3
	RTS

LAB_0009:
	TST.B	(A3)
	BNE.S	LAB_0008
	SUBQ.W	#1,0(A5,D1.W)
	BNE.S	LAB_0008
	TST.B	2(A3)
	BNE.S	LAB_0007
	BRA.S	LAB_0006
LAB_000A:
	MOVE.W	26(A0),D0
	SUB.W	D1,D0
	MOVE.L	A3,-(A7)
	MOVEA.L	A0,A3
	SUBA.L	LAB_0030(PC),A3
	CMPA.L	#$0004e3e0,A3
	BNE.S	LAB_000B
	LEA	LAB_0034+3(PC),A3
	BRA.S	LAB_000C
LAB_000B:
	LEA	LAB_0037(PC),A3
LAB_000C:
	TST.B	(A3)
	BEQ.S	LAB_000D
	ADD.W	D1,D0
LAB_000D:
	MOVEA.L	(A7)+,A3
	RTS

kb_interrupt:
	MOVEM.L	D0/A0,-(A7)
	LEA	LAB_0034(PC),A0
	CMPI.B	#$60,D0
	BEQ.S	LAB_000F
	CMPI.B	#$61,D0
	BNE.S	LAB_0010
LAB_000F:
	BSET	#0,(A0)
	BRA.S	LAB_0013
LAB_0010:
	CMPI.B	#$e0,D0
	BEQ.S	LAB_0011
	CMPI.B	#$e1,D0
	BNE.S	LAB_0012
LAB_0011:
	BCLR	#0,(A0)
	BRA.S	LAB_0013
LAB_0012:
	TST.B	D0
	BMI.S	LAB_0014
	LEA	LAB_0032+1(PC),A0
	MOVE.B	D0,(A0)
LAB_0013:
	LEA	LAB_0034(PC),A0
	TST.B	(A0)
	BEQ.S	LAB_0014
	CLR.L	(A7)
LAB_0014:
	MOVEM.L	(A7)+,D0/A0
	CLR.B	12346(A5)
	TST.B	D0
	RTS

LAB_0015:
	MOVEM.L	D0-D7/A0-A6,-(A7)
	MOVEQ	#0,D0
	LEA	LAB_0032+1(PC),A0
	MOVE.B	(A0),D0
	CLR.B	(A0)
	MOVEA.L	LAB_0030(PC),A6
	MOVEA.L	A6,A2
	ADDA.L	#$0003117c,A2
	MOVEA.L	A6,A3
	LEA	LAB_0034+1(PC),A4
	BTST	#0,-1(A4)
	BEQ.S	LAB_0016
	ADDA.L	#$0004e618,A3
	MOVEQ	#1,D7
	BRA.S	LAB_0017
LAB_0016:
	ADDA.L	#$0004e3e0,A3
	MOVEQ	#0,D7
LAB_0017:
	TST.B	9(A4)
	BEQ.S	LAB_0018
	BSR.S	trainer_keys
LAB_0018:
	MOVEQ	#83,D0
	TST.B	(A4)
	BEQ.S	LAB_0019
	MOVEQ	#74,D0
LAB_0019:
	MOVEA.L	A6,A0
	ADDA.L	#$00020276,A0
	MOVE.B	D0,(A0)
	MOVE.B	D0,2898(A6)
	MOVEM.L	(A7)+,D0-D7/A0-A6
	BTST	#4,$DFF01F
	RTS

trainer_keys:
	MOVEQ	#1,D1
	MOVEQ	#-1,D2
	CMPI.B	#$50,D0			; F1..........Toggle unlimited lives
	BNE.S	LAB_001B
	EOR.B	D1,0(A4,D7.W)
	RTS

LAB_001B:
	CMPI.B	#$51,D0			; F2..........Toggle unlimited energy
	BNE.S	LAB_001C
	EOR.B	D1,2(A4,D7.W)
	RTS

LAB_001C:
	CMPI.B	#$52,D0			; F3..........Toggle unlimited bullets
	BNE.S	LAB_001D
	EOR.B	D1,4(A4,D7.W)
	RTS

LAB_001D:
	CMPI.B	#$53,D0			; F4..........Toggle unlimited magazines
	BNE.S	LAB_001E
	EOR.B	D1,6(A4,D7.W)
	RTS

LAB_001E:
	CMPI.B	#$55,D0			; F6..........Refill lives
	BNE.S	LAB_001F
	MOVE.B	#$09,401(A3)
	RTS

LAB_001F:
	CMPI.B	#$56,D0			; F7..........Refill energy
	BNE.S	LAB_0020
	MOVE.W	366(A3),26(A3)
	RTS

LAB_0020:
	CMPI.B	#$57,D0			; F8..........Refill bullets
	BNE.S	LAB_0021
	MOVE.W	D7,D0
	ADD.W	D0,D0
	ADDI.W	#$3cc6,D0
	MOVE.W	#$0006,0(A2,D0.W)
	RTS

LAB_0021:
	CMPI.B	#$58,D0			; F9..........Refill magazines
	BNE.S	LAB_0022
	MOVE.B	#$09,413(A3)
	RTS

LAB_0022:
	CMPI.B	#$46,D0			; DEL.........Skip to end boss
	BNE.S	LAB_0023
	TST.W	-3(A4)
	BNE.S	LAB_0023
	CMPI.W	#$0013,16720(A2)
	BEQ.S	LAB_0023
	MOVE.W	#$0012,16720(A2)
	BRA.S	LAB_0024
LAB_0023:
	CMPI.B	#$5f,D0			; HELP........Skip level
	BNE.S	LAB_0027
LAB_0024:
	CMPI.W	#$0013,16720(A2)
	BEQ.S	LAB_0026
	MOVE.W	#$0003,12454(A2)
	MOVEA.L	LAB_0030(PC),A0
	ADDA.L	#$0004e558,A0
	LEA	568(A0),A1
	BTST	#0,-1(A4)
	BEQ.S	LAB_0025
	EXG	A0,A1
LAB_0025:
	MOVE.W	(A1),D0
	CMP.W	(A0),D0
	BCS.S	LAB_0026
	ADDQ.W	#1,D0
	MOVE.W	D0,(A0)
LAB_0026:
	RTS

LAB_0027:
	RTS

LAB_0028:
	MOVEA.L	0(A1,D1.W),A1
	MOVE.L	D0,-(A7)
	MOVE.L	A1,D0
	AND.L	#$000fffff,D0
	MOVEA.L	D0,A1
	MOVE.L	(A7)+,D0
	ADDA.L	24(A5),A1
	RTS

rn_loader:

	TST.W	D3
	BNE.S	LAB_002B
	TST.W	D2
	BEQ.S	LAB_002A
	BSR.S	LAB_002C
	MOVEM.L	D0-D7/A0-A6,-(A7)
	MOVEQ	#0,D0
	MOVE.W	D1,D0
	MOVEQ	#0,D1
	MOVE.W	D2,D1
	MULU	#$0200,D0
	MULU	#$0200,D1
	MOVE.L	disk_number(PC),D2
	MOVEA.L	_resload(PC),A2
	JSR	resload_DiskLoad(A2)	;448
	MOVEM.L	(A7)+,D0-D7/A0-A6
LAB_002A:
	MOVEQ	#0,D0
	RTS

LAB_002B:
	MOVEQ	#1,D0
	RTS

LAB_002C:
	CMPI.L	#$1,D7
	BEQ.S	LAB_002D
	CMPI.L	#$2,D7
	BEQ.S	LAB_002D
	CMPI.L	#$3,D7
	BEQ.S	LAB_002D
	RTS

LAB_002D:
	MOVE.L	A0,-(A7)
	LEA	disk_number(PC),A0
	MOVE.L	D7,(A0)
	MOVEA.L	(A7)+,A0
	RTS

LAB_002E:
	MOVE.L	_resload(PC),-(A7)
	ADDQ.L	#4,(A7)
	RTS

_resload:
	dc.l	0
LAB_0030:
	dc.l	0
LAB_0031:
	dc.l	0
LAB_0032:
	dc.w  $0100
LAB_0034:
	dc.l	0
LAB_0037:
	dc.l	0
LAB_0039:
	DC.B	$0	;4a6
	DC.B	$1	;4a7
	dc.w	$015e,$0204
disk_number:
	dc.l	$0
	

	
IGNORE_JOY_DIRECTIONS
	include	"ReadJoyPad.s"
	

