***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      BLUES BROTHERS IMAGER SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            November 2017                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 23-Nov-2017	- typo in info text fixed :)

; 22-Nov-2017	- skips invalid file starting with "e5" now
;		- not all files were saved correctly so file saving has
;		  been redone completely using large parts of the original
;		  loader code
;		- requires RawDIC 5.0 now!

; 21-Nov-2017	- work started, using Mr.Larmer's work as base
;		- file saving for non-DOS files added
;		- saves main.prg (DOS file) too


	; The Blues Brothers imager

	; A track contains 10 sectors. Sector 0 to 9 contain 512 bytes data,
	; (Total: $1400 bytes)

	; sector format description:

	; sync ($4489)
	; 1 byte header ID (MFM: $5554)
	; 2 unused bytes
	; 1 byte sector number (0-9) + 1
	; 1 byte
	; 1 word checksum
	; gap
	; sync ($4489)
	; 1 byte data block ID (MFM: $5545)
	; 512 bytes data
	; 1 word checksum

	; The checksum test is quite strange, a CRC16 calculation is done
	; which always leads to 0 when everything went ok.
	; Part of the CRC16 calculation are also 3 sync signal words and
	; the header/data block ID, and ofcourse the checksum.

	; The MFM decoding is done by skipping all odd bits in the bitstream.

	; Similar formats: Thalion games (uses the same CRC16 method)



	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	5		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"The Blues Brothers imager V1.1",10
	dc.b	"by Mr.Larmer & StingRay "
	dc.b	"(23.11.2017)",0
	CNOP	0,4


.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_NORESTRICTIONS		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	Init		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read


.tracks	TLENTRY	000,019,512*11,SYNC_STD,DMFM_STD
	TLENTRY	080,081,512*11,SYNC_STD,DMFM_STD


		TLENTRY 20,79,$1400,SYNC_STD,DMFM_NR
		TLENTRY 82,157,$1400,SYNC_STD,DMFM_NR
	TLEND



LoadInit
	move.w	#20,Track
	moveq	#7,d3
	move.w	d3,DirectorySector
	addq.w	#7,d3
	move.w	d3,SectorAdd

	moveq	#0,d1		; track
	moveq	#2,d0		; sector in track
	moveq	#6-1,d3		; num tracks
	lea	Bitmap,a2	; a2: sector table/bitmap
.loop	bsr	LoadSector
	add.w	#512,a2
	addq.w	#1,d0
	dbf	d3,.loop

	move.w	DirectorySector(pc),d0
	lea	Directory,a2
	moveq	#7-1,d3
.loop2	move.w	d0,d4
	bsr.w	CalcSectorAndLoad
	move.w	d4,d0
	add.w	#512,a2
	addq.w	#1,d0
	dbf	d3,.loop2
.exit	rts


; a4.l: directory
; a2.l: destination
LoadFile
	move.w	$1A(a4),d0
	rol.w	#8,d0		; d0.w: sector
	move.w	$1E(a4),d1
	rol.w	#8,d1
	swap	d1
	move.w	$1C(a4),d1
	rol.w	#8,d1		; d1.l: length
	move.l	d1,a5
	move.l	d1,FileLen
	bra.b	LoadFileData

FileLen	dc.l	0


LoadLastBytes
	movem.l	d0-a6,-(a7)
	move.l	a2,a3
	lea	Sector,a2
	bsr.b	Load2Sectors
	move.w	a5,d1
	subq.w	#1,d1
	lea	Sector,a2
.copy	move.b	(a2)+,(a3)+
	dbf	d1,.copy
	movem.l	(a7)+,d0-a6
	rts

; d0.w: sector
; a5.l: length
LoadFileData
	lea	Bitmap,a4
.loop	move.w	d0,d5		; d5: sector
	cmp.l	#0,a5
	beq.b	.skip
	cmp.l	#$400,a5
	blt.b	LoadLastBytes
.skip	bsr.b	Load2Sectors
	sub.l	#$400,a5
	add.w	#512,a2
	move.w	d5,d0
	asl.w	#1,d0
	add.w	d5,d0
	lsr.w	#1,d0
	btst	#0,d5
	beq.b	.is_even
	moveq	#0,d6
	move.b	1(a4,d0.w),d6
	rol.w	#8,d6
	move.b	(a4,d0.w),d6
	lsr.w	#4,d6
	bra.b	.next

