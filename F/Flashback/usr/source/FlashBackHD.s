;*---------------------------------------------------------------------------
;  :Program.	FlashBackHD.asm
;  :Contents.	Slave for "FlashBack"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: FlashBackHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"FlashBack.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;DEBUG


	IFND	DEBUG
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $A0000
BLACKSCREEN
	ELSE
CHIPMEMSIZE	= $170000
FASTMEMSIZE	= $0000
HRTMON
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000


; Info() returns a size believed to be a size of a hard drive
; (the game checks volume size to determine if it is ran from
; floppy or HD)

HD_Cyls			= 1000

;DISKSONBOOT
;DOSASSIGN
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE
;STACKSIZE = 10000

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"3.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name		dc.b	"FlashBack",0
slv_copy		dc.b	"1992 Deplhine Software",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Set CUSTOM1=1 for infinite shield",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"flashback",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

; $9000-$FF000, pc $2D75E restart

;============================================================================

	;initialize kickstart and environment

_bootdos
	bsr	_beamdelay_calibration

	move.l	(_resload),a2		;A2 = resload

	;get tags
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
		movem.l	d0-a6,-(a7)
		add.l	d7,d7
		add.l	d7,d7
		bsr	_patch_exe
		movem.l	(a7)+,d0-a6

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

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

CRACKIT = 1
PATCH_NOPNOP:MACRO
	move.l	#$4E714E71,\1
	ENDM

; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
	rts

_patch_exe:
	moveq	#0,d2
	bsr	get_section
	move.l	A1,A3

	bsr	.get_bounds_s0

	; 1st prot: just press RETURN without having to type 6 chars

	moveq.l	#8,D0
	lea	.prot1(pc),A2
.loop1
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.out1
	add.l	#$14,A0

	; done 2 times

	IFD	CRACKIT
	PATCH_NOPNOP	(A0)
	ENDC

	bra.b	.loop1
.out1:
	bsr	.get_bounds_s0

	; 1st prot: any code passes

	moveq.l	#8,D0
	lea	.prot4(pc),A2

	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.out4
	; only first one, no loop
	IFD	CRACKIT
	PATCH_NOPNOP	(A0)
	ENDC

.out4:

	bsr	.get_bounds_s0

	; 2nd prot: teleport test

	moveq.l	#8,D0
	lea	.prot2(pc),A2
.loop2
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.out2

	IFD	CRACKIT
	PATCH_NOPNOP	(A0)
	ENDC
	addq.l	#4,a0

;;	bra.b	.loop2
.out2:
	bsr	.get_bounds_s0
	moveq.l	#6,D0
	lea	.prot3(pc),A2

	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.out3

	IFD	CRACKIT
	PATCH_NOPNOP	(A0)
	ENDC
	; only first one!
.out3:
	move.l	_custom1(pc),d0
	beq.b	.skiptrain

	bsr	.get_bounds_s0
	move.l	#12,d0
	lea	.lives(pc),A2
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skiptrain
	move.w	#$4EF9,(a0)+
	pea	_trainer(pc)
	move.l	(a7)+,(a0)
.skiptrain
	bsr	.get_bounds_s0
	move.l	#12,D0
	lea	.joy1(pc),A2

	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.out5

	; 2 button joypad patch
	move.l	#$612A4E71,(A0)

	move.l	#$600A33FC,$2A(A0)
	move.l	#$CC0100DF,$2E(A0)
	move.l	#$F034600A,$32(A0)

	move.l	#$60060802,$3E(A0)
	move.l	#$000E4E75,$42(A0)
.out5:
	; remove floppy led stuff

	bsr	.get_bounds_s0

	lea	.led(pc),A2
	move.l	#4,D0
.loop5
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.out6
	cmp.w	#$13FC,-4(A0)
	bne.b	.nomatch
	move.w	#$6006,-4(A0)
.nomatch
	addq.l	#4,A0
	bra	.loop5
.out6
	bsr	.get_bounds_s0
	lea	.kbwait(pc),a2
	moveq	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.out7
	move.w	#$80,2(a0)	; increase kb delay
.out7
	bsr	.get_bounds_s0
	move.l	#$51C8FFFE,D0
	move.l	#$4EB80100,D1
	bsr	_hexreplacelong

	patch	$100,_dbf_d0
	pea	_trapcache(pc)
	move.l	(a7)+,$BC.W

	bsr	.get_bounds_s0
	lea	.jmp00(pc),a2
	moveq	#6,D0
.loop7
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.out8
	move.w	#$4E4F,(a0)
	bra.b	.loop7
.out8

	bsr	.get_bounds_s0
	lea	.outofbounds(pc),a2
	moveq	#6,D0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.out9
	move.w	#$4EB9,(a0)+
	pea	move_60(pc)
	move.l	(a7)+,(a0)
