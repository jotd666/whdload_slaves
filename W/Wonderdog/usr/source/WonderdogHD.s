	INCDIR	"Include:"
	INCLUDE	whdload.i
	IFD	BARFLY
	OUTPUT	Wonderdog.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;DEBUG

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd|WHDLF_ClearMem
		IFD	DEBUG
		dc.l	$100000
		ELSE
		dc.l	$80000			;ws_BaseMemSize
		ENDC
		dc.l	0
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	0			;ws_keyexit = F10
_expmem	
		IFD	DEBUG
		dc.l	0
		ELSE
		dc.l	$80000			;ws_ExpMem
		ENDIF
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
		
DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
		
	
_config
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C2:X:Trivial password table xAAAAAAA:0;"
        dc.b    "C3:X:Force sound effects by default:0;"
        dc.b    "C4:X:use blue/2nd button for jump:0;"
        dc.b    "C5:X:alternate backgrounds palette:0;"
		dc.b	0

	dc.b	'$VER: Wonderdog by Bored Seal & JOTD '
	DECL_VERSION
	dc.b	0


_name		dc.b	"Wonderdog"
			IFD	DEBUG
			dc.b 	" (DEBUG MODE)"
			ENDC
			dc.b	0
_copy		dc.b	"1993 Core Design",0
_info		dc.b	"Adapted by Bored Seal & JOTD",10,10
	dc.b	"Press HELP or red+yel+grn+blue to skip levels",10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
		CNOP 0,2

_Start	

	lea	(_resload,pc),a1
	move.l	a0,(a1)
	move.l	a0,a2
		
	IFD	DEBUG
	lea	_expmem(pc),A0
	move.l	#$80000,(A0)
	ENDC
 
	bsr	_detect_controller_types
	
		moveq	#0,d0
		move.l	#$50f,d1
		moveq	#$34,d2
		lea	$70000,a0
		bsr	LoadRNCTracks

		move.l	a0,-(sp)
		move.l	d2,d0
		mulu.w	#$200,d0
		jsr     (resload_CRC16,a2)
		cmp.w	#$6a82,d0		;Keith v1
		bne	Unsupported
		move.l	(sp)+,a0
		
		PEA	Level2Inter(pc)
		move.l	(a7)+,$68.W
		PEA	dummy_trapf(pc)
		move.l	(a7)+,$BC.W
		
		move.l	a0,a1
		lea	pl_intro(pc),a0
		jsr	(resload_Patch,a2)
		
		move.w	#$c008,$dff09a		;Enable keyboard interrupt for intro
		jmp	$70000


pl_intro:
	PL_START
	;;PL_W	$6274,$602c	;mem test
	PL_P	$6274,set_expmem
	PL_P	$5af8,LoadRNCTracks
	PL_P	$6348,Decrunch
	PL_P	$6322,PatchGame
	PL_END

	
set_expmem
	move.l	_expmem(pc),$76342
	rts
	
dummy_trapf
	RTE
	
	
PatchGame
	movem.l	d0-d1/A1-A2,-(a7)
	move.l	_resload(pc),a2
	move.l	_expmem(pc),A1
	lea	pl_main(pc),a0
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/A1-A2
	
	move.w	#$c008,$dff09a		;Enable keyboard interrupt for intro
	move.l	$76342,a0
	jmp	(a0)

	
