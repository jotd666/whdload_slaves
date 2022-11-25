;this is an example of converting a multidisked game, use of 
;  cyclenumber in D6, use it as basic structure if all disks 
;  have the same structure
;additionally it is one of the more seldom examples of decoding a 
;  sectorized disk

	INCDIR	ASM-ONE:INCLUDE2.0/

	INCLUDE	OWN/Patcher.I
	INCLUDE	DEVICES/TRACKDISK.I
	INCLUDE	EXEC/EXEC_LIB.I
	INCLUDE	EXEC/IO.I
	INCLUDE	LIBRARIES/DOS_LIB.I
	INCLUDE	LIBRARIES/FILEHANDLER.I

	INCDIR	ASM-ONE:OWN/PATCHER/PARAMQTX/


HP	MOVEQ.L	#20,D0
	RTS
	DC.L	TAB
	DC.B	'PTCH'
	DC.B	'$VER:Wrath_of_the_Demon_Diskimager_V1.00',0
	EVEN

TAB	DC.L	PCH_INIT,INITROUT
	DC.L	PCH_FILECOUNT,4
	DC.L	PCH_ADAPTOR,ADNAME
	DC.L	PCH_DISKNAME,DISKNAMEARRAY
	DC.L	PCH_FILENAME,FILENAMEARRAY
	DC.L	PCH_NAME,PARAMNAME
	DC.L	PCH_DATALENGTH,LENGTHTABLE
	DC.L	PCH_SPECIAL,SPECIALARRAY
	DC.L	PCH_STATE,STATEARRAY
	DC.L	PCH_STATE2,STATEARRAY2
	DC.L	PCH_MINVERSION,VERSNAME		;minimum version of THE PATCHER
	DC.L	0

;minimum version of the patcher required
VERSNAME	DC.B	'V1.05'		;MAY NOT CONTAIN HEADING ZEROES
	EVEN				;MUST CONTAIN 2 NUMBERS AFTER POINT


ADNAME	DC.B	'Done by Harry.',0
	EVEN


PARAMNAME
	DC.B	'Wrath of the Demon, Imager for HD-install',0
	EVEN


DISKNAMEARRAY	DC.L	DISK1NAME
	DC.L	DISK1NAME
	DC.L	DISK1NAME
	DC.L	DISK1NAME

DISK1NAME	DC.B	'WrathOfTheDemon',0
	EVEN


FILENAMEARRAY
	DC.L	FILE1NAME
	DC.L	FILE2NAME
	DC.L	FILE3NAME
	DC.L	FILE4NAME

FILE1NAME	DC.B	'disk.1',0
	EVEN
FILE2NAME	DC.B	'disk.2',0
	EVEN
FILE3NAME	DC.B	'disk.3',0
	EVEN
FILE4NAME	DC.B	'disk.4',0
	EVEN

LENGTHTABLE
	DC.L	$8F*$1900
	DC.L	$99*$1900
	DC.L	$70*$1900
	DC.L	($a0)*$1900


;the parameter-initializing opens sourcedevice 
INITROUT
	MOVE.B	#'1',DISKNR		;set number for display to 1 on init
	MOVE.B	#'1',DISKNR2
	MOVEQ.L	#0,D0
	MOVE.L	PTB_OPENDEVICE(A5),A0
	JSR	(A0)
	TST.L	D0
	RTS

;loading-statetexts for the cycles
STATEARRAY	DC.L	LOADSTATE
	DC.L	LOADSTATE
	DC.L	LOADSTATE
	DC.L	LOADSTATE

LOADSTATE
	DC.B	'Please insert your original writepro-',$A
	DC.B	'tected disk '
disknr	dc.b	'1 in the source drive.',0
	EVEN

STATEARRAY2	DC.L	SAVESTATE
	DC.L	SAVESTATE
	DC.L	SAVESTATE
	DC.L	SAVESTATE

SAVESTATE	
	DC.B	'Please insert your destination disk.',0
	EVEN

