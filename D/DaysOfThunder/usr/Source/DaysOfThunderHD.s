***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      DAYS OF THUNDER WHDLOAD SLAVE         )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               July 2015                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 02-Jul-2015	- default quit key changed to Del as F10 is used in the game
;		- Chk/Div0/TrapV exceptions fixed

; 01-Jul-2015	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	whdmacros.i
	
EMULFLAGS	= WHDLF_EmulTrap|WHDLF_EmulChk|WHDLF_EmulDivZero|WHDLF_EmulTrapV
FLAGS		= WHDLF_NoError|WHDLF_ClearMem|EMULFLAGS
QUITKEY		= $46		; Del
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

;CHIP_ONLY
RELOC_ENABLED
;UNRELOC_ENABLED

	IFD	RELOC_ENABLED
EXPMEMSIZE = $80000
	ELSE
EXPMEMSIZE = $0	
	ENDC
	
	IFD	CHIP_ONLY
CHIPMEMSIZE = $80000+EXPMEMSIZE
FASTMEMSIZE = 0	
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = EXPMEMSIZE
	IFND	UNRELOC_ENABLED
UNRELOC_ENABLED
	ENDC
	
	ENDC
	
; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	CHIPMEMSIZE		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
_keyexit:
	dc.b	QUITKEY		; ws_KeyExit
_expmem:
	dc.l	FASTMEMSIZE		; ws_ExpMem
	dc.w	name-HEADER	; ws_name
	dc.w	copy-HEADER	; ws_copy
	dc.w	info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	
    dc.b    "C1:X:Trainer no timer - fast qualifying:0;"
	dc.b	0

dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/DaysOfThunder/"
	ENDC
	dc.b	"data",0
	
_reloc_file
	dc.b	"dot.reloc",0
_unreloc_file
	dc.b	"dot.unreloc",0

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

name	dc.b	"Days of Thunder"
		IFD		CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
		
		dc.b	0
copy	dc.b	"1990 Mindscape",0
info	dc.b	"installed by StingRay/[S]carab^Scoopex & JOTD",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version "
	DECL_VERSION
	dc.b	0

	dc.b	0
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	10,0	

Name	dc.b	"dot",0
		CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	TAG_END

resload	dc.l	0

PROGRAM_START = $300
PROGRAM_SIZE = $41dac

Patch	

	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	IFD		RELOC_ENABLED
	IFD		CHIP_ONLY
	lea		_expmem(pc),A0
	move.l	#$80000,(a0)
	ENDC
	
	move.l	_reloc_base(pc),d0
	add.l	_expmem(pc),d0
	lea		_reloc_base(pc),a0
	move.l	d0,(a0)
	ENDC
	
	move.l	_expmem(pc),$100.W
	
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; install keyboard irq
	bsr	SetLev2IRQ


; load demo
	lea	Name(pc),a0
	lea	PLGAME(pc),a1
	move.w	#$764e,d0		; SPS 0285


; a0.l: file name
; a1.l. patch list
; d0.w: checksum
.load_and_patch
	move.l	a1,a4
	move.w	d0,d5
	
	lea	PROGRAM_START-$20,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	d5,d0
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.ok

	
	add.w	#$20,a5		; skip hunk header
	
	IFD		RELOC_ENABLED
	
	; copy program

	move.l	#PROGRAM_SIZE/4,d0
	lea		PROGRAM_START,a0
	move.l	_reloc_base(pc),A1
.copyr
	move.l	(a0)+,(a1)+
	subq.l	#1,d0
	bne.b	.copyr
	
	; load reloc table

	lea	_reloc_file(pc),a0		; name of reloc binary table
	lea		PROGRAM_START+PROGRAM_SIZE,a1		; use program end
	move.l	a1,a3	; save load location
	jsr		resload_LoadFileDecrunch(a2)

	; relocate
	move.l	_reloc_base(pc),a0
	move.l	a0,a5		; change start
	lea		(-PROGRAM_START,a0),a1	; reloc base -$300
	move.l	a1,d1
	move.l	a3,a1	; reloc table load location
