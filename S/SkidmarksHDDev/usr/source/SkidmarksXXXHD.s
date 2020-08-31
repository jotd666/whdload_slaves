;*---------------------------------------------------------------------------
;  :Program.	SkidmarksHD.asm
;  :Contents.	Slave for "Skidmarks"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SkidmarksHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


CIAA_PRA	EQU	$BFE001
DMACONR		EQU	$DFF002
VHPOSR		EQU	$DFF006
INTENAR		EQU	$DFF01C
DMACON		EQU	$DFF096
INTENA		EQU	$DFF09A
COLOR00		EQU	$DFF180

NUMDRIVES	= 1
WPDRIVES	= %0000

DEBUG
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 10000
BOOTDOS

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.0"
	ENDM

_assign
	dc.b	"Skidmarks",0

slv_name		dc.b	"Skidmarks "
		IFD	AGA_MODE
		dc.b	"(AGA enhanced)"
		ENDC
		dc.b	0
slv_copy	dc.b	"1992 Acid Software",0
slv_info	dc.b	"adapted by JOTD",10,10
		dc.b	"Thanks to Fairlight for DOS HD install",10,10
		dc.b	"Version "
		DECL_VERSION
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"Skidmarks",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
		dc.b	$A,$D,0
	ENDC

	EVEN

_bootdos
		bsr	patch_trackdisk

		clr.l	$0.W

		move.l	(_resload),a2		;A2 = resload

	;enable cache only for slave

		move.l	#WCPUF_Base_NC|WCPUF_Exp_NC|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

RELOC_MOVEL:MACRO
	movem.l	a6,-(a7)
	lea	\2(pc),a6
	move.l	\1,(a6)
	movem.l	(a7)+,a6
	ENDM
RELOC_MOVEW:MACRO
	movem.l	a6,-(a7)
	lea	\2(pc),a6
	move.w	\1,(a6)
	movem.l	(a7)+,a6
	ENDM
RELOC_MOVEB:MACRO
	movem.l	a6,-(a7)
	lea	\2(pc),a6
	move.b	\1,(a6)
	movem.l	(a7)+,a6
	ENDM
RELOC_ORIW:MACRO
	movem.l	a6,-(a7)
	lea	\2(pc),a6
	ori.w	#\1,(a6)
	movem.l	(a7)+,a6
	ENDM
RELOC_LEA:MACRO
	pea	\1(pc)
	move.l	(a7)+,\2
	ENDM

patch_main
	move.l	_resload(pc),a2
	lea	_program(pc),a0
	jsr	resload_GetFileSize(a2)
	cmp.l	#192008,d0
	beq.b	.ok

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok

	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_main(pc),a0
	lea	-$20(a1),a1	; makeup for comp offsets
	bsr	change_msg
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)	; apply diff for main exec file

	; now the adaptation of the Fairlight patch

	move.l	d7,d0
	ADDQ.L	#4,D0			;04A: 5880
	MOVEA.L	D0,A0			;04C: 2040

	RELOC_LEA	.patch_c0,$C0.W
	RELOC_LEA	.patch_c4,$C4.W

	bsr	_flushcache
	JSR	(A0)			;0C2: 4E90

	bra	_quit

.patch_c0:
	MOVEM.L	D1/A0-A2,-(A7)		;14C: 48E740E0
	MOVEA.L	D0,A0			;150: 2040
	MOVEA.L	D1,A1			;152: 2241
	CMPI.B	#$54,(A0)		;154: 0C100054
	BEQ.S	.lab_000E		;158: 6706
	CMPI.B	#$74,(A0)		;15A: 0C100074
	BNE.S	.lab_0011		;15E: 662A
.lab_000E:
	BTST	#7,CIAA_PRA		;16A: 0839000700BFE001
	BEQ.S	.lab_000F		;172: 670E
	BTST	#6,CIAA_PRA		;174: 0839000600BFE001
	BNE.S	.lab_000E		;17C: 66E2

	MOVEQ	#48,D0			;17E: 7030
	BRA.S	.lab_0010		;180: 6002
