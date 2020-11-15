
		; Pinball Fantasies disk imager
		;
		; Written by Jean-François Fabre. Adapted from Patcher imager
		; by Mr.Larmer/Wanted Team
        ;
		; Sector format description:
		;
		; sync ($2112)
		; sector data

        
		incdir	Include:
		include	RawDIC.i
        IFD     BARFLY
		OUTPUT	"PinballFantasies.islave"

		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
        ENDC
        
		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0	; Slave flags
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"Pinball Fantasies imager V1.0",10
		dc.b	"by Mr.Larmer/Wanted Team/JOTD on "
        IFD BARFLY
		INCBIN	"T:date"
        ELSE
        incbin	datetime
        ENDC
		dc.b	0
		cnop	0,4

DSK_1		
        dc.l	DSK_2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read
        
DSK_2		dc.l	DSK_3		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read
        
DSK_3		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS		; Disk flags
		dc.l	TL_3		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

RAWREADLEN	= $7c00
BYTESPERTRACK	= $1858
SYNC		= $2112
SYNC2		= $448A

TL_DSK:MACRO
TL_\1:
		TLENTRY	000,000,$1600,SYNC_STD,DMFM_STD
        ; repeating the first track to respect legacy imager format
		TLENTRY	000,000,BYTESPERTRACK-$1600,SYNC_STD,DMFM_NULL
		TLENTRY	001,\2,BYTESPERTRACK,SYNC,_DMFM
		TLEND
    ENDM
    
    TL_DSK  1,097
    TL_DSK  2,116
    TL_DSK  3,117
    



;======================================================================

_DMFM; IN:	A0 = raw
;	A1 = dest
; OUT:	D0 = error

   ; dc.w    $60FE
		movem.l	d1-a6,-(a7)
        move.w  (a0)+,d0
        cmp.w   #SYNC2,d0
        bne.b   .nosync
        
		bsr.b	.GetLongWords

		move.l	D0,D1

		bsr.b	.GetChecksum

		cmp.l	D0,D1
		bne.b	.fail

		move.w	#BYTESPERTRACK/4-1,D3
.loop
		bsr.b	.GetLongWords

		swap	D0
		move.w	D0,(A1)+
		swap	D0
		move.w	D0,(A1)+
		dbf	D3,.loop

		bra.b	.success

.fail		movem.l	(a7)+,a0/a1
        moveq	#IERR_CHECKSUM,d0
		bra.b	.quit

.success	moveq	#IERR_OK,d0
.quit	
		movem.l	(a7)+,d1-a6
		rts
.error		moveq	#IERR_NOSECTOR,d0
		bra.b	.quit
.nosync		moveq	#IERR_NOSYNC,d0
		bra.b	.quit
.GetLongWords
		move.l	(A0)+,D0
		move.l	(A0)+,D1

		and.l	#$55555555,D0
		and.l	#$55555555,D1
		add.l	D0,D0
		or.l	D1,D0

		rts

.GetChecksum
		movem.l	D1-D3/A0,-(A7)

		move.w	#BYTESPERTRACK/2-1,D2
		moveq	#0,D0
.loop2
		move.l	(A0)+,D1

		eor.l	D1,D0
		dbra	D2,.loop2

		and.l	#$55555555,D0

		movem.l	(A7)+,D1-D3/A0
		rts
        

