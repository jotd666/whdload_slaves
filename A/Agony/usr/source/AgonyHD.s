
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	Agony.slave
	OPT	O+ OG+			;enable optimizing
	ENDC
	
;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
		dc.b	0		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem		
	dc.l	0			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

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
	
_data   dc.b    0
_name	dc.b	'Agony',0
_copy	dc.b	'1992 Psygnosis & Art And Magic',0
_info
    dc.b   'adapted by JOTD',10,10
	dc.b	'AGA Copper patches and little fixes by ross',10
	dc.b	'Thanks to Psygore for blitter fix',10,10
    dc.b   'Press HELP to skip levels',10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	
_config
	dc.b	"BW;"
    dc.b    "C1:X:Infinite lives:0;"
    dc.b    "C2:X:Full power:0;"
    dc.b    "C3:X:Skip introduction (PAL only):0;"
	dc.b	0

	dc.b	'$VER: Agony by JOTD - '
	DECL_VERSION
	dc.b	0
	CNOP 0,2

NOSCORE_ID = 'NOSC'
LOAD_SIGNATURE = $33C6

; $1B4.L: score in hex. Set 300000 points: W $1B4 $300000.L

;======================================================================
Start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	
	lea	$60000,A0		; dest buffer
	move.l	#$7E6,D0		; length
	lea	boot(pc),A1		; source buffer
	bsr	Decrunch

	sub.l	a1,a1
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	
		
	lea	Tags(pc),a0
	jsr	resload_Control(a2)		

	jmp	$60000

quit:
		move.l	_resload(pc),a2
		move.l	#TDREASON_OK,-(A7)
		jmp	resload_Abort(a2)

Remove24BitErrors:
	move.l	#$284045EA,D0	; move.l D0,A4...
	move.l	#$264045EA,D1	; move.l D0,A3...
.loop:
	move.l	(A0),D2
	cmp.l	D1,D2
	beq.b	.patchA3
	cmp.l	D0,D2
	beq.b	.patchA4
.next:
	addq.l	#2,A0
	cmp.l	A0,A1
	bcc.b	.loop
	RTS

.patchA3:
	move.w	#$4E4E,(A0)
	bra.b	.next

.patchA4:
	move.w	#$4E4F,(A0)
	bra.b	.next

; *** TRAP #$E entry

Patch24Bit_A3:
	move.l	D0,-(A7)
	andi.l	#$FFFFFF,D0
	move.l	D0,A3
	move.l	(A7)+,D0
	RTE

; *** TRAP #$F entry

Patch24Bit_A4:
	move.l	D0,-(A7)
	andi.l	#$FFFFFF,D0
	move.l	D0,A4
	move.l	(A7)+,D0
	RTE

KbInt_Level1:
	tst.b	$BFED01
	cmp.b	#$5F,D0
	bne	CheckQuit
	move.w	#$14,($7CCA,A5)
	st.b	($7CE0,A5)
	rts

; *** common to levels 2-3-4-5-6

KbInt_Level2:
	tst.b	$BFED01
	cmp.b	#$5F,D0
	bne	CheckQuit

	cmp.l	#$54DB4,A5
	beq.b	Skip_Level2	; PAL
	cmp.l	#$54E14,A5
	beq.b	Skip_Level2	; NTSC

	cmp.l	#$59370,A5	; PAL
	beq.b	Skip_Level3
	cmp.l	#$593D0,A5	; NTSC
	beq.b	Skip_Level3

	cmp.l	#$55548,A5
	beq.b	Skip_Level4	; PAL
	cmp.l	#$555A8,A5
	beq.b	Skip_Level4	; NTSC

	cmp.l	#$5900C,A5
	beq.b	Skip_Level5	; PAL
	cmp.l	#$5906C,A5
	beq.b	Skip_Level5	; NTSC

	cmp.l	#$5A0A6,A5
	beq.b	Skip_Level6	; PAL
	cmp.l	#$5A106,A5
	beq.b	Skip_Level6	; NTSC

	bra.b	CheckQuit

Skip_Level2:
	move.w	#$14,($6D0E,A5)
	st.b	($6D24,A5)
	rts

Skip_Level3:
	move.w	#$14,($71A6,A5)
	st.b	($71BC,A5)
	rts

