;*---------------------------------------------------------------------------
;  :Program.	CombatAirPatrol.asm
;  :Contents.	Slave for "CombatAirPatrol"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"CombatAirPatrol.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DEBUG
;DISKSONBOOT
;DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_EmulTrap|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	CNOP 0,4
_name		dc.b	"Combat Air Patrol",0
_copy		dc.b	"1991 Psygnosis",0
_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"CUSTOM1=1 skips introduction",10,10
		dc.b	"Version 1.2 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"cap.amg",0
_intro:
	dc.b	"capintro",0
_introdir
	dc.b	"intro",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootdos
	bsr	_patchkb

	move.l	(_resload),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_NC|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		move.l	_custom1(pc),d0
		bne.b	.skipintro

	;lock intro directory

		lea	_introdir(pc),a1
		move.l	a1,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
		beq.b	_end3

		jsr	(_LVOCurrentDir,a6)
		move.l	d0,-(a7)

	;load exe
		lea	_intro(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			; file not found

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)
		
		move.l	(a7)+,d1
		jsr	(_LVOCurrentDir,a6)
.skipintro
	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			; file not found

		bsr	_patch_exe
		bsr	_flushcache
	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)
_quit
		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end
		pea	_program(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_end2
		pea	_intro(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
_end3
		pea	_introdir(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_patch_exe:
	movem.l	D0-A6,-(A7)

	move.l	D7,A3
	add.l	a3,a3
	add.l	a3,a3

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$30000,A1
	lea	.ecsshit(pc),A2
	moveq.l	#8,D0
.loop1
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipecs
	move.w	#$600A,(A0)+
	bra.b	.loop1
.skipecs
	move.l	A3,A0
	move.l	A0,A1
	add.l	#$60000,A1
	lea	.ecsshit2(pc),A2
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipecs2
	move.w	#$4EB9,(A0)+
	pea	_waitblit1(pc)
	move.l	(a7)+,(A0)
.skipecs2


	; SMC on a AND.W  #immop changing all the time

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$60000,A1
	lea	.smc1(pc),A2
	move.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipsmc1
	move.w	#$4E4F,-4(A0)
	lea	_andd1(pc),A0
	move.l	A0,$BC.W
.skipsmc1

	; the SMC which causes flashes: wrong JMP because of caches/prefetch

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$30000,A1
	lea	.smc2(pc),A2
	move.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipsmc2
	move.w	#$4E4E,8(A0)
	lea	_trapjmp(pc),A0
	move.l	A0,$B8.W
.skipsmc2

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$30000,A1
	lea	.smc3(pc),A2
	move.l	#14,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipsmc3
	move.w	#$4E4E,12(A0)
	lea	_trapjmp(pc),A0
	move.l	A0,$B8.W
.skipsmc3

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$60000,A1
	lea	.diskstuff(pc),A2
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipflop
	move.w	#$4E75,(A0)
.skipflop

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$30000,A1
	lea	.bytes(pc),A2
	moveq.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip
	move.w	#$4EB9,(a0)+
	pea	_kbint(pc)
	move.l	(a7)+,(a0)+
	move.w	#$6006,(A0)
.skip

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$30000,A1
	lea	.cacr(pc),A2
	moveq.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipcacr
	move.w	#$6036,(A0)
.skipcacr

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$30000,A1
	lea	.prot(pc),A2
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip2
	move.l	#$10C14E71,(A0)
.skip2
	movem.l	(a7)+,d0-a6
	rts
.smc1:
	dc.l	$14014602,$83158315
.smc2:
	dc.l	$303B000E,$323B100C
	dc.w	$4EF9
.smc3:
	dc.l	$30310002,$23311004,$C043C243
	dc.w	$4EF9

.ecsshit:
	dc.l	$3D7C2020,$01DC3D7C
.ecsshit2:
	dc.l	$317C01F0,$00404268
.waitblit:
	dc.l	$08390006,$DFF002
	dc.w	$66F6
	dc.l	$08390006,$DFF002
	dc.w	$66F6

.diskstuff:
	dc.l	$33FC4000,$DFF024
.bytes:
	dc.l	$103900BF
	dc.w	$EC01
.prot:
	dc.l	$B2186608
	dc.l	$51C8FFF4
.cacr:
	dc.l	$20780014
	dc.w	$21FC

_andd1
	move.l	A0,-(a7)
	move.l	6(A7),A0
	and.w	(A0),D1
	move.l	(A7)+,A0
	addq.l	#2,2(A7)
	rte

_waitblit1:
	bsr	_waitblit
	move.w	#$1F0,($40,A0)
	rts
_waitblit2
	bsr	_waitblit
	rts

_waitblit:
	TST.B	dmaconr+_custom
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	TST.B	dmaconr+_custom
.end
	rts

_hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts

; corrects SMC $4EF9(address changing all the time)
; fixes color flashes

_trapjmp
	move.l	A0,-(A7)
	move.l	6(A7),A0	; return address
	move.l	(A0),6(A7)	; RTE -> JMP address
	move.l	(A7)+,A0
	rte

_kbint:
	move.b	$BFEC01,D0
	move.l	D0,-(A7)
	ror.b	#1,D0
	not.b	D0
	cmp.b	_keyexit(pc),D0
	beq	_quit
.skip
	bset	#6,$BFEE01
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	move.l	(A7)+,D0
	rts


_patchkb
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	INCLUDE	kick13.s

;============================================================================

	END
