
	SECTION	ISlave,CODE
	OPT	O+,W-,P=68000

	; RawDIC imager slave for Killing Cloud
	; (c) 2001 Halibut Software

	INCDIR	INCLUDE:
	INCLUDE	RawDIC.i

;--------------------------------

	SLAVE_HEADER
	dc.b	1	; slv_Version
	dc.b	0	; slv_Flags
	dc.l	_d1	; slv_FirstDisk
	dc.l	_txt	; slv_Text

;--------------------------------

_d1:	dc.l	_d2	; dsk_NextDisk
	dc.w	1	; dsk_Version
	dc.w	0	; dsk_Flags
	dc.l	_d1_tl	; dsk_TrackList
	dc.l	0	; UNUSED
	dc.l	FL_DISKIMAGE	; dsk_FileList
	dc.l	0	; dsk_CRCList
	dc.l	0	; dsk_AltDisk
	dc.l	0	; dsk_InitCode
	dc.l	0	; dsk_DiskCode

_d1_tl:	TLENTRY	000,001,$1600,SYNC_STD,DMFM_STD
	TLENTRY	002,159,$1200,$4489,_dmfm
	TLEND

;----------

_d2:	dc.l	0	; dsk_NextDisk
	dc.w	1	; dsk_Version
	dc.w	0	; dsk_Flags
	dc.l	_d2_tl	; dsk_TrackList
	dc.l	0	; UNUSED
	dc.l	FL_DISKIMAGE	; dsk_FileList
	dc.l	0	; dsk_CRCList
	dc.l	0	; dsk_AltDisk
	dc.l	0	; dsk_InitCode
	dc.l	0	; dsk_DiskCode

_d2_tl:	TLENTRY	000,159,$1200,$4489,_dmfm
	TLEND

;--------------------------------

	; >d0=track number
	; >a0=MFM source
	; >a1=dest

_dmfm:	; decode track to 9 * $212 sectors in temporary buffer

	subq.l	#8,a0	; a0=MFM start
	lea	$6800(a0),a2	; a2=MFM end
	lea	_buf_track,a3	; a3=temp track buffer
	moveq	#9-1,d7	; 9 sectors/track
.dm_sector_loop:

	; decode and check this sector

	move.w	#$5554,d0	; skip to sector header
	bsr.s	_dmfm_nextsync
	bmi.s	.dm_err_ns

	moveq	#8-1,d0	; decode sector header
	lea	(a3),a4
	move.l	#$a1a1a1fe,d1
	bsr	_dmfm_block
	bmi.s	.dm_err_cs

	move.w	#$5545,d0	; skip to sector data
	bsr.s	_dmfm_nextsync
	bmi.s	.dm_err_ns

	move.w	#$204-1,d0	; decode sector data
	lea	$a(a3),a4
	move.l	#$a1a1a1fb,d1
	bsr	_dmfm_block
	bmi.s	.dm_err_cs

	; sector ok, copy to output

	lea	$e(a3),a4	; a4=source
	moveq	#0,d0	; a5=destination
	move.b	6(a3),d0
	subq.b	#1,d0
	mulu	#512,d0
	lea	0(a1,d0.l),a5
	moveq	#32-1,d0	; copy 512 bytes
.dm_copy_loop:
	move.l	(a4)+,(a5)+
	move.l	(a4)+,(a5)+
	move.l	(a4)+,(a5)+
	move.l	(a4)+,(a5)+
	dbf	d0,.dm_copy_loop

	cmp.b	#9,6(a3)	; if sector 9, we might need to bitrot
	bne.s	.dm_next	;   remaining mfm to find sector 1 sync
	bsr.s	_dmfm_rottofind4489	;   after index gap
	bmi.s	.dm_err_ns

.dm_next:	lea	$212(a3),a3	; loop for next sector
	dbf	d7,.dm_sector_loop

	moveq	#IERR_OK,d0	; all OK
	rts

.dm_err_ns:	moveq	#IERR_NOSYNC,d0
	rts

.dm_err_cs:	moveq	#IERR_CHECKSUM,d0
	rts

