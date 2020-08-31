CHIPMEMSIZE=$80000
FASTMEMSIZE=$0
FAKEFMEMSIZE=$0
MAJOR_VERSION = 2
MINOR_VERSION = 0
	IFD	BARFLY
WHDLOADSLAVE = 1
	OUTPUT	SpaceCrusadeExpDisk.slave
	ENDC
	incdir	include:
	include	"jst.i"
	IFND	WHDLOADSLAVE
	HD_PARAMS	"disk.",STD_DISK_SIZE,1
	ELSE
	HD_PARAMS	"disk.",STD_DISK_SIZE,1,<Space Crusade Expansion Disk>,<1992 Gremlin>,<Install & fix by JOTD>
	ENDC
; *** Written by Jean-François Fabre




;SEARCH_FAULTS = 1

loader:
	Mac_printf	"Space Crusade Exp. Disk HD Loader & fix V1.0"
	Mac_printf	"Coded by Jean-François Fabre © 1998"

	bsr	ReadSaveDataHD
	JSRABS	LoadDisks

	moveq.l	#0,D0
	move.l	#CACRF_CopyBack,D1
	JSRABS	Degrade

	GO_SUPERVISOR
	SAVE_OSDATA	$80000

	JSRGEN	FreezeAll

	bsr	InstallBoot

	IFD	SEARCH_FAULTS
	bsr	Install24BitCheck
	ENDC

	JSRGEN	FlushCachesHard
	move.w	#$8210,$DFF000+dmacon
	nop
	nop
	JMP	$73542		; GO GO
	nop
	nop

trace:
	rte

Decrunch:
	JSRGEN	RNCDecrunch
	cmp.w	#$4EB9,$834C
	bne	.patched

	PATCHUSRJSR	$834C,SkipCheckDisk
	PATCHUSRJSR	$8360,SkipPassword

	; *** remove format check

	move.w	#$600E,$9BC6

	; *** replace load dir

	PATCHUSRJSR	$991E,ReadSaveData

.patched
	JSRGEN	FlushCachesHard
	rts

SkipCheckDisk:
	move.b	#1,$189.W
	rts

SkipPassword:
	move.b	#1,$187.W
	rts

InstallBoot:
	moveq	#0,D0
	move.l	#$4700,D1
	move.l	#$2E32,D2
	lea	$10000,A0
	JSRGEN	ReadDiskPart
	
	lea	$10000,A0
	lea	$235C.W,A1
	JSRGEN	RNCDecrunch

	PATCHUSRJMP	$2566.W,ReadSectors

	; *** keyboard quit key

	PATCHUSRJSR	$69EC.W,KbInt

	; *** kb fix acknowledge kb

	move.w	#$4E71,$6A06

	; *** decrunch relocated, and patch after decrunch

	PATCHUSRJMP	$7FAE.W,Decrunch

	; *** blitter

	bsr	PatchBlit

	; *** transfert

	lea	$8296,A6
	LEA	$73542,A5
	MOVE	#$00E1,D7
LAB_0000:
	MOVE	(A6)+,(A5)+
	DBF	D7,LAB_0000
	
	rts

ReadSectors:
	cmp.b	#1,D3
	beq	WriteSectors
	cmp.b	#2,D3
	beq	FormatSectors

	moveq	#2,d0		; disk #3
	JSRGEN	ReadRobSectors
.exit
	moveq	#0,D0
	rts

WriteSectors:
	cmp.b	#$B,D1
	bne	WrongSave
	cmp.b	#$1,D2
	bne	WrongSave

	bsr	WriteSaveData
	moveq	#0,D0
	rts

FormatSectors:
	moveq	#0,d0
	rts

WrongSave:
	IFND	WHDLOADSLAVE
	lea	WrongSaveErr(pc),A0
	JSRGEN	SetExitRoutine
	ENDC
	JSRGEN	InGameExit
	bra	WrongSave

KbInt:
	move.l	D0,-(sp)
	not.b	D0
	ror.b	#1,D0
	IFND	WHDLOADSLAVE
	cmp.b	#$5F,D0
	ELSE
	cmp.b	_whdinit_base+ws_keyexit(pc),D0
	ENDC
	bne	.noquit
	JSRGEN	InGameExit
.noquit
	moveq	#2,D0
	JSRGEN	BeamDelay
	move.l	(sp)+,D0
	rts

