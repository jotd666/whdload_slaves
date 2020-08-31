CHIPMEMSIZE=$80000
FASTMEMSIZE=$0
FAKEFMEMSIZE=$0
MAJOR_VERSION = 2
MINOR_VERSION = 2
	IFD	BARFLY
WHDLOADSLAVE = 1
	OUTPUT	SpaceCrusade.slave
	ENDC
	incdir	include:
	include	"jst.i"
	IFND	WHDLOADSLAVE
	HD_PARAMS	"disk.",STD_DISK_SIZE,2
	ELSE
	HD_PARAMS	"disk.",STD_DISK_SIZE,2,<Space Crusade>,<1991 Gremlin>,<Install & fix by JOTD>
	ENDC
; *** Written by Jean-François Fabre




;SEARCH_FAULTS = 1

_loader:
;	Mac_printf	"Space Crusade HD Loader & fix V1.1a"
;	Mac_printf	"Coded by Jean-François Fabre © 1997"

	bsr	ReadSaveDataHD
	JSRABS	LoadDisks

	moveq.l	#0,D0
	move.l	#CACRF_CopyBack,D1
	JSRABS	Degrade

	GO_SUPERVISOR
	SAVE_OSDATA	$80000

	move	#$2700,SR

	bsr	InstallBoot

	IFD	SEARCH_FAULTS
	bsr	Install24BitCheck
	ENDC

	; **** boot stuff and patch

	JSRGEN	FlushCachesHard
	move.w	#$83D0,dmacon+$DFF000
	jmp	$8006

FlushNJump:
	PATCHUSRJSR	$7D14,Patch24Bit
	PATCHUSRJSR	$6A10.W,KbInt1
	PATCHUSRJSR	$2380.W,PatchProtect

	move.l	#$7FF00,$7366A		; changes stack location
	bsr	PatchBlit

	JSRGEN	FlushCachesHard
	JMP	$73668

PatchBlit:
	STORE_REGS
	PATCHUSRJMP	$C6.W,WaitBlitD0
	PATCHUSRJMP	$CC.W,WaitBlitD1
	PATCHUSRJMP	$D2.W,WaitBlitD7

	move.l	#$35400058,D0
	move.l	#$4EB800C6,D1
	lea	$2000.W,A0
	lea	$7FFC.W,A1
	bsr	HexReplaceLong

	move.l	#$35410058,D0
	move.l	#$4EB800CC,D1
	lea	$2000.W,A0
	lea	$7FFC.W,A1
	bsr	HexReplaceLong

	move.l	#$35470058,D0
	move.l	#$4EB800D2,D1
	lea	$2000.W,A0
	lea	$7FFC.W,A1
	bsr	HexReplaceLong

	PATCHUSRJSR	$6F4A.W,PatchBlitD7A5
	PATCHUSRJSR	$6F58.W,PatchBlitD7A5
	PATCHUSRJSR	$6F66.W,PatchBlitD7A5
	PATCHUSRJSR	$6F74.W,PatchBlitD7A5
	PATCHUSRJSR	$6F88.W,PatchBlitD7A5

	PATCHUSRJSR	$720C.W,PatchBlitD7A6
	PATCHUSRJSR	$721A.W,PatchBlitD7A6
	PATCHUSRJSR	$7228.W,PatchBlitD7A6
	PATCHUSRJSR	$7236.W,PatchBlitD7A6
	PATCHUSRJSR	$7244.W,PatchBlitD7A6
	PATCHUSRJSR	$74D0.W,PatchBlitD7A6
	PATCHUSRJSR	$74DE.W,PatchBlitD7A6
	PATCHUSRJSR	$74EC.W,PatchBlitD7A6
	PATCHUSRJSR	$74FA.W,PatchBlitD7A6
	PATCHUSRJSR	$7508.W,PatchBlitD7A6

	PATCH_NOP	$6A24.W
	PATCHUSRJSR	$6A26.W,KbAck

	PATCH_NOP	$7AE2.W
	PATCHUSRJSR	$7AE4.W,CheckA0AA
	RESTORE_REGS
	rts