;----------

	; skip to after next sync word
	; >d0=sync
	; >a0=mfm
	; >a2=mfm end
	; <d0=0 if sync found, -1 if not found
	; <a0=mfm after next sync

_dmfm_nextsync:
	move.l	d1,-(a7)
	move.l	#$44890000,d1	; look for $4489,$SYNC
	move.w	d0,d1
	moveq	#0,d0
.ns1:	cmp.l	(a0)+,d1
	beq.s	.ns2
	subq.l	#2,a0
	cmp.l	a2,a0
	blt.s	.ns1
	moveq	#-1,d0
.ns2:	move.l	(a7)+,d1
	tst.l	d0
	rts

;--------------------------------

	; bit rotate mfm data until sync word appears
	; >a0=mfm start
	; >a2=mfm end
	; <d0=0 if sync found, -1 if not found

_dmfm_rottofind4489:
	movem.l	d5-7/a0,-(a7)

	moveq	#15,d7	; d7=number of shifts to try
	move.l	a2,d6	; d6=number of words to shift
	sub.l	a0,d6
	asr.l	#1,d6
	subq.l	#1,d6
	moveq	#0,d0	; init return code

	movem.l	d6/a0,-(a7)	; save len/start
.rtf_tryloop:

	; search for sync in current mfm

	move.w	#$4489,d5
.rtf_sloop:	cmp.w	(a0)+,d5
	beq.s	.rtf_done
	dbf	d6,.rtf_sloop

	; didnt find sync - rotate mfm one bit and try again

	movem.l	(a7),d6/a0	; rotate mfm data
	move.w	#0,ccr
.rtf_rotloop:
	roxr.w	(a0)+
	dbf	d6,.rtf_rotloop
	moveq	#0,d5	; store last bit rotated out
	roxr.w	#1,d5	; as new first bit
	movem.l	(a7),d6/a0
	or.w	d5,(a0)

	dbf	d7,.rtf_tryloop	; loop back for next try

	moveq	#-1,d0	; didnt find sync!

.rtf_done:	addq.l	#8,a7	; back to caller
	movem.l	(a7)+,d5-7/a0
	tst.l	d0
	rts

;--------------------------------

	; decode, decrypt and checksum a block of mfm
	; > d0=block length
	; > d1=initial checksum seed
	; > a0=mfm source
	; > a4=destination
	; < d0=0 if checksum ok, -1 otherwise

_dmfm_block:	movem.l	d1-7/a1-6,-(a7)

	movem.l	d0/a4,-(a7)	; save count/dest

	; decode mfm to destination

	lea	.db_decbtab(pc),a2	; a2=decryption table
	moveq	#$55,d7	; d7=decode constant
	move.l	d1,(a4)+	; store seed long
.db_loop1:	move.b	(a0)+,d1	; decode mfm word to data byte
	and.l	d7,d1
	move.b	(a0)+,d2
	and.l	d7,d2
	add.b	d1,d1
	or.b	d2,d1
	move.b	0(a2,d1.l),(a4)+
	dbf	d0,.db_loop1

	movem.l	(a7)+,d0/a4	; restore count/dest

	; checksum decoded mfm

	lea	.db_csumtab(pc),a2	; a2,a3=checksum tables
	lea	$100(a2),a3
	moveq	#-1,d6	; initialise checksum
	moveq	#-1,d7
.db_loop2:	move.b	(a4)+,d1
	eor.b	d6,d1
	move.b	0(a2,d1.l),d6
	eor.b	d7,d6
	move.b	0(a3,d1.l),d7
	dbf	d0,.db_loop2

	cmp.b	(a4)+,d6	; compare checksum
	bne.s	.db_err
	cmp.b	(a4)+,d7
	bne.s	.db_err

	movem.l	(a7)+,d1-7/a1-6	; all ok
	moveq	#0,d0
	rts

.db_err:	movem.l	(a7)+,d1-7/a1-6	; checksum error!
	moveq	#-1,d0
	rts

;-----

