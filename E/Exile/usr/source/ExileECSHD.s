		INCDIR	"Include:"
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"Exile.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

CHIPMEMSIZE = $80000

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$2000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		
DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
    
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
    
_name		dc.b	'Exile',0
_copy		dc.b	'1991 Audiogenic',0
_info		dc.b	'adapted by Bored Seal & JOTD',10
		dc.b	'and Codetapper/Action!',10,10
		dc.b	'-------------------------',10
		dc.b	'All Protection removed by',10
		dc.b	'Galahad / Fairlight',10
		dc.b	'-------------------------',10,10
		DECL_VERSION
        dc.b    0
		even



_Start		LEA	(_resload,PC),A1
		MOVE.L	A0,(A1)

		move.l	a0,a2		;does old savedisk image exists?
		lea	_savedisk(pc),a0
        jsr     (resload_GetFileSize,a2)
		tst.l	d0
		bne	continue

		lea	_savedisk(pc),a0	;create empty disk.2 image
		suba.l	a1,a1
		move.l	#22528,d0
		jsr	(resload_SaveFile,a2)

continue	LEA	(_tags,PC),A0
		JSR	(resload_Control,A2)

        ; stack in fast memory (used to be in $82000 WTF,
        ; preventing 512k chip users to run the game)
		move.l  _expmem(pc),d0
        add.l   #$2000,d0
        move.l  d0,a7
        
		MOVEQ	#0,D0
		MOVEQ	#2,D1
		MOVEQ	#6,D2
		LEA	($6F53C).L,A0
		BSR.W	LoadRNCTracks

		LEA	($6FFF8).L,A1
		LEA	($6F560).L,A0
		MOVE.W	#$2A6,D1
		BSR.W	Decode

		MOVE.W	#$4EF9,($6F6DA).L
		PEA	(LoadRNCTracks,PC)
		MOVE.L	(SP)+,($6F6DC).L

		MOVE.W	#$4EF9,($6F5D6).L
		PEA	(PatchBoot,PC)
		MOVE.L	(SP)+,($6F5D8).L

		LEA	($DFF000).L,A5
		JMP	($6F558).L

PatchBoot	LEA	($6CCBE).L,A1
		LEA	($6B334).L,A0
		MOVE.W	#$662,D1
		BSR.W	Decode

		MOVE.W	#$4EF9,($6BE94).L	;remove copylock
		PEA	(NoCopylock,PC)
		MOVE.L	(SP)+,($6BE96).L

		MOVE.W	#$100,($6BE5C).L
		MOVE.W	#$4EF9,($100).W
		PEA	(PatchGame,PC)
		MOVE.L	(SP)+,($102).W

		MOVE.W	#$4E75,($6BEE6).L	;don't wait for music pattern

		LEA	(_fastboot,PC),A3
		TST.L	(A3)
		BEQ.B	noskip
		
		MOVE.W	#$4E71,($6BD6C).L
		MOVE.W	#$4E75,($6C0DC).L
		MOVE.W	#$4E75,($6C146).L

noskip		LEA	(Deprotect,PC),A0	;copy correct copylock crack
		LEA	($6B34E).L,A1
		MOVEQ	#$61,D0
until		MOVE.B	(A0)+,(A1)+
		DBRA	D0,until
		MOVE.L	#$600008C0,(A1)+
        
    patchs   $6BD0C,loader_hook
        bsr     _flushcache

		JMP	$6B32C

loader_hook
    CLR.L $0006ff9c
    cmp.l   #$2321C,a0
    bne.b   .nointro

    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    move.l  a0,a1
    lea pl_intro(pc),a0
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2

.nointro
    rts

pl_intro
    PL_START
    PL_PSS   $2358E-$2321C,soundtracker_loop,2
    PL_PSS   $23578-$2321C,soundtracker_loop,2
    PL_END
    
    
soundtracker_loop
	move.w	#8,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	rts
    
