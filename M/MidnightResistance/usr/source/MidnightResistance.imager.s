;*---------------------------------------------------------------------------
;  :Program.	midnightresistance.imager.asm
;  :Contents.	Imager for Midnight Resistance
;  :Author.	Wepl
;  :Version.	$Id: MidnightResistance.imager.asm 1.2 2004/05/26 06:45:09 wepl Exp wepl $
;  :History.	09.01.02 started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	Disk 1:		0-1	standard
;			2-159	$1800 bytes sync=8944 with directory at track 80
;
;	pos	len	contens
;	-4	4	aaaaaaaa
;	0	2	4489
;	2	2	aaaa
;	4	8	mfm: 0=?? 1=secnum 2=secs-before-gap 3=0
;	c	8	mfm: chksum
;	14	200	data odd
;	214	200	data even
;	414
;
;	tracklength is around $3387 (pal version)
;
;	directory:
;	$00	WORD	file number
;	$02	CHAR17	filename
;	$13	BYTE	rc for loader???
;	$14	LONG	default destination address
;	$18	LONG	length unpacked
;	$1c	LONG	length packed
;---------------------------------------------------------------------------*

;DEBUG

	INCDIR	Includes:
	INCLUDE	devices/trackdisk.i
	INCLUDE	dos/dos.i
	INCLUDE	intuition/intuition.i
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	lvo/intuition.i
	INCLUDE	patcher.i

	IFD BARFLY
	;OUTPUT	"C:Parameter/MidnightResistance.Imager"
	OUTPUT	"Develop:Installs/midnightresistance inst/MidnightResistance.Imager"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	ENDC

;======================================================================

	SECTION a,CODE

		moveq	#-1,d0
		rts
		dc.l	_Table
		dc.l	"PTCH"

;======================================================================

_Table		dc.l	PCH_ADAPTOR,.adname		;name adaptor
		dc.l	PCH_NAME,.name			;description of parameter
		dc.l	PCH_FILECOUNT,1			;number of cycles
		dc.l	PCH_DATALENGTH,.lengtharray	;file lengths
		dc.l	PCH_SPECIAL,.specialarray	;functions
		dc.l	PCH_STATE,.statearray		;state texts
		dc.l	PCH_MINVERSION,.patcherver	;minimum patcher version required
		dc.l	PCH_INIT,_Init			;init routine
		dc.l	PCH_FINISH,_Finish		;finish routine
		dc.l	PCH_ERRORINPARAMETER,_Finish	;finish routine
		dc.l	TAG_DONE

.lengtharray	dc.l	4
.specialarray	dc.l	_Special
.statearray	dc.l	.insertdisk

.adname		dc.b	"Done by Wepl.",0
.name		dc.b	"Midnight Resistance, Diskimager for HD-Install",0
.patcherver	dc.b	"V1.05"
.insertdisk	dc.b	'Please insert your original writepro-',10
		dc.b	'tected disk into the source drive.',0
	IFD BARFLY
		dc.b	"$VER: "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	0
		dc.b	"$Id: MidnightResistance.imager.asm 1.2 2004/05/26 06:45:09 wepl Exp wepl $"
	ENDC
	EVEN

;======================================================================

_Init		moveq	#0,d0				;source drive
		move.l	PTB_INHIBITDRIVE(a5),a0		;inhibit drive
		jsr	(a0)
		tst.l	d0
		bne	.error
		
		moveq	#0,d0				;source drive
		move.l	PTB_OPENDEVICE(a5),a0		;open source device
		jsr	(a0)
		tst.l	d0
		bne	.error
		rts

.error		bsr	_Finish
		moveq	#-1,d0
		rts

;======================================================================

_Finish		moveq	#0,d0				;source drive
		move.l	PTB_ENABLEDRIVE(a5),a0		;deinhibit drive
		jmp	(a0)

;======================================================================

BYTESPERTRACK	= $1800
RAWREADLEN	= $6800
SYNC		= $8944

;======================================================================

