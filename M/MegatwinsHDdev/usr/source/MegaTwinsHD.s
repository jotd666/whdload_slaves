CHIPMEMSIZE=$80000
FASTMEMSIZE=$0
FAKEFMEMSIZE=$0
MAJOR_VERSION = 1
MINOR_VERSION = 2
	IFD	BARFLY
WHDLOADSLAVE = 1
	OUTPUT	Megatwins.slave
	ENDC
	incdir	include:
	include	"jst.i"

	HD_PARAMS	"disk.",808960,2,<Megatwins>,<1990 US Gold>,<Installed by Keith/JOTD>

; *** Mega Twins HD Loader v1.1
; *** Written by Keith Krellwitz (kkrellwi@nmu.edu)

_loader:
	RELOC_MOVEL	D0,trainer

	Mac_printf	"Megatwins HD Loader v1.2"
	Mac_printf	"Coded by Keith Krellwitz (Abaddon) ©1997/98"
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
	SAVE_OSDATA	$80000

	JSRGEN	FreezeAll

;	LEA		$0007F000,A7
;	MOVE	#$2700,SR
;	MOVE.W	#$7FFF,$00DFF09A
;	MOVE.W	#$7FFF,$00DFF09C
;	MOVE.W	#$7FFF,$00DFF096
;	BSET	#$01,$00BFE001

	lea		$100,a1
	lea		$7fffc,a2
clear:
	move.l	$0,(a1)+
	cmpa.l	a1,a2
	bne 	clear


;check which version

	lea		$8054,a0
	move.l	#$45,d0
	move.l	#$1,d1
	bsr		loader1
	cmpi.l	#$00023b7c,$8054
	bne		version2
version1:
	lea		boot(pc),a0
	lea		$8054,a1
	JSRGEN	RNCDecrunch
	PATCHUSRJMP $82b0,loader1
	PATCHUSRJMP $80a2,jumper1
	move.l	#$4e714e71,$8060
	move.l	#$4e714e71,$807a
	JSRGEN	FlushCachesHard
	jmp	$8054

version2:
	lea		boot2(pc),a0
	lea		$8054,a1
	JSRGEN	RNCDecrunch
	PATCHUSRJMP $82d6,loader1
	PATCHUSRJMP $80aa,escape
	move.l	#$4e714e71,$8062
	move.l	#$4e714e71,$807c
	JSRGEN	FlushCachesHard
	jmp	$8054

loader1:
	STORE_REGS
	move.l	#$0,d2
	cmpi.l	#$3c,d0
	bne	side0
	move.l	#$1,d2
side0:
	bsr	loadtracks1
	JSRGEN	FlushCachesHard
	RESTORE_REGS
	rts	

loadtracks1:
	STORE_REGS
	move.l	d1,d3
	move.l	d0,d1
	move.l	d2,d0
	move.l	d3,d2
	clr.l	d3
	subi.l	#$1,d1
	cmpi.l	#$1,d0
	bne	loadit
	addi.l	#$4f,d1
loadit:
	mulu	#$a,d1
	mulu	#$a,d2
	move.l	disknum(pc),d0
	JSRGEN	ReadRobSectors
	RESTORE_REGS
	rts

jumper1:
	jsr		$80fa
escape:
	PATCHUSRJSR $128ce,loadtracks1
	PATCHUSRJMP $128d8,jumper2
	move.l	trainer(pc),d0
	tst.l	d0
	beq	.nope
	move.w	#$1,$1a0
.nope:
	JSRGEN	FlushCachesHard
	jmp	$10000

jumper2:							;levels 1-3 main
	PATCHUSRJMP $6225c,loadtracks1
	move.w	#$1,$190
	PATCHUSRJMP $5016c,jumper3
	PATCHUSRJMP $5018a,jumper3
	PATCHUSRJMP $501a8,jumper3
	PATCHUSRJMP $61bd2,jumper5
	PATCHUSRJSR $50102,disk1
	move.w	#$6032,$50108
	PATCHUSRJSR $61b82,disk2
	move.w	#$6032,$61b88
	move.l	#$20202020,$61f4d
	move.l	#$20204142,$61f4d+$4
	move.l	#$4144444f,$61f4d+$8
	move.l	#$4e202620,$61f4d+$c
	move.l	#$46414252,$61f5d
	move.l	#$45203937,$61f5d+$4
	move.l	#$20202020,$61f5d+$8
	JSRGEN	FlushCachesHard
	jmp	$50000

jumper3:
	PATCHUSRJSR $bb0c,KbInt
	PATCHUSRJMP $dd8a,jumper4
	PATCHUSRJMP $14f98,jumper2
	PATCHUSRJMP $15050,jumper5
	PATCHUSRJMP $d970,loadtracks1
	move.w	#$6070,$dc8a
	PATCHUSRJSR $dd04,disk1
	move.w	#$6036,$dd0a
	PATCHUSRJSR $14f3c,disk1
	move.w	#$6038,$14f42
	PATCHUSRJSR $14ff4,disk2
	move.w	#$6038,$14ffa
	bsr 	patchblitter
	JSRGEN	FlushCachesHard
	jmp	$b450

jumper4:	;press escape during play load the intro again
	jsr	$deac	;and redo the patching
	bra	escape

jumper5:
	PATCHUSRJSR $4408e,disk2
	move.w	#$6032,$44094
	PATCHUSRJMP $4718e,loadtracks1
	PATCHUSRJMP $44278,jumper6
	JSRGEN	FlushCachesHard
	jmp	$44000 

jumper6:
	PATCHUSRJMP $be1c,loadtracks1
	PATCHUSRJSR $b91c,disk1
	move.w	#$603a,$b922
	PATCHUSRJMP $b9aa,escape
	JSRGEN	FlushCachesHard
	jmp	$b450

disk1:
	lea	disknum(pc),a0
	move.l	#$0,(a0)
	JSRGEN	FlushCachesHard
	rts
disk2:
	lea	disknum(pc),a0
	move.l	#$1,(a0)
	JSRGEN	FlushCachesHard
	rts

patchblitter:
	PATCHUSRJMP	$c6,blitshit1
	STORE_REGS
	lea		$1e800,a0
	lea		$1ec00,a1
patch:
	cmpi.l	#$3d470058,(a0)
	bne		nopatch
	move.l	#$4eb800c6,(a0)
nopatch:
	adda.l	#$1,a0
	cmpa.l	a0,a1
	bne		patch
	RESTORE_REGS
	rts

blitshit1:
	move.w	d7,$58(a6)
	JSRGEN	WaitBlit
	rts


KbInt:
	move.b	d0,$10610
	IFND	WHDLOADSLAVE
	cmp.b	#$59,D0
	ELSE
	cmp.b	_whdinit_base+ws_keyexit(pc),D0
	ENDC
	bne	.noquit
	JSRGEN 	InGameExit
.noquit:
	movem.l d0,-(a7)
	move.l	#$1800,d0
taco:
	subi.l	#$1,d0
	bne	taco
	movem.l (a7)+,d0
	rts
boot:
	incbin "mt0.RNC"
	even
boot2:
	incbin "mt1.RNC"
	even
trainer:
	dc.l	0
disknum
	dc.l	0
