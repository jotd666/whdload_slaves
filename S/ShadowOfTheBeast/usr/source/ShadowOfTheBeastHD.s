;*---------------------------------------------------------------------------
;  :Program.	beast1slave.asm
;  :Contents.	Slave for "ShadowOfTheBeast 1"
;  :Author.	Harry
;  :History.	05.06.97
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;---------------------------------------------------------------------------*

crc_v1	= $43DC
crc_v2	= $D71B

	INCDIR	include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"ShadowOfTheBeast.slave"
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings

	DOSCMD	"WDate  >T:date"

	ENDC

;======================================================================

_base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem	;ws_flags
		dc.l	$80000		;ws_BaseMemSize			;$bc000
		dc.l	$0		;ws_ExecInstall
		dc.w	_Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache

_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
		dc.l	0			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config
        dc.b    "C1:X:Skip introduction:0;"
		dc.b	0


DECL_VERSION:MACRO
	dc.b	"2.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"Shadow Of The Beast",0
_copy		dc.b	"1989 Psygnosis",0
_info		dc.b	"install by Harry/JOTD",10,10
		dc.b	"F1 toggles infinite energy on/off",10
		dc.b	"Fire terminates death sequence",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

		even

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using

	;	move.l	#CACRF_EnableI,d0	;enable instruction cache
	;	move.l	d0,d1			;mask
	;	jsr	(resload_SetCACR,a0)


	;get tags
	move.l	(_resload,pc),a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)


	move.l	#$400,d0		;len
	LEA.L	$60000,a1		;address
	lea	INITNAME(PC),a0		;filename
	move.l	(_resload,pc),a2
	jsr	(resload_LoadFile,a2)

	MOVE.L	#$60000,A0
	MOVE.L	#$400,D0
	move.l	(_resload,pc),a2
	jsr	(resload_CRC16,a2)

	moveq	#1,d1
	cmp.w	#crc_v1,d0
	beq	.set
	moveq	#2,d1
	cmp.w	#crc_v2,d0
	beq	.set
	bra	badver

.set	lea	_version(PC),a0
	move.w	d1,(a0)


	MOVE.W	#$2700,SR
	MOVE.W	#$8210,$DFF096
	LEA.L	$60126,A0
	LEA.L	$8.W,A1
	JSR	$60070
;MODIFY
	MOVE.W	#$4E75,$9C.W
	MOVE.W	#$4EF9,$14C.W
	MOVE.W	_version(PC),-(A7)
	CMP.W	#1,(A7)+
	BEQ.S	.V1
	PEA.L	LOADROUT2(PC)
	BRA.S	.VE

.V1	PEA.L	LOADROUT(PC)
.VE	MOVE.L	(A7)+,$14E.W
	PEA.L	PATCH1(PC)
	MOVE.L	(A7)+,$98.W
	bsr	_flushcache
	JMP	$44.W

PATCH1	
	MOVE.W	_version(PC),-(A7)
	CMP.W	#1,(A7)+
	BEQ.S	.V1
	PEA	LOADROUT2(PC)
	BRA.S	.VE

