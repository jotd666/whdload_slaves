;*---------------------------------------------------------------------------
;  :Program.	SpeedballHD.asm
;  :Contents.	Slave for "Speedball" from
;  :Author.	JOTD
;  :History.	28.01.05
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
	OUTPUT	Speedball.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

SAVE_SIZE = $1740


;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError	;ws_flags
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
	DOSCMD	"WDate  >T:date"
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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	
_name		dc.b	"Speedball",0
_copy		dc.b	"1988-1990 Imageworks/Mirrorsoft",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION

	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION

		dc.b	0

		even

; version SPS86:
; W $B141 0.W  => match over (time out)
; $B112.B: computer/player 2 score

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	lea	$7FF00,a7

	move.l	_expmem(pc),$24.W
	move.l	_expmem(pc),$100.W

	; load & version check

	lea	$1000.W,A0
	move.l	#$0,D0		; offset
	move.l	#$4000,D1	; length
	bsr	diskload

	lea	$1000.W,A0
	move.l	#$4000,d0
	jsr	resload_CRC16(a2)

	cmp.l	#$17B7,d0
	beq.b	.rerelease
	cmp.l	#$A90F,d0
	beq.b	.version_v86
	cmp.l	#$9226,d0
	beq		.version_v581

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; ---------- re-release version

.rerelease
	; load executable file 'SB' from HD

	lea	sbname(pc),a0
	lea	$1000.W,a1
	move.l	#$A898,d0
	move.l	#$A4,d1
	sub.l	d1,d0
	move.l	_resload(pc),a2
	jsr	resload_LoadFileOffset(a2)

	; dbf delays -> beam delays

	move.l	#$51C8FFFE,D0
	move.l	#$4EB80080,D1
	lea	$B300,A0
	lea	$B600,A1
	bsr	hex_replace_long

	lea	pl_rerelease(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)

	jmp	$1096.W

START_ADDRESS = $80

.version_v86
	move.l	#$1740*8,D1
	move.l	#$A2C00,D0
	lea	$10000,A0
	bsr	diskload

	pea	START_ADDRESS
	patch	$100CC,patch_loader_v86
	bsr	_flushcache
	jmp	$10000

.version_v581
	move.l	#$1740*8,D1
	move.l	#$A2C00,D0
	lea	$10000,A0
	bsr	diskload

	pea	START_ADDRESS
	patch	$100CC,patch_loader_2
	bsr	_flushcache
	lea	$10000,a5
	jmp	(a5)

patch_loader_v86
	clr.w	$24.W
	move.l	#$51C8FFFE,D0
	move.l	#$4EB80080,D1
	lea	START_ADDRESS,A0
	lea	START_ADDRESS+$10000,A1
	bsr	hex_replace_long


	lea	pl_version_v86(pc),a0
	bra	patch_end
	

patch_loader_2
	clr.w	$24.W		; no expansion memory
	move.l	#$51C8FFFE,D0
	move.l	#$4EB80080,D1
	lea	START_ADDRESS,A0
	lea	START_ADDRESS+$10000,A1
	bsr	hex_replace_long

	lea	pl_version_v581(pc),a0
patch_end
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	move.w	#$4000,$DFF096
	move.w	#$7FFF,$DFF09A
	move.w	#$7FFF,$DFF09C
	move.l	#START_ADDRESS+$82,(a7)

	rts

pl_version_v86
	PL_START
	PL_P	$80,wait_d0
	PL_I	$70A

	; SMC
	PL_PS	$432,store_d7_43a
	PL_PS	$2448,store_d7_2450
	PL_W	$37D2,$4E71

	; load/save

	PL_PS	$98B0,load_game
	PL_PS	$AA5A,save_game
	PL_L	$AA60,$70004EF9
	PL_L	$AA64,$A6BA
	PL_W	$97E0,$6020

	; keyboard

	PL_PS	$6B6,kb_int_mfm

	; hd load

	PL_P	$A9CC,read_tracks_mfm
	PL_R	$A940
	PL_R	$A976
	PL_R	$A914
	PL_R	$A752

	PL_END

PATCH_RFV2:MACRO
	PL_PS	\1,wrap_read_file
	ENDM

