; v1.1, 06.11.2017, stingray
; - Bplcon0 color bit fixes
; - WaitRaster fix removed
; - interrupts fixed
; - 68000 quitkey support
; - blitter wait added
; - most of the code converted to patch lists

; 07.11.2017
; - version check added
; - 68000 quitkey for intro par added
; - default quitkey changed to F10


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	whdmacros.i

;DEBUG

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
	
HEADER	SLAVE_HEADER		; ws_Security+ws_ID
	DC.W	17		; ws_Version
	DC.W	7		; ws_Flags
	DC.L	$80000		; ws_BaseMemSize
	DC.L	0		; ws_ExecInstall
	DC.W	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	: ws_CurrentDir
	ELSE
	DC.W	0		; ws_CurrentDir
	ENDC
	DC.W	0		; ws_DontCache
	DC.B	0		; ws_keydebug
	DC.B	$59		; ws_keyexit
	DC.L	0		; ws_ExpMem
	DC.W	.name-HEADER	; ws_name
	DC.W	.copy-HEADER	; ws_copy
	DC.W	.info-HEADER	; ws_info
	dc.w    0     ; kickstart name
	dc.l    $0         ; kicksize
	dc.w    $0         ; kickcrc
	dc.w	.slv_config-HEADER

.slv_config:
		dc.b    "C2:B:Second button jumps;"
		dc.b	0
	even
.dir	IFD	DEBUG
	dc.b	"CODE:SOURCES_WRK/WHD_Slaves/Wolfchild",0
	ENDC
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

.name	DC.B	'-) WOLFCHILD (-',0
.copy	DC.B	'1991 Core Design Ltd.',0
.info	DC.B	'Installed and fixed by',10
	dc.b	10
	DC.B	'------------------------',10
	DC.B	"Galahad of Fairlight",10
	dc.b	"StingRay/Scarab^Scoopex",10
	dc.b	"JOTD",10
	DC.B	'Version '
	DECL_VERSION
	dc.b	10
	DC.B	'Original and BTTR versions supported',10
	DC.B	'------------------------',10
	dc.b	10
	DC.B	'Thanks to John Regent for the images',10,0

	CNOP	0,2

IGNORE_JOY_DIRECTIONS

	include	"ReadJoyPad.s"

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2
	

; install level 2 interrupt
	bsr	SetLev2IRQ

	moveq	#1,d2
	move.l	#$400,d0
	move.l	#$6E00,d1
	lea	$7000.W,a0
	move.l	a0,a5
	move.l	d1,d5
	bsr	LoadDisk


	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$6ed9,d0
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)
	jmp	(a5)




PLBOOT	PL_START
	PL_P	$11b2,Loader
	PL_P	$1166,.patch
	PL_ORW	$8a+2,1<<3		; enable level 2 interrupt
	PL_END
	



.patch	movem.l	a0/a1,-(sp)
	lea	$6814E,a0
	lea	Patch2(pc),a1
	move.w	#$4EF9,(a0)+
	move.l	a1,(a0)+
	movem.l	(sp)+,a0/a1
	bsr	_flushcache
	jmp	$68000


_flushcache:
	move.l	a2,-(a7)
	move.l	resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts


Patch2	move.l	a1,a2			; stack code
.copy	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne.b	.copy
.clear	clr.b	(a1)+
	subq.l	#1,d1
	bne.b	.clear

	movem.l	d0-a6,-(a7)
	lea	PL1(pc),a0
	lea	$68000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6

	jmp	(a2)


PL1	PL_START
	PL_P	$4c74,Loader
	PL_P	$4ac,.PatchGame
	


; v1.1 patches, StingRay
	PL_P	$95c,.ackCOP
	PL_ORW	$2cae+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3d2a+2,1<<9		; set Bplcon0 color bit
	

	PL_ORW	$84a+2,1<<3		; enable level 2 interrupt
	PL_END

.ackCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte


.PatchGame
	;;MOVEM.L	D0-D7/A0-A7,-(A7)	;00400: 48e7ffff
	; stolen decrunch code from $400. run from here avoids double jump
	; plus it runs from fastmem so it's faster than from $400
	LEA	$4B0.W,A0		;00404: 41fa00aa
	LEA	$400.W,A1	;00408: 43fafff6
	MOVEA.L	A0,A3			;0040c: 2648
	ADDA.W	2(A3),A0		;0040e: d0eb0002
	TST.L	(A3)+			;00412: 4a9b
	ADDQ.W	#4,A0			;00414: 5848
	MOVE.L	(A0)+,D1		;00416: 2218
	MOVE.L	(A0)+,D0		;00418: 2018
	MOVE.L	D0,-(A7)		;0041a: 2f00
	LEA	0(A0,D0.L),A2		;0041c: 45f00800
	ADDA.L	#$00000100,A2		;00420: d5fc00000100
	ADDA.L	D1,A0			;00426: d1c1
	MOVE.B	-(A0),D1		;00428: 1220
	MOVEQ	#0,D2			;0042a: 7400
	MOVEQ	#7,D3			;0042c: 7607
