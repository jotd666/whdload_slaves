;*---------------------------------------------------------------------------
;  :Program.	obliterator.asm
;  :Contents.	Slave for "Obliterator"
;  :Author.	Morbidus, Wepl
;  :Version.	$Id: obliterator.asm 1.4 2014/07/17 00:06:06 wepl Exp wepl $
;  :History.	??.??.?? initial
;		28.08.01 reworked and fixed by Wepl
;		15.07.14 keyboard wait fixed, issue #3031
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:o/obliterator/Obliterator.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

_resload	= $110

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$1000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
    
DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
    
    
_name		dc.b	"Obliterator",0
_copy		dc.b	"1988 Psygnosis",0
_info		dc.b	"installed and fixed by Morbidus/Wepl/JOTD",10
		dc.b	"Version "
        DECL_VERSION
		dc.b	0
SAVE.MSG	dc.b	'SAVE/'
lbL000339	ds.b	6

	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0

	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		move.l	a0,(_resload)
		move.l	a0,a2

	;	clr.w	_custom+bplpt+22	;avoid snoop on bpl6pt

	move.l	#$1600,d0
	move.l	#$1600,d1
	moveq	#1,d2
	lea	($62000).l,a0
	move.l	a0,a3
	jsr	(resload_DiskLoad,a2)
	
	lea	(_pl1,pc),a0
	move.l	a3,a1
	jsr	(resload_Patch,a2)

	move.b	#1,($100).l

	lea	$763c0,a0
	move.w	#320*200*5/8/4-1,d0
.clr	clr.l	(a0)+			;clear screen
	dbf	d0,.clr

	jmp	(a3)

_pl1	PL_START
	PL_P	$23e,_load
	PL_R	$1d8
	PL_R	$1ca
	PL_P	$214,lbC000310
	PL_P	$328,lbC0002FE
	PL_P	$70,lbC0000D8
	PL_R	$34e
	PL_W	$86,$5200		;bplcon0
	PL_END

lbC0000D8
	movem.l	d0-d1/a0-a2,-(a7)
	lea	(_pl2,pc),a0
	sub.l	a1,a1
	movea.l	(_resload),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	move.l	(_expmem,pc),a4
	add.w	#$1000-8,a4
	move.l	a4,$1042		;ssp
	movea.l	#$8000,sp
	lea	(8,a7),a4
	jmp	(a7)        ; $8000

_pl2	PL_START
	PL_S	$1000,$40		;init, cacr
	PL_W	$382c,$33fc		;ori dmacon
	PL_R	$4de6			;motor?
	PL_P	$4f78,_load
	PL_P	$4e8c,lbC000310
	PL_P	$4ebc,lbC000322
	PL_P	$4eee,lbC0002FE
	PL_R	$4f58
	PL_P	$4e3c,_setside1
	PL_P	$4db4,lbC0002EE
	PL_P	$4e64,_setside2
	PL_P	$5096,_save
	PL_R	$1488
	PL_P	$824a,_b1
	PL_PS	$36d4,_keyb
	PL_PS	$372a,_keybw
	;PL_PS	$2b0e,_dmafix
	PL_PS	$2bba,_dmafix
	PL_P	$4c8e,_b2
    ; access fault $80000
    PL_PSS  $03d30,_avoid_af_80000,2
	PL_END

_avoid_af_80000:
    cmp.l   #$7FFFE,a1
    beq.b   .skip
	AND.L	D5,(A1)
	OR.L	D4,(A1)
.out
	ADDA.L	$4a4.W,A1
    rts
    ; special case for $7FFFE to avoid overwriting $80000.W
.skip
    swap    d5
    and.w   d5,(a1)
    swap    d5
    swap    d4
    or.w    d4,(a1)
    swap    d4
    bra.b   .out
    
_dmafix	waitvb
	;tst.w	_custom+copjmp1
	move.w	#DMAF_SETCLR|DMAF_MASTER,$dff096
	rts

_b2	move.l	a6,d5
	lea	_custom,a6
	BLITWAIT a6
	clr.w	($64,a6)
	move.w	d4,($66,a6)
	move.l	#-1,($44,a6)
	move.l	#$9f00000,($40,a6)
	move.w	#DMAF_MASTER|DMAF_SETCLR|DMAF_BLITHOG|DMAF_BLITTER,(dmacon,a6)
.lp	add.l	$454,d1
	add.l	$41c,d0
	BLITWAIT a6
	move.l	d1,($50,a6)
	move.l	d1,($4c,a6)
	move.l	d1,($48,a6)
	move.l	d0,($54,a6)
	move.w	d3,($58,a6)
	dbf	d2,.lp
	move.l	d5,a6
	movem.l	(a7)+,d0-d5
	rts

