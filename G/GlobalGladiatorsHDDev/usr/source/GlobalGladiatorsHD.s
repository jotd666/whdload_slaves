		INCDIR	"Include:"
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
	IFD BARFLY
	OUTPUT	GlobalGladiators.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC



	IFD	BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.5"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$80000
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base
		dc.w    0     ; kickstart name
		dc.l    $0         ; kicksize
		dc.w    $0         ; kickcrc
		dc.w	slv_config-_base

slv_config:
		dc.b    "C1:X:trainer infinite lives:0;"
		dc.b    "C2:B:second button jumps;"
		dc.b	0
        
_name		dc.b	"Global Gladiators",0
_copy		dc.b	"1993 Virgin",0
_info		dc.b	"installed & fixed by Bored Seal & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	10,0
	even
    
IGNORE_JOY_DIRECTIONS
    include    ReadJoyPad.s
    
;-----------------
_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
		move.l	a0,a2
    
        bsr _detect_controller_types        
        
		move.l	#$400,d0
		move.l	#$1200,d1
		moveq	#1,d2			;disk number
		lea	$50000,a0
		move.l	a0,a5
		bsr	Load

;		move.l	#$80000,-4(a5)	;set chip expansion memory
		move.l	_expmem(pc),-4(a5)	;set expansion memory

		lea	pl_boot_50000(pc),a0
		move.l	a5,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		jmp	(a5)

jump_7ffc0
    ; memory copy relocated in fast mem
    ; should be slightly faster
.copy
    MOVE.B -(A1),-(A3)
    DBF D0,.copy
    ADDQ.W #$01,D0
    SUBQ.L #$01,D0
    BCC.B .copy
    
    movem.l d0-d1/a0-a2,-(a7)
    lea $500.W,a1
    lea pl_boot_500(pc),a0
    move.l	_resload(pc),a2
    jsr	resload_Patch(a2)
    movem.l (a7)+,d0-d1/a0-a2     
     
    JMP $500    
 

Patch
        jsr	$122c.W
        
		movem.l	a0-a2/d0-d1,-(sp)
		lea	pl_game(pc),a0
		suba.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(sp)+,a0-a2/d0-d1
		
		jmp	$1500.W

pl_boot_50000		
        PL_START
		PL_W	$30,$601e	;remove disk access
        PL_P    $90,jump_7ffc0
        PL_NOP  $6C,4   ; no need to copy tiny reloc code now
        
		PL_END

pl_boot_500
        PL_START        
		PL_P	$C0,Loader	;loader for Virgin games
		PL_PSS	$D02,Patch,2
        PL_P    $1052-$500,run_length_encoder
		PL_END
        
pl_game		PL_START
        PL_PS   $0ba74,vbl_hook
		PL_PS	$772e,AccessFault	;24bit access fix
		PL_P	$2d42,Copylock		;skip RNC copylock
		PL_W	$a6b4,$6002		;fix memory routine
		PL_AW	$1be6,$200		;bplcon0 access fixes
		PL_AW	$1ca4,$200
		PL_AW	$30e1a,$200
		PL_AW	$31922,$200
		PL_P	$9BB0,mask_int_6
		PL_PA	$1CEC,mask_int_6
		PL_PA	$1CF4,mask_int_6
		PL_PSS	$6F5E,kb_routine,2
        ;;PL_PS   $0a2f0,dma_wait
        
        PL_PSS  $0713c,read_fire_1,2
        
        PL_IFC1X    0
        PL_NOP  $6e4a,4
        PL_ENDIF
        PL_IFC2
        PL_PS   $0714a,read_joydat
        PL_ENDIF
		PL_END