.db_decbtab:	dc.b $00,$01,$10,$11,$02,$03,$12,$13
	dc.b $20,$21,$30,$31,$22,$23,$32,$33
	dc.b $04,$05,$14,$15,$06,$07,$16,$17
	dc.b $24,$25,$34,$35,$26,$27,$36,$37
	dc.b $40,$41,$50,$51,$42,$43,$52,$53
	dc.b $60,$61,$70,$71,$62,$63,$72,$73
	dc.b $44,$45,$54,$55,$46,$47,$56,$57
	dc.b $64,$65,$74,$75,$66,$67,$76,$77
	dc.b $08,$09,$18,$19,$0A,$0B,$1A,$1B
	dc.b $28,$29,$38,$39,$2A,$2B,$3A,$3B
	dc.b $0C,$0D,$1C,$1D,$0E,$0F,$1E,$1F
	dc.b $2C,$2D,$3C,$3D,$2E,$2F,$3E,$3F
	dc.b $48,$49,$58,$59,$4A,$4B,$5A,$5B
	dc.b $68,$69,$78,$79,$6A,$6B,$7A,$7B
	dc.b $4C,$4D,$5C,$5D,$4E,$4F,$5E,$5F
	dc.b $6C,$6D,$7C,$7D,$6E,$6F,$7E,$7F
	dc.b $80,$81,$90,$91,$82,$83,$92,$93
	dc.b $A0,$A1,$B0,$B1,$A2,$A3,$B2,$B3
	dc.b $84,$85,$94,$95,$86,$87,$96,$97
	dc.b $A4,$A5,$B4,$B5,$A6,$A7,$B6,$B7
	dc.b $C0,$C1,$D0,$D1,$C2,$C3,$D2,$D3
	dc.b $E0,$E1,$F0,$F1,$E2,$E3,$F2,$F3
	dc.b $C4,$C5,$D4,$D5,$C6,$C7,$D6,$D7
	dc.b $E4,$E5,$F4,$F5,$E6,$E7,$F6,$F7
	dc.b $88,$89,$98,$99,$8A,$8B,$9A,$9B
	dc.b $A8,$A9,$B8,$B9,$AA,$AB,$BA,$BB
	dc.b $8C,$8D,$9C,$9D,$8E,$8F,$9E,$9F
	dc.b $AC,$AD,$BC,$BD,$AE,$AF,$BE,$BF
	dc.b $C8,$C9,$D8,$D9,$CA,$CB,$DA,$DB
	dc.b $E8,$E9,$F8,$F9,$EA,$EB,$FA,$FB
	dc.b $CC,$CD,$DC,$DD,$CE,$CF,$DE,$DF
	dc.b $EC,$ED,$FC,$FD,$EE,$EF,$FE,$FF

;-----

