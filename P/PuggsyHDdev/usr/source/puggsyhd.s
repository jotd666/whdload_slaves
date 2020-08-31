CHIPMEMSIZE=$80000
FASTMEMSIZE=$80000
FAKEFMEMSIZE=0
MAJOR_VERSION = 1
MINOR_VERSION = 1
	IFD	BARFLY
WHDLOADSLAVE = 1
	OUTPUT	Puggsy.slave
	ENDC
	incdir	include:
	include	"jst.i"


WHDLOADSLAVESUBDIR = 1
	HD_PARAMS	"",0,0,<Puggsy>,<1993 Psygnosis>,<Installed by JOTD>

; *** Puggsy Hard Disk Loader V$VER
; *** Written by Jean-François Fabre

_loader:
	bra.b	_run
_whddata:
	dc.b	"data",0
	even
_run
	move.l	#$80000,D0
	JSRABS	AllocExtMem
	RELOC_MOVEL	D0,ExtBase
	beq	MemErr

	Mac_printf	"Puggsy HD Loader V1.0"
	Mac_printf	"Coded by Jean-François Fabre © 1997"
	
	IFND	WHDLOADSLAVE
	lea	_whddata(pc),A0
	JSRABS	SetFilesPath
	ENDC

	TESTFILE	introname
	tst.l	D0
	bne	FileErr

	move.l	#1000,D0
	JSRABS	LoadSmallFiles

	moveq.l	#0,D0
	move.l	#CACRF_CopyBack,D1
	JSRABS	Degrade


	GO_SUPERVISOR
	SAVE_OSDATA	$80000
	move.w	#$2700,SR

	bsr	InstallBoot

	; **** boot stuff and patch

	JSRGEN	FlushCachesHard
	move.w	#$7FFF,dmacon+$DFF000
	JSRGEN	BlackScreen
	JMP	$918.W

InstallBoot:
	lea	introname(pc),A0
	lea	$800.W,A1
	moveq	#-1,D1
	moveq	#0,D0
	JSRGEN	ReadFile

	lea	$800.W,A0
	move.l	A0,A1
	JSRGEN	RNCDecrunch

	PATCHUSRJMP	$1248.W,RNCDecrunch
	PATCHUSRJMP	$2502.W,LoadFile
	PATCHUSRJMP	$1074.W,KbInt
	PATCHUSRJMP	$148C.W,GetExtMem_1
	PATCHUSRJMP	$208E.W,PatchMain
	PATCHUSRJMP	$20FE.W,PatchIntro2
	move.w	#$4E75,$21C4.W

;	move.w	#$4E75,$22CE.W
;	move.w	#$4E75,$23B0.W

	RTS


PatchIntro2:
	PATCHUSRJMP	$D40C,LoadFile
	PATCHUSRJMP	$DF0A,RNCDecrunch
	PATCHUSRJMP	$D028,PatchMain
	move.w	#$4E75,$D0E2
	PATCHUSRJMP	$1CE9A,GetExtMem_3
	JSRGEN	FlushCachesHard
	jmp	$CC26

GetExtMem_1:
	move.l	ExtBase(pc),$8F4.W
	RTS

GetExtMem_2:
	move.l	ExtBase(pc),$2FB74
	RTS

GetExtMem_3:
	move.l	ExtBase(pc),$7F2E4
	RTS

RNCDecrunch:
	JSRGEN	RNCDecrunch
	rts

KbInt:
	move.b	D0,$808.W
	IFND	WHDLOADSLAVE
	cmp.b	#$59,D0
	ELSE
	cmp.b	_whdinit_base+ws_keyexit(pc),D0
	ENDC
	bne	.noquit
	JSRGEN	InGameExit
.noquit
	RTS

KbInt_2:
	move.b	D0,$20058
	IFND	WHDLOADSLAVE
	cmp.b	#$59,D0
	ELSE
	cmp.b	_whdinit_base+ws_keyexit(pc),D0
	ENDC
	bne	.noquit
	JSRGEN	InGameExit
.noquit
	RTS

PatchMain:
	PATCHUSRJMP	$2FB2A,GetExtMem_2
	PATCHUSRJMP	$1EADC,LoadFile
	PATCHUSRJSR	$23F3A,Patch2ndButton
	PATCHUSRJSR	$1FFDC,KbInt_2
	PATCHUSRJMP	$28B1E,RNCDecrunch
	move.w	#$4E71,$23F40

	move.w	#$4E75,$1E792			; goto root block

	JSRGEN	FlushCachesHard
	JMP	$1B2C0

Patch2ndButton:
	movem.l	D0/A0,-(sp)
	move.w	$DFF016,D0
	move.w	#$CC01,$DFF034	; resets button read
	btst	#14,D0
	movem.l	(sp)+,D0/A0
	rts

LoadFile:
	STORE_REGS	D0-D1/A0-A1
	moveq	#0,D0
	moveq	#-1,D1
	JSRGEN	ReadFile
	RESTORE_REGS	D0-D1/A0-A1
	moveq	#0,D0
	RTS

trainer:
	dc.l	0
ExtBase:
	dc.l	0
introname:
	dc.b	"INTRO.BIN",0
	even


MemErr:
	Mac_printf	"** Not enough memory to run Puggsy!"
	JMPABS	CloseAll

FileErr:
	Mac_printf	"** File ''INTRO.BIN'' missing!"
	JMPABS	CloseAll
