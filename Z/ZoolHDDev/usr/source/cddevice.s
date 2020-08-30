; cd.device "emulation"
; (rather, a kind of stub to avoid crashes, and to reply properly whenever possible)
;
; Written by JOTD
;

	include	devices/cd.i

CD_NULL_ACTION:MACRO
	cmp.w	#CD_\1,d0
	beq	.out
	ENDM

cddevice_DoIO:
cddevice_SendIO:
	move.w	IO_COMMAND(a1),d0
	cmp.w	#CD_MOTOR,d0
	beq	.motor

	cmp.w	#CD_CONFIG,d0
	beq	.config

	cmp.w	#CD_INFO,d0
	beq	.info

	cmp.w	#CD_PLAYTRACK,d0
	beq	.playtrack

	cmp.w	#CD_READXL,d0
	beq	.readxl

	cmp.w	#CD_STOP,d0
	beq	.stop

	CD_NULL_ACTION	ADDCHANGEINT
	CD_NULL_ACTION	REMCHANGEINT

.out
	moveq.l	#0,D0
	rts

.readxl
	move.b	#1,IO_ERROR(a1)
	moveq	#-1,d0
	rts

.motor
	lea	.status(pc),a0
	or.w	#CDSTSF_SPIN,(a0)
	bra.b	.out

.stop
	lea	.status(pc),a0
	move.w	#CDSTSF_CLOSED|CDSTSF_DISK,(a0)
	bra.b	.out

.playtrack
	lea	.status(pc),a0
	or.w	#CDSTSF_PLAYING,(a0)
	bra.b	.out

.info
	move.l	40(a1),a0	; info structure
	move.w	.playspeed+2(pc),CDINFO_PlaySpeed(a0)
	move.w	.readspeed+2(pc),CDINFO_ReadSpeed(a0)
	move.w	.readxlspeed+2(pc),CDINFO_ReadXLSpeed(a0)
	move.w	#2048,CDINFO_SectorSize(a0)
	move.w	.xlecc+2(pc),CDINFO_XLECC(a0)
	move.w	#0,CDINFO_EjectReset(a0)
	move.w	#150,CDINFO_MaxSpeed(a0)
	move.w	#0,CDINFO_AudioPrecision(a0)
	move.w	.status(pc),CDINFO_Status(a0)
	bra.b	.out

.config
	move.l	40(a1),a0	; taglist
.config_loop
	move.l	(a0)+,d0
	beq.b	.out
	cmp.l	#TAGCD_READSPEED,d0
	bne.b	.noreadspeed
	lea	.readspeed(pc),a1
	move.l	(a0)+,(a1)
	bra.b	.config_loop
.noreadspeed
	cmp.l	#TAGCD_READXLSPEED,d0
	bne.b	.noreadxlspeed
	lea	.readxlspeed(pc),a1
	move.l	(a0)+,(a1)
	bra.b	.config_loop
.noreadxlspeed
	cmp.l	#TAGCD_XLECC,d0
	bne.b	.noxlecc
	lea	.xlecc(pc),a1
	move.l	(a0)+,(a1)
	bra.b	.config_loop
.noxlecc
	cmp.l	#TAGCD_PLAYSPEED,d0
	bne.b	.noplayspeed
	lea	.playspeed(pc),a1
	move.l	(a0)+,(a1)
	bra.b	.config_loop
.noplayspeed
	cmp.l	#TAGCD_EJECTRESET,d0
	bne.b	.noejectreset
	lea	.ejectreset(pc),a1
	move.l	(a0)+,(a1)
	bra.b	.config_loop
.noejectreset
	ILLEGAL

.playspeed
	dc.l	$4B
.readspeed
	dc.l	$4B	; default is 1x
.readxlspeed
	dc.l	$4B
.ejectreset
	dc.l	1
.xlecc
	dc.l	0
.status
cddevice_status
	dc.w	CDSTSF_CLOSED|CDSTSF_DISK

cddevice_AbortIO:
	lea	cddevice_status(pc),a0
	move.w	#CDSTSF_CLOSED|CDSTSF_DISK,(a0)
cddevice_WaitIO:	
cddevice_CheckIO:
	; ignore (cd.device)
	
	moveq.l	#0,D0
	rts