PatchGame	MOVEM.L	D0-D3/A0-A2,-(SP)
		LEA	($100).W,A0		;insert blitter waits
		MOVE.W	#$4EF9,D0
		MOVE.W	D0,(A0)+
		PEA	(BlitFixD0,PC)
		MOVE.L	(SP)+,(A0)+
		MOVE.W	D0,(A0)+
		PEA	(BlitFixD1,PC)
		MOVE.L	(SP)+,(A0)+
		MOVE.W	D0,(A0)+
		PEA	(BlitFixD2,PC)
		MOVE.L	(SP)+,(A0)+
		MOVE.W	D0,(A0)+
		PEA	(BlitFixD3,PC)
		MOVE.L	(SP)+,(A0)+
		MOVE.W	D0,(A0)+
		PEA	(BlitFixD4,PC)
		MOVE.L	(SP)+,(A0)+

		MOVE.W	#$3B40,D1
		MOVE.L	#$4EB80100,D2
		BSR.W	Replace
		MOVE.W	#$3B41,D1
		MOVE.L	#$4EB80106,D2
		BSR.W	Replace
		MOVE.W	#$3B42,D1
		MOVE.L	#$4EB8010C,D2
		BSR.W	Replace
		MOVE.W	#$3B43,D1
		MOVE.L	#$4EB80112,D2
		BSR.W	Replace
		MOVE.W	#$3B44,D1
		MOVE.L	#$4EB80118,D2
		BSR.W	Replace

		MOVE.L	#$4E714EB9,D0
		MOVE.W	D0,($1BCE2).L
		PEA	(BlitFix1,PC)
		MOVE.L	(SP)+,($1BCE4).L

		MOVE.W	D0,($1BD0A).L
		PEA	(BlitFix2,PC)
		MOVE.L	(SP)+,($1BD0C).L

		MOVE.W	D0,($1B4A8).L
		MOVE.W	D0,($1B768).L
		PEA	(BlitFix3,PC)
		MOVE.L	(SP),($1B4AA).L
		MOVE.L	(SP)+,($1B76A).L

		MOVE.L	D0,($1B752).L
		PEA	(BlitFix4,PC)
		MOVE.L	(SP)+,($1B756).L

		MOVE.W	D0,($2067E).L
		PEA	(BlitFix5,PC)
		MOVE.L	(SP)+,($20680).L

		LEA	(InsertDisk2_JMP,PC),A0
		MOVE.L	A0,($1FAF6).L

		LEA	(InsertDisk2_JMP2,PC),A0
		MOVE.L	A0,($1FBEC).L

		LEA	(InsertDisk1_JMP,PC),A0
		MOVE.L	A0,($1F63C).L

		LEA	(Deprotect2,PC),A0	;Galahad's crack
		LEA	($1FF04).L,A1
		MOVE.W	#$4EB9,(A1)+
		MOVE.L	A0,(A1)
		MOVE.W	#$4E71,($1A880).L

		MOVE.W	#$6008,($1FC10).L	;skip disk id check

		LEA	(_disknum,PC),A0	;insert savedisk
		MOVE.B	#2,(A0)

		MOVE.W	D0,($1D648).L		;This allows everyone to quit the game, even 68000 users
		PEA	(_keybd,PC)
		MOVE.L	(SP)+,($1D64A).L
	
		clr.l	-(a7)			;Set switch between O/S and
		pea	_cbswitch(pc)		;game, otherwise game freezes
		pea	WHDLTAG_CBSWITCH_SET	;after the game is saved
		move.l	a7,a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		add.w	#12,a7	

		MOVEM.L	(SP)+,D0-D3/A0-A2
        bsr     _flushcache
		JMP	($470).W

_keybd		MOVE.B	($BFEC01).L,D0		;Detect quit key
		MOVE.L	D0,-(SP)
		NOT.B	D0
		LSR.B	#1,D0
		CMP.B	(_keyexit,PC),D0
		BEQ.W	_exit
		MOVE.L	(SP)+,D0
		RTS

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

_cbswitch	MOVE.L	#$6A014,($DFF084).L	;required for savegames
		MOVE.W	#$FFFF,($DFF044).L
		MOVE.W	#$7FFF,($DFF046).L
		JMP	(A0)

Replace		LEA	($1B2A8).L,A0
hunt		MOVE.W	(A0)+,D3
		CMP.W	D1,D3
		BNE.B	notmycode
		CMPI.W	#$58,(A0)+
		BNE.B	notmycode
		MOVE.L	D2,-(A0)
notmycode	CMPA.L	#$1C15A,A0
		BLE.B	hunt
		RTS

BlitFixD1	MOVE.W	D1,($58,A5)
		BRA.B	BlitWait

BlitFixD2	MOVE.W	D2,($58,A5)
		BRA.B	BlitWait

BlitFixD3	MOVE.W	D3,($58,A5)
		BRA.B	BlitWait

BlitFixD4	MOVE.W	D4,($58,A5)
		BRA.B	BlitWait

BlitFixD0	MOVE.W	D0,($58,A5)
BlitWait	BTST	#6,($DFF002).L
		BNE.B	BlitWait
		RTS

BlitFix1	MOVE.W	($1BD8E).L,($58,A5)
		BRA.B	BlitWait

BlitFix2	MOVE.W	($1BD90).L,($58,A5)
		BRA.B	BlitWait

