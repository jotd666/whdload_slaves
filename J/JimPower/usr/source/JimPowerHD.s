***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/Ż|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        JIM POWER WHDLOAD SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              May 2014                                   *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 28-apr-2020 - JOTD took over to merge the joypad controls and finetune
;        the rasterbeam fixes level by level (tedious) using real HW
;
; 19-Jun-2016	- Invincibility in-game key added
;		- ButtonWait for map screen added
;		- better "skip level" approach, using status register bits
;		  (d7) instead of just calling the "next level" routine
;		  directly
;		- copperlist bugs fixed which could cause trashed graphics
;		  (copperlists were set without waiting for vertical blank)
;		- some SMC fixed

; 18-Jun-2016	- "Get Key" trainer works now

; 17-Jun-2016	- trainers added
;		- timing and flickering bugs fixed
;		- started to add CD32 pad support

; 16-Jun-2016	- work restarted
;		- moveP instruction emulated
;		- Bplcon0 color bit fix
;		- blitter wait added (68010+ only)

; 16-May-2014	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	whdmacros.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10

; TODO: cd32load stop dmaaudio & restart after CD has started replaying
;       cdslave: patch end of level avoid stop music? because restarts
;       after purple boss / flying level with foreground: flicker!
;       boss 1 still sync issue (minor)

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

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
	
HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	19		; ws_version
	dc.w	FLAGS		; flags
	dc.l	$80000		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	_start-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"BW;"
	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Time:1;"
	dc.b	"C1:X:Unlimited Bombs:2;"
    dc.b    "C2:B:Use 2nd button to jump;"
	dc.b	"C3:B:In-Game Keys;"
    dc.b    "C5:X:disable rasterbeam fixes:0;"
    dc.b    "C5:X:disable music fixes:1;"
	;dc.b	"C2:L:Start at Level:1,2,3,4,5"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/JimPower",0
	ENDC

.name	dc.b	"Jim Power",0
.copy	dc.b	"1992 Loriciel",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
    dc.b    "Joypad controls & rasterbeam tuning by JOTD",10,10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	CNOP	0,2

	dc.b	"$VER: Jim Power slave "
	DECL_VERSION
	dc.b	10,0
	even
	
TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0

		dc.l	WHDLTAG_CUSTOM1_GET
; bit 0: unlimited lives on/off
; bit 1: unlimited time on/off
; bit 2: unlimited bombs on/off
; bit 3: in-game keys on/off

TRAINEROPTS	dc.l	0

		dc.l	WHDLTAG_CUSTOM2_GET
STARTLEVEL	dc.l	0

		dc.l	WHDLTAG_BUTTONWAIT_GET
BUTTONWAIT	dc.l	0	
		dc.l	TAG_END

_resload	dc.l	0


	INCLUDE	ReadJoyPad.s

CURRENT_LEVEL = $5A8

_start	
    lea	_resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2
	
    lea wait_values(pc),a0
    moveq.l #10,d0
    lea $100.w,a1
.wc
    move.l  (a0)+,(a1)+
    dbf d0,.wc
    
	bsr	_detect_controller_types

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ


; load boot
	move.l	#$d4000,d0
	move.l	#$4400,d1
	lea	$70000,a0
	move.l	a0,a5
	move.l	d1,d5

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$3d7,d0
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; decrunch
	lea	$bc(a5),a0		; crunched data
	lea	$5fc74,a1		; destination
	bsr	BK30_Decrunch
	
	
; patch
	lea	PLBOOT(pc),a0
	jsr	resload_Patch(a2)


; and start
	jmp	$60000			; $60000: skip protection


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7fff,$dff096
	move.w	#$7fff,$dff09c
	rts

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

PLBOOT	PL_START
	PL_PSS	$3e4,.patch,2		; patch after code has been copied to $400
	PL_PSS	$3ec,SetKbd,2		; don't install new level 2 interrupt
	PL_END

.patch	
	movem.l	d0-a6,-(a7)
	lea	PLBOOT400(pc),a0
	lea	$400.w,a1

; install trainers
	move.l	TRAINEROPTS(pc),d0

; unlimited lives
	lsr.l	#1,d0
	bcc.b	.noLivesTrainer
	bsr.b	ToggleLives
.noLivesTrainer

