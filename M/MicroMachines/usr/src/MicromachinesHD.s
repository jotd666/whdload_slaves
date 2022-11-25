CHIPMEMSIZE=$80000
FASTMEMSIZE=$0
FAKEFMEMSIZE=$0
MAJOR_VERSION = 1
MINOR_VERSION = 1
	IFD	BARFLY
WHDLOADSLAVE = 1
WHDLOADSLAVESUBDIR = 1
	OUTPUT	MicroMachines.slave
	ENDC
	incdir	include:
	include	"jst.i"

	HD_PARAMS	"",STD_DISK_SIZE,1,<MicroMachines>,<1993 Codemasters>,<Install & fix by JOTD>
; *** Written by Jean-François Fabre



_loader:
	bra.b	_run
_whddata:
	dc.b	"data",0
	even
_run
	IFND	WHDLOADSLAVE

	Mac_printf	"Micromachines HD Loader V1.1"
	Mac_printf	"Coded by Jean-François Fabre © 1998-2000"

	TESTFILE	midname
	tst.l	D0
	bne	RunTimeFileErr

	move.l	#4000,D0
	JSRABS	LoadSmallFiles
	ENDC

	moveq.l	#0,D0
	move.l	#CACRF_CopyBack,D1
	JSRABS	Degrade

	GO_SUPERVISOR
	SAVE_OSDATA	$80000

	JSRGEN	FreezeAll
	move	#$2700,SR

	bsr	InstallBoot

	JSRGEN	FlushCachesHard

	lea	$7FE00,A7
	jmp	$7EE90

Intro_v1:
	PATCHUSRJMP	$66560,ImploderDecrunch	; decrunch routine in fastmem

	PATCHUSRJMP	$7321E,EmulateCopylock	; protection

	PATCHUSRJSR	$631DE,AvoidAccessFault	; bugfix

	IFND	WHDLOADSLAVE
	PATCHUSRJSR	$6493A,StoreCop	; for iconify
	PATCHUSRJSR	$65940,StoreCop
	ENDC

	PATCHUSRJSR	$659E8,KbInt_1	; keyboard, menu
	PATCH_NOP	$659E8+6

	JSRGEN	FlushCachesHard
	jmp	$62018

Intro_v2:
	PATCHUSRJMP	$64366,ImploderDecrunch	; decrunch routine in fastmem

	bsr	EmulateCopylock

;;	PATCHUSRJMP	$7321E,EmulateCopylock	; protection, skipped


	IFND	WHDLOADSLAVE
	PATCHUSRJSR	$627DE,StoreCop	; for iconify
	PATCHUSRJSR	$637DA,StoreCop
	ENDC

	PATCHUSRJSR	$63882,KbInt_1_v2	; keyboard, menu
	PATCH_NOP	$63882+6

	JSRGEN	FlushCachesHard
	jmp	$60010

AvoidAccessFault:
	lea	$17(A1),A1
	movem.l	D0,-(A7)
	move.l	A1,D0
	swap	D0
	cmp.b	#$92,D0
	movem.l	(A7)+,D0
	bne.b	.continue

	; avoids access fault

	addq.l	#4,A7
	rts

.continue:
	clr.b	(A1)
	rts

EmulateCopylock:
	move.l	#$28539983,$F4.W
	rts

KbInt_1_v2:
	move.b	D1,($3C10).w
	bra	KbInt_Common

KbInt_1:
	move.b	D1,($3A10).w
	bra	KbInt_Common

KbInt_2:
	move.b	D1,($6B00).w
	bra	KbInt_Common

KbInt_2_v2:
	move.b	D1,($6D00).w
	bra	KbInt_Common

KbInt_Common:
	IFND	WHDLOADSLAVE
	cmp.b	#$59,D1
	ELSE
	cmp.b	_whdinit_base+ws_keyexit(pc),D1
	ENDC		; F10
	bne	.noquit
	JSRGEN	InGameExit
.noquit
	IFND	WHDLOADSLAVE
	cmp.b	#$42,D1		; TAB
	bne	.noicon
	JSRGEN	InGameIconify
.noicon
	ENDC
	bclr	#7,D1		; original game
	RTS

	IFND	WHDLOADSLAVE
StoreCop:
	move.l	D0,-(sp)
	move.l	4(A0),D0
	move.l	D0,$80(A6)
	JSRGEN	StoreCopperPointer
	move.l	(sp)+,D0
	rts
	ENDC

