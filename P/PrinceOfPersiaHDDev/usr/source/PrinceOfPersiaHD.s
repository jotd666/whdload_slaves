;*---------------------------------------------------------------------------
;  :Program.	PrinceOfPersiaHD.asm
;  :Contents.	Slave for "Prince Of Persia" from Broderbund
;  :Author.	JOTD
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
	INCLUDE	hardware/custom.i

	IFD BARFLY
	OUTPUT	PrinceOfPersia.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;CHIP_ONLY = 1
; there seems to exist some spare memory up to $7E7E0 more than enough
; but this memory is used later on
SAVESCREEN = $7A000
SAVESCREENSIZE = $3000

	IFD	CHIP_ONLY
CHIPMEMSIZE = $100000+SAVESCREENSIZE
	ELSE
CHIPMEMSIZE = $80000		;ws_BaseMemSize
	ENDC
	

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError	;ws_flags
		dc.l	CHIPMEMSIZE
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem	
	IFND	CHIP_ONLY	
	dc.l	$80000+SAVESCREENSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
		
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
	
DECL_VERSION:MACRO
	dc.b	"3.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Prince Of Persia"
    IFD CHIP_ONLY
    
    dc.b    " (DEBUG/CHIP MODE)"
    ENDC
    dc.b 0
_copy		dc.b	"1990 Jordan Mechner/Broderbund",0
_info		dc.b	"adapted & fixed by JOTD & Harry",10,10
		dc.b	"Thanks to Wepl for savegame system",10,10
		dc.b	"Version "
		DECL_VERSION
	dc.b	0
		even

_config
        dc.b    "C1:X:Trainer Infinite Energy/Time:0;"
		dc.b    "C2:X:Levelskip does not steal time:0;"
		dc.b	0
	even
MAX_LEVEL = $D
BASE_ADDRESS = $7E800

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	lea	_expmem(pc),a0
	IFD	CHIP_ONLY
	move.l	#$80000,(a0)
	ENDC


	lea	$10000,a7
	move	#$2700,SR

	; load & version check

	lea	BASE_ADDRESS,A0
	moveq.l	#$0,D0		; offset
	move.l	#$1800,D1	; length
	moveq	#1,D2		; always disk 1!
	bsr	_loaddisk

	lea	BASE_ADDRESS,A0
	move.l	#$1000,d0
	jsr	resload_CRC16(a2)

	lea	pl_boot_1(pc),a0

	moveq	#1,d1		; UK 1a
	cmp.l	#$F020,d0
	beq.b	.vok
	moveq	#1,d1		; UK 1b
	cmp.l	#$4599,d0
	beq.b	.vok
	moveq	#2,d1		; US? boot is completely different
	cmp.l	#$12CB,d0
	bne.b	.v3
	lea	pl_boot_2(pc),a0
	bra.b	.vok
.v3
	moveq	#3,d1		; german
	cmp.l	#$44FE,d0
	beq.b	.vok
	moveq	#4,d1		; french
	cmp.l	#$2E98,d0
	beq.b	.vok

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.vok
	lea	version(pc),a3
	move.l	d1,(a3)
	lea	BASE_ADDRESS,A1
	jsr	resload_Patch(a2)
		
	; game flags for expansion memory, not used but we set them to 0 anyway

	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d7

	move.l	version(pc),d0
	cmp.l	#2,d0
	beq.b	.runv2
	jmp	BASE_ADDRESS+$186
.runv2
	jmp	BASE_ADDRESS+$188

pl_boot_1
	PL_START
	; 512k expansion mem

	PL_P	$2A0,get_extmem

	; disk load

	PL_P	$624,read_tracks
	PL_W	$1E6,$6006
	PL_W	$A6,$6044
	PL_P	$298,_exit
	PL_L	$22A,$4E714E71
	PL_P	$22E,patch_program
	PL_END

pl_boot_2
	PL_START
	; 512k expansion mem

	PL_P	$2A4,get_extmem

	; disk load

	PL_P	$628,read_tracks
	PL_W	$1E8,$6006
	PL_W	$A8,$6044

	; main patch
	PL_L	$22C,$4E714E71
	PL_P	$230,patch_program

	; safety

	PL_I	$B96
	PL_P	$29C,_exit
	PL_END

get_extmem
    move.l  _expmem(pc),a0
    rts

_exit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; A1=buffer, D0=begtrack, D1=length in tracks

