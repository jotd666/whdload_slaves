;*---------------------------------------------------------------------------
;  :Program.	BlastarHD.asm
;  :Contents.	Slave for "Blastar" from Ocean
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	28.01.99
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	exec/io.i

	IFD BARFLY
	OUTPUT	GreatCourts.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem	
		dc.l	0
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
		
DECL_VERSION:MACRO
	dc.b	"2.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


_name		dc.b	"Great Courts / Pro Tennis Tour",0
_copy		dc.b	"1993 Ubi Soft",0
_info		dc.b	"adapted & fixed by JOTD & CFou!",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

; version xx.slave works


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

;======================================================================
start	;	A0 = resident loader
;======================================================================

	; install dummy kb int (issue #0003802)
	pea	dummy_kbint(pc)
	move.l	(A7)+,$68.W
	
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use


	lea	$7FF00,a7
	lea     $6520.W,A0
	moveq.l #0,D0		; offset: start of disk
	move.l  #$D24A,D1	; size
	moveq.l #1,D2
	bsr	_loaddisk

	; load & version check

	move.l	#$D200,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)

	lea	version(pc),a0

	cmp.l	#$a29e,d0
	beq	v1
	cmp.l	#$951c,d0
	beq	v2
	cmp.l	#$3233,d0	; pro tennis tour, works for both PTT versions
	beq	v1080_ptt	; or v4
	cmp.l	#$16BA,d0
	beq	v2605

	; unknown version

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; dummy keyboard interrupt to catch a possible level 2 interrupt
; occurring at game startup BEFORE game level 2 interrupt handler is installed

dummy_kbint
	movem.l	D0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey

	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a5
	move.w	#8,$dff09c
	rte

	
v1
	move.l	#1,(a0)
	lea	pl_v1(pc),a0
	bra cont

v2:
	move.l	#2,(a0)
	lea	pl_v2(pc),a0
	bra cont

v1080_ptt:
	move.l	#3,(a0)
	lea	pl_v1080_ptt(pc),a0
	bra cont

v2605
	move.l	#5,(a0)
	lea	pl_v2605(pc),a0
	bra cont

cont
	patch	$100,empty_d7_loop

	sub.l	a1,a1
	jsr	resload_Patch(a2)

	move.l	version(pc),d0
	cmp.l	#1,d0
	bne.b	.no1
	lea	save_offset(pc),a2
	move.l	#$D2970,(a2)	; change load player data offset
.no1
	cmp.l	#3,d0
	beq.b	.j3
	cmp.l	#5,d0
	beq.b	.j3
    jmp     $652E.W         ; skip vector overwrite & random value read ??
.j3
	jmp	$6534.W		; pro-tennis tour and great courts v2605

save_offset:
	dc.l	$D4100		; for all except v1 (first one I patched)
version:
	dc.l	0

; Pro Tennis Tour
pl_v1080_ptt
	PL_START
	PL_W	$13480,$4E71
	PL_W	$134D4,$4E71
	PL_R	$133BE
	PL_R	$130AC
	PL_R	$130D4
	PL_R	$130FC
	PL_R	$1313C
	PL_P	$135C8,save_game
	PL_P	$13530,read_disk

	; keyboard protection (quit key & fix)

	PL_PS	$B6DA,kb_int_ptt
	PL_P	$B706,end_kb_int
	PL_S	$B6BC,$10
	PL_R	$B748
	PL_W	$9E02,$C018
	PL_W	$9EC6,$C018

        ; patch keyword protection

	PL_W	$7F66,$42B9
	PL_S	$7F4A,$1C


	; empty dbf fix

	PL_PS	$12CD4,fix_cpu_wait
	PL_W	$12CDA,$4E71

	PL_L	$A794,$4E714E71		; useless DBF loop because before dma write
	PL_L	$AE2E,$4EB80100		; classical delay loop, not sound related
;;	PL_L	$B754,$4EB80100		; unused, keyboard fixed some other way
	PL_L	$12E22,$4EB80100	; music


	PL_P	$A70C,enable_dma_audio_2	; during game
	PL_PS	$A762,enable_dma_audio_1	; intro sound

	PL_END

pl_v1
	PL_START
	PL_W	$1344C,$4E71
	PL_W	$134A0,$4E71
	PL_R	$13388
	PL_R	$13070
	PL_R	$130C0
	PL_R	$13100
	PL_P	$13598,save_game
	PL_NEXT	pl_boot_gc

pl_v2
	PL_START
	PL_W	$1344C+$2C,$4E71
	PL_W	$134A0+$2C,$4E71
	PL_R	$13388+$2C
	PL_R	$13070+$2C
	PL_R	$130C0+$2C
	PL_R	$13100+$2C
	PL_P	$13598+$2C,save_game
	PL_NEXT	pl_boot_gc

; new version, great courts

pl_v2605
	PL_START
	PL_W	$1344C+$30,$4E71
	PL_W	$134A0+$30,$4E71
	PL_R	$133BA
	PL_R	$130A8
	PL_R	$130F8
	PL_R	$13138
	PL_P	$135C4,save_game

	PL_P	$1352C,read_disk

	; keyboard protection (quit key & fix)

	PL_PS	$B6D4+6,kb_int_ptt
	PL_P	$B700+6,end_kb_int
	PL_S	$B6B6+6,$10
	PL_R	$B742+6
	PL_W	$9DFC+6,$C018
	PL_W	$9EC0+6,$C018

        ; patch keyword protection

	PL_W	$7F60+6,$42B9
	PL_S	$7F44+6,$1C

	; empty dbf fix

	PL_PS	$12CD0,fix_cpu_wait
	PL_W	$12CD6,$4E71

	PL_L	$A794,$4E714E71		; useless DBF loop because before dma write
	PL_L	$AE2E,$4EB80100		; classical delay loop, not sound related
;;	PL_L	$B754,$4EB80100		; unused, keyboard fixed some other way
	PL_L	$12E1E,$4EB80100	; music


	PL_P	$A70C,enable_dma_audio_2	; during game
	PL_PS	$A762,enable_dma_audio_1	; intro sound

	PL_END

enable_dma_audio_1
	move.w	#$8003,($96,a5)
	; wait a little while or sound is trashed
	move.l	#$12C,d7
	bsr	empty_d7_loop
	rts

enable_dma_audio_2
	move.w	d3,($96,a5)
	; wait a little while or sound is trashed
	move.l	#$12C,d7
	bsr	empty_d7_loop
	rts

pl_boot_gc
	PL_START
	PL_P	$134FE,read_disk

	; keyboard protection (quit key & fix)

	PL_PS	$B6D4,kb_int
	PL_P	$B700,end_kb_int
	PL_S	$B6B6,$10
	PL_R	$B742
	PL_W	$9DFC,$C018
	PL_W	$9EC0,$C018

        ; patch keyword protection

	PL_W	$7F60,$42B9
	PL_S	$7F44,$1C

	; empty dbf fix

	PL_PS	$12C9E,fix_cpu_wait
	PL_W	$12C9E+6,$4E71

	PL_L	$A87E,$4E714E71		; useless DBF loop because before dma write
	PL_L	$AE28,$4EB80100		; classical delay loop, not sound related
	PL_L	$12DEC,$4EB80100	; music


	PL_P	$A706,enable_dma_audio_2	; during game
	PL_PS	$A75C,enable_dma_audio_1	; intro sound

	PL_END


end_kb_int:
        move.w  #$8,$DFF09C
        RTE

kb_int
	move.b  D0,$B710	; original
	bra	kb_common

kb_int_ptt
	move.b  D0,$B716	; original
	bra	kb_common

empty_d7_loop
	move.l	D0,-(a7)
	move.l	d7,d0
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.l	(a7)+,d0
	move.w	#$FFFF,d7
	rts

kb_common
	cmp.b	_keyexit(pc),D0

	bne	.noquit

	; quit

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	movem.l	d0,-(a7)
	bset	#6,$bfee01
	moveq	#2,d0
	bsr	beamdelay	; handshake: 75 us minimum
	bclr	#6,$bfee01
	movem.l	(a7)+,d0
        rts

fix_cpu_wait
	movem.l	d0,-(a7)
	moveq	#2,d0
	bsr	beamdelay
	movem.l	(a7)+,d0
	rts



save_game:
	movem.l	D0-A6,-(a7)
	move.l	a0,a1
	lea	highs_filename(pc),A0
	move.l	#$700,d0	; size
	move.l	(_resload,pc),a2
	jsr	(resload_SaveFile,a2)
	movem.l	(a7)+,D0-A6
	moveq	#0,D0
	rts

highs_filename
	dc.b	"gamesave",0
	even

; < A0: out buffer (matches DiskLoad call)
; < D0: start track
; < D1: length to read in bytes (matches DiskLoad call)

read_disk:
;	cmp.b	#$FE,d0
;	beq.b	.out
;	cmp.b	#$FC,d0
;	beq.b	.out

	movem.l	d1-d2/a0-a2,-(a7)
	and.l	#$ff,d0

	cmp.w	#$50,D0
	bcs.b	.side1
	subq.l	#2,D0
	subq.l	#7,D0
.side1
	subq.l  #1,D0

	mulu	#$1790,D0

	cmp.l	save_offset(pc),d0
	bne.b	.no_highs

	movem.l	d0-d1/a0-a1,-(a7)
	lea	highs_filename(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	movem.l	(a7)+,d0-d1/a0-a1
	beq.b	.no_highs	; file not found: read from disk image

	; load from highs file

	move.l	a0,a1
	lea	highs_filename(pc),A0
	move.l	(_resload,pc),a2
	jsr	(resload_LoadFile,a2)

	bra.b	.restore_out
.no_highs
	moveq.l	#1,D2		; only 1 disk
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)
.restore_out
	movem.l	(a7)+,d1-d2/a0-a2
.out
        move.l	version(pc),d0
	cmp.l	#2,d0
	beq.b	.skip
	movem.l (a7)+,d4-d7/a5          ; version 1 & PTT need this
.skip
        moveq.l #0,D0
        rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts


; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_loaddisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts



;--------------------------------

_resload	dc.l	0		;address of resident loader

