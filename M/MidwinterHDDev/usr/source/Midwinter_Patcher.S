	incdir	gore:asm/include/

	include	patcher.I
	include	devices/trackdisk.i
	include	exec/exec_lib.i
	include	exec/io.i
	include	libraries/dos_lib.i


tracklength	=$1400
syncindex	=$4489


;--- power to the people

j	moveq	#20,d0
	rts
;---

	dc.l	table				; pointer to patcher table
	dc.b	'PTCH'				; id


;--- version id

	dc.b	'$VER: Midwinter Imager by Dark Angel V1.1 [28/04/98]',0
	even


;--- patcher table

table	dc.l	pch_minversion,minvers		; minimum version required
	dc.l	pch_name,what4			; name of game
	dc.l	pch_adaptor,ididit		; who did it
	dc.l	pch_state,messa			; load messages
	dc.l	pch_state2,messb		; save messages
	dc.l	pch_filecount,3			; number of disks
	dc.l	pch_diskname,sources		; source disks
	dc.l	pch_filename,dests		; image names
	dc.l	pch_datalength,lengths		; image sizes
	dc.l	pch_init,init			; open source device
	dc.l	pch_special,special		; image loader
	dc.l	0


;--- minimum version required

minvers	dc.b	'V1.05'
	even


;--- imager messages

what4	dc.b	'Midwinter Imager for HD Install',0
	even

ididit	dc.b	'Written by Dark Angel',0
	even


;--- loading messages for the cycles

messa	dc.l	loadmsg
	dc.l	loadmsg
	dc.l	loadmsg
;---

loadmsg	dc.b	'Please insert your original writepro-',10
	dc.b	'tected disk in the source drive.',0
	even


;--- save messages for the cycles

messb	dc.l	savemsg
	dc.l	savemsg
	dc.l	savemsg
;---

savemsg	dc.b	'Please insert your destination disk.',0
	even


;--- names of the volume to save on

sources	dc.l	disk1
	dc.l	disk1
	dc.l	disk1
;---

disk1	dc.b	'Midwinter',0
	even


;--- name of the files to save

dests	dc.l	file1
	dc.l	file2
	dc.l	file3
;---

file1	dc.b	'Disk.1',0
file2	dc.b	'Disk.2',0
file3	dc.b	'Disk.3',0
	even


;--- table of lengths of the files

lengths	dc.l	78*tracklength
	dc.l	51*tracklength
	dc.l	80*tracklength


;--- the parameter initializing opens sourcedevice 

init	moveq	#0,d0
	move.l	ptb_opendevice(a5),a0
	jsr	(a0)
	tst.l	d0
	rts


;--- loader routines

special	dc.l	imager1
	dc.l	imager2
	dc.l	imager3

;------------------------------------------------------------------------
current_track	dc.l	0	; current track				=
still_to_read	dc.l	0	; count down filesize			=
pointer_image	dc.l	0	; pointer to current image position	=
pointer_decode	dc.l	0	; pointer to current decode position	=
track_offset	dc.l	0	; offset within track			=
retry_counter	dc.l	0	; retries for track reading		=
correct_disk	dc.l	0	; true after correct disk acknowledged	=
error_occured	dc.l	0	; true after an error has occured	=
;------------------------------------------------------------------------


;--- imager lower side

imager1	moveq	#0,d0
	move.l	ptb_inhibitdrive(a5),a0
	jsr	(a0)

	lea	correct_disk(pc),a0
	moveq	#0,d0
	move.l	d0,(a0)+			; one disk change allowed
	move.l	d0,(a0)				; no error...yet

.start	move.l	ptb_devicesourceptr(a5),a1
	move	#td_changestate,io_command(a1)
	move.l	4.w,a6
	jsr	_lvodoio(a6)			; disk in source drive?
	tst.l	io_actual(a1)
	beq.b	.diskin

	bsr.w	req_dsk
	beq.b	.start
	bra.w	failed
;---

