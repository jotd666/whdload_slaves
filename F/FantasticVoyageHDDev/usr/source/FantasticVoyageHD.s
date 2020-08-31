;*---------------------------------------------------------------------------
;  :Program.	FantasticVoyageHD.asm
;  :Contents.	Slave for "Fantastic Voyage" from Ocean
;  :Author.	JOTD
;  :History.	
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	FantasticVoyage.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		IFD	USE_FASTMEM
		dc.l	$80000		;ws_BaseMemSize
		ELSE
		dc.l	$100000
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem	
	IFD	USE_FASTMEM	
	dc.l	$80000			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"Fantastic Voyage",0
_copy		dc.b	"1991 Centaur Software",0
_info		dc.b	"adapted & fixed by Abaddon & JOTD",10,10
		dc.b	"CUSTOM1=1 enables trainer",10,10
		dc.b	"Version "
		incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	dc.b	0


; version xx.slave works

	dc.b	"$","VER: slave "
		incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
		dc.b	$A,$D,0
	ENDC

		even

BASE_ADDRESS = $1000
DECRUNCH_LENGTH = $A0	; approx.

;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	a0,a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

	lea	$7FF00,a7
	lea	$DFF000,a6
	move.w	#$4000,intena(a6)
	move.w	#$7fff,dmacon(a6)
	move.w	#$7fff,intreq(a6)

	move.w	#-1,$84.W	; $100000 of chipmem

	;;  load track 2 in $60000
	LEA	$60000,A4		;0112: 49F900060000
	MOVEA.L	A4,A0			;0118: 204C
	MOVEQ	#2,D0			;011A: 7002 => track 2
	MOVEQ	#1,D1			;011C: 7201 => 1 track
	BSR.S	disk_routine		;0126: 611E
	LEA	$C0.W,A0		;0128: 41F800C0
	MOVEQ	#0,D0			;012C: 7000
	MOVE.B	18(A4),D0		;012E: 102C0012 => track 3
	MOVE.B	16(A4),D1		;0132: 122C0010 => 7 tracks
	BSR.S	disk_routine		;013E: 6106

	lea	$9B4C,a0
	lea	pp_decrunch(pc),a1
	move.l	#(DECRUNCH_LENGTH/4)-1,d0
.c
	move.l	(a0)+,(a1)+
	dbf	D0,.c

	move.l	_resload(pc),a2
	sub.l	a1,a1
	lea	pl_boot(pc),a0
	move.l	_custom1(pc),d0
	beq.b	.p
	lea	pl_train(pc),a0
.p
	jsr	resload_Patch(a2)

	MOVEA.L	$C0.W,A0		;0140: 207800C0
	JMP	$106.W			;0144: 4ED0

pp_decrunch
	blk.b	DECRUNCH_LENGTH
	even

