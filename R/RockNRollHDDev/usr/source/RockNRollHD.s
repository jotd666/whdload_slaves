;*---------------------------------------------------------------------------
;  :Program.	rocknrollslave.asm
;  :Contents.	Slave for "Rock n Roll"
;  :Author.	Harry, Wepl
;  :History.	25.05.97
;		15.01.12 adapted for whdload v10
;			 blitwait in intro added
;			 intro skip via custom1
;			 highscores 1/10th
;			 title scrolling fixed
;			 leading zeros in high score table removed
;			 button control on map display fixed
;			 disk loader optimized, less resload calls
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;---------------------------------------------------------------------------*

;Rocknroll-startvorgang
;initkram laden, 
;^50164 jmp $30002 patchen (0)
;trap #0, decrunchen
;(0) spricht an
;^30114 patchen ZU WAITLOGO (8 BYTES)
;rainbow arts zeigen
;^6012a jmp aaac patchen (1)
;dann zur $60024 springen
;decrunch
;(1) spricht an
;$a014 patchen - lader
; d0-part (= $30 highscore)
; tabelle ab $a65c:
;  L-ladeaddy
;  L-filelaenge
;  W-starttrack
;  L-trackoffset
;  W-?
;^aad8 jmp $3a000 patchen (2)
;^ab50 jmp $12024 patchen (4)
;jmp $aaac
;(2) spricht an
;move.l #$aae2,4.W
;move.l	#$4e714e71,$3a078 -stackframeerror fixen
;move.w #$4e75,$3a0d0
;^3a072 pea 7bc44 patchen (3)
;jmp $3a000
;(3)spricht an
;zeitschleife patchen
;jmp $7bc44
;(4)spricht an
;^120CE JMP 11200 patchen (5)
;jmp $12024
;(5) spricht an
;^71120 RTS	;disk ein
;^7113e rts     ;disk aus
;^71594	SAVE HIGH
;^71554 LOAD HIGH
;^711B8 RTS	;TRACK0-SEARCH
;DBF-KRAM UND TASTATUR


crc_v11	= $0bf7		;2-disk sps-801, all 'N' patcher imager
crc_v12	= 0		;2-disk sps-801, all zero for new rawdic imager
crc_v2	= $58bc		;1-disk sps-2167

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

    IFD    BARFLY
	OUTPUT	"wart:ri/rock'n roll/RocknRoll.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
    ENDC
    
;======================================================================

_base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize			;$bc000
		dc.l	$0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
		dc.b	0		;no debugkey
qkey		dc.b	$5D		;* quits
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_info

;======================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"Rock'n Roll",0
_copy		dc.b	"1989 Rainbow Arts",0
_info		dc.b	"Adapted by Harry/Wepl/JOTD",10
		dc.b	"Version "
        DECL_VERSION
		dc.b	0
_config		
    dc.b    "C1:X:infinite money:0;"
    dc.b    "C1:X:infinite lives:1;"
    dc.b    "C2:B:enable fast code entry;"
    dc.b    "C3:L:default start level:"
    dc.b   "EASY LIVING,"
    dc.b   "UP AND DOWN,"
    dc.b   "SILENT MOVING,"
    dc.b   "TIME IS MONEY,"
    dc.b   "WORDS R EASY,"
    dc.b   "GEOMETRIC,"
    dc.b   "SECRET AREA,"
    dc.b   "VARIED OFFER,"
    dc.b   "CROSSROADS,"
    dc.b   "TRY THE TREE,"
    dc.b   "BEAM ME UP,"
    dc.b   "BOMBASTIC,"
    dc.b   "TRICKY TRACK,"
    dc.b   "WAYOUT,"
    dc.b   "FRAGILE ACTION,"
    dc.b   "AIR FORTRESS,"
    dc.b   "OPEN AND CLOSE,"
    dc.b   "RUNNING MAN,"
    dc.b   "HELPING HAND,"
    dc.b   "YOUR CHOICE,"
    dc.b   "PUSH AND FALL,"
    dc.b   "RIDDLE ROOMS,"
    dc.b   "DISK ACCESS,"
    dc.b   "SKATING RINK,"
    dc.b   "ARROW-ACTION,"
    dc.b   "DONT PANIC,"
    dc.b   "RADIATION,"
    dc.b   "THINK TWICE,"
    dc.b   "FREE FALL,"
    dc.b   "ROLLERCOASTER,"
    dc.b   "CRAZY DREAMS,"
    dc.b   "CASTLE OF DOOM,"
    dc.b   "BONUSLEVEL;"    
    dc.b	"C5:B:Skip Intro",0
