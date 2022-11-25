***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(            DUNE IMAGER SLAVE               )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2017                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 04-Jan-2018	- files are now created correctly even if they already
;		  exist, rawdic_SaveFile used for saving the first sector,
;		  rawdic_AppendFile for all follwing sectors
;		- dir.1 is renamed to dir.0 as done in the original
;		  installer, dir.1 file is not saved anymore
;		- dummy file is only saved for disk 3 now, no need to
;		  have 3 dummy files (one for each disk)
;		- checksum checks for the Dune custom tracks added

; 27-Dec-2017	- work started, adapted from my AmigaDOS file imager
;		- and finished a short while later, saves all files
;		- a bit later: version specific file names supported
;		- another while later: support for spanish version added


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Dune imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(04.01.2018)",0
	CNOP	0,4


.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk2	dc.l	.disk3		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk3	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.tracks	TLENTRY	000,159,512*11,SYNC_STD,DMFM_STD
	TLEND




DOSName	dc.b	"dos.library",0
		CNOP	0,2


; d0.w: disk number
; a5.l: rawdic base
SaveFiles
	movem.l	d0-a6,-(a7)
	bsr	SaveDOSFiles
	movem.l	(a7)+,d0-a6


; check version
	lea	Dir0,a0
	moveq	#0,d1
	moveq	#0,d2
	move.w	#1442/2-1,d7
.crc	add.w	(a0)+,d1
	addx.w	d2,d1
	dbf	d7,.crc

; $9a64: en -> 1
; $c748: fr -> 2
; $d4d8: de -> 3
; $b134: it -> 5
; $b3da: es -> 6


	moveq	#"1",d2		; en
	cmp.w	#$9a64,d1
	beq.b	.found
	moveq	#"2",d2		; fr
	cmp.w	#$c748,d1
	beq.b	.found
	moveq	#"3",d2		; de
	cmp.w	#$d4d8,d1
	beq.b	.found
	moveq	#"5",d2		; it
	cmp.w	#$b134,d1
	beq.b	.found
	moveq	#"6",d2		; es
	cmp.w	#$b3da,d1
	bne.b	.unknown

.found	lea	cmd(pc),a0	; "commandX.hsq"
	move.b	d2,7(a0)
	lea	phr1(pc),a0	; "phraseX1.hsq"
	move.b	d2,6(a0)
	lea	phr2(pc),a0	; "phraseX2.hsq"
	move.b	d2,6(a0)

.unknown


	move.w	d0,d6
	cmp.w	#3,d6
	bne.b	.nodisk3
	addq.w	#1,d6
.nodisk3


	subq.w	#1,d0
	lsl.w	#2,d0
	lea	names(pc),a2
	move.l	(a2,d0.w),a2

.save
	lea	Dir0,a4
	moveq	#0,d2
	move.b	(a2)+,d2

	lea	FILESTATUS,a0
	tst.b	(a0,d2.w)		; file already saved?
	bne.w	.next
	st	(a0,d2.w)


	mulu.w	#14,d2
	add.w	d2,a4


	moveq	#0,d0
	tst.w	8(a4)
	beq.b	.no1
	or.b	#1,d0
.no1	tst.w	10(a4)
	beq.b	.no2
	or.b	#2,d0
.no2	tst.w	12(a4)
	beq.b	.no3
	or.b	#4,d0
.no3	


	move.w	d6,d1
	and.b	d0,d1


	and.w	#6,d1
	move.w	8(a4,d1.w),d0		; sector
	move.l	4(a4),d1		; length


	divu.w	#510,d1
	swap	d1
	move.w	d1,d7
	swap	d1
					; in original installer: a3: buffer

	lea	rawdic_SaveFile(a5),a6	; first run: create file
	subq.w	#1,d1
	bmi.b	.last

; read sector here
.loop	movem.l	d0-d7,-(a7)
	bsr	LoadBlock		; -> a3: sector data
	movem.l	(a7)+,d0-d7

	bsr	.Checksum
	bne.b	.error

