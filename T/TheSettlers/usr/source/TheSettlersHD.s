***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       THE SETTLERS WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                      (c)oded by JOTD+StingRay                           *
*                      ------------------------                           *
*                            February 2013                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 2022 (JOTD is back) - fixed intro properly
;              - fixed intro/game transition seamlessly
;
; 13-Jul-2016	- access fault fix in french version was wrong
;		  (PL_PS used instead of PL_PSS), fixed
;		- cache is now disabled during intro
;		- blitter wait added
;		- WHDLoad v17+ features used now (config)
;		- Bplcon3/4 and FMODE access disabled

; 27-Feb-2013	- keyboard support for intro added, quit key works fine
;		  now

; 26-Feb-2013	- worked out a generic approach for my fixes/crack patch
;		  so that supporting different version could be done
;		  easily
;		- support for English, French and the 2 German versions
;		  added
;		- intro part supported
;		- JOTD's access fault fix added

; 25-Feb-2013	- work started
;		- keyboard bug fixed!
;		- cracked the game in a way that any checksums will not
;		  matter anymore!
;		  checksums!
;		- completely new source as I had to change so much
;		  that adding it to the old source would have been a lot
;		  of unnecessary extra work. so I did it "My Way". :)


	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	;INCLUDE	lvo/dos.i

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

MC68020	MACRO
	ENDM

;CHIP_ONLY

;============================================================================

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0
HRTMON
	ELSE
BLACKSCREEN
	IFD	LOWMEM
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $100000*2
	ELSE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000*4
	ENDC
	ENDC
	
NUMDRIVES	= 1
WPDRIVES	= %0000


;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
CBKEYBOARD
SEGTRACKER
CACHE
; DEBUG is used locally but also makes kickemu less laxist
; on some dos stuff and can fail where it would have worked without it
;DEBUG
;DISKSONBOOT
;DOSASSIGN
FONTHEIGHT	= 8
HDINIT
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
;INIT_LOWLEVEL
;INIT_MATHFFP
IOCACHE		= 1024
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
;NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_ClearMem|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/TheSettlers/data_de",0
		ELSE
		dc.b	"data",0
		ENDIF


DECL_VERSION:MACRO
	dc.b	"1.7"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
slv_name	dc.b	"The Settlers/Die Siedler"
		IFD		CHIP_ONLY
			dc.b	" (chip/debug mode)"
		ENDC
			dc.b	0
slv_copy	dc.b	"1993 Blue Byte",0

slv_info	dc.b	"adapted by JOTD & StingRay",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to Tony Aksnes & Wepl for disk images",10,10
		dc.b	"Thanks to Olivier Schott for testing & bugreports",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_config
    dc.b    "C1:B:Skip introduction;"
		dc.b	0
	dc.b	"$VER: The Settlers "
	DECL_VERSION
	dc.b	0
		CNOP	0,4

	IFD BOOTDOS

_bootdos
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6

	move.l	_resload(pc),a2
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


	move.l	#-2,$4c0.w
	move.l	#-2,$377d0

	move.l	NOINTRO(pc),d0
	bne	.nointro
	
	lea		RunIntro(pc),a0
	tst.w	(a0)
	beq.b	.nointro
	clr.w	(a0)	; only run intro once, not after reboot
	
	; align exe memory on round value for intro
	IFD CHIP_ONLY
	movem.l a6,-(a7)
	move.l	$4.w,a6
	move.l  #$20000-$1976C,d0
	move.l  #MEMF_CHIP,d1
	jsr _LVOAllocMem(a6)
	movem.l (a7)+,a6
	ENDC
		
	lea	.intro(pc),a0
	lea	.cmdi(pc),a3		; command line
	moveq	#.cmdi_end-.cmdi,d5		; length of command line arguments
	moveq	#0,d0
	move.w	#$a2-0,d1


	bsr.b	.dopatch		; patch and run intro

.nointro


; check which game is installed (german/int.)
	lea	.game(pc),a0
	addq.w	#1,RunGame-.game(a0)
	move.l	a0,d7
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)
	move.l	d0,d1
	beq.b	.nofile
	jsr	_LVOClose(a6)
	move.l	d7,a0
	bra.b	.dogame

