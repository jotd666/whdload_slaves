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
	OUTPUT	"PoliceQuest2.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;CHIPMEMSIZE	= $180000
;FASTMEMSIZE	= $0000
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $C0000

;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
SAVEDISK_NUMBER = 4
BLACKSCREEN

;============================================================================
    IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
    ENDC
    
;============================================================================

	include	"sierra_trackdisk.s"

_name		dc.b	"Police Quest 2",0
_copy		dc.b	"1990 Sierra",0
_info		dc.b	"Adapted & fixed by JOTD",10,10
		dc.b	"Thanks to BTTR for disk images",10,10
		dc.b	"Thanks to Vision Factory for the crack",10,10
		dc.b	"Version 1.0 "
		;INCBIN	"T:date"
		dc.b	0
	EVEN

; < d1 seglist APTR
; use _get_section to compute segments

_specific_patch
	patch	$100,_crack

	move.l	#0,d2
	bsr	_get_section
	cmp.w	#$4EF9,(a0)
	bne.b	.packed		; crack exe (BTTR) is packed with imploder
	move.l	#18,d2
	bsr	_get_section
	add.l	#$1C18-$29C,a0
	move.l	#$4EB80100,(a0)

	moveq.l	#0,d0
	rts
.packed
	add.l	#$36,a0
	move.w	#$4EF9,(a0)+
	pea	_flush_and_jump(pc)
	move.l	(a7)+,(a0)

	; don't patch anything

	moveq.l	#1,d0
	rts

_flush_and_jump
	; after imploder decrunch

	move.l	$3C(a7),d1	; get return address
	subq.l	#4,d1

	; apply generic patches

	bsr	_generic_patches

	; cache flush

	bsr	_flushcache
	movem.l	(a7)+,d0-a6
	rts

; thanks to Vision Factory, this is a smart crack

_crack:
	movem.l	a0,-(a7)
	lea	_counter(pc),a0
	tst.w	(a0)
	bne.b	.cracked
	MOVE	#$0001,(a0)
	CLR	-26656(A4)
	BRA.S	.out
.cracked
	MOVE	D0,-26656(A4)
.out
	movem.l	(a7)+,a0
	RTS

_counter:
	dc.l	0