; copy sector data (510 bytes) to destination (a3)
	movem.l	d0-a6,-(a7)
	move.l	a2,a0
	lea	2(a3),a1
	move.l	#510,d0
	jsr	(a6)
	movem.l	(a7)+,d0-a6
	
	lea	rawdic_AppendFile(a5),a6
	
	addq.w	#1,d0			; next sector
	dbf	d1,.loop


.last
	movem.l	d0-d7,-(a7)
	bsr	LoadBlock		; -> a3: sector data
	movem.l	(a7)+,d0-d7

	bsr.b	.Checksum
	bne.b	.error

; read sector here
	subq.w	#1,d7
	bmi.w	.nocopy

; copy sector data (d7 bytes) to destination (a3)
	movem.l	d0-a6,-(a7)
	move.l	a2,a0
	lea	2(a3),a1
	moveq	#1,d0
	add.w	d7,d0
	jsr	(a6)
	movem.l	(a7)+,d0-a6


.nocopy


.next
.getend	tst.b	(a2)+
	bne.b	.getend

	cmp.b	#-1,(a2)
	bne.w	.save

	moveq	#IERR_OK,d0
	rts

.error	moveq	#IERR_CHECKSUM,d0
	rts

.Checksum
	movem.l	d0-a6,-(a7)
	lea	2(a3),a0
	move.w	#510/2-1,d7
	moveq	#0,d0
.checksector
	add.w	(a0)+,d0
	dbf	d7,.checksector
	cmp.w	(a3),d0
	movem.l	(a7)+,d0-a6
	rts



names	dc.l	names1
	dc.l	names2
	dc.l	names3
	

names1	DC.B	100
	DC.B	'm1.hsq',0
	DC.B	0
	DC.B	'icone.hsq',0
	DC.B	2
	DC.B	'leto.hsq',0
	DC.B	3
	DC.B	'jess.hsq',0
	DC.B	7
	DC.B	'stil.hsq',0
	DC.B	8
	DC.B	'kyne.hsq',0
	DC.B	9
	DC.B	'chan.hsq',0
	DC.B	11
	DC.B	'baro.hsq',0
	DC.B	12
	DC.B	'feyd.hsq',0
	DC.B	14
	DC.B	'hark.hsq',0
	DC.B	23
	DC.B	'balcon.hsq',0
	DC.B	27
	DC.B	'dunes2.hsq',0
	DC.B	35
	DC.B	'prim1.hsq',0
	DC.B	36
	DC.B	'prim2.hsq',0
	DC.B	39
	DC.B	'pers.hsq',0
	DC.B	40
	DC.B	'chankiss.hsq',0
	DC.B	41
	DC.B	'sky.hsq',0
	DC.B	44
	DC.B	'attack.hsq',0
	DC.B	45
	DC.B	'stars.hsq',0
	DC.B	46
	DC.B	'intds.hsq',0
	DC.B	47
	DC.B	'sunrs.hsq',0
	DC.B	48
	DC.B	'paul.hsq',0
	DC.B	49
	DC.B	'back.hsq',0
	DC.B	54
	DC.B	'generic.hsq',0
	DC.B	55
	DC.B	'cryo.hsq',0
	DC.B	56
	DC.B	'shai.hsq',0
	DC.B	57
	DC.B	'dunes3.hsq',0
	DC.B	59
	DC.B	'map2.hsq',0
	DC.B	68
	DC.B	'siet8.hsq',0
	DC.B	72
	DC.B	'siet12.hsq',0
	DC.B	79
	DC.B	'stars1.hsq',0
	DC.B	80
	DC.B	'back1.hsq',0
	DC.B	82
	DC.B	'credits.hsq',0
	DC.B	83
	DC.B	'shai1.hsq',0
	DC.B	84
	DC.B	'shai2.hsq',0
	DC.B	86
	DC.B	'tablat.bin',0
	DC.B	87
	DC.B	'dunechar.hsq',0
	DC.B	90
	DC.B	'siet.sam',0
	DC.B	91
	DC.B	'palace.sam',0
	DC.B	94
	DC.B	'map.hsq',0
	DC.B	95
	DC.B	'globdata.hsq',0

	;dc.b	96
	;dc.b	"command1.hsq",0	; en
	;dc.b	97
	;dc.b	"command2.hsq",0	; fr
	;dc.b	98
	;dc.b	"command3.hsq",0	; de
	;dc.b	100
	;dc.b	"command5.hsq",0	; it

	dc.b	98