_Special
.idisk		move.l	#1,d0
		bsr	_InsertDisk
		tst.l	d0
		beq	.nodisk
		
	;check for disk in drive
		move.l	(PTB_DEVICESOURCEPTR,a5),a1
		move.w	#TD_CHANGESTATE,(IO_COMMAND,a1)
		move.l	(4).w,a6
		jsr	(_LVODoIO,a6)
		tst.l	(IO_ACTUAL,a1)
		bne	.idisk

	;read allocation map and directory
		move.w	#$3cc,d2
		lea	(_map),a0
		moveq	#12-1,d3
.root		move.w	d2,d0
		bsr	_loadsec
		beq	.motoff
		addq.w	#1,d2
		add.w	#$200,a0
		dbf	d3,.root
		
	IFD DEBUG
	;save directory and bitmap
		move.l	#12*512,d0
		move.l	#"dr0"<<8,d1
	;	add.b	d6,d1
		move.l	d1,-(a7)
		move.l	a7,a0
		lea	(_map),a1
		bsr	_WriteFile
		addq.l	#4,a7
	ENDC

	;load and save each file
		lea	(_dir),a2
.nextfile	lea	(_file),a1

		LEA	(_map+$38+$3cc),A3
		move.l	($1c,a2),d5
		MOVE.W	D5,D0
		MOVEQ	#9,D1
		LSR.L	D1,D5
		ANDI.W	#$01FF,D0
		SEQ	D0
		EXT.W	D0
		ADD.W	D0,D5
		MOVE.W	#$03CB,D4
		move.w	(a2),d6
.126		CMP.B	-(A3),D6
		DBEQ	D4,.126
		BNE.B	.146
		MOVE.W	D4,D0
		lea	(_sec),a0
		BSR.W	_loadsec
		beq	.motoff
		bsr	_dec
		SUBQ.W	#1,D4
		BCS.B	.144
		DBRA	D5,.126
		BRA.B	.16C

.144		SUBQ.W	#1,D5
.146		MOVE.W	#$03EF,D4
		LEA	(_map+$38+$3d8),A3
.14E		CMP.B	(A3)+,D6
		DBEQ	D4,.14E
		bne	.error
		MOVE.W	D4,D0
		NEG.W	D0
		ADDI.W	#$07C7,D0
		lea	(_sec),a0
		bsr	_loadsec
		beq	.motoff
		bsr	_dec
		SUBQ.W	#1,D4
		DBRA	D5,.14E
.16C
		move.l	($18,a2),d0
		lea	(2,a2),a0
		lea	(_file),a1
		bsr	_WriteFile
		beq	.error

.skip		add.w	#32,a2
		tst.b	(2,a2)
		bne	.nextfile
		
		moveq	#0,d7
.error

	;switch motor off
.motoff		move.l	(PTB_DEVICESOURCEPTR,a5),a1
		clr.l	(IO_LENGTH,a1)
		move.w	#TD_MOTOR,(IO_COMMAND,a1)
		move.l	(4).w,a6
		jsr	(_LVODoIO,a6)
.nodisk
	;enable drive
		tst.b	d7
		beq	.quit
		bsr	_Finish
		
.quit		move.l	d7,d0
		rts

; a0=src a1=dest
_dec		MOVE.W	#$01FF,D2
.1B2		MOVEQ	#0,D1
		SUBQ.W	#1,D2
		BCS.B	.1CE
		MOVE.B	(A0)+,D1
		SUBQ.B	#1,D1
		BVS.B	.1CE
		ADDQ.B	#1,D1
		BMI.B	.1D0
		SUB.W	D1,D2
.1C4		MOVE.B	(A0)+,(A1)+
		DBRA	D1,.1C4
		DBRA	D2,.1B2
.1CE		RTS	
.1D0		NEG.B	D1
		MOVE.B	(A0)+,D0
.1D4		MOVE.B	D0,(A1)+
		DBRA	D1,.1D4
		DBRA	D2,.1B2
		RTS	

; -> d0=sec a0=dest
; <- d0=succ

_loadsec	movem.l	d1-a6,-(a7)

	add.w	#24,d0

		move.l	a0,a3			;a3 = dest

		ext.l	d0
		divu	#12,d0
		move.w	d0,d7			;d7 = track
		swap	d0
		move.w	d0,d6			;d6 = sector
		cmp.w	(.lasttrk),d7
		beq	.copysec

		move.w	d7,d2
		bchg	#0,d2			;swap sides
		moveq	#5-1,d4			;D4 = retries
