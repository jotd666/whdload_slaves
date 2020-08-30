; Magic Pockets slave by JOTD
;
; history:
; - v2.0: first whdload release. 3 versions supported

; version description:
; - v1.10: NTSC US version with password protection and level codes
; - v1.00-1: PAL version with copylock at the end of level 1 (SPS)
; - v1.00-2: PAL version with copylock before level 1

; Assembled with Barfly & vasm

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	MagicPockets.slave
	ENDC

; game internals:
; A5 holds pointer to game structure. NTSC/US: A5 = $130A
; +$414.W: level ($171E.W)
; +$416.W: sub-level ($1720.W)
; +$41C.B: charge power ($1726.B): 0 -> $1F
;          score ($16F6.L) (plus backup score just afterwards)
; NTSC $00015814 write to dma audio
; some offsets:
; 
DBFD0_CODE = $51C8FFFE

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_DontCache
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
		dc.l	$0			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
;---
	dc.w	slv_config-_base
	
slv_config:
        dc.b    "C1:X:trainer infinite lives:0;"
        dc.b    "C1:X:trainer infinite credits:1;"
        dc.b    "C1:X:enable cheat keys (HELP/T/S/F/E/G):2;"
        dc.b    "C1:X:start with gold chalice (superpowered):3;"
        dc.b    "C1:X:always keep easy difficulty level:4;"
        dc.b    "C2:B:second button jumps;"
        dc.b    "C4:X:enable external level files:0;"
        dc.b    "C4:X:disable speed regulation:1;"
        dc.b    "C4:X:disable simplified level codes like 0011 0012...:2;"
        ; could not make start level as accurate as this. Only thing that works
        ; is to start at level 1 of a new world, but that's already good
;        dc.b    "C5:L:select start level:One,Two,Three,Four,Five,Race,Six,Seven,Eight,Ten,"
;		dc.b	"Eleven,Twelve,Beat the Gorilla,Thirteen,Fourteen,Fifteen,Sixteen,Seventeen,Eighteen,Find the treasure,"
;		dc.b	"Ninteen,Twenty,Twenty-one,Twenty-two,Twenty-three,Twenty-four,Twenty-five,Twenty-six,"
;		dc.b	"Teleport to get home;"
        dc.b    "C5:L:select start world:Cave,Jungle,Lake,Mountain;"
		dc.b	0
	
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	
DECL_VERSION:MACRO
	dc.b	"3.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


_name		dc.b	"Magic Pockets",0
_copy		dc.b	"1991 The Bitmap Brothers",0
_info		dc.b	"installed & fixed by JOTD",10,10
		dc.b	"Thanks to Galahad for help with copylock",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
		even
	include	ReadJoyButtons.s

_start	
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	bsr	_detect_controller_type
	
	;enable cache
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	;get tags
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;check & compute version

	bsr	_check_version


	lea	$7FF00,A7

;	MOVE.W	#$0100,$00DFF096
;	MOVE.W	#$0000,$00DFF180

	CLR.B	$1C.W
	clr.l	$80.W

; if expansion memory
;	MOVE.B	#$02,$0000001C
;	MOVE.L	_expmem(pc),$80.W

	lea	$80.W,A5	
	move.l	A5,A0		; buffer
	moveq.l	#1,D2		; disk 1
	MOVE.L	#$022A,D0	; offset
	MOVE.L	#$1400,d1	; length
	move.l	_version(pc),D3
	cmp.l	#3,D3
	bne.b	.skipv3
	add.l	#$10,D0		; shift for v3
.skipv3
	move.l	_version(pc),D3
	cmp.l	#2,D3
	bne.b	.skipv2
	addq.l	#4,D0		; shift for v2
.skipv2
	move.l	_resload(pc),A2
	jsr	resload_DiskLoad(a2)

	lea	_pl_boot_us(pc),A0
	move.l	_version(pc),D0
	cmp.l	#3,D0
	beq.b	.patch
	lea	_pl_boot_v1(pc),A0
	cmp.l	#1,D0
	beq.b	.patch
	lea	_pl_boot_v2(pc),A0
.patch
	sub.l	A1,A1
	jsr	(resload_Patch,A2)

	move.l	#CACRF_EnableI,D0
	move.l	D0,D1
	jsr	(resload_SetCACR,a2)

	jmp	4(A5)

_diskload:
	moveq.l	#0,D0
	bra	_robread