_b1	move.l	a6,d3
	lea	_custom,a6
	BLITWAIT a6
	move.w	#DMAF_MASTER|DMAF_SETCLR|DMAF_BLITHOG|DMAF_BLITTER,(dmacon,a6)
	movem.w	d0-d1,($64,a6)
	move.l	#-1,($44,a6)
	move.l	#$9f00000,($40,a6)
	move.l	#$1f40,d0
	moveq	#4,d1
.lp	BLITWAIT a6
	movem.l	a0-a1,($50,a6)
	move.w	d2,($58,a6)
	add.l	d0,a0
	add.l	d0,a1
	dbf	d1,.lp
	move.l	d3,a6
	movem.l	(a7)+,d0-d3/a0-a1
	rts

lbC0001A0
	move.w	#$4E75,($1488).l
	rts

_load	movem.l	d0-d7/a0-a6,-(sp)

	cmp.b	#2,($100)		;disk #2
	bne	.load
	cmp.l	#$5D800,($104)		;savegame start offset
	bhs	_loadgame
.load
	move.l	#$1600,d1
	move.l	($104).l,d0
	move.b	($100).l,d2
	movea.l	(_resload),a2
	jsr	(resload_DiskLoad,a2)
lbC0001E0
	movem.l	(sp)+,d0-d7/a0-a6
	cmpa.l	#$400,a0
	beq.w	lbC0001A0
	adda.l	#$1600,a0
	rts

_mknam	lea	(lbL000339+5,pc),a5
	moveq	#4,d5
	clr.l	d4
	move.l	($104).l,d3
.l	move.b	d3,d4
	andi.b	#15,d4
	addi.b	#$41,d4
	move.b	d4,-(a5)
	ror.l	#4,d3
	dbra	d5,.l
	rts

_save	movem.l	d0-d7/a0-a6,-(sp)
	bsr	_mknam
	move.l	#$1600,d0
	lea	(a0),a1
	lea	(SAVE.MSG,pc),a0
	movea.l	(_resload),a2
	jsr	(resload_SaveFile,a2)
	movem.l	(sp)+,d0-d7/a0-a6
	adda.l	#$1600,a0
	rts

_loadgame
	bsr	_mknam
	movem.l	a0-a5,-(sp)
	lea	(a0),a1
	lea	(SAVE.MSG,pc),a0
	movea.l	(_resload),a2
	jsr	(resload_GetFileSize,a2)
	movem.l	(sp)+,a0-a5
	tst.l	d0
	bne	.load
	move.w	#$1600/4-1,d0
.clr	clr.l	(a0)+
	dbf	d0,.clr
	suba.l	#$1600,a0
	bra	lbC0001E0

.load	lea	(a0),a1
	lea	(SAVE.MSG,pc),a0
	movea.l	(_resload),a2
	jsr	(resload_LoadFile,a2)
	bra	lbC0001E0

_setside1	move.b	#1,($100).l
	rts

_setside2	move.b	#2,($100).l
	rts

lbC0002EE	bsr.w	_setside1
	bsr.w	lbC0002FE
	clr.w	($506).l
	rts

lbC0002FE	move.l	#0,($104).l
	clr.w	($506).l
	rts

lbC000310	addq.w	#1,($506).l
	addi.l	#$1600,($104).l
	rts

lbC000322	subq.w	#1,($506).l
	subi.l	#$1600,($104).l
	rts

_keyb	ror.b	#1,d0		;original
	not.b	d0		;original

    cmp.b   _keyexit(pc),d0
    bne.b   .noquit
	pea	TDREASON_OK
	move.l	(_resload),a2
	jmp	(resload_Abort,a2)
    
.noquit
	cmpi.b	#$57,d0		;F8 trainer
	bne.w	.2
	move.w	#$FFF,($DFF180).l
	move.b	#$58,($60D4F).l
	move.b	#$99,($60D73).l
	move.b	#$99,($60D7D).l
	move.b	#$99,($60D87).l
	move.b	#9,($60D91).l
	move.b	#$99,($60D69).l
	move.b	#$99,($60D6A).l
.2	rts

_keybw	
	;better would be to use the cia-timer to wait, but we don't know if
	;they are otherwise used, so using the rasterbeam
	;required minimum waiting is 75 탎, one rasterline is 63.5 탎
	;a loop of 3 results in min=127탎 max=190.5탎
		moveq	#3-1,d1
.wait1		move.b	(vhposr+_custom),d0
.wait2		cmp.b	(vhposr+_custom),d0
		beq	.wait2
		dbf	d1,.wait1
		rts

	end