; unlimited time
	lsr.l	#1,d0
	bcc.b	.noTimeTrainer
	bsr.b	ToggleTime
.noTimeTrainer

; unlimited bombs
	lsr.l	#1,d0
	bcc.b	.noBombsTrainer
	bsr.b	ToggleBombs
.noBombsTrainer


	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0			; 68000?
	bcc.b	.noblit			; -> no blitter wait patches
	
	lea	PLBLIT(pc),a0
	lea	$400.w,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

.noblit

	movem.l	(a7)+,d0-a6

	;not.b	$3584.w			; enable built-in cheat

	move.l	#$400+$d6,$6c.w	; original code
	rts

ToggleLives
	eor.b	#$19,$400+$2cfe.w	; subq.b #1 <-> tst.b
	rts

ToggleTime
	eor.b	#$19,$400+$2d76.w	; subq.b #1 <-> tst.b
	rts

ToggleBombs
	eor.b	#$19,$400+$21f4.w	; subq.b #1 <-> tst.b
	rts


PLBLIT	PL_START
	PL_PS	$1c1a,.wblit1

	PL_PS	$1dea,.flush		; flush cache after SMC
	PL_END

.flush	move.w	#$3fc,d0
	addq.w	#4,a1

.FlushCache
	move.l	a0,-(a7)
	move.l	_resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.l	(a7)+,a0
	rts


.wblit1	bsr.b	WaitBlit
	movem.l	a2-a5,$48(a6)
	rts

WaitBlit
	tst.b	$02(a6)
.wblit	btst	#6,$02(a6)
	bne.b	.wblit
	rts
	


PLBOOT400
	PL_START
	PL_P	$3d6,.load
	PL_P	$e2,AckVBI
	PL_PS	$249c,.movep	; emulate moveP instruction
	PL_ORW	$4374+2,1<<9	; set Bplcon0 color bit
	PL_PS	$3966-$400,.tfmx_loaded
	
    PL_IFC5X	0
    PL_ELSE
    ; try to fix flickering in the various game main loops
    ; where the parameters were finely adjusted to A500 timings
	PL_PS	$162,_waitraster_0    ; intro (param=$28)
	PL_PSS	$214,_waitraster_1,2	; main loop (waited until $F8)
	PL_PSS	$31e,_waitraster_2,2	; fix flickering (param=$10C)
	PL_PS	$c86,_waitraster_3    ; map fade
	PL_PSS	$d0e,_waitraster_4,2  ; big flying monster after level 1 (param=$E0)
	PL_PSS	$d52,_waitraster_5,2  ; big monster level 2 (param=$FF)
	PL_PSS	$d8e,_waitraster_6,2  ; big monster level 3 (param=$F8)
	PL_PSS	$dd2,_waitraster_7,2  ; big monster level 4 (param=$F8)
	PL_PSS	$e42,_waitraster_8,2  ; big monster level 5 (param=$F8)
	PL_PSS	$31e2,_waitraster_9,2 ; end sequence (param=$FE)

	PL_PS	$293c,WaitRaster	; fix timing ("Game Over" screen) (param=$70)
	PL_ENDIF

	;PL_IFC3
	;PL_PS	$1b2,.setlevel
	;PL_PS	$20c,.setlevel2
	;PL_ENDIF

	PL_IFC3
	PL_PS	$30c4,.checkkeys
    PL_ELSE
    PL_PS   $30C4,.checkjoy
	PL_ENDIF

	PL_IFBW
	PL_PS	$c7a,.waitmap
	
	PL_ENDIF

	PL_P	$42d4,.WaitCop		; set copperlist during Vblank
	
    PL_PS   $2D32-$400,game_over

	PL_IFC2
	PL_PS	$1D0A-$400,hack_up
	PL_ELSE
	PL_PS	$1D0A-$400,read_joy
	PL_ENDIF
	
	PL_END

.setlevel2
	move.l	STARTLEVEL(pc),d0
	add.w	d0,d0
	move.w	d0,$5a8.w
	jsr	$400+$2c64.w
	jsr	$400+$42c6.w

	tst	d0
	beq	.first
	pea	$400+$90a.w

.first	rts


.WaitCop
	bsr	WaitRaster

	cmp.w	#$6280,$47d24+2		; fix illegal Bplcon0 value in
	bne.b	.nofix			; end sequence
	move.w	#$6200,$47d24+2