jump_a000
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_a000(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$a000

jump_29800
	movem.l	d0-d1/a0-a2,-(a7)
	lea	pl_29800(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$29800

load_highscore
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	a0,a1
	clr.l	(a1)+
	clr.l	(a1)+
	lea	hiscore_name(pc),a0	
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts

save_highscore
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_custom1(pc),d0	; not saved because cheat is on
	bne.b	.skip
	lea	8(a0),a1
	lea	hiscore_name(pc),a0
	move.l	#186,d0
	move.l	_resload(pc),a2
	jsr	resload_SaveFile(a2)
.skip
	movem.l	(a7)+,d0-d1/a0-a2
	rts

pl_train
	PL_START
	PL_W	$DF4,$6024
	PL_NEXT	pl_boot
pl_boot
	PL_START
	
	; adapted from Abaddon patches

	PL_PS	$6c5a,kbint
	PL_PS	$6c80,kbint
	PL_P	$757C,disk_routine
	PL_P	$71d8,disk_routine_2
	PL_R	$7CC4
	PL_PS	$6DB0,disk_change
	PL_PS	$6EB8,disk_change
	PL_L	$1A0,$4E714E71	; drive access

	; blitter

	PL_L	$04a8,$4EB800A6
	PL_L	$042e,$4EB800A6
	PL_L	$4ffc,$4EB800A6
	PL_L	$4fa6,$4EB800A6
	PL_L	$4f58,$4EB800A6
	PL_L	$4e32,$4EB800A6
	PL_L	$4db8,$4EB800A6
	PL_L	$4cb8,$4EB800A6
	PL_L	$4c42,$4EB800A6
	PL_L	$4b4e,$4EB800A6
	PL_L	$4a42,$4EB800A6

	PL_L	$5D22,$4EB800AC
	PL_L	$6002,$4EB800AC
	PL_PS	$9FE,blit6

	PL_P	$AC,blit3
	PL_P	$A6,blit5

	; JOTD fixes

	PL_PS	$6FEC,jump_a000	; menu
	PL_P	$6F98,jump_a000

	PL_P	$9B4C,pp_decrunch	; fast decrunch

	PL_P	$7080,jump_29800

	PL_END



; JOTD

pl_a000
	PL_START

	; blitter & snoop shit

	PL_PS	$B1C6,blit1

	; PAL/NTSC switch disable

	PL_R	$A8C0

	; hiscore

	PL_P	$C8D6,load_highscore
	PL_P	$C8F0,save_highscore

	PL_END

pl_29800
	PL_START
	PL_PS	$29E30,blit1
	PL_PS	$2b074,blit2
	PL_PS	$2ad04,blit4
	PL_PS	$2ad5e,blit7
	PL_W	$2ad5e+6,$4E71
	PL_PS	$2ad9c,blit1
	PL_END


blit1
	bsr	wt
	move.w	#0,($5AC2,a6)
	rts

blit2
	bsr	wt
	move.w	d0,($5ac0,a6)                  ;$00dff044
	moveq	#$4c,d0
	rts

blit3:
	move.w	d1,$5ad4(a6)
	bra		wt

blit4
	bsr	wt
	move.w	#$ffff,($5ac2,a6)              ;$00dff046
	rts

blit5:
	move.w	d4,$5ad4(a6)
	bra	wt

blit6:
	move.w	#$209,$5ad4(a6)
	bra	wt

blit7
	bsr	wt
	move.l	a2,($5acc,a6)                  ;$00dff050
	move.l	a3,($5ad0,a6)
	rts
wt
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
;	TST.B	$BFE001
;	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
;	TST.B	dmaconr+$DFF000
.end
	rts

disk_routine_2
	movem.l	d0-d2/a0-a2,-(a7)
	movea.l	$fa.W,a0
	moveq	#$0,d0
	moveq	#$0,d1
	move.b	$fe.W,d0
	move.b	$ff.W,d1
	add.b	d1,$fe.W
	clr.b	$ff.W
	bsr	disk_routine
	mulu	#$200,d1
	add.l	d1,$fa.W
	movem.l	(a7)+,d0-d2/a0-a2
	jmp	$7494.W

kbint
	move.b	$bfec01,d0
	movem.l	d0,-(a7)
	ror.b	#$1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq.b	quit
	movem.l	(a7)+,d0
	rts

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; < A0 destination
; < D0 track number
; < D1 number of tracks
; < D4 number of bytes to copy (always $1800, ignored)

disk_routine
	movem.l	d0-d2/a0-a2,-(A7)

	move.l	current_disk(pc),d2	; disk number
	addq	#1,d2

	subq	#2,d0	; tracks 0 & 1 are DOS and unused

	; D0: offset (*$1800)
	mulu	#24,d0
	lsl.l	#8,d0
	; D1: size
	mulu	#24,d1
	lsl.l	#8,d1
	
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
.readnothing
	movem.l	(a7)+,d0-d2/a0-a2
	rts

current_disk
	dc.l	0

disk_change
	movem.l	a0,-(a7)
	lea	current_disk(pc),a0
	eori.l	#$1,(a0)
	move.w	#$ffff,d0		;makes fantasic voyage think the disk was changed
	movem.l	(a7)+,a0
	rts

get_extmem
	lea	_expmem(pc),a0
	IFD	USE_FASTMEM
	add.l	#$10,(a0)	; workaround decrunch bug for pre-16.4 WHDload
	ELSE
	move.l	#$80000,(a0)
	ENDC
	move.l	(A0),A0
	rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

hiscore_name
	dc.b	"highs",0
	even

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;--------------------------------

_resload	dc.l	0		;address of resident loader

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