.is_even
	move.b	1(a4,d0.w),d6
	and.w	#15,d6
	rol.w	#8,d6
	move.b	(a4,d0.w),d6
.next
	move.w	d6,d0
	cmp.w	#$FF8,d6
	bls.b	.loop
	rts

Load2Sectors
	subq.w	#2,d0
	asl.w	#1,d0
	add.w	SectorAdd(pc),d0
	move.w	d0,d3
	bsr.b	CalcSectorAndLoad
	move.w	d3,d0
	addq.w	#1,d0
	add.w	#$200,a2
CalcSectorAndLoad
	moveq	#0,d1
	move.w	d0,d1
	move.w	Track(pc),d2
	divu	d2,d1
	move.w	d1,d2
	move.w	Track(pc),d7
	mulu	d7,d2
	sub.w	d2,d0
	addq.w	#1,d0
	;bra.w	LoadSector


; d0.w: sector
; d1.w: track
; a2.l: destination

LoadSector
	movem.l	d0-a6,-(a7)
	subq.w	#1,d0
	mulu.w	#512,d0
	mulu.w	#512*10*2,d1
	add.l	d1,d0

	add.l	#22*$1600,d0		; skip DOS tracks

	move.l	DiskData(pc),a0
	add.l	d0,a0
	moveq	#512/4-1,d7
.loop	move.l	(a0)+,(a2)+
	dbf	d7,.loop
	movem.l	(a7)+,d0-a6
	rts


Track		dc.w	0
DirectorySector	dc.w	0
SectorAdd	dc.w	0
DiskData	dc.l	0

; a1.l: ptr to disk image
SaveFiles
	move.l	a1,DiskData

	move.l	a5,-(a7)
	bsr	LoadInit
	move.l	(a7)+,a5


	lea	Directory,a4

.loop	movem.l	a4/a5,-(a7)
	lea	File,a2
	bsr	LoadFile
	movem.l	(a7)+,a4/a5

	moveq	#11-1,d7
	lea	.name(pc),a0
.clear	clr.b	(a0)+
	dbf	d7,.clear

	move.l	a4,a0
	cmp.b	#$e5,(a0)
	beq.b	.next

	lea	.name(pc),a1
	cmp.b	#" ",7(a0)
	bne.b	.full
	cmp.b	#" ",8(a0)
	beq.b	.full
	move.b	#".",7(a0)
.full		
	moveq	#11-1,d7
.copy	cmp.b	#" ",(a0)
	beq.b	.skip
	move.b	(a0),(a1)+

.skip	addq.w	#1,a0
	dbf	d7,.copy	

	lea	.name(pc),a0
	lea	File,a1
	move.l	FileLen(pc),d0
	jsr	rawdic_SaveFile(a5)
.next

	add.w	#32,a4			; next file
	tst.l	(a4)
	bne.b	.loop

	bsr	SaveFiles_DOS

	moveq	#IERR_OK,d0
	rts


.name	ds.b	11+1




DMFM_NR:
		lea	SectorFlags(pc),a2
		moveq	#9,d1
.l0		sf	(a2)+		; clear sector flags
		dbra	d1,.l0

		moveq	#9,d1
		bra.b	.s0		; don't search first sync
.l1		jsr	rawdic_NextSync(a5)
.s0		cmp.w	#$5554,(a0)
		bne.b	.l1

		bsr.b	DMFM_NR_header
		bne.b	.error

		jsr	rawdic_NextSync(a5)	; search data block
		cmp.w	#$5545,(a0)
		bne.b	.s0

		move.b	d2,d0

		bsr	DMFM_NR_data
		bne.b	.error
		dbra	d1,.l1

		lea	SectorFlags(pc),a2
		moveq	#9,d1
.l2		tst.b	(a2)+		; if one sector is missing, one of
		dbeq	d1,.l2		; these flags will be FALSE
		beq.b	.nosect

		moveq	#IERR_OK,d0
.error		rts
.nosect		moveq	#IERR_NOSECTOR,d0
		rts

