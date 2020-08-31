;simple example of an imager for a hd-install
;use this as base to write your own imagers


	INCDIR	ASM-ONE:INCLUDE2.0/

	INCLUDE	OWN/Patcher.I
	INCLUDE	DEVICES/TRACKDISK.I
	INCLUDE	EXEC/EXEC_LIB.I
	INCLUDE	EXEC/IO.I
	INCLUDE	LIBRARIES/DOS_LIB.I


HP	MOVEQ.L	#20,D0
	RTS
	DC.L	TAB
	DC.B	'PTCH'
	DC.B	'$VER:PPHammer_Diskimager_V1.00',0
	EVEN

TAB	DC.L	PCH_INIT,INITROUT
	DC.L	PCH_FILECOUNT,2
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

TRACKLENGTH=$17FC


;minimum version of the patcher required, its a commandline-parameter
VERSNAME	DC.B	'V1.05'		;MAY NOT CONTAIN HEADING ZEROES
	EVEN				;MUST CONTAIN 2 NUMBERS AFTER POINT


;name of the adaptor
ADNAME	DC.B	'Done by Harry.',0
	EVEN

PARAMNAME	DC.B	'PP Hammer, Diskimager for HD-Install',0
	EVEN

;name(s) of the volume to save on
DISKNAMEARRAY	DC.L	DISK1NAME
	DC.L	DISK1NAME

DISK1NAME	DC.B	'PPHammer',0
	EVEN

;name of the file(s) to save
FILENAMEARRAY	DC.L	FILE1NAME
	DC.L	FILE2NAME

FILE1NAME	DC.B	'disk.1',0
	EVEN
FILE2NAME	DC.B	'pphammer',0
	EVEN

;table of the length(s) of the file
LENGTHTABLE	DC.L	0
	dc.l	0
	
;the parameter-initializing opens sourcedevice 
INITROUT	
	MOVEQ.L	#0,D0
	MOVE.L	PTB_OPENDEVICE(A5),A0
	JSR	(A0)
	TST.L	D0
	BEQ.S	.1
	RTS

.1	MOVEQ.L	#0,D7				;one diskchange allowed
	MOVEQ.L	#0,D0
	MOVE.L	PTB_INHIBITDRIVE(A5),A0
	JSR	(A0)
.NEU
.4	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;disk in sourcedrive?
	MOVE.W	#TD_CHANGESTATE,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	IO_ACTUAL(A1)
	BNE.W	.NOTORG

	MOVEQ.L	#1,D2
.5	MOVEQ.L	#$4,D5				;4 tries, then error

	MOVE.L	D2,D0				;display track to read from
	BSR.W	TRACKREADING


.55	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1
	MOVE.L	PTB_SPACE(A5),IO_DATA(A1)	;track is to load in PTB_SPACE
	MOVE.L	#$7C00,IO_LENGTH(A1)		;double length of track
						;to decode the index-sync-read data
	MOVE.L	D2,D0				;my own trackcounter
	MOVE.L	D0,IO_OFFSET(A1)
	MOVE.W	#TD_RAWREAD,IO_COMMAND(A1)
	MOVE.B	#IOTDB_INDEXSYNC,IO_FLAGS(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	D0
	BNE.W	.NXCYCLE
	MOVE.L	PTB_SPACE(A5),A0		;begin of raw track
	LEA.L	$7C00(A0),A1			;end of raw track=start of 
	LEA.L	$7C00(A0),A3			;decoded track
	BSR.W	TRACKDECODE
	TST.L	D0
	BEQ.S	.R1OK
.NXCYCLE
	DBF	D5,.55

	TST.L	D7				;if disk has already been
	BNE.W	.DISPERR			;recognized: read error
	BRA.W	.NOTORG