Skip_Level4:
	move.w	#$14,($7622,A5)
	st.b	($7638,A5)
	rts

Skip_Level5:
	move.w	#$14,($71E4,A5)
;	clr.w	$1B8.W		; ESC key
	st.b	($71FA,A5)
	rts

Skip_Level6:
	move.w	#$14,($6C62,A5)
	st.b	($6C78,A5)
	rts


InstallNTSCFat:
	movem.l   D0-A6,-(A7)
	lea	ntscfat(pc),A0
	lea	$200.W,A1
	move.w	#$EF,D0
.copy
	move.b	(A0)+,(A1)+
	dbf	D0,.copy

	movem.l   (A7)+,D0-A6
	rts

KbInt:
	lsr.w	#1,D0
	eor.w	#$7F,D0
CheckQuit:
	
	cmp.b	_keyexit(pc),D0
	bne.b	.noquit		; F10: exit
	bra	quit
.noquit
	RTS

EmulateDbf:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	
; < D0: numbers of vertical positions to wait
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts


; st $44(A6) was wrong (thanks Psygore)

SetBltMask:
	move.w	#$FFFF,$44(A6)
	rts

; 00000634 4eb9 0000 1aa0           JSR $00001aa0 called after game over
; < A0: score table
HandleScores:
	movem.l   D0-A6,-(A7)
	move.l	a0,a1		; put buffer in A1
	lea	scorename(pc),A0	; now set name
	moveq	#$30,D0
	move.l	_resload(pc),a2
	
	tst.b	D1
	beq.b	ReadScores
WriteScores:
	; don't save score if you cheat (and end the game)
	move.l	infinite_lives(pc),d1
	bne.b	.nowrite
	move.l	maxed_out(pc),d1
	bne.b	.nowrite
	jsr	resload_SaveFile(a2)
.nowrite
	bra.b	score_exit

ReadScores:
	move.l	a1,a3	; save in A3
	lea	scorename(pc),A0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	score_exit
	lea	scorename(pc),A0
	move.l	a3,a1
	jsr	resload_LoadFile(a2)
score_exit
	movem.l   (A7)+,D0-A6
	RTS

PatchIntro:
	patch	$663B8,ReadFile
	bsr	_flushcache
	JMP	$66352


_wait3s
	movem.l	d0/a2,-(sp)
	moveq	#30,d0				;3 seconds
	move.l	(_resload,pc),a2
	jsr	(resload_Delay,a2)
	movem.l	(sp)+,d0/a2
	lea	$dff000,a6
	rts

	
ReadFileWait:
	bsr.b	DoRead
	move.l	D0,-(sp)
	move.l	buttonwait(pc),D0
	beq.b	.exit
.wait
	btst	#7,$BFE001
	bne.b	.wait
.exit
	move.l	(sp)+,D0
	tst.l	D0
	RTS

ReadFile:
	bsr.b	DoRead
	tst.l	D0
	RTS

; read routine
; < D0: offset (bytes, careful, substract 2*tracklen for disk 1 and 2)
; < D1: size (bytes)
; < A0: target
; > D6: disk (0-2)
; > D7: crypt key

DoRead:
	movem.l   D0-A6,-(A7)

	move.l	D0,D2	; offset
	moveq	#0,d0
	move.b	D6,D0
	cmp.b	#2,D0
	beq.b	.nosub
	subi.l	#$3000,D2	; substract offset
.nosub
; offset should be in d0
; D0 is disk number, move to D2
; D1 is OK
	exg.l	d0,d2
	addq.l	#1,d2
	move.l	_resload(pc),a2
	movem.l	d0-d1/a0-a1,-(a7)
	jsr	(resload_DiskLoad,a2)
	movem.l	(a7)+,d0-d1/a0-a1
;  success,errorcode = resload_DiskLoad(offset,size,diskno,dest)
;          D0       D1                    D0    D1    D2    A0
;         BOOL    ULONG                  ULONG ULONG UBYTE APTR
	
	bsr.b	Decrypt

	movem.l   (A7)+,D0-A6
	add.l	D1,A0
	moveq	#0,D0
	RTS

Decrypt:
.loop
	eor.l	D7,(A0)+
	subq.l	#4,D1
	bcc.b	.loop
	rts

.fileerr

	bra	quit


