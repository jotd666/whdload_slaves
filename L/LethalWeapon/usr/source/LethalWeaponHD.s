
		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"LethalWeapon.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;CHIP_ONLY

	IFD	CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = 0
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
	ENDC
;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	19			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	FASTMEMSIZE			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config
		
_config
        dc.b    "C1:X:trainer infinite lives:0;"
        dc.b    "C1:X:trainer infinite magazines:1;"
        dc.b    "C2:B:blue/second button jumps;"
		dc.b	0
;============================================================================
		IFND	.passchk
		;DOSCMD	"WDate  >T:date"
.passchk
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
_name		dc.b	"Lethal Weapon"
		IFD	CHIP_ONLY
		dc.b	"(debug/chip mode)"
		ENDC
		dc.b	0
_copy		dc.b	"1992 Ocean",0
_info		dc.b	"Adapted by Abaddon/Codetapper/JOTD",10

		dc.b	"Version "
		DECL_VERSION
		dc.b	-1,"Thanks to Steven Becker and Sun 68"
		dc.b	10,"for sending the originals!"
		dc.b	0

	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0


		EVEN


	include	ReadJoyPad.s
	
;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart
		IFD	CHIP_ONLY
		lea	_expmem(pc),a0
		move.l	#$80000,(a0)
		ENDC
		move.l	_expmem(pc),d0
		lea	player_structure(pc),a1
		add.l	d0,(a1)
		lea		ladder_flag_address(pc),a1
		add.l	d0,(a1)
		move.l	d0,a0
		moveq	#$16,d1
		moveq	#$71,d2
		bsr	_Loader

		move.l	_expmem(pc),a0
		move.l	#$e200,d0
		move.l	_resload(pc),a2
		jsr	resload_CRC16(a2)
		
		cmp.w	#$f6e8,d0		;Original (Sun 68)
		beq	_VersionOK
		cmp.w	#$1b34,d0		;Ministry crack
		bne	_wrongver

_VersionOK	move.l	_expmem(pc),a0		;Copy the decruncher to
		add.l	#$60,a0
		lea	_Decruncher(pc),a1	;fast memory
		move.l	#(($26c-$60)/4),d0
_CopyDecruncher	move.l	(a0)+,(a1)+
		dbf	d0,_CopyDecruncher

		lea	$dff180,a0
		moveq	#16-1,d0
_ClearPalette	move.w	#0,(a0)+
		dbf	d0,_ClearPalette

	
		lea	_PL_Boot(pc),a0		;Patch boot
		move.l	_expmem(pc),a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	_expmem(pc),a0
		move.l	#$e200,d0
		lea	(a0,d0.l),a1
		move.l	a0,a4
		move.l	_expmem(pc),a4
		jmp	(a4)

_PL_Boot	PL_START
		PL_W	$c,$6106		;bsr.w -> bsr.b
		PL_P	$e,_Game		;trap #15 and jmp *+$26c
		PL_P	$60,_Decruncher		;RNC decruncher
		PL_B	$3eb0,$ff		;Fix RNC bug $00
		PL_END

;======================================================================

_Game		movem.l	d0-d1/a0-a2,-(sp)

	; we don't need extra joypad buttons, game doesn't have pause
	; so no big need to add extra buttons besides second button
	;bsr		_detect_controller_types
	lea	controller_joypad_1(pc),a0
	clr.b	(a0)
	
		lea	_PL_Game(pc),a0
		move.l	_expmem(pc),a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2

		move.l	_expmem(pc),a0		;Start game
		add.l	#$26c,a0
		jmp	(a0)

_PL_Game	PL_START
	PL_IFC1X	0
	PL_L	$148a4,$4a6d	; infinite lives
	PL_ENDIF
	PL_IFC1X	1
	PL_NOP	$c02a,4			; infinite magazines
	PL_ENDIF
	
	PL_AL	$258e+2,8		; skip stupid intena change
	PL_ORW	$2596+2,$20		; enable VBLANK
	PL_PS	$2aec,_VblHook
	
	PL_IFC2
	PL_PSS	$1f1e,_ReadJoystick,2
	PL_PS	$c7aa,_TestForLadder
	PL_PS	$15aaa,_AcceptMissionLoop
	PL_ENDIF
	
	; fix sound
	PL_PS	$4494,write_dmacon_d4
	
	PL_W	$932,$5200		;Colour bit fix
	PL_W	$182e,$5200		;Colour bit fix
	PL_W	$1a12,$6600		;Colour bit fix
	PL_PS	$1ffc,_Keybd		;move.b #1,($c00,a1)
	PL_S	$2c7a,$82-$7a		;move.w #$20,$dff1dc
	PL_S	$2c8a,$92-$8a		;move.w #$0,$dff1dc
	PL_PSS	$3672,_Blt_a450_d358,2	;Blitter wait
	PL_PS	$4850,_WeirdFault	;Occurs when you go out some doors (sometimes!) - go into the first door, up, out the next door, then back through the doors and the fault occurs
	PL_P	$6942,_Loader		;Rob Northen loader
	PL_S	$74ee,$53a-$4ee		;Turn off drive
	PL_P	$adee,_Copylock		;Crack copylock
	PL_PS	$ece6,_AccessFault
	PL_END

;======================================================================

write_dmacon_d4
	move.w	d4,_custom+dmacon
	move.w  d0,-(a7)
	move.w	#4,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
	rts 
	
