;*---------------------------------------------------------------------------
;  :Program.	deliveranceslave.asm
;  :Contents.	Slave for "Deliverance"
;  :Author.	Harry
;  :History.	21.05.97
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;---------------------------------------------------------------------------*

;TODO: trainer address

;crc_v1	= $baec
;crc_v2	= $a12d

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"FireAndIce.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

; game doesn't work properly when 32-bit memory is set
;USE_FASTMEM

;======================================================================

_base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_EmulTrapV|WHDLF_EmulTrap|WHDLF_EmulDivZero|WHDLF_NoError	;ws_flags
		dc.l	$80000
		dc.l	$0		;ws_ExecInstall
		dc.w	_start-_base	;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem
		IFD	USE_FASTMEM
		dc.l	$80000
		ELSE
		dc.l	0			;ws_ExpMem
		ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config
        dc.b    "C1:X:Trainer Infinite lives:0;"
        dc.b    "C1:X:Trainer Exit with incomplete key:1;"
        dc.b    "C2:X:Second/blue button jumps:0;"
        dc.b    "C3:L:train start level:None,1,2,3,4,5,6,7;"
		dc.b	0
	
; Jff: I reworked most of the stuff down there
; as a rule: all stuff in upper case is Ralf code, all stuff
; in lower case is mine :)
;
; Version 1: v1.00
; Version 2: v1.05

;======================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"3.4"
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

_data		dc.b	"data",0
_name		dc.b	"Fire And Ice"
	dc.b	0
_copy		dc.b	"1991 Graftgold",0
_info		dc.b	"Install & fix by Ralf/JOTD",10,10
			dc.b	"CD32 play pauses",10
			dc.b	"CD32 rev+fwd when paused aborts",10,10
			dc.b	"Thanks to Carlo Pirri for supplying the original disks",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

	include	ReadJoyButtons.s


NUM_BLOCKS	EQU	11
BLOCK_SIZE	EQU	512
TRACK_SIZE	EQU	NUM_BLOCKS*BLOCK_SIZE

; OK
OFFS_JMPALLOC	EQU	$3C
OFFS_ENDALLOC	EQU	$5E
OFFS_JMP10AE    EQU     $9C
OFFS_LOADER	EQU	$1EE



; for V1
OFFS_254D       EQU     $254D
OFFS_PROTPASS_V1    EQU     $1D3C	; codewheel protection
OFFS_PROTPASS_V2    EQU     $1D34
OFFS_35E6_V1    EQU     $35E6
OFFS_35E6_V2    EQU     $37B2

OFFS_CHIPALLOC_V1	EQU	$FD86
OFFS_EXTALLOC_V1	EQU	$FCF4
OFFS_FCACHE_V1     EQU     $FBB4
OFFS_JMP39XX_V1    EQU     $FBC0
OFFS_LOADER2_V1	EQU	$102B8
OFFS_WRITE_V1	EQU	$103CC
OFFS_KBDIRQ_V1	EQU	$109FC
OFFS_TRAINER_V1 EQU	$22F8E

OFFS_CHIPALLOC_V2	EQU	$FD9C
OFFS_EXTALLOC_V2	EQU	$FD0A
OFFS_FCACHE_V2     EQU     $FBB8
OFFS_JMP39XX_V2    EQU     $FBC4
OFFS_LOADER2_V2	EQU	$11318
OFFS_WRITE_V2	EQU	$1142C
OFFS_KBDIRQ_V2	EQU	$102BA
OFFS_TRAINER_V2 EQU     $22C7C



SCORES_LEN	EQU	TRACK_SIZE

INVALID_SCORE   EQU     $AABBCCDD
BOOT_ADDRESS = $59F4

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea	$7FF00,A7
		move.w	#$2700,SR
		
		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using

;		move.l	#CACRF_EnableI,d0	;enable instruction cache
;		move.l	d0,d1			;mask
;		jsr	(resload_SetCACR,a0)

		bsr	_detect_controller_type
		move.l	_resload(pc),a2
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	bsr	CheckVersion


	lea	BOOT_ADDRESS,a1
	LEA	FireBoot(pc),A0
	MOVE	#1035,D0

.COPY_BOOT
	MOVE.B	(A0)+,(A1)+
	DBF	D0,.COPY_BOOT

	lea	BOOT_ADDRESS,a1
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	BOOT_ADDRESS