.diskin	lea	current_track(pc),a0
	clr.l	(a0)				; start track

	bsr.w	msgread				; display track to read from

	move.l	ptb_devicesourceptr(a5),a1
	move.l	ptb_addressoffile(a5),a0
	move.l	a0,io_data(a1)
	move.l	#$400,io_length(a1)
	clr.l	io_offset(a1)
	move.w	#cmd_read,io_command(a1)
	clr.l	iotd_seclabel(a1)
	move.l	4.w,a6
	jsr	_lvodoio(a6)			; load bootblock
	tst.l	d0
	bne.w	failed

	lea	pointer_image(pc),a0
	move.l	ptb_addressoffile(a5),(a0)	; load first part of disk
	add.l	#tracklength,(a0)		; offset to load in dataspace

	lea	still_to_read(pc),a0
	move.l	ptb_filesize(a5),(a0)		; bytes to read alltogether
	sub.l	#tracklength,(a0)		; we've got bootblock already

	lea	current_track(pc),a0
	moveq	#2,d0
	move.l	d0,(a0)				; start track real image

	lea	track_offset(pc),a0
	moveq	#0,d0
	move.l	d0,(a0)				; start at beginning of track
	bra.b	.read
;---

.nxttrk	lea	track_offset(pc),a0		; when buffer not empty go on
	tst.l	(a0)				; transferring, else read next
	bne.b	.inbuff

.read	lea	retry_counter(pc),a0
	moveq	#5,d0
	move.l	d0,(a0)				; retry counter

	bsr.w	msgread				; display current track

.retry	move.l	ptb_devicesourceptr(a5),a1	; track loads into ptb_space
	move.l	ptb_space(a5),io_data(a1)	; double length of track to
	move.l	#$7c00,io_length(a1)		; decode index-sync-read data
	move.l	current_track(pc),io_offset(a1)
	move.w	#td_rawread,io_command(a1)
	move.b	#iotdb_indexsync,io_flags(a1)
	move.l	4.w,a6
	jsr	_lvodoio(a6)
	tst.l	d0
	bne.b	.nxttry

	bsr.w	decode
	beq.b	.trans

.nxttry	lea	retry_counter(pc),a0
	subq.l	#1,(a0)
	bne.b	.retry

	bsr.w	req_dsk				; if disk has already been
	beq.w	.start				; recognized -> read error

	bsr.w	reqertr				; display error track
	bra.b	failed
;---

.trans	lea	correct_disk(pc),a0
	moveq	#-1,d0
	move.l	d0,(a0)				; correct disk

	lea	current_track(pc),a0
	addq.l	#2,(a0)				; increment tracknumber

.inbuff	lea	track_offset(pc),a0
	lea	pointer_image(pc),a1
	move.l	(a0),d0
	move.l	(a1),a2
	move.l	pointer_decode(pc),a3

	move.b	(a3,d0.l),(a2)+

	move.l	a2,(a1)
	addq.l	#1,d0
	move.l	d0,(a0)

	cmp.l	#tracklength,d0
	bne.b	.noteot
	moveq	#0,d0
	move.l	d0,(a0)				; new track

.noteot	lea	still_to_read(pc),a0
	subq.l	#1,(a0)
	bgt.w	.nxttrk

	move.l	ptb_devicesourceptr(a5),a1
	clr.l	io_length(a1)
	move.w	#td_motor,io_command(a1)
	move.l	4.w,a6
	jsr	_lvodoio(a6)			; switch motor off

	move.l	error_occured(pc),d0
	rts
;---

failed	lea	error_occured(pc),a0
	moveq	#-1,d0
	move.l	d0,(a0)
	bra.w	leave


;--- imager upper side

imager2	lea	correct_disk(pc),a0
	moveq	#0,d0
	move.l	d0,(a0)+			; one disk change allowed
	move.l	d0,(a0)				; no error...yet

.start	move.l	ptb_devicesourceptr(a5),a1
	move	#td_changestate,io_command(a1)
	move.l	4.w,a6
	jsr	_lvodoio(a6)			; disk in source drive?
	tst.l	io_actual(a1)
	beq.b	.diskin

	bsr.w	req_dsk
	beq.b	.start
	bra.b	failed
;---

.diskin	lea	pointer_image(pc),a0
	move.l	ptb_addressoffile(a5),(a0)	; load first part of disk

	lea	still_to_read(pc),a0
	move.l	ptb_filesize(a5),(a0)		; bytes to read alltogether

	lea	current_track(pc),a0
	moveq	#1,d0
	move.l	d0,(a0)				; start track real image

	lea	track_offset(pc),a0
	moveq	#0,d0
	move.l	d0,(a0)				; start at beginning of track
	bra.b	.read
;---

.nxttrk	lea	track_offset(pc),a0		; when buffer not empty go on
	tst.l	(a0)				; transferring, else read next
	bne.b	.inbuff