.V1	PEA.L	LOADROUT(PC)
.VE	MOVE.L	(A7)+,$690C6
	PEA		PATCH2(pc)
	move.l	(a7)+,$684AC

	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_main(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	JMP	$68058

skip_intro:
	JMP	$6845A
	
pl_main
	PL_START
	PL_R	$68F5E
	PL_W	$690C4,$4EF9
	PL_W	$69064,$601a
	PL_IFC1
	PL_P	$680F8,skip_intro
	PL_ENDIF
	PL_END
	
end_sequence_loop:
.loop
	btst	#7,$bfe001
	beq.b	.out
	TST.B $0ad4.W
	bne.b	.loop
.out
	rts
	
PATCH2
	MOVE.W	_version(PC),D1
	MOVE.W	#$6012,D0
	CMP.W	#1,D1
	BEQ.S	.V1_1
	MOVE.W	D0,$377F0
	BRA.S	.VE_1

.V1_1
	MOVE.W	D0,$377e2
	
.VE_1
	patchs	$2A2E4,end_sequence_loop

	MOVE.W	D0,$290b6
	MOVE.W	D0,$28df6
	MOVE.W	D0,$2a3c6
	MOVE.W	D0,$2ea70

	CMP.W	#1,D1
	BEQ.S	.V1_2
	MOVE.W	#$4E75,$3841C
	patch	$3784A,DISKCHANGE
	MOVE.L	#$2A3C0000,$34406
	MOVE.L	#$010A7000,$3440A
	MOVE.W	#$4E75,$3440E
	MOVE.B	#$1E,$354F5
	MOVE.W	#$4E75,$383BE		;!! ADDITIONALLY
	BRA.S	.VE_2

.V1_2	MOVE.W	#$4E75,$38412
	patch	$3783C,DISKCHANGE
;^2873C 2a 3c 00 00 01 0a 70 00 4e 75
;^343f8 2a 3c 00 00 01 0a 70 00 4e 75
	MOVE.L	#$2A3C0000,$343F8
	MOVE.L	#$010A7000,$343FC
	MOVE.W	#$4E75,$34400
	MOVE.B	#$1E,$354e7
.VE_2	MOVE.L	#$2A3C0000,$2873C
	MOVE.L	#$010A7000,$28740
	MOVE.W	#$4E75,$28744
;^304fa 34 3c
;^304fe 4e714e71
;^31300 343c
;^31304 4e714e71
;^29ac8 34 3c
;^29acc 4e714e71
;^1ed1a 3a 3c
;^1ed1e 4e714e71
	MOVE.W	#$343C,D0
	MOVE.W	D0,$304FA
	CMP.W	#1,D1
	BEQ.S	.V1_3
	MOVE.W	D0,$3130E
	BRA.S	.VE_3

.V1_3	MOVE.W	D0,$31300
.VE_3	MOVE.W	D0,$29AC8
	MOVE.W	#$3A3C,$1ED1A
	MOVE.L	#$4E714E71,D0
	MOVE.L	D0,$304FE
	MOVE.L	D0,$29ACC
	MOVE.L	D0,$1ED1E

	CMP.W	#1,D1
	BEQ.S	.V1_4

	; JOTD: the version I got later

	MOVE.L	D0,$31312

	movem.l	d0-d1/a0-a2,-(a7)


	lea	$28960,a0
	lea	$28a16,a1
	bsr	_reloc_decrunch

	move.l	_custom1(pc),d0
	bne.b	.skipbp_v2

	lea	_checked_pl_v2(pc),a0
	sub.l	a1,a1
	bsr	_checked_patch

	lea	_checked_pl_common(pc),a0
	sub.l	a1,a1
;	move.l	_resload(pc),a2
;	jsr	resload_Patch(a2)
	bsr	_checked_patch

	lea	_blitter_pl_v2(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
.skipbp_v2

	lea	_pl_v2(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)


	movem.l	(a7)+,d0-d1/a0-a2

	BRA.S	.VE_4

.V1_4	
	; JOTD: the version I'm working with...

	MOVE.L	D0,$31304

	movem.l	d0-d1/a0-a2,-(a7)

	lea	$28960,a0
	lea	$28a16,a1
	bsr	_reloc_decrunch

	move.l	_custom1(pc),d0
	bne.b	.skipbp_v1

	lea	_checked_pl_v1(pc),a0
	sub.l	a1,a1
;	move.l	_resload(pc),a2
;	jsr	resload_Patch(a2)
	bsr	_checked_patch

	lea	_checked_pl_common(pc),a0
	sub.l	a1,a1
;	move.l	_resload(pc),a2
;	jsr	resload_Patch(a2)
	bsr	_checked_patch

	lea	_blitter_pl_v1(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

.skipbp_v1
	lea	_pl_v1(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-d1/a0-a2
.VE_4
;.SOF	MOVE.W	$DFF004,D0
;	BPL.S	.SOF
	JMP	$1E986

_pl_v1:
	PL_START
	; harry patches

	PL_P	$3847C,LOADROUT
	PL_W	$3832C,$6028
	PL_R	$383de
	PL_R	$38436
	PL_R	$38454
	PL_W	$35F8A,$4E71
	PL_PS	$35F8C,KEYHP
	PL_P	$28960,_decrunch

	; clist stuff (JOTD)

	PL_W	$284a2,$200
	
	PL_END

_blitter_pl_v1
	PL_START

	; blitter stuff (JOTD)

	PL_PS	$2A82E,_waitblit_CLR_64
	PL_PS	$2AC32,_waitblit_CLR_64
	PL_PS	$2AD80,_waitblit_CLR_64


	PL_END

_checked_pl_v1:
	PL_START

	PL_PS	$3075E,_waitblit_D6_50
	PL_PS	$3084C,_waitblit_D6_50
	PL_PS	$309A0,_waitblit_A0_50
	PL_PS	$30B58,_waitblit_A0_50
	PL_PS	$30C72,_waitblit_A0_50
	PL_PS	$30C78,_waitblit_A1_54
	PL_PS	$30CEC,_waitblit_A0_50
	PL_PS	$30CF2,_waitblit_A1_54
	PL_PS	$32626,_waitblit_A1_54
	PL_PS	$3267A,_waitblit_A0_50
	PL_PS	$32680,_waitblit_A1_54
	PL_PS	$375D4,_waitblit_A0_50
	PL_PS	$3760A,_waitblit_A1_54

	PL_PS	$308BA,_waitblit_6437A_50

	PL_PS	$2DDBA,_waitblit_3AEA0_50
;;	PL_PS	$2867E,_waitblit_37B50_50

        PL_PS   $308C4,_waitblit_64378_54
        PL_PS   $307BC,_waitblit_643C8_54
        PL_PS   $307a6,_waitblit_643CA_54
        PL_PS   $30870,_waitblit_643CA_54


	PL_PS	$2970E,_waitblit_FFFF_44
	PL_PS	$2DD8E,_waitblit_FFFF_44
	PL_PS	$285AE,_waitblit_FFFF_44
	PL_PS	$297A6,_waitblit_FFFF_44
	PL_PS	$2AE8A,_waitblit_FFFF_44
	PL_PS	$2B174,_waitblit_FFFF_44
	PL_PS	$2B22A,_waitblit_FFFF_44
	PL_PS	$2B648,_waitblit_FFFF_44
	PL_PS	$2B6FE,_waitblit_FFFF_44
	PL_PS	$2BB3A,_waitblit_FFFF_44
	PL_PS	$2C2EA,_waitblit_FFFF_44
	PL_PS	$2E17A,_waitblit_FFFF_44
	PL_PS	$2E5F4,_waitblit_FFFF_44
	PL_PS	$2E760,_waitblit_FFFF_44
	PL_PS	$30AB6,_waitblit_FFFF_44


	PL_PS	$2AE62,_waitblit_09F0_40
	PL_PS	$2B304,_waitblit_09F0_40
	PL_PS	$2B7F4,_waitblit_09F0_40
	PL_PS	$2C01C,_waitblit_09F0_40
	PL_PS	$30958,_waitblit_09F0_40
	PL_PS	$30BFA,_waitblit_09F0_40
	PL_END

_pl_v2:
	PL_START

	; harry patches

	PL_P	$38486,LOADROUT2
	PL_W	$38336,$6028
	PL_R	$383e8
	PL_R	$38440
	PL_R	$3845E
	PL_W	$35F98,$4E71
	PL_PS	$35F9A,KEYHP

	; decrunch routine relocated

	PL_P	$28960,_decrunch

	; clist stuff (JOTD)

	PL_W	$284a2,$200

	PL_END

_blitter_pl_v2
	PL_START

	; blitter stuff (JOTD)

	PL_PS	$2A82E,_waitblit_CLR_64
	PL_PS	$2AC32,_waitblit_CLR_64
	PL_PS	$2AD80,_waitblit_CLR_64
	PL_PS	$30C26,_waitblit_CLR_64

	PL_END

_checked_pl_common:
	PL_START
	PL_PS	$285D0,_waitblit_A0_50
	PL_PS	$2868C,_waitblit_D2_54
	PL_PS	$286EC,_waitblit_A0_50
	PL_PS	$2975A,_waitblit_D1_54
	PL_PS	$29BFA,_waitblit_A0_50
	PL_PS	$2A85A,_waitblit_A0_50
	PL_PS	$2A864,_waitblit_A1_54
	PL_PS	$2AB26,_waitblit_A4_50
	PL_PS	$2AB30,_waitblit_A3_54
	PL_PS	$2ABB2,_waitblit_A4_50
	PL_PS	$2ABBC,_waitblit_A3_54
	PL_PS	$2AC7E,_waitblit_A4_50
	PL_PS	$2AC88,_waitblit_A3_54
	PL_PS	$2ADE0,_waitblit_D0_50
	PL_PS	$2ADE6,_waitblit_A3_54
	PL_PS	$2AE1A,_waitblit_D0_50
	PL_PS	$2AEA4,_waitblit_A0_50
	PL_PS	$2B1F0,_waitblit_A0_50
	PL_PS	$2B294,_waitblit_A0_50
	PL_PS	$2B344,_waitblit_A0_50
	PL_PS	$2B34A,_waitblit_A1_54
	PL_PS	$2B6C4,_waitblit_A0_50
	PL_PS	$2B792,_waitblit_A0_50
	PL_PS	$2B834,_waitblit_A0_50
	PL_PS	$2BBCC,_waitblit_A0_50
	PL_PS	$2C06E,_waitblit_A1_54
	PL_PS	$2C4A4,_waitblit_A0_50
	PL_PS	$2DDD4,_waitblit_A0_54
	PL_PS	$2E1AE,_waitblit_A0_50
	PL_PS	$2E626,_waitblit_A0_50
	PL_PS	$2E792,_waitblit_A0_50
	PL_PS	$30400,_waitblit_A0_50
	PL_PS	$3040A,_waitblit_A1_54
	PL_END

_checked_pl_v2:
	PL_START

	PL_PS	$3076C,_waitblit_D6_50
	PL_PS	$3085A,_waitblit_D6_50
	PL_PS	$309AE,_waitblit_A0_50
	PL_PS	$30B66,_waitblit_A0_50
	PL_PS	$30C80,_waitblit_A0_50
	PL_PS	$30C86,_waitblit_A1_54
	PL_PS	$30CFA,_waitblit_A0_50
	PL_PS	$30D00,_waitblit_A1_54
	PL_PS	$32634,_waitblit_A1_54
	PL_PS	$32688,_waitblit_A0_50
	PL_PS	$3268E,_waitblit_A1_54
	PL_PS	$375E2,_waitblit_A0_50
	PL_PS	$37618,_waitblit_A1_54

        PL_PS   $308C8,_waitblit_6437A_50

	PL_PS	$2970E,_waitblit_FFFF_44
	PL_PS	$2DD8E,_waitblit_FFFF_44
	PL_PS	$285AE,_waitblit_FFFF_44
	PL_PS	$297A6,_waitblit_FFFF_44
	PL_PS	$2AE8A,_waitblit_FFFF_44
	PL_PS	$2B174,_waitblit_FFFF_44
	PL_PS	$2B22A,_waitblit_FFFF_44
	PL_PS	$2B648,_waitblit_FFFF_44
	PL_PS	$2B6FE,_waitblit_FFFF_44
	PL_PS	$2BB3A,_waitblit_FFFF_44
	PL_PS	$2C2EA,_waitblit_FFFF_44
	PL_PS	$2E17A,_waitblit_FFFF_44
	PL_PS	$2E5F4,_waitblit_FFFF_44
	PL_PS	$2E760,_waitblit_FFFF_44
	PL_PS	$30AC4,_waitblit_FFFF_44

	PL_PS	$2AE62,_waitblit_09F0_40
	PL_PS	$2B304,_waitblit_09F0_40
	PL_PS	$2B7F4,_waitblit_09F0_40
	PL_PS	$2C01C,_waitblit_09F0_40
	PL_PS	$30966,_waitblit_09F0_40
	PL_PS	$30C08,_waitblit_09F0_40
	PL_END

_checked_patch:
	movem.l	d0-a6,-(a7)
	move.l	a0,a2		; copy patchlist start pointer
.loop:
	move.w	(a0)+,D0
	cmp.w	#PLCMD_END,D0
	beq.w	.exit

	bclr	#15,D0
	beq.b	.bit32
	moveq.l	#0,D1
	move.w	(a0)+,D1	; D1.W: offset
	bra.b	.endbit32
.bit32
	move.l	(a0)+,D1	; D1.L: address
.endbit32:
	cmp.w	#PLCMD_PS,D0
	bne.b	.nojsr

	bsr	.get_slave_address

	moveq	#0,d0
	move.w	-2(a3),d0	; instruction size
	move.w	4(a3),d2	; move.? instruction (located after the bsr.w)
	cmp.w	(A1,D1.L),d2	; is it the same as the one about to be patched
	bne.b	.nomatch
	move.l	(a3,d0.w),d2
	lea	-4(A1,D1.L),a4
	add.l	d0,a4
	cmp.l	(A4),d2
	bne.b	.wrongcustomreg

	move.w	#$4EB9,(A1,D1.L)
	move.l	A3,2(A1,D1.L)
	bra.b	.loop
.nojsr
	; only PL_PS in this patchlist
	dc.w	$FF01
.nomatch
	add.l	d1,a1	; patch location
	; d2: move.? opcode
	dc.w	$FF02
.wrongcustomreg
	dc.w	$FF03
.exit

	movem.l	(a7)+,d0-a6
	rts

; <> A0: patch buffer (+=2 on exit)
; < A2: patch start
; > A3: real address of the routine in the slave
; D2 trashed

.get_slave_address:
	move.w	(A0)+,D2
	lea	(A2,D2.W),A3
	rts

WAITBLIT_XX_L:MACRO
	CNOP	2,4
	dc.w	6
_waitblit_\1_\2:
	bsr	_waitblit
	CNOP	0,4
	move.l	\1,$DFF0\2
	rts
	ENDM

WAITBLIT_XX_W:MACRO
	CNOP	2,4
	dc.w	6
_waitblit_\1_\2:
	bsr	_waitblit
	CNOP	0,4
	move.w	\1,$DFF0\2
	rts
	ENDM

WAITBLIT_ABS_L:MACRO
	CNOP	2,4
	dc.w	10	; instruction size
_waitblit_\1_\2:
	bsr	_waitblit	; must be 4 instruction wide
	CNOP	0,4
	move.l	#$\1,$DFF0\2
	addq.l	#4,(a7)
	rts
	ENDM

WAITBLIT_ABS_W:MACRO
	CNOP	2,4
	dc.w	8	; instruction size
_waitblit_\1_\2:
	bsr.w	_waitblit	; must be 4 instruction wide
	CNOP	0,4
	move.w	#$\1,$DFF0\2
	addq.l	#2,(a7)
	rts
	ENDM

	WAITBLIT_ABS_L	6437A,50

	WAITBLIT_ABS_L	64378,54
	WAITBLIT_ABS_L	643C8,54
	WAITBLIT_ABS_L	643CA,54
	WAITBLIT_ABS_L	3AEA0,50

	WAITBLIT_XX_L	D0,50
	WAITBLIT_XX_L	D6,50
	WAITBLIT_XX_L	A0,50
	WAITBLIT_XX_L	A4,50
	WAITBLIT_XX_L	A0,54
	WAITBLIT_XX_L	A1,54
	WAITBLIT_XX_L	A3,54
	WAITBLIT_XX_L	D1,54
	WAITBLIT_XX_L	D2,54

	WAITBLIT_XX_W	D1,64

_waitblit_CLR_44:
	subq.l	#2,(A7)
	bra.b	_waitblit_0_44

	WAITBLIT_ABS_W	0,44
_waitblit_CLR_64:
	subq.l	#2,(A7)
	bra.b	_waitblit_0_64

	WAITBLIT_ABS_W	0,64

	WAITBLIT_ABS_W	FFFF,44
	WAITBLIT_ABS_W	09F0,40

_waitblit:
	btst	#6,$dff002
	beq.b	.end
.wait
	btst	#6,$dff002
	bne.b	.wait
.end
	rts

_reloc_decrunch
	lea	_decrunch(pc),a2
.loop
	move.w	(a0)+,(a2)+
	cmp.l	a0,a1
	bne.b	.loop
	rts

_decrunch:
	ds.b	$A16-$960,0

;D0-DISKNR (0,1)
DISKCHANGE
	LEA.L	DISKNR(PC),A0
	ADD.B	#1,D0
	MOVE.B	D0,(A0)
	RTS



;A0-MEMADR
;A1-PARTENTRYPOINTER
;PARTAREA:
; 0(A1):DISKSTART
; 4(A1):LENGTH

LOADROUT
	MOVEM.L	D0-A6,-(A7)
	
	MOVEQ.L	#1,D2
	MOVE.B	DISKNR(PC),D2	;DISK#
	MOVE.L	4(A1),D1	;LENGTH
;	MOVE.L	A0,A0		;MEMDESTINATION
	MOVE.L	(A1),D0
	CMP.L	#($28*$1838+$822D0),D0
	BLS.S	.3
	MOVEQ.L	#2,D2
.3	CMP.L	#$822D0,D0
	BLO.S	.2
	ADD.L	#$79180-$822D0-$1838,D0
.2	CMP.B	#1,D2
	BNE.S	.1
	SUB.L	#$1838,D0
.1				;D0-DISKSTART
;	MOVE.W	#$2700,SR
	move.l	(_resload,pc),a3
	jsr	(resload_DiskLoad,a3)
;	MOVE.W	#$2000,SR
	MOVEM.L	(A7)+,D0-A6
	RTS

;LOADING ROUTINE FOR LONGTRACK-VERSION
LOADROUT2
	MOVEM.L	D0-A6,-(A7)
	
	MOVEQ.L	#1,D2
	MOVE.B	DISKNR(PC),D2	;DISK#
	MOVE.L	4(A1),D1	;LENGTH
;	MOVE.L	A0,A0		;MEMDESTINATION
	MOVE.L	(A1),D0
	CMP.L	#($28*$190C+$86A08),D0
	BLS.S	.3
	MOVEQ.L	#2,D2
.3	CMP.L	#$86A08,D0
	BLO.S	.2
	ADD.L	#-$6*$190C-$190C,D0
.2	CMP.B	#1,D2
	BNE.S	.1
	SUB.L	#$190C,D0
.1				;D0-DISKSTART
;	MOVE.W	#$2700,SR
	move.l	(_resload,pc),a3
	jsr	(resload_DiskLoad,a3)
;	MOVE.W	#$2000,SR
	MOVEM.L	(A7)+,D0-A6
	RTS

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

_version	dc.w	0	;version of disks
_resload	dc.l	0	;address of resident loader

INITNAME	DC.B	'init',0
DISKNR	DC.B	1
	EVEN


;======================================================================


; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f

KEYHP	MOVE.W	D0,-(A7)
	MOVE.W	#$3,D0
.L2	MOVE.W	D0,-(A7)
	MOVE.B	$DFF006,D0
.LOOP	CMP.B	$DFF006,D0
	BEQ.S	.LOOP
	MOVE.W	(A7)+,D0
	DBF	D0,.L2
	MOVE.W	(A7)+,D0
	NOT.B	D0
	ROR.B	#1,D0
	CMP.B	_keyexit(pc),D0
	BEQ.S	QUIT

	CMP.B	#$50,D0
	BNE.S	.1
	EOR.W	#(~$5379&$4A79)!($5379&~$4A79),$2CA8A	;SUBTRACT ONE ENERGY

.1	RTS

QUIT	;MOVE.W	#$2700,SR
.exit	pea	TDREASON_OK
	bra	_end
badver	pea	TDREASON_WRONGVER
_end	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0