_check_version:
	lea	_version(pc),A3

	MOVE.L	_resload(PC),A2
	
	moveq.l	#1,D2		; disk 1
	move.l	#8,D1		; 8 bytes to read
	move.l	#$140,D0	; offset $13A
	lea	-8(A7),A7
	move.l	A7,A0
	jsr	(resload_DiskLoad,a2)
	move.l	A7,A0
	cmp.l	#'V1.1',(A0)	; v1.10
	bne.b	.notv3
	cmp.l	#'0  V',4(A0)	; v1.10
	bne.b	.notv3

	; v1.10 (konami/US) password protected (v3)

	move.l	#3,(A3)
	bra.b	.exit

.notv3
	cmp.l	#'ETS ',(A0)	; v1.00
	bne.b	.notv2

	; v1.00 copylock just before level 1

	move.l	#2,(A3)

	; set copylock end for v2

	lea	_copylock_address(pc),a3
	move.l	#$14CAC,(A3)

	bra.b	.exit

.notv2
	cmp.l	#'00  ',(A0)	; v1.00
	bne.b	.notv1

	; v1.00 copylock just after level 1

	move.l	#1,(A3)

	; set copylock end for v1

	lea	_copylock_address(pc),a3
	move.l	#$14DF6,(A3)

	bra.b	.exit
.notv1

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit
	lea	8(A7),A7
	rts

_decrunch:
	bsr	_mpdecrunch	; modified RNC decruncher
	movem.l	D0-A6,-(A7)

	move.l	_version(pc),D0
	cmp.l	#1,D0
	bne	.v2

    
	; ----- version 1 -----
	cmp.l	#$303900df,$00006C06
	bne.b	.nogame_v1
    

    lea pl_game_v1(pc),a0
    sub.l   a1,a1
    move.l  _resload(pc),a2
    jsr resload_Patch(a2)
    
.nogame_v1

	cmp.w	#$4E40,$3B28.W
	bne.b	.nopt3
	move.w	#$4E71,$3B28.W	; remove trap
.nopt3
	cmp.l	#DBFD0_CODE,$2EEFC
	bne	.nopdbf3

	patch	$4,_patch_dbf_d0
	move.l	#$4EB80004,$2EEFC
	move.l	#$4EB80004,$2EF14
.nopdbf3

	bra	.out
	; version 2
.v2


	cmp.w	#$4E40,$3B28.W
	bne.b	.nopt4
	move.w	#$4E71,$3B28.W	; remove trap
.nopt4
	cmp.l	#DBFD0_CODE,$2EEFC
	bne	.nopdbf4

	patch	$100,_patch_dbf_d0
	move.l	#$4EB80100,$2EEFC
	move.l	#$4EB80100,$2EF14
.nopdbf4
	cmp.w	#$1340,$6B9E.W
	bne	.skip2
    ; change variable address
	lea	var_shift(pc),a0
	move.w	#1044,(a0)
    
    lea pl_game_v2(pc),a0
    sub.l   a1,a1
    move.l  _resload(pc),a2
    jsr resload_Patch(a2)

.skip2
.out
	bsr	_flushcache
	movem.l	(A7)+,D0-D7/A0-A6	; stolen code
	rts


	; --------------------------------------
	; US - password codes - NTSC version
_end_decrunch_us:
	cmp.w	#$4E40,$3B42.W
	bne.b	.nopt3
	move.w	#$4E71,$3B42.W	; remove trap
.nopt3
	; *** Remove the password check (US version)


    ; intro dirty fixes
    
	cmp.l	#DBFD0_CODE,$2EF04
	bne	.nopdbf3

	patch	$4,_patch_dbf_d0
	move.l	#$4EB80004,$2EF04
	move.l	#$4EB80004,$2EF1C
.nopdbf3

	cmp.w	#$1340,$6BC4
	bne	.nogame_us
    

    lea pl_game_us(pc),a0
    sub.l   a1,a1
    move.l  _resload(pc),a2
    jsr resload_Patch(a2)
    


	
.nogame_us
	bsr	_flushcache
	movem.l	(A7)+,D0-D7/A0-A6	; stolen code
	rts
    
level_table
	dc.b	1,1
;	dc.b	1,2
;	dc.b	1,3
;	dc.b	1,4
;	dc.b	1,5
;	dc.b	1,6
	dc.b	2,1