InstallBoot:
	lea	midname(pc),A0
	lea	$7EE60,A1
	moveq	#-1,D1
	moveq	#0,D0
	JSRGEN	ReadFile
	IFND	WHDLOADSLAVE
	tst.l	D0
	bne	RunTimeFileErr
	ENDC

	; fix SNOOP bug

	PATCHUSRJSR	$7EEEC,GetVPos
	move.w	#$6004,$7EEEC+6
	

	move.l	$7FC5E,D0
	cmp.l	#$2C780004,D0
	beq	.version_1

; version_2: ; legalized crack

	move.l	#$60104E71,$7EEC4

	PATCHUSRJMP	$7FC2C,FakeMemDetect	; memory extension: none

	PATCHUSRJSR	$7F796,Intro_v2		; introduction

	PATCHUSRJMP	$7F84C,SetTrap2		; read fat + set trap 1

	PATCHUSRJMP	$7F8CE,ReadTheFile
	rts


.version_1: ; original
	move.l	#$600E4E71,$7EEC4	; remove page 0 clear

	PATCHUSRJMP	$7FC5E,FakeMemDetect	; memory extension: none

	PATCHUSRJSR	$7F7A6,Intro_v1		; introduction

	PATCHUSRJMP	$7F8EE,SetTrap1		; read fat + set trap 1

	PATCHUSRJMP	$7F970,ReadTheFile

	PATCHUSRJMP	$75EB2,ImploderDecrunch		; read fat + set trap 1

	rts

GetVPos:
	move.w	$DFF006,$188.W
	move.w	#$14AA,$18A.W
	rts

; A0: filename
; A1: file dest buffer

ReadTheFile:
	STORE_REGS
	moveq	#0,D0
	moveq	#-1,D1
	JSRGEN	ReadFile
	IFND	WHDLOADSLAVE
	tst.l	D0
	bne	FileErr
	ENDC

	cmp.l	#$11C16B00,$785BC
	bne	.nopatch_v1

	; in-game patches

	move.w	#$6004,$719DA		; remove FMODE change

	PATCHUSRJSR	$775FE,BlitStuff	; snoop fixes
	PATCH_NOP	$775FE+6
	PATCHUSRJSR	$7774A,BlitStuff	; snoop fixes
	PATCH_NOP	$7774A+6
	PATCHUSRJSR	$777FE,BlitStuff	; snoop fixes
	PATCH_NOP	$777FE+6

	PATCHUSRJSR	$785BC,KbInt_2	; keyboard, game
	PATCH_NOP	$785BC+6

	PATCHUSRJMP	$7CE72,ImploderDecrunch
.nopatch_v1:
	cmp.l	#$11C16D00,$7858C
	bne	.nopatch_v2

	; plomb ds boucle 71B74

	; in-game patches

	PATCHUSRJSR	$7858C,KbInt_2_v2	; keyboard, game
	PATCH_NOP	$7858C+6

	PATCHUSRJMP	$75EB2,ImploderDecrunch

.nopatch_v2

	JSRGEN	FlushCachesHard
	RESTORE_REGS
	rte

	IFND	WHDLOADSLAVE
RunTimeFileErr:
	lea	FileErrMsg(pc),A0
	JSRGEN	SetExitRoutine
	JSRGEN	InGameExit
	bra.b	RunTimeFileErr
	ENDC

BlitStuff:
	movem.l	A5,-(A7)
	lea	.returnaddy(pc),A5
	move.l	4(A7),(A5)	; return address

	lea	8(A7),A5
	move.l	(A5)+,($50,A6)
	move.l	(A5)+,($54,A6)

	movem.l	(A7)+,A5

	; now pop up the stack
	addq.l	#8,A7

	move.l	.returnaddy(pc),(A7)	; change return address
	rts
.returnaddy:
	dc.l	0

SetTrap1:
	move.l	#$7F970,$84.W
	rts
SetTrap2:
	move.l	#$7F8CE,$84.W
	rts


ImploderDecrunch
	JSRGEN	ImploderDecrunch
	rts

FakeMemDetect:
	moveq	#0,D4
	move.l	#$32,D7
	move.l	#$7FFE0,D5
	rts

	IFND	WHDLOADSLAVE
FileErr:
	bsr	FileErrMsg
	JMPABS	CloseAll

FileErrMsg:
	Mac_printf	"** One of the files was not found!"
	Mac_printf	"   Press Return"
	JSRABS	WaitReturn
	rts
	ENDC
	
midname:
	dc.b	"MID",0
	cnop	0,4
