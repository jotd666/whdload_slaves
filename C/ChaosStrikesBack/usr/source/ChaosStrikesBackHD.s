;*---------------------------------------------------------------------------
;  :Program.	ChaosStrikesBackHD.asm
;  :Contents.	Slave for "Chaos Strikes Back"
;  :Author.	Harry
;  :History.	20.03.2017
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.	adapt CSB 3.5
;---------------------------------------------------------------------------*




		INCDIR	"ASM-ONE:include3.0/"
	INCLUDE	own/whdload.i
	INCLUDE	own/whdmacros.i
	INCLUDE	dos/dos.i
	INCLUDE	dos/dosextens.i
	INCLUDE lvo/graphics.i
	INCLUDE exec/exec.i
	INCLUDE lvo/exec.i
	INCLUDE lvo/dos.i
	INCLUDE lvo/expansion.i
	INCLUDE graphics/displayinfo.i

	IFD BARFLY
;	OUTPUT	"ChaosStrikesBack.Slave"
;	BOPT	O-				;enable optimizing
;	BOPT	OG-				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
NUMDRIVES	= 2
WPDRIVES	= %0010	; disk 2 is save game

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
SETPATCH
CBDOSLOADSEG
BOOTBLOCK

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

;============================================================================

;	IFND	.passchk
;	DOSCMD	"WDate  >T:date"
;.passchk
;	ENDC

;DECL_VERSION:MACRO
;	dc.b	"1.1"
;	IFD BARFLY
;		dc.b	" "
;		INCBIN	"T:date"
;	ENDC
;	ENDM

;slv_CurrentDir		dc.b	"data",0
slv_CurrentDir		dc.b	0
slv_name		dc.b	"Chaos Strikes Back",0
slv_copy		dc.b	"1989-1990 FTL/Software Heaven",0
slv_info		dc.b	"adapted & fixed by Harry/JOTD",10,10
		dc.b	"Set CUSTOM1=x where x is file 'disk.x'",10
		dc.b	"which is the current savegame disk",10
		dc.b	"default: x=3",10,10
		dc.b	"Set CUSTOM2=1 to start on utility disk",10,10
		dc.b	"Version 1.21 (2019-10-04)"
;		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	dc.b	"1.21 (2019-10-04)"
	dc.b	$A,$D,0

	EVEN

_bootblock
	movem.l	a0-a2/a6/d0-d1,-(A7)

	;get tags
	lea	(tag,pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Control,a2)

	move.l	_custom2(pc),d0
	beq.b	.sk
	lea	_trd_disk(pc),a0
	move.b	#2,(a0)		; changes disk 1
.sk
	moveq	#3,d0
	move.l	_custom1(pc),d1
	beq.b	.setdisk
	; forbidden values 1 & 2 since they're game disks
	cmp.b	#1,d1
	beq.b	.setdisk
	cmp.b	#2,d1
	beq.b	.setdisk
	move.l	d1,d0		; accept disk change
.setdisk
	lea	_trd_disk(pc),a0
	move.b	d0,1(a0)		; changes disk 2
	movem.l	(a7)+,a0-a2/a6/d0-d1

	jsr	($C,a4)

	moveq.l	#0,D0
	rts


; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
		add.l	D1,D1		
		add.l	D1,D1	
		addq.l	#4,d1

		; now D1 is start address

		lsl.l	#2,d0
		move.l	d0,a0

		cmp.b	#'V',1(a0)
		bne.s	.nextprog
		cmp.b	#'e',2(a0)
		bne.s	.nextprog
		cmp.b	#'r',3(a0)
		bne.s	.nextprog
		cmp.b	#'s',4(a0)
		bne.s	.nextprog
		move.w	#$4ef9,$c0.w
		pea	_chkkaosver(pc)
		move.l	(a7)+,$c2.w
		move.l	d1,a0
		move.l	#$4ef800c0,(a0)
		rts

.nextprog
		;cmp.l	#'BJEL',1(A0)	; BJELoad_R BSTR
		cmp.b	#'B',1(a0)
		bne.s	.skip
		cmp.b	#'J',2(a0)
		bne.s	.skip
		cmp.b	#'E',3(a0)
		bne.s	.skip
		cmp.b	#'L',4(a0)
		bne.b	.skip

		move.l	d1,A3
		move.l	a3,$d4.w	;for debugging
		bsr	_patch_bjeload
		rts
