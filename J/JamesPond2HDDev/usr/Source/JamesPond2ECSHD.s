***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      JAMES POND 2 WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2015                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 13-May-2015	- PowerPacker decruncher code optimised a bit and code
; (Friday)	  cleaned up
;		- fixed the annoying problem with Escape (game restarted
;		  over and over again), caused by simply restarting
;		  the game without properling handling the keyboard
;		  interrupt
;		- one wrong blitter wait patch corrected
;		  (move.l a3,$dff050 -> move.l a3,$dff054)
;		- In-Game keys removed and option to enable built-in
;		  cheat added
;		- support for Kixx budget version (which is actually
;		  just a stolen Skid Row crack...) added

; 11-Mar-2015	- blitter waits added, trainers added

; 10-Mar-2015	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	524288		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Credits:2;"
	dc.b	"C1:X:Enable Built-In Cheat:3;"
	dc.b	"C2:B:Force Blitter Waits on 68000"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/JamesPond2/"
	ENDC
	dc.b	"data",0
.name	dc.b	"James Pond 2 - Codename RoboCod",0
.copy	dc.b	"1991 Millennium",0
.info	dc.b	"Installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2 (13.03.2015)",0

Name	dc.b	"JP2_000",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET

; bit 0: unlimited lives on/off
; bit 1: unlimited energy on/off
; bit 2: unlimited credits on/off
; bit 3: built-in cheat on/off
TRAINEROPTIONS	dc.l	0

		dc.l	WHDLTAG_CUSTOM2_GET
FORCEBLITWAITS	dc.l	0

		dc.l	TAG_END
resload	dc.l	0


Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; load crunched game binary
	lea	Name(pc),a0
	lea	$300.w,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)
	
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$6e83,d0			; SPS 1352, retail version
	beq.b	.ok
	cmp.w	#$7cb5,d0			; SPS 1353, Kixx budget version
	beq.b	.kixx

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

; Kixx budget version or stolen Skid Row version rather...
.kixx	lea	$f4(a5),a2
	move.l	#$24a5c,(a2)		; store decrunched size
	lea	$500.w,a1
	bsr	PP_DECRUNCH

	lea	$500.w,a0
	lea	-$206(a0),a1
	move.l	#353892/2,d7
.copy	move.w	(a0)+,(a1)+
	subq.l	#1,d7
	bne.b	.copy	
	bra.b	.go

.ok
; decrunch
	lea	$180(a5),a2
	lea	$500.w,a1
.decrunch
	bsr	PP_DECRUNCH		


; install trainers
.go	move.l	TRAINEROPTIONS(pc),d0
	moveq	#$19,d1				; subq <-> tst
	lea	$500.w,a0

; unlimited lives
	lsr.l	#1,d0
	bcc.b	.nolivestrainer
	eor.b	d1,$500+$fb6c
.nolivestrainer

; unlimited energy
	lsr.l	#1,d0
	bcc.b	.noenergytrainer
	eor.b	d1,$500+$fa3a
	eor.b	d1,$500+$fab2
.noenergytrainer

; unlimited credits
	lsr.l	#1,d0
	bcc.b	.nocreditstrainer
	eor.b	d1,$500+$153b4
.nocreditstrainer


; enable built-in cheat
	lsr.l	#1,d0
	bcc.b	.nocheat
	st	$2552.w
.nocheat

; patch
	lea	PLGAME(pc),a0
	bsr.b	.patch

	move.l	FORCEBLITWAITS(pc),d0
	bne.b	.doblit
	move.l	CPUFLAGS(pc),d0			; 68000?
	lsr.l	#1,d0
	bcc.b	.noblit				; -> skip blitter wait patches
	
.doblit	lea	PLGAME_BLIT(pc),a0
	bsr.b	.patch
.noblit


; create fake memlist
	lea	$200.w,a0
	clr.l	(a0)+				; start of chip
	move.l	#$80000,(a0)+			; size of chip
	move.l	HEADER+ws_ExpMem(pc),(a0)+	; start of ext. mem
	move.l	#$80000,(a0)			; size of ext. mem

