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


	IFD BARFLY
	OUTPUT	"AlienBreed.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

Prot	=	0	; you must set NoVBRMove and protection will be stop
			; at trap #2 (screen flashed)
;DEBUG = 1
	
;======================================================================

_base
		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd	;ws_flags
	ifne	Prot
		dc.l	$120000			;ws_BaseMemSize
	else
		IFD	DEBUG		
		dc.l	$100000
		ELSE
		dc.l	$80000			;ws_BaseMemSize
		ENDC
	endc
		dc.l	0			;ws_ExecInstall
		dc.w	start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = '*'
_expmem
	ifne	Prot
		dc.l	$0			;ws_ExpMem
	else
		IFD	DEBUG		
		dc.l	$0
		ELSE
		dc.l	$80000			;ws_ExpMem
		ENDC
	endc
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

;============================================================================


	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

_config
	    dc.b	"BW;"
        dc.b    "C1:X:Infinite Lives & Ammo & keys & credits:0;"
        dc.b    "C2:X:Enable original cheat keys (F7 levelskip/F9 megacheat):0;"
		dc.b	0
		
DECL_VERSION:MACRO
	dc.b	"2.2"
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

_name		dc.b	"Alien Breed"
		IFD	DEBUG
		dc.b	" (DEBUG MODE)"
		ENDC
		dc.b	0
_copy		dc.b	"1991 Team 17",0
_info		dc.b	"fixed by Mr.Larmer",10,10
		dc.b	"additional enhancements by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1
		dc.b	"Greetings to Helmut Motzkau",0
DiskNr		dc.b	1
		even

GET_EXPMEM:MACRO	
	IFD	DEBUG
	move.l	#$80000,\1
	ELSE
	move.l	_expmem(pc),\1
	ENDC
	ENDM
	
;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	a0,a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)


		lea	$60000,a0
		moveq	#0,d0
		move.l	#$400,d1
		moveq	#1,d2
		bsr.w	_LoadDisk

		move.w	#0,SR
		move.w	#$8240,$DFF096

		move.w	#$4EF9,$B8(a0)
		pea	Boot(pc)
		move.l	(a7)+,$BA(a0)
		
		bsr	_flushcache
		jmp	$3E(a0)

IGNORE_JOY_DIRECTIONS
		include	ReadJoyPad.s
		
;--------------------------------

Copy_A3
		movem.l	d0/a2/a3,-(a7)
		sub.w	#$70,a7
		lea	(a7),a2
		bsr.b	Copy2
		bsr	_flushcache
		movem.l	$70(a7),d0/a2/a3
Leave
		jsr	(a7)
		add.w	#$70+12,a7
		rts

;--------------------------------

Copy2
.copy
		cmp.w	#$47FA,(a3)
		beq.b	.lea3
		cmp.w	#$49FA,(a3)
		beq.b	.lea4
		cmp.w	#$40C7,(a3)		; move.w SR,d7
		beq.b	.sr
		move.w	(a3)+,(a2)+
		cmp.b	#$60,-2(a3)
		bne.b	.copy
		cmp.w	#$49FA,(a3)
		beq.b	.lea4
		move.w	#$4E75,(a2)+
		move.l	#$548B4E75,(a2)		; addq.l #2,a3
		rts
.sr
		move.w	#$2008,d7		; SR value
		addq.l	#2,a3
		bra.b	.copy
.lea3
		move.w	#$47F9,(a2)+
		bra.b	.do
.lea4
		move.w	#$49F9,(a2)+
.do
		addq.l	#2,a3
		move.l	a3,d0
		add.w	(a3)+,d0
		move.l	d0,(a2)+
		bra.b	.copy

;--------------------------------

Boot
		lea	$600B8,a3

		move.l	#$49FA032C,(a3)
		move.w	#$47FA,4(a3)
.go2
		bsr.b	Copy_A3

		cmp.l	#$6033E,a3
		bne.b	.go2

		movem.l	$100.w,d0-a6
		move.w	d2,(a6)

		clr.l	4.w

		lea	$70000,a0
		move.l	#$400,d0
		move.l	#$2800,d1
		moveq	#1,d2
		bsr.w	_LoadDisk

		lea	(a0,d1.w),a0
		move.w	#$13FF,d0
		move.w	#$FFFE,d1
.loop
		eor.w	d1,-(a0)
		rol.w	#1,d1
		dbf	d0,.loop

		lea	$7FFFC,a7
		GET_EXPMEM	(A7)
		move.w	#0,SR
		lea	$7F800,a7

		lea	$70826,a0
.go
		bsr.b	Copy_A0

		cmp.l	#$70ABE,a0
		bne.b	.next

		lea	$70F2A-$70ABE(a0),a0