.nofix

	move.l	a0,$80(a6)
	move.l	a0,$84(a6)
	rts


.waitmap
	btst	#7,$bfe001
	bne.b	.waitmap
	jsr	$400+$c86.w	; fade down map screen
	sf	$d6a.w
	rts
	
.tfmx_loaded
	cmp.w	#$33EE,$6cfa2
	bne.b	.done
	movem.l	d0-d1/a1-a2,-(a7)
	move.l	_resload(pc),a2
	sub.l	a1,a1
	lea		pl_tfmx(pc),a0
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a1-a2
.done
	
	MOVEA.L	4(A7),A0		;3966: original: move.l (a7)+,a0
	; TFMX routine is loaded now
	MOVE.W	-(A0),D7		;3968: 3e20
	CLR.W	(A0)			;396a: 4250
	; fix the jsr before we restored A0 from stack
	; we needed those 6 bytes badly for our JSR ...
	move.l	(a7),4(a7)
	addq.l	#4,A7
	rts
	
.checkjoy
	move.b	(a0),d0 ; original code
	clr.b	(a0)
	lea	4(a7),a6
    
    bra joypad_controls
    
.checkkeys
	move.b	(a0),d0 ; original code
	clr.b	(a0)
	lea	4(a7),a6
    
    bsr joypad_controls
	movem.l	d1,-(a7)
	
	cmp.b	#$36,d0		; N - skip level
	beq.b	.N
	move.l	joy1(pc),d1
	btst	#JPB_BTN_YEL,d1
	beq.b	.noN
	btst	#JPB_BTN_FORWARD,d1
	beq.b	.noN

    movem.l a0,-(a7)
    lea     joy1(pc),a0
    clr.l   (a0)
    movem.l (a7)+,a0
.N
	;jsr	$400+$90a.w
	;move.w	#18-2,$5a8

	bset	#14,d7
	bset	#15,d7
	;bset	#12,d7
.noN

	cmp.b	#$28,d0		; L - toggle unlimited lives
	bne.b	.noL
	bsr	ToggleLives
.noL

	cmp.b	#$14,d0		; T - toggle unlimited time
	bne.b	.noT
	bsr	ToggleTime
.noT

	cmp.b	#$35,d0		; B - toggle unlimited bombs
	bne.b	.noB
	bsr	ToggleBombs
.noB

	cmp.b	#$27,d0		; K - get key
	bne.b	.noK
	addq.b	#1,$400+$1aa.w
	bset	#13,d7
.noK

	cmp.b	#$17,d0		; I - toggle invincibility
	bne.b	.noI
;	bset	#1,d7		; turn direction to left
;	bset	#7,d7		; move arm to shoot
	bchg	#9,d7		; invincibility

.noI
    movem.l (a7)+,d1

	rts




.setlevel
	move.l	d0,-(a7)
	move.l	STARTLEVEL(pc),d0
	lsl.w	#2,d0

	lea	$400+$1a8.w,a0
	move.w	d0,(a0)+


	jsr	$400+$90e.w

	move.l	(a7)+,d0
	rts





.movep	move.w	(a1)+,(a3)

; movep.w d1,5(a3)
	move.b	d1,7(a3)
	ror.w	#8,d1
	move.b	d1,5(a3)
	rts
	

; a0.l: file table (sector.w, length.w, destination.l)
.load
	movem.l	d0-a6,-(a7)

.loop	move.l	a0,a1
	moveq	#1,d2		; disk 1
	move.w	(a1)+,d0
	cmp.w	#160*11,d0
	blt.b	.disk1
	sub.w	#160*11,d0
	moveq	#2,d2		; disk 2
.disk1

	move.w	(a1)+,d1
	move.l	(a1)+,a0	; destination
	mulu.w	#512,d0
	mulu.w	#512,d1

	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6


	move.l	a1,a0
	jsr	$400+$3436.w	; ATOM decruncher

	tst.w	(a0)		; -1 = end of file table
	bpl.b	.loop

	movem.l	(a7)+,d0-a6
	moveq	#0,d7
	rts


.ackVBI	move.w	#1<<5,$9c(a6)
	move.w	#1<<5,$9c(a6)
	rts


