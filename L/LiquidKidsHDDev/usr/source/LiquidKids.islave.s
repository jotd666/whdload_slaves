
                ; Son Shu Shi imager V1.0
                ;
                ; Track  000-159: Dos

                incdir  Include:
                include RawDIC.i

;_DiskImage      ; to replace File extraction by Disk images
;_Flash          ; Wait LMB+Flash for test

                IFD     BARFLY
                  IFD _DiskImage
                  OUTPUT  "LiquidKids-disk.islave"
                  else
                  OUTPUT  "LiquidKids.islave"
                  ENDC
                IFND    .passchk
                DOSCMD  "WDate >T:date"
.passchk
                ENDC
                ENDC


;=====================================================================

TRACK_LENGTH    equ     $1600
TRACK_NUMBER    equ     160
;=====================================================================

                SLAVE_HEADER
                dc.b    1       ; Slave version
                dc.b    0       ; Slave flags
                dc.l    DSK_1   ; Pointer to the first disk structure
                dc.l    Text    ; Pointer to the text displayed in the imager window

                dc.b    "$VER:"
Text:
                IFD _DiskImage
                dc.b    "Liquid Kids (disks) imager V1.0",10
                else
                dc.b    "Liquid Kids (files) imager V1.0",10
                ENDC
                dc.b    "by CFou! "
                IFD     BARFLY
                INCBIN  "T:date"
                ELSE
                dc.b    "(05.11.2005)"
                ENDC
                dc.b    0
                cnop    0,4

DSK_1           dc.l    0; DSK_2                ; Pointer to next disk structure
                dc.w    1                       ; Disk structure version
                dc.w    DFLG_NORESTRICTIONS|DFLG_ERRORS     ; Disk flags
                dc.l    TL_1                    ; List of tracks which contain data
                dc.l    0                       ; UNUSED, ALWAYS SET TO 0!
 IFD _DiskImage
                dc.l    FL_DISKIMAGE            ; List of files to be saved
                dc.l    0                       ; Table of certain tracks with CRC values
                dc.l    0                       ; Alternative disk structure, if CRC failed
                dc.l    0                       ; Called before a disk is read
                dc.l    0                       ; Called after a disk has been read
 else
                dc.l    FL_NULL                 ; List of files to be saved
                dc.l    0                       ; Table of certain tracks with CRC values
                dc.l    0                       ; Alternative disk structure, if CRC failed
                dc.l    0                       ; Called before a disk is read
                dc.l    _SaveDisk1              ; Called after a disk has been read
 ENDC


TL_1
               ; TLENTRY 000,000,$1600,SYNC_INDEX,_DMFM_STD_CUSTOM
                TLENTRY 000,TRACK_NUMBER-1,$1600,SYNC_INDEX,DMFM_STD
                TLEND

;=====================================================================
_DMFM_STD_CUSTOM
                IFD _Flash
.t
                move.w #$f,$dff180
                btst #6,$bfe001
                bne .t
                ENDC
                lea _DestBuffer(pc),a2
                move.l a1,(a2)
                move.l #11,d0   ; number of sector
                jsr     rawdic_DMFM_STANDARD(a5)
                rts

 IFD _DiskImage
 ; nothing

 else
_GetDiskImageBuffer
                movem.l d1-a6,-(a7)
                lea _DestBuffer(pc),a2
                move.l a5,a1    ; Rawbase
                move.l a5,a0
                move.l #TRACK_LENGTH*TRACK_NUMBER,d0
                sub.l #$600+2,a0  ; Rawbase pointer

.next
                tst.w (a0)+
                cmp.l 4(a0),d0
                bne .next
                cmp.l 8(a0),d0
                bne .next
                move.l (a0),(a2)
                bra .good

.bad
                move.l #$f00,d0
.enc
                move.w #$f0,$dff180
                dbf d0,.enc
                clr.l d0
.good
                movem.l (a7)+,d1-a6
                rts