.nofile	lea	.gameDE(pc),a0


; load game
.dogame	move.w	#$3696,d0		; start of texts in german version
	move.w	#$38c0-$3696,d1		; end, good for CRC
	lea	.cmd(pc),a3		; command line
	moveq	#.cmdlen,d5		; length of command line

.dopatch
	lea	PT_GAME(pc),a1
.go	bsr		.LoadAndPatch
	bsr.b	.run
	move.w	RunGame(pc),d0
	bne.w	QUIT
	rts

; a3.l: command line
; d5.l: length of command line

.run	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	movem.l	d7/a6,-(a7)
	move.l	a3,a0
	move.l	d5,d0
	addq.w	#4,a1
	move.w	RunGame(pc),d1
	beq.b	.nogame
	move.l	a1,CODESTART-.cmd(a0)
.nogame	jsr	(a1)
	movem.l	(a7)+,d7/a6
	move.l	d7,d1
	jmp	_LVOUnLoadSeg(a6)

; d0.w: start offset for version check
; d1.w: length for version check
; a0.l: file name
; a1.l: patch table
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.w	d0,d3
	moveq	#0,d4
	move.w	d1,d4

	move.l	a0,d6
	move.l	a1,a5
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.error

	move.l	d7,a0
	add.l	a0,a0
	add.l	a0,a0
	lea	4(a0,d3.w),a0
	move.l	d4,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	move.w	d0,d2

; d0: checksum
	move.l	a5,a0
.find	movem.w	(a0)+,d0/d1		; checksum, offset to variables
	cmp.w	#-1,d0			; do not remove this! checksum can
	beq.b	.out			; have the sign bit set so just
	tst.w	d0			; bmi.b is not going to work!
	beq.b	.wrongver
	cmp.w	d0,d2
	beq.b	.found
	addq.w	#2,a0
	bra.b	.find

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


.found	move.w	d1,VARS-PT_GAME(a5)
	add.w	(a0),a5


	move.l	a5,a0
.patch	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
.out	rts

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.b	EXIT


.cmd	dc.b	" ",10			; -f: floppy mode, -s: single player
.cmdlen	= *-.cmd			; -m0...9: map size

.intro		dc.b	"mcp",0
.cmdi		dc.b	"SCPT",10
.cmdi_end
	dc.b	0

.game	dc.b	"TheSettlers",0
.gameDE	dc.b	"DieSiedler",0
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; format: checksum, offset to vars (a5), offset to patch list
PT_GAME	dc.w	$2205,$6eec,PLGAMEDE-PT_GAME	; german version
	dc.w	$8b87,$6ede,PLGAMEDE_2-PT_GAME	; german version #2
	dc.w	$06aa,$6eda,PLGAMEEN-PT_GAME	; english version
	dc.w	$91d1,$6ef6,PLGAMEFR-PT_GAME	; french version

; intro
	dc.w	$f284,0,PLINTRO-PT_GAME
	dc.w	0				; end of tab

PLINTRO	PL_START
	;;PL_S	$13b6,$1428-$13b6	; temp skip blitter emu
	
	PL_B	$41c,$60		; skip VBR access
	PL_B	$2f12,$60		; skip CACR access

	PL_PS	$2b80,.key

	PL_PSS	$5cc,.fixcop,6
	;PL_I	$5cc

	PL_PS	$10fc,.flush
	
	;;PL_PS	$2bec,jsr_a2
	
	;PL_I	$220
	;PL_R	$3f4


	PL_PS	$de4,.flush1
	PL_PS	$278a,.flush2
	PL_PSS	$5ec,.flush3,2

	PL_PS	$cc0,.flush4
;	PL_P	$1008,.test

	PL_PSS	$13AC,blit_1,4
	
	; reboot before intro triggers a recoverable alert which needs RMB
	; to exit from, and confuses the users into believing that the game
	; locked up
	PL_P	$05c8,reboot
	PL_END

;.test	btst	#2,$dff016
;	bne.b	.test
;	movem.l	(a7)+,d2-d7/a0-a2/a5
;	rts