BlitFix3	MOVE.W	(6,SP),($58,A5)
		BRA.B	BlitWait

BlitFix4	MOVE.W	(4,SP),($58,A5)
		ANDI.W	#$F000,D6
		BRA.B	BlitWait

BlitFix5	MOVE.W	#$20C,($58,A5)
		BRA.B	BlitWait

NoCopylock	MOVE.L	#$3B6E0002,($2383E).L	;snoop mode fixes
		MOVE.W	#$3D7C,($23838).L
		MOVE.W	#2,($2383C).L
		MOVE.L	#$B076837E,D0		;copylock key
		RTS

Decode		MOVE.W	-(A1),D0
		MOVE.W	(A0),(A1)
		MOVE.W	D0,(A0)+
		DBRA	D1,Decode
		RTS

InsertDisk2_JMP	MOVE.L	A0,-(SP)
		LEA	(_disknum,PC),A0
		MOVE.B	#2,(A0)
		MOVEA.L	(SP)+,A0
		JMP	($1E9EE).L

InsertDisk2_JMP2	MOVE.L	A0,-(SP)
		LEA	(_disknum,PC),A0
		MOVE.B	#2,(A0)
		MOVEA.L	(SP)+,A0
		JMP	($1E5B4).L

InsertDisk2	MOVE.L	A0,-(SP)
		LEA	(_disknum,PC),A0
		MOVE.B	#2,(A0)
		MOVEA.L	(SP)+,A0
		RTS

InsertDisk1_JMP	MOVE.L	A0,-(SP)
		LEA	(_disknum,PC),A0
		MOVE.B	#1,(A0)
		MOVEA.L	(SP)+,A0
		JMP	($1946C).L

LoadRNCTracks	MOVEM.L	D0-D3/A0-A2,-(SP)
		MULU.W	#$200,D1
		MULU.W	#$200,D2
		MOVE.L	D1,D0
		MOVE.L	D2,D1
		MOVEA.L	(_resload,PC),A2
		LEA	(_disknum,PC),A1
		MOVE.B	(A1),D2
		CMPI.B	#2,D2
		BNE.B	TestCMD
		SUB.L	#$94800,D0		;fix offset for savedisk image
TestCMD		CMPI.W	#$8001,D3		;test if "save" (RNC loader command)
		BEQ.B	SaveGame
		CMPI.W	#$8002,D3		;test if "format" (RNC loader command - useless)
		BEQ	Return
		JSR	(resload_DiskLoad,A2)
		MOVEM.L	(SP)+,D0-D3/A0-A2
		MOVEQ	#0,D0
		RTS

SaveGame	EXG	D0,D1
		MOVE.L	A0,A1
		LEA	(_savedisk,PC),A0
		MOVEA.L	(_resload,PC),A2
		JSR	(resload_SaveFileOffset,A2)
		BSR	BlitWait		;wait after save is done
Return		MOVEM.L	(SP)+,D0-D3/A0-A2
		RTS

Deprotect2	MOVE.L	A0,-(SP)
		LEA	(_disknum,PC),A0
		MOVE.B	#2,(A0)
		MOVEA.L	(SP)+,A0
		
		MOVEM.L	D0-D7/A0-A6,-(SP)
Deprotect	MOVEM.L	D0-D7/A0-A7,-(SP)
		MOVE.L	#$2CC6C50D,D0
		MOVEQ	#3,D3
		MOVEA.L	SP,A6
pt1		LSL.W	#2,D3
		MOVE.L	(A6,D3.W),D2
		ROL.W	#4,D2
		AND.B	#15,D2
		BEQ.W	pt2
		SUBI.W	#$1000,(2,A6,D3.W)
		MOVE.L	(A6,D3.W),D3
		ROL.W	#8,D3
		MOVE.W	D3,D1
		AND.W	#7,D1
		LSL.W	#2,D1
		MOVEA.L	($20,A6,D1.W),A0
		ROL.W	#4,D3
		MOVE.W	D3,D1
		AND.W	#7,D1
		LSL.W	#2,D1
		MOVE.L	(A6,D1.W),D1
pt3		MOVEA.L	(A0)+,A1
		ADD.L	D0,(A1,D1.L)
		SUBQ.B	#1,D2
		BNE.B	pt3
		ROL.W	#4,D3
		AND.W	#15,D3
		CMP.B	#8,D3
		BLT.B	pt1
pt2		LEA	($40,SP),SP
		MOVE.L	D0,($60).W
		MOVEM.L	(SP)+,D0-D7/A0-A6
		RTS

_exit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2) 
		
_savedisk	dc.b	'Disk.2',0
_disknum	dc.b	1
_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
_fastboot	dc.l	0,0
