CHIPMEMSIZE=$80000
FASTMEMSIZE=$80000
FAKEFMEMSIZE=0
MAJOR_VERSION = 1
MINOR_VERSION = 0
	IFD	BARFLY
WHDLOADSLAVE = 1
OSEMU_USES_LISTFILES = 1
	OUTPUT	Defender.slave
	ENDC
	incdir	include:
	include  "syslibs.i"
	include	"jst.i"
	HD_PARAMS   "",0,0,<Defender>,<1994 Giles.F.McArdell>,<Install by JOTD>

loader:
	move.l   #FASTMEMSIZE,D0
	JSRABS   AllocExtMem

	JSRABS	UseHarryOSEmu

	JSRABS	LoadFiles

	moveq.l	#0,D0
	move.l	#CACRF_CopyBack,D1
	JSRABS	Degrade

	GO_SUPERVISOR
	SAVE_OSDATA	$80000

	move.w	#0,SR

	JSRGEN	BlackScreen

	lea	exename(pc),A0
	bsr	LoadExecutable

	; **** boot stuff and patch

	JSRGEN	FlushCachesHard

	jsr	(A1)

	JSRGEN	InGameExit


; loads an executable by calling OSEmu LoadSeg()
;
; < A0: name of the executable
; > A1: start address (do a JSR (a1) to start the program)
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
	beq.b	.error
	LSL.L	#2,D0
	MOVE.L	D0,A1
	ADDQ.L	#4,A1

	lea	progargs(pc),A0
	move.l	A0,D0
	JSRGEN	StrlenAsm	; arguments length

	JSRGEN	FlushCachesHard
	movem.l	(A7)+,A2-A6/D1-D7
	rts

.error:
	JSRGEN	InGameExit

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
hiscore_address:
	dc.l	0
firsttime:
	dc.l	0
progargs:
	; your arguments here (ex: dc.b "/f data1")
	dc.b	10,0		; linefeed + null termination
dosname:
	dc.b	"dos.library",0
exename:
	dc.b	"defender",0