;routines to 'load' something
SPECIALARRAY	DC.L	LOADROUT	;load stuff from original
	DC.L	LOADROUT
	DC.L	LOADROUT
	DC.L	LOADROUT

STARTTRACK	DC.B	3,0,0,0

LOADROUT
	MOVEQ.L	#0,D7
	CMP.B	#0,D6			;inhibit drive only on first cycle
	BNE.S	.NOINHIBIT
	MOVEQ.L	#0,D0
	MOVE.L	PTB_INHIBITDRIVE(A5),A0
	JSR	(A0)
.NOINHIBIT
;	BRA.W	.NOTORG			;at first imaging you have of course
					;no idea to recognize disks, so ask
					;every cycle for the right disk

.NEU


.4	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1
	MOVE.W	#TD_CHANGESTATE,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	IO_ACTUAL(A1)
	BNE.W	.NOTORG

	MOVE.L	PTB_ADDRESSOFFILE(A5),A4	;load first part of disk
	LEA.L	(A4),A2				;offset to load in the dataspace
	MOVE.L	PTB_FILESIZE(A5),D3		;bytes to read

	MOVEQ.L	#0,D2				;get starttrack from table
	MOVE.B	STARTTRACK(PC,D6.W),D2

	CMP.B	#0,D6				;first cycle (=first disk)?
	BNE.W	.STTRACK0

	MOVEQ.L	#0,D0				;display readingmessage
	BSR.W	TRACKREADING
	
	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;on first disk, load some
	MOVE.L	A4,IO_DATA(A1)  		;normal tracks in the
	MOVE.L	#$1200,IO_LENGTH(A1)		;datafile, waste of $200 byte
	MOVE.L	#$400,IO_OFFSET(A1)
	MOVE.W	#CMD_READ,IO_COMMAND(A1)
	CLR.L	IOTD_SECLABEL(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	D0
	BNE.W	.NOTORG

	CMP.L	#$F7DA2C79,8(A4)		;final check for first disk
	BNE.W	.NOTORG

	ST	D7				;disk recognized

	MOVEQ.L	#1,D0
	BSR.W	TRACKREADING

	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1
	LEA.L	$1200(A4),A0
	MOVE.L	A0,IO_DATA(A1)
	MOVE.L	#$1600,IO_LENGTH(A1)
	MOVE.L	#$1600,IO_OFFSET(A1)
	MOVE.W	#CMD_READ,IO_COMMAND(A1)
	CLR.L	IOTD_SECLABEL(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	D0
	BNE.W	.NOTORG

	MOVEQ.L	#2,D0
	BSR.W	TRACKREADING

	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1
	LEA.L	$2800(A4),A0
	MOVE.L	A0,IO_DATA(A1)
	MOVE.L	#$800,IO_LENGTH(A1)
	MOVE.L	#$2C00,IO_OFFSET(A1)
	MOVE.W	#CMD_READ,IO_COMMAND(A1)
	CLR.L	IOTD_SECLABEL(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	D0
	BNE.W	.NOTORG

	LEA.L	$1900*2(A4),A2			;skip 2 tracks (they are 
	SUB.L	#$1900*2,D3			;already loaded)

.STTRACK0
	MOVEQ.L	#0,D4				;data from the start of the track
;	bra.s	.5				;because reading starts with
						;trackstart, this is obsolete

.3	TST.L	D4
	BNE.W	.1
.5

	MOVE.L	D2,D0
	BSR.W	TRACKREADING

	MOVEQ.L	#$4,D5				;4 tries, then error

.55
	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1
	MOVE.L	PTB_SPACE(A5),IO_DATA(A1)	;track is to load in PTB_SPACE
	MOVE.L	#$7C00,IO_LENGTH(A1)		;double length of track
						;to decode the index-sync-read data
						;my own trackcounter
	MOVE.L	D2,D0
	MOVE.L	D0,IO_OFFSET(A1)
	MOVE.W	#TD_RAWREAD,IO_COMMAND(A1)
	MOVE.B	#IOTDB_INDEXSYNC,IO_FLAGS(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	D0
	BNE.W	.NXCYCLE
	MOVE.L	PTB_SPACE(A5),A0
	LEA.L	$7C00(A0),A1			;end of buffer
	LEA.L	$7C00(A0),A3
	BSR.W	TRACKDECODE
	TST.L	D0
	BEQ.S	.R1OK
.NXCYCLE
	DBF	D5,.55


	IFEQ	1				;COMMENTED!
	MOVE.L	PTB_SPACE(A5),A0		;for me, that i see wrong
	LEA.L	$7C00(A0),A3			;track instead of abandoning
	MOVE.L	A3,A0				;at first imaging
	MOVE.W	#$2000/4-1,D0
.TE1	MOVE.L	#'NNNN',(A0)+
	DBF	D0,.TE1
	BRA.S	.R1OK
	ENDC

	TST.L	D7
	BNE.W	.DISPERR
	BRA.W	.NOTORG

.R1OK
						;of course you may comment this
						;with IFEQ 1 on first imaging

	CMP.B	#0,D2				;DISKCHECK
	BNE.S	.R3OK				;on track 00
	CMP.B	#1,D6				;2nd disk?
	BNE.S	.D3
	CMP.L	#$5F8408E2,4(A3)
	BNE.S	.NOTORG
	BRA.S	.R2OK

.D3	CMP.B	#2,D6				;3rd disk?
	BNE.S	.D4
	CMP.L	#$F8185D08,(A3)
	BNE.S	.NOTORG
	BRA.S	.R2OK

.D4	CMP.B	#3,D6				;4th disk?
	BNE.S	.R3OK
	CMP.L	#$D6BEEBFF,4(A3)
	BNE.S	.NOTORG

.R2OK
	ST	D7				;correct disk - nothing anymore
						;to change
.R3OK	ADDQ.L	#1,D2

.1	MOVE.B	(A3)+,(A2)+
	ADDQ.L	#1,D4
	CMP.L	#$1900,D4			;tracklength
	BNE.S	.2
	MOVEQ.L	#0,D4				;new track
.2	SUBQ.L	#1,D3
	BNE.W	.3

	MOVEQ.L	#0,D4
.END

	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;switch motor off
	MOVE.L	#0,IO_LENGTH(A1)
	MOVE.W	#TD_MOTOR,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	D4			;enable drive on error
	BNE.S	.EAGAIN
	CMP.B	#3,D6			;or on last cycle
	BNE.S	.SKENABLE
.EAGAIN
	MOVEQ.L	#0,D0
	MOVE.L	PTB_ENABLEDRIVE(A5),A0
	JSR	(A0)
.SKENABLE
	ADDQ.B	#1,DISKNR		;set disknumber-displays to next disk
	ADDQ.B	#1,DISKNR2

	MOVE.L	D4,D0
	RTS

.ERR	MOVEQ.L	#-1,D4
	BRA.S	.END

.NOTORG	TST.L	D7			;if the first time the original
	BNE.S	.ERR			;was not in the source drive,
	ST	D7			;youll be asked to put it there

	LEA.L	LOADSTATE(PC),A0	;display 'please insert...'
	MOVE.L	PTB_DISPLAY(A5),A6
	JSR	(A6)

	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;motor off
	MOVE.L	#0,IO_LENGTH(A1)
	MOVE.W	#TD_MOTOR,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	LEA.L	LINE1(PC),A0
	LEA.L	LINE2(PC),A1
	MOVE.L	PTB_REQUEST(A5),A6	;requester 'please insert...'
	JSR	(A6)
	TST.L	D0
	BNE.S	.ERR
	BRA.W	.NEU

.DISPERR
	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;motor off
	MOVE.L	#0,IO_LENGTH(A1)
	MOVE.W	#TD_MOTOR,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	BSR.W	TRACKERROR
	BRA.S	.ERR

TRACKERROR
	MOVE.B	D2,D0
	AND.L	#$FF,D0
	DIVU.W	#$A,D0
	SWAP	D0
	ADD.B	#$30,D0
	MOVE.B	D0,ETRACK+2
	CLR.W	D0
	SWAP	D0
	DIVU.W	#$A,D0
	SWAP	D0
	ADD.B	#$30,D0
	MOVE.B	D0,ETRACK+1
	CLR.W	D0
	SWAP	D0
	DIVU.W	#$A,D0
	SWAP	D0
	ADD.B	#$30,D0
	MOVE.B	D0,ETRACK

	LEA.L	LINEE1(PC),A0
	LEA.L	LINEE2(PC),A1
	MOVE.L	PTB_REQUEST(A5),A6
	JSR	(A6)
	RTS

TRACKREADING				;message 'reading track 000'
	AND.L	#$FF,D0
	DIVU.W	#$A,D0
	SWAP	D0
	ADD.B	#$30,D0
	MOVE.B	D0,RTRACK+2
	CLR.W	D0
	SWAP	D0
	DIVU.W	#$A,D0
	SWAP	D0
	ADD.B	#$30,D0
	MOVE.B	D0,RTRACK+1
	CLR.W	D0
	SWAP	D0
	DIVU.W	#$A,D0
	SWAP	D0
	ADD.B	#$30,D0
	MOVE.B	D0,RTRACK

	LEA.L	READINGNR(PC),A0
	MOVE.L	PTB_DISPLAY(A5),A6
	JSR	(A6)
	RTS

LINEE1	DC.B	'Read Error',0
	EVEN
LINEE2	dc.b	'on Track '
ETRACK	DC.B	'000',0
	EVEN

READINGNR
	DC.B	'Reading track '
RTRACK	DC.B	'000.',0
	EVEN

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11
LINE1	DC.B	'Please insert your original',0
	EVEN
LINE2	DC.B	'disk '
DISKNR2	DC.B	'1 in the source drive.',0
	EVEN



;< A0 RAWTRACK
;< A1 TRACKBUFFER
;> D0 ERROR

SYNC	DC.W	$4489

GETSYNC
;SYNCANFANG SUCHEN
	MOVE.W	SYNC(PC),D1
.SHF2	MOVEQ.L	#$10-1,D5
.SHF1	MOVE.L	(A2),D0
	LSR.L	D5,D0
	CMP.W	D1,D0
	BEQ.S	.SY
	DBF	D5,.SHF1
	ADDQ.L	#2,A2
	CMP.L	A2,A4
	BHI.S	.SHF2
	BRA.S	.ERR
.SY	

.1	MOVE.L	(A2),D0
	ADDQ.L	#2,A2
	LSR.L	D5,D0
	CMP.W	D1,D0
	BEQ.S	.1
	SUBQ.L	#2,A2
	CMP.L	A2,A4
	BLS.S	.ERR
	MOVEQ.L	#0,D0
	RTS

.ERR	MOVEQ.L	#-1,D0
	RTS



;< A0 RAWTRACK
;< A1 TRACKBUFFER
;> D0 ERROR
;INTERNAL
;  D5 SHIFT
;  D7 SEKTORCOUNT
;format is 4 sectors with $640 bytes each (long track)

TRACKDECODE	MOVEM.L	A2/A3/A4/A5/D2/D3/D4/D5/D6/D7,-(A7)
	MOVE.L	A0,A2
	LEA.L	($7C00-$680*2)(A0),A4
	MOVE.L	#%1111,D7	;for each unloaded sector 1 bit in D7 
				;(total 4 sectors)


.NEXTSEC
.ANF	MOVE.L	#$55555555,D3
	BSR.W	GETSYNC		;get sync
	TST.L	D0
	BNE.W	.ERR

	BSR.S	DEC1L		;get sectornumber (like original)
	MOVE.L	D0,D2

	BSR.S	DEC1L		;as 'headerchecksum' like original
	EOR.L	D2,D0
	ADDQ.L	#1,D0
	BNE.S	.NEXTSEC
	;contents of D2:$XXXX<SECTOR><TRACK>

				;now get sectordata

	LSR.W	#8,D2		;get sectornumber
	AND.L	#$FF,D2
	
	BTST	D2,D7		;sector already present (happens only if
	BEQ.S	.NEXTSEC	;track is a bit erroneus)


	MOVEQ.L	#0,D0
	MOVE.W	D2,D0
	MULU	#$640,D0	;offset of that sector in the tracktable
	LEA.L	0(A1,D0.L),A3

	LEA.L	$640(A2),A0	;displacement for decoding

.DECSEC
	MOVE.L	#$640/4-1,D4	;decode sectordata
.DECSEC1	BSR.W	DEC1L640
	MOVE.L	D0,(A3)+
	DBF	D4,.DECSEC1
	LEA.L	$640(A2),A2	;skip half sector (already used in A0)
	
	BSR.S	DEC1L		;get sectorchecksum
	MOVE.L	D0,D4

	BSR.S	CHKSUMSECTOR	;evaluate sectorchecksum
	CMP.L	D0,D4
	BNE.S	.NEXTSEC	;sector couldnt be loaded, but try as long as
				;trackdata are present
;	BSR.S	DEC1L		;the original had still a check, now removed
;	CMP.L	#$53444446,D0
;	BNE.S	.ERR

	BCLR	D2,D7		;mark that sector as loaded

	TST.L	D7		;all sectors loaded?
	BNE.W	.NEXTSEC
	MOVEQ.L	#0,D0
.END
	MOVEM.L	(A7)+,A2/A3/A4/A5/D2/D3/D4/D5/D6/D7
	RTS
.ERR
	MOVEQ.L	#-1,D0
	BRA.S	.END

CHKSUMSECTOR
	MOVEQ.L	#0,D0
	MOVE.W	D2,D0
	MULU	#$640,D0
	LEA.L	0(A1,D0.L),A3
	MOVEQ.L	#0,D0
	MOVE.W	#$640/4-1,D1
.1	ADD.L	(A3)+,D0
	DBF	D1,.1
	RTS

DEC1L				;decode 1 longword of the stream

;	MOVE.L	(A2)+,D0
				;my *NEW* code to get a longword
	MOVE.L	(A2)+,D0	;get higher word
	LSR.L	D5,D0
	SWAP	D0
	MOVE.L	-2(A2),D6	;get lower word
	LSR.L	D5,D6
	MOVE.W	D6,D0		;my code ends

;	MOVE.L	(A2)+,D1
				;my *NEW* code to get a longword
	MOVE.L	(A2)+,D1	;get higher word
	LSR.L	D5,D1
	SWAP	D1
	MOVE.L	-2(A2),D6	;get lower word
	LSR.L	D5,D6
	MOVE.W	D6,D1		;my code ends

	AND.L	D3,D0
	AND.L	D3,D1
	LSL.L	#1,D0
	OR.L	D1,D0
	RTS

DEC1L640			;sector has $640 bits displacement from word
				;with even to word with odd bits, so the
				;program was able to decode the track with
				;the blitter, obviously i HAVE to change
				;that to the decode with CPU
;	MOVE.L	(A2)+,D0
				;my *NEW* code to get a longword
	MOVE.L	(A2)+,D0	;get higher word
	LSR.L	D5,D0
	SWAP	D0
	MOVE.L	-2(A2),D6	;get lower word
	LSR.L	D5,D6
	MOVE.W	D6,D0		;my code ends

;	MOVE.L	(A0)+,D1
				;my *NEW* code to get a longword
	MOVE.L	(A0)+,D1	;get higher word
	LSR.L	D5,D1
	SWAP	D1
	MOVE.L	-2(A0),D6	;get lower word
	LSR.L	D5,D6
	MOVE.W	D6,D1		;my code ends

	AND.L	D3,D0
	AND.L	D3,D1
	LSL.L	#1,D0
	OR.L	D1,D0
	RTS

