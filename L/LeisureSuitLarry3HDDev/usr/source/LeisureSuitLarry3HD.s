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
	OUTPUT	"LeisureSuitLarry3.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


;;CHIP_ONLY


    IFD CHIP_ONLY
CHIPMEMSIZE	= $120000
FASTMEMSIZE	= $0000
HRTMON
    ELSE
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $80000
    ENDC
    
IOCACHE = 50000

;
;SETPATCH

;============================================================================

PATCH_KEYBOARD = 1     ; seems to crash the game!
PATCH_MT32 = 1

CRACKIT = 1

; expmem+A0C1A: workout counters

;============================================================================

	include	"sierra_hdinit.s"
   
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
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

slv_name		dc.b	"Leisure Suit Larry 3"
    IFD CHIP_ONLY
    dc.b    "(DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1990 Sierra",0
slv_info		dc.b	"Adapted & fixed by JOTD",10,10
			dc.b	"Thanks to BTTR & Hubert for disk images",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
			even

_rename_file:
    rts
    
; german version 5 disks: Section 4: move D0,(A3) code around 36A8 => 43CC or 460C
; < d1 seglist APTR
; use _get_section to compute segments

_specific_patch
	; section 37:protection
    add.l   d1,d1
    add.l   d1,d1
    
	move.w	#37,d2
	bsr	_get_section
	move.l	a0,a3
	add.l	#$AC8,a0

	; ticket number crack

	cmp.w	#$3013,(a0)
	beq.b	.v1

	; try v2

	move.w	#36,d2
	bsr	_get_section
	move.l	a0,a3
	add.l	#$AC8,a0

	; ticket number crack

	cmp.w	#$3013,(a0)
	beq.b	.v2

	; try german

	move.w	#4,d2
	bsr	_get_section
	move.l	a0,a3
	add.l	#$04320-$036a8,a0
	cmp.w	#$3013,(a0)
    beq   .v3
	; unknown



	bra	_wrong_version

	; --------------------------
	; VERSION #1
	; --------------------------

.v1
	IFD	CRACKIT

	lea	_saved_offset(pc),a1
	move.w	4(a0),(a1)

	; ---------------------------
	;    ticket number crack
	; ---------------------------

	move.w	#$4EB9,(a0)+
	pea	_crack_1_v1(pc)
	move.l	(a7)+,(a0)
	
	move.l	a3,a0
	add.l	#2718,a0

	; ---------------------------
	;     locker combo crack
	; ---------------------------

	move.w	#$4EB9,(a0)+
	pea	_crack_2_v1(pc)
	move.l	(a7)+,(a0)
	ENDC

	bra.b	.out

	; --------------------------
	; VERSION #2
	; --------------------------

.v2
	lea	_saved_offset(pc),a1
	move.w	4(a0),(a1)

	IFD	CRACKIT

	; ---------------------------
	;    ticket number crack
	; ---------------------------

	move.w	#$4EB9,(a0)+
	pea	_crack_1_v2(pc)
	move.l	(a7)+,(a0)
	
	move.l	a3,a0
	add.l	#2718,a0

	; ---------------------------
	;     locker combo crack
	; ---------------------------

	move.w	#$4EB9,(a0)+
	pea	_crack_2_v2(pc)
	move.l	(a7)+,(a0)
	bra	.out
	ENDC

.v3
    lsr.l #2,d1
    move.l  d1,a1   ; BPTR
    lea pl_v3(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_PatchSeg,a2)
    
.out
	moveq.l	#0,d0
	rts

pl_v3
    PL_START
    PL_PS   $03d3a,_crack_1_v3
    PL_END
    
; previous cracks have been done in 2003 by me, but I completely forgot how I did that, on a real amiga, without
; memory watches :)
;
; so now that I'm old and not that patient, I used a different method. The password is stored as a 16-bit number
; so if you know the proper password, it's easy to search for that number in memory. Also enter things like 57005
; and look for $DEAD
; with an emulator, use memwatches
; the game accesses the entered value to copy it somewhere else (first memwatch), then watch the value where it's copied
; and it takes you directly where the value is compared to the proper value
;
; for the locker part, same thing: I don't remember how I did at all (not to mention that the code / sections
; are completely different so it's out of the question to adapt old cracks)
; I figured out that the proper combination is stored as 3 consecutive 16-bit digits. Ex if the code is 17 19 12
; in memory you'll find $0011 $0013 $000C. It's at 2 locations in the memory, so it's not too difficult (the code is checked on
; then highest location of the 2)
; If you search your entered combination (after 2 enters, so the game doesn't start
; the check yet) you find the 2-number sequence somewhere else.
; anyway, the test ends up at the exact same location as the first protection
 