.db_csumtab:	dc.b $00,$10,$20,$30,$40,$50,$60,$70
	dc.b $81,$91,$A1,$B1,$C1,$D1,$E1,$F1
	dc.b $12,$02,$32,$22,$52,$42,$72,$62
	dc.b $93,$83,$B3,$A3,$D3,$C3,$F3,$E3
	dc.b $24,$34,$04,$14,$64,$74,$44,$54
	dc.b $A5,$B5,$85,$95,$E5,$F5,$C5,$D5
	dc.b $36,$26,$16,$06,$76,$66,$56,$46
	dc.b $B7,$A7,$97,$87,$F7,$E7,$D7,$C7
	dc.b $48,$58,$68,$78,$08,$18,$28,$38
	dc.b $C9,$D9,$E9,$F9,$89,$99,$A9,$B9
	dc.b $5A,$4A,$7A,$6A,$1A,$0A,$3A,$2A
	dc.b $DB,$CB,$FB,$EB,$9B,$8B,$BB,$AB
	dc.b $6C,$7C,$4C,$5C,$2C,$3C,$0c,$1C
	dc.b $ED,$FD,$CD,$DD,$AD,$BD,$8D,$9D
	dc.b $7E,$6E,$5E,$4E,$3E,$2E,$1E,$0E
	dc.b $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
	dc.b $91,$81,$B1,$A1,$D1,$C1,$F1,$E1
	dc.b $10,$00,$30,$20,$50,$40,$70,$60
	dc.b $83,$93,$A3,$B3,$C3,$D3,$E3,$F3
	dc.b $02,$12,$22,$32,$42,$52,$62,$72
	dc.b $B5,$A5,$95,$85,$F5,$E5,$D5,$C5
	dc.b $34,$24,$14,$04,$74,$64,$54,$44
	dc.b $A7,$B7,$87,$97,$E7,$F7,$C7,$D7
	dc.b $26,$36,$06,$16,$66,$76,$46,$56
	dc.b $D9,$C9,$F9,$E9,$99,$89,$B9,$A9
	dc.b $58,$48,$78,$68,$18,$08,$38,$28
	dc.b $CB,$DB,$EB,$FB,$8B,$9B,$AB,$BB
	dc.b $4A,$5A,$6A,$7A,$0A,$1A,$2A,$3A
	dc.b $FD,$ED,$DD,$CD,$BD,$AD,$9D,$8D
	dc.b $7C,$6C,$5C,$4C,$3C,$2C,$1C,$0C
	dc.b $EF,$FF,$CF,$DF,$AF,$BF,$8F,$9F
	dc.b $6E,$7E,$4E,$5E,$2E,$3E,$0E,$1E
	dc.b $00,$21,$42,$63,$84,$A5,$C6,$E7
	dc.b $08,$29,$4A,$6B,$8C,$AD,$CE,$EF
	dc.b $31,$10,$73,$52,$B5,$94,$F7,$D6
	dc.b $39,$18,$7B,$5A,$BD,$9C,$FF,$DE
	dc.b $62,$43,$20,$01,$E6,$C7,$A4,$85
	dc.b $6A,$4B,$28,$09,$EE,$CF,$AC,$8D
	dc.b $53,$72,$11,$30,$D7,$F6,$95,$B4
	dc.b $5B,$7A,$19,$38,$DF,$FE,$9D,$BC
	dc.b $C4,$E5,$86,$A7,$40,$61,$02,$23
	dc.b $CC,$ED,$8E,$AF,$48,$69,$0A,$2B
	dc.b $F5,$D4,$B7,$96,$71,$50,$33,$12
	dc.b $FD,$DC,$BF,$9E,$79,$58,$3B,$1A
	dc.b $A6,$87,$E4,$C5,$22,$03,$60,$41
	dc.b $AE,$8F,$EC,$CD,$2A,$0B,$68,$49
	dc.b $97,$B6,$D5,$F4,$13,$32,$51,$70
	dc.b $9F,$BE,$DD,$FC,$1B,$3A,$59,$78
	dc.b $88,$A9,$CA,$EB,$0c,$2D,$4E,$6F
	dc.b $80,$A1,$C2,$E3,$04,$25,$46,$67
	dc.b $B9,$98,$FB,$DA,$3D,$1C,$7F,$5E
	dc.b $B1,$90,$F3,$D2,$35,$14,$77,$56
	dc.b $EA,$CB,$A8,$89,$6E,$4F,$2C,$0D
	dc.b $E2,$C3,$A0,$81,$66,$47,$24,$05
	dc.b $DB,$FA,$99,$B8,$5F,$7E,$1D,$3C
	dc.b $D3,$F2,$91,$B0,$57,$76,$15,$34
	dc.b $4C,$6D,$0E,$2F,$C8,$E9,$8A,$AB
	dc.b $44,$65,$06,$27,$C0,$E1,$82,$A3
	dc.b $7D,$5C,$3F,$1E,$F9,$D8,$BB,$9A
	dc.b $75,$54,$37,$16,$F1,$D0,$B3,$92
	dc.b $2E,$0F,$6C,$4D,$AA,$8B,$E8,$C9
	dc.b $26,$07,$64,$45,$A2,$83,$E0,$C1
	dc.b $1F,$3E,$5D,$7C,$9B,$BA,$D9,$F8
	dc.b $17,$36,$55,$74,$93,$B2,$D1,$F0

;--------------------------------

_ver:	dc.b	"$VER: "
_txt:	dc.b	"Killing Cloud imager "
	INCLUDE	Version.i
	dc.b	10
	INCLUDE	Copyright.i
	dc.b	0
	EVEN

;--------------------------------

	SECTION	Buffer1,BSS
_buf_track:	ds.b	$1300

;--------------------------------