_CreateTable1
                movem.l d0-a6,-(a7)
                clr.l d3
                lea     _FileTable1(pc),a2
                move.l #'ICE!',d0               ; header files
                move.l _DestBuffer(pc),a0
                move.l a0,a1
                move.l a0,a3
                add.l #TRACK_LENGTH*TRACK_NUMBER,a1
                clr.l d1
                bra .start
.next
                add.l #2,d1
                tst.w (a0)+
.next2
                cmp.l a1,a0
                bcc .end
.start
                cmp.l (a0),d0
                bne .next
                add.l #1,d3

                move.l d1,(a2)+      ; file offset
                move.l 4(a0),(a2)+   ; file lg
                move.l 4(a0),d2
                cmp.l #$96000,d1
                bne .pasbug
                add.l #$2800,d2      ; skip main loader  ; if not error rip it
                                     ; offset $98e00($4c7) lg $2723
.pasbug
                divu #$200,d2
                and.l #$ffff,d2
                add.l #1,d2
                mulu #$200,d2


                add.l d2,d1
                add.l d2,a0
                bra .next2
.end
                move.l #-1,(a2) ; end of list

                movem.l (a7)+,d0-a6
                rts

_SaveDisk1
                IFD _Flash
.t
                move.w #$f,$dff180
                btst #6,$bfe001
                bne .t
                ENDC
                bsr _GetDiskImageBuffer
                beq _OK   ; fin not found start adress of disk image
                bsr _CreateTable1

                move.l  #0,d0                   ;Save track 0 on disk 1
                move.l  #$1600,d1
                move.l  d0,d2
                bsr     _SaveFile               ;Save this file

                move.l  #$4c7*$200,d0           ;Save main loader not ICE!
                move.l  #$2723,d1
                move.l  d0,d2
                bsr     _SaveFile               ;Save this file

                lea     _FileTable0(pc),a2
                move.b  #'1',d0
                bsr _SaveDiskGen

                lea     _FileTable1(pc),a2      ; ICE! files
                move.b  #'1',d0
                bsr _SaveDiskGen
                bra _OK
_SaveDiskGen
_SaveDisk       lea     _DiskNumber(pc),a0      ;Store disk number
                move.b  d0,(a0)

.NextFile
                move.l  (a2)+,d0                ;Start offset
                move.l  (a2)+,d1                 ;Final offset (-1 = done)

                tst.l   d0                      ;Check if complete (-1 = done)
                blt     _OK2

                 move.l d0,d2
                bsr     _SaveFile               ;Save this file
                bra     .NextFile               ;And go again
_OK2
                rts
;=====================================================================

_SaveFile     movem.l d0-d1/a0-a2,-(sp)
                bsr     _GetFileNameA0          ;a0 = Filename
                lea     _FileName(pc),a0
                jsr     rawdic_SaveDiskFile(a5)
                movem.l (sp)+,d0-d1/a0-a2
                rts

;=====================================================================

_GetFileNameA0  lea     _FileNumber(pc),a0      ;d0 = File number
                move.l  d2,-(sp)
                divu #$200,d2                   ; take sector number

                 bsr     _NumToHex
                 move.b  d3,3(a0)
                 lsr.l #4,d2
                 bsr     _NumToHex
                 move.b  d3,2(a0)
                 lsr.l #4,d2
                 bsr     _NumToHex
                 move.b  d3,1(a0)
                 lsr.l #4,d2
                 bsr     _NumToHex
                 move.b  d3,0(a0)

                 move.l  (sp)+,d2
                rts

_NumToHex       move.b d2,d3
                and.b #$f,d3
                cmp.b   #9,d3
                bgt     .HexChar
                add.b   #'0',d3
                rts
.HexChar        add.b   #'a'-10,d3
                rts

_FileName       dc.b    "LiquidKids"
_FileNumber     dc.b    "0000.bin",0
_DiskNumber     dc.b    "1"
                EVEN
_DestBuffer
                dc.l 0

_OK             moveq   #IERR_OK,d0
                rts