HIGHNAME	DC.B	'RRHIGH',0
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	10,0	
	EVEN

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
		move.l	a0,a3

		move.l	#CACRF_EnableI,d0	;enable instruction cache
		move.l	d0,d1			;mask
		jsr	(resload_SetCACR,a0)

		lea	_tags(pc),a0
		jsr	(resload_Control,a3)

	;check disk version
	move.l	#$0,d0		;offset
	move.l	#$400,d1	;size
	moveq	#1,d2		;disk
	lea	$40000,a0	;data
	movem.l	d1/a0,-(a7)
	jsr	(resload_DiskLoad,a3)

	movem.l	(a7)+,d0/a0
	jsr	(resload_CRC16,a3)

	cmp.w	#crc_v11,d0
	beq	.FIRST
	cmp.w	#crc_v12,d0
	beq	.FIRST
	cmp.w	#crc_v2,d0
	beq	_SECOND
	pea	TDREASON_WRONGVER
	jmp	(resload_Abort,a3)

;======================================================================
; code for version 1, 2-disk sps-801

.FIRST	MOVE.L	#$42*$1800,D0
	MOVE.L	#$1800,D1
	MOVEQ.L	#1,D2
	MOVE.L	#$70000,A0
	jsr	(resload_DiskLoad,a3)

    lea $70000,a1
    lea pl_boot(pc),a0
    jsr (resload_Patch,a3)
	JMP	$70000

pl_boot
    PL_START
	PL_R  $6E
	PL_R  $B6
	PL_R  $D4
	PL_P  $4FC,_load1
	PL_PA   $22,boot
    PL_END
    
boot:
	lea	$7bc40,a6

	bsr	_patchdelay

	clr.l	-(a7)
	pea	(a6)
	pea	WHDLTAG_DBGADR_SET
	move.l	a7,a0
	move.l	(_resload,pc),a2
	jsr	(resload_Control,a2)

	lea	_pl_40(pc),a0
	move.l	a6,a1
	jsr	(resload_Patch,a2)

	move.l	_skip_intro(pc),d0
	bne	.skipi
	JMP	(4,a6)
.skipi	JMP	($1276,a6)

_pl_40	PL_START
	PL_PS	$c2,_buttonwait		;last intro screen
	PL_PS	$84e,_bw1
	PL_L	$ab2,$4EB80100		;$7C6F2
	PL_L	$b26,$4EB80100		;$7C766
	PL_L	$db4,$4EB80112		;$7C9F4
	PL_PA	$12f2,_main1
	PL_R	$12fa			;disk access
	PL_R	$1302			;disk access
	PL_R	$135c			;disk access
	PL_P	$1602,_mload
	PL_END

_mload	MOVEM.L	D1-A6,-(A7)
	MOVE.L	#$1,D2
	MOVE.L	#$2*$1800,D0
	MOVE.L	#($43-2)*$1800,D1
	MOVE.L	#$1A578,A0
	move.l	(_resload,pc),a3
	jsr	(resload_DiskLoad,a3)
	MOVEM.L	(A7)+,D1-A6
	CLR.L	D0
	RTS

_main1
	lea	_pl_m801(pc),a0
	lea	$1a578,a1
	move.l	(_resload,pc),a2
	jsr	(resload_Patch,a2)

    bsr set_start_level
    
    
	JMP	$68166			;offset 4dbee

_pl_m801	PL_START
	PL_P	$4e610,_disk2		;68B88
	PL_P	$4e6cc,_disk1		;68C44
	PL_P	$56fee,_load1		;71566 ^71554
	PL_P	$5702e,_save1		;715a6 ^71594
    
	PL_NEXT	_pl_m