;	dc.b	2,2
;	dc.b	2,3
;	dc.b	2,4
;	dc.b	2,5
;	dc.b	2,6
;	dc.b	2,7
	dc.b	3,1
;	dc.b	3,2
;	dc.b	3,3
;	dc.b	3,4
;	dc.b	3,5
;	dc.b	3,6
;	dc.b	3,7
;	dc.b	3,8
	dc.b	4,1
;	dc.b	4,2
;	dc.b	4,3
;	dc.b	4,4
;	dc.b	4,5
;	dc.b	4,6
;	dc.b	4,7
;	dc.b	4,8
;	dc.b	4,9
	
pl_game_v1:
    PL_START
    
    PL_IFC2
    PL_PS   $6BF0,read_fire
	PL_PS	$00006C06,read_joy_directions
    PL_ENDIF
    
    ; crack
    PL_P    $14D4C,_copylock

    PL_IFC1X    0
     ; no lives subtract. 0 lives = $7B... address: $1741
    PL_NOP  $9b2e,4 ; flying
    PL_NOP  $E928,4 ; walking
    PL_ENDIF
    
    PL_IFC1X    1
    PL_NOP  $00009B94,8 ; no credit subtract  
    PL_ENDIF
    
    PL_IFC1X    2
	PL_PSS	$6BDA,_levelskip_v1,6
    PL_ELSE
    PL_PSS  $6BDA,_kb_common,6
    PL_ENDIF

    PL_IFC1X    3
    ; set flag to one instead of just noping the test
    ; makes difficulty harder, like the original game does
    ; (unless CUSTOM1 bit 4 is set see below)
    PL_PS   $E494,set_gold_chalice_v1
    PL_ENDIF
    
    PL_IFC1X    4
    ; easy difficulty regardless of gold chalice
    ; or succeeded in warping from level 4 to level 1
    PL_NOP  $C8CA,2
    PL_NOP  $C8D0,2
    PL_ENDIF
    
    ; fix audio
    PL_PS   $0001575A,fix_dma_write
    PL_PS   $00015804,fix_dma_write
    PL_PS   $00015a34,fix_dma_write
    PL_PS   $0001568c,fix_dma_write
    
    ; fix access fault when entering a code when the game has been completed (doesn't work,
    ; game looks corrupt at this point, with trashed gfx in the end screen)
    PL_PS   $0ccc4,fix_access_fault
    
    ; try to regulate the game speed
    PL_IFC4X    1    
    PL_ELSE
    PL_PSS  $43C2,regulate_speed,2
    PL_ENDIF
    
    PL_PSS  $4C18,pause,2
    PL_PSS  $4C48,unpause,$58-$4C
    
    PL_IFC5
    PL_PS   $0430c,load_current_level_v1
    PL_ENDIF
    
    PL_END

pl_game_v2:
    PL_START
    
    PL_IFC2
    PL_PS   $06bb4,read_fire
	PL_PS	$06bca,read_joy_directions
    PL_ENDIF
    
    ; crack
    PL_P    $14c0c,_copylock

    PL_IFC1X    0
     ; no lives subtract. 0 lives = $7B...
    PL_NOP  $09acc,4 ; flying
    PL_NOP  $0e8d4,4 ; walking
    PL_ENDIF
    
    PL_IFC1X    1
    PL_NOP  $09b32,6 ; no credit subtract: note shorter nop sequence than v1  
    PL_ENDIF
    
    PL_IFC1X    2
	PL_PSS	$06b9e,_levelskip_v2,6
    PL_ELSE
    PL_PSS  $06b9e,_kb_common,6
    PL_ENDIF

    PL_IFC1X    3
    ; set flag to one instead of just noping the test
    ; makes difficulty harder, like the original game does
    ; (unless CUSTOM1 bit 4 is set see below)
    PL_PS   $0e440,set_gold_chalice_v2
    PL_ENDIF
    
    PL_IFC1X    4
    ; easy difficulty regardless of gold chalice
    ; or succeeded in warping from level 4 to level 1
    PL_NOP  $0c856,2
    PL_NOP  $0c85c,2
    PL_ENDIF


    ; fix audio
    PL_PS   $15542,fix_dma_write
    PL_PS   $15610,fix_dma_write
    PL_PS   $156ba,fix_dma_write
    PL_PS   $158ea,fix_dma_write
    
    ; fix access fault when the game has been completed
    PL_PS   $0cc50,fix_access_fault

    ; try to regulate the game speed
    PL_IFC4X    1    
    PL_ELSE
    PL_PSS  $043c0,regulate_speed,2
    PL_ENDIF
    
    PL_PSS  $04c60,pause,2
    PL_PSS  $04c8c,unpause,$58-$4C

    PL_IFC5
    PL_PS   $04304,load_current_level_v2
    PL_ENDIF

    PL_END
    