;=====================================================================
_FileTable0
                dc.l $200*$16
                dc.l $200*$2
                dc.l $200*$18
                dc.l $200*$2
                dc.l $200*$1a
                dc.l $200*$2
                dc.l $200*$1c
                dc.l $200*$3
                dc.l $200*$1f
                dc.l $200*$6
                dc.l $200*$25
                dc.l $200*$4
                dc.l $200*$29
                dc.l $200*$3
                dc.l $200*$2c
                dc.l $200*$2
                dc.l $200*$2e
                dc.l $200*$6
                dc.l $200*$34
                dc.l $200*$2
                dc.l $200*$36
                dc.l $200*$3
                dc.l $200*$39
                dc.l $200*$9
                dc.l $200*$42
                dc.l $200*$2
                dc.l $200*$44
                dc.l $200*$2
                dc.l $200*$46
                dc.l $200*$3
                dc.l $200*$49
                dc.l $200*$2
                dc.l $200*$4b
                dc.l $200*$6
                dc.l $200*$51
                dc.l $200*$2
;---------------------------
                dc.l $200*$ee
                dc.l $200*$1
                dc.l $200*$ef
                dc.l $200*$1
                dc.l $200*$f0
                dc.l $200*$1
                dc.l $200*$f1
                dc.l $200*$1
                dc.l $200*$f2
                dc.l $200*$4
                dc.l $200*$f6
                dc.l $200*$2
                dc.l $200*$f8
                dc.l $200*$2
                dc.l $200*$fa
                dc.l $200*$1
                dc.l $200*$fb
                dc.l $200*$4
                dc.l $200*$ff
                dc.l $200*$2
                dc.l $200*$101
                dc.l $200*$2
                dc.l $200*$103
                dc.l $200*$3
                dc.l $200*$106
                dc.l $200*$1
                dc.l $200*$107
                dc.l $200*$1
                dc.l $200*$108
                dc.l $200*$2
                dc.l $200*$10a
                dc.l $200*$1
                dc.l $200*$10b
                dc.l $200*$3
                dc.l $200*$10e
                dc.l $200*$1
;-------------------------
                dc.l $200*$333
                dc.l $200*$1
                dc.l $200*$334
                dc.l $200*$1
                dc.l $200*$335
                dc.l $200*$1
                dc.l $200*$336
                dc.l $200*$1
                dc.l $200*$337
                dc.l $200*$1
                dc.l $200*$338
                dc.l $200*$1
                dc.l $200*$339
                dc.l $200*$1
                dc.l $200*$33a
                dc.l $200*$1
                dc.l $200*$33b
                dc.l $200*$1
                dc.l $200*$33c
                dc.l $200*$7
                dc.l $200*$343
                dc.l $200*$3
                dc.l $200*$346
                dc.l $200*$8
                dc.l $200*$34e
                dc.l $200*$6
                dc.l $200*$354
                dc.l $200*$3
                dc.l $200*$357
                dc.l $200*$4
                dc.l $200*$35b
                dc.l $200*$4
                dc.l $200*$35f
                dc.l $200*$9
                dc.l $200*$368
                dc.l $200*$6
;----------------------------  $36e
                dc.l $200*$371
                dc.l $200*$1
                dc.l $200*$372
                dc.l $200*$1
                dc.l $200*$373
                dc.l $200*$1
                dc.l $200*$374
                dc.l $200*$1
                dc.l $200*$375
                dc.l $200*$1
                dc.l $200*$376
                dc.l $200*$1
                dc.l $200*$377
                dc.l $200*$1
;-------------------------------- $378
                dc.l $200*$440
                dc.l $200*$1
                dc.l $200*$441
                dc.l $200*$1
;----------------------- boss 1
                dc.l $200*$40e
                dc.l $200*$d
;----------------------- apres boss 1 door Left
                dc.l $200*$41b
                dc.l $485c
;------------------------- last boss fire
                dc.l $200*$442
                dc.l $1380
                dc.l    -1

_FileTable1     ;dc.l   0                       ;Skip first file
                blk.l 45*2 ; 45 files
                dc.l    -1

 ENDC

 END