cmd	dc.b	"command1.hsq",0

	dc.b	-1

names2	DC.B	'em2.hsq',0
	DC.B	1
	DC.B	'fresk.hsq',0
	DC.B	2
	DC.B	'leto.hsq',0
	DC.B	3
	DC.B	'jess.hsq',0
	DC.B	4
	DC.B	'hawa.hsq',0
	DC.B	5
	DC.B	'idah.hsq',0
	DC.B	6
	DC.B	'gurn.hsq',0
	DC.B	7
	DC.B	'stil.hsq',0
	DC.B	8
	DC.B	'kyne.hsq',0
	DC.B	9
	DC.B	'chan.hsq',0
	DC.B	10
	DC.B	'hara.hsq',0
	DC.B	11
	DC.B	'baro.hsq',0
	DC.B	12
	DC.B	'feyd.hsq',0
	DC.B	13
	DC.B	'empr.hsq',0
	DC.B	14
	DC.B	'hark.hsq',0
	DC.B	15
	DC.B	'smug.hsq',0
	DC.B	16
	DC.B	'frm1.hsq',0
	DC.B	17
	DC.B	'frm2.hsq',0
	DC.B	18
	DC.B	'frm3.hsq',0
	DC.B	19
	DC.B	'por.hsq',0
	DC.B	20
	DC.B	'prouge.hsq',0
	DC.B	21
	DC.B	'comm.hsq',0
	DC.B	22
	DC.B	'equi.hsq',0
	DC.B	23
	DC.B	'balcon.hsq',0
	DC.B	24
	DC.B	'corr.hsq',0
	DC.B	25
	DC.B	'siet0.hsq',0
	DC.B	26
	DC.B	'sas.hsq',0
	DC.B	27
	DC.B	'dunes2.hsq',0
	DC.B	31
	DC.B	'serre.hsq',0
	DC.B	33
	DC.B	'palplan.hsq',0
	DC.B	34
	DC.B	'sun.hsq',0
	DC.B	37
	DC.B	'dunes.hsq',0
	DC.B	38
	DC.B	'onmap.hsq',0
	DC.B	39
	DC.B	'pers.hsq',0
	DC.B	41
	DC.B	'sky.hsq',0
	DC.B	42
	DC.B	'ornypan.hsq',0
	DC.B	43
	DC.B	'ornytk.hsq',0
	DC.B	',attack.hsq',0
	DC.B	45
	DC.B	'stars.hsq',0
	DC.B	48
	DC.B	'paul.hsq',0
	DC.B	50
	DC.B	'mois.hsq',0
	DC.B	51
	DC.B	'book.hsq',0
	DC.B	52
	DC.B	'orny.hsq',0
	DC.B	53
	DC.B	'ornycab.hsq',0
	DC.B	54
	DC.B	'generic.hsq',0
	DC.B	57
	DC.B	'dunes3.hsq',0
	DC.B	58
	DC.B	'ver.hsq',0
	DC.B	59
	DC.B	'map2.hsq',0
	DC.B	79
	DC.B	'stars1.hsq',0
	DC.B	85
	DC.B	'mirror.hsq',0
	DC.B	87
	DC.B	'dunechar.hsq',0
	DC.B	88
	DC.B	'condit.hsq',0
	DC.B	89
	DC.B	'dialogue.hsq',0
	DC.B	90
	DC.B	'siet.sam',0
	DC.B	91
	DC.B	'palace.sam',0
	DC.B	95
	DC.B	'globdata.hsq',0

	DC.B	96
phr1	DC.B	"phrase11.hsq",0
	DC.B	97
phr2	DC.B	"phrase12.hsq",0

	DC.B	99
	DC.B	'dune10s0.sav',0

	dc.b	-1


