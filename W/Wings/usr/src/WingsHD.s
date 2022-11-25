CHIPMEMSIZE=$80000
FASTMEMSIZE=$80000
;;FASTMEMSIZE=$100000
FAKEFMEMSIZE=0
MAJOR_VERSION = 1
MINOR_VERSION = 0
	IFD	BARFLY
WHDLOADSLAVE = 1
WHDLOADSLAVESUBDIR = 1
	OUTPUT	Wings.slave
	ENDC
	incdir	include:
	include  "syslibs.i"
	include	"jst.i"

; *** Wings HD loader v1.0
; *** Written by Jean-François Fabre


	HD_PARAMS   "",0,0,<Wings>,<1990 Cinemaware>,<Install by JOTD>

loader:
	bra.b	_run
_whddata:
	dc.b	"data",0
	even
_run

	move.l   #FASTMEMSIZE,D0
	JSRABS   AllocExtMem

	Mac_printf  "Wings HD Loader v1.0"
	Mac_printf  "Coded by Jean-François Fabre © 2001"

	TESTFILE	progname
	tst.l	D0
	bne	ExeErr


	JSRABS	UseHarryOSEmu

	JSRABS	LoadFiles

	moveq.l	#0,D0
	move.l	#CACRF_CopyBack,D1
	JSRABS	Degrade

	GO_SUPERVISOR
	SAVE_OSDATA	CHIPMEMSIZE
	move.w	#0,SR

	bsr	InstallBoot

	bsr	PatchDosFunctions

	; **** boot stuff and patch

	JSRGEN	FlushCachesHard

	jsr	(A1)

	JSRGEN	InGameExit

InstallBoot:
	lea	progname(pc),A0
	bsr	LoadExecutable

	IFD	WAITBLIT
	STORE_REGS
	move.l	A1,A3
	move.l	A3,A0
	move.l	A3,A1
	add.l	#$10000,A1
	moveq.l	#8,D0
	lea	.blit11(pc),A2
.blloop11
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipbl11
	

	PATCHUSRJSR	(A0),_waitblit11
	bra.b	.blloop11
.skipbl11
	RESTORE_REGS
	ENDC


	rts
.blit11:
	dc.l	$376CB2EA,$00585245


_loadseg:
	pea	.cont(pc)
	move.l	_loadseg_save(pc),-(A7)
	rts
.cont
	STORE_REGS

	addq.l	#1,D0
	add.l	D0,D0
	add.l	D0,D0
	move.l	D0,A1
	move.l	A1,A3

	move.l	A1,A0
	add.l	#$12000,A1
	move.l	#12,D0
	lea	.prot(pc),A2
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip
	move.l	#$4e754e75,(A0)+	; remove protection screen
.skip
	IFD	WAITBLIT
	move.l	A3,A0
	move.l	A3,A1
	add.l	#$30000,A1
	move.l	#14,D0
	lea	.blit(pc),A2
.blloop
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipbl
	PATCHUSRJSR	(A0),_waitblit
	PATCH_NOPNOP	6(A0)
	PATCH_NOPNOP	10(A0)
	bra.b	.blloop
	
.skipbl

	move.l	A3,A0
	move.l	A3,A1
	add.l	#$30000,A1
	move.l	#14,D0
	lea	.blit2(pc),A2
.blloop2
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipbl2
	PATCHUSRJSR	(A0),_waitblit
	PATCH_NOPNOP	6(A0)
	PATCH_NOPNOP	10(A0)
	bra.b	.blloop2
.skipbl2

	move.l	A3,A0
	move.l	A3,A1
	add.l	#$30000,A1
	moveq.l	#10,D0
	lea	.blit10(pc),A2
.blloop10
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipbl10

	PATCHUSRJSR	(A0),_waitblit10
	PATCH_NOP	6(A0)
	bra.b	.blloop10
.skipbl10


	move.l	A3,A0
	move.l	A3,A1
	add.l	#$30000,A1
	moveq.l	#8,D0
	lea	.blit12(pc),A2
.blloop12
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipbl12

	PATCHUSRJSR	(A0),_waitblit12
	bra.b	.blloop12