.read	lea	retry_counter(pc),a0
	moveq	#5,d0
	move.l	d0,(a0)				; retry counter

	bsr.w	msgread				; display current track

.retry	move.l	ptb_devicesourceptr(a5),a1	; track loads into ptb_space
	move.l	ptb_space(a5),io_data(a1)	; double length of track to
	move.l	#$7c00,io_length(a1)		; decode index-sync-read data
	move.l	current_track(pc),io_offset(a1)
	move.w	#td_rawread,io_command(a1)
	move.b	#iotdb_indexsync,io_flags(a1)
	move.l	4.w,a6
	jsr	_lvodoio(a6)
	tst.l	d0
	bne.b	.nxttry

	bsr.w	decode
	beq.b	.trans

.nxttry	lea	retry_counter(pc),a0
	subq.l	#1,(a0)
	bne.b	.retry

	bsr.w	req_dsk				; if disk has already been
	beq.w	.start				; recognized -> read error

	bsr.w	reqertr				; display error track
	bra.w	failed
;---

.trans	lea	correct_disk(pc),a0
	moveq	#-1,d0
	move.l	d0,(a0)				; correct disk

	lea	current_track(pc),a0
	addq.l	#2,(a0)				; increment tracknumber

.inbuff	lea	track_offset(pc),a0
	lea	pointer_image(pc),a1
	move.l	(a0),d0
	move.l	(a1),a2
	move.l	pointer_decode(pc),a3

	move.b	(a3,d0.l),(a2)+

	move.l	a2,(a1)
	addq.l	#1,d0
	move.l	d0,(a0)

	cmp.l	#tracklength,d0
	bne.b	.noteot
	moveq	#0,d0
	move.l	d0,(a0)				; new track

.noteot	lea	still_to_read(pc),a0
	subq.l	#1,(a0)
	bgt.w	.nxttrk

leave	move.l	ptb_devicesourceptr(a5),a1	; switch motor off
	clr.l	io_length(a1)
	move.w	#td_motor,io_command(a1)
	move.l	4.w,a6
	jsr	_lvodoio(a6)

	moveq	#0,d0				; enable drive again
	move.l	ptb_enabledrive(a5),a0
	jsr	(a0)

	move.l	error_occured(pc),d0
	rts


;--- create dummy image

imager3	lea	error_occured(pc),a0
	moveq	#0,d0
	move.l	d0,(a0)				; no error...yet

	move.l	ptb_addressoffile(a5),a0
	move.l	ptb_filesize(a5),d7		; bytes to read alltogether

.clear	clr.b	(a0)+
	subq.l	#1,d7
	bne.b	.clear

	move.l	error_occured(pc),d0
	rts


;--- request correct disk in drive

req_dsk	lea	correct_disk(pc),a0		; if the first time the
	tst.l	(a0)				; original was not in the
	bne.b	.error				; source drive you'll be asked
	moveq	#-1,d0				; to put it there
	move.l	d0,(a0)

	move.l	ptb_devicesourceptr(a5),a1	; switch motor off
	clr.l	io_length(a1)
	move	#td_motor,io_command(a1)
	move.l	4.w,a6
	jsr	_lvodoio(a6)

	lea	loadmsg(pc),a0			; display 'please insert...'
	move.l	ptb_display(a5),a6
	jsr	(a6)

	lea	reqdsk1(pc),a0			; requester 'please insert...'
	lea	reqdsk2(pc),a1
	move.l	ptb_request(a5),a6
	jsr	(a6)
	tst.l	d0
	bne.b	.error

	moveq	#0,d0
	rts
;---

.error	moveq	#-1,d0
	rts


;--- show requester 'read error on track x'

reqertr	lea	ertrack(pc),a0
	move.l	current_track(pc),d0

	and.l	#$ff,d0
	divu	#10,d0
	swap	d0
	add.b	#$30,d0
	move.b	d0,2(a0)
	clr	d0
	swap	d0
	divu	#10,d0
	swap	d0
	add.b	#$30,d0
	move.b	d0,1(a0)
	clr	d0
	swap	d0
	divu	#10,d0
	swap	d0
	add.b	#$30,d0
	move.b	d0,(a0)

	lea	errtrk1(pc),a0
	lea	errtrk2(pc),a1
	move.l	ptb_request(a5),a6
	jmp	(a6)


;--- print message 'reading track x'

