CHIPMEMSIZE=$80000
FASTMEMSIZE=$80000
FAKEFMEMSIZE=0
MAJOR_VERSION = 1
MINOR_VERSION = 1
	IFD	BARFLY
WHDLOADSLAVE = 1
WHDLOADSLAVESUBDIR = 1
	OUTPUT	Killerball.slave
	ENDC
	incdir	include:
	include	"syslibs.i"
	include	"jst.i"

; *** Killerball HD loader v1.0
; *** Written by Jean-François Fabre

	include	"osemu.i"

	HD_PARAMS	"",0,0,<Killerball>,<1990 Microids>,<install/fix by JOTD>

loader:
	bra.b	_run
_whddata:
	dc.b	"data",0
	even
_run

	move.l	#$80000,D0
	JSRABS	AllocExtMem

	Mac_printf	"Killerball HD Loader v1.0"
	Mac_printf	"Coded by Jean-François Fabre © 2000"

	TESTFILE	progname
	tst.l	D0
	bne	ExeErr


	JSRABS	UseHarryOSEmu

	move.l	#91000,D0
	JSRABS	LoadSmallFiles

	moveq.l	#0,D0
	move.l	#CACRF_CopyBack,D1
	JSRABS	Degrade

	GO_SUPERVISOR
	SAVE_OSDATA	$80000

	move.w	#0,SR

	bsr	InstallBoot

	; **** boot stuff and patch

	JSRGEN	FlushCachesHard

	jsr	(A1)

	JSRGEN	InGameExit

InstallBoot:
	lea	progname(pc),A0
	bsr	LoadExecutable

	STORE_REGS
	move.l	(A1),a3	; next seg
	add.l	a3,a3
	add.l	a3,a3
	move.l	a3,a1

	move.l	A1,A0
	add.l	#$1000,A1
	lea	.protect(pc),A2
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip

	move.w	#$33C0,(-6,A0)
	move.l	#$4E716002,(A0)
.skip
	move.w	#17,d0
.loop
	move.l	(a3),a3	; next seg
	add.l	a3,a3
	add.l	a3,a3
	dbf	D0,.loop

	move.l	a3,a1
	move.l	a1,a0
	add.l	#$4000,a1
	lea	.prefetch(pc),A2
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip2
	PATCHUSRJSR	(A0),_avoid_prefetch
.skip2
	move.l	a3,a1
	move.l	a1,a0
	add.l	#$4000,a1
	move.l	#$51C8FFFE,D0
	move.l	#$4EB80100,D1
	JSRGEN	HexReplaceLong

	PATCHUSRJMP	$100,_emulate_dbf
	RESTORE_REGS

	addq.l	#4,A1
	rts

.prefetch:
	dc.l	$42433806,$3A074846
.protect:
	dc.l	$B0416702,$7E014EB9

_emulate_dbf:
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	JSRGEN	BeamDelay
	rts

_avoid_prefetch:
	CLR	D3			;0FE36: 4243
	MOVE	D6,D4			;0FE38: 3806
	MOVE	D7,D5			;0FE3A: 3A07
	JSRGEN	FlushCachesHard
	rts

_hexsearch:
	JSRGEN	HexSearch
	rts

ExeErr:
	FILE_NOT_FOUND	progname

trainer:
	dc.l	0

progname:
	dc.b	"roller.prg",0
	cnop	0,4

; loads an executable by calling OSEmu LoadSeg()
;
; < A0: name of the executable
; > A1: first segment address (do a JSR (4,a1) to start the program)
; > A0: pointers on arguments
; > D0: argument string length
;
; ** no checks are done there so be careful **

LoadExecutable:
	movem.l	A2-A6/D1-D7,-(A7)
	move.l	A0,-(A7)
	MOVE.L	$4.W,A6			;OPEN DOSLIB FOR USE (THE EMU
	MOVEQ.L	#0,D0			;PROVIDES THE FUNCTIONS)
	LEA	dosname(PC),A1
	JSRLIB	OpenLibrary
	RELOC_MOVEL	D0,dosbase
	MOVE.L	D0,A6
	move.l	(A7)+,A0

	MOVE.L	A0,D1
	JSRLIB	LoadSeg
	RELOC_MOVEL	D0,loaderseg

	MOVE.L	D0,A1
	add.l	a1,a1
	add.l	a1,a1

	lea	progargs(pc),A0
	move.l	A0,D0
	JSRGEN	StrlenAsm	; arguments length

	JSRGEN	FlushCachesHard
	movem.l	(A7)+,A2-A6/D1-D7
	rts

; unloads previously loaded executable

UnloadExecutable:
	STORE_REGS
	move.l	dosbase(pc),A6
	move.l	loaderseg(pc),D1
	JSRLIB	UnLoadSeg
	RESTORE_REGS
	rts

loaderseg:
	dc.l	0
dosbase:
	dc.l	0
progargs:
	; your arguments here (ex: dc.b "/f data1")
	dc.b	10,0		; linefeed + null termination
dosname:
	dc.b	"dos.library",0