.skipbl12


	move.l	A3,A0
	move.l	A3,A1
	add.l	#$30000,A1
	moveq.l	#8,D0
	lea	.blit13(pc),A2
.blloop13
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipbl13

	PATCHUSRJMP	(A0),_waitblit13
	bra.b	.blloop13
.skipbl13

	ENDC

	RESTORE_REGS
	tst.l	D0
	rts

.prot:
	dc.l	$4e55fffe,$3f3c008c,$3f3c0010
.blit:
	dc.w	$082B,$000E,$0002
	dc.w	$082B,$000E,$0002,$66F8
.blit2:
	dc.w	$082B,$0006,$0002
	dc.w	$082B,$0006,$0002,$66F8
.blit10:
	dc.w	$2748,$0054,$3741,$0058,$4E75
.blit12:
	dc.l	$37420058,$52466094
.blit13:
	dc.l	$376CD7AC,$00584E75

_hexsearch
	JSRGEN	HexSearch
	rts

_waitblit10:
	move.l	A0,($54,A3)
	bsr	_waitblit
	move.w	D1,($58,A3)
	bsr	_waitblit
	rts
_waitblit11:
	bsr	_waitblit
	move.w	(-$4D16,A4),($58,A3)
	bsr	_waitblit
	rts
_waitblit12:
	bsr	_waitblit
	move.w	D3,($58,A3)
	bsr	_waitblit
	addq.w	#1,D6
	rts
_waitblit13:
	bsr	_waitblit
	move.w	(-$2854,A4),($58,A3)
	bsr	_waitblit
	rts

ExeErr:
	FILE_NOT_FOUND	progname
	JMPABS	CloseAll

_waitblit:
	JSRGEN	WaitBlit
	rts

PatchDosFunctions:
	STORE_REGS
	move.l	dosbase(pc),a0
	add.w	#_LVOOpen+2,a0
	lea	_open_save(pc),a1
	move.l	(a0),(a1)
	lea	_openfile(pc),a1
	move.l	a1,(a0)
	move.l	dosbase(pc),a0
	add.w	#_LVOLock+2,a0
	lea	_lock_save(pc),a1
	move.l	(a0),(a1)
	lea	_lockfile(pc),a1
	move.l	a1,(a0)
	move.l	dosbase(pc),a0
	add.w	#_LVODeleteFile+2,a0
	lea	_deletefile(pc),a1
	move.l	a1,(a0)
	move.l	dosbase(pc),a0
	add.w	#_LVOLoadSeg+2,a0
	lea	_loadseg_save(pc),a1
	move.l	(a0),(a1)
	lea	_loadseg(pc),a1
	move.l	a1,(a0)
	RESTORE_REGS
	rts


_openfile:
	bsr	skipdir
	move.l	_open_save(pc),-(a7)
	rts

_lockfile:
	bsr	skipdir
	move.l	_lock_save(pc),-(a7)
	rts

; < D1: name
; > D1: name without <dirname>/

skipdir:
	STORE_REGS	A0/D2
	move.l	d1,a0

	JSRGEN	SkipColon		; skips possible 'DF0:' stuff

.loop
	move.b	(A0)+,d0
	beq.b	.exit
	cmp.b	#'/',d0
	bne.b	.loop

	move.l	a0,d1
.exit
	RESTORE_REGS	A0/D2
	rts

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

	LSL.L	#2,D0
	MOVE.L	D0,A1
	ADDQ.L	#4,A1

	lea	progargs(pc),A0
	move.l	A0,D0
	JSRGEN	StrlenAsm	; arguments length

	JSRGEN	FlushCachesHard
	movem.l	(A7)+,A2-A6/D1-D7
	rts

_deletefile:
	moveq.l	#-1,D0
	rts

loaderseg:
	dc.l	0
dosbase:
	dc.l	0
_loadseg_save:
	dc.l	0
_lock_save:
	dc.l	0
_open_save:
	dc.l	0


progname:
	dc.b	"Wings",0
progargs:
	; your arguments here (ex: dc.b "/f data1")
	dc.b	10,0		; linefeed + null termination
dosname:
	dc.b	"dos.library",0
	even

