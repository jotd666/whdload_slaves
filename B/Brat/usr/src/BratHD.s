CHIPMEMSIZE=$80000
FASTMEMSIZE=$0
FAKEFMEMSIZE=$0
MAJOR_VERSION = 2
MINOR_VERSION = 0
	IFD	BARFLY
WHDLOADSLAVEFLAGS = 2 ; no error
WHDLOADSLAVE = 1
	OUTPUT	Brat.slave
	ENDC
	incdir	include:
	include	"jst.i"
	IFND	WHDLOADSLAVE
	HD_PARAMS	"brat.d",STD_DISK_SIZE,2
	ELSE
	HD_PARAMS	"brat.d",STD_DISK_SIZE,2,<Brat>,<1991 ImageWorks>,<Install & fix by Abaddon/Jeff>
	ENDC



_loader:
	Mac_printf	"Brat HD Loader & fix v2.0"
	Mac_printf	"Coded by Abaddon & Jeff ©1998/2001"

	JSRABS	LoadDisks

	move.l	#CACRF_CopyBack,D1
	moveq.l	#0,D0
	JSRABS	Degrade

	GO_SUPERVISOR
	SAVE_OSDATA	$80000

	; WHDLoad slave needs this
	move.l	#$FFFFFFFE,$4.W
	move.l	#$4,$DFF080
	move.w	#$A3D0,$DFF096



	move.l	#$7ff00,a7
	move.l	#$0,d0
	lea		$78000,a0
	move.l	#$16,d1
	move.l	#$27,d2
	moveq	#0,D3
	JSRGEN  ReadRobSectors
	move.b	#$6e,$7c16b
	PATCHUSRJMP	$78514,ReadRobSectors
	PATCHUSRJMP	$7c1c0,jumper

;;;	move.l	#$BFD000,$78060	; fix access fault

	JSRGEN	FlushCachesHard
	jmp		$7c166

jumper:
	STORE_REGS
	PATCHUSRJSR	$FD0.W,KbDelay
	PATCH_NOP	$FD6.W

	PATCHUSRJMP	$13be.w,loader
	PATCHUSRJSR	$f84.w,KbInt
	PATCHUSRJMP	$ce2e,prot2
	PATCHUSRJMP	$4946,prot
	move.w	#$4e71,$4834
	PATCHUSRJMP	$49b0.W,InGameExit
	PATCHUSRJSR	$6b86,blit1
	PATCHUSRJMP	$b0,blit2
	PATCHUSRJMP	$b6,blit3
	move.l	#$4eb800b0,$1926
	move.l	#$4eb800b0,$1902
	move.l	#$4eb800b0,$18d4
	move.l	#$4eb800b0,$18ba
	move.l	#$4eb800b6,$188a
	PATCHUSRJSR	$4926,moreblit
	move.l	#$bfd000,$f9a.W
	PATCHUSRJSR	$876A,StoreCop

	PATCH_NOP	$8770

	; JOTD: relocate decrunch in fastmem

	lea	$430C.W,A0
	lea	Decrunch(pc),A1
	move.l	#$B4-$0C,D0
	JSRGEN	CopyMem

	PATCHUSRJMP	$430C.W,Decrunch

	; JOTD: fix dbf loop for music

	move.l	#$4EB80100,$9066
	move.l	#$4EB80100,$907C
	PATCHUSRJMP	$100.W,EmulateDbf

	RESTORE_REGS

	JSRGEN	FlushCachesHard
	jmp		$200.w


EmulateDbf:
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	JSRGEN	BeamDelay
	rts


prot:
	jmp		$5214.W
prot2:
	addi.l	#$a0ce4420,(a4)
	rts
 
KbDelay:
	BEAM_DELAY	#2
	andi.b	#$BF,$BFEE01
	rts

blit1:
	move.w	#$410,$58(a6)
	bra		wt
blit2:
	move.w	d1,$58(a2)
	bra		wt
blit3:
	move.w	d0,$58(a2)
	bra		wt
blit4:
	move.w	d7,$58(a6)
	bra		wt
blit5:
	move.w	#$802,$58(a6)
	bra		wt
blit6:
	move.w	#$3204,$58(a6)
	bra		wt
blit7:
	move.w	d5,(a6)
	lea		$1f40(a0),a0
	bra		wt
blit8:
	move.l	a1,(a3)+
	move.l	a5,(a3)
	move.w	d5,(a6)
	bra		wt
blit9:
	move.w	#$1009,$58(a6)
	bra		wt
blita:
	move.w	#$17c9,$58(a6)
	bra		wt
wt:
	btst	#$6,$dff002
wt1:
	btst	#$6,$dff002
	bne		wt1
	rts

blitshit:
	move.l	a3,$54(a0)
	JSRGEN	WaitBlit
	move.w	d0,$58(a0)
	rts
loader:
	jsr		$1bcc.w
ReadRobSectors:
	moveq.l	#0,D0
	cmp.w	#1,$3AC2
	bne.b	.disk1
	moveq	#1,D0
.disk1
	STORE_REGS	D3
	moveq.l	#0,D3
	JSRGEN	ReadRobSectors
	RESTORE_REGS	D3
	rts

StoreCop:
	STORE_REGS
	move.l	#$9F8,D0
	JSRGEN	StoreCopperPointer
	move.l	D0,($80,A6)	
	RESTORE_REGS
	RTS

InGameExit:
	JSRGEN	InGameExit
	rts

moreblit:
	move.l	#$4eb800bc,$1e6d0
	PATCHUSRJMP	$bc,blit4
	PATCHUSRJSR	$15f8e,blit5
	PATCHUSRJSR	$15efa,blit6
	PATCHUSRJSR	$15eae,blit7
	PATCHUSRJSR	$15ea0,blit7
	PATCHUSRJSR	$15e92,blit7
	PATCHUSRJSR	$15e84,blit7
	PATCHUSRJMP	$15a2a,blit8

	PATCHUSRJSR	$15a02,blit8
	PATCHUSRJSR	$15a16,blit8
	PATCHUSRJSR	$159ee,blit8
	PATCHUSRJSR	$156d4,blit9
	PATCHUSRJSR	$1565c,blita
	clr.w	$5832
	rts

KbInt:
	move.b	$bfec01,d0
	movem.l	d0,-(a7)
	ror.b	#$1,d0
	not.b	d0
	IFND	WHDLOADSLAVE
	cmp.b	#$59,D0
	ELSE
	cmp.b	_whdinit_base+ws_keyexit(pc),D0
	ENDC
	bne		.noquit
	JSRGEN	InGameExit
.noquit:
	cmp.b	#$42,D0
	bne.b	.noicon
	JSRGEN	InGameIconify
.noicon
	move.l	(a7)+,d0
	rts
disknum:
	dc.l	0

Decrunch:
	ds.b	$B0