DMFM_NR_header:

		; => D2.b=sector number

		movem.l	d1/a0,-(sp)

		bsr.b	InitCRC16
		moveq	#9,d6
		bsr.b	StreamCalcCRC16
		or.b	d2,d3		; header checksum ok?
		bne.b	.error

		subq.l	#4*2,a0		; 4 bytes back
		bsr.b	NextByte	; get sector number
		subq.b	#1,d0
		move.b	d0,d2

		movem.l	(sp)+,d1/a0
		moveq	#IERR_OK,d0
		rts
.error		movem.l	(sp)+,d1/a0
		moveq	#IERR_CHECKSUM,d0
		rts

DMFM_NR_data:

		; D0.b=sector number

		movem.l	d1/a0-a1,-(sp)

		cmp.b	#9,d0
		bhi.b	.error
		move.w	#$01ff,d5
.s0
		lea	SectorFlags(pc),a2
		and.w	#$00ff,d2
		st	(a2,d2.w)

		lsl.w	#8,d0
		lsl.w	#1,d0
		add.w	d0,a1

		bsr.b	InitCRC16
		moveq	#3,d6
		bsr.b	StreamCalcCRC16

.l1		bsr.b	NextByte	; calculate header checksum
		bsr.b	CalcCRC16
		move.b	d0,(a1)+
		dbra	d5,.l1

		moveq	#1,d6
		bsr.b	StreamCalcCRC16

		or.b	d2,d3
		bne.b	.error

		movem.l	(sp)+,d1/a0-a1
		moveq	#IERR_OK,d0
		rts
.error		movem.l	(sp)+,d1/a0-a1
		moveq	#IERR_CHECKSUM,d0
		rts

InitCRC16:	lea	CRC_table,a2	; initialise registers for CalcCRC16
		moveq	#0,d0
		moveq	#0,d1
		moveq	#-1,d2
		moveq	#-1,d3
		subq.l	#3*2,a0		; 3 syncwords needed for CRC calculation
		rts

StreamCalcCRC16:
.l0		bsr.b	NextByte
		bsr.b	CalcCRC16
		dbra	d6,.l0
		rts

NextByte:	move.w	(a0)+,d0
		BITSKIP_B d0
		rts
CalcCRC16:
		move.b	d0,d1
		eor.b	d2,d1
		lea	(a2,d1.w),a3
		move.b	(a3),d2
		eor.b	d3,d2
		move.b	$0100(a3),d3
		rts

Init:		; initialisation of the CRC table.

		lea	CRC_table,a0
		moveq	#0,d1
.l1		moveq	#0,d2
		move.b	d1,d2
		lsl.w	#8,d2
		moveq	#7,d0
.l0		add.w	d2,d2
		bcc.b	.s0
		eor.w	#$1021,d2	; $1021 = standard CRC16 value
.s0		dbra	d0,.l0
		move.b	d2,$0100(a0)
		lsr.w	#8,d2
		move.b	d2,(a0)+
		addq.b	#1,d1
		bne.b	.l1

		moveq	#IERR_OK,d0
		rts

SectorFlags:	ds.b	10






DOSName	dc.b	"dos.library",0
		CNOP	0,2


; d0.w: disk number
; a5.l: rawdic base
SaveFiles_DOS
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
	bne.b	.RootBlockInvalid

	lea	ROOTBLOCK,a3
	lea	6*4(a3),a2	; hash table
	bsr	ProcessHashTable
	bra.b	.exit


	moveq	#512/4-56-1,d6	; max. # of entries in hash table

.do_all	move.l	(a2)+,d0	; first block
	beq.b	.next

.load_loop
	bsr	LoadBlock	; a3: block

; copy file name
	lea	512-80(a3),a0	; sector name (1. byte: length of name)
	move.b	(a0)+,d0	; length of file name
	lea	FILENAME,a1
.copyname
	move.b	(a0)+,(a1)+
	subq.b	#1,d0
	bne.b	.copyname	
	sf	(a1)		; null-terminate

	cmp.l	#2,512-4(a3)	; secondary type = ST_USERDIR?
	beq.b	.next		; we don't need to handle directories

.noDir	lea	FILENAME,a0	; check if file may need to be excluded
	bsr	CheckName	; from saving
	tst.l	d0
	beq.b	.next

	lea	FILENAME,a0	; save the file
	bsr	SaveBlocks
	tst.l	d0
	bne.b	.error