_crack_1_v3:
    MOVE.W  -28996(A4),D2           ;03d3a: 342c8ebc    ; expected code
    cmp.l   #'My p',$44(a2)
    bne   .no_part_1
    
    ; make sure that it's the proper section, filter anything that isn't a real code
    ; just to avoid possible side effects
    cmp.w   #00741,d2
    beq.b   .ok
    cmp.w   #55811,d2
    beq.b   .ok
    cmp.w   #30004,d2
    beq.b   .ok
    cmp.w   #18608,d2
    beq.b   .ok
    cmp.w   #32841,d2
    beq.b   .ok
    cmp.w   #00993,d2
    beq.b   .ok
    cmp.w   #09170,d2
    beq.b   .ok
    cmp.w   #49114,d2
    beq.b   .ok
    cmp.w   #33794,d2
    beq.b   .ok
    cmp.w   #54482,d2
    beq.b   .ok
    cmp.w   #62503,d2
    bne.b   .no_part_1
.ok
    move.w  D2,(A2)     ; store proper code in user input
    bra   .orig
.no_part_1
    cmp.l   #"lly ",$20(a2)
    bne   .orig
    ; part 2
    ; make sure that it's the proper section, filter anything that isn't a real code
    ; just to avoid possible side effects (although those values aren't too specific...)
    cmp.w   #02,d2   
    beq.b   .ok2
    cmp.w   #08,d2
    beq.b   .ok2
    cmp.w   #09,d2
    beq.b   .ok2
    cmp.w   #10,d2
    beq.b   .ok2
    cmp.w   #12,d2
    beq.b   .ok2
    cmp.w   #13,d2
    beq.b   .ok2
    cmp.w   #16,d2
    beq.b   .ok2
    cmp.w   #17,d2
    beq.b   .ok2
    cmp.w   #18,d2
    beq.b   .ok2
    cmp.w   #19,d2
    beq.b   .ok2
    cmp.w   #23,d2
    beq.b   .ok2
    cmp.w   #24,d2
    bne.b   .no_part_2
.ok2
    move.w  D2,(A2)     ; store proper code in user input
.no_part_2
   
.orig
    CMP.W   (A2),D2                 ;03d3e: b452
    rts


_crack_1_v1
	movem.l	d1,-(a7)

	move.l	a3,d1
	btst	#0,d1
	bne.b	.nocrk	; A3 must be even

	; ticket number crack
	;
	; signature "try one ..."

	cmp.l	#'try ',-$B4(a3)
	bne.b	.nocrk
	cmp.l	#'one ',-$B0(a3)
	bne.b	.nocrk
	move.w	#$000F,(A3)		; page 15
	cmp.l	#'My p',$44(a2)
	bne.b	.nocrk
	move.w	#$23D2,(A2)		; valid code for page 15
.nocrk
	move.w	(a3),d0

	move.w	_saved_offset(pc),d1
	move.w	d0,(a4,d1.W)
	movem.l	(a7)+,d1
	rts



_crack_1_v2
	movem.l	d1,-(a7)

	move.l	a3,d1
	btst	#0,d1
	bne.b	.nocrk	; A3 must be even

	; ticket number crack
	;
	; signature "pass on "

	cmp.l	#'pass',-248(a3)
	bne.b	.nocrk
	cmp.l	#' on ',-244(a3)
	bne.b	.nocrk

	cmp.l	#'My p',$44(a2)
	bne.b	.nocrk

	move.w	#$000F,(A3)		; page 15

	move.w	#$23D2,(A2)		; valid code for page 15
.nocrk
	move.w	(a3),d0

	move.w	_saved_offset(pc),d1
	move.w	d0,(a4,d1.W)
	movem.l	(a7)+,d1
	rts

_crack_2_v1
_crack_2_v2
	movem.l	d1,-(a7)

	move.l	a3,d1
	btst	#0,d1
	bne.b	.nocrk	; A3 must be even

	; locker combo crack
	;
	; signature

	tst.w	(a3)
	beq.b	.nocrk
	cmp.l	#'Ente',-$5E(a2)
	bne.b	.nocrk

	move.l	-$138(a3),d1
	cmp.l	#'rmal',d1
	beq.b	.crk
	cmp.l	#'alBa',d1
	beq.b	.crk
	cmp.l	#'Base',d1
	beq.b	.crk
	bra.b	.nocrk
.crk
	move.w	#$0001,(A2)
	move.w	#$0001,(A3)
.nocrk
	move.w	(a3),d0

	move.w	_saved_offset(pc),d1
	move.w	d0,(a4,d1.W)
	movem.l	(a7)+,d1
	rts

_saved_offset
	dc.w	0