.lab_000F:
	MOVEQ	#49,D0			;182: 7031
.lab_0010:
	RELOC_MOVEB	D0,.lab_001A		;184: 13C00000020E
.lab_0011:
	MOVEQ	#-1,D0			;18A: 70FF
	MOVEM.L	(A7)+,D1/A0-A2		;18C: 4CDF0702
	RTS				;190: 4E75


.patch_c4:
	MOVEM.L	D1-D2/A0-A2,-(A7)	;192: 48E760E0
	MOVEA.L	D0,A0			;196: 2040
	MOVEA.L	D1,A1			;198: 2241
	MOVE.B	(A0),D2			;19A: 1410
	ROL.L	#8,D2			;19C: E19A
	MOVE.B	1(A0),D2		;19E: 14280001
.lab_0013:
	ROL.L	#8,D2			;1A2: E19A
.lab_0014:
	MOVE.B	2(A0),D2		;1A4: 14280002
	ROL.L	#8,D2			;1A8: E19A
	MOVE.B	3(A0),D2		;1AA: 14280003
	CMPI.L	#$706F7273,D2		;1AE: 0C82706F7273
.lab_0015:
	BEQ.S	.lab_001C		;1B4: 6760
	CMPI.L	#$63616D61,D2		;1B6: 0C8263616D61
	BEQ.S	.lab_001C		;1BC: 6758
	CMPI.L	#$74727563,D2		;1BE: 0C8274727563
	BEQ	.lab_001C		;1C4: 67000050
	CMPI.L	#$62756767,D2		;1C8: 0C8262756767
	BEQ	.lab_001C		;1CE: 67000046
	CMPI.L	#$504F5253,D2		;1D2: 0C82504F5253
	BEQ.S	.lab_001C		;1D8: 673C
	CMPI.L	#$43414D41,D2		;1DA: 0C8243414D41
	BEQ.S	.lab_001C		;1E0: 6734
	CMPI.L	#$54525543,D2		;1E2: 0C8254525543
	BEQ	.lab_001C		;1E8: 6700002C
	CMPI.L	#$42554747,D2		;1EC: 0C8242554747
	BEQ	.lab_001C		;1F2: 67000022
	BRA.S	.lab_001D		;1F6: 602E
.lab_0016:
	BSR	.lab_0023		;1F8: 6100006A
	MOVEM.L	(A7)+,D1-D2/A0-A2	;1FC: 4CDF0706
	RTS				;200: 4E75
.lab_0017:
	DC.W	$4147			;202
.lab_0018:
	dc.l	$412F5858
	dc.l	$58580000
.lab_0019:
	dc.w	$5452
.lab_001A:
	dc.l	$302F5858
	dc.l	$58580000			;214
.lab_001C:
	RELOC_MOVEL	D2,.lab_0018+2		;216: 23C200000206
	LEA	.lab_0017(pc),A0		;21C: 41F900000202
	BRA	.lab_0016		;222: 6000FFD4
.lab_001D:
	RELOC_MOVEL	D2,.lab_001A+2		;226: 23C200000210
	LEA	.lab_0019(pc),A0		;22C: 41F90000020C
	BRA	.lab_0016		;232: 6000FFC4
	dc.l	0			;236: 00000000
	dc.l	0			;23A: 00000000
	dc.l	0			;23E: 00000000
	dc.l	0			;242: 00000000
	dc.l	0			;246: 00000000
	dc.l	0			;24A: 00000000
	DC.L	$00004100
.lab_0020:
	dc.l	0			;25A: 00000000
.lab_0021:
	dc.l	0			;25E: 00000000
.lab_0022:
	DC.W	$0000			;262


; < A0: filename
; < A1: buffer
; > D0: file length

.lab_0023:
	MOVEM.L	D1/A0-A2,-(A7)	;264: 48E7FFFE
	move.l	_resload(pc),a2