.readretry	bsr	_ReadTrack
		tst.b	d0
		beq	.readerr

		move.l	(PTB_SPACE,a5),a0	;source
		lea	(_decoded),a1		;destination
		bsr	_Decode
		tst.b	d0
		bne	.readok
		dbf	d4,.readretry
		bra	.readerr

.readok		lea	(.lasttrk),a0
		move.w	d7,(a0)

.copysec	lea	(_decoded),a0
		mulu	#$200,d6
		add.w	d6,a0
		move.l	#$200/4-1,d0
.c		move.l	(a0)+,(a3)+
		dbf	d0,.c
		
		moveq	#-1,d0

		movem.l	(a7)+,_MOVEMREGS
		rts

.readerr	bsr	_ReadError
		moveq	#0,d0
		movem.l	(a7)+,_MOVEMREGS
		rts

.lasttrk	dc.w	-1

;======================================================================
; IN:	D2 = track
;	D6 = amount tracks left
; OUT:	D0 = error

_ReadTrack
		and.l	#$ffff,d2

		move.l	d2,d0
		move.l	d3,d1
		bsr	_Display

SOURCE = 0	;0=real 1=nomadwarp 2=wwarp

	IFEQ SOURCE
	;reading from a real disk
		move.l	(PTB_DEVICESOURCEPTR,a5),a1
		move.l	(PTB_SPACE,a5),(IO_DATA,a1)	;track is to load in ptb_space
		move.l	#RAWREADLEN,(IO_LENGTH,a1)	;double length of track to decode data
		move.l	d2,(IO_OFFSET,a1)
		move.w	#TD_RAWREAD,(IO_COMMAND,a1)
		move.b	#0,(IO_FLAGS,a1)
		move.l	(4).w,a6
		jsr	(_LVODoIO,a6)
		move.l	(PTB_DEVICESOURCEPTR,a5),a1
		tst.b	(IO_ERROR,a1)
		seq	d0
		rts
	ENDC
	IFEQ SOURCE-1
	;reading from a track-file written by nomad-warp
		movem.l	d2-d4/a2-a3,-(a7)
		lea	(.name),a0			;format string
		move.w	d2,d0
		lsr.w	#1,d0
		and.w	#1,d2
		movem.w	d0/d2,-(a7)
		move.l	a7,a1				;arg array
		lea	(_PutChar),a2
		sub.l	#100-4,a7
		move.l	a7,a3				;buffer
		move.l	(4),a6
		jsr	(_LVORawDoFmt,a6)
		move.l	a7,d1
		move.l	#MODE_OLDFILE,d2
		move.l	(PTB_DOSBASE,a5),a6
		jsr	(_LVOOpen,a6)
		add.l	#100,a7
		move.l	d0,d4
		beq	.err
		move.l	d4,d1
		move.l	(PTB_SPACE,a5),d2
		move.l	#RAWREADLEN,d3
		jsr	(_LVORead,a6)
		move.l	d4,d1
		jsr	(_LVOClose,a6)
		moveq	#-1,d0
.err		movem.l	(a7)+,d2-d4/a2-a3
		rts
.name		dc.b	"ram:track_%02d_head_%02d",0,0
	ENDC
	IFEQ SOURCE-2
	;reading from a wwarp image
		movem.l	d2-d6,-(a7)
		move.l	d2,d6
		moveq	#0,d5
		sub.w	#168*4,a7
		lea	.name,a0
		move.l	a0,d1
		move.l	#MODE_OLDFILE,d2
		move.l	(PTB_DOSBASE,a5),a6
		jsr	(_LVOOpen,a6)
		move.l	d0,d4
		beq	.err
		move.l	d4,d1
		move.l	#16,d2
		move.l	#OFFSET_BEGINNING,d3
		jsr	(_LVOSeek,a6)			;skip header
		move.l	d4,d1
		move.l	a7,d2
		move.l	#168*4,d3
		jsr	(_LVORead,a6)
		cmp.l	d0,d3
		bne	.close
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
.0		cmp.w	d0,d6
		beq	.1
		move.l	(a7,d1.l),d3
		and.l	#$ffff,d3
		beq	.2
		add.l	d3,d2
		add.l	#16,d2				;skip track headline
