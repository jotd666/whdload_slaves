;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	dos/dos.i
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"ChaosStrikesBack.Slave"
	BOPT	O-				;enable optimizing
	BOPT	OG-				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $80000
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

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Chaos Strikes Back",0
slv_copy		dc.b	"1989-1990 FTL/Software Heaven",0
slv_info		dc.b	"adapted & fixed by Harry/JOTD",10,10
		dc.b	"Set CUSTOM1=x where x is file 'disk.x'",10
		dc.b	"which is the current savegame disk",10
		dc.b	"default: x=3",10,10
		dc.b	"Set CUSTOM2=1 to start on utility disk",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
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

		cmp.l	#'BJEL',1(A0)	; BJELoad_R BSTR
		bne.b	.skip

		move.l	d1,A3
		bsr	_patch_bjeload
		bsr	_patch_kb
		rts
.skip
		; skip program

		move.l	D1,A0
		move.l	#$70004E75,(A0)
		rts

_quit
		PEA	TDREASON_OK
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

	move.b	_trd_disk(pc),d0
	cmp.b	#1,d0
	bne.b	.out		; don't patch utility disk

	move.l	a3,a1
	lea	_pl_main_protect(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

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
	bne.b	.nomain

	bsr	_patch_kaos
.nomain
	move.l	(A7)+,D0

	bsr	_flushcache

	move.l	.return(pc),-(A7)
	jmp	(A0)
.return
	dc.l	0

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


_patch_kb
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


tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;============================================================================


;============================================================================

_dosname
	dc.b	"dos.library",0
	END