.R1OK
	CMP.L	#'PPHA',2(A3)
	BNE.S	.NOTORG
	CMP.L	#'MMER',6(A3)
	BNE.S	.NOTORG

	MOVE.L	$D4(A3),LENGTHTABLE
	MOVE.L	$F4(A3),LENGTHTABLE+4

	MOVE.B	$D1(A3),TRACKTABLE
	MOVE.B	$F1(A3),TRACKTABLE+1

	MOVEQ.L	#0,D4

.END	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;switch motor off
	MOVE.L	#0,IO_LENGTH(A1)
	MOVE.W	#TD_MOTOR,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	D4				;obsolete, because only 1 cycle
	BEQ.S	.SK
	MOVEQ.L	#0,D0				;enable drive again
	MOVE.L	PTB_ENABLEDRIVE(A5),A0
	JSR	(A0)

.SK	MOVE.L	D4,D0
	RTS

.ERR	MOVEQ.L	#-1,D4
	BRA.S	.END

.NOTORG	TST.L	D7			;if the first time the original
	BNE.S	.ERR			;was not in the source drive,
	ST	D7			;youll be asked to put it there

	LEA.L	LOADSTATE(PC),A0	;display 'please insert...'
	MOVE.L	PTB_DISPLAY(A5),A6
	JSR	(A6)

	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;switch motor off
	MOVE.L	#0,IO_LENGTH(A1)
	MOVE.W	#TD_MOTOR,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)

	LEA.L	LINE1(PC),A0		;requester 'please insert...'
	LEA.L	LINE2(PC),A1
	MOVE.L	PTB_REQUEST(A5),A6
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
	MOVEQ.L	#0,D2
	BSR.W	TRACKERROR		;requester 'error on track 000'
	BRA.S	.ERR



;loading-statetext(s) for the cycles
STATEARRAY	DC.L	LOADSTATE
	DC.L	LOADSTATE

;save-statetext(s) for the cycles
STATEARRAY2	DC.L	SAVESTATE
	DC.L	SAVESTATE

LOADSTATE
	DC.B	'Please insert your original writepro-',$A
	DC.B	'tected disk in the source drive.',0
	EVEN
SAVESTATE
	DC.B	'Please insert your destination disk.',0
	EVEN


;routines to 'load' something
SPECIALARRAY	DC.L	LOADROUT		;load stuff from original
	DC.L	LOADROUT

TRACKTABLE	DC.B	0,0

LOADROUT
;.xxx	bra.s	.xxx
	MOVEQ.L	#0,D7				;one diskchange allowed
;	MOVEQ.L	#0,D0
;	MOVE.L	PTB_INHIBITDRIVE(A5),A0
;	JSR	(A0)
.NEU
.4	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;disk in sourcedrive?
	MOVE.W	#TD_CHANGESTATE,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	IO_ACTUAL(A1)
	BNE.W	.NOTORG

	MOVE.L	PTB_ADDRESSOFFILE(A5),A4	;load first part of disk
	LEA.L	(A4),A2				;offset to load in the dataspace
	MOVEQ.L	#0,D2
	MOVE.B	TRACKTABLE(PC,D6.W),D2

	MOVEQ.L	#0,D4				;data from the start of the track

	MOVE.L	PTB_FILESIZE(A5),D3		;bytes to read
	bra.s	.5				;because reading starts with
						;trackstart, this is obsolete

.3	TST.L	D4
	BNE.W	.1
.5	MOVEQ.L	#$4,D5				;4 tries, then error

	MOVE.L	D2,D0				;display track to read from
	ADD.L	D0,D0				;side-oriented disk!
	CMP.L	#$A0,D0
	BLO.S	.NE
	SUB.L	#$9F,D0
.NE	EOR.W	#1,D0				;inversed sides
	BSR.W	TRACKREADING


.55	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1
	MOVE.L	PTB_SPACE(A5),IO_DATA(A1)	;track is to load in PTB_SPACE
	MOVE.L	#$7C00,IO_LENGTH(A1)		;double length of track
						;to decode the index-sync-read data
	MOVE.L	D2,D0				;my own trackcounter
	ADD.L	D0,D0				;one-sided disk!
	CMP.L	#$A0,D0
	BLO.S	.NE1
	SUB.L	#$9F,D0
