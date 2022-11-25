;*---------------------------------------------------------------------------
;  :Program.	HollywoodPokerProHD.asm
;  :Contents.	Slave for "HollywoodPokerPro" from
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	HollywoodPokerPro.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $0

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	_dir-_base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

		
DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


_name		dc.b	"Hollywood Poker Pro"
		dc.b	0
_copy		dc.b	"1991 Reline",0
_info		dc.b	"adapted & fixed by Dark Angel & JOTD",10,10
		dc.b	"CUSTOM1=1 enables cheat keys",10,10
		dc.b	"F1: set pot to 0",10
		dc.b	"F2: set your money to 0",10
		dc.b	"F3: set girl money to 0",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_dir
	dc.b	"data",0
_config
        dc.b    "C1:X:Cheat keys F1/F2/F3:0;",0

main	dc.b	'hollydat',0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0
	even

one_id	=$a108					; dos format version
two_id	=$72cd					; top shots version

;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	a0,a2
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

		lea	CHIPMEMSIZE-$100,a7


	lea	main(pc),a0
	lea	$60500,a1
	move.l	_resload(pc),a6
	jsr	resload_LoadFile(a6)

	lea	$60500,a0
	move.l	_resload(pc),a6
	jsr	resload_CRC16(a6)

	lea	version(pc),a0
	cmp	#one_id,d0
	beq.b	.known
	cmp	#two_id,d0
	beq.b	.known


;--- return to os
.unknown
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts


;--- patch game

.known	move	d0,(a0)

	cmp	#one_id,d0
	bne.b	.v2

.v1	move	#$4e75,$63624			; no ext. mem
	bra.b	.unknown

	move.l	#$4e714e71,d0

	patchs	$66d80,pal			; read from exec structure
	move.l	d0,$66d86

	lea	$67470,a0			; they write to $dff058 first!
	move.l	d0,(a0)+
	move	d0,(a0)
	patch	$674b2,blit

	patch	$62e66,cia

	patch	$67804,loader
	bsr	flush
	jmp	$60502
;---

; JOTD: original, MFM version

.v2	
	movem.l	d0-d1/a0-a2,-(a7)
	sub.l	a1,a1
	lea	pl_v2(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(A2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$60502

pl_v2
	PL_START
	PL_R	$63624			; no ext. mem

	PL_P	$62698,active_loop_d7
	PL_P	$65244,active_loop_d6

	PL_PS	$66d8a,pal			; read from exec structure
	PL_L	$66d90,$4E714E71

	; they write to $dff058 first!
	PL_L	$6747A,$4E714E71
	PL_W	$6747E,$4E71
	PL_P	$674bc,blit

	PL_P	$62e66,cia

	PL_P	$6780e,loader

	; JOTD: fix the press-return-to-continue-then-freeze bug (after losing or winning)
	;
	; (keyboard interrupt problem detected on 68060 because code is in chipmem
	; and is slow so the bug has the time to occur before the proper interrupt
	; routine is installed)

	PL_W	$6350A,$8010	; was $8018 to enable keyboard
	PL_PS	$63536,enable_keyboard_interrupt

;;	PL_P	$675E8,dummy_acknowledge_interrupt

	PL_END

enable_keyboard_interrupt
	clr.b	$bfec01	; original
	move.w	#$8008,$dff09a	; the proper interrupt routine is installed again
	rts

dummy_acknowledge_interrupt
	IFEQ	1
	btst	#7,$bfe001
	bne.B	.sk
	ILLEGAL
.sk
	ENDC

	MOVE	#$7FFD,$dff09C
	RTE				;675F0: 4E73
	
;--- active loops

DELAY_FACTOR = $20	; the higher, the shorter is the delay

active_loop_d6
	DIVU	#DELAY_FACTOR,D6		;62698: 8EFC00DC
	ANDI.L	#$0000FFFF,D6		;6269C: 02870000FFFF
	move.l	d0,-(a7)
	move.l	d6,d0
	bsr	beamdelay
	move.l	(a7)+,d0
	rts


active_loop_d7
	DIVU	#DELAY_FACTOR,D7		;62698: 8EFC00DC
	ANDI.L	#$0000FFFF,D7		;6269C: 02870000FFFF
	move.l	d0,-(a7)
	move.l	d7,d0
	bsr	beamdelay
	move.l	(a7)+,d0
	rts


quit:
	pea	TDREASON_OK
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
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


;--- fake pal vblankfrequency

pal	moveq	#50,d0
	rts


;--- write to blitsize at last

blit	move	d1,$dff058

.bbusy	btst	#14,$dff002
	bne.b	.bbusy

	movem.l	(sp)+,d0-a6
	rts


;--- keyboard

cia
	movem.l	d0-d1/a0-a1,-(sp)

	lea	$bfe001,a1
	btst	#3,$d00(a1)
	beq.b	.ciabye

	move.b	$c00(a1),d0
	clr.b	$c00(a1)

	ror.b	#1,d0
	not.b	d0
	and	#$ff,d0
	move	d0,$60084

	cmp.b	_keyexit(pc),d0
	beq		quit
	
	move.l	_custom1(pc),d1
	beq.b	.nokeys

	cmp.b	#$50,d0
	bne.b	.nozpot
	clr.w	$6017E
.nozpot
	cmp.b	#$51,d0
	bne.b	.nozyou
	clr.w	$60182
.nozyou
	cmp.b	#$52,d0
	bne.b	.nozme
	clr.w	$60186
.nozme
.nokeys

	or.b	#$40,$e00(a1)

	moveq	#2,d1
.hshake	move.b	$dff006,d0
.same	cmp.b	$dff006,d0
	beq.b	.same
	dbf	d1,.hshake

	and.b	#$bf,$e00(a1)


.ciabye	move	#8,$dff09c
	movem.l	(sp)+,d0-d1/a0-a1
	rte


;--- file loader

loader	movem.l	d1-a7,-(sp)

	move	#$8210,$dff096			; done in the loader

	move.l	d1,a0
	move.l	d2,a1
	move.l	_resload(pc),a6
	jsr	resload_LoadFile(a6)

	move.l	#$48a7fffe,d1			; fix coder bugs

	lea	$1f5a4,a0
	cmp.l	(a0),d1
	bne.b	.no1
	move	#$48e7,(a0)
	move	#$4cdf,12(a0)

.no1	lea	$1f66e,a0
	cmp.l	(a0),d1
	bne.b	.no2
	move	#$48e7,(a0)
	move	#$4cdf,12(a0)

.no2	bsr.b	flush

	movem.l	(sp)+,d1-a7
	rts


;--- flush caches

flush
	move.l	a6,-(a7)
	move.l	_resload(pc),a6
	jsr	resload_FlushCache(a6)
	move.l	(a7)+,a6
	rts

;--------------------------------
_resload
	dc.l	0
version	dc.w	0	;	=
;--------------------------------

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0


