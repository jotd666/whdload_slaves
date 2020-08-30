;*---------------------------------------------------------------------------
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


	IFD BARFLY
	OUTPUT	LaserSquad.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

SAVESCREEN = $70000

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem
		dc.l	$0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	0	;_config-_base		;ws_config

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.4"
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
	
_name		dc.b	"Laser Squad",0
_copy		dc.b	"1989 Teque",0
_info		dc.b	"fixed by Abaddon & JOTD",10,10
		dc.b	"Thanks to Wepl for savegame system",10,10
		dc.b	"Version "
		DECL_VERSION
	dc.b	0
		even

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	lea	$7FF00,a7

	lea	$400.W,a0
	move.l	#$2C00,d0
	move.l	#$2C00,d1
	bsr	load_disk
	nop
	cmpi.l	#$41f90000,$2258.W
	beq.b	.v1
	cmp.l	#$4E4241F9,$2258.W
	beq.b	.v2

	bra	wrong_version

; v1 or v3 or italian version
.v1
	patch	$225E,patch_main_v1
	bra	.cont
.v2
	patch	$2264,patch_main_v2
.cont

	lea	$0.W,a1
	lea	pl_boot(pc),a0
	bsr	patch_it

	lea	$400.W,a6
	jmp	(a6)


wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; protection (lame)

disk_stuff
	move.l	#$55465459,d1
	move.l	#$0,d0
	rts

patch_trap
	bsr	correct_trap
	jmp	$A9E.W

; from original JOTD floppy patch
; avoids stackframe errors

correct_trap:
	move.l	$BC.W,-(sp)
	move.l	$204.W,$BC.W
	trap	#$F
	move.l	(sp)+,$BC.W
	rts

patch_trap_2
	bsr	correct_trap
	add.l	#6,(a7)
	rts

; UK blade V1 or microillusions V3 or italian

patch_main_v1
	jsr	$238e
	jsr	$2428

	lea	$25c4,a6
	bsr	get_main_crc
	cmp.w	#$5F62,d0
	beq.b	.ukblade
	cmp.w	#$BEDE,d0
	beq.b	.micro3
	cmp.w	#$BB19,d0
	beq.b	.italian
	bra	wrong_version
.ukblade	; "vmi" dir
	lea	pl_blit_v1(pc),a0
	bra.b	.patch
.micro3
	lea	pl_blit_v3(pc),a0
	bra.b	.patch
.italian
	lea	pl_blit_vita(pc),a0
.patch
	sub.l	a1,a1
	bsr	patch_it

	bsr	_flushcache

	jmp	(a6)

; microillusions V2

patch_main_v2
	jsr	$242a.W

	lea	$25c6.W,a6
	bsr	get_main_crc
	cmp.w	#$4B8B,d0
	bne	wrong_version

	lea	pl_blit_v2(pc),a0
	sub.l	a1,a1
	bsr	patch_it

	jmp	(a6)


; < A6: buffer
; > D0: crc

get_main_crc
	movem.l	d1/a0-a2,-(a7)
	move.l	a6,a0
	move.l	#$1000,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	movem.l	(a7)+,d1/a0-a2
	rts

PL_PSNOP:MACRO
	PL_PS	\1,\2
	PL_W	\1+6,$4E71
	ENDM
pl_blit_vita
	PL_START
	PL_PS		$03310,patch_kb
	PL_PS		$032f6,patch_trap_2

	PL_PSNOP	$02C20,blit_stuff_3
	PL_PS		$03d9c,blit_stuff_2

	PL_PSNOP	$0b612,blit_stuff_1
	PL_PSNOP	$0b624,blit_stuff_1
	PL_PSNOP	$0b636,blit_stuff_1
	PL_PSNOP	$0b648,blit_stuff_1

	; succession of oversized blits
	; resolved by increasing chipmemsize
	; (so now the hidden movement screen displayed OK)

	PL_PSNOP	$0cefc,blit_stuff_4
	PL_PSNOP	$0cf08,blit_stuff_4
	PL_PSNOP	$0cf14,blit_stuff_4
	PL_PSNOP	$0cf20,blit_stuff_4

	; other blitstuff Keith had forgotten

	PL_PS		$0ced8,load_a6_wait
	PL_PS		$03d52,blit_stuff_5
	PL_PS		$02be0,load_a2_wait
	PL_PS		$0b59c,load_a5_wait

	; number of players, difficulty level blits

	PL_PSNOP	$06eaa,blit_stuff_6
	PL_PSNOP	$06eb6,blit_stuff_6
	PL_PSNOP	$06ec2,blit_stuff_6
	PL_PSNOP	$06ece,blit_stuff_6

	; load/save

	PL_PS		$05c80,load_game_position
	PL_PS		$09482,save_game_position
	PL_W		$09482+22,$7000

	PL_S		$05c5e,$16	; $6014
	PL_S		$09466,$10	; $600E

	PL_END


