;*---------------------------------------------------------------------------
;  :Program.	AlienBreed.asm
;  :Contents.	Slave for "Alien Breed" from Team 17
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	21.03.2001
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	hardware/custom.i


	IFD BARFLY
	OUTPUT	"StreetRacer.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
	INCDIR	Include:
	INCLUDE	whdload.i

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ReqAGA|WHDLF_Req68020|WHDLF_ClearMem	;ws_flags
		dc.l	$200000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem		
	dc.l	0			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	0	;_config-_base		;ws_config

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
		
_data   dc.b    'data',0
_name	dc.b	'Street Racer AGA',0
_copy	dc.b	'1994 Epic',0
_info
    dc.b   'by JOTD',10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	
;_config
 ;       dc.b    "C1:X:Trainer Infinite Lives & Ammo:0;"
;		dc.b	0

	dc.b	'$VER: Street Racer AGA HD by JOTD - '
	DECL_VERSION
	dc.b	0
	CNOP 0,2

	include	ReadJoyPad.s

MUSIC_NAME:MACRO
music\1name:
	dc.b	"MOD"
	dc.b	"\2"
	dc.b	".PAK",0

	ENDM

BUILD_TABLE:MACRO
	lea	MusicTable(pc),A0
	lea	music\1name(pc),A1
	move.l	#\2,8*(\1-1)(A0)	; disk offset
	move.l	A1,(8*(\1-1)+4)(A0)	; pointer on filename
	ENDM


    
;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

	BUILD_TABLE	1,$21C
	BUILD_TABLE	2,$234
	BUILD_TABLE	3,$1D4
	BUILD_TABLE	4,$24C
	BUILD_TABLE	5,$204
	BUILD_TABLE	6,$15C
	BUILD_TABLE	7,$1A4
	BUILD_TABLE	8,$1EC
	BUILD_TABLE	9,$174
	BUILD_TABLE	10,$1BC
	lea		$1ffffc,a7	;Abaddon added and now the game works
					;Same error I got with Dennis AGA and Out to Lunch AGA

	bsr	InstallBoot

	;move.l	_resload(pc),a2
	;jsr	resload_FlushCache(a2)
	jmp	($48D00)

InstallBoot:
	move.l	_resload(pc),a2
	lea	mainname(pc),A0
	lea	$48D00,A1
	jsr	(resload_LoadFileDecrunch,a2)

	; check if main2 file is here
    ; this file contains the same data, but it
    ; does not clears the higher memory like the
    ; original one, allowing CD32load CD buffers
    ; to be preserved
    
	lea	main2name(pc),A0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.classic
		
	lea	main2name(pc),A0
	lea	$1A30D0+$48D00,A1
	jsr	(resload_LoadFileDecrunch,a2)

.classic
    bsr _detect_controller_types
    
	; remove wrong blitter waits

	lea	$1A0000,A0
	lea	$1D0000,A1
	lea	.waitblit(pc),a2
	moveq.l	#10,D0
	bsr	_removeblit

	lea	$4E000,A0
	lea	$51000,A1
	lea	.waitblit(pc),a2
	moveq.l	#10,D0
	bsr	_removeblit


	lea	$1A0000,A0
	lea	$1D0000,A1
	lea	.accessC00000(pc),a2
	moveq.l	#4,D0
.loop
	bsr	HexSearch
	cmp.l	#0,A0
	beq.b	.out
	move.l	A0,d1
	addq.l	#2,a0
	btst	#0,d1
	bne.b	.loop		; odd address!
	cmp.b	#$33,(-4,A0)
	bne.b	.loop
	move.l	#$60044E71,(-4,A0)
	bra.b	.loop
.out

	move.l	_resload(pc),a2
	sub.l	A1,A1
	lea		pl_main(pc),a0
	jsr	(resload_Patch,a2)

	rts
.waitblit:
	dc.l	$02794000,$DFF002
	dc.w	$66F6

.accessC00000:
	dc.l	$C00000