PatchBlit:
	STORE_REGS
	PATCHUSRJMP	$C6.W,WaitBlitD0
	PATCHUSRJMP	$CC.W,WaitBlitD1
	PATCHUSRJMP	$D2.W,WaitBlitD7

	move.l	#$35400058,D0
	move.l	#$4EB800C6,D1
	lea	$2A00.W,A0
	lea	$2C00.W,A1
	bsr	HexReplaceLong

	move.l	#$35410058,D0
	move.l	#$4EB800CC,D1
	lea	$2A00.W,A0
	lea	$2C00.W,A1
	bsr	HexReplaceLong

	move.l	#$35470058,D0
	move.l	#$4EB800D2,D1
	lea	$6E00.W,A0
	lea	$7C00.W,A1
	bsr	HexReplaceLong

	PATCHUSRJSR	$6F26.W,PatchBlitD7A5
	PATCHUSRJSR	$6F34.W,PatchBlitD7A5
	PATCHUSRJSR	$6F42.W,PatchBlitD7A5
	PATCHUSRJSR	$6F50.W,PatchBlitD7A5
	PATCHUSRJSR	$6F64.W,PatchBlitD7A5

	PATCHUSRJSR	$71E8.W,PatchBlitD7A6
	PATCHUSRJSR	$71F6.W,PatchBlitD7A6
	PATCHUSRJSR	$7204.W,PatchBlitD7A6
	PATCHUSRJSR	$7212.W,PatchBlitD7A6
	PATCHUSRJSR	$7220.W,PatchBlitD7A6

	PATCHUSRJSR	$74AC.W,PatchBlitD7A6
	PATCHUSRJSR	$74BA.W,PatchBlitD7A6
	PATCHUSRJSR	$74C8.W,PatchBlitD7A6
	PATCHUSRJSR	$74D6.W,PatchBlitD7A6
	PATCHUSRJSR	$74E4.W,PatchBlitD7A6

	RESTORE_REGS
	rts

HexReplaceLong:
	JSRGEN	HexReplaceLong
	rts

PatchBlitD7A5:
	bsr WaitBlit
	move.w	D7,(A5)
	rts

PatchBlitD7A6:
	bsr WaitBlit
	move.w	D7,(A6)
	rts

WaitBlitD0:
	bsr WaitBlit
	move.w	D0,$58(A2)
	rts

WaitBlitD1:
	bsr WaitBlit
	move.w	D1,$58(A2)
	rts

WaitBlitD7:
	bsr WaitBlit
	move.w	D7,$58(A2)
	rts

WaitBlit:
	bsr WaitBlit
	rts

ReadSaveDataHD:
	lea	savename(pc),A0
	lea	savebuff(pc),A1
	moveq	#0,D0
	move.l	#$200,D1
	JSRGEN	ReadUserFileHD
	tst.l	D0
	beq	.exit
	NEWLINE
	Mac_printf	"** Unable to read savegame info"
.exit
	rts

WriteSaveDataHD:
	lea	savename(pc),A0
	lea	savebuff(pc),A1
	moveq	#0,D0
	move.l	#$200,D1
	JSRGEN	WriteUserFileHD
	tst.l	D0
	beq	.exit
	NEWLINE
	Mac_printf	"** Unable to write savegame info!"
	Mac_printf	"   Hit RETURN"
	JSRABS	WaitReturn
.exit
	rts

WrongSaveErr:
	Mac_printf	"** Unexpected write command. Contact author"
	Mac_printf	"   Hit RETURN"
	JSRABS	WaitReturn
	rts

WriteSaveData:
	STORE_REGS
	lea	savebuff(pc),A1
	move.l	#$7F,D0
.copy
	move.l	(A0)+,(A1)+
	dbf	D0,.copy

	IFND	WHDLOADSLAVE
	lea	WriteSaveDataHD(pc),A0
	JSRGEN	SetExitRoutine
	ELSE
	bsr	WriteSaveDataHD
	ENDC

	RESTORE_REGS
	moveq	#0,D0
	rts

ReadSaveData:
	STORE_REGS
	lea	savebuff(pc),A1
	move.l	(A1),D0

	cmp.l	#'FUCK',D0
	beq	.quit
	
	move.l	#$7F,D0
.copy
	move.l	(A1)+,(A0)+
	dbf	D0,.copy

	RESTORE_REGS
	moveq	#0,D0
	rts

.quit
	RESTORE_REGS
	moveq	#-1,D0
	rts


save_changed:
	dc.l	0
ExtBase:
	dc.l	0

savename:
	dc.b	"spcrus.sav",0
	even
savebuff:
	dc.b	"FUCK"
	blk.l	$90,0
