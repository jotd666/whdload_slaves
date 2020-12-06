;*---------------------------------------------------------------------------
;  :Program.	EliteHD.asm
;  :Contents.	Slave for "Elite" from
;  :Author.	Dark Angel, JOTD
;  :History.	
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
	OUTPUT	Elite.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

basemem	=$80000


;--- power to the people

_base
	SLAVE_HEADER		;ws_Security + ws_ID
	dc.w	17		;ws_Version
	dc.w	WHDLF_EmulTrap|WHDLF_NoError	; ws_flags
	dc.l	basemem					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	_start-_base				; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
	dc.b	0					; ws_keydebug
_keyexit
	dc.b	92					; ws_keyexit [num \]
	dc.l	0					; ws_expmem
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
	dc.b	"$VER: slave "
	DECL_VERSION
    
_config	dc.b  "BW;"
	dc.b	"C1:B:enables passwords and cheat (type SUZANNE);"
	dc.b	"C3:B:turn off fast cpu fixes;"
	dc.b	0


_name		dc.b	"Elite v2.0"
		dc.b	0
_copy		dc.b	"1989 Mr Micro",0
_info		dc.b	"adapted & fixed by Dark Angel & JOTD",10,10

		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works




;--- version id

;	dc.b	'$VER: EliteV2.0 HD by Dark Angel V1.0 [08/04/99]',0
;	even

pushall:MACRO
	movem.l	d0-a6,-(a7)
	ENDM

pullall:MACRO
	movem.l	(a7)+,d0-a6
	ENDM

;--- bootblock

_start
	lea	_resload(pc),a1
	move.l	a0,(a1)

	move.l	_resload(pc),a6

	;enable cache
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a6)

	lea	tags(pc),a0
	jsr	resload_Control(a6)

	move.l	#2*$1600,d0
	move.l	#17*$1600,d1
	moveq	#1,d2
	lea	$400-4,a0
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

	pea	toggle_ro_1(pc)
	move.l	(a7)+,$b8
	pea	toggle_ro_2(pc)
	move.l	(a7)+,$bc

    move.w  $404,d0
    cmp.w   #$26f2,d0
    bne.b   .other
	lea	pl_main_1572(pc),a0
    bra.b   .p
.other
    cmp.w   #$26e6,d0
    bne.b   .unsup
	lea	pl_main_115(pc),a0
    bra.b   .p
.unsup
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
    
.p
	sub.l	a1,a1
	jsr	resload_Patch(a6)

	jmp	$400.w

ROR_CODE = $E07B
ROL_CODE = $E17B

TOGGLE_ROR_ROL:MACRO
toggle_ro_\1
	movem.l	d1,-(a7)
	move.w	ro_\1(pc),d1
	cmp.w	#ROR_CODE,d1
	beq.b	.ror
	rol.w	d0,d3
	bra.b	.out
.ror
	ror.w	d0,d3
.out
	movem.l	(a7)+,d1
	rte
store_ro_\1
	movem.l	a0,-(a7)
	lea	ro_\1(pc),a0
	move.w	d3,(a0)	
	movem.l	(a7)+,a0
	rts
	
	ENDM

	TOGGLE_ROR_ROL	1
	TOGGLE_ROR_ROL	2

ro_1
	dc.w	ROR_CODE
ro_2
	dc.w	ROR_CODE


pl_main_1572
	PL_START

    PL_IFC1
    PL_ELSE
	PL_R	$bc42			; skip manual protection
    PL_ENDIF
    
	PL_B	$bd08,$60			; manual protection (cheat remains)
	
	PL_S	$26FC,$270C-$26FC	; skip vector overwrite

	PL_PSS	$7718,kb_routine,2

    PL_IFBW
	PL_PS	$2764,buttondelay_1572
    PL_ENDIF
    PL_IFC3
    PL_ELSE
	PL_PSS	$766A,bbusy,2
    ; sound fix
    PL_PS   $06276,write_dmacon_d5
    PL_ENDIF
    
	PL_B	$162be,$60			; self check
	PL_NOP	$bcd0,2			; allow return only


	PL_R	$af10			; head -> #0
	PL_R	$af94			; headpos
	PL_R	$aec4			; head move
	PL_R	$af4a			; drive off

	PL_PS	$29fa,lower
	PL_PS	$a8a6,lower
	PL_PS	$abb8,lower
	PL_PS	$ac6e,lower

	PL_PS	$2a04,upper
	PL_PS	$10d2a,upper
	PL_PS	$10f84,upper

	PL_P	$aea2,rd_trk
	PL_P	$ad1e,sv_trk
	PL_S	$ac8c,$D8-$8C

	; fix SMC without flushing cache (tricky)

	PL_PS	$C7AE,store_ro_1
	PL_S	$C7B4,$C7D4-$C7B4	; skip SMC

	PL_PS	$C9DE,store_ro_2
	PL_S	$C9E4,$CA22-$C9E4	; skip SMC

	PL_W	$C81A,$4E4E
	PL_W	$C83A,$4E4E
	PL_W	$C84E,$4E4E
	PL_W	$C864,$4E4E
	PL_W	$C87A,$4E4E

	PL_W	$CAB2,$4E4F
	PL_W	$CAEE,$4E4F
	PL_W	$CB04,$4E4F
	PL_W	$CB1C,$4E4F
	PL_W	$CB34,$4E4F
	PL_W	$CA54,$4E4F
	PL_W	$CA5E,$4E4F
	PL_W	$CA68,$4E4F
	PL_W	$CA72,$4E4F
	PL_W	$CA7C,$4E4F
    
	PL_END