.NE1	EOR.W	#1,D0				;inversed sides
	MOVE.L	D0,IO_OFFSET(A1)
	MOVE.W	#TD_RAWREAD,IO_COMMAND(A1)
	MOVE.B	#IOTDB_INDEXSYNC,IO_FLAGS(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	TST.L	D0
	BNE.W	.NXCYCLE
	MOVE.L	PTB_SPACE(A5),A0		;begin of raw track
	LEA.L	$7C00(A0),A1			;end of raw track=start of 
	LEA.L	$7C00(A0),A3			;decoded track
	BSR.W	TRACKDECODE
	TST.L	D0
	BEQ.S	.R1OK
.NXCYCLE
	DBF	D5,.55

	ifeq	1
	MOVE.L	A3,A1			;FOR ME, THAT I SEE WRONG TRACKS
	MOVE.W	#$2000-1,D0		;INSTEAD OF ABANDONING AT THE
.NEX	MOVE.B	#'N',(A1)+		;TESTIMAGING
	DBF	D0,.NEX
	BRA.W	.R1OK
	endc

	TST.L	D7				;if disk has already been
	BNE.W	.DISPERR			;recognized: read error
	BRA.W	.NOTORG

.R1OK
					;the format is that unusual that
					;i didnt check for a special
					;value - thats also better if theres
					;another version of that game
					;but on dos-disks i recommend a check

	ST	D7			;correct disk - nothing anymore
					;to change

;	ADDQ.L	#1,D2			;increment tracknumber for next read
	MOVE.W	(A3),D2
	CMP.W	#$A0,D2
	BHS.S	.ERR

	LEA.L	4(A3),A3

.1					
	MOVE.B	(A3,D4.W),(A2)+
	ADDQ.L	#1,D4
	CMP.L	#TRACKLENGTH,D4			;tracklength
	BNE.S	.2
	MOVEQ.L	#0,D4				;new track
.2	SUBQ.L	#1,D3
	BNE.W	.3


	MOVEQ.L	#0,D4				;all went ok

.END	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;switch motor off
	MOVE.L	#0,IO_LENGTH(A1)
	MOVE.W	#TD_MOTOR,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)
	CMP.W	#1,D6
	BEQ.S	.EN
	TST.L	D4				;obsolete, because only 1 cycle
	BEQ.S	.SK
.EN	MOVEQ.L	#0,D0				;enable drive again
	MOVE.L	PTB_ENABLEDRIVE(A5),A0
	JSR	(A0)

.SK	MOVE.L	D4,D0
	RTS

.ERR	MOVEQ.L	#-1,D4
	BRA.S	.END

.NOTORG	TST.L	D7			;if the first time the original
	BNE.S	.ERR			;was not in the source drive,
	ST	D7			;youll be asked to put it there

	LEA.L	LOADSTATE(PC),A0	;display 'please insert...'
	MOVE.L	PTB_DISPLAY(A5),A6
	JSR	(A6)

	MOVE.L	PTB_DEVICESOURCEPTR(A5),A1	;switch motor off
	MOVE.L	#0,IO_LENGTH(A1)
	MOVE.W	#TD_MOTOR,IO_COMMAND(A1)
	MOVE.L	(_SYSBASE).W,A6
	JSR	_LVODOIO(A6)

	LEA.L	LINE1(PC),A0		;requester 'please insert...'
	LEA.L	LINE2(PC),A1
	MOVE.L	PTB_REQUEST(A5),A6
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
	BSR.S	TRACKERROR		;requester 'error on track 000'
	BRA.S	.ERR

TRACKERROR				;requester 'error on track 000'
	MOVE.B	D2,D0
	ADD.L	D0,D0				;one-sided disk!
	CMP.L	#$A0,D0
	BLO.S	.NE
	SUB.L	#$9F,D0
