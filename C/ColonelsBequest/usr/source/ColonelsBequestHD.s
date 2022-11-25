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

	IFD BARFLY
	OUTPUT	"ColonelsBequest.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


; in chipmem:
; protenum $D572A.W, clickedenum $CCA66.W, check in $C0068
; disk required: A4-$66BA, lock loop $B59CC

;============================================================================

;CHIPMEMSIZE	= $180000
;FASTMEMSIZE	= $0000
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $C0000

BLACKSCREEN

;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
IOCACHE = 50000

;============================================================================


PATCH_SOUND = 1

;============================================================================

	include	"sierra_hdinit.s"

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"Colonel's Bequest",0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"Adapted & fixed by JOTD",10,10
		dc.b	"Thanks to Ungi/XBody/Tony Aksnes for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

	EVEN

; < d1 seglist APTR
; use _get_section to compute segments

_specific_patch

	; section 36:protection

	move.w	#36,d2
	bsr	_get_section
	add.l	#$B70,a0
	move.w	#$4EB9,(a0)+
	pea	_crack(pc)
	move.l	(a7)+,(a0)

	moveq	#0,d0
	rts


_crack:
	movem.l	d0-d1/a0-a2,-(a7)
	cmp.l	#'tify',-$10(a3)
	bne.b	.skip
	lea	_counter(pc),a0
	addq.l	#1,(a0)
	cmp.l	#2,(a0)
	bne.b	.skip

	; select celie and tell this is the celie fingerprint

;;;;	clr.w	6(a3)	; 0-11 celie,...

	clr.w	(a3)	; 0-3 celie,ethelprune,drfeels,sparrow
	clr.w	(a2)	; 0: celie
.skip
	movem.l	(a7)+,d0-d1/a0-a2

	; original code
	move.w	(a3),d0
	addq.w	#2,a2
	move.w	D0,(a2)
	rts

_counter:
	dc.l	0

