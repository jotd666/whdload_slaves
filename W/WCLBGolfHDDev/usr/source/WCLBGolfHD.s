;*---------------------------------------------------------------------------
;  :Program.	WCLBGolf.asm
;  :Contents.	Slave for "WCLBGolf"
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
	OUTPUT	"WCLBGolf.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_assign0
	dc.b	"dh",0
_assign1
	dc.b	"c1",0
_assign2
	dc.b	"c2",0

_assigndir:
	dc.b	"wclb/courses",0
_course1dir:
	dc.b	"wclb/courses1",0
_course2dir:
	dc.b	"wclb/courses2",0

slv_name		dc.b	"World Class Leaderboard Golf",0
slv_copy		dc.b	"1988 Access",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to C. Vella/C. Johansson/Cap. HIT for diskimages",10,10
		dc.b	"Version 1.2 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Golf",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign0(pc),a0
		sub.l	a1,a1
		lea	_assigndir(pc),a1
		bsr	_dos_assign

		lea	_assign1(pc),a0
		sub.l	a1,a1
		lea	_course1dir(pc),a1
		bsr	_dos_assign

		lea	_assign2(pc),a0
		sub.l	a1,a1
		lea	_course2dir(pc),a1
		bsr	_dos_assign

		bsr	_patch_alloc

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end

	;patch
		bsr	_patch_exe
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
_quit:
		move.l	_resload(pc),a2
		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end		moveq	#0,d0
		rts

_patch_alloc:
	move.l	$4.W,a0
	add.w	#_LVOAllocMem+2,a0
	lea	_alloc_save(pc),a1
	move.l	(a0),(a1)
	lea	_allocmem(pc),a1
	move.l	a1,(a0)
	bsr	_flushcache
	rts

_allocmem:
	btst	#MEMB_CHIP,D1
	beq.b	.org
	cmp.l	#$107C4,D0
	bne.b	.org
	bclr	#MEMB_CHIP,D1

	move.l	a6,a0
	add.w	#_LVOAllocMem+2,a0
	move.l	_alloc_save(pc),(a0)
	bsr	_flushcache	
.org
	move.l	_alloc_save(pc),-(A7)
	rts

_patch_exe:
	bsr	.getbounds

	moveq.l	#8,D0
	lea	.access_fault_1(pc),a2
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip1
	
	move.w	#$41EC,(A0)
.skip1
	bsr	.getbounds

	moveq.l	#12,D0
	lea	.quit_game(pc),a2
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip2
	move.w	#$4EF9,(A0)+
	pea	_quit(pc)
	move.l	(A7)+,(A0)
.skip2
	bsr	.getbounds

	moveq.l	#10,D0
	lea	.coursespath(pc),a2
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip3
	bsr	.setdh0
.skip3

	bsr	.getbounds
	moveq.l	#4,D0
	lea	.df0(pc),a2
.loop1
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip4
	bsr	.setdh1
	bra.b	.loop1
.skip4
	bsr	.getbounds
	moveq.l	#4,D0
	lea	.df1(pc),a2
.loop2
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip5
	bsr	.setdh2
	bra.b	.loop2
.skip5

	bsr	_flushcache
	rts

.setdh0:
	move.b	#'d',(A0)+
	move.b	#'h',(A0)+
	move.b	#':',(A0)+
	move.b	#0,(A0)+
	rts

.setdh1:
	move.b	#'c',(A0)+
	move.b	#'1',(A0)+
	move.b	#':',(A0)+
	move.b	#0,(A0)+
	rts

.setdh2:
	move.b	#'c',(A0)+
	move.b	#'2',(A0)+
	move.b	#':',(A0)+
	move.b	#0,(A0)+
	rts

.getbounds:
	move.l	d7,a0
	add.l	a0,a0
	add.l	a0,a0
	move.l	a0,a1
	add.l	#$107B0,a1
	rts

.coursespath:
	dc.b	"wclb/courses"
	even
.df0:
	dc.b	"df0:"
.df1:
	dc.b	"df1:"

.access_fault_1:
	dc.l	$206C8AAC,$12300000

.quit_game:
	dc.l	$222F0004,$2C6C4548,$4EEEFF70

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

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


PATCH_OFFSET:MACRO
	move.l	A3,A1
	add.l	#_LVO\1,A1
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	_old\1(pc),a0
	move.l	A1,(A0)+

	move.l	A3,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)

	move.w	#$4EF9,(A1)+	
	pea	_new\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	_end_patch\1
_old\1:
	dc.l	0
_d0_value_\1
	dc.l	0
_end_patch\1:
	ENDM


_patch_dos:
	movem.l	D0-A6,-(A7)
	move.l	A6,A3
	move.l	$4.W,A6
	PATCH_OFFSET	Lock
	PATCH_OFFSET	Open
	bsr	_flushcache
	movem.l	(A7)+,D0-A6
	rts

_newLock:
	bsr	_fix_slash
	moveq	#0,D0
	move.l	_d0_value_Lock(pc),d0
	move.l	_oldLock(pc),-(A7)
	rts

_newOpen:
	bsr	_fix_slash
	moveq	#0,D0
	move.l	_d0_value_Open(pc),d0
	move.l	_oldOpen(pc),-(A7)
	rts


_fix_slash:
	move.l	D1,A0
	cmp.l	#0,a0
	beq.b	.skip

.loop1
	cmp.b	#'/',(a0)
	beq.b	.oneslash
	tst.b	(a0)+
	bne.b	.loop1
	bra.b	.skip		; colon not found
.oneslash
	addq.l	#1,a0
	cmp.b	#'/',(a0)
	bne.b	.skip		; no problemo
	
	lea	.buffer(pc),a0
	move.l	d1,a1

	; copy and replace ':/' by ':'
.loop
	move.b	(a1)+,(a0)+
	beq.b	.out
	cmp.b	#'/',-1(a1)
	bne.b	.loop
	cmp.b	#'/',(a1)
	bne.b	.loop
	addq	#1,a1	; skip next '/'
	bra.b	.loop
	
.out
	lea	.buffer(pc),a0
	move.l	A0,D1
.skip
	rts

.buffer:
	blk.b	$40,0

_alloc_save:
	dc.l	0

;============================================================================
