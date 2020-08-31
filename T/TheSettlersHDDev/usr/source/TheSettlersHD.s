;*---------------------------------------------------------------------------
;  :Program.	TheSettlersHD.asm
;  :Contents.	Slave for "TheSettlers"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: TheSettlersHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"TheSettlers.slave"
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
FASTMEMSIZE	= $400000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
NEEDFPU
;SETPATCH
BOOTDOS

CRACKIT = 1

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.5"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name	dc.b	"The Settlers / Die Siedler",0
slv_copy	dc.b	"1993 Blue Byte",0
slv_info	dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Set CUSTOM1=1 to skip introduction",10,10
		dc.b	"Thanks to Tony Aksnes & Wepl for disk images",10,10
		dc.b	"Thanks to Olivier Schott for testing & bugreports",10,10
		dc.b	"Version "
	IFND	CRACKIT
		dc.b	"(uncracked) "
	ENDC
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_intro:
	dc.b	"mcp",0
_intro_args:
	dc.b	"SCPT",0
_intro_args_end:
	dc.b	0
_program_uk:
	dc.b	"TheSettlers",0
_program_de:
	dc.b	"DieSiedler",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN
_german:
	dc.l	0
_program:
	dc.l	0

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

;;	bsr	_patchkb

	move.l	(_resload),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	_program_uk(pc),a3
		move.l	a3,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
		bne.b	.ok

		lea	_german(pc),a3
		move.l	#1,(a3)

		lea	_program_de(pc),a3
		move.l	a3,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
		bne.b	.ok

		move.l	a3,-(A7)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
.ok
		jsr	(_LVOUnLock,a6)

		lea	_program(pc),a0
		move.l	a3,(a0)

		move.l	_custom1(pc),d0
		bne.b	.skipintro

	;load exe
		lea	_intro(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
		bsr	_patch_intro
		bsr	_flushcache

	;disable cache for intro
		move.l	#WCPUF_Base_NC|WCPUF_Exp_NC|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_intro_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_intro_args_end-_intro_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)


.skipintro:
	;enable cache for intro
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	;load exe
		move.l	_program(pc),d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
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

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_end
		move.l	_program(pc),-(A7)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_patch_intro:
	movem.l	d0-a6,-(A7)

	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a3,a0
	lea	$1200(a0),a1

	lea	_pvbr(pc),A2
	moveq.l	#4,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip0
	move.l	#$4E717000,(A0)
.skip0
	move.l	a3,a0
	lea	$1200(a0),a1

	lea	_pcacr(pc),A2
	moveq.l	#4,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip1
	move.l	#$4E714E71,(A0)
.skip1
	lea	_jmpa6(pc),A2
	moveq.l	#2,D0
	move.l	a3,a0
	lea	$1200(a0),a1
.loop
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip2
	move.w	#$4E40,(a0)+
	bra.b	.loop
.skip2
	pea	_handle_jmpa6(pc)
	move.l	(a7)+,$80.W

	movem.l	(a7)+,d0-a6
	rts

_handle_jmpa6:
	move.l	A0,-(A7)
	lea	.next(pc),a0
	move.l	a0,6(a7)	; change TRAP return address
	move.l	(a7)+,a0
	RTE			; goes to .next
.next
	bsr	_flushcache
	jmp	(A6)

_avoid_subq_af:
	move.l	($34,a0),a0
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

	subq.b	#1,(8,a0)
.skip
	move.l	(a7)+,d0
	rts

_patch_exe:
	movem.l	d0-a6,-(A7)

	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3
	addq.l	#4,a3

	lea	-$20(a3),a1
	move.l	_german(pc),d0
	bne.b	.gotoger

	cmp.l	#'LIQU',$38C2(a1)
	beq.b	.french_v1
	cmp.l	#'DENT',$38B6(a1)
	beq.b	.uk_v1

	bra	_wrong_version

.uk_v1
	lea	_pl_english(pc),a0
.patch
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

.french_v1:
	lea	_pl_french_v1(pc),a0
	bra.b	.patch

.gotoger
	cmp.l	#'BITT',$38B0(a1)
	beq.b	.gerv1
	cmp.l	#'BITT',$38BE(a1)
	beq.b	.gerv2
	bra	_wrong_version
.gerv1:
	lea	-$20(a3),a1
	lea	_pl_german_v1(pc),a0
	bra	.patch
.gerv2:
	lea	-$20(a3),a1
	lea	_pl_german_v2(pc),a0
	bra	.patch


_jmpa6
	dc.w	$4ED6

_pvbr:
	dc.l	$4E7A0801

_pcacr:
	dc.l	$4E7B1002

_wrong_version:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


; Amigapatchlist compliant
_pl_german_v1:
	PL_START
	IFD	CRACKIT
        PL_L	$6a6e,$4e714E71
        PL_B	$7d00,$60
        PL_B	$ba7A,$60
	PL_B	$c3aa,$60
	PL_B	$cc94,$60
	PL_B	$17be2,$60
	PL_W	$25124,$4e71
	ENDC

	; access fault when soldiers enter the castle

	PL_W	$EC66,$4E71
	PL_PS	$EC68,_avoid_subq_af

	; empty DBF

	PL_PS	$6594,_emu_dbf_50

	; VBR

	PL_L	$132,$70004E71
	PL_END


; Amigapatchlist compliant

_pl_german_v2:
	PL_START

	IFD	CRACKIT
	PL_L	$6a7c,$4e714E71
	PL_B    $7d12,$60
	PL_B    $bac0,$60
	PL_B    $c3ca,$60
	PL_B	$ccFC,$60
	PL_B	$17c50,$60
	PL_W	$251B4,$4e71
	ENDC

	; access fault when soldiers enter the castle

	PL_W	$ECCE,$4E71
	PL_PS	$ECD0,_avoid_subq_af

	; VBR

	PL_L	$132,$70004E71

	; empty DBF

	PL_PS	$65a2,_emu_dbf_50

	PL_END


; Amigapatchlist compliant

_pl_english:
        PL_START

	; protection

	IFD	CRACKIT
	PL_L	$6a6a,$4e714e71
	PL_B    $7d00,$60
	PL_B    $baae,$60
	PL_B    $c3b8,$60
	PL_B    $ccea,$60
	PL_B    $17c3e,$60
	PL_W    $250be,$4e71
	ENDC

	; access fault when soldiers enter the castle

	PL_W	$ECBC,$4E71
	PL_PS	$ECBE,_avoid_subq_af

	; VBR

	PL_L	$132,$70004E71

	; empty DBF

	PL_PS	$6590,_emu_dbf_50

        PL_END

_pl_french_v1:
	PL_START
	; protection, adapted from UK

	IFD	CRACKIT
	PL_L    $6a86,$4e714E71
	PL_B	$7d1c,$60
	PL_B    $bacA,$60
	PL_B    $c3d4,$60
	PL_B    $cd06,$60
	PL_B    $17c5a,$60
	PL_W    $25106,$4e71
	ENDC

	; VBR

	PL_L	$132,$70004E71

	; empty DBF

	PL_PS	$659A,_emu_dbf_50

	; access fault when soldiers enter the castle

	PL_W	$ECD8,$4E71
	PL_PS	$ECDA,_avoid_subq_af

	PL_END

_emu_dbf_50:
	moveq	#1,d0
	bra	_beamdelay

_patchkb
	IFEQ	KICKSIZE-$40000

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
	ELSE
	rts
	ENDC


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

;---------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