pl_main
	PL_START
	PL_PA	$88,Copylock
	PL_P	$2D5EE,LoadRNCTracks
	PL_PA	$13EF8,Insert
	PL_PA	$440a,Disk1
	PL_P	$419E,Decrunch
	PL_PS	$6956,SnoopFix
	
	PL_PS	$b7dc,test_end_level
	
	
	PL_IFC1
	PL_W	$B922,$6008	; infinite lives
	PL_ENDIF
	PL_IFC2
	; trivial password table
	PL_STR	$8510,<BAAAAAAACAAAAAAADAAAAAAAEAAAAAAAFAAAAAAA>
	PL_ENDIF
	PL_IFC3
	PL_B	$840C,$60	; no more MUSIC/SFX switch
	PL_W	$8D7E,1		; SFX by default
	;;PL_PS	$14050,before_load_music	; store sector for music file
	PL_ENDIF
	
	PL_IFC4
	PL_PSS	$BC7A,test_for_jump_button,6
	PL_ELSE
	PL_PSS	$BC7A,test_for_jump_up,6	
	PL_ENDIF
	PL_PSS	$B846,resume_game_test,2
	
	PL_IFC5
	PL_L   $1d30c,   $8400e84
	PL_L   $1d310,   $fdb0680
	PL_L   $1d314,    $400877
	PL_L   $1d318,        $82
	PL_L   $1d31c,    $500d81
	PL_L   $1d320,   $8410ecc
	PL_L   $1d324,    $8d000d
	PL_L   $1d3bc,   $8400e84
	PL_L   $1d3c8,        $82
	PL_L   $1d3cc,    $500d81
	PL_L   $1d3d0,   $8410ecc
	PL_L   $1d3d4,    $8d000d
	PL_L   $1d46c,   $8400e84
	PL_L   $1d478,        $82
	PL_L   $1d47c,    $500d81
	PL_L   $1d480,   $8410ecc
	PL_L   $1d484,    $8d000d
	PL_L   $1d51c,   $8400e84
	PL_L   $1d528,        $82
	PL_L   $1d52c,    $500d81
	PL_L   $1d530,   $8410ecc
	PL_L   $1d534,    $8d000d
	PL_L   $1d5cc,   $8400e84
	PL_L   $1d5d8,        $82
	PL_L   $1d5dc,    $500d81
	PL_L   $1d5e0,   $8410ecc
	PL_L   $1d5e4,    $8d000d
	PL_L   $1dcbc,   $8600282
	PL_L   $1dcc0,   $6d40a80
	PL_L   $1dcc4,   $ca00ed4
	PL_L   $1dcc8,       $640
	PL_L   $1dccc,   $8620a84
	PL_L   $1dcd0,    $6000a0
	PL_L   $1dd6c,   $8600282
	PL_L   $1dd70,   $6d40a80
	PL_L   $1dd74,   $ca00ed4
	PL_L   $1dd78,       $640
	PL_L   $1dd7c,   $8620a84
	PL_L   $1dd80,    $6000a0
	PL_L   $1de1c,   $8600282
	PL_L   $1de20,   $6d40a80
	PL_L   $1de24,   $ca00ed4
	PL_L   $1de28,       $640
	PL_L   $1de2c,   $8620a84
	PL_L   $1de30,    $6000a0
	PL_L   $1decc,   $8600282
	PL_L   $1ded0,   $6d40a80
	PL_L   $1ded4,   $ca00ed4
	PL_L   $1ded8,       $640
	PL_L   $1dedc,   $8620a84
	PL_L   $1dee0,    $6000a0
	PL_L   $1df7c,   $8600282
	PL_L   $1df80,   $6d40a80
	PL_L   $1df84,   $ca00ed4
	PL_L   $1df88,       $640
	PL_L   $1df8c,   $8620a84
	PL_L   $1e040,   $c2a0806
	PL_L   $1e0f0,   $c2a0806
	PL_L   $1e1a0,   $c2a0806
	PL_L   $1e250,   $c2a0806
	PL_ENDIF
	
	PL_END

test_end_level:
	CMPI.W	#$0001,386(A5)		;0: 0c6d00010182
	beq.b	.end
	movem.l	d0,-(a7)
	move.l	buttons_state(pc),d0
	and.l	#JPF_BTN_BLU|JPF_BTN_RED|JPF_BTN_YEL|JPF_BTN_GRN,d0
	cmp.l	#JPF_BTN_BLU|JPF_BTN_RED|JPF_BTN_YEL|JPF_BTN_GRN,d0
	movem.l	(a7)+,d0
	beq.b	.end	; skip
	
	cmp.b	#$5F,376(A5)	; test if help pressed
	beq.b	.end
	; now we'll test for a joypad combination: all 4 front buttons pressed
	
.end
	rts

	
buttons_state
	dc.l	0
	
; joystick up test:
;0008BC7A 0801 0008                BTST.L #$0008,D1
;0008BC7E 6700 0006                BEQ.W #$0006 == $0008bc86 (F)
;0008BC82 08c3 0002                BSET.L #$0002,D3
test_for_jump_button:
	movem.l	d0,-(a7)
	moveq.l	#1,d0
	bsr	_read_joystick		; returns state in D0
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_jump
	BSET.L #$0002,D3	; jump
.no_jump
	bsr	handle_keys
	movem.l	(a7)+,d0
	rts

; store current keypress
;0008D882 1b40 0178                MOVE.B D0,(A5, $0178) == $00006ba4 [60]
; test for pause
; 0008B834 0c2d 0019 0178           CMP.B #$19,(A5, $0178) == $00006ba4 [e0]
; test for quit
; 0008B852 0c2d 0045 0178           CMP.B #$45,(A5, $0178) == $00006ba4 [e0]
; loop to test if P is pressed again to resume
; 0008B846 0c2d 0019 0178           CMP.B #$19,(A5, $0178) == $00006ba4 [60]

test_for_jump_up:
	movem.l	d0,-(a7)
	moveq.l	#1,d0
	BTST.L #$0008,D1	; test joy up
	beq.b	.no_jump
	BSET.L #$0002,D3	; jump
.no_jump
	bsr	_read_joystick		; returns state in D0
	bsr	handle_keys
	movem.l	(a7)+,d0
	rts

