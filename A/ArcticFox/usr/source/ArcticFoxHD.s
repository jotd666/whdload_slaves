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
BOOTBLOCK

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

slv_CurrentDir:
	dc.b	0

DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name		dc.b	"Arctic Fox",0
slv_copy		dc.b	"1985 Electronic Arts / Dynamic",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
	EVEN

;============================================================================

_bootblock:
	movem.l	a0-a2/a6/d0-d1,-(A7)

	move.l	_resload(pc),a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;kb fix

	lea	_pl_bootblock(pc),a0
	move.l	a4,a1
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
	bne.b	.skip1
	move.w	#$4EB9,$F0(A1)
	pea	_emulate_protect(pc)
	move.l	(A7)+,$F2(A1)
	ifeq	1
	move.l	-$268(A1),a1
	move.l	_resload(pc),a2
	lea	_pl_protect(pc),a0
	jsr	resload_Patch(a2)
	endc
	bra.b	.out
.skip1
	move.l	a1,a0
	add.l	#$E412-$3770,a0
	cmp.l	#$DFF00A,(A0)
	bne.b	.out

	move.l	$48C(a1),a0
	move.w	#$4E75,$89C(A0)	; remove delay (2)

	
	move.l	_custom1(pc),d0	; CUSTOM1!=0: replace port 0 by port 1
	beq.b	.out

	move.l	_resload(pc),a2
	lea	_pl_joystick(pc),a0
	jsr	resload_Patch(a2)
	
.out
	movem.l	(A7)+,D0-D1/A0-A3
	bsr	_flushcache
	jmp	(A1)

_new_doio
	cmp.l	#$1600,$2C(a1)
	beq.b	.error			; report error on track 1 (protection)
	jsr	_LVODoIO(a6)	; -$1C8
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

_get_button_d1:
	move.b	$BFE001,d1
	btst	#7,d1
	beq.b	.fire
	rts
.fire
	bclr	#6,d1
	rts

_get_button_d0:
	move.b	$BFE001,d0
	btst	#7,d0
	beq.b	.fire
	rts
.fire
	bclr	#6,d0
	rts

; --------------------------------------------------------------

_pl_bootblock:
	PL_START
	PL_R	$9C	; avoid green screen + pause
	PL_END

_pl_joystick
	PL_START

	; replace joystick input, port 0 by port 1

	PL_L	$E412-$3770,$DFF00C
	PL_L	$E55C-$3770,$DFF00C
	PL_PS	$E51A-$3770,_get_button_d1
	PL_PS	$E5BE-$3770,_get_button_d0
	PL_W	$E53A-$3770,$E
	PL_END

	ifeq	1
_pl_protect:
	PL_START

	PL_L	$13F54-$12BB8,$4EB80100

	PL_END
	endc

_pl_boot:
	PL_START

	; avoid long pause

	PL_R	$D4-$98

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


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END