_disk1	moveq	#1,d0
	bra	_disk

_disk2	moveq	#2,d0

_disk	MOVE.L	A0,-(A7)
	LEA.L	DISKNR(PC),A0
	MOVE.B	d0,(A0)
	MOVE.L	(A7)+,A0
	MOVEQ.L	#$30,D0
	Jmp	$71554

set_start_level:
    move.l  _start_level(pc),$69584+2
    move.l  _start_level(pc),$686ac+2
    rts
    
;>A4 ^STARTTRACK
;>A5 ^MEMDEST
;>A6 -2(A6) ENDTRACK-1

_load1	MOVEM.L	D1-A6,-(A7)
	MOVEQ.L	#0,D2
	MOVE.B	DISKNR(PC),D2
	move.l	(_resload,PC),a2

	CMP.W	#$A1,(a4)
	BEQ.S	.OHIGHLOAD

.loop	moveq	#0,d0
	move.w	(a4)+,d0		;offset
	move.w	d0,d3
	move.l	#$1800,d1		;length
	mulu	d1,d0
.comb	cmp.l	a4,a6
	beq	.load
	addq.w	#1,d3
	cmp.w	(a4),d3
	bne	.load
	addq.l	#2,a4
	add.l	#$1800,d1
	bra	.comb
.load	move.l	a5,a0
	add.l	d1,a5
	jsr	(resload_DiskLoad,a2)
	cmp.l	a4,a6
	bne	.loop

.quit	MOVEM.L	(A7)+,D1-A6
	MOVEQ.L	#0,D0
	RTS

.OHIGHLOAD
	lea	(HIGHNAME,PC),a0	;filename
	jsr	(resload_GetFileSize,a2)
	tst.l	d0
	beq	.loop
	MOVE.L	A5,A1			;ADDY
	MOVE.L	#$1800,D0		;LEN
	lea	(HIGHNAME,PC),a0	;filename
	jsr	(resload_LoadFile,a2)

	MOVE.L	A5,A1			;PROTECT HIGH
	MOVE.W	#$10A0/4-1,D0
	MOVEQ.L	#0,D1
.11	ADD.L	(A1)+,D1
	DBF	D0,.11
	CMP.L	$10A0(A5),D1
	bne	.loop
	bra	.quit

_save1	MOVEM.L	D1-A6,-(A7)

	MOVE.L	$10A0(A5),-(a7)
	MOVE.L	A5,A1
	MOVE.W	#$10A0/4-1,D0
	MOVEQ.L	#0,D1
.1	ADD.L	(A1)+,D1
	DBF	D0,.1
	MOVE.L	D1,$10A0(A5)

	MOVE.L	A5,A1
	move.l	#$1800,D0		;len
	lea	HIGHNAME(PC),a0		;filename
	move.l	(_resload,pc),a2
	jsr	(resload_SaveFile,a2)
	MOVE.L	(a7)+,$10A0(A5)
	MOVEM.L	(A7)+,D1-A6
	moveq	#0,d0
	RTS

;======================================================================
; code for version 2, 1-disk sps-2167

_SECOND
	MOVEQ.L	#1,D2
	MOVE.L	#$2A00,D1		;length
	MOVE.L	#$50000,A0
	MOVE.L	#$200,D0		;offset
	move.l	(_resload,pc),a3
	jsr	(resload_DiskLoad,a3)

	MOVE.L	#$2400,D1		;length
	MOVE.L	#$52A00,A0
	MOVE.L	#$D9C00,D0		;offset
	move.l	(_resload,pc),a3
	jsr	(resload_DiskLoad,a3)

	LEA	$00054400,A0
	LEA	$00060000,A2
	LEA	$00054E00,A1
.1	MOVE.L	(A0)+,(A2)+
	CMPA.L	A0,A1
	BGE.B	.1

	move.l	_skip_intro(pc),d0
	bne	.skipr			;rainbow arts logo

	move.w	#$4e75,$50164
	jsr	$50020			;decrunch

;^30114 patchen ZU WAITLOGO (8 BYTES)
	MOVE.L	#$4E714EB9,$30114
	LEA.L	WAITLOGO(PC),A0
	MOVE.L	A0,$30118

	move.w	#$4e75,$30168
	jsr	$30002			;decrunch
