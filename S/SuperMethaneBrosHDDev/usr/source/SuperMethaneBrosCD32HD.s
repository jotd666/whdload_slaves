; Resourced by whdslave_resourcer v0.91
; a program written by JOTD in 2016-2019
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	IFD BARFLY
	OUTPUT	"SuperMethaneBrosCD32.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;============================================================================

	IFD	CHIPONLY
CHIPMEMSIZE	= $1D0000
FASTMEMSIZE	= $0
HRTMON
	ELSE
CHIPMEMSIZE	= $1D0000
FASTMEMSIZE	= $40000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
INITAGA
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

QUIT_JOYPAD_MASK = JPF_BUTTON_FORWARD|JPF_BUTTON_REVERSE|JPF_BUTTON_PLAY

; without dummy cd it crashes. Game expects cd.device
DUMMY_CD_DEVICE = 1
;USE_DISK_LOWLEVEL_LIB
;USE_DISK_NONVOLATILE_LIB

;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

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
slv_name	dc.b	'Super Methane Bros CD³²',0
slv_copy	dc.b	'1993 Apache',0
slv_info
    dc.b   'Installed by Codetapper/Action! & JOTD',10
	dc.b	'Version '
	DECL_VERSION
	dc.b	10,'Press Help to toggle infinite lives!',10
	dc.b	10,'Thanks to Chris Vella and Mike West',10
	dc.b	'for the originals!',0
	
slv_CurrentDir:
	dc.b	"data",0
slv_config:
        ;;dc.b    "C1:X:Trainer Infinite Lives:0;"
        ;;dc.b    "C2:X:Force 1-button joystick (up jumps):0;"
		dc.b	0
;--- version id
    dc.b	0
bootname:
	dc.b	"boot",0
_args		dc.b	10
_args_end
	dc.b	0
assign
	dc.b	"cd0",0

    even

