;*---------------------------------------------------------------------------
;  :Program.	SabreTeamHD.asm
;  :Contents.	Slave for "SabreTeam"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SabreTeamHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	IFD	CD32
	OUTPUT	"SabreTeamCD32.slave"
	ELSE
	OUTPUT	"SabreTeamAGA.slave"
	ENDC
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

; $282E8: crash on save/load

;DEBUG

	IFD	DEBUG
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $20000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1

	IFND	CD32
DISKSONBOOT
WPDRIVES	= %1111
	ELSE
WPDRIVES	= %0000
	ENDC

DOSASSIGN
HDINIT
INITAGA
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


DUMMY_CD_DEVICE = 1
USE_DISK_LOWLEVEL_LIB
USE_DISK_NONVOLATILE_LIB

;============================================================================

	IFD	CD32
	INCLUDE	kick31cd32.s
	ELSE
	INCLUDE	kick31.s
	ENDC

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

_assign0
	dc.b	"CD0",0
_assign1
	dc.b	"SabreTeam_Disk1",0
_assign2
	dc.b	"SabreTeam_Disk2",0
_assign3
	dc.b	"SabreTeam_Disk3",0
_assign4
	dc.b	"SabreTeam_Disk4",0
_assign5
	dc.b	"SabreTeam_Disk5",0


slv_name	dc.b	"Sabre Team "
		IFD	CD32		
		dc.b	"CD³²"
		ELSE
		dc.b	"AGA"
		ENDC
		dc.b	0
slv_copy	dc.b	"1992 Krisalis",0
slv_info	dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"CD³² emulation keys",10,10
		dc.b	"F1 : green",10
		dc.b	"F2 : yellow",10
		dc.b	"F3 : red",10
		dc.b	"F4 : blue",10
		dc.b	"F5 : play",10
		dc.b	10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"UnPack",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

		bsr	openwindow
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign0(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign5(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	detect_version

		IFD	CD32
		bsr	_patch_cd32_libs
		ENDC

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

detect_version
	lea	st1200(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	IFND	CD32
	cmp.l	#347100,d0
	beq.b	.aga
	ELSE
	cmp.l	#348148,d0
	beq.b	.cd32
	ENDC

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.aga
	lea	version(pc),a1
	move.l	#1,(a1)

;	lea	savedir(pc),a0
;	bsr	must_exist

	rts
.cd32
	lea	version(pc),a1
	move.l	#2,(a1)
	rts

version	
	dc.l	0

; < d7: seglist

patch_main
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_unpack(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts

pl_unpack
	PL_START
	PL_P	$11E,run_game
	PL_END
	
run_game
	MOVE	278(A5),D0		;2A8: 302D0116
	ADD	D0,D0			;2AC: D040
	ADD	D0,D0			;2AE: D040
	MOVE.L	12(A5,D0.W),D0
	MOVEA.L	D0,A0			;122: 2040

	movem.l	D0-D1/A0-A3,-(a7)

	move.l	2(a0),a3	; store address to "hunk" #1

	move.l	_resload(pc),a2
	move.l	a0,a1

	move.l	version(pc),d0
	cmp.l	#2,d0
	beq.b	.cd32

	lea	pl_main_0_aga(pc),a0
	jsr	resload_Patch(a2)
	bra.b	.out
.cd32
	add.l	#$2ECB7-$237B0,a0
	lea	sabre_rawkeycode(pc),a2
	move.l	a0,(a2)
	
	lea	pl_main_0_cd32(pc),a0
	jsr	resload_Patch(a2)
	

.out
	;enable cache in chipmem

	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	movem.l	(a7)+,D0-D1/A0-A3
	JMP	(A0)			;124: 4ED0

sabre_rawkeycode
	dc.l	0

pl_main_0_aga
	PL_START
	PL_W	$184D2-$A440,$4E71	; protection check #1
	PL_W	$184DE-$A440,$4E71	; protection check #2
	PL_R	$208FC-$A440		; don't have to click for the protection
	PL_PS	$30678-$A440,fix_add_d2	; access fault

;	PL_PS	$31914-$A440,openfile
;	PL_PA	$2850E-$A440,savedir
;	PL_PA	$28168-$A440,savedir
	PL_END

pl_main_0_cd32
	PL_START
	PL_P	$2F23E-$237B0,end_read_joypad
	PL_PS	$49C76-$237B0,fix_add_d2
	PL_END

openfile
	move.l	#MODE_OLDFILE,D2
	btst	#6,$bfe001
	bne.b	.x
	illegal
.x
	RTS
end_read_joypad
	move.l	sabre_rawkeycode(pc),a2
	move.b	(a2),d2

	cmp.b	#$50,d2		; F1
	bne.b	.nof1
	bset	#JPB_BUTTON_GREEN,d0
.nof1
	cmp.b	#$51,d2		; F2
	bne.b	.nof2
	bset	#JPB_BUTTON_YELLOW,d0
.nof2
	cmp.b	#$52,d2		; F3
	bne.b	.nof3
	bset	#JPB_BUTTON_RED,d0
.nof3
	cmp.b	#$53,d2		; F4
	bne.b	.nof4
	bset	#JPB_BUTTON_BLUE,d0
.nof4
	cmp.b	#$54,d2		; F5
	bne.b	.nof5
	bset	#JPB_BUTTON_PLAY,d0
.nof5
	MOVEM.L	(A7)+,D2-D7/A2-A6	;2F23E: 4CDF7CFC
	RTS				;2F242: 4E75

fix_add_d2
	add.w	d2,a4	; was add.l
	lsl.w	#3,d2
	add.w	d2,a3
	rts

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
	movem.l	a4-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a4-a6/d7
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


openwindow:
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	lea	.newscreen_struct(pc),A0
	jsr	_LVOOpenScreen(A6)

	lea	.newwindow_struct(pc),A0
	move.l	D0,$1E(A0)	; nw_Screen

	jsr	_LVOOpenWindow(A6)

	rts

.newscreen_struct:
	dc.w	0,0
	dc.w	320,200
	dc.w	2
	dc.b	1,0
	dc.W	0
	dc.W	0
	dc.l	0	; no font
	dc.l	0	; no title
	dc.l	0
	dc.l	0
.newwindow_struct:
	dc.w	0,0
	dc.w	320,200
	dc.w	0
	dc.l	0,0,0,0
	dc.l	0	; no title
	dc.l	0,0
	dc.w	10,10,320,200
	dc.w	0

.intname:
	dc.b	"intuition.library",0
st1200
	dc.b	"SabreTeam1200",0
	even
;============================================================================