.skipr
	move.w	#$4e75,$6012a
	jsr	$60024
	
	lea	$a000,a6

	clr.l	-(a7)
	pea	(a6)
	pea	WHDLTAG_DBGADR_SET
	move.l	a7,a0
	move.l	(_resload,pc),a2
	jsr	(resload_Control,a2)

	lea	_pl_a000(pc),a0
	move.l	a6,a1
	jsr	(resload_Patch,a2)

	move.l	_skip_intro(pc),d0
	bne	.skipi
	JMP	($aac,a6)		;intro
.skipi	JMP	($ade,a6)		;main

_pl_a000
	PL_START
	PL_P	$14,_load2
	PL_P	$ad8,_intro2
	PL_B	$ae0,$20		;sr = 2000
	PL_PA	$b52,_main2
	PL_END

_intro2	lea	$3a000,a0
	move.l	#$4e714e71,($78,a0)
	move.w	#$4e75,($d0,a0)		;rte -> rts
;^3a072 pea 7bc44 patchen (3)
	LEA	.p(PC),A1
	MOVE.L	A1,($74,a0)
	jmp	($20,a0)		;decrunch

.p	lea	$1087e,a6

	clr.l	-(a7)
	pea	(a6)
	pea	WHDLTAG_DBGADR_SET
	move.l	a7,a0
	move.l	(_resload,pc),a2
	jsr	(resload_Control,a2)

	lea	_pl_1087e(pc),a0
	move.l	a6,a1
	jsr	(resload_Patch,a2)

	JMP	$7BC44			;offset 6b3c6

_pl_1087e
	PL_START
	PL_PS	$6bc10,_bw1		;7c48e
	PL_PSS	$6c640,_buttonwait,2	;7CEBE last intro screen
	PL_END

_main2
;^120CE JMP 11200 patchen (5)
	LEA.L	.p(PC),A0
	MOVE.L	A0,$120D0
	JMP	$12024			;decrunch

.p	lea	$1a578,a6

	bsr	_patchdelay

	clr.l	-(a7)
	pea	(a6)
	pea	WHDLTAG_DBGADR_SET
	move.l	a7,a0
	move.l	(_resload,pc),a2
	jsr	(resload_Control,a2)

    bsr set_start_level

    
	lea	_pl_m2(pc),a0
	move.l	a6,a1
	jsr	(resload_Patch,a2)

	JMP	$11200

_pl_m2	PL_START
	PL_P	$56fdc,_load2			;71554
	PL_P	$5701c,_save2			;71594
	PL_NEXT	_pl_m

;	MOVE.L	#$4EB80100,$10A6A
;	MOVE.L	#$4EB80100,$7C6F2
;	MOVE.L	#$4EB80100,$7C766
;	MOVE.L	#$4EB80112,$7C9F4


RESTART
	MOVE.W	#$7FFF,$DFF09A		;FIX CRASH AFTER GAMECOMPLETION
	JMP	$AADE

;D0-FILENR
;TABELLE SIEHE OBEN

_load2	MOVEM.L	D1-A6,-(A7)
	move.l	(_resload,pc),a3
	CMP.B	#$FF,D0
	BEQ.S	RESTART

	MOVE.L	D0,D3
	LEA.L	$A65C,A2
	LSL.L	#4,D3
	LEA.L	(A2,D3.W),A2

	CMP.B	#$30,D0
	bne	.nohs

	lea	(HIGHNAME,PC),a0	;filename
	jsr	(resload_GetFileSize,a3)
	tst.l	d0
	beq	.nohs

	MOVE.L	(a2),a1
	move.l	#$1800,D0		;len
	lea	HIGHNAME(PC),a0		;filename
	jsr	(resload_LoadFile,a3)

	MOVE.L	(a2),A1			;PROTECT HIGH
	MOVE.W	#$10A0/4-1,D0
	MOVEQ.L	#0,D1
.hs_1	ADD.L	(A1)+,D1
	DBF	D0,.hs_1
	CMP.L	(A1),D1
	beq	.2
.nohs
	MOVE.L	(A2),A0