; and start game
	jmp	$500.w


.patch	lea	$500.w,a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

KillSys	move.w	#$7fff,$dff09a		; disable all interrupts
	bsr	WaitRaster
	move.w	#$7ff,$dff096		; disable all DMA
	move.w	#$7fff,$dff09c		; disable all interrupt requests
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	rts


PLGAME_BLIT
	PL_START
	PL_PS	$93c2,.wblit
	PL_PSS	$938c,.wblit2,4
	PL_PSS	$a6aa,.wblit2,2
	PL_PS	$e084,.wblit3
	PL_P	$8934,.wblit4
	PL_PSS	$d6f2,.wblit2,4
	PL_PS	$9618,.wblit5
	PL_PSS	$93e4,.wblit2,4
	PL_PSS	$a75a,.wblit6,2
	PL_END



.wblit	bsr.b	WaitBlit
	move.l	a2,$dff050
	rts

.wblit2	bsr.b	WaitBlit
	move.l	#-1,$dff044
	rts

.wblit3	bsr.b	WaitBlit
	move.l	a3,$dff054
	rts

.wblit4	bsr.b	WaitBlit
	move.w	#0,$dff044
	rts

.wblit5	lea	$dff000,a4
	bra.b	WaitBlit


.wblit6	bsr.b	WaitBlit
	move.l	a2,$50(a5)
	move.l	a1,$54(a5)
	rts

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


PLGAME	PL_START
	PL_SA	$abbc,$abcc		; don't kill exception vectors
	PL_PS	$acb2,.ackLev1
	PL_PS	$abd6,.setkbd		; don't install new level 2 interrupt
	PL_R	$ace6			; so we can call level 2 interrupt code
	PL_SA	$abdc,$abf0		; skip CIA stuff
	PL_R	$ac38
	PL_PS	$ad48,.ackVBI
	PL_PS	$ad72,.ackLev4
	PL_R	$16ac0			; diable loader init
	PL_P	$187dc,.crack		; disable protection check
	PL_P	$b9c6,.crack2		; disable 2nd protection check
	PL_P	$168ac,.loadfile
	PL_P	$1687c,.loadfile_decrunch
	PL_PSS	$aff0,.fixcop,2		; fix wrong copperlist init
	PL_ORW	$5e14+2,1<<9		; set Bplcon0 color bit
	PL_W	$abf0+2,$7fff
	PL_W	$abf8+2,$7fff
	PL_P	$ae54,.esc		; end keyboard interrupt if Esc pressed
	PL_END


.esc	tst.w	$2550.w
	beq.b	.restart
	jmp	$500+$ae5e

.restart

; emd keyboard interrupt
	lea	$dff000,a0
	lea	$bfe001,a1
	or.b	#1<<6,$e00(a1)		; set output mode

	moveq	#3-1,d1
.dloop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.dloop

	and.b	#~(1<<6),$e00(a1)	; set input mode

	jmp	$544.w




.fixcop	lea	$7978.w,a1		; move.l -> lea!
	tst.l	$5a6.w			; original code
	rts

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	addq.w	#4,a1
	rts

.kbdcust
	lea	RawKey(pc),a0
	move.b	(a0),d0
	clr.b	(a0)

.nokeys	jmp	$500+$acda		; call original level 2 interrupt code



.ackLev4
.ackVBI
.ackLev1
	move.w	d0,$dff09c
	move.w	d0,$dff09c
	rts

.crack	move.w	#$ee,$2522.w
	rts

.crack2	move.w	#$ee,$500+$fc0a
	rts


; d0.w: file number
.loadfile_decrunch
	bsr.b	.convName		; build file name
	lea	Name(pc),a0
	move.l	$500+$17092,a1
	move.l	a1,a5
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	move.l	d0,-(a7)		; save file length

	move.l	a5,a2
	move.l	$500+$17092,a1
	bsr	PP_DECRUNCH

	move.l	(a7)+,d1
	rts


; d0.w: file number
; a0.l: destination
; -----
; d1.l: file length