names3	DC.B	'fm3.hsq',0
	DC.B	6
	DC.B	'gurn.hsq',0
	DC.B	7
	DC.B	'stil.hsq',0
	DC.B	8
	DC.B	'kyne.hsq',0
	DC.B	9
	DC.B	'chan.hsq',0,$A
	DC.B	'hara.hsq',0
	DC.B	14
	DC.B	'hark.hsq',0
	DC.B	15
	DC.B	'smug.hsq',0
	DC.B	16
	DC.B	'frm1.hsq',0
	DC.B	17
	DC.B	'frm2.hsq',0
	DC.B	18
	DC.B	'frm3.hsq',0
	DC.B	23
	DC.B	'balcon.hsq',0
	DC.B	25
	DC.B	'siet0.hsq',0
	DC.B	27
	DC.B	'dunes2.hsq',0
	DC.B	28
	DC.B	'fort.hsq',0
	DC.B	29
	DC.B	'bunk.hsq',0
	DC.B	30
	DC.B	'harko.hsq',0
	DC.B	32
	DC.B	'bota.hsq',0
	DC.B	34
	DC.B	'sun.hsq',0
	DC.B	37
	DC.B	'dunes.hsq',0
	DC.B	38
	DC.B	'onmap.hsq',0
	DC.B	39
	DC.B	'pers.hsq',0
	DC.B	40
	DC.B	'chankiss.hsq',0
	DC.B	41
	DC.B	'sky.hsq',0
	DC.B	42
	DC.B	'ornypan.hsq',0
	DC.B	43
	DC.B	'ornytk.hsq',0
	DC.B	44
	DC.B	'attack.hsq',0
	DC.B	50
	DC.B	'mois.hsq',0
	DC.B	52
	DC.B	'orny.hsq',0
	DC.B	53
	DC.B	'ornycab.hsq',0
	DC.B	57
	DC.B	'dunes3.hsq',0
	DC.B	58
	DC.B	'ver.hsq',0
	DC.B	59
	DC.B	'map2.hsq',0
	DC.B	60
	DC.B	'death.hsq',0
	DC.B	61
	DC.B	'siet1.hsq',0
	DC.B	62
	DC.B	'siet2.hsq',0
	DC.B	63
	DC.B	'siet3.hsq',0
	DC.B	64
	DC.B	'siet4.hsq',0
	DC.B	65
	DC.B	'siet5.hsq',0
	DC.B	66
	DC.B	'siet6.hsq',0
	DC.B	67
	DC.B	'siet7.hsq',0
	DC.B	68
	DC.B	'siet8.hsq',0
	DC.B	69
	DC.B	'siet9.hsq',0
	DC.B	70
	DC.B	'siet10.hsq',0
	DC.B	71
	DC.B	'siet11.hsq',0
	DC.B	72
	DC.B	'siet12.hsq',0
	DC.B	73
	DC.B	'vilg1.hsq',0
	DC.B	74
	DC.B	'vilg2.hsq',0
	DC.B	75
	DC.B	'vilg3.hsq',0
	DC.B	76
	DC.B	'vilg4.hsq',0
	DC.B	77
	DC.B	'vilg5.hsq',0
	DC.B	78
	DC.B	'vilg6.hsq',0
	DC.B	81
	DC.B	'final.hsq',0
	DC.B	90
	DC.B	'siet.sam',0
	DC.B	91
	DC.B	'palace.sam',0
	DC.B	92
	DC.B	'vilg.sam',0
	DC.B	93
	DC.B	'hark.sam',0
	DC.B	94
	DC.B	'map.hsq',0
	DC.B	95
	DC.B	'globdata.hsq',0


	dc.b	-1

	CNOP	0,2





; d0.w: disk number
; a5.l: rawdic base
SaveDOSFiles
	move.w	d0,d7		; save disk number
	
	lea	DOSName(pc),a1
	move.l	$4.w,a6
	moveq	#0,d0		; any version will do
	jsr	-552(a6)	; OpenLibrary()
	move.l	d0,a6
	tst.l	d0
	beq.w	.noDOS


; load rootblock
	move.w	#880,d0
	bsr	LoadBlock
	lea	ROOTBLOCK,a0
	bsr	CopyBlock

; check it
	bsr	CheckRootBlock	; checksum ok?, bitmap valid?
	bne.w	.RootBlockInvalid

	lea	ROOTBLOCK,a2
	lea	6*4(a2),a2	; hash table


	moveq	#512/4-56-1,d6	; max. # of entries in hash table