;EVTL $E(A2) BEACHTEN
	MOVE.W	$E(A2),D4
	MOVE.L	4(A2),D1
	MOVEQ.L	#0,D0
	MOVE.W	8(A2),D0
	MULU	#$1600,D0
	ADD.L	$A(A2),D0
	TST.W	D4
	BEQ.S	.1
	LEA.L	-$500(A0),A0
	JSR	$A4F0
	MOVE.L	A0,$A642
.1	MOVEQ.L	#1,D2			;DISK
	jsr	(resload_DiskLoad,a3)
	TST.W	D4
	BEQ.S	.2
	MOVE.L	$A642,A0
	LEA.L	$500(A0),A1
	JSR	$A510
	MOVE.L	$A642,A0
	JSR	$A4F0
.2	MOVEM.L	(A7)+,D1-A6
	CLR.L	D0
	RTS

_save2	MOVEM.L	D1-A6,-(A7)
	MOVE.L	D0,D3
	LEA.L	$A65C,A2
	LSL.L	#4,D3
	LEA.L	(A2,D3.W),A2
	MOVE.L	(A2),A4			;address

	MOVE.L	$10A0(A4),-(a7)
	MOVE.L	A4,A1
	MOVE.W	#$10A0/4-1,D0
	MOVEQ.L	#0,D1
.1	ADD.L	(A1)+,D1
	DBF	D0,.1
	MOVE.L	D1,$10A0(A4)

	MOVE.L	A4,A1
	move.l	#$1800,D0		;len
	lea	HIGHNAME(PC),a0		;filename
	move.l	(_resload,pc),a2
	jsr	(resload_SaveFile,a2)
	MOVE.L	(a7)+,$10A0(A4)
	MOVEM.L	(A7)+,D1-A6
	moveq	#0,d0
	RTS

WAITLOGO
	MOVE.L	D0,-(A7)
	MOVE.B	$DFF006,D0
.2	CMP.B	$DFF006,D0
	BEQ.S	.2
	MOVE.L	(A7)+,D0
	SUB.L	#$3,$30D96
	BPL.S	.1
	MOVE.L	#1,$30D96
.1	BTST	#6,$BFE001
	RTS

;======================================================================
; code used for both versions

_pl_m	PL_START
	PL_S	$4ed8e,4		;wait_raster_16
	PL_S	$4f2fe,4		;wait_raster_16
	PL_S	$4f34a,4		;wait_raster_16
	PL_S	$4f366,4		;wait_raster_16
	PL_S	$4f3b2,4		;wait_raster_16
	PL_PSS	$502d2,_hstbl,$f0-$d2-6
	PL_L	$510fe,$4EB8010C	;$6B676	d7 ffffff
	PL_PSS	$5115c,_waitmap,16-6
	PL_P	$511f4,_waitmap
	PL_L	$5141e,$4EB8010C	;$6B996 d7 fff
	PL_L	$515a2,$4EB80106	;$6BB1A d4 8fff
;	PL_BKPT	$54856			;print highscore
	PL_PS	$54862,_score
	PL_PS	$54890,_score
;	PL_BKPT	$548b2			;print picks
;	PL_BKPT	$549c8			;print bombs
;	PL_BKPT	$549f6			;print parachutes
;	PL_BKPT	$54d90			;print level
	PL_L	$554e0,$4EB80100	;$6FA58 d0 1111
	PL_L	$56468,$4EB80100	;$709E0 d0 ff
	PL_S	$56556,8		;empty loop
