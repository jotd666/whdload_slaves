; Game is available on aminet: game/jump/DK-1200.lha

		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		INCLUDE	hardware/dmabits.i

		IFD BARFLY
		OUTPUT	"DonkeyKong.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

BASEMEM		equ	$80000

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_NoKbd	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
;		dc.w	_Data-_base		;ws_CurrentDir
		dc.w	0
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

_name		dc.b	"Donkey Kong",0
_copy		dc.b	"1991 Bignomia",0
_info		dc.b	"Installed by JOTD",10
		dc.b	"Version 1.0 "
		INCBIN	"T:date"
		dc.b	0
		dc.b	-1,"Thanks to Mad-Matt for the original!",0
_MainFile	dc.b	"DK-1200",0
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

	lea	BASEMEM-$20,A7
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use


	lea	_MainFile(pc),a0	;Decrunch main game
	lea	$10000-$20,a1
	move.l	a1,a5
	move.l	_resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)		

	move.l	a5,a0
	move.l	#384960,D0	; exe raw length
	jsr	resload_CRC16(A2)
	cmp.w	#$416C,D0
	bne	_wrongver	; will fail if the file is exe-ProPacked

	bsr	InstallVectors

	sub.l	a1,a1
	lea	_pmain(pc),A0
	jsr	(resload_Patch,A2)

	jmp	$1000A

_pmain:	PL_START
	PL_S	$10022,$8	; skip custom stuff
	PL_PS	$10160,KbFix
	PL_W	$10166,$4E71
	PL_P	$10040,JmpC0
	PL_END	

_pc0:	PL_START
	PL_P	$E8,JmpA6
	PL_END	

_pl_main:
	PL_START
;;	PL_PS	$1F6-$EC,_check_lmb
	PL_W	$12C-$EC,$80		; correct cop2 -> cop1
	PL_W	$136-$EC,$88		; correct copjmp2 -> copjmp1
	PL_S	$2E,6			; skip freeze all interrupts
	PL_PS	$FE,PauseTest
	PL_END

_check_lmb:
	btst	#6,$BFE001
	bne.b	.zap
	illegal
.zap
	and.l	#$1FF00,D1
	rts
JmpC0:
	lea	$6DF88,A1
	movem.l	A0-A2/D0-D1,-(A7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)

	sub.l	a1,a1
	lea	_pc0(pc),A0
	jsr	(resload_Patch,A2)

	movem.l	(A7)+,A0-A2/D0-D1
	jmp	$C0.W

JmpA6:
	movem.l	A0-A2/D0-D1,-(A7)
	move.l	_resload(pc),a2
	move.l	a6,a1
	lea	_pl_main(pc),A0
	jsr	(resload_Patch,A2)

	move.w	#$C008,$DFF09A

	movem.l	(A7)+,A0-A2/D0-D1
	jmp	(A6)
	
KbFix:
	move.b	_kbvalue(pc),d0
	cmp.b	_keyexit(pc),D0		; quit key?
	beq	_exit
	and.b	#$BF,$BFEE01	; stolen code
	rts

PauseTest:
	move.l	d0,-(A7)
	move.b	_kbvalue(pc),d0
	cmp.b	_keyexit(pc),D0		; quit key?
	beq	_exit

	cmp.b	#25,D0		; 'P' for pause
	bne.b	.nopause

	move.l	A0,-(A7)

	move.w	_custom+dmaconr,d0
	and.w	#$F,d0
	move.w	#$F,_custom+dmacon	; stops sound

	lea	_kbvalue(pc),a0
	clr.b	(a0)
	; wait for pause again
.loop
	cmp.b	#25,(a0)
	bne.b	.loop
	clr.b	(a0)

	bset	#15,d0
	move.w	D0,_custom+dmaconr	; resumes sound

	move.l	(a7)+,a0
.nopause
	move.l	(a7)+,d0
	and.l	#$FFFF,d0	; stolen code
	rts

InstallVectors:
	lea	int68(pc),A0
	move.l	A0,$68.W
	rts


;	lea	int6C(pc),A0
;	move.l	A0,$6C.W
;	lea	int70(pc),A0
;	move.l	A0,$70.W

;	move.l	#$00880000,$40.W
;	move.l	#$FFFFFFFE,$44.W
;	move.l	#$FFFFFFFE,$48.W
;	move.l	#$48,$DFF084
;	move.l	#$40,$DFF080

;;	move.w	#$80D0,$DFF096	; enables bitplane/copper dma

_kbdelay
	; delay for keyboard

	move.l	D0,-(A7)
	moveq	#2,D0
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.l	(A7)+,D0
	rts

_kbvalue:
	dc.w	0

int68:
	btst	#3,$bfed01
	beq.b	.skip
	movem.l	D0/A0,-(A7)
	move.b	$bfec01,d0
	ror.b	#1,d0
	not.b	d0
	lea	_kbvalue(pc),a0
	move.b	d0,(a0)
	bset	#6,$bfee01
	bsr	_kbdelay
	bclr	#6,$bfee01
	movem.l	(a7)+,D0/A0
.skip
	move.w	#$8,$DFF09C
	RTE


;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

_exit	
		pea	TDREASON_OK
		bra	_end
;_debug		pea	TDREASON_DEBUG
;		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================
