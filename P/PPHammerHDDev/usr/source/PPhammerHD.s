;*---------------------------------------------------------------------------
;  :Program.	pphammerslave.asm
;  :Contents.	Slave for "PP Hammer"
;  :Author.	Harry
;  :History.	24.01.1998/19.2.1998
;  :Requires.	whdload-package :)
;  :Copyright.  GPL
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;---------------------------------------------------------------------------*

crc_v1	= $e08d ;rerelease
crc_v2	= $08b8	;original (ntsc?)



	INCDIR	Include:
	INCLUDE	whdload.i
	IFD BARFLY
	OUTPUT	"PPHammer.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
;======================================================================

_base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize			;$bc000
		dc.l	$00		;ws_ExecInstall
		dc.w	_start-_base	;ws_GameLoader
		dc.w	_curdir-_base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
 		dc.b	$00		;debugkey
qkey		dc.b	$5D		;quitkey
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_curdir
	dc.b	"data",0
_config
	dc.b	"BW;"
	dc.b	0
_name		dc.b	"P.P. Hammer",0
_copy		dc.b	"1991 Demonware",0
_info		dc.b	"installed by Harry & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

;======================================================================
_start:	;	A0 = resident loader
;======================================================================

	
		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using


		move.l	#CACRF_EnableI,d0	;enable instruction cache
		move.l	d0,d1			;mask
		jsr	(resload_SetCACR,a0)
	MOVE.B	qkey(PC),d0
	NOT.B	D0
	ROL.B	#1,D0
	LEA.L	_quitkey(PC),a0
	MOVE.B	d0,(A0)
;	MOVE.B	qkey(PC),d0
;	SUBQ.B	#2,D0
;	NOT.B	D0
;	ROL.B	#1,D0
;	LEA.L	keyhp\.tkey(PC),a0
;	MOVE.B	d0,(A0)
;	BSET	#1,$BFE001

	LEA.L	$20000,A1		;ADDY
	MOVE.L	#$20000,D0		;LEN
	lea	(pphname,PC),a0	;filename
	MOVE.L	_resload(PC),a3
	jsr	(resload_LoadFile,a3)


	MOVE.L	#$1000,D0
	LEA.L	$20200,A0
	jsr	(resload_CRC16,a3)
	

	cmp.w	#crc_v2,d0
	BEQ.S	.org
	CMP.W	#crc_v1,D0
	BNE.W	BADVER

	MOVE.W	#$4ef9,$2023e
	pea	patch1(PC)
	MOVE.L	(A7)+,$20240
	
	JMP	$20020

	; version 1, PP20 packed
.org
	LEA.L	$1000,A1		;ADDY
	MOVE.L	#$20000,D0		;LEN
	lea	(pphname,PC),a0	;filename
	MOVE.L	_resload(PC),a3
	jsr	(resload_LoadFile,a3)

	PEA	PATCH1O(PC)
	MOVE.L	(A7)+,$1018.W
	JMP	$1000.W

active_fire_loop:
	move.l	D4,-(A7)
	move.w	#1,d4
	bsr	DBFD4
	move.l	(a7)+,d4
	TST.B	$BFE001		;0958a: 4a3900bfe001
	rts

wait_after_dma_enable:
	; DMA sound enable: wait

	movem.l	D4,-(A7)
	moveq.l	#7,D4
	bsr	DBFD4
	movem.l	(A7)+,D4
	rts

dmacon_wait_1
	MOVE.W	82(A5),$DFF096		;32874: 33ed005200dff096
	bra	wait_after_dma_enable
dmacon_wait_2
	MOVE.W	80(A5),$DFF096		;3287e: 33ed005000dff096
	bra	wait_after_dma_enable
	
	   
pl_v2:
	PL_START
	PL_P	$54c6,loadrout
	PL_P	$48,keyhp

	PL_L	$42F4,$4EB80048  ;KEYBOARD
	PL_L	$4194,$4EB80048
	PL_L	$87D8,$4EB80048
	PL_L	$BCE8,$4EB80048

	PL_R	$5496		;RESET DRIVE
	PL_CB	$2cee0      ;repair colors
	PL_CB	$527E
	PL_CB	$BF38

	; press fire before start
	PL_W	$0514c,DELAY_VALUE
	PL_PS	$0514e,active_fire_loop
	PL_W	$05166,DELAY_VALUE
	PL_PS	$05168,active_fire_loop
	; press fire when paused
	PL_W	$0bf02,DELAY_VALUE
	PL_PS	$0bf04,active_fire_loop
	PL_W	$0bf1c,DELAY_VALUE
	PL_PS	$0bf1e,active_fire_loop
	
	; press fire when ESC
	PL_PS	$4644,active_fire_loop
	PL_W	$4658,ESC_DELAY_VALUE		; lower timer because we introduce CPU independent delay
	PL_W	$4922,ESC_DELAY_VALUE		; lower timer because we introduce CPU independent delay
	
	; fix sound/music play
	PL_PSS	$35208,dmacon_wait_1,2
	PL_PSS	$35212,dmacon_wait_2,2

	PL_END

