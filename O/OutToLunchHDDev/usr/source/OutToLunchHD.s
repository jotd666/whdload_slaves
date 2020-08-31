CHIPMEMSIZE=$200000
FASTMEMSIZE=$0
FAKEFMEMSIZE=$0
	IFD	BARFLY
	incdir	include:
	include	whdload.i
WHDLOADSLAVE = 1
	OUTPUT	OutToLunch.slave
	ENDC

	include	"jst.i"

_base
_whdinit_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_ReqAGA	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM


; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

_name		dc.b	"Pierre le Chef is ... Out To Lunch",0
_copy		dc.b	"1994 Mindscape",0
_info		dc.b	"adapted & fixed by Abaddon/JOTD",10,10

;;		dc.b	"CUSTOM1=1 disables joypad patch",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

;;	HD_PARAMS	"disk.",829440,2,<Out To Lunch>,<1994 Mindscape>,<Install & fix by Abaddon/JOTD>
HDP_FnameStart
	dc.b	"disk."
HDP_FnameDiskNo
	dc.b	0,0

		even


start
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	JSRABS	LoadDisks

	move.l	#CACRF_CopyBack,D1
	moveq.l	#0,D0
	JSRABS	Degrade

	GO_SUPERVISOR
;;	SAVE_OSDATA	CHIPMEMSIZE

	MOVE	#$2700,SR
	JSRGEN	FreezeAll

	lea	$1000.W,a0
	moveq	#$0,d0
	moveq	#$1,d1
	move.l	#$24d,d2
	bsr	ReadRobSectors
	lea	$400.W,a1
	lea	$1000.W,a0
	bsr	RNCDecrunch
	PATCHUSRJMP	$ce7a,loadtracks
	move.l	#$600008ae,$54e
	move.l	#$9ff5d958,$1502
	move.w	#$600E,$406
	PATCHUSRJMP	$cc70,swap
	PATCHUSRJSR	$17c0,KbInt
	PATCHUSRJSR	$151C,fix_2nd_button
	PATCH_NOP	$151C+6
;;;;;	PATCHUSRJSR	$4c1c,fix
;;;;;	PATCHUSRJSR	$2D32,avoid_wild_copy

	PATCHUSRJMP	$6622.W,clrchip

	; copy RNC decrunch routine (modified, WHDLoad one does not work)

	lea	$6644.W,A0
	lea	$6852.W,A1
	lea	_decrunch(pc),a2
.copy
	move.w	(A0)+,(A2)+
	cmp.l	A0,A1
	bne.b	.copy

	PATCHUSRJMP	$6644,_decrunch

	JSRGEN	FlushCachesHard

	lea	$19CA8,A7
	jmp		$416.w

fix_2nd_button
	btst	#6,$dff016
	bne.b	.out
	move.w	#$CC01,$dff034
	cmp.b	d0,d0	; sets Z flag
.out
	rts
clrchip:
	cmp.l	#CHIPMEMSIZE,a0
	beq.b	.out
	move.b	d1,(a0)+
	subq.l	#1,d0
	bne.b	clrchip
.out
	rts
fix:
	cmpa.l	#CHIPMEMSIZE,a6
	blt		.fixed
	lea		$4c66.w,a6
.fixed
	add.w	$6(a6),d0
	addq.w	#$5,d0
	rts

avoid_wild_copy:
	tst.l	D1
	bmi.b	.out
.loop
	move.b	(a1)+,(a0)+
	subq.l	#1,d1
	bne.b	.loop
.out
	rts
RNCDecrunch
	JSRGEN	RNCDecrunch
	rts

loadtracks:
	moveq	#0,D0
	move.w	disknum(pc),d0
	movem.l	d1,-(a7)
	sub.l	#$18,d1
	bsr	ReadRobSectors
	movem.l	(a7)+,d1
	tst.l	D0
	rts

swap:
	movem.l	d0/a0,-(a7)
	lea		disknum(pc),a0
	move.w	(a0),d0
	eor.w	#$1,d0
	move.w	d0,(a0)
	movem.l	(a7)+,d0/a0
	JSRGEN	FlushCachesHard
	jmp		$cbee

ReadRobSectors:
	JSRGEN	ReadRobSectors
	rts

KbInt:
	not.b	d0
	ror.b	#$1,d0
	move.b	d0,d1
	IFND	WHDLOADSLAVE
	cmp.b	#$59,D0
	ELSE
	cmp.b	_whdinit_base+ws_keyexit(pc),D0
	ENDC
	bne	.noquit		; F10: exit
	JSRGEN	InGameExit
.noquit
	move.l	#$8,$dff09c
	rts

;boot:
;	incbin "boot",$f9e
;	even

disknum:
	dc.w	0
_decrunch:
	blk.b	$210,0
	illegal
_resload
	dc.l	0