; 3b7c 0001 017a           MOVE.W #$0001,(A5, $017a) : triggers quit game
resume_game_test:
	movem.l	d0,-(a7)
	bsr	.wait_play_release

	; now check if pressed
.loop
	CMP.B #$19,($0178,A5)	; P pressed
	beq.b	.p_key
	; now test resume from joypad
	moveq.l	#1,d0
	bsr	_read_joystick		; returns state in D0
	btst	#JPB_BTN_PLAY,d0
	bne.b	.resume
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.loop
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.loop
	MOVE.W #$0001,($017a,A5)	; ESC
.resume
	bsr	.wait_play_release
	move.B #$19,($0178,A5)	; P pressed
.p_key
	movem.l	(a7)+,d0
	rts
.wait_play_release
	moveq.l	#1,d0
	bsr	_read_joystick		; returns state in D0
	; first ensure that pause joypad button ISN'T pressed
	btst	#JPB_BTN_PLAY,d0
	bne.b	.wait_play_release
	rts
	
; < D0: joybutton status
; < A5: game struct
handle_keys:
	movem.l	a0,-(a7)
	; if key was pressed, zero it and put it where
	; the game expects it (so it makes up for the keyboard
	; conflict we have generated by re-enabling level 2
	; interrupts)
	
	lea	pressed_key(pc),a0
	move.b	(a0),d0
	beq.b	.sk
	clr.b	(a0)
	move.B d0,($0178,A5)
.sk
	lea	buttons_state(pc),a0
	move.l	d0,(a0)
	
	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_pause
	move.B #$19,($0178,A5)
.no_pause
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.no_quit
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.no_quit
	
	move.B #$45,($0178,A5)
.no_quit
	movem.l	(a7)+,a0
	rts
	
;energy trainer
;		move.w	#$6004,$8dc8a
;		move.w	#$6004,$8dd6c
;		move.w	#$6004,$951f2
;		move.w	#$6004,$9636e
;		move.w	#$6004,$96416
;		move.w	#$6004,$96cf2

SnoopFix	moveq	#0,d1
		move.b	6(a1),d1
		move.w	d1,$42(a6)
		rts

Copylock	move.l	#$9926be13,D6
		move.l	d6,$100.W
		move.l	_expmem(pc),-(a7)
		add.l	#$8C,(A7)
		RTS
		

Insert		cmp.l	#'CR2A',(a4)
		bne	Disk2

Disk1		lea	disknum(pc),a2
		move.w	#1,(a2)
		bra	LoadRNCTracks

Disk2		lea	disknum(pc),a2
		move.w	#2,(a2)

LoadRNCTracks	movem.l a0-a2/d0-d3,-(sp)
		mulu.w	#$200,d1
		mulu.w	#$200,d2
		move.l	d1,d0
		move.l	d2,d1
		lea	disknum(pc),a2
		move.w	(a2),d2
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		movem.l (sp)+,a0-a2/d0-d3
		clr.l	d0
		rts

; this is required because we've enabled level 2 interrupts
; (which allows to exit from 68000 in the intro and also allows
; cd play on cd32load :))
; the only issue is that it conflicts with the game way of reading
; the keyboard so ESC and P don't work anymore
;
; let's store the last pressed key here and hook it to our esc/pause
; detection that we installed for the joypad

Level2Inter
		movem.l	d0-d1/a0,-(sp)		;Level 2 interrupt
		lea	$BFE000,a0
		move.b	($D01,a0),d0
		btst	#3,d0
		beq.b	_NotKeybdInt
		clr.w	d0
		move.b	($C01,a0),d0
		bset	#6,$e01(a0)
		not.b	d0
		lsr.b	#1,d0
		lea	pressed_key(pc),a0
		move.b	d0,(a0)
		
		cmp.b	_keyexit(pc),d0		;Check for quit key
		beq	_exit
		bsr	_EmptyDBF		;Delay before acknowledge
		bclr	#6,($BFEE01).l
_NotKeybdInt	movem.l	(sp)+,d0-d1/a0
		move.w	#8,($DFF09C).l
		rte

_EmptyDBF	movem.l	d0-d1,-(sp)
		moveq	#3-1,d1			;wait because handshake min 75 탎
int2w1		move.b	$dff006,d0
int2w2		cmp.b	$dff006,d0		;one line is 63.5 탎
		beq	int2w2
		dbf	d1,int2w1		;(min=127탎 max=190.5탎)
		movem.l	(sp)+,d0-d1
		rts

pressed_key
	dc.w	0
	
Unsupported	
	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_exit		pea	TDREASON_OK
		bra	_end

_resload	dc.l	0

disknum		dc.w	1

	
IGNORE_JOY_DIRECTIONS
	include	ReadJoyPad.s
Decrunch
	incbin	"wonderdogrnc.bin"

; music files:



	