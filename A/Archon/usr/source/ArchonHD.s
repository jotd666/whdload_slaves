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
	INCLUDE	lvo/graphics.i

	IFD BARFLY
	OUTPUT	"Archon.slave"
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
; $1DADA: jsr protect

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

slv_name		dc.b	"Archon",0
slv_copy		dc.b	"1985 Electronic Arts",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Thanks to Ungi for original disk image",10,10
		dc.b	"Version 1.2 "
		INCBIN	"T:date"
		dc.b	0
slv_CurrentDir:
	dc.b	0

	EVEN

;============================================================================
;============================================================================

_bootblock:
	movem.l	a0-a2/a6/d0-d1,-(A7)

	patch	$100,_new_doio

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
	moveq.l	#0,D5
	moveq.l	#0,D7
	moveq.l	#0,D0
	rts


_protect:
	move.l	(4,A7),A0

	movem.l	D0-D1/A0-A2,-(A7)

	move.w	#$4E75,$24C-$210(A0)	; remove wait
	bsr	_patch_gfxbase
	movem.l	(A7)+,D0-D1/A0-A2
	bsr	_flushcache
	jmp	(A0)

_patch_gfxbase:
	lea	.gfxname(pc),a1
	move.l	$4.w,a6
	moveq	#0,D0
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,A0
	add.w	#_LVOFreeSprite+2,a0
	lea	_freesprite_save(pc),a1
	move.l	(a0),(a1)
	lea	_freesprite(pc),a1
	move.l	a1,(a0)
	rts

.gfxname:
	dc.b	"graphics.library",0
	even

_freesprite_save:
	dc.l	0

_freesprite:
	cmp.l	#16,d0
	bcc.b	.skip
	move.l	_freesprite_save(pc),-(a7)
.skip
	rts
	
_new_doio
	cmp.l	#$1600,$2C(a1)
	beq.b	.error			; report error on track 1 (protection)
	jsr	-$1C8(a6)
	rts
.error
	moveq	#$15,D0
.loop
	move.w	#$0F0,$dff180
	btst	#6,$bfe001
	bne.b	.loop
	rts

_emulate_protection:
	move.l	#$248b5827,(A1)+
	move.l	#$a945d2e6,(A1)+
	move.l	#$4455d847,(A1)+
	move.l	#$91133e26,(A1)+
	move.l	#$12446efe,(A1)+
	move.l	#$5113de2a,(A1)+
	move.l	#$4449e8cb,(A1)+
	move.l	#$45105e2b,(A1)+
	move.l	#$a92352fb,(A1)+
	move.l	#$889452fd,(A1)+
	move.l	#$2249df46,(A1)+
	move.l	#$2923ee3b,(A1)+
	move.l	#$a4a330fe,(A1)+
	move.l	#$2289ee3b,(A1)+
	move.l	#$8a89e84b,(A1)+
	move.l	#$a225d8e6,(A1)+
	move.l	#$4545ef4b,(A1)+
	move.l	#$5488537e,(A1)+
	move.l	#$488be8ca,(A1)+
	move.l	#$22886b2b,(A1)+
	move.l	#$4a4b284b,(A1)+
	move.l	#$a549f0fe,(A1)+
	move.l	#$292330fb,(A1)+
	move.l	#$45233efa,(A1)+
	move.l	#$252528fb,(A1)+
	move.l	#$a22b3e25,(A1)+
	move.l	#$2529dee5,(A1)+
	move.l	#$8a23e845,(A1)+
	move.l	#$52a3d827,(A1)+
	move.l	#$94446b25,(A1)+
	moveq	#0,D0
	move.l	#$8D2,D1
	move.l	#$9445114A,D2
	rts

; --------------------------------------------------------------

_pl_bootblock:
	PL_START
	PL_W	$9C,$4E75	; avoid green screen + pause
	PL_END

_pl_protect:
	PL_START

	; remove protection


	PL_END
	
_pl_boot:
	PL_START

	; avoid long pause

	PL_W	$D4-$98,$4E75

	; protection

	PL_PS	$242,_emulate_protection

	; decryption fix (thanks Marble Madness Derek's patch)

	PL_L	$1080,$2F3C00FC
	PL_L	$1084,$00004E71
	PL_L	$1088,$4E714E71
	PL_W	$108C,$4E71

	PL_L	$10BC,$2F3C00FC
	PL_L	$10C0,$00004E71

	PL_L	$10F4,$2F3C00FC
	PL_L	$10F8,$00004E71

	PL_L	$1112,$2F3C00FC
	PL_L	$1116,$00004E71

	PL_L	$1128,$2F3C00FC
	PL_L	$112C,$00004E71

	PL_L	$2E80,$4EB80100

	; patch decrypted protection check

	PL_P	$560,_protect

	PL_END

;============================================================================


;============================================================================

	END