Decrunch:
	MOVEM.L	D2-D7/A2-A6,-(A7)	;000: 48E73F3E
	MOVEA.L	A0,A3			;004: 2648
	MOVEA.L	(A1)+,A2		;006: 2459
	ADDA.L	A2,A3			;008: D7CA
	TST.L	D0			;00A: 4A80
	BEQ.B	LAB_0001		;00C: 67000016
	MOVEA.L	A1,A4			;010: 2849
	ADDA.L	D0,A4			;012: D9C0
	MOVEA.L	A3,A5			;014: 2A4B
	ADDQ	#8,A5			;016: 504D
	ADDQ.L	#8,D0			;018: 5080
LAB_0000:
	MOVE.B	-(A4),-(A5)		;01A: 1B24
	SUBQ.L	#1,D0			;01C: 5380
	BPL.S	LAB_0000		;01E: 6AFA
	LEA	9(A5),A1		;020: 43ED0009
LAB_0001:
	MOVEQ	#32,D3			;024: 7620
	MOVEQ	#31,D4			;026: 781F
	MOVE	#$1FFF,D5		;028: 3A3C1FFF
	MOVEQ	#34,D6			;02C: 7C22
	MOVE.B	(A1)+,D7		;02E: 1E19
LAB_0002:
	MOVEQ	#0,D0			;030: 7000
	MOVE.B	(A1)+,D0		;032: 1019
	BTST	#7,D0			;034: 08000007
	BNE	LAB_000E		;038: 66000094
	BTST	#6,D0			;03C: 08000006
	BEQ.S	LAB_0008		;040: 674E
	BTST	#5,D0			;042: 08000005
	BEQ.S	LAB_0006		;046: 6732
	LSL	#8,D0			;048: E148
	OR.B	(A1)+,D0		;04A: 8019
	AND	D5,D0			;04C: C045
	BCLR	#12,D0			;04E: 0880000C
	BEQ.S	LAB_0004		;052: 6712
	ADDI	#$0011,D0		;054: 06400011
LAB_0003:
	MOVE.B	D7,(A0)+		;058: 10C7
	DBF	D0,LAB_0003		;05A: 51C8FFFC
	CMPA.L	A0,A3			;05E: B7C8
	BGT.S	LAB_0002		;060: 6ECE
	BRA	LAB_0014		;062: 600000BE
LAB_0004:
	ADDI	#$0011,D0		;066: 06400011
	MOVE.B	(A1)+,D1		;06A: 1219
LAB_0005:
	MOVE.B	D1,(A0)+		;06C: 10C1
	DBF	D0,LAB_0005		;06E: 51C8FFFC
	CMPA.L	A0,A3			;072: B7C8
	BGT.S	LAB_0002		;074: 6EBA
	BRA	LAB_0014		;076: 600000AA
LAB_0006:
	LSL	#8,D0			;07A: E148
	OR.B	(A1)+,D0		;07C: 8019
	AND	D5,D0			;07E: C045
	ADD	D3,D0			;080: D043
LAB_0007:
	MOVE.B	(A1)+,(A0)+		;082: 10D9
	DBF	D0,LAB_0007		;084: 51C8FFFC
	CMPA.L	A0,A3			;088: B7C8
	BGT.S	LAB_0002		;08A: 6EA4
	BRA	LAB_0014		;08C: 60000094
LAB_0008:
	BTST	#5,D0			;090: 08000005
	BEQ.S	LAB_000C		;094: 6728
	AND	D4,D0			;096: C044
	BCLR	#4,D0			;098: 08800004
	BEQ.S	LAB_000A		;09C: 670E
	MOVE.B	D7,(A0)+		;09E: 10C7
LAB_0009:
	MOVE.B	D7,(A0)+		;0A0: 10C7
	DBF	D0,LAB_0009		;0A2: 51C8FFFC
	CMPA.L	A0,A3			;0A6: B7C8
	BGT.S	LAB_0002		;0A8: 6E86
	BRA.S	LAB_0014		;0AA: 6076
LAB_000A:
	MOVE.B	(A1)+,D1		;0AC: 1219
	MOVE.B	D1,(A0)+		;0AE: 10C1