store_old_pos_and_read_joystick
	; save previous joystick input
	lea	previous_joy(pc),a0
	move.l	joy1(pc),(a0)
	moveq	#1,d0
	bsr	_read_joystick
	lea	joy1(pc),a0
	move.l	d0,(a0)		
	rts
	
pl_tfmx
	PL_START
    PL_IFC5X	1
    PL_ELSE
	PL_PSS	$6cfa2,tfmx_fix_dmacon_1,2
	PL_PS	$6cf1e,tfmx_fix_dmacon_2
	PL_ENDIF
	PL_END
	
tfmx_fix_dmacon_2
	MOVE.W	d0,_custom+dmacon
	bra.b	soundtracker_loop
tfmx_fix_dmacon_1
	MOVE.W	50(A6),_custom+dmacon
soundtracker_loop
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
; we'll change A6 to point not to $DFF00C but to our copy
hack_up:
	movem.l	d0/a0,-(a7)
	bsr	store_old_pos_and_read_joystick
	; only when walking levels

	move.w	CURRENT_LEVEL,d0
	lea	level_table(pc),a0

	tst.w	(a0,d0.w)
	bne.b	.skip
	
	move.l	joy1(pc),d0
	
	move.w	(a6),d1	; joyxdat value
	move.l	d0,d2
	
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d1
	btst	#9,d1
	beq.b	.noneed
	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d2
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:
	lea		fake_joydat(pc),a6
	move.w	d1,(a6)		; store the tampered-with value
.skip
	movem.l	(a7)+,d0/a0
	; original code (which changes D1-D3 so no need to save regs above)
_orig
    MOVE.L #$02,D1
    MOVE.L #$01,D2
    MOVE.L #$01,D3
	RTS
read_joy:
	move.l	d0,d1
	move.l	a0,d2
	bsr		store_old_pos_and_read_joystick	; read and store for later
	move.l	d1,d0
	move.l	d2,a0
	bra		_orig
level_table
	dc.w	0	; first walking level
	dc.w	1,1,1
	dc.w	0	; jungle walking level
	dc.w	1,1,1
	dc.w	0,0	; 2 last levels, walking
fake_joydat
	dc.w	0
	
game_over
    lea keyboard_address(pc),a0
    tst.l   (a0)
    beq.b   .noescgo
    ; cancel ESC
    ; that's a way to avoid instant "ESC" the next
    ; time a game is run and fwd+reverse is pressed
    move.l  (a0),a0
    clr.b   (a0)
.noescgo
    LEA.L $0007fa14,A0
    rts
    
    
joypad_controls:
	movem.l	a0/d0/d1,-(a7)
	tst.w	$359e.W	; pause flag
	beq.b	.noread
	move.l	A0,-(a7)
	bsr		store_old_pos_and_read_joystick	; read and store for later
	move.l	(a7)+,a0
.noread

	move.l	joy1(pc),d0
	move.l	previous_joy(pc),d1
	btst	#JPB_BTN_PLAY,d1
	bne.b	.nopause
	
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause	
	move.b	#$19,(A0)	; "P"

.nopause
;	btst	#JPB_BTN_GRN,d0
;	beq.b	.nosb
;	move.b	#$40,(a0)	; "SPACE" yeah but doesn't work!
;.nosb

	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	move.b	#$45,(A0)	; "ESC"
    move.l  a1,d0
    ; note down keyboard address
    lea keyboard_address(pc),a1
    move.l  a0,(a1)
    move.l  d0,a1
.noesc
	movem.l	(a7)+,a0/d0/d1
	RTS
	
previous_joy:
	dc.l	0
keyboard_address:	
	dc.l	0
;;	move.b	#$40,$528.w		; key: space
	
SetKbd	move.l	a0,-(a7)
	bsr	SetLev2IRQ

	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.l	(a7)+,a0
	rts

.kbdcust
	move.b	RawKey(pc),d0
	move.b	d0,$528.w
	rts


.nokeys
	rts
	

WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
	rts

FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts

***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1


	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.w	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	lea	Key(pc),a2
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

	move.l	KbdCust(pc),d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom	
	


	or.b	#1<<6,$e00(a1)			; set output mode



	cmp.b	HEADER+ws_keydebug(pc),d0	
	bne.b	.nodebug
	movem.l	(a7)+,d0-d1/a0-a2
	move.w	(a7),6(a7)			; sr
	move.l	2(a7),(a7)			; pc
	clr.w	4(a7)				; ext.l sr
	bra.b	.debug