read_tracks
	movem.l	d0-d2/a0-a2,-(A7)

	move.l	A1,A0	; destination buffer
	subq.l	#1,D0	; always >=1
	bcs	.exit	; impossible ??
	
	and.l	#$FFFF,D1
	mulu.w	#24,D1
	lsl.l	#8,D1	; * $1800 = size
	
	and.w	#$FFFF,D0
	mulu.w	#24,D0
	lsl.l	#8,D0	; * $1800 = offset

	moveq	#1,d2
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
.exit
	moveq	#-1,d0
	movem.l	(a7)+,d0-d2/a0-a2
	rts


get_save_backup_mem:
    bsr get_extmem
    add.l   #$80000,a0
    rts
    
DEF_SAVELOAD_HIGH:MACRO
savehigh_v\1:
	movem.l	D1-A6,-(sp)

	lea.l	\2,a1
	bsr	savehigh
	move.l	#$d0,D0
	movem.l	(sp)+,D1-A6
	rts

loadhigh_v\1
	movem.l	D1-A6,-(sp)
	lea.l	\2,a1
	bsr	loadhigh
	movem.l	(sp)+,D1-A6
	rts
	ENDM

DEF_TRAINER:MACRO
trainer_v\1
	tst.l	d0
	bne	.nodie
	CLR.L	\1
.nodie
	RTS
	ENDM

PATCH_VERSION:MACRO
	lea	pl_v\1(pc),a0
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-d1/a0-a2
	jmp	\2
	ENDM

patch_program
	movem.l	d0-d1/a0-a2,-(A7)

	; *** removes protection level (common to both (all?) versions)

	move.l	#-1,$6378.W

	sub.l	a1,a1
	move.l	_resload(pc),a2

	move.l	version(pc),D0
	cmp.l	#1,d0
	bne	version2

	; version 1, first one I patched
	PATCH_VERSION	1,$1F662

version2:
	cmp.l	#2,d0
	bne	version3
	PATCH_VERSION	2,$1F636

version3:
	cmp.l	#3,d0
	bne	version4

	PATCH_VERSION	3,$1F63A
	cmp.l	#4,d0
	bne	version5
version4
	PATCH_VERSION	4,$1F65E
version5
	; not possible to reach
	illegal
	

pl_v1
	PL_START

	; removes unexpected exception

	PL_W	$195E8,$6004

	; quit key

	PL_PS	$1A322,kbint

	; load/save

	PL_P	$C770,savegame_v1
	PL_P	$C808,loadgame_v1
	PL_P	$C910,savehigh_v1
	PL_P	$C972,loadhigh_v1

	PL_IFC1
	; time--

	PL_L	$1926A,$4E714E71
	PL_W	$1926E,$4E71


	; infinite energy

	PL_PS	$C622,trainer_v1

	; time=15 (levelskip)

	PL_B	$190D6,$60
	; levelskip up to level 12

	PL_B	$19097,MAX_LEVEL
	PL_ELSE
	PL_IFC2
	; time=15 (levelskip)

	PL_B	$190D6,$60
	; levelskip up to level 12

	PL_B	$19097,MAX_LEVEL
	PL_ENDIF
	PL_ENDIF
	PL_END


pl_v2
	PL_START
	; removes unexpected exception

	PL_W	$195B6,$6004

	; quit key

	PL_PS	$1A2F0,kbint

	; *** if exception exit

;	PL_P	$7F38E,error

	; *** load/save

	PL_P	$C774,savegame_v2
	PL_P	$C806,loadgame_v2
	PL_P	$C902,savehigh_v2
	PL_P	$C95E,loadhigh_v2

	PL_IFC1
	; time-

	PL_L	$19238,$4E714E71
	PL_W	$1923C,$4E71
	; *** infinite energy

	PL_PS	$C626,trainer_v2

	; *** time=15 (levelskip)

	PL_W	$190A6,$703C
	PL_W	$1909C,$703C

	; levelskip up to level 12

	PL_B	$19065,MAX_LEVEL
	PL_ELSE
	PL_IFC2
	; *** time=15 (levelskip)

	PL_W	$190A6,$703C
	PL_W	$1909C,$703C

	; levelskip up to level 12

	PL_B	$19065,MAX_LEVEL
	PL_ENDIF
	PL_ENDIF
	PL_END
	
