	incdir	include:
	include	whdload.i
	include	whdmacros.i

	IFD BARFLY
	IFD	ONEMEG
	OUTPUT	FinalFight.slave
	ELSE
	OUTPUT	FinalFight_512.slave
	ENDC
	
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;one_id	=$336f	; powerpacker packed v1
;two_id	=$50d7
one_id	=$7A64
two_id	=$5B38

REMOVE_AF=1

patch:MACRO
	move.w	#$4EF9,\1
	pea	\2(pc)
	move.l	(a7)+,\1+2
	ENDM
	
patchs:MACRO
	move.w	#$4EB9,\1
	pea	\2(pc)
	move.l	(a7)+,\1+2
	ENDM

pushall:MACRO
	movem.l	D0-A6,-(A7)
	ENDM
pullall:MACRO
	movem.l	(A7)+,D0-A6
	ENDM
_rte = $4E73
_nopnop = $4E714E71

_nop = $4E71

TST_EVEN:MACRO
	ENDM
; debug version of TST_EVEN: note down the odd value	
;	movem.w	d7,-(A7)
;	move.w	\1,d7
;	btst	#0,d7
;	beq.b	.even\@
;	move.w	#$0F0,$DFF180
;	move.l	\1,$150000
;	move.w	#\2,$150004
;.even\@
;	movem.w	(A7)+,d7
;	ENDM

	IFD	ONEMEG
basemem=$100000
	ELSE
basemem=$80000
	ENDC
	
_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	15		;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError	;ws_flags
		dc.l	basemem
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	data-_base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
		dc.l	0	; optional $80000 memory, cannot set it since game does not like 32-bit memory
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

data:
	dc.b	"data",0
	even
_expmem		dc.l	basemem-$80000	; optional $80000 memory at $80000

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.7"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"Final Fight"
		dc.b	0
_copy		dc.b	"1991 Capcom",0
_info		dc.b	"adapted by Dark Angel & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	0
	even

EXEBASE = $1000
;--- load & unpack main file

start:
	lea	_resload(pc),a1
	move.l	a0,(a1)

	lea	4.w,a0
.clr	clr.l	(a0)+
	cmp.l	#$200,a0
	blt.b	.clr

	lea	main(pc),a0
	lea	EXEBASE-$20,a1
	move.l	_resload(pc),a6
	jsr	resload_LoadFileDecrunch(a6)

	lea	EXEBASE-$20,a0
	move.l	_resload(pc),a6
	jsr	resload_CRC16(a6)

	move	#$2700,sr
	lea	$dff000,a6
	lea	$300.w,a7
	
	lea	version(pc),a0
	cmp	#one_id,d0
	beq.b	version_1
	
	cmp	#two_id,d0
	beq.b	version_2


;--- return to os

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts

	
;--- patch selection part

version_1	
;--- patch main file

	patch	EXEBASE+$14C,part11
	bsr	_flushcache
	
	move.l	_expmem(pc),d0
	bne.b	.expansion
	
	jmp	EXEBASE+$C6	; no extra memory
.expansion
	move.l	d0,A0
	move.l	d0,A1
	add.l	#$80000,A1
	jmp	EXEBASE+$e4	; extra memory
	
;---
version_2
;--- patch main file
	
	patch	EXEBASE+$188,part12
	bsr	_flushcache
	
	move.l	_expmem(pc),d0
	bne.b	.expansion
	
	jmp	EXEBASE+$102	; no extra memory
.expansion
	move.l	d0,A0
	move.l	d0,A1
	add.l	#$80000,A1
	jmp	EXEBASE+$120	; extra memory

;---
	IFD	ONEMEG
JMPEXT:MACRO
	move.l	_expmem(pc),-(A7)
	add.l	#\1,(A7)	
	rts
	ENDM
LEAEXT:MACRO
	move.l	_expmem(pc),\2
	add.l	#\1,\2	
	ENDM
	ELSE
	; same thing, only faster
LEAEXT:MACRO
	lea	\1,\2
	ENDM
JMPEXT:MACRO
	jmp	\1
	ENDM
	ENDC
	
part11
	; copy some data to zero page
.loop11
	move	(a0)+,(a1)+
	dbf	d7,.loop11

	patch	$1c,part21
	bsr	_flushcache
	rts	; jump to zero
;---

part12	move	(a0)+,(a1)+
	dbf	d7,part12

	patch	$1c,part22
	bsr	_flushcache
	rts