;	jsr	resload_LoadFileDecrunch(a2)
	jsr	resload_LoadFile(a2)
	MOVEM.L	(A7)+,D1/A0-A2	;378: 4CDF7FFF
	RTS				;3C6: 4E75

change_msg:
	movem.l	a0-a1,-(a7)
	add.l	#$2BCCE,a1
	lea	.msg(pc),a0
.copy
	move.b	(a0)+,(a1)+
	bne.b	.copy
	movem.l	(a7)+,a0-a1
	rts

.msg
	;	 -------------------------------
	dc.b	"LMB: TRACKS 1 - FIRE: TRACKS 2 ",0
	even

pl_main
	PL_START

	; jump #1

	PL_L	$834e,$207800c0
	PL_W	$8352,$4ed0

	; jump #2

	PL_L	$8392,$207800c4
	PL_W	$8396,$4ed0

	; disk calls?

	PL_L	$80fa,$6000003c
	PL_L	$d43a,$6000003c
	PL_L	$17048,$6000003c

	; VBR shit

	PL_L	$1FBBA+$20,$74004E71
	PL_L	$22290+$20,$74004E71

	; AGA/ECS
	
	PL_PS	$23CA6+$20,detect_chipset

	; PAL/NTSC bypass

	PL_R	$2A206+$20

	PL_END

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

detect_chipset
	IFD	AGA_MODE
	move.w	#$F8,d0
	ELSE
	move.w	#0,d0
	ENDC
	rts

; patch useless (and unsupported) trackdisk device calls

patch_trackdisk
	movem.l	D0-A6,-(A7)
	lea	_trackdisk_device(pc),A0
	tst.l	(A0)
	bne.b	.out		; already patched
	lea	_trdname(pc),A0

	move.l	$4.W,A6

	lea	-$30(A7),A7
	move.l	A7,A1
	moveq	#0,D0
	moveq	#0,D1
	jsr	_LVOOpenDevice(A6)
	
	lea	_trackdisk_device(pc),A1
	move.l	IO_DEVICE(A7),(A1)		; save trackdisk device pointer

	lea	$30(A7),A7

	move.l	$4.W,A0
	add.w	#_LVODoIO+2,a0
	lea	_doio_save(pc),a1
	move.l	(a0),(a1)
	lea	_doio(pc),a1
	move.l	a1,(a0)
	move.l	$4.W,A0
	add.w	#_LVOSendIO+2,a0
	lea	_sendio_save(pc),a1
	move.l	(a0),(a1)
	lea	_sendio(pc),a1
	move.l	a1,(a0)

.out
	movem.l	(A7)+,D0-A6

	rts


_doio:
	move.l	_trackdisk_device(pc),D0
	cmp.l	IO_DEVICE(A1),D0
	bne.b	.org
	bra.b	.skipit		; skip accesses to trackdisk device
	move.w	$1C(A1),D0
	cmp.w	#$800A,D0	; seek
	beq.b	.skipit
;	cmp.w	#$00A,D0	; seek
;	beq.b	.skipit
.org
	move.l	_doio_save(pc),-(A7)
	rts
.skipit:
	clr.b	$1F(A1)
	moveq.l	#0,D0
	rts

_sendio:
	move.l	_trackdisk_device(pc),D0
	cmp.l	IO_DEVICE(A1),D0
	bne.b	.org
	move.w	$1C(A1),D0
	cmp.w	#$800A,D0	; seek
	beq.b	.skipit
;	cmp.w	#$00A,D0	; seek
;	beq.b	.skipit
.org
	move.l	_sendio_save(pc),-(A7)
	rts
.skipit:
	clr.b	$1F(A1)
	moveq.l	#0,D0
	rts

_trackdisk_device:
	dc.l	0
_doio_save:
	dc.l	0
_sendio_save:
	dc.l	0

_trdname:
	dc.b	"trackdisk.device",0
	even

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
;============================================================================

	END