.skip
		; skip program

		move.l	D1,A0
		move.l	#$70004E75,(A0)
		rts

_chkkaosver
	move.b	_trd_disk(pc),d0
	cmp.b	#1,d0
	bne.w	.skverdetect

;load first $1000 bytes of "KAOS" for version detection

	movem.l	D1-a6,-(A7)
;	lea	_dosbase(pc),a3
	lea	_dosname(pc),a1
	moveq	#0,D0
	move.l	$4.W,a6
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,a6
;	move.l	d0,(a3)

	lea.l	_kaosname(pc),a0
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	jsr	(_LVOOpen,a6)
	move.l	d0,d7
	beq.w	_wrongver

	move.l	d7,d1
	move.l	#$50000,d2
	move.l	#$1000,d3
	jsr	_LVORead(a6)

	move.l	d7,d1
	jsr	_LVOClose(a6)
		
	move.l	#$1000,d0
	move.l	#$50000,a0
	move.l	_resload(pc),a2
	jsr	(resload_CRC16,a2)
	movem.l	(a7)+,d1-a6

;	illegal

	cmp.w	#$6527,d0	;crc 3.5
	beq.s	.ver35

	cmp.w	#$a2d4,d0	;crc 3.1 tri-language
	bne.w	_wrongver

	moveq	#1,d0
	bra.s	.allver

.ver35	moveq	#2,d0

.allver
	lea	_kaosver(pc),a0
	move.b	d0,(a0)

.skverdetect
	moveq	#0,d0
	rts

_wrongver
		PEA	TDREASON_WRONGVER
		bra.s	_exitwhd
_quit
		PEA	TDREASON_OK
_exitwhd
		MOVE.L	_resload(PC),-(A7)
		add.l	#resload_Abort,(a7)
		rts

; A3: real start

