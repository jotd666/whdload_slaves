;*---------------------------------------------------------------------------
; Program:	Hacker.s
; Contents:	Slave for "Hacker" (c) 1985 Activision
; Author:	Codetapper & JOTD
; History:	26.01.05 - v1.0
;		         - initial release
;		         - disk protection removed (Codetapper)
;		         - program decrypted (Codetapper)
;		         - KickEmu adaptation & trackdisk device bug fixed (JOTD)
;		         - quick solution included
;		         - source code included
;		         - RomIcon, NewIcon and OS3.5 Colour icon added (Codetapper)
; Requires:	WHDLoad 16+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		INCLUDE	lvo/dos.i

		IFD BARFLY
		OUTPUT	"Hacker.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
NUMDRIVES	= 1
WPDRIVES	= %1111

;BLACKSCREEN
BOOTBLOCK
;BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG
DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT	= 8
;HDINIT
;HRTMON
;IOCACHE		= 1024
;MEMFREE	= $10000
;NEEDFPU
;POINTERTICKS	= 1
;SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;======================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D

;======================================================================

		INCLUDE	whdload/kick13.s

;======================================================================


DECL_VERSION:MACRO
	dc.b	"1.0"
	ENDM

slv_CurrentDir	dc.b	0
slv_name	dc.b	"Hacker",0
slv_copy	dc.b	"1985 Activision",0
slv_info	dc.b	"Installed by Codetapper & JOTD",10
		dc.b	"Version "
		IFD BARFLY
		DECL_VERSION
		dc.b	" "
		IFND	.passchk
		DOSCMD	"WDate >T:date"
.passchk
		ENDC
		INCBIN	"T:date"
		ELSE
		dc.b	"(26.01.2005)"
		ENDC
		dc.b	-1,"Thanks to Carlo Pirri for the original!"
		dc.b	0
		EVEN


	dc.b	"$","VER: slave "
	DECL_VERSION
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
		dc.b	$A,$D,0

;======================================================================

_bootblock
	movem.l	a0-a2/a6/d0-d1,-(A7)

	;get tags
	lea	(tag,pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Control,a2)


	lea	pl_bootblock(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2

	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/a6/d0-d1
	jsr	($C,a4)
	movem.l	a0-a2/a6/d0-d1,-(A7)

	move.l	a0,a1
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,a0-a2/a6/d0-d1
	moveq.l	#0,D0
	rts

pl_bootblock
	PL_START
	PL_W	$46,$4E71
	PL_PS	$48,boot
	PL_END

;======================================================================

boot
	movea.l	(4).w,a6
	jsr	_LVODoIO(a6)	; stolen

	move.l	8(sp),a0		;Boot file is encrypted
	bsr	decrypt_boot		;so this will decrypt it!

	rts


pl_boot		
		PL_START
		PL_S	$0,$430			;Skip decryption
		PL_P	$4a6,_wrongver		;Error occurred
		PL_P	$4de,patch_game		;Game erases copy protection so we can use this to patch the game
		PL_W	$5c2,$7000		;Checksum was OK (game does decrypt ok but the check thinks the serial is wrong? So it's skipped)
		PL_W	$524,$7200		;moveq #MEMF_PUBLIC,d0 -> moveq #MEMF_PUBLIC,d1
		PL_R	$67a			;Don't step to track 20, read MFM etc
		;PL_L	$692,$4e714e71		;Step to track 20 (causes crash)
		PL_S	$542,$84-$42		;Read MFM
		PL_PS	$584,set_decrypt_key	;Setup decryption loop
		PL_R	$6ae			;Start of reading MFM
		PL_END

;======================================================================

; called instead of copy-protection erasure, just before game

; +$519E read disk and search for 'Gene' PC=$100F6

patch_game
		movem.l	d0-d1/a0-a2,-(sp)
		move.l	a0,a1
		lea	pl_game_unregged(pc),a0
		move.l	key_enabled(pc),d0
		beq.b	.sk
		lea	pl_game(pc),a0
.sk
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		moveq	#0,d5
		moveq	#0,d7

		rts

pl_game
		PL_START
		PL_PS	$15D6,read_ddf00a	; mouse
		PL_NEXT	pl_game_common

pl_game_unregged
		PL_START
		PL_PS	$15D6,fake_read_ddf00a	; fake mouse routine
		PL_NEXT	pl_game_common

pl_game_common
		PL_START
		PL_S	$22,$2e-$22		; skip SR stuff, lethal for a 68010+
;		PL_I	$1172
;		PL_I	$10c4
		PL_END

; wrong address to read mouse port fixed

read_ddf00a
	move.w	$dff00a,d0
	rts

;======================================================================

; if some lamer changes this code he'll have a nice surprise!

fake_read_ddf00a
set_decrypt_key	
	move.l	#$17a7d,d0		;Key used to decrypt game
	rts

;======================================================================

decrypt_boot
		movem.l	d0-d7/a0-a6,-(sp)
		move.l	a0,a5

		move.w	#$7CD,d0
		move.l	d0,-(sp)
		lea	$c(a5),a0		;lea	(lbC01000C,pc),a0
		move.l	a0,-(sp)
;lbC01000C
		move.l	(4,sp),d0
		movea.l	(sp),a0
		movea.l	a0,a1
		adda.w	#$25,a1
.Dec_18		move.b	(a0)+,d1
		move.b	(a1)+,d2
		eor.b	d1,d2
		eor.b	d2,(a1)
		dbra	d0,.Dec_18

		subi.l	#$26,(4,sp)
		addi.l	#$26,(sp)
		move.l	(4,sp),d0
		movea.l	(sp),a0
		move.l	(4,sp),d0
		movea.l	(sp),a0
		movea.l	a0,a1
		adda.w	#$25,a1
.Dec_44		move.b	(a0)+,d1
		move.b	(a1)+,d2
		eor.b	d1,d2
		eor.b	d2,(a1)
		dbra	d0,.Dec_44

		move.l	#26-1,d7		;This same decryption loop
						;is in the game 26 times
.Dec_Main	subi.l	#$26,(4,sp)
		addi.l	#$26,(sp)
		move.l	(4,sp),d0
		movea.l	(sp),a0
		movea.l	a0,a1
		adda.w	#$25,a1
.Dec_6A		move.b	(a0)+,d1
		move.b	(a1)+,d2
		eor.b	d1,d2
		eor.b	d2,(a1)
		dbra	d0,.Dec_6A

		dbf	d7,.Dec_Main		;Decrypt again and again...
		movea.l	(sp)+,a0
		move.l	(sp)+,d0

		movem.l	(sp)+,d0-d7/a0-a6
		rts

;======================================================================

tag		dc.l	WHDLTAG_Private3
key_enabled	dc.l	0
		dc.l	0

_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
