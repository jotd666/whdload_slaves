	incdir	include:
	include	whdload.i
	include	whdmacros.i

pushall:MACRO
	movem.l	d0-a6,-(a7)
	ENDM

pullall:MACRO
	movem.l	(a7)+,d0-a6
	ENDM


	IFD BARFLY
	OUTPUT	CiscoHeat.slave
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

;--- power to the people

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_Disk|WHDLF_NoError	; ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
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

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Cisco Heat"
		dc.b	0
_copy		dc.b	"1992 Imageworks",0
_info		dc.b	"adapted & fixed by Dark Angel & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION


COPYLOCK_ID=$b4863d88

	even


;--- bootblock

start	lea	_resload(pc),a1
	move.l	a0,(a1)

	move.l	#1300,d1
	move.l	#61,d2
	lea	$10000,a0
	bsr.w	loader

	patch	$10066,.part1
	bsr	_flushcache

	jmp	$10000
;---

.part1	lea	.part2(pc),a0
	move.l	a0,$70006			; pea .part2

	patch	$7016a,loader
	bsr	_flushcache
	jmp	$70000
;---

.part2	patch	$15e0.w,.part3
	bsr	_flushcache
	jmp	$800.w
;---

.part3
	bsr.w	lscore

	move.l	#$4e714e71,d0
	lea	$24fc.w,a0			; kill access faults
	moveq	#4,d7
	bsr.w	remra
	lea	$253e.w,a0
	moveq	#2,d7
	bsr.b	remra
	lea	$2560.w,a0
	moveq	#0,d7
	bsr.b	remra

	pea	fix_smc_jmp(pc)
	move.l	(a7)+,$BC.W

	lea	pl_main(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	$1f42.w


_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

pl_main
	PL_START
	PL_W	$1f8e,$4E71.w			; no ext. mem
	PL_W	$1f94,$4E71.w
	PL_W	$1f9a,$4E71.w

	PL_PS	$9bfe,access

	PL_L	$1f5c,0				; fake rn
	PL_L	$25a8,0
	PL_L	$60,COPYLOCK_ID
	PL_L	$263f4,COPYLOCK_ID
	PL_L	$2640c,COPYLOCK_ID
	PL_L	$34f6,-2.w

	PL_P	$a6ec,cia
	PL_B	$15791,$7f			; add backspace to key table

	PL_P	$5362,sscore

	PL_P	$771c,loader

	; JOTD

	; fix sound

	PL_PS	$A9AE,fix_sound_fault_1
	PL_PS	$A9E4,fix_sound_fault_2

	; fix SMC
	
	PL_PS	$7682,store_d0_d1
	PL_PS	$76E4,retrieve_d0_d1
	PL_W	$76EA,$4E71

	PL_W	$9472,$4E4F	; JMP emu

	PL_PS	$960C,store_a0
	PL_PS	$9782,retrieve_a0

	PL_PS	$98F4,store_d1
	PL_PS	$9A24,retrieve_d1
	PL_END

store_d1
	move.l	a0,-(a7)
	lea	value_d1(pc),a0
	move	d1,(a0)+
	movem.l	(a7)+,a0
	rts

retrieve_d1
	move.w	value_d1(pc),d1
	tst.b	d1	; stolen
	rts

value_d1
	dc.w	0

store_a0
	movem.l	a1,-(a7)
	lea	value_a0(pc),a1
	move.l	a0,(a1)
	movem.l	(a7)+,a1
	rts

retrieve_a0
	move.l	value_a0(pc),a0
	rts

value_a0
	dc.l	0

store_d0_d1
	move.l	a0,-(a7)
	lea	values_d0d1(pc),a0
	move	d0,(a0)+
	move	d1,(a0)+
	movem.l	(a7)+,a0
	add.l	#6,(a7)
	rts

retrieve_d0_d1
	move.l	a0,-(a7)
	lea	values_d0d1(pc),a0
	move	(a0)+,d0
	move	(a0)+,d1
	movem.l	(a7)+,a0
	rts

values_d0d1
	dc.l	$8F	; start value

fix_smc_jmp
	move.l	A0,-(A7)
	move.l	6(A7),A0	; return address
	move.l	(A0),6(A7)	; RTE -> JMP address
	move.l	(A7)+,A0
	rte

; volume settings: byte write to DFF0x8 now fixed

fix_sound_fault_1

	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	(a2),d0
	move.w	d0,(A1)
	move.l	(a7)+,d0

	MOVE.L	A2,26(A6)

	rts

fix_sound_fault_2
	MOVEA.L	18(A6),A2		;0A9E4: 246E0012

	move.l	d1,-(a7)
	and.w	#$00FF,d1
	move.w	d1,(A2)
	move.l	(a7)+,d1
	addq.l	#1,a1
	rts

;--- remove roms access

remra	move.l	d0,(a0)+
	move	d0,(a0)+
	addq.l	#6,a0
	dbf	d7,remra
	rts


;--- avoid access fault

access	move	d1,d0
	subq	#1,d0

	move.l	d0,-(sp)

	move.l	a6,d0
	and.l	#$7ffff,d0
	move.l	d0,a0

	move.l	(sp)+,d0
	rts


;--- keyboard

cia	movem.l	d0-d1/a0-a1,-(sp)

	lea	$bfe001,a1
	btst	#3,$d00(a1)
	beq.b	.ciabye

	moveq	#0,d0
	move.b	$c00(a1),d0
	clr.b	$c00(a1)

	not.b	d0
	lsr.b	#1,d0
	bcs.b	.nokey

	cmp.b	_keyexit(pc),d0
	bne.b	.noquit

	; quit possible on 68000 now
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.noquit
	lea	$15750,a0
	move.b	(a0,d0.w),d0
	beq.b	.nokey
	move.l	$1574c,a0
	cmp.l	#$1574c,a0
	beq.b	.nokey
	move.b	d0,(a0)+
	move.l	a0,$1574c

.nokey	or.b	#$40,$e00(a1)

	moveq	#2,d1
.hshake	move.b	$dff006,d0
.same	cmp.b	$dff006,d0
	beq.b	.same
	dbf	d1,.hshake

	and.b	#$bf,$e00(a1)

.ciabye	move	#8,$dff09c
	movem.l	(sp)+,d0-d1/a0-a1
	rte


;--- load highscores

lscore	pushall

	lea	scores(pc),a0
	lea	$536e.w,a1
	move.l	_resload(pc),a6
	jsr	resload_LoadFile(a6)

	pullall
	rts


;--- save highscores

sscore
	jsr	$31b4.w				; fade off screen

	pushall
	move.l	#192,d0
	lea	scores(pc),a0
	lea	$536e.w,a1
	move.l	_resload(pc),a6
	jsr	resload_SaveFile(a6)

.nosave	pullall
	moveq	#0,d0
	rts


;--- universal loader

loader	pushall

	move.l	d1,d0
	move.l	d2,d1
	mulu	#512,d0
	mulu	#512,d1
	moveq	#1,d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

	pullall
	moveq	#0,d0
	rts

;--------------------------------
_resload	dc.l	0	;	=
;--------------------------------


;--- file names

scores	dc.b	'highs',0