pl_v3:
	PL_START
	; *** removes unexpected exception

	PL_W $195C0,$6004

	; quit key

	PL_PS	$1A2FA,kbint

	; *** load/save

	PL_P	$C748,savegame_v3
	PL_P	$C7E0,loadgame_v3
	PL_P	$C8E8,savehigh_v3
	PL_P	$C94A,loadhigh_v3
		  
	; time--

	PL_IFC1
	PL_NOP	$19242,4
	PL_NOP	$19246,2
	PL_NOP	$12246,2

	; time=15 (levelskip)
    PL_B	 $190AE,$60
		  ; max level for levelskip
	PL_B	 $1906F,MAX_LEVEL
		  
	; *** infinite energy

	PL_PS	$C5FA,trainer_v3
	PL_ELSE
	PL_IFC2
	; time=15 (levelskip)
    PL_B	 $190AE,$60
		  ; max level for levelskip
	PL_B	 $1906F,MAX_LEVEL
	PL_ENDIF
	PL_ENDIF
	PL_END

; version 4 - French version "Prince de Perse"

pl_v4:
	PL_START
	; *** removes unexpected exception

	PL_W $195E4,$6004

	; *** quit key

	PL_PS	$1A31E,kbint

	; *** load/save

	PL_P	$C76C,savegame_v4
	PL_P	$C804,loadgame_v4
	PL_P	$C90C,savehigh_v4
	PL_P	$C96E,loadhigh_v4


	; time--

	PL_IFC1
	PL_NOP	$19266,4
	PL_NOP	$1226A,2
    
	; *** time=15 (levelskip)

	PL_B $190D2,$60

	; levelskip up to level 12

	PL_B $19093,MAX_LEVEL

	; *** infinite energy

	PL_PS	$C61E,trainer_v4
	PL_ELSE
	PL_IFC2
	; *** time=15 (levelskip)

	PL_B $190D2,$60

	; levelskip up to level 12

	PL_B $19093,MAX_LEVEL
	PL_ENDIF
	PL_ENDIF
	PL_END

	DEF_TRAINER		1,$47AD4
	DEF_TRAINER		2,$479FC
	DEF_TRAINER		3,$47AAC
	DEF_TRAINER		4,$47AD0

	DEF_SAVELOAD_HIGH	1,$49BDC
	DEF_SAVELOAD_HIGH	2,$49B04
	DEF_SAVELOAD_HIGH	3,$49BB4
	DEF_SAVELOAD_HIGH	4,$49BD8	; ???



; < A1: buffer
loadhigh
	lea	highname(pc),a0
	move.l	_resload(pc),a2
	movem.l a0-a1,-(a7)
	JSR resload_GetFileSize(a2)
	movem.l (a7)+,a0-a1
	tst.l	d0
	beq.b	.out
	move.l	#$D0,d0
	moveq.l	#4,d1		; skip first 4 bytes
	jsr	resload_LoadFileOffset(a2)
.out
	move.l	#$d0,D0
	rts

savehigh
	move.l	trainer(pc),D0
	bne.b	.nosave		; don't save hiscores
	move.l	_resload(pc),a2
	lea	highname(pc),a0
	move.l	#$D0,d0
	moveq.l	#4,d1		; skip first 4 bytes
	jsr	resload_SaveFileOffset(a2)
	lea	startword(pc),a1
	lea	highname(pc),a0
	moveq.l	#4,d0
	moveq.l	#0,d1
	jsr	resload_SaveFileOffset(a2)
.nosave
	move.l	#$d0,D0
	rts

highname	dc.b	'prince.high',0
	even
startword
	dc.l	'POPS'

loadgame_v1
	movem.l	d1-a6,-(a7)
	lea	savegame_buffer(pc),a1
	bsr	loadgame
	move.l	(A1)+,$47B0C
	move.l	(A1)+,$47B10
	move.l	(A1)+,$47B04
	move.l	(A1)+,$47B08
	move.l	#1,$470D6
	movem.l	(a7)+,d1-a6
	rts

loadgame_v2
	movem.l	d1-a6,-(a7)
	lea	savegame_buffer(pc),a1
	bsr	loadgame
	move.l	(A1)+,$47A34
	move.l	(A1)+,$47A38
	move.l	(A1)+,$47A2C
	move.l	(A1)+,$47A30
	move.l	#1,$46FFE	; tell the game not to reset life/time
	movem.l	(a7)+,d1-a6
	rts

