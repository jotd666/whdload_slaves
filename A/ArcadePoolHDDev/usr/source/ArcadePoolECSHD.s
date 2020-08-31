;*---------------------------------------------------------------------------
;  :Program.	ArcadePoolAGAHD.asm
;  :Contents.	Slave for "ArcadePoolAGA"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ArcadePoolECSHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	IFD BARFLY
	OUTPUT	"ArcadePoolECS.slave"
	ENDC

;============================================================================

;DEBUG

	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC

	include	"ArcadePoolXXXHD.asm"

patch_boot
	; ECS
	lea	$FD800,a5
patch_memory:
	moveq.l	#1,d0
	rts

patch_1_v1
	move.l	16(A0),A1	; extbase
	move.l	a1,-(a7)
	lea	pl_patch_1_v1(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,a0
	jmp	(A0)

pl_patch_1_v1
	PL_START
	PL_P	$32E2,read_sectors
	; install cache flush
	PL_P	$2DF4,setint3_1
	PL_P	$2DFE,setint3_2
	PL_END

patch_1_v2
	move.l	16(A0),A1	; extbase
	move.l	a1,-(a7)
	lea	pl_patch_1_v2(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,a0
	jmp	(A0)

pl_patch_1_v2
	PL_START
	PL_P	$330E,read_sectors
	; install cache flush
	PL_P	$2E14,setint3_1
	PL_P	$2E1E,setint3_2
	PL_END
