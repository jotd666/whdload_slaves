CHIPMEMSIZE=$80000
FASTMEMSIZE=$0
FAKEFMEMSIZE=$0
MAJOR_VERSION = 1
MINOR_VERSION = 3
	IFD	BARFLY
WHDLOADSLAVE = 1
	OUTPUT	ThemeParkMystery.slave
	ENDC
	incdir	include:
	include	"jst.i"
	HD_PARAMS	"disk.",STD_DISK_SIZE,1,<Theme Park Mystery>,<1991 Imageworks & Konami>,<coded by Abaddon>,<adapted to WHDLoad by JOTD>

_loader:
	RELOC_MOVEL	D0,trainer
	
	Mac_printf	"Theme Park Mystery HD Loader v1.2b"
	Mac_printf	"Programmed by Keith Krellwitz (Abaddon) ©1997"

	tst.l	D0
	beq		notrain
	NEWLINE
	Mac_printf	"Trainer activated"
notrain:
	JSRABS	LoadDisks

	move.l	#CACRF_CopyBack,D1
	moveq.l	#0,D0
	JSRABS	Degrade

	GO_SUPERVISOR
	SAVE_OSDATA	CHIPMEMSIZE

	LEA		$0007FFF0,A7
	MOVE	#$2700,SR
	MOVE.W	#$7FFF,$00DFF09A
	MOVE.W	#$7FFF,$00DFF09C
	MOVE.W	#$7fff,$00DFF096
	BSET	#$01,$00BFE001

	move.l	#$0,d0
	move.l	#$0,d3
	lea		$79000,a0
	move.l	#$5b6,d1
	move.l	#$1,d2
	JSRGEN ReadRobSectors
	cmpi.l	#$524e4301,(a0)
	bne		imageworks
	move.l	#$0,d0						;Konami/Imageworks loader
	move.l	#$0,d3
	lea		$a498,a0
	move.l	#$629,d1
	move.l	#$34,d2
	JSRGEN ReadRobSectors
	move.l	#$524e4331,$24
	PATCHUSRJMP	$ab34,ReadRobSectors
	PATCHUSRJMP	$a5a8,jumper
	JSRGEN	FlushCachesHard
	jmp		$a4b6
imageworks:
	move.l	#$0,d0						;Imageworks loader
	move.l	#$0,d3
	lea		$19fe4,a0
	move.l	#$5b6,d1
	move.l	#$118,d2
	JSRGEN ReadRobSectors
jumper:
	bsr		patloader
	JSRGEN	FlushCachesHard
	jmp		$1a000

patloader:
	PATCHUSRJMP	$1a16e,ReadRobSectors
	PATCHUSRJSR	$1caa8,pointerfx		;RN prot shit bypassed
	PATCHUSRJSR	$1ad22,KbInt

	clr.l	$398f4						;2nd and 3rd versions need this one

	clr.l	$39996						;RN check clr's here
	move.w	#$4e75,$1a158
	move.l	trainer(pc),d0
	beq.b	notrainer
	clr.b	$21ab9
	clr.b	$2d035
notrainer:
	rts

pointerfx:
	rts

ReadRobSectors
	JSRGEN	ReadRobSectors
	rts

KbInt:
	movea.l	#$36aa2,a0
	IFND	WHDLOADSLAVE
	cmp.b	#$59,d0
	ELSE
	cmp.b	_whdinit_base+ws_keyexit(pc),d0
	ENDC				; f10
	bne		noquit
	JSRGEN	InGameExit
noquit:
	rts
trainer
	dc.l	0