pl_boot:
	PL_START
	PL_PS	$5AEE-$59F4,Patch5AEE

	PL_P	$1EE,MY_LOADER
	PL_NOP	$3C,4		; jmpalloc
	PL_PS	$5E,MY_ALLOCMEM
	PL_P	$9C,Jump10AE
	PL_END
	
	
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success


CheckVersion:
	lea	$10000,A0
	moveq.l	#1,D2
	move.l	#$B000,D0
	move.l	#$1600,D1
	jsr	(resload_DiskLoad,a2)
	
	lea	$10000,A0
	move.l	#$1600,D0
	jsr	(resload_CRC16,a2)

	cmp.w	#$5525,D0
	beq.b	.v1
	cmp.w	#$D00B,D0
	beq.b	.v2

	bra	_badver

.v2
	movem.l	a0,-(a7)
	lea	Version(pc),a0
	move.l	#1,(a0)
	movem.l	(a7)+,a0
.v1
	rts
	
Patch5AEE:
	; we must do all this shit only because we just have 2 bytes (RTS)
	; to insert our patch at the right place. a TRAP was done by Ralf,
	; but this involved lots of strange stuff including changing the stack,
    ; and I don't want to do that (whdload does not like it)
	
	movem.l	D0/A0,-(A7)
	move.l	8(A7),D0
	lea	.return_addy(pc),A0
	move.l	D0,(A0)		; store return address for later use
	movem.l	(A7)+,D0/A0

	move.w	($20,A5),D0	; original code
	beq.b	.skipcall

	; tricky

	move.l	A0,D5		; trash D5, will be trashed in the original game code
	lea	.skipcall(pc),A0

	lea	-$20(A7),A7		; readjust the stack to avoid trouble

	move.l	A0,(A7)		; RTS of the called routine will go there
	move.l	D5,A0		; restore A0

	move.l	.return_addy(pc),-(A7)	; re-install the original address
	rts				; and go!
	; we return here after the main exe has been loaded
.skipcall
	; the RTS should be performed here, but we prefer patch first

	movem.l	d0-a6,-(a7)


	
	lea	pl_main_2(pc),a0
	move.l	Version(pc),d0
	bne	.skipv2
	lea	pl_main_1(pc),a0
    
.skipv2
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	RTS

.return_addy:
	dc.l	0
	


PATCHLIST:MACRO
pl_main_\1:
	PL_START
	PL_P	OFFS_LOADER2_V\1,MY_LOADER2
	PL_P	OFFS_WRITE_V\1,MY_WRITE
	PL_PS	OFFS_KBDIRQ_V\1,MY_KBDIRQ
	PL_P	OFFS_CHIPALLOC_V\1,MY_CHIPALLOC
	PL_PS	OFFS_EXTALLOC_V\1,MY_EXTALLOC
	PL_NOP	OFFS_EXTALLOC_V\1+6,4
	PL_P	OFFS_FCACHE_V\1,FlushCache
	PL_P	OFFS_JMP39XX_V\1,Jump39CX

	PL_END
	ENDM
	
	PATCHLIST	1
	PATCHLIST	2
	
MY_ALLOCMEM
	LEA	$104.W,A5
	CLR.L	(A5)+
	CLR.L	(A5)+
	CLR.L	(A5)+
	CLR.L	(A5)+
	LEA	$DFF000,A4
	RTS
	

Jump10AE
	bsr	_flushcache
	jmp	$10AE.W
	

_badver		pea	TDREASON_WRONGVER
		bra	_end
_exit		pea	TDREASON_OK
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

FlushCache:
	bsr	_flushcache
	lsr.l	#2,D2
	jmp	(-10,A5)

; for V1/V2: here it seems that most of the game engine is loaded
Jump39CX:
	movem.l	d0-d1/a0-a2,-(a7)
    move.l  trainer_start_level(pc),d1
    lsl.w   #2,d1
    
	move.l	Version(pc),d0
	beq.b	.v1