.next	dbf	d6,.do_all



.exit

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
	jsr	rawdic_Print(a5)
	rts

.errtxt_DOS	dc.b	"Error opening dos.library!",0
txt_cr	dc.b	10,0
	CNOP	0,2


; a2.l: hash table
ProcessHashTable
	sub.w	#DIR_SIZEOF,a7
	
	moveq	#512/4-56-1,d6	; max. # of entries in hash table
.do_all	move.l	(a2)+,d0	; first block
	beq.w	.next

.load_loop
	bsr	LoadBlock	; a3: block

; copy file name
	lea	512-80(a3),a0	; sector name (1. byte: length of name)
	move.b	(a0)+,d0	; length of file name
	lea	DIRNAME(a7),a1
.copyname
	move.b	(a0)+,(a1)+
	subq.b	#1,d0
	bne.b	.copyname	
	sf	(a1)		; null-terminate

	cmp.l	#2,512-4(a3)	; secondary type = ST_USERDIR?
	bne.b	.noDir


	bra.b	.next

; normal file
.noDir	lea	DIRNAME(a7),a0
	bsr	CheckName
	tst.l	d0
	beq.b	.next

	lea	DIRNAME(a7),a0
	bsr	SaveBlocks
	tst.l	d0
	bne.b	.error


.next	dbf	d6,.do_all

.out	add.w	#DIR_SIZEOF,a7
	rts

.error	moveq	#IERR_NOSECTOR,d0
	bra.b	.out
	



		RSRESET
DIRBUF		rs.b	512
DIRNAME		rs.b	30+2
DIRLOCK		rs.l	1
DIRLOCK_OLD	rs.l	1
DIR_SIZEOF	rs.b	0

REGS		ds.l	16


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
	beq.b	.same_name
	move.b	(a1)+,d2

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

.exclude1	dc.b	"loader",0
.exclude2	dc.b	"system-configuration",0
		CNOP	0,2


*******************************************************************************
*									      *
*			     HELPER ROUTINES				      *
*						      			      *
*******************************************************************************

*******************************************
*** CALCULATE HASH FOR FILE NAME	***
*******************************************

; calculates the hash value for the given
; file name

; a0.l: name
; ----
; d0.l: hash value

CalcHash
	movem.l	d1/d1/a0/a1,-(a7)
	move.l	a0,a1
	moveq	#-1,d0
.getlen	addq.l	#1,d0
	tst.b	(a0)+
	bne.b	.getlen

	moveq	#0,d1
	move.w	d0,d7
.loop	move.b	(a1)+,d1

	cmp.b	#"a",d1
	bcs.b	.ok
	cmp.b	#"z",d1
	bhi.b	.ok
	bclr	#5,d1
.ok	

	mulu.w	#13,d0
	add.w	d1,d0
	and.w	#$7ff,d0
	subq.w	#1,d7
	bne.b	.loop

	divu.w	#(512/4)-56,d0
	swap	d0			; d0.w: hash value

	addq.w	#6,d0			; hash+6 = first block in hash table
	lsl.w	#2,d0			; *4 because table entries are longs
	movem.l	(a7)+,d1/d7/a0/a1
	rts


*******************************************
*** SAVE ALL BLOCKS FOR A FILE		***
*******************************************

; a0.l: file name
; a3.l: block data

SaveBlocks
	move.l	a0,a4		; save file name

.save_file
	move.l	4*4(a3),d0	; next block
	beq.b	.done
	cmp.w	#160*11,d0
	bge.b	.error
	bsr.b	LoadBlock

	move.l	a4,a0
	lea	6*4(a3),a1	; data
	move.l	3*4(a3),d0	; data size
	jsr	rawdic_AppendFile(a5)

	bra.b	.save_file

.done
	
.error	rts


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
; given rootblock, also check if secondary type
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
	bne.b	.error
	cmp.l	#-1,rbl_bm_flag(a3)
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

CRC_table:	ds.b	$200

DIRBLOCK	ds.b	512
ROOTBLOCK	ds.b	512
FILENAME	ds.b	30+2		; +2: null-termination+padding


	SECTION	FILES,BSS

Bitmap		ds.b	6*512
Directory	ds.b	7*512
Sector		ds.b	512*2
File		ds.b	100000		; largest file: 32768 bytes