patch1
	movem.l	d0-a2,-(a7)
	lea	pl_v2(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a2
	MOVE.W	#0,$9A(A4)		;ORIGINAL CODE
	jmp	(A2)

	; data-v1
	
DELAY_VALUE=$1000
ESC_DELAY_VALUE=$20

pl_v1:
	PL_START
	PL_P	$27C4,OLOADROUT
	PL_P	$48,keyhp

	PL_L	$16AA,$4EB80048
	PL_L	$180A,$4EB80048
	PL_L	$5E44,$4EB80048
	PL_L	$9354,$4EB80048

	PL_CB	$2A54C
	PL_CB	$279C
	PL_CB	$95A4
	
	; press fire before start
	PL_W	$266A,DELAY_VALUE
	PL_PS	$266C,active_fire_loop
	PL_W	$2684,DELAY_VALUE
	PL_PS	$2686,active_fire_loop
	; press fire when paused
	PL_W	$956E,DELAY_VALUE
	PL_PS	$9570,active_fire_loop
	PL_W	$9588,DELAY_VALUE
	PL_PS	$958A,active_fire_loop
	
	; press fire when ESC
	PL_PS	$1b5a,active_fire_loop
	PL_W	$1B6E,ESC_DELAY_VALUE		; lower timer because we introduce CPU independent delay
	PL_W	$1E3E,ESC_DELAY_VALUE		; lower timer because we introduce CPU independent delay
	
	; fix sound/music play
	PL_PSS	$32874,dmacon_wait_1,2
	PL_PSS	$3287E,dmacon_wait_2,2
	
	PL_L	$1000,$FFFFFFFE
	PL_END
	
PATCH1O
	movem.l	d0-a2,-(a7)
	lea	pl_v1(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a2
	
	MOVE.L	#$1000,$DFF080

;	MOVE.W	#$4AFC,$15D0

	JMP	$1500.W


;>D0-TEILNR
;>A6-DEST
;<D0=0 OK

OLOADROUT
	MOVEM.L	D0-A6,-(A7)
	LEA.L	$28AE.W,A4
	MOVE.L	D0,D7
	MOVEQ.L	#0,D0
.2	SUBQ.W	#1,D7
	BMI.S	.1
	ADD.L	(A4)+,D0
	BRA.S	.2

.1				;OFFSET IN D0
	MOVE.L	(A4)+,D1	;SIZE IN D1

	lea	(A6),a0		;dest
	MOVEQ.L	#1,D2
	move.l	(_resload,pc),a3
	jsr	(resload_DiskLoad,a3)

	MOVEM.L	(A7)+,D0-A6
	MOVEQ.L	#0,D0
	RTS




;>a0; ^filename
;>a1: loadaddy


loadrout
	LEA.L	myfilename(PC),a2
	MOVE.B	(A0),(A2)
	MOVE.B	1(A0),1(A2)
	MOVE.B	2(A0),2(A2)
	MOVE.B	3(A0),3(A2)
	MOVE.L	#$60000,d0
;	MOVE.L	a1,a1
	MOVE.L	a2,a0
	MOVE.L	_resload(PC),a3
	jsr	(resload_LoadFile,a3)
	rts


DBFD4
	AND.L	#$FFFF,D4
	DIVU	#$28,D4
.4	MOVE.L	D4,-(A7)
	MOVE.B	$DFF006,D4
.3	CMP.B	$DFF006,D4
	BEQ.S	.3
	MOVE.L	(A7)+,D4
	DBF	D4,.4
	RTS

;version	dc.w	0	;version of disks
_resload	dc.l	0	;address of resident loader
myfilename	dc.l	0
pphname	dc.b	'pphammer',0
	EVEN

; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f
;	NUM *	$5D

keyhp	
	MOVEQ.L	#$50,D4
	BSR.W	DBFD4

	CMP.B	_quitkey(pc),D0
	BEQ.S	QUIT

;	CMP.B	#$0,D0
;.TKEY	EQU	*-1
;	BNE.S	.1
;	EOR.B	#$E0,$57E0F
.1
	RTS
_quitkey
	dc.b	0
	even


QUIT	pea	TDREASON_OK
	bra	_end
BADVER	pea	TDREASON_WRONGVER
_end	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