;---

part21
	movem.l	D0-D1/A0-A2,-(A7)
	LEAEXT	$71190,A1
	lea	pl_main_1(pc),A0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(A7)+,D0-D1/A0-A2
	JMPEXT	$7375a
	
; 1MB chipmem offset: x-$71190 => x+$80000. ex $789B6 => $F89B6
; this is historical: at first, slave only supported 512k chip no fastmem
; with some strange allocation

pl_main_1:
	PL_START
	IFD	REMOVE_AF
	PL_PS	$789b6-$71190,_af1			; remove access faults
	PL_PS	$78b1a-$71190,_af2
	PL_PS	$78a58-$71190,_af31
	PL_W	$78a5e-$71190,$4E71
	PL_PS	$7693c-$71190,_af4
	PL_PS	$780a2-$71190,_af51
	PL_W	$780a8-$71190,$4E71
	PL_PS	$71778-$71190,_af6
	PL_P	$78ad2-$71190,_af71
	PL_PS	$76af6-$71190,_af8
	PL_PS	$78ab0-$71190,_af9
	PL_PS	$74068-$71190,_afa
	PL_PS	$769c0-$71190,_afb
	PL_PS	$7699e-$71190,_afc
	ENDC
	
	; skip drive access
	PL_NOPS	$797E0-$71190,1
	PL_S	$797F2-$71190,$10
	PL_S	$797C8-$71190,$DA-$C8
	
	PL_W	$798ac-$71190,$4E73			; no disk protection
	PL_P	$79802-$71190,_loader
    
    PL_PS  $732B0-$71190,keyboard  ; quitkey on 68000
    ;PL_P   $732D2-$71190,handshake
    
	PL_END

	

;---

part22
	movem.l	D0-D1/A0-A2,-(A7)
	LEAEXT	$71154,A1
	lea	pl_main_2(pc),A0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(A7)+,D0-D1/A0-A2
	JMPEXT	$73758
	
pl_main_2
	PL_START
	IFD	REMOVE_AF
	PL_PS	$789b4-$71154,_af1			; remove access faults
	PL_PS	$78b18-$71154,_af2
	PL_PS	$78a56-$71154,_af32
	PL_W	$78a5c-$71154,$4E71
	PL_PS	$7693a-$71154,_af4
	PL_PS	$780a0-$71154,_af52
	PL_W	$780a6-$71154,$4E71
	PL_PS	$71776-$71154,_af6
	PL_P	$78ad0-$71154,_af72
	PL_PS	$76af4-$71154,_af8
	PL_PS	$78aae-$71154,_af9
	PL_PS	$74066-$71154,_afa
	PL_PS	$769be-$71154,_afb
	PL_PS	$7699c-$71154,_afc
	ENDC
	
	PL_W	$798aa-$71154,$4E73			; no disk protection
	
	; skip drive access & DSKRDY that locks up on some amigas
	PL_NOPS	$797D4-$71154,2
	PL_NOPS	$797F6-$71154,3
	PL_NOPS	$797DE-$71154,1

	PL_P	$79800-$71154,_loader

    PL_PS  $732AE-$71154,keyboard  ; quitkey on 68000
     ; was to remove a shitload of NOPs, done after proper timer wait
     ; causes more issues than it fixes
    ;PL_P   $732D0-$71154,handshake

	PL_END


keyboard:
    MOVE.B $00bfec01,D0
    movem.w d0,-(a7)
    ror.b   #1,d0
    not.b   d0
    cmp.b   _keyexit(pc),d0
    movem.w (a7)+,d0    ; movem preserves flags
    bne.b   .noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit    
    rts    
    
    IFEQ    1
handshake:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
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
    ENDC
    

AF_MASK = basemem-1	; $7FFFF or $FFFFF

;--- remove access faults

_af1	
	and.l	#AF_MASK,d0
	move.l	d0,a1
	clr.l	(a1)
	clr	$18(a1)
	rts
;---

_af2	move.l	d0,-(sp)
	
	move.l	a5,d0
	add.w	d1,d0
	
	move.l	(a5,d1.w),d0
	and.l	#AF_MASK,d0
	move.l	d0,a5
	move.l	(sp)+,d0

	tst.l	(a5)
	rts
;---