.reloc
	move.l	(a1)+,d0
	beq.b	.end
	add.l	d1,(a0,d0.l)
	bra.b	.reloc
.end

	IFD	UNRELOC_ENABLED
	; unrelocate: cancel relocation of some data that
	; needs to be in chipmem
	lea		_unreloc_file(pc),a0
	move.l	a3,a1	; load location
	jsr		resload_LoadFileDecrunch(a2)
	
	; relocate
	move.l	_reloc_base(pc),a0
	lea		(-PROGRAM_START,a0),a1	; reloc base -$300
	move.l	a1,d1
	move.l	a3,a1	; load location
.unreloc
	move.l	(a1)+,d0
	beq.b	.endu
	; correct offsets
	sub.l	d1,(a0,d0.l)
	bra.b	.unreloc
.endu
	ENDC
	
	; debug: add MMU protect on old program $ -> $ for v1
	; 
	; w 0 $300 $41dac-$300
	ENDC
	
; patch
	move.l	a4,a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

; set default VBI
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w


; and start
	IFD		RELOC_ENABLED
	move.l	_expmem(pc),a7
	add.l	#EXPMEMSIZE,a7
	jmp	($A,a5)
	ELSE
	jmp	($4,a5)		; original stack
	ENDC




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte



PLGAME	PL_START
	PL_PSS	$4d3e-$300,.ackVBI,2
	PL_PSA	$3cb8-$300,.loadfile,$3d4e-$300
	PL_R	$e3c6-$300			; disable drive access (motor off)

	PL_P	$4ab2-$300,.setlev2		; don't install new level 2 interrupt
	PL_R	$4b3c-$300			; terminate level 2 interrupt code

	PL_W	$11bfe-$300,$4e73		; fix Div0 exception
	PL_W	$11c1e-$300,$4e73		; fix TrapV exception
	PL_W	$11c34-$300,$4e73		; fix Chk exception
	PL_I	$0b2b8-$300				; bogus code made illegal (won't happen)
	PL_I	$03d94-$300				; infinite loop
	
	PL_P	$1a10a-$300,soundtracker_loop_d0
	PL_PSS	$01aba-$300,soundtracker_loop_d7,2
	PL_PSS	$18be6-$300,soundtracker_loop_d7,2
	PL_PSS	$18c60-$300,soundtracker_loop_d7,2
	
	PL_PSS	$18bb0-$300,soundtracker_loop_d7,2
	PL_PSS	$18c30-$300,soundtracker_loop_d7,2
	PL_PSS	$18c9a-$300,soundtracker_loop_d7,2
	
	PL_PS	$0d8fa-$300,fix_smc_d8fa
	; same SMC twice
	PL_PSS	$ebfc-$300,fix_smc_ebfc,2
	PL_PSS	$f912-$300,fix_smc_ebfc,2
	; duff device #1 (we're overwriting robustness code)
	PL_PS	$0d90c-$300,fix_duff_device_1
	PL_PS	$0eb96-$300,fix_duff_device_2
	; same SMC twice
	PL_PS	$0ecc0-$300,fix_smc_ecc0
	PL_PS	$0f9d6-$300,fix_smc_ecc0

	; trainer: no timer
	PL_IFC1X	0
	PL_NOP	$0401e-$300,4	; no timer: super 0 time!!!
	PL_NOP	$040a4-$300,2	; instant qualifying after 1 lap
	PL_ENDIF
	
	IFD		RELOC_ENABLED
	PL_PSS	$19FF4-$300,load_sound,2
	ENDC
	PL_END

.emulate_dbf
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	.beamdelay
	move.w	#$FFFF,d0
	rts

.beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts


	
.setlev2
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.w	#$c008,$dff09a		; enable level 2 interrupt
	rts

.kbdcust
	moveq	#0,d0
	move.b	Key(pc),d0
	not.b	d0
	move.w	d0,-(a7)
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	beq		QUIT
	
	IFEQ	1
	cmp.b	#1,d0
	bne.b	.no_one
	move.l	a0,-(a7)
	move.l	_expmem(pc),a0
	; adds a lap
	;add.l	#$39f8a,a0		; main status struct
	;addq.w	#1,(66,a0)
	add.l	#$3ca30,a0
	move.w	#1,(a0)
	move.l	(a7)+,a0
.no_one
	ENDC
	
	move.w	(a7)+,d0
	move.l	_expmem(pc),-(a7)
	add.l	#$4B30,(a7)
	rts
	

.loadfile
	move.l	_expmem(pc),a1
	move.l	($778a,a1),a1
	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)

.ackVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts
	
load_sound:
	move.l	_expmem(pc),a5
	lea		$1a8d2,A0		;19ff4: 41fa08dc
	add.l	#$18f04,A5	;19ff8: 4bfaef0a
	rts
	
soundtracker_loop_d0
	move.w	#4,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts 

soundtracker_loop_d7
	move.w	#4,d7   ; make it 7 if still issues
.bd_loop1
	move.w  d7,-(a7)
    move.b	$dff006,d7	; VPOS
.bd_loop2
	cmp.b	$dff006,d7
	beq.s	.bd_loop2
	move.w	(a7)+,d7
	dbf	d7,.bd_loop1
	rts 

fix_smc_ecc0:
	ADDQ.W	#1,D6			;0ecc0: 5246
	LEA	160(A2),A2		;0ecc2: 45ea00a0
	; too many SMC occurrences ahead: flush cache instead
	bra.b	_flushcache
	
fix_smc_f9f0:
	LEA	10(A1),A1		;0f9f0: 43e9000a
	move.l	a0,-(a7)
	move.l	(4,a7),a0
	sub.w	(a0),d5
	move.l	(a7)+,a0
	addq.w	#2,(a7)
	rts
	
fix_duff_device_1:
	move.l	d1,-(a7)
	moveq	#0,d1
	move.w	d0,d1
	add.w	#14,d1			; make up for early jump
	add.l	d1,(4,a7)		; emulate SMC bra
	move.l	(a7)+,d1
	rts
	
fix_duff_device_2:
	AND.L	D0,(A3)			;0eb96: c193
	AND.L	D3,D1			;0eb98: c283
	OR.L	D1,(A3)+		;0eb9a: 839b
	bra.b		_flushcache		; temporary
	
fix_smc_d8fa:
	move.l	(a7),a2		; return address
	move.w	(a2),d1		; emulate SMC
	ADDA.W	D0,A0			;0d8fa: d0c0
	MOVEA.L	A6,A2			;0d8fc: 244e
	addq.l	#2,(a7)		; skip data
	rts


_flushcache:
	move.l	a2,-(a7)
	move.l	resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

	; we let the fake/bogus smc comparison happen but we ignore
	; the result as it's not reliable
	; then we do something correct. Tricky but less tricky than
	; a TRAP before the value (we don't have room to patch before the test
	; because lb_0ebfc can be branched to)
	; this is untested as I didn't reach that point
fix_smc_ebfc:
	movem.l	d0/a0,-(a7)
	move.l	(8,a7),a0		; return address
	move.w	(-8,a0),d0		; real value to compare to
	cmp.w	d0,d6			; game comparison instruction
	movem.l	(a7)+,d0/a0
	BNE.W	.pass		;0ec00: 66000006
	; pop stack
	addq.l	#4,a7
	; original code from now on
	MOVEA.L	(A7)+,A0		;0ec04: 205f
	RTS				;0ec06: 4e75
.pass
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


FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	$13(a1),d0
	move.w	d0,8(a5)
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
_reloc_base
	dc.l	PROGRAM_START