.out9
	bsr	.get_bounds_s0
	lea	.blit1(pc),a2
	moveq	#6,D0
.cont9
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.out91
	move.w	#$4EB9,(a0)+
	pea	wait_blit_1(pc)
	move.l	(a7)+,(a0)
	bra.b	.cont9
.out91
	bsr	.get_bounds_s0

	lea	.active_loop_d0(pc),A2
	move.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.out92

	; no more wait (it was for OS swaps)

	move.w	#$4E75,(a0)
.out92

	moveq.l	#2,d2	; section 2
	bsr	get_section
	move.l	A1,A3

	bsr	.get_bounds_s2
	move.l	#$51C8FFFE,D0
	move.l	#$4EB80100,D1
	bsr	_hexreplacelong

	bsr	.get_bounds_s2
	lea	.jmp00(pc),a2
	moveq	#6,D0
.loop10
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.out11
	move.w	#$4E4F,(a0)
	bra.b	.loop10
.out11
	; nasty checksum nearly the end!!
	
	bsr	.get_bounds_s2
	lea	.checksum_prot(pc),a2
	moveq	#6,D0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.out12
	move.b	#$60,10(a0)	; checks every time
.out12
	bsr	_flushcache
	
	rts

.jmp00
	dc.w	$4EF9
	dc.l	0
.lives:
	dc.l	$C0FC0022,$D3C03029,$00085340

.outofbounds
	dc.w	$D041,$1585,$0060
.kbwait
	dc.l	$303C0064,$51C8FFFE
.prot1:
	dc.l	$6000007C,$B23C000A
.prot2:
	dc.l	$66000028,$51C8FFF2
.prot3:
	dc.l	$67000020
	dc.w	$43F9
.prot4:
	dc.l	$66000008,$51C8FFF2
.joy1:
	dc.l	$0802000E,$66000006,$08C00005
.led:
	dc.l	$BFD100

.blit1
	dc.w	$4279
	dc.l	$DFF066

.active_loop_d0
	dc.w	$5380
	dc.l	$6600FFFC

; checks for protection test
; not present in english version, but in all other ones

.checksum_prot
	dc.l	$0CB96600
	dc.w	$0008

; just code of first segment

.get_bounds_s0:
	move.l	A3,A1
	move.l	A1,A0
	add.l	#110000,A1
	rts


.get_bounds_s2:
	move.l	A3,A1
	move.l	A1,A0
	add.l	#17460,A1
	rts

move_60
	add.w	d1,d0
	cmp.w	#$36,d0
	bcc.b	.outofbounds
	move.b	d5,($60,a2,d0.w)
	rts
.outofbounds
	rts

wait_blit_1
	bsr	wait_blit
	move.w	#0,$dff066
	rts

_trap_mouse
	btst	#6,$bfe001
	bne.b	.out
	ILLEGAL
.out
	RTS

; fr: freeze en +$5D1D6

_trapcache:
	bsr	_flushcache

	movem.l	a0,-(a7)
	move.l	6(a7),a0
	move.l	(a0),6(a7)
	movem.l	(a7)+,a0
	rte
_dbf_d0:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

_trainer:
	mulu	#$22,d0
	add.l	d0,a1

	move.w	#4,(8,a1)	; fix lives

	move.w	(8,a1),d0
	subq.w	#1,d0
	move.w	D0,(8,a0)
	moveq	#1,d0
	rts

;< A0: start
;< A1: end
;< D0: longword to look for
;< D1: longword used to replace

_hexreplacelong:
	movem.l	A0-A1/D0-D1,-(A7)
.srch
	cmp.l	(A0),D0
	beq.b	.found
.next
	addq.l	#2,A0
	cmp.l	A1,A0
	bcc.b	.exit
	bra.b	.srch
.found
	move.l	D1,(A0)+
	bra	.next
.exit
	movem.l	(A7)+,A0-A1/D0-D1
	rts

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

wait_blit
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts

; < D0: numbers of vertical positions to wait
_beamdelay_old
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_beamdelay_calibration
	move.l	#10,d0	; 10 loops
	moveq	#0,d1
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	addq.l	#1,d1
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	lea	nb_ticks(pc),a0
	move.l	d1,(a0)
	rts

nb_ticks:
	dc.l	0

_beamdelay
	move.l  d1,-(a7)
	divu	#10,d0
.bd_loop0
	move.l	nb_ticks(pc),d1
.bd_loop1
	tst.b	$0
	subq.l	#1,d1
	bne.b	.bd_loop1
	dbf	d0,.bd_loop0
	move.l	(a7)+,d1
	rts



_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
