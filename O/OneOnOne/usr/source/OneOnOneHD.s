;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"OneOnOne.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $000
NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT
BOOTBLOCK
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
slv_Version	= 17
slv_Flags	= WHDLF_NoError
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"One on One",0
slv_copy		dc.b	"1985 Electronic Arts",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Thanks to Carlo for original diskimage",10
		dc.b	"and help with debug dumps",10,10
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	0
slv_config
        dc.b    "C1:X:Swap joystick port:1;"
		dc.b	0

	EVEN


_bootblock:
	movem.l	a0-a2/a6/d0-d1,-(A7)

	bsr	calibrate_delay_loop
	
	patch	$100,_new_doio

	lea	_pl_bootblock(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/d0-d1
	jsr	($C,a4)
	movem.l	a0-a2/d0-d1,-(A7)
	move.l	a0,a1
	lea	_pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/a6/d0-d1
	moveq.l	#0,D0
	rts

slowdown:
	movem.l	D0,-(a7)
	move.l	vbl_counter(pc),d0
	sub.l	#$D38,d0		; value measured with "exact cycle"
	bmi.b	.skip
	lsr.l	#8,d0	; roughly divide by 64
	beq.b	.skip
	bsr	beamdelay
.skip
	movem.l	(a7),d0
	move.l	A0,(a7)
	move.l	memory_loc(pc),a0
	MOVE.B	(a0),D0
	move.l	(a7)+,A0
	rts
vbl_counter:
	dc.l	0
memory_loc:
	dc.l	0	; probably $22EE8, who knows?
	
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

	; 17CB7, 8DAA: A1200 cycle exact??, D37: A500 cycle exact
calibrate_delay_loop
	lea	_custom,a2
	move.w	#$4000,(intena,a2)
.vbl
	btst	#5,(intreqr+1,a2)
	beq.b	.vbl
	
	move.w	#$3FFF,(intreq,a2)
	move.l	#0,d0
.loop
	add.l	#1,d0
	btst	#5,(intreqr+1,a2)
	beq.b	.loop
	
	move.w	#$C000,(intena,a2)
	lea	vbl_counter(pc),a2
	move.l	d0,(a2)
	rts
	
; $270DC active wait

_go_main:
	move.l	(4,a7),a0
	movem.l	D0-D1/A0-A2,-(A7)
	move.l	a0,a2
	add.l	#$34AA6-$22EE8,a2
	lea	memory_loc(pc),a1
	move.l	(a2),a1		; store this location, we'll need it later
	move.l	a0,a1
	move.l	_resload(pc),a2
	lea	_pl_main(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(A7)+,D0-D1/A0-A2

	jmp	(a0)

_protect:
	lsl.l	#2,d1
	move.l	d1,a1

	movem.l	D0-D1/A0-A3,-(A7)
	cmp.w	#$4EB9,$F0(a1)
	bne.b	.skip
	move.l	_resload(pc),a2
	lea	_pl_protect(pc),a0
	jsr	resload_Patch(a2)
.skip
	movem.l	(A7)+,D0-D1/A0-A3

	bsr	_flushcache
	jmp	(A1)

_new_doio
	cmp.l	#$1600,$2C(a1)
	beq.b	.error			; report error on track 1 (protection)
	jsr	-$1C8(a6)
	rts
.error
	moveq	#$15,D0

.loop
	move.w	#$0F0,$dff180
	btst	#6,$bfe001
	bne.b	.loop

	rts

_emulate_protect:
	movem.l	A0/A1,-(A7)
	lea	$10(A0),A0
	clr.w	(a0)+
	move.l	#$1,(a0)+

	move.l	#$248b5827,(a1)+
	move.l	#$a945d2e6,(a1)+
	move.l	#$4455d847,(a1)+
	move.l	#$91133e26,(a1)+
	move.l	#$12446efe,(a1)+
	move.l	#$5113de2a,(a1)+
	move.l	#$4449e8cb,(a1)+
	move.l	#$45105e2b,(a1)+
	move.l	#$a92352fb,(a1)+
	move.l	#$889452fd,(a1)+
	move.l	#$2249df46,(a1)+
	move.l	#$2923ee3b,(a1)+
	move.l	#$a4a330fe,(a1)+
	move.l	#$2289ee3b,(a1)+
	move.l	#$8a89e84b,(a1)+
	move.l	#$a225d8e6,(a1)+
	move.l	#$4545ef4b,(a1)+
	move.l	#$5488537e,(a1)+
	move.l	#$488be8ca,(a1)+
	move.l	#$22886b2b,(a1)+
	move.l	#$4a4b284b,(a1)+
	move.l	#$a549f0fe,(a1)+
	move.l	#$292330fb,(a1)+
	move.l	#$45233efa,(a1)+
	move.l	#$252528fb,(a1)+
	move.l	#$a22b3e25,(a1)+
	move.l	#$2529dee5,(a1)+
	move.l	#$8a23e845,(a1)+
	move.l	#$52a3d827,(a1)+
	move.l	#$94446b25,(a1)+
	addq.l	#8,A1
	move.l	#$7000000,(a1)+
	move.l	#$0,(a1)+
	move.l	#$5f500038,(a1)+
	move.l	#$ffffffff,(a1)+
	move.l	#$ffffffff,(a1)+
	move.l	#$90000,(a1)+
	move.l	#$ff,(a1)+
	move.l	#$0,(a1)+
	move.l	#$0,(a1)+
	move.l	#$0,(a1)+
	move.l	#$0,(a1)+
	move.l	#$0,(a1)+
	move.l	#$a758,(a1)+
	move.l	#$140,(a1)+
	move.l	#$ff000000,(a1)+
	move.l	#$1d,(a1)+
	move.l	#$1970,(a1)+
	move.l	#$ffffffff,(a1)+
	move.l	#$0,(a1)+
	move.l	#$5f64,(a1)+
	move.l	#$0,(a1)+
	addq.l	#4,A1
	move.l	#$a758,(a1)+
	move.l	#$118,(a1)+


	movem.l	(A7)+,A0/A1
	move.l	A1,D0
	rts

_pl_main:
	PL_START
	; slowdown
	PL_PS	$23620-$22EE8,slowdown
	PL_IFC1
	; replace joystick input, port 0 by port 1

	PL_L	$CAD8-$2EE8,$DFF00C
	PL_L	$CE24-$2EE8,$DFF00C
	PL_W	$CAEA-$2EE8,$7
	PL_W	$CB30-$2EE8,$7

	; replace joystick input, port 1 by port 0

	PL_L	$CB20-$2EE8,$DFF00A
	PL_L	$CE14-$2EE8,$DFF00A
	PL_W	$CB06-$2EE8,$6
	PL_W	$CB4D-$2EE8,$6
	PL_ENDIF
	PL_END

; --------------------------------------------------------------

_pl_bootblock:
	PL_START
	PL_R	$9C	; avoid green screen + pause
	PL_END

_pl_protect:
	PL_START

	PL_PS	$F0,_emulate_protect
	PL_L	$CEC,$4EB80100
	PL_END


_pl_boot:
	PL_START

	; avoid long pause

	PL_R	$3C
	PL_L	$329C,$4EB80100

	; decryption fix (thanks Marble Madness Derek's patch)
	PL_L	$1C40,$2F3C00FC
	PL_L	$1C44,$00004E71
	PL_L	$1C48,$4E714E71
	PL_W	$1C4C,$4E71

	PL_L	$1C7C,$2F3C00FC
	PL_L	$1C80,$00004E71

	PL_L	$1CB4,$2F3C00FC
	PL_L	$1CB8,$00004E71

	PL_L	$1CD2,$2F3C00FC
	PL_L	$1CD6,$00004E71

	PL_L	$1CE8,$2F3C00FC
	PL_L	$1CEC,$00004E71

	; patch decrypted protection check

	PL_PS	$1A38,_protect

	; main program

	PL_P	$5FC,_go_main

	PL_END



_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0



	END