.2		addq.l	#1,d0
		addq.l	#4,d1
		bra	.0
.1		move.l	d4,d1
		add.l	#16,d2				;skip track headline
		move.l	#OFFSET_CURRENT,d3
		jsr	(_LVOSeek,a6)
		move.l	d4,d1
		move.l	(PTB_SPACE,a5),d2
		move.l	#RAWREADLEN,d3
		jsr	(_LVORead,a6)
		cmp.l	d0,d3
		bne	.close
		moveq	#-1,d5
.close		move.l	d4,d1
		jsr	(_LVOClose,a6)
.err		add.w	#168*4,a7
		move.l	d5,d0
		movem.l	(a7)+,d2-d6
		rts
.name		dc.b	"develop:cracks/nebulus2/neb2.wwp",0
	EVEN
	ENDC

;======================================================================
; IN:	D0 = size
;	A0 = name
;	A1 = address
; OUT:	D0 = error

_WriteFile	movem.l	d2-d7,-(a7)
		move.l	a0,-(a7)
		move.l	d0,d3
		moveq	#0,d5
		move.l	a1,d6
		move.l	(PTB_DOSBASE,a5),a6
		move.l	a0,d1
		move.l	#MODE_NEWFILE,d2
		jsr	(_LVOOpen,a6)
		move.l	d0,d4
		beq	.err
		move.l	d4,d1
		move.l	d6,d2
		jsr	(_LVOWrite,a6)
		cmp.l	d0,d3
		bne	.err
		moveq	#-1,d5
		bra	.close
.err		jsr	(_LVOIoErr,a6)
		sub.l	a0,a0				;window
		pea	(.gadgets)
		pea	(.text)
		pea	(.titel)
		clr.l	-(a7)
		pea	(EasyStruct_SIZEOF)
		move.l	a7,a1				;easyStruct
		sub.l	a2,a2				;IDCMP_ptr
		move.l	d0,-(a7)
		move.l	a7,a3				;Args
		move.l	(PTB_INTUITIONBASE,a5),a6
		jsr	(_LVOEasyRequestArgs,a6)
		add.w	#6*4,a7
.close		move.l	d4,d1
		beq	.1
		jsr	(_LVOClose,a6)
.1		move.l	d5,d0
		movem.l	(a7)+,d1-d7
		rts

.titel		dc.b	"Error",0
.text		dc.b	"Dos Error %ld writing file '%s'",0
.gadgets	dc.b	"OK",0
	EVEN

;======================================================================
; IN:	A0 = raw
;	A1 = dest
; OUT:	D0 = error

GetW	MACRO
		cmp.l	a0,a5
		bls	.error
		move.l	(a0),\1
		lsr.l	d5,\1
	ENDM
GetW2	MACRO
		cmp.l	a2,a5
		bls	.error
		move.l	(a2),\1
		lsr.l	d5,\1
	ENDM
GetWI	MACRO
		GetW	\1
		addq.l	#2,a0
	ENDM
GetWI2	MACRO
		GetW2	\1
		addq.l	#2,a2
	ENDM
GetLI	MACRO
		GetWI	\1
		swap	\1
		GetWI	\2
		move.w	\2,\1
	ENDM
GetLI2	MACRO
		GetWI2	\1
		swap	\1
		GetWI2	\2
		move.w	\2,\1
	ENDM
GetL2	MACRO
		GetWI2	\1
		swap	\1
		GetW2	\2
		move.w	\2,\1
		subq.l	#2,a2
	ENDM

_Decode		movem.l	d1-a6,-(a7)
		move.l	a7,a6			;A6 = return stack
		lea	(RAWREADLEN,a0),a5	;A5 = end of raw data

		move.w	#SYNC,d2		;D2 = sync

	;find sync
.sync1		moveq	#16-1,d5		;D5 = shift count
.sync2		GetW	d0
		cmp.w	d2,d0
		beq	.sync3
.sync_retry	dbf	d5,.sync2
		addq.l	#2,a0
		bra	.sync1

.sync3		movem.l	a0/a1,-(a7)		;save this point for new try

		MOVE.L	#$55555555,D6
		moveq	#12,d7			;track count