pl_main
	PL_START
	PL_PS	$1C321E,KbInt	; keyboard patch
	PL_W	$1C3224,$6016		; skip kb ack

	PL_P	$4A874,Clear	; faster clr
	PL_P	$4A748,Decrunch1; faster decrunch
	PL_P	$4A3E8,Decrunch2; faster decrunch

	PL_P	$1C0AA2,RNCDecrunch
	PL_PS	$1C0E0E,LoadMusic	; disk routine

	PL_PS	$1ABF78,patch_af_1

	; remove zillions of access faults

	PL_W	$1AD1F8,$6004		; fixes access fault
	PL_W	$1AA8D8,$6004	; fixes access fault
	PL_W	$1AD9C6,$6004		; fixes access fault

    PL_PS   $50642,vbl_hook
    PL_PSS  $050994,test_fire,2
    PL_PSS  $05099e,test_fire,2
    PL_PSS  $1b84c8,test_space,2
    PL_PSS  $1bcaf8,test_space,2
    PL_PSS  $1be43c,test_f1,2
    PL_PS   $04a89e,test_f1_2
    
    ; talk about bad luck!!!
    ; remove stupid check on address $6.W (probably error!)
    ; this checks for 1.W. in the meantime whdload sets
    ; $4.L to $F0000001 so $6.W == 1 and the addresses are
    ; completely off and access faults are triggered
    ; but now access fault fix is not necessary when disabling
    ; this test
    ; A similar bad luck was seen in some Team 17 games when game read
    ; $4.B and found $F0 for whdload.
    
    PL_NOP  $1B5E4A,10
    
	PL_W	$49A7E,$6006		; no force PAL
	PL_W	$49AEA,$6006

	PL_P	$100,EmulateDbf

	PL_L	$1C3FBE,$4EB80100
	PL_L	$1C3FD8,$4EB80100	; fix cpu dependent dbf loops
	PL_END

; useless (and possibly not 100% functionnal) now that
; the stupid 6.W read is gone
;
;    PL_P   $1B5E08,patch_af_2
;    PL_PS   $1B5CBC,patch_af_3
;    PL_PS   $1B5CE6,patch_af_4
    IFEQ    1
; patch 2 and 3 avoid access faults on 3, 4 player modes	
patch_af_2
.loop
    cmp.l  #$1FFFF0,a0
    bcc.b  .berzerk
    MOVE.W	(A0)+,D0		;1b5e08: 3018
    DBF	D7,.loop		;1b5e0a: 51cffffc
    RTS				;1b5e0e: 4e75
.berzerk
   rts

patch_af_3
    cmp.l  #$1FFFF0,a0
    bcc.b  .berzerk
    ADD.W #$0016,(2,A0)
    rts
.berzerk
    add.l   #14,(A7)    ; skip loop
    rts
patch_af_4
    cmp.l  #$1FFFF0,a0
    bcc.b  .berzerk
    ADD.W #$0016,(2,A0)
    rts
.berzerk

    addq.l #4,a7 ; pop up
    rts
    ENDC
    
patch_af_1
	movem.l	d0,-(a7)
	move.l	A1,d0
	rol.l	#8,d0
	tst.b	d0
	movem.l	(a7)+,d0
	beq.b	.ok

	addq.l	#6,(a7)
	rts
.ok
	move.b	(a1)+,d0
	add.w	#$87,d0
	rts
 
ascii_keycode_copy = $1c3333

test_space:
	CMPI.B	#$20,ascii_keycode_copy
    beq.b   .pressed
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    btst    #JPB_BTN_BLU,d0
    movem.l (a7)+,d0
    eor #4,CCR
.pressed
    rts
    
test_f1_2:
	MOVE.B	ascii_keycode_copy,D0		;04a89e: 1039001c3333
	CMPI.B	#$01,ascii_keycode_copy
    beq.b   .pressed
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    movem.l (a7)+,d0
    beq.b   .pressed
    move.b  #1,d0   ; simulate F1