;	PL_L	$5655a,$4EB80100	;$70AD2	d0 8000
	PL_P	$5662a,_wait16
	PL_P	$5664e,_bw
	PL_L	$566f4,$4EB80112	;$70C6C d1 bfec01
	PL_R	$56ba8			;71120 disk ein
	PL_R	$56bc6			;7113e disk aus
	PL_R	$56c40			;711b8 TRACK0 WEG
    
    PL_S  $694dc-$1a578,$6952e-$694dc        ; no level code check
    PL_NOP  $6956e-$1a578,2        ; no level code "checksum"
    PL_PS   $69560-$1a578,_sub_and_mask_d1   ; must mask d1
    
    PL_IFC2
    PL_STR  $68416-$1a578,<RAINBOW(ARTS>
    PL_B    $68416+$C-$1a578,$FF
    PL_B    $68459-$1a578,$22
    PL_ENDIF
    
    PL_IFC1X    0
    PL_L    $6bd84+2-$1a578,1000    ; clear money in the end
    PL_L    $6e2dc+2-$1a578,1000    ; start money
    PL_NOP  $6e256-$1a578,6         ; no money decrease
    PL_L    $719c2-$1a578,1000      ; init money at startup
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $6bc88-$1a578,8
    PL_ENDIF

    
	PL_END

_sub_and_mask_d1
    and.l   #$FF,d1
    subq.l  #1,d1
    rts
    
_waitmap
	bsr	_wait16
	btst	#6,$bfe001
	beq	_waitmap

_wait16 move.l	d0,-(a7)
.w1	move.l	_custom+vposr,d0
	lsr.l	#8,d0
	cmp.w	#16,d0
	beq	.w1
.w2	move.l	_custom+vposr,d0
	lsr.l	#8,d0
	cmp.w	#16,d0
	bne	.w2
	move.l	(a7)+,d0
	rts

	;allow 6 digits for decimal conversion with highscores
	;means scores up to 10..999990 (instead 100..999900)
_hstbl	bsr	_hex2dec
	subq.l	#5,a0
	moveq	#4,d1
	moveq	#"(",d5
.l	move.b	(a0),d0
	beq	.s
	moveq	#"0",d5
.s	add.b	d5,d0
	move.b	d0,(a0)+
	dbf	d1,.l
	rts

_score	bsr	_hex2dec
	move.l	a3,a0
	addq.l	#4,(a7)
	rts

_hex2dec
	move.l	a2,d1
	move.l	a3,a0		;original
	divu	#50000,d1
	lsr.w	#1,d1
	scs	d0
	bsr	.w
	divu	#10000,d1	;original
	tst.b	d0
	beq	.s
	addq.w	#5,d1
.s	bsr	.w
	divu	#1000,d1
	bsr	.w
	divu	#100,d1
	bsr	.w
	divu	#10,d1
.w	move.b	d1,(a0)+
	clr.b	(a0)
	clr.w	d1
	swap	d1
	rts
	

_buttonwait	move.l	#100,d0
		move.l	(_resload,pc),a0
		jmp	(resload_Delay,a0)

_bw	BLITWAIT
	rts

_bw1	bsr	_bw
	move.w	#$1c,$dff064
	addq.l	#2,(a7)
	rts

; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f

QUIT	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_patchdelay
    patch   $100,DELAY2
    patch   $106,DELAYD4
    patch   $10C,DELAYD7
    patch   $112,DELAYD1
	rts

DELAYD1	MOVE.L	D0,-(A7)
	NOT.B	D0
	ROR.B	#1,D0
	CMP.B	qkey(pc),D0
	BEQ	QUIT
	ADD.B	#$28,D1
	MOVE.L	D1,D0
	BSR.S	DELAY2
	MOVE.L	(A7)+,D0
	RTS

DELAYD4	MOVE.L	D0,-(A7)
	MOVE.L	D4,D0
	BSR.S	DELAY2
	MOVE.L	(A7)+,D0
	RTS

DELAYD7	MOVE.L	D0,-(A7)
	MOVE.L	D7,D0
	BSR.S	DELAY2
	MOVE.L	(A7)+,D0
	RTS

DELAY	MOVE.W	#$12C,D0
DELAY2	SWAP	D0
	CLR.W	D0
	SWAP	D0
	DIVU	#$28,D0
.2	MOVE.l	D0,-(A7)
	MOVE.B	$DFF006,D0
.1	CMP.B	$DFF006,D0
	BEQ.S	.1
	MOVE.l	(A7)+,D0
	DBF	D0,.2
	RTS

;=====================================================================

_tags		dc.l	WHDLTAG_CUSTOM5_GET
_skip_intro		dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_start_level		dc.l	0
		dc.l	0
_resload	dc.l	0	;address of resident loader
DISKNR		DC.B	1