; before calling each file init
.flush4
	movem.l	d0-d1/a0-a2,-(a7)

	MOVEA.L	D4,A6			;0cc0: 2c44
	ADDA.L	(A6),A6			;0cc2: ddd6
	MOVE.L	A6,D5			;0cc4: 2a0e
;	cmp.l	#$3d7cc80f,$849E-$6F50(a6)
;	bne.b	.x
	nop
;.x
	cmp.l	#$426d0088,$e210-$DC44(a6)
	bne.b	.no_part1
	move.l	_resload(pc),a2
	lea		pl_intro_2(pc),a0
	move.l	a6,a1
	jsr		resload_Patch(a2)
.no_part1
	; children running needs blitter fix
	move.l	a6,-(a7)
	lea		$c824-$6F50(a6),a6
	cmp.l	#$3d7ced94,(a6)
	bne.b	.x
	; install blit wait
	move.w	#$4EB9,(a6)+
	pea		.fix_blitwait_children(pc)
	move.l	(a7)+,(a6)
.x
	move.l	(a7)+,a6
	movem.l	(a7)+,d0-d1/a0-a2
	bsr	FlushCache
	rts
	
.fix_blitwait_children
	move.w #$ed94,(bltsize,a6)
	bra		wait_blit
	
.flush1	bsr	FlushCache
	move.l	d0,$12(a6)
	moveq	#0,d0
	rts

.flush2	bsr	FlushCache
	cmp.l	#"GA01",d0
	rts

.flush3
	bsr	FlushCache
	move.l	$18(a4),a0
	tst.w	10(a0)
	rts


.flush	move.l	a0,-(a7)
	move.l	_resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.l	(a7)+,a0
	addq.l	#7,d1
	and.b	#$f8,d1
	rts


.fixcop	btst	#2,$dff016
	bne.b	.fixcop
	move.l	$44(a5),a1
	move.l	$26(a1),$dff080
	rts

.key	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq.w	QUIT
	move.b	$bfed01,d0		; original code
	rts

reboot
	lea	.doit(pc),a5
	move.l	$4.W,a6
	jsr	_LVOSupervisor(a6)
.doit
	move.w	#$2700,SR
	bra	kick_reboot
	
blit_1:
	MOVE.W	#$0000,(bltdmod,A3)		;13ac: 377c00000066
	MOVE.W	D1,(bltsize,A3)		;13b2: 37410058
	; waiting here fixes the lockup issues with fast machines
	bra		wait_blit
	
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts

; part 1 scrolling & sky	
; 00088558 3d7c c80f 0058           move.w #$c80f,(a6,$0058) == $00dff058

pl_intro_2
	PL_START
	; fix color bit
	PL_PSS	$8e20c-$8DC44,set_copperlist,2
	; fix forgotten blitwait (trashed children & dog)
	PL_P	$8f0b0-$8DC44,wait_blit_1
	PL_END
	
wait_blit_1
	MOVEM.L	(A7)+,D5-D7/A2-A4	;8f0b0: 4cdf1ce0
	bra		wait_blit
	
	
set_copperlist
	move.l	d0,a0
	move.w	#$200,(2,a0)	; set color bit
	MOVE.L	D0,cop1lc(A5)		;8e20c: 2b400080
	CLR.W	copjmp1(A5)			;8e210: 426d0088
	rts
	
FlushCache
	move.l	a0,-(a7)
	move.l	_resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.l	(a7)+,a0
	rts


; German version (SPS 0401)
PLGAMEDE
	PL_START
	PL_W	$6a5a,$7a00		; moveq #0,d5 -> disable prot. check
	PL_PS	$3940,.fix		; restore protection opcode

	PL_ORW	$24b24+2,1<<3		; enable level 2 interrupt (save games)

	; access fault when soldiers enter the castle
	PL_PSS	$ECCE-$20,FixAccessFault,2


	PL_PSS	$8b72,WaitBlit1,2

	PL_NEXT	PLCOMMON
	PL_END

.fix	move.l	#$2691c,d0		; routine offset
	move.l	#$6a5a,d1		; offset to opcode
	bra.w	CrackMagic

WaitBlit1
	tst.b	$02(a6)