msgread	lea	rdtrack(pc),a0
	move.l	current_track(pc),d0

	and.l	#$ff,d0
	divu	#10,d0
	swap	d0
	add.b	#$30,d0
	move.b	d0,2(a0)
	clr	d0
	swap	d0
	divu	#10,d0
	swap	d0
	add.b	#$30,d0
	move.b	d0,1(a0)
	clr	d0
	swap	d0
	divu	#10,d0
	swap	d0
	add.b	#$30,d0
	move.b	d0,(a0)

	lea	readtr(pc),a0
	move.l	ptb_display(a5),a6
	jmp	(a6)


;--- messages

reqdsk1	dc.b	'Please insert your original',0
reqdsk2	dc.b	'disk in the source drive.',0
	even
;---

readtr	dc.b	'Reading track '
rdtrack	dc.b	'000.',0
	even
;---

errtrk1	dc.b	'Read error',0
errtrk2	dc.b	'on Track '
ertrack	dc.b	'000',0
	even


;--- search sync mark

sync	dc.w	syncindex

getsync	move	sync(pc),d1	    ; find sync in the bitstream, skip 
.shf2	moveq	#16-1,d5	    ; all syncwords and return 
.shf1	move.l	(a2),d0		    ; position: word (in a2) + bitshift (in d5)
	lsr.l	d5,d0
	cmp	d1,d0
	beq.b	.sync
	dbf	d5,.shf1
	addq.l	#2,a2
	cmp.l	a2,a4
	bhi.b	.shf2
	bra.b	.err
;---

.sync	move.l	(a2),d0
	addq.l	#2,a2
	lsr.l	d5,d0
	cmp.w	d1,d0
	beq.S	.sync
	subq.l	#2,a2
	cmp.l	a2,a4
	bls.b	.err
	moveq	#0,d0
	rts
;---

.err	moveq	#-1,d0
	rts


;COMMENT: a trackdecoderoutine is heavily based on the routine
;of the original, take it, remove all crap, set syncfinding on
;my provided routine and change the reads of words and longwords 
;in reads from the bitstream, often its also necessary to change
;the use of registers (eg move use of d5 to d7) - if thats not possible
;store the bitshift somewhere - either an or memory (slow) - see nitro-imager


;--- decode raw track

;< a0 raw track
;< a1 end raw buffer
;< a3 track buffer (=a1)
;> d0 error
;  d5 shift

decode	move.l	ptb_space(a5),a0		; begin of raw track
	lea	$7c00(a0),a1			; end of raw track=start of 
	lea	$7c00(a0),a3			; decoded track

	lea	pointer_decode(pc),a4
	move.l	a3,(a4)

	movem.l	d1-a7,-(sp)

	move.l	a0,a2
	lea	($7b80-tracklength*2)(a0),a4	; last chance for correct sync
						; (read length -$80 safety 
						;  -length of a raw track or
						;  sector)
	move.l	#$55555555,d6
	bsr.b	getsync
	tst.l	d0
	bne.b	.error

	lea	(a2),a4
	move	#tracklength*2+100,d4
.shift	move.l	(a4),d0
	lsr.l	d5,d0
	move	d0,(a4)+
	dbf	d4,.shift
;---

	lea	(a2),a0
	BSR.B	.decode
	CMP.B	current_track+3(pc),d0		; check track id
	BNe.B	.error

	lea	8(a2),a0
	BSR.B	.decode
	move.l	d0,d7				; store checksum

	lea	16(a2),a0
	move.W	#$2800,d1
	lsr	#2,d1
	move.l	(a0)+,d0
	subq	#2,d1
.calc	move.l	(a0)+,d2
	eor.l	d2,d0				; calculate checksum
	dbf	d1,.calc
	and.l	d6,d0

	CMP.l	d0,d7
	BNe.B	.error

	lea	16(a2),a0
	move	#$1400,d0
	lea	(a0,d0.W),a1
	lsr	#2,d0
	subq	#1,d0

.trans	move.l	(a0)+,d1
	move.l	(a1)+,d2
	and.l	d6,d1
	and.l	d6,d2
	add.l	d1,d1
	or.l	d2,d1
	move.l	d1,(a3)+
	dbf	d0,.trans

	movem.l	(sp)+,d1-a7
	moveq	#0,d0
	rts

.error	movem.l	(sp)+,d1-a7
	moveq	#-1,d0
	rts
;---

.decode	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	d6,d0
	and.l	d6,d1
	add.l	d0,d0
	or.l	d1,d0
	rts

rip