pl_version_v581
	PL_START
	PL_P	$80,wait_d0
	PL_I	$70A

	; SMC (there are other SMC stuff, but they don't cause problems...)

	PL_PS	$432,store_d7_43a
	PL_PS	$2382,store_d7_238a
	PL_W	$3732,$4E71

	; load/save

	PL_PS	$975C,load_game
	PL_PS	$AAFE,save_game
	PL_L	$AAFE+6,$70004EF9
	PL_L	$AAFE+10,$A760
	PL_W	$968C,$6020

	; keyboard

	PL_PS	$6B6,kb_int_mfm

	; hd load

	PL_P	$AA70,read_tracks_mfm
	PL_R	$A9E4
	PL_R	$AA1A
	PL_R	$A9B8
	PL_R	$A7F6

	; disk protection, not present in other MFM version

	PL_R	$AC54		; track read and trash D7 (in stack) if error

;	PL_L	$ACB6,$70004E75	; not good enough, WHDLoad crash after a while!
	PL_NOP	$ACEE,4	; faster "sync" search (never found!)

	; disk protection, workaround to pretend protected track is here
	
	PATCH_RFV2	$001D4
	PATCH_RFV2	$00212
	PATCH_RFV2	$00256
	PATCH_RFV2	$00306
	PATCH_RFV2	$00388
	PATCH_RFV2	$003C4
	PATCH_RFV2	$00442
	PATCH_RFV2	$004D6
	PATCH_RFV2	$0054C
	PATCH_RFV2	$01CD4
	PATCH_RFV2	$01D18
	PATCH_RFV2	$01D3A
	PATCH_RFV2	$0236C
	PATCH_RFV2	$023BE
	PATCH_RFV2	$02506

	PL_END

; ------------------- re-release (DOS tracks) --------------------

pl_rerelease
	PL_START
	PL_L	$4,$80	; game does that

	PL_P	$B566,read_tracks_rerel
	PL_R	$B4F8
	PL_R	$B324
	PL_R	$B4D0


	PL_PS	$163E,kb_int_rerel

	PL_PS	$A27A,load_game

	PL_PS	$B5AE,save_game
	PL_L	$B5B4,$70004EF9
	PL_L	$B5B8,$B27C
	PL_R	$B31A

	; remove check save=load

	PL_W	$A1AA,$6020

	PL_P	$80,wait_d0

	; default intena/intreq value

	PL_L	$20,$40280040

	PL_END

wrap_read_file
	jsr	$A6B4
	movem.l	d1,-(a7)
	moveq	#0,d1
	movem.l	(a7)+,d1
	rts


kb_int_rerel
	move.l	$166C.W,A1
	cmp.b	_keyexit(pc),D0
	beq	quit
	rts

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

; < A0: destination buffer
; < D6.W: number of tracks to read
; < D7.W: start track

read_tracks_rerel
	movem.l	d1/d6-d7,-(a7)
	and.w	#$FFFF,D6
	and.w	#$FFFF,D7

	mulu	#$1600,D6
	mulu	#$1600,D7
	move.l	D6,D1	; length
	move.l	D7,D0	; offset

	bsr	diskload

	movem.l	(a7)+,d1/d6-d7
	moveq	#0,D0
	rts

; < A0: destination buffer
; < D6.W: number of tracks to read
; < D7.W: start track

; v1 disk map: 0-1: DOS, 2-159: MFM
; v2 disk map: 0-1: DOS, 2-73: MFM, 74-99: blank, 100-133: MFM, 134-159: blank
; there is some disk protection check performed in version 2, don't know on which track

read_tracks_mfm
	movem.l	d1/d6-d7,-(a7)
	and.w	#$FFFF,D6
	and.w	#$FFFF,D7

	subq.l	#2,d7

	mulu	#$1740,D6
	mulu	#$1740,D7
	move.l	D6,D1	; length
	move.l	D7,D0	; offset

	bsr	diskload

	movem.l	(a7)+,d1/d6-d7
	moveq	#0,D0
	rts

kb_int_mfm
	bset	#0,$E00(A0)
	move.l	D0,-(sp)
	not.b	D0
	ror.b	#1,D0
	cmp.b	_keyexit(pc),D0
	beq	quit
	move.l	(sp)+,d0
	rts

store_d7_43a:
	move.l	D7,$43A.W
	bra	_flushcache

store_d7_2450:
	move.l	D7,$2450.W
	bra	_flushcache

store_d7_238a:
	move.l	D7,$238A.W
	bra	_flushcache

load_game:
	cmp.b	#$98,D7
	beq	load_league
	cmp.b	#$96,D7
	beq	load_knockout
	cmp.b	#$97,D7
	beq	load_twoplay
	illegal

save_game:
	cmp.b	#$98,D7
	beq	save_league
	cmp.b	#$96,D7
	beq	save_knockout
	cmp.b	#$97,D7
	beq	save_twoplay
	illegal

DEF_LOADSAVE_GAME:MACRO
load_\1:
	movem.l	d0-d1/a0-a3,-(a7)
	move.l	A0,A3
	lea	\1name(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.pb
	lea	\1name(pc),A0
	move.l	A3,A1
	moveq	#0,D1
	move.l	#SAVE_SIZE,D0
	jsr	resload_LoadFileOffset(a2)
	moveq	#0,d0
	bra.b	.out
.pb
	moveq	#-1,d0
.out
	movem.l	(a7)+,d0-d1/a0-a3
	rts
save_\1:
	movem.l	d0-d1/a0-a2,-(a7)
	moveq	#0,D1
	move.l	#SAVE_SIZE,D0
	move.l	A0,A1
	lea	\1name(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_SaveFileOffset(a2)
	moveq	#0,d0
	movem.l	(a7)+,d0-d1/a0-a2
	rts
	ENDM

	DEF_LOADSAVE_GAME	league
	DEF_LOADSAVE_GAME	knockout
	DEF_LOADSAVE_GAME	twoplay



_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

;--------------------------------

_resload	dc.l	0		;address of resident loader

wait_d0:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

wait_d7:
	move.l	D0,-(sp)
	moveq	#0,d0
	move.w	D7,D0
	bsr	wait_d0
	move.l	(sp)+,D0
	rts

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



;< A0: start
;< A1: end
;< D0: longword to search for
;< D1: longword to replace by

hex_replace_long:
	movem.l	A0-A1/D0-D1,-(A7)
.srch
	cmp.l	(A0),D0
	beq.b	.found
.next
	addq.l	#2,A0
	cmp.l	A1,A0
	bcc.b	.exit
	bra.b	.srch
.found
	move.l	D1,(A0)+
	bra	.next
.exit
	movem.l	(A7)+,A0-A1/D0-D1
	rts

diskload
	movem.l	d0-d2/a0-a2,-(a7)
	moveq	#1,D2
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-d2/a0-a2
	rts

leaguename:
	dc.b	"league.sav",0
knockoutname:
	dc.b	"knockout.sav",0
twoplayname:
	dc.b	"twoplay.sav",0
sbname:
	dc.b	"SB",0