pl_main_115
	PL_START

    PL_IFC1
    PL_ELSE
	PL_R	$0bc04			; skip manual protection
    PL_ENDIF
    
	PL_B	$bcca,$60			; manual protection (cheat remains)
	
	PL_S	$026f0,$10	; skip vector overwrite

	PL_PSS	$076f8,kb_routine,2

    PL_IFBW
	PL_PS	$02758,buttondelay_115
    PL_ENDIF
    PL_IFC3
    PL_ELSE
	PL_PSS	$0764a,bbusy,2
    PL_PS   $06246,write_dmacon_d5
    PL_ENDIF
    
	PL_B	$1621e,$60			; self check
	PL_NOP	$0bc92,2			; allow return only


	PL_R	$0aed2			; head -> #0
	PL_R	$0af56			; headpos
	PL_R	$0ae86			; head move
	PL_R	$0af0c			; drive off

	PL_PS	$029da,lower
	PL_PS	$0a868,lower
	PL_PS	$0ab7a,lower
	PL_PS	$0ac30,lower

	PL_PS	$029e4,upper
	PL_PS	$10ce2,upper
	PL_PS	$10f36,upper

	PL_P	$0ae64,rd_trk
	PL_P	$0ace0,sv_trk
	PL_S	$0ac4e,$D8-$8C

	; fix SMC without flushing cache (tricky)

	PL_PS	$0c76e,store_ro_1
	PL_S	$0c774,$C7D4-$C7B4	; skip SMC

	PL_PS	$0c99e,store_ro_2
	PL_S	$0c9a4,$CA22-$C9E4	; skip SMC

	PL_W	$0c7da,$4E4E
	PL_W	$0c7fa,$4E4E
	PL_W	$0c80e,$4E4E
	PL_W	$0c824,$4E4E
	PL_W	$0c83a,$4E4E

	PL_W	$ca72,$4E4F
	PL_W	$caae,$4E4F
	PL_W	$cac4,$4E4F
	PL_W	$cadc,$4E4F
	PL_W	$caf4,$4E4F
	PL_W	$ca14,$4E4F
	PL_W	$CA1e,$4E4F
	PL_W	$CA28,$4E4F
	PL_W	$CA32,$4E4F
	PL_W	$CA3C,$4E4F
    
	PL_END

;	PL_PS	$c7ce,.smod1
;	PL_PS	$ca1c,.smod1	; there was a bug in SMC fix !

write_dmacon_d5
	MOVE.W	D5,_custom+dmacon		;: 33c500dff096
	move.w  d0,-(a7)
	move.w	#7,d0
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
    
kb_routine
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01

	cmp.b	_keyexit(pc),d1
	beq.b	.out

	rts

.out
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

;--- buttonwait delay

buttondelay_115
	jsr	$8782
    bra.b   buttondelay_all
buttondelay_1572
	jsr	$8786
buttondelay_all
	pushall

	move.l	#$10000,d7

.wait	btst	#6,$bfe001
	beq.b	.bwbye
	btst	#7,$bfe001
	beq.b	.bwbye

	move.b	$dff006,d0
.sameln	cmp.b	$dff006,d0
	beq.b	.sameln

	subq.l	#1,d7
	bne.b	.wait
;---

.bwbye
	pullall
	rts


;--- flush caches after selfmodification

;.smod1	move	d3,$c87a
;	bra.b	.flush
;---

;.smod2	move	d3,$ca7c
;	bra.b	.flush
;---

;.flush
;	move.l	a6,-(a7)
;	move.l	_resload(pc),a6
;	jsr	resload_FlushCache(a6)
;	move.l	(a7)+,a6
;	rts


;--- blitter wait

bbusy
	MOVE.W	#$1c10,88(A0)		;0766e: 31400058
	
    btst	#6,$dff002
.w
    btst	#6,$dff002
	bne.b	.w

	rts


;--- switch to image 1

lower	move.l	a0,-(sp)

	lea	reqside(pc),a0
	move.l	#1,(a0)

	move.l	(sp)+,a0
	rts


;--- switch to image 2

upper	move.l	a0,-(sp)

	lea	reqside(pc),a0
	move.l	#2,(a0)

	move.l	(sp)+,a0
	rts


;--- single track reader

rd_trk
	pushall

	move	d0,d1
	addq	#1,d1
	move	d7,d0
	mulu	#$1600,d0
	mulu	#$1600,d1
	move.l	reqside(pc),d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

	pullall
	rts


;--- single track saver

sv_trk	
	pushall
	move	d0,d1
	lsr	#1,d1
	move	d7,d0
	addq	#1,d0
	mulu	#$1600,d0
	mulu	#$1600,d1
	lea	(a0),a1
	lea	disk1(pc),a0
	move.l	_resload(pc),a6
	jsr	resload_SaveFileOffset(a6)
	pullall
	rts


;--- skip drive access

format	
	jmp	$acd8

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

;--------------------------------
_resload	dc.l	0	;	=
reqside	dc.l	0	;	=
;--------------------------------


;--- tag list

tags	dc.l	WHDLTAG_BUTTONWAIT_GET
button	dc.l	0
	dc.l	0


;--- file names

disk1	dc.b	'Disk.1',0

rip