loadgame_v3
	movem.l	d1-a6,-(a7)
	bsr	loadgame
	lea	savegame_buffer(pc),a1
	move.l	(A1)+,$47AE4
	move.l	(A1)+,$47AE8
	move.l	(A1)+,$47ADC
	move.l	(A1)+,$47AE0
	move.l	#1,$470AE
	movem.l	(a7)+,d1-a6
	rts

loadgame_v4
	movem.l	d1-a6,-(a7)
	lea	savegame_buffer(pc),a1
	bsr	loadgame
	move.l	(A1)+,$47B08
	move.l	(A1)+,$47B0C
	move.l	(A1)+,$47B00
	move.l	(A1)+,$47B04
	move.l	#1,$470D2

	movem.l	(a7)+,d1-a6
	rts

savegame_v1
	movem.l	d1-a6,-(a7)
	lea	savegame_buffer(pc),a1
	move.l	$47AB8,(A1)+
	move.l	$47B10,(A1)+
	move.l	$47B04,(A1)+
	move.l	$47B08,(A1)+
	bsr	savegame
	movem.l	(a7)+,d1-a6
	rts

savegame_v2
	movem.l	d1-a6,-(a7)
	lea	savegame_buffer(pc),a1
	move.l	$63A6.W,(A1)+		; level
	move.l	$47A38,(A1)+		; max energy
	move.l	$47A2C,(A1)+		; minutes left
	move.l	$47A30,(A1)+		; milli-minutes???
	bsr	savegame
	movem.l	(a7)+,d1-a6
	rts
	
savegame_v3
	movem.l	d1-a6,-(a7)
	lea	savegame_buffer(pc),a1
	move.l	$63A6.W,(A1)+
	move.l	$47AE8,(A1)+
	move.l	$47ADC,(A1)+
	move.l	$47AE0,(A1)+
	bsr	savegame
	movem.l	(a7)+,d1-a6
	rts

savegame_v4
	movem.l	d1-a6,-(a7)
	lea	savegame_buffer(pc),a1
	move.l	$47AB4,(A1)+
	move.l	$47B0C,(A1)+
	move.l	$47B00,(A1)+
	move.l	$47B04,(A1)+
	bsr	savegame
	movem.l	(a7)+,d1-a6
	rts


loadgame
    movem.l a2,-(a7)
	bsr	loadsave_prepro
	bsr	_sg_load
	bsr	loadsave_postpro
	lea	savegame_buffer(pc),a1
    movem.l (a7)+,a2
	move.l	#$10,d0
	rts

savegame
    movem.l a2,-(a7)
	move.l	trainer(PC),d0
	bne.s	.skip		;no save on trainer
	bsr	loadsave_prepro
	bsr	_sg_save
	bsr	loadsave_postpro
.skip
    movem.l (a7)+,a2
	move.l	#$10,D0
	rts

loadsave_prepro
	lea	savegame_buffer(pc),a0
	lea	SAVESCREEN,a1
    lea savegame_name(pc),a2
    ; save chipmem prior to using it
    movem.l d0/a0-a1,-(a7)
    bsr get_save_backup_mem
    move.l  #(SAVESCREENSIZE/4)-1,d0
.loop
    move.l  (a1)+,(a0)+
    dbf d0,.loop
    movem.l (a7)+,d0/a0-a1
    
	moveq	#$10,d0
	rts
    
loadsave_postpro
    ; put back backed up memory from expansion to chip
    movem.l d0/a0-a1,-(a7)
    bsr get_save_backup_mem
	lea	SAVESCREEN,a1
    exg a0,a1 
    move.l  #(SAVESCREENSIZE/4)-1,d0
.loop
    move.l  (a1)+,(a0)+
    dbf d0,.loop
    movem.l (a7)+,d0/a0-a1

	movem.l	a6,-(a7)
	lea	$dff000,a6
	move.w	#$5200,(bplcon0,a6)
	move.w	#$0000,(bpl1mod,a6)
	move.w	#$0B90,(color+2,a6)	; or Prince will have white hair :)
	movem.l	(a7)+,a6
	rts



savegame_buffer
	ds.b	$10,0
savegame_name:
    dc.b    "savegame",0
    even
    
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

kbint:
	move.b	$BFEC01,D2
	move.l	D2,-(sp)
	not.b	D2
	ror.b	#1,D2
	cmp.b	_keyexit(pc),D2
	beq	_exit
	move.l	(sp)+,D2
	rts

version
	dc.l	0
_tag		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
unlimited_levelskip	dc.l	0
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

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_loaddisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

	include	savegame.s
		  