CheckA0AA:
	cmp.w	#$3E30,$A0AA
	bne.b	.sk
	PATCHUSRJSR	$A0AA,AvoidAf
	JSRGEN	FlushCachesHard
.sk
	clr.b	$2B5.W
	move.b	$28E.W,d0
	rts

AvoidAf:
	cmp.l	#0,a0
	beq.b	.sk
	move.w	(0,a0,d2.w),d7
	and.w	d1,d7
.sk
	rts
HexReplaceLong:
	JSRGEN	HexReplaceLong
	rts

PatchBlitD7A5:
	bsr	WaitBlit
	move.w	D7,(A5)
	rts

KbAck:
	move.b	#1,($500,a0)
	BEAM_DELAY #2
	rts

PatchBlitD7A6:
	bsr	WaitBlit
	move.w	D7,(A6)
	rts

WaitBlitD0:
	bsr	WaitBlit
	move.w	D0,$58(A2)
	rts

WaitBlitD1:
	bsr	WaitBlit
	move.w	D1,$58(A2)
	rts

WaitBlitD7:
	bsr	WaitBlit
	move.w	D7,$58(A2)
	rts

WaitBlit:
	JSRGEN	WaitBlit
	rts

PatchProtect:
	move.w	#1,($17C).W
	move.w	#$6004,$80C4	; removes protection

	move.w	#$6048,$98FC	; skip format check for saves

	move.w	#$4E71,$9648
	PATCHUSRJSR	$964A,WriteSaveData

	move.w	#$4E71,$9676
	PATCHUSRJSR	$9678,ReadSaveData

;	move.w	#$7002,$845E	; activates expansion mission disk
	JSRGEN	FlushCachesHard
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

Patch24Bit:
	movem.l	($364).W,A1-A3
	move.l	D0,-(a7)
	move.l	A1,D0
	and.l	#$FFFFFF,D0	; remove higher byte
	move.l	D0,A1
	move.l	(a7)+,D0
	rts

KbInt1:
	move.l	D0,-(sp)
	ror.b	#1,D0
	not.b	D0
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

PatchProg2:
	JSRGEN	FlushCachesHard
	nop
	nop
	jmp	$43EA2
	nop
	nop

InstallBoot:
	moveq	#0,D0
	move.l	#$1600,D2
	move.l	#$4D000,D1
	lea	$8000,A0
	JSRGEN	ReadDiskPart

	PATCHUSRJMP	$43F2C,ReadSectors
	PATCHUSRJMP	$43EC8,PatchProg1

	GETUSRADDR	PatchProg2
	move.l	D0,$7FFC.W
	rts


PatchProg1:
.loop
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	dbf	D7,.loop

	PATCHUSRJMP	$251A.W,ReadSectors2
	PATCHUSRJMP	$7FFC.W,FlushNJump
	JSRGEN	FlushCachesHard
	jmp	(A2)
	
	
ReadSectors2:
	bsr	GetDiskId
	JSRGEN	ReadRobSectors
	rts

GetDiskId
	cmp.l	#'SPC2',$176.W
	bne	.nod2
	moveq	#1,D0
.nod2
	cmp.l	#'SPCR',$176.W
	bne	.quit
	moveq	#0,D0
.quit
	rts

ReadSectors:
	JSRGEN	ReadRobSectors
	rts

	IFD	SEARCH_FAULTS

Install24BitCheck:
	GETUSRADDR	Check24Bit
	move.l	D0,$24.W
	move.w	#$4E75,$D0.W
	rts

Check24Bit:
	move	#$2700,SR
	movem.l	D0-A6,-(A7)
	move.l	$3E(A7),D0	; return PC
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.ok

	move.l	A1,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A0,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A2,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A3,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A5,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A6,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault


	move.l	A4,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	beq	.ok

.fault
	move.l	$3E(A7),D0	; incriminated PC
	nop
	nop
	jsr	$D0.W
	nop			; breakpoint here
	nop

.ok
	movem.l	(A7)+,D0-A6
	rte
	ENDC


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