.do_all	move.l	(a2)+,d0	; first block
	beq.b	.noentry

.load_loop
	bsr	LoadBlock	; a3: block
	move.l	rbl_next_hash(a3),d5

; copy file name
	lea	512-80(a3),a0	; sector name (1. byte: length of name)
	move.b	(a0)+,d0	; length of file name
	lea	FILENAME,a1
.copyname
	move.b	(a0)+,(a1)+
	subq.b	#1,d0
	bne.b	.copyname	
	sf	(a1)		; null-terminate

	lea	FILENAME,a0	; check if file/directory may need to be
	bsr	CheckName	; excluded from saving
	tst.l	d0
	beq.b	.next

	;cmp.b	#"1",4(a0)
	;bne.b	.noDir1
	;move.b	#"0",4(a0)
;.noDir1


.nonext	cmp.l	#2,512-4(a3)	; secondary type = ST_USERDIR?
	bne.b	.noDir

	movem.l	d0-a6,-(a7)	; yes, save all files in the directory
	bsr.b	SaveDirFiles	; including all sub-directories
	movem.l	(a7)+,d0-a6
	bra.b	.next

.noDir	bsr	SaveBlocks
	tst.l	d0
	bne.b	.error

.next	move.l	d5,d0		; more entries with the same hash value?
	bne.b	.load_loop


.noentry
	dbf	d6,.do_all



.exit


; all files have been saved successfully, create a 0-byte
; dummy file so install procedure can check if all files have been
; saved without any errors
	lea	.dummy(pc),a0
	cmp.b	#3,d7
	bne.b	.nodummy
	add.b	#"0",d7		; convert disk number to ascii
	move.b	d7,4(a0)
	move.l	a0,a1
	moveq	#0,d0
	jsr	rawdic_SaveFile(a5)
.nodummy


; close DOS library
	move.l	a6,a1		; a1: DOSBase
	move.l	$4.w,a6
	jsr	-414(a6)	; CloseLibrary()

	moveq	#IERR_OK,d0
	rts

.error
.RootBlockInvalid
	moveq	#IERR_NOSECTOR,d0
	rts

.noDOS	lea	.errtxt_DOS(pc),a0
	sub.l	a1,a1
	jmp	rawdic_Print(a5)

.errtxt_DOS	dc.b	"Error opening dos.library!",0
.dummy		dc.b	"Disk0Dummy",0
		CNOP	0,2





	

; a0.l: directory name (null-terminated)
; a3.l: block (ST_USERDIR)
; a6.l: DOS Base

SaveDirFiles
	sub.w	#VAR_SIZEOF,a7	; make room on stack for variables/buffers

; create directory
	move.l	a0,d1
	jsr	-120(a6)	; CreateDir()
.lockok	move.l	d0,DIRLOCK(a7)
	beq.b	.direrror

	move.l	d0,d1
	jsr	-126(a6)	; CurrentDir()
	move.l	d0,DIRLOCK_OLD(a7)


	move.l	a7,a0
	bsr	CopyBlock	; copy directory block

	lea	6*4(a7),a2	; hash table
	moveq	#512/4-56-1,d6	; max. # of entries in hash table
.do_all	move.l	(a2)+,d0	; first block
	beq.b	.next

.load_loop
	bsr	LoadBlock	; a3: block

	lea	512-80(a3),a0	; sector name (1. byte: length of name)
	move.b	(a0)+,d0	; length of file name
	lea	SECNAME(a7),a1
.copyname
	move.b	(a0)+,(a1)+
	subq.b	#1,d0
	bne.b	.copyname	
	sf	(a1)		; null-terminate

	cmp.l	#2,512-4(a3)	; secondary type = ST_USERDIR?
	bne.b	.noDir

	movem.l	d0-a6,-(a7)	; yes, we have a sub-directory!
	lea	SECNAME+15*4(a7),a0
	bsr	SaveDirFiles	; save all files in the sub-directory
	movem.l	(a7)+,d0-a6
	bra.b	.next