.pressed
    rts
    
test_f1:
	CMPI.B	#$01,ascii_keycode_copy
    beq.b   .pressed
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    movem.l (a7)+,d0
    eor #4,CCR
.pressed
    rts
    
keyboard_table = $1c32b0

TESTKEY:MACRO
    cmp.b   #$FF,(\2,a0)
    beq.b   .no_press_\1
    add.b   #1,(\2,a0)
.no_press_\1
	btst	#JPB_BTN_\1,d0
	beq.b	.no_\1
	move.b    #$F0,(\2,a0)	; pressed
.no_\1
    ENDM
    
test_fire:
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    eor #4,CCR
    rts
    
vbl_hook
    ; we can trash the registers
    ADDQ.W	#1,$1eeaae  ; original
    
    bsr _joystick
    move.l  joy1(pc),d0
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_PLAY,d0
    bne _quit
.noquit
    rts
    
_removeblit:
.loop1
	bsr	HexSearch
	cmp.l	#0,A0
	beq.b	.out
	move.w	#$4EB9,(A0)+
	pea	WaitBlit(pc)
	move.l	(a7)+,(a0)+
	move.l	#$4E714E71,(A0)+
	bra.b	.loop1
.out:
	rts

HexSearch:
;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

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
	
EmulateDbf:
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	rts

kb_delay:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
	rts

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

WaitBlit:
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts

RNCDecrunch	
	movem.l	D0-d7/A0-A6,-(A7)
	move.l	_resload(pc),a2
	jsr	(resload_Decrunch,a2)
	movem.l	(A7)+,D0-d7/A0-A6
	rts


LoadMusic:
	movem.l	d0-A6,-(a7)
	
	move.l	A0,A1

	bsr	SearchFile
	cmp.l	#0,A0
	bne	.read	; file found

	lea	music11name(pc),A0	; not found
	bra	.read			; load race music

	movem.l	(a7)+,d0-a6
	lea	$BFE201,A4
	rts
.read
	move.l	_resload(pc),a2
	jsr	(resload_LoadFile,a2)
	
	movem.l	(a7)+,d0-a6
	moveq	#0,D0
	addq.l	#4,A7	; pops up stack
	rts

	
SearchFile:
	lea	MusicTable(pc),A2
.loop
	move.l	(A2)+,D2
	beq	.end
	cmp.l	D0,D2
	beq	.end
	addq.l	#4,A2
	bra	.loop
.end
	move.l	(A2),A0	; 0 or valid filename pointer
	rts

Clear:
	LEA	$29500,A0
	MOVE.L	#$00003EFF,D7
	BSR	.clrloop
	LEA	$39100,A0
	MOVE.L	#$00003EFF,D7
.clrloop:
	CLR.L	(A0)+
	DBF	D7,.clrloop
	ADDQ	#1,D7
	SUBQ.L	#1,D7
	BPL.S	.clrloop
	RTS
KbInt:
	move.b	D0,($1C3330)
	cmp.b	_base+ws_keyexit(pc),D0
	bne	_noquit
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
_noquit:
	; acknowledge keyboard properly

	bsr	kb_delay
	rts
mainname:
	dc.b	"MAIN.PAK",0
main2name:
	dc.b	"MAIN2.PAK",0

	MUSIC_NAME	1,HOD
	MUSIC_NAME	2,FRA
	MUSIC_NAME	3,SUZ
	MUSIC_NAME	4,BIF
	MUSIC_NAME	5,RAP
	MUSIC_NAME	6,SUR
	MUSIC_NAME	7,HEL
	MUSIC_NAME	8,SUM
	MUSIC_NAME	9,RUM
	MUSIC_NAME	10,END
	MUSIC_NAME	11,RAC

	cnop	0,4

MusicTable:
	blk.l	$20,0
;--------------------------------

    
Decrunch1:
	incbin	"decr4A748"
	even
Decrunch2:
	incbin	"decr4A3E8"

_resload	dc.l	0		;address of resident loader
