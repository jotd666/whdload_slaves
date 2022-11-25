;*---------------------------------------------------------------------------
; Program:	CaliforniaGames.s
; Contents:	Slave for "California Games" (c) 1988 Epyx/Westwood Associates
; Author:	Codetapper of Action
; History:	31.12.03 - v1.0
;		         - Full load from HD
;		         - Copy protection removed (Herndon HLS Duplication/encryption/disk check x2)
;		         - Loads and saves best scores
;		         - Manual included
;		         - RomIcon, NewIcon and OS3.5 Colour Icons (created by me!) and 2 Exoticons
;		           (taken from http://exotica.fix.no)
;		         - Quit option (default key is 'F10')
;       :	20.04.21 - v1.1 done by JOTD
;                - reassembled with new kickemu, fixes 68000/68010 crash
;                - uses fastmem and only 512kb chip
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
		OUTPUT	"CaliforniaGames.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================
;CHIP_ONLY
    IFD CHIP_ONLY
CHIPMEMSIZE	= $c0000
FASTMEMSIZE	= 0
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG
;DISKSONBOOT
DOSASSIGN
;FONTHEIGHT	= 8
HDINIT
;HRTMON
IOCACHE		= 10240
MEMFREE	= $100
;NEEDFPU
POINTERTICKS	= 1
;SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;======================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59

;======================================================================

		INCLUDE	whdload/kick13.s

;======================================================================

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
slv_name	dc.b	"California Games"
        IFD CHIP_ONLY
        dc.b    " (DEBUG/CHIP mode)"
        ENDC
        dc.b    0
slv_copy	dc.b	"1988 Epyx/Westwood Associates",0
slv_info	dc.b	"adapted by Codetapper & JOTD",10
		dc.b	"Version "
        DECL_VERSION
		dc.b	-1,"Thanks to Angus Manwaring for sending the original!"
		dc.b	0
_program	dc.b	"CALGAMES/CalGames",0
_args		dc.b	10
_args_end	dc.b	0
_FailedLoadMsg	dc.b	"Failed to load the file CALGAMES/CalGames!",10
    dc.b    "Check it is a standard Amiga executable",10,"and hasn't been compressed!",0
slv_config
    dc.b    0
    even
    
;======================================================================

_bootdos	lea	_saveregs(pc),a0
		movem.l	d1-d6/a2-a6,(a0)
		move.l	(a7)+,(44,a0)

		move.l	_resload(pc),a2

		move.l	(4),a6
        IFD   CHIP_ONLY
        move.l  #0,d1
        move.l #$20000-$1E300,d0
        jsr (_LVOAllocMem,a6)
        ENDC
        
		lea	(_dosname,pc),a1	;Open dos.library
		jsr	(_LVOOldOpenLibrary,a6)
		lea	(_dosbase,pc),a0
		move.l	d0,(a0)
		move.l	d0,a6			;A6 = dosbase

		lea	(_disk1,pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	(_disk2,pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	(_program,pc),a0	;Check version
		move.l	a0,d1
		move.l	#MODE_OLDFILE,d2
		jsr	(_LVOOpen,a6)
		move.l	d0,d1
		beq	.end
		move.l	#300,d3
		sub.l	d3,a7
		move.l	a7,d2
		jsr	(_LVORead,a6)
		move.l	d3,d0
		move.l	a7,a0
		move.l	(_resload,pc),a2
		jsr	(resload_CRC16,a2)
		add.l	d3,a7
		
		move.w	d0,d6
		cmp.w	#$45be,d0		;Original game
		beq	.Original

		cmp.w	#$1e88,d0		;Quartex crack
		bne	_wrongver

.Original	lea	_program(pc),a0		;Load exe
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_failedtoload		;bra .end

		cmp.w	#$1e88,d6		;Quartex crack is already
		beq	.PatchGame		;deprotected cleanly!

		bsr	_DecryptHerndon		;Bye bye protection!

.PatchGame	lea	_PL_Game(pc),a0		;Patch game
		move.l	d7,a1
		move.l	_resload(pc),a2
		jsr	resload_PatchSeg(a2)


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

_PL_Game	PL_START
		PL_NOP	$254,4		;Skip disk change
		PL_END

	EVEN

_saveregs	ds.l	11
_saverts	dc.l	0
_dosbase	dc.l	0
_disk1		dc.b	"Cal Games Program",0	;For Assign
		EVEN
_disk2		dc.b	"Cal Games Data",0	;For Assign
		EVEN

;======================================================================

_DecryptHerndon	movem.l	d0-d7/a0-a6,-(sp)	;Decrypt the fucker!

		move.l	d7,a0			;d7 = LoadSeg address
		add.l	a0,a0
		add.l	a0,a0
		add.l	#4,a0
		move.l	a0,a5			;a5 = Start of real code

		move.l	a5,a0
		add.l	#$24b08,a0
		move.l	a5,a1
		add.l	#$24b42,a1
		move.w	#$284,d1
		move.w	(a0)+,d0
		eor.w	d0,(a1)+
		subq	#1,d1			;dbra d1,.4b8

.2504e		move.w	#14,d0
.25052		not.w	(a0)+
		dbra	d0,.25052

		move.l	a5,a0
		add.l	#$24b08,a0
		move.w	#'Ca',(a0)		;California Games: assign
		
.24b3c		move.w	(a0)+,d0
		eor.w	d0,(a1)+
		dbra	d1,.24b3c

		move.l	a5,a4			;lea .25098(pc),a5 <- changed to a4
		add.l	#$25098,a4

		movea.l	a4,a0
.24b54		move.w	(a0),d0
		beq	.24b70
		movea.l	a5,a1			;movea.l $24(a5),a1
		clr.w	(a0)+
		adda.w	(a0),a1
		adda.w	(a0),a1
		clr.w	(a0)+
		subq.w	#1,d0
.24b66		move.w	(a0),(a1)+
		clr.w	(a0)+
		dbra	d0,.24b66
		bra	.24b54
.24b70
		lea	($43fc).w,a0
		move.l	#$e53aeee2,(-$43d8,a0)
		eori.l	#$2042454e,(-$43d8,a0)
		neg.l	(-$43d8,a0)

		lea	$ffff97b8,a0
		movea.w	a0,a1

		move.l	a5,a0			;lea (.24b08,pc),a0
		add.l	#$24b08,a0

		moveq	#-1,d0
		move.w	#$136,d5
		subq.w	#1,d5
.24cb2		move.w	(a0)+,d1
		moveq	#15,d4
.24cb6		moveq	#0,d2
		lsl.w	#1,d1
		roxr.w	#1,d2
		eor.w	d2,d0
		lsl.w	#1,d0
		bcc.b	.24cc8
		move.l	($686c,a1),d3
		eor.w	d3,d0
.24cc8		dbra	d4,.24cb6
		dbra	d5,.24cb2
		move.w	#$16A,d2
.24cd4		move.w	(a0)+,d1
		add.w	d0,d1
		eor.w	d1,(a0)
		dbra	d2,.24cd4

		move.l	#$3e8,d0		;Wire in correct values
		move.l	#$20,d3			;for d0 and d3

.24ecc		sub.w	d3,d0
		move.l	d0,-(sp)

		pea	($42454e44).l		;BEND (start of second bit of encryption)

		move.l	a5,a0
		add.l	#$24b08,a0

		moveq	#-1,d0
		move.w	#$2c8,d5
		subi.l	#$4244ea97,(sp)
		movea.l	(sp)+,a1
		subq.w	#1,d5
.24ef6		move.w	(a0)+,d1
		moveq	#15,d4
.24efa		moveq	#0,d2
		lsl.w	#1,d1
		roxr.w	#1,d2
		eor.w	d2,d0
		lsl.w	#1,d0
		bcc.b	.24f0c
		move.l	(-$6389,a1),d3
		eor.w	d3,d0
.24f0c		dbra	d4,.24efa
		dbra	d5,.24ef6
		move.l	(sp)+,d1
		andi.w	#$FF80,d1
		add.w	d1,d0
		neg.w	d1
		eor.w	d1,d0
		lsr.w	#8,d1
		eor.b	d1,d0

		lea	_BadSector1a00(pc),a2	;movea.l ($1A,a5),a2

		move.w	d0,d2
		moveq	#0,d0
.24f2c		move.w	(a2)+,d0
		move.w	(a2)+,d3
		beq.b	.24f50

		lea	(a5),a0			;movea.l ($24,a5),a0

		adda.l	d0,a0
		adda.l	d0,a0

		move.l	a5,a1			;lea .24b08(pc),a1
		add.l	#$24b08,a1

		subq.w	#2,d3
.24f40		move.w	(a0)+,d0
		move.b	(a1)+,d1
		eor.w	d2,d0			;d2 = $6524 in WinUAE
		eor.b	d1,d0
		eor.w	d0,(a0)
		dbra	d3,.24f40
		bra.b	.24f2c
.24f50		
.25038		move.w	#$14D,d1		;Wipes from Cal Games Program: & Ben Herndon

		move.l	a5,a0			;lea .24b08(pc),a0
		add.l	#$24b08,a0

.25040		clr.l	(a0)+
		dbra	d1,.25040

		; Here begins the second loop of this fucking shit!

		move.l	a5,a0
		add.l	#$2454c,a0
		move.l	a5,a1
		add.l	#$24586,a1
		move.w	#$284,d1
		move.w	(a0)+,d0
		eor.w	d0,(a1)+
		subq	#1,d1			;dbra d1,.4b8

.24a92		move.w	#14,d0
.24a96		not.w	(a0)+
		dbra	d0,.24a96

		move.l	a5,a0
		add.l	#$2454c,a0
		move.w	#'Ca',(a0)		;California Games: assign

.24580		move.w	(a0)+,d0
		eor.w	d0,(a1)+
		dbra	d1,.24580

		move.l	a5,a4			;lea .24adc(pc),a5 <- changed to a4
		add.l	#$24adc,a4

		movea.l	a4,a0
.24598		move.w	(a0),d0
		beq	.245b4
		movea.l	a5,a1			;movea.l $24(a5),a1
		clr.w	(a0)+
		adda.w	(a0),a1
		adda.w	(a0),a1
		clr.w	(a0)+
		subq.w	#1,d0
.245aa		move.w	(a0),(a1)+
		clr.w	(a0)+
		dbra	d0,.245aa
		bra	.24598
.245b4
.24588		lea	($43fc).w,a0
		move.l	#$c556f2b6,(-$43d8,a0)
		eori.l	#$2042454e,(-$43d8,a0)
		neg.l	(-$43d8,a0)

		lea	$ffff97b8,a0
		movea.w	a0,a1

		move.l	a5,a0			;lea (.2454c,pc),a0
		add.l	#$2454c,a0

		moveq	#-1,d0
		move.w	#$136,d5
		subq.w	#1,d5
.246f6		move.w	(a0)+,d1
		moveq	#15,d4
.246fa		moveq	#0,d2
		lsl.w	#1,d1
		roxr.w	#1,d2
		eor.w	d2,d0
		lsl.w	#1,d0
		bcc.b	.2470c
		move.l	($686c,a1),d3
		eor.w	d3,d0
.2470c		dbra	d4,.246fa
		dbra	d5,.246f6
		move.w	#$16A,d2
.24718		move.w	(a0)+,d1
		add.w	d0,d1
		eor.w	d1,(a0)
		dbra	d2,.24718

		move.l	#$3e8,d0		;Wire in correct values
		move.l	#$20,d3			;for d0 and d3

.24910		sub.w	d3,d0
		move.l	d0,-(sp)

		pea	($42454e44).l		;BEND (start of second bit of encryption)

		move.l	a5,a0			;lea .2454c(pc),a0
		add.l	#$2454c,a0

		moveq	#-1,d0
		move.w	#$2C8,d5
		subi.l	#$4244ea97,(sp)
		movea.l	(sp)+,a1
		subq.w	#1,d5
.2493a		move.w	(a0)+,d1
		moveq	#15,d4
.2493e		moveq	#0,d2
		lsl.w	#1,d1
		roxr.w	#1,d2
		eor.w	d2,d0
		lsl.w	#1,d0
		bcc.b	.24950
		move.l	(-$6389,a1),d3
		eor.w	d3,d0
.24950		dbra	d4,.2493e
		dbra	d5,.2493a
		move.l	(sp)+,d1
		andi.w	#$FF80,d1
		add.w	d1,d0
		neg.w	d1
		eor.w	d1,d0
		lsr.w	#8,d1
		eor.b	d1,d0

		lea	_BadSector1a00(pc),a2	;movea.l ($1A,a5),a2

		move.w	d0,d2
		moveq	#0,d0
.24970		move.w	(a2)+,d0
		move.w	(a2)+,d3
		beq.b	.24994

		lea	(a5),a0			;movea.l ($24,a5),a0

		adda.l	d0,a0
		adda.l	d0,a0

		move.l	a5,a1			;lea .$2454c(pc),a1
		add.l	#$2454c,a1

		subq.w	#2,d3
.24984		move.w	(a0)+,d0
		move.b	(a1)+,d1
		eor.w	d2,d0
		eor.b	d1,d0
		eor.w	d0,(a0)
		dbra	d3,.24984
		bra.b	.24970
.24994	
.24a56		move.w	#$14D,d1

		move.l	a5,a0			;lea .$2454c(pc),a0
		add.l	#$2454c,a0

.24a84		clr.l	(a0)+
		dbra	d1,.24a84

		movem.l	(sp)+,d0-d7/a0-a6
		rts

		; This is the copy protection sector which is also 
		; duplicated at $2800 (but which is identical)

_BadSector1a00	dc.l	$3002F,$3B0008,$4C0005,$650006
		dc.l	$7A000E,$8A0011,$9D0012,$B10029
		dc.l	$EF0036,$1270006,$12F0151,$2920031
		dc.l	$2D50019,$2F0000E,$3090066,$37B01AE
		dc.l	$52E0006,$53E0005,$5520005,$559000A
		dc.l	$5650010,$5770006,$57F000C,$58D0025
		dc.l	$5B70007,$5C6000A,$5D90016,$5F10007
		dc.l	$6040012,$6220007,$6320007,$6490009
		dc.l	$6540006,$65C0007,$6650011,$67C0007
		dc.l	$6850009,$6BB0007,$6C4000B,$6F0000D
		dc.l	$704000C,$7120009,$71D0007,$726000E
		dc.l	$7360007,$73F000E,$74F0007,$7580011
		dc.l	$78C0007,$7950005,$79C0008,$7A60007
		dc.l	$7AF0007,$7B80007,$7C60006,$7CE0005
		dc.l	$7D5000A,$7E60007,$7F40006,$7FC0008
		dc.l	$806000B,$8180009,$82F0007,$84D0005
		dc.l	$8640005,$8760005,$88D0005,$89F0005
		dc.l	$8B60005,$8C80005,$8DF0006,$9050005
		dc.l	$90C0036,$9440008,$9570005,$9660008
		dc.l	$9790005,$9870006,$9950013,$9AA0021
		dc.l	$9CD0005,$9D40009,$9E40008,$A060009
		dc.l	$A190009,$A240007,$A2D000F,$A3E000D
		dc.l	$A520009,$A5D0007,$A660019,$A860012
		dc.l	$AB60005,$ACE0009,$ADC0014,$AF20010
		dc.l	$B160005,$B330006,$B3B000E,$B50000A
		dc.l	$B610008,$B700011,$B880005,$B8F000A
		dc.l	$BA00007,$BA9000E,$BBE000E,$BD3000F
		dc.l	$BE90063,$C4E0028,$C810008,$C8B000B
		dc.l	$C980009,$CA30016,$CBB0009,$CC6000C
		dc.l	$CD40009,$CDF002D,$D0E0017,$D270005
		dc.l	$D310005,$D3E0007,$D47000A,$D530006
		dc.l	$D5B0006,$D630006,$D6B0006,0

;======================================================================

;======================================================================

_wrongver	pea	TDREASON_WRONGVER
		bra	_end
_failedtoload	pea	_FailedLoadMsg(pc)
		pea	TDREASON_FAILMSG
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