.loadfile
	bsr.b	.convName		; build file name
	move.l	a0,a1
	lea	Name(pc),a0
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	move.l	d0,d1
	rts

.convName
	movem.l	d0/d1/a0,-(a7)
	lea	Name+4(pc),a0
	moveq	#3-1,d3			; convert 3 digits
	lea	.TAB(pc),a1
.loop	moveq	#-"0",d1
.loop2	sub.w	(a1),d0
	dbcs	d1,.loop2
	neg.b	d1
	move.b	d1,(a0)+
.nope	add.w	(a1)+,d0
	dbf	d3,.loop
	movem.l	(a7)+,d0/d1/a0
	rts

.TAB	dc.w	100
	dc.w	10
	dc.w	1

	




WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
	rts

***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1

	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end


	moveq	#0,d0
	move.b	$c00(a1),d0
	lea	Key(pc),a2
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

	move.l	KbdCust(pc),d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom	
	


	or.b	#1<<6,$e00(a1)			; set output mode



	cmp.b	HEADER+ws_keydebug(pc),d0	
	bne.b	.nodebug
	movem.l	(a7)+,d0-d1/a0-a2
	move.w	(a7),6(a7)			; sr
	move.l	2(a7),(a7)			; pc
	clr.w	4(a7)				; ext.l sr
	bra.b	.debug


.nodebug
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

.debug	pea	(TDREASON_DEBUG).w
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit	pea	(TDREASON_OK).w
	bra.b	.quit

Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine


; PowerPacker decruncher
; disassembled and optimised by stingray

; a2: source
; a1: destination
PP_DECRUNCH
	move.l	a2,a0
	add.l	(a2)+,a0		; a0: end of crunched data
	moveq	#1,d5
	move.l	a1,a4
	move.l	-(a0),d1
	tst.b	d1
	beq.b	.skip
	bsr.b	.nextbit
	subq.b	#1,d1
	lsr.l	d1,d5
.skip	lsr.l	#8,d1
	add.l	d1,a1

.loop	bsr.b	.nextbit
	bcs.b	.packed

; data is unpacked
; get length of unpacked data to copy
	moveq	#0,d2
.getlen	moveq	#1,d0
	bsr.b	.getbits_d0
	add.w	d1,d2
	subq.w	#3,d1
	beq.b	.getlen

.store_byte
	moveq	#8-1,d0			; get the byte
	bsr.b	.getbits_d0
	move.b	d1,-(a1)		; and store
	dbf	d2,.store_byte

	cmp.l	a1,a4
	bcs.b	.packed
	bra.b	.exit

.nextbit
	lsr.l	#1,d5
	beq.b	.nextlong
	rts

.nextlong
	move.l	-(a0),d5
	roxr.l	#1,d5
	rts



.getbits
	subq.w	#1,d0
.getbits_d0
	moveq	#0,d1
.getbits_loop
	lsr.l	#1,d5
	beq.b	.getnextlong
.getmore
	addx.l	d1,d1
	dbf	d0,.getbits_loop
	rts

.getnextlong
	move.l	-(a0),d5
	roxr.l	#1,d5
	bra.b	.getmore


.packed	moveq	#1,d0
	bsr.b	.getbits_d0
	moveq	#0,d0
	move.b	(a2,d1.w),d0
	move.w	d1,d2
	subq.w	#3,d1
	bne.b	.haslen
	bsr.b	.nextbit
	bcs.b	.hasbit
	moveq	#7,d0
.hasbit	bsr.b	.getbits
	move.w	d1,d3
.getlen2
	moveq	#2,d0
	bsr.b	.getbits_d0
	add.w	d1,d2
	subq.w	#7,d1
	beq.b	.getlen2
	bra.b	.enter

.haslen	bsr.b	.getbits
	move.w	d1,d3
.enter	addq.w	#1,d2
.unpack	move.b	(a1,d3.w),-(a1)
	dbf	d2,.unpack
	cmp.l	a1,a4
	bcs.b	.loop

.exit	rts