pl_blit_v3
	PL_START
	PL_PS		$3310,patch_kb
	PL_PS		$32f6,patch_trap_2

	PL_PSNOP	$2C20,blit_stuff_3
	PL_PS		$3D9C,blit_stuff_2

	PL_PSNOP	$B62E,blit_stuff_1
	PL_PSNOP	$B640,blit_stuff_1
	PL_PSNOP	$B652,blit_stuff_1
	PL_PSNOP	$B664,blit_stuff_1

	; succession of oversized blits
	; resolved by increasing chipmemsize
	; (so now the hidden movement screen displayed OK)

	PL_PSNOP	$CF18,blit_stuff_4
	PL_PSNOP	$CF24,blit_stuff_4
	PL_PSNOP	$CF30,blit_stuff_4
	PL_PSNOP	$CF3C,blit_stuff_4

	; other blitstuff Keith had forgotten

	PL_PS		$CEF4,load_a6_wait
	PL_PS		$3D52,blit_stuff_5
	PL_PS		$2BDA,load_a2_wait
	PL_PS		$B5B8,load_a5_wait

	; number of players, difficulty level blits

	PL_PSNOP	$6EAA,blit_stuff_6
	PL_PSNOP	$6EB6,blit_stuff_6
	PL_PSNOP	$6EC2,blit_stuff_6
	PL_PSNOP	$6ECE,blit_stuff_6

	; load/save

	PL_PS		$5C80,load_game_position
	PL_PS		$9482,save_game_position
	PL_W		$9482+22,$7000

	PL_S		$5C5E,$16	; $6014
	PL_S		$9482-$1C,$10	; $600E


	PL_END


pl_blit_v1
	PL_START

	PL_PS		$03310,patch_kb
	PL_PS		$32f6,patch_trap_2	; pea xx + move sr,-(a7)

	PL_PSNOP	$2C20,blit_stuff_3	; move.l	a0,($50,a2)
	PL_PS		$3DCE,blit_stuff_2

	PL_PSNOP	$B78E,blit_stuff_1
	PL_PSNOP	$B7A0,blit_stuff_1
	PL_PSNOP	$B7B2,blit_stuff_1
	PL_PSNOP	$B7C4,blit_stuff_1

	; succession of oversized blits
	; resolved by increasing chipmemsize
	; (so now the hidden movement screen displayed OK)

	PL_PSNOP	$D07E,blit_stuff_4
	PL_PSNOP	$D08A,blit_stuff_4
	PL_PSNOP	$D096,blit_stuff_4
	PL_PSNOP	$D0A2,blit_stuff_4

	; other blitstuff Keith had forgotten

	PL_PS		$D05A,load_a6_wait
	PL_PS		$3D84,blit_stuff_5
	PL_PS		$2BDA,load_a2_wait
	PL_PS		$B718,load_a5_wait

	; number of players, difficulty level blits

	PL_PSNOP	$6EFC,blit_stuff_6
	PL_PSNOP	$6F08,blit_stuff_6
	PL_PSNOP	$6F14,blit_stuff_6
	PL_PSNOP	$6F14+$C,blit_stuff_6

	; load/save

	PL_PS		$5CBE,load_game_position
	PL_PS		$95CC,save_game_position
	PL_W		$95CC+22,$7000

	PL_S		$5C9C,$16	; $6014
	PL_S		$95B0,$10	; $600E
	PL_END