pl_game_us:
    PL_START
    
    PL_IFC2
    PL_PS   $06bda,read_fire
	PL_PS	$06bf0,read_joy_directions
    PL_ENDIF
    
    PL_IFC1X    0
     ; no lives subtract. 0 lives = $7B...
    PL_NOP  $09b00,4 ; flying
    PL_NOP  $0ecf2,4 ; walking
    PL_ENDIF
    
    PL_IFC1X    1
    PL_NOP  $09b66,8 ; no credit subtract  
    PL_ENDIF
    
    PL_IFC1X    2
	PL_PSS	$06bc4,_levelskip_us,6
    PL_ELSE
    PL_PSS  $06bc4,_kb_common,6
    PL_ENDIF

    PL_IFC1X    3
    ; set flag to one instead of just noping the test
    ; makes difficulty harder, like the original game does
    ; (unless CUSTOM1 bit 4 is set see below)
    PL_PS   $0e85a,set_gold_chalice_us
    PL_ENDIF
    
    PL_IFC1X    4
    ; easy difficulty regardless of gold chalice
    ; or succeeded in warping from level 4 to level 1
    PL_NOP  $0c956,2
    PL_NOP  $0c95c,2
    PL_ENDIF


    ; fix audio
    PL_PS   $15746,fix_dma_write
    PL_PS   $15814,fix_dma_write
    PL_PS   $158be,fix_dma_write
    PL_PS   $15aee,fix_dma_write
    
    ; force password entered
    ; set $1758.W to 1 to make believe we already checked the protection OK   
    PL_B    $0525c+3,1
    
    ; fix access fault when entering a code when the game has been completed (doesn't work,
    ; game looks corrupt at this point, with trashed gfx in the end screen)
    PL_PS   $0cddc,fix_access_fault

    ; try to regulate the game speed
    PL_IFC4X    1    
    PL_ELSE
    PL_PSS  $043ca,regulate_speed,2
    PL_ENDIF

    ; try to regulate the game speed
    PL_IFC4X    2
    PL_ELSE
    PL_DATA $04fb6,120
    dc.b    "001100120013001400150016002100220023002400250026002700310032003300340035003600370038004100420043004400450046004700480049"    
    PL_ENDIF

    
    PL_PSS  $4C12,pause,2
    PL_PSS  $4c58,unpause,$58-$4C
    ; reinstate P for pause, Q for quit (also makes pause/unpause patch common)
    PL_B    $04c25,$50  ; P
    PL_B    $04c35,$51  ; Q
    PL_B    $04c55,$19  ; P raw

    ; word/byte move fix when increasing difficulty level:
    ; maybe it's intended to make the game easier when completing
    ; warping from 4 to 1... I'm leaving it as is, probably not
    ; reached anyway (it's in the "enter code" section)
    ; PL_W    $04ef8,$1b7c
    
    PL_IFC5
    PL_PS   $04314,load_current_level_us
    PL_ENDIF
    
    PL_END

set_gold_chalice_v1
    move.b  #1,1070(A5)
    rts
set_gold_chalice_v2
    move.b  #1,1062(A5)
    rts
set_gold_chalice_us
    move.b  #1,1072(A5)
    rts
    
load_current_level_v1:
    movem.l d0/a0,-(a7)
	move.l	_start_level(pc),d0
	lea	level_table(pc),a0
	add.l	d0,d0
	move.w	(a0,d0),d0
	move.b	d0,1047(A5)
    move.w  #1,1046(A5)     ; level 1
	lsr.w	#8,d0
	move.b	d0,1045(A5)     ; world

    bsr level_load_v1

.no_start_level
    movem.l (a7)+,d0/a0
    
    ;;add.l   #$04352-$04312,(a7)
    rts

level_load_v1:
    cmp.w   #1,1044(a5)
    bne.b   .level2
	JSR	$14760
	MOVE.W	#$3162,$4bfe
	BRA.W	.LAB_006E		;04b6a: 60000060
.level2:
    cmp.w   #2,1044(a5)
    bne.b   .level3
	JSR	$14890
	MOVE.W	#$3262,$4bfe
	BRA.W	.LAB_006E		;04b88: 60000042
.level3:
    cmp.w   #3,1044(a5)
    bne.b   .level4
	JSR	$149ca
	JSR	$05e00		;04b9e: 61001620
	MOVE.W	#$3361,$4bfe
	BRA.W	.LAB_006E		;04baa: 60000020
.level4:
	JSR	$14b2c
	MOVE.W	#$3461,$4bfe
.LAB_006E:
	MOVE.B	#$ff,$4458
	MOVEA.L	#$ffffffff,A0		;04bd2: 207cffffffff
	JSR	$f688
	MOVE.B	#$00,1066(A5)		;04bde: 1b7c0000042c
	MOVE.B	#$00,980(A5)		;04be4: 1b7c000003d4
    RTS
    
    
load_current_level_v2:
    movem.l d0/a0,-(a7)
	move.l	_start_level(pc),d0
	lea	level_table(pc),a0
	add.l	d0,d0
	move.w	(a0,d0),d0
	move.b	d0,1039(A5)
    move.w  #1,1038(A5)     ; level 1
	lsr.w	#8,d0
	move.b	d0,1037(A5)     ; world

    bsr level_load_v2

.no_start_level
    movem.l (a7)+,d0/a0
    
    ;;add.l   #$04352-$04312,(a7)
    rts

level_load_v2:
    cmp.w   #1,1036(a5)
    bne.b   .level2
	JSR	$14674
	MOVE.W	#$3162,$4c46
	BRA.W	.LAB_006E		;04b6a: 60000060
.level2:
    cmp.w   #2,1036(a5)
    bne.b   .level3
	JSR	$14790
	MOVE.W	#$3262,$4c46
	BRA.W	.LAB_006E		;04b88: 60000042
.level3:
    cmp.w   #3,1036(a5)
    bne.b   .level4
	JSR	$148c6
	JSR	$05de6		;04b9e: 61001620
	MOVE.W	#$3361,$4c46
	BRA.W	.LAB_006E		;04baa: 60000020
.level4:
	JSR	$14a20
	MOVE.W	#$3461,$4c46
.LAB_006E:
	MOVE.B	#$ff,$4456
	MOVEA.L	#$ffffffff,A0		;04bd2: 207cffffffff
	JSR	$f616
	MOVE.B	#$00,1058(A5)		;04bde: 1b7c0000042c
	MOVE.B	#$00,980(A5)		;04be4: 1b7c000003d4
    RTS
        
load_current_level_us:
    movem.l d0/a0,-(a7)
	move.l	_start_level(pc),d0
	;;beq.b	.no_start_level
	lea	level_table(pc),a0
	add.l	d0,d0
	move.w	(a0,d0),d0
	move.b	d0,1047(A5)
    move.w  #1,1046(A5)     ; level 1
	lsr.w	#8,d0
	move.b	d0,1045(A5)     ; world

    bsr level_load_us
	;00004CCA 3b7c 0001 0414           MOVE.W #$0001,(A5,$0414) == $0000171e [0001]
	;00004CD0 3b7c 0001 0416           MOVE.W #$0001,(A5,$0416) == $00001720 [0001]
	;MOVE.W	#$0001,current_level_1046(A5)		;0524a: 3b7c00010416
	;MOVE.W	#$0001,current_world_1044(A5)		;05250: 3b7c00010414
.no_start_level
    movem.l (a7)+,d0/a0
    
    ;addq.l  #4,a7
    ;move.w  1044(A5),d7
    ;move.w  1046(A5),d6
    ;sub.w   #1,d6    
    ;jsr $0528a
    ;jmp $046e8
    ;;add.l   #$0435a-$0431a,(a7)
    rts

level_load_us:
    cmp.w   #1,1044(a5)
    bne.b   .level2
	JSR	$14a46
	MOVE.W	#$3162,$4bf8
	BRA.W	.LAB_006E		;04b6a: 60000060
.level2:
    cmp.w   #2,1044(a5)
    bne.b   .level3
	JSR	$14b92
	MOVE.W	#$3262,$4bf8
	BRA.W	.LAB_006E		;04b88: 60000042
.level3:
    cmp.w   #3,1044(a5)
    bne.b   .level4
	JSR	$14cb4
	JSR	$061c0		;04b9e: 61001620
	MOVE.W	#$3361,$4bf8
	BRA.W	.LAB_006E		;04baa: 60000020
.level4:
	JSR	$14dfe
	MOVE.W	#$3461,$4bf8
.LAB_006E:
	MOVE.B	#$ff,$4460
	MOVEA.L	#$ffffffff,A0		;04bd2: 207cffffffff
	JSR	$fa22
	MOVE.B	#$00,1068(A5)		;04bde: 1b7c0000042c
	MOVE.B	#$00,980(A5)		;04be4: 1b7c000003d4
    RTS

current_rawkey_981 = 981

pause:
    movem.l d0,-(a7)
    move.l  _current_buttons_state(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .p_pressed
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .q_not_pressed
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .q_not_pressed
    btst    #JPB_BTN_YEL,d0
    bne _quit        ; quit to wb
    bra.b   .q_pressed
.q_not_pressed
    movem.l (a7)+,d0

	MOVE.B	current_rawkey_981(A5),D7		;04c18: 1e2d03d5
	BPL.S	.pressed		;04c1c: 6a02
    addq.l  #4,a7
.pressed
	RTS				;04c1e: 4e75
.p_pressed
    move.b  #$19,d7
    movem.l (a7)+,d0
    rts
.q_pressed
    move.b  #$10,d7
    movem.l (a7)+,d0
    rts
    
unpause:
    bsr wait_play_released

.wait
	MOVE.B	973(A5),D7		;04c48: 1e2d03cd
	ANDI.B	#$01,D7			;04c4c: 02070001
	BNE.W	.out		;04c50: 66000008
    move.l  _current_buttons_state(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .out
	MOVE.B	current_rawkey_981(A5),D7		;04c54: 1e2d03d5
	BEQ.S	.wait		;04c58: 67ee
.out
    bsr wait_play_released
    rts

wait_play_released
    movem.l d0,-(a7)
.play_pressed
    move.l  _current_buttons_state(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .play_pressed
    movem.l (a7)+,d0
    rts
    
wait_vbl:
    movem.l d0/a0,-(a7)
	; wait for VBL
	lea	$DFF000,a0
	move.w	#$7FFF,intreq(a0)
.wait
	move.w	intreqr(a0),d0
	btst	#5,d0
	beq.b	.wait
    movem.l (a7)+,d0/a0
	rts
    
regulate_speed:
    movem.l d0/a0,-(a7)
    lea speed_counter(pc),a0
    eor.w   #1,(a0)   ; alternatively wait more
.wait
    move.w  42(a5),d0
	CMP.W	(a0),d0		;043c2: 0c6d0000002a
	BLS.S	.wait		;043c8: 63f8
    movem.l (a7)+,d0/a0
    rts
    
speed_counter
    dc.w    0
        
fix_access_fault:
    cmp.w   #$7FFF,d1
    bcc   _quit     ; game is corrupt, just quit instead of access fault
  	ADDA.W	D1,A4			;: d8c1
	MOVE.W	(A4),24(A0)		;0cdde: 31540018
    rts
   

fix_dma_write:
    MOVE.W (2,A4),(A5,$0096)
soundtracker_loop
	move.w  d0,-(a7)
	move.w	#4,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts
 
read_fire
	bsr	_update_buttons_status
	movem.l	d1,-(a7)
    move.l  _current_buttons_state(pc),d1
    btst    #JPB_BTN_RED,d1
    movem.l (a7)+,d1
    bne.b   .pressed
    move.b  #$C0,d0
    rts
.pressed
    clr.b   d0
    rts
    
read_joy_directions:
	movem.l	d1-d2/a0,-(a7)
    move.l  _current_buttons_state(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
	move.w	var_shift(pc),d2
    
	; is weapon charging in pocket?
	tst.b	(a5,d2.w)        ; ($41C,a5) (1 & 3: $1726.W)
	bne.b	.no_blue
	; has diving helmet while in water?
	cmp.b	#$41,(7,a5,d2.w)   ; ($423,a5)
	beq.b	.no_blue
	; has bubble gum?
	cmp.b	#$21,(7,a5,d2.w)    ; ($423,a5)
	beq.b	.no_blue
	

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
	movem.l	(a7)+,d1-d2/a0
	RTS
	
_levelskip_v2:
	cmp.b	#$5F,D0		; HELP
	bne	.1
	move.b	#$47,$1D75.W
.1
	cmp.b	#20,D0	; 'T'
	bne.b	.2
	; bonus: coin
	move.w	#$090A,$178C.W	; next: gold star / coin
	move.b	#1,$1784.W	; 1 silver star
.2
	cmp.b	#33,D0	; 'S'
	bne.b	.2_1
	; bonus: coin
	move.w	#$090A,$178C.W	; next: gold star / coin
    cmp.b   #6,$1784.W
    bcc.b   .2_1
	add.b	#1,$1784.W	; 1 more silver star
.2_1

	bra	_kb_cheat_common      ; in version 2 fly/toy is not working... didn't try too hard

_levelskip_v1:
	cmp.b	#$5F,D0		; HELP
	bne	.1
	move.b	#$47,$1D7D.W
.1
	cmp.b	#20,D0	; 'T'
	bne.b	.2
	; bonus: coin
	move.w	#$090A,$1794.W	; next: gold star / coin
	move.b	#1,$178C.W	; 1 silver star
.2
	cmp.b	#33,D0	; 'S'
	bne.b	.2_1
	; bonus: coin
	move.w	#$090A,$1794.W	; next: gold star / coin
    cmp.b   #6,$178C.W
    bcc.b   .2_1
	add.b	#1,$178C.W	; 1 more silver star
.2_1

	bra	_kb_cheat_common

_patch_dbf_d0:
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0

; < D0: numbers of vertical positions to wait
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_levelskip_us:
	cmp.b	#$5F,D0		; help
	bne	.1

	move.b	#$47,$1D8B.W
.1
	cmp.b	#20,D0	; 'T'
	bne.b	.2
	; bonus: coin
	move.w	#$090A,$17A2.W	; next: gold star / coin
	move.b	#1,$179A.W	; 1 silver star
.2
	cmp.b	#33,D0	; 'S'
	bne.b	.2_1
	; bonus: coin
	move.w	#$090A,$17A2.W	; next: gold star / coin
    cmp.b   #6,$179A.W
    bcc.b   .2_1
	add.b	#1,$179A.W	; 1 more silver star
.2_1
	cmp.b	#66,D0	; 'TAB'
	bne.b	.3
	; toggle "sprites" on/off
	movem.l	D0-D1/A0-A1,-(A7)
	move.l	#$37440058,D0
	move.l	#$6002DEAD,D1
	lea	$1257A,a0
	cmp.l	(A0),D0
	beq.b	.nswp
	exg.l	D1,D0
.nswp
	lea	$127A0,A1
	bsr	_hexreplace
	bsr	_flushcache
	movem.l	(A7)+,D0-D1/A0-A1
.3
_kb_cheat_common
    movem.l d1-d2/a0/a1,-(a7)
    move.w	var_shift(pc),d2
    tst.b   (8,a5,d2.w)
    bne.b   .notoy  ; don't fly if toy or such
    cmp.b   #$23,d0 ; F
    bne.b   .nofly
    move.b  #$21,(7,a5,d2.w)   ; bubble gum
.nofly

    cmp.b   #$12,d0     ; E
    bne.b   .notoy
    lea toy_table(pc),a1
    move.w  1044(A5),d1
    move.b  -1(a1,d1.w),d1
    beq.b   .notoy
    move.b  d1,(7,a5,d2.w)   ; bike, bouncing ball
.notoy
    cmp.b   #$24,d0     ; G
    bne.b   .noscore
    add.l   #5000,(1004,A5)     ; adds 5000 points to score
.noscore
   movem.l (a7)+,d1-d2/a0/a1
_kb_common:
.lp
	btst	#0,$D00(A0)
	beq	.lp

    
	; check quitkey, in order to be able to quit
	; even if NOVBRMOVE is set

	cmp.b	_keyexit(pc),D0
	beq _quit

	move.b	D0,$3D5(A1)
	rts

; only works for bike & bouncing ball
toy_table:
    dc.b    $15,0,0,$43

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

_hexreplace:
;	movem.l	A0-A1/D0-D1,-(A7)
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
;	movem.l	(A7)+,A0-A1/D0-D1
	rts

; ----------------------------------------------


; Rob Northen track loading routine
; < A0: buffer
; < D0: disk number
; < D1: sector offset (*$200)
; < D2: sector length (*$200)
; < D3: command (ignored)
; > D0: 0 if ok (which is all the time :))

_robread:
	movem.l	d1-d3/a0-a2,-(A7)
	and.b	#$FF,D3
	bne.b	.exit

	move.l	d0,d3		; disk number stored
	
	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.exit		; length=0: out

	move.l	D1,D0
	ext.l	d0
	lsl.l	#7,d0			;diskoffset
	lsl.l	#2,d0

	move.l	_misc_options(pc),d1
    btst    #0,d1
	beq.b	.readdisk
    ; custom levels
	move.l	_version(pc),d1
	cmp.l	#3,d1
	bne.b	.readdisk	; only supported for US right now
	; check if offset matches a level file
	lea	file_table(pc),a2
.loop
	move.l	(a2)+,d1
	beq.b	.readdisk	; not found
	cmp.l	d0,d1		; compare offset
	beq.b	.found
	addq.l	#4,A2
	bra.b	.loop
.found
	move.l	a0,a1	; destination address
	move.l	(A2),A0	; filename
	lea	file_table(pc),a2
	add.l	a2,a0	; make address absolute
	MOVE.L	_resload(PC),A2
	jsr	(resload_LoadFile,a2)
	
	bra.b	.exit
.readdisk
	move.l	D2,D1			;len to read
	ext.l	d1
	lsl.l	#7,d1
	lsl.l	#2,d1

	move.l	D3,D2
	addq.l	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)
.exit
	movem.l	(A7)+,d1-d3/a0-a2
	moveq.l	#0,D0
	rts

file_table:
	dc.l	$52c00,.filename_0-file_table,$55000,.filename_1-file_table
	dc.l	$d7400,.filename_2-file_table,$d5400,.filename_3-file_table,0
.filename_0:
	dc.b	'LEVEL1A.PAP',0
.filename_1:
	dc.b	'LEVEL1B.PAP',0
.filename_2:
	dc.b	'NEW1.PIN',0
.filename_3:
	dc.b	'PCMAP.PAP',0
	even
	
_flushcache:
	move.l	A2,-(A7)
	move.l	(_resload,pc),a2
	jsr	(resload_FlushCache,a2)
	move.l	(A7)+,A2
	rts

; ----------------------------------------------
; ### PATCHLISTS
; ----------------------------------------------

_pl_boot_v1:
		PL_START
		PL_P	$FA,_decrunch
		PL_P	$25C,_diskload
		PL_END
_pl_boot_v2:
		PL_START
		PL_P	$FA,_decrunch
		PL_P	$258,_diskload
		PL_L	$C4,$7FFE0	; change stack pointer
		PL_END
_pl_boot_us:
		PL_START
		; decrunch is in $100/$108
		PL_P	$220,_end_decrunch_us	; end of decrunch
		PL_P	$318,_diskload	; rob read
		PL_L	$C8,$7FFE0	; change stack pointer
		PL_END

; ----------------------------------------------------------------------

_decrunch_data:
	ds.b	$200,0
	even

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_cheat_keys	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_second_button_jumps	dc.l	0
		dc.l	WHDLTAG_CUSTOM4_GET
_misc_options	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_start_level	dc.l	0       ; not active
		dc.l	0

_resload:
	dc.l	0
_version:
	dc.l	0

; modified RNC routine

_mpdecrunch:
	incbin	"mpdec.bin"
	cnop	0,4


COPYLOCK_KEY = $AE3B9CE3

_copylock:
	move.l	#$161F,D3

; this is the decryption of the RNC buffer with the copylock key
; I don't know when the copylock does it. I found it by a memory compare...

	move.l	#COPYLOCK_KEY,D0
	move.l	8(A7),A0
	move.l	8(A0),D1
	eor.l	D0,D1		; crunched len
	move.l	A0,A1
	add.l	D1,A1
	lea	16(a1),A1
.loop
	move.l	(A0),D1
	eor.l	D0,D1
	move.l	D1,(A0)+
	cmp.l	A0,A1
	bcc.b	.loop

	; save key

	move.l	D0,$60.W

	lea	$10(a7),a7

	move.l	_copylock_address(pc),A0
	add.l	D0,(A0)              ;THIRD CHECK TO CHECK PROTECTION WAS RUN: thx Galahad!!
	rts
; variable default address for version 1 & 3
var_shift:
	dc.w	1052        ; $41C

    
_copylock_address
	dc.l	0
