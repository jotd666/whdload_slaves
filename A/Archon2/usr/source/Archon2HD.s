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
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"Archon2.slave"
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
BOOTBLOCK
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s



;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

slv_name		dc.b	"Archon II: Adept",0
slv_copy		dc.b	"1986 Electronic Arts",0
slv_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"Version 1.1 "
		INCBIN	"T:date"
		dc.b	0
slv_CurrentDir:
	dc.b	0
	EVEN

;============================================================================
	;initialize kickstart and environment

_bootblock:
	movem.l	a0-a2/a6/d0-d1,-(A7)
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
	move.l	_resload(pc),a2
	lea	_pl_protect(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(A7)+,D0-D1/A0-A3
	jmp	(A1)


_emulate_protect:
	; A1 = $5FD0

	move.l	#$4,(A1)
	move.l	#$2,4(A1)
	move.l	#$1,8(A1)
	move.l	#$1,12(A1)

;;	move.l	#$ff,112(a1)
	move.l	#$30050,324(a1)	; without it: access fault

;	move.l	#$f70000,352(a1)
;	move.l	#$81e0000,592(a1)
;	move.l	#$33420105,596(a1)

	rts

; --------------------------------------------------------------

_pl_bootblock:
	PL_START
	PL_W	$9C,$4E75	; avoid green screen + pause
	PL_END

_pl_protect:
	PL_START
	; replace protection call by memory patch
	; (if not present, needs any DOS disk in drive to work)
	
	PL_PS	$F0,_emulate_protect

	; remove protection (part of floppy crack)

	PL_L	$FC,$42280013
	PL_W	$100,$6010
	PL_W	$22C,$600A
	PL_L	$286,$2D7C0000
	PL_L	$28A,$04E1FFF4
	PL_W	$28E,$2000

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


;============================================================================


;============================================================================

	END