.next
		cmp.l	#$70F9C,a0
		bne.b	.next2

		lea	$713EE-$70F9C(a0),a0
.next2
		cmp.l	#$715FE,a0
		bne.b	.next3

		lea	$715EC-$715FE(a0),a0
.next3
		cmp.l	#$71864,a0
		bne.b	.go

		move.w	#$4EF9,$70FDA-$71864(a0)
		pea	Load(pc)
		move.l	(a7)+,$70FDC-$71864(a0)

		pea	Patch(pc)
		move.l	(a7)+,$7187E-$71864(a0)		; jmp $30000

		bsr	_flushcache
		jmp	(a0)

;--------------------------------

Copy_A0
		movem.l	d0/a0/a2,-(a7)
		sub.w	#$70,a7
		lea	(a7),a2
		bsr.b	Copy
		bsr	_flushcache
		movem.l	$70(a7),d0/a0/a2
		bra.w	Leave

;--------------------------------

Copy
.copy
		cmp.w	#$41FA,(a0)
		beq.b	.lea
		move.w	(a0)+,(a2)+
		cmp.w	#$51c8,-2(a0)
		bne.b	.copy
		move.w	(a0)+,(a2)+
		cmp.w	#$41FA,(a0)
		beq.b	.lea
		move.w	#$4E75,(a2)
		rts
.lea
		move.w	#$41F9,(a2)+
		addq.l	#2,a0
		move.l	a0,d0
		add.w	(a0)+,d0
		move.l	d0,(a2)+
		bra.b	.copy

;--------------------------------

Patch
		lea	$30014,a0
.copy
		bsr.b	Copy_A0

		cmp.l	#$20000,a0
		bne.b	.next0

		lea	$30E72,a0
.next0
		cmp.l	#$30F5C,a0
		bne.b	.next

		move.w	#$4EF9,$31606-$30F5C(a0)
		pea	Load(pc)
		move.l	(a7)+,$31608-$30F5C(a0)

		lea	$70000,a0
		jsr	$315F8

		lea	$319C6,a0
.next
		cmp.l	#$31A64,a0
		bne.b	.next1
		bsr	_flushcache
		jsr	(a0)

		lea	$30F6E,a0
.next1
		cmp.l	#$310C2,a0
		bne.b	.next2

		jsr	$31A88-$310C2(a0)

		lea	$310D4,a0
.next2
		cmp.l	#$312D2,a0
		bne.b	.next3

		jsr	$31AB2-$312D2(a0)

		lea	$312D6,a0
.next3
		cmp.l	#$3157E,a0
		bne.b	.copy

		pea	Patch2(pc)
		move.l	(a7)+,$32048-$3157E(a0)		; jmp $8000
		bsr	_flushcache
		jsr	$31AE0-$3157E(a0)
		bsr	_flushcache
		jmp	$31590

;--------------------------------

Patch2
		lea	$8788,a0
.copy
		bsr.w	Copy_A0

		cmp.l	#$A32E,a0
		bne.b	.copy

		move.w	#$4EF9,$100.w
		pea	Patch3(pc)
		move.l	(a7)+,$102.w
		move.w	#$100,$A3BA-$A32E(a0)
		bsr	_flushcache
		jmp	(a0)

;--------------------------------

Patch3
		clr.w	$100.w
		clr.l	$102.w

	move.l	a0,-(a7)
	lea	Patch4(pc),a0
	ifne	Prot
	sub.l	#$80000,a0
	else
	IFD	DEBUG
	sub.l	#$80000,a0
	ELSE
	sub.l	_expmem(pc),a0
	ENDC
	endc
	move.l	a0,$2E(a5)		; a5=expmem
	move.l	(a7)+,a0
	bsr	_flushcache
	jmp	$400.w

;--------------------------------

Patch4
	movem.l	d0-d1/a0-a2/A4,-(a7)
	
	bsr	_detect_controller_types
	
	move.l	a5,a1	; expansion mem
	
	
	add.l	#$A000,a1
	addq.l	#4,$697A(a1)		; fix access fault
	addq.l	#4,$69CE(a1)

	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	move.l	a5,a1
	jsr	resload_Patch(a2)

	GET_EXPMEM	A4

	
	move.l	A4,d0
	add.l	#$85A,d0
	move.l	d0,2(a5)


	bsr	_flushcache
	movem.l	(a7)+,d0-d1/a0-a2/A4
	jmp	(a5)			; expmem

; keyboard handshake timer
_ack_kb:
	move.b	#$FF,$bfec01
	move.l  d0,-(a7)
	moveq	#2,d0
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.l	(a7)+,d0
	rts
	