.wblit	btst	#6,$02(a6)
	bne.b	.wblit
	move.l	#$ffffffff,$44(a6)
	rts


; German version #2
PLGAMEDE_2
	PL_START
	PL_W	$6a4c,$7a00		; moveq #0,d5 -> disable prot. check
	PL_PS	$3932,.fix		; restore protection opcode

	PL_ORW	$24ab4+2,1<<3		; enable level 2 interrupt (save games)

	; access fault when soldiers enter the castle
	PL_PSS	$EC66-$20,FixAccessFault,2


	PL_PSS	$8b60,WaitBlit1,2

	PL_NEXT	PLCOMMON
	PL_END


.fix	move.l	#$2688c,d0		; routine offset
	move.l	#$6a4c,d1		; offset to opcode
	bra.w	CrackMagic


; English version (SPS 0143)
PLGAMEEN
	PL_START
	PL_W	$6a48,$7a00		; moveq #0,d5 -> disable prot. check
	PL_PS	$392e,.fix		; restore protection opcode

	PL_ORW	$24a2e+2,1<<3		; enable level 2 interrupt (save games)

	; access fault when soldiers enter the castle
	PL_PSS	$ECBC-$20,FixAccessFault,2

	PL_PSS	$8b60,WaitBlit1,2

	PL_NOP	$00586,6		; disable long wait at start
	PL_NEXT	PLCOMMON
	PL_END


.fix	move.l	#$26826,d0		; routine offset
	move.l	#$6a48,d1		; offset to opcode
	bra.b	CrackMagic


; French version (SPS 2378)
PLGAMEFR
	PL_START
	PL_W	$6a64,$7a00		; moveq #0,d5 -> disable prot. check
	PL_PS	$3938,.fix		; restore protection opcode

	PL_ORW	$24a76+2,1<<3		; enable level 2 interrupt (save games)

	; access fault when soldiers enter the castle
	PL_PSS	$ECD8-$20,FixAccessFault,2

	PL_PSS	$8b7c,WaitBlit1,2

	PL_NEXT	PLCOMMON
	PL_END


.fix	move.l	#$2686e,d0		; routine offset
	move.l	#$6a64,d1		; offset to opcode
	bra.b	CrackMagic




; common patches for all versions of the game
PLCOMMON
	PL_START
	PL_B	$104,$60		; skip VBR access
	PL_ORW	$1cb6+2,1<<3		; enable level 2 interrupt (passwords)

	PL_SA	$f20,$f32		; skip Bplcon3,4 and FMode access
	PL_END




; this routine performs the "checksum checks do not matter" magic. :)

; d0.l: offset to routine to call
; d1.l: offset to opcode to restore
CrackMagic
	moveq	#0,d2
	move.w	VARS(pc),d2
	sub.l	d2,d1
	move.w	#$ba40,(a5,d1.l)	; cmp.w d0,d5
	sub.l	d2,d0
	jmp	(a5,d0.l)		; call original routine


_cb_keyboard
	move.w	RunGame(pc),d1		; do not store any key
	beq.b	.no			; while the intro is running!
	move.l	CODESTART(pc),a5
	add.w	VARS(pc),a5
	rol.b	d0
	not.b	d0
	btst	#0,d0
	beq.b	.no
	move.b	d0,$1f5(a5)
.no	rts


; JOTD's fix for the access fault
FixAccessFault
	move.l	$34(a0),a0
	move.l	d0,-(a7)
	move.l	a0,d0
	rol.l	#8,d0
	tst.b	d0
	beq.b	.ok
	cmp.b	_expmem(pc),d0
	bne.b	.skip
.ok
	; commit sub only if MSB is 0 or matches expansion mem
	; (not 100% satisfactory but seems to work)

	subq.b	#1,8(a0)

.skip	move.l	(a7)+,d0
	rts

CODESTART	dc.l	0		; start of program code
VARS		dc.w	0		; offset to variables (a5)
RunGame		dc.w	0
RunIntro	dc.w	1

TAGLIST	dc.l	WHDLTAG_CUSTOM1_GET
NOINTRO	dc.l	0		; skip intro
	dc.l	TAG_END


	ENDC