LAB_000B:
	MOVE.B	D1,(A0)+		;0B0: 10C1
	DBF	D0,LAB_000B		;0B2: 51C8FFFC
	CMPA.L	A0,A3			;0B6: B7C8
	BGT	LAB_0002		;0B8: 6E00FF76
	BRA.S	LAB_0014		;0BC: 6064
LAB_000C:
	AND	D4,D0			;0BE: C044
LAB_000D:
	MOVE.B	(A1)+,(A0)+		;0C0: 10D9
	DBF	D0,LAB_000D		;0C2: 51C8FFFC
	CMPA.L	A0,A3			;0C6: B7C8
	BGT	LAB_0002		;0C8: 6E00FF66
	BRA.S	LAB_0014		;0CC: 6054
LAB_000E:
	BTST	#6,D0			;0CE: 08000006
	BEQ.S	LAB_000F		;0D2: 670C
	MOVE.B	D0,D1			;0D4: 1200
	LSL	#8,D1			;0D6: E149
	OR.B	(A1)+,D1		;0D8: 8219
	AND	D5,D1			;0DA: C245
	ADD	D6,D1			;0DC: D246
	BRA.S	LAB_0010		;0DE: 6006
LAB_000F:
	MOVE.B	D0,D1			;0E0: 1200
	AND	D4,D1			;0E2: C244
	ADDQ	#2,D1			;0E4: 5441
LAB_0010:
	BTST	#5,D0			;0E6: 08000005
	BEQ.S	LAB_0012		;0EA: 671E
	MOVEQ	#0,D2			;0EC: 7400
	MOVE.B	(A1)+,D2		;0EE: 1419
	LSL	#8,D2			;0F0: E14A
	OR.B	(A1)+,D2		;0F2: 8419
	LEA	-257(A0),A4		;0F4: 49E8FEFF
	SUBA.L	D2,A4			;0F8: 99C2
	SUBA	D1,A4			;0FA: 98C1
LAB_0011:
	MOVE.B	(A4)+,(A0)+		;0FC: 10DC
	DBF	D1,LAB_0011		;0FE: 51C9FFFC
	CMPA.L	A0,A3			;102: B7C8
	BGT	LAB_0002		;104: 6E00FF2A
	BRA.S	LAB_0014		;108: 6018
LAB_0012:
	MOVEQ	#0,D2			;10A: 7400
	MOVE.B	(A1)+,D2		;10C: 1419
	LEA	-1(A0),A4		;10E: 49E8FFFF
	SUBA	D2,A4			;112: 98C2
	SUBA	D1,A4			;114: 98C1
LAB_0013:
	MOVE.B	(A4)+,(A0)+		;116: 10DC
	DBF	D1,LAB_0013		;118: 51C9FFFC
	CMPA.L	A0,A3			;11C: B7C8
	BGT	LAB_0002		;11E: 6E00FF10
LAB_0014:
	MOVE.L	A2,D0			;122: 200A
	MOVEM.L	(A7)+,D2-D7/A2-A6	;124: 4CDF7CFC

	bsr		PatchProgs
	bsr.b	PatchAGACL
	bsr.b	_flushcache

	tst.l	D0
	RTS				;128: 4E75

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
	
PatchAGACL:
	movem.l   d0-d3/a0-a1,-(A7)
	move.l	#$009000b0,d1
	move.l	#$01e43110,d2

	lea	_cop1lcs(pc),a0		;PAL
	moveq	#0,d3
	bsr.b	.nl
	beq.b	.p

	lea	_cop1lcs(pc),a0		;NTSC
	move.w	#$f0b0,d1
	move.w	#$3010,d2
	moveq	#$60,d3
	bsr.b	.nl
	bne.b	.x

.p	move.l	d2,(a1)
	move.w	d1,-178(a1)
	move.w	#$6601,42(a1)
	move.w	#$0c60,$dff106

.x	movem.l   (a7)+,d0-d3/a0-a1
	rts

.nl	moveq	#(_cop1lcend-_cop1lcs)/4-1,d0
.ll	movea.l	(a0)+,a1
	lea	292(a1),a1
	adda.l	d3,a1
	cmp.l	(a1),d1
	dbeq	d0,.ll
	rts


_cop1lcs
;PAL		;   L1     L2     L3     L4     L5     L6
	dc.l	$5e962,$599e4,$5e438,$5a8e0,$5e3ba,$5eed2