pl_main:
	PL_START
	PL_IFBW
	PL_PS	$E976,mission_text
	PL_ENDIF
	PL_IFC1
	; not efficient, credit value is somehow reset when entering shop
	;PL_PS	$117C,set_max_credits
	PL_PSS	$D294,set_max_credits,2
	PL_B	$804E,$4A	; energy
	PL_B	$8052,$4A
	PL_B	$A6AA,$4A
	PL_B	$749C,$4A	; lives
	PL_B	$D950,$4A	; ammo
	PL_B	$7BA8,$4A	; keys
	PL_B	$D964,$4A	; magazines
	PL_B	$2D8E,$4A	; time
	PL_B	$2D9E,$4A
	PL_ENDIF
	PL_IFC2
	; check cheat keys active: always
	PL_NOP	$E08,4
	PL_ENDIF
	
	PL_PSS	$2004E,read_ciasdr,4	; keyboard
	PL_PS	$A6D6,Protection
	PL_PS	$A000+$561A,ChangeDisk
	
	PL_P	$ADA6,Load

	; allows to quit after the end sequence
	; unfortunately this crashes the game!!! strange
	;;PL_P	$CF8,game_end
	
	; removes fire button to connect to intex

	PL_NOP	$7E32,2
	
	; replaces RMB check by RMB+button 2

	;;PL_PS	$7E3E,_button_test	; no longer needed, joypad test issues the spacebar keycode
;	PL_PS	$80D2,_button_test

	; keyboard fix

	PL_PSS	$2009C,_ack_kb,2
	
	PL_END
	IFEQ	1
game_end
	btst	#6,$bfe001
	beq.b	.quit
	btst	#7,$bfe001
	beq.b	.quit
	move.b	$bfec01,d0
	not.b	d0
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	bne.b	game_end
.quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	ENDC
mission_text
	btst	#6,$bfe001
	beq.b	.release
	btst	#7,$bfe001
	bne.b	mission_text
.release
	btst	#6,$bfe001
	beq.b	mission_text
	btst	#7,$bfe001
	beq.b	mission_text
	
	move.l	#$20,D0		; original code
	rts
		
read_ciasdr
	move.b	$bfec01,d0
	not.b	d0
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
	; quitkey works for 68000 now :)
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit	
	movem.l	d0,-(a7)
	movem.l	d1,-(a7)
	move.b	controller_joypad_1(pc),d0
	beq	.onlyjoystick
	; read the joypad buttons and send proper keycode
	bsr	_read_joysticks_buttons
	move.l	joy1_buttons(pc),d0
	moveq.l	#0,d1
	
	bclr	#JPB_BTN_GRN,d0
	beq.b	.nowchg
	move.b	#$64,d1	; code for "L-alt"
.nowchg	
	; we have cleared this green button flag if pressed
    ; now OR d0 with the contents of joy0 buttons
	; (since apart from weapon change, both players buttons perform the same actions)
	or.l	joy0_buttons(pc),d0
	; now we can test both joypads buttons at the same time :)
	btst	#JPB_BTN_GRN,d0
	beq.b	.nowchgp2
	move.b	#$65,d1	; code for "R-alt"
.nowchgp2
	
	; this button could be pressed on a non-joypad (2-button joystick)
	btst	#JPB_BTN_BLU,d0
	beq.b	.nointex
	move.b	#$40,d1	; code for "space"
.nointex
	btst	#JPB_BTN_PLAY,d0
	bne.b	.pause
	; reset pause press flag
	movem.l	A0,-(a7)
	lea	pause_pressed(pc),a0
	clr.b	(a0)
	movem.l	(a7)+,a0
	bra.b	.nopause
.pause
	movem.l	A0,-(a7)
	lea	pause_pressed(pc),a0
	tst.b	(a0)
	bne.b	.dont_press_again
.presspause
	move.b	#$19,d1	; code for "P"
	st.b	(a0)
.dont_press_again	
	movem.l	(a7)+,a0
.nopause
	btst	#JPB_BTN_YEL,d0
	beq.b	.nomap
	move.b	#$37,d1	; code for "M"
.nomap
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	move.b	#$45,d1	; code for "ESC"
.noesc
	tst.b	d1
	beq.b	.nobuttonpress	; no button pressed, don't clobber keyboard
	move.w	d1,d0
	movem.l	(a7)+,d1
	addq.l	#4,A7	; do not restore D0!
.set_carry_and_quit
	rol.b	#1,d0
	ror.b	#1,d0
	rts
.nobuttonpress
	movem.l	(a7)+,d1
