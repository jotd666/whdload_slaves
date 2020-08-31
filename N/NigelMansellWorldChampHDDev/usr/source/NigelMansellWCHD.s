;*---------------------------------------------------------------------------
;  :Program.	NigelMansellWorldChampHD.asm
;  :Contents.	Slave for "NigelMansellWorldChamp"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: NigelMansellWorldChampHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
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
	OUTPUT	"NigelMansellWC.slave"
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

	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $00000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
;IOCACHE		= 1000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
STACKSIZE = 8000

; todo: fix result music in AGA version (probably a wrong fastmem allocation
; for samples)

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
	incbin	"slave_version"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

_assign1
	dc.b	"MANSELL_DISK1",0
_assign2
	dc.b	"MANSELL_DISK2",0

slv_name		dc.b	"Nigel Mansell World Champion ECS/AGA",0
slv_copy		dc.b	"1992 Gremlin",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Thanks to C.Vella and C.Pirri for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Mansell",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
		bsr	_patchrnc
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
		pea	_program(pc)
		jsr	(_LVOIoErr,a6)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_patchrnc
	movem.l	D0-A6,-(A7)

	; intercept program after the RNC executable decrunch
	; strange thing: one executable is decrunched OK with XFDDecrunch
	; but the other version is not (needs ProPack, so it's simpler to
	; support the crunched exe directly)

	move.l	d7,a5
	add.l	a5,A5
	add.l	a5,A5

	lea	$260(a5),a4
	cmp.l	#$4CDF7FFF,(a4)
	beq.b	.patch

	lea	$200(a5),a4
	cmp.l	#$4CDF7FFF,(a4)
	beq.b	.patch

	; unsupported version or decrunched exe

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
.patch
	pea	_patchexe(pc)
	move.w	#$4EF9,(a4)+
	move.l	(a7)+,(a4)+

	bsr	_flushcache
	movem.l	(a7)+,D0-A6
	rts

_patchexe:
	move.l	$3C(a7),a1	; return address
	move.l	a1,a0
	move.l	a1,a3
	move.l	a3,a4
	move.l	_resload(pc),a2
	add.l	#$8000,a3
	cmp.l	#$51C8FFFE,$A(a3)
	beq.b	.v1
	cmp.l	#$51C8FFFE,$A02(a3)
	beq.b	.v2
	cmp.l	#$51C8FFFE,$9FE(a3)
	beq.b	.vaga

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	

	; ECS version #1 (no gfx problems at start)
.v1
	lea	_pl_v1(pc),a0
	bra.b	.patch
.v2
	; ECS version #2 (small gfx problems at start)

	lea	_pl_v2(pc),a0
	bra.b	.patch
.vaga
	; AGA version

	lea	_pl_vaga(pc),a0
	bra.b	.patch
.patch
	jsr	resload_Patch(a2)

	patch	$100,_emulate_dbf
	pea	_trap_clist(pc)
	move.l	(a7)+,$BC.W

	movem.l	(a7)+,D0-A6
	rts

_pl_v1:
	PL_START
	PL_L	$800A,$4EB80100	; dbf
	PL_L	$801E,$4EB80100	; dbf
	PL_L	$83AC,$323C0012	; fixes access fault
	PL_W	$83B0,$4E71	; af
	PL_B	$EDE,$60	; skips protection
	PL_PS	$EA10,_ack_kb
	PL_W	$EA10+$14,$6004	; keyboard ack start
	PL_W	$EA10+$34,$6004	; keyboard ack end

	PL_END

_pl_v2:
	PL_START
	PL_L	$8A02,$4EB80100	; dbf
	PL_L	$8A16,$4EB80100	; dbf
	PL_L	$8D44,$323C0012	; fixes access fault
	PL_W	$8D48,$4E71	; af
	PL_B	$F36,$60	; skips protection
	PL_PS	$F486,_ack_kb
	PL_W	$F486+$14,$6004	; keyboard ack start
	PL_W	$F486+$34,$6004	; keyboard ack end

	PL_W	$108C,$4E4F	; sets copperlist
	PL_W	$1098,$4E4F	; sets copperlist
	PL_END


_pl_vaga:
	PL_START
	PL_L	$89FE,$4EB80100	; dbf
	PL_L	$8A12,$4EB80100	; dbf
	PL_L	$8D40,$323C0012	; fixes access fault
	PL_W	$8D44,$4E71	; access fault 2
	PL_B	$F36,$60	; skips protection
	PL_PS	$F482,_ack_kb	; replaces keyboard ack with handshake timing
	PL_W	$F482+$14,$6004	; keyboard ack start
	PL_W	$F482+$34,$6004	; keyboard ack end
	PL_PS	$672,alloc_aga_1
;	PL_PS	$6EE,alloc_aga_2
	PL_END

alloc_aga_1
	MOVE.L	(A4)+,D1		;00672: 221C
	cmp.l	#$E99A,d0	; alloc size matching music module "mod.results.30"
	bne.b	.skip

	; module results30 was loaded in fastmem: buggy music on result screen

	or.l	#MEMF_CHIP,d1
.skip
	JSR	_LVOAllocMem(A6)	;(exec.library)
	rts


alloc_aga_2
	JSR	_LVOAllocMem(A6)	;(exec.library)
	TST.L	D0			;006F2: 4A80
	rts

_trap_clist:
	movem.l	a1,-(a7)
	move.l	6(a7),a1
	move.l	(a1),a1

	; a1: copperlist pointer
	; patch copperlist now

	move.w	#$01FE,$40(a1)
	move.l	#$01FE0000,$44(a1)
	move.l	#$FFFFFFFE,$0.W

	move.l	a1,$dff080
	movem.l	(a7)+,a1
	addq.l	#8,2(a7)
	rte

_emulate_dbf:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

_ack_kb
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	rts

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

;============================================================================

	END