;NTSC		;   L(x)+$60
;	dc.l	$5e9c2,$59a44,$5e498,$5a940,$5e41a,$5ef32
_cop1lcend


PatchProgs:
	movem.l   D0-A6,-(A7)
	move.l	_resload(pc),a2
	
	cmp.l	#$66352,$D9A.W
	bne.b	.lab1

	patch	$D98.w,PatchIntro

.lab1:

	cmp.w	#LOAD_SIGNATURE,$12EC.W
	bne.b	.lab2

	; patch 2 (NTSC)

	lea	pl_2_ntsc(pc),a0
	sub.l	a1,a1
	jsr	(resload_Patch,a2)
	

	bsr	InstallNTSCFat

.lab2:

	cmp.w	#LOAD_SIGNATURE,$12D0.W
	bne.b	.lab3

	; patch 2 (PAL)

	lea	pl_2_pal(pc),a0
	sub.l	a1,a1
	jsr	(resload_Patch,a2)

	; *** insert my name :-)

	lea	$42BDC,A0
	move.l	#$29070329,(A0)+	; HD
	move.l	#$0B0E0003,(A0)+	; LOAD
	move.l	#$041129FE,(A0)+	; ER

	lea	$42BF2,A0
	move.l	#$29292929,(A0)+
	move.l	#$090E1303,(A0)+	; JOTD
	move.l	#$291B2323,(A0)+	; 1997
	move.l	#$212929FE,(A0)+

.lab3
	cmp.w	#LOAD_SIGNATURE,$3BC2.W
	bne.b	.lab4

	; patch 3 (PAL)

	; *** level 1 patches

	patch	$3BC8.W,ReadFile
	patchs	$5C94.W,KbInt_Level1
	
.lab4:
	cmp.w	#LOAD_SIGNATURE,$3BCA.W
	bne.b	.lab5

	; *** level 1 patches

	patch	$3BD0.W,ReadFile
	patchs	$5CF4.W,KbInt_Level1

.lab5
	; *** between game load

	cmp.w	#LOAD_SIGNATURE,$61762
	bne.b	.lab6

	patch	$61768,ReadFileWait

	; *** between game load

.lab6

	cmp.w	#LOAD_SIGNATURE,$6177E
	bne.b	.lab7

	patch	$61784,ReadFileWait

.lab7

	cmp.w	#LOAD_SIGNATURE,$3BBE.W
	bne.b	.lab8

	; *** level 2-3-4-5-6 patches

	patch	$3BC4.W,ReadFile
	patchs	$5BC4.W,KbInt_Level2

.lab8

	cmp.w	#LOAD_SIGNATURE,$3BC6.W
	bne.b	.lab9

	; *** level 2-3-4-5-6 patches

	patch	$3BCC.W,ReadFile
	patchs	$5C24.W,KbInt_Level2

.lab9

	cmp.w	#LOAD_SIGNATURE,$CFA.W
	bne.b	.laba

	; *** patch end sequence

	patch	$D00.W,ReadFile

.laba

	cmp.w	#LOAD_SIGNATURE,$D16.W
	bne.b	.labb

	; *** patch end sequence NTSC

	patch	$D1C.W,ReadFile

.labb

	; *** 24 bit patch : 2 search zones: $2000-$3000 and $4A000-$52000

	lea	$2000.w,A0
	lea	$3000.w,A1
	bsr	Remove24BitErrors

	lea	$4A000,A0
	lea	$52000,A1
	bsr	Remove24BitErrors

	; *** blitter mask error patch: search $1000 $5000

	lea	$1000.w,A0
	lea	$5000.w,A1
	move.l	#$50EE0044,D0
	move.l	#$4EB80106,D1
.looprep
	move.l	(a0),d2
	cmp.l	d2,d0
	bne.b	.next
	move.l	d1,(a0)
.next
	addq.l	#2,a0		;addq.l	#4,a0 (fix search)	
	cmp.l	a0,a1
	bne.b	.looprep

	; *** blitter mask error patch: search $1000 $5000

	lea	$4000.w,A0
	lea	$7000.w,A1
	bsr.b	button2support

	movem.l   (A7)+,D0-A6
	RTS