.lab_0001:
	MOVEA.L	A3,A4			;0042e: 284b
.lab_0002:
	ADD.B	D1,D1			;00430: d201
	BCC.S	.lab_0003		;00432: 6402
	ADDQ.W	#2,A4			;00434: 544c
.lab_0003:
	DBF	D3,.lab_0004		;00436: 51cb0006
	MOVEQ	#7,D3			;0043a: 7607
	MOVE.B	-(A0),D1		;0043c: 1220
.lab_0004:
	MOVE.W	(A4),D4			;0043e: 3814
	BMI.S	.lab_0005		;00440: 6b04
	ADDA.W	D4,A4			;00442: d8c4
	BRA.S	.lab_0002		;00444: 60ea
.lab_0005:
	TST.B	D2			;00446: 4a02
	BMI.S	.lab_0006		;00448: 6b0a
	CMP.W	#$f100,D4		;0044a: b87cf100
	BNE.S	.lab_0007		;0044e: 660a
	SUBQ.B	#1,D2			;00450: 5302
	BRA.S	.lab_0001		;00452: 60da
.lab_0006:
	ADD.B	D4,D2			;00454: d404
	SUB.L	D2,D0			;00456: 9082
	MOVE.B	(A2),D4			;00458: 1812
.lab_0007:
	MOVE.B	D4,-(A2)		;0045a: 1504
	DBF	D2,.lab_0007		;0045c: 51cafffc
	ADDQ.W	#1,D2			;00460: 5242
	SUBQ.L	#1,D0			;00462: 5380
	BNE.S	.lab_0001		;00464: 66c8
	LEA	-4(A3),A0		;00466: 41ebfffc
	MOVE.L	(A7)+,D0		;0046a: 201f
	ADDA.W	2(A0),A0		;0046c: d0e80002
	MOVE.L	8(A0),D0		;00470: 20280008
	ADDA.L	#$0000010c,A0		;00474: d1fc0000010c
	MOVE.L	A0,D1			;0047a: 2208
	SUB.L	A1,D1			;0047c: 9289

; we used to do that previously (hook on 47E)	
;.oldpg
;	lea	$47E.W,a0
;	lea	.dopatch(pc),a1		; call patch afer decrunching
;	move.w	#$4EF9,(a0)+
;	move.l	a1,(a0)
;	jmp	$400.w

.dopatch
	move.l	a1,a2			; stack code
.copy	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne.b	.copy
.clear	clr.b	(a1)+
	subq.l	#1,d1
	bne.b	.clear

	; now load from disk 2
	lea	DiskNum(pc),a0
	addq.w	#1,(a0)

	IFD	DEBUG
	move.w	#0,sr			; back to user mode so snoop works
	ENDC


	lea	PLGAME(pc),a0
	move.l	a2,a1
	move.l	resload(pc),a3
	jsr	resload_Patch(a3)

	bsr	_detect_controller_types

	; a2 = $9BC
	jmp	(a2)


WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

RTSZ = $4E750000
current_keycode = $17CAB

PLGAME	PL_START
	; "emulate" modifications done by the copylock
	PL_L	$75A-$400,RTSZ
	PL_L	$74EC-$400,RTSZ
	PL_L	$7DD0-$400,RTSZ
	PL_L	$A30A-$400,RTSZ
	PL_L	$A3CE-$400,RTSZ
	PL_L	$FDD4-$400,RTSZ
	PL_L	$10E26-$400,RTSZ
	PL_W	$17B34-$400,$AC		; set some variables
	PL_L	$17B36-$400,$ACAC00		; as above
	PL_L	$1F4AC-$400,$6000FF7C	; skip strange code
	PL_L	$1F5F4-$400,$6000FE34	; skip strange code
	PL_P	$17944,Loader
	PL_R	$16478			; disable copylock
	PL_R	$11d74			; disable disk 2 request	
	

; v1.1 patches, StingRay
	PL_ORW	$151d2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$15302+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1547a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1556c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$15ff0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$16100+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$16238+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$16294+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$16458+2,1<<9		; set Bplcon0 color bit


	PL_PS	$1776a,.ackCOP
	PL_PS	$17870,.checkquit
	
	PL_PS	$19184,.wblit1
	