_bootdos
	; configure the button emulation

	IFND	USE_DISK_LOWLEVEL_LIB
	lea	OSM_JOYPAD1KEYS(pc),a0
	move.w	#$4019,2(a0)	; SPACE = bomb, P = pause
	move.w	#$4545,4(a0)	; both charcoal: ESC so ESC quits the game in pause mode

	; force joypad/joystick in port 1 (my autosense code does not
	; work at least with WinUAE, so I'm forcing it)

	lea	port_0_attribute(pc),a0
	move.l	#JP_TYPE_GAMECTLR,(a0)
	lea	port_1_attribute(pc),a0
	move.l	#JP_TYPE_GAMECTLR,(a0)
	ENDC

	move.l	_resload(pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		bsr	_patch_cd32_libs

		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		
		lea	bootname(pc),A0
.load

	;load exe
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_exe(pc),a5
		bsr	_load_exe
	;quit
	bra	_quit

	;load program
; IRA V2.00 (Nov  2 2010) (c)1993-95 Tim Ruehsen, (c)2009 Frank Wille
ABSEXECBASE	EQU	$4
EXT_0001	EQU	$100
EXT_0002	EQU	$102
EXT_0003	EQU	$400
CIAA_SDR	EQU	$BFEC01
EXT_0005	EQU	$DFF005
EXT_0006	EQU	$DFF01F
COLOR00		EQU	$DFF180

highscores_name:
	DC.B	'SuperMethaneBros.highs',0
trainer_keycode:
	dc.b	$00	;11a
subexecutable_first_letter:
	dc.b	$00	;11b
trainer_used:
	dc.b	$00	;11c
	dc.b	$00	;11d
	even
	
patch_exe
	move.l	d7,a1
	add.l	#4,a1
	LEA	pl_boot(PC),A0		;17e: 41fa0050
	MOVEA.L	A1,A5			;182: 2a49
	JSR	resload_Patch(A2)	;184 (offset=64)
	patch	$100,get_segment_start

	CLR.L	-(A7)			;196: 42a7
	CLR.L	-(A7)			;198: 42a7
	PEA	WHDLTAG_MONITOR_GET		;19a: monitor get
	MOVEA.L	A7,A0			;1a0: 204f
	MOVEA.L	_resload(PC),A2		;1a2: 247a022c
	JSR	resload_Control(A2)	;1a6 (offset=34)
	MOVE.L	4(A7),D0		;1aa: 202f0004
	LEA	12(A7),A7		;1ae: 4fef000c
	CMPI.L	#NTSC_MONITOR_ID,D0		;1b2: 0c8000011000
	BEQ.S	ntsc		;1b8: 6706
	LEA	pl_pal(PC),A0		;1ba: 41fa0036
	BRA.S	LAB_000B		;1be: 6004
ntsc:
	LEA	pl_ntsc(PC),A0		;1c0: 41fa0038
LAB_000B:
	MOVEA.L	A5,A1			;1c4: 224d
	JSR	resload_Patch(A2)	;1c6 (offset=64)
	rts
	
pl_boot:
	PL_START
	PL_P	$a4,LAB_0023
	PL_PS	$130,LABN_0342
	PL_L	$15e,$4eb80100
	PL_W	$1be,1
	PL_W	$1c2,1
	PL_END

pl_pal:
	PL_START
	PL_S	$68,$2a
	PL_END

pl_ntsc:
	PL_START
	PL_S	$68,$14
	PL_END

pl_choose:
	PL_START
	PL_S	$b2,8
	PL_S	$108,8
	PL_W	$11a,1
	PL_W	$11c,1
	PL_NOP	$3c4,6
	PL_NOP	$3f0,4
	PL_P	$73c,decrunch
	PL_END

pl_doanim:
	PL_START
	PL_P	$512,decrunch
	PL_NOP	$6f2,8
	PL_NOP	$72e,4
	PL_END

pl_methane:
	PL_START
	PL_PS	$6c8,keyboard_interrupt_handler
	PL_NOP	$6ce,2
	PL_S	$752a,10
	PL_P	$7542,load_scores
	PL_NOP	$7554,4
	PL_P	$7570,save_scores
	PL_P	$65804,decrunch
	PL_END

load_scores:
	MOVEM.L	D0-D1/A0-A3,-(A7)	;286: 48e7c0f0
	MOVEA.L	A2,A1			;28a: 224a
	MOVEA.L	A2,A3			;28c: 264a
	LEA	highscores_name(PC),A0	;28e: 41fafe73
	MOVEA.L	_resload(PC),A2		;292: 247a013c
	JSR	resload_GetFileSize(A2)	;296 (offset=24)
	TST.L	D0			;29a: 4a80
	BEQ.S	LAB_0012		;29c: 6710
	LEA	highscores_name(PC),A0	;29e: 41fafe63
	MOVEA.L	A3,A1			;2a2: 224b
	MOVE.L	A1,-(A7)		;2a4: 2f09
	JSR	resload_LoadFile(A2)	;2a6 (offset=8)
	MOVEA.L	(A7)+,A1		;2aa: 225f
	BSR.S	crypt_scores		;2ac: 612c
LAB_0012:
	MOVEM.L	(A7)+,D0-D1/A0-A3	;2ae: 4cdf0f03
	RTS				;2b2: 4e75

save_scores:
	MOVEM.L	D0-D1/A0-A2,-(A7)	;2b4: 48e7c0e0
	MOVE.B	trainer_keycode(PC),D0		;2b8: 103afe60
	BNE.S	LAB_0013		;2bc: 6616
	LEA	highscores_name(PC),A0	;2be: 41fafe43
	MOVEA.L	A2,A1			;2c2: 224a
	MOVEA.L	_resload(PC),A2		;2c4: 247a010a
	BSR.S	crypt_scores		;2c8: 6110
	MOVE.L	A1,-(A7)		;2ca: 2f09
	JSR	resload_SaveFile(A2)	;2cc (offset=c)
	MOVEA.L	(A7)+,A1		;2d0: 225f
	BSR.S	crypt_scores		;2d2: 6106
LAB_0013:
	MOVEM.L	(A7)+,D0-D1/A0-A2	;2d4: 4cdf0703
	RTS				;2d8: 4e75

crypt_scores:
	MOVEQ	#64,D0			;2da: 7040
	MOVE.L	D0,-(A7)		;2dc: 2f00
LAB_0015:
	EOR.B	D0,(A1)+		;2de: b119
	SUBQ.L	#1,D0			;2e0: 5380
	BNE.S	LAB_0015		;2e2: 66fa
	MOVE.L	(A7)+,D0		;2e4: 201f
	SUBA.L	D0,A1			;2e6: 93c0
	RTS				;2e8: 4e75

decrunch:
	MOVEM.L	D0-D1/A0-A2,-(A7)	;2ea: 48e7c0e0
	MOVEA.L	_resload(PC),A2		;2ee: 247a00e0
	JSR	resload_Decrunch(A2)	;2f2 (offset=18)
	MOVEM.L	(A7)+,D0-D1/A0-A2	;2f6: 4cdf0703
	RTS				;2fa: 4e75

get_segment_start:
	MOVEM.L	D0-D1/A0-A2,-(A7)	;2fc: 48e7c0e0
	LEA	segment_start(PC),A1		;300: 43fa00d6
	ADDQ.W	#4,A0			;304: 5848
	MOVE.L	A0,(A1)			;306: 2288
	MOVEA.L	A0,A1			;308: 2248
	MOVE.B	subexecutable_first_letter(PC),D0	;30a: 103afe0f
	CMPI.B	#'m',D0			;30e: 0c00006d
	BEQ.S	patch_methane		;312: 6714
	CMPI.B	#'c',D0			;314: 0c000063
	BEQ.S	patch_choose		;318: 671a
	CMPI.B	#'d',D0			;31a: 0c000064
	BEQ.S	patch_doanim		;31e: 670e
LAB_0017:
	MOVEM.L	(A7)+,D0-D1/A0-A2	;320: 4cdf0703
	JMP	4(A0)			;324: 4ee80004

patch_methane:
	LEA	pl_methane(PC),A0		;328: 41faff2c
	BRA.S	LAB_001B		;32c: 600a
patch_doanim:
	LEA	pl_doanim(PC),A0		;32e: 41faff08
	BRA.S	LAB_001B		;332: 6004
patch_choose:
	LEA	pl_choose(PC),A0		;334: 41fafecc
LAB_001B:
	MOVEA.L	_resload(PC),A2		;338: 247a0096
	JSR	resload_Patch(A2)	;33c (offset=64)
	BRA.S	LAB_0017		;340: 60de
LABN_0342:
	ADDQ.L	#4,A0			;342: 5888
	MOVEM.L	A0-A1,-(A7)		;344: 48e700c0
	LEA	subexecutable_first_letter(PC),A1	;348: 43fafdd1
	MOVE.B	(A0),(A1)		;34c: 1290
	MOVEM.L	(A7)+,A0-A1		;34e: 4cdf0300
	MOVE.L	A0,D1			;352: 2208
	JMP	_LVOLoadSeg(A6)		;354: 4eeeff6a

keyboard_interrupt_handler:
	MOVEM.L	D0/A0,-(A7)		;358: 48e78080
	MOVE.B	CIAA_SDR,D0		;35c: 103900bfec01
	NOT.B	D0			;362: 4600
	ROR.B	#1,D0			;364: e218
	CMP.B	_keyexit(PC),D0	;366: b03afcb7
	BEQ	_quit		;36a: 6770
	CMP.B	trainer_keycode(PC),D0		;36c: b03afdae
	BEQ.S	LAB_001E		;370: 6750
	LEA	trainer_used(PC),A0		;372: 41fafda8
	MOVE.B	D0,(A0)			;376: 1080
	CMPI.B	#$5f,D0			;378: 0c00005f
	BNE.S	LAB_001E		;37c: 6644
	MOVE.L	D0,-(A7)		;37e: 2f00
LAB_001C:
	MOVE.W	D0,COLOR00		;380: 33c000dff180
	SUBQ.W	#1,D0			;386: 5340
	BTST	#0,EXT_0005		;388: 0839000000dff005
	BEQ.S	LAB_001C		;390: 67ee
LAB_001D:
	MOVE.W	D0,COLOR00		;392: 33c000dff180
	SUBQ.W	#1,D0			;398: 5340
	BTST	#0,EXT_0005		;39a: 0839000000dff005
	BNE.S	LAB_001D		;3a2: 66ee
	MOVE.L	(A7)+,D0		;3a4: 201f
	MOVE.L	A0,-(A7)		;3a6: 2f08
	MOVEA.L	segment_start(PC),A0		;3a8: 207a002e
	ADDA.L	#$00009e0c,A0		;3ac: d1fc00009e0c
	EORI.L	#$1d194e15,(A0)		;3b2: 0a901d194e15
	LEA	trainer_keycode(PC),A0		;3b8: 41fafd60
	MOVE.B	#$ff,(A0)		;3bc: 10bc00ff
	MOVEA.L	(A7)+,A0		;3c0: 205f
LAB_001E:
	MOVEM.L	(A7)+,D0/A0		;3c2: 4cdf0101
	BTST	#5,EXT_0006		;3c6: 0839000500dff01f
	RTS				;3ce: 4e75

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

	add.l	d7,d7
	add.l	d7,d7

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	a3-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a3-a6/d7
.skip
	;call
	move.l	d7,a1

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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

LAB_0020:
	dc.l	0			;3d4: 00000000
segment_start:
	dc.l	0			;3d8: 00000000
_quit:
	PEA	TDREASON_OK			;3dc: 4878ffff
	BRA.S	LAB_0024		;3e0: 600a
LAB_0023:
	PEA	TDREASON_DEBUG			;3e2: 48780005
LAB_0024:
	MOVE.L	_resload(PC),-(A7)	;3ec: 2f3affe2
	ADDQ.L	#4,(A7)			;3f0: 5897
	RTS				;3f2: 4e75