pl_blit_v2
	PL_START

	PL_PS		$35b0,patch_trap_2
	PL_PS		$35CA,patch_kb
	
	PL_PSNOP	$B8BC,blit_stuff_1
	PL_PSNOP	$B8CE,blit_stuff_1
	PL_PSNOP	$B8E0,blit_stuff_1
	PL_PSNOP	$B8F2,blit_stuff_1

	PL_PS		$4056,blit_stuff_2
	PL_PSNOP	$2C22,blit_stuff_3

	; succession of oversized blits
	; resolved by increasing chipmemsize
	; (so now the hidden movement screen displayed OK)

	PL_PSNOP	$D268,blit_stuff_4
	PL_PSNOP	$D274,blit_stuff_4
	PL_PSNOP	$D280,blit_stuff_4
	PL_PSNOP	$D28C,blit_stuff_4

	; other blitstuff Keith had forgotten

	PL_PS		$D244,load_a6_wait
	PL_PS		$400C,blit_stuff_5
	PL_PS		$2BDC,load_a2_wait
	PL_PS		$B846,load_a5_wait

	; number of players, difficulty level blits

	PL_PSNOP	$716A,blit_stuff_6
	PL_PSNOP	$7176,blit_stuff_6
	PL_PSNOP	$7182,blit_stuff_6
	PL_PSNOP	$718E,blit_stuff_6

	; load/save

	PL_PS		$5F2E,load_game_position
	PL_PS		$9706,save_game_position
	PL_W		$971C,$7000

	PL_S		$5F0C,$16	; $6014
	PL_S		$96EA,$10	; $600E
	PL_END

pl_boot
	PL_START
	PL_R	$F5C		; CIA stuff

	PL_P	$BF4,load_tracks
	PL_PS	$AAC,patch_kb
	PL_P	$A92,patch_trap
	PL_P	$1232,disk_stuff
	PL_R	$11D4
	
	PL_PS	$1C98,audio_bytewrite
	PL_END

patch_kb
	ori.b	#$40,($E00,A1)
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	add.l	#4,(A7)
	rts
	
audio_bytewrite
	move.w	D0,-(a7)
	moveq	#0,d0
	move.b	(3,a6),d0
	move.w	d0,(8,a5)
	move.w	(a7)+,d0
	rts

load_a5_wait
	lea	$dff000,a5
	bsr	waitblit
	rts
load_a6_wait
	lea	$dff000,a6
	bsr	waitblit
	rts
load_a2_wait
	lea	$dff000,a2
	bsr	waitblit
	rts


blit_stuff_1:
	bsr	waitblit
	move.l	a1,$50(a5)
	move.l	a6,$54(a5)
	rts
blit_stuff_2:
	addq.w	#$2,d3
	bsr	waitblit
	move.w	d3,$58(a5)
	rts
blit_stuff_3:
	bsr	waitblit
	move.l	a0,$50(a2)
	move.l	a1,$54(a2)
	rts
;blit_too_long
;	move.w	#$0A0D,d1	; bltsize too big for source 2C0->0A0
blit_stuff_4
	bsr	waitblit
	move.l	A0,($54,a6)
	move.w	D1,($58,A6)
	rts

blit_stuff_5
	bsr	waitblit
	move.w	D2,($62,A5)
	sub.w	d3,d2
	rts

blit_stuff_6
	bsr	waitblit
	move.l	A0,($54,a6)
	move.w	D0,($58,A6)
	rts

waitblit
.wait
	tst.b	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.B	.wait
	rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

_exit
	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

;--------------------------------

_resload	dc.l	0		;address of resident loader


load_game_position
	movem.l	d1-a6,-(a7)
	bsr	get_save_params
	bsr	_sg_load
	bsr	restore_display
	movem.l	(a7)+,d1-a6
	not.l	d0
	rts

save_game_position
	movem.l	d1-a6,-(a7)
	bsr	get_save_params
	bsr	_sg_save
	bsr	restore_display
	movem.l	(a7)+,d1-a6
	not.l	d0
	rts

restore_display
	lea	$dff000,a6
	move.w	#$1200,(bplcon0,a6)
	move.w	#$0000,(bpl1mod,a6)
	rts

get_save_params
	move.l	D0,A0		; buffer
	lea	SAVESCREEN,A1	; screen buffer
	move.l	D1,D0		; length
	rts
	
; < $2(A6): destination
; < D1: length in bytes
; < D2.W: sector #
; < $E(A6): track #
; > D0: 0 because OK

load_tracks:
	movem.l	d0-a6,-(a7)
	move.l	$2(a6),a0	: dest
	clr.l	d0
	clr.l	d3
	move.w	d2,d3
	clr.l	d2
	move.w	d3,d2
	move.w	$e(a6),d3
	mulu	#$1600,d3
	mulu	#$200,d2
	add.l	d3,d2

	move.l	d2,d0
	bsr	load_disk

	bsr	_flushcache
	movem.l	(a7)+,d0-a6
	move.l	#$0,d0				;must return 0 in d0
	rts


patch_it
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts

;--------------------------------
; IN:	d0=offset d1=size a0=dest
; OUT:	d0=success

load_disk	movem.l	d0-d2/a0-a2,-(a7)
		moveq	#1,d2
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d2/a0-a2
		rts

;======================================================================

	include	"savegame.s"

	END