.noDir	lea	SECNAME(a7),a0
	bsr	CheckName
	tst.l	d0
	beq.b	.next

	lea	SECNAME(a7),a0
	bsr	SaveBlocks
	tst.l	d0
	bne.b	.error


.next	dbf	d6,.do_all



.out	move.l	DIRLOCK_OLD(a7),d1
	beq.b	.noolddir
	jsr	-126(a6)	; CurrentDir()
.noolddir

	move.l	DIRLOCK(a7),d1
	beq.b	.nonewdir
	jsr	-90(a6)		; Unlock()
.nonewdir
	


.direrror
	add.w	#VAR_SIZEOF,a7
.nosave	rts
	


.error	moveq	#IERR_NOSECTOR,d0
	bra.b	.out


		RSRESET
SECBUF		rs.b	512	; sector buffer
SECNAME		rs.b	30+2	; sector name
DIRLOCK		rs.l	1
DIRLOCK_OLD	rs.l	1
VAR_SIZEOF	rs.b	0



*******************************************
*** EXCLUDE FILES FROM SAVING		***
*******************************************

; checks if a file should be excluded from saving
; this is useful for dummy or protection files which
; often have read errors and are not needed for a game
; to work (protection has to be removed anyway!)


; a0.l: file name
; ----
; d0.l: result, 0: file should be excluded

CheckName
	movem.l	d1-a6,-(a7)
	lea	.TAB(pc),a4
	move.l	a4,a3
	moveq	#1,d0			; default: name is valid
.loop	move.w	(a3)+,d1
	beq.b	.done

	move.l	a0,a2
	lea	(a4,d1.w),a1
.compare
	move.b	(a2)+,d1
	move.b	(a1)+,d2
	beq.b	.same_name

; convert to uppper case
	cmp.b	#"a",d1
	bcs.b	.n1
	cmp.b	#"z",d1
	bhi.b	.n1
	and.b	#~(1<<5),d1
.n1			

; as above
	cmp.b	#"a",d2
	bcs.b	.n2
	cmp.b	#"z",d2
	bhi.b	.n2
	and.b	#~(1<<5),d2
.n2

	cmp.b	d2,d1			
	bne.b	.loop			; names differ, check next entry
	bra.b	.compare

.same_name
	moveq	#0,d0			; file should be excluded!

.done	movem.l	(a7)+,d1-a6
	rts

.TAB	dc.w	.exclude1-.TAB
	dc.w	.exclude2-.TAB
	dc.w	0

.exclude1	dc.b	"sigfile",0	; Bard's Tale protection file
.exclude2	dc.b	"        ",0	; HLS protection file
		CNOP	0,2


*******************************************************************************
*									      *
*			     HELPER ROUTINES				      *
*						      			      *
*******************************************************************************

*******************************************
*** SAVE ALL BLOCKS FOR A FILE		***
*******************************************

; a0.l: file name
; a3.l: block data

SaveBlocks
	movem.l	d5/d7/a2,-(a7)

	move.l	a0,a4		; save file name
	moveq	#0,d5
	cmp.b	#"d",(a4)
	bne.b	.nodir
	cmp.b	#"i",1(a4)
	bne.b	.nodir
	cmp.b	#"r",2(a4)
	bne.b	.nodir
	cmp.b	#".",3(a4)
	bne.b	.nodir
	cmp.b	#"0",4(a4)
	bne.b	.nodir
	moveq	#1,d5
	lea	Dir0,a2
.nodir
	
	moveq	#rawdic_SaveFile,d7	; first run: create file
.save_file
	move.l	4*4(a3),d0		; next block
	beq.b	.done
	cmp.w	#160*11,d0
	bge.b	.error
	bsr.b	LoadBlock

	move.l	a4,a0
	cmp.b	#"1",4(a0)		; dir.1 -> dir.0
	bne.b	.no
	move.b	#"0",4(a0)
.no	lea	6*4(a3),a1		; data
	move.l	3*4(a3),d0		; data size
	jsr	(a5,d7.l)
	moveq	#rawdic_AppendFile,d7

	tst.l	d5
	beq.b	.normal
	lea	6*4(a3),a1		; data
	move.l	3*4(a3),d0		; data size