read_fire_1
    move.l  d0,-(a7)
    move.l  prev_buttons_state(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts
    
read_joydat
	move.w	$DFF00C,D0
    cmp.l   #$44A0,(8,A7)
    beq.b   .skip   ; menu
	movem.l	d1/a0,-(a7)
	move.l	prev_buttons_state(pc),d1

	;;beq.b	.no_blue
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,D0
	btst	#9,D0
	beq.b	.noneed
	bset	#8,D0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,D0
	btst	#9,D0
	bne.b	.no_blue
	bset	#8,D0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	movem.l	(a7)+,d1/a0
.skip
	RTS
    
dma_wait:
	MOVE.W	8(A0),150(A6)		;: 3d6800080096
	move.w  d0,-(a7)
	move.w	#7,d0   ; make it 7 if still issues
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

rawkey = $11C

;key table
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d2
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    bset    #7,d3
.pressed_\1
    move.b  d3,rawkey(A5)
    jsr $6FB6   ; original keyboard handler
.nochange_\1
    ENDM
    
vbl_hook:
    ; read controls one out of two vblanks (40ms)
    lea .flipflop(pc),a6
    eor.w   #1,(a6)
    beq.b   .skip
    movem.l d0-d3/a0,-(a7)
    lea prev_buttons_state(pc),a0
    ;;move.l rawkey_table_address(pc),a1
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_read_joystick
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d2 to get what has changed quickly
    move.l  d0,d2
    eor.l   d1,d2
    beq.b   .nochange   ; cheap-o test just in case no input has changed
    clr.w   d3
    ; d2 bears changed bits (buttons pressed/released)

    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .nofwd
    btst    #JPB_BTN_YEL,d0
    bne.b   _quit
.nofwd
    TEST_BUTTON FORWARD,$45     ; esc
.noquit
    btst    #JPB_BTN_PLAY,d2
    beq.b   .nochange_PLAY
    btst    #JPB_BTN_PLAY,d0
    beq.b   .nochange_PLAY    
    ; pressed: toggle pause
    eor.w   #$FFFF,1048(A5)
.nochange_PLAY

.nochange    
    movem.l (a7)+,d0-d3/a0
    
.skip
    LEA	_custom,A6
    rts
.flipflop
    dc.w    0
prev_buttons_state
        dc.l    0

    
        
kb_routine:
	not.b	d0
	move.b	d0,(rawkey,A5)	; stolen
	cmp.b	_keyexit(pc),d0
	beq.b	_quit
    rts
    
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
    rts
		
; avoids crashes on CD32
mask_int_6
	move.w	#$2000,$DFF09C
	btst.b	#0,$BFDD00		; acknowledge CIA-B Timer A interrupt
	RTE
Copylock	move.l	#$e7f4fd52,d5
		move.l	d5,$f4
		jmp	$360e.W

AccessFault	lea	-8(a0),a0
		move.l	(a0),d0
		and.l	#$00ffffff,d0
		rts

Loader		MOVEM.L	D0-D7/A0-A6,-(SP)
		MOVEQ	#0,D0
		MOVE.W	D1,D0
		MULU.W	#$200,D0
		MOVEQ	#0,D1
		MOVE.W	D2,D1
		MULU.W	#$200,D1
		MOVEQ	#0,D2
		MOVE.B	D4,D2
		CMP.B	#3,D2
		BNE.B	LoadData
		MOVEQ	#2,D2
LoadData	BSR.W	Load
		BTST	#4,D3
		BEQ.B	GoBack
		MOVEA.L	A0,A1
		BTST	#5,D3		;this proceeds file with "RLE" header
		BEQ.B	ProcessRLE
		MOVEA.L	A2,A1
ProcessRLE	bsr run_length_encoder		; decrunch?
GoBack		MOVEM.L	(SP)+,D0-D7/A0-A6
		MOVEQ	#0,D0
		RTS

Load		MOVEM.L	D0/D1/A0-A2,-(SP)
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		MOVEM.L	(SP)+,D0/D1/A0-A2
		RTS

run_length_encoder:
	CMPI.L	#$524c4500,(A0)		;1052: 0c90524c4500
	BNE.W	LAB_0082		;1058: 6600008a
	MOVEA.L	A1,A4			;105c: 2849
	ADDA.L	4(A0),A1		;105e: d3e80004
	MOVEA.L	A0,A2			;1062: 2448
	ADDA.L	8(A0),A2		;1064: d5e80008
	MOVE.L	A2,D0			;1068: 200a
	ADDQ.L	#1,D0			;106a: 5280
	ANDI.B	#$fe,D0			;106c: 020000fe
	MOVEA.L	D0,A3			;1070: 2640
	MOVEM.L	(A3),D0-D3		;1072: 4cd3000f
	MOVEM.L	D0-D3,-(A7)		;1076: 48e7f000
	MOVEM.L	16(A3),D0-D3		;107a: 4ceb000f0010
	MOVEM.L	D0-D3,-(A7)		;1080: 48e7f000
	MOVEM.L	32(A3),D0-D3		;1084: 4ceb000f0020
	MOVEM.L	D0-D3,-(A7)		;108a: 48e7f000
	MOVEM.L	48(A3),D0-D3		;108e: 4ceb000f0030
	MOVEM.L	D0-D3,-(A7)		;1094: 48e7f000
LAB_007D:
	MOVE.B	-(A2),D0		;1098: 1022
	BPL.S	LAB_007F		;109a: 6a10
	NEG.B	D0			;109c: 4400
	BMI.S	LAB_0081		;109e: 6b16
	EXT.W	D0			;10a0: 4880
	MOVE.B	-(A2),D1		;10a2: 1222
LAB_007E:
	MOVE.B	D1,-(A1)		;10a4: 1301
	DBF	D0,LAB_007E		;10a6: 51c8fffc
	BRA.S	LAB_007D		;10aa: 60ec
LAB_007F:
	EXT.W	D0			;10ac: 4880
LAB_0080:
	MOVE.B	-(A2),-(A1)		;10ae: 1322
	DBF	D0,LAB_0080		;10b0: 51c8fffc
	BRA.S	LAB_007D		;10b4: 60e2
LAB_0081:
	MOVEM.L	(A7)+,D0-D3		;10b6: 4cdf000f
	MOVEM.L	D0-D3,48(A4)		;10ba: 48ec000f0030
	MOVEM.L	(A7)+,D0-D3		;10c0: 4cdf000f
	MOVEM.L	D0-D3,32(A4)		;10c4: 48ec000f0020
	MOVEM.L	(A7)+,D0-D3		;10ca: 4cdf000f
	MOVEM.L	D0-D3,16(A4)		;10ce: 48ec000f0010
	MOVEM.L	(A7)+,D0-D3		;10d4: 4cdf000f
	MOVEM.L	D0-D3,(A4)		;10d8: 48d4000f
	MOVE.L	#$00000000,D0		;10dc: 203c00000000
	RTS				;10e2: 4e75
LAB_0082:
	MOVE.L	#$80000040,D0		;10e4: 203c80000040
	RTS				;10ea: 4e75
    
_resload	dc.l	0