.nojoypad
	movem.l	(a7)+,d0	; restore D0 value: keyboard code
	bra.b	.set_carry_and_quit
	rts
; not a joypad: just read 2nd button, no need to read all the others & the pause
; logic wasting CPU cycles for no chance of ever reading any extra buttons
.onlyjoystick
	moveq.l	#1,d0
	bsr	_read_joystick
	moveq.l	#0,d1
	; this button could be pressed on a non-joypad (2-button joystick)
	btst	#JPB_BTN_BLU,d0
	beq.b	.noesc
	move.b	#$40,d1	; code for "L-alt"
	bra.b	.noesc
	
set_max_credits
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	lea	pl_credits(pc),a0
	sub.l	a1,a1
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	
	GET_EXPMEM	a0

	; set a lot of credits each time entering shop
	; I don't really see the relation between the value and the
	; displayed value, but let's say it's a lot of cash
	move.l	#$00100010,($7A4,a0)
	
	rts

pl_credits
	PL_START
	; remove the credit subtract in various places in the shop
	PL_NOP	$2BB1E,6
	PL_NOP	$2B23E,2
	PL_NOP	$2BB2C,2
	PL_END
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

;--------------------------------

Protection
	ifne	Prot
		lea	$C6874,a0
.copy
		bsr.w	Copy_A0

		cmp.l	#$C68D0,a0
		bne.b	.copy

		move.w	#$4EB9,$C7636
		pea	Decode(pc)
		move.l	(a7)+,$C7638

		pea	(a2)
		jsr	$C759C
		jsr	$C75D6
		move.l	(a7)+,a2

		jmp	$C68DC		; go to trace code
	endc
		eor.b	#$4E,$458.w	; this code is forgot in cracked version :)

		lea	Track(pc),a0
		moveq	#8-1,d0
.copy
		move.l	(a0)+,(a2)+
		dbf	d0,.copy

;		move.l	#$77000000,d0
		moveq	#$77,d0
		ror.l	#8,d0
		move.l	#$4449534B,d1
;		move.l	#$32000000,d2
		moveq	#$32,d2
		ror.l	#8,d2
;		move.l	#$10000000,d3
		moveq	#$10,d3
		ror.l	#8,d3
		moveq	#2,d4
		moveq	#-1,d6
;		move.l	#$FFFF,d5
		moveq	#0,d5
		move.w	d6,d5
		move.l	#$55555555,d7

; read track 0_0 from disk 2 with SYNC $8924 to $200 ptr
; and calculated values are leaved in d0-d7 !

		rts
Track
		dc.l	$8924912A,$AAAA552A,$AAAAAAA4,$A9254449
		dc.l	$5149112A,$AAAA92AA,$AAAAAAAA,$AAAAAAAA

;--------------------------------

	ifne	Prot
Decode
		move.l	-4(a0),d0
		eor.l	d0,(a0)

		moveq	#0,d0
		move.w	(a0),d0
		lsr.w	#1,d0
		lea	Size(pc),a1
		move.b	(a1,d0.w),d0
		btst	#0,1(a0)
		bne.b	.skip
		lsr.b	#4,d0
.skip
		and.w	#$F,d0
		beq.b	.error		; if 0 ist isn't support opcode size
		subq.w	#1,d0
.back
		bsr.b	.calc_dest
.copy
		move.w	(a0)+,(a1)+
		dbf	d0,.copy
		rts
.calc_dest
		move.l	d1,-(a7)
		move.l	a0,d1
		sub.l	#$C6000,d1
		lea	$100000,a1
		add.l	d1,a1
		move.l	(a7)+,d1
		rts

;--------------------------------------

.error
.m
		move.w	$dff006,$dff180

		btst	#6,$bfe001
		bne.b	.m
.m1
		btst	#6,$bfe001
		beq.b	.m1

;	move.w	#$60FE,$C7592

		bra.b	.back
	endc

;--------------------------------

Load
		movem.l	d0-d2/a0-a2,-(a7)

		mulu	#$200,d0
		mulu	#$200,d1
		lea	DiskNr(pc),a1
		moveq	#0,d2
		move.b	(a1),d2
		bsr.b	_LoadDisk

		movem.l	(a7)+,d0-d2/a0-a2
		moveq	#0,d0
		rts

;--------------------------------

ChangeDisk
		move.l	a0,-(a7)
		lea	DiskNr(pc),a0
		move.b	#2,(a0)
		move.l	(a7)+,a0
		rts

;--------------------------------

_resload	dc.l	0		;address of resident loader

pause_pressed
		dc.w	0
		
;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

	ifne	Prot
Size
		incbin 'ist'
	endc

	END