button2support
	move.l	a0,a3
	lea	.int2end(pc),a2
	moveq	#12,d0
	bsr.b	hexsearch
	cmp.l	#0,a0
	beq.b	.out
	lea	int2jmp(pc),a2
	move.l	a0,(a2)
	move.l	a3,a0

	lea	.int3end(pc),a2
	moveq	#12,d0
	bsr.b	hexsearch
	cmp.l	#0,a0
	beq.b	.out
	move.w	#$4EF9,(a0)+
	pea	button2test(pc)
	move.l	(a7)+,(a0)
.out
	rts

.int3end
	dc.l	$3D7C0020,$009C4CDF,$7FFF4E73
.int2end
	dc.l	$B07C0040,$6700005A,$B07C0045

hexsearch
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts

int2jmp
	dC.l	0

button2test:
	btst	#6,$dff016
	bne.b	.out
	move.w	#$CC01,$dff034	; reset POTGO
	move.w	last_time_pressed(pc),d0
	bne.b	.out2		; don't do anything till release
	lea	last_time_pressed(pc),a0
	st	(a0)
	move.b	#$40,d0	; emulates SPACE key
	move.w	#$20,($9C,a6)	; stolen
	move.l	int2jmp(pc),-(a7)
	rts
.out
	; not pressed
	lea	last_time_pressed(pc),a0
	clr.w	(a0)
.out2
	move.w	#$20,($9C,a6)	; stolen
	
	; here we can plug our trainer
	move.l	infinite_lives(pc),d0
	beq.b	.noinf
	move.w	#$1F,$1B8.W	; 5 lives no matter what
.noinf
	move.l	maxed_out(pc),d0
	beq.b	.nomax
	MOVE.W #$1F,$000001b8.w 
	MOVE.L #$FF00FF00,$000001ba.w 	; 2 swords
	MOVE.W #4,$000001be.w 		; front weapon
	move.l	#$00010001,D0
	; special powers: there are 8 of them, 1 word per power
	lea	$1C4.W,A0
	MOVE.L D0,(a0)+
	MOVE.L D0,(a0)+
	MOVE.L D0,(a0)+
	MOVE.L D0,(a0)+
.nomax
	movem.l   (A7)+,D0-A6
	RTE

last_time_pressed
	dc.w	0
	
pl_boot:
	PL_START
	PL_P	$80,Decrunch
	PL_P	$100,EmulateDbf
	PL_P	$106,SetBltMask
	PL_P	$C6,ReadFile
	PL_PA	$B8,Patch24Bit_A3
	PL_PA	$BC,Patch24Bit_A4
	PL_P	$6013E,ReadFile
	PL_IFC3
	PL_W	$60074,$6042
	PL_ENDIF
	PL_END

pl_2_pal
	PL_START
	PL_PS	$d2e,_wait3s
	PL_P	$12D6,ReadFile
	; called from $634
	; $98E
	; $99C
	PL_P	$1AA0,HandleScores
	; patch dbf delays
	PL_L	$226C,$4EB80100
	PL_L	$2282,$4EB80100
	PL_L	$29B4,$4EB80100
	PL_L	$29CA,$4EB80100
	PL_NEXT	pl_common

pl_2_ntsc
	PL_START
	PL_PS	$d2e,_wait3s
	PL_P	$12F2,ReadFile
	PL_P	$1ABC,HandleScores
	; patch dbf delays
	PL_L	$2288,$4EB80100
	PL_L	$229E,$4EB80100
	PL_L	$29D0,$4EB80100
	PL_L	$29E6,$4EB80100
	PL_NEXT	pl_common
	
	; common to PAL and NTSC versions

pl_common
	PL_START
	PL_PS	$D80,KbInt

	PL_END

	
Tags		dc.l	WHDLTAG_BUTTONWAIT_GET
buttonwait:		dc.l	0
	dc.l	WHDLTAG_CUSTOM1_GET
infinite_lives	dc.l	0
	dc.l	WHDLTAG_CUSTOM2_GET
maxed_out	dc.l	0
	
		dc.l	0


_resload
	dc.l	0
scorename:
	dc.b	"highs",0
	cnop	0,4
ScoreTable:
	dc.l	NOSCORE_ID
	ds.l	$2F
boot:
	incbin	"boot.bin"
	cnop	0,4
ntscfat:
	incbin	"ntscfat.bin"