; v1.2 patch, JOTD
	PL_PS	$17B92-$400,.load_ciaa_pra
	PL_P	$008C2-$400,.unpause
	PL_IFC2
	PL_PS	$00017BB6-$400,.read_joydat_button_1
	PL_PSS	$00017BCA-$400,.read_joydat_button_2,2
	PL_ENDIF
	PL_END

.load_ciaa_pra
	bsr	_read_joysticks_buttons
	movem.l	D0,-(a7)
	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	move.b	#$45,current_keycode
.noesc
	btst	#JPB_BTN_PLAY,d0
	beq.b	.noplay
	move.b	#$19,current_keycode
.noplay
	movem.l	(a7)+,d0
	MOVE.B	$BFE001,D7
	RTS

.unpause:
	movem.l	D0,-(a7)
	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_PLAY,d0
	beq.b	.w
	; PLAY was pressed. Clear key
	CLR.B	current_keycode
	; now wait PLAY and P not pressed first
.w
	bsr	.wait_unpress
	
	; now wait for P/PLAY to be pressed again to unpause
	; play when rev+fwd are pressed => quit to wb
.wait_press
	CMPI.B	#$19,current_keycode		;008c2: 0c39001900017cab
	beq.S	.final_wait_press		;008ca: 67f6
	bsr	_read_joysticks_buttons
	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_PLAY,d0
	beq.b	.wait_press
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.final_wait_press
	btst	#JPB_BTN_REVERSE,d0
	bne	EXIT
	
.final_wait_press
	; now wait PLAY and P not pressed first, AGAIN
	bsr	.wait_unpress

	movem.l	(a7)+,d0
	RTS
	
.wait_unpress
	bsr	_read_joysticks_buttons
	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_PLAY,d0
	bne.b	.wait_unpress
	CMPI.B	#$19,current_keycode		;008c2: 0c39001900017cab
	beq.b	.wait_unpress
	rts
	
.read_joydat_button_1:
	movem.l	d2,-(a7)
	MOVE.B (A6,$000c),D0		; original

	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#0,D0
	btst	#1,D0
	beq.b	.noneed2
	bset	#0,D0	; xor 8 and 9 yields 0 cos bit9=1
.noneed2
	move.l	joy1_buttons(pc),d2
	btst	#JPB_BTN_BLU,d2
	beq.b	.no_blue2
	; set UP because blue pressed
	bclr	#0,D0
	btst	#1,D0
	bne.b	.no_blue2
	bset	#0,D0	; xor 8 and 9 yields 1 cos bit9=0
.no_blue2:

	movem.l	(a7)+,d2
	; original
	MOVE.B D0,D1
	rts
	
.read_joydat_button_2:
	movem.l	d2,-(a7)
	move.l	joy1_buttons(pc),d2
    MOVE.B (A6,$000c),D1	; original, not the BYTE read
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	; (subtracted 8 to bit values, cos original reads JOYDAT
	; byte by byte)
	bclr	#0,d1
	btst	#1,d1
	beq.b	.noneed
	bset	#0,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d2
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#0,d1
	btst	#1,d1
	bne.b	.no_blue
	bset	#0,d1	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:
	
	movem.l	(a7)+,d2
	; original
    BTST.L #$0001,D1
	RTS

	
.wblit1	bsr	WaitBlit
	move.w	#$ffff,$44(a6)
	rts


.ackCOP	move.w	#1<<4,$9c(a6)
	move.w	#1<<4,$9c(a6)
.noquit	rts


.checkquit
	move.b	d0,$400+$178ab

	cmp.b	HEADER+ws_keyexit(pc),d0
	bne.b	.noquit
	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts





Loader	movem.l	d1-a6,-(a7)
	tst.l	d1
	beq.b	.error
	tst.l	d2
	beq.b	.error
	tst.w	d0
	bne.b	.error
	move.l	#$FFF,d4
	and.l	d4,d1
	and.l	d4,d2
	cmp.w	#$6E0,d2
	bgt.b	.error
	moveq	#0,d3
	add.w	d1,d3
	add.w	d2,d3
	cmp.w	#$6E0,d3
	bgt.b	.error
	bsr.b	.getparams
	moveq	#0,d2
	move.w	DiskNum(pc),d2
	bsr.w	LoadDisk
	movem.l	(a7)+,d1-a6
	moveq	#0,d0			; no errors
	rts

.error	movem.l	(sp)+,d1-d7/a0-a6
	moveq	#-1,d0
	rts

.getparams
	mulu	#512,d1
	mulu	#512,d2
	move.l	d1,d0
	move.l	d2,d1
	rts



DiskNum	dc.w	1
resload	dc.l	0

LoadDisk
	movem.l	d0/d1/a0-a2,-(a7)
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0/d1/a0-a2
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
	beq.b	.end

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

.exit
QUIT	pea	(TDREASON_OK).w
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	
	
Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

