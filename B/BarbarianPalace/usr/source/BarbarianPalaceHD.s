;*---------------------------------------------------------------------------
; Program:	BarbarianPalace.s
; Contents:	Slave for "Barbarian" (c) 1988 Palace
; Author:	Codetapper of Action
; History:	07.01.04 - v1.0
;		         - Full load from HD
;		         - Copy protection removed (encryption/checksum/disk check)
;		         - Access faults fixed (x2)
;		         - RomIcon, NewIcon and OS3.5 Colour Icons (created by Frank and myself!) 
;		           and 2 Exoticons (taken from http://exotica.fix.no)
;		         - Quit option (default key is 'F10')
; Requires:	WHDLoad 17+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Info:		There is a hidden trainer option available by setting the
;		CUSTOM1 tooltype. Set bit 0 for invulnerability to player 1
;		and set bit 1 for invulnerability to player 2:
;
;		CUSTOM1=0 = %00 = Normal
;		CUSTOM1=1 = %01 = Only player 1 invulnerable
;		CUSTOM1=2 = %10 = Only player 2 invulnerable
;		CUSTOM1=3 = %11 = Both players invulnerable
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		INCLUDE	lvo/dos.i

		IFD BARFLY
		OUTPUT	"BarbarianPalace.slave"
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
FASTMEMSIZE	= 0
NUMDRIVES	= 1
WPDRIVES	= %1111

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG
;DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT	= 8
HDINIT
;HRTMON
IOCACHE		= 10240
;MEMFREE	= $100
;NEEDFPU
POINTERTICKS	= 1
;SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;======================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5d

;======================================================================

		INCLUDE	whdload/kick13.s

;======================================================================
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Barbarian",0
slv_copy	dc.b	"1988 Palace",0
slv_info	dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1,"Keys: F1 - 1 player game    F2 - 2 player game"
		dc.b	10,"      F3 - Pause/Unpause   F10 - Quit game    "
		dc.b	-1,"Greetings to Mark Knibbs and Frank!"
		dc.b	0
slv_config:
        dc.b    "C1:X:Trainer Infinite lives player 1:0;"
        dc.b    "C1:X:Trainer Infinite lives player 2:1;"
		dc.b	0
_program	dc.b	"main",0
_args		dc.b	10
_args_end	dc.b	0
_FailedLoadMsg	dc.b	"Failed to load the file main!",10,"Check it is a standard Amiga executable",10,"and hasn't been compressed!",0
		EVEN

;======================================================================

_bootdos	lea	_saveregs(pc),a0
		movem.l	d1-d6/a2-a6,(a0)
		move.l	(a7)+,(44,a0)

		lea	_Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		lea	(_dosname,pc),a1	;Open dos.library
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		lea	(_dosbase,pc),a0
		move.l	d0,(a0)
		move.l	d0,a6			;A6 = dosbase

	;check version
		lea	(_program,pc),a0
		move.l	a0,d1
		move.l	#MODE_OLDFILE,d2
		jsr	(_LVOOpen,a6)
		move.l	d0,d1
		beq	.end
		move.l	#3516,d3
		sub.l	d3,a7
		move.l	a7,d2
		jsr	(_LVORead,a6)
		move.l	d3,d0
		move.l	a7,a0
		move.l	(_resload,pc),a2
		jsr	(resload_CRC16,a2)
		add.l	d3,a7
		
		cmp.w	#$3eb9,d0
		bne	_wrongver

		lea	_program(pc),a0		;Load exe
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_failedtoload		;bra .end

		bsr	_DecryptBoot

		lea	_PL_Boot(pc),a0		;Patch game
		move.l	d7,a1
		move.l	_resload(pc),a2
		jsr	resload_PatchSeg(a2)

	IFD DEBUG
		clr.l	-(a7)			;set debug
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

		move.l	d7,a1			;Start game
		add.l	a1,a1
		add.l	a1,a1
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		movem.l	(_saveregs,pc),d1-d6/a2-a6
		jsr	(4,a1)

	IFD QUIT_AFTER_PROGRAM_EXIT
		pea	TDREASON_OK
		jmp	(resload_Abort,a2)
	ELSE
		move.l	d7,d1			;Remove EXE
		move.l	(_dosbase,pc),a6
		jsr	(_LVOUnLoadSeg,a6)
	ENDC

.end		moveq	#0,d0
		move.l	(_saverts,pc),-(a7)
		rts

_PL_Boot	PL_START
		PL_S	$4,$40-$4		;Skip decryption
		PL_L	$94,$4e714e71		;Don't setup protect process
		PL_PS	$c0,_Game		;Patch game: move.l ($10,a0),d0 and addq.l #8,d0
		PL_L	$462,$203c0000		;Wire checksum (move.l #$afcb,d0 and eor.l d0,d1)
		PL_L	$466,$afcbb181
		PL_L	$46a,$4e714e71
		PL_L	$46e,$4e714e71
		PL_END

	EVEN

_saveregs	ds.l	11
_saverts	dc.l	0
_dosbase	dc.l	0
_GameAddress	dc.l	0
		EVEN

;======================================================================

_Game		move.l	($10,a0),d0		;Stolen code
		addq.l	#8,d0

		movem.l	d0-d1/a0-a2,-(sp)

		lea	_GameAddress(pc),a0
		move.l	d0,(a0)
		move.l	d0,a1			;a1 = Game load address

		move.l	_Custom1(pc),d1		;Check for hidden trainer
		btst	#0,d1			;options
		beq	.CheckTrainerP2
		move.l	#$4e714e71,$4afa(a1)

.CheckTrainerP2	btst	#1,d1
		beq	.NoTrainerP2
		move.l	#$4e714e71,$4ae6(a1)

.NoTrainerP2	lea	_PL_Game(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2
		rts

_PL_Game	PL_START
		PL_PS	$589a,_Fix_1		;Access fault
		PL_PS	$5982,_Fix_1		;Access fault
		PL_PS	$76ba,_Fix_1		;Access fault
		PL_PS	$21e38-$1c498,_Fix_2	;Access fault
		PL_END

;======================================================================

_Fix_1		movea.l	a0,a1
		adda.l	d1,a1
		movea.l	(a1),a2
		bra	_FixA2

_Fix_2		movea.l	(a0),a1
		bsr	_FixA1
		move.w	($18,a1),d1
		rts

;======================================================================

_FixA1		move.l	d0,-(sp)
		move.l	a1,d0
		and.l	#$7ffff,d0
		move.l	d0,a1
		move.l	(sp)+,d0
		rts

_FixA2		move.l	d0,-(sp)
		move.l	a2,d0
		and.l	#$7ffff,d0
		move.l	d0,a2
		move.l	(sp)+,d0
		rts

;======================================================================

_DecryptBoot	movem.l	d0-d7/a0-a6,-(sp)	;Decrypt the boot file

		move.l	d7,d0
		add.l	d0,d0
		add.l	d0,d0
		add.l	#4,d0
		move.l	d0,a5

		move.l	#$200,d2
		move.l	#$d58,d3
		move.l	a5,a0
		lea	$40(a5),a1
		clr.l	d0
.1a		clr.l	d1
		move.w	(a0,d0.w),d5
.20		eor.w	d5,(a1,d1.w)
		move.w	(a1,d1.w),d5
		addq.l	#2,d1
		cmp.w	d3,d1
		bne.w	.20
.30		addq.l	#2,d0
		cmp.w	#$40,d0
		beq.w	.30
		cmp.w	d2,d0
		bne.w	.1a

		movem.l	(sp)+,d0-d7/a0-a6
		rts

;======================================================================

_Tags		dc.l	WHDLTAG_CUSTOM1_GET
_Custom1	dc.l	0

		dc.l	TAG_DONE

;======================================================================

_wrongver	pea	TDREASON_WRONGVER
		bra	_end
_failedtoload	pea	_FailedLoadMsg(pc)
		pea	TDREASON_FAILMSG
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