;======================================================================

_AcceptMissionLoop
	MOVE.W	#$0096,D0		;95aaa: 303c0096
	MOVE.W	#$0097,D1		;95aae: 323c0097
	; disable second button to be able to use up
	lea		over_ladder_flag(pc),a0
	st.b	(a0)
	
	move.l	(a7),a0
	addq.w	#2,a0	; mainloop address
	
	jsr	(a0)
	
	; enable second button
	lea		over_ladder_flag(pc),a0
	clr.b	(a0)
	addq.w	#4,a7	; pop stack
	rts

;======================================================================
	
_TestForLadder
	; copy the flag which seems to indicate that player
	; is over a ladder, ready to climb it
	; when not over a ladder, flag is a steady 0
	; when over a ladder, flag toggles between $FF and 0
	; so we maintain a non-zero value for 1 iteration
	; (with a shift)
	movem.l	d0/a0/a1,-(a7)
	lea		over_ladder_flag(pc),a0
	move.l	ladder_flag_address(pc),a1
	move.b	(a0),d0
	; zero or positive: reload flag
	; (we get $FF every time over a ladder yeah!!!)
	bpl.b	.copy

	; negative: has been set at the previous call
	; latency: don't cancel the flag immediately
	lsr.b	#4,d0	; remains non-zero (but now positive)
	move.b	d0,(a0)
	bra.b	.skip
.copy
	move.b	(a1),(a0)
.skip
	; always test value
	tst.b	(a1)
	movem.l	(a7)+,d0/a0/a1
	rts
	
;======================================================================

_VblHook
	lea	_custom,a6	; original
	move.w	intreqr(a6),d0
	btst	#5,d0
	beq.b	.copper
	; vblank stuff: read buttons
	moveq	#1,d0
	bsr	_read_joystick
	lea	joy1(pc),a0
	move.l	d0,(a0)		

	; end
	addq.w	#4,A7	; pops up stack
	move.w	#$20,intreq(a6)
	MOVEM.L	(A7)+,D0-D7/A0-A6	;82b48: 4cdf7fff
	RTE				;82b5c: 4e73

.copper:
	rts
	
;======================================================================

_ReadJoystick:
	movem.l	d1-a6,-(a7)
	move.l	joy1(pc),d0
	moveq.l	#0,d1
	move.w	$DFF00C,D1
	move.l	player_structure(pc),a5
	tst.b	(25,a5)		; on ladder?
	bne.b	.no_blue
	move.b	over_ladder_flag(pc),d2
	BNE.S	.no_blue		;8c83e: 670a
.cancel	
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
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
	movem.l	(a7)+,d1-a6
	
	
	BTST	#1,D0			;81f22: 08000001
	rts
	
;======================================================================

_Copylock	move.l	#$daeb43cf,d0		;Copylock ID
		move.l	d0,($100).w
		move.l	d0,d7			;move.l	d0,($1C,a6)
		rol.l	#1,d0			;move.l	d1,(a6)+
		rol.l	#1,d0
		move.l	d0,d2			;move.l	d0,(a6)+
		rol.l	#1,d0
		move.l	d0,d3			;move.l	d0,(a6)+
		rol.l	#1,d0
		rol.l	#1,d0
		move.l	d0,d4			;move.l	d0,(a6)+
		rol.l	#1,d0
		move.l	d0,d5			;move.l	d0,(a6)+
		rol.l	#1,d0
		move.l	d0,d6			;move.l	d0,(a6)+
		moveq	#0,d0
		moveq	#0,d1
		rts

;======================================================================

_Blt_a450_d358	move.l	a4,($50,a6)
		move.w	d3,($58,a6)
		
		btst	#6,2(a6)
_BlitWait	btst	#6,2(a6)
		bne	_BlitWait
		rts

;======================================================================

_AccessFault	move.l	_expmem(pc),a0
		add.l	#$419c,a0
		movea.l	(a0),a0
		cmpa.l	#$FFFFFFFF,a0
		bne	_NoFault
		add.l	#4,sp
_NoFault	rts

;======================================================================

_WeirdFault	add.w	d1,d1
		movea.l	($78,a0,d1.w),a1
		cmp.l	#$80000,a1
		bhi	_SkipD1Fix
		rts
_SkipD1Fix	movea.l	($78,a0),a1		;Unsure how safe this is
		cmp.l	#$80000,a1
		bhi	_debug
		rts

;======================================================================

_Loader		movem.l	d1-d2/a0-a2,-(sp)
		move.l  _resload(pc),a2		;a0 = dest address
		mulu	#$200,d1		;offset (sectors)
		mulu	#$200,d2		;length (sectors)
		exg.l	d1,d0			;d0 = offset (bytes)
		exg.l	d2,d1			;d1 = length (bytes)
		moveq	#1,d2			;d2 = disk
		jsr	resload_DiskLoad(a2)	;a0 = destination
		movem.l	(sp)+,d1-d2/a0-a2
		moveq	#0,d0
		rts

;======================================================================

_Keybd		cmp.b	_keyexit(pc),d2
		beq	_exit
		move.b	#1,($c00,a1)		;Stolen code
		rts

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_Decruncher	ds.l	(($26c-$60)/4)+1

player_structure:
	dc.l	$1A16E
ladder_flag_address:
	dc.l	$1a16a
over_ladder_flag
	dc.b	0