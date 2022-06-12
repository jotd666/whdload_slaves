;*---------------------------------------------------------------------------
;  :Program.	ArcadePoolXXXHD.asm
;  :Contents.	Slave for "Arcade Pool" floppy
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ArcadePoolAGAHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

NUMDRIVES	= 1
WPDRIVES	= %1111

BOOTBLOCK
DISKSONBOOT

;INITAGA
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
CACHE

	IFD	AGA
XTRA_FLAGS = WHDLF_ReqAGA
	ELSE
XTRA_FLAGS = 0
	ENDC

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_ClearMem|XTRA_FLAGS
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC



DECL_VERSION:MACRO
	dc.b	"3.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"Arcade Pool "
	IFD	AGA
			dc.b	"AGA"
	ELSE
			dc.b	"ECS"
	ENDC
	
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1994 Team 17",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0
	EVEN

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

	lea	(-$400,a5),a1
		
	move.l	$DC6(A1),d0
	cmp.l	#$48E77FFC,D0
	bne	.v2

.v1
	lea	pl_v1(pc),a0
	bra.b	.p
.v2
	move.l	$DEC(A1),d0
	cmp.l	#$48E77FFC,D0
	bne.b	.wrongver

	lea	pl_v2(pc),a0
	bra.b	.p

.wrongver
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.p
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,a0-a2/a6/d0-d1
	jmp	(a5)


pl_bootblock:
	PL_START
	PL_R	$32
	PL_P	$34,patch_boot
	PL_END

pl_v1
	PL_START
	PL_P	$DC6,read_sectors
	PL_P	$826,patch_memory
	PL_PS	$48A,patch_1_v1
	PL_END

pl_v2
	PL_START
	PL_P	$DEC,read_sectors
	PL_P	$826,patch_memory
	PL_PS	$48A,patch_1_v2
	PL_END

setint3_1:
	bsr	_flushcache
	move.l	A0,$6C.W
	rts	
setint3_2:
	bsr	_flushcache
	move.l	(2,A0),$6C.W
	rts	

decrunch:
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts

read_sectors
	movem.l	d1-d2/a0-a2,-(A7)

	sub.w	#$4,D1			; -4 12 sectored tracks + 4 11 sectored tracks

	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.readnothing		; length=0: out

	exg.l	d0,d2
	addq.l	#1,d2	; disk number

	exg.l	d0,d1

	ext.l	d0
	lsl.l	#7,d0
	lsl.l	#2,d0			;offset
	ext.l	d1
	lsl.l	#7,d1			;size
	lsl.l	#2,d1
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
.readnothing
	movem.l	(a7)+,d1-d2/a0-a2
	moveq	#0,d0
	rts


tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0


