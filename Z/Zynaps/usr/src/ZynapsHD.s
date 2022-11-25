CHIPMEMSIZE=$80000
FASTMEMSIZE=$0
FAKEFMEMSIZE=$0
MAJOR_VERSION=1
MINOR_VERSION=1

	IFD	BARFLY
WHDLOADSLAVE = 1
WHDLOADSLAVEFLAGS=2
	OUTPUT	Zynaps.slave
	ENDC
	
	incdir	include:
	include	"syslibs.i"
	include	"jst.i"
	IFND	WHDLOADSLAVE
	HD_PARAMS	"",0,0
	ELSE
	HD_PARAMS	"",0,0,<Zynaps>,<1988 Hewson>,<Installed & fixed by JF Fabre>
	ENDC
; *** Imperium Hard Disk Loader V1.0
; *** Written by Jean-François Fabre 1999




loader:

	Mac_printf	"Zynaps HD Loader & fix V1.0"
	Mac_printf	"Coded by Jean-François Fabre © 1999"

	JSRABS	UseHarryOSEmu

	TESTFILE	LOADERFILE
	tst.l	d0
	bne	FileErr

	JSRABS	LoadFiles

	moveq.l	#0,D0
	move.l	#CACRF_CopyBack,D1
	JSRABS	Degrade

	GO_SUPERVISOR
	IFND	WHDLOADSLAVE
	SAVE_OSDATA	$80000,#$5D
	ELSE
	SAVE_OSDATA	$80000
	ENDC

	; **** boot stuff and patch

	MOVE.L	$4.W,A6			;OPEN DOSLIB FOR USE (THE EMU
	lea	$12E00,A1
	move.l	#54000,D0
	JSRLIB	AllocAbs
	tst.l	D0
	beq	quit

	lea	LOADERFILE(pc),A0
	lea	$12E00,A1
	moveq	#0,D0
	moveq	#-1,D1
	JSRGEN	ReadFile

	move.l	A1,A0
	JSRGEN	RNCDecrunch

	; remove a disk related CIA access

	PATCH_RTS	$16B28

	; patches cpu waits

	PATCHUSRJSR	$1CF14,EmulateDbfD1
	PATCHUSRJSR	$1D068,EmulateDbfD1

	JSRGEN	FlushCachesHard
	
	move.w	#$A06C,$DFF09A

;;	move.w	#0,SR
	jmp	$12E30

EmulateDbfD1:
	divu.w	#$10,D1
	swap	D1
	clr.w	D1
	swap	D1
	BEAM_DELAY	D1
	rts

quit:
	JSRGEN	InGameExit
FileErr:
	Mac_printf	"A file is missing!"
	JSRABS	CloseAll

loader_seg:
	dc.l	0
DOSP:
	dc.l	0
DOSNAM:
	dc.b	"dos.library",0
LOADERFILE:
	dc.b	"zyn12e00.rnc",0
	even