.NE	EOR.W	#1,D0				;inversed sides

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


LINE1	DC.B	'Please insert your original',0
	EVEN
LINE2	DC.B	'disk in the source drive.',0
	EVEN




;< A0 RAWTRACK
;< A1 TRACKBUFFER
;> D0 ERROR

SYNC	DC.W	$8915

GETSYNC
;SYNCANFANG SUCHEN
	MOVE.W	SYNC(PC),D1	    ;find sync in the bitstream, skip 
.SHF2	MOVEQ.L	#$10-1,D5	    ;all syncwords and return 
.SHF1	MOVE.L	(A2),D0		    ;position: word (in A2)+bitshift (in D5)
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
;INTERN
;  D5 SHIFT


TRACKDECODE	MOVEM.L	A2/A3/A4/A5/D1/D2/D3/D4/D5/D6/D7,-(A7)

	MOVE.L	A0,A2
	LEA.L	($7B80-TRACKLENGTH*2)(A0),A4	;LAST CHANCE FOR CORRECT SYNC 
					;(READ LENGTH -$80 SAFETY 
					;-LENGTH OF A RAW TRACK OR SECTOR)
.ANF
	MOVE.L	A1,A3
	MOVE.L	#$55555555,D6
	BSR.W	GETSYNC
	TST.L	D0
	BNE.W	.ERR

	MOVE.L	(A2),D0
	ADDQ.L	#2,A2
	LSR.L	D5,D0

	CMP.W	#$AAAA,D0
	BNE.S	.ANF


	MOVE.L	(A2),D0
	ADDQ.L	#2,A2
	LSR.L	D5,D0

	CMP.W	#$AAAA,D0
	BNE.S	.ANF

	TST.L	(A2)+
	TST.L	(A2)+

	MOVEQ.L	#0,D2
	MOVE.W	#$600-1,D4
.1

;	MOVE.L	(A2)+,D0
				;my *NEW* code to get a longword
	MOVE.L	(A2)+,D0	;get higher word
	LSR.L	D5,D0
	SWAP	D0
	MOVE.L	-2(A2),D3	;get lower word
	LSR.L	D5,D3
	MOVE.W	D3,D0		;my code ends


;	MOVE.L	(A2)+,D1
				;my *NEW* code to get a longword
	MOVE.L	(A2)+,D1	;get higher word
	LSR.L	D5,D1
	SWAP	D1
	MOVE.L	-2(A2),D3	;get lower word
	LSR.L	D5,D3
	MOVE.W	D3,D1		;my code ends


	AND.L	D6,D0
	AND.L	D6,D1
	LSL.L	#1,D0
	OR.L	D0,D1
	EOR.L	D1,D2
	MOVE.L	D1,(A3)+
	DBF	D4,.1

;	MOVE.L	(A2)+,D0
				;my *NEW* code to get a longword
	MOVE.L	(A2)+,D0	;get higher word
	LSR.L	D5,D0
	SWAP	D0
	MOVE.L	-2(A2),D3	;get lower word
	LSR.L	D5,D3
	MOVE.W	D3,D0		;my code ends


;	MOVE.L	(A2)+,D1
				;my *NEW* code to get a longword
	MOVE.L	(A2)+,D1	;get higher word
	LSR.L	D5,D1
	SWAP	D1
	MOVE.L	-2(A2),D3	;get lower word
	LSR.L	D5,D3
	MOVE.W	D3,D1		;my code ends


	AND.L	D6,D0
	AND.L	D6,D1
	LSL.L	#1,D0
	OR.L	D0,D1
	CMP.L	D1,D2
	BNE.S	.ERR

	MOVEQ.L	#0,D0
.END
	MOVEM.L	(A7)+,A2/A3/A4/A5/D1/D2/D3/D4/D5/D6/D7
	RTS
.ERR
	MOVEQ.L	#-1,D0
	BRA.S	.END

