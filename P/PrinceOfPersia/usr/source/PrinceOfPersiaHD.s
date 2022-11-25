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

RELOC_ENABLED = 1
; when relocated, PC is shifted by $102000

;CHIP_ONLY = 1

; there seems to exist some spare memory up to $7E7E0 more than enough
; but this memory is used later on
SAVESCREEN = $7A000
SAVESCREENSIZE = $3000

	IFD	RELOC_ENABLED
RELOC_MEM = $4A000
	ELSE
	; not relocated: slave is a debug slave
	; (I don't want to distribute a non-relocated slave)
RELOC_MEM = SAVESCREENSIZE
CHIP_ONLY = 1
	ENDC
	
FASTMEMSIZE = $80000

	IFD	CHIP_ONLY
CHIPMEMSIZE = $80000+FASTMEMSIZE+RELOC_MEM
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
	dc.l	FASTMEMSIZE+SAVESCREENSIZE+RELOC_MEM			;ws_ExpMem
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
	dc.b	"4.4"
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
		dc.b	"Thanks to Wepl for savegame system",10
		dc.b	"Thanks to Hexaae for testing & bug reports",10,10
		dc.b	"Version "
		DECL_VERSION
	dc.b	0
		even

_config
        dc.b    "C1:X:Trainer Infinite Time:0;"
        dc.b    "C1:X:Trainer Infinite Energy:1;"
		dc.b    "C1:X:Super levelskip:2;"
		dc.b    "C2:X:second button jumps:0;"
		dc.b    "C2:X:up disabled:1;"
		dc.b    "C3:B:Save from any level;"
		dc.b	0
		
		dc.b	"$VER: PrinceOfPersia "
		DECL_VERSION
		dc.b	0
		even
	
	
_reloc_base
	dc.l	$1000
	
MAX_LEVEL = $D
BASE_ADDRESS = $7E800

IGNORE_JOY_DIRECTIONS
	include	ReadJoyPad.s
	
;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	bsr	_detect_controller_types
	
	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	IFD	CHIP_ONLY
	lea	_expmem(pc),a0
	move.l	#$80000,(a0)
	ENDC
	IFD	RELOC_ENABLED
	lea		_reloc_base(pc),a0
	move.l	_expmem(pc),d0
	add.l	#FASTMEMSIZE+SAVESCREENSIZE,d0
	move.l	d0,(a0)
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
	moveq	#5,d1		; UK 1b
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
	
	; set address for pause flag (not relocated)
	lea		pause_address_table(pc),a1
	subq.l	#1,d1
	add.l	d1,d1
	add.l	d1,d1
	move.l	(a1,d1.l),d0

	lea		game_paused_flag_address(pc),a1
	move.l	d0,(a1)
	
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

	PL_R	$7edce-$7E800	; drive stuff
	PL_R	$7ec4a-$7E800	; skip interrupt vector set
	PL_P	$624,read_tracks
	PL_W	$1E6,$6006
	PL_W	$A6,$6044
	PL_P	$298,_exit
	PL_NOP	$22A,4
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
	PL_NOP	$22C,4
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
	move.l	monitor(pc),d0
	cmp.l	#NTSC_MONITOR_ID,d0
	bne.b	.patch_\1
	lea	pl_v\1_ntsc(pc),a0	
.patch_\1
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-d1/a0-a2
	lea	\2,a0
	add.l	_reloc_base(pc),a0
	sub.w	#$1000,a0
	jmp	(a0)
	ENDM

PROGRAM_SIZE = $46800  ; $2F*$1800 tracks
PROGRAM_START = $0532c
; just for protect write, no need to be super-accurate
; too high => risk of false alarm
; slightly too low => probably doesn't matter
PROGRAM_END = $001f7ca

patch_program
	movem.l	d0-d1/a0-a2,-(A7)
	move.l	_resload(pc),a2

	; *** removes protection level (common to both (all?) versions)

	move.l	#-1,$6378.W		; 3 instead?
	IFD		RELOC_ENABLED
	
	; copy program

	
	move.l	#PROGRAM_SIZE/4,d0
	lea		$1000.W,a0
	move.l	_reloc_base(pc),A1
.copy
	move.l	(a0)+,(a1)+
	subq.l	#1,d0
	bne.b	.copy
	
	; load reloc table
	
	lea	_reloc_table_address(pc),a1
	lea		reloc_file_name_table(pc),a0
	
	move.l	version(pc),D0
	add.l	d0,d0
	add.w	(a0,d0.l),a0	; relative => absolute name
	jsr		resload_LoadFileDecrunch(a2)

	; relocate
	move.l	_reloc_base(pc),a0
	lea		(-$1000,a0),a1	; reloc base -$1000
	move.l	a1,d1
	lea	_reloc_table_address(pc),a1
.reloc
	move.l	(a1)+,d0
	beq.b	.end
	add.l	d1,(a0,d0.l)
	bra.b	.reloc
.end
	; debug: add MMU protect on old program $ -> $ for v1
	; winuae: w 0 $532c $1f7ca-$532C
	IFD	CHIP_ONLY
	move.l	#PROGRAM_END-PROGRAM_START,d0                   ;one longword
	lea     PROGRAM_START,a0                ;address
	move.l  (_resload,pc),a2
	;jsr     (resload_ProtectRead,a2)
	move.l	#PROGRAM_END-PROGRAM_START,d0                   ;one longword
	lea     PROGRAM_START,a0                ;address
	move.l  (_resload,pc),a2
	;jsr     (resload_ProtectWrite,a2)
	
	ENDC

	ENDC
	
	move.l	_reloc_base(pc),A1
	; make it like memory is absolute
	; as patchlist base is zero
	sub.w	#$1000,a1

	move.l	version(pc),D0
	cmp.l	#1,d0
	bne.b	version2

	; version 1, first one I patched
	PATCH_VERSION	1,$1F662

version2:
	cmp.l	#2,d0
	bne.b	version3
	PATCH_VERSION	2,$1F636

version3:
	cmp.l	#3,d0
	bne.b	version4
	PATCH_VERSION	3,$1F63A
version4
	cmp.l	#4,d0
	bne.b	version5
	PATCH_VERSION	4,$1F65E
version5
	cmp.l	#5,d0
	bne.b	version6
	; version 1b slightly different
	PATCH_VERSION	1,$1F662
version6	
	; not possible to reach
	illegal

pl_v1_ntsc
	PL_START
	PL_W	$1ba9e+2,$2c81	; DIWSTRT
	PL_W	$1baa6+2,$f4c1	; DIWSTOP
	PL_NEXT	pl_v1
	
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

	PL_PSS	$19fac,vbl_hook,2
	
	PL_IFC2
	PL_PS	$1B8C6,read_joydat
	PL_ENDIF
	
	PL_IFC3
	; save at any level
	PL_S	$1900C,$20-$C
	PL_ENDIF
	
	PL_IFC1X	0
	; time--

	PL_NOP	$1926A,6

	PL_ENDIF
	
	PL_IFC1X	1
	; infinite energy

	PL_PS	$C622,trainer_v1
	PL_ENDIF
	
	PL_IFC1X	2
	; time=15 (levelskip)

	PL_B	$190D6,$60
	; levelskip up to level 12

	PL_B	$19097,MAX_LEVEL
	PL_ENDIF

; replaces STOP blitter interrupt wait by active blitwaits
;	PL_IFC5
;	PL_P	$53AA,blitter_1
;	PL_P	$53d6,blitter_2
;	PL_ENDIF
	
	PL_END


pl_v2_ntsc
pl_v2
	PL_START
	; removes unexpected exception

	PL_W	$195B6,$6004

	; quit key

	PL_PS	$1A2F0,kbint

	PL_PSS	$19f7a,vbl_hook,2

	PL_IFC2
	PL_PS	$1b894,read_joydat
	PL_ENDIF

	PL_IFC3
	; save at any level
	PL_S	$18fda,$20-$C
	PL_ENDIF

	; *** if exception exit

;	PL_P	$7F38E,error

	; *** load/save

	PL_P	$C774,savegame_v2
	PL_P	$C806,loadgame_v2
	PL_P	$C902,savehigh_v2
	PL_P	$C95E,loadhigh_v2

	PL_IFC1X	0
	; time-

	PL_NOP	$19238,6
	PL_ENDIF
	
	PL_IFC1X	1
	; *** infinite energy

	PL_PS	$C626,trainer_v2
	PL_ENDIF
	
	PL_IFC1X	2
	; *** time=15 (levelskip)

	PL_W	$190A6,$703C
	PL_W	$1909C,$703C

	; levelskip up to level 12

	PL_B	$19065,MAX_LEVEL

	PL_ENDIF
	PL_END
	
; german
pl_v3_ntsc
	PL_START
	PL_W	$1ba76+2,$2c81	; DIWSTRT
	PL_W	$1ba7e+2,$f4c1	; DIWSTOP
	PL_NEXT	pl_v3

pl_v3:
	PL_START
	; *** removes unexpected exception

	PL_W $195C0,$6004

	; quit key

	PL_PS	$1A2FA,kbint

	PL_PSS	$19f84,vbl_hook,2

	PL_IFC2
	PL_PS	$1b89e,read_joydat
	PL_ENDIF

	PL_IFC3
	; save at any level
	PL_S	$18fe4,$20-$C
	PL_ENDIF

	; *** load/save

	PL_P	$C748,savegame_v3
	PL_P	$C7E0,loadgame_v3
	PL_P	$C8E8,savehigh_v3
	PL_P	$C94A,loadhigh_v3
		  
	; time--

	PL_IFC1X	0
	PL_NOP	$19242,4
	PL_NOP	$19246,2
	PL_NOP	$12246,2
	PL_ENDIF
	
	PL_IFC1X	1
	; *** infinite energy

	PL_PS	$C5FA,trainer_v3
	PL_ENDIF
	
	PL_IFC1X	2
	; time=15 (levelskip)
    PL_B	 $190AE,$60
		  ; max level for levelskip
	PL_B	 $1906F,MAX_LEVEL
	PL_ENDIF
	

	PL_END

; version 4 - French version "Prince de Perse"

pl_v4_ntsc
	PL_START
	PL_W	$1ba9a+2,$2c81	; DIWSTRT
	PL_W	$1baa2+2,$f4c1	; DIWSTOP
	PL_NEXT	pl_v4

pl_v4:
	PL_START
	; *** removes unexpected exception

	PL_W $195E4,$6004

	; *** quit key

	PL_PS	$1A31E,kbint

	PL_PSS	$19fa8,vbl_hook,2

	PL_IFC2
	PL_PS	$1b8c2,read_joydat
	PL_ENDIF

	PL_IFC3
	; save at any level
	PL_S	$19008,$20-$C
	PL_ENDIF

	; *** load/save

	PL_P	$C76C,savegame_v4
	PL_P	$C804,loadgame_v4
	PL_P	$C90C,savehigh_v4
	PL_P	$C96E,loadhigh_v4


	; time--

	PL_IFC1X	0
	PL_NOP	$19266,4
	PL_NOP	$1226A,2
    PL_ENDIF
	
	
	PL_IFC1X	1
	; *** infinite energy

	PL_PS	$C61E,trainer_v4

	PL_ENDIF

	; *** time=15 (levelskip)
	PL_IFC1X	2

	PL_B $190D2,$60

	; levelskip up to level 12

	PL_B $19093,MAX_LEVEL
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

	
read_joydat:
	movem.l	d0/a0,-(a7)
	MOVE.W	_custom+joy1dat,D2
	move.l	button_controls(pc),d0
	btst	#1,d0
	beq.b	.noneed
	; ATM leave "up" alone. Just simulate it with blue button
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,D2
	btst	#9,D2
	beq.b	.noneed
	bset	#8,D2	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	move.l	joypad_state(pc),d0
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,D2
	btst	#9,D2
	bne.b	.no_blue
	bset	#8,D2	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	movem.l	(a7)+,d0/a0
	RTS
	
vbl_hook
	move.w	#$20,_custom+intreq	; original
	moveq.l	#1,d0
	bsr		_read_joystick
	lea		joypad_state(pc),a0
	move.l	d0,(a0)
	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_pause
	move.l	game_paused_flag_address(pc),a0
	move.l	#-1,(a0)
.no_pause	
	rts
	
blitter_1
	move.w	D0,_custom+bltsize
	bsr.b	wait_blit
	UNLK	A6			;053d0: 4e5e
	RTS				;053d2: 4e75
	
blitter_2
	move.w	D0,_custom+bltsize
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
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

SAVEBASE_V1 = $47B04
SAVEBASE_V2 = $47A2C
SAVEBASE_V3 = $47ADC
SAVEBASE_V4 = $47B00

	
loadgame_v1
	movem.l	d1-a6,-(a7)
	lea		SAVEBASE_V1,a0
	bsr	loadgame
	move.l	#1,$470D6
	movem.l	(a7)+,d1-a6
	rts

loadgame_v2
	movem.l	d1-a6,-(a7)
	lea		SAVEBASE_V2,a0
	bsr	loadgame
	move.l	#1,$46FFE	; tell the game not to reset life/time
	movem.l	(a7)+,d1-a6
	rts

loadgame_v3
	movem.l	d1-a6,-(a7)
	lea		SAVEBASE_V3,a0
	bsr	loadgame
	move.l	#1,$470AE	; tell the game not to reset life/time
	movem.l	(a7)+,d1-a6
	rts

loadgame_v4
	movem.l	d1-a6,-(a7)
	lea		SAVEBASE_V4,a0
	bsr	loadgame
	move.l	#1,$470D2	; tell the game not to reset life/time

	movem.l	(a7)+,d1-a6
	rts

savegame_v1
	movem.l	d1-a6,-(a7)
	lea		SAVEBASE_V1,a0
	lea	savegame_buffer(pc),a1
	bsr	savegame
	movem.l	(a7)+,d1-a6
	rts

savegame_v2
	movem.l	d1-a6,-(a7)
	lea		SAVEBASE_V2,a0
	lea	savegame_buffer(pc),a1
	bsr	savegame
	movem.l	(a7)+,d1-a6
	rts
	
savegame_v3
	movem.l	d1-a6,-(a7)
	lea		SAVEBASE_V3,a0
	lea	savegame_buffer(pc),a1
	bsr	savegame
	movem.l	(a7)+,d1-a6
	rts

savegame_v4
	movem.l	d1-a6,-(a7)
	lea		SAVEBASE_V4,a0
	lea	savegame_buffer(pc),a1
	bsr	savegame
	movem.l	(a7)+,d1-a6
	rts


loadgame
    movem.l a0/a2,-(a7)
	bsr	loadsave_prepro
	bsr	_sg_load
	bsr	loadsave_postpro
	lea	savegame_buffer(pc),a1
    movem.l (a7)+,a0/a2
	
	move.l	(A1)+,(8,a0)
	move.l	(A1)+,(12,a0)
	move.l	(A1)+,(a0)
	move.l	(A1)+,(4,a0)
	move.l	#$10,d0
	rts

savegame
	move.l	(-$4C,a0),(A1)+   		; level
	move.l	(12,a0),(A1)+     		; max energy
	move.l	(a0),(A1)+        		; minutes left
	move.l	(4,a0),(A1)+      		; milli-minutes???

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
_tag
		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
button_controls		dc.l	0
	dc.l	WHDLTAG_MONITOR_GET
monitor
	dc.l	0
		dc.l	0

joypad_state
	dc.l	0
game_paused_flag_address
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

pause_address_table
	dc.l	$470da
	dc.l	$47002
	dc.l	$470b2
	dc.l	$470d6
	dc.l	$470da
	
reloc_file_name_table
	dc.w	0
	dc.w	reloc_uk1a-reloc_file_name_table
	dc.w	reloc_us2-reloc_file_name_table
	dc.w	reloc_de3-reloc_file_name_table
	dc.w	reloc_fr4-reloc_file_name_table
	dc.w	reloc_uk1b-reloc_file_name_table

reloc_uk1b:		; same reloc tables
reloc_uk1a:
	dc.b	"prince_uk1.reloc",0
reloc_us2:
	dc.b	"prince_us2.reloc",0
reloc_de3:
	dc.b	"prince_de3.reloc",0
reloc_fr4:
	dc.b	"prince_fr4.reloc",0

	even
	
	include	savegame.s
	IFD	RELOC_ENABLED
	even
_reloc_table_address
	ds.b	10000
	ENDC
	