.nodebug
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

.debug	pea	(TDREASON_DEBUG).w
	bra.w	EXIT

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

WAIT_RASTER:MACRO
_waitraster_\1
    move.l  #$100+\1*4,$140.W   ; mark current used wait (debug)
.w
	move.l	$dff004,d1
	and.l	#$1ff00,d1
	cmp.l	$100+\1*4,d1
	bne.b	.w
	rts
    ENDM
    
    WAIT_RASTER    0
    WAIT_RASTER    1
    WAIT_RASTER    2
    WAIT_RASTER    3
    WAIT_RASTER    4
    WAIT_RASTER    5
    WAIT_RASTER    6
    WAIT_RASTER    7
    WAIT_RASTER    8
    WAIT_RASTER    9
    WAIT_RASTER    10

_waitraster_4_or_10
    ; timings depend on the level, but loop is shared...
    cmp.w   #2,CURRENT_LEVEL
    beq.b   .first_flying_subboss
    bra _waitraster_10
.first_flying_subboss
    bra _waitraster_4
    
wait_values:
    dc.l    303<<8  ; ??
    dc.l    $120<<8 ; walk levels ($4)
    dc.l    $120<<8 ; flying after purple boss flicker issues on 68060
    dc.l    303<<8  ; map fade ($C)
    dc.l    $F8<<8  ; first flying boss ($10) don't change value
    dc.l    $110<<8  ; boss 2 ($14)
    dc.l    $120<<8  ;  flying boss vertical scroll ($18) with 303<<8 fireballs are splitted!!
    dc.l    $100<<8  ;  machine boss ($1C)
    dc.l    $120<<8  ; last boss ($20) fireballs flicker issues on 68060
    dc.l    303<<8  ; ??
    dc.l    $120<<8 ; flying after purple boss flicker issues on 68060
    
; ByteKiller 3.0 decruncher

; a0.l: source
; a1.l: destination

BK30_Decrunch
	movem.l	d0-a6,-(a7)
	bsr.b	.decrunch
	movem.l	(a7)+,d0-a6
	rts
	
.decrunch
	move.l	(a0)+,d0		; crunched length
	move.l	(a0)+,d1		; decrunched length
	add.l	d0,a0			; end of crunched data
	move.l	(a0),d0
	move.l	a1,a2
	add.l	d1,a2			; a2: end of decrunched data

	moveq	#3,d5
	moveq	#2,d6
	moveq	#1<<4,d7
.loop	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.b	.nextlong
.nonew1	bcs.b	.get_cmd

	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.nextlong
.nonew2	bcs.b	.store

	moveq	#3,d1
	moveq	#0,d4

.enter_unpacked
	bsr.b	.getbits
	move.w	d2,d3
	add.w	d4,d3

.store_unpacked
	moveq	#8-1,d1
.getbyte
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.nextlong
.nonew3	addx.l	d2,d2
	dbf	d1,.getbyte
	move.b	d2,-(a2)
	dbf	d3,.store_unpacked
	bra.b	.next

.cmd_02	moveq	#8,d1
	moveq	#8,d4
	bra.b	.enter_unpacked

.get_cmd
	moveq	#2,d1
	bsr.b	.getbits
	cmp.b	d6,d2		; d6: 2 -> %01
	blt.b	.cmd_01
	cmp.b	d5,d2		; d5: 3 -> %11
	beq.b	.cmd_02

.cmd_03	moveq	#8,d1
	bsr.b	.getbits
	move.w	d2,d3
	moveq	#12,d1
	bra.b	.store

.cmd_01	moveq	#9,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3
;	move.b	d3,(a6)

.store	bsr.b	.getbits

.copy	subq.w	#1,a2
	move.b	(a2,d2.w),(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	move.w	d7,ccr
	roxr.l	#1,d0
	rts

.getbits
	subq.w	#1,d1
	moveq	#0,d2
.getbits_loop
	lsr.l	#1,d0
	bne.b	.stream_ok
	move.l	-(a0),d0
	move.w	d7,ccr
	roxr.l	#1,d0
.stream_ok
	addx.l	d2,d2
	dbf	d1,.getbits_loop
	rts