_af31	move.l	d0,-(sp)
	LEAEXT	$743e2,a3
	move.l	(a3,d1.w),d0
	and.l	#AF_MASK,d0
	move.l	d0,a3
	TST_EVEN	d0,12
	move.l	(sp)+,d0
	rts
;---

_af32	move.l	d0,-(sp)
	LEAEXT	$743e0,a3
		
	move.l	(a3,d1.w),d0
	and.l	#AF_MASK,d0
	move.l	d0,a3
	TST_EVEN	d0,1
	move.l	(sp)+,d0
	rts
;---

_af4	move.l	d0,-(sp)

	move.l	a3,d0
	add.l	d1,d0
	
	move.l	(a3,d1.w),d0
	and.l	#AF_MASK,d0
	move.l	d0,a3
	move.l	(sp)+,d0

	tst.l	(a3)
	rts
;---

_af51	move.l	d0,-(sp)
	LEAEXT	$743e2,a1
	move.l	(a1,d0.w),d0
	and.l	#AF_MASK,d0
	move.l	d0,a1
	TST_EVEN	d0,4
	move.l	(sp)+,d0
	rts
;---

_af52	move.l	d0,-(sp)
	LEAEXT	$743e0,a1
	move.l	(a1,d0.w),d0
	and.l	#AF_MASK,d0
	move.l	d0,a1
	TST_EVEN	d0,5
	move.l	(sp)+,d0
	rts
;---

_af6	move.l	d0,-(sp)
	lsl	#2,d3
	move.l	(a2,d3.w),d0
	and.l	#AF_MASK,d0
	move.l	d0,a2
	TST_EVEN	d0,6
	move.l	(sp)+,d0
	rts
;---

_af71	and.l	#AF_MASK,d1
	move.l	d1,a0
	tst.l	(a0)
	beq.b	.j78acc
	JMPEXT	$78ad8
.j78acc	JMPEXT	$78acc
;---

_af72	and.l	#AF_MASK,d1
	move.l	d1,a0
	tst.l	(a0)
	beq.b	.j78aca
	JMPEXT	$78ad6
.j78aca	JMPEXT	$78aca
;---

_af8	move.l	d1,-(sp)
	lsl	#2,d0
	move.l	(a0,d0.w),d1
	and.l	#AF_MASK,d1
	move.l	d1,a0
	TST_EVEN	d0,7
	move.l	(sp)+,d1
	rts
;---

_af9	move.l	d0,-(sp)
	lsl	#2,d2
	move.l	(a4,d2.w),d0
	and.l	#AF_MASK,d0
	move.l	d0,a0
	TST_EVEN	d0,10
	move.l	(sp)+,d0
	rts
;---

_afa	move.l	d1,-(sp)
	lsl	#2,d0

	move.l	a2,d1
	add.l	d0,d1
	cmp.l	#AF_MASK+1,d1
	bge.b	.beyond

	move.l	(a2,d0.w),d1
	and.l	#AF_MASK,d1
	; problem here: d1 can be odd, transfered to A3
	; and at $74098 there's a TST.W  (A3) => crash on 68000
	; but the game worked, which means that access fault (fixed)
	; read a different value that in non-fixed (where it probably read 0 in the woods):
	; I decided to set A3 only if D1 is even else set it to 0
	; (hell the game is buggy)
	sub.l	A3,A3
	btst	#0,d1
	bne.b	.beyond
	move.l	d1,a3
	TST_EVEN	d1,30
.beyond	move.l	(sp)+,d1
	rts
;---

_afb	lsl	#2,d6
	move.l	(a2,d6.w),d2
	and.l	#AF_MASK,d2
	TST_EVEN	d2,23
	rts
;---

_afc	move.l	d0,-(sp)
	lsl	#2,d1
	move.l	(a0,d1.w),d0
	and.l	#AF_MASK,d0
	move.l	d0,a1
	TST_EVEN	d0,20
	move.l	(sp)+,d0
	rts


;--- file loader

_loader	pushall

	move.l	$1ada.w,a0
	move.l	$1ade.w,d0
	and.l	#AF_MASK,d0
	move.l	d0,a1
	move.l	_resload(pc),a6
	jsr	resload_LoadFileDecrunch(a6)

	add.l	d0,$1ade.w

	pullall

	sf	$1af8.w
	moveq	#0,d0

	move.l	$1afa,a7
	rts



_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

;--------------------------------
_resload	dc.l	0	;	=
version	dc.w	0	;	=
;--------------------------------


;--- file names

main	dc.b	'final',0