.loop2		GetLI	d0,d3
		cmp.l	#$8944aaaa,d0
		bne	.fail
		
		lea	(4,a0),a2
		bsr	.getlong
		lsr.w	#8,d0
		cmp.w	d7,d0			;12 sectors before gap?
		bne	.fail
		
		swap	d0
		and.w	#$ff,d0
		cmp.w	#12,d0			;sector number
		bhs	.fail
		mulu	#$200,d0
		lea	(a1,d0.w),a3		;a3 = dest
		
		addq.l	#4,a0
		addq.l	#4,a2
		bsr	.getlong
		move.l	d0,d4			;checksum
		
		addq.l	#4,a0
		lea	($200,a0),a2
		moveq	#$200/4-1,d2
.loop		bsr	.getlong
		move.l	d0,(a3)+
		dbf	d2,.loop
		
		sub.w	#$200,a3
		move.w	#$200/2-1,d3
		moveq	#0,d2
		moveq	#0,d1
.crc		and.w	#15,d2
		move.w	(a3)+,d0
		rol.w	d2,d0
		addx.w	d0,d1
		addq.w	#1,d2
		dbf	d3,.crc
		
		lsr.l	#8,d4
		cmp.w	d4,d1
		bne	.fail
		
		lea	(4,a2),a0		;skip aaaaaaaa
		
		subq.w	#1,d7
		bne	.loop2

.success	moveq	#-1,d0
.quit		move.l	a6,a7
		movem.l	(a7)+,d1-a6
		rts

.fail		movem.l	(a7)+,a0/a1
		bra	.sync_retry		;try again

.error		moveq	#0,d0
		bra	.quit

.getlong	GetLI	d0,d3
		GetLI2	d1,d3
		and.l	d6,d0
		and.l	d6,d1
		add.l	d0,d0
		or.l	d1,d0
		rts

;======================================================================
; D0 = disk number

_InsertDisk	sub.l	a0,a0				;window
		pea	(.gadgets)
		pea	(.text)
		pea	(.titel)
		clr.l	-(a7)
		pea	(EasyStruct_SIZEOF)
		move.l	a7,a1				;easyStruct
		sub.l	a2,a2				;IDCMP_ptr
		move.l	d0,-(a7)
		move.l	a7,a3				;Args
		move.l	(PTB_INTUITIONBASE,a5),a6
		jsr	(_LVOEasyRequestArgs,a6)
		add.w	#6*4,a7
		rts

.titel		dc.b	"Insert Disk",0
.text		dc.b	"Insert your original disk #%ld",10
		dc.b	"into the source drive !",0
.gadgets	dc.b	"OK|Cancel",0,0

;======================================================================

_ReadError	sub.l	a0,a0				;window
		pea	(.gadgets)
		pea	(.text)
		pea	(.titel)
		clr.l	-(a7)
		pea	(EasyStruct_SIZEOF)
		move.l	a7,a1				;easyStruct
		sub.l	a2,a2				;IDCMP_ptr
		move.l	d2,-(a7)
		move.l	a7,a3				;Args
		move.l	(PTB_INTUITIONBASE,a5),a6
		jsr	(_LVOEasyRequestArgs,a6)
		add.w	#6*4,a7
		rts

.titel		dc.b	"Error",0
.text		dc.b	"Can't read track %ld",0
.gadgets	dc.b	"OK",0

;======================================================================
; IN:	D0 = actual tracknumber
;	D1 = tracks left to do

_Display	movem.l	d0-d1/a0-a3/a6,-(a7)
		lea	(.text),a0		;format string
		move.l	d1,-(a7)
		move.l	d0,-(a7)
		move.l	a7,a1			;arg array
		lea	(_PutChar),a2
		sub.l	#100-8,a7
		move.l	a7,a3			;buffer
		move.l	(4),a6
		jsr	(_LVORawDoFmt,a6)
		move.l	a7,a0
		move.l	(PTB_DISPLAY,a5),a6
		jsr	(a6)
		add.l	#100,a7
		movem.l	(a7)+,d0-d1/a0-a3/a6
		rts

.text		dc.b	"reading track %ld",0

_PutChar	move.b	d0,(a3)+
		rts

;===============================================================

	SECTION	b,BSS
	
_map		dsb	512*4
_dir		dsb	512*8
_decoded	dsb	$1800
_sec		dsb	512
_file		dsb	190000