_patch_bjeload:
	MOVEM.L	A0-A2,-(A7)		;0008: 48E700E0

	; check version

	move.l	(A3),D0
	cmp.l	#$4EFA1494,d0
	beq.b	.v1
	swap	D0
	cmp.w	#$4A39,d0
	beq	.out		; no patch

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.v1

	; install JOTD callback

	pea	_patch_1(pc)
	move.l	(A7)+,$80.W

	; patch rest of bjeload_r code

	move.l	a3,a1
	lea	_pl_main_patch(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
;.1	btst	#7,$bfe001
;	bne.s	.1

	move.b	_trd_disk(pc),d0
	cmp.b	#1,d0
	bne.w	.out		; don't patch utility disk

	move.l	a3,a1
	lea	_pl_main_protect(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	d0,-(a7)
	move.b	_kaosver(pc),d0
	cmp.b	#1,d0
	bne.s	.out2

;3.1 tri-language
	; install harry original 1st segment

	lea	_harry_patch(pc),a2
	LEA	14(A2),A1		;0020: 43FA0022
	MOVE.L	2090(A3),8(A2)		;0024: 24A8082A
	MOVE.L	A1,2090(A3)		;0028: 2149082A

	move.w	#$4EF9,$1A(a2)
	pea	_flush_and_jump(pc)
	move.l	(a7)+,$1C(a2)

	move.w	#$4EB9,$216(a2)
	pea	_jsr_and_flush(pc)
	move.l	(a7)+,$218(a2)

.out2	move.l	(a7)+,d0
.out
	MOVEM.L	(A7)+,A0-A2
	RTS

_flush_and_jump
	bsr	_flushcache
	move.l	-4(a0),a0
	jmp	(a0)

_jsr_and_flush
	jsr	2642(a5)
	bsr	_flushcache
	addq.l	#6,(A7)
	rts

_pl_main_protect:
	; Harry crack routines

	PL_START
;	PL_W	$390,$4e71
	PL_W	$692,$4e71
	PL_W	$694,$4e71
	PL_W	$6a2,$4e71
	PL_W	$6a4,$4e71
	PL_W	$746,$4e71
	PL_W	$748,$4e71
	PL_W	$840,$4e71
	PL_W	$842,$4e71
	PL_W	$434-$28,$302d
	PL_W	$438-$28,$6006
	PL_W	$6d0-$28,$302d
	PL_W	$6d2-$28,$ffc0
	PL_W	$6d4-$28,$3e00
	PL_W	$6d6-$28,$de40
	PL_W	$774-$28,$3e2d
	PL_W	$776-$28,$ffc4
	PL_W	$778-$28,$3007
	PL_W	$77a-$28,$6006
	PL_W	$86e-$28,$3e2d
	PL_W	$870-$28,$ffc2
	PL_W	$872-$28,$3007
	PL_W	$874-$28,$6004
	PL_END

_pl_main_patch:
	PL_START
	PL_W	$E90,$4E40
	PL_END



_patch_1:
	move.l	A0,-(A7)
	lea	.return(pc),a0
	move.l	6(A7),(a0)

	lea	.cont(pc),a0
	move.l	a0,6(a7)
	move.l	(a7)+,A0
	rte
.cont
	bsr	_patch_dos

	move.l	D0,-(A7)
	move.l	_last_opened_file(pc),d0
	cmp.l	#'KAOS',D0
	bne.w	.nomain

	move.l	a0,$d0.w	;store kaos pointer for debugging
	move.b	_kaosver(pc),d0
	cmp.b	#2,d0
	bne.w	.test2
				;patch here 3.5

;.1	btst	#7,$bfe001
;	bne.s	.1

;	move.l	#$4a548-$350f0,d0
;	move.l	#$4e714e71,0(a0,d0.l)

	move.l	#$383a2-$350f0,d0	;guru
;	move.b	#$60,0(a0,d0.l)
	move.w	#$4afc,2(a0,d0.l)

	move.l	#$3ab4e-$350f0,d0	;int diskrout?
	move.w	#$6032,0(a0,d0.l)
	move.l	#$4eb800e0,$88-$4e(a0,d0.l)
	move.w	#$6016,$8c-$4e(a0,d0.l)
	move.l	#$3abdc-$350f0,d0	;end?
;	move.w	#$602a,0(a0,d0.l)
	move.w	#$600a,0(a0,d0.l)
	move.w	#$6016,$14(a0,d0.l)

	move.l	#$49872-$350f0,d0	;end int rout
	move.w	#$4e75,0(a0,d0.l)

	move.l	#$39afa-$350f0,d0	;start int drive
	move.w	#$6050,0(a0,d0.l)
;	move.w	#$4eb9,0(a0,d0.l)
;	pea	_patch_ts3(pc)
;	move.l	(a7)+,2(a0,d0.l)
;	move.w	#$604a,6(a0,d0.l)

	move.l	#$4783a-$350f0,d0	;int start dma
	move.l	#$70006026,0(a0,d0.l)
	move.l	#$4eb800e0,-6(a0,d0.l)
	move.w	#$4e71,-2(a0,d0.l)
	move.w	#$4ef9,$e0.w
	pea	_patch_ts2(pc)
	move.l	(a7)+,$e2.w

	move.l	#$3aae8-$350f0,d0	;start int trackcheck
	move.w	#$6030,0(a0,d0.l)

	move.l	#$4e44e-$350f0,d0	;trackcheck
	move.b	#$60,0(a0,d0.l)

	move.l	#$3c682-$350f0,d0	;trackcheck
	move.l	#$600000ac,0(a0,d0.l)

	move.l	#$3b6a8-$350f0,d0	;trackcheck
	move.w	#$7e0a,0(a0,d0.l)
	move.l	#$6000018e,2(a0,d0.l)

	move.l	#$553fe-$350f0,d0	;trackcheck
	move.w	#$4eb9,0(a0,d0.l)
	pea	_patch_ts1(pc)
	move.l	(a7)+,2(a0,d0.l)
;	move.l	#$3d7c0088,0(a0,d0.l)
	move.w	#$6066,6(a0,d0.l)

	move.l	#$44610-$350f0,d0	;trackcheck
	move.w	#$6038,0(a0,d0.l)
;	move.w	#$6024,0(a0,d0.l)

	move.l	#$5a074-$350f0,d0	;trackcheck
	move.l	#$7c014e71,0(a0,d0.l)

	move.l	#$52596-$350f0,d0	;chksum $443f
	move.l	#$303c443f,0(a0,d0.l)	;move.w #$,d0
	move.l	#$55842-$350f0,d0	;chksum $5711
	move.l	#$303c5711,0(a0,d0.l)
	move.l	#$55e04-$350f0,d0	;chksum $843f
	move.l	#$303c843f,0(a0,d0.l)
	move.l	#$5aca0-$350f0,d0	;chksum $843f
	move.l	#$303c843f,0(a0,d0.l)

	move.l	#$5cff2-$350f0,d0
	move.w	#$4afc,0(a0,d0.l)	;reboot

	move.l #$53946-$39898,d0	;write jmp to hidden rout. 1
	move.l #$4eb800c6,0(a0,d0.l)
	move.w #$4ef9,$c6.w
	pea.l	_patch_makejmp(pc)
	move.l	(a7)+,$c8.w


	bra.s	.nomain

.test2
	cmp.b	#1,d0
	bne.s	.nomain

	bsr	_patch_kaos
.nomain
	move.l	(A7)+,D0

	bsr	_flushcache

	move.l	.return(pc),-(A7)
	jmp	(A0)
.return
	dc.l	0

_patch_makejmp
	move.l	(a7),$c(a7)
	lea.l	$c(a7),a7	;orig instr.
;now hang into the calling routine (a3)

	cmp.l	#$41fa003a,(a3)
	bne.s	.skip
	cmp.l	#$4258227a,4(a3)
	bne.s	.skip
	cmp.l	#$002222d8,8(a3)
	bne.s	.skip
	cmp.l	#$3290207a,$c(a3)
	bne.s	.skip
	cmp.l	#$001e3f3a,$10(a3)
	bne.s	.skip
	cmp.l	#$4e904fef,$22(a3)
	bne.s	.skip

	move.l	a0,-(a7)
	move.w	#$4e71,$22(a3)
	move.l	#$4eb800fa,$24(a3)

	move.w	#$4ef9,$fa.w
	pea.l	_patch_gfxdat(pc)
	move.l	(a7)+,$fc.w

	move.l	(a7)+,a0
	rts
.skip	illegal
	rts

_patch_gfxdat
;orig. instr.
;	JSR	(A0)
;	LEA	$a(a7),A7
	movem.l	a1/a2,-(a7)
	lea.l	.jmpback(pc),a2
	move.l	8(a7),a1
	move.l	2(a1),(a2)
;check for right subroutine
	cmp.l	#$4e560000,(a0)
	bne.s	.skip
	cmp.l	#$48e71f18,4(a0)
	bne.s	.skip
	cmp.l	#$286e0008,8(a0)
	bne.s	.skip
	cmp.l	#$206e000c,$c(a0)
	bne.s	.skip
	cmp.l	#$0c470463,$48(a0)
	bne.s	.skip

	move.l	#$4eb800f4,$1a(a0)
	move.w	#$4ef9,$f4.w
	pea.l	_patch_gfxdatgetd3(pc)
	move.l	(a7)+,$f6.w
	move.w	#$58,$20(a0)

;.skip
	movem.l	(a7)+,a1/a2
.skip2	lea	4(a7),a7
	jsr	(A0)	;orig
	lea	$a(a7),a7
	dc.w	$4ef9
.jmpback
	dc.l	$0
	rts

.skip	movem.l	(a7)+,a1/a2
	cmp.l	#$4e560000,(a0)
	bne.s	.skip2
	cmp.l	#$48e71f3e,4(a0)
	bne.s	.skip2
	cmp.l	#$2a6e000c,8(a0)
	bne.s	.skip2
	cmp.l	#$08ed0000,$c(a0)
	bne.s	.skip2
	cmp.l	#$000c66f8,$10(a0)
	bne.s	.skip2
	move.w	#$6054,4(a0)
;.1	move.w	#$f00,$dff180
;	btst	#7,$bfe001
;	bne.s	.1
;	illegal
	bra.s	.skip2

_patch_gfxdatgetd3
	move.l	a0,-(a7)
	lea	_tabled3(pc),a0
	move.b	-1(a0),d6
	move.b	0(a0,d6.w),d3	

	addq.b	#$1,d6
	cmp.b	#$c,d6
	bne.s	.1
	moveq	#0,d6
.1	move.b	d6,-1(a0)
	move.l	(a7)+,a0
	rts
	even
_byterandomd3
	dc.b	$00
_tabled3
	dc.b	$C8,$CA,$CB,$C6
	dc.b	$C9,$CC,$CF,$CD
	dc.b	$CE,$D2,$D0,$D1

	even	

_patch_ts1
	move.w	$dff00a,d4
	and.w	#$ff,d4
	add.w	#$88,d4
	move.w	d4,-2(a6)
	rts

_patch_ts2
	moveq	#4,d0
	move.w	d0,-$3604(a5)

	MOVE.L	-$1ef6(a5),A0
	MOVE.W	#$4F6,D0
.1	MOVE.W	#$1440,0(A0,D0.W)
	ADDQ.W	#2,D0
	CMP.W	#$8C8,D0
	BNE.S	.1
	ADDQ.W	#2,D0
	MOVE.W	#$1014,0(A0,D0.W)
	ADDQ.W	#2,D0
	MOVE.W	#$1004,0(A0,D0.W)

	move.w	#$2000,$dff09c
	move.w	#$a000,$dff09a
;	CLR.B	-$357C(A5)
;	MOVEQ	#1,D0
	RTS



_patch_ts3
	move.l	8(a6),$cc.w
	rts

_patch_dos
	move.l	_dosbase(pc),-(a7)
	tst.l	(a7)+
	bne.b	.out		; already patched
	movem.l	D0-a6,-(A7)
	lea	_dosbase(pc),a3
	lea	_dosname(pc),a1
	moveq	#0,D0
	move.l	$4.W,a6
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,(a3)

	; dos patch - only works for kick 1.x

	move.l	_dosbase(pc),a0
	add.w	#_LVOOpen,a0
	move.w	#$4EF9,(A0)+

	moveq.l	#0,D0
	move.w	2(A0),D0	; offset
	move.l	A0,A2
	add.l	D0,A2
	addq.l	#2,A2		; now the real open address

	lea	_open_save(pc),A1
	move.l	A2,(A1)		; save it

	pea	_openfile(pc)
	move.l	(a7)+,(A0)

	movem.l	(A7)+,D0-A6
.out
	bsr	_flushcache
	rts

_is_csbsave:
	moveq	#0,d0
	move.l	d1,a0
	cmp.b	#'C',4(a0)
	beq.b	.ok
	moveq.l	#-1,d0
.ok
	rts

_is_dmsave:
	moveq	#0,d0
	move.l	d1,a0
	cmp.b	#'D',4(a0)
	beq.b	.ok	
	moveq.l	#-1,d0
.ok
	rts

; test if game is savegame
; < d1: pointer on savegame name
; > d0: 0 ok, !=0 not a savegame

_is_savegame:
	move.l	d1,a0
	cmp.b	#'D',(a0)+
	bne.b	.wrong
	cmp.b	#'F',(a0)+
	bne.b	.wrong
	cmp.b	#'1',(a0)+
	bne.b	.wrong
	cmp.b	#':',(a0)+
	bne.b	.wrong
.search_zero
	tst.b	(a0)+
	bne.b	.search_zero
	subq.l	#1,a0
	cmp.b	#'T',-(a0)
	bne.b	.wrong
	cmp.b	#'A',-(a0)
	bne.b	.wrong
	cmp.b	#'D',-(a0)
	bne.b	.wrong
	cmp.b	#'.',-(a0)
	bne.b	.wrong
	moveq	#0,d0
	rts
.wrong:
	moveq	#-1,d0
	rts

_openfile
	movem.l	d3/d4,-(a7)
	moveq	#0,d4
	move.l	d1,d3	; save for later use

	move.l	d1,a0
	lea	_last_opened_file(pc),a1
	; save 4-letter file name (68000 compatible mode)

	move.b	(A0)+,(A1)+
	move.b	(A0)+,(A1)+
	move.b	(A0)+,(A1)+
	move.b	(A0)+,(A1)+

	bsr	_is_savegame
	tst.l	d0
	bne	.skip

	bsr	_is_dmsave
	move.l	d0,d4		; d4 set: csb savegame

	cmp.l	#MODE_NEWFILE,d2
	beq	.create

	; try with passed name
	moveq	#-1,D0		; original 1.3 doslib does that
	pea	.next(pc)
	move.l	_open_save(pc),-(a7)
	rts
.next
	tst.l	d0
	bne	.ok	; works with the original name ok

	; failed: try with the other name 'CSBGAMEF.DAT'

	move.l	d3,a0		; restore name
	lea	.namecopy(pc),a1
	bsr	.copy

	; ------------------------------

	lea	.namecopy(pc),a1
	move.l	a1,d1		; change name (sort of "link")
	bsr	.getnameend
	move.b	#'F',(a1)+
	move.b	#'.',(a1)+
	move.b	#'D',(a1)+
	move.b	#'A',(a1)+
	move.b	#'T',(a1)+
	move.b	#0,(a1)+

	moveq	#-1,D0		; original 1.3 doslib does that
	pea	.next2(pc)
	move.l	_open_save(pc),-(a7)
	rts
.next2
	tst.l	d0
	bne	.ok

	; ------------------------------

	lea	.namecopy(pc),a1
	move.l	a1,d1		; change name (sort of "link")
	bsr	.getnameend
	move.b	#'G',(a1)+

	moveq	#-1,D0		; original 1.3 doslib does that
	pea	.next3(pc)
	move.l	_open_save(pc),-(a7)
	rts
.next3
	tst.l	d0
	bne	.ok

	; ------------------------------

	lea	.namecopy(pc),a1
	move.l	a1,d1		; change name (sort of "link")
	bsr	.getnameend
	move.b	#'.',(a1)+
	move.b	#'D',(a1)+
	move.b	#'A',(a1)+
	move.b	#'T',(a1)+
	move.b	#0,(a1)+

	moveq	#-1,D0		; original 1.3 doslib does that
	pea	.next4(pc)
	move.l	_open_save(pc),-(a7)
	rts
.next4
; whether it worked or not, we return
	tst.l	d0
	bne.b	.ok

.quit
	movem.l	(a7)+,d3/d4
	tst.l	d0
	rts

; < a1
; < d4
; > a1
.getnameend
	lea	11(a1),a1
	tst	d4
	bne.b	.csb
	subq.l	#1,a1		; DM instead of CSB
.csb
	rts

	; open ok: return, after having copied the proper name
.ok
	tst	d4
	beq.b	.quit		; not set: not csb: don't copy

	lea	.namecopy(pc),a0
	lea	.correctname(pc),a1
	bsr	.copy

	bra.b	.quit
.skip

	moveq	#-1,D0		; original 1.3 doslib does that
	movem.l	(a7)+,d3/d4
	move.l	_open_save(pc),-(a7)
	rts

.create
	lea	.correctname(pc),a0
	tst.b	(a0)
	beq.b	.skip		; no correct name has been recorded

	; replace passed name by correct name
	move.l	a0,d1
	bra.b	.skip

.copy
	move.b	(a0)+,(a1)+
	bne.b	.copy
	rts

.namecopy:
	blk.b	$20,0
.correctname:
	blk.b	$20,0

_dosbase:
	dc.l	0
_open_save:
	dc.l	0
_last_opened_file:
	dc.l	0

_patch_kaos:
	movem.l	D0-A6,-(A7)
	move.l	_resload(pc),a2
	move.l	a0,a1
	lea	_pl_kaos(pc),a0
	jsr	resload_Patch(a2)	
	movem.l	(A7)+,D0-A6
	rts

_restart:
	bra	_quit
	IFEQ	1
	pea	.svmode(pc)
	move.l	(a7)+,$80.W
	trap	#0
.svmode
	ori	#$700,SR
	bra	_kickreboot
	ENDC

_pl_kaos:
	PL_START
	PL_P	$239BC,_restart
	PL_END

; replace DF0: by DF1: for savegame disk unit

_replace_df0:
	movem.l	D0-A6,-(A7)

	move.l	a0,a1		; end
	sub.l	#$20000,a0
	lea	.df0_1(pc),a2
	moveq.l	#4,d0
.df0_1_loop:
	bsr	_rev_hexsearch

	cmp.l	#0,A1
	beq.b	.exit_1

	move.l	#'DF1:',(a1)
	cmp.l	#$00004475,4(a1)
	bne.b	.df0_1_loop
.exit_1
	movem.l	(A7)+,D0-A6
	rts

.df0_1:
	dc.b	"DF0:"


;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A1: address or 0 if not found

_rev_hexsearch:
	movem.l	D1/D3/A0/A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A1,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	subq.l	#1,A1	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A1,A1
.exit:
	movem.l	(A7)+,D1/D3/A0/A2
	rts


_harry_patch:
	incbin	"harrypatch.bin"



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


tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;============================================================================


;============================================================================

_dosname
	dc.b	"dos.library",0
_kaosname
	dc.b	"KAOS.FTL",0
_kaosver
	dc.b	0
	END