.copy	move.b	(a1)+,(a2)+
	subq.l	#1,d0
	bne.b	.copy

.normal

	bra.b	.save_file

.done
	
.error	movem.l	(a7)+,d5/d7/a2
	rts


*******************************************
*** LOAD A BLOCK			***
*******************************************

; d0.w: block
; ----
; a1.l: data
; a3.l: data

LoadBlock
	move.w	d0,d1
	mulu.w	#512,d1		; offset
	divu.w	#$1600,d1	; track
	move.w	d1,d0
	swap	d1		; offset
	move.w	d1,-(a7)
	jsr	rawdic_ReadTrack(a5)
	add.w	(a7)+,a1
	move.l	a1,a3
	rts




*******************************************
*** COPY BLOCK TO BUFFER		***
*******************************************

; copies a block to the destination buffer

; a3.l: block data
; a0.l: destination

CopyBlock
	movem.l	d7/a0/a3,-(a7)
	moveq	#512/4-1,d7
.loop	move.l	(a3)+,(a0)+
	dbf	d7,.loop
	movem.l	(a7)+,d7/a0/a3
	rts


*******************************************
*** CHECK ROOTBLOCK			***
*******************************************

; checks the bitmap flag and checksum for the
; given rootblock, also checks if secondary type
; is ST_ROOT

; a3.l: root block
; ----
; zflg: if set, rootblock is OK!


; checks checksum and bitmap flag in root block

CheckRootBlock
	move.l	rbl_checksum(a3),-(a7)
	clr.l	rbl_checksum(a3)
	moveq	#0,d0
	move.l	a3,a0
	moveq	#512/4-1,d1
.loop	add.l	(a0)+,d0	
	dbf	d1,.loop
	neg.l	d0
	cmp.l	(a7)+,d0
	bne.b	.error
	cmp.l	#1,512-4(a3)		; secondary type = ST_ROOT?
	;bne.b	.error
	;cmp.l	#-1,rbl_bm_flag(a3)
.error	rts










; root block format
		RSRESET
rbl_type	rs.l	1		; primary type, 2=T_HEADER
rbl_headerkey	rs.l	1		; unused
rbl_highseq	rs.l	1		; unused
rbl_htsize	rs.l	1		; hash table size (BLOCKSIZE/4)-56
rbl_firstdata	rs.l	1		; unused
rbl_checksum	rs.l	1		; checksum
rbl_ht		rs.l	(512/4)-56	; hash table
rbl_bm_flag	rs.l	1		; bitmap flag, -1 = valid
rbl_bm_pages	rs.l	25		; bitmap blocks pointers
rbl_bm_ext	rs.l	1		; first bitmap extension block (harddisk only)
rbl_r_day	rs.l	1		; last root alteration date, days since 1.1.1978
rbl_r_min	rs.l	1		; minutes past midnight
rbl_r_ticks	rs.l	1		; ticks (1/50 sec) past last minute
rbl_name_len	rs.b	1		; volume name length
rbl_diskname	rs.b	30		; volume name
rbl_unused	rs.b	1		; unused, set to 0
rbl_unused2	rs.l	2		; unused, set to 0
rbl_v_days	rs.l	1		; last disk alt. date, days since 1.1.78
rbl_v_mins	rs.l	1		; minutes past midnight
rbl_v_ticks	rs.l	1		; ticks (1/50 sec) past last minute
rbl_c_days	rs.l	1		; filesystem creation date
rbl_c_mins	rs.l	1		; 
rbl_c_ticks	rs.l	1		;
rbl_next_hash	rs.l	1		; unused (value = 0)
rbl_parent_dir	rs.l	1		; unused (value = 0)
rbl_extentsion	rs.l	1		; FFS: first dircache block, 0 otherwise
rbl_sec_type	rs.l	1		; block secondary type = ST_ROOT (value 1)



	SECTION	BSS,BSS

ROOTBLOCK	ds.b	512
FILENAME	ds.b	30+2		; +2: null-termination+padding

Dir0		ds.b	2048		; 1442 bytes needed, rest for safety
FILESTATUS	ds.b	128

