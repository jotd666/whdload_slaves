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
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"ArcticFox.slave"
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
FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH

;============================================================================

KICKSIZE	= $40000		;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	11			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_name		dc.b	"Arctic Fox",0
_copy		dc.b	"1986 Electronic Arts",0
_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"Version 0.1 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		move.l	a0,a2

	;get/set tags
;		lea	(_tag,pc),a0
;		jsr	(resload_Control,a2)

	;	move.l	#WCPUF_Exp_WT,d0
	;	move.l	#WCPUF_Exp,d1
	;	jsr	(resload_SetCPU,a2)
		move.l	a2,a0

	;initialize kickstart and environment
		bra	_boot

_bootblock:
	movem.l	a0-a2/a6/d0-d1,-(A7)

	;kb fix

	bsr	_patchkb

	lea	_pl_bootblock(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/d0-d1
	jsr	($C,a4)
	movem.l	a0-a2/d0-d1,-(A7)
	move.l	a0,a1
	lea	_pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/a6/d0-d1
	moveq.l	#0,D0
	rts


_protect:
	lsl.l	#2,d1
	move.l	d1,a1
	movem.l	D0-D1/A0-A3,-(A7)
	patch	$100,_new_doio

	cmp.w	#$4EB9,$F0(a1)
	bne.b	.skip
	move.w	#$4EB9,$F0(A1)
	pea	_emulate_protect(pc)
	move.l	(A7)+,$F2(A1)
	move.l	-$268(A1),a1
	move.l	_resload(pc),a2
	lea	_pl_protect(pc),a0
	jsr	resload_Patch(a2)
.skip
	movem.l	(A7)+,D0-D1/A0-A3
	bsr	_flushcache
	jmp	(A1)

_new_doio
	cmp.l	#$1600,$2C(a1)
	beq.b	.error			; report error on track 1 (protection)
	jsr	-$1C8(a6)
	rts
.error
	moveq	#$15,D0
	rts

_emulate_protect:
	movem.l	A1,-(A7)
	clr.w	($12,A0)

	move.l	#$544aca15,(A1)+
	move.l	#$2a4b0573,(A1)+
	move.l	#$54949bbf,(A1)+
	move.l	#$a92ba626,(A1)+
	move.l	#$5255dd15,(A1)+
	move.l	#$a4a92b72,(A1)+
	move.l	#$4950c7bd,(A1)+
	move.l	#$92a31e22,(A1)+
	move.l	#$2544ad1d,(A1)+
	move.l	#$4a8bcb63,(A1)+
	move.l	#$9515079e,(A1)+
	move.l	#$2a289e65,(A1)+
	move.l	#$5453ad93,(A1)+
	move.l	#$a8a5ca7e,(A1)+
	move.l	#$514905a5,(A1)+
	move.l	#$a2909a12,(A1)+
	move.l	#$2295de7d,(A1)+
	move.l	#$45292da3,(A1)+
	move.l	#$8a50ca1e,(A1)+
	move.l	#$14a30565,(A1)+

	movem.l	(A7)+,A1
	moveq	#0,D0
	rts

; --------------------------------------------------------------

_pl_bootblock:
	PL_START
	PL_W	$9C,$4E75	; avoid green screen + pause
	PL_END

_pl_protect:
	PL_START

	PL_L	$13F54-$12BB8,$4EB80100

	PL_END


_pl_boot:
	PL_START

	; avoid long pause

	PL_W	$D4-$98,$4E75

	; decryption fix (thanks Marble Madness Derek's patch)

	PL_L	$13F0-8,$2F3C00FC
	PL_L	$13F0-4,$00004E71
	PL_L	$13F0,$4E714E71
	PL_W	$13F0+4,$4E71

	PL_L	$142C-8,$2F3C00FC
	PL_L	$142C-4,$00004E71

	PL_L	$1464-8,$2F3C00FC
	PL_L	$1464-4,$00004E71

	PL_L	$1482-8,$2F3C00FC
	PL_L	$1482-4,$00004E71

	PL_L	$1498-8,$2F3C00FC
	PL_L	$1498-4,$00004E71

	; patch decrypted protection check

	PL_PS	$1154,_protect

	PL_END


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

;============================================================================

	INCLUDE	osemu:kick13.s

;============================================================================

	END