; version 2
    move.w  d1,$013f0.w

	lea	pl_game_v2(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$39CA.W
	
.v1
    move.w  d1,$13ee.w

	lea	pl_game_v1(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	jmp	$39C6.W

;  3039 00df f00c           MOVE.W $00dff00c,D0
	
pl_game_v1
	PL_START
	PL_B	$04430,$60	; remove access to $BFD100
	PL_IFC2
	PL_PS	$4972,read_joystick_blue_jumps
    ; use read from joypad instead of re-read from CIAPRA
    PL_PSS  $0000491E,test_fires_joypad_controls,4
	;;PL_L	$491E,$70FF4E71		; blue button has no fire effect now
	PL_ELSE
	PL_PS	$4972,read_joystick_up_jumps
    ; use read from joypad instead of re-read from CIAPRA
    PL_PSS  $0000491E,test_fires_standard_controls,4
	PL_ENDIF
    PL_NOP  $00004946,6 ; no write to POTGO
	PL_IFC1X    0
	PL_NOP	OFFS_TRAINER_V1,4
	PL_ENDIF

    PL_IFC1X    1
    PL_NOP  $2385c,2
    PL_ENDIF
    
    ; don't limit trainer to 4 first levels
    PL_NOP  $06a3e,2
    PL_W    $07f3e,$20
    
    ; fix title music
    PL_PS   $2a2ea,set_dma_off
    PL_PS   $2a2cc,set_dma_on

    ; keyboard meta keys
    PL_P  $077a0,meta_keys
        
	PL_END
    
pl_game_v2
	PL_START
	PL_B	$05490,$60	; remove access to $BFD100
	PL_IFC2
	;;PL_L	$41DC,$70FF4E71		; blue button has no fire effect now (note: doesn't work!!)
	PL_PS	$4230,read_joystick_blue_jumps
    PL_PSS  $041dc,test_fires_joypad_controls,4
 	PL_ELSE
	PL_PS	$4230,read_joystick_up_jumps
    PL_PSS  $041dc,test_fires_standard_controls,4
	PL_ENDIF
    ; use read from joypad instead of re-read from CIAPRA
    PL_NOP  $04204,6 ; no write to POTGO
    
	PL_IFC1X    0
	PL_NOP	OFFS_TRAINER_V2,4
	PL_ENDIF
 
    ; always exit even if missing keys
    PL_IFC1X    1
    PL_NOP  $2354A,2
    PL_ENDIF
 
    ; don't limit trainer to 4 first levels
    PL_NOP  $06a66,2
    PL_W    $07f8c,$20
    
    ; fix title music: no need as this version has fixed music

    ; keyboard meta keys
    PL_P  $0781a,meta_keys
 
	PL_END

DEF_SET_DMA:MACRO
set_dma_\1:
    movem.l d0,-(a7)
    MOVE.W	(dma_\1_table,PC,D0.W),150(A0)
	move.w	#6,d0   ; should be enough
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	
    movem.l (a7)+,d0
    rts
    ENDM
    
    DEF_SET_DMA on
    DEF_SET_DMA off
    
dma_off_table:
	dc.l  $00010002
	dc.l  $00040008
dma_on_table:
	dc.l  $80018002
	dc.l  $80048008
    
CHECK_META_KEY:MACRO
    cmp.w   #$\1,d0
    eor.w   #4,CCR  ; flip Z
    beq.b   .no_\1_test
    
	move.l	previous_buttons_state(pc),d1
	move.l	buttons_state(pc),d0
    btst    #JPB_BTN_\2,d1
    eor.w   #4,CCR  ; flip Z
    beq.b   .out
    ; xxx wasn't pressed previously
    ; test if xxx just pressed
    btst    #JPB_BTN_\2,d0
    bra.b   .out
.no_\1_test
    ENDM
    
; < D0: raw keycode
; > Z set if keycode is pressed
meta_keys:
    ; original
  	MOVE.W	118(A4),D7		;: 3e2c0076
	JSR	0(A4,D7.W)		;077a4: 4eb47000
    bne.b   .pressed

    movem.l d0-d1,-(a7)

    ; HELP
    CHECK_META_KEY  5F,PLAY
    ; ESC
    CHECK_META_KEY  45,REVERSE
    
    nop
.out
    movem.l (a7)+,d0-d1
.pressed
	MOVEM.L	(A7)+,A4/A6		;077a8: 4cdf5000
	RTS				;077ac:

; inverted logic for ports: 0 means set !!!
; < D0: bit 14 cleared if fire 2 (blue) pressed
; < N cleared if fire pressed, set otherwise
test_fires_standard_controls
	movem.l	d2,-(a7)
    st.b   d1
    move.w  #$FFFF,d0
	move.l	buttons_state(pc),d2
	btst	#JPB_BTN_BLU,d2
    beq.b   .noblu
    bclr    #$E,d0      ; fire2
.noblu
	btst	#JPB_BTN_RED,d2
    beq.b   .nored
    ; clear N flag: fire pressed
    moveq.l #0,d2
    bra.b   .out
.nored
    moveq.l #-1,d2      ; set N
.out
	movem.l	(a7)+,d2
    rts

; inverted logic for ports: 0 means set !!!
; < D0: bit 14 cleared if fire 2 (blue) pressed
; < N cleared if fire pressed, set otherwise
test_fires_joypad_controls
	movem.l	d2,-(a7)
    st.b   d1
    move.w  #$FFFF,d0
	move.l	buttons_state(pc),d2
	btst	#JPB_BTN_RED,d2
    beq.b   .nored
    ; clear N flag: fire pressed
    moveq.l #0,d2
    bra.b   .out
.nored
    moveq.l #-1,d2      ; set N
.out
	movem.l	(a7)+,d2
    rts
    
read_joystick_blue_jumps
	bsr	read_joystick
	movem.l	d1/a0,-(a7)
	move.l	buttons_state(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
    ; fortunately this game doesn't have fly sections or ladders, so up
    ; is strictly the same as second button
	bclr	#8,d1
	btst	#9,d1
	beq.b	.noneed
	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	move.l	d1,d0
	movem.l	(a7)+,d1/a0
	RTS
	
read_joystick_up_jumps
	bsr	read_joystick
	move.w	$DFF00C,D0
	rts
	
read_joystick
	movem.l	d0/d1/a0,-(a7)
	lea	previous_buttons_state(pc),a0
    move.l  (a0),d1
	lea	buttons_state(pc),a0
    move.l  d1,(a0)
	bsr	_read_joystick_port_1
	move.l	d0,(a0)
    
    btst    #JPB_BTN_PLAY,d1
    bne.b   .prev_play_pressed
    btst    #JPB_BTN_PLAY,d0
    beq.b   .noplay
    btst    #JPB_BTN_PLAY,d1
    bne.b   .noplay
    ; play just pressed
    move.b  #1,$100
    move.b  #$5F,(a0)       ; pause: HELP keycode
    bra.b   .noplay
.prev_play_pressed
    btst    #JPB_BTN_PLAY,d0
    bne.b   .noplay
    ; play just released
    move.b  #$5F+$80,(a0)       ; pause: HELP keycode released
    move.b  #1,$101
.noplay    
	movem.l	(a7)+,d0/d1/a0
	RTS


    
    
FixAccessFault:
	exg.l	A6,D0
	lsl.l	#8,D0
	lsr.l	#8,D0
	exg.l	D0,A6
	move.w	(6,A6),D7
	rts

; keyboard quit for 68000 machines
MY_KBDIRQ
	MOVE.B	$BFEC01,D0
	
	MOVEM.L	D0/A0,-(A7)
	not.b	D0
	ror.b	#1,D0
	cmp.b	_keyexit(pc),D0

	beq	_exit

	MOVEM.L	(A7)+,D0/A0
	RTS

MY_EXTALLOC:
	sub.l	A1,A1
	sub.l	A0,A0
	moveq.l	#0,D0
	rts

MY_CHIPALLOC
	MOVEQ	#8,D0
	SWAP	D0
	RTS

; lowest hiscore to be saved: 10500
MY_WRITE
	MOVEM.L	D1/A0-A2,-(A7)
	move.l	trainer(pc),d0
	bne	.end			; don't save scores if trainer set

	move.l	A2,A1
	move.l	_resload(pc),a2
	lea	ScoresName(pc),A0
	MOVE.L	#SCORES_LEN,D0

	jsr	resload_SaveFile(a2)

	move.l	Version(pc),D0
	bne.b	.v2
	CLR.W	OFFS_35E6_V1
	bra.b	.end
.v2
	CLR.W	OFFS_35E6_V2
.end
	MOVEM.L	(A7)+,D1/A0-A2
	MOVEQ	#0,D0
	RTS


MY_LOADER
	MOVEM.L	D0-D2,-(A7)
	
	AND.L	#$FFFF,D3
	AND.L	#$FFFF,D5

	LEA	(A3),A0
	MOVE.L	DISK(PC),D0

	MOVE.L	D5,D1
	MULU	#BLOCK_SIZE,D1

	ADD.L	D1,A3

	MOVE.L	D3,D2
	MULU	#BLOCK_SIZE,D2

	bsr	do_read

	MOVEM.L	(A7)+,D0-D2
	RTS


PatchMain

	cmp.l	#$3E2E0006,$857C
	bne	.patched

	move.l	#$4EB800F0,$857C		; added by JOTD, probably just for version 1
	patch	$F0,FixAccessFault


	bsr	_flushcache
	
.patched
	rts

MY_LOADER2
	MOVEM.L	D1-A6,-(A7)

	bsr	PatchMain

	AND.L	#$FFFF,D3
	AND.L	#$FFFF,D4
	AND.L	#$FFFF,D5
	AND.L	#$FFFF,D6
	
	SUBQ.W	#1,D5

	LEA	COUNT(PC),A0
	ADDQ.L	#1,(A0)

	move.l	(A0),D0
	add.l	Version(pc),D0	; 1 less for V2

	CMP.L	#$21,D0
	BNE	.NO_CHANGE

	BSR	.CHANGE_DISK

.NO_CHANGE
	ADD.L	D4,D4

	TST.L	D3
	BEQ.S	.SIDE_OKAY

	ADDQ.L	#1,D4

.SIDE_OKAY
	MULU	#TRACK_SIZE,D4
	MULU	#BLOCK_SIZE,D5
	ADD.L	D5,D4

	MULU	#BLOCK_SIZE,D6

	LEA	(A2),A0
	MOVE.L	DISK(PC),D0
	
	MOVE.L	D6,D1
	MOVE.L	D4,D2
	
	bsr	do_read

	MOVEQ	#0,D0

	BSET	#3,OFFS_254D
	NOP
	NOP
		
	lea	OFFS_PROTPASS_V1,A0
	move.l	Version(pc),d3
	beq.b	.v1
	lea	OFFS_PROTPASS_V2,A0
.v1
	move.w	(A0),D2
	NEG.W	D2
	CMPI.W	#4,D2
	BCC.S	.NO_LOCK
	CLR.W	(A0)		; remove codewheel protection

.NO_LOCK

	move.l	Version(pc),d3
	MOVEM.L	(A7)+,D1-A6
	bne.b	.v2
	CLR.W	OFFS_35E6_V1
	bra.b	.end
.v2
	CLR.W	OFFS_35E6_V2
.end
	RTS

.CHANGE_DISK
	LEA	DISK(PC),A0
	MOVE.L	#1,(A0)
	
	RTS
	
COUNT
	DC.L	0
	
DISK
	DC.L	0

; D0: disk number 0 or 1
; D1: size to read
; D2: disk offset
; A0: destination
do_read	
	movem.l	D0-D1/A0-A2,-(a7)
	move.l	_resload(pc),a2
	movem.l	A0/D0-D2,-(A7)
    ; d1 read offset, unchanged
	exg.l	d0,d2	; offset <=> disk #: D0 is now read size
	addq.l	#1,d2   ; add one to disk number
	jsr	resload_DiskLoad(a2)
	movem.l	(A7)+,A0/D0-D2
	; we read disk only if not track 0 head 1 of disk 2
	tst.w	D0
	beq	.disk1		; disk 1 ? read
	cmp.l	#$1600,D2	; check if try to read track 0 head 1
	bne	.out
    
	; track 0 head 1 of disk 2: scores track
	movem.l	A0/D0/D1,-(A7)
	lea	ScoresName(pc),A0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	movem.l	(A7)+,A0/D0/D1
	beq.b	.out

	move.l	A0,A1       ; dest in A1
	lea	ScoresName(pc),A0
	jsr	resload_LoadFile(a2)
    bra.b   .out
.disk1
    cmp.l   #$40A00,D2
    bne.b   .out
    ; wait 2 seconds on the "cool coyote" screen
    move.l  #20,D0
    jsr (resload_Delay,a2)
.out

	movem.l	(a7)+,D0-D1/A0-A2


	rts
; ----------------------------

tag
    dc.l	WHDLTAG_CUSTOM1_GET
trainer
    dc.l	0
    dc.l	WHDLTAG_CUSTOM3_GET
trainer_start_level
    dc.l	0
	dc.l	0

; this boot code has been decrypted by JOTD using a custom copylock
; decoder (before Mr Larmer copylock decoder excellent program) running
; using action replay MKIII on a A500 moons ago.
; Once decoded I preciously saved it
; so the copylock is completely skipped by just loading this code
; (and I don't really remember how I pulled this either...)
FireBoot:
	INCBIN	"fire59f4.bin"
buttons_state
	dc.l	0
previous_buttons_state
    dc.l    0
Version:
	dc.l	0
TrainerAddress:
	dc.l	0
_resload
	dc.l	0
ScoresName:
	DC.B	"FireAndIce.high",0
	CNOP	0,4

	